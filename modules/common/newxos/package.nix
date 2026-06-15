{ inputs, ... }:
{
  perSystem =
    {
      self',
      pkgs,
      lib,
      ...
    }:
    let
      inherit (pkgs.stdenv.hostPlatform) system;
      diskoPackage = inputs.disko.packages.${system}.disko or inputs.disko.packages.${system}.default;

      newxos-bin = pkgs.writeShellApplication {
        name = "newxos";
        runtimeInputs =
          with pkgs;
          [
            coreutils
            diskoPackage
            gnugrep
            jq
            nh
            nix
            nixos-install-tools
            nix-output-monitor
            ripgrep
            util-linux
            self'.packages.basic-memory-uv2nix
          ]
          ++ (lib.optionals (self'.packages ? opencode) [ self'.packages.opencode ]);
        text = ''
                    usage() {
                      cat <<'EOF' >&2
          usage: newxos <build-iso|first-install|os|home|flake|clean> ...

            newxos build-iso [--key <path-to-key>]
            newxos first-install <host>
            newxos os <switch|boot|build> [host] [--git-only]
            newxos home <switch|build> <config> [--git-only]
            newxos flake build [host] [--git-only]
            newxos flake check [host] [--git-only]
            newxos flake show [host] [--git-only]
            newxos flake run <attr> [--git-only]
            newxos ai
            newxos memory <reindex|reset>
            newxos clean [nh-clean args...]

          env:
            NEWXOS_FLAKE  repo path. default: $HOME/newxos
            NEWXOS_HOST  default nixos host for host-based commands
          EOF
                      exit 2
                    }

                    die() {
                      printf '%s\n' "$*" >&2
                      exit 1
                    }

                    repo_root() {
                      local root

                      root="''${NEWXOS_FLAKE:-$HOME/newxos}"
                      [ -d "$root" ] || die "missing repo at $root"
                      [ -e "$root/flake.nix" ] || die "missing flake at $root"

                      printf '%s\n' "$root"
                    }

                    flake_ref() {
                      local mode root

                      mode="$1"
                      root="$(repo_root)"

                      case "$mode" in
                        path) printf 'path:%s\n' "$root" ;;
                        git) printf 'git+file://%s\n' "$root" ;;
                        *) die "bad flake mode: $mode" ;;
                      esac
                    }

                    install_repo_root() {
                      local root

                      root="''${NEWXOS_FLAKE:-}"
                      if [ -z "$root" ]; then
                        if [ -e /etc/newxos/flake.nix ]; then
                          root=/etc/newxos
                        else
                          root="$HOME/newxos"
                        fi
                      fi

                      [ -d "$root" ] || die "missing repo at $root"
                      [ -e "$root/flake.nix" ] || die "missing flake at $root"

                      printf '%s\n' "$root"
                    }

                    copy_repo_to_home() {
                      local root root_mountpoint user home_dir

                      root="$1"
                      root_mountpoint="$2"
                      user="$3"
                      home_dir="$root_mountpoint/home/$user"

                      mkdir -p "$home_dir"
                      rm -rf "$home_dir/newxos"
                      cp -aL "$root" "$home_dir/newxos"
                      chroot "$root_mountpoint" chown -R "$user:users" "/home/$user/newxos"
                    }

                    install_sops_age_key() {
                      local root_mountpoint key_source

                      root_mountpoint="$1"
                      key_source=""

                      if [ -r /var/lib/sops-nix/key.txt ]; then
                        key_source=/var/lib/sops-nix/key.txt
                      elif [ -r /etc/newxos-sops-age-key.txt ]; then
                        key_source=/etc/newxos-sops-age-key.txt
                      fi

                      if [ -z "$key_source" ]; then
                        return 0
                      fi

                      install -d -m 0700 "$root_mountpoint/var/lib/sops-nix"
                      install -m 0400 "$key_source" "$root_mountpoint/var/lib/sops-nix/key.txt"
                    }

                    list_nixos_hosts() {
                      rg --no-filename --only-matching --replace '$1' \
                        'flake\.nixosConfigurations\.([[:alnum:]_.+-]+)' \
                        "$(repo_root)/modules" \
                        -g '*.nix' | sort -u
                    }

                    list_home_configs() {
                      rg --no-filename --only-matching --replace '$1' \
                        'flake\.homeConfigurations\.([[:alnum:]_.+-]+)' \
                        "$(repo_root)/modules" \
                        -g '*.nix' | sort -u
                    }

                    list_run_targets() {
                      local system

                      system="$(nix eval --impure --raw --expr builtins.currentSystem)"
                      nix flake show --json "$(flake_ref path)" 2>/dev/null \
                        | jq -r --arg system "$system" '
                            [
                              (.packages[$system] // {} | keys[]?),
                              (.apps[$system] // {} | keys[]?)
                            ]
                            | .[]
                          ' \
                        | sort -u
                    }

                    require_in_list() {
                      local kind needle item cmd

                      kind="$1"
                      needle="$2"
                      cmd="$3"

                      while IFS= read -r item; do
                        [ "$item" = "$needle" ] && return 0
                      done < <("$cmd")

                      die "unknown $kind: $needle"
                    }

                    require_nixos_host() {
                      require_in_list "nixos host" "$1" list_nixos_hosts
                    }

                    require_home_config() {
                      require_in_list "home config" "$1" list_home_configs
                    }

                    default_nixos_host() {
                      local host

                      host="''${NEWXOS_HOST:-}"
                      [ -n "$host" ] || die "missing host arg and NEWXOS_HOST is unset"

                      require_nixos_host "$host"
                      printf '%s\n' "$host"
                    }

                    parse_target_args() {
                      FLAKE_MODE=path
                      POSITIONAL=()

                      while [ "$#" -gt 0 ]; do
                        case "$1" in
                          --git-only) FLAKE_MODE=git ;;
                          -h|--help) usage ;;
                          -*) die "unknown flag: $1" ;;
                          *) POSITIONAL+=("$1") ;;
                        esac
                        shift
                      done
                    }

                    run_nom_nix() {
                      nix --log-format internal-json -v "$@" |& nom --json
                    }

                    complete_cmd() {
                      [ "$#" -eq 1 ] || die "usage: newxos _complete <nixos-hosts|home-configs|run-targets>"

                      case "$1" in
                        nixos-hosts) list_nixos_hosts ;;
                        home-configs) list_home_configs ;;
                        run-targets) list_run_targets ;;
                        *) die "unknown completion group: $1" ;;
                      esac
                    }

                    os_cmd() {
                      local action host

                      [ "$#" -ge 1 ] || usage
                      action="$1"
                      shift

                      case "$action" in
                        switch|boot|build) ;;
                        *) die "unknown os action: $action" ;;
                      esac

                      parse_target_args "$@"
                      case "''${#POSITIONAL[@]}" in
                        0) host="$(default_nixos_host)" ;;
                        1)
                          host="''${POSITIONAL[0]}"
                          require_nixos_host "$host"
                          ;;
                        *) usage ;;
                      esac

                      nh os "$action" "$(flake_ref "$FLAKE_MODE")" -H "$host"
                    }

                    first_install_cmd() {
                      local host install_host install_user flake_root root_mountpoint

                      [ "$#" -eq 1 ] || usage

                      if [ "$EUID" -ne 0 ]; then
                        exec sudo "$0" first-install "$@"
                      fi

                      host="$1"
                      require_nixos_host "$host"
                      flake_root="$(install_repo_root)"
                      root_mountpoint=/mnt
                      install_host="$host"
                      install_user="''${host%%-*}"

                      disko \
                        --mode destroy,format,mount \
                        --root-mountpoint "$root_mountpoint" \
                        --flake "path:$flake_root#$install_host"

                      install_sops_age_key "$root_mountpoint"

                      nixos-install \
                        --root "$root_mountpoint" \
                        --flake "path:$flake_root#$install_host" \
                        --no-root-passwd

                      echo "=== copying newxos flake to /home/$install_user/newxos ==="
                      copy_repo_to_home "$flake_root" "$root_mountpoint" "$install_user"

                      echo ""
                      echo "=== install complete ==="
                      echo "reboot into $host"
                    }

                    build_iso_cmd() {
                      local key root iso_attr

                      key=""
                      while [ "$#" -gt 0 ]; do
                        case "$1" in
                          --key)
                            [ "$#" -ge 2 ] || usage
                            key="$2"
                            shift 2
                            ;;
                          -h|--help) usage ;;
                          -*) die "unknown build-iso flag: $1" ;;
                          *) usage ;;
                        esac
                      done

                      root="$(repo_root)"
                      iso_attr="path:$root#nixosConfigurations.newxos-live-usb.config.system.build.isoImage"

                      if [ -n "$key" ]; then
                        if [ ! -e "$key" ] && ! sudo test -e "$key"; then
                          die "missing key: $key"
                        fi

                        if [ -r "$key" ]; then
                          NEWXOS_INSTALLER_SOPS_KEY="$key" nix build --impure "$iso_attr"
                        else
                          sudo env NEWXOS_INSTALLER_SOPS_KEY="$key" nix build --impure "$iso_attr"
                        fi
                      else
                        nix build "$iso_attr"
                      fi
                    }

                    home_cmd() {
                      local action config_name

                      [ "$#" -ge 2 ] || usage
                      action="$1"
                      shift

                      case "$action" in
                        switch|build) ;;
                        *) die "unknown home action: $action" ;;
                      esac

                      parse_target_args "$@"
                      [ "''${#POSITIONAL[@]}" -eq 1 ] || usage
                      config_name="''${POSITIONAL[0]}"

                      require_home_config "$config_name"
                      nh home "$action" "$(flake_ref "$FLAKE_MODE")" -c "$config_name"
                    }

                    flake_cmd() {
                      local action host attr

                      [ "$#" -ge 1 ] || usage
                      action="$1"
                      shift

                      case "$action" in
                        build)
                          parse_target_args "$@"
                          case "''${#POSITIONAL[@]}" in
                            0) host="$(default_nixos_host)" ;;
                            1)
                              host="''${POSITIONAL[0]}"
                              require_nixos_host "$host"
                              ;;
                            *) usage ;;
                          esac

                          nom build "$(flake_ref "$FLAKE_MODE")#nixosConfigurations.$host.config.system.build.toplevel"
                          ;;
                        check)
                          parse_target_args "$@"
                          [ "''${#POSITIONAL[@]}" -le 1 ] || usage

                          if [ "''${#POSITIONAL[@]}" -eq 1 ]; then
                            require_nixos_host "''${POSITIONAL[0]}"
                          fi

                          run_nom_nix flake check "$(flake_ref "$FLAKE_MODE")"
                          ;;
                        show)
                          parse_target_args "$@"
                          [ "''${#POSITIONAL[@]}" -le 1 ] || usage

                          if [ "''${#POSITIONAL[@]}" -eq 1 ]; then
                            require_nixos_host "''${POSITIONAL[0]}"
                          fi

                          nix flake show "$(flake_ref "$FLAKE_MODE")"
                          ;;
                        run)
                          parse_target_args "$@"
                          [ "''${#POSITIONAL[@]}" -eq 1 ] || usage
                          attr="''${POSITIONAL[0]}"

                          nom build "$(flake_ref "$FLAKE_MODE")#$attr"
                          nix run "$(flake_ref "$FLAKE_MODE")#$attr"
                          ;;
                        *) die "unknown flake action: $action" ;;
                      esac
                    }

                    clean_cmd() {
                      if [ "$#" -eq 0 ]; then
                        nh clean all --keep 1 --keep-since 0h
                      else
                        nh clean all "$@"
                      fi
                    }

                    ai_cmd() {
                      command -v opencode >/dev/null 2>&1 \
                        || die "opencode not available (build this system with the opencode module)"

                      (cd "$(repo_root)" && exec opencode)
                    }

                    git_cmd() {
                      [ "$#" -eq 0 ] || usage
                      cd "$(repo_root)"

                      if git lg >/dev/null 2>&1; then
                        exec git lg
                      fi

                      exec git log --graph --decorate --oneline --all
                    }

                    reload_shell_cmd() {
                      [ "$#" -eq 0 ] || usage
                      systemctl --user restart newshell
                    }

                    dev_mode_cmd() {
                      [ "$#" -eq 0 ] || usage
                      printf '%s\n' "''${NEWXOS_DEV:-''${DEVMODE:-0}}"
                    }

                    memory_cmd() {
                      local action

                      [ "$#" -ge 1 ] || usage
                      action="$1"
                      shift

                      local repo_root
                      repo_root="$(repo_root)"

                      local memory_root="$repo_root/knowledge"
                      local state_root="$repo_root/.cache/basic-memory"

                      mkdir -p "$memory_root" "$state_root"

                      cat > "$state_root/config.json" <<EOF
          {
            "default_project": "newxos",
            "projects": {
              "newxos": {
                "path": "''$memory_root",
                "mode": "local"
              }
            },
            "semantic_search_enabled": true,
            "semantic_embedding_provider": "fastembed",
            "cloud_mode": false
          }
          EOF

                      export BASIC_MEMORY_CONFIG_DIR="''$state_root"
                      export BASIC_MEMORY_MCP_PROJECT="newxos"
                      export BASIC_MEMORY_SEMANTIC_SEARCH_ENABLED="true"
                      export BASIC_MEMORY_SEMANTIC_EMBEDDING_PROVIDER="fastembed"
                      export BASIC_MEMORY_NO_PROMOS="1"

                      case "$action" in
                        reindex)
                          basic-memory reindex --project newxos
                          ;;
                        reset)
                          printf 'y\n' | basic-memory reset --reindex
                          ;;
                        *) die "unknown memory action: $action" ;;
                      esac
                    }

                    main() {
                      local group

                      [ "$#" -ge 1 ] || usage
                      group="$1"
                      shift

                      case "$group" in
                        build-iso) build_iso_cmd "$@" ;;
                        first-install) first_install_cmd "$@" ;;
                        switch) os_cmd switch "$@" ;;
                        os) os_cmd "$@" ;;
                        home) home_cmd "$@" ;;
                        flake) flake_cmd "$@" ;;
                        memory) memory_cmd "$@" ;;
                        ai) ai_cmd "$@" ;;
                        git) git_cmd "$@" ;;
                        reload_shell) reload_shell_cmd "$@" ;;
                        dev_mode) dev_mode_cmd "$@" ;;
                        clean) clean_cmd "$@" ;;
                        _complete) complete_cmd "$@" ;;
                        -h|--help|help) usage ;;
                        *) die "unknown command group: $group" ;;
                      esac
                    }

                    main "$@"
        '';
      };
    in
    {
      packages.newxos = pkgs.symlinkJoin {
        name = "newxos";
        paths = [
          newxos-bin
          self'.packages.newxos-completions
        ];
        meta.mainProgram = "newxos";
      };
    };
}

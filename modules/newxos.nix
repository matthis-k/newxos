{ withSystem, ... }:
{
  flake.modules.nixos.newxos =
    { config, ... }:
    {
      environment.sessionVariables.NEWXOS_HOST = config.networking.hostName;
    };

  perSystem =
    { pkgs, ... }:
    let
      newxos-bin = pkgs.writeShellApplication {
        name = "newxos";
        runtimeInputs = with pkgs; [
          coreutils
          jq
          nh
          nix
          nix-output-monitor
          ripgrep
        ];
        text = ''
          usage() {
            cat <<'EOF' >&2
          usage: newxos <os|home|flake> ...

            newxos os <switch|boot|build> [host] [--git-only]
            newxos home <switch|build> <config> [--git-only]
            newxos flake build [host] [--git-only]
            newxos flake check [host] [--git-only]
            newxos flake show [host] [--git-only]
            newxos flake run <attr> [--git-only]

          env:
            NEWXOS  repo path. default: $HOME/newxos
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

            root="''${NEWXOS:-$HOME/newxos}"
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

          main() {
            local group

            [ "$#" -ge 1 ] || usage
            group="$1"
            shift

            case "$group" in
              os) os_cmd "$@" ;;
              home) home_cmd "$@" ;;
              flake) flake_cmd "$@" ;;
              _complete) complete_cmd "$@" ;;
              -h|--help|help) usage ;;
              *) die "unknown command group: $group" ;;
            esac
          }

          main "$@"
        '';
      };

      fish-completion = pkgs.writeTextDir "share/fish/vendor_completions.d/newxos.fish" ''
        function __fish_newxos_words
          commandline -opc
        end

        function __fish_newxos_wants_nixos_host
          set -l words (__fish_newxos_words)
          test (count $words) -eq 3; or return 1
          test "$words[2]" = os; or return 1
          contains -- "$words[3]" switch boot build
        end

        function __fish_newxos_wants_home_config
          set -l words (__fish_newxos_words)
          test (count $words) -eq 3; or return 1
          test "$words[2]" = home; or return 1
          contains -- "$words[3]" switch build
        end

        function __fish_newxos_wants_flake_host
          set -l words (__fish_newxos_words)
          test (count $words) -eq 3; or return 1
          test "$words[2]" = flake; or return 1
          contains -- "$words[3]" build check show
        end

        function __fish_newxos_wants_run_target
          set -l words (__fish_newxos_words)
          test (count $words) -eq 3; or return 1
          test "$words[2]" = flake; or return 1
          test "$words[3]" = run
        end

        function __fish_newxos_supports_git_only
          set -l words (__fish_newxos_words)
          test (count $words) -ge 3; or return 1

          switch "$words[2]:$words[3]"
            case 'os:switch' 'os:boot' 'os:build' 'home:switch' 'home:build' 'flake:build' 'flake:check' 'flake:show' 'flake:run'
              return 0
          end

          return 1
        end

        complete -c newxos -f
        complete -c newxos -n 'not __fish_seen_subcommand_from os home flake' -a 'os home flake'
        complete -c newxos -n '__fish_seen_subcommand_from os; and not __fish_seen_subcommand_from switch boot build' -a 'switch boot build'
        complete -c newxos -n '__fish_seen_subcommand_from home; and not __fish_seen_subcommand_from switch build' -a 'switch build'
        complete -c newxos -n '__fish_seen_subcommand_from flake; and not __fish_seen_subcommand_from build check show run' -a 'build check show run'

        complete -c newxos -n '__fish_newxos_wants_nixos_host' -a '(newxos _complete nixos-hosts 2>/dev/null)'
        complete -c newxos -n '__fish_newxos_wants_home_config' -a '(newxos _complete home-configs 2>/dev/null)'
        complete -c newxos -n '__fish_newxos_wants_flake_host' -a '(newxos _complete nixos-hosts 2>/dev/null)'
        complete -c newxos -n '__fish_newxos_wants_run_target' -a '(newxos _complete run-targets 2>/dev/null)'
        complete -c newxos -n '__fish_newxos_supports_git_only; and not __fish_seen_argument -l git-only' -l git-only -d 'Use git flake ref'
      '';
    in
    {
      packages.newxos = pkgs.symlinkJoin {
        name = "newxos";
        paths = [
          newxos-bin
          fish-completion
        ];
        meta.mainProgram = "newxos";
      };
    };

  flake.modules.homeManager.newxos =
    {
      config,
      pkgs,
      ...
    }:
    {
      home.packages = withSystem pkgs.stdenv.hostPlatform.system (
        { self', ... }: [ self'.packages.newxos ]
      );

      home.sessionVariables.NEWXOS = "${config.home.homeDirectory}/newxos";
    };
}

{
  inputs,
  lib,
  self,
  ...
}:
{
  imports = [
    inputs.git-hooks-nix.flakeModule
    inputs.treefmt-nix.flakeModule
  ];

  perSystem =
    {
      config,
      inputs',
      pkgs,
      self',
      ...
    }:
    let
      # ================================================
      # Individual check executables (deterministic,
      # individually runnable, no nested nix run)
      # ================================================

      writeFlake = pkgs.writeShellScriptBin "repo-write-flake" ''
        set -euo pipefail
        ${lib.getExe self'.packages.write-flake}
        if ! git diff --exit-code -- flake.nix; then
          echo "error: flake.nix has uncommitted changes after write-flake; regenerate and commit" >&2
          exit 1
        fi
      '';

      flakeCheck = pkgs.writeShellScriptBin "repo-flake-check" ''
        set -euo pipefail

        nix flake check "path:$PWD"
      '';

      updateDocsIndex = pkgs.writeShellScriptBin "repo-update-docs-index" ''
        set -euo pipefail

        ${lib.getExe' self'.packages.newxos "newxos"} memory reindex
      '';

      repoDoctor = pkgs.writeShellScriptBin "repo-doctor" ''
        set -euo pipefail

        errors=0

        # 10.1 Generated flake is current
        if ! git diff --exit-code -- flake.nix; then
          echo "error: flake.nix has uncommitted changes; run write-flake and commit" >&2
          errors=$((errors + 1))
        fi

        # 10.3 Basic Memory root is consistent
        if ${pkgs.ripgrep}/bin/rg -n 'root\.join\("knowledge"\)' \
          packages modules configs docs \
          --glob '!docs/history/**' --glob '!modules/dev/workflow.nix' 2>/dev/null; then
          echo "error: Basic Memory must use docs/ as project root, not knowledge/" >&2
          errors=$((errors + 1))
        fi

        # 10.4 No stale IPC target names
        if ${pkgs.ripgrep}/bin/rg -n 'applauncher' configs modules packages \
          --glob '!docs/history/**' --glob '!modules/dev/workflow.nix' 2>/dev/null; then
          echo "error: stale applauncher IPC target found; use launcher" >&2
          errors=$((errors + 1))
        fi

        # 10.5 Runtime test packages must use the correct mode for their intended backend.
        if ${pkgs.ripgrep}/bin/rg -n 'runNewshellIpcTestsHyprland' \
          modules/dev/workflow.nix 2>/dev/null \
          && ! ${pkgs.ripgrep}/bin/rg -q 'INSTANCE_MODE=external' \
            modules/dev/workflow.nix; then
          echo "error: hyprland test runner must set NEWSHELL_TEST_INSTANCE_MODE=external" >&2
          errors=$((errors + 1))
        fi

        # 10.6 OpenCode package must not mask eval failure
        if ${pkgs.ripgrep}/bin/rg -n 'builtins\.tryEval' modules/dev/opencode.nix 2>/dev/null; then
          echo "error: opencode wrapper evaluation must fail at evaluation/build time; do not mask with tryEval" >&2
          errors=$((errors + 1))
        fi

        # 10.7 No behavior cases in configs/newshell/launcher/tests/cases/
        if [ -n "$(find "${self}/configs/newshell/launcher/tests/cases" -maxdepth 1 -name '*.json' -print -quit 2>/dev/null)" ]; then
          echo "error: Launcher behavior cases must live in tests/launcher/cases/. jq/debug probes must be derived from canonical cases, not maintained separately." >&2
          errors=$((errors + 1))
        fi

        if [ "$errors" -gt 0 ]; then
          echo "repo-doctor: $errors check(s) failed" >&2
          exit 1
        fi
        echo "repo-doctor: all checks passed"
      '';

      rustCheck = pkgs.writeShellScriptBin "repo-rust" ''
        set -euo pipefail
        cd "${self}/packages/newxos-cli"
        ${pkgs.cargo}/bin/cargo test
      '';

      runNewshellIpcTests = pkgs.writeShellApplication {
        name = "run-newshell-launcher-ipc-tests";
        runtimeInputs = [
          self'.packages.newshell
          pkgs.bash
          pkgs.coreutils
          pkgs.jq
        ];
        text = ''
          set -euo pipefail

          if [ "''${NEWXOS_RUN_NEWSHELL_RUNTIME_TESTS:-0}" != "1" ]; then
            echo "Skipping newshell runtime IPC tests. Set NEWXOS_RUN_NEWSHELL_RUNTIME_TESTS=1 to run."
            exit 0
          fi

          export NEWSHELL_BIN=${lib.getExe self'.packages.newshell}
          exec bash "${self}/configs/newshell/launcher/tests/run-launcher-interaction-ipc-tests.sh"
        '';
      };

      # Hyprland-headless mode: starts a private compositor that launches newshell via exec-once
      # with timeout protection.
      runNewshellIpcTestsHyprland = pkgs.writeShellApplication {
        name = "run-newshell-launcher-ipc-tests-hyprland";
        runtimeInputs = [
          self'.packages.newshell
          self'.packages.newshell-launcher-test
          inputs'.hyprland.packages.hyprland
          pkgs.bash
          pkgs.coreutils
          pkgs.findutils
          pkgs.jq
        ];
        text = ''
          set -euo pipefail

          if [ "''${NEWXOS_RUN_NEWSHELL_RUNTIME_TESTS:-0}" != "1" ]; then
            echo "Skipping newshell runtime IPC tests (hyprland). Set NEWXOS_RUN_NEWSHELL_RUNTIME_TESTS=1 to run."
            exit 0
          fi

          NEWSHELL_BIN=${lib.getExe self'.packages.newshell}
          LAUNCHER_TEST_BIN=${lib.getExe self'.packages.newshell-launcher-test}

          tmp_root="$(mktemp -d)"
          runtime_dir="$tmp_root/runtime"
          hypr_config="$tmp_root/hyprland.conf"
          hypr_log="$tmp_root/hyprland.log"
          ipc_test_log="$tmp_root/newshell-ipc-test.log"
          canonical_log="$tmp_root/newshell-canonical-test.log"

          INSTANCE_ID="newshell-hypr-test-$$-''${RANDOM}"
          IPC_NS="$INSTANCE_ID"

          cleanup() {
            local status=$?

            if [ -n "''${HYPRLAND_PID:-}" ] && kill -0 "$HYPRLAND_PID" 2>/dev/null; then
              kill "$HYPRLAND_PID" 2>/dev/null || true
              wait "$HYPRLAND_PID" 2>/dev/null || true
            fi

            if [ "$status" -ne 0 ]; then
              echo "=== Hyprland log ===" >&2
              cat "$hypr_log" >&2 2>/dev/null || true
              echo "=== newshell IPC test log ===" >&2
              cat "$ipc_test_log" >&2 2>/dev/null || true
              echo "=== canonical case test log ===" >&2
              cat "$canonical_log" >&2 2>/dev/null || true
              echo "=== runtime dir ===" >&2
              ls -la "$runtime_dir" >&2 2>/dev/null || true
              echo "=== generated Hyprland config ===" >&2
              cat "$hypr_config" >&2 2>/dev/null || true
              echo "=== environment ===" >&2
              echo "XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR" >&2
              echo "WAYLAND_DISPLAY=''${WAYLAND_DISPLAY:-}" >&2
              echo "WLR_BACKENDS=''${WLR_BACKENDS:-}" >&2
              echo "QT_QPA_PLATFORM=''${QT_QPA_PLATFORM:-}" >&2
              echo "NEWSHELL_BIN=$NEWSHELL_BIN" >&2
              echo "tmp_root=$tmp_root" >&2
            else
              rm -rf "$tmp_root"
            fi

            exit "$status"
          }
          trap cleanup EXIT INT TERM

          mkdir -p "$runtime_dir"
          chmod 700 "$runtime_dir"

          export XDG_RUNTIME_DIR="$runtime_dir"
          export XDG_SESSION_TYPE=wayland
          export QT_QPA_PLATFORM=wayland
          export WLR_BACKENDS=headless
          export WLR_RENDERER=pixman
          export WLR_LIBINPUT_NO_DEVICES=1

          cat > "$hypr_config" <<EOF
          monitor=,1280x720@60,0x0,1

          misc {
            disable_hyprland_logo = true
            disable_splash_rendering = true
          }

          exec-once = env NEWSHELL_TEST_MODE=1 NEWSHELL_TEST_INSTANCE_ID=$INSTANCE_ID NEWSHELL_IPC_NAMESPACE=$IPC_NS NEWXOS_DEV=0 $NEWSHELL_BIN
          EOF

          Hyprland --config "$hypr_config" >"$hypr_log" 2>&1 &
          HYPRLAND_PID=$!

          wayland_socket=""
          for wait_try in $(seq 1 200); do
            if ! kill -0 "$HYPRLAND_PID" 2>/dev/null; then
              echo "error: Hyprland exited early after ''${wait_try} tries" >&2
              exit 1
            fi

            found="$(find "$XDG_RUNTIME_DIR" -maxdepth 1 -type s -name 'wayland-*' -printf '%f\n' | head -n1 || true)"
            if [ -n "$found" ]; then
              wayland_socket="$found"
              break
            fi

            sleep 0.05
          done

          if [ -z "$wayland_socket" ]; then
            echo "error: no Wayland socket appeared" >&2
            exit 1
          fi

          export WAYLAND_DISPLAY="$wayland_socket"
          export NEWSHELL_TEST_INSTANCE_MODE=external
          export NEWSHELL_TEST_MODE=1
          export NEWSHELL_TEST_INSTANCE_ID="$INSTANCE_ID"
          export NEWSHELL_IPC_NAMESPACE="$IPC_NS"
          export NEWSHELL_BIN="$NEWSHELL_BIN"

          # Run the existing IPC test suite
          echo "=== Running IPC interaction tests ==="
          timeout "''${NEWSHELL_TEST_TIMEOUT_SECONDS:-30}" \
            bash "${self}/configs/newshell/launcher/tests/run-launcher-interaction-ipc-tests.sh" >"$ipc_test_log" 2>&1
          cat "$ipc_test_log"

          # Run canonical cases against the same namespaced instance
          echo ""
          echo "=== Running canonical launcher cases ==="
          timeout "''${NEWSHELL_TEST_TIMEOUT_SECONDS:-30}" \
            $LAUNCHER_TEST_BIN run "${self}/tests/launcher/cases" --mode headless >"$canonical_log" 2>&1
          cat "$canonical_log"
        '';
      };

      # Session mode: test against the currently running user service (manual smoke only)
      runNewshellIpcTestsSession = pkgs.writeShellApplication {
        name = "run-newshell-launcher-ipc-tests-session";
        runtimeInputs = [
          self'.packages.newshell
          pkgs.bash
          pkgs.coreutils
          pkgs.jq
        ];
        text = ''
          set -euo pipefail

          echo "WARNING: Session mode tests against running user service — not isolated, not CI-safe." >&2
          echo "" >&2

          export NEWSHELL_BIN=${lib.getExe self'.packages.newshell}
          export NEWSHELL_TEST_INSTANCE_MODE=session
          exec bash "${self}/configs/newshell/launcher/tests/run-launcher-interaction-ipc-tests.sh"
        '';
      };

      reinstallGitHooks = pkgs.writeShellScriptBin "repo-install-git-hooks" ''
        set -euo pipefail
        # Nested nix run only here — hooks reinstalled on workflow.nix changes only
        nix run "path:$PWD#install-git-hooks"
      '';

      treefmtProjectRoot = lib.cleanSourceWith {
        src = self;
        filter =
          path: type:
          let
            relPath = lib.removePrefix "${self}/" (toString path);
          in
          relPath != ".git" && !lib.hasPrefix ".git/" relPath;
      };
      hyprlandConfigDir = builtins.path {
        name = "hyprland-config";
        path = "${self}/configs/hypr";
      };

      newshellConfigDir = builtins.path {
        name = "newshell-config";
        path = "${self}/configs/newshell";
      };

      checkHyprlandConfig = pkgs.writeShellApplication {
        name = "check-hyprland-config";
        runtimeInputs = [ self'.packages.newxos-hyprland ];
        text = ''
          set -euo pipefail
          "${self'.packages.newxos-hyprland}/bin/Hyprland" --verify-config
        '';
      };

      checkNeovimConfig = pkgs.writeShellApplication {
        name = "check-neovim-config";
        runtimeInputs = [
          self'.packages.nvim
          pkgs.git
          pkgs.gnugrep
        ];
        text = ''
          output=$(nvim --headless -c "quitall!" 2>&1) || true
          if [ -n "$output" ]; then
            echo "$output"
          fi
          if echo "$output" | grep -qiE "error|E[0-9]+:"; then
            echo "Neovim config validation failed"
            exit 1
          fi
        '';
      };

      checkNewshellConfig = pkgs.writeShellApplication {
        name = "check-newshell-config";
        runtimeInputs = [ pkgs.kdePackages.qtdeclarative ];
        text = ''
          set -euo pipefail

          shell_qml="${newshellConfigDir}/shell.qml"

          if [ ! -f "$shell_qml" ]; then
            echo "ERROR: $shell_qml not found"
            exit 1
          fi

          QT_LOGGING_RULES="*.warning=false" qmllint "$shell_qml"

          # Best-effort broader lint (some QML imports may not resolve in this context)
          find "${newshellConfigDir}" -name '*.qml' -print0 | while IFS= read -r -d $'\0' file; do
            QT_LOGGING_RULES="*.warning=false" qmllint "$file" 2>/dev/null || true
          done
        '';
      };

      newshellCasesCheck = pkgs.writeShellApplication {
        name = "repo-newshell-cases";
        runtimeInputs = [
          self'.packages.newshell-launcher-test
          pkgs.bash
          pkgs.coreutils
        ];
        text = ''
          set -euo pipefail
          ${lib.getExe self'.packages.newshell-launcher-test} validate "${self}/tests/launcher/cases"
        '';
      };

      newshellSessionCheck = pkgs.writeShellApplication {
        name = "repo-newshell-session";
        runtimeInputs = [
          self'.packages.newshell
          self'.packages.newshell-launcher-test
          pkgs.bash
          pkgs.coreutils
        ];
        text = ''
          set -euo pipefail

          if ! newshell ipc call query pipeline "?" >/dev/null 2>&1; then
            echo "error: No running newshell instance. Start the service or use newshell-runtime."
            exit 1
          fi

          export NEWSHELL_BIN="${lib.getExe self'.packages.newshell}"
          ${lib.getExe self'.packages.newshell-launcher-test} run "${self}/tests/launcher/cases" --mode headless
        '';
      };

      # ================================================
      # Repo-Gate: selector / orchestrator over checks
      # ================================================

      repoGate = pkgs.writeShellApplication {
        name = "repo-gate";
        runtimeInputs = [
          pkgs.bash
          pkgs.coreutils
          pkgs.git
          pkgs.jq
          pkgs.statix
          writeFlake
          flakeCheck
          repoDoctor
          rustCheck
          checkNewshellConfig
          newshellCasesCheck
          newshellSessionCheck
          runNewshellIpcTestsHyprland
          checkHyprlandConfig
          checkNeovimConfig
          updateDocsIndex
          reinstallGitHooks
          config.treefmt.build.wrapper
        ];
        text = ''
            MODE="normal"
            ARGS=()

            while [[ $# -gt 0 ]]; do
              case "$1" in
                --list|-l)
                  cat <<'LISTEOF'
          Available checks:
            write-flake       regenerate flake.nix and fail on drift
            fmt               run treefmt
            statix            run statix fix/check
            flake-check       run nix flake check
            repo-doctor       run repo invariants
            rust              run newxos-cli Rust tests
            newshell-static   qmllint shell.qml + best-effort lint
            newshell-cases    validate canonical launcher case files (no runtime needed)
            newshell-session  run canonical cases against running service/session
            newshell-runtime  run headless Hyprland newshell IPC + canonical cases (opt-in)
            newshell-probe    derive/debug launcher probes from canonical cases (diagnostic)
            hyprland          verify Hyprland config
            neovim            verify Neovim starts headless
            docs-index        reindex Basic Memory docs
            hooks             reinstall managed git hooks

          Aliases:
            newshell          newshell-static + newshell-cases + newshell-session
            session           newshell-session
            runtime           newshell-runtime
            nix               write-flake + statix + fmt + flake-check
            quick             write-flake + fmt + statix + newshell-static
            all               write-flake + fmt + statix + flake-check + repo-doctor + rust + newshell + hyprland + neovim (includes newshell-session)
            probe             newshell-probe
          LISTEOF
                  exit 0
                  ;;
                --hook)
                  MODE="hook"
                  shift
                  ARGS+=("$1")
                  shift
                  ;;
                --staged)
                  MODE="staged"
                  shift
                  ARGS=("$@")
                  break
                  ;;
                -*)
                  echo "Unknown option: $1" >&2
                  exit 1
                  ;;
                *)
                  ARGS=("$@")
                  break
                  ;;
              esac
            done

            # --hook pre-commit emulates the old behavior: temp index + all checks
            if [ "$MODE" = "hook" ] && [ "''${ARGS[0]}" = "pre-commit" ]; then
              ARGS=("all")
            fi

            if [ "''${#ARGS[@]}" -eq 0 ]; then
              ARGS=("all")
            fi

            # Alias resolution
            resolve_alias() {
              local name="$1"
              case "$name" in
                newshell)  echo "newshell-static newshell-cases newshell-session" ;;
                runtime)   echo "newshell-runtime" ;;
                nix)       echo "write-flake statix fmt flake-check" ;;
                quick)     echo "write-flake fmt statix newshell-static" ;;
                all)       echo "write-flake fmt statix flake-check repo-doctor rust newshell hyprland neovim" ;;
                probe)     echo "newshell-probe" ;;
                session)   echo "newshell-session" ;;
                *)         echo "$name" ;;
              esac
            }

            # Build flat check list
            CHECKS=()
            for arg in "''${ARGS[@]}"; do
              resolved=$(resolve_alias "$arg")
              for check in $resolved; do
                CHECKS+=("$check")
              done
            done

            # Dedup (preserve order)
            unique=()
            for check in "''${CHECKS[@]}"; do
              found=false
              for u in "''${unique[@]}"; do
                [ "$u" = "$check" ] && found=true && break
              done
              $found || unique+=("$check")
            done
            CHECKS=("''${unique[@]}")

            # Staged mode: create temp index with all files
            if [ "$MODE" = "staged" ] || { [ "$MODE" = "hook" ] && [ "''${ARGS[0]}" = "pre-commit" ]; }; then
              real_index="$(git rev-parse --git-path index 2>/dev/null || echo "")"
              temp_index="$(mktemp)"
              trap 'rm -f "$temp_index"' EXIT

              if [ -f "$real_index" ]; then
                cp "$real_index" "$temp_index"
              fi
              GIT_INDEX_FILE="$temp_index" git add -A -- .
              export GIT_INDEX_FILE
            fi

            # Run checks
            FAILED=0
            for check in "''${CHECKS[@]}"; do
              printf "==> %s ... " "$check"

              case "$check" in
                write-flake)
                  repo-write-flake
                  ;;
                fmt)
                  treefmt
                  ;;
                statix)
                  statix fix
                  ;;
                flake-check)
                  repo-flake-check
                  ;;
                repo-doctor)
                  repo-doctor
                  ;;
                rust)
                  repo-rust
                  ;;
                newshell-static)
                  check-newshell-config
                  ;;
                newshell-cases)
                  repo-newshell-cases
                  ;;
                newshell-session)
                  repo-newshell-session
                  ;;
                newshell-probe)
                  ${lib.getExe self'.packages.newshell-launcher-test} list "${self}/tests/launcher/cases"
                  echo ""
                  echo "To derive a probe for a specific case:"
                  echo "  newshell-launcher-test probe tests/launcher/cases --filter <query> --print"
                  echo "  newshell-launcher-test probe tests/launcher/cases --filter <query> --run"
                  ;;
                newshell-runtime)
                  if [ "''${NEWXOS_RUN_NEWSHELL_RUNTIME_TESTS:-0}" != "1" ]; then
                    echo "skipped (set NEWXOS_RUN_NEWSHELL_RUNTIME_TESTS=1 to run)"
                    continue
                  fi
                  run-newshell-launcher-ipc-tests-hyprland
                  ;;
                hyprland)
                  check-hyprland-config
                  ;;
                neovim)
                  check-neovim-config
                  ;;
                docs-index)
                  repo-update-docs-index
                  ;;
                hooks)
                  repo-install-git-hooks
                  ;;
                *)
                  echo "unknown check: $check" >&2
                  exit 1
                  ;;
              esac

              status=$?
              if [ "$status" -ne 0 ]; then
                FAILED=$((FAILED + 1))
                echo "FAIL: $check"
              else
                echo "OK: $check"
              fi
            done

            echo ""
            if [ "$FAILED" -gt 0 ]; then
              echo "repo-gate: $FAILED check(s) failed" >&2
              exit 1
            fi
            echo "repo-gate: all checks passed"
        '';
      };
    in
    {
      pre-commit.check.enable = false;

      treefmt = {
        projectRoot = treefmtProjectRoot;
        projectRootFile = "flake.nix";
        programs.nixfmt.enable = true;
        programs.stylua.enable = true;
      };

      pre-commit.settings.hooks.statix = {
        enable = true;
        after = [ "repo-write-flake" ];
        entry = "${lib.getExe repoGate} --hook statix";
        types = [ "nix" ];
      };

      pre-commit.settings.hooks.repo-write-flake = {
        enable = true;
        name = "write flake";
        description = "Regenerate flake.nix before commit.";
        entry = "${lib.getExe repoGate} --hook write-flake";
        pass_filenames = false;
        always_run = true;
      };

      pre-commit.settings.hooks.repo-write-nvim-pack-lock =
        lib.mkIf (self'.packages ? write-nvim-pack-lock)
          {
            enable = true;
            name = "write nvim pack lockfile";
            description = "Regenerate the Neovim pack lockfile when flake.lock changes.";
            entry = lib.getExe self'.packages.write-nvim-pack-lock;
            after = [ "statix" ];
            files = "^flake\\.lock$";
            pass_filenames = false;
          };

      pre-commit.settings.hooks.repo-fmt = {
        enable = true;
        name = "format repo";
        description = "Format the repo after generated files are refreshed.";
        entry = "${lib.getExe repoGate} --hook fmt";
        after = [
          "statix"
        ]
        ++ lib.optional (self'.packages ? write-nvim-pack-lock) "repo-write-nvim-pack-lock";
        pass_filenames = false;
        always_run = true;
      };

      pre-commit.settings.hooks.repo-flake-check = {
        enable = true;
        name = "flake check";
        description = "Run flake checks after formatting when staged Nix files changed.";
        entry = "${lib.getExe repoGate} --hook flake-check";
        after = [ "repo-fmt" ];
        pass_filenames = false;
        types = [ "nix" ];
      };

      pre-commit.settings.hooks.repo-update-docs-index = {
        enable = true;
        name = "update docs index";
        description = "Reindex Basic Memory when docs files change.";
        entry = "${lib.getExe repoGate} --hook docs-index";
        after = [ "repo-fmt" ];
        files = "^docs/";
        pass_filenames = false;
      };

      pre-commit.settings.hooks.repo-install-git-hooks = {
        enable = true;
        name = "install git hooks";
        description = "Reinstall managed git hooks when the workflow module changes.";
        entry = "${lib.getExe repoGate} --hook hooks";
        after = [
          "repo-flake-check"
          "repo-update-docs-index"
        ];
        files = "^modules/dev/workflow\\.nix$";
        pass_filenames = false;
      };

      pre-commit.settings.hooks.check-hyprland-config = {
        enable = true;
        name = "check hyprland config";
        description = "Verify Hyprland Lua config parses without errors.";
        entry = "${lib.getExe repoGate} --hook hyprland";
        files = "^configs/hypr/";
        pass_filenames = false;
      };

      pre-commit.settings.hooks.check-neovim-config = {
        enable = true;
        name = "check neovim config";
        description = "Verify Neovim starts without errors in headless mode.";
        entry = "${lib.getExe repoGate} --hook neovim";
        files = "^configs/nvim/";
        pass_filenames = false;
      };

      pre-commit.settings.hooks.check-newshell-config = {
        enable = true;
        name = "check newshell config";
        description = "Verify newshell shell.qml passes qmllint; best-effort lint for other QML files (some imports may not resolve in CI).";
        entry = "${lib.getExe repoGate} --hook newshell-static";
        files = "^configs/newshell/";
        pass_filenames = false;
      };

      devShells.default = config.pre-commit.devShell;

      packages.fmt = config.treefmt.build.wrapper;
      packages.install-git-hooks = pkgs.writeShellScriptBin "install-git-hooks" ''
        set -euo pipefail
        ${config.pre-commit.installationScript}
      '';
      packages.repo-gate = repoGate;
      packages.repo-doctor = repoDoctor;
      packages.repo-rust = rustCheck;
      packages.repo-write-flake = writeFlake;
      packages.repo-flake-check = flakeCheck;
      packages.repo-newshell-cases = newshellCasesCheck;
      packages.repo-newshell-session = newshellSessionCheck;
      packages.repo-update-docs-index = updateDocsIndex;
      packages.repo-install-git-hooks = reinstallGitHooks;
      packages.run-newshell-launcher-ipc-tests = runNewshellIpcTests;
      packages.run-newshell-launcher-ipc-tests-hyprland = runNewshellIpcTestsHyprland;
      packages.run-newshell-launcher-ipc-tests-session = runNewshellIpcTestsSession;

      # Static checks that can run in nix flake check
      checks.repo-doctor =
        pkgs.runCommand "repo-doctor-check"
          {
            nativeBuildInputs = with pkgs; [ ripgrep ];
          }
          ''
                errors=0
                cd ${self}

                # 10.3 Basic Memory root is consistent
                if rg -n 'root\.join\("knowledge"\)' \
                  packages modules configs docs \
                  --glob '!docs/history/**' --glob '!modules/dev/workflow.nix' 2>/dev/null; then
                  echo "error: Basic Memory must use docs/ as project root, not knowledge/" >&2
                  errors=$((errors + 1))
                fi

                # 10.4 No stale IPC target names
                if rg -n 'applauncher' configs modules packages \
                  --glob '!docs/history/**' --glob '!modules/dev/workflow.nix' 2>/dev/null; then
                  echo "error: stale applauncher IPC target found; use launcher" >&2
                  errors=$((errors + 1))
                fi

                # 10.5 Runtime test packages must use the correct mode for their intended backend.
                if rg -n 'runNewshellIpcTestsHyprland' modules/dev/workflow.nix 2>/dev/null \
                  && ! rg -q 'INSTANCE_MODE=external' modules/dev/workflow.nix; then
                  echo "error: hyprland test runner must set NEWSHELL_TEST_INSTANCE_MODE=external" >&2
                  errors=$((errors + 1))
                fi

            # 10.6 profile.inherit is not supported; use originGroup: "inherited" on evidence
            if rg 'inherit\s*:' configs/newshell/launcher 2>/dev/null; then
              echo "ERROR: profile.inherit is not supported. Use evidence originGroup instead." >&2
              errors=$((errors + 1))
            fi

            # 10.7 No behavior cases in configs/newshell/launcher/tests/cases/
            if [ -n "$(find configs/newshell/launcher/tests/cases -maxdepth 1 -name '*.json' -print -quit 2>/dev/null)" ]; then
              echo "error: Launcher behavior cases must live in tests/launcher/cases/. jq/debug probes must be derived from canonical cases, not maintained separately." >&2
              errors=$((errors + 1))
            fi

            # 10.6 OpenCode package must not mask eval failure
            if rg -n 'builtins\.tryEval' modules/dev/opencode.nix 2>/dev/null; then
              echo "error: opencode wrapper evaluation must fail at evaluation/build time; do not mask with tryEval" >&2
              errors=$((errors + 1))
            fi

            if [ "$errors" -gt 0 ]; then
                  echo "repo-doctor: $errors check(s) failed" >&2
                  exit 1
                fi
                echo "repo-doctor: all checks passed"
                touch $out
          '';

      # Newxos CLI tests (Rust unit tests)
      checks.newxos-cli-tests = self'.packages.newxos-cli.overrideAttrs (old: {
        doCheck = true;
      });

      # Enhance newshell static check to lint all .qml files (uses same logic as hook)
      checks.check-newshell-static = checkNewshellConfig;

      # Explicit check for Hyprland config
      checks.check-hyprland-config = checkHyprlandConfig;

      # Explicit check for Neovim config
      checks.check-neovim-config = checkNeovimConfig;
    };
}

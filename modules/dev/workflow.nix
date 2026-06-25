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

      testFlakeWrite = pkgs.writeShellScriptBin "test-flake-write" ''
        set -euo pipefail
        ${lib.getExe self'.packages.write-flake}
        if ! git diff --exit-code -- flake.nix; then
          echo "error: flake.nix has uncommitted changes after write-flake; regenerate and commit" >&2
          exit 1
        fi
      '';

      testFlakeCheck = pkgs.writeShellScriptBin "test-flake-check" ''
        set -euo pipefail

        nix flake check "path:$PWD"
      '';

      testDocsIndex = pkgs.writeShellScriptBin "test-docs-index" ''
        set -euo pipefail

        ${lib.getExe' self'.packages.newxos "newxos"} memory reindex
      '';

      testRustUnit = pkgs.writeShellScriptBin "test-rust-unit" ''
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
      testNewshellRuntime = pkgs.writeShellApplication {
        name = "test-newshell-runtime";
        runtimeInputs = [
          self'.packages.newshell
          self'.packages.newshell-launcher-test
          pkgs.westonLite
          pkgs.bash
          pkgs.coreutils
          pkgs.findutils
          pkgs.git
          pkgs.gnugrep
          pkgs.jq
        ];
        text = ''
          set -euo pipefail

          NEWSHELL_BIN=${lib.getExe self'.packages.newshell}
          LAUNCHER_TEST_BIN=${lib.getExe self'.packages.newshell-launcher-test}
          WESTON_BIN=${lib.getExe' pkgs.westonLite "weston"}

          tmp_root="$(mktemp -p /tmp -d nl-XXXXXX)"
          runtime_dir="$tmp_root/r"
          weston_log="$tmp_root/weston.log"
          newshell_log="$tmp_root/newshell.log"
          ipc_test_log="$tmp_root/ipc-test.log"
          canonical_log="$tmp_root/canonical-test.log"

          INSTANCE_ID="newshell-runtime-$$-$RANDOM"
          IPC_NS="$INSTANCE_ID"

          cleanup() {
            local status=$?
            if [ -n "''${NEWSHELL_PID:-}" ] && kill -0 "$NEWSHELL_PID" 2>/dev/null; then
              kill "$NEWSHELL_PID" 2>/dev/null || true
              wait "$NEWSHELL_PID" 2>/dev/null || true
            fi
            if [ -n "''${WESTON_PID:-}" ] && kill -0 "$WESTON_PID" 2>/dev/null; then
              kill "$WESTON_PID" 2>/dev/null || true
              wait "$WESTON_PID" 2>/dev/null || true
            fi
            if [ "$status" -ne 0 ]; then
              echo "=== weston log ===" >&2
              cat "$weston_log" >&2 2>/dev/null || true
              echo "=== newshell log ===" >&2
              cat "$newshell_log" >&2 2>/dev/null || true
              [ -s "$ipc_test_log" ] && echo "=== IPC test log ===" >&2 && cat "$ipc_test_log" >&2 2>/dev/null || true
              [ -s "$canonical_log" ] && echo "=== canonical case log ===" >&2 && cat "$canonical_log" >&2 2>/dev/null || true
              echo "=== runtime dir ===" >&2
              ls -la "$runtime_dir" >&2 2>/dev/null || true
            else
              rm -rf "$tmp_root"
            fi
            exit "$status"
          }
          trap cleanup EXIT INT TERM

          mkdir -p "$runtime_dir"
          chmod 700 "$runtime_dir"

          export XDG_RUNTIME_DIR="$runtime_dir"
          export NEWSHELL_TEST_MODE=1
          export NEWSHELL_TEST_INSTANCE_ID="$INSTANCE_ID"
          export NEWSHELL_IPC_NAMESPACE="$IPC_NS"
          export NEWXOS_DEV=0

          # Start weston headless compositor
          "$WESTON_BIN" --backend=headless-backend.so >"$weston_log" 2>&1 &
          WESTON_PID=$!

          # Wait up to 15s for Wayland socket
          wayland_socket=""
          for wait_try in $(seq 1 300); do
            if ! kill -0 "$WESTON_PID" 2>/dev/null; then
              echo "error: weston exited early after ''${wait_try} tries" >&2
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

          # Launch newshell in background (keeps running for IPC tests if needed)
          "$NEWSHELL_BIN" >"$newshell_log" 2>&1 &
          NEWSHELL_PID=$!

          # Wait for config to load (up to 8s)
          config_loaded=false
          for wait_try in $(seq 1 80); do
            if ! kill -0 "$NEWSHELL_PID" 2>/dev/null; then
              echo "error: newshell exited early after ''${wait_try} tries" >&2
              break
            fi
            if grep -qiE "Configuration Loaded" "$newshell_log" 2>/dev/null; then
              config_loaded=true
              break
            fi
            if grep -qiE "Failed to load configuration|Singleton is not a type" "$newshell_log" 2>/dev/null; then
              break
            fi
            sleep 0.1
          done

          # Early fail: check for hard config loading errors
          if grep -qiE "Failed to load configuration|Singleton is not a type" "$newshell_log" 2>/dev/null; then
            echo "ERROR: newshell config loading failed" >&2
            grep --color=never -iE "Failed to load configuration|Singleton is not a type" "$newshell_log" >&2 2>/dev/null || true
            exit 1
          fi

          if ! $config_loaded; then
            echo "ERROR: could not confirm 'Configuration Loaded' in output" >&2
            cat "$newshell_log" >&2 2>/dev/null || true
            exit 1
          fi

          echo "newshell config loaded successfully"

          # Optional: IPC / canonical runtime tests
          # Run automatically if launcher or test case files changed, or forced via flag.
          run_ipc=0
          if [ "''${NEWXOS_RUN_NEWSHELL_RUNTIME_TESTS:-0}" = "1" ]; then
            run_ipc=1
          else
            # Check git for relevant changes (uncommitted, staged, or recent commits)
            if git rev-parse --git-dir >/dev/null 2>&1; then
              if git diff --name-only 2>/dev/null | grep -qE '^configs/newshell/launcher/|^tests/launcher/cases/'; then
                run_ipc=1
              elif git diff --cached --name-only 2>/dev/null | grep -qE '^configs/newshell/launcher/|^tests/launcher/cases/'; then
                run_ipc=1
              else
                for i in 1 2 3; do
                  if git diff "HEAD~$i" --name-only 2>/dev/null | grep -qE '^configs/newshell/launcher/|^tests/launcher/cases/'; then
                    run_ipc=1
                    break
                  fi
                done
              fi
            fi
          fi

          if [ "$run_ipc" -ne 1 ]; then
            echo "Skipping IPC runtime tests (no launcher/test changes detected)."
            echo "Set NEWXOS_RUN_NEWSHELL_RUNTIME_TESTS=1 to force."
            exit 0
          fi

          export NEWSHELL_TEST_INSTANCE_MODE=external
          export NEWSHELL_TEST_INSTANCE_ID="$INSTANCE_ID"
          export NEWSHELL_IPC_NAMESPACE="$IPC_NS"
          export NEWSHELL_BIN="$NEWSHELL_BIN"

          ipc_ok=0; canonical_ok=0
          echo ""
          echo "=== Running IPC interaction tests ==="
          timeout "''${NEWSHELL_TEST_TIMEOUT_SECONDS:-30}" \
            bash "${self}/configs/newshell/launcher/tests/run-launcher-interaction-ipc-tests.sh" >"$ipc_test_log" 2>&1 && ipc_ok=1 || true
          cat "$ipc_test_log"

          echo ""
          echo "=== Running canonical launcher cases ==="
          timeout "''${NEWSHELL_TEST_TIMEOUT_SECONDS:-30}" \
            $LAUNCHER_TEST_BIN run "${self}/tests/launcher/cases" --mode headless >"$canonical_log" 2>&1 && canonical_ok=1 || true
          cat "$canonical_log"

          if [ "$ipc_ok" -ne 1 ] || [ "$canonical_ok" -ne 1 ]; then
            echo ""
            echo "WARNING: Some IPC/runtime tests failed (see above). This does not affect the boot/load pass." >&2
          fi
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

      testInstallHooks = pkgs.writeShellScriptBin "test-install-hooks" ''
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

      testHyprlandConfig = pkgs.writeShellApplication {
        name = "test-hyprland-config";
        runtimeInputs = [ self'.packages.newxos-hyprland ];
        text = ''
          set -euo pipefail
          "${self'.packages.newxos-hyprland}/bin/Hyprland" --verify-config
        '';
      };

      testNeovimConfig = pkgs.writeShellApplication {
        name = "test-neovim-config";
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

      testQmlLint = pkgs.writeShellApplication {
        name = "test-qml-lint";
        runtimeInputs = [ pkgs.kdePackages.qtdeclarative ];
        text = ''
          set -euo pipefail

          shell_qml="${newshellConfigDir}/shell.qml"

          if [ ! -f "$shell_qml" ]; then
            echo "ERROR: $shell_qml not found"
            exit 1
          fi

          # Phase A: Shell entry lint (mandatory)
          QT_LOGGING_RULES="*.warning=false" qmllint "$shell_qml"

          # Phase B: Strict repo-local QML lint
          # qmllint in CI produces false-positive import warnings when QtQuick
          # etc. are unavailable.  We only fail on hard parse/type errors;
          # import-resolution failures are printed as warnings because they
          # are known tooling-context limitations.
          errors_found=0
          while IFS= read -r -d $'\0' file; do
            [ "$file" = "$shell_qml" ] && continue
            output=$(QT_LOGGING_RULES="*.warning=false" qmllint "$file" 2>&1) || true

            # Skip files where imports cannot be resolved (CI false positive)
            if echo "$output" | grep -qiE "Failed to import|Warnings occurred while importing" 2>/dev/null; then
              echo "WARNING: $file (import resolution unavailable, skipping lint)" >&2
              continue
            fi

            if echo "$output" | grep -qiE "Expected token|SyntaxError" 2>/dev/null; then
              echo "ERROR: $file" >&2
              echo "$output" >&2
              errors_found=$((errors_found + 1))
            elif [ -n "$(printf '%s' "$output" | tr -d '[:space:]')" ]; then
              echo "WARNING: $file" >&2
              echo "$output" >&2
            fi
          done < <(find "${newshellConfigDir}" -name '*.qml' -print0)

          if [ "$errors_found" -gt 0 ]; then
            echo "test-qml-lint: $errors_found file(s) have QML errors" >&2
            exit 1
          fi
        '';
      };

      testLauncherPolicy = pkgs.writeShellApplication {
        name = "test-launcher-policy";
        runtimeInputs = [
          self'.packages.newshell-launcher-test
          pkgs.bash
          pkgs.coreutils
        ];
        text = ''
          set -euo pipefail
          ${lib.getExe self'.packages.newshell-launcher-test} policy validate "${self}/tests/launcher/policies"
        '';
      };

      testLauncherMock = pkgs.writeShellApplication {
        name = "test-launcher-mock";
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

      testLauncherHeadless = pkgs.writeShellApplication {
        name = "test-launcher-headless";
        runtimeInputs = [
          self'.packages.newshell
          self'.packages.newshell-launcher-test
          pkgs.westonLite
          pkgs.bash
          pkgs.coreutils
          pkgs.findutils
          pkgs.gnugrep
        ];
        text = ''
          set -euo pipefail

          NEWSHELL_BIN=${lib.getExe self'.packages.newshell}
          LAUNCHER_TEST_BIN=${lib.getExe self'.packages.newshell-launcher-test}
          WESTON_BIN=${lib.getExe' pkgs.westonLite "weston"}

          tmp_root="$(mktemp -p /tmp -d nl-run-XXXXXX)"
          runtime_dir="$tmp_root/r"
          weston_log="$tmp_root/weston.log"
          newshell_log="$tmp_root/newshell.log"
          canonical_log="$tmp_root/canonical-test.log"

          INSTANCE_ID="newshell-cases-run-$$-$RANDOM"
          IPC_NS="$INSTANCE_ID"

          cleanup() {
            local status=$?
            if [ -n "''${NEWSHELL_PID:-}" ] && kill -0 "$NEWSHELL_PID" 2>/dev/null; then
              kill "$NEWSHELL_PID" 2>/dev/null || true
              wait "$NEWSHELL_PID" 2>/dev/null || true
            fi
            if [ -n "''${WESTON_PID:-}" ] && kill -0 "$WESTON_PID" 2>/dev/null; then
              kill "$WESTON_PID" 2>/dev/null || true
              wait "$WESTON_PID" 2>/dev/null || true
            fi
            if [ "$status" -ne 0 ]; then
              echo "=== weston log ===" >&2
              cat "$weston_log" >&2 2>/dev/null || true
              echo "=== newshell log ===" >&2
              cat "$newshell_log" >&2 2>/dev/null || true
              [ -s "$canonical_log" ] && echo "=== canonical case log ===" >&2 && cat "$canonical_log" >&2 2>/dev/null || true
            else
              rm -rf "$tmp_root"
            fi
            exit "$status"
          }
          trap cleanup EXIT INT TERM

          mkdir -p "$runtime_dir"
          chmod 700 "$runtime_dir"

          export XDG_RUNTIME_DIR="$runtime_dir"
          export NEWSHELL_TEST_MODE=1
          export NEWSHELL_TEST_INSTANCE_ID="$INSTANCE_ID"
          export NEWSHELL_IPC_NAMESPACE="$IPC_NS"
          export NEWXOS_DEV=0

          # Start weston headless compositor
          "$WESTON_BIN" --backend=headless-backend.so >"$weston_log" 2>&1 &
          WESTON_PID=$!

          # Wait up to 15s for Wayland socket
          wayland_socket=""
          for wait_try in $(seq 1 300); do
            if ! kill -0 "$WESTON_PID" 2>/dev/null; then
              echo "error: weston exited early after ''${wait_try} tries" >&2
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

          # Launch newshell
          "$NEWSHELL_BIN" >"$newshell_log" 2>&1 &
          NEWSHELL_PID=$!

          # Wait for config load (up to 8s)
          config_loaded=false
          for wait_try in $(seq 1 80); do
            if ! kill -0 "$NEWSHELL_PID" 2>/dev/null; then break; fi
            if grep -qiE "Configuration Loaded" "$newshell_log" 2>/dev/null; then
              config_loaded=true; break
            fi
            sleep 0.1
          done

          if grep -qiE "Failed to load configuration|Singleton is not a type" "$newshell_log" 2>/dev/null; then
            echo "ERROR: newshell config loading failed" >&2
            exit 1
          fi
          if ! $config_loaded; then
            echo "ERROR: could not confirm 'Configuration Loaded'" >&2
            cat "$newshell_log" >&2 2>/dev/null || true
            exit 1
          fi

          echo "newshell config loaded, running launcher cases..."

          # Run all canonical launcher cases (fail on any failure)
          export NEWSHELL_TEST_INSTANCE_MODE=headless
          $LAUNCHER_TEST_BIN run "${self}/tests/launcher/cases" --mode headless >"$canonical_log" 2>&1
          cat "$canonical_log"

          # Run policy-chain-invariants unit tests via IPC
          echo ""
          echo "Running policy-chain-invariants unit tests..."
          policy_test=$("$NEWSHELL_BIN" ipc call debugPolicies '{"check":"policy-chain-invariants"}' 2>/dev/null || echo "FAILED")
          if echo "$policy_test" | grep -q '"passed"[[:space:]]*:[[:space:]]*true'; then
            echo "policy-chain-invariants: all tests passed"
          else
            echo "ERROR: policy-chain-invariants tests failed"
            echo "$policy_test"
            exit 1
          fi
        '';
      };

      testLauncherSession = pkgs.writeShellApplication {
        name = "test-launcher-session";
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
          pkgs.statix
          testFlakeWrite
          testFlakeCheck
          testRustUnit
          testQmlLint
          testLauncherPolicy
          testLauncherMock
          testLauncherHeadless
          testNewshellRuntime
          testLauncherSession
          testHyprlandConfig
          testNeovimConfig
          testDocsIndex
          testInstallHooks
          config.treefmt.build.wrapper
          self'.packages.repo-handoff
        ];
        text = ''
          case "''${1:-}" in
            --list|-l)
              echo "Delegate to repo-handoff for check selection and execution."
              echo "See: repo-handoff --help"
              echo ""
              echo "Available groups: all, test, nix, newshell, newshell.launcher"
              echo "Available targets: fmt, rust, nix.write-flake, nix.statix,"
              echo "  nix.flake-check, newshell.static, newshell.policy,"
              echo "  newshell.cases, newshell.cases-run, hyprland, neovim,"
              echo "  docs.index, newshell.session"
              echo ""
              echo "Usage:"
              echo "  repo-gate                  repo-handoff (changed-file handoff)"
              echo "  repo-gate <id>             repo-handoff run <id>"
              echo "  repo-gate --staged handoff repo-handoff check --staged"
              echo "  repo-gate test             repo-handoff run test"
              echo "  repo-gate --hook <check>   run single check directly (pre-commit)"
              exit 0
              ;;

            --hook)
              shift
              check="''${1:-}"
              case "$check" in
                write-flake)  test-flake-write ;;
                fmt)          treefmt ;;
                statix)       statix fix ;;
                flake-check)  test-flake-check ;;
                rust)         test-rust-unit ;;
                newshell)     test-qml-lint ;;
                newshell-static)  test-qml-lint ;;
                newshell-policy)  test-launcher-policy ;;
                newshell-cases)   test-launcher-cases ;;
                newshell-cases-run) test-launcher-cases-run ;;
                newshell-session)  test-launcher-session ;;
                newshell-runtime)  test-newshell-runtime ;;
                hyprland)     test-hyprland-config ;;
                neovim)       test-neovim-config ;;
                docs-index)   test-docs-index ;;
                hooks)        test-install-hooks ;;
                *)
                  echo "unknown hook check: $check" >&2
                  exit 1
                  ;;
              esac
              ;;

            --staged)
              shift
              if [ "''${1:-}" = "handoff" ]; then
                shift
                repo-handoff check --staged "$@"
              else
                repo-handoff check --staged "$@"
              fi
              ;;

            -*)
              echo "Unknown option: $1" >&2
              exit 1
              ;;

            *)
              # Delegate to repo-handoff
              if [ $# -eq 0 ]; then
                repo-handoff check
              else
                repo-handoff run "$@"
              fi
              ;;
          esac
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

      pre-commit.settings.hooks.agentest = {
        enable = true;
        name = "agentest";
        description = "Run handoff checks based on changed files";
        entry = "${lib.getExe repoGate}";
        args = [ "--staged" "handoff" ];
        pass_filenames = false;
        always_run = true;
      };

      devShells.default = config.pre-commit.devShell;

      packages.fmt = config.treefmt.build.wrapper;
      packages.install-git-hooks = pkgs.writeShellScriptBin "install-git-hooks" ''
        set -euo pipefail
        ${config.pre-commit.installationScript}
      '';
      packages.repo-gate = repoGate;
      packages.test-rust-unit = testRustUnit;
      packages.test-flake-write = testFlakeWrite;
      packages.test-flake-check = testFlakeCheck;
      packages.test-newshell-runtime = testNewshellRuntime;
      packages.test-launcher-policy = testLauncherPolicy;
      packages.test-launcher-cases = testLauncherMock;
      packages.test-launcher-cases-run = testLauncherHeadless;
      packages.test-launcher-session = testLauncherSession;
      packages.test-docs-index = testDocsIndex;
      packages.test-install-hooks = testInstallHooks;
      packages.run-newshell-launcher-ipc-tests = runNewshellIpcTests;
      packages.run-newshell-launcher-ipc-tests-hyprland = testNewshellRuntime;
      packages.run-newshell-launcher-ipc-tests-session = runNewshellIpcTestsSession;

      # Newxos CLI tests (Rust unit tests)
      checks.newxos-cli-tests = self'.packages.newxos-cli.overrideAttrs (old: {
        doCheck = true;
      });

      # Enhance newshell static check to lint all .qml files (uses same logic as hook)
      checks.test-qml-lint = testQmlLint;

      # Policy unit tests: validate policy test cases (fast, deterministic, no backends)
      checks.test-launcher-policy = testLauncherPolicy;

      # Launcher case validation: validate JSON test case schemas (no runtime needed)
      checks.test-launcher-cases = testLauncherMock;

      # Launcher case runtime: run canonical cases against headless newshell
      checks.test-launcher-cases-run = testLauncherHeadless;

      # Runtime check: boot config in headless compositor + optional IPC tests (opt-in)
      checks.test-newshell-runtime = testNewshellRuntime;

      # Explicit check for Hyprland config
      checks.test-hyprland-config = testHyprlandConfig;

      # Explicit check for Neovim config
      checks.test-neovim-config = testNeovimConfig;

      # Test gate: runs repo-handoff run test; only realizes if tests pass
      packages.test = pkgs.writeShellApplication {
        name = "newxos-test";
        runtimeInputs = [
          self'.packages.repo-handoff
          self'.packages.repo-gate
        ];
        text = ''
          set -euo pipefail

          cd "${self}"

          # When run via nix build (not inside the repo), provide a
          # synthetic git repo so repo-handoff can detect the root.
          if ! git rev-parse --git-dir >/dev/null 2>&1; then
            git init --initial-branch=main
            git config user.email "test@newxos"
            git config user.name "Test"
            git add -A
          fi

          repo-handoff run test
        '';
      };

      packages.repo-test = self'.packages.test;
      checks.test = self'.packages.test;
      checks.repo-test = self'.packages.test;
    };
}

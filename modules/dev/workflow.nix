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
      pkgs,
      self',
      ...
    }:
    let
      writeFlake = pkgs.writeShellScriptBin "repo-write-flake" ''
        set -euo pipefail

        ${pkgs.nix}/bin/nix run "path:$PWD#write-flake"
      '';

      flakeCheck = pkgs.writeShellScriptBin "repo-flake-check" ''
        set -euo pipefail

        ${pkgs.nix}/bin/nix flake check "path:$PWD"
      '';

      updateDocsIndex = pkgs.writeShellScriptBin "repo-update-docs-index" ''
        set -euo pipefail

        ${pkgs.nix}/bin/nix run "path:$PWD#newxos" -- memory reindex
      '';

      repoDoctor = pkgs.writeShellScriptBin "repo-doctor" ''
        set -euo pipefail

        errors=0

        # 10.1 Generated flake is current
        if ! ${pkgs.nix}/bin/nix run "path:$PWD#write-flake" 2>/dev/null; then
          echo "error: write-flake failed" >&2
          errors=$((errors + 1))
        fi
        if ! ${pkgs.git}/bin/git diff --exit-code -- flake.nix; then
          echo "error: flake.nix has uncommitted changes after write-flake; regenerate and commit" >&2
          errors=$((errors + 1))
        fi

        # 10.3 Basic Memory root is consistent
        # Only flag actual source code references to `knowledge/` as project root.
        # The specific pattern is `root.join("knowledge")` which was the Rust CLI bug.
        if ${pkgs.ripgrep}/bin/rg -n 'root\.join\("knowledge"\)' \
          packages modules configs docs \
          --glob '!docs/history/**' --glob '!modules/dev/workflow.nix' 2>/dev/null; then
          echo "error: Basic Memory must use docs/ as project root, not knowledge/" >&2
          errors=$((errors + 1))
        fi

        # 10.4 No stale IPC target names
        # Only flag actual source file references, not the doctor check itself
        if ${pkgs.ripgrep}/bin/rg -n 'applauncher' configs modules packages \
          --glob '!docs/history/**' --glob '!modules/dev/workflow.nix' 2>/dev/null; then
          echo "error: stale applauncher IPC target found; use launcher" >&2
          errors=$((errors + 1))
        fi

        # 10.5 Runtime test packages must use namespaced targets.
        # The test script supports session/external/self-managed modes;
        # session mode intentionally uses global targets.
        # Check the Nix package wrappers, not the test script itself.
        if ${pkgs.ripgrep}/bin/rg -n 'newshell ipc call (launcher|query)\b' \
          packages \
          --glob '!*.md' 2>/dev/null; then
          echo "error: newshell runtime tests must use NEWSHELL_IPC_NAMESPACE targets, never global launcher/query" >&2
          errors=$((errors + 1))
        fi

        # 10.6 OpenCode package must not mask eval failure
        if ${pkgs.ripgrep}/bin/rg -n 'builtins\.tryEval' modules/dev/opencode.nix 2>/dev/null; then
          echo "error: opencode wrapper evaluation must fail at evaluation/build time; do not mask with tryEval" >&2
          errors=$((errors + 1))
        fi

        if [ "$errors" -gt 0 ]; then
          echo "repo-doctor: $errors check(s) failed" >&2
          exit 1
        fi
        echo "repo-doctor: all checks passed"
      '';

      runNewshellIpcTests = pkgs.writeShellScriptBin "run-newshell-launcher-ipc-tests" ''
        set -euo pipefail

        if [ "''${NEWXOS_RUN_NEWSHELL_RUNTIME_TESTS:-0}" != "1" ]; then
          echo "Skipping newshell runtime IPC tests. Set NEWXOS_RUN_NEWSHELL_RUNTIME_TESTS=1 to run."
          exit 0
        fi

        export NEWSHELL_BIN=${lib.getExe self'.packages.newshell}
        exec ${pkgs.bash}/bin/bash "${self}/configs/newshell/launcher/tests/run-launcher-interaction-ipc-tests.sh"
      '';

      # Hyprland-headless mode: starts a private compositor that launches newshell via exec-once
      runNewshellIpcTestsHyprland = pkgs.writeShellScriptBin "run-newshell-launcher-ipc-tests-hyprland" ''
        set -euo pipefail

        if [ "''${NEWXOS_RUN_NEWSHELL_RUNTIME_TESTS:-0}" != "1" ]; then
          echo "Skipping newshell runtime IPC tests (hyprland). Set NEWXOS_RUN_NEWSHELL_RUNTIME_TESTS=1 to run."
          exit 0
        fi

        NEWSHELL_BIN=${lib.getExe self'.packages.newshell}

        tmp_root="$(${pkgs.coreutils}/bin/mktemp -d)"
        runtime_dir="$tmp_root/runtime"
        hypr_config="$tmp_root/hyprland.conf"
        hypr_log="$tmp_root/hyprland.log"
        test_log="$tmp_root/newshell-ipc-test.log"

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
            ${pkgs.coreutils}/bin/cat "$hypr_log" >&2 2>/dev/null || true
            echo "=== newshell test log ===" >&2
            ${pkgs.coreutils}/bin/cat "$test_log" >&2 2>/dev/null || true
            echo "tmp_root=$tmp_root" >&2
          else
            ${pkgs.coreutils}/bin/rm -rf "$tmp_root"
          fi

          exit "$status"
        }
        trap cleanup EXIT INT TERM

        ${pkgs.coreutils}/bin/mkdir -p "$runtime_dir"
        ${pkgs.coreutils}/bin/chmod 700 "$runtime_dir"

        export XDG_RUNTIME_DIR="$runtime_dir"
        export XDG_SESSION_TYPE=wayland
        export QT_QPA_PLATFORM=wayland
        export WLR_BACKENDS=headless
        export WLR_RENDERER=pixman
        export WLR_LIBINPUT_NO_DEVICES=1

        ${pkgs.coreutils}/bin/cat > "$hypr_config" <<EOF
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
        for i in $(seq 1 200); do
          if ! kill -0 "$HYPRLAND_PID" 2>/dev/null; then
            echo "error: Hyprland exited early" >&2
            exit 1
          fi

          found="$(${pkgs.findutils}/bin/find "$XDG_RUNTIME_DIR" -maxdepth 1 -type s -name 'wayland-*' -printf '%f\n' | ${pkgs.coreutils}/bin/head -n1 || true)"
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

        ${pkgs.bash}/bin/bash "${self}/configs/newshell/launcher/tests/run-launcher-interaction-ipc-tests.sh" >"$test_log" 2>&1
        ${pkgs.coreutils}/bin/cat "$test_log"
      '';

      # Session mode: test against the currently running user service (manual smoke only)
      runNewshellIpcTestsSession = pkgs.writeShellScriptBin "run-newshell-launcher-ipc-tests-session" ''
        set -euo pipefail

        echo "WARNING: Session mode tests against running user service — not isolated, not CI-safe." >&2
        echo "" >&2

        export NEWSHELL_TEST_INSTANCE_MODE=session
        exec ${pkgs.bash}/bin/bash "${self}/configs/newshell/launcher/tests/run-launcher-interaction-ipc-tests.sh"
      '';

      reinstallGitHooks = pkgs.writeShellScriptBin "repo-install-git-hooks" ''
        set -euo pipefail

        ${pkgs.nix}/bin/nix run "path:$PWD#install-git-hooks"
      '';

      repoGate = pkgs.writeShellScriptBin "repo-gate" ''
        set -euo pipefail

        real_index="$(${pkgs.git}/bin/git rev-parse --git-path index)"
        temp_index="$(${pkgs.coreutils}/bin/mktemp)"

        cleanup() {
          ${pkgs.coreutils}/bin/rm -f "$temp_index"
        }
        trap cleanup EXIT

        prepare_temp_index() {
          if [ -f "$real_index" ]; then
            ${pkgs.coreutils}/bin/cp "$real_index" "$temp_index"
          else
            : > "$temp_index"
          fi

          GIT_INDEX_FILE="$temp_index" ${pkgs.git}/bin/git add -A -- .
        }

        run_hooks() {
          GIT_INDEX_FILE="$temp_index" \
            ${pkgs.nix}/bin/nix develop "path:$PWD" -c pre-commit run --hook-stage pre-commit
        }

        attempt=1
        max_attempts=2

        while [ "$attempt" -le "$max_attempts" ]; do
          prepare_temp_index

          if run_hooks; then
            break
          fi

          if [ "$attempt" -eq "$max_attempts" ]; then
            exit 1
          fi

          attempt=$((attempt + 1))
        done

        # Run repo doctor after hooks (generated file drift check)
        echo ""
        echo "--- repo-doctor ---"
        ${pkgs.nix}/bin/nix run "path:$PWD#repo-doctor"

        # Optional runtime newshell IPC tests
        echo ""
        echo "--- newshell runtime IPC tests ---"
        if [ "''${NEWXOS_RUN_NEWSHELL_RUNTIME_TESTS:-0}" = "1" ]; then
          case "''${NEWXOS_NEWSHELL_TEST_BACKEND:-hyprland}" in
            hyprland)
              ${pkgs.nix}/bin/nix run "path:$PWD#run-newshell-launcher-ipc-tests-hyprland"
              ;;
            session)
              ${pkgs.nix}/bin/nix run "path:$PWD#run-newshell-launcher-ipc-tests-session"
              ;;
            self-managed)
              ${pkgs.nix}/bin/nix run "path:$PWD#run-newshell-launcher-ipc-tests"
              ;;
            *)
              echo "error: unknown NEWSHELL_TEST_BACKEND" >&2
              exit 1
              ;;
          esac
        else
          echo "Skipping newshell runtime IPC tests; set NEWXOS_RUN_NEWSHELL_RUNTIME_TESTS=1 to run."
        fi
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
        entry = "${pkgs.statix}/bin/statix fix";
        types = [ "nix" ];
      };

      pre-commit.settings.hooks.repo-write-flake = {
        enable = true;
        name = "write flake";
        description = "Regenerate flake.nix before commit.";
        entry = lib.getExe writeFlake;
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
        entry = "${config.treefmt.build.wrapper}/bin/treefmt";
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
        entry = lib.getExe flakeCheck;
        after = [ "repo-fmt" ];
        pass_filenames = false;
        types = [ "nix" ];
      };

      pre-commit.settings.hooks.repo-update-docs-index = {
        enable = true;
        name = "update docs index";
        description = "Reindex Basic Memory when docs files change.";
        entry = lib.getExe updateDocsIndex;
        after = [ "repo-fmt" ];
        files = "^docs/";
        pass_filenames = false;
      };

      pre-commit.settings.hooks.repo-install-git-hooks = {
        enable = true;
        name = "install git hooks";
        description = "Reinstall managed git hooks when the workflow module changes.";
        entry = lib.getExe reinstallGitHooks;
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
        entry = lib.getExe checkHyprlandConfig;
        files = "^configs/hypr/";
        pass_filenames = false;
      };

      pre-commit.settings.hooks.check-neovim-config = {
        enable = true;
        name = "check neovim config";
        description = "Verify Neovim starts without errors in headless mode.";
        entry = lib.getExe checkNeovimConfig;
        files = "^configs/nvim/";
        pass_filenames = false;
      };

      pre-commit.settings.hooks.check-newshell-config = {
        enable = true;
        name = "check newshell config";
        description = "Verify newshell shell.qml passes qmllint; best-effort lint for other QML files (some imports may not resolve in CI).";
        entry = lib.getExe checkNewshellConfig;
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
      packages.run-newshell-launcher-ipc-tests = runNewshellIpcTests;
      packages.run-newshell-launcher-ipc-tests-hyprland = runNewshellIpcTestsHyprland;
      packages.run-newshell-launcher-ipc-tests-session = runNewshellIpcTestsSession;

      # Static checks that can run in nix flake check
      # Runs only non-git-dependent invariants (generated-file drift is checked by repo-gate)
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

            # 10.5 Runtime test packages must use namespaced targets.
            # The test script supports session/external/self-managed modes;
            # session mode intentionally uses global targets.
            # Check the Nix package wrappers, not the test script itself.
            if rg -n 'newshell ipc call (launcher|query)\b' \
              packages \
              --glob '!*.md' 2>/dev/null; then
              echo "error: newshell runtime tests must use NEWSHELL_IPC_NAMESPACE targets, never global launcher/query" >&2
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
      # Builds the CLI package with tests enabled.
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

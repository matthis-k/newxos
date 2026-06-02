---
title: encountered_issues
type: note
permalink: newxos/encountered-issues
---

# Encountered Issues

Append-only repo memory for repeatable mistakes and gotchas.

## Observations

- [fact] This file tracks repeatable mistakes and gotchas for future reference
- [technique] Each entry includes date, problem, symptom, cause, fix, rule, and related knowledge links
- [decision] Keep this append-only; do not remove old entries even if resolved
- [fact] Most issues relate to scope boundaries between flake-parts, NixOS modules, and shell wrappers

## Relations

- part_of [[Knowledge]]
- relates_to [[Workflow]]
- relates_to [[Libraries]]

## Entry Format

- Date: `YYYY-MM-DD`
- Problem: short reusable description of the actual issue
- Symptom: what failed or what misleading behavior showed up
- Cause: what was actually wrong
- Fix: what resolved it
- Rule: durable rule to follow next time
- Context: optional subsystem or task
- Related knowledge: link the relevant library, pattern, workflow, or structure page

## Entries

### 2026-04-27: `modulesPath` missing from outer flake-parts module args

- Date: `2026-04-27`
- Problem: requesting `modulesPath` from the outer flake-parts file function for a `flake.modules.nixos.*` declaration
- Symptom: `nix flake check` failed with `attribute 'modulesPath' missing` while evaluating the host module
- Cause: `modulesPath` is a NixOS module-system arg, not an arg automatically available to the outer flake-parts file function
- Fix: define `flake.modules.nixos.<name>` as a NixOS module function when it needs `modulesPath`, `config`, or similar NixOS-only args
- Rule: keep flake-parts args and NixOS module args separate; request NixOS-only args inside the module value, not at the outer file boundary
- Context: adding generated hardware config as a host module
- Related knowledge: [[flake-parts]], [[Scope Boundaries And Per-System Access]], [[Host And User Layout]]

### 2026-04-27: reaching for `self.packages.${system}` instead of `withSystem` and `self'`

- Date: `2026-04-27`
- Problem: manually indexing `self.packages.${system}` from a top-level `flake.modules.nixos.*` module
- Symptom: the code worked, but it sidestepped the intended flake-parts per-system access pattern and made scope mistakes more likely
- Cause: forgetting that `self'` is only available inside the per-system scope entered through `withSystem`
- Fix: use `withSystem pkgs.stdenv.hostPlatform.system ({ self', ... }: ...)` inside the reusable module and read packages from `self'.packages`
- Rule: in top-level reusable modules, use `withSystem` to enter system scope; inside `perSystem`, use `inputs'` and `self'`
- Context: exposing the wrapped `opencode` package through a reusable Home Manager module while keeping unsupported systems non-fatal
- Related knowledge: [[flake-parts]], [[Scope Boundaries And Per-System Access]]

### 2026-04-28: defaulted outer module args still require `_module.args` when reused as NixOS modules

- Date: `2026-04-28`
- Problem: using a defaulted outer file arg like `mainDisk ? "/dev/..."` to parameterize a value exported under `flake.modules.nixos.*`
- Symptom: shallow flake output discovery worked, but forcing the NixOS module failed with `attribute 'mainDisk' missing`
- Cause: once the exported value was evaluated by the NixOS module system, `mainDisk` was treated as a module arg resolved through `_module.args`; the outer default did not behave like a normal local binding there
- Fix: replace the pseudo-parameter with a local `let` binding for fixed values, or provide a real module option or `_module.args` when configurability is truly needed
- Rule: do not parameterize exported `flake.modules.nixos.*` modules with ad hoc outer args unless you also arrange to pass them during NixOS module evaluation
- Context: `disko.devices.disk.main.device` in a host filesystem module
- Related knowledge: [[flake-parts]], [[Scope Boundaries And Per-System Access]], [[Host And User Layout]], [[disko]]

### 2026-05-05: generic Base16 browser targets can lose semantic contrast intent

- Date: `2026-05-05`
- Problem: relying on generic Base16 slot mapping for Zen Browser theming
- Symptom: contrast looked wrong in places like selected vertical tabs and urlbar suggestion rows even though palette itself was fine
- Cause: full semantic palette got flattened into Base16 slots before browser-specific UI groups were chosen, so contrast-sensitive surfaces lost app-specific intent
- Fix: generate repo-owned Zen Browser CSS directly from `config.stylix.fullPalette.colors` and keep browser UI groups mapped from semantic colors in one place
- Rule: when app theme needs more nuance than Base16 slots provide, disable built-in target CSS and generate repo-owned full-palette target under `modules/theming/`
- Context: Zen Browser Catppuccin-style theme customization
- Related knowledge: [[stylix]], [[Wrapped Programs And Generated Config]], [[Workflow]]

### 2026-05-06: shell arity guards can bypass documented env fallbacks

- Date: `2026-05-06`
- Problem: requiring too many positional args before a command reaches its documented environment-based defaulting logic
- Symptom: `newxos os switch` printed usage instead of using `NEWXOS_HOST` or reporting that the env var was unset or invalid
- Cause: `os_cmd` required at least two args before parsing optional host position, so the default-host branch was unreachable
- Fix: lower the upfront shell arity check so `switch|boot|build` can run without a positional host and fall through to `default_nixos_host`
- Rule: when a command supports env-backed optional positionals, keep the initial argument-count guard aligned with the truly required args only
- Context: `newxos` wrapper host resolution
- Related knowledge: [[nh and nom]], [[Workflow]]

### 2026-05-06: multiline shell snippets can break pipelines inside generated wrappers

- Date: `2026-05-06`
- Problem: interpolating a multiline shell snippet immediately before a pipe in `writeShellScriptBin`
- Symptom: build succeeded far enough to generate the script, but running or checking it failed with `syntax error near unexpected token '|'`
- Cause: the interpolated snippet ended with a newline, so the generated script placed `| next-command` on its own shell line
- Fix: keep the full pipeline structure in one script body, or dispatch by mode with `case` instead of splicing whole commands into pipeline positions
- Rule: do not interpolate free-form multiline shell fragments into the middle of pipelines in generated shell scripts
- Context: Hyprland screenshot helpers
- Related knowledge: [[hyprland]], [[Workflow]]

### 2026-05-07: `buildEnv` tool bundles cannot safely mix wrapped compiler toolchains

- Date: `2026-05-07`
- Problem: putting both `gcc` and `clang` wrapper packages into one shared `pkgs.buildEnv` tool bundle
- Symptom: the `dev-tools` package failed to build with `two given paths contain a conflicting subpath` for `bin/ld`
- Cause: both wrapper toolchains exported the same linker path into the merged environment
- Fix: keep one compiler toolchain per `buildEnv` bundle, and add only the extra tools that do not collide with that wrapper
- Rule: when building shared tool bundles with `pkgs.buildEnv`, avoid mixing `gcc` and `clang` wrappers unless you split them into separate outputs
- Context: `modules/dev/dev-tools.nix`
- Related knowledge: [[Workflow]]

### 2026-05-11: `git-hooks.nix` pre-commit hook breaks after Nix GC

- Date: `2026-05-11`
- Problem: pre-commit hook fails with `No such file or directory` on the `pre-commit` binary
- Symptom: `git commit` errors with `.git/hooks/pre-commit: line 13: /nix/store/...-pre-commit-4.5.1/bin/pre-commit: No such file or directory`
- Cause: `git-hooks.nix` generates `.git/hooks/pre-commit` with an absolute store path to the Python `pre-commit` binary; Nix garbage collection removes that path
- Fix: run `nix run "path:$PWD#install-git-hooks"` to regenerate the hook with a valid store path
- Rule: after Nix GC, flake updates, or any rebuild that could change the `pre-commit` store path, run `install-git-hooks` before committing
- Context: pre-commit hook wired through `git-hooks.nix` (`modules/dev/workflow.nix`)
- Related knowledge: [[workflow tooling]], [[Workflow]]

### 2026-05-07: Lua multi-return inside table constructors can collapse runtime library lists

- Date: `2026-05-07`
- Problem: expanding a list with `unpack(...)` in the middle of a table constructor for LuaLS workspace libraries
- Symptom: editing Neovim config Lua files had no `vim.` member completions even though `lua_ls` was attached
- Cause: Lua only keeps all return values from a function call when it is the final expression; in a non-final table field, `unpack(vim.api.nvim_get_runtime_file("", true))` contributed only the first runtime path
- Fix: build the runtime path list first, then extend it with extra libraries instead of unpacking in the middle of the table literal
- Rule: when a Lua config needs a whole list from `unpack(...)`, do not place that call before additional table elements unless losing all but the first value is intended
- Context: `configs/nvim/lsp/lua_ls.lua`
- Related knowledge: [[Workflow]]

### 2026-05-12: repo QuickShell modules can outrun the version in pinned nixpkgs or the user profile

- Date: `2026-05-12`
- Problem: importing a newer QuickShell module like `Quickshell.Networking` while the active `quickshell` binary is still an older profile or nixpkgs build
- Symptom: config load fails with `module "Quickshell.Networking" is not installed` even though upstream v0.3 docs list that module
- Cause: the runtime binary was `quickshell 0.2.1`, which predates `Quickshell.Networking`; the import path was correct, but the package version was too old
- Fix: update the repo `nixpkgs` lock to a revision that ships the required QuickShell version, then rebuild or run the repo-managed package
- Rule: when adding newer QuickShell APIs, verify the QuickShell version provided by the pinned `nixpkgs` lock, not just the docs or the binary currently found in the user profile
- Context: QuickShell network quickmenu migration from local `nmcli` wrapper to `Quickshell.Networking`
- Related knowledge: [[quickshell]], [[Workflow]]

## NixOS module imports inside mkMerge

- [issue] Putting `imports` inside an attrset returned by `lib.mkMerge` makes it part of module `config`, causing `The option 'imports' does not exist` when that branch is enabled.
- [fix] Keep `imports` at the module top level and put conditional option definitions under `config = lib.mkMerge [...]`.
- [prevention] When a module needs conditional imports, return `{ imports = lib.optionals condition [...]; config = ...; }` instead of merging `imports` with normal config options.

Relations:
- relates_to [[Dendritic Feature Modules]]
- relates_to [[Scope Boundaries And Per-System Access]]

### 2026-05-18: ATA DRM logs are not graphics DRM

- Context: investigating Plymouth/NVIDIA boot graphics on `matthisk-desktop-newxos`.
- Problem: kernel messages like `ata5.00: supports DRM functions and may not be fully accessible` look related to Direct Rendering Manager at first glance.
- Root cause: in this ATA/storage context, DRM refers to drive feature/security support, not Linux graphics DRM/KMS.
- Rule: for Plymouth/NVIDIA issues, focus on `simpledrm`, `nvidia_drm`, framebuffer handoff, and Plymouth service logs; do not treat `ata*.00 supports DRM functions` as a graphics error.
- Related knowledge: [[Host And User Layout]], [[hyprland]].

### 2026-05-21: Hyprland `hyprctl` fish completions can be generated stale

- Context: fixing `hyprctl` completions from upstream Hyprland.
- Problem: upstream-generated `hyprctl.fish` can show nested literals like `0` at top level and pair commands with wrong descriptions.
- Symptom: `hyprctl ` completion listed `event` with `Output in JSON format` and `0` with the monitor description.
- Cause: the generated completion state machine in the upstream package was stale or misindexed relative to `hyprctl.usage`.
- Fix: keep the upstream Hyprland package, copy only the installed `hyprctl.fish`, apply a local patch in a tiny derivation, and install it with `lib.hiPrio`.
- Rule: for broken package-provided shell completions, prefer a high-priority post-install completion override before rebuilding the upstream package from source.
- Related knowledge: [[hyprland]], [[Workflow]].

### 2026-05-23: Open WebUI TTS split setting persisted over Nix env

- Date: `2026-05-23`
- Problem: Open WebUI kept stopping Kokoro TTS playback after the first split chunk even after changing `AUDIO_TTS_SPLIT_ON` in Nix.
- Symptom: long text playback stopped after one or two sentences while direct Kokoro `/v1/audio/speech` requests generated full audio.
- Cause: Open WebUI stores audio config in SQLite as `PersistentConfig`; persisted `audio.tts.split_on = "punctuation"` overrode Nix environment settings while `ENABLE_PERSISTENT_CONFIG` was true. Empty `AUDIO_TTS_SPLIT_ON` also falls back to punctuation in the frontend splitter.
- Fix: set `ENABLE_PERSISTENT_CONFIG = "False"` and `AUDIO_TTS_SPLIT_ON = "none"` declaratively for Open WebUI, letting Kokoro handle long text as one request.
- Rule: for declarative Open WebUI settings, disable persistent config or explicitly clear/update the database; use valid splitter values (`punctuation`, `paragraphs`, `none`), not an empty string.
- Context: `modules/desktop/llm-server.nix`, Kokoro TTS on RTX 5060.
- Related knowledge: [[Ollama local LLM setup]], [[Workflow]]

### 2026-05-23: OpenedAI Speech upstream image needs CUDA 12.8 and TorchCodec on RTX 5060

- Date: `2026-05-23`
- Problem: upstream `ghcr.io/matatonic/openedai-speech:latest` is not sufficient for XTTS on RTX 5060 / Blackwell.
- Symptom: XTTS can fail with CUDA kernel compatibility errors, or torchaudio can raise `TorchCodec is required for load_with_torchcodec` after upgrading PyTorch/torchaudio.
- Cause: the upstream image ships PyTorch wheels that do not support Blackwell `sm_120`, and newer torchaudio load paths require `torchcodec`.
- Fix: build the local `openedai-speech-xtts-sm120:torchcodec` image from `modules/desktop/xtts-gpu-fix/Dockerfile`, installing `torch==2.11.0+cu128`, `torchaudio==2.11.0+cu128`, and `torchcodec==0.13.0`.
- Rule: for GPU containers on RTX 5060, verify the container PyTorch CUDA arch support and companion codec packages, not just host driver support.
- Context: `modules/desktop/llm-server.nix`, `modules/desktop/xtts-gpu-fix/Dockerfile`, OpenedAI Speech XTTS-v2.
- Related knowledge: [[Local LLM and TTS setup]], [[Workflow]]

### 2026-05-25: Open WebUI punctuation TTS chunks can sound clipped

- Date: `2026-05-25`
- Problem: Open WebUI punctuation-based TTS chunking creates audible clipped or slashed transitions between XTTS chunks.
- Symptom: speech works, but sentence boundaries sound abrupt compared with longer chunks.
- Cause: punctuation splitting sends many short requests to the OpenAI-compatible TTS backend, so prosody and audio joins are less smooth.
- Fix: use paragraph chunking for Open WebUI TTS while keeping persistent config disabled so the declarative environment wins.
- Rule: for XTTS quality, prefer paragraph-sized Open WebUI chunks over punctuation-sized chunks unless latency matters more than transition smoothness.
- Context: `modules/desktop/llm-server.nix`, Open WebUI, OpenedAI Speech XTTS-v2.
- Related knowledge: [[Local LLM and TTS setup]], [[Workflow]]

### 2026-05-25: Kokoro-FastAPI GPU container image and CDI selector must match host

- Date: `2026-05-25`
- Problem: Open WebUI read-aloud showed a server connection error after switching to Kokoro-FastAPI.
- Symptom: `kokoro-fastapi.service` restarted with Docker exit status 125 and no process listened on the configured TTS port.
- Cause: the configured `ghcr.io/remsky/kokoro-fastapi-gpu:latest-cu128` tag was not available locally or in GHCR, and Docker `--gpus all` selected a missing AMD CDI spec on this mixed/RTX host.
- Fix: use the known local `kokoro-fastapi-gpu-sm120:latest` image and pass the NVIDIA CDI device explicitly with `--device nvidia.com/gpu=all`.
- Rule: for RTX 50-series local TTS containers, verify both the image tag and Docker GPU selector with a direct container probe before wiring Open WebUI to the service.
- Context: `modules/desktop/llm-server.nix`, Kokoro-FastAPI, Open WebUI TTS.
- Related knowledge: [[Local LLM and TTS setup]], [[Workflow]]

### 2026-05-25: Zen cannot import Caddy CA from private state path

- Date: `2026-05-25`
- Problem: Zen Browser policy installed Caddy's local root CA directly from `/var/lib/caddy/.local/share/caddy/pki/authorities/local/root.crt`.
- Symptom: the Open WebUI HTTPS reverse proxy worked with `curl -k`, but the policy path was not traversable by the user because `/var/lib/caddy` is private service state.
- Cause: Firefox/Zen enterprise certificate policy needs a readable certificate file path; Caddy's generated CA lives under service-owned state.
- Fix: publish the Caddy root CA to a world-readable runtime path such as `/run/caddy-local-root.crt`, then point `Certificates.Install` at that path.
- Rule: when browser policy consumes a service-generated certificate, verify both TLS trust with `curl --cacert` and user-readable permissions on the policy path.
- Context: `modules/desktop/llm-server.nix`, `modules/socials/zen-browser.nix`, Open WebUI HTTPS microphone access.
- Related knowledge: [[Local LLM and TTS setup]], [[Workflow]]

### 2026-06-01: Launcher composite search retained the whole tree per keystroke

- Date: `2026-06-01`
- Problem: launcher composite search treated every allowed node as a candidate even without evidence
- Symptom: typing in the launcher hogged CPU and could almost freeze the desktop
- Cause: `candidate: selfAllowed || retainedChildren` retained the whole tree, and candidate indexing also had a whole-index substring scan path
- Fix: require indexed candidate membership, direct evidence, own visibility, or retained children; prune non-candidate subtrees early; remove whole-index substring scans from the hot path
- Rule: launcher candidate retention must never use permission/allowance as proof of search relevance
- Context: QuickShell launcher composite search optimization
- Related knowledge: [[quickshell]]

### 2026-06-01: Launcher result rows retained circular evaluated trees

- Date: `2026-06-01`
- Problem: composite launcher result rows included the raw evaluated node object
- Symptom: IPC debug output failed with `TypeError: Cannot convert circular structure to JSON`, and the UI model retained large circular evaluated trees per row
- Cause: `toResultRow` returned `raw: ev`; evaluated nodes contain parent/tree references and evidence/children state not needed by delegates
- Fix: remove the raw evaluated object from normalized result rows; keep only primitive row fields, actions, evidence, and metadata needed by delegates/debugging
- Rule: normalized launcher rows must not carry raw backend/evaluation tree objects into ListView models or IPC responses
- Context: QuickShell launcher composite search performance and debug IPC
- Related knowledge: [[quickshell]]

### 2026-06-01: Launcher prewarm can cache desktop apps before DesktopEntries is ready

- Date: `2026-06-01`
- Problem: prewarming every command-tree composite root at component completion cached an empty desktop app tree
- Symptom: `@app zen` and unprefixed `zen` lost application results after restart while action directives still worked
- Cause: `DesktopAppsBackend` depends on `Quickshell.DesktopEntries`; prewarming ran before entries were populated, and the cached composite root then stayed empty
- Fix: keep startup prewarm for static command trees but disable it for `DesktopAppsBackend`; let the app backend build its composite root lazily once queried
- Rule: do not prewarm QuickShell backends whose source model is populated asynchronously unless the backend invalidates/rebuilds when the source model becomes ready
- Context: QuickShell launcher composite root cache optimization
- Related knowledge: [[quickshell]]

- Context: QuickShell launcher async file backend
  - Issue: `ProcessBackendBase.applySearchOutput()` only invoked callbacks when parsed results were non-empty, which can leave the launcher controller with stale pending/loading state and prevent empty async searches from settling.
  - Fix: Always invoke the async callback with the parsed result array, including `[]`; file path queries also get an immediate direct-path composite row while process results catch up.
  - Prevention: Async launcher backends must always settle their callback for every request, even on no-match or process failure paths.

### 2026-06-01: Launcher debugSearch can fail on circular debug rows

- Date: `2026-06-01`
- Problem: `newshell ipc call launcher debugSearch "zen n"` returned Quickshell IPC `PeerClosedError` text instead of JSON.
- Symptom: the query worked in `debugBenchmark` and returned row counts, but `debugSearch`/`debugComplete` failed because JSON serialization of result rows hit circular or repeated object references.
- Cause: debug IPC serialized rich row objects directly; selected/child actions can share nested objects in a way that is unsafe for plain `JSON.stringify`.
- Fix: use `LauncherController.debugStringify()` with a circular-safe replacer for debug IPC responses, and let the result collection helper record per-query errors instead of aborting.
- Rule: debug IPC must serialize sanitized/debug-safe values, not assume UI model rows are plain JSON trees.
- Context: QuickShell launcher debug result collection baseline.
- Related knowledge: [[quickshell]]

### 2026-06-02: Launcher debug baselines should use compact row DTOs

- Date: `2026-06-02`
- Problem: Full launcher row debug output could exceed practical IPC/debug safety because rows carried rich action/evidence graphs and executable payload details.
- Symptom: Combined `debugSearch "zen n"` failed while backend-isolated debug output and `debugBenchmark` worked.
- Cause: The debug path serialized too much row internals; the UI needs normalized row fields, not full evidence and executable action closures.
- Fix: Emit compact normalized debug rows and keep static backend executable closures backend-internal, resolved through `metadata.commandPath` and action id.
- Rule: Launcher baselines should diff normalized public row fields, not private backend execution objects.
- Context: QuickShell launcher result collection baseline.
- Related knowledge: [[quickshell]]

## Quickshell Environment Access

- [issue] QML checks using `Qt.application.environment` can silently read as unset in Quickshell, causing state like launcher dev-mode toggles to drift from the actual service environment.
- [root-cause] Quickshell exposes process environment through `Quickshell.env("VAR")`; `Qt.application.environment` is not the supported API here.
- [fix] Use `Quickshell.env("NEWXOS_DEV") === "1"` (and fallback variables as needed) for live Quickshell environment checks.
- [prevention] When reading environment variables from Quickshell QML, import `Quickshell` and use `Quickshell.env()`.

## Relations

- relates_to [[quickshell]]
- relates_to [[Dev Specialization]]

## Quickshell Launcher Tree Results Collapsed Frame

- [issue] The launcher could have valid controller results while the visible results frame stayed collapsed, making queries like `session` appear blank.
- [root-cause] The frame height depended only on `resultsColumn.implicitHeight`; tree delegates loaded through `Loader` can report no implicit height briefly, so the result area can collapse even when `controller.results.length > 0`.
- [fix] Reserve at least `rowHeight * visibleRows` whenever results exist, while still allowing `resultsColumn.implicitHeight` to expand tree rows.
- [prevention] For loader-backed result lists, size the viewport from model count as a floor and delegate implicit size as an expansion, not from delegate implicit size alone.

## Relations

- relates_to [[quickshell]]
- relates_to [[Launcher Result Limits]]

### 2026-06-02: Launcher action groups can look blank when only nested children are emitted

- Date: `2026-06-02`
- Problem: a matching launcher action group could be returned only as a non-executable parent with nested child rows.
- Symptom: searching `newxos` produced valid debug rows, but the launcher could appear to show nothing useful or actionable.
- Cause: the `Newxos` group used category group display defaults that favored the parent row and nested children, while the parent had no default action.
- Fix: give the `Newxos` group a default `newxos switch` action and tune its group display margins so at least the primary child action is flattened into a normal visible row.
- Rule: launcher groups intended as user-entered command namespaces should either be executable themselves or flatten at least one actionable child row for the namespace query.
- Context: QuickShell launcher desktop actions.
- Related knowledge: [[quickshell]]

### 2026-06-03: Launcher category groups should flatten actionable descendants

- Date: `2026-06-03`
- Problem: normal launcher category groups emitted non-executable parent rows with nested children.
- Symptom: searches such as `networking`, `audio`, `notifications`, and `power profile` produced valid debug DTOs but looked invisible or non-actionable in the launcher because the frontend selected the tree delegate for nested groups.
- Cause: `ActionGroupNode` defaulted to nested group display, and flattening only considered immediate children, so wrapper groups like `Power Mode` could still become non-executable rows.
- Fix: make `ActionGroupNode` default to flattening category matches and have `CompositeSearchFlatten.flattenActionableChildren()` walk through non-action wrapper groups to emit executable leaves or switch rows.
- Rule: user-facing launcher category templates should flatten to actionable descendant rows unless the parent group is intentionally executable and visually useful.
- Context: QuickShell launcher desktop actions.
- Related knowledge: [[quickshell]]

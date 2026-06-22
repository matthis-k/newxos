# QuickShell State Singleton Audit

Scope: `configs/newshell/services/*.qml` plus launcher/global singleton-like modules touched by dashboard, bar, and launcher behavior.

Classification key:
- A: Reasonable complexity
- B: Slightly too large but acceptable
- C: Too much code for the behavior
- D: Wrong ownership or should be split/moved

| Singleton | Verdict | Notes | Follow-up |
|---|---:|---|---|
| `NetworkService.qml` | B | Owns nmcli polling, parsing, Wi-Fi actions, wired state, and presentation. This is large but mostly one domain. Fake `busy/scanning/connecting` placeholders were replaced with normalized operation/error state. `scan()` is canonical; `rescan()` remains a compatibility wrapper. | Consider extracting nmcli output parsing only if it grows again. |
| `BluetoothService.qml` | A | Thin adapter over QuickShell Bluetooth plus normalized device DTOs. Operation state is now exposed for adapter/device mutations. | Keep as-is. |
| `AudioService.qml` | B | PipeWire device/stream normalization, controls, and actions are in one service. Large, but output/input/stream behavior is tightly coupled. Operation state now covers volume, mute, default-device, and stream move actions. | If stream routing grows, extract stream command helper. |
| `PowerService.qml` | A | Small UPower/power-profile adapter. Operation state is mostly for consistency around profile changes. | Keep as-is. |
| `Brightness.qml` | A | Small brightnessctl-backed service. Operation state now covers set/adjust failures. | Keep as-is. |
| `NordVPN.qml` | B | CLI parsing, status watching, destinations, and settings all live here. Size is acceptable for one provider but would not scale to multiple providers. Operation state now covers connect/disconnect/settings. | Split provider-specific parser only if another VPN provider is added. |
| `VpnService.qml` | A | Façade that normalizes the current VPN provider for UI/launcher. | Keep as-is; expose provider operation state through this façade. |
| `ConnectivityService.qml` | A | Derived aggregate over network, VPN, and Bluetooth. No side effects. | Keep as-is. |
| `NotificationCenter.qml` | B | State model plus notification body HTML rendering live together. Behavior is still moderate, but rendering is view-adjacent. | Move body formatting out if another view needs different notification rendering. |
| `ShellState.qml` | B | Per-screen window ownership, dashboard tab state, and IPC entrypoints are intentionally centralized. Large but justified by being shell composition state. | Keep dashboard tab state here; avoid adding service parsing or launcher ranking here. |
| `ShellActions.qml` | A | Signal bus for reusable shell actions. | Keep as-is. |
| `HyprlandService.qml` | B | Hyprland state plus visual ordering helpers. The column-major toplevel ordering is behavior-specific but reused by UI. | If another ordering mode is added, consider extracting toplevel ordering helper. |
| `Stats.qml` | C | Collects CPU, memory, disk, network, GPU, battery graph persistence, and parsing. This is much more code than a single state surface normally needs, but it is isolated and currently working. | Do not rewrite opportunistically. Future safe split: per-domain collectors plus shared graph persistence helper. |
| `Config.qml` | B | Theme, spacing, motion, and persistent style state are large but intentionally central. | Keep exact values in source only; avoid duplicating in docs. |
| `launcher/BindingRegistry.qml` | A | Small registry. | Keep as-is. |
| `launcher/PolicyRegistry.qml` | A | Registry/alias owner. | Keep as-is. |
| `launcher/logic/ActionPolicy.qml` | A | Default action candidate selection and scoring. It does not execute actions or reference services/backends. | Keep selection policy here; keep delegates heuristic-free. |
| `launcher/logic/ActionRegistry.qml` | B | Executes recipe steps and dispatches service payloads. Some service dispatch branching is expected. | If service payload cases keep growing, extract service dispatch table. |
| `launcher/logic/RenderedRows.qml` | B | Row DTO construction is necessarily central but should stay declarative. It now consumes ActionPolicy metadata instead of owning action heuristics. | Keep backend refs out of row DTOs. |

General follow-ups:
- Prefer normalized `operation` state for new command-backed services.
- Avoid local `Process` usage in view components when the action is reusable by launcher, dashboard, or bar.
- Keep presentation DTOs small; move view-only markup/formatting out when multiple views need different rendering.

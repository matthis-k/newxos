---
title: quickshell
type: note
permalink: newxos/libraries/quickshell
---

# quickshell

Quickshell (v0.3) provides a QtQuick/QML-based compositor-agnostic shell toolkit for building bars, panels, widgets, and overlays on Wayland.

## Observations

- [fact] Hand-written template config in `configs/quickshell/`; exposed as `newshell` and `newshelldev` wrapper packages
- [technique] Use `newshell` for Nix-store template, `newshelldev` for live edits under `${NEWXOS_FLAKE:-$HOME/newxos}/configs/quickshell`
- [fact] If pinned `nixpkgs` QuickShell is too old for new module like `Quickshell.Networking`, update repo lock before changing imports
- [decision] Leave `.qmlls.ini` untracked next to `shell.qml`; Quickshell manages it per machine for `qmlls` support
- [fact] Breaking changes expected before 1.0; upstream will provide migration guides

## Relations

- relates_to [[Wrapped Programs And Generated Config]]
- relates_to [[Flake Structure]]
- relates_to [[quickshell-design]]

## What It Does Here

- Keeps the hand-written template config in `configs/quickshell/`.
- Exposes `newshell`, a nix-wrapper-modules wrapper around `quickshell -p <store-template-dir>`.
- Exposes `newshelldev`, the same wrapper pointed at `${NEWXOS_FLAKE:-$HOME/newxos}/configs/quickshell` for live local config iteration.
- Installs both the raw `quickshell` binary and the repo wrapper through Home Manager so ad hoc runs stay available.
- Sets `QS_ICON_THEME` from the active Stylix icon selection so `quickshell` and `newshell` stay aligned.
- Keeps the wrapper minimal instead of copying Quickshell config into `~/.config/`.

## Basics

- Edit `configs/quickshell/shell.qml` when changing the repo template.
- Use `newshell` for the Nix-store template, `newshelldev` for live edits under `${NEWXOS_FLAKE:-$HOME/newxos}/configs/quickshell`, and `quickshell` directly for other config paths.
- If the pinned `nixpkgs` QuickShell is too old for a new module such as `Quickshell.Networking`, update the repo lock before changing imports.
- Leave `.qmlls.ini` untracked next to `shell.qml`; Quickshell manages it per machine for `qmlls` support.
- Related reading: [[Wrapped Programs And Generated Config]], [[Flake Structure]].

## Upstream Overview (v0.3)

### Config layout

- Quickshell searches `~/.config/quickshell/` for configs.
- Each subfolder containing a `shell.qml` is a separate config.
- A specific config is selected with `-c` / `--config`, or run from an arbitrary path with `-p` / `--path`.
- Root imports (`import "root:/..."`) are legacy and break LSP/singletons; avoid them.

### QML language fundamentals

- **Imports**: module imports (`import QtQuick`), directory imports (`import "./widgets"`), Quickshell module imports (`import qs.widgets`), JS imports (`import "util.js" as Util`).
- **Objects**: defined by type name (uppercase), contain properties, functions, signals.
- **Properties**: reactive bindings re-evaluate when dependencies change. `property <type> <name>[: binding]`, `readonly`, `required`, `default`.
- **id**: unique per-file reference name (lowercase).
- **Signals and handlers**: `on<Signal>` pattern (e.g., `onClicked`). `Connections` object for indirect targets.
- **Functions and lambdas**: `function name(params) { ... }`, `x => x * 2`.
- **Reactivity**: automatic when properties reference other properties. `Qt.binding()` for manual bindings. Assignment (not binding) removes reactivity.
- **Components**: file-based types (uppercase `.qml` files), inline `component Foo: Type { ... }`, `pragma Singleton` for single-instance types.

### Window types

- **PanelWindow**: bars, widgets, overlays; reserves screen space. Supports anchors to screen edges.
- **FloatingWindow**: standard desktop windows.
- Both accept a `screen` property for monitor assignment.

### Multi-screen pattern

- `Quickshell.screens` is a reactive list of available screens.
- `Variants` + `Component` creates one window per screen, with `modelData` carrying the screen reference.
- Windows are created/destroyed reactively as monitors connect/disconnect.

### Shared state pattern

- `Scope` provides a non-visual root for non-widget objects.
- Use `property` on the root `Scope` for shared state across multiple windows.
- `Singleton` types (via `pragma Singleton` + `Singleton` root) provide globally accessible single-instance objects.

### Core Quickshell types (by namespace)

**Quickshell** — `Quickshell` singleton (screens, settings, quantizer), `PanelWindow`, `FloatingWindow`, `PopupWindow`, `ShellRoot`, `ShellScreen`, `QsWindow`, `Variants`, `Scope`, `Singleton`, `SystemClock`, `PersistentProperties`, `Reloadable`, `Retainable`, `LazyLoader`, `ObjectModel`, `ScriptModel`, `DesktopEntry`/`DesktopEntries`, `EasingCurve`, `Edges`, `ElapsedTimer`, `Intersection`, `Region`/`RegionShape`, `TransformWatcher`, `BoundComponent`, `ExclusionMode`, `PopupAnchor`/`PopupAdjustment`, `QsMenuHandle`/`QsMenuOpener`/`QsMenuEntry`/`QsMenuAnchor`/`QsMenuButtonType`.

**Quickshell.Io** — `Process`, `Socket`, `SocketServer`, `DataStream`/`DataStreamParser`/`SplitParser`, `StdioCollector`, `FileView`/`FileViewAdapter`/`FileViewError`, `IpcHandler`, `JsonAdapter`/`JsonObject`.

**Quickshell.Wayland** — `WlrLayershell`/`WlrLayer`, `Toplevel`/`ToplevelManager`, `ScreencopyView`, `IdleInhibitor`/`IdleMonitor`, `ShortcutInhibitor`, `WlSessionLock`/`WlSessionLockSurface`, `WlrKeyboardFocus`, `BackgroundEffect`.

**Quickshell.Hyprland** — `Hyprland` (IPC client), `HyprlandWorkspace`, `HyprlandMonitor`, `HyprlandToplevel`, `HyprlandWindow`, `HyprlandEvent`, `HyprlandFocusGrab`, `GlobalShortcut`.

**Quickshell.Services.Pipewire** — `Pipewire`, `PwNode`/`PwNodeAudio`, `PwLink`/`PwLinkGroup`/`PwLinkState`, `PwAudioChannel`, `PwNodePeakMonitor`, `PwNodeLinkTracker`, `PwObjectTracker`, `PwNodeType`.

**Quickshell.Services.Mpris** — `Mpris`, `MprisPlayer`, `MprisPlaybackState`, `MprisLoopState`.

**Quickshell.Services.Notifications** — `NotificationServer`, `Notification`, `NotificationAction`, `NotificationUrgency`, `NotificationCloseReason`.

**Quickshell.Services.SystemTray** — `SystemTray`, `SystemTrayItem`, `Category`, `Status`.

**Quickshell.Services.UPower** — `UPower`, `UPowerDevice`, `UPowerDeviceType`, `UPowerDeviceState`, `PowerProfiles`, `PowerProfile`, `PerformanceDegradationReason`.

**Quickshell.Services.Polkit** — `PolkitAgent`, `AuthFlow`.

**Quickshell.Services.Pam** — `PamContext`, `PamResult`, `PamError`.

**Quickshell.Services.Greetd** — `Greetd`, `GreetdState`.

**Quickshell.Networking** — `Networking`, `Network`, `NetworkDevice`, `WiredDevice`, `WifiDevice`/`WifiNetwork`/`WifiDeviceMode`/`WifiSecurityType`, `NetworkConnectivity`, `ConnectionState`, `ConnectionFailReason`, `NetworkBackendType`, `NMSettings`.

**Quickshell.Bluetooth** — `Bluetooth`, `BluetoothAdapter`, `BluetoothDevice`, `BluetoothAdapterState`, `BluetoothDeviceState`.

**Quickshell.DBusMenu** — `DBusMenuHandle`, `DBusMenuItem`.

**Quickshell.I3** — `I3`, `I3IpcListener`, `I3Event`, `I3Workspace`, `I3Monitor`.

**Quickshell.WindowManager** — `WindowManager`, `Windowset`, `ScreenProjection`, `WindowsetProjection`.

**Quickshell.Widgets** — `WrapperRectangle`, `WrapperManager`/`MarginWrapperManager`, `WrapperItem`, `WrapperMouseArea`, `ClippingRectangle`/`ClippingWrapperRectangle`, `IconImage`.

### QtQuick modules overview

QuickShell configs rely heavily on QtQuick. The following modules are the most relevant for shell/bar/widget development.

#### QtQuick — Core visual types

Module: `import QtQuick`

- **Basic items**: `Item` (invisible base), `Rectangle`, `Text`, `Image`, `BorderImage`, `AnimatedImage`, `AnimatedSprite`, `SpriteSequence`, `Canvas`, `ShaderEffect`.
- **Input**: `MouseArea`, `Keys` (attached), `Shortcut`, `FocusScope`, `PinchArea`, `MultiPointTouchArea`.
- **Positioning**: `anchors` system (top/bottom/left/right/centerIn/fill/horizontalCenter/verticalCenter/baseline), `parent`, `x`/`y`/`z`, `implicitWidth`/`implicitHeight`.
- **State and transitions**: `states`, `transitions`, `State`, `Transition`, `PropertyChanges`, `AnchorChanges`, `Revert`, `ParentChange`.
- **Animation**: `NumberAnimation`, `PropertyAnimation`, `ColorAnimation`, `RotationAnimation`, `Vector3dAnimation`, `PauseAnimation`, `SequentialAnimation`, `ParallelAnimation`, `Behavior`, `SmoothedAnimation`, `SpringAnimation`, `Easing` curves.
- **Models and views**: `ListModel`, `ListElement`, `DelegateModel`, `ObjectModel`, `Repeater`, `Instantiator`.
- **Utilities**: `Timer`, `Loader`, `Qt` object (`formatDateTime`, `binding`, `rgba`, `hsla`, `platform`, `resolvedUrl`), `Component`, `Connections`, `Binding`, `PropertyAction`, `QtObject`, `FontLoader`, `XMLListModel`, `JsonListModel`.
- **Layout helpers**: `Column`, `Row`, `Grid`, `Flow`, `PathView`, `Path`, `PathLine`, `PathQuad`, `PathCubic`, `PathArc`, `PathSvg`.
- **Effects**: `ShaderEffectSource`, `Layer` (attached), `OpacityMask`, `ColorOverlay`, `GammaAdjust`, `ThresholdMask`, `ConicalGradient`, `LinearGradient`, `RadialGradient`.

Docs: `https://doc.qt.io/qt-6/qtquick-qmlmodule.html`
Type index: `https://doc.qt.io/qt-6/qml-qtquick-item.html`

#### QtQuick.Layouts — Automatic layout containers

Module: `import QtQuick.Layouts`

- **LayoutContainer** — base class for layout types.
- **RowLayout** — horizontal layout with stretch and alignment.
- **ColumnLayout** — vertical layout with stretch and alignment.
- **GridLayout** — grid-based layout with row/column spanning.
- **Layout** (attached) — properties `fillWidth`, `fillHeight`, `preferredWidth`, `preferredHeight`, `minimumWidth`, `minimumHeight`, `maximumWidth`, `maximumHeight`, `alignment`, `row`, `column`, `rowSpan`, `columnSpan`.
- Layouts respect `implicitWidth`/`implicitHeight` of children and can mix with anchors on outer containers.

Docs: `https://doc.qt.io/qt-6/qtquicklayouts-qmlmodule.html`

#### QtQuick.Controls — High-level UI components

Module: `import QtQuick.Controls`

- **Buttons**: `Button`, `RoundButton`, `ToolButton`, `DelayButton`, `DialogButtonBox`.
- **Input**: `TextField`, `TextArea`, `SpinBox`, `ComboBox`, `Dial`, `Slider`, `ScrollBar`, `ScrollIndicator`, `Switch`, `CheckBox`, `RadioButton`, `ButtonGroup`.
- **Containers**: `GroupBox`, `Frame`, `BoxLayout`, `StackView`, `SwipeView`, `TabBar`, `TabButton`, `ScrollView`, `Flickable`, `Pane`, `GroupBox`, `ToolBar`, `ToolTip`, `Menu`, `MenuBar`, `MenuItem`, `MenuSeparator`, `Drawer`, `Dialog`, `Page`, `PageIndicator`, `SplitView`, `ApplicationWindow`, `Overlay`.
- **Display**: `Label`, `ProgressBar`, `BusyIndicator`, `StackLayout`, `SwipeDelegate`, `ItemDelegate`, `CheckDelegate`, `RadioDelegate`, `RangeSlider`, `Tumbler`, `TumblerColumn`, `Calendar`, `DateTimeEdit`.
- **Styling**: `Control` base properties (`palette`, `font`, `spacing`, `padding`, `leftPadding`, `rightPadding`, `topPadding`, `bottomPadding`, `horizontalPadding`, `verticalPadding`, `topInset`, `bottomInset`, `leftInset`, `rightInset`, `inset`, `focusPolicy`, `focusReason`, `hoverEnabled`, `mirrored`, `modal`, `dimmed`, `flat`, `checkable`, `checked`, `down`, `highlighted`, `visualFocus`, `activeFocus`).
- Controls are themeable via `palette` and custom delegates.

Docs: `https://doc.qt.io/qt-6/qtquickcontrols2-qmlmodule.html`

#### QtQuick.Effects — GPU-accelerated visual effects

Module: `import QtQuick.Effects`

- **MultiEffect** — unified effect combining blur, shadow, colorization, brightness/contrast, saturation, hue, mask, and more in a single pass.
- **Effect** — base type for custom effect chains.
- **FastBlur** — simple blur effect (legacy, prefer `MultiEffect`).
- **GaussianBlur** — configurable Gaussian blur (legacy, prefer `MultiEffect`).
- **DropShadow** — drop shadow effect (legacy, prefer `MultiEffect`).
- **OpacityMask** — mask one item with the alpha of another.
- **ColorOverlay** — overlay a color on an item.
- **ThresholdMask** — mask using a threshold on a source item.
- **RecursiveBlur** — blur that feeds back into itself for glow effects.
- **DirectionalBlur** — blur in a specific direction.
- **ZoomBlur** — blur radiating from a center point.
- **Displace** — displace pixels using a displacement map.

Docs: `https://doc.qt.io/qt-6/qtquickeffects-qmlmodule.html`

#### QtQuick.Window — Window management

Module: `import QtQuick.Window`

- **Window** — top-level window (less relevant in QuickShell, which uses `PanelWindow`/`FloatingWindow`).
- **Screen** — screen information (geometry, name, devicePixelRatio, orientation). QuickShell provides its own `ShellScreen` and `Quickshell.screens`.
- **Qt::ScreenOrientation** — portrait/landscape enums.
- **Visibility** — window visibility states (Windowed, Minimized, Maximized, FullScreen, AutomaticVisibility, Hidden).

Docs: `https://doc.qt.io/qt-6/qtquick-window-qmlmodule.html`

#### Qt5Compat.GraphicalEffects — Legacy effects (Qt 5 compat)

Module: `import Qt5Compat.GraphicalEffects`

- Provides Qt 5-era effects for migration: `Blur`, `BrightnessContrast`, `Colorize`, `Desaturate`, `FastBlur`, `Glow`, `HueSaturation`, `InnerShadow`, `LevelAdjust`, `MaskedBlur`, `OpacityMask`, `RadialBlur`, `RectangularGlow`, `RecursiveBlur`, `ThresholdMask`, `ZoomBlur`.
- Prefer `QtQuick.Effects` (`MultiEffect`) for new code.

Docs: `https://doc.qt.io/qt-6/qt5compat-graphicaleffects-qmlmodule.html`

#### Qt.labs.platform — Native platform dialogs

Module: `import Qt.labs.platform`

- `FileDialog`, `FolderDialog`, `ColorDialog`, `FontDialog`, `MessageDialog`, `StandardPaths`.
- Uses native platform dialogs where available.
- Note: these may not work well in QuickShell's panel context; prefer custom QML dialogs.

Docs: `https://doc.qt.io/qt-6/qtlabsplatform-qmlmodule.html`

#### QtCore — Utility types

Module: `import QtCore`

- `QAbstractItemModel`, `QSortFilterProxyModel`, `QStringListModel`, `QIdentityProxyModel`.
- `MimeData`, `Settings` (persistent key-value storage), `CommandLineParser`, `CommandLineOption`.
- `Locale`, `TimeZone`, `Date`, `Time`, `DateTime`.
- `RegularExpression`, `RegularExpressionMatch`, `RegularExpressionMatchIterator`.

Docs: `https://doc.qt.io/qt-6/qtcore-qmlmodule.html`

### QtQuick types commonly used in shells

`Item`, `Rectangle`, `Text`, `Image`, `MouseArea`, `Timer`, `Repeater`, `Column`/`Row`/`Grid`, `Loader`, `ShaderEffect`, `MultiEffect`, `NumberAnimation`, `SequentialAnimation`/`ParallelAnimation`, `PropertyAnimation`, `Qt` utility object (`formatDateTime`, `binding`), `Flickable`, `PathView`, `State`/`Transition`, `Behavior`, `Connections`.

### Editor / LSP setup

- Create `.qmlls.ini` next to `shell.qml` (Quickshell manages it; gitignore it).
- Neovim: `lspconfig.qmlls.setup {}`
- Emacs: `lsp-mode` or `eglot` with `qmlls`
- VSCode: Official QML extension, enable `qt-qml.qmlls.useQmlImportPathEnvVar`
- Helix: built-in qmlls support
- LSP caveats: doesn't work well with unstructured files, no docs for Quickshell types, `PanelWindow` resolution issues.

### Helpful Docs

- Guide index: `https://quickshell.org/docs/v0.3.0/guide`
- Install and setup: `https://quickshell.org/docs/v0.3.0/guide/install-setup/`
- Introduction (bar tutorial): `https://quickshell.org/docs/v0.3.0/guide/introduction/`
- Item size and position: `https://quickshell.org/docs/v0.3.0/guide/size-position/`
- QML language reference: `https://quickshell.org/docs/v0.3.0/guide/qml-language/`
- Distributing configs: `https://quickshell.org/docs/v0.3.0/guide/distribution/`
- Advanced options: `https://quickshell.org/docs/v0.3.0/guide/advanced/`
- FAQ: `https://quickshell.org/docs/v0.3.0/guide/faq/`
- Type reference (all namespaces): `https://quickshell.org/docs/v0.3.0/types`
- QtQuick types: `https://doc.qt.io/qt-6/qtquick-qmlmodule.html`
- Upstream mirror: `https://github.com/quickshell-mirror/quickshell`
- Examples: `https://git.outfoxxed.me/outfoxxed/quickshell-examples`

## Known Quirks

- The wrapper's `newshell` config path is fixed at build time, so config edits there take effect after the package is rebuilt through the normal Home Manager or flake flow.
- Use `newshelldev` when you want the wrapper to load the working-tree config at `${NEWXOS_FLAKE:-$HOME/newxos}/configs/quickshell` without rebuilding.
- Keep the template lightweight unless the repo starts managing a fuller shell layout.
- Breaking changes expected before 1.0; upstream will provide migration guides.
- `PanelWindow` in particular may not resolve in qmlls.

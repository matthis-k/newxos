# Dashboard Change Playbook

Use this when changing the QuickShell dashboard, quickmenu tabs, dashboard bar indicators, dashboard open/close behavior, tab switching, or dashboard service integration.

## Core Rule

Dashboard state belongs to `ShellState.qml`; dashboard UI consumes that state.

Do not duplicate dashboard open/close/tab state inside tab pages, bar delegates, or quickmenu content components.

## Ownership

### `ShellState.qml`
Owns dashboard phase, active tab, tab list, transition timing, and bar-expansion-for-dashboard state. All dashboard open/close/tab transitions go through its APIs. Source: `configs/newshell/services/ShellState.qml`.

### `modules/quickmenu/Window.qml`
Owns panel visibility, backdrop, animation, SwipeView, wheel/swipe tab navigation, syncing from ShellState.activeTab, Escape/outside-click close. Consumes `shellScreenState`; does not own canonical dashboard state.

### `modules/quickmenu/<Tab>.qml`
Owns page layout, section ordering, tab-specific rendering, small view-local formatting. Does not own global dashboard state.

### `modules/bar/`
Owns dashboard launch/indicator buttons, bar expansion rendering, calling `shellScreenState.openDashboard/toggleDashboard`. Does not duplicate active tab state.

### `services/`
Own system data, side effects, polling/watchers, shell command wrappers, long-lived model derivation. Dashboard pages prefer service APIs over direct shell commands.

## Change Routing

If adding a dashboard tab:
1. Add tab id to `ShellState.dashboardTabs`.
2. Add page to `quickmenu/Window.qml` in the same order.
3. Add bar icon/indicator in the same order if the tab should be reachable from the bar.
4. Add content page under `modules/quickmenu/`.
5. Keep tab id, page order, and bar order synchronized.

If tab switching is wrong: check `ShellState.normalizeTab()`, `tabIndex()`, `activeTab`, and `quickmenu/Window.syncCurrentTab()`.

If open/close is wrong: check `ShellState.dashboardPhase`, `openDashboard()`, `closeDashboard()`, `toggleDashboard()`.

If panel animation is wrong: check `quickmenu/Window.qml` panel progress, backdrop opacity, animation blocks.

If bar expansion is wrong: check `ShellState.barExpandedForDashboard` and `modules/bar/Bar.qml` right-side spacing.

If service value is wrong: fix the owning service, do not patch around stale data in the dashboard page.

## Tab Order Contract

`ShellState.dashboardTabs`, `quickmenu/Window.qml` SwipeView page order, and bar dashboard icon order must stay synchronized. If divergence is intentional, document why near the relevant code.

## Model/View Split

Tab pages may contain view-local formatting. Extract to `services/`, `components/`, or `utils/` when they accumulate: large data collection, cross-service model building, polling, shell commands, complex repeated row components.

## Do Not

- Duplicate `activeTab` or `dashboardPhase`.
- Let bar buttons directly mutate quickmenu internals.
- Let tab pages own dashboard open/close state.
- Bypass `ShellState` when opening/toggling dashboard tabs.
- Put long-lived polling in tab pages.
- Duplicate service actions across dashboard, launcher, and bar.

## Validation

After dashboard changes:
```bash
repo-gate newshell
```

When running the shell:
```bash
systemctl --user restart newshell
```

Manual checks: open from every bar icon, toggle active tab closes, switch tabs with bar icons and wheel/swipe, Escape and outside-click close, bar expansion with dashboard, each tab renders.

## Done Criteria

- ShellState remains single dashboard state owner.
- Tab order synchronized or divergence documented.
- Bar, quickmenu, and tab pages keep separate responsibilities.
- Service side effects in services where reusable.
- No new duplicated dashboard state introduced.

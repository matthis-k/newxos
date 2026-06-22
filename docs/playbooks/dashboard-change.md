# Dashboard Change Playbook

Use this when changing the QuickShell dashboard, quickmenu tabs, dashboard bar indicators, dashboard open/close behavior, tab switching, or dashboard service integration.

## Core Rule

Dashboard state belongs to `ShellState.qml`; dashboard UI consumes that state.

Do not duplicate dashboard open/close/tab state inside tab pages, bar delegates, or quickmenu content components.

## Canonical Structure

```txt
configs/newshell/services/ShellState.qml
  -> owns dashboard phase, active tab, tab list, transition timing

configs/newshell/modules/quickmenu/Window.qml
  -> owns panel window, backdrop, animation, SwipeView, tab host, swipe/wheel navigation

configs/newshell/modules/quickmenu/*.qml
  -> own tab page layout and content

configs/newshell/modules/bar/
  -> owns dashboard entry buttons/indicators

configs/newshell/services/
  -> own system data and side effects

configs/newshell/components/
  -> reusable dashboard rows/cards/controls
```

## Ownership

### `ShellState.qml`

Owns:

```txt
dashboardWidth
dashboardTabs
activeTab
dashboardPhase
dashboardOpen
barExpandedForDashboard
dashboardTransitionMs
normalizeTab(tab)
tabIndex(tab)
isIndicatorActive(tab)
openDashboard(tab)
closeDashboard()
toggleDashboard(tab)
stepDashboardTab(offset)
```

All dashboard open/close/tab transitions should go through these APIs.

### `modules/quickmenu/Window.qml`

Owns:

```txt
dashboard panel visibility
backdrop
panel animation
SwipeView
wheel/swipe tab navigation
syncing SwipeView index from ShellState.activeTab
Escape/outside-click close behavior
```

It should consume `shellScreenState`; it should not own canonical dashboard state.

### `modules/quickmenu/<Tab>.qml`

Owns:

```txt
page layout
section ordering
tab-specific rendering
small view-local formatting
```

It should not own global dashboard state.

If a tab starts deriving complex service models or owning shell side effects, extract that logic into a service, utility, or smaller component.

### `modules/bar/`

Owns:

```txt
dashboard launch/indicator buttons
bar expansion rendering
calling shellScreenState.openDashboard/toggleDashboard
```

It should not duplicate active tab state.

### `services/`

Own:

```txt
system data
system side effects
polling/watchers
shell command wrappers
long-lived model derivation
```

Dashboard pages should prefer service APIs over direct shell commands.

## Change Routing

If adding a dashboard tab:

```txt
1. Add tab id to ShellState.dashboardTabs.
2. Add page to quickmenu/Window.qml in the same order.
3. Add bar icon/indicator in the same order if the tab should be reachable from the bar.
4. Add content page under modules/quickmenu/.
5. Keep tab id, page order, and bar order synchronized.
```

If tab switching is wrong:

```txt
Check ShellState.normalizeTab(), tabIndex(), activeTab, and quickmenu/Window.syncCurrentTab().
```

If open/close behavior is wrong:

```txt
Check ShellState.dashboardPhase, openDashboard(), closeDashboard(), toggleDashboard(), finishTransition().
```

If panel animation is wrong:

```txt
Check quickmenu/Window.qml panelProgress, backdropOpacity, Behavior blocks, and dashboardTransitionMs.
```

If bar expansion is wrong:

```txt
Check ShellState.barExpandedForDashboard and modules/bar/Bar.qml right-side width/spacing behavior.
```

If dashboard content layout is wrong:

```txt
Fix the relevant tab page or shared component.
Do not change ShellState for content layout issues.
```

If a service value is wrong:

```txt
Fix the owning service.
Do not patch around stale or wrong service data inside the dashboard page.
```

If a dashboard page directly calls shell commands:

```txt
Prefer moving that action into the owning service when the action is reusable by launcher/actions/bar/dashboard.
```

## Tab Order Contract

The following must stay synchronized:

```txt
ShellState.dashboardTabs
quickmenu/Window.qml SwipeView page order
bar dashboard icon order
```

If you intentionally allow divergence, document why near the relevant code.

## Model/View Split Rule

Tab pages may contain simple view-local formatting.

Tab pages should not accumulate:

```txt
large data collection functions
cross-service model building
long-lived polling
shell command wrappers
complex repeated row components
```

When this happens, extract to:

```txt
services/<Domain>Service.qml
utils/<Domain>Model.js
components/dashboard/<ReusableThing>.qml
modules/quickmenu/<Domain>/<SmallComponent>.qml
```

## Do Not

* Do not duplicate `activeTab`.
* Do not duplicate `dashboardPhase`.
* Do not let bar buttons directly mutate quickmenu internals.
* Do not let tab pages own dashboard open/close state.
* Do not hardcode tab ids in many unrelated places without documenting the tab order contract.
* Do not bypass `ShellState.qml` when opening/toggling dashboard tabs.
* Do not put long-lived polling in tab pages.
* Do not duplicate service actions across dashboard, launcher, and bar.
* Do not introduce a dynamic tab system unless static tabs have become a proven maintenance problem.

## Validation

After dashboard changes:

```bash
nix run "path:$PWD#repo-gate"
```

When running the shell:

```bash
systemctl --user restart newshell
```

Manual checks:

```txt
- Open dashboard from every bar icon.
- Toggle currently active tab closes the dashboard if that is intended behavior.
- Switch tabs with bar icons.
- Switch tabs with horizontal wheel/swipe if supported.
- Press Escape to close.
- Click outside panel to close.
- Verify bar right side expands/contracts with dashboard.
- Verify each tab still renders.
- Verify no popup gets closed by outside-click behavior unexpectedly.
```

For service-backed tabs:

```txt
- Verify service values update.
- Verify action side effects work.
- Verify no duplicate polling/watchers were introduced.
```

## Done Criteria

A dashboard change is done when:

```txt
- ShellState remains the single dashboard state owner.
- Tab order is synchronized or divergence is documented.
- Bar, quickmenu window, and tab pages keep separate responsibilities.
- Service side effects live in services where reusable.
- No new duplicated dashboard state was introduced.
- Manual dashboard checks pass.
- The playbook is updated if dashboard ownership/workflow changed.
```

---
title: Dashboard improvements
type: note
permalink: newxos/tasks/dashboard-improvements
id: task-dashboard-improvements
links:
- task-quickshell-desktop-shell
- quickshell-design
- agents-index
status: doing
tags:
- task
- quickshell
- dashboard
updated: '2026-05-16'
---

# Dashboard improvements

## Context
Enhancements to the QuickShell dashboard based on user requirements for better navigation, stats visualization, and memory/storage tracking.

## Observations

- [fact] Dashboard tabs now include: overview, audio, notifications, bluetooth, wifi, energy, stats, datamemorystorage
- [fact] Bar indicators (StatusIcon) toggle dashboard tabs via `screenState.toggleDashboard(tabName)`
- [fact] Stats page shows CPU graph with toggleable legends, live stats (memory, swap, root disk), and network throughput
- [fact] SystemStats service collects data every 1s with disk enumeration support
- [decision] Section titles in overview act as navigation links to dedicated tabs
- [decision] Stats graphs support toggling via legend clicks (default: only average visible)
- [decision] Data/memory/storage tab shows RAM, swap, and per-disk/partition details with 5s updates
- [fact] All tasks completed successfully

## Relations

- extends [[task-quickshell-desktop-shell]]
- relates_to [[quickshell-design]]
- part_of [[agents-index]]

## Completed tasks

### 1. Overview section title navigation ✓
- Made Notifications section title clickable to navigate to notifications tab
- Made System stats section title clickable to navigate to stats tab
- Used existing `screenState.openDashboard(tabName)` mechanism
- Visual feedback on hover (color change to secondaryAccent)

### 2. Stats graph toggling ✓
- Removed duplicate CPU average display from live stats section
- Added legend click handlers to toggle individual graph series
- Default state: only average visible, cores hidden
- Created toggle mechanism in CpuGraph component
- Legend items show visual feedback (opacity, color) when disabled

### 3. Data/Memory/Storage tab ✓
- Created new `DataMemoryStorage.qml` page
- Added to ShellState dashboard tabs array
- Added bar indicator icon (DataMemoryStorageIcon)
- Dynamic table showing:
  - RAM: name, used/total, percentage (updates every 5s)
  - Swap: name, used/total, percentage (updates every 5s)
  - Per-disk/partition: mount point, used/total, percentage
- Each node shows: name, total/capacity, percentage
- Extended SystemStats service for disk enumeration
- Semi-live updates (5s interval) for all metrics

## Implementation details

### New files created
- `configs/quickshell/components/NavigableSectionHeader.qml` - Clickable section header wrapper
- `configs/quickshell/modules/quickmenu/DataMemoryStorage.qml` - New data/memory/storage tab
- `configs/quickshell/modules/bar/DataMemoryStorageIcon.qml` - Bar indicator for new tab

### Modified files
- `configs/quickshell/modules/quickmenu/Overview.qml` - Added navigable sections for notifications and stats
- `configs/quickshell/components/CpuGraph.qml` - Added legend toggle functionality
- `configs/quickshell/modules/quickmenu/Stats.qml` - Removed duplicate CPU InfoRow
- `configs/quickshell/services/SystemStats.qml` - Added disk enumeration and parsing
- `configs/quickshell/services/ShellState.qml` - Added datamemorystorage to dashboard tabs
- `configs/quickshell/modules/quickmenu/Window.qml` - Added DataMemoryStorage to SwipeView
- `configs/quickshell/modules/bar/Bar.qml` - Added DataMemoryStorageIcon to bar indicators

### Design decisions
- Followed existing patterns: DashboardPage, DashboardSection, InfoRow
- Used Config.spacing and Config.colors for consistency
- Respected flat design principles
- Graceful degradation for missing backends
- 5s update interval for data/memory/storage tab (balanced between live and performance)

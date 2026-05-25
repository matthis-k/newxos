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

- [fact] Dashboard source lives under `configs/quickshell/modules/quickmenu/`, `configs/quickshell/modules/bar/`, and `configs/quickshell/services/`
- [fact] Navigation and stats behavior are implemented in QML source; read source for current tabs, intervals, and service APIs
- [decision] Section titles in overview act as navigation links to dedicated tabs
- [decision] Stats graphs support toggling via legend clicks (default: only average visible)
- [decision] Data/memory/storage tab shows RAM, swap, and per-disk/partition details with 5s updates
- [fact] All tasks completed successfully

## Relations

- extends [[task-quickshell-desktop-shell]]
- relates_to [[quickshell-design]]
- part_of [[agents-index]]

## Source Index

- Dashboard pages: `configs/quickshell/modules/quickmenu/`.
- Bar indicators: `configs/quickshell/modules/bar/`.
- Shared dashboard components: `configs/quickshell/components/`.
- System metrics service: `configs/quickshell/services/Stats.qml`.
- Shared shell state: `configs/quickshell/services/ShellState.qml`.

## Durable Decisions

- Section titles can act as navigation affordances when they lead to a dedicated tab.
- Stats graph controls should keep graph visibility and legend state in one source of truth.
- Data-heavy dashboard pages should degrade gracefully when a backend is missing.
- Read QML source for exact tab names, update intervals, and component APIs.

---
title: QML Graph Goal
type: reference
permalink: newxos/patterns/qml-graph-goal
id: pattern-qml-graph-goal
status: active
links:
- pattern-qml-graph-requirements
- quickshell-design
- task-quickshell-desktop-shell
tags:
- qml
- quickshell
- graph
- architecture
---

# QML Graph Goal

## Context

The QuickShell UI needs a reusable graphing primitive for compact telemetry and future dashboard visualizations. The component should stay generic enough for any QML list-like data source, while fitting the existing flat QuickShell design.

## Observations

- [goal] Build a reusable QML graph component that manages multiple named graph series inside one view.
- [requirement] Accept data from list-like QML sources instead of assuming one owned JavaScript array shape.
- [decision] Keep data access, graph-series configuration, viewport/projection, and render scheduling as separate concerns.
- [requirement] Coalesce updates so multiple graph data changes in one tick cause one render pass.
- [decision] Prefer simple QML-friendly APIs first; optimize rendering internals only when profiling shows the need.

## Relations

- relates_to [[QML Graph Requirements]]
- relates_to [[QuickShell design guidelines]]
- relates_to [[QuickShell desktop shell requirements]]

## Goal

Create a `GraphView` component with child graph series that can render compact line-style telemetry and support future series types without rewriting callers.

The graph system should be useful for CPU, memory, battery, network, mathematical functions, and other dashboard data. It should support multiple visible or hidden named graphs, per-series styling, annotations, automatic or manual viewport behavior, and efficient redraw scheduling.

## Non-goals

- Do not implement a full charting framework with legends, interaction tooling, and export features.
- Do not make the component depend on a single stats service or QuickShell module.
- Do not introduce decorative visual effects that violate the flat QuickShell design rules.

## Design Direction

Use this conceptual split:

- `GraphView`: owns viewport, axes, markers, global bounds, graph ordering, and render scheduling.
- `Graph`: owns one named series descriptor, collector reference, visibility, and color mapping; data mutation stays in `DataCollector`.
- `DataCollector`: normalizes raw source samples, applies retention and viewport filtering, then maps to graph-ready `{ x, y }` points.
- Render scheduler: tracks dirty series and batches multiple updates into one paint request.

## Completion Shape

The first implementation is complete when existing QuickShell stats/battery graph usage can use the new API without leaving temporary task notes or one-off graph code paths.

## Implementation Ownership

- [fact] Graph implementation lives under `configs/quickshell/components/`.
- [fact] Telemetry collectors live under `configs/quickshell/services/`.
- [decision] Keep exact current caller wiring and graph series lists in QML source, not in memory.

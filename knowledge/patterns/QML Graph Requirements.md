---
title: QML Graph Requirements
type: reference
permalink: newxos/patterns/qml-graph-requirements
id: pattern-qml-graph-requirements
status: active
links:
- pattern-qml-graph-goal
- quickshell-design
tags:
- qml
- quickshell
- graph
- requirements
---

# QML Graph Requirements

## Context

These requirements define the reusable QML graph component API and behavior. They are intentionally implementation-oriented so future changes can keep the graph system maintainable.

## Observations

- [requirement] `GraphView` owns shared rendering context and batches redraws.
- [requirement] Each graph series is named, independently visible, independently styled, and independently dirty-tracked.
- [requirement] Bounds are calculated from visible, filtered, projected data unless an explicit viewport overrides them.
- [decision] Use numeric `z`/order values for stable render ordering instead of caller-provided comparator functions where possible.
- [requirement] Graph data changes must not force unrelated caller code to manually request repainting.

## Relations

- relates_to [[QML Graph Goal]]
- relates_to [[QuickShell design guidelines]]

## GraphView Requirements

`GraphView` should provide:

- `graphs`: array/list of graph series definitions.
- `markers`: array of annotations.
- `showXAxis`: bool.
- `showYAxis`: bool.
- `showLabels`: bool.
- `viewportMode`: `"auto"` or `"manual"`.
- `viewport`: `{ minX, maxX, minY, maxY }` for manual or computed visible range.
- `globalBounds`: union bounds for visible graphs.
- `padding`: graph content padding.
- `toScreen(x, y)`: world/data coordinates to component pixels.
- `batch(fn)`: defers repaint until grouped mutations finish.
- `requestRender(graphName, reason)`: marks a graph or global view concern dirty.

## Graph Requirements

Each graph series should provide:

- `name`: stable programmatic identifier, not a visual label.
- `visible`: whether the series draws and contributes to auto bounds.
- `z`: numeric render order.
- `collector`: source-owned data pipeline that exposes `calculate(viewport, seriesName)`, `rawBounds`, `points`, and `bounds`.
- `color`: static color fallback.
- `colorAt(x, y, index)`: optional graph-coordinate color function for thresholds.

## Data Source Requirements

The component should support these source forms through collector components:

- `TimedDataCollector` for long-lived sampled telemetry.
- `StaticDataCollector` for static/source-driven point lists.
- Custom `DataCollector` retention, viewport, and mapper functions.

Invalid points must be skipped:

- missing x/y
- `NaN`
- infinities
- `null` or `undefined`

## Projection Pipeline

The collector-backed point pipeline is:

```text
raw source sample
-> DataCollector normalization
-> retentionFilter
-> viewportFilter
-> mapper
-> graph-ready points
-> GraphView viewport
-> toScreen
-> render
```

Bounds are computed from graph-ready collector points. Hidden graphs do not contribute to `globalBounds`. Markers do not affect bounds unless a future explicit setting enables that.

## Markers

Markers should be annotations with at least:

- `type`: `"xLine"`, `"yLine"`, `"point"`, `"rangeX"`, or `"rangeY"`.
- `x`, `y`, `min`, `max` as applicable.
- `color`.
- `label`.
- `visible`.
- `labelVisible`.
- `z`.

The first implementation may support only the marker types used by callers, but the data shape should not block the rest.

## Redraw Requirements

Rendering must be scheduled, not immediate per mutation:

- Graph data changes mark that graph data-dirty.
- Graph style/color/visibility changes mark the relevant series dirty.
- Viewport, axis, marker, or size changes mark the view dirty.
- Multiple changes in one event tick should coalesce into one render request.
- `batch(fn)` suppresses intermediate repaints and schedules one final repaint if anything changed.

The first implementation may repaint one shared render surface. Per-series layer caching can be added later without changing the public API.

## Calculated Graph Requirements

Calculated graphs should live behind a collector mapper or a custom collector `calculate(viewport, seriesName)` implementation. `GraphView` should not own per-domain sampling or history state.

## QuickShell Visual Requirements

- Follow [[QuickShell design guidelines]].
- Use Catppuccin colors from `Config.colors` or semantic aliases from `Config.styling`.
- Avoid gradients, shadows, glass, and 3D effects in the component chrome.
- Keep graph details subtle and information-dense.
- Wrap user-visible labels with `qsTr()` in QML.

## Implementation Notes

- [fact] `GraphView` exposes `graphs`, `graphItems`, `markers`, `viewportMode`, `viewport`, `globalBounds`, `padding`, `toScreen()`, `batch()`, `setSeriesVisible()`, `toggleSeries()`, and `requestRender()`.
- [fact] `Graph` is a collector-backed series descriptor with `name`, `visible`, `z`, `color`, `colorAt`, and `collector`.
- [decision] Graph controls should derive enabled/disabled state from graph `visible` state and change visibility through `GraphView.setSeriesVisible()` or `GraphView.toggleSeries()` so rendering and controls share one source of truth.
- [decision] The first implementation keeps one shared render surface and coalesces paint requests; per-series render layers remain a future optimization.

## Viewport Notes
- [requirement] Default relative viewports should use `GraphView.globalBounds.maxX` as the raw x upper bound and render into normalized x coordinates from `0` to `xWindow`.
- [fact] `maxX` means the maximum x-axis bound. It must not encode domain semantics such as time; callers decide what x units mean.

## Windowing Notes

- [requirement] Relative retention trimming belongs in `DataCollector.retentionFilter`, anchored by collector raw bounds.
- [requirement] Relative viewport filtering belongs in `DataCollector.viewportFilter`; the default keeps one extra sample interval and clamps mapped x to `0` during drawing, so small sampling delays do not leave a visual gap at the left edge.

## Graph Signal Notes

- [requirement] `DataCollector` owns graph-ready `points` and `bounds`; `Graph` only references the collector and carries series metadata.
- [requirement] Collector collection emits graph changes through `Graph.dataChanged`; `GraphView` consumes collector raw bounds when computing `globalBounds`.

## Interval Marker Notes

- [requirement] `GraphView.xMarkerInterval` draws vertical markers at fixed x-axis intervals, measured in the graph's own x units.
- [fact] Current sampled graphs set `xMarkerInterval` in their own x units: CPU `30000`, memory `60000`, battery `3600000`.

## Relative X Transform

- [requirement] Relative default viewports keep `globalBounds` in raw graph x coordinates, then transform visible points into a normalized render viewport from `0` to `xWindow`.
- [requirement] `xMarkerInterval` markers are drawn in normalized viewport x units when `relativeX` is enabled, so markers stay visually stationary while raw x values advance.

## Removed Legacy Sampling

- [decision] `GraphView.dataSets`, panel-local sampling, and graph cache helpers were removed in favor of service-owned collectors.

## Collection Ownership Notes

- [decision] Long-lived telemetry history should be collected by data-source services at shell startup, not by panel-local graph views.
- [requirement] Data-source services should expose collectors with raw data, retention filtering, viewport filtering, and mapping before `GraphView` renders.
- [requirement] `GraphView` should treat collector-provided points as graph-ready viewport points and avoid reapplying its legacy relative-x transform to them.
- [fact] System CPU, memory, and battery graph histories are owned by centralized `Stats` `TimedDataCollector` instances.

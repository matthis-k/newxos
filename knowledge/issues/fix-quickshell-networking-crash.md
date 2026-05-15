---
title: Fix Quickshell Networking Crash
type: note
permalink: newxos/fix-quickshell-networking-crash
id: fix-quickshell-networking-crash
status: completed
tags:
- quickshell
- networking
- nmcli
- crash-fix
updated: 2026-05-14
---

# Fix Quickshell Networking Crash

## Observations

- [fact] Quickshell 0.3.0 crashes with segfault during Wi-Fi scan events due to `NMAccessPoint::~NMAccessPoint` use-after-free
- [technique] Replaced all `Quickshell.Networking` usage with `nmcli` via `Process`
- [decision] Community configs (`caelestia-dots/shell`, `end-4/dots-hyprland`) use identical pattern, avoiding `Quickshell.Networking` entirely
- [fact] Crash log: `~/.cache/quickshell/crashes/7gp2om70ft/report.txt`

## Relations

- relates_to [[quickshell]]
- relates_to [[issue-quickshell-networking-crash]]

## Problem

Quickshell 0.3.0 crashes with segfault during Wi-Fi scan events due to `NMAccessPoint::~NMAccessPoint` use-after-free in C++ networking implementation. Crash occurs at `QHash<QString, qs::network::NMAccessPoint*>::values()` when `device.networks.values` is accessed during scan.

## Root Cause

`Quickshell.Networking` triggers heavy C++ object churn on every AP change. `NMAccessPoint` objects are destroyed by libnm during scan events, but Quickshell's wrapper doesn't handle this gracefully, causing use-after-free.

## Solution

Replaced all `Quickshell.Networking` usage with `nmcli` via `Process`:

### Files Changed

- `configs/quickshell/services/NetworkService.qml` - New singleton service using nmcli
- `configs/quickshell/modules/quickmenu/Network.qml` - Rewritten to use NetworkService
- `configs/quickshell/modules/quickmenu/Overview.qml` - Removed Networking import
- `configs/quickshell/modules/bar/NetworkIcon.qml` - Uses NetworkService
- `configs/quickshell/modules/bar/OverviewIcon.qml` - Uses NetworkService

### Architecture

- **NetworkService.qml**: Singleton that polls nmcli for network state
  - `nmcli radio` - Wi-Fi enabled/hardware state
  - `nmcli general` - Connectivity state
  - `nmcli -g ACTIVE,SIGNAL,FREQ,SSID,BSSID,SECURITY d wifi` - Network list
  - `nmcli -g DEVICE,TYPE,STATE,IP4.ADDRESS device status` - Wired connection
  - `nmcli monitor` - State change detection (debounced 300ms)
  - `nmcli dev wifi list --rescan yes` - Manual scan
  - `nmcli dev wifi connect <ssid> [password <pw>]` - Connect
  - `nmcli con down id <name>` - Disconnect

### Key Patterns

- Parse nmcli output into plain JS objects/QtObject instances
- Manual lifecycle management with `rn.destroy()` for removed networks
- Debounced monitor events to prevent rapid-fire updates
- No C++ object references held across scan events

### References

- Community configs (`caelestia-dots/shell`, `end-4/dots-hyprland`) use identical pattern
- Both avoid `Quickshell.Networking` entirely due to this crash
- Crash log: `~/.cache/quickshell/crashes/7gp2om70ft/report.txt`

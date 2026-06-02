---
title: NordVPN OpenVPN chattr runtime dependency
type: issue
permalink: newxos/issues/nord-vpn-open-vpn-chattr-runtime-dependency
id: issue-nordvpn-openvpn-chattr
status: resolved
updated: '2026-06-02'
links:
- issues-index
- nord-vpn-firewall-blocks-avahi-m-dns-discovery
tags:
- issue
- networking
- nordvpn
- nixos
---

# NordVPN OpenVPN chattr runtime dependency

## Observations

- [fact] NordVPN login can succeed while server connection fails during tunnel setup.
- [fact] The daemon log line `exec: "chattr": executable file not found in $PATH` indicates the NordVPN service runtime PATH is missing `e2fsprogs`.
- [fact] The shared NordVPN module owns this dependency because both laptop and desktop use the same daemon packaging.
- [decision] Add `pkgs.e2fsprogs` to `systemd.services.nordvpn.path` instead of changing host-local config.

## Relations

- part_of [[Issues]]
- relates_to [[NordVPN firewall blocks Avahi mDNS discovery]]
- relates_to [[Workflow]]

## Source Pointers

- Shared module: `modules/network/nordvpn.nix`.
- Failure logs: `journalctl -u nordvpn.service -u nordvpn-bootstrap.service`.

## Prevention

When NordVPN reaches `CONNECTING` and immediately disconnects after login, inspect daemon logs for missing runtime tools before rotating tokens again.
---
title: NordVPN firewall blocks Avahi mDNS discovery
type: issue
permalink: newxos/issues/nord-vpn-firewall-blocks-avahi-m-dns-discovery
id: issue-nordvpn-firewall-mdns
status: resolved
updated: '2026-05-21'
tags:
- issue
- networking
- nordvpn
- avahi
---

# NordVPN firewall blocks Avahi mDNS discovery

## Observations

- [fact] Avahi SSH advertisement can appear only on loopback when `lo` is not denied; deny `lo` so services publish on LAN interfaces.
- [fact] With NordVPN connected, `nordvpn set firewall enabled` can suppress mDNS multicast on Wi-Fi even when `lan-discovery` is enabled.
- [fact] Shared NordVPN module owns reusable CLI allowlist wiring; concrete hosts own their mDNS policy
- [decision] Keep host-specific mDNS allowlist values in host source, not in shared defaults

## Relations

- relates_to [[Issues]]
- relates_to [[Agents]]
- relates_to [[Workflow]]

## Follow-up Decisions

- The shared NordVPN wrapper should expose generic allowlist and settings primitives; concrete hosts choose policy values.
- Potentially destructive default resets must be explicit and ordered before login-sensitive operations.
- Bootstrap scripts should treat idempotent `already` responses from the NordVPN CLI as success when the desired state is already reached.
- Login failure should stop later settings application so systemd retry behavior is clear.

## Source Pointers

- Shared module: `modules/network/`.
- Host-specific mDNS policy: concrete host modules under `modules/hosts/`.
- Read source for exact option names, systemd unit names, ports, subnets, and CLI command ordering.

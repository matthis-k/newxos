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
- [fact] The shared NordVPN module exposes generic `settings.allowlist.ports`, `settings.allowlist.portRanges`, and `settings.allowlist.subnets` options for the CLI allowlist.
- [decision] Concrete hosts configure the mDNS policy by allowlisting UDP port `5353` and subnet `224.0.0.0/24`; the shared module does not impose those defaults.

## Relations

- relates_to [[Issues]]
- relates_to [[Agents]]
- relates_to [[Workflow]]

## Follow-up

- [fact] The NordVPN wrapper now exposes the full observed `nordvpn set` surface: booleans, DNS servers, technology, auto-connect target/group, firewall mark, reset defaults, and allowlist ports/ranges/subnets.
- [decision] `set defaults` is represented as explicit `services.nordvpn.settings.resetDefaults`; it defaults to false so normal activation does not reset CLI state unless requested.

## Bootstrap design

- [decision] NordVPN bootstrap now generates a separate `configure-nordvpn` script from module options for easier inspection.
- [decision] The generated script runs `nordvpn set defaults` only when `services.nordvpn.settings.resetDefaults` is enabled; when enabled, the reset runs before login so it does not clear the active session.
- [technique] `allowlist_add` remains as a small helper because `nordvpn allowlist add` exits non-zero when an entry is already present.

## Login ordering

- [decision] `nordvpn-bootstrap` now waits for `network-online.target` and `NetworkManager-wait-online.service` when NetworkManager is enabled before login/settings.
- [decision] Login failure exits the service with failure before running the generated settings script; systemd restarts it on failure after 30 seconds.

## Activation bootstrap fix

- [fact] `nordvpn set meshnet disabled` can print `Meshnet is already disabled.` while exiting with status 1, so bootstrap scripts must treat idempotent `already` set responses as success.
- [fact] `nordvpn set defaults` can clear the current login session when run after token login, causing later `connect` to fail as not logged in.
- [decision] `services.nordvpn.settings.resetDefaults` defaults to false and, when explicitly enabled, runs before the bootstrap login step.

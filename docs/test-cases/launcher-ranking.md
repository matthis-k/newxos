# Launcher ranking expectations

Use `newshell ipc call query search '<query>'` after `systemctl --user restart newshell` to verify results. Source: `configs/quickshell/launcher/tools/collect-debug-search.sh`.

## Core checklist

Run these queries after any launcher search change:

`zen`, `zen `, `zen priv`, `zen win`, `zen browser`, `zen new`, `wifi`, `wifi `, `wifi on`, `wifi off`, `wifi toggle`, `toggle wifi`, `wo`, `wt`, `:`, `:wifi`, `:wifi `, `:wifi on`, `:db wifi`, `@apps`, `@apps zen`, `@apps wifi`, `db wifi`, `dashboard wifi`, `au`, `aud`, `audi`, `audio`, `en`, `screen`, `session`, `newxos`, `vpn of`, `notes`, `/tmp`

## Expected top/defaults

- `zen` — collapsible Zen group is the top result
- `zen ` (with trailing space) — Zen children visible
- `zen priv` / `zen win` — private / window actions win
- `wifi` / `wifi on` / `wifi off` / `wifi toggle` — toggle, on, off as queried
- `wo` — selects Wi-Fi on
- `wt` — selects Wi-Fi toggle
- `:` — gates to desktop actions
- `:wifi` / `:wifi on` — gated desktop action variants of Wi-Fi
- `@apps` — gates to desktop apps
- `db wifi` / `dashboard wifi` — selects Dashboard tab `wifi`
- `au` / `aud` / `audi` / `audio` — selects `Audio` over Dashboard tab `audio`; shows `Audio > <sink> > Streams`; the sink row has a live volume slider and mute-aware accent color, and `Audio` expands by default
- `session` — shows session group (Lock, Log Out, etc.)
- `newxos` — shows newxos group with direct children
- `notes` — does not activate files
- `/tmp` — activates files backend

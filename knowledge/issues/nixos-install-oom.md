---
id: issue-nixos-install-oom
type: issue
title: nixos-install OOM on low-memory live USB
status: active
tags:
- issue
- installation
- nixos
- oom
links:
- issues-index
- installation-low-memory-live-usb
updated: 2026-05-11
permalink: newxos/issues/nixos-install-oom
---

# nixos-install OOM on low-memory live USB

## Problem

`nixos-install` runs out of memory when installing from a low-memory live USB environment.

## Symptoms

- Build or copy processes are killed by OOM killer.
- Installation fails partway through.

## Cause

Nix builds require significant RAM, especially for large derivations. Low-memory live USBs (e.g. 4 GB) may not have enough.

## Workaround

- Use a live USB with more RAM.
- Enable swap before running `nixos-install`.
- Use a binary cache to avoid building large derivations locally.

## Related

- [[installation-low-memory-live-usb]]
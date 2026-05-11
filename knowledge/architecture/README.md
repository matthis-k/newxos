---
id: architecture-index
type: index
title: Architecture
status: active
tags:
- architecture
- nix
- newxos
links:
- architecture-flake-file
- architecture-import-tree
updated: 2026-05-11
permalink: newxos/architecture/readme
---

# Architecture

This folder describes the structural design of `newxos`.

Start here when working on:

- module organization
- generated `flake.nix`
- flake-file declarations
- import-tree behavior
- NixOS/Home Manager module boundaries

## Core notes

- [[architecture-flake-file]]
- [[architecture-import-tree]]
- [Dendritic Feature Modules](../patterns/dendritic-modules.md)

## Agent rule

Do not edit generated files directly when the project has a generator workflow.

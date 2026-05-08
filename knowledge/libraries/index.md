# Libraries

Important upstream libraries, tools, and configured programs used by this repo.

## How To Use This

- Start here for the rough map.
- Open the linked page when repo usage is non-trivial.
- Use upstream docs for exact options or behavior.

## Index

- `nixpkgs`: base package set, `lib`, NixOS modules, and most package selection. Use when touching packages, overlays, `lib.*`, or module options. Docs: `https://nixos.org/manual/nixpkgs/unstable/` and `https://nixos.org/manual/nixos/unstable/`
- [flake-parts](flake-parts.md): core flake module system. Use when changing `imports`, `perSystem`, `flake`, reusable modules, or `withSystem`. Docs: `https://flake.parts/`
- [flake-file](flake-file.md): generates the root `flake.nix` from repo declarations. Use when changing inputs or generated flake structure. Docs: `https://flake-file.oeiuwq.com/overview/`
- `import-tree`: recursively imports the `modules/` tree. Use when tree shape matters or new modules are not being seen. Docs: `https://import-tree.oeiuwq.com`
- [home-manager](home-manager.md): user-level config integration. Use when wiring users, home packages, or shared HM modules. Docs: `https://nix-community.github.io/home-manager/`
- [nh and nom](nh-nom.md): repo-owned CLI wrapper flow for NixOS, Home Manager, and direct flake actions. Use when changing `newxos`, fancy build output, or local flake command UX. Docs: `https://github.com/nix-community/nh` and `https://github.com/maralorn/nix-output-monitor`
- [stylix](stylix.md): theme plumbing and palette flow. Use when touching colors, generated themes, or Stylix targets. Docs: `https://nix-community.github.io/stylix/`
- [hyprland](hyprland.md): Wayland compositor and Lua config layout. Use when changing desktop session behavior or config file layout. Docs: `https://wiki.hypr.land/`
- `nix-index-database`: prebuilt `nix-index` database and modules for shell integration. Use when touching command-not-found, `comma`, or fish shell package lookup behavior. Docs: `https://github.com/nix-community/nix-index-database`
- `zen-flake`: Zen Browser package and Home Manager module. Use when touching the browser package source or its Home Manager integration. Docs: `https://github.com/0xc000022070/zen-browser-flake`
- `nordvpn-flake`: NordVPN service packaging used by the repo's VPN module. Use when touching NordVPN service wiring or its upstream package source. Docs: `https://github.com/connerohnesorge/nordvpn-flake`
- [disko](disko.md): declarative disk layout. Use when changing storage or install-time disk setup. Docs: `https://github.com/nix-community/disko/blob/master/docs/INDEX.md`
- [sops-nix](sops-nix.md): encrypted secret provisioning. Use when wiring secrets, keys, or secret-backed files. Docs: `https://github.com/Mic92/sops-nix`
- [nix-wrapper-modules](nix-wrapper-modules.md): wrapped end-user program packages. Use when the repo owns config for a program like `opencode`, `kitty`, or `neovim`. Docs: `https://github.com/BirdeeHub/nix-wrapper-modules`
- [workflow tooling](workflow-tooling.md): `treefmt-nix` and `git-hooks.nix`. Use when touching formatting, hooks, or local gate behavior. Docs: `https://github.com/numtide/treefmt-nix` and `https://github.com/cachix/git-hooks.nix`
- [opencode and MCP](opencode.md): wrapped assistant package plus configured MCP servers. Use when changing the local assistant setup. Docs: `https://opencode.ai/docs/config/`
- `mcp-nixos`: packaged Nix metadata MCP server used by the wrapped assistant. Use when the assistant needs upstream package or option truth. Docs: `https://github.com/utensils/mcp-nixos`

## Related Pages

- Repo layout: [Flake Structure](../flake-structure.md)
- Composition conventions: [Patterns](../patterns/index.md)
- Repeat mistakes: [Encountered Issues](../encountered_issues.md)

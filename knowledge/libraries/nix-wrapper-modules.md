# nix-wrapper-modules

`nix-wrapper-modules` builds wrapped end-user program packages with repo-owned configuration.

## What It Does Here

- Wraps `opencode`, `kitty`, and `neovim` as packages exposed by this flake.
- Lets the repo install a configured program instead of only a raw upstream package.
- Keeps wrapper logic in Nix and hand-written app config in `configs/`.

## Basics

- Use a wrapper when the repo should ship the program with opinionated config.
- Install wrapped packages from reusable Home Manager or NixOS modules via `withSystem` and `self'.packages`.
- Keep hand-written config in `configs/` and generated fragments in nearby modules when that split is cleaner.
- Related reading: [Wrapped Programs And Generated Config](../patterns/wrapped-programs.md), [Flake Structure](../flake-structure.md#configs).

## Short Example

```nix
packages.kitty = inputs.nix-wrapper-modules.wrappers.kitty.wrap {
  inherit pkgs;
  extraConfig = ''
    include ~/.config/kitty/stylix-theme.auto.conf
    ${builtins.readFile ../../configs/kitty/kitty.conf}
  '';
};
```

## Helpful Docs

- Upstream repo: `https://github.com/BirdeeHub/nix-wrapper-modules`

## Known Quirks Here

- Prefer the wrapper if this repo already exposes one for the program.
- Wrapper-owned generated config should usually be imported into hand-written config, not copied and duplicated by hand.

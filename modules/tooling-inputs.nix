{ ... }:
{
  flake-file = {
    formatter = pkgs: pkgs.nixfmt;

    inputs.git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    inputs.nix-wrapper-modules = {
      url = "github:BirdeeHub/nix-wrapper-modules";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    inputs.mcp-nixos = {
      url = "github:utensils/mcp-nixos";
    };

    inputs.treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}

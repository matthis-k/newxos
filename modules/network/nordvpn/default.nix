{ inputs, ... }:
{
  flake-file.inputs.nordvpn-flake = {
    url = "github:connerohnesorge/nordvpn-flake/f802a2efd8225116158371a8c85db28e7b0846dd";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}

_: {
  flake.modules.nixos.security = {
    security.sudo.wheelNeedsPassword = false;
  };
}

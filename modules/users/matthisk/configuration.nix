{ ... }:
{
  flake.modules.nixos.matthisk = {
    users.users.matthisk = {
      isNormalUser = true;
      description = "matthisk";
      extraGroups = [ "wheel" ];
    };
  };
}

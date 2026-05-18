{ inputs, ... }:
{
  flake.modules.nixos.networking = {
    imports = [ inputs.self.modules.nixos.nordvpn ];

    hardware.bluetooth.enable = true;
    hardware.bluetooth.powerOnBoot = true;
    hardware.bluetooth.settings = {
      General = {
        JustWorksRepairing = "always";
        FastConnectable = true;
        Experimental = true;
        KernelExperimental = true;
        Privacy = "device";
        SecureConnections = "on";
        ControllerMode = "dual";
        NameResolving = true;
        RefreshDiscovery = true;
      };
      Policy = {
        AutoEnable = true;
        ReconnectAttempts = 7;
        ReconnectIntervals = "1,2,4,8,16,32,64";
      };
    };
    networking.networkmanager.enable = true;

    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
      publish = {
        enable = true;
        addresses = true;
      };
    };
  };
}

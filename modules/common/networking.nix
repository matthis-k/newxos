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
      denyInterfaces = [
        "lo"
        "nordlynx"
        "tun0"
      ];
      nssmdns4 = true;
      openFirewall = true;
      publish = {
        enable = true;
        addresses = true;
        workstation = true;
      };
      extraServiceFiles.ssh = ''
        <?xml version="1.0" standalone='no'?><!--*-nxml-*-->
        <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
        <service-group>
          <name replace-wildcards="yes">%h SSH</name>
          <service>
            <type>_ssh._tcp</type>
            <port>22</port>
          </service>
        </service-group>
      '';
    };
  };
}

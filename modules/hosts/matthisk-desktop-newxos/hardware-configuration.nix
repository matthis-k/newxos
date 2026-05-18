_: {
  flake.modules.nixos.matthisk-desktop-newxos =
    {
      config,
      lib,
      modulesPath,
      ...
    }:
    {
      imports = [
        (modulesPath + "/installer/scan/not-detected.nix")
      ];

      boot.initrd.availableKernelModules = [
        "nvme"
        "xhci_pci"
        "ahci"
        "usbhid"
        "sd_mod"
      ];
      boot.initrd.kernelModules = [
        "nvidia"
        "nvidia_modeset"
        "nvidia_uvm"
        "nvidia_drm"
      ];
      boot.kernelModules = [ "kvm-amd" ];
      boot.kernelParams = [
        "amd_pstate=active"
        "nvidia_drm.fbdev=1"
        "nvidia_drm.modeset=1"
      ];
      boot.extraModulePackages = [ ];

      hardware.enableRedistributableFirmware = true;
      hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
      hardware.graphics.enable = true;
      hardware.graphics.enable32Bit = true;
      hardware.nvidia = {
        modesetting.enable = true;
        nvidiaSettings = true;
        open = true;
        package = config.boot.kernelPackages.nvidiaPackages.latest;
        powerManagement.enable = true;
      };

      services.xserver.videoDrivers = [ "nvidia" ];

      environment.variables = {
        GBM_BACKEND = "nvidia-drm";
        LIBVA_DRIVER_NAME = "nvidia";
        NVD_BACKEND = "direct";
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      };
    };
}

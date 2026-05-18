{
  inputs,
  self,
  withSystem,
  ...
}:
let
  sopsAgeKeyPath = builtins.getEnv "NEWXOS_INSTALLER_SOPS_KEY";
  sopsAgeKeySource =
    if sopsAgeKeyPath == "" then
      null
    else
      builtins.path {
        path = builtins.toPath sopsAgeKeyPath;
        name = "newxos-installer-sops-age-key.txt";
      };

  repoSource = builtins.path {
    path = self;
    name = "newxos-installer-source";
    filter =
      path: _type:
      !(builtins.elem (builtins.baseNameOf path) [
        ".git"
        ".direnv"
        "result"
      ]);
  };
in
{
  flake.modules.nixos.installerMedia =
    { lib, pkgs, ... }:
    {
      imports = lib.optionals (sopsAgeKeySource != null) (
        with inputs.self.modules.nixos;
        [
          sops
        ]
      );

      config = lib.mkMerge [
        {
          environment.etc."newxos-source".source = repoSource;
          environment.sessionVariables.NEWXOS_FLAKE = "/home/newxos/newxos";

          users.users.newxos = {
            isNormalUser = true;
            extraGroups = [
              "networkmanager"
              "video"
              "wheel"
            ];
            initialHashedPassword = "";
          };

          services.getty.autologinUser = lib.mkForce "newxos";

          system.activationScripts.newxosInstallerMutableFlake.text = ''
            if [ ! -e /home/newxos/newxos/flake.nix ]; then
              rm -rf /home/newxos/newxos
              install -d -m 0755 -o newxos -g users /home/newxos/newxos
              cp -R --no-preserve=mode,ownership /etc/newxos-source/. /home/newxos/newxos/
              chmod -R u+rwX /home/newxos/newxos
              chown -R newxos:users /home/newxos/newxos
            fi
          '';

          environment.systemPackages = [
            pkgs.curl
            pkgs.cryptsetup
            pkgs.dosfstools
            pkgs.git
            pkgs.gptfdisk
            pkgs.jq
            pkgs.lvm2
            pkgs.mdadm
            pkgs.nvme-cli
            pkgs.parted
            pkgs.pciutils
            pkgs.ripgrep
            pkgs.rsync
            pkgs.usbutils
            pkgs.vim
            pkgs.wget
          ]
          ++ withSystem pkgs.stdenv.hostPlatform.system ({ self', ... }: [ self'.packages.newxos ]);
        }

        (lib.optionalAttrs (sopsAgeKeySource != null) {
          environment.etc."newxos-sops-age-key.txt" = {
            source = sopsAgeKeySource;
            mode = "0400";
          };

          system.activationScripts.newxosInstallerSopsAgeKey.text = ''
            install -d -m 0750 -o root -g wheel /var/lib/sops-nix
            install -m 0440 -o root -g wheel /etc/newxos-sops-age-key.txt /var/lib/sops-nix/key.txt
          '';

          sops.secrets.github_token = {
            format = "binary";
            mode = "0444";
            path = "/run/secrets/github_token";
            sopsFile = ../../secrets/github_token;
          };
        })
      ];
    };
}

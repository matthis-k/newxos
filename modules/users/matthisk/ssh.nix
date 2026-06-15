_: {
  flake.modules.homeManager.matthisk-ssh = {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings = {
        "*" = {
          ForwardAgent = false;
          AddKeysToAgent = "no";
          Compression = false;
          ServerAliveInterval = 0;
          ServerAliveCountMax = 3;
          HashKnownHosts = false;
          UserKnownHostsFile = "~/.ssh/known_hosts";
          ControlMaster = "no";
          ControlPath = "~/.ssh/master-%r@%n:%p";
          ControlPersist = "no";
        };

        "matthisk-desktop-newxos desktop" = {
          HostName = "matthisk-desktop-newxos.local";
          IdentitiesOnly = true;
          IdentityFile = "/run/secrets/home_network_id";
          User = "matthisk";
        };

        "matthisk-laptop-newxos laptop" = {
          HostName = "matthisk-laptop-newxos.local";
          IdentitiesOnly = true;
          IdentityFile = "/run/secrets/home_network_id";
          User = "matthisk";
        };
      };
    };
  };
}

_: {
  flake.modules.nixos.ollama =
    { pkgs, ... }:
    {
      nix.settings.substituters = [
        "https://cache.nixos-cuda.org"
      ];
      nix.settings.trusted-public-keys = [
        "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
      ];

      services.ollama = {
        enable = true;
        package = pkgs.ollama-cuda;
        host = "0.0.0.0";
        loadModels = [
          "qwen2.5:7b"
          "dolphin-mistral:7b"
        ];
      };

      services.open-webui = {
        enable = true;
        host = "0.0.0.0";
        port = 3000;
        openFirewall = true;
        environment = {
          OLLAMA_BASE_URL = "http://localhost:11434";
        };
      };

      users.users.matthisk.extraGroups = [ "ollama" ];
    };
}

_: {
  flake.modules.nixos.ollama =
    { pkgs, ... }:
    {
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

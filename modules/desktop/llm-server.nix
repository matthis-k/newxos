_: {
  flake.modules.nixos.llm-server =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.services.llm-server;
      ttsServiceName = "kokoro-fastapi";
      ttsImage = "kokoro-fastapi-gpu-sm120:latest";
      webUIHostName = "matthisk-desktop-newxos.local";
      caddyLocalRootCert = "/run/caddy-local-root.crt";
      webUIPublicUrl = "https://${webUIHostName}";
      ollamaUrl = "http://localhost:${toString cfg.ollamaPort}";
      webUIUrl = "http://localhost:${toString cfg.webUIPort}";
      ttsUrl = "http://localhost:${toString cfg.ttsPort}/v1";
    in
    {
      options.services.llm-server = {
        enableOllama = (lib.mkEnableOption "Ollama LLM inference service") // {
          default = true;
        };

        enableOpenWebUI = (lib.mkEnableOption "Open WebUI frontend") // {
          default = true;
        };

        enableTTS = lib.mkEnableOption "local OpenAI-compatible Kokoro-FastAPI TTS service";

        ollamaHost = lib.mkOption {
          type = lib.types.str;
          default = "0.0.0.0";
          description = "Ollama bind address";
        };

        ollamaPort = lib.mkOption {
          type = lib.types.port;
          default = 11434;
          description = "Ollama port";
        };

        ollamaModels = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [
            "qwen2.5:7b"
            "qwen2.5-coder:7b"
            "dolphin-mistral:7b"
            "nomic-embed-text"
          ];
          description = "Ollama models to preload";
        };

        webUIPort = lib.mkOption {
          type = lib.types.port;
          default = 3000;
          description = "Open WebUI port";
        };

        webUIOpenFirewall = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Open firewall for Open WebUI";
        };

        ttsPort = lib.mkOption {
          type = lib.types.port;
          default = 8000;
          description = "Local TTS API port";
        };

        ttsVoice = lib.mkOption {
          type = lib.types.str;
          default = "af_heart";
          description = "Default Kokoro-FastAPI voice or voice formula";
        };

        ttsSplitOn = lib.mkOption {
          type = lib.types.enum [
            "punctuation"
            "paragraphs"
            "none"
          ];
          default = "punctuation";
          description = "Open WebUI TTS text splitting mode before sending requests to Kokoro-FastAPI";
        };

        ttsOpenFirewall = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Open firewall for local TTS";
        };
      };

      config = lib.mkIf (cfg.enableOllama || cfg.enableOpenWebUI || cfg.enableTTS) {
        nix.settings.substituters = [
          "https://cache.nixos-cuda.org"
        ];
        nix.settings.trusted-public-keys = [
          "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
        ];

        hardware.nvidia-container-toolkit.enable = lib.mkIf cfg.enableTTS true;

        virtualisation.docker.enable = lib.mkIf cfg.enableTTS true;

        services.ollama = lib.mkIf cfg.enableOllama {
          enable = true;
          package = pkgs.ollama-cuda;
          host = cfg.ollamaHost;
          loadModels = cfg.ollamaModels;
        };

        services.open-webui = lib.mkIf cfg.enableOpenWebUI {
          enable = true;
          host = "0.0.0.0";
          port = cfg.webUIPort;
          openFirewall = cfg.webUIOpenFirewall;
          environment = {
            ENABLE_PERSISTENT_CONFIG = "False";
            OLLAMA_BASE_URL = ollamaUrl;
            RAG_EMBEDDING_ENGINE = "ollama";
            RAG_EMBEDDING_BASE_URL = ollamaUrl;
            RAG_EMBEDDING_MODEL = "nomic-embed-text";
            WEBUI_URL = webUIPublicUrl;
          }
          // lib.optionalAttrs cfg.enableTTS {
            AUDIO_TTS_ENGINE = "openai";
            AUDIO_TTS_OPENAI_API_BASE_URL = ttsUrl;
            AUDIO_TTS_OPENAI_API_KEY = "not-needed";
            AUDIO_TTS_MODEL = "kokoro";
            AUDIO_TTS_VOICE = cfg.ttsVoice;
            # Open WebUI owns live playback chunking; Kokoro-FastAPI then streams
            # each OpenAI-compatible /v1/audio/speech request internally.
            AUDIO_TTS_SPLIT_ON = cfg.ttsSplitOn;
          };
        };

        services.caddy = lib.mkIf cfg.enableOpenWebUI {
          enable = true;
          openFirewall = true;
          virtualHosts.${webUIHostName}.extraConfig = ''
            tls internal
            reverse_proxy ${webUIUrl}
          '';
        };

        systemd.services.caddy-local-root-cert = lib.mkIf cfg.enableOpenWebUI {
          description = "Publish Caddy local root certificate for browsers";
          after = [ "caddy.service" ];
          requires = [ "caddy.service" ];
          wantedBy = [ "multi-user.target" ];

          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = pkgs.writeShellScript "publish-caddy-local-root-cert" ''
              set -eu

              source=/var/lib/caddy/.local/share/caddy/pki/authorities/local/root.crt

              for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30; do
                if [ -r "$source" ]; then
                  ${pkgs.coreutils}/bin/install -m 0444 -o root -g root "$source" ${caddyLocalRootCert}
                  exit 0
                fi

                ${pkgs.coreutils}/bin/sleep 1
              done

              printf 'Caddy local root certificate was not readable at %s\n' "$source" >&2
              exit 1
            '';
          };
        };

        systemd.services.${ttsServiceName} = lib.mkIf cfg.enableTTS {
          description = "Kokoro-FastAPI TTS Service";
          after = [ "docker.service" ];
          wants = [ "docker.service" ];
          wantedBy = [ "multi-user.target" ];

          serviceConfig = {
            Type = "simple";
            Restart = "always";
            RestartSec = 10;
            TimeoutStartSec = "5min";

            ExecStart = lib.concatStringsSep " " [
              "${pkgs.docker}/bin/docker"
              "run"
              "--rm"
              "--name"
              ttsServiceName
              "--device"
              "nvidia.com/gpu=all"
              "-p"
              "${toString cfg.ttsPort}:8880"
              ttsImage
            ];

            ExecStop = "${pkgs.docker}/bin/docker stop ${ttsServiceName}";
          };
        };

        networking.firewall.allowedTCPPorts = lib.optionals cfg.ttsOpenFirewall [ cfg.ttsPort ];

        users.users.matthisk.extraGroups = [
          "ollama"
          "docker"
        ];
      };
    };
}

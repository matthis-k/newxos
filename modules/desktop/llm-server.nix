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
    in
    {
      options.services.llm-server = {
        enableOllama = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable Ollama LLM inference service";
        };

        enableOpenWebUI = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable Open WebUI frontend";
        };

        enableKokoroTTS = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable Kokoro-FastAPI TTS service";
        };

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

        kokoroPort = lib.mkOption {
          type = lib.types.port;
          default = 8880;
          description = "Kokoro-FastAPI TTS port";
        };

        kokoroVoice = lib.mkOption {
          type = lib.types.enum [
            "af"
            "af_bella"
            "af_irulan"
            "af_nicole"
            "af_sarah"
            "af_sky"
            "am_adam"
            "am_michael"
            "am_gurney"
            "bf_emma"
            "bf_isabella"
            "bm_george"
            "bm_lewis"
          ];
          default = "bf_isabella";
          description = "Default Kokoro TTS voice";
        };

        kokoroOpenFirewall = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Open firewall for Kokoro TTS";
        };
      };

      config = lib.mkIf (cfg.enableOllama || cfg.enableOpenWebUI || cfg.enableKokoroTTS) {
        nix.settings.substituters = [
          "https://cache.nixos-cuda.org"
        ];
        nix.settings.trusted-public-keys = [
          "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
        ];

        virtualisation.docker.enable = lib.mkIf cfg.enableKokoroTTS true;

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
            OLLAMA_BASE_URL = "http://localhost:${toString cfg.ollamaPort}";
            RAG_EMBEDDING_ENGINE = "ollama";
            RAG_EMBEDDING_BASE_URL = "http://localhost:${toString cfg.ollamaPort}";
            RAG_EMBEDDING_MODEL = "nomic-embed-text";
          }
          // lib.optionalAttrs cfg.enableKokoroTTS {
            AUDIO_TTS_ENGINE = "openai";
            AUDIO_TTS_OPENAI_API_BASE_URL = "http://localhost:${toString cfg.kokoroPort}/v1";
            AUDIO_TTS_OPENAI_API_KEY = "not-needed";
            AUDIO_TTS_MODEL = "kokoro";
            AUDIO_TTS_VOICE = cfg.kokoroVoice;
            AUDIO_TTS_SPLIT_ON = "none";
          };
        };

        systemd.services.kokoro-tts = lib.mkIf cfg.enableKokoroTTS {
          description = "Kokoro-FastAPI TTS Service";
          after = [ "docker.service" ];
          wants = [ "docker.service" ];
          wantedBy = [ "multi-user.target" ];

          serviceConfig = {
            Type = "simple";
            Restart = "always";
            RestartSec = 10;
            TimeoutStartSec = "5min";

            ExecStartPre = "${pkgs.docker}/bin/docker pull ghcr.io/remsky/kokoro-fastapi-cpu:latest";

            ExecStart = lib.concatStrings [
              "${pkgs.docker}/bin/docker run --rm "
              "--name kokoro-tts "
              "--network host "
              "ghcr.io/remsky/kokoro-fastapi-cpu:latest"
            ];

            ExecStop = "${pkgs.docker}/bin/docker stop kokoro-tts";
          };
        };

        networking.firewall.allowedTCPPorts = lib.optionals cfg.kokoroOpenFirewall [ cfg.kokoroPort ];

        users.users.matthisk.extraGroups = [
          "ollama"
          "docker"
        ];
      };
    };
}

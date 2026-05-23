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
      ttsImage = "openedai-speech-xtts-sm120:torchcodec";
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

        enableTTS = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable local OpenAI-compatible XTTS service";
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

        ttsPort = lib.mkOption {
          type = lib.types.port;
          default = 8000;
          description = "Local TTS API port";
        };

        ttsModel = lib.mkOption {
          type = lib.types.enum [
            "tts-1-hd"
            "tts-1"
          ];
          default = "tts-1-hd";
          description = "OpenAI-compatible TTS model; tts-1-hd uses XTTS, tts-1 uses Piper";
        };

        ttsVoice = lib.mkOption {
          type = lib.types.enum [
            "alloy"
            "alloy-alt"
            "echo"
            "fable"
            "nova"
            "onyx"
            "shimmer"
          ];
          default = "alloy";
          description = "Default XTTS voice";
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

        systemd.tmpfiles.rules = lib.mkIf cfg.enableTTS [
          "d /var/lib/openedai-speech 0755 root root -"
          "d /var/lib/openedai-speech/config 0755 root root -"
          "d /var/lib/openedai-speech/voices 0755 root root -"
        ];

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
            OLLAMA_BASE_URL = "http://localhost:${toString cfg.ollamaPort}";
            RAG_EMBEDDING_ENGINE = "ollama";
            RAG_EMBEDDING_BASE_URL = "http://localhost:${toString cfg.ollamaPort}";
            RAG_EMBEDDING_MODEL = "nomic-embed-text";
          }
          // lib.optionalAttrs cfg.enableTTS {
            AUDIO_TTS_ENGINE = "openai";
            AUDIO_TTS_OPENAI_API_BASE_URL = "http://localhost:${toString cfg.ttsPort}/v1";
            AUDIO_TTS_OPENAI_API_KEY = "not-needed";
            AUDIO_TTS_MODEL = cfg.ttsModel;
            AUDIO_TTS_VOICE = cfg.ttsVoice;
            AUDIO_TTS_SPLIT_ON = "none";
          };
        };

        systemd.services.openedai-speech = lib.mkIf cfg.enableTTS {
          description = "OpenedAI Speech XTTS Service";
          after = [ "docker.service" ];
          wants = [ "docker.service" ];
          wantedBy = [ "multi-user.target" ];

          serviceConfig = {
            Type = "simple";
            Restart = "always";
            RestartSec = 10;
            TimeoutStartSec = "5min";

            ExecStartPre = "${pkgs.bash}/bin/sh -c '${pkgs.docker}/bin/docker image inspect ${ttsImage} >/dev/null 2>&1 || ${pkgs.docker}/bin/docker build -t ${ttsImage} ${./.}/xtts-gpu-fix'";

            ExecStart = lib.concatStrings [
              "${pkgs.docker}/bin/docker run --rm "
              "--name openedai-speech "
              "--network host "
              "--device nvidia.com/gpu=all "
              "-e PRELOAD_MODEL=xtts "
              "-e TTS_HOME=/app/voices "
              "-e HF_HOME=/app/voices "
              "-v /var/lib/openedai-speech/config:/app/config "
              "-v /var/lib/openedai-speech/voices:/app/voices "
              ttsImage
            ];

            ExecStop = "${pkgs.docker}/bin/docker stop openedai-speech";
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

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
          description = "Enable Kokoro-FastAPI TTS service (OpenAI-compatible, emotional voices)";
        };

        enableComfyUI = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable ComfyUI Stable Diffusion image generation";
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

        kokoroOpenFirewall = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Open firewall for Kokoro TTS";
        };

        comfyUIPort = lib.mkOption {
          type = lib.types.port;
          default = 8188;
          description = "ComfyUI web interface port";
        };

        comfyUIDataDir = lib.mkOption {
          type = lib.types.path;
          default = "/var/lib/comfyui";
          description = "ComfyUI data directory for models, outputs, and custom nodes";
        };

        comfyUIOpenFirewall = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Open firewall for ComfyUI";
        };

        comfyUIModelUrl = lib.mkOption {
          type = lib.types.str;
          default = "https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.safetensors";
          description = "URL to download the default Stable Diffusion model checkpoint";
        };

        comfyUIModelName = lib.mkOption {
          type = lib.types.str;
          default = "v1-5-pruned-emaonly.safetensors";
          description = "Filename for the downloaded model checkpoint";
        };
      };

      config =
        lib.mkIf (cfg.enableOllama || cfg.enableOpenWebUI || cfg.enableKokoroTTS || cfg.enableComfyUI)
          {
            nix.settings.substituters = [
              "https://cache.nixos-cuda.org"
            ];
            nix.settings.trusted-public-keys = [
              "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
            ];

            virtualisation.docker.enable = lib.mkIf (cfg.enableKokoroTTS || cfg.enableComfyUI) true;

            hardware.nvidia-container-toolkit.enable = lib.mkIf (cfg.enableKokoroTTS || cfg.enableComfyUI) true;

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
              environment = lib.filterAttrs (_: v: v != null) {
                OLLAMA_BASE_URL = "http://localhost:${toString cfg.ollamaPort}";
                AUDIO_TTS_ENGINE = lib.mkIf cfg.enableKokoroTTS "openai";
                AUDIO_TTS_OPENAI_API_BASE_URL = lib.mkIf cfg.enableKokoroTTS "http://localhost:${toString cfg.kokoroPort}/v1";
                AUDIO_TTS_OPENAI_API_KEY = lib.mkIf cfg.enableKokoroTTS "not-needed";
                AUDIO_TTS_MODEL = lib.mkIf cfg.enableKokoroTTS "kokoro";
                AUDIO_TTS_VOICE = lib.mkIf cfg.enableKokoroTTS "bf_isabella";
                AUDIO_TTS_SPLIT_ON = lib.mkIf cfg.enableKokoroTTS "none";
                IMAGE_GENERATION_ENGINE = lib.mkIf cfg.enableComfyUI "comfyui";
                IMAGE_GENERATION_COMFYUI_URL = lib.mkIf cfg.enableComfyUI "http://localhost:${toString cfg.comfyUIPort}";
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

            systemd.services.comfyui = lib.mkIf cfg.enableComfyUI {
              description = "ComfyUI Stable Diffusion Service";
              after = [ "docker.service" ];
              wants = [ "docker.service" ];
              wantedBy = [ "multi-user.target" ];

              serviceConfig = {
                Type = "simple";
                Restart = "always";
                RestartSec = 10;
                TimeoutStartSec = "10min";

                ExecStartPre = [
                  "${pkgs.bash}/bin/bash -c '${pkgs.coreutils}/bin/mkdir -p ${cfg.comfyUIDataDir}/{models,output,input} && ${pkgs.coreutils}/bin/mkdir -p ${cfg.comfyUIDataDir}/models/checkpoints'"
                  "${pkgs.bash}/bin/bash -c 'test -f ${cfg.comfyUIDataDir}/models/checkpoints/${cfg.comfyUIModelName} || ${pkgs.curl}/bin/curl -L -o ${cfg.comfyUIDataDir}/models/checkpoints/${cfg.comfyUIModelName} ${cfg.comfyUIModelUrl}'"
                  "${pkgs.docker}/bin/docker pull ghcr.io/ai-dock/comfyui:latest"
                ];

                ExecStart = lib.concatStrings [
                  "${pkgs.docker}/bin/docker run --rm "
                  "--name comfyui "
                  "--device nvidia.com/gpu=all "
                  "-p ${toString cfg.comfyUIPort}:8188 "
                  "-v ${cfg.comfyUIDataDir}/models:/opt/ComfyUI/models:rw "
                  "-v ${cfg.comfyUIDataDir}/output:/opt/ComfyUI/output:rw "
                  "-v ${cfg.comfyUIDataDir}/input:/opt/ComfyUI/input:rw "
                  "-e CLI_ARGS='--listen 0.0.0.0' "
                  "ghcr.io/ai-dock/comfyui:latest"
                ];

                ExecStop = "${pkgs.docker}/bin/docker stop comfyui";
              };
            };

            networking.firewall = {
              allowedTCPPorts =
                lib.optionals cfg.kokoroOpenFirewall [ cfg.kokoroPort ]
                ++ lib.optionals cfg.comfyUIOpenFirewall [ cfg.comfyUIPort ];
            };

            users.users.matthisk.extraGroups = [
              "ollama"
              "docker"
            ];
          };
    };
}

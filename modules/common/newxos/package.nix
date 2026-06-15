{ inputs, ... }:
{
  perSystem =
    {
      self',
      pkgs,
      lib,
      ...
    }:
    let
      inherit (pkgs.stdenv.hostPlatform) system;
      diskoPackage = inputs.disko.packages.${system}.disko or inputs.disko.packages.${system}.default;

      runtimeInputs =
        with pkgs;
        [
          bash
          coreutils
          diskoPackage
          gnugrep
          jq
          nh
          nix
          nixos-install-tools
          nix-output-monitor
          ripgrep
          util-linux
          self'.packages.basic-memory-uv2nix
        ]
        ++ (lib.optionals (self'.packages ? opencode) [ self'.packages.opencode ]);

      newxos-cli = pkgs.rustPlatform.buildRustPackage {
        pname = "newxos";
        version = "0.1.0";
        src = ../../../packages/newxos-cli;
        cargoHash = "sha256-4gbEISaUTGB5ph/KWlQZ5pXTERDExBXVUV/RqcR5wxE=";
      };

      dynamicCompletions = ''

        # Dynamic completions for newxos
        complete -c newxos -n '__fish_seen_subcommand_from switch; and not __fish_seen_argument -l git-only' -l git-only -d 'Use git flake ref'
        complete -c newxos -n '__fish_seen_subcommand_from os; and __fish_seen_subcommand_from switch boot build; and not __fish_seen_argument -l git-only' -l git-only -d 'Use git flake ref'
        complete -c newxos -n '__fish_seen_subcommand_from home; and __fish_seen_subcommand_from switch build; and not __fish_seen_argument -l git-only' -l git-only -d 'Use git flake ref'
        complete -c newxos -n '__fish_seen_subcommand_from flake; and __fish_seen_subcommand_from build check show run; and not __fish_seen_argument -l git-only' -l git-only -d 'Use git flake ref'

        complete -c newxos -n '__fish_seen_subcommand_from switch; and test (count (commandline -opc)) -eq 2' -a '(newxos _complete nixos-hosts 2>/dev/null)'
        complete -c newxos -n '__fish_seen_subcommand_from first-install; and test (count (commandline -opc)) -eq 2' -a '(newxos _complete nixos-hosts 2>/dev/null)'
        complete -c newxos -n '__fish_seen_subcommand_from os; and __fish_seen_subcommand_from switch boot build; and test (count (commandline -opc)) -eq 3' -a '(newxos _complete nixos-hosts 2>/dev/null)'
        complete -c newxos -n '__fish_seen_subcommand_from home; and __fish_seen_subcommand_from switch build; and test (count (commandline -opc)) -eq 3' -a '(newxos _complete home-configs 2>/dev/null)'
        complete -c newxos -n '__fish_seen_subcommand_from flake; and __fish_seen_subcommand_from build check show; and test (count (commandline -opc)) -eq 3' -a '(newxos _complete nixos-hosts 2>/dev/null)'
        complete -c newxos -n '__fish_seen_subcommand_from flake; and __fish_seen_subcommand_from run; and test (count (commandline -opc)) -eq 3' -a '(newxos _complete run-targets 2>/dev/null)'
      '';
    in
    {
      packages.newxos =
        pkgs.runCommand "newxos"
          {
            nativeBuildInputs = [ pkgs.makeWrapper ];
          }
          ''
            mkdir -p $out/bin $out/share/fish/vendor_completions.d

            cp ${newxos-cli}/bin/newxos $out/bin/newxos
            chmod +w $out/bin/newxos

            source ${pkgs.makeWrapper}/nix-support/setup-hook
            wrapProgram $out/bin/newxos \
              --prefix PATH : ${lib.makeBinPath runtimeInputs}

            $out/bin/newxos completions fish > $out/share/fish/vendor_completions.d/newxos.fish
            cat >> $out/share/fish/vendor_completions.d/newxos.fish <<'FISH'
            ${dynamicCompletions}
            FISH
          '';
    };
}

_: {
  perSystem =
    { pkgs, ... }:
    {
      packages.newxos-completions = pkgs.writeTextDir "share/fish/vendor_completions.d/newxos.fish" ''
        function __fish_newxos_words
          commandline -opc
        end

        function __fish_newxos_wants_nixos_host
          set -l words (__fish_newxos_words)
          test (count $words) -ge 2; or return 1
          if test "$words[2]" = switch
            test (count $words) -eq 2; and return 0
            return 1
          end
          test (count $words) -eq 3; or return 1
          test "$words[2]" = os; or return 1
          contains -- "$words[3]" switch boot build
        end

        function __fish_newxos_wants_build_iso_flag
          set -l words (__fish_newxos_words)
          test (count $words) -ge 2; or return 1
          test "$words[2]" = build-iso
        end

        function __fish_newxos_wants_first_install_host
          set -l words (__fish_newxos_words)
          test (count $words) -eq 2; or return 1
          test "$words[2]" = first-install
        end

        function __fish_newxos_wants_home_config
          set -l words (__fish_newxos_words)
          test (count $words) -eq 3; or return 1
          test "$words[2]" = home; or return 1
          contains -- "$words[3]" switch build
        end

        function __fish_newxos_wants_flake_host
          set -l words (__fish_newxos_words)
          test (count $words) -eq 3; or return 1
          test "$words[2]" = flake; or return 1
          contains -- "$words[3]" build check show
        end

        function __fish_newxos_wants_run_target
          set -l words (__fish_newxos_words)
          test (count $words) -eq 3; or return 1
          test "$words[2]" = flake; or return 1
          test "$words[3]" = run
        end

        function __fish_newxos_supports_git_only
          set -l words (__fish_newxos_words)
          test (count $words) -ge 3; or return 1

          if test "$words[2]" = switch
            return 0
          end

          switch "$words[2]:$words[3]"
            case 'os:switch' 'os:boot' 'os:build' 'home:switch' 'home:build' 'flake:build' 'flake:check' 'flake:show' 'flake:run'
              return 0
          end

          return 1
        end

        function __fish_newxos_wants_clean_flag
          set -l words (__fish_newxos_words)
          test (count $words) -ge 2; or return 1
          test "$words[2]" = clean
        end

        complete -c newxos -f
        complete -c newxos -n 'not __fish_seen_subcommand_from build-iso first-install switch os home flake ai git reload_shell dev_mode memory clean' -a 'build-iso first-install switch os home flake ai git reload_shell dev_mode memory clean'
        complete -c newxos -n '__fish_seen_subcommand_from os; and not __fish_seen_subcommand_from switch boot build' -a 'switch boot build'
        complete -c newxos -n '__fish_seen_subcommand_from home; and not __fish_seen_subcommand_from switch build' -a 'switch build'
        complete -c newxos -n '__fish_seen_subcommand_from flake; and not __fish_seen_subcommand_from build check show run' -a 'build check show run'
        complete -c newxos -n '__fish_seen_subcommand_from memory; and not __fish_seen_subcommand_from reindex reset' -a 'reindex reset'

        complete -c newxos -n '__fish_newxos_wants_build_iso_flag; and not __fish_seen_argument -l key' -l key -r -d 'Embed SOPS age key in ISO'
        complete -c newxos -n '__fish_newxos_wants_nixos_host' -a '(newxos _complete nixos-hosts 2>/dev/null)'
        complete -c newxos -n '__fish_newxos_wants_first_install_host' -a '(newxos _complete nixos-hosts 2>/dev/null)'
        complete -c newxos -n '__fish_newxos_wants_home_config' -a '(newxos _complete home-configs 2>/dev/null)'
        complete -c newxos -n '__fish_newxos_wants_flake_host' -a '(newxos _complete nixos-hosts 2>/dev/null)'
        complete -c newxos -n '__fish_newxos_wants_run_target' -a '(newxos _complete run-targets 2>/dev/null)'
        complete -c newxos -n '__fish_newxos_supports_git_only; and not __fish_seen_argument -l git-only' -l git-only -d 'Use git flake ref'
        complete -c newxos -n '__fish_newxos_wants_clean_flag; and not __fish_seen_argument -s k -l keep' -s k -l keep -r -d 'Keep at least this many generations'
        complete -c newxos -n '__fish_newxos_wants_clean_flag; and not __fish_seen_argument -s K -l keep-since' -s K -l keep-since -r -d 'Keep generations and gcroots newer than a duration'
        complete -c newxos -n '__fish_newxos_wants_clean_flag; and not __fish_seen_argument -s v -l verbose' -s v -l verbose -d 'Increase logging verbosity'
        complete -c newxos -n '__fish_newxos_wants_clean_flag; and not __fish_seen_argument -s q -l quiet' -s q -l quiet -d 'Decrease logging verbosity'
        complete -c newxos -n '__fish_newxos_wants_clean_flag; and not __fish_seen_argument -s e -l elevation-strategy' -s e -l elevation-strategy -r -d 'Set privilege elevation strategy'
        complete -c newxos -n '__fish_newxos_wants_clean_flag; and not __fish_seen_argument -s n -l dry' -s n -l dry -d 'Print actions without removing anything'
        complete -c newxos -n '__fish_newxos_wants_clean_flag; and not __fish_seen_argument -s a -l ask' -s a -l ask -d 'Ask for confirmation before cleaning'
        complete -c newxos -n '__fish_newxos_wants_clean_flag; and not __fish_seen_argument -l no-gc' -l no-gc -d 'Skip nix store garbage collection'
        complete -c newxos -n '__fish_newxos_wants_clean_flag; and not __fish_seen_argument -l no-gcroots' -l no-gcroots -d 'Keep gcroots such as result links'
        complete -c newxos -n '__fish_newxos_wants_clean_flag; and not __fish_seen_argument -l optimise' -l optimise -d 'Run nix-store --optimise after gc'
        complete -c newxos -n '__fish_newxos_wants_clean_flag; and not __fish_seen_argument -l max' -l max -r -d 'Limit bytes freed during nix store gc'
        complete -c newxos -n '__fish_newxos_wants_clean_flag; and not __fish_seen_argument -s h -l help' -s h -l help -d 'Show nh clean help'
      '';
    };
}

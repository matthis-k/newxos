{ ... }:
{
  flake.templates = {
    dendritic-simple-module = {
      path = ../templates/dendritic-simple-module;
      description = "Minimal dendritic module template with documented flake-file and flake-parts pitfalls.";
      welcomeText = ''
        Start in `modules/example-message.nix`.

        This template shows a small, focused flake-parts module inside a
        flake-file + dendritic layout. If you later add inputs or change root
        flake wiring, regenerate `flake.nix` with `nix run "path:$PWD#write-flake"`.
      '';
    };

    dendritic-workflow-module = {
      path = ../templates/dendritic-workflow-module;
      description = "Dendritic workflow module template showing upstream flake module imports and common pitfalls.";
      welcomeText = ''
        Start in `modules/workflow.nix` and `modules/workflow-inputs.nix`.

        This template shows how to keep flake-file input declarations separate
        from the flake-parts module that uses them, and calls out the common
        `inputs`/`self` mistakes along the way.
      '';
    };
  };
}

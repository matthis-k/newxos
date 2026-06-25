{ pkgs, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      handoffPkg = pkgs.rustPlatform.buildRustPackage {
        pname = "repo-handoff";
        version = "0.1.0";
        src = ../../tools/handoff;
        cargoHash = "";
        meta.mainProgram = "repo-handoff";
      };
    in
    {
      packages.repo-handoff = handoffPkg;

      apps.repo-handoff = {
        type = "app";
        program = "${handoffPkg}/bin/repo-handoff";
        meta.description = "Path-aware handoff and correctness gate for repo changes";
      };
    };
}

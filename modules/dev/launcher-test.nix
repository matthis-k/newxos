_: {
  perSystem =
    { pkgs, ... }:
    let
      launcherTestPkg = pkgs.rustPlatform.buildRustPackage {
        pname = "newshell-launcher-test";
        version = "0.1.0";
        src = ../../tools/launcher-test;
        cargoHash = "sha256-fx/9r/weuPwMuXM8g5QWyGewwcXx2gNYsdvyK3hyb/Q=";
        meta.mainProgram = "newshell-launcher-test";
      };
    in
    {
      packages.newshell-launcher-test = launcherTestPkg;

      apps.newshell-launcher-test = {
        type = "app";
        program = "${launcherTestPkg}/bin/newshell-launcher-test";
        meta.description = "Run launcher test cases against a newshell instance via semantic IPC";
      };
    };
}

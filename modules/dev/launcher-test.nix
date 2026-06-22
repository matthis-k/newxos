_: {
  perSystem =
    { pkgs, ... }:
    let
      launcherTestPkg = pkgs.rustPlatform.buildRustPackage {
        pname = "newshell-launcher-test";
        version = "0.1.0";
        src = ../../tools/launcher-test;
        cargoHash = "sha256-UzuELgcBOVQhH7cSvax1s1BgZ1xyo0+2Fm3Oh5Vv2r0=";
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

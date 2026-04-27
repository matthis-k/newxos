{ ... }:
{
  perSystem =
    {
      pkgs,
      self',
      ...
    }:
    {
      packages.example-message = pkgs.writeShellScriptBin "example-message" ''
        printf '%s\n' "hello from a small dendritic module"
      '';

      apps.example-message.program = "${self'.packages.example-message}/bin/example-message";
    };
}

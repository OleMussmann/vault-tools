{
  description = "vault and stack — CLI tooling for the Hermes/Pi shared memory vault";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      rev = self.rev or "dirty";
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          vault = pkgs.writeShellApplication {
            name = "vault";
            runtimeInputs = with pkgs; [
              git
              coreutils
              gnused
              gnugrep
              ripgrep
            ];
            text = builtins.replaceStrings [ "@VAULT_TOOLS_REV@" ] [ rev ] (
              builtins.readFile ./bin/vault
            );
          };

          stack = pkgs.writeShellApplication {
            name = "stack";
            runtimeInputs = with pkgs; [
              git
              coreutils
              gnused
              gnugrep
              jq
              curl
              incus
            ];
            text = builtins.readFile ./bin/stack;
          };

          default = self.packages.${system}.vault;
        }
      );
    };
}

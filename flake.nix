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

          # For deployment into the Hermes container, which has no /nix/store:
          # writeShellApplication's wrapper (above) bakes in an absolute-path
          # shebang and PATH from runtimeInputs, neither of which resolve
          # there. This builds straight from the source file instead — its
          # own shebang (#!/usr/bin/env bash) is already portable, so there's
          # no wrapper to strip. Same source, still shellchecked, just not
          # Nix-wrapped. Relies on bin/vault's own command -v preflight
          # (git, sed, grep, rg) in place of runtimeInputs pinning — those
          # are confirmed present on the stock Hermes image's PATH.
          vault-hermes = pkgs.runCommand "vault-hermes" { nativeBuildInputs = [ pkgs.shellcheck ]; } ''
            substitute ${./bin/vault} vault --replace-fail '@VAULT_TOOLS_REV@' '${rev}'
            shellcheck vault
            install -Dm555 vault $out/bin/vault
          '';

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

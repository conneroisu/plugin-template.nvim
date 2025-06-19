{
  description = "A development shell for neovim plugins";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = inputs @ {nixpkgs, ...}: let
    supportedSystems = [
      "x86_64-linux"
      "x86_64-darwin"
      "aarch64-linux"
      "aarch64-darwin"
    ];
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
  in {
    devShells = forAllSystems (system: let
      pkgs = import nixpkgs {
        inherit system;
      };

      scripts = {
        dx = {
          exec = ''$EDITOR "$REPO_ROOT"/flake.nix'';
          description = "Edit flake.nix";
        };
      };

      scriptPackages =
        pkgs.lib.mapAttrs
        (
          name: script:
            pkgs.writeShellApplication {
              inherit name;
              text = script.exec;
              runtimeInputs = script.deps or [];
            }
        )
        scripts;
    in {
      default = pkgs.mkShell {
        name = "dev";

        # Available packages on https://search.nixos.org/packages
        packages = with pkgs;
          [
            alejandra # Nix
            nixd
            statix
            deadnix

            lua
            luarocks
            lua-language-server
            stylua
            yaml-language-server
            actionlint
          ]
          ++ builtins.attrValues scriptPackages;

        shellHook = ''
          export REPO_ROOT=$(git rev-parse --show-toplevel)
        '';
      };
    });
  };
}

{
  description = "draperu-cardano";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ self, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-darwin" ];

      perSystem = { config, pkgs', self', inputs', system, ... }:
        let
          pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [ ];
          };
        in {
          devShells.default = pkgs.mkShell {
            buildInputs = [
              pkgs.bun
              pkgs.nodejs
              pkgs.aiken
              pkgs.typescript-language-server
              pkgs.vscode-langservers-extracted
              pkgs.prettierd
            ];
          };
        };
    };
}

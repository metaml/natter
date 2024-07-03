{
  description = "natter";

  inputs = {
    nixpkgs     = { url = "nixpkgs/nixpkgs-unstable"; };
    flake-utils = { url = "github:numtide/flake-utils"; };
    poetry2nix  = { url = "github:nix-community/poetry2nix";
                    inputs.nixpkgs.follows = "nixpkgs";
                  };
  };
  
  outputs = { self, nixpkgs, flake-utils, poetry2nix }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        inherit (poetry2nix.lib.mkPoetry2Nix { inherit pkgs; }) mkPoetryApplication;
      in {
        devShells.default = pkgs.mkShell {
          buildInput = with pkgs; [
            pypy
            python
          ];
          inputsFrom = [ self.packages.${system}.default ];
          shellHook = ''
            export PYTHONPATH=./src:$PYTHONPATH
            export LANG=en_US.UTF-8
            export PS1="natter|$PS1"
          '';
        };

        packages.default = mkPoetryApplication {
          projectDir = self;
        };
      }
    );
}


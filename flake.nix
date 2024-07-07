{
  description = "natter";

  inputs = {
    nixpkgs     = { url = "nixpkgs/nixpkgs-unstable"; };
    utils       = { url = "github:numtide/flake-utils"; };
  };
  
  outputs = { self, nixpkgs, utils }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        python = pkgs.python311;
        python-pkgs = pkgs.python311Packages;
      in {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            cacert
            gnumake
            python
            python-pkgs.flake8
            # python-pkgs.gradio
            # python-pkgs.openai
            python-pkgs.mypy
            python-pkgs.pytest
            python-pkgs.pytest-cov                        
            python-pkgs.pip
            python-pkgs.isort
          ];
          shellHook = ''
            export LANG=en_US.UTF-8
            export PIP_PREFIX=$(pwd)/venv/pypy
            export PYTHONPATH=./src:"$PIP_PREFIX/${python.sitePackages}:$PYTHONPATH"
            export PATH="$PIP_PREFIX/bin:$PATH"
            unset SOURCE_DATE_EPOCH
            export PS1="natter|$PS1"
          '';
        };
        devShell = self.devShells.${system}.default;        
      }
    );
}


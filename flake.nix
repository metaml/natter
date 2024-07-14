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
        python = pkgs.python312;
        python-pkgs = pkgs.python312Packages;
      in {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            cacert
            gnumake
            python
            python-pkgs.flake8
            python-pkgs.isort
            python-pkgs.mypy
            python-pkgs.pip
            python-pkgs.pytest
            python-pkgs.pytest-cov
          ];
          shellHook = ''
            export LANG=en_US.UTF-8
            export PIP_PREFIX=$(pwd)/venv/pypy
            export PYTHONPATH=$(pwd)/src:"$PIP_PREFIX/${python.sitePackages}:$PYTHONPATH"
            export PATH="$PIP_PREFIX/bin:$PATH"
            unset SOURCE_DATE_EPOCH
            export PS1="natter|$PS1"
            python -m venv ./venv
            . ./venv/bin/activate
          '';
        };
        devShell = self.devShells.${system}.default;        
      }
    );
}


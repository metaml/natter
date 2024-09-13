{
  description = "ami rest";

  inputs = {
    nixpkgs = { url = "nixpkgs/nixpkgs-unstable"; };
    utils   = { url = "github:numtide/flake-utils"; };
  };

  outputs = { self, nixpkgs, utils }:
    utils.lib.eachDefaultSystem ( system:
      let pname    = "ami";
          pversion = "0.1.0.0";
          pdeps    = [ pkgs.cacert
                       python
                       python-pkgs.asyncpg
                       python-pkgs.boto3
                       python-pkgs.environs
                       python-pkgs.fastapi
                       python-pkgs.gradio
                       python-pkgs.jinja2
                       python-pkgs.openai
                       python-pkgs.passlib
                       python-pkgs.pydantic-core
                       python-pkgs.pyjwt
                       python-pkgs.termcolor
                       python-pkgs.uvicorn
                     ];
          bdeps    = [ pkgs.cacert
                       python-pkgs.setuptools
                     ];

          pkgs        = nixpkgs.legacyPackages.${system};
          python      = pkgs.python312;
          python-pkgs = pkgs.python312Packages;

          ddeps = with pkgs; [ git # nb: read this should be first--verify later
                               awscli2
                               docker
                               gnumake
                               jq
                             ];
          shell-hook = ''
            export LANG=en_US.UTF-8
            export PYTHONPATH=$(pwd)/src:$PYTHONPATH
            export PS1="ami|$PS1"
            # awscli2 and openai have a dependency conflict
            [ ! -f .creds ] || source .creds
            alias aws='PYTHONPATH= aws'
          '';
      in { packages.default = python.pkgs.buildPythonApplication rec {
             pname   = "$(pname)";
             version = "${pversion}";
             src     = self;
             format  = "other";
             doCheck = false;
             propagatedBuildInputs = pdeps ++ bdeps;
             installPhase          = ''mkdir -p $out/bin
                                       && cp -p ./app/ami.py $out/bin
                                       && cp -ap src $out/lib
                                     '';
           };
           defaultPackage = self.packages.${system}.default;

           devShells.default = pkgs.mkShell { buildInputs = pdeps ++ ddeps;
                                              shellHook = "${shell-hook}";
                                            };
           devShell = self.devShells.${system}.default;
         }
    );
}

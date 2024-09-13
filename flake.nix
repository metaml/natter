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
      in { #packages.${pname} = python.pkgs.buildPythonApplication rec {
           packages.default = python.pkgs.buildPythonApplication rec {
             pname   = "$(pname)";
             version = "${pversion}";
             src     = self;
             format  = "other";
             doCheck = false;
             propagatedBuildInputs = pdeps ++ bdeps;
             #installPhase = "install -Dm755 ./app/ami.py $out/bin/ami.py";
             installPhase = "mkdir -p $out/bin && cp -p ./app/ami.py $out/bin && cp -ap src $out/lib";
           };
           defaultPackage = self.packages.${system}.default;

           devShell = pkgs.mkShell { buildInputs = pdeps ++ ddeps;
                                     shellHook = ''
                                       export LANG=en_US.UTF-8
                                       export PYTHONPATH=$(pwd)/src:$PYTHONPATH
                                       export PS1="ami|$PS1"
                                       # awscli2 and openai have a dependency conflict
                                       if [ -f .creds ]; then source .creds; fi
                                       alias aws='PYTHONPATH= aws'
                                       alias m=make
                                       alias b='m build'
                                     '';
                                   };
         }
    );
}

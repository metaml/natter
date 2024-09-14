{
  description = "ami rest";

  inputs = {
    nixpkgs = { url = "nixpkgs/nixpkgs-unstable"; };
    utils   = { url = "github:numtide/flake-utils"; };
  };

  outputs = { self, nixpkgs, utils }:
    utils.lib.eachDefaultSystem ( system:
      let pnom    = "ami";
          pversion = "0.1.0.0";
          runtime-deps    = [ pkgs.cacert
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
          build-deps = with pkgs; [ awscli2
                                    git
                                    python-pkgs.setuptools
                                    docker
                                    gnumake
                                    jq
                                  ];
          pkgs        = nixpkgs.legacyPackages.${system};
          python      = pkgs.python312;
          python-pkgs = pkgs.python312Packages;

          shell-hook = ''
            export LANG=en_US.UTF-8
            export PYTHONPATH=$(pwd)/src:$PYTHONPATH
            export PS1="ami|$PS1"
            # awscli2 and openai have a dependency conflict
            [ ! -f .creds ] || source .creds
            alias aws='PYTHONPATH= aws'
          '';
      in { # runtime environment
           packages.default = python.pkgs.buildPythonApplication rec {
             pname   = "${pnom}";
             version = "${pversion}";
             src     = self;
             format  = "other";
             doCheck = false;
             propagatedBuildInputs = runtime-deps;
             # nb: odd behaviour in that nix build seems to introspect the string below
             installPhase = "mkdir -p $out/bin; cp -p app/ami.py $out/bin/ami.py; cp -ap src $out/lib";
             postFixup = "wrapProgram $out/bin/ami.py --prefix PYTHONPATH : $PYTHONPATH --prefix PATH : ${python}/bin";
           };
           defaultPackage = self.packages.${system}.default;

           # docker image
           packages.docker = pkgs.dockerTools.buildImage {
             name = "${pnom}";
             tag = "latest";
             created = "now";
             copyToRoot = pkgs.buildEnv {
               name = "${pnom}";
               paths = with pkgs; [
                 bashInteractive
                 cacert
                 coreutils
                 python
                 self.defaultPackage.${system}
               ];
               pathsToLink = [ "/bin" "/usr" ];
             };
           };

           # buld environment
           devShells.default = pkgs.mkShell { buildInputs = build-deps ++ runtime-deps;
                                              shellHook = "${shell-hook}";
                                            };
           devShell = self.devShells.${system}.default;
         }
    );
}

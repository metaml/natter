{
  description = "ami rest";

  inputs = {
    nixpkgs.url     = "nixpkgs/nixpkgs-unstable";
    systemd.url     = "github:serokell/systemd-nix";
    systemd.inputs.nixpkgs.follows = "nixpkgs";
    deploy.url      = "github:serokell/deploy-rs";
    utils.url       = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, systemd, deploy, utils }:
    utils.lib.eachDefaultSystem ( system:
      let name    = "ami";
          version = "0.1.0.0";
          runtime-deps    = [ pkgs.cacert
                              python
                              python-pkgs.asyncpg
                              python-pkgs.boto3
                              python-pkgs.cryptography
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
          dev-deps = with pkgs; [ awscli2
                                  docker
                                  git
                                  gnumake
                                  jq
                                  postgresql_16
                                  python-pkgs.setuptools
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
          inherit version;
          pname   = "${name}";
          src     = self;
          format  = "other";
          doCheck = false;
          propagatedBuildInputs = runtime-deps;
          # nb: odd behaviour in that nix build seems to introspect the string below
          installPhase = "mkdir -p $out/bin; cp -p app/ami.py $out/bin/ami.py; cp -ap src $out/lib";
          postFixup = "wrapProgram $out/bin/ami.py --prefix PYTHONPATH : $out/lib --prefix PYTHONPATH : $PYTHONPATH  --prefix PATH : ${python}/bin";
        };
        defaultPackage = self.packages.${system}.default;

        # needed by deploy below
        apps.default = utils.lib.mkApp { drv = self.packages.${system}.default; };

        # deploy systemd config: nix run
        inherit (deploy) defaultApp;
        deploy.nodes.ami = {
          hostname = "localhost";
          profiles.ami = {
            path = systemd.lib.${system}.mkSystemService "ami" {
              path = deploy.lib.${system}.setActivate nixpkgs.legacyPackages.${system}.ami "./bin/ami.py";
              serviceConfig = {
                ExecStart = "ami.py";
                Restart   = "always";
                Killmode  = "mixed";
              };
              description = "ami rest service";
            };
            activate = "$PROFILE/bin/activate";
          };
        };

        # docker image
        packages.docker = pkgs.dockerTools.buildImage {
          name = "ami-lambda";
          tag = "latest";
          created = "now";
          copyToRoot = pkgs.buildEnv {
            inherit name;
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
        devShells.default = pkgs.mkShell { buildInputs = dev-deps ++ runtime-deps;
                                           shellHook = "${shell-hook}";
                                         };
        devShell = self.devShells.${system}.default;
      }
    );
}

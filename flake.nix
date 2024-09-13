{
  description = "ami";

  inputs = {
    nixpkgs     = { url = "nixpkgs/nixpkgs-unstable"; };
    utils       = { url = "github:numtide/flake-utils"; };
  };

  outputs = { self, nixpkgs, utils }:
    utils.lib.eachDefaultSystem (system:
      let
        pname = "ami";
        pkgs = nixpkgs.legacyPackages.${system};
        python = pkgs.python312;
        python-pkgs = pkgs.python312Packages;
        version = "0.1.0";
      in {
        packages = rec {
          ami = pkgs.stdenv.mkDerivation rec {
            name = "${pname}";
            src = self;
            version = "";

            buildPhase = ":";
            installPhase = ''
              mkdir -p $out/bin $out/lib
              cp -p ./app/ami.py $out/bin/ami.py
              chmod +x $out/bin/*.py
              cp -ap ./src/* $out/lib
            '';
          };
          default = ami;
        };

        apps.default = rec {
          ami = utils.lib.mkApp { drv = self.packages.${system}.ami; };
          default = ami;
        };

        defaultPackage = self.packages.${system}.default;

        packages.docker = pkgs.dockerTools.buildImage {
          name = "${pname}";
          tag = "latest";
          created = "now";

          copyToRoot = pkgs.buildEnv {
            name = "${pname}";
            paths = with pkgs; [
              bashInteractive
              cacert
              coreutils
              python
              self.defaultPackage.${system}
            ];
            pathsToLink = [ "/bin" "/usr" ];
          };

          config = {
            WorkingDir = "/";
            Env = [
              "AWS_LAMBDA_LOG_GROUP_NAME=/aws/ami"
              "AWS_LAMBDA_LOG_STREAM_NAME=ami-log-events"
              "NIX_SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
              "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
              "SYSTEM_CERTIFICATE_PATH=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
            ];
            CMD = [ "/bin/bash" ];
          };
        };

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            git
            awscli2
            cacert
            docker
            gnumake
            jq
            postgresql
            python
            python-pkgs.asyncpg
            python-pkgs.boto3
            python-pkgs.environs
            python-pkgs.fastapi
            python-pkgs.gradio
            python-pkgs.jinja2
            python-pkgs.jupyterlab
            python-pkgs.notebook
            python-pkgs.openai
            python-pkgs.passlib
            python-pkgs.pydantic-core
            python-pkgs.pyjwt
            python-pkgs.termcolor
            python-pkgs.uvicorn
          ];

          shellHook = ''
            export LANG=en_US.UTF-8
            export PIP_PREFIX=$(pwd)/venv/pypy
            export PYTHONPATH=$(pwd)/src:$PYTHONPATH
            export PATH="$PIP_PREFIX/bin:$PATH"
            unset SOURCE_DATE_EPOCH
            # awscli2 and openai have a dependency conflict
            alias aws='PYTHONPATH= aws'
            alias python=python3.12
            if [ -f .creds ]; then source .creds; fi
            if [ "$LOGNAME" != "root" ]; then export PS1="ami|$PS1"; fi
          '';
        };
        devShell = self.devShells.${system}.default;
      }
    );
}

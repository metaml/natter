{
  description = "aip";

  inputs = {
    nixpkgs     = { url = "nixpkgs/nixpkgs-unstable"; };
    utils       = { url = "github:numtide/flake-utils"; };
  };
  
  outputs = { self, nixpkgs, utils }:
    utils.lib.eachDefaultSystem (system:
      let
        pname = "aip";
        pkgs = nixpkgs.legacyPackages.${system};
        python = pkgs.python312;
        python-pkgs = pkgs.python312Packages;
        version = "0.1.0";
      in {
        packages = rec {
          aip = pkgs.stdenv.mkDerivation rec {
            name = "${pname}";
            src = self;
            version = "";

            buildPhase = ":";
            installPhase = ''
              mkdir -p $out/bin
              cp -p ./app/chat.py $out/bin/chat.py
              cp -p ./app/aip.py $out/bin/aip.py
              chmod +x $out/bin/*.py
              pwd
            '';
          };
          default = aip;
        };

        apps = rec {
          aip = utils.lib.mkApp { drv = self.packages.${system}.aip; };
          default = aip;
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
              "AWS_LAMBDA_LOG_GROUP_NAME=/aws/aip"
              "AWS_LAMBDA_LOG_STREAM_NAME=aip-log-events"
              "NIX_SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
              "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
              "SYSTEM_CERTIFICATE_PATH=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
            ];
            EntryPoint = [ "/bin/bash" ];
            #CMD = [ "app.aip:app" ];
          };
        };
        
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            cacert
            gnumake
            #python
            python-pkgs.pip
          ];
          shellHook = ''
            export LANG=en_US.UTF-8
            export PIP_PREFIX=$(pwd)/venv/pypy
            export PYTHONPATH=$(pwd)/src:$(pwd)/app:"$PIP_PREFIX/${python.sitePackages}:$PYTHONPATH"
            export PATH="$PIP_PREFIX/bin:$PATH"
            unset SOURCE_DATE_EPOCH
            export PS1="aip|$PS1"
            python -m venv ./venv
            . ./venv/bin/activate
          '';
        };
        devShell = self.devShells.${system}.default;        
      }
    );
}

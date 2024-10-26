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
      let name        = "ami";
          version     = "0.1.0.0";
          pkgs        = nixpkgs.legacyPackages.${system};
          clang       = pkgs.clang;
          llvm-pkgs   = pkgs.llvmPackages;
          python      = pkgs.python312;
          python-pkgs = pkgs.python312Packages;

          runtime-deps = [ pkgs.cacert
                           python
                           python-pkgs.asyncpg
                           python-pkgs.boto3
                           python-pkgs.colorama
                           python-pkgs.cryptography
                           python-pkgs.environs
                           python-pkgs.fastapi
                           python-pkgs.jinja2
                           python-pkgs.numpy
                           python-pkgs.openai
                           python-pkgs.passlib
                           python-pkgs.pydantic-core
                           python-pkgs.python-multipart
                           python-pkgs.pyjwt
                           python-pkgs.pyyaml
                           python-pkgs.regex
                           python-pkgs.requests
                           python-pkgs.setuptools
                           python-pkgs.termcolor
                           python-pkgs.tiktoken
                           python-pkgs.typer
                           python-pkgs.urllib3
                           python-pkgs.uvicorn
                           python-pkgs.virtualenv
                           python-pkgs.wcwidth
                         ];
          dev-deps = with pkgs; [ awscli2
                                  docker
                                  git
                                  gnumake
                                  jq
                                  postgresql_16
                                ];
          # cc-deps = with llvm-pkgs; [ clang
          #                             clang-tools
          #                             libcxx
          #                             libstdcxxClang
          #                             pkgs.stdenv.cc.cc.lib
          #                           ];
          cc-deps = with pkgs; [ gcc14Stdenv
                                 gcc-unwrapped.lib
                               ];
          shell-hook = ''
            export LANG=en_US.UTF-8
            export PATH=$(pwd)/app:$(pwd)/venv/bin:$PATH
            export PYTHONPATH=$(pwd)/src:$(pwd)/venv/lib/python3.12/site-packages:$PYTHONPATH
            unset SOURCE_DATE_EPOCH
            export PS1="ami|$PS1"
            [ ! -f .creds ] || source .creds
            [ ! -f .creds-rds ] || source .creds-rds
            [ ! -f .openai-api-key ] || source .openai-api-key
          '';
      in { # runtime environment
        packages.default = python.pkgs.buildPythonApplication rec {
          inherit version;
          pname   = "${name}";
          src     = [ self ];
          format  = "other";
          doCheck = false;
          propagatedBuildInputs = runtime-deps ++ cc-deps;
          installPhase = ''
            mkdir -p $out/bin
            cp -p  app/ami.py $out/bin
            cp -p  app/letta.py $out/bin
            mkdir $out/etc
            cp -p etc/key.pem $out/etc
            cp -p etc/cert.pem $out/etc
            cp -ap src $out/lib
            cp -ap venv $out/
          '';
          postFixup = ''
            wrapProgram $out/bin/ami.py --prefix PYTHONPATH : $out/lib --prefix PYTHONPATH : $out/venv  --prefix PYTHONPATH : $out/venv/lib/python3.12/site-packages --prefix PYTHONPATH : $PYTHONPATH --prefix PATH : ${python}/bin --prefix PATH : $out/venv/bin --prefix SSL_KEY : $out/etc/key.pem --prefix SSL_CERT : $out/etc/cert.pem --prefix STATIC_DIR : '/static'
            wrapProgram $out/bin/letta.py --prefix PYTHONPATH : $out/lib --prefix PYTHONPATH : $out/venv  --prefix PYTHONPATH : $out/venv/lib/python3.12/site-packages --prefix PYTHONPATH : $PYTHONPATH --prefix PATH : ${python}/bin --prefix PATH : $out/venv/bin
          '';
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
        # deploy.nodes.letta = {
        #   hostname = "localhost";
        #   profiles.letta = {
        #     path = systemd.lib.${system}.mkSystemService "letta" {
        #       path = deploy.lib.${system}.setActivate nixpkgs.legacyPackages.${system}.ami "./bin/letta.sh";
        #       serviceConfig = {
        #         ExecStart = "letta.sh";
        #         Restart   = "always";
        #         Killmode  = "mixed";
        #       };
        #       description = "letta rest service";
        #     };
        #     activate = "$PROFILE/bin/activate";
        #   };
        # };

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

        # dev environment
        devShells.default = pkgs.mkShell.override { stdenv = pkgs.gcc14Stdenv; } rec {
          LD_LIBRARY_PATH = "$LD_LIBRARY_PATH:${pkgs.stdenv.cc.cc.lib}/lib";
          packages = cc-deps ++ runtime-deps; # ++ [ python-pkgs.venvShellHook ];
          nativeBuildInputs = dev-deps;

          venv = "lib";
          src = null;
          postVenv = "unset SOURCE_DATE_EPOCH";
          postShellHook = ''
            unset SOURCE_DATE_EPOCH
            unset LD_PRELOAD
          '';

          shellHook = "${shell-hook}";
        };
        devShell = self.devShells.${system}.default;
      }
    );
}

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
          pkgs        = nixpkgs.legacyPackages.${system};
          clang       = pkgs.clang;
          llvm-pkgs   = pkgs.llvmPackages;
          python      = pkgs.python312;
          python-pkgs = pkgs.python312Packages;

          runtime-deps    = [ pkgs.cacert
                              python
                              python-pkgs.asyncpg
                              python-pkgs.boto3
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
                              python-pkgs.setuptools
                              python-pkgs.termcolor
                              python-pkgs.typer
                              python-pkgs.urllib3
                              python-pkgs.uvicorn
                              python-pkgs.virtualenv
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
            export PIP_PREFIX=$(pwd)/venv
            export PYTHONPATH=$(pwd)/src:$PIP_PREFIX/${python.sitePackages}:$PYTHONPATH
            export PATH=$(pwd)/app:$PIP_PREFIX/bin:$PATH
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
          src     = self;
          format  = "other";
          doCheck = false;
          propagatedBuildInputs = runtime-deps ++ cc-deps;
          # nb: odd behaviour in that nix build seems to introspect the string below
          installPhase = "mkdir -p $out/bin && cp -p app/ami.py $out/bin/ami.py && cp -ap src $out/lib";
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

        # letta shell script
        packages.letta-script =
          let letta-script = pkgs.writeShellScriptBin "letta.sh" ''
                export LANG=en_US.UTF-8
                export PIP_PREFIX=$(pwd)/venv/pypi
                export PATH=$(pwd)/bin:$PIP_PREFIX/bin:$PATH
                unset SOURCE_DATE_EPOCH
                [ ! -f .creds-rds ]      || source .creds-rds
                [ ! -f .openai-api-key ] || source .openai-api-key
                python -m venv ./venv
                source ./venv/bin/activate
                echo letta server
              '';
              bldInputs = with pkgs; [
                self.defaultPackage.${system}
              ];
          in pkgs.symlinkJoin {
            name = "letta.sh";
            paths = [ letta-script ] ++ bldInputs;
            buildInputs = [ pkgs.makeWrapper ];
            postBuild = "wrapProgram $out/bin/${name} --prefix PATH : $out/bin";
          };

        # dev environment
        devShells.default = pkgs.mkShell.override { stdenv = pkgs.gcc14Stdenv; } rec {
          LD_LIBRARY_PATH = "$LD_LIBRARY_PATH:${pkgs.stdenv.cc.cc.lib}/lib";
          packages = cc-deps ++ runtime-deps ++ [ python-pkgs.venvShellHook ];
          nativeBuildInputs = dev-deps;

          venv = "venv";
          src = null;
          postVenv = ''
            unset SOURCE_DATE_EPOCH
          '';
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


# {
#   description = "Nix Development Flake for your package";
#   inputs.nixpkgs.url = "github:NixOS/nixpkgs/master";
#   outputs =
#     { self, nixpkgs, flake-utils }:
#     flake-utils.lib.eachDefaultSystem
#       (system:
#       let
#         pkgs = import nixpkgs { inherit system; };
#         python = pkgs.python310;
#         pythonPackages = python.pkgs;
#       in
#       {
#         devShells.default = pkgs.mkShell {
#           name = "your_package";
#           nativeBuildInputs = [ pkgs.bashInteractive ];
#           buildInputs = with pythonPackages; [
#             pkgs.nodePackages.pyright
#             pkgs.poetry
#             setuptools
#             wheel
#             venvShellHook
#           ];
#           venvDir = ".venv";
#           src = null;
#           postVenv = ''
#             unset SOURCE_DATE_EPOCH
#           '';
#           postShellHook = ''
#             unset SOURCE_DATE_EPOCH
#             unset LD_PRELOAD
#             PYTHONPATH=$PWD/$venvDir/${python.sitePackages}:$PYTHONPATH
#           '';
#         };
#       });
# }

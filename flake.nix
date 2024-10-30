{
  description = "ami rest";

  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    systemd.url = "github:serokell/systemd-nix";
    systemd.inputs.nixpkgs.follows = "nixpkgs";
    deploy.url  = "github:serokell/deploy-rs";
    utils.url   = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, systemd, deploy, utils }:
    utils.lib.eachDefaultSystem ( system:
      let name        = "ami";
          version     = "0.1.0.0";
          pkgs        = nixpkgs.legacyPackages.${system};
          python      = pkgs.python312;
          python-pkgs = pkgs.python312Packages;

          runtime-deps = [ pkgs.cacert
                           python
                           python-pkgs.ipython
                           python-pkgs.onnxruntime
                           python-pkgs.asyncpg
                           python-pkgs.boto3
                           python-pkgs.chroma-hnswlib
                           python-pkgs.colorama
                           python-pkgs.cryptography
                           python-pkgs.environs
                           python-pkgs.fastapi
                           python-pkgs.jinja2
                           python-pkgs.grpcio
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
                           python-pkgs.tokenizers
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
          cc-deps = with pkgs; [ gcc14
                                 gcc14Stdenv
                                 gcc-unwrapped.lib
                               ];
          shell-hook = ''
            export LANG=en_US.UTF-8
            export PATH=$(pwd)/app:$(pwd)/venv/bin:$PATH
            export PYTHONPATH=$(pwd)/src:$(pwd)/venv/lib/python3.12/site-packages:$PYTHONPATH
            export LD_LIBRARY_PATH="${pkgs.gcc14Stdenv.cc.cc.lib}/lib";
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
            cp -p etc/nixos/*.nix $out/etc
            cp -ap src $out/lib
            cp -ap venv $out/
          '';
          postFixup = ''
            wrapProgram $out/bin/ami.py --prefix PYTHONPATH : $out/lib --prefix PYTHONPATH : $out/venv  --prefix PYTHONPATH : $out/venv/lib/python3.12/site-packages --prefix PYTHONPATH : $PYTHONPATH --prefix PATH : ${python}/bin --prefix PATH : $out/venv/bin --prefix SSL_KEY : $out/etc/key.pem --prefix SSL_CERT : $out/etc/cert.pem --prefix STATIC_DIR : '/static'
            wrapProgram $out/bin/letta.py --prefix PYTHONPATH : $out/lib --prefix PYTHONPATH : $out/venv  --prefix PYTHONPATH : $out/venv/lib/python3.12/site-packages --prefix PYTHONPATH : $PYTHONPATH --prefix PATH : ${python}/bin --prefix PATH : $out/venv/bin
          '';
        };
        # defaultPackage = self.packages.${system}.default; # deprecated
        # needed by deploy below
        apps.ami   = utils.lib.mkApp { drv = self.packages.${system}.default; };
        apps.letta = utils.lib.mkApp { drv = self.packages.${system}.default; };

        # dev environment
        devShells.default = pkgs.mkShell.override { stdenv = pkgs.gcc14Stdenv; } rec {
          packages = runtime-deps; # ++ [ python-pkgs.venvShellHook ];
          nativeBuildInputs = dev-deps ++ cc-deps;

          venv = "lib";
          src = null;
          postVenv = "unset SOURCE_DATE_EPOCH";
          postShellHook = ''
            unset SOURCE_DATE_EPOCH
            unset LD_PRELOAD
          '';

          shellHook = "${shell-hook}";
        };
      }
    );
}

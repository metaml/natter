{ modulesPath, pkgs, ... }: {
  imports = [ "${modulesPath}/virtualisation/amazon-image.nix" ];
  nix.extraOptions = "trusted-users = root";
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 80 443 8000 8283 ];
    allowedUDPPortRanges = [
      { from = 4000; to = 4007; }
      { from = 8000; to = 8010; }
    ];
  };
  # 1. allow return traffic for outgoing connections initiated by the server itself
  # 2. allow outgoing traffic of all established connections
  networking.firewall.extraStopCommands = ''
    iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT || true
    iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED -j ACCEPT        || true
  '';
  nixpkgs.config = {
    allowUnfree = true; # Allow "unfree" packages.
    # firefox.enableAdobeFlash = true;
    # chromium.enablePepperFlash = true;
  };
  system.stateVersion = "24.05";
  documentation.doc.enable = false;

  environment.variables = { AWS_DEFAULT_REGION = "us-east-2"; };
  environment.systemPackages = with pkgs; [
    awscli2
    bashInteractive
    coreutils
    dateutils
    dig
    docker
    emacs
    fetchutils
    findutils
    gawk
    git
    gnugrep
    gnumake
    gnused
    idutils
    inetutils
    jq
    less
    openssl
    tree
    unzip
    vim
    zip
    zlib.dev
  ];

  systemd.services.dockerd = {
    enable = true;
    wantedBy      = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart  = "${pkgs.docker}/bin/dockerd";
      Restart    = "always";
      RestartSec = 1;
    };
    description   = "dockerd";
  };

  systemd.services."ami" = {
    description = "ami rest service";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart    = "/root/.nix-profile/bin/ami.py";
      KillMode     = "mixed";
      Restart      = "always";
      RestartSec   = 8;
      StandardError  = "journal";
      StandardOutput = "journal";
      StandardInput  = "null";
    };
  };

  systemd.services."letta" = {
    description = "letta rest service";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart    = "/root/.nix-profile/bin/letta.py";
      KillMode     = "mixed";
      Restart      = "always";
      RestartSec   = 8;
      StandardError  = "journal";
      StandardOutput = "journal";
      StandardInput  = "null";
    };
  };
}

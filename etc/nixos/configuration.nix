{ modulesPath, pkgs, ... }: {
  imports = [ "${modulesPath}/virtualisation/amazon-image.nix" ];

  nix.settings.experimental-features = ["nix-command" "flakes"];
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 443 ];
    allowedUDPPortRanges = [
      { from = 4000; to = 4007; }
      { from = 8000; to = 8010; }
    ];
  };
  system.stateVersion = "24.05";

  environment.systemPackages = with pkgs; [
    git
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
    description   = "dockerd";
    unitConfig    = { Type = "simple";};
    wantedBy      = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart  = "${pkgs.docker}/bin/dockerd";
      Restart    = "always";
      RestartSed = 1;
    };
  };  			   
}

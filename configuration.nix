# MYBONK console default configuration file. 
# For testing only.

{ config, lib, pkgs, ... }:

{
  imports = lib.optional (builtins.pathExists ./do-userdata.nix) ./do-userdata.nix ++ 
    [
      
    ];

  # If you use an SSD (which you most probably are) it may be useful to enable TRIM support and set filesystem flags for best performance.
  fileSystems."/".options = [ "noatime" "nodiratime" "discard" ];

  # Automatically generate all secrets required by services.
  # The secrets are stored in /etc/nix-bitcoin-secrets
  nix-bitcoin.generateSecrets = true;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";
  
  nix.settings = {
    # Enable flakes and new 'nix' command
    experimental-features = "nix-command flakes";
    # Deduplicate and optimize nix store
    auto-optimise-store = true;
  };
 
  users.motd = "WELCOME";
  networking.wireless.enable = false; # We prefer our nodes not to operate over WiFi. 

  # Use this setting 'loose' because strict reverse path filtering breaks Tailscale exit node use and some subnet routing setups
  networking.firewall.checkReversePath = "loose";
  networking.networkmanager.enable = true;
  
  # Set your time zone.
  time.timeZone = "Europe/Brussels"; # FIXME: Adjust for your timezone.


  # FIXME: Configure keymap in X11
  services.xserver = {
    layout = "fr";
    xkbVariant = "mac";
  };

  # FIXME: Configure console keymap
  console.keyMap = "fr";

  # Define a user account. Don't forget to set a password with 'passwd'
  users.users.mybonk = {
    isNormalUser = true;
    description = "mybonk";
    extraGroups = [ "networkmanager" "wheel" "bitcoin" ];
    packages = with pkgs; [];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    wget
    sshfs
    git
    vim
    ripgrep
    pv
    multitail
    htop
    powertop
    btop
    glances
    geekbench
  ];


  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # Looks like this is a workaround required to run hardened node (?)
  services.logrotate.checkConfig = true;

  # Enable tailscale
  services.tailscale.enable = true;
  # Tell the firewall to implicitly trust packets routed over Tailscale:
  networking.firewall.trustedInterfaces = [ "tailscale0" ];

  services.openssh = {
    enable = true;
    settings = {
       PasswordAuthentication = true; #Keep this to false unless you are playing around
       PermitRootLogin = "yes"; #Keep this to false unless you are playing around
    }; 
    #Define with extraConfig setting to give ssh as little right as possible
    #for user 'replication-user' as explained
    #[HERE](https://serverfault.com/questions/354615/allow-sftp-but-disallow-ssh)
#    extraConfig = ''
#         Match user replication-user
#           ChrootDirectory /data/backups/clightning
#           AllowTcpForwarding no
#           AllowAgentForwarding no
#           ForceCommand internal-sftp
#           PasswordAuthentication no
#           X11Forwarding no
#       '';
  };

  systemd.tmpfiles.rules = [
    # Because this directory is chrooted by sshd, it only needs to be writable by user/group root
#    "d /data/backups/clightning 0755 root root - -"
#    "d /data/backups/clightning/writable 0700 nb-replication - - -"
  ];


  users.users.replication-user = {
    isSystemUser = true;
    group = "replication-user";
    shell = "${pkgs.coreutils}/bin/false";
    #openssh.authorizedKeys.keys = [ "<contents of $secretsDir/clightning-replication-ssh.pub>" ];
  };
  users.groups.replication-user = {};

  users.users.root = {
    openssh.authorizedKeys.keys = [
      # FIXME: Replace this with your SSH pubkey
      "ssh-ed25519 AAAAC3..."
    ];
  };

  ### BITCOIND
  # Bitcoind is enabled by default via secure-node.nix.

  services.bitcoind = {
    enable = true;
    dataDir = "/data/bitcoind";
    #signet = true;
    tor.enforce = false;
    tor.proxy = false;
    extraConfig = ''
      mempoolfullrbf=1
      #debug=true
      
      # Specific to Mutinynet: Set fallback fee, without this fee estimate is always 0.
      fallbackfee=0.00000253

      # Enable block filters (optional)
      blockfilterindex=1
      peerblockfilters=1
    '';
    # Listen to RPC connections on all interfaces
    rpc.address = "0.0.0.0";

    # Allow RPC connections from external addresses
    rpc.allowip = [
      #"10.10.0.0/24" # Allow a subnet
      #"10.50.0.3" # Allow a specific address
      "0.0.0.0/0" # Allow all addresses
    ];
    
    rpc.port=8332;
     rpc.users = {
	bitcoin = {
           passwordHMAC = "f7efda5c189b999524f151318c0c86$d5b51b3beffbc02b724e5d095828e0bc8b2456e9ac8757ae3211a5d9b16a22ae";
           rpcwhitelist = [ "getnetworkinfo" "getpeerinfo" "listwallets" ]; 
        };	
     };
  };
  nix-bitcoin.onionServices.bitcoind.public = true;

  ### CLIGHTNING
  services.clightning = {
    enable = true; 
    dataDir = "/data/clightning"; 
    tor.enforce = false;
    tor.proxy = false;
    extraConfig = ''
      #FIXME below choose an alias name of your node
      alias=MYBONK-SIGNET-2
    '';
    plugins = {
       prometheus.enable = true;
       monitor.enable = true;
       summary.enable = true;  
    };
    #replication = {
     # enable = true; # clightning database replication. Ref nix-bitcoin documentation 
     # sshfs.destination = "mybonk@mybonk-jay:/data/remote-backup/mybonk-jay";
     # encrypt = true;
    #};
  }; 
  programs.ssh.knownHosts.mybonk-jay.publicKey = "AAAAC3NzaC1lZDI1NTE5AAAAINXuENT+AZLJhCujXYMDI5mqmrCxWKWEEqDSd9PvgVUJ";
  programs.ssh.knownHosts.mybonk-jay2.publicKey = "AAAAC3NzaC1lZDI1NTE5AAAAIKzYHSDrUS59UrsoGsmIccAh+VsDuDpNwtwMBNt1try4";
  nix-bitcoin.onionServices.clightning.public = true;
  systemd.services.clightning.serviceConfig.TimeoutStartSec = "5m";
  
# == REST server 
  # Set this to create a clightning REST onion service.
  # This also adds binary `lndconnect-clightning` to the system environment.
  # This binary creates QR codes or URLs for connecting applications to clightning
  # via the REST onion service.
  # You can also connect via WireGuard instead of Tor.
  # See ../docs/services.md for details.
  #
  services.clightning-rest = {
    enable = true;
    port = 3001;
    lndconnect = {
      enable = true;
    };
  };


  services.rtl = {
    enable = true;
    nodes.clightning.enable = true;
  };

  ### FULCRUM
  # Set this to enable fulcrum, an Electrum server implemented in C++.
  #
  # Compared to electrs, fulcrum has higher storage demands but
  # can serve arbitrary address queries instantly.
  #
  # Before enabling fulcrum, and for more info on storage demands,
  # see the description of option `enable` in ../modules/fulcrum.nix
  #
  services.fulcrum = {
    enable = true; 
    dataDir = "/data/fulcrum";
    port = 50011;
    extraConfig = ''
      #debug=true
      fast-sync = 3500
    '';
  };


#networking.firewall.allowedTCPPorts = [
#    config.services.clightning-rest.port
#    config.services.bitcoind.rpc.port
#    config.services.rtl.port
#    #config.services.uptime-kuma.settings.PORT
#    3300
#    config.services.fulcrum.port
#  ];

  services.mempool = {
    enable = true;
    electrumServer = "fulcrum";
    tor = {
      proxy = true;
      enforce = true;
    };
  };
  nix-bitcoin.onionServices.mempool-frontend.enable = true;

  users.users.operator.extraGroups = [ "wheel" ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It is perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?

  # The nix-bitcoin release version that your config is compatible with.
  # When upgrading to a backwards-incompatible release, nix-bitcoin will display an
  # an error and provide instructions for migrating your config to the new release.
  nix-bitcoin.configVersion = "0.0.85";

}


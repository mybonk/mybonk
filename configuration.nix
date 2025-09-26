{
  modulesPath,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    #imports = lib.optional (builtins.pathExists ./do-userdata.nix) ./do-userdata.nix ++ 
    (fetchTarball { url="https://github.com/msteen/nixos-vscode-server/tarball/master"; sha256="1rdn70jrg5mxmkkrpy2xk8lydmlc707sk0zb35426v1yxxka10by"; } )
    #./disk-config.nix
  ];
  boot.loader.grub = {
    # no need to set devices, disko will add all devices that have a EF02 partition to the list already
    #devices = [  ];
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  nix.settings = {
    # Enable flakes and new 'nix' command
    experimental-features = "nix-command flakes";
    # Deduplicate and optimize nix store
    auto-optimise-store = true;
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Enable vscode server (this allows to connect remotly from vscode).
  services.vscode-server.enable = true;

  # Use this setting 'loose' because strict reverse path filtering breaks Tailscale exit node use and some subnet routing setups
  networking.firewall.checkReversePath = "loose";
  networking.networkmanager.enable = true;
  
  # Set your time zone.
  time.timeZone = "Europe/Brussels"; # FIXME: Adjust for your timezone.

  # FIXME: Configure keymap in X11
  services.xserver.xkb = {
    layout = "fr";
    variant = "mac";
  };

  # FIXME: Configure console keymap
  console.keyMap = "fr";

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
        PermitRootLogin = "yes"; 
    }; 
  };

  environment.systemPackages = map lib.lowPrio [
    pkgs.curl
    pkgs.gitMinimal
    pkgs.wget
    pkgs.tmux
    pkgs.tmuxinator
    pkgs.sshfs
    pkgs.vim
    pkgs.ripgrep
    pkgs.pv
    pkgs.multitail
    pkgs.htop
    pkgs.powertop
    pkgs.btop
    pkgs.glances
    pkgs.ripgrep
  ];

  users.users.root.openssh.authorizedKeys.keys = [
    # change this to your ssh key
    "ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBABTjXzlHGw941UGukM3HVUTpvsXCLgx7EZRJ83YE32qEe8HtXmGHo41YftauWwnTN5rQvMWTd0puFzXz4vKu7YC1gATUUtYNa6mzgtt+dNvTvLNcQ1vSQ5s19yKKgJjZV1MZBlcf/HklfNdS0Owja1aIrp9jKlJErTWPXKtN6vkfLSF5g== Jay@Jay-MacBook-Pro.local"
    ];


  users.users.operator = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
    # change this to your ssh key
    "ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBABTjXzlHGw941UGukM3HVUTpvsXCLgx7EZRJ83YE32qEe8HtXmGHo41YftauWwnTN5rQvMWTd0puFzXz4vKu7YC1gATUUtYNa6mzgtt+dNvTvLNcQ1vSQ5s19yKKgJjZV1MZBlcf/HklfNdS0Owja1aIrp9jKlJErTWPXKtN6vkfLSF5g== Jay@Jay-MacBook-Pro.local"
    "ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBAH26emFyi+s8bYytRcKgObsHMCRmtvb81pnPoQIjVspLrmlH45fQSaE3doxauE9o8gD4bzOgtPATEDEPQNxncUgpwCUr6hanu5ojFWSAYJff0k9/W4TMuEbPcqUg6I+lEzn+N/eDtESIIi5BZh5e6oaqd9I/WwjmvLOdOZFmv/dpjOXyQ== operator@mothership"
  ];
  };
  
  security.sudo.extraRules= [
  {  users = [ "operator" ];
    commands = [
       { command = "ALL" ;
         options= [ "NOPASSWD" ]; # "SETENV" # Adding the following could be a good idea
      }
    ];
  }
];

  system.stateVersion = "24.05";
}

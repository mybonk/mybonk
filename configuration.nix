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
    ./disk-config.nix
  ];
  boot.loader.grub = {
    # no need to set devices, disko will add all devices that have a EF02 partition to the list already
    # devices = [ ];
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
        PermitRootLogin = "without-password"; 
    }; 
  };

  # Add and configure other services you need, here CouchDB
  # services.couchdb = {
  #     enable = true;
  #     adminUser = "FIXME";
  #     adminPass = "FIXME";
  # };

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
    pkgs.geekbench
  ];

  users.users.root.openssh.authorizedKeys.keys = [
    # change this to your ssh key
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCuGp2f5FDhoq9tB+WuY/LKYBGSsDE5C2aKMd8zkjM/lVhsOxwd1BUuqiZ8L5m1IYRGNh5ewnYH1om9RTbU4ngxyW58LfXZ/RYNq52/ZtOqpQq6Pw6IH5YjG3qBGitN4vg1ILQF02Kw+tWlPsJ2H3a8VNGOOUNlAO0FB3n2O4MPGeCVM7h/SgjUGFfrX+stVxeH9oFzXR82dZT0I3hzpm6Kl1DDMnbv+eTUvCNgPT8w3w3HOCFxa2nLz61XMXqcW2sO8Onn0/WqZC7NC7G7Fx0VMY+tguoEySUCRIZSCkvQeZDypj0CFoYs9ohVWfqh2wl7x1eoow/RAGSQ+O4DgpLv2TNHCVJB8x12igczMhgM/F21bDOZoh2wkwk5Y8JbBUaPqQ0YEvrniuR7ZbZCP39V0VvodjNzlPvFb1o0fHrXeHzaHJ5XJBeM2s6bqKuvr5wKLt4NUT5dQGZcWl2gGmaAn7qcCKVJsq0zppEAdaRJ6soFRd8vM3G7jzNNGxusUYE= operator@mybonk-jay4"
  ];


  users.users.operator = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
    # change this to your ssh key
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCuGp2f5FDhoq9tB+WuY/LKYBGSsDE5C2aKMd8zkjM/lVhsOxwd1BUuqiZ8L5m1IYRGNh5ewnYH1om9RTbU4ngxyW58LfXZ/RYNq52/ZtOqpQq6Pw6IH5YjG3qBGitN4vg1ILQF02Kw+tWlPsJ2H3a8VNGOOUNlAO0FB3n2O4MPGeCVM7h/SgjUGFfrX+stVxeH9oFzXR82dZT0I3hzpm6Kl1DDMnbv+eTUvCNgPT8w3w3HOCFxa2nLz61XMXqcW2sO8Onn0/WqZC7NC7G7Fx0VMY+tguoEySUCRIZSCkvQeZDypj0CFoYs9ohVWfqh2wl7x1eoow/RAGSQ+O4DgpLv2TNHCVJB8x12igczMhgM/F21bDOZoh2wkwk5Y8JbBUaPqQ0YEvrniuR7ZbZCP39V0VvodjNzlPvFb1o0fHrXeHzaHJ5XJBeM2s6bqKuvr5wKLt4NUT5dQGZcWl2gGmaAn7qcCKVJsq0zppEAdaRJ6soFRd8vM3G7jzNNGxusUYE= operator@mybonk-jay4"
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC+VC97yrRmvfSpivUepie9ykV6jBYWDQ2HeOidXFgZ73gsIwnnOrdr7GONoNunK6dDYI7nZ60Qxg97p8uQT82YwoNAbavJH6+a7vE1vaWTGjBiTPPGkJ/DJwqCXsntJCkW2Q3/pHbz/nVEMCTjawzraVVPTV8Z0dPTrmckSvXNQXHZF0R/ZoSfZYgmVq+La745bftCjwKXZR+9fUfxmHgEWcpVhYwCXz6nFHHDwSjRWESkzKqV85yQhmnGsqUWQAgCSHkQP8RUH1Jzbf897DQTUedhgaXKf2z4IZw89vMIISG+gWDy3w0aZgfrVPXsMUPJ7PONDHGK/dF+f19sZn7pvrRrBIAo3h+Y2SoljiUpQgVAPx8EqTqjtGiLY4EeLMTnUDbz+0MQq0ujE3qXFVKcRcap4ZXBG5A8cUZLBq7uRlrmnU6maAv/PLz8RzstPXUH3CdWn5J4qxldfbyqhI3KBdZ8KfAfpM0bo25Z9oM7y78Kwd1IgUE27dxVZKP1KI+6lltEz5ppIu+WTLehn5z/J2eTMn10wCsS8WAvnqfnTIpVMADBexMfwKv6Q20c6uOcslSLHMXCzDeaT6mTofgyjZ0cU4lYuHWFceZjeBgx+vq1Paga5cXAonm31qcOjdSBJSwlU9bMCVKby9s0fkMFZzWXZ33MxiMePgPRk5lTTw== Jay@Jay-MacBook-Pro.local"
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

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
  ];

  users.users.root.openssh.authorizedKeys.keys = [
    # change this to your ssh key
  "ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBAHj1NOz5CQGPvrJFRIcDRlNixhIkJKnaVypGtjK+DPmvZKP0G55ASxIG+vk3Nk5Vyjo1ymjb0fYIK3YqwPv1xG0CAF5shi0sY+M2wKJL4+YCy/+xhYH3EVbLE1xtUM+uLqCr76i+Z9+QhosW/Etd9UxgDeoy8S9uQ64FeIUUpDANksURQ=="
  ];


  users.users.operator = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
    # change this to your ssh key
    "ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBAHj1NOz5CQGPvrJFRIcDRlNixhIkJKnaVypGtjK+DPmvZKP0G55ASxIG+vk3Nk5Vyjo1ymjb0fYIK3YqwPv1xG0CAF5shi0sY+M2wKJL4+YCy/+xhYH3EVbLE1xtUM+uLqCr76i+Z9+QhosW/Etd9UxgDeoy8S9uQ64FeIUUpDANksURQ=="
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC+VC97yrRmvfSpivUepie9ykV6jBYWDQ2HeOidXFgZ73gsIwnnOrdr7GONoNunK6dDYI7nZ60Qxg97p8uQT82YwoNAbavJH6+a7vE1vaWTGjBiTPPGkJ/DJwqCXsntJCkW2Q3/pHbz/nVEMCTjawzraVVPTV8Z0dPTrmckSvXNQXHZF0R/ZoSfZYgmVq+La745bftCjwKXZR+9fUfxmHgEWcpVhYwCXz6nFHHDwSjRWESkzKqV85yQhmnGsqUWQAgCSHkQP8RUH1Jzbf897DQTUedhgaXKf2z4IZw89vMIISG+gWDy3w0aZgfrVPXsMUPJ7PONDHGK/dF+f19sZn7pvrRrBIAo3h+Y2SoljiUpQgVAPx8EqTqjtGiLY4EeLMTnUDbz+0MQq0ujE3qXFVKcRcap4ZXBG5A8cUZLBq7uRlrmnU6maAv/PLz8RzstPXUH3CdWn5J4qxldfbyqhI3KBdZ8KfAfpM0bo25Z9oM7y78Kwd1IgUE27dxVZKP1KI+6lltEz5ppIu+WTLehn5z/J2eTMn10wCsS8WAvnqfnTIpVMADBexMfwKv6Q20c6uOcslSLHMXCzDeaT6mTofgyjZ0cU4lYuHWFceZjeBgx+vq1Paga5cXAonm31qcOjdSBJSwlU9bMCVKby9s0fkMFZzWXZ33MxiMePgPRk5lTTw=="
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

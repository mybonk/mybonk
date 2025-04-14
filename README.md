# INSTALL MYBONK IN LESS THAN 10MIN

NixOS Workshop @Buenos Aeres @Saturday 19th 2025
If you are really new to computing have a look at our ["Baby rabbit holes"](https://github.com/mybonk/mybonk-wiki/blob/main/baby-rabbit-holes.md).
If at the end of this workshop you want to learn more about how the "automagic" installation process works under the hood have a look at our [MYBONK Wiki](https://github.com/mybonk/mybonk-wiki/tree/main)

Here are the instructions to push a system configuration to any Linux computer to which you have `root` access. 

This is not a full instructions on how to setup a complete MYBONK full node but rather demonstrate its installation and management mechanism based on 4 simple commands:
- mybonk-erase-and-install.sh
- mybonk-rebuild.sh
- mybonk-term-open.sh
- mybonk-term-close.sh

Thereby the configuration that will be used is the simplest you can imagine (only basic services and Tailscale), it is refered to as '.#generic' in this document. 

Any feedback before, during and after the workshop are welcome.

## INSTRUCTIONS

### STEP 1
On any NixOS system (or at least any system having Nix, the package manager, installed) clone the present repository:
```
$ git clone https://github.com/mybonk/mybonk.git
$ cd mybonk
````

### STEP 2
In the cloned directory modify the `configuration.nix` to set your own ssh public keys (parameters `authorizedKeys.keys`) instead of the ones there by default which are only examples to show you what it looks like. Again: Make 100% sure you put your own key(s) (public key of a private-public keys pair) else you may loose access to the machine after installation.

### STEP 3
Launch the auto-installation command (use `--flake .#generic` as in the example if you are not too sure).
```
$ ./mybonk-rebuild.sh switch --target-host root@178.156.170.26 --flake .#generic
````

### STEP 4
Done. Your MYBONK is running. 

### CONCLUSION

You can now explore the following helper commands.

#### mybonk-erase-and-install.sh
- Automatically builds and install MYBONK.
- BE CARFUL**: The local partitions will be wiped out, you would normally run this once to get your system up and running then use `mybonk-rebuild.sh` instead to adjust the configuration of the system subsequently.
- If the `--target-host` option is provided the install is done on that machine (you will need ssh keys setup for this to work).
- Use the option `--help` to see all that is possible.
```bash
$ ./mybonk-erase-and-install.sh --target-host root@178.156.170.26 --flake .#generic
```

#### mybonk-rebuild.sh
- Allows you to update the configuration of MYBONK (local or remote) hot by default (without requiring a system reboot).
	- Use the option `--help` to see all that is possible.

```
$ ./mybonk-rebuild.sh switch --target-host root@178.156.170.26 --flake .#generic
```

#### mybonk-term-open.sh
- Allows you to open a preconfigured tmux session with MYBONK. 
- Use the option `--help` to see all that is possible.
```
$ ./mybonk-term-open.sh operator@178.156.170.26
```

#### mybonk-term-close.sh
- Kill the tmux session with MYBONK. 
- Use the option `--help` to see all that is possible.
```
./mybonk-term-close.sh operator@178.156.170.26
```

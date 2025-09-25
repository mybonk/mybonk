#bash!

construct_command() {
    local target_host="$1" flake="$2" test="$3"
    local command="nix run --extra-experimental-features nix-command --extra-experimental-features  flakes  github:nix-community/nixos-anywhere -- --generate-hardware-config nixos-generate-config ./hardware-configuration.nix"

    [[ "$target_host" ]] && command+=" --target-host $target_host"

    command+=" --flake"
    default_flake_name=".#"
    default_flake_name+=${target_host#*@} # We are interested only in anything after '@' in target_host (the server name).
    [[ -z $flake ]] && command+=" $default_flake_name"
    command+=" $flake"
    [[ "$test" ]] && command+=" --vm-test"
    echo $command
}

confirm_operation() {
    echo "#############################"
    echo "### ALL DATA WILL BE LOST ###"
    echo "#############################"
    echo "This action will change the partitions and format the drive(s) on the target machine."
    echo "The following command will be executed:" 
    echo "$command"
    echo "Are you really certain you want to run it? (yes/no)"
    read -r confirmation
    [[ "$confirmation" != "yes" ]] && echo "Operation cancelled." && exit 0
}

# Test SSH connection
test_ssh_connection() {
    local host="$1"
    local command="ssh -o StrictHostKeyChecking=no ${verbose:+-v} $host exit </dev/null 2>&1"
    echo "running command: $command"
    if $command; then
        echo "Test SSH connection with $host successful."
    else
        echo "Failed to connect to $host via SSH. Please check your SSH key setup."
        exit 1
    fi
}

run_nix_run() {
    
    local command="$1"
    start_time=$(date +%s)

    $command || { local end_time=$(date +%s); echo "Error executing nix run after $(display_elapsed_time $((end_time - start_time))). 😞"; exit 1; }
    end_time=$(date +%s)
    echo "⏱️ Operation took $(display_elapsed_time $((end_time - start_time)))"
    echo "✅ Operation completed successfully 🚀"
}

# Display elapsed time in a human-readable format
display_elapsed_time() {
local seconds=$1

output=$seconds
output+=" seconds ("

days=$((seconds / 86400))
seconds=$((seconds % 86400))

hours=$((seconds / 3600))
seconds=$((seconds % 3600))

minutes=$((seconds / 60))
seconds=$((seconds % 60))



if [ $days -gt 0 ]; then
  output+="${days}d, "
fi

if [ $hours -gt 0 ]; then
  output+="${hours}h, "
fi

if [ $minutes -gt 0 ]; then
  output+="${minutes}m, "
fi

if [ $seconds -gt 0 ]; then
  output+="${seconds}s"
fi
output+=")";
echo $output
}

# Display usage information
display_usage() {
    echo "Usage: $0 --target-host <host> [--flake <flake>] [--test] [--help]"
    echo
    echo "  --target-host <host>  Specify the target host for the deployment"
    echo "  --flake <flake>       Optional, specify the configuration to be deployed, so it must be defined as an nixosConfiguration element in the flake.nix. If not provided the default is made using target-host as follows: .#<target-host>"
    echo "  --test                Run the operation in test mode (adds --vm-test to the nix run command)"
    echo "  --help                Display this help message"
    echo
    echo "This script runs the specified nixos-anywhere command with the provided options."
    echo "If --target-host is not provided the install takes place on local machine (still requiring an ssh connection as root needs to be used for system setup)."
    echo "The script tests ssh connections to the hosts before running."
}

while [[ "$1" != "" ]]; do
    case $1 in
        --target-host)
            shift
            target_host="$1"
            ;;
        --flake)
            shift
            flake="$1"
            ;;
        --test)
            test="true"
            exit 0
            ;;
        --help)
            display_usage
            exit 0
            ;;
        *)
            display_usage
            echo "ERROR: Unrecognized option '$1'"
            exit 1
    esac
    shift
done


[[ -z "$target_host" ]] && echo "Parameter '--target-host' is mandatory." && exit 0

command=$(construct_command "$target_host" "$flake" "$test")

confirm_operation
# Before anything else make sure we can ssh into the machine if it's a remote one.
test_ssh_connection "$target_host"

run_nix_run "$command"

#bash!

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
    echo "Usage: $0 <sub-command> [--target-host <host>] [--build-host <host>] [--flake <flake>] [--verbose] [--help]"
    echo
    echo "Sub-commands:"
    echo "  switch   Build the configuration and make it the default boot option, activating it immediately"
    echo "  boot     Build the configuration and make it the default boot option, but don't activate it until the next reboot"
    echo "  test     Build the configuration and activate it, but don't add it to the bootloader menu"
    echo "  build    Build the configuration and place a symlink called 'result' pointing to the derivation in the Nix store"
    echo "  dry-activate  Build the configuration, but do not activate it. Instead, show the changes that would be performed"
    echo "  build-vm Build a QEMU VM that runs the new configuration. Leaves a symlink 'result' with the built VM"
    echo "  --target-host <host>  Specify the target host for the sub-command (default: localhost)"
    echo "  --build-host <host>   Specify the build host for the sub-command"
    echo "  --flake <flake>       Specify the configuration to be deployed, so it must be defined as an nixosConfiguration element in the flake.nix. If not provided the default is made using target-host as follows: .#<target-host>"
    echo "  --verbose             Enable verbose output (pass it on to the underlying ssh command)"
    echo "  --help                Display this help message"
    echo "  --show-trace          Display error trace (pass it on to the underlying nixos-rebuild command)"
    echo
    echo "This script runs the specified nixos-rebuild sub-command with the provided options."
    echo "If the hosts are not provided, localhost is used as the default for target-host."
    echo "The script tests ssh connections to the hosts, if required, before executing."
}

# Parse command line arguments
if [[ "$1" == "" ]]; then
    display_usage
    exit 1
fi

sub_command="$1"
shift

while [[ "$1" != "" ]]; do
    case $1 in
        --target-host)
            shift
            target_host="$1"
            ;;
        --build-host)
            shift
            build_host="$1"
            ;;
        --flake)
            shift
            flake="$1"
            ;;
        --verbose)
            verbose="$1"
            ;;
	--use-remote-sudo)
	    use_remote_sudo="$1"
	    ;;
        --show-trace)
            show_trace="$1"
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

# Set default values for optional parameters
#target_host="${target_host:-localhost}"
flake="${flake:-.#$target_host}"

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

# Run the specified nixos-rebuild sub-command
run_nixos_rebuild() {
    local sub_command="$1"
    local nixos_rebuild_command="nixos-rebuild ${use_remote_sudo:+--use-remote-sudo} ${verbose:+--verbose} ${show_trace:+--show-trace} $sub_command ${target_host:+--target-host ${target_host:-$target_host}} ${build_host:+--build-host ${build_host:-$build_host}}  --flake $flake"
    echo "Command to run: $nixos_rebuild_command"
    
    start_time=$(date +%s)
    if $nixos_rebuild_command; then
        end_time=$(date +%s)
        elapsed_time=$((end_time - start_time))
        echo "⏱️ Operation took $(display_elapsed_time "$elapsed_time")"
        echo "✅ Operation completed successfully 🚀"
    else
        end_time=$(date +%s)
        elapsed_time=$((end_time - start_time))
        echo "Error executing $sub_command after $(display_elapsed_time "$elapsed_time"). 😞"
        exit 1
    fi
}

# Test SSH connection
echo "Testing any ssh connection(s) that may be required before going any further"
#if [[ -n "$build_host" && "$target_host" != "$build_host" ]]; then
if [[ -n "$build_host" ]]; then
    echo "--build-host defined: testing connection with $build_host..."
    test_ssh_connection "$build_host"
else 
    echo "--build-host not defined: No need to test ssh as will build localy."
fi

if [[ -n "$target_host" ]]; then
    echo "--target-host defined, testing connection with $target_host..."
    test_ssh_connection "$target_host"
else 
    echo "--target-host not defined: No need to test ssh as will deploy locally."
fi

# Run the specified nixos-rebuild sub-command
case $sub_command in
    switch|boot|test|build|dry-activate|build-vm)
        run_nixos_rebuild "$sub_command"
        ;;
    *)
        echo "Error: '$sub_command' is not a valid sub-command. Use --help to learn more."
        display_usage
        exit 1
        ;;
esac

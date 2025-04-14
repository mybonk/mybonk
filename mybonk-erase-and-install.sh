#bash!

construct_command() {
    local command="nix run github:nix-community/nixos-anywhere -- --flake "$flake" $target_host"
    [[ "$test_mode" == "true" ]] && command+=" --vm-test"
    echo $command
}

confirm_operation() {
    echo "### ALL DATA WILL BE LOST ###"
    echo "This action will change the partitions and format the drive(s) on the target machine."
    echo "The following command will be executed:" 
    echo "$command"
    echo "Are you really certain you want to run it? (y/n)"
    read -r confirmation
    [[ "$confirmation" != "y" ]] && echo "Operation cancelled." && exit 0
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
    local start_time=$(date +%s)
    #$command || { local end_time=$(date +%s); echo "Error executing nix run after $(display_elapsed_time $((end_time - start_time))). 😞"; exit 1; }
    #local end_time=$(date +%s)
    #echo "⏱️ Operation took $(display_elapsed_time $((end_time - start_time)))"
    #echo "✅ Operation completed successfully 🚀"
}

display_elapsed_time() {
    local seconds=$1 days=$((seconds / 86400)) hours=$((seconds / 3600 % 24)) minutes=$((seconds / 60 % 60)) seconds=$((seconds % 60))
    printf "%ds (%02dd, %02dh, %02dm, %02ds)" $seconds $days $hours $minutes $seconds
}

# Display usage information
display_usage() {
    echo "Usage: $0 --target-host <target-host> --flake <flake> [--test]"
    echo "Options:"
    echo "  --test  Runs the operation in test mode (adds --vm-test to the nix run command)"
    exit 1
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
        --test_mode)
            test_mode=true
            ;;
        --help)
            display_usage
            exit 0
            ;;
        *)
            display_usage
            exit 1
    esac
    shift
done

# Test SSH connection
echo "Testing any ssh connection(s) that may be required before going any further"
if [[ -n "$target_host" ]]; then
    echo "--target-host defined, testing connection with $target_host..."
    test_ssh_connection "$target_host"
else 
    echo "--target-host not defined: No need to test ssh as will deploy locally."
fi


command=$(construct_command "$target_host" "$flake" "$test_mode")
confirm_operation

run_nix_run "$nix_run_command"
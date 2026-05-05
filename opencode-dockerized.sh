#!/bin/bash

# OpenCode Docker Wrapper Script
# This script makes it easy to run OpenCode in a secure Docker container

set -e

# Resolve symlinks so SCRIPT_DIR points to the real source directory
# This allows the script to be invoked via a symlink in PATH (e.g. ~/.local/bin)
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
IMAGE_NAME="opencode-dockerized:latest"

# Colors for output (defined before sourcing config-lib so it picks them up)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Source the shared config module
source "$SCRIPT_DIR/config-lib.sh"

# Function to print colored output
print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Function to check if Docker is running
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
}

# Function to check required configuration files
check_config() {
    local missing_files=()

    if [ ! -f "$HOME/.config/opencode/opencode.json" ] && [ ! -f "$HOME/.config/opencode/opencode.jsonc" ]; then
        missing_files+=("$HOME/.config/opencode/opencode.json (or opencode.jsonc)")
    fi

    if [ ! -d "$HOME/.local/share/opencode" ]; then
        missing_files+=("$HOME/.local/share/opencode/")
    fi

    if [ ${#missing_files[@]} -gt 0 ]; then
        print_warning "Some OpenCode configuration files are missing:"
        for file in "${missing_files[@]}"; do
            echo "  - $file"
        done
        print_info "OpenCode will run but may need configuration. Run 'opencode auth login' inside the container."
    fi

    # Ensure OpenCode storage directories exist
    # According to docs: https://opencode.ai/docs/troubleshooting/#storage
    ensure_opencode_dirs
}

# Function to run OpenCode authentication
run_auth() {
    check_image "$IMAGE_NAME" || exit 1

    print_info "Running OpenCode authentication..."

    # Ensure OpenCode directories exist
    ensure_opencode_dirs

    # Parse custom config and build docker arguments
    parse_config
    build_mount_args
    build_env_args
    build_common_docker_args

    # Build volume mount arguments for auth
    local -a auth_volume_args=(
        -v "$HOME/.local/share/opencode:/home/app/.local/share/opencode"
        -v "$HOME/.cache/opencode:/home/app/.cache/opencode"
        # Config directory read-write for writing opencode.json during auth
        -v "$HOME/.config/opencode:/home/app/.config/opencode"
    )

    # Run OpenCode auth login in Docker
    if ! docker run -it \
        --name "opencode-auth-$$" \
        "${DOCKER_COMMON_ARGS[@]}" \
        "${auth_volume_args[@]}" \
        "${DOCKER_MOUNT_ARGS[@]}" \
        "${DOCKER_ENV_ARGS[@]}" \
        "$IMAGE_NAME" \
        opencode auth login; then
        print_error "Authentication failed"
        exit 1
    fi

    print_success "Authentication complete! Your credentials are saved in $HOME/.local/share/opencode"
}

# Function to run OpenCode
run_opencode() {
    local project_dir="${1:-$(pwd)}"
    local dry_run="${DRY_RUN:-false}"

    # Validate project directory exists
    if [ ! -d "$project_dir" ]; then
        print_error "Project directory does not exist: $project_dir"
        exit 1
    fi

    # Convert to absolute path
    project_dir="$(cd "$project_dir" && pwd)"

    check_image "$IMAGE_NAME" || exit 1

    # Generate unique container name based on project directory and random suffix
    local dir_name
    dir_name=$(sanitize_container_name "$(basename "$project_dir")")
    local random_suffix
    random_suffix=$(generate_random_suffix)
    local container_name="opencode-${dir_name}-${random_suffix}"

    print_info "Starting OpenCode in Docker..."
    print_info "Project directory: $project_dir"
    print_info "Container name: $container_name"

    INCLUDE_DOCKER_SOCKET=false
    # Parse custom config and build docker arguments
    parse_config
    build_mount_args
    build_env_args
    build_common_docker_args
    build_standard_volume_args "$project_dir" "$INCLUDE_DOCKER_SOCKET"

    # Build the full docker run command as an array
    # CONTAINER_WORKDIR is set by build_standard_volume_args (host path with $HOME stripped)
    local -a docker_cmd=(
        docker run -it
        --name "$container_name"
        --workdir "$CONTAINER_WORKDIR"
        -e "OPENCODE_WORKDIR=$CONTAINER_WORKDIR"
        "${DOCKER_COMMON_ARGS[@]}"
        "${VOLUME_ARGS[@]}"
        "${GIT_WORKTREE_ARGS[@]}"
        "${DOCKER_MOUNT_ARGS[@]}"
        "${DOCKER_ENV_ARGS[@]}"
        "$IMAGE_NAME"
        opencode
    )

    if [ "$dry_run" = true ]; then
        print_info "Dry run — would execute:"
        echo "${docker_cmd[*]}"
        return 0
    fi

    # Note: Each run gets a unique container name, so no cleanup needed
    # The --rm flag ensures automatic cleanup when the container exits
    if ! "${docker_cmd[@]}"; then
        print_error "OpenCode exited with an error"
        exit 1
    fi
}

# Function to update OpenCode configuration files on the host
update_opencode_config() {
    local src_dir="$SCRIPT_DIR/config/opencode"
    local dest_dir="$HOME/.config/opencode"

    if [ ! -d "$src_dir" ]; then
        print_error "Source OpenCode config directory not found: $src_dir"
        exit 1
    fi

    mkdir -p "$dest_dir"

    # Core OpenCode config files
    if [ -f "$src_dir/opencode.jsonc" ]; then
        cp "$src_dir/opencode.jsonc" "$dest_dir/opencode.jsonc"
        print_success "Updated ~/.config/opencode/opencode.jsonc"
    fi

    if [ -f "$src_dir/oh-my-opencode.json" ]; then
        cp "$src_dir/oh-my-opencode.json" "$dest_dir/oh-my-opencode.json"
        print_success "Updated ~/.config/opencode/oh-my-opencode.json"
    fi

    # Optional command and plugin directories
    if [ -d "$src_dir/commands" ]; then
        mkdir -p "$dest_dir/commands"
        cp -R "$src_dir/commands/." "$dest_dir/commands/"
        print_success "Updated ~/.config/opencode/commands/"
    fi

    if [ -d "$src_dir/plugins" ]; then
        mkdir -p "$dest_dir/plugins"
        cp -R "$src_dir/plugins/." "$dest_dir/plugins/"
        print_success "Updated ~/.config/opencode/plugins/"
    fi

    print_info "OpenCode configuration refresh complete"
}

# Function to show or edit configuration
show_config() {
    local subcommand="${1:-show}"

    case "$subcommand" in
        show)
            parse_config
            print_config
            ;;
        edit)
            if [ -z "$EDITOR" ]; then
                print_error "EDITOR environment variable is not set"
                exit 1
            fi
            if [ ! -f "$CONFIG_FILE" ]; then
                print_warning "Config file does not exist. Running setup first..."
                "$SCRIPT_DIR/setup.sh"
            else
                "$EDITOR" "$CONFIG_FILE"
            fi
            ;;
        path)
            echo "$CONFIG_FILE"
            ;;
        *)
            print_error "Unknown config subcommand: $subcommand"
            echo "Usage: $0 config [show|edit|path]"
            exit 1
            ;;
    esac
}

# Function to manage OpenCode config templates on host
manage_opencode_config() {
    local subcommand="${1:-update}"

    case "$subcommand" in
        update)
            update_opencode_config
            ;;
        *)
            print_error "Unknown config-opencode subcommand: $subcommand"
            echo "Usage: $0 config-opencode [update]"
            exit 1
            ;;
    esac
}

# Function to show help
show_help() {
    cat << EOF
OpenCode Docker Wrapper

Usage: $0 [COMMAND] [OPTIONS]

Commands:
    run [DIR]           Run OpenCode in Docker (default: current directory)
    auth                Run OpenCode authentication (opencode auth login)
    version             Show OpenCode version in the container
    config [show|edit|path]  Show, edit, or print config file path
    config-opencode [update]  Update OpenCode config files from repository templates
    help                Show this help message

Environment Variables:
    DRY_RUN=true        Print the Docker command without executing it

For more information, see README.md
EOF
}

# Function to show version
show_version() {
    check_image "$IMAGE_NAME" || exit 1
    docker run --rm --entrypoint bash "$IMAGE_NAME" -c "source \$NVM_DIR/nvm.sh && opencode --version"
}

# Main script logic
main() {
    check_docker

    local command="${1:-run}"
    shift || true

    case "$command" in
        run)
            check_config
            run_opencode "$@"
            ;;
        auth)
            run_auth
            ;;
        version)
            show_version
            ;;
        config)
            show_config "$@"
            ;;
        config-opencode)
            manage_opencode_config "$@"
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "Unknown command: $command"
            echo
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"

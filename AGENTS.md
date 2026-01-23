# Agent Guidelines for OpenCode Dockerized

## Project Overview

Shell script-based Docker wrapper for running OpenCode (AI coding assistant) in secure, isolated containers with controlled project access. Provides a sandboxed environment limiting OpenCode's blast radius to only the mounted project directory.

**Key Components:**
- `opencode-dockerized.sh` - Main wrapper script with build, run, auth, update commands
- `Dockerfile` - Container image with Node.js, Java, Python, Docker CLI
- `entrypoint.sh` - UID/GID mapping for host file permissions
- `setup.sh` - First-time initialization for config directories
- Shell completion scripts for Bash and Zsh

## Build/Test/Lint Commands

```bash
# Core Operations
./opencode-dockerized.sh build          # Build Docker image
./opencode-dockerized.sh auth           # Authenticate OpenCode (no local install needed)
./opencode-dockerized.sh run [DIR]      # Run OpenCode (default: current dir)
./opencode-dockerized.sh update         # Update OpenCode to latest version
./opencode-dockerized.sh version        # Show OpenCode version in container
./opencode-dockerized.sh help           # Show help message

# Setup
./setup.sh                              # Initialize config directories (~/.config/opencode, etc.)
chmod +x *.sh                           # Fix script permissions if needed

# Testing & Validation
bash -n script.sh                       # Syntax check a shell script (static analysis)
bash -n *.sh                            # Syntax check all shell scripts
shellcheck script.sh                    # Lint shell script (if shellcheck installed)

# Docker Operations
docker build -t opencode-dockerized:latest .                    # Manual build
docker build --no-cache -t opencode-dockerized:latest .         # Force rebuild
docker run --rm opencode-dockerized:latest opencode --version   # Check version
```

## Code Style Guidelines

### Shell Scripts (Bash)

**File Header:**
```bash
#!/bin/bash
set -e  # Exit on first error
```

**Variable Handling:**
- Always quote variables: `"$variable"` not `$variable`
- Use `$()` for command substitution, not backticks
- Use absolute paths: `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"`
- Convert relative to absolute: `project_dir="$(cd "$project_dir" && pwd)"`

**Function & Variable Naming:**
- Functions: snake_case - `check_docker()`, `build_image()`, `print_error()`
- Constants: UPPER_SNAKE - `IMAGE_NAME`, `SCRIPT_DIR`
- Local variables: lower_snake - `project_dir`, `volume_args`

**Color Output Pattern:**
```bash
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
print_error() { echo -e "${RED}x${NC} $1"; }
print_success() { echo -e "${GREEN}v${NC} $1"; }
print_warning() { echo -e "${YELLOW}!${NC} $1"; }
print_info() { echo -e "${BLUE}i${NC} $1"; }
```

**Error Handling:**
- Redirect stderr for expected failures: `2>/dev/null || true`
- Check prerequisites before operations (e.g., `check_docker` before Docker commands)
- Use explicit error messages with `print_error()` before `exit 1`

**Conditionals:**
```bash
[ -f "$file" ] && echo "File exists"      # File check
[ -d "$dir" ] && echo "Dir exists"        # Directory check
[ -S "$socket" ] && echo "Socket exists"  # Socket check

if ! docker info >/dev/null 2>&1; then
    print_error "Docker is not running"
    exit 1
fi
```

**Multi-line Help:**
```bash
show_help() {
    cat << EOF
Usage: $0 [COMMAND] [OPTIONS]
Commands:
    run [DIR]    Run OpenCode (default: current directory)
    build        Build the Docker image
EOF
}
```

### Dockerfile Best Practices

- Use specific versions: `debian:bookworm-slim` not `latest`
- Clean up in same RUN layer: `&& rm -rf /var/lib/apt/lists/*`
- Install Docker CLI only (not daemon): `docker-ce-cli` not `docker-ce`
- Install language tools as non-root user: NVM (Node.js), SDKMAN (Java), uv (Python)
- Use official installers from trusted sources
- Create non-root user: `useradd -m -s /bin/bash -u 1000 coder`
- Document security/architecture decisions in comments

### Security Conventions

**Volume Mounts:**
- Mount config files read-only (`:ro`) when possible
- Only mount what's necessary
- Separate read-only config from read-write data directories

**Sensitive Files (never commit):**
- `.env`, `auth.json`, `*.pem`, `*.key`, credentials

**Docker Socket:**
- Use host Docker socket mounting (no privileged mode)
- No Docker-in-Docker daemon - CLI only uses host daemon
- Handle socket permissions dynamically in entrypoint

**Container Execution:**
- Run as non-root user inside container
- Map container UID/GID to match host user
- Use `--rm` flag for automatic cleanup

### File Organization

```
project/
  AGENTS.md                           # Agent guidelines (this file)
  README.md                           # User documentation
  Dockerfile                          # Container image definition
  entrypoint.sh                       # Container entrypoint script
  opencode-dockerized.sh              # Main wrapper script
  run-simple.sh                       # Simplified alternative runner
  setup.sh                            # First-time setup script
  opencode-dockerized-completion.bash # Bash completion
  opencode-dockerized-completion.zsh  # Zsh completion
  .env.example                        # Environment variable template
  .gitignore                          # Git ignore patterns
```

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Shell scripts | kebab-case with `.sh` | `opencode-dockerized.sh` |
| Functions | snake_case | `check_docker()`, `build_image()` |
| Constants | UPPER_SNAKE | `IMAGE_NAME`, `SCRIPT_DIR` |
| Local variables | lower_snake | `project_dir`, `volume_args` |
| Docker images | kebab-case:tag | `opencode-dockerized:latest` |
| Container names | kebab-case with suffix | `opencode-myproject-abc123` |

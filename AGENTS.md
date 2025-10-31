# Agent Guidelines for OpenCode Dockerized

## Project Overview
Shell script-based Docker wrapper for running OpenCode in secure, isolated containers with controlled project access.

## Build/Test Commands
```bash
./opencode-dockerized.sh build          # Build Docker image
./opencode-dockerized.sh run [DIR]      # Run OpenCode (default: current dir)
./opencode-dockerized.sh update         # Update OpenCode version
./opencode-dockerized.sh version        # Show OpenCode version
./setup.sh                              # Initialize config directories
chmod +x *.sh                           # Fix script permissions if needed
```

## Code Style Guidelines

### Shell Scripts
- Use `set -e` at script start for error handling
- Use `bash` (not `sh`) - shebang: `#!/bin/bash`
- Quote all variables: `"$variable"` not `$variable`
- Use `$()` for command substitution, not backticks
- Prefer absolute paths: `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"`
- Use meaningful function names: `check_docker()`, `build_image()`, `print_error()`
- Color codes: RED, GREEN, YELLOW, BLUE with NC reset
- Check prerequisites before operations (e.g., `check_docker` before running)

### Dockerfile
- Use specific base image versions: `node:20-slim` not `node:latest`
- Clean up in same RUN layer: `&& rm -rf /var/lib/apt/lists/*`
- Create non-root user with UID/GID flexibility
- Use COPY for scripts, make executable with chmod
- Document security considerations in comments

### Error Handling
- Always use `set -e` to exit on errors
- Provide user-friendly error messages with `print_error()`
- Check for missing files/directories before operations
- Use `|| true` to continue despite expected failures
- Redirect stderr appropriately: `2>/dev/null || true`

### Security
- Mount config files read-only (`:ro`)
- Run as non-root user inside container
- Use UID/GID mapping via entrypoint
- Never commit `.env`, `auth.json`, or API keys
- Document security boundaries and blast radius

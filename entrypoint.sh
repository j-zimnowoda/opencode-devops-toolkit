#!/bin/bash
set -e


# Resolve the project working directory (set by opencode-dockerized.sh)
# Falls back to /workspace for backward compatibility
WORKDIR="${OPENCODE_WORKDIR:-/}"

# Switch to coder user and execute the command
# Set HOME explicitly to ensure it points to /home/coder
export HOME=/home/app
export USER=node

# Source NVM and SDKMAN to make Node.js and Java available
export NVM_DIR="/home/app/.nvm"

# Auto-initialize OpenSpec for the project if enabled and not yet initialized
# Runs 'openspec init --tools opencode --profile core' in the project directory when:
#   1. OPENSPEC_SUPPORT=true (set by opencode-dockerized config)
#   2. No openspec/ directory exists in the project yet
#   3. The openspec CLI is available in the image
# Then runs 'openspec update' to regenerate instruction files for the current CLI version.
# The update also runs on already-initialized projects to keep files in sync after upgrades.
if [ "${OPENSPEC_SUPPORT:-false}" = "true" ]; then
    if command -v openspec >/dev/null 2>&1 || [ -x "$NVM_DIR/default/bin/openspec" ]; then
        if [ ! -d "$WORKDIR/openspec" ]; then
            echo "OpenSpec: initializing project with OpenCode tool integration..."
            setpriv --reuid="$TARGET_UID" --regid="$TARGET_GID" --init-groups \
                bash -c "source \$NVM_DIR/nvm.sh && cd \"$WORKDIR\" && openspec init --tools opencode --profile core" 2>/dev/null || \
                echo "OpenSpec: init failed (non-fatal) — you can run 'openspec init --tools opencode --profile core' manually"
        fi
        # Update instruction files to match the current CLI version (idempotent)
        setpriv --reuid="$TARGET_UID" --regid="$TARGET_GID" --init-groups \
            bash -c "source \$NVM_DIR/nvm.sh && cd \"$WORKDIR\" && openspec update" 2>/dev/null || true
    fi
fi

# Use setpriv to drop privileges and exec the command as the mapped user
# cd into the project working directory before executing
exec setpriv --reuid="$TARGET_UID" --regid="$TARGET_GID" --init-groups \
    bash -c "source \$NVM_DIR/nvm.sh && source /home/app/.sdkman/bin/sdkman-init.sh 2>/dev/null || true && cd \"$WORKDIR\" && exec \"\$@\"" \
    -- "$@"

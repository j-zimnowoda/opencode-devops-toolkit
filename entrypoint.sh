#!/bin/bash
set -e


# Resolve the project working directory (set by opencode-dockerized.sh)
# Falls back to /workspace for backward compatibility
WORKDIR="${OPENCODE_WORKDIR:-/}"

# Switch to coder user and execute the command
# Set HOME explicitly to ensure it points to /home/node
export HOME=/home/app
export USER=node

# Source NVM and SDKMAN to make Node.js and Java available
export NVM_DIR="/home/app/.nvm"

# # Use setpriv to drop privileges and exec the command as the mapped user
# # cd into the project working directory before executing
# bash -c "source \$NVM_DIR/nvm.sh && source /home/app/.sdkman/bin/sdkman-init.sh 2>/dev/null || true && cd \"$WORKDIR\" && exec \"\$@\"" \
#     -- "$@"

exec "$@" -- "$@"
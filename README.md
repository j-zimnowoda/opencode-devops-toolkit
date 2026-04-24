# OpenCode Dockerized - Secure Sandbox Environment

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Run OpenCode in a secure, isolated Docker container with controlled access to your projects. This setup provides OpenCode with just enough access to be useful while maintaining strong security boundaries.

## Overview 
The Dockerfile contains all required tools but it does not contain OpenCode plugins. 
After running `./setup.sh` the script will bootstrap required configuration files. Once its set plugins and versions in the `$HOME/.config/opencode/opencode.jsonc` on your host. The OpenCode in docker installs plugins with `bun` during the start.



## Prerequisites

1. **Docker** installed and running

## Installation
```bash
# 2. Run setup script (creates config directories on your host for persistence, adds to PATH)
./setup.sh

# 3. Build the Docker image
# For best experience build the container image that matches user and group id from your host 
docker build -t opencode-dockerized:latest --build-arg USER_UID=$(id -u) --build-arg USER_GID=$(id -g) .

# 4. Authenticate with your LLM provider (persists in ~/.local/share/opencode)
opencode-dockerized auth
```

## Version Updates
### Dockerfile
Change versions in Dockerfile and run 
```bash
# Force rebuild without cache
docker build --no-cache -t opencode-dockerized:latest .
```

### Opencode plugins
Open `.config/opencode/opencode.jsonc` file and change versions. Opencode will update them on startup

## Usage

```bash
opencode-dockerized build          # Build Docker image
opencode-dockerized auth           # Authenticate with LLM provider
opencode-dockerized run [DIR]      # Run OpenCode (default: current dir)
opencode-dockerized version        # Show version
opencode-dockerized config show    # Show parsed configuration
opencode-dockerized config edit    # Edit config in $EDITOR
opencode-dockerized config path    # Print config file path
opencode-dockerized clean          # Remove the Docker image
opencode-dockerized help           # Show help
```

### Dry Run Mode

Preview the `docker run` command without executing it:

```bash
DRY_RUN=true opencode-dockerized run /path/to/project
```
Prints the full Docker command with all volume mounts, environment variables, and flags — useful for debugging configuration issues.


## Working with OpenCode
This version comes with preconfigured Oh-My-Openagent (OMO) plugin, which is set to use Copilot models. Modify it accordingly to you LLM provider.

OMO comes with predefined primary agents. Use `tab` to switch between them.

You can perform build in OpenCode commands by typing `/` in the dialog window.

```bash
/status           # See the enabled MCP servers, formatters and plugins
/init-deep        # This is the OMO command that deeply analyze your project and creates hierarchical AGENTS.md knowledge base to help coding agents in the future assignments.
```

It your project does not have any `AGENTS.md` file the it is worth executing the `/init-deep`. This is the OMO command that deeply analyze your project and creates hierarchical AGENTS.md knowledge base to help coding agents in the future assignments.

# Appendix
### Global Installation

The `setup.sh` script offers to install `opencode-dockerized` globally by creating a symlink in `~/.local/bin`. This means you can run `opencode-dockerized` from any directory without navigating to the project first.

If you skipped global installation during setup, you can do it manually:

```bash
# Create symlink (one-time)
mkdir -p ~/.local/bin
ln -sf /path/to/opencode-dockerized/opencode-dockerized.sh ~/.local/bin/opencode-dockerized

# Ensure ~/.local/bin is in PATH (add to ~/.bashrc or ~/.zshrc if not)
export PATH="$HOME/.local/bin:$PATH"
```

### Create an Alias (Alternative)

If you prefer aliases over the global symlink:

```bash
# For Bash users - add to ~/.bashrc
echo "alias ocd='/path/to/opencode-dockerized/opencode-dockerized.sh'" >> ~/.bashrc
echo "alias ocdr='/path/to/opencode-dockerized/opencode-dockerized.sh run'" >> ~/.bashrc
source ~/.bashrc

# For Zsh users - add to ~/.zshrc
echo "alias ocd='/path/to/opencode-dockerized/opencode-dockerized.sh'" >> ~/.zshrc
echo "alias ocdr='/path/to/opencode-dockerized/opencode-dockerized.sh run'" >> ~/.zshrc
source ~/.zshrc

# Then use it anywhere
cd ~/my-project
ocd run
```

### Shell Completion (Optional)

Autocompletion support is available for both Bash and Zsh:

**For Bash:**
```bash
# Source the completion file
source /path/to/opencode-dockerized/completions/bash.sh

# Or add to ~/.bashrc for permanent installation
echo "source /path/to/opencode-dockerized/completions/bash.sh" >> ~/.bashrc
```

**For Zsh:**
```bash
# Source the completion file
source /path/to/opencode-dockerized/completions/zsh.sh

# Or add to ~/.zshrc for permanent installation
echo "source /path/to/opencode-dockerized/completions/zsh.sh" >> ~/.zshrc

# For system-wide installation (requires sudo)
sudo cp /path/to/opencode-dockerized/completions/zsh.sh /usr/local/share/zsh/site-functions/_opencode-dockerized
```

After installation, you'll get:
- Command completion (`run`, `build`, `update`, `version`, `auth`, `config`, `clean`, `help`)
- Subcommand completion for `config` (`show`, `edit`, `path`)
- Directory completion for the `run` command
- Helpful descriptions for each command
- Works with `opencode-dockerized.sh`, the global `opencode-dockerized` command, and the `ocd` alias


## 🔧 Configuration

### Environment Variables

Create a `.env` file (copy from `examples/.env.example`):

```bash
# Project directory to work on
PROJECT_DIR=/home/youruser/projects/myproject
# Terminal type
TERM=xterm-256color
```

### Volume Mounts

| Host Path | Container Path | Mode | Purpose |
|-----------|---------------|------|---------|
| `$PROJECT_DIR` | `$PROJECT_DIR` (with `$HOME` stripped) | read-write | Your project files |
| `~/.config/opencode/` | `/home/app/.config/opencode/` | read-only | OpenCode & oh-my-opencode config, skills, commands, agents |
| `~/.local/share/opencode/` | `/home/app/.local/share/opencode/` | read-write | Auth, logs, sessions, storage |
| `~/.cache/opencode/` | `/home/app/.cache/opencode/` | read-write | Provider package cache |
| `~/.cache/oh-my-opencode/` | `/home/app/.cache/oh-my-opencode/` | read-write | Oh My OpenCode cache |
| `~/.gradle/gradle.properties` | `/home/app/.gradle/gradle.properties` | read-only | Gradle config (optional) |
| `~/.npmrc` | `/home/app/.npmrc` | read-only | NPM config (optional) |
| `~/.mcp-auth/` | `/home/app/.mcp-auth/` | read-only | MCP authentication (optional) |


### Custom Global Configuration (Optional)

**Advanced Users:** You can configure custom volume mounts and environment variables to be automatically mounted in the container for all projects. This is useful for:

- **SSH agent forwarding**: Enable `setting.ssh_agent_support=true` for secure git over SSH (recommended)
- **Global git configuration**: Mount `~/.gitconfig` and global gitignore
- **Environment variables**: Pass API keys and other credentials

#### Getting Started with Custom Global Config

```bash
# During setup, you'll be prompted to add custom mounts and env vars
./setup.sh

# Or manually edit the config file
~/.config/opencode-dockerized/config
```

#### Config Format

Configuration is stored in `~/.config/opencode-dockerized/config` (INI format):

```ini
# Settings (built-in features)
# Format: setting.<name>=<value>
setting.ssh_agent_support=true
setting.openspec_support=true

# Custom volume mounts (read-only by default)
# Format: mount.<name>=<host_path>:<container_path>[:rw]
mount.gitconfig=~/.gitconfig:/home/app/.gitconfig

# Environment variables to pass from host to container
# Format: env.<name>=<VARIABLE_NAME>
env.aws_bedrock=AWS_BEARER_TOKEN_BEDROCK
env.context7=CONTEXT7_API_KEY
```

#### Examples

**Example 1: Git configuration with SSH agent forwarding (Recommended)**
```ini
setting.ssh_agent_support=true
mount.gitconfig=~/.gitconfig:/home/app/.gitconfig
```

**Example 2: API keys and credentials**
```ini
env.aws_bedrock=AWS_BEARER_TOKEN_BEDROCK
env.context7=CONTEXT7_API_KEY
```

**Note:** 
- **SSH Agent Support**: Use `setting.ssh_agent_support=true` instead of manually mounting `~/.ssh` or passing `SSH_AUTH_SOCK`
- Mounts are **read-only by default** (append `:rw` for read-write)
- Paths use `~` which is expanded to your home directory at runtime
- Environment variables must be set in your host environment to be passed
- Re-run `./setup.sh` anytime to update your custom configuration

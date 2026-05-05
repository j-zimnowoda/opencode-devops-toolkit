#compdef opencode-dockerized.sh
# shellcheck shell=bash disable=SC2034,SC2154,SC1087,SC2016

# Zsh completion for opencode-dockerized.sh
# Source this file in your ~/.zshrc or place in /usr/local/share/zsh/site-functions/

_opencode_dockerized() {
    local -a commands
    commands=(
        'run:Run OpenCode in Docker (default: current directory)'
        'auth:Run OpenCode authentication (opencode auth login)'
        'build:Build the Docker image'
        'update:Update OpenCode to the latest version'
        'version:Show OpenCode version in the container'
        'config:Show, edit, or print config file path'
        'config-opencode:Update OpenCode config files from repository templates'
        'clean:Remove the Docker image'
        'help:Show help message'
    )

    _arguments -C \
        '1: :->cmds' \
        '*:: :->args'

    case $state in
        cmds)
            _describe -t commands 'opencode-dockerized command' commands
            ;;
        args)
            case $words[1] in
                run)
                    _files -/
                    ;;
                config)
                    local -a config_cmds
                    config_cmds=(
                        'show:Show current configuration'
                        'edit:Edit config file in $EDITOR'
                        'path:Print config file path'
                    )
                    _describe -t config_cmds 'config subcommand' config_cmds
                    ;;
                config-opencode)
                    local -a opencode_config_cmds
                    opencode_config_cmds=(
                        'update:Refresh OpenCode config files from repository templates'
                    )
                    _describe -t opencode_config_cmds 'config-opencode subcommand' opencode_config_cmds
                    ;;
            esac
            ;;
    esac
}

compdef _opencode_dockerized opencode-dockerized.sh
compdef _opencode_dockerized opencode-dockerized
compdef _opencode_dockerized ocd

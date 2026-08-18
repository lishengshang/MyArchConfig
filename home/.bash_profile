# shellcheck shell=bash
# Bash login entrypoint managed by dotfiles.
# Load the interactive Bash configuration for login shells as well.
[[ -r "$HOME/.bashrc" ]] && source "$HOME/.bashrc"

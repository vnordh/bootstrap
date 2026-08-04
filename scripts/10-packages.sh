#!/usr/bin/env bash

set -Eeuo pipefail

require_root

packages=(
    bash-completion
    ca-certificates
    curl
    fzf
    git
    jq
    nano
    rsync
    shellcheck
    tmux
    tree
)

log_info "Updating package index"
apt-get update

log_info "Installing baseline packages"
apt-get install -y "${packages[@]}"

log_info "Baseline packages installed"

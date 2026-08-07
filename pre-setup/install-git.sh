#!/usr/bin/env bash

set -Eeuo pipefail

log_info() {
    printf '[INFO ] %s\n' "$*"
}

die() {
    printf '[ERROR] %s\n' "$*" >&2
    exit 1
}

[[ "$EUID" -eq 0 ]] ||
    die "This script must be run as root."

command -v apt-get >/dev/null 2>&1 ||
    die "apt-get not found; this script currently supports Debian-based systems."

if command -v git >/dev/null 2>&1; then
    log_info "Git already installed: $(git --version)"
    exit 0
fi

log_info "Updating package index"

apt-get update

log_info "Installing Git"

apt-get install -y git ca-certificates

command -v git >/dev/null 2>&1 ||
    die "Git installation failed."

log_info "Git installed: $(git --version)"

#!/usr/bin/env bash

set -Eeuo pipefail

target_user="${SUDO_USER:-}"
[[ -n "$target_user" && "$target_user" != "root" ]] ||
    die "Run bootstrap with sudo from the target user account."

target_home="$(getent passwd "$target_user" | cut -d: -f6)"
[[ -n "$target_home" ]] || die "Cannot determine home for $target_user."

source_file="${SCRIPT_DIR}/config/bash/bashrc"
target_file="${target_home}/.bashrc"

[[ -f "$source_file" ]] || die "Missing $source_file"

if cmp -s "$source_file" "$target_file"; then
    log_info "Bash configuration already current for $target_user"
else
    if [[ -e "$target_file" && ! -L "$target_file" ]]; then
        backup="${target_file}.bak.$(date +%Y%m%d-%H%M%S)"
        cp -p "$target_file" "$backup"
        chown "$target_user:$target_user" "$backup"
        log_info "Backed up existing .bashrc to $backup"
    fi

    install -o "$target_user" -g "$target_user" -m 0644 \
        "$source_file" "$target_file"

    log_info "Installed Bash configuration for $target_user"
fi

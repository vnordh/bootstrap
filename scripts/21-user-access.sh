#!/usr/bin/env bash

set -Eeuo pipefail

target_user="${SUDO_USER:-}"

[[ -n "$target_user" && "$target_user" != "root" ]] ||
    die "Run bootstrap with sudo from the target user account."

target_home="$(getent passwd "$target_user" | cut -d: -f6)"
target_group="$(id -gn "$target_user")"

[[ -n "$target_home" ]] ||
    die "Cannot determine home directory for $target_user."

source_file="${SCRIPT_DIR}/config/ssh/authorized_keys"
ssh_dir="${target_home}/.ssh"
target_file="${ssh_dir}/authorized_keys"

[[ -s "$source_file" ]] ||
    die "Missing or empty $source_file."

install -d \
    -o "$target_user" \
    -g "$target_group" \
    -m 0700 \
    "$ssh_dir"

if cmp -s "$source_file" "$target_file"; then
    log_info "SSH authorized keys already current for $target_user"
else
    install \
        -o "$target_user" \
        -g "$target_group" \
        -m 0600 \
        "$source_file" \
        "$target_file"

    log_info "Installed SSH authorized keys for $target_user"
fi

#!/usr/bin/env bash

set -Eeuo pipefail

source_file="${SCRIPT_DIR}/config/sshd/20-bootstrap.conf"
target_file="/etc/ssh/sshd_config.d/20-bootstrap.conf"
backup_file="${target_file}.previous"

[[ -f "$source_file" ]] || die "Missing $source_file"
require_command sshd
require_command systemctl

if cmp -s "$source_file" "$target_file"; then
    log_info "SSH server configuration already current"
    return 0
fi

if [[ -f "$target_file" ]]; then
    cp -p "$target_file" "$backup_file"
fi

install -o root -g root -m 0644 "$source_file" "$target_file"

if ! sshd -t; then
    log_error "Invalid SSH configuration; restoring previous state"

    if [[ -f "$backup_file" ]]; then
        mv "$backup_file" "$target_file"
    else
        rm -f "$target_file"
    fi

    sshd -t || die "SSH configuration remains invalid after rollback"
    die "SSH configuration was not installed"
fi

rm -f "$backup_file"

systemctl reload ssh
log_info "SSH server configured on ports 22 and 1122"

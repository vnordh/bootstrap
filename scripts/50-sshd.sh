#!/usr/bin/env bash

set -Eeuo pipefail

source_file="${SCRIPT_DIR}/config/sshd/sshd.conf"
target_file="/etc/ssh/sshd_config.d/20-bootstrap.conf"
backup_file="${target_file}.previous"

[[ -f "$source_file" ]] || die "Missing $source_file"
require_command sshd
require_command systemctl

if cmp -s "$source_file" "$target_file"; then
    log_info "SSH server configuration already current"
else

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
fi

if systemctl list-unit-files --type=socket --no-legend |
    awk '{print $1}' |
    grep -qx 'ssh.socket' &&
   systemctl is-active --quiet ssh.socket; then

    log_info "SSH uses systemd socket activation"

    systemctl daemon-reload
    systemctl restart ssh.socket
else
    log_info "SSH uses the traditional service"

    systemctl reload-or-restart ssh.service
fi

log_info "SSH server configured"

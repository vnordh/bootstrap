#!/usr/bin/env bash

set -Eeuo pipefail

readonly SSH_PORT="${SSH_PORT:-1122}"
readonly SSH_PORT_PLACEHOLDER="\${SSH_PORT}"

source_file="${SCRIPT_DIR}/config/sshd/sshd.conf"
target_file="/etc/ssh/sshd_config.d/20-bootstrap.conf"
backup_file="${target_file}.previous"
rendered_file="$(mktemp)"

cleanup() {
    rm -f "$rendered_file"
}

trap cleanup EXIT

[[ -f "$source_file" ]] || die "Missing $source_file"

require_command sshd
require_command systemctl

if [[ ! "$SSH_PORT" =~ ^[0-9]+$ ]] ||
   (( SSH_PORT < 1 || SSH_PORT > 65535 )); then
    die "SSH_PORT must be a number from 1 to 65535; current value: $SSH_PORT"
fi

template="$(<"$source_file")"

if [[ "$template" != *"$SSH_PORT_PLACEHOLDER"* ]]; then
    die "Missing $SSH_PORT_PLACEHOLDER placeholder in $source_file"
fi

printf '%s\n' \
    "${template//$SSH_PORT_PLACEHOLDER/$SSH_PORT}" \
    >"$rendered_file"

if grep -Fq "$SSH_PORT_PLACEHOLDER" "$rendered_file"; then
    die "SSH configuration contains an unresolved placeholder"
fi

if cmp -s "$rendered_file" "$target_file"; then
    log_info "SSH server configuration already current"
else
    if [[ -f "$target_file" ]]; then
        cp -p "$target_file" "$backup_file"
    fi

    install -o root -g root -m 0644 "$rendered_file" "$target_file"

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
    log_info "Set SSH port to $SSH_PORT"
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

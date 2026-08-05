#!/usr/bin/env bash

set -Eeuo pipefail

require_root
require_command apt-get
require_command apt-config

auto_source="${SCRIPT_DIR}/config/apt/auto-upgrades.conf"
policy_source="${SCRIPT_DIR}/config/apt/unattended-upgrades.conf"

auto_target="/etc/apt/apt.conf.d/20auto-upgrades"
policy_target="/etc/apt/apt.conf.d/52-bootstrap-unattended-upgrades"

[[ -f "$auto_source" ]] || die "Missing $auto_source"
[[ -f "$policy_source" ]] || die "Missing $policy_source"

log_info "Installing unattended-upgrades package"
apt-get install -y unattended-upgrades
require_command unattended-upgrade

if cmp -s "$auto_source" "$auto_target"; then
    log_info "Automatic update schedule already current"
else
    install -o root -g root -m 0644 "$auto_source" "$auto_target"
    log_info "Installed automatic update schedule"
fi

if cmp -s "$policy_source" "$policy_target"; then
    log_info "Unattended-upgrades policy already current"
else
    install -o root -g root -m 0644 "$policy_source" "$policy_target"
    log_info "Installed unattended-upgrades policy"
fi

apt-config dump >/dev/null ||
    die "APT configuration validation failed"

unattended-upgrade --dry-run --debug >/dev/null ||
    die "Unattended-upgrades dry-run failed"

log_info "Automatic updates configured"

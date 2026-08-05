#!/usr/bin/env bash

set -Eeuo pipefail

AUTOUPDATES_AUTOMATIC_REBOOT="${AUTOUPDATES_AUTOMATIC_REBOOT:-true}"
AUTOUPDATES_REBOOT_TIME="${AUTOUPDATES_REBOOT_TIME:-04:30}"

readonly AUTOUPDATES_AUTOMATIC_REBOOT
readonly AUTOUPDATES_REBOOT_TIME

readonly REBOOT_PLACEHOLDER="\${AUTOUPDATES_AUTOMATIC_REBOOT}"
readonly TIME_PLACEHOLDER="\${AUTOUPDATES_REBOOT_TIME}"

auto_source="${SCRIPT_DIR}/config/apt/auto-upgrades.conf"
policy_source="${SCRIPT_DIR}/config/apt/unattended-upgrades.conf"

auto_target="/etc/apt/apt.conf.d/20auto-upgrades"
policy_target="/etc/apt/apt.conf.d/52-bootstrap-unattended-upgrades"

rendered_policy="$(mktemp)"

cleanup() {
    rm -f "$rendered_policy"
}

trap cleanup EXIT

require_root
require_command apt-get
require_command apt-config

[[ -f "$auto_source" ]] || die "Missing $auto_source"
[[ -f "$policy_source" ]] || die "Missing $policy_source"

case "$AUTOUPDATES_AUTOMATIC_REBOOT" in
    true|false)
        ;;
    *)
        die "AUTOUPDATES_AUTOMATIC_REBOOT must be true or false"
        ;;
esac

if [[ ! "$AUTOUPDATES_REBOOT_TIME" =~ ^([01][0-9]|2[0-3]):[0-5][0-9]$ ]]; then
    die "AUTOUPDATES_REBOOT_TIME must use HH:MM format"
fi

policy_template="$(<"$policy_source")"

if [[ "$policy_template" != *"$REBOOT_PLACEHOLDER"* ]]; then
    die "Missing $REBOOT_PLACEHOLDER placeholder in $policy_source"
fi

if [[ "$policy_template" != *"$TIME_PLACEHOLDER"* ]]; then
    die "Missing $TIME_PLACEHOLDER placeholder in $policy_source"
fi

rendered="${policy_template//$REBOOT_PLACEHOLDER/$AUTOUPDATES_AUTOMATIC_REBOOT}"
rendered="${rendered//$TIME_PLACEHOLDER/$AUTOUPDATES_REBOOT_TIME}"

printf '%s\n' "$rendered" >"$rendered_policy"

if grep -Fq "\${AUTOUPDATES_" "$rendered_policy"; then
    die "Unattended-upgrades policy contains an unresolved placeholder"
fi

log_info "Installing unattended-upgrades package"
apt-get install -y unattended-upgrades
require_command unattended-upgrade

if cmp -s "$auto_source" "$auto_target"; then
    log_info "Automatic update schedule already current"
else
    install -o root -g root -m 0644 "$auto_source" "$auto_target"
    log_info "Installed automatic update schedule"
fi

if cmp -s "$rendered_policy" "$policy_target"; then
    log_info "Unattended-upgrades policy already current"
else
    install -o root -g root -m 0644 \
        "$rendered_policy" "$policy_target"

    log_info "Installed unattended-upgrades policy"
fi

apt-config dump >/dev/null ||
    die "APT configuration validation failed"

unattended-upgrade --dry-run --debug >/dev/null ||
    die "Unattended-upgrades dry-run failed"

log_info "Automatic updates configured"

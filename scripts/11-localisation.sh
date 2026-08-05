#!/usr/bin/env bash

set -Eeuo pipefail

readonly DESIRED_LOCALE="en_US.UTF-8"
readonly DESIRED_TIMEZONE="Europe/Madrid"
readonly DESIRED_KEYBOARD_LAYOUT="se"
readonly DESIRED_KEYBOARD_MODEL="pc105"

require_command locale-gen
require_command update-locale
require_command timedatectl

if ! locale -a | grep -qi '^en_US\.utf8$'; then
    log_info "Generating locale ${DESIRED_LOCALE}"
    locale-gen "$DESIRED_LOCALE"
else
    log_info "Locale ${DESIRED_LOCALE} already generated"
fi

current_locale="$(
    awk -F= '/^LANG=/ {
        gsub(/"/, "", $2)
        print $2
    }' /etc/default/locale 2>/dev/null
)"

if [[ "$current_locale" != "$DESIRED_LOCALE" ]]; then
    update-locale LANG="$DESIRED_LOCALE"
    log_info "Set system locale to ${DESIRED_LOCALE}"
else
    log_info "System locale already set to ${DESIRED_LOCALE}"
fi

current_timezone="$(timedatectl show -p Timezone --value)"

if [[ "$current_timezone" != "$DESIRED_TIMEZONE" ]]; then
    timedatectl set-timezone "$DESIRED_TIMEZONE"
    log_info "Set timezone to ${DESIRED_TIMEZONE}"
else
    log_info "Timezone already set to ${DESIRED_TIMEZONE}"
fi

timedatectl set-ntp true
log_info "Network time synchronization enabled"

if timedatectl show -p NTP --value | grep -qx yes; then
    log_info "NTP service enabled"
else
    die "Failed to enable NTP"
fi

keyboard_file="/etc/default/keyboard"

desired_keyboard_config="XKBMODEL=\"${DESIRED_KEYBOARD_MODEL}\"
XKBLAYOUT=\"${DESIRED_KEYBOARD_LAYOUT}\"
XKBVARIANT=\"\"
XKBOPTIONS=\"\""

if [[ -f "$keyboard_file" ]] &&
   [[ "$(cat "$keyboard_file")" == "$desired_keyboard_config" ]]; then
    log_info "Keyboard layout already set to ${DESIRED_KEYBOARD_LAYOUT}"
else
    printf '%s\n' "$desired_keyboard_config" >"$keyboard_file"
    log_info "Set keyboard layout to ${DESIRED_KEYBOARD_LAYOUT}"

    if command -v setupcon >/dev/null 2>&1; then
        setupcon
        log_info "Applied console keyboard layout"
    else
        log_warn "setupcon not available; keyboard layout will apply after reboot"
    fi
fi

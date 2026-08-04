#!/usr/bin/env bash

set -Eeuo pipefail

readonly DESIRED_LOCALE="en_US.UTF-8"
readonly DESIRED_TIMEZONE="Europe/Madrid"
readonly DESIRED_KEYBOARD_LAYOUT="se"
readonly DESIRED_KEYBOARD_MODEL="pc105"

require_command locale-gen
require_command update-locale
require_command timedatectl
require_command localectl

if ! locale -a | grep -qi '^en_US\.utf8$'; then
    log_info "Generating locale ${DESIRED_LOCALE}"
    locale-gen "$DESIRED_LOCALE"
else
    log_info "Locale ${DESIRED_LOCALE} already generated"
fi

current_locale="$(localectl status |
    awk -F= '/System Locale/ {gsub(/^[[:space:]]+/, "", $2); print $2}')"

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

current_layout="$(localectl status |
    awk -F: '/X11 Layout/ {gsub(/^[[:space:]]+/, "", $2); print $2}')"

current_model="$(localectl status |
    awk -F: '/X11 Model/ {gsub(/^[[:space:]]+/, "", $2); print $2}')"

if [[ "$current_layout" != "$DESIRED_KEYBOARD_LAYOUT" ||
      "$current_model" != "$DESIRED_KEYBOARD_MODEL" ]]; then

    localectl set-x11-keymap \
        "$DESIRED_KEYBOARD_LAYOUT" \
        "$DESIRED_KEYBOARD_MODEL"

    log_info "Set keyboard layout to ${DESIRED_KEYBOARD_LAYOUT}"
else
    log_info "Keyboard layout already set to ${DESIRED_KEYBOARD_LAYOUT}"
fi

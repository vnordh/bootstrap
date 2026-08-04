#!/usr/bin/env bash

log_info() {
    printf '[INFO ] %s\n' "$*"
}

log_warn() {
    printf '[WARN ] %s\n' "$*" >&2
}

log_error() {
    printf '[ERROR] %s\n' "$*" >&2
}

die() {
    log_error "$*"
    exit 1
}

require_root() {
    [[ $EUID -eq 0 ]] || die "This script must be run as root."
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || \
        die "Required command '$1' not found."
}

require_ubuntu() {
    [[ -r /etc/os-release ]] || die "Cannot identify operating system."

    # shellcheck disable=SC1091
    source /etc/os-release

    [[ "$ID" == "ubuntu" ]] || \
        die "Unsupported operating system: ${PRETTY_NAME:-unknown}"

    case "$VERSION_ID" in
        22.04|24.04|26.04)
            log_info "Detected Ubuntu $VERSION_ID"
            ;;
        *)
            die "Unsupported Ubuntu version: $VERSION_ID"
            ;;
    esac
}

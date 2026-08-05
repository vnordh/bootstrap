#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

ENV_FILE="${SCRIPT_DIR}/.env"

# shellcheck disable=SC1091

if [[ -f "$ENV_FILE" ]]; then

    env_mode="$(stat -c '%a' "$ENV_FILE")"

    if [[ "$env_mode" != "600" ]]; then

        die "$ENV_FILE must have permissions 600; current mode is $env_mode"

    fi

    set -a

    # shellcheck disable=SC1090

    source "$ENV_FILE"

    set +a

    log_info "Loaded environment from $ENV_FILE"

else

    log_info "No .env file found; using built-in defaults"

fi


# Load common functions
# shellcheck source=lib/common.sh
require_root
require_ubuntu

log_info "Bootstrap starting"

for script in "${SCRIPT_DIR}"/scripts/*.sh; do
    [[ -f "$script" ]] || continue

    log_info "Running $(basename "$script")"

    # shellcheck disable=SC1090
    source "$script"
done

log_info "Bootstrap completed successfully"

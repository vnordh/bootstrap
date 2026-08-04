#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load common functions
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

log_info "Bootstrap starting"

for script in "${SCRIPT_DIR}"/scripts/*.sh; do
    [[ -f "$script" ]] || continue

    log_info "Running $(basename "$script")"

    # shellcheck disable=SC1090
    source "$script"
done

log_info "Bootstrap completed successfully"

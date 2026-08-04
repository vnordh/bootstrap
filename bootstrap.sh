#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

log_info "Bootstrap starting"
log_info "Project directory: ${SCRIPT_DIR}"
log_info "Bootstrap complete"

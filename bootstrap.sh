#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Bootstrap"
echo "=========="
echo "Project directory: ${SCRIPT_DIR}"
echo
echo "Bootstrap complete."

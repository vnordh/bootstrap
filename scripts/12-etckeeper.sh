#!/usr/bin/env bash

set -Eeuo pipefail

require_root
require_command apt-get

log_info "Installing etckeeper"
apt-get install -y etckeeper git

require_command etckeeper

if [[ ! -d /etc/.git ]]; then
    log_info "Initialising etckeeper repository"
    etckeeper init
    etckeeper commit "Initial /etc snapshot"
else
    log_info "Etckeeper repository already initialised"
fi

log_info "Etckeeper configured"

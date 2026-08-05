#!/usr/bin/env bash

set -Eeuo pipefail

require_root
require_command apt-get
require_command debconf-set-selections

target_user="${SUDO_USER:-}"

[[ -n "$target_user" && "$target_user" != "root" ]] ||
    die "Run bootstrap with sudo from the target user account."

###############################################################################
# Validate environment
###############################################################################

required_variables=(
    MAIL_HOSTNAME
    MAIL_SMTP_HOST
    MAIL_SMTP_PORT
    MAIL_SMTP_USER
    MAIL_SMTP_PASSWORD
    MAIL_TO
)

for variable_name in "${required_variables[@]}"; do
    [[ -n "${!variable_name:-}" ]] ||
        die "$variable_name is required."
done

[[ "$MAIL_HOSTNAME" == *.* ]] ||
    die "MAIL_HOSTNAME must be a fully qualified hostname."

[[ "$MAIL_HOSTNAME" != .* &&
   "$MAIL_HOSTNAME" != *. &&
   "$MAIL_HOSTNAME" != *..* &&
   "$MAIL_HOSTNAME" != *[[:space:]]* ]] ||
    die "MAIL_HOSTNAME is not valid: $MAIL_HOSTNAME"

[[ "${MAIL_HOSTNAME,,}" != *.local ]] ||
    die "MAIL_HOSTNAME must not use the reserved .local domain."

[[ "$MAIL_SMTP_HOST" != *[[:space:]]* ]] ||
    die "MAIL_SMTP_HOST must not contain whitespace."

if [[ ! "$MAIL_SMTP_PORT" =~ ^[0-9]+$ ]] ||
   (( MAIL_SMTP_PORT < 1 || MAIL_SMTP_PORT > 65535 )); then
    die "MAIL_SMTP_PORT must be a number from 1 to 65535."
fi

[[ "$MAIL_SMTP_USER" == *@* ]] ||
    die "MAIL_SMTP_USER must be an email-style SMTP username."

[[ "$MAIL_TO" == *@* ]] ||
    die "MAIL_TO must be an email address."

###############################################################################
# Paths
###############################################################################

main_source="${SCRIPT_DIR}/config/postfix/main.cf"
passwd_source="${SCRIPT_DIR}/config/postfix/sasl-passwd"
aliases_source="${SCRIPT_DIR}/config/postfix/aliases"

main_target="/etc/postfix/main.cf"
passwd_target="/etc/postfix/sasl/passwd"
aliases_target="/etc/aliases"
mailname_target="/etc/mailname"

for source_file in \
    "$main_source" \
    "$passwd_source" \
    "$aliases_source"; do

    [[ -s "$source_file" ]] ||
        die "Missing or empty $source_file."
done

###############################################################################
# Install packages
#
# Tell Debian/Ubuntu that the bootstrap owns the Postfix configuration.
# This prevents the package questionnaire from generating main.cf.
###############################################################################

log_info "Installing Postfix mail packages"

export DEBIAN_FRONTEND=noninteractive

printf '%s\n' \
    'postfix postfix/main_mailer_type select No configuration' |
    debconf-set-selections

apt-get install -y \
    ca-certificates \
    gettext-base \
    libsasl2-modules \
    postfix

require_command debconf-communicate
require_command envsubst
require_command newaliases
require_command postfix
require_command postmap
require_command systemctl

###############################################################################
# Verify Postfix package configuration ownership
###############################################################################

debconf_reply="$(
    printf '%s\n' 'GET postfix/main_mailer_type' |
        debconf-communicate postfix
)"

[[ "$debconf_reply" == "0 No configuration" ]] ||
    die "Postfix Debconf state is not 'No configuration': $debconf_reply"

log_info "Postfix package configuration ownership verified"

###############################################################################
# Prepare directories and temporary files
###############################################################################

install -d \
    -o root \
    -g root \
    -m 0700 \
    /etc/postfix/sasl

main_rendered="$(mktemp)"
passwd_rendered="$(mktemp)"
aliases_rendered="$(mktemp)"
mailname_rendered="$(mktemp)"

main_backup="$(mktemp)"
passwd_backup="$(mktemp)"
aliases_backup="$(mktemp)"
mailname_backup="$(mktemp)"

main_existed=false
passwd_existed=false
aliases_existed=false
mailname_existed=false

cleanup() {
    rm -f \
        "$main_rendered" \
        "$passwd_rendered" \
        "$aliases_rendered" \
        "$mailname_rendered" \
        "$main_backup" \
        "$passwd_backup" \
        "$aliases_backup" \
        "$mailname_backup"
}

trap cleanup EXIT

###############################################################################
# Render templates
#
# The single-quoted envsubst lists are intentional. They pass literal variable
# names to envsubst while protecting Postfix variables such as $myhostname.
###############################################################################

# shellcheck disable=SC2016
envsubst \
    '$MAIL_HOSTNAME $MAIL_SMTP_HOST $MAIL_SMTP_PORT' \
    <"$main_source" \
    >"$main_rendered"

# shellcheck disable=SC2016
envsubst \
    '$MAIL_SMTP_HOST $MAIL_SMTP_PORT $MAIL_SMTP_USER $MAIL_SMTP_PASSWORD' \
    <"$passwd_source" \
    >"$passwd_rendered"

# shellcheck disable=SC2016
envsubst \
    '$MAIL_TO' \
    <"$aliases_source" \
    >"$aliases_rendered"

sudo_user_placeholder="\${SUDO_USER}"
aliases_content="$(<"$aliases_rendered")"

if [[ "$aliases_content" != *"$sudo_user_placeholder"* ]]; then
    die "Missing $sudo_user_placeholder placeholder in $aliases_source."
fi

printf '%s\n' \
    "${aliases_content//$sudo_user_placeholder/$target_user}" \
    >"$aliases_rendered"

printf '%s\n' "$MAIL_HOSTNAME" >"$mailname_rendered"

###############################################################################
# Verify rendering
###############################################################################

for rendered_file in \
    "$main_rendered" \
    "$passwd_rendered" \
    "$aliases_rendered"; do

    [[ -s "$rendered_file" ]] ||
        die "Rendered Postfix configuration is empty: $rendered_file"

    if grep -Eq '\$\{(MAIL_[A-Z0-9_]+|SUDO_USER)\}' "$rendered_file"; then
        die "Rendered Postfix configuration contains an unresolved placeholder."
    fi
done

###############################################################################
# Track changes and preserve existing files for rollback
###############################################################################

main_changed=false
passwd_changed=false
aliases_changed=false
mailname_changed=false

if [[ -f "$main_target" ]]; then
    cp -p "$main_target" "$main_backup"
    main_existed=true
fi

if [[ -f "$passwd_target" ]]; then
    cp -p "$passwd_target" "$passwd_backup"
    passwd_existed=true
fi

if [[ -f "$aliases_target" ]]; then
    cp -p "$aliases_target" "$aliases_backup"
    aliases_existed=true
fi

if [[ -f "$mailname_target" ]]; then
    cp -p "$mailname_target" "$mailname_backup"
    mailname_existed=true
fi

###############################################################################
# Install main.cf
###############################################################################

if cmp -s "$main_rendered" "$main_target"; then
    log_info "Postfix main configuration already current"
else
    install \
        -o root \
        -g root \
        -m 0644 \
        "$main_rendered" \
        "$main_target"

    main_changed=true
    log_info "Installed Postfix main configuration"
fi

###############################################################################
# Install /etc/mailname
###############################################################################

if cmp -s "$mailname_rendered" "$mailname_target"; then
    log_info "Mail hostname already current"
else
    install \
        -o root \
        -g root \
        -m 0644 \
        "$mailname_rendered" \
        "$mailname_target"

    mailname_changed=true
    log_info "Installed mail hostname"
fi

###############################################################################
# Install and index Gmail SMTP credentials
###############################################################################

if cmp -s "$passwd_rendered" "$passwd_target"; then
    log_info "Postfix SMTP credentials already current"
else
    install \
        -o root \
        -g root \
        -m 0600 \
        "$passwd_rendered" \
        "$passwd_target"

    passwd_changed=true
    log_info "Installed Postfix SMTP credentials"
fi

if [[ "$passwd_changed" == true ||
      ! -f "${passwd_target}.db" ]]; then

    postmap "$passwd_target"

    chown root:root \
        "$passwd_target" \
        "${passwd_target}.db"

    chmod 0600 \
        "$passwd_target" \
        "${passwd_target}.db"

    log_info "Generated Postfix SMTP credentials database"
fi

###############################################################################
# Install and index local aliases
###############################################################################

if cmp -s "$aliases_rendered" "$aliases_target"; then
    log_info "Mail aliases already current"
else
    install \
        -o root \
        -g root \
        -m 0644 \
        "$aliases_rendered" \
        "$aliases_target"

    aliases_changed=true
    log_info "Installed mail aliases"
fi

if [[ "$aliases_changed" == true ||
      ! -f "${aliases_target}.db" ]]; then

    newaliases
    log_info "Generated mail aliases database"
fi

###############################################################################
# Validate and roll back on failure
###############################################################################

if ! postfix check; then
    log_error "Postfix validation failed; restoring previous configuration"

    if [[ "$main_existed" == true ]]; then
        cp -p "$main_backup" "$main_target"
    else
        rm -f "$main_target"
    fi

    if [[ "$passwd_existed" == true ]]; then
        cp -p "$passwd_backup" "$passwd_target"
        postmap "$passwd_target"
        chmod 0600 "$passwd_target" "${passwd_target}.db"
    else
        rm -f "$passwd_target" "${passwd_target}.db"
    fi

    if [[ "$aliases_existed" == true ]]; then
        cp -p "$aliases_backup" "$aliases_target"
        newaliases
    else
        rm -f "$aliases_target" "${aliases_target}.db"
    fi

    if [[ "$mailname_existed" == true ]]; then
        cp -p "$mailname_backup" "$mailname_target"
    else
        rm -f "$mailname_target"
    fi

    postfix check ||
        die "Postfix remains invalid after rollback."

    die "Postfix configuration was not installed."
fi

###############################################################################
# Enable and activate Postfix
###############################################################################

systemctl enable postfix.service >/dev/null

if [[ "$main_changed" == true ||
      "$passwd_changed" == true ||
      "$mailname_changed" == true ]]; then

    systemctl reload-or-restart postfix.service
    log_info "Activated updated Postfix configuration"
else
    systemctl start postfix.service
fi

systemctl is-active --quiet postfix.service ||
    die "Postfix is not running."

if [[ "$aliases_changed" == false &&
      "$main_changed" == false &&
      "$passwd_changed" == false &&
      "$mailname_changed" == false ]]; then

    log_info "Postfix configuration already current"
fi

log_info "Postfix outbound Gmail relay configured"

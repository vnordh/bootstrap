#!/usr/bin/env bash

set -Eeuo pipefail

log_info() {
    printf '[INFO ] %s\n' "$*"
}

die() {
    printf '[ERROR] %s\n' "$*" >&2
    exit 1
}

[[ "$EUID" -eq 0 ]] ||
    die "This script must be run as root."

command -v apt-get >/dev/null 2>&1 ||
    die "apt-get not found; this script currently supports Debian-based systems."

read -r -p "Local username: " username

[[ "$username" =~ ^[a-z_][a-z0-9_-]*$ ]] ||
    die "Invalid username: $username"

read -r -p "GitHub username: " github_user

[[ -n "$github_user" ]] ||
    die "GitHub username is required."

read -r -p "Enable passwordless sudo for '$username'? [y/N]: " answer

case "${answer,,}" in
    y|yes)
        passwordless_sudo=true
        ;;
    *)
        passwordless_sudo=false
        ;;
esac

packages=()

command -v sudo >/dev/null 2>&1 || packages+=(sudo)
command -v curl >/dev/null 2>&1 || packages+=(curl)

if (( ${#packages[@]} > 0 )); then
    log_info "Installing required packages: ${packages[*]}"
    apt-get update
    apt-get install -y "${packages[@]}"
else
    log_info "Required packages already installed"
fi

if id "$username" >/dev/null 2>&1; then
    log_info "User '$username' already exists"
else
    log_info "Creating user '$username'"
    adduser "$username"
fi

user_home="$(
    getent passwd "$username" |
        cut -d: -f6
)"

[[ -n "$user_home" && -d "$user_home" ]] ||
    die "Could not determine home directory for '$username'."

if id -nG "$username" | tr ' ' '\n' | grep -qx sudo; then
    log_info "User '$username' already belongs to sudo group"
else
    log_info "Adding '$username' to sudo group"
    usermod -aG sudo "$username"
fi

ssh_dir="${user_home}/.ssh"
authorized_keys="${ssh_dir}/authorized_keys"
keys_tmp="$(mktemp)"

cleanup() {
    rm -f "$keys_tmp"
}

trap cleanup EXIT

log_info "Fetching SSH keys for GitHub user '$github_user'"

curl -fsSL \
    "https://github.com/${github_user}.keys" \
    >"$keys_tmp" ||
    die "Could not retrieve SSH keys for GitHub user '$github_user'."

[[ -s "$keys_tmp" ]] ||
    die "No public SSH keys found for GitHub user '$github_user'."

install \
    -d \
    -o "$username" \
    -g "$username" \
    -m 0700 \
    "$ssh_dir"

if [[ -f "$authorized_keys" ]] &&
   cmp -s "$keys_tmp" "$authorized_keys"; then

    log_info "SSH authorized_keys already current"
else
    install \
        -o "$username" \
        -g "$username" \
        -m 0600 \
        "$keys_tmp" \
        "$authorized_keys"

    log_info "Installed GitHub SSH keys"
fi

sudoers_file="/etc/sudoers.d/90-bootstrap-${username}"

if [[ "$passwordless_sudo" == true ]]; then
    sudoers_tmp="$(mktemp)"

    printf '%s ALL=(ALL:ALL) NOPASSWD: ALL\n' \
        "$username" \
        >"$sudoers_tmp"

    chmod 0440 "$sudoers_tmp"

    visudo -cf "$sudoers_tmp" >/dev/null ||
        die "Generated sudoers configuration is invalid."

    if [[ -f "$sudoers_file" ]] &&
       cmp -s "$sudoers_tmp" "$sudoers_file"; then

        log_info "Passwordless sudo already configured"
    else
        install \
            -o root \
            -g root \
            -m 0440 \
            "$sudoers_tmp" \
            "$sudoers_file"

        log_info "Passwordless sudo enabled for '$username'"
    fi

    rm -f "$sudoers_tmp"
else
    if [[ -f "$sudoers_file" ]]; then
        rm -f "$sudoers_file"
        log_info "Passwordless sudo disabled for '$username'"
    else
        log_info "Passwordless sudo not enabled"
    fi
fi

id "$username" >/dev/null 2>&1 ||
    die "User creation verification failed."

id -nG "$username" | tr ' ' '\n' | grep -qx sudo ||
    die "User '$username' is not a member of the sudo group."

log_info "Administrative user '$username' is ready"

printf '\nNext steps:\n\n'
printf '    ssh %s@<server>\n' "$username"

if command -v git >/dev/null 2>&1; then
    printf '    git clone https://github.com/vnordh/bootstrap.git\n'
    printf '    cd bootstrap\n'
    printf '    sudo ./bootstrap.sh\n'
else
    printf '    Git is not installed. Run pre-setup/install-git.sh first.\n'
fi

printf '\n'

# Bootstrap

Personal Ubuntu server bootstrap framework.

The goal of this project is to provide a reliable, repeatable, and idempotent way of configuring Ubuntu servers.

Running the bootstrap multiple times should converge the system to the same desired state without duplicating configuration or damaging an already configured system.

## Supported platforms

Currently supported:

- Ubuntu Server 22.04 LTS
- Ubuntu Server 24.04 LTS
- Ubuntu Server 26.04 LTS

Proxmox VE support may be added later with separate platform-specific policies.

## Design Principles

### Idempotency

Every script must be idempotent.

Running the bootstrap repeatedly should:

- not duplicate configuration;
- not fail because something already exists;
- only change the system when it differs from the desired state;
- leave the system in a working and predictable condition.

### Small, focused scripts

Each script should perform one logical task.

Scripts are executed in filename order.

Naming convention:

| Range | Purpose |
|------:|---------|
| `10-19` | Base system |
| `20-29` | Users and shell |
| `30-39` | Networking |
| `40-49` | Services |
| `50-59` | Security |
| `60-69` | Monitoring |
| `70-79` | Storage |
| `80-89` | Host-specific configuration |
| `90-99` | Personal preferences |

### Configuration ownership

The bootstrap follows these rules:

- Never modify package-owned configuration files when a supported override or drop-in mechanism exists.
- Use drop-in configuration where supported, such as:
  - `sshd_config.d`;
  - systemd unit overrides;
  - `sysctl.d`;
  - APT configuration drop-ins.
- When no supported override mechanism exists, the bootstrap owns the destination file and recreates it on every run.

### Configuration management

Configuration should normally be managed as complete files rather than edited in place.

Preferred workflow:

1. Store the desired configuration under `config/`.
2. Compare it with the installed version.
3. Replace it only when different.
4. Apply appropriate ownership and permissions.
5. Validate the configuration before restarting or reloading a service.
6. Log whether the configuration was updated or already current.

Avoid modifying configuration files with `sed`, `awk`, or regular-expression replacements unless there is no practical alternative.

### Validation and failure handling

Scripts should:

- validate required commands and source files;
- validate configuration before activating it;
- stop immediately on unrecoverable errors;
- restore the previous configuration when practical;
- produce clear error messages.

### Logging

Scripts should clearly report what they are doing.

Typical output should distinguish between:

- updated;
- already current;
- skipped;
- warning;
- error.

### Secrets

Secrets must not be committed to Git.

The committed `.env.example` file documents supported variables. The actual `.env` file is ignored by Git and may contain machine-specific values and secrets.

## Repository Layout

```text
bootstrap/
├── bootstrap.sh
├── README.md
├── .env.example
├── .gitignore
├── lib/
│   └── common.sh
├── scripts/
│   ├── 10-packages.sh
│   ├── 11-localisation.sh
│   ├── 12-etckeeper.sh
│   ├── 20-shell.sh
│   ├── 21-user-access.sh
│   ├── 40-automatic-updates.sh
│   └── 50-sshd.sh
└── config/
    ├── apt/
    │   ├── auto-upgrades.conf
    │   └── unattended-upgrades.conf
    ├── bash/
    │   └── bashrc
    ├── ssh/
    │   └── authorized_keys
    └── sshd/
        └── sshd.conf
```

## Current Modules

### Base packages

Installs the baseline command-line tools used on managed systems.

### Localisation

Configures:

- system locale;
- timezone;
- Swedish keyboard layout;
- network time synchronization.

### Etckeeper

Installs and initializes etckeeper for `/etc`.

Package-provided cron and systemd behavior is left unchanged.

### Shell configuration

Installs the managed Bash configuration for the target user.

### SSH authorized keys

Installs the managed `authorized_keys` file with appropriate ownership and permissions.

### Automatic updates

Configures Ubuntu unattended upgrades with:

- daily package-list updates;
- daily unattended upgrades;
- Ubuntu default security origins;
- removal of unused kernels and dependencies;
- automatic reboot when required;
- scheduled reboot time;
- no reboot while users are logged in;
- routine email reports disabled.

Automatic Ubuntu release upgrades are not performed.

### SSH server

Configures the SSH server with:

- port `1122`;
- root SSH login disabled;
- public-key authentication enabled;
- password authentication enabled;
- support for both traditional `ssh.service` operation and systemd socket activation.

## Configuration

The bootstrap works without a `.env` file by using built-in defaults.

To create machine-specific configuration:

```bash
cp .env.example .env
chmod 600 .env
nano .env
```

Then run:

```bash
sudo ./bootstrap.sh
```

The `.env` file may contain secrets and is excluded from Git.

The bootstrap refuses to load `.env` unless its permissions are exactly `600`.

Example variables include:

```dotenv
SYSTEM_LOCALE=en_US.UTF-8
SYSTEM_TIMEZONE=Europe/Madrid

KEYBOARD_LAYOUT=se
KEYBOARD_MODEL=pc105

SSH_PORT=1122

AUTOUPDATES_AUTOMATIC_REBOOT=true
AUTOUPDATES_REBOOT_TIME=04:30
```

Optional credentials and tokens should remain empty in `.env.example` and should only be populated in the local `.env` file.

## Installation

Clone the repository:

```bash
git clone git@github.com:vnordh/bootstrap.git
cd bootstrap
```

Optionally create `.env`:

```bash
cp .env.example .env
chmod 600 .env
nano .env
```

Run the bootstrap:

```bash
sudo ./bootstrap.sh
```

Run it again to verify idempotency:

```bash
sudo ./bootstrap.sh
```

## Development

Run ShellCheck before committing:

```bash
shellcheck -x bootstrap.sh lib/common.sh scripts/*.sh
```

Review changes:

```bash
git status
git diff
```

Commit and push using the configured helper:

```bash
gpush "Describe the change"
```

## Status

Early development.

The framework is already functional on Ubuntu Server 24.04, but additional testing is required for Ubuntu 22.04, Ubuntu 26.04, ARM-based Ubuntu derivatives, and future platform-specific support.

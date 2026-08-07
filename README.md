# Bootstrap

An idempotent bootstrap framework for Ubuntu Server.

The project provisions a new Ubuntu installation into a consistent, repeatable baseline using small, focused modules. Running the bootstrap multiple times converges the system to the desired state without duplicating configuration or damaging an already configured system.

## Features

- Baseline packages
- Locale, timezone and keyboard configuration
- Etckeeper
- Bash configuration
- SSH authorized keys
- SSH server configuration
- Automatic security updates
- Outbound mail notifications
- Idempotent operation

## Tested platform

Tested:

- Ubuntu Server 24.04 LTS

Expected to work, but not yet fully tested:

- Ubuntu Server 22.04 LTS
- Ubuntu Server 26.04 LTS

## Installation

Clone the repository:

```bash
git clone git@github.com:vnordh/bootstrap.git
cd bootstrap
```

Create a machine-specific configuration if required:

```bash
cp .env.example .env
chmod 600 .env
nano .env
sudo ./bootstrap.sh
```

Re-running the bootstrap is supported and should only apply necessary changes.

## Configuration

Defaults are built into the bootstrap.

Machine-specific settings are stored in `.env`.

Common options include:

- locale
- timezone
- keyboard layout
- SSH port
- automatic reboot policy
- SMTP relay settings
- notification recipient
- server hostname

See:

- `docs/configuration.md`

## Current modules

| Script | Purpose |
|---------|---------|
|10-packages|Baseline packages|
|11-localisation|Locale, timezone and keyboard|
|12-etckeeper|Etckeeper|
|20-shell|Bash configuration|
|21-user-access|SSH authorized keys|
|40-automatic-updates|Automatic updates|
|45-mail|Postfix SMTP relay|
|50-sshd|SSH server|

## Documentation

- `docs/architecture.md`
- `docs/configuration.md`
- `docs/development.md`
- `docs/mail.md`
- `docs/modules.md`

## Development

Run ShellCheck before committing:

```bash
shellcheck -x bootstrap.sh lib/common.sh scripts/*.sh
```

Typical workflow:

```bash
git diff
git status
gpush "Describe the change"
```

## Status

The bootstrap is under development.

It has been tested on Ubuntu Server 24.04 LTS and is intended to provide a repeatable, idempotent baseline for new servers.

Compatibility with Ubuntu Server 22.04 LTS, Ubuntu Server 26.04 LTS, ARM-based Ubuntu systems and future platform-specific support remains to be validated.

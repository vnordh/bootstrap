# Bootstrap

An idempotent bootstrap framework for Ubuntu Server.

The project provisions a new Ubuntu installation into a consistent, repeatable baseline using small, focused modules. Running the bootstrap multiple times converges the system to the desired state without duplicating configuration or damaging an already configured system.

## Features

- Idempotent design
- Baseline packages
- Locale, timezone and keyboard configuration
- Etckeeper
- Bash configuration
- SSH authorized keys
- SSH server configuration
- Automatic security updates
- Outbound mail notifications

## Tested platform

Tested:

- Ubuntu Server 24.04 LTS

Expected to work, but not yet fully tested:

- Ubuntu Server 22.04 LTS
- Ubuntu Server 26.04 LTS

## Repository layout

```text
bootstrap/
├── bootstrap.sh
├── README.md
├── .env.example
├── config/
├── docs/
├── hosts/
├── lib/
├── pre-setup/
└── scripts/
```

## Installation

Clone the repository:

```bash
git clone https://github.com/vnordh/bootstrap.git
cd bootstrap
```

On systems that only provide a root account (for example Proxmox VE), run the optional pre-setup scripts first.

```bash
To download the create-user.sh script:
curl -fsSLO https://raw.githubusercontent.com/vnordh/bootstrap/main/pre-setup/create-user.sh && chmod 755 create-user.sh

cd pre-setup
sudo ./install-git.sh
sudo ./create-user.sh
```

Then log in as the new user and continue:

```bash
cp .env.example .env
chmod 600 .env
nano .env

sudo ./bootstrap.sh
```

Re-running the bootstrap is supported and should only apply necessary changes.

## Configuration

The bootstrap contains sensible defaults.

Machine-specific settings are stored in `.env`.

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
|40-automatic-updates|Automatic security updates|
|45-mail|Postfix SMTP relay and notifications|
|50-sshd|SSH server configuration|

## Documentation

- `docs/architecture.md`
- `docs/configuration.md`
- `docs/development.md`
- `docs/mail.md`
- `docs/modules.md`
- `pre-setup/README.md`

## Development

Run ShellCheck before committing:

```bash
shellcheck -x bootstrap.sh lib/common.sh scripts/*.sh pre-setup/*.sh
```

Typical workflow:

```bash
git diff
git status
gpush "Describe the change"
```

## Status

The bootstrap is under development.

It has been tested on Ubuntu Server 24.04 LTS. Support for Ubuntu 22.04 LTS and Ubuntu 26.04 LTS is expected but not yet fully validated.

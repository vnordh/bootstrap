# Bootstrap

Personal Ubuntu server bootstrap framework.

The goal is to build a reliable, repeatable, and idempotent way of configuring Ubuntu servers.

## Design principles
## Design Principles

The goal of this project is to provide a deterministic, idempotent bootstrap for Ubuntu servers. Running the bootstrap multiple times should always converge the system to the same desired state.

### Configuration ownership

The bootstrap follows these rules:

- Never modify package-owned configuration files if a supported override mechanism exists.
- Use drop-in configuration whenever supported (for example `sshd_config.d`, `systemd`, `sysctl.d`, etc.).
- If no supported override mechanism exists, the bootstrap owns the configuration file and recreates it on every run.

### Configuration management

Configuration should be managed as complete files, not edited in place.

Preferred workflow:

1. Store the desired configuration under `config/`.
2. Compare it with the installed version.
3. Replace it atomically if different.
4. Log whether the file was updated or already current.

Avoid using `sed`, `awk`, or regular-expression replacements to modify existing configuration files unless there is no practical alternative.

### Idempotency

Every script must be idempotent.

Running the bootstrap repeatedly should:

- never duplicate configuration,
- never produce errors because something already exists,
- only make changes when the system differs from the desired state.

### Small, focused scripts

Each script should perform one logical task only.

Naming convention:

- `10-*` Base system
- `20-*` Users and shell
- `30-*` Networking
- `40-*` Services
- `50-*` Security
- `60-*` Monitoring
- `90-*` Personal preferences

### Logging

Scripts should clearly report what they are doing.

Typical output should distinguish between:

- configuration updated,
- already current,
- skipped,
- warning,
- error.

This makes repeated runs easy to review and simplifies troubleshooting.

- Small scripts with a single responsibility.
- Idempotent – safe to run repeatedly.
- Every script can be executed independently.
- No hidden side effects.
- Configuration separated from secrets.
- Minimal external dependencies.
- Fail fast with clear error messages.
- Validate before making changes.
- Prefer drop-in configuration over editing vendor files.
- Designed for long-term maintainability.

## Supported platforms

- Ubuntu Server 22.04 LTS
- Ubuntu Server 24.04 LTS
- Ubuntu Server 26.04 LTS

## Repository layout

```
bootstrap/
├── bootstrap.sh
├── README.md
├── lib/
├── scripts/
├── config/
└── hosts/
```

## Script numbering

| Range | Purpose |
|------:|---------|
| 10-19 | Base system |
| 20-29 | Users and shell |
| 30-39 | Networking |
| 40-49 | Services |
| 50-59 | Security |
| 60-69 | Monitoring |
| 70-79 | Storage |
| 80-89 | Host-specific configuration |
| 90-99 | Personal preferences (dotfiles, aliases, etc.) |

## Planned scripts

- Packages
- Locale
- Time synchronization
- SSH server
- User accounts
- Email notifications
- Unattended upgrades
- Etckeeper
- Dotfiles

## Status

🚧 Early development.


## Configuration

The bootstrap works without a `.env` file by using built-in defaults.

To customize a system:

```bash
cp .env.example .env
chmod 600 .env
nano .env
sudo ./bootstrap.sh

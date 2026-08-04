# Bootstrap

Personal Ubuntu server bootstrap framework.

The goal is to build a reliable, repeatable, and idempotent way of configuring Ubuntu servers.

## Design principles

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

# Architecture

The bootstrap configures Ubuntu servers through small shell modules executed in filename order.

## Execution model

`bootstrap.sh`:

1. validates the operating system;
2. loads `.env` when present;
3. loads shared functions from `lib/common.sh`;
4. runs each script under `scripts/` in lexical order.

Modules depend on the common functions loaded by `bootstrap.sh` and are not intended to be executed directly.

## Module numbering

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

## Idempotency

Each module should:

- compare the desired and installed state;
- only change files when required;
- tolerate repeated execution;
- validate configuration before activation;
- preserve or restore the previous configuration when practical.

## Configuration ownership

Preferred order:

1. use package-supported drop-ins or override directories;
2. install complete managed files when no suitable drop-in exists;
3. avoid editing files in place with regular-expression replacements.

Managed templates are stored under `config/`.

## Target user

The current model assumes:

- a non-root user already exists;
- that user runs `sudo ./bootstrap.sh`;
- `SUDO_USER` identifies the target account.

Direct execution as root or unattended execution without `SUDO_USER` is not currently supported for user-specific modules.

## Secrets

`.env.example` documents supported variables.

The real `.env` file:

- is excluded from Git;
- may contain credentials;
- must have permissions exactly `600`.

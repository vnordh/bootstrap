# Modules

Modules are executed by `bootstrap.sh` in filename order.

## `10-packages.sh`

Installs the baseline command-line packages used on managed systems.

The current package set includes tools for:

- shell completion;
- certificates and HTTPS;
- file transfer;
- Git;
- JSON processing;
- terminal editing and multiplexing;
- synchronization;
- shell validation;
- directory inspection.

The module updates the APT package index before installing packages.

## `11-localisation.sh`

Configures:

- system locale;
- timezone;
- console keyboard layout;
- network time synchronization.

Values are read from `.env` when configured.

The module avoids regenerating or rewriting settings that are already current.

## `12-etckeeper.sh`

Installs and initializes etckeeper for `/etc`.

It leaves the package-provided cron jobs and systemd timers unchanged.

The module initializes the repository only when `/etc` is not already managed by etckeeper.

## `20-shell.sh`

Installs the managed Bash configuration for the user who invoked the bootstrap through `sudo`.

The target account is determined from `SUDO_USER`.

The user’s home directory is resolved through the system account database rather than assumed to be under `/home`.

## `21-user-access.sh`

Installs the managed SSH `authorized_keys` file for the target user.

The module:

- creates the user’s `.ssh` directory when required;
- applies restrictive permissions;
- installs the key file with correct ownership;
- avoids rewriting an unchanged file.

## `40-automatic-updates.sh`

Installs and configures `unattended-upgrades`.

It manages:

- the APT periodic update schedule;
- unattended-upgrades policy;
- removal of unused kernels and dependencies;
- optional automatic reboot;
- reboot time;
- error-only email reporting.

The policy is rendered from `.env` values.

Unattended-upgrades sends mail to the local `root` account only when an error occurs. Postfix aliases then forward that mail to the configured external recipient.

The module validates the APT configuration and performs an unattended-upgrades dry run.

Automatic Ubuntu release upgrades are not configured.

## `45-mail.sh`

Configures Postfix as an outbound-only authenticated SMTP relay.

The module:

- installs Postfix, SASL support, CA certificates and `bsd-mailx`;
- configures the Postfix package for `No configuration` through Debconf;
- verifies that Debconf state after installation;
- renders the Postfix configuration from templates;
- installs SMTP credentials with restrictive permissions;
- generates the Postfix credentials database;
- installs local aliases;
- validates Postfix before activation;
- restores previous files if validation fails;
- enables and starts Postfix.

Postfix listens only on loopback and does not provide a public inbound mail service.

Local mail for `root` and the bootstrap user is forwarded to `MAIL_TO`.

The authenticated SMTP account may differ from the original local sender. Gmail, for example, may expose the authenticated address while preserving the original server sender in `X-Google-Original-From`.

## `50-sshd.sh`

Installs the managed SSH server drop-in:

```text
/etc/ssh/sshd_config.d/20-bootstrap.conf
```

The module:

- renders the SSH port from `SSH_PORT`;
- validates the generated configuration with `sshd -t`;
- restores the previous drop-in if validation fails;
- supports both traditional `ssh.service` operation and systemd socket activation.

The managed policy currently:

- disables root SSH login;
- enables public-key authentication;
- enables password authentication;
- enables keyboard-interactive authentication.

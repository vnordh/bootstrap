# Outbound Mail

The bootstrap configures Postfix as an outbound-only SMTP relay.

## Mail flow

```text
cron, unattended-upgrades or a local script
    -> local Postfix
    -> authenticated SMTP relay
    -> external recipient
```

Postfix listens only on the local host.

No inbound SMTP port is exposed to the network.

## Server identity

`MAIL_HOSTNAME` identifies the originating machine:

```dotenv
MAIL_HOSTNAME=server.example.com
```

Locally generated mail can therefore originate as:

```text
root@server.example.com
```

The SMTP provider may rewrite the visible sender to the authenticated account. Gmail preserves the original sender in:

```text
X-Google-Original-From
```

## Local aliases

The managed aliases include:

```text
postmaster -> root
root       -> MAIL_TO
SUDO_USER  -> MAIL_TO
```

This covers:

- root cron jobs;
- unattended-upgrades;
- system-generated mail;
- cron jobs belonging to the bootstrap user.

## Gmail example

```dotenv
MAIL_SMTP_HOST=smtp.gmail.com
MAIL_SMTP_PORT=587
MAIL_SMTP_USER=smtp-user@example.com
MAIL_SMTP_PASSWORD=application-password
MAIL_TO=recipient@example.com
```

The password should be a Google application password or another credential accepted by the configured account.

## Testing

Send a message through the local alias:

```bash
printf '%s\n' 'Mail test body' |
    mail -s "Mail test from $(hostname)" root
```

Check the queue:

```bash
sudo postqueue -p
```

Inspect recent logs:

```bash
sudo journalctl -u postfix --since "10 minutes ago" --no-pager
```

Validate the configuration:

```bash
sudo postfix check
```

## Unattended-upgrades

The configured policy is:

```text
Unattended-Upgrade::Mail "root";
Unattended-Upgrade::MailReport "only-on-error";
```

Routine successful upgrades do not generate email.

Notification when an automatic reboot is scheduled is not currently implemented.

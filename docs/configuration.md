# Configuration

The bootstrap uses built-in defaults where available and reads machine-specific values from `.env`.

Create it with:

```bash
cp .env.example .env
chmod 600 .env
nano .env
```

The bootstrap refuses to load `.env` unless its permissions are exactly `600`.

## Localisation

```dotenv
SYSTEM_LOCALE=en_US.UTF-8
SYSTEM_TIMEZONE=Europe/Madrid
KEYBOARD_LAYOUT=se
KEYBOARD_MODEL=pc105
```

## SSH

```dotenv
SSH_PORT=1122
```

The port must be an integer from `1` to `65535`.

## Automatic updates

```dotenv
AUTOUPDATES_AUTOMATIC_REBOOT=true
AUTOUPDATES_REBOOT_TIME=04:30
```

`AUTOUPDATES_AUTOMATIC_REBOOT` must be `true` or `false`.

`AUTOUPDATES_REBOOT_TIME` must use `HH:MM` format.

## Outbound mail

```dotenv
MAIL_HOSTNAME=server.example.com
MAIL_SMTP_HOST=smtp.gmail.com
MAIL_SMTP_PORT=587
MAIL_SMTP_USER=smtp-user@example.com
MAIL_SMTP_PASSWORD=
MAIL_TO=recipient@example.com
```

`MAIL_HOSTNAME` identifies the originating server in local mail addresses such as:

```text
root@server.example.com
```

It must be explicitly configured and must not use the `.local` domain.

`MAIL_SMTP_PASSWORD` may contain an SMTP or application-specific password and must never be committed.

## Applying changes

After editing `.env`:

```bash
sudo ./bootstrap.sh
```

Run the bootstrap again to confirm idempotency:

```bash
sudo ./bootstrap.sh
```

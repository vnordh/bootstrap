# Development

## Validation

Run ShellCheck before committing:

```bash
shellcheck -x bootstrap.sh lib/common.sh scripts/*.sh
```

Check for whitespace errors:

```bash
git diff --check
```

Review the complete change:

```bash
git status
git diff
```

## Module rules

A module should:

- use `set -Eeuo pipefail` through the project execution model;
- validate required files, commands and variables;
- avoid unnecessary writes and service reloads;
- log whether configuration changed or was already current;
- validate configuration before activation;
- restore the previous configuration when practical.

## Templates

Templates are stored under `config/`.

Project variables use shell-style placeholders:

```text
${VARIABLE_NAME}
```

When using `envsubst`, pass an explicit variable list so application variables such as Postfix’s `$myhostname` are not expanded accidentally.

Intentional literal variable lists may require:

```bash
# shellcheck disable=SC2016
```

## Secrets

Never commit:

- `.env`;
- SMTP passwords;
- private keys;
- access tokens.

Example files must leave secrets empty.

## Adding a module

1. Choose the appropriate numeric range.
2. Add `scripts/NN-name.sh`.
3. Add required templates under `config/`.
4. Make the script executable:
   ```bash
   chmod 755 scripts/NN-name.sh
   ```
5. Run ShellCheck.
6. Test on Ubuntu Server 24.04.
7. Run the complete bootstrap twice.
8. Confirm that the second run is idempotent.

## Commit workflow

```bash
git diff --check
shellcheck -x bootstrap.sh lib/common.sh scripts/*.sh
gpush "Describe the change"
```

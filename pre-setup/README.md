# Setup

The scripts in this directory prepare a system before running the bootstrap.

These scripts are **not** part of the bootstrap itself and are typically run only once.

Current scripts:

| Script | Purpose |
|--------|---------|
| create-user.sh | Create an administrative user on systems that only provide the root account (for example Proxmox VE). |

# Linux commands used in this project

This page explains the main commands used by `auditor.sh`.

| Command | Purpose |
|---|---|
| `hostname` | Displays the system hostname. |
| `uname -sr` | Displays the kernel name and release. |
| `uname -m` | Displays the machine architecture. |
| `id` | Displays the current user's ID and group information. |
| `uptime -p` | Displays how long the system has been running. |
| `df -hP` | Displays filesystem disk usage in a human-readable format. |
| `free -h` | Displays memory and swap usage in a human-readable format. |
| `who` | Lists users currently logged in. |
| `hostname -I` | Displays IP addresses assigned to the host. |
| `ip -brief address` | Displays a concise summary of network interfaces and addresses. |
| `systemctl is-active` | Checks whether a systemd service is active. |
| `stat` | Displays file or directory metadata, including permissions and ownership. |
| `grep` | Finds matching lines in text output or files. |
| `date` | Displays the date and time and creates a timestamp for the report. |

## Understanding Linux file permissions

Linux permissions are commonly represented by three groups:

- Owner: permissions for the file's owner.
- Group: permissions for users in the file's group.
- Others: permissions for everyone else.

The numeric permission values are:

| Number | Permission |
|---|---|
| `4` | Read |
| `2` | Write |
| `1` | Execute |

For example, `755` means:

- Owner: read, write and execute (`7`).
- Group: read and execute (`5`).
- Others: read and execute (`5`).

The project uses `stat` to read permission values. It does not change them.

## Useful commands to practise

```bash
pwd                 # Show the current directory
ls -la              # List files, including hidden files
cd /etc             # Move to the /etc directory
whoami              # Show the current username
chmod +x auditor.sh # Make the script executable
./auditor.sh        # Run the audit script
```

## Safety note

Do not change permissions on important system files just to make a test pass. This project is intended to inspect the system, not modify it.

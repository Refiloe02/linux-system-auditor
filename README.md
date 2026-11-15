# Linux System Auditor

A Bash-based Linux system auditing tool that collects system information, monitors resource usage, checks selected file permissions, and generates a timestamped text report.

The project is designed as a beginner-friendly practical exercise after completing the **Red Hat Enterprise Linux Technical Overview (RH024)** course.

## Features

- Displays hostname, operating system, kernel version, current user, and uptime.
- Reports disk and memory usage.
- Lists logged-in users.
- Displays network addresses and interfaces when the required tools are available.
- Checks the status of selected services when `systemctl` is available.
- Inspects permissions on important system files and directories.
- Generates a timestamped report in the `reports/` directory.
- Runs without changing system settings or requiring root privileges.

## Requirements

- Bash 4 or newer is recommended.
- A Linux distribution.
- Common Linux utilities: `date`, `hostname`, `uname`, `df`, `who`, `id`, and `stat`.
- Optional utilities: `free`, `ip`, `systemctl`.

The script checks for optional commands and explains when information cannot be collected.

## Project structure

```text
linux-system-auditor/
├── README.md
├── auditor.sh
├── .gitignore
├── reports/
│   └── .gitkeep
├── screenshots/
│   └── .gitkeep
└── docs/
    └── commands.md
```

## Getting started

Clone the repository:

```bash
git clone https://github.com/YOUR-USERNAME/linux-system-auditor.git
cd linux-system-auditor
```

Make the script executable:

```bash
chmod +x auditor.sh
```

Run the audit:

```bash
./auditor.sh
```

The report is saved in `reports/` with a date and time in its filename.

To see available options:

```bash
./auditor.sh --help
```

To choose a different report directory:

```bash
./auditor.sh --output-dir /tmp/linux-audit-reports
```

## Example output

The exact values depend on the machine where the script is run.

```text
========================================
        LINUX SYSTEM AUDIT REPORT
========================================

Generated: 2026-11-13 12:00:00

[ SYSTEM INFORMATION ]
Hostname: example-host
Operating system: Fedora Linux
Kernel: Linux 6.x.x
Current user: learner
Uptime: up 2 hours

[ RESOURCE USAGE ]
Filesystem information:
...

Memory information:
...

[ USER INFORMATION ]
Current user details:
...

Logged-in users:
...

[ SECURITY PERMISSION CHECKS ]
...

========================================
Audit complete.
========================================
```

## Permission checks

The script performs a small set of read-only checks on important files and directories. It flags selected risky permission conditions, such as a world-readable `/etc/shadow` or a world-writable `/etc/passwd`.

These checks are educational indicators, not a complete security assessment. A result marked `REVIEW` should be investigated in the context of the distribution and its configuration.

## Safety

- The script does not modify users, groups, permissions, services, packages, or network settings.
- It does not attempt to exploit or access other systems.
- It does not require `sudo` for its normal operation.
- Some information may be unavailable to an unprivileged user or on a distribution that does not provide an optional command.

## What I learned

This project provides practical experience with:

- Bash scripting and command-line utilities.
- Linux filesystem navigation and permissions.
- Reading system information.
- Basic service and network inspection.
- Generating reports and handling missing commands.
- Using Git to track development.

## Future improvements

- Add command-line options to select individual checks.
- Export reports in CSV or JSON.
- Add configurable thresholds for disk and memory usage.
- Add automated tests for the Bash script.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE).

#!/usr/bin/env bash

# Linux System Auditor
# Collects read-only system information and writes a timestamped report.

set -u
set -o pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="${SCRIPT_DIR}/reports"

usage() {
    cat <<'USAGE'
Linux System Auditor

Usage:
  ./auditor.sh [--output-dir DIRECTORY] [--help]

Options:
  --output-dir DIRECTORY  Save the report in DIRECTORY.
  -h, --help              Show this help message.

The script performs read-only checks and does not require sudo.
USAGE
}

while (($#)); do
    case "$1" in
        --output-dir)
            if [[ $# -lt 2 || -z "${2:-}" ]]; then
                echo "Error: --output-dir requires a directory." >&2
                exit 2
            fi
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Error: Unknown option: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

if ! mkdir -p -- "$OUTPUT_DIR"; then
    echo "Error: Could not create output directory: $OUTPUT_DIR" >&2
    exit 1
fi

if [[ ! -w "$OUTPUT_DIR" ]]; then
    echo "Error: Output directory is not writable: $OUTPUT_DIR" >&2
    exit 1
fi

timestamp="$(date '+%Y%m%d_%H%M%S')"
report_file="${OUTPUT_DIR%/}/linux_audit_${timestamp}.txt"

# Send all report content to both the terminal and the report file.
if ! touch "$report_file"; then
    echo "Error: Could not create report file: $report_file" >&2
    exit 1
fi
exec > >(tee "$report_file") 2>&1

section() {
    printf '\n[%s]\n' "$1"
    printf '%s\n' "----------------------------------------"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

print_command_output() {
    local label="$1"
    shift
    printf '%s:\n' "$label"
    if "$@"; then
        :
    else
        printf '  Information unavailable (command failed).\n'
    fi
}

get_os_name() {
    if [[ -r /etc/os-release ]]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        printf '%s' "${PRETTY_NAME:-Unknown Linux distribution}"
    else
        printf 'Unknown ( /etc/os-release not found )'
    fi
}

check_file_permissions() {
    local path="$1"
    local description="$2"
    local mode owner
    local status="OK"

    if [[ ! -e "$path" ]]; then
        printf 'INFO: %s (%s) does not exist on this system.\n' "$description" "$path"
        return
    fi

    if command_exists stat; then
        mode="$(stat -c '%a' "$path" 2>/dev/null || true)"
        owner="$(stat -c '%U:%G' "$path" 2>/dev/null || true)"
    else
        printf 'INFO: stat command unavailable; cannot inspect %s.\n' "$path"
        return
    fi

    if [[ -z "$mode" ]]; then
        printf 'INFO: Could not read permissions for %s.\n' "$path"
        return
    fi

    # These are deliberately narrow checks for a few obvious permission risks.
    case "$path" in
        /etc/passwd)
            if (( (8#$mode & 0002) != 0 )); then
                status="REVIEW - world-writable"
            fi
            ;;
        /etc/group)
            if (( (8#$mode & 0002) != 0 )); then
                status="REVIEW - world-writable"
            fi
            ;;
        /etc/shadow)
            if (( (8#$mode & 0004) != 0 )); then
                status="REVIEW - world-readable"
            fi
            if (( (8#$mode & 0002) != 0 )); then
                status="REVIEW - world-writable"
            fi
            ;;
        /etc/sudoers)
            if (( (8#$mode & 0002) != 0 )); then
                status="REVIEW - world-writable"
            fi
            ;;
    esac

    printf '%s: %s | mode=%s | owner=%s\n' "$status" "$description" "$mode" "${owner:-unknown}"
}

printf '%s\n' "========================================"
printf '%s\n' "        LINUX SYSTEM AUDIT REPORT"
printf '%s\n' "========================================"
printf 'Generated: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')"
printf 'Report file: %s\n' "$report_file"

section "SYSTEM INFORMATION"
printf 'Hostname: %s\n' "$(hostname 2>/dev/null || printf 'Unavailable')"
printf 'Operating system: %s\n' "$(get_os_name)"
printf 'Kernel: %s\n' "$(uname -sr 2>/dev/null || printf 'Unavailable')"
printf 'Architecture: %s\n' "$(uname -m 2>/dev/null || printf 'Unavailable')"
printf 'Current user: %s\n' "$(id -un 2>/dev/null || printf 'Unavailable')"
printf 'User ID and groups: %s\n' "$(id 2>/dev/null || printf 'Unavailable')"
printf 'Uptime: %s\n' "$(uptime -p 2>/dev/null || uptime 2>/dev/null || printf 'Unavailable')"

section "DISK USAGE"
if command_exists df; then
    df -hP
else
    printf 'df command is not available.\n'
fi

section "MEMORY USAGE"
if command_exists free; then
    free -h
elif [[ -r /proc/meminfo ]]; then
    printf 'Memory details from /proc/meminfo:\n'
    grep -E '^(MemTotal|MemFree|MemAvailable|SwapTotal|SwapFree):' /proc/meminfo || true
else
    printf 'Memory information is unavailable.\n'
fi

section "USER INFORMATION"
printf 'Current user details:\n'
id 2>/dev/null || printf 'Could not read current user details.\n'

printf '\nLogged-in users:\n'
if command_exists who; then
    who || true
else
    printf 'who command is not available.\n'
fi

section "NETWORK INFORMATION"
if command_exists hostname; then
    printf 'IP addresses:\n'
    hostname -I 2>/dev/null || printf 'Could not retrieve IP addresses using hostname.\n'
fi

if command_exists ip; then
    printf '\nNetwork interfaces and addresses:\n'
    ip -brief address 2>/dev/null || ip address 2>/dev/null || true
else
    printf '\nip command is not available; skipping interface details.\n'
fi

section "SERVICE STATUS"
if command_exists systemctl; then
    services=("sshd" "ssh" "NetworkManager")
    for service in "${services[@]}"; do
        if systemctl list-unit-files "${service}.service" --no-legend 2>/dev/null | grep -q "${service}.service"; then
            state="$(systemctl is-active "$service" 2>/dev/null || true)"
            printf '%s: %s\n' "$service" "${state:-unknown}"
        else
            printf '%s: not found (may not be installed or used on this distribution)\n' "$service"
        fi
    done
else
    printf 'systemctl is not available; this system may use a different init system.\n'
fi

section "BASIC FILE PERMISSION CHECKS"
printf 'These checks are limited indicators, not a complete security assessment.\n\n'
check_file_permissions "/etc/passwd" "User account database"
check_file_permissions "/etc/group" "Group database"
check_file_permissions "/etc/shadow" "Shadow password file"
check_file_permissions "/etc/sudoers" "Sudo configuration"

printf '\nDirectory permissions:\n'
for directory in /etc /home /tmp; do
    if [[ -d "$directory" ]] && command_exists stat; then
        stat -c '%n | mode=%a | owner=%U:%G' "$directory" 2>/dev/null \
            || printf 'Could not inspect %s.\n' "$directory"
    else
        printf '%s: not present or stat unavailable.\n' "$directory"
    fi
done

printf '\n========================================\n'
printf 'Audit complete.\n'
printf 'Report saved to: %s\n' "$report_file"
printf '========================================\n'

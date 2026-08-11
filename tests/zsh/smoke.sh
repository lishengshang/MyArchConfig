#!/usr/bin/env bash
# =============================================================================
# smoke.sh - zsh smoke test wrapper.
#
# Feeds smoke.zsh into a REAL interactive zsh through a pty with a deliberate
# 2s idle window, so zinit turbo plugins get loaded by the actual zle event
# loop (they DO NOT load under `zsh -ic` - verified empirically).
#
# Usage: ./smoke.sh [--idle SECONDS]
# Exit 0 if all assertions pass, non-zero otherwise.
# =============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IDLE=2

while [[ $# -gt 0 ]]; do
    case "$1" in
        --idle) IDLE="$2"; shift 2 ;;
        *) echo "smoke.sh: unknown option: $1" >&2; exit 2 ;;
    esac
done

if ! command -v script >/dev/null 2>&1; then
    echo "smoke.sh: 'script' (util-linux) required for pty" >&2
    exit 2
fi

# A. Clean startup check: interactive start must produce zero zsh errors
# (the "can't change option: zle" artifact only appears WITHOUT a tty)
clean_err=$(script -qec 'zsh -ic exit' /dev/null 2>&1 \
    | grep -c -E "zsh:[0-9]+:|can't change option|parse error|command not found" || true)
if (( clean_err == 0 )); then
    echo "SMOKE_PASS startup:clean"
else
    echo "SMOKE_FAIL startup:clean (found $clean_err error lines)"
fi

# B-G. Functional assertions inside real interactive zsh:
#  1. wake the shell (first command), 2. idle so turbo loads, 3. run checks
out=$(
    {
        printf 'sleep 0.3\n'
        sleep "$IDLE"
        printf 'source %s\nexit\n' "$SCRIPT_DIR/smoke.zsh"
    } | script -qec 'zsh -i' /dev/null 2>&1
)

printf '%s\n' "$out" | grep -E '^SMOKE_(PASS|FAIL|SUMMARY|FAILED)' || true

# Exit code from summary
summary=$(printf '%s\n' "$out" | grep -E '^SMOKE_SUMMARY' | tail -1)
if [[ "$summary" == *", 0 failed"* ]]; then
    exit 0
else
    echo "smoke.sh: FAILED -> ${summary:-no summary output}" >&2
    exit 1
fi

#!/usr/bin/env bash
# =============================================================================
# smoke.sh - zsh smoke test wrapper.
#
# Feeds smoke.zsh into a REAL interactive zsh through a pty with a deliberate
# 2s idle window, so zinit turbo plugins get loaded by the actual zle event
# loop (they DO NOT load under `zsh -ic` - verified empirically).
#
# Sections:
#   A  clean startup (no zsh errors in pty)
#   B-G functional assertions (smoke.zsh: tools/comps/abbr/bindings/prompt)
#   H  zsh-abbr expansion regression (typing "path " must expand)
#
# Usage: ./smoke.sh [--idle SECONDS]
# Exit 0 if all assertions pass, non-zero otherwise.
# =============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IDLE=2
FAILURES=0

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

# --- A. clean startup ------------------------------------------------------
clean_err=$(script -qec 'zsh -ic exit' /dev/null 2>&1 \
    | grep -c -E "zsh:[0-9]+:|can't change option|parse error|command not found" || true)
if (( clean_err == 0 )); then
    echo "SMOKE_PASS startup:clean"
else
    echo "SMOKE_FAIL startup:clean (found $clean_err error lines)" >&2
    (( FAILURES++ ))
fi

# --- B-G. functional assertions inside real interactive zsh ----------------
# 1. wake the shell (first command), 2. idle so turbo loads, 3. run checks
out=$(
    {
        printf 'sleep 0.3\n'
        sleep "$IDLE"
        printf 'source %s\nexit\n' "$SCRIPT_DIR/smoke.zsh"
    } | script -qec 'zsh -i' /dev/null 2>&1
)

printf '%s\n' "$out" | grep -E '^SMOKE_(PASS|FAIL|SUMMARY|FAILED)' || true
summary=$(printf '%s\n' "$out" | grep -E '^SMOKE_SUMMARY' | tail -1)
if [[ "$summary" == *", 0 failed"* ]]; then
    echo "gate: smoke PASS"
else
    echo "gate: smoke FAIL -> ${summary:-no summary output}" >&2
    (( FAILURES++ ))
fi

# --- H. zsh-abbr expansion regression --------------------------------------
# Typing "path" char-by-char + space must expand to
# `echo $PATH | tr ":" "\n"` and print the PATH entries (first entry is
# ~/.local/bin from .zshenv). Regression for the bindings.zsh `bindkey -e`
# wipe bug that silently disabled all abbr expansion.
abbr_out=$(
    {
        printf 'sleep 0.3\n'
        sleep "$IDLE"
        printf 'p'; sleep 0.15; printf 'a'; sleep 0.15; printf 't'; sleep 0.15; printf 'h'; sleep 0.15; printf ' '; sleep 0.3; printf '\n'
        sleep 1
        printf 'exit\n'
    } | script -qec 'zsh -i' /dev/null 2>&1
)
if printf '%s\n' "$abbr_out" | grep -q '^/home/mio/'; then
    echo "SMOKE_PASS abbr:expansion"
else
    echo "SMOKE_FAIL abbr:expansion (PATH first entry not printed)" >&2
    (( FAILURES++ ))
fi

if (( FAILURES )); then
    echo "smoke.sh: FAILED ($FAILURES)" >&2
    exit 1
fi
echo "smoke.sh: ALL PASS"

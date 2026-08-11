#!/usr/bin/env bash
# =============================================================================
# run.sh - regression gate: bench + smoke + tolerance check.
#
#   ./run.sh                    # run everything; fail if median > baseline+10%
#   ./run.sh --update-baseline  # re-record baseline.json from current state
#   ./run.sh --tolerance 5      # override tolerance percent (default 10)
#   ./run.sh --skip-smoke       # bench only
#   ./run.sh --skip-bench       # smoke only
#
# Notes:
#   - The 10% default tolerance accounts for measured run-to-run noise
#     (~±9% on this machine: 160-190ms). Timing-POSITIVE waves assert their
#     own reductions explicitly in their commits.
# =============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOLERANCE=10
UPDATE_BASELINE=0
SKIP_SMOKE=0
SKIP_BENCH=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --update-baseline) UPDATE_BASELINE=1; shift ;;
        --tolerance) TOLERANCE="$2"; shift 2 ;;
        --skip-smoke) SKIP_SMOKE=1; shift ;;
        --skip-bench) SKIP_BENCH=1; shift ;;
        *) echo "run.sh: unknown option: $1" >&2; exit 2 ;;
    esac
done

failures=0

# --- bench ----------------------------------------------------------------
if (( ! SKIP_BENCH )); then
    tmp="$SCRIPT_DIR/.run-bench.json"
    "$SCRIPT_DIR/bench.sh" --output "$tmp"
    new_median=$(sed -n 's/.*"median_ms": \([0-9]*\).*/\1/p' "$tmp" | head -1)
    baseline="$SCRIPT_DIR/baseline.json"

    if (( UPDATE_BASELINE )); then
        mv "$tmp" "$baseline"
        echo "gate: baseline updated (median ${new_median}ms)"
    elif [[ -f "$baseline" ]]; then
        base_median=$(sed -n 's/.*"median_ms": \([0-9]*\).*/\1/p' "$baseline" | head -1)
        limit=$(( base_median * (100 + TOLERANCE) / 100 ))
        if (( new_median <= limit )); then
            echo "gate: PASS median ${new_median}ms <= baseline ${base_median}ms +${TOLERANCE}% (limit ${limit}ms)"
        else
            echo "gate: FAIL median ${new_median}ms > baseline ${base_median}ms +${TOLERANCE}% (limit ${limit}ms)" >&2
            failures=$((failures + 1))
        fi
    else
        echo "gate: no baseline.json - recording current state as baseline"
        mv "$tmp" "$baseline"
    fi
fi

# --- smoke ----------------------------------------------------------------
if (( ! SKIP_SMOKE )); then
    if "$SCRIPT_DIR/smoke.sh"; then
        echo "gate: smoke PASS"
    else
        echo "gate: smoke FAIL" >&2
        failures=$((failures + 1))
    fi
fi

if (( failures )); then
    echo "run.sh: FAILED ($failures gate(s))" >&2
    exit 1
fi
echo "run.sh: ALL GATES PASS"

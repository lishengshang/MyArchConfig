#!/usr/bin/env bash
# =============================================================================
# bench.sh - zsh startup benchmark harness
#
# Measures interactive zsh startup latency inside a REAL pty (required: without
# a tty, `zsh -ic exit` emits a spurious "can't change option: zle" artifact
# that corrupts timing).
#
# Usage:
#   ./bench.sh [--runs N] [--warmup N] [--output FILE] [--no-warmup]
#
# Output:
#   JSON file (default: baseline.json next to this script) with median/mean/
#   min/max in ms, plus metadata. Human summary printed to stdout.
#
# Method:
#   - If hyperfine is installed: hyperfine -N --warmup --runs ... --export-json
#   - Else: date +%s%N around `script -qec 'zsh -ic exit' /dev/null`
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUNS=15
WARMUP=3
OUTPUT="$SCRIPT_DIR/baseline.json"
CMD='zsh -ic exit'

usage() {
    sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --runs)   RUNS="$2"; shift 2 ;;
        --warmup) WARMUP="$2"; shift 2 ;;
        --output) OUTPUT="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) echo "bench.sh: unknown option: $1" >&2; usage ;;
    esac
done

command -v script >/dev/null 2>&1 && HAS_SCRIPT=1 || HAS_SCRIPT=0

# ---------------------------------------------------------------------------
# Run one startup, return elapsed milliseconds on stdout
# ---------------------------------------------------------------------------
time_one() {
    local start_ns end_ns
    start_ns=$(date +%s%N)
    if (( HAS_SCRIPT )); then
        script -qec "$CMD" /dev/null >/dev/null 2>&1 || true
    else
        bash -c "$CMD" >/dev/null 2>&1 || true
    fi
    end_ns=$(date +%s%N)
    echo $(( (end_ns - start_ns) / 1000000 ))
}

# ---------------------------------------------------------------------------
# hyperfine path
# ---------------------------------------------------------------------------
if command -v hyperfine >/dev/null 2>&1; then
    hyperfine -N --warmup "$WARMUP" --runs "$RUNS" --export-json "$OUTPUT" \
        "script -qec 'zsh -ic exit' /dev/null" >/dev/null
    if command -v python3 >/dev/null 2>&1; then
        python3 - "$OUTPUT" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
r = d["results"][0]
print(f"median startup: {r['median']*1000:.0f} ms ({r['times'] and len(r['times'])} runs) [hyperfine]")
PY
    else
        echo "median startup: see $OUTPUT (hyperfine, python3 unavailable for summary)"
    fi
    exit 0
fi

# ---------------------------------------------------------------------------
# date-based pty path
# ---------------------------------------------------------------------------
warmup_done=0
[[ $WARMUP -gt 0 ]] && echo "warmup: $WARMUP runs" >&2
for ((i=0; i<WARMUP; i++)); do
    time_one >/dev/null
done
warmup_done=1

times_ms=()
for ((i=0; i<RUNS; i++)); do
    t=$(time_one)
    times_ms+=("$t")
done

# median / mean / min / max (awk)
# NOTE: read from process substitution returns 1 on bash 5.3 (data is still
# populated) which trips `set -e` - so we go through a temp file instead.
_stats_tmp=$(mktemp)
printf '%s\n' "${times_ms[@]}" | sort -n | awk -v n="${#times_ms[@]}" '
    { a[NR]=$1; sum+=$1 }
    END {
        m = (n % 2) ? a[(n+1)/2] : (a[n/2]+a[n/2+1])/2;
        printf "%d %d %d %d\n", m, sum/n, a[1], a[n]
    }' > "$_stats_tmp"
read -r median mean min max < "$_stats_tmp"
rm -f "$_stats_tmp"

# metadata
zsh_ver=$(zsh --version 2>/dev/null | awk '{print $2}')
git_sha=$(git -C "$SCRIPT_DIR/../.." rev-parse --short HEAD 2>/dev/null || echo "unknown")
date_iso=$(date -Iseconds)
method="pty-script"
(( HAS_SCRIPT )) || method="no-tty"

cat > "$OUTPUT" <<EOF
{
  "median_ms": $median,
  "mean_ms": $mean,
  "min_ms": $min,
  "max_ms": $max,
  "runs": $RUNS,
  "warmup": $WARMUP,
  "date_iso": "$date_iso",
  "zsh_version": "$zsh_ver",
  "git_sha": "$git_sha",
  "method": "$method"
}
EOF

echo "median startup: $median ms ($RUNS runs) [method=$method]"

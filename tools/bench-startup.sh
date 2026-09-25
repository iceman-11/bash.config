#!/usr/bin/env bash
################################################################################
#
# Measure how long an interactive bash takes to start with this configuration.
#
# Usage:
#   tools/bench-startup.sh [-n RUNS]      median of RUNS start-ups (default 5)
#   tools/bench-startup.sh --profile      time spent per file and slowest lines
#
# Uses your real HOME and configuration, like opening a new terminal. Run it
# from a real terminal to include what only happens when a tty is attached.
# Development tool: needs bash 5 (EPOCHREALTIME).
#
################################################################################

set -euo pipefail

runs=5
profile=0

while (( $# )); do
	case $1 in
		-n) runs=$2; shift 2 ;;
		--profile) profile=1; shift ;;
		-h | --help) sed -n '4,13s/^# \{0,1\}//p' "$0"; exit 0 ;;
		*) echo "unknown option: $1" >&2; exit 2 ;;
	esac
done

# Wall-clock milliseconds of one run of "bash ARGS"
__time_ms() {
	local start=$EPOCHREALTIME
	bash "$@" > /dev/null 2>&1 || true
	local end=$EPOCHREALTIME
	echo $(( (${end/[.,]/} - ${start/[.,]/}) / 1000 ))
}

__median() {
	sort -n | awk '{ a[NR] = $1 } END { print (NR % 2) ? a[(NR + 1) / 2] : int((a[NR / 2] + a[NR / 2 + 1]) / 2) }'
}

tty -s && tty_state="with a tty" || tty_state="without a tty"
echo "bash $BASH_VERSION, $(uname -s), $tty_state"

if (( profile )); then
	trace=$(mktemp)
	trap 'rm -f "$trace"' EXIT

	PS4='+ ${EPOCHREALTIME} ${BASH_SOURCE[0]##*/}:${LINENO} ' \
		bash -ixc exit 2> "$trace" > /dev/null || true

	# Each trace line's time is charged to the line traced just before it
	awk '
		$1 ~ /^\++$/ && $2 ~ /^[0-9]+[.,][0-9]+$/ {
			sub(",", ".", $2); t = $2
			if (p) { d = t - p; file[pf] += d; if (d > line_d[pl]) line_d[pl] = d; total += d }
			p = t; split($3, a, ":"); pf = a[1]; pl = $3
		}
		END {
			printf "\nTime per file (total %.2f s):\n", total
			for (f in file) printf "%8.0f ms  %s\n", file[f] * 1000, f | "sort -rn"
			close("sort -rn")
			printf "\nSlowest lines:\n"
			for (l in line_d) if (line_d[l] >= 0.05) printf "%8.0f ms  %s\n", line_d[l] * 1000, l | "sort -rn | head -15"
		}' "$trace"
	exit 0
fi

with=$(for (( i = 0; i < runs; i++ )); do __time_ms -ic exit; done | __median)
without=$(for (( i = 0; i < runs; i++ )); do __time_ms --norc -ic exit; done | __median)

printf 'median of %d runs: %d ms with the configuration, %d ms without\n' "$runs" "$with" "$without"

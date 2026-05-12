#!/usr/bin/env bash
# A1.9 — Balance simulation runner.
#
# Usage:
#   tower/run_balance_sim.sh [godot-bin]
#
# Sweeps both starter characters across A0–A2, 200 runs each, and writes a
# per-(character × ascension) CSV under tower_game/sim_out/. Then summarizes
# winrates with the Python aggregator.
#
# Pass an explicit godot binary as the first arg if `godot` isn't on PATH:
#   tower/run_balance_sim.sh /Applications/Godot.app/Contents/MacOS/Godot

set -euo pipefail

GODOT="${1:-godot}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GAME="$ROOT/tower_game"
OUT="$GAME/sim_out"
mkdir -p "$OUT"

CHARACTERS=("char_vanguard" "char_archivist")
ASCENSIONS=(0 1 2)
RUNS_PER_CELL=200

for c in "${CHARACTERS[@]}"; do
	for a in "${ASCENSIONS[@]}"; do
		csv="$OUT/${c}_a${a}.csv"
		echo "[balance] $c × A$a → $csv"
		"$GODOT" --headless --path "$GAME" --script res://scripts/tools/headless_runs.gd -- \
			--char="$c" --asc="$a" --runs="$RUNS_PER_CELL" --out="$csv"
	done
done

echo
echo "[balance] aggregating..."
python3 "$ROOT/tower/aggregate_balance.py" "$OUT"

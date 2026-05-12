#!/usr/bin/env python3
"""A1.9 — winrate aggregator for balance sim CSVs.

Reads every *.csv in the directory passed on the command line and prints a
per-(character × ascension) summary table. Designed for fast eyeballing in
under 60 seconds.

Usage:
    python3 tower/aggregate_balance.py tower_game/sim_out
"""
import csv
import statistics
import sys
from collections import defaultdict
from pathlib import Path


def load_rows(folder: Path):
    rows = []
    for csv_path in sorted(folder.glob("*.csv")):
        with csv_path.open() as f:
            reader = csv.DictReader(f)
            for r in reader:
                rows.append(r)
    return rows


def summarize(rows):
    buckets = defaultdict(list)
    for r in rows:
        key = (r["character"], int(r["ascension"]))
        buckets[key].append(r)
    print(f"{'Character':<16} {'A':>2}  {'Runs':>5}  {'Win%':>6}  {'Avg HP':>7}  {'Avg Floors':>11}  {'Avg Turns':>10}  {'Biggest hit':>11}")
    print("-" * 90)
    for (char, asc), entries in sorted(buckets.items()):
        wins = sum(1 for e in entries if e["outcome"] == "victory")
        runs = len(entries)
        winrate = 100.0 * wins / max(1, runs)
        avg_hp = statistics.mean(int(e["final_hp"]) for e in entries) if entries else 0
        avg_floors = statistics.mean(int(e["floors_cleared"]) for e in entries) if entries else 0
        avg_turns = statistics.mean(int(e["turns_total"]) for e in entries) if entries else 0
        biggest = max(int(e["biggest_hit"]) for e in entries) if entries else 0
        print(f"{char:<16} {asc:>2}  {runs:>5}  {winrate:>5.1f}%  {avg_hp:>7.1f}  {avg_floors:>11.1f}  {avg_turns:>10.1f}  {biggest:>11}")


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    folder = Path(sys.argv[1])
    if not folder.is_dir():
        print(f"Not a directory: {folder}")
        sys.exit(2)
    rows = load_rows(folder)
    if not rows:
        print(f"No CSV rows found in {folder}")
        sys.exit(3)
    summarize(rows)


if __name__ == "__main__":
    main()

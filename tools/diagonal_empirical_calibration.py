#!/usr/bin/env python3
"""Empirical audit of BizHawk diagonal_action_matrix.csv captures.

The probe measures ball motion, NOT a confirmed completed pass. This analysis
never edits the Lua policy or infers ownership from team-possession alone.
"""
import argparse
import csv
import math
from collections import defaultdict
from pathlib import Path

DIRECTIONS = {
    ("Right", "Up"): (1, -1),
    ("Right", "Down"): (1, 1),
    ("Left", "Up"): (-1, -1),
    ("Left", "Down"): (-1, 1),
}
REQUIRED = {
    "horizontal", "vertical", "button", "base_owner", "action_dx",
    "action_dy", "end_dx", "end_dy", "first_owner_change_frame",
    "max_displacement",
}


def number(raw):
    try:
        value = float(raw)
        return value if math.isfinite(value) else None
    except (TypeError, ValueError):
        return None


def analyze(paths, min_sessions, min_motion, min_alignment):
    groups = defaultdict(list)
    rejected = []
    seen = set()
    for path in paths:
        with path.open(newline="", encoding="utf-8-sig") as stream:
            reader = csv.DictReader(stream)
            if not reader.fieldnames or not REQUIRED.issubset(reader.fieldnames):
                rejected.append((str(path), "missing_columns"))
                continue
            file_rows = list(reader)
        # One independent starting situation per file; do not count the
        # sixteen commands within one savestate as sixteen replications.
        for row in file_rows:
            key = (row["horizontal"], row["vertical"])
            button = row["button"]
            if key not in DIRECTIONS or button not in ("A", "B", "X", "Y"):
                continue
            identity = (str(path.resolve()), key, button)
            if identity in seen:
                continue
            seen.add(identity)
            dx, dy = number(row["end_dx"]), number(row["end_dy"])
            start_owner = number(row["base_owner"])
            max_distance = number(row["max_displacement"])
            if None in (dx, dy, start_owner, max_distance):
                rejected.append((str(path), "invalid_numeric_row"))
                continue
            motion = math.hypot(dx, dy)
            ux, uy = DIRECTIONS[key]
            cosine = (dx * ux + dy * uy) / (motion * math.sqrt(2)) if motion >= min_motion else None
            groups[(key[0], key[1], button)].append({
                "file": str(path),
                "motion": motion,
                "cosine": cosine,
                "changed_owner": row["first_owner_change_frame"].strip() != "",
                "max_distance": max_distance,
            })
    results = []
    for horizontal in ("Right", "Left"):
        for vertical in ("Up", "Down"):
            for button in ("A", "B", "X", "Y"):
                rows = groups[(horizontal, vertical, button)]
                moved = [r for r in rows if r["cosine"] is not None]
                aligned = sum(r["cosine"] >= min_alignment for r in moved)
                wrong = sum(r["cosine"] < min_alignment for r in moved)
                observations = len(rows)
                # Require independent captures, reliable motion, and no
                # contradictory observed direction before calling it stable.
                if observations < min_sessions:
                    verdict = "INSUFFICIENT_INDEPENDENT_CAPTURES"
                elif len(moved) < min_sessions:
                    verdict = "INCONCLUSIVE_LOW_MOTION"
                elif wrong:
                    verdict = "INCONSISTENT_DIRECTION"
                else:
                    verdict = "DIRECTION_REPRODUCED_NOT_PASS_CONFIRMED"
                results.append({
                    "horizontal": horizontal, "vertical": vertical,
                    "button": button, "captures": observations,
                    "motion_captures": len(moved),
                    "aligned_captures": aligned,
                    "misaligned_captures": wrong,
                    "mean_end_displacement": f"{sum(r['motion'] for r in rows) / observations:.3f}" if observations else "",
                    "mean_alignment_cosine": f"{sum(r['cosine'] for r in moved) / len(moved):.3f}" if moved else "",
                    "owner_signal_changed": sum(r["changed_owner"] for r in rows),
                    "verdict": verdict,
                    "pass_confirmed": "NO",
                })
    return results, rejected


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("captures", nargs="+", type=Path, help="CSV files from independent match snapshots")
    parser.add_argument("--output", type=Path, default=Path("diagonal_empirical_calibration.csv"))
    parser.add_argument("--min-sessions", type=int, default=5)
    parser.add_argument("--min-motion", type=float, default=8.0)
    parser.add_argument("--min-alignment", type=float, default=0.80)
    args = parser.parse_args()
    if args.min_sessions < 2 or args.min_motion <= 0 or not -1 <= args.min_alignment <= 1:
        parser.error("invalid calibration thresholds")
    results, rejected = analyze(args.captures, args.min_sessions, args.min_motion, args.min_alignment)
    with args.output.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(stream, fieldnames=list(results[0]))
        writer.writeheader()
        writer.writerows(results)
    for row in results:
        if row["button"] == "B":
            print(f"{row['horizontal']}+{row['vertical']}+B: {row['verdict']} "
                  f"({row['aligned_captures']}/{row['captures']} aligned)")
    for path, reason in rejected:
        print(f"WARNING {path}: {reason}")
    print(f"Calibration report: {args.output}")


if __name__ == "__main__":
    main()

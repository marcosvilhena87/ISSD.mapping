#!/usr/bin/env python3
"""Analyze matched BizHawk diagonal-risk A/B/C recordings; no policy changes."""
import argparse
import csv
from collections import defaultdict
from pathlib import Path

ACTIONS = ("UP_B", "DOWN_B", "RIGHT_A")
REQUIRED = {"action", "frame", "owner", "game_state", "target",
            "target_distance", "nearest_cpu_ball", "nearest_cpu_target",
            "ball_displacement", "signal", "held_frames"}


def numeric(value):
    try:
        return float(value)
    except (TypeError, ValueError):
        return None


def summarize(rows, action, source):
    ordered = sorted(rows, key=lambda r: int(r["frame"]))
    if not ordered:
        raise ValueError(f"{source}: no frames for {action}")
    frames = [int(r["frame"]) for r in ordered]
    if frames[0] != 0 or len(frames) != len(set(frames)):
        raise ValueError(f"{source}: invalid or duplicate frames for {action}")
    target = 0x0B00 if action == "UP_B" else 0x0C00 if action == "DOWN_B" else None
    expected = target or 0
    for row in ordered:
        observed_target = numeric(row["target"])
        if (target is None and row["target"].strip()) or (
            target is not None and observed_target != expected
        ):
            raise ValueError(f"{source}: unexpected target in {action}")
    first_target = next((int(r["frame"]) for r in ordered
                         if target is not None and numeric(r["owner"]) == target), None)
    first_cpu = next((int(r["frame"]) for r in ordered
                      if numeric(r["owner"]) is not None
                      and 0x1000 <= numeric(r["owner"]) <= 0x1A00), None)
    # Only signals occurring after the initial frame count as a new receipt.
    first_target = first_target if first_target and first_target > 0 else None
    first_cpu = first_cpu if first_cpu and first_cpu > 0 else None
    if first_target is not None and (first_cpu is None or first_target < first_cpu):
        outcome = "TARGET_OWNER_FIRST"
    elif first_cpu is not None and (first_target is None or first_cpu < first_target):
        outcome = "CPU_OWNER_FIRST"
    elif first_cpu is not None and first_cpu == first_target:
        outcome = "AMBIGUOUS_SIMULTANEOUS"
    else:
        outcome = "UNRESOLVED"
    def minimum(column):
        values = [numeric(r[column]) for r in ordered if numeric(r[column]) is not None]
        return round(min(values), 3) if values else ""
    final = ordered[-1]
    return {
        "capture": Path(source).name, "action": action,
        "frames_observed": len(ordered), "held_frames": final["held_frames"],
        "first_target_owner_frame": first_target if first_target is not None else "",
        "first_cpu_owner_frame": first_cpu if first_cpu is not None else "",
        "min_ball_target_distance": minimum("target_distance"),
        "min_cpu_ball_distance": minimum("nearest_cpu_ball"),
        "min_cpu_target_distance": minimum("nearest_cpu_target"),
        "max_ball_displacement": round(max(float(r["ball_displacement"]) for r in ordered), 3),
        "final_owner": final["owner"], "outcome_signal": outcome,
        "confirmed_physical_reception": "NO",
    }


def analyze(paths):
    output = []
    for path in paths:
        with path.open(newline="", encoding="utf-8-sig") as stream:
            reader = csv.DictReader(stream)
            if not reader.fieldnames or not REQUIRED.issubset(reader.fieldnames):
                raise ValueError(f"{path}: missing columns")
            groups = defaultdict(list)
            for row in reader:
                if row["action"] not in ACTIONS:
                    raise ValueError(f"{path}: unknown action {row['action']}")
                groups[row["action"]].append(row)
        if set(groups) != set(ACTIONS):
            raise ValueError(f"{path}: incomplete matched trial (expected 3 actions)")
        for action in ACTIONS:
            output.append(summarize(groups[action], action, str(path)))
    return output


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("captures", nargs="+", type=Path)
    parser.add_argument("--output", type=Path, default=Path("diagonal_risk_outcomes.csv"))
    args = parser.parse_args()
    rows = analyze(args.captures)
    with args.output.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)
    for row in rows:
        print(f"{row['capture']} {row['action']}: {row['outcome_signal']} "
              f"(target={row['first_target_owner_frame']}, cpu={row['first_cpu_owner_frame']})")
    print("Owner signals are not confirmation of physical reception.")


if __name__ == "__main__":
    main()

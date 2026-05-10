#!/usr/bin/env python3
"""Analyze KX134 dual ESP-NOW sync precheck logs."""

from __future__ import annotations

import argparse
import csv
import json
import math
from collections import Counter, defaultdict
from datetime import datetime
from pathlib import Path
from statistics import mean, median, pstdev


EXPECTED_HEADER = [
    "protocol_version",
    "session_id",
    "sensor_id",
    "physical_label",
    "node_id",
    "node_mac",
    "seq",
    "sensor_t_us",
    "receiver_t_us",
    "pc_wall_s",
    "sync_group_id",
    "pair_seq",
    "x_raw",
    "y_raw",
    "z_raw",
    "x_g",
    "y_g",
    "z_g",
    "sample_rate_hz",
    "odr_hz",
    "range_g",
    "calibration_id",
    "calibration_applied",
    "packet_status",
    "packet_error_code",
    "firmware_version",
    "contract_version",
]

EXPECTED_MAC = {
    1: "D4:E9:F4:E9:8E:1C",
    2: "D4:E9:F4:C3:37:14",
}

FORBIDDEN_FIELD_TOKENS = (
    "mv_x",
    "mv_y",
    "mv_z",
    "gx_est",
    "gy_est",
    "gz_est",
    "g_norm_est",
    "voltage",
    "millivolts",
)


def percentile(values: list[float], pct: float) -> float | None:
    if not values:
        return None
    ordered = sorted(values)
    index = (len(ordered) - 1) * pct
    lower = math.floor(index)
    upper = math.ceil(index)
    if lower == upper:
        return ordered[int(index)]
    return ordered[lower] + (ordered[upper] - ordered[lower]) * (index - lower)


def stats(values: list[float]) -> dict[str, float | int | None]:
    if not values:
        return {"count": 0, "mean": None, "median": None, "min": None, "max": None, "p95": None, "std": None}
    return {
        "count": len(values),
        "mean": mean(values),
        "median": median(values),
        "min": min(values),
        "max": max(values),
        "p95": percentile(values, 0.95),
        "std": pstdev(values) if len(values) > 1 else 0.0,
    }


def read_rows(path: Path) -> tuple[list[dict[str, str]], dict[str, object]]:
    rows: list[dict[str, str]] = []
    diagnostics: list[str] = []
    header: list[str] | None = None
    header_detected = False
    header_fallback_used = False
    invalid_field_count = 0
    pre_header_rows_discarded = 0

    for raw_line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        line = raw_line.strip()
        if not line:
            continue
        if line.startswith("#"):
            diagnostics.append(line)
            continue
        try:
            fields = next(csv.reader([line]))
        except csv.Error:
            invalid_field_count += 1
            continue
        normalized_first = fields[0].lstrip("\ufeff") if fields else ""
        if fields == EXPECTED_HEADER:
            if header_fallback_used and rows:
                pre_header_rows_discarded += len(rows)
                rows = []
                header_fallback_used = False
            header = fields
            header_detected = True
            continue
        if header is None:
            if len(fields) == len(EXPECTED_HEADER) and normalized_first == "kx134.v3":
                header = EXPECTED_HEADER
                header_fallback_used = True
            else:
                invalid_field_count += 1
                continue
        if len(fields) != len(header):
            invalid_field_count += 1
            continue
        if normalized_first != "kx134.v3":
            invalid_field_count += 1
            continue
        fields[0] = normalized_first
        rows.append(dict(zip(header, fields)))

    forbidden_fields = [
        field
        for field in (header or [])
        if any(token in field.lower() for token in FORBIDDEN_FIELD_TOKENS)
    ]
    metadata = {
        "log_path": str(path),
        "header_detected": header_detected,
        "header_fallback_used": header_fallback_used,
        "invalid_field_count": invalid_field_count,
        "pre_header_rows_discarded": pre_header_rows_discarded,
        "columns": header or [],
        "contract_columns_match": header == EXPECTED_HEADER or (header_fallback_used and header == EXPECTED_HEADER),
        "forbidden_fields_detected_in_header": forbidden_fields,
        "diagnostic_lines_sample": diagnostics[:40],
        "diagnostic_lines_tail": diagnostics[-40:],
        "diagnostic_line_count": len(diagnostics),
    }
    return rows, metadata


def int_field(row: dict[str, str], key: str) -> int:
    return int(row[key])


def float_field(row: dict[str, str], key: str) -> float:
    return float(row[key])


def g_norm(row: dict[str, str]) -> float:
    x = float_field(row, "x_g")
    y = float_field(row, "y_g")
    z = float_field(row, "z_g")
    return math.sqrt(x * x + y * y + z * z)


def frequency_hz(times_us: list[int]) -> float | None:
    if len(times_us) < 2:
        return None
    duration_s = (times_us[-1] - times_us[0]) / 1_000_000.0
    if duration_s <= 0:
        return None
    return (len(times_us) - 1) / duration_s


def duplicate_diagnostics(rows: list[dict[str, str]]) -> dict[str, object]:
    exact = Counter(",".join(row.get(column, "") for column in EXPECTED_HEADER) for row in rows)
    by_sensor_seq: dict[tuple[str, str], list[dict[str, str]]] = defaultdict(list)
    by_sensor_seq_sensor_t: dict[tuple[str, str, str], list[dict[str, str]]] = defaultdict(list)
    by_sensor_seq_receiver_t: dict[tuple[str, str, str], list[dict[str, str]]] = defaultdict(list)
    for row in rows:
        by_sensor_seq[(row["sensor_id"], row["seq"])].append(row)
        by_sensor_seq_sensor_t[(row["sensor_id"], row["seq"], row["sensor_t_us"])].append(row)
        by_sensor_seq_receiver_t[(row["sensor_id"], row["seq"], row["receiver_t_us"])].append(row)

    repeated_sensor_seq = {key: value for key, value in by_sensor_seq.items() if len(value) > 1}
    repeated_sensor_seq_sensor_t = {key: value for key, value in by_sensor_seq_sensor_t.items() if len(value) > 1}
    repeated_sensor_seq_receiver_t = {key: value for key, value in by_sensor_seq_receiver_t.items() if len(value) > 1}

    examples = []
    receiver_same = 0
    receiver_different = 0
    pair_same = 0
    pair_different = 0
    for (sensor_id, seq), group in repeated_sensor_seq.items():
        receiver_values = {row["receiver_t_us"] for row in group}
        pair_values = {row["pair_seq"] for row in group}
        if len(receiver_values) == 1:
            receiver_same += 1
        else:
            receiver_different += 1
        if len(pair_values) == 1:
            pair_same += 1
        else:
            pair_different += 1
        if len(examples) < 10:
            examples.append({
                "sensor_id": sensor_id,
                "seq": seq,
                "count": len(group),
                "receiver_t_us_values": sorted(receiver_values, key=int),
                "pair_seq_values": sorted(pair_values, key=int),
                "line_values_identical_except_receiver_or_pair": len({(row["sensor_t_us"], row["x_raw"], row["y_raw"], row["z_raw"], row["x_g"], row["y_g"], row["z_g"]) for row in group}) == 1,
            })

    exact_duplicate_rows = sum(count - 1 for count in exact.values() if count > 1)
    duplicate_seq_count_by_sensor = Counter(key[0] for key in repeated_sensor_seq)
    exact_duplicate_by_sensor = Counter()
    for line, count in exact.items():
        if count <= 1:
            continue
        try:
            sensor_id = next(csv.reader([line]))[2]
        except Exception:
            sensor_id = "unknown"
        exact_duplicate_by_sensor[sensor_id] += count - 1

    if not repeated_sensor_seq and exact_duplicate_rows == 0:
        classification = "DUPLICATES_NOT_OBSERVED"
    elif exact_duplicate_rows > 0 and receiver_different == 0 and pair_different == 0:
        classification = "DUPLICATES_CAPTURE_ARTIFACT_LIKELY"
    elif receiver_different > 0 or pair_different > 0:
        classification = "DUPLICATES_RECEIVER_STREAM_LIKELY"
    else:
        classification = "DUPLICATES_UNRESOLVED"

    return {
        "classification": classification,
        "exact_duplicate_rows": exact_duplicate_rows,
        "exact_duplicate_rows_by_sensor": dict(exact_duplicate_by_sensor),
        "duplicate_sensor_seq_keys": len(repeated_sensor_seq),
        "duplicate_seq_count_by_sensor": dict(duplicate_seq_count_by_sensor),
        "duplicate_sensor_seq_sensor_t_keys": len(repeated_sensor_seq_sensor_t),
        "duplicate_sensor_seq_receiver_t_keys": len(repeated_sensor_seq_receiver_t),
        "duplicate_groups_same_receiver_t_us": receiver_same,
        "duplicate_groups_different_receiver_t_us": receiver_different,
        "duplicate_groups_same_pair_seq": pair_same,
        "duplicate_groups_different_pair_seq": pair_different,
        "examples": examples,
    }


def rows_for_metrics(rows: list[dict[str, str]], dedup_mode: str) -> list[dict[str, str]]:
    if dedup_mode != "remove_for_metrics":
        return rows
    filtered: list[dict[str, str]] = []
    seen: set[tuple[str, str]] = set()
    for row in rows:
        key = (row["sensor_id"], row["seq"])
        if key in seen:
            continue
        seen.add(key)
        filtered.append(row)
    return filtered


def summarize_sensor(sensor_id: int, raw_rows: list[dict[str, str]], metric_rows: list[dict[str, str]], expected_rate: float) -> dict[str, object]:
    seq_values = [int_field(row, "seq") for row in metric_rows]
    sensor_times = [int_field(row, "sensor_t_us") for row in metric_rows]
    receiver_times = [int_field(row, "receiver_t_us") for row in metric_rows]
    norms = [g_norm(row) for row in metric_rows]
    seq_gaps = 0
    duplicate_seq_count = 0
    for prev, curr in zip(seq_values, seq_values[1:]):
        if curr == prev + 1:
            continue
        if curr <= prev:
            duplicate_seq_count += 1
        else:
            seq_gaps += curr - prev - 1

    packet_status_counts = Counter(row.get("packet_status", "") for row in raw_rows)
    packet_error_counts = Counter(row.get("packet_error_code", "") for row in raw_rows)
    node_mac_counts = Counter(row.get("node_mac", "") for row in raw_rows)

    effective_hz = frequency_hz(sensor_times)
    receiver_hz = frequency_hz(receiver_times)
    hz_ok = effective_hz is not None and expected_rate - 2 <= effective_hz <= expected_rate + 2

    return {
        "sensor_id": sensor_id,
        "rows": len(raw_rows),
        "metric_rows": len(metric_rows),
        "seq_initial": seq_values[0] if seq_values else None,
        "seq_final": seq_values[-1] if seq_values else None,
        "seq_gaps": seq_gaps,
        "duplicate_seq_count_in_metric_rows": duplicate_seq_count,
        "timestamp_errors": sum(1 for prev, curr in zip(sensor_times, sensor_times[1:]) if curr <= prev),
        "receiver_timestamp_errors": sum(1 for prev, curr in zip(receiver_times, receiver_times[1:]) if curr <= prev),
        "effective_hz": effective_hz,
        "receiver_hz": receiver_hz,
        "g_norm_mean": mean(norms) if norms else None,
        "g_norm_min": min(norms) if norms else None,
        "g_norm_max": max(norms) if norms else None,
        "g_norm_std": pstdev(norms) if len(norms) > 1 else 0.0,
        "node_mac_counts": dict(node_mac_counts),
        "packet_status_counts": dict(packet_status_counts),
        "packet_error_code_counts": dict(packet_error_counts),
        "checks": {
            "min_rows_1000": len(metric_rows) >= 1000,
            "mac_valid": set(node_mac_counts) == {EXPECTED_MAC[sensor_id]},
            "effective_hz_ok": hz_ok,
            "seq_gaps_zero": seq_gaps == 0,
            "sensor_t_us_increasing": sum(1 for prev, curr in zip(sensor_times, sensor_times[1:]) if curr <= prev) == 0,
            "receiver_t_us_increasing": sum(1 for prev, curr in zip(receiver_times, receiver_times[1:]) if curr <= prev) == 0,
            "receiver_t_us_nonzero": all(value != 0 for value in receiver_times),
            "packet_status_ok": set(packet_status_counts) == {"OK"},
            "packet_error_code_ok": set(packet_error_counts) == {"OK"},
        },
    }


def pairing_summary(rows_by_sensor: dict[int, list[dict[str, str]]], max_pair_window_ms: float) -> dict[str, object]:
    s1 = sorted(rows_by_sensor.get(1, []), key=lambda row: int_field(row, "receiver_t_us"))
    s2 = sorted(rows_by_sensor.get(2, []), key=lambda row: int_field(row, "receiver_t_us"))
    used_s2: set[int] = set()
    deltas_receiver: list[float] = []
    deltas_sensor_t: list[float] = []
    max_us = max_pair_window_ms * 1000.0
    j = 0

    for row1 in s1:
        t1 = int_field(row1, "receiver_t_us")
        while j + 1 < len(s2) and int_field(s2[j + 1], "receiver_t_us") <= t1:
            j += 1
        candidates = []
        for idx in (j - 1, j, j + 1):
            if 0 <= idx < len(s2) and idx not in used_s2:
                candidates.append(idx)
        if not candidates:
            continue
        best = min(candidates, key=lambda idx: abs(int_field(s2[idx], "receiver_t_us") - t1))
        delta = int_field(s2[best], "receiver_t_us") - t1
        if abs(delta) <= max_us:
            used_s2.add(best)
            deltas_receiver.append(float(delta))
            deltas_sensor_t.append(float(int_field(s2[best], "sensor_t_us") - int_field(row1, "sensor_t_us")))

    return {
        "pair_window_ms": max_pair_window_ms,
        "pair_count": len(deltas_receiver),
        "unpaired_sensor_1": max(0, len(s1) - len(deltas_receiver)),
        "unpaired_sensor_2": max(0, len(s2) - len(used_s2)),
        "delta_receiver_us": stats(deltas_receiver),
        "delta_receiver_ms_abs_p95": (percentile([abs(value) for value in deltas_receiver], 0.95) or 0.0) / 1000.0 if deltas_receiver else None,
        "delta_sensor_t_us": stats(deltas_sensor_t),
        "sensor_t_note": "sensor_t_us comes from independent ESP32 clocks and is not a direct sync reference.",
    }


def detect_events(rows_by_sensor: dict[int, list[dict[str, str]]]) -> dict[str, object]:
    summaries: dict[str, object] = {}
    first_times: dict[int, int] = {}
    arm_after_us = 4_000_000
    for sensor_id in (1, 2):
        rows = sorted(rows_by_sensor.get(sensor_id, []), key=lambda row: int_field(row, "receiver_t_us"))
        if len(rows) < 20:
            summaries[str(sensor_id)] = {"event_count": 0, "first_event_time_receiver_us": None, "status": "NO_EVENT_DETECTED"}
            continue
        norms = [g_norm(row) for row in rows]
        receiver_t0 = int_field(rows[0], "receiver_t_us")
        baseline = [
            value
            for row, value in zip(rows, norms)
            if int_field(row, "receiver_t_us") - receiver_t0 < arm_after_us
        ]
        if len(baseline) < 10:
            baseline = norms[:max(10, min(len(norms) // 5, 300))]
        baseline_median = median(baseline)
        baseline_mean = mean(baseline)
        baseline_mad = median([abs(value - baseline_median) for value in baseline])
        baseline_std = pstdev(baseline) if len(baseline) > 1 else 0.0
        threshold = max(0.06, baseline_mad * 1.4826 * 8.0)
        candidate_indices = [
            idx
            for idx, value in enumerate(norms)
            if int_field(rows[idx], "receiver_t_us") - receiver_t0 >= arm_after_us
            and abs(value - baseline_median) >= threshold
        ]
        events: list[int] = []
        last_event_time = -10_000_000
        for idx in candidate_indices:
            t = int_field(rows[idx], "receiver_t_us")
            if t - last_event_time >= 500_000:
                events.append(t)
                last_event_time = t
        first_time = events[0] if events else None
        if first_time is not None:
            first_times[sensor_id] = first_time
        summaries[str(sensor_id)] = {
            "event_count": len(events),
            "first_event_time_receiver_us": first_time,
            "event_times_receiver_us": events[:10],
            "baseline_g_norm_median": baseline_median,
            "baseline_g_norm_mean": baseline_mean,
            "baseline_g_norm_std": baseline_std,
            "baseline_g_norm_mad": baseline_mad,
            "threshold_delta_g": threshold,
            "event_arm_after_s": arm_after_us / 1_000_000.0,
            "status": "OK" if events else "NO_EVENT_DETECTED",
        }

    if 1 in first_times and 2 in first_times:
        delta = first_times[2] - first_times[1]
        status = "OK" if abs(delta) <= 30_000 else "EVENT_DELTA_TOO_LARGE"
    else:
        delta = None
        status = "NO_EVENT_DETECTED"

    return {
        "mode": "event",
        "sensors": summaries,
        "delta_event_receiver_us": delta,
        "delta_event_ms": (delta / 1000.0) if delta is not None else None,
        "status": status,
    }


def parse_receiver_stat(diagnostics: list[str]) -> dict[str, int | None]:
    last = None
    for line in diagnostics:
        if line.startswith("#STAT,role=receiver"):
            last = line
    result: dict[str, int | None] = {"invalid": None, "duplicate_drops": None, "queue_drops": None}
    if not last:
        return result
    for part in last.split(","):
        if "=" not in part:
            continue
        key, value = part.split("=", 1)
        if key in result:
            try:
                result[key] = int(value)
            except ValueError:
                result[key] = None
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("log_path")
    parser.add_argument("--output", required=True)
    parser.add_argument("--event-mode", choices=["static", "event"], required=True)
    parser.add_argument("--expected-rate", type=float, default=100.0)
    parser.add_argument("--max-pair-window-ms", type=float, default=20.0)
    parser.add_argument("--dedup-mode", choices=["none", "report_only", "remove_for_metrics"], default="report_only")
    args = parser.parse_args()

    log_path = Path(args.log_path)
    rows, metadata = read_rows(log_path)
    duplicate_info = duplicate_diagnostics(rows)
    metric_rows = rows_for_metrics(rows, args.dedup_mode)

    rows_by_sensor_raw: dict[int, list[dict[str, str]]] = defaultdict(list)
    rows_by_sensor_metric: dict[int, list[dict[str, str]]] = defaultdict(list)
    bad_sensor_ids: list[str] = []
    for row in rows:
        try:
            sensor_id = int(row.get("sensor_id", ""))
        except ValueError:
            bad_sensor_ids.append(row.get("sensor_id", ""))
            continue
        if sensor_id in (1, 2):
            rows_by_sensor_raw[sensor_id].append(row)
        else:
            bad_sensor_ids.append(str(sensor_id))
    for row in metric_rows:
        try:
            sensor_id = int(row.get("sensor_id", ""))
        except ValueError:
            continue
        if sensor_id in (1, 2):
            rows_by_sensor_metric[sensor_id].append(row)

    sensor_summaries = {
        str(sensor_id): summarize_sensor(
            sensor_id,
            rows_by_sensor_raw.get(sensor_id, []),
            rows_by_sensor_metric.get(sensor_id, []),
            args.expected_rate,
        )
        for sensor_id in (1, 2)
    }
    pair_summary = pairing_summary(rows_by_sensor_metric, args.max_pair_window_ms)
    diagnostics = metadata["diagnostic_lines_sample"] + metadata["diagnostic_lines_tail"]
    receiver_stat = parse_receiver_stat(diagnostics)

    static_checks = {
        "both_sensors_1000_rows": sensor_summaries["1"]["checks"]["min_rows_1000"] and sensor_summaries["2"]["checks"]["min_rows_1000"],
        "sensor_1_effective_hz_ok": sensor_summaries["1"]["checks"]["effective_hz_ok"],
        "sensor_2_effective_hz_ok": sensor_summaries["2"]["checks"]["effective_hz_ok"],
        "sensor_1_seq_gaps_zero": sensor_summaries["1"]["checks"]["seq_gaps_zero"],
        "sensor_2_seq_gaps_zero": sensor_summaries["2"]["checks"]["seq_gaps_zero"],
        "receiver_t_us_valid": sensor_summaries["1"]["checks"]["receiver_t_us_nonzero"] and sensor_summaries["2"]["checks"]["receiver_t_us_nonzero"],
        "packet_status_ok": sensor_summaries["1"]["checks"]["packet_status_ok"] and sensor_summaries["2"]["checks"]["packet_status_ok"],
        "packet_error_code_ok": sensor_summaries["1"]["checks"]["packet_error_code_ok"] and sensor_summaries["2"]["checks"]["packet_error_code_ok"],
        "no_forbidden_fields": not metadata["forbidden_fields_detected_in_header"],
        "only_expected_sensor_ids": not bad_sensor_ids,
        "receiver_invalid_zero_if_seen": receiver_stat["invalid"] in (None, 0),
        "receiver_queue_drops_zero_if_seen": receiver_stat["queue_drops"] in (None, 0),
    }

    event_summary = None
    event_checks: dict[str, bool] = {}
    if args.event_mode == "event":
        event_summary = detect_events(rows_by_sensor_metric)
        event_checks = {
            "event_detected_sensor_1": event_summary["sensors"]["1"]["event_count"] >= 1,
            "event_detected_sensor_2": event_summary["sensors"]["2"]["event_count"] >= 1,
            "delta_event_receiver_us_lte_30000": event_summary["delta_event_receiver_us"] is not None and abs(event_summary["delta_event_receiver_us"]) <= 30_000,
        }

    duplicate_nonblocking = duplicate_info["classification"] in (
        "DUPLICATES_NOT_OBSERVED",
        "DUPLICATES_CAPTURE_ARTIFACT_LIKELY",
    )
    if duplicate_info["classification"] == "DUPLICATES_RECEIVER_STREAM_LIKELY":
        duplicate_nonblocking = (
            duplicate_info["duplicate_groups_different_receiver_t_us"] <= 5
            and duplicate_info["duplicate_sensor_seq_keys"] <= 5
        )

    if args.event_mode == "static":
        mode_pass = all(static_checks.values())
    else:
        event_integrity_checks = {
            key: value
            for key, value in static_checks.items()
            if key not in ("sensor_1_seq_gaps_zero", "sensor_2_seq_gaps_zero")
        }
        mode_pass = all(event_integrity_checks.values()) and all(event_checks.values())
    ready = mode_pass and duplicate_nonblocking

    result = {
        "analysis_timestamp": datetime.now().isoformat(),
        "event_mode": args.event_mode,
        "dedup_mode": args.dedup_mode,
        "expected_rate_hz": args.expected_rate,
        "metadata": metadata,
        "rows_total": len(rows),
        "metric_rows_total": len(metric_rows),
        "bad_sensor_ids": bad_sensor_ids,
        "duplicate_diagnostics": duplicate_info,
        "sensor_summaries": sensor_summaries,
        "pairing_summary": pair_summary,
        "event_summary": event_summary,
        "receiver_stat_last_seen": receiver_stat,
        "checks": {
            "static_checks": static_checks,
            "event_checks": event_checks,
            "event_integrity_note": "event mode does not hard-fail seq_gaps_zero; gaps are reported and static precheck remains the continuity gate.",
            "duplicate_nonblocking": duplicate_nonblocking,
            "mode_pass": mode_pass,
        },
        "decision": {
            "READY_FOR_GUI_KX134_STREAM_INTEGRATION": "YES" if ready else "NO",
            "reason": "criteria_passed" if ready else "criteria_failed_or_duplicates_blocking",
        },
    }

    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(result, indent=2), encoding="utf-8")
    print(f"analysis_json={output}")
    print(f"READY_FOR_GUI_KX134_STREAM_INTEGRATION={result['decision']['READY_FOR_GUI_KX134_STREAM_INTEGRATION']}")
    print(f"duplicate_classification={duplicate_info['classification']}")
    return 0 if ready else 1


if __name__ == "__main__":
    raise SystemExit(main())

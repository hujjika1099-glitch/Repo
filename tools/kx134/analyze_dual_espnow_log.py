#!/usr/bin/env python3
"""Analyze KX134 dual ESP-NOW receiver logs.

The tool accepts the receiver monitor log, extracts KX134 v3 CSV rows, validates
identity/timing/status rules, and writes a JSON report beside the test runs.
"""

from __future__ import annotations

import csv
import json
import math
import sys
from collections import Counter, defaultdict
from datetime import datetime
from pathlib import Path
from statistics import mean


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

DEFAULT_WARMUP_DISCARD_US = 2_000_000

FORBIDDEN_FIELDS = {
    "mv_x",
    "mv_y",
    "mv_z",
    "gx_est",
    "gy_est",
    "gz_est",
    "g_norm_est",
    "voltage_x",
    "voltage_y",
    "voltage_z",
    "millivolts_x",
    "millivolts_y",
    "millivolts_z",
}


def parse_bool(value: str) -> bool:
    return value.strip().lower() == "true"


def parse_rows(path: Path) -> tuple[list[dict[str, str]], dict[str, object]]:
    rows: list[dict[str, str]] = []
    header: list[str] | None = None
    header_detected = False
    header_fallback_used = False
    invalid_field_count = 0
    pre_header_rows_discarded = 0
    diagnostic_lines: list[str] = []

    for raw_line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        line = raw_line.strip()
        if not line:
            continue
        if line.startswith("#"):
            diagnostic_lines.append(line)
            continue
        fields = next(csv.reader([line]))
        if fields == EXPECTED_HEADER:
            if header_fallback_used and rows:
                pre_header_rows_discarded += len(rows)
                rows = []
                header_fallback_used = False
            header = fields
            header_detected = True
            continue
        if header is None:
            if len(fields) == len(EXPECTED_HEADER) and fields[0].lstrip("\ufeff") == "kx134.v3":
                header = EXPECTED_HEADER
                header_fallback_used = True
            else:
                invalid_field_count += 1
                continue
        if len(fields) != len(header):
            invalid_field_count += 1
            continue
        if fields[0].lstrip("\ufeff") != "kx134.v3":
            invalid_field_count += 1
            continue
        fields[0] = fields[0].lstrip("\ufeff")
        rows.append(dict(zip(header, fields)))

    metadata = {
        "header_detected": header_detected,
        "header_fallback_used": header_fallback_used,
        "invalid_field_count": invalid_field_count,
        "pre_header_rows_discarded": pre_header_rows_discarded,
        "diagnostic_lines_sample": diagnostic_lines[:30],
        "diagnostic_lines_tail": diagnostic_lines[-30:],
        "forbidden_fields_detected_in_header": sorted(set(header or []) & FORBIDDEN_FIELDS),
    }
    return rows, metadata


def safe_int(row: dict[str, str], key: str, errors: list[str]) -> int:
    try:
        return int(row[key])
    except Exception:
        errors.append(f"bad_int:{key}")
        return 0


def safe_float(row: dict[str, str], key: str, errors: list[str]) -> float:
    try:
        return float(row[key])
    except Exception:
        errors.append(f"bad_float:{key}")
        return float("nan")


def frequency_hz(times_us: list[int]) -> float | None:
    if len(times_us) < 2:
        return None
    duration_s = (times_us[-1] - times_us[0]) / 1_000_000.0
    if duration_s <= 0:
        return None
    return (len(times_us) - 1) / duration_s


def apply_analysis_window(rows: list[dict[str, str]], metadata: dict[str, object]) -> list[dict[str, str]]:
    receiver_times: list[int] = []
    for row in rows:
        try:
            receiver_times.append(int(row.get("receiver_t_us", "0")))
        except ValueError:
            continue
    if not receiver_times:
        metadata["analysis_warmup_discard_us"] = DEFAULT_WARMUP_DISCARD_US
        metadata["analysis_rows_before_warmup"] = len(rows)
        metadata["analysis_rows_after_warmup"] = len(rows)
        return rows

    start_us = min(receiver_times)
    cutoff_us = start_us + DEFAULT_WARMUP_DISCARD_US
    filtered = [
        row
        for row in rows
        if int(row.get("receiver_t_us", "0") or 0) >= cutoff_us
    ]
    metadata["analysis_warmup_discard_us"] = DEFAULT_WARMUP_DISCARD_US
    metadata["analysis_rows_before_warmup"] = len(rows)
    metadata["analysis_rows_after_warmup"] = len(filtered)
    return filtered


def deduplicate_sensor_rows(rows: list[dict[str, str]]) -> tuple[list[dict[str, str]], int]:
    deduped: list[dict[str, str]] = []
    seen_seq: set[int] = set()
    duplicate_count = 0
    for row in rows:
        try:
            seq = int(row.get("seq", ""))
        except ValueError:
            deduped.append(row)
            continue
        if seq in seen_seq:
            duplicate_count += 1
            continue
        seen_seq.add(seq)
        deduped.append(row)
    return deduped, duplicate_count


def summarize_sensor(sensor_id: int, rows: list[dict[str, str]]) -> dict[str, object]:
    raw_rows = rows
    rows, exact_duplicate_rows_removed = deduplicate_sensor_rows(raw_rows)
    errors: list[str] = []
    seq_values = [safe_int(row, "seq", errors) for row in rows]
    sensor_times = [safe_int(row, "sensor_t_us", errors) for row in rows]
    receiver_times = [safe_int(row, "receiver_t_us", errors) for row in rows]
    x_g = [safe_float(row, "x_g", errors) for row in rows]
    y_g = [safe_float(row, "y_g", errors) for row in rows]
    z_g = [safe_float(row, "z_g", errors) for row in rows]

    seq_gaps = 0
    duplicate_or_reverse_seq = 0
    for prev, curr in zip(seq_values, seq_values[1:]):
        if curr == prev + 1:
            continue
        if curr <= prev:
            duplicate_or_reverse_seq += 1
        else:
            seq_gaps += curr - prev - 1

    timestamp_errors = sum(1 for prev, curr in zip(sensor_times, sensor_times[1:]) if curr <= prev)
    receiver_timestamp_errors = sum(1 for prev, curr in zip(receiver_times, receiver_times[1:]) if curr <= prev)
    g_norm = [
        math.sqrt(x * x + y * y + z * z)
        for x, y, z in zip(x_g, y_g, z_g)
        if math.isfinite(x) and math.isfinite(y) and math.isfinite(z)
    ]

    value_counts = {
        "protocol_version": Counter(row.get("protocol_version", "") for row in rows),
        "node_mac": Counter(row.get("node_mac", "") for row in rows),
        "sample_rate_hz": Counter(row.get("sample_rate_hz", "") for row in rows),
        "odr_hz": Counter(row.get("odr_hz", "") for row in rows),
        "range_g": Counter(row.get("range_g", "") for row in rows),
        "calibration_applied": Counter(row.get("calibration_applied", "") for row in rows),
        "packet_status": Counter(row.get("packet_status", "") for row in rows),
        "packet_error_code": Counter(row.get("packet_error_code", "") for row in rows),
        "contract_version": Counter(row.get("contract_version", "") for row in rows),
    }

    checks = {
        "min_rows": len(rows) >= 300,
        "mac_valid": set(value_counts["node_mac"]) == {EXPECTED_MAC[sensor_id]},
        "sample_rate_valid": set(value_counts["sample_rate_hz"]) == {"100"},
        "odr_valid": set(value_counts["odr_hz"]) == {"100"},
        "range_valid": set(value_counts["range_g"]) == {"8"},
        "calibration_applied": set(value_counts["calibration_applied"]) == {"true"},
        "packet_status_ok": set(value_counts["packet_status"]) == {"OK"},
        "packet_error_code_ok": set(value_counts["packet_error_code"]) == {"OK"},
        "contract_valid": set(value_counts["contract_version"]) == {"kx134.v3"},
        "sensor_t_us_increasing": timestamp_errors == 0,
        "receiver_t_us_increasing": receiver_timestamp_errors == 0,
        "receiver_t_us_nonzero": all(value != 0 for value in receiver_times),
        "seq_gaps_ok": seq_gaps <= 3 and duplicate_or_reverse_seq == 0,
    }

    effective_hz = frequency_hz(sensor_times)
    receiver_hz = frequency_hz(receiver_times)
    checks["effective_hz_ok"] = effective_hz is not None and 98.0 <= effective_hz <= 102.0
    checks["g_norm_mean_ok"] = bool(g_norm) and 0.80 <= mean(g_norm) <= 1.20

    return {
        "sensor_id": sensor_id,
        "rows": len(rows),
        "raw_rows_before_dedup": len(raw_rows),
        "exact_duplicate_rows_removed": exact_duplicate_rows_removed,
        "seq_initial": seq_values[0] if seq_values else None,
        "seq_final": seq_values[-1] if seq_values else None,
        "seq_gaps": seq_gaps,
        "duplicate_or_reverse_seq": duplicate_or_reverse_seq,
        "timestamp_errors": timestamp_errors,
        "receiver_timestamp_errors": receiver_timestamp_errors,
        "effective_hz": effective_hz,
        "receiver_hz": receiver_hz,
        "g_norm_mean": mean(g_norm) if g_norm else None,
        "g_norm_min": min(g_norm) if g_norm else None,
        "g_norm_max": max(g_norm) if g_norm else None,
        "value_counts": {key: dict(counter) for key, counter in value_counts.items()},
        "parse_errors": errors,
        "checks": checks,
        "validation_status": "pass" if all(checks.values()) and not errors else "fail",
    }


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: python tools/kx134/analyze_dual_espnow_log.py <receiver_log.txt>", file=sys.stderr)
        return 2

    log_path = Path(sys.argv[1])
    if not log_path.exists():
        print(f"Log not found: {log_path}", file=sys.stderr)
        return 2

    rows, metadata = parse_rows(log_path)
    rows = apply_analysis_window(rows, metadata)
    rows_by_sensor: dict[int, list[dict[str, str]]] = defaultdict(list)
    bad_sensor_ids = []
    for row in rows:
        try:
            sensor_id = int(row.get("sensor_id", ""))
        except ValueError:
            bad_sensor_ids.append(row.get("sensor_id", ""))
            continue
        if sensor_id in (1, 2):
            rows_by_sensor[sensor_id].append(row)
        else:
            bad_sensor_ids.append(str(sensor_id))

    sensor_summaries = {
        str(sensor_id): summarize_sensor(sensor_id, rows_by_sensor.get(sensor_id, []))
        for sensor_id in (1, 2)
    }

    invalid_diag = [
        line
        for line in metadata["diagnostic_lines_sample"] + metadata["diagnostic_lines_tail"]
        if line.startswith("#INVALID")
    ]
    stat_lines = [
        line
        for line in metadata["diagnostic_lines_sample"] + metadata["diagnostic_lines_tail"]
        if line.startswith("#STAT,role=receiver")
    ]

    forbidden_in_rows = sorted(
        field
        for field in FORBIDDEN_FIELDS
        if any(field in row for row in rows)
    )

    checks = {
        "both_sensors_present": len(rows_by_sensor.get(1, [])) >= 300 and len(rows_by_sensor.get(2, [])) >= 300,
        "only_sensor_ids_1_and_2": not bad_sensor_ids,
        "sensor_1_pass": sensor_summaries["1"]["validation_status"] == "pass",
        "sensor_2_pass": sensor_summaries["2"]["validation_status"] == "pass",
        "forbidden_fields_absent": not metadata["forbidden_fields_detected_in_header"] and not forbidden_in_rows,
    }

    ready = all(checks.values())
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    output_path = Path("reports/kx134_test_runs") / f"TICKET_013_dual_espnow_analysis_{timestamp}.json"
    output_path.parent.mkdir(parents=True, exist_ok=True)

    result = {
        "analysis_timestamp": datetime.now().isoformat(),
        "log_path": str(log_path),
        "rows_total": len(rows),
        "metadata": metadata,
        "bad_sensor_ids": bad_sensor_ids,
        "forbidden_fields_detected": forbidden_in_rows,
        "sensor_summaries": sensor_summaries,
        "receiver_diagnostics": {
            "invalid_lines_seen_in_samples": invalid_diag,
            "stat_lines_seen_in_samples": stat_lines,
        },
        "checks": checks,
        "READY_FOR_DUAL_SYNC_PRECHECK": "YES" if ready else "NO",
    }

    output_path.write_text(json.dumps(result, indent=2), encoding="utf-8")
    print(f"analysis_json={output_path}")
    print(f"READY_FOR_DUAL_SYNC_PRECHECK={result['READY_FOR_DUAL_SYNC_PRECHECK']}")
    return 0 if ready else 1


if __name__ == "__main__":
    raise SystemExit(main())

from __future__ import annotations

import argparse
import csv
import json
import math
from collections import Counter, defaultdict
from pathlib import Path


KX134_EXPECTED_HEADER = [
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

FORBIDDEN_FIELDS = {
    "mv_x",
    "mv_y",
    "mv_z",
    "gx_est",
    "gy_est",
    "gz_est",
    "g_norm_est",
    "voltage",
    "voltage_x",
    "voltage_y",
    "voltage_z",
    "millivolts",
    "millivolts_x",
    "millivolts_y",
    "millivolts_z",
}

EXPECTED_MACS = {
    1: "D4:E9:F4:E9:8E:1C",
    2: "D4:E9:F4:C3:37:14",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Validate KX134 GUI hardware capture artifacts")
    parser.add_argument("--session-json", required=True)
    parser.add_argument("--raw-csv", required=True)
    parser.add_argument("--summary", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--expected-sample-rate", type=int, default=100)
    parser.add_argument("--expected-range-g", type=int, default=8)
    parser.add_argument("--min-rows-per-sensor", type=int, default=500)
    parser.add_argument("--require-pc-wall-positive", default="true")
    return parser.parse_args()


def to_bool(text: str) -> bool:
    return str(text).strip().lower() not in {"0", "false", "no", "off"}


def as_int(value: str, field: str, failures: list[str]) -> int:
    try:
        return int(str(value).strip())
    except (TypeError, ValueError):
        failures.append(f"bad_int:{field}:{value}")
        return 0


def as_float(value: str, field: str, failures: list[str]) -> float:
    try:
        return float(str(value).strip())
    except (TypeError, ValueError):
        failures.append(f"bad_float:{field}:{value}")
        return math.nan


def count_seq_gaps(rows: list[dict[str, object]]) -> int:
    seqs = sorted(int(row["seq"]) for row in rows)
    gaps = 0
    for previous, current in zip(seqs, seqs[1:]):
        if current > previous + 1:
            gaps += current - previous - 1
    return gaps


def count_timestamp_errors(rows: list[dict[str, object]], field: str) -> int:
    values = [int(row[field]) for row in rows]
    return sum(1 for previous, current in zip(values, values[1:]) if current <= previous)


def effective_hz(rows: list[dict[str, object]]) -> float:
    if len(rows) < 2:
        return 0.0
    ordered = sorted(rows, key=lambda row: int(row["sensor_t_us"]))
    delta_s = (int(ordered[-1]["sensor_t_us"]) - int(ordered[0]["sensor_t_us"])) / 1_000_000.0
    if delta_s <= 0:
        return 0.0
    return (len(ordered) - 1) / delta_s


def validate_csv(
    raw_csv: Path,
    *,
    expected_sample_rate: int,
    expected_range_g: int,
    min_rows_per_sensor: int,
    require_pc_wall_positive: bool,
) -> tuple[dict[str, object], list[str]]:
    failures: list[str] = []
    with raw_csv.open(newline="", encoding="utf-8") as handle:
        reader = csv.DictReader(handle)
        header = list(reader.fieldnames or [])
        rows_in = list(reader)

    header_exact = header == KX134_EXPECTED_HEADER
    if not header_exact:
        failures.append("csv_header_not_exact_kx134_v3")

    forbidden_detected = sorted({field for field in header if field.lower() in FORBIDDEN_FIELDS})
    if forbidden_detected:
        failures.append("forbidden_fields_detected")

    rows_by_sensor: dict[int, list[dict[str, object]]] = defaultdict(list)
    packet_status_counts: Counter[str] = Counter()
    packet_error_code_counts: Counter[str] = Counter()
    pc_wall_positive = True
    receiver_t_us_valid = True

    for row_number, row in enumerate(rows_in, start=2):
        row_failures: list[str] = []
        sensor_id = as_int(row.get("sensor_id", ""), "sensor_id", row_failures)
        seq = as_int(row.get("seq", ""), "seq", row_failures)
        sensor_t_us = as_int(row.get("sensor_t_us", ""), "sensor_t_us", row_failures)
        receiver_t_us = as_int(row.get("receiver_t_us", ""), "receiver_t_us", row_failures)
        pc_wall_s = as_float(row.get("pc_wall_s", ""), "pc_wall_s", row_failures)
        sample_rate_hz = as_int(row.get("sample_rate_hz", ""), "sample_rate_hz", row_failures)
        odr_hz = as_int(row.get("odr_hz", ""), "odr_hz", row_failures)
        range_g = as_int(row.get("range_g", ""), "range_g", row_failures)
        for field in ("x_raw", "y_raw", "z_raw"):
            as_int(row.get(field, ""), field, row_failures)
        for field in ("x_g", "y_g", "z_g"):
            as_float(row.get(field, ""), field, row_failures)

        if row_failures:
            failures.extend(f"row_{row_number}:{failure}" for failure in row_failures)
            continue

        if sensor_id not in (1, 2):
            failures.append(f"row_{row_number}:bad_sensor_id:{sensor_id}")
        if not str(row.get("node_mac", "")).strip():
            failures.append(f"row_{row_number}:missing_node_mac")
        if sensor_id in EXPECTED_MACS and row.get("node_mac") != EXPECTED_MACS[sensor_id]:
            failures.append(f"row_{row_number}:bad_node_mac_sensor_{sensor_id}")
        if sample_rate_hz != expected_sample_rate:
            failures.append(f"row_{row_number}:bad_sample_rate:{sample_rate_hz}")
        if odr_hz != expected_sample_rate:
            failures.append(f"row_{row_number}:bad_odr:{odr_hz}")
        if range_g != expected_range_g:
            failures.append(f"row_{row_number}:bad_range_g:{range_g}")
        if str(row.get("calibration_applied", "")).strip().lower() != "true":
            failures.append(f"row_{row_number}:calibration_not_applied")
        packet_status_counts[str(row.get("packet_status", ""))] += 1
        packet_error_code_counts[str(row.get("packet_error_code", ""))] += 1
        if row.get("packet_status") != "OK":
            failures.append(f"row_{row_number}:packet_status_not_ok")
        if row.get("packet_error_code") != "OK":
            failures.append(f"row_{row_number}:packet_error_code_not_ok")
        if require_pc_wall_positive and pc_wall_s <= 0:
            pc_wall_positive = False
        if receiver_t_us <= 0:
            receiver_t_us_valid = False

        rows_by_sensor[sensor_id].append(
            {
                "seq": seq,
                "sensor_t_us": sensor_t_us,
                "receiver_t_us": receiver_t_us,
                "node_mac": row.get("node_mac", ""),
            }
        )

    rows_by_sensor_count = {str(sensor_id): len(rows_by_sensor.get(sensor_id, [])) for sensor_id in (1, 2)}
    seq_gaps = {str(sensor_id): count_seq_gaps(rows_by_sensor.get(sensor_id, [])) for sensor_id in (1, 2)}
    timestamp_errors = {
        str(sensor_id): count_timestamp_errors(rows_by_sensor.get(sensor_id, []), "sensor_t_us")
        for sensor_id in (1, 2)
    }
    receiver_timestamp_errors = {
        str(sensor_id): count_timestamp_errors(rows_by_sensor.get(sensor_id, []), "receiver_t_us")
        for sensor_id in (1, 2)
    }
    duplicate_keys = {}
    for sensor_id in (1, 2):
        keys = [
            (row["node_mac"], row["seq"])
            for row in rows_by_sensor.get(sensor_id, [])
        ]
        duplicate_keys[str(sensor_id)] = sum(count - 1 for count in Counter(keys).values() if count > 1)

    hz = {str(sensor_id): effective_hz(rows_by_sensor.get(sensor_id, [])) for sensor_id in (1, 2)}

    for sensor_id in (1, 2):
        if rows_by_sensor_count[str(sensor_id)] < min_rows_per_sensor:
            failures.append(f"sensor_{sensor_id}:too_few_rows")
        if not (98.0 <= hz[str(sensor_id)] <= 102.0):
            failures.append(f"sensor_{sensor_id}:effective_hz_out_of_range")

    if require_pc_wall_positive and not pc_wall_positive:
        failures.append("pc_wall_s_not_positive")
    if not receiver_t_us_valid:
        failures.append("receiver_t_us_not_valid")

    result = {
        "csv_header_exact_kx134_v3": header_exact,
        "forbidden_fields_detected": bool(forbidden_detected),
        "forbidden_fields": forbidden_detected,
        "rows_by_sensor": rows_by_sensor_count,
        "effective_hz_by_sensor": hz,
        "seq_gaps_by_sensor": seq_gaps,
        "timestamp_errors_by_sensor": timestamp_errors,
        "receiver_timestamp_errors_by_sensor": receiver_timestamp_errors,
        "duplicate_keys_by_sensor": duplicate_keys,
        "pc_wall_s_positive": pc_wall_positive,
        "receiver_t_us_valid": receiver_t_us_valid,
        "packet_status_counts": dict(packet_status_counts),
        "packet_error_code_counts": dict(packet_error_code_counts),
    }
    return result, failures


def main() -> int:
    args = parse_args()
    session_json = Path(args.session_json).resolve()
    raw_csv = Path(args.raw_csv).resolve()
    summary = Path(args.summary).resolve()
    output = Path(args.output).resolve()
    output.parent.mkdir(parents=True, exist_ok=True)

    failures: list[str] = []
    artifacts_exist = {
        "raw_csv": raw_csv.exists(),
        "session_json": session_json.exists(),
        "summary": summary.exists(),
    }
    for name, exists in artifacts_exist.items():
        if not exists:
            failures.append(f"missing_artifact:{name}")

    csv_result: dict[str, object] = {}
    if raw_csv.exists():
        csv_result, csv_failures = validate_csv(
            raw_csv,
            expected_sample_rate=args.expected_sample_rate,
            expected_range_g=args.expected_range_g,
            min_rows_per_sensor=args.min_rows_per_sensor,
            require_pc_wall_positive=to_bool(args.require_pc_wall_positive),
        )
        failures.extend(csv_failures)

    metadata_result: dict[str, object] = {}
    if session_json.exists():
        metadata = json.loads(session_json.read_text(encoding="utf-8"))
        metadata_result = {
            "has_summary": "summary" in metadata,
            "expected_sample_rate_hz": metadata.get("expected_sample_rate_hz"),
            "invalid_lines": metadata.get("invalid_lines"),
            "artifacts": metadata.get("artifacts", {}),
            "artifact_paths_exist": {},
        }
        if not metadata_result["has_summary"]:
            failures.append("metadata_missing_summary")
        if metadata.get("expected_sample_rate_hz") != args.expected_sample_rate:
            failures.append("metadata_bad_expected_sample_rate")
        for key, value in (metadata.get("artifacts", {}) or {}).items():
            metadata_result["artifact_paths_exist"][key] = Path(value).exists()
            if not Path(value).exists():
                failures.append(f"metadata_artifact_missing:{key}")

    result = {
        "pass": not failures,
        "failures": failures,
        "artifacts": {
            "raw_csv": str(raw_csv),
            "session_json": str(session_json),
            "summary": str(summary),
            "exist": artifacts_exist,
        },
        "csv": csv_result,
        "metadata": metadata_result,
    }
    output.write_text(json.dumps(result, indent=2, ensure_ascii=True), encoding="utf-8")
    print(str(output))
    return 0 if result["pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())

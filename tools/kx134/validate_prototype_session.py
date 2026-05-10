from __future__ import annotations

import argparse
import csv
import json
import math
import sys
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))

from gui.kx134_stream_contract import KX134_EXPECTED_HEADER, KX134_FORBIDDEN_FIELDS  # noqa: E402


EXPECTED_MACS = {
    1: "D4:E9:F4:E9:8E:1C",
    2: "D4:E9:F4:C3:37:14",
}


def parse_bool(value: object) -> bool:
    return str(value).strip().lower() in {"1", "true", "yes", "y", "on"}


def parse_blockers(value: str) -> list[str]:
    return [item.strip() for item in str(value or "").split(",") if item.strip()]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Validate a controlled KX134 prototype session")
    parser.add_argument("--session-json", required=True)
    parser.add_argument("--raw-csv", required=True)
    parser.add_argument("--summary-md", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--expected-sample-rate", type=int, default=100)
    parser.add_argument("--expected-range-g", type=int, default=8)
    parser.add_argument("--min-duration-s", type=float, default=60.0)
    parser.add_argument("--min-rows-per-sensor", type=int, default=5500)
    parser.add_argument("--require-live-plot-confirmation", default="true")
    parser.add_argument("--live-plot-confirmed", default="false")
    parser.add_argument(
        "--pcb-blockers",
        default="",
        help="Comma-separated physical/mechanical blockers. If empty, final PCB recommendation remains false.",
    )
    return parser.parse_args()


def as_int(value: object, field: str, failures: list[str]) -> int:
    try:
        return int(str(value).strip())
    except (TypeError, ValueError):
        failures.append(f"bad_int:{field}:{value}")
        return 0


def as_float(value: object, field: str, failures: list[str]) -> float:
    try:
        return float(str(value).strip())
    except (TypeError, ValueError):
        failures.append(f"bad_float:{field}:{value}")
        return math.nan


def seq_gaps(rows: list[dict[str, object]]) -> int:
    seqs = sorted(int(row["seq"]) for row in rows)
    return sum(max(0, current - previous - 1) for previous, current in zip(seqs, seqs[1:]))


def timestamp_errors(rows: list[dict[str, object]], field: str) -> int:
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


def load_csv(path: Path, failures: list[str]) -> tuple[list[str], list[dict[str, str]]]:
    if not path.exists():
        failures.append("raw_csv_missing")
        return [], []
    with path.open(newline="", encoding="utf-8") as handle:
        reader = csv.DictReader(handle)
        return list(reader.fieldnames or []), list(reader)


def validate_csv(
    path: Path,
    *,
    expected_sample_rate: int,
    expected_range_g: int,
    min_rows_per_sensor: int,
    failures: list[str],
    warnings: list[str],
) -> dict[str, object]:
    header, rows = load_csv(path, failures)
    forbidden = sorted(
        field for field in header if field.strip().lower() in {item.lower() for item in KX134_FORBIDDEN_FIELDS}
    )
    if header != KX134_EXPECTED_HEADER:
        failures.append("csv_header_not_exact_kx134_v3")
    if forbidden:
        failures.append("forbidden_fields_detected")

    rows_by_sensor: dict[int, list[dict[str, object]]] = defaultdict(list)
    packet_status_counts: Counter[str] = Counter()
    packet_error_code_counts: Counter[str] = Counter()
    pc_wall_s_positive = True
    receiver_t_us_valid = True

    for row_number, row in enumerate(rows, start=2):
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

        if sensor_id not in EXPECTED_MACS:
            failures.append(f"row_{row_number}:bad_sensor_id:{sensor_id}")
        elif row.get("node_mac") != EXPECTED_MACS[sensor_id]:
            failures.append(f"row_{row_number}:bad_node_mac_sensor_{sensor_id}")
        if sample_rate_hz != expected_sample_rate:
            failures.append(f"row_{row_number}:bad_sample_rate:{sample_rate_hz}")
        if odr_hz != expected_sample_rate:
            failures.append(f"row_{row_number}:bad_odr:{odr_hz}")
        if range_g != expected_range_g:
            failures.append(f"row_{row_number}:bad_range_g:{range_g}")
        if str(row.get("calibration_applied", "")).strip().lower() != "true":
            failures.append(f"row_{row_number}:calibration_not_applied")
        if row.get("packet_status") != "OK":
            failures.append(f"row_{row_number}:packet_status_not_ok")
        if row.get("packet_error_code") != "OK":
            failures.append(f"row_{row_number}:packet_error_code_not_ok")
        if pc_wall_s <= 0:
            pc_wall_s_positive = False
        if receiver_t_us <= 0:
            receiver_t_us_valid = False

        packet_status_counts[str(row.get("packet_status", ""))] += 1
        packet_error_code_counts[str(row.get("packet_error_code", ""))] += 1
        rows_by_sensor[sensor_id].append(
            {
                "seq": seq,
                "sensor_t_us": sensor_t_us,
                "receiver_t_us": receiver_t_us,
                "node_mac": row.get("node_mac", ""),
            }
        )

    rows_count = {str(sensor_id): len(rows_by_sensor.get(sensor_id, [])) for sensor_id in (1, 2)}
    gaps = {str(sensor_id): seq_gaps(rows_by_sensor.get(sensor_id, [])) for sensor_id in (1, 2)}
    ts_errors = {
        str(sensor_id): timestamp_errors(rows_by_sensor.get(sensor_id, []), "sensor_t_us")
        for sensor_id in (1, 2)
    }
    receiver_ts_errors = {
        str(sensor_id): timestamp_errors(rows_by_sensor.get(sensor_id, []), "receiver_t_us")
        for sensor_id in (1, 2)
    }
    duplicate_keys = {}
    for sensor_id in (1, 2):
        keys = [(row["node_mac"], row["seq"]) for row in rows_by_sensor.get(sensor_id, [])]
        duplicate_keys[str(sensor_id)] = sum(count - 1 for count in Counter(keys).values() if count > 1)
    hz = {str(sensor_id): effective_hz(rows_by_sensor.get(sensor_id, [])) for sensor_id in (1, 2)}

    for sensor_id in (1, 2):
        key = str(sensor_id)
        if rows_count[key] < min_rows_per_sensor:
            failures.append(f"sensor_{sensor_id}:too_few_rows")
        if not (98.0 <= hz[key] <= 102.0):
            failures.append(f"sensor_{sensor_id}:effective_hz_out_of_range")
        if gaps[key] > 3:
            failures.append(f"sensor_{sensor_id}:seq_gaps_gt_3")
        elif gaps[key] > 0:
            warnings.append(f"sensor_{sensor_id}:seq_gaps:{gaps[key]}")
        if duplicate_keys[key] > 0:
            warnings.append(f"sensor_{sensor_id}:duplicate_keys:{duplicate_keys[key]}")
    if not pc_wall_s_positive:
        failures.append("pc_wall_s_not_positive")
    if not receiver_t_us_valid:
        failures.append("receiver_t_us_not_valid")

    return {
        "csv_header_exact_kx134_v3": header == KX134_EXPECTED_HEADER,
        "forbidden_fields_detected": bool(forbidden),
        "forbidden_fields": forbidden,
        "rows_by_sensor": rows_count,
        "effective_hz_by_sensor": hz,
        "seq_gaps_by_sensor": gaps,
        "timestamp_errors_by_sensor": ts_errors,
        "receiver_timestamp_errors_by_sensor": receiver_ts_errors,
        "duplicate_keys_by_sensor": duplicate_keys,
        "pc_wall_s_positive": pc_wall_s_positive,
        "receiver_t_us_valid": receiver_t_us_valid,
        "packet_status_counts": dict(packet_status_counts),
        "packet_error_code_counts": dict(packet_error_code_counts),
    }


def validate_metadata(path: Path, min_duration_s: float, failures: list[str], warnings: list[str]) -> dict[str, object]:
    if not path.exists():
        failures.append("session_json_missing")
        return {"metadata_schema_pass": False, "invalid_lines": None}
    metadata = json.loads(path.read_text(encoding="utf-8-sig"))
    required = [
        "session_id",
        "session_name",
        "protocol_version",
        "contract_version",
        "capture_duration_requested_s",
        "capture_duration_actual_s",
        "summary",
        "artifacts",
    ]
    missing = [field for field in required if field not in metadata]
    if missing:
        failures.append("metadata_missing_required_fields")
    duration_actual = float(metadata.get("capture_duration_actual_s") or 0)
    duration_requested = float(metadata.get("capture_duration_requested_s") or 0)
    if duration_requested < min_duration_s:
        failures.append("capture_duration_requested_below_min")
    if duration_actual < min_duration_s * 0.95:
        warnings.append("capture_duration_actual_below_95pct_min")
    invalid_lines = metadata.get("invalid_lines", metadata.get("summary", {}).get("invalid_lines", 0))
    try:
        invalid_count = int(invalid_lines)
    except (TypeError, ValueError):
        invalid_count = None
        failures.append("invalid_lines_not_numeric")
    if invalid_count not in (None, 0):
        warnings.append(f"invalid_lines:{invalid_count}")
    artifacts = metadata.get("artifacts", {})
    artifact_paths_present = bool(artifacts)
    if not artifact_paths_present:
        failures.append("metadata_artifacts_missing")
    return {
        "metadata_schema_pass": not missing,
        "missing_metadata_fields": missing,
        "capture_duration_requested_s": duration_requested,
        "capture_duration_actual_s": duration_actual,
        "invalid_lines": invalid_count,
        "artifact_paths_present": artifact_paths_present,
    }


def main() -> int:
    args = parse_args()
    session_json = Path(args.session_json)
    raw_csv = Path(args.raw_csv)
    summary_md = Path(args.summary_md)
    output = Path(args.output)
    failures: list[str] = []
    warnings: list[str] = []

    if not summary_md.exists():
        failures.append("summary_md_missing")
    summary_text = summary_md.read_text(encoding="utf-8", errors="replace") if summary_md.exists() else ""
    if "Sensor 1" not in summary_text or "Sensor 2" not in summary_text:
        warnings.append("summary_missing_sensor_labels")

    csv_result = validate_csv(
        raw_csv,
        expected_sample_rate=args.expected_sample_rate,
        expected_range_g=args.expected_range_g,
        min_rows_per_sensor=args.min_rows_per_sensor,
        failures=failures,
        warnings=warnings,
    )
    metadata_result = validate_metadata(session_json, args.min_duration_s, failures, warnings)

    live_required = parse_bool(args.require_live_plot_confirmation)
    live_confirmed = parse_bool(args.live_plot_confirmed)
    if live_required and not live_confirmed:
        failures.append("live_plot_confirmation_missing")

    passed = not failures
    pcb_blockers = parse_blockers(args.pcb_blockers)
    pcb_final_recommendation = passed and not pcb_blockers
    if passed and not pcb_blockers:
        warnings.append("pcb_final_recommendation_requires_physical_mechanical_decisions")
        pcb_final_recommendation = False
    result = {
        "pass": passed,
        "failures": failures,
        "warnings": warnings,
        "raw_csv": str(raw_csv),
        "session_json": str(session_json),
        "summary_md": str(summary_md),
        "rows_by_sensor": csv_result.get("rows_by_sensor", {}),
        "effective_hz_by_sensor": csv_result.get("effective_hz_by_sensor", {}),
        "seq_gaps_by_sensor": csv_result.get("seq_gaps_by_sensor", {}),
        "timestamp_errors_by_sensor": csv_result.get("timestamp_errors_by_sensor", {}),
        "receiver_timestamp_errors_by_sensor": csv_result.get("receiver_timestamp_errors_by_sensor", {}),
        "duplicate_keys_by_sensor": csv_result.get("duplicate_keys_by_sensor", {}),
        "invalid_lines": metadata_result.get("invalid_lines"),
        "pc_wall_s_positive": csv_result.get("pc_wall_s_positive", False),
        "receiver_t_us_valid": csv_result.get("receiver_t_us_valid", False),
        "packet_status_counts": csv_result.get("packet_status_counts", {}),
        "packet_error_code_counts": csv_result.get("packet_error_code_counts", {}),
        "forbidden_fields_detected": csv_result.get("forbidden_fields_detected", True),
        "metadata_schema_pass": metadata_result.get("metadata_schema_pass", False),
        "artifact_paths_present": metadata_result.get("artifact_paths_present", False),
        "live_plot_confirmed": live_confirmed,
        "ready_for_prototype_delivery": passed,
        "ready_for_pcb_design_technical_capture_recommendation": passed,
        "ready_for_pcb_design_final_recommendation": pcb_final_recommendation,
        "ready_for_pcb_design_recommendation": pcb_final_recommendation,
        "pcb_blockers": pcb_blockers,
        "pcb_recommendation_note": (
            "PCB final recommendation requires physical/mechanical decisions."
            if not pcb_blockers
            else "PCB final recommendation is blocked by physical/mechanical open items."
        ),
    }
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(result, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(output)
    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())

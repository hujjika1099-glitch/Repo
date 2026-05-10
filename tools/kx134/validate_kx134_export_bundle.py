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

from gui.kx134_stream_contract import (  # noqa: E402
    KX134_EXPECTED_HEADER,
    KX134_FORBIDDEN_FIELDS,
    KX134_PROTOCOL_VERSION,
)


EXPECTED_MACS = {
    1: "D4:E9:F4:E9:8E:1C",
    2: "D4:E9:F4:C3:37:14",
}


REQUIRED_METADATA_FIELDS = [
    "session_id",
    "session_name",
    "session_type",
    "protocol_version",
    "contract_version",
    "created_at_iso",
    "started_at_iso",
    "ended_at_iso",
    "capture_duration_requested_s",
    "capture_duration_actual_s",
    "port",
    "baud",
    "expected_sample_rate_hz",
    "allowed_sample_rates_hz",
    "expected_range_g",
    "expected_odr_hz",
    "serial_warmup_s",
    "firmware_configuration_sent",
    "topology_version",
    "total_esp32_required",
    "transport",
    "nodes_expected",
    "summary",
    "artifacts",
    "artifacts_relative_to_session_root",
    "invalid_lines",
    "decision",
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Validate a hardened KX134 export bundle")
    parser.add_argument("--session-json", required=True)
    parser.add_argument("--raw-csv", required=True)
    parser.add_argument("--summary-md", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--expected-sample-rate", type=int, default=100)
    parser.add_argument("--expected-range-g", type=int, default=8)
    parser.add_argument("--min-rows-per-sensor", type=int, default=500)
    parser.add_argument("--require-relative-artifacts", default="true")
    parser.add_argument("--require-pc-wall-positive", default="true")
    return parser.parse_args()


def to_bool(value: object) -> bool:
    return str(value).strip().lower() not in {"0", "false", "no", "off"}


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


def count_seq_gaps(rows: list[dict[str, object]]) -> int:
    seqs = sorted(int(row["seq"]) for row in rows)
    return sum(max(0, current - previous - 1) for previous, current in zip(seqs, seqs[1:]))


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
) -> tuple[dict[str, object], list[str], list[str]]:
    failures: list[str] = []
    warnings: list[str] = []
    with raw_csv.open(newline="", encoding="utf-8") as handle:
        reader = csv.DictReader(handle)
        header = list(reader.fieldnames or [])
        rows_in = list(reader)

    if header != KX134_EXPECTED_HEADER:
        failures.append("csv_header_not_exact_kx134_v3")
    if len(header) != 27:
        failures.append("csv_header_field_count_not_27")

    forbidden_fields = sorted(
        {field for field in header if field.strip().lower() in {item.lower() for item in KX134_FORBIDDEN_FIELDS}}
    )
    if forbidden_fields:
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
        if sensor_id in EXPECTED_MACS and row.get("node_mac") != EXPECTED_MACS[sensor_id]:
            failures.append(f"row_{row_number}:bad_node_mac_sensor_{sensor_id}")
        if not str(row.get("node_mac", "")).strip():
            failures.append(f"row_{row_number}:missing_node_mac")
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
        if require_pc_wall_positive and pc_wall_s <= 0:
            pc_wall_positive = False
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
        keys = [(row["node_mac"], row["seq"]) for row in rows_by_sensor.get(sensor_id, [])]
        duplicate_keys[str(sensor_id)] = sum(count - 1 for count in Counter(keys).values() if count > 1)
    hz = {str(sensor_id): effective_hz(rows_by_sensor.get(sensor_id, [])) for sensor_id in (1, 2)}

    for sensor_id in (1, 2):
        if rows_count[str(sensor_id)] < min_rows_per_sensor:
            failures.append(f"sensor_{sensor_id}:too_few_rows")
        if expected_sample_rate == 100 and not (98.0 <= hz[str(sensor_id)] <= 102.0):
            failures.append(f"sensor_{sensor_id}:effective_hz_out_of_range")
        if seq_gaps[str(sensor_id)] > 0:
            warnings.append(f"sensor_{sensor_id}:seq_gaps:{seq_gaps[str(sensor_id)]}")
        if duplicate_keys[str(sensor_id)] > 0:
            warnings.append(f"sensor_{sensor_id}:duplicate_keys:{duplicate_keys[str(sensor_id)]}")
    if require_pc_wall_positive and not pc_wall_positive:
        failures.append("pc_wall_s_not_positive")
    if not receiver_t_us_valid:
        failures.append("receiver_t_us_not_valid")

    result = {
        "csv_header_exact_kx134_v3": header == KX134_EXPECTED_HEADER,
        "csv_field_count": len(header),
        "forbidden_fields_detected": bool(forbidden_fields),
        "forbidden_fields": forbidden_fields,
        "rows_by_sensor": rows_count,
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
    return result, failures, warnings


def validate_metadata(
    metadata: dict[str, object],
    *,
    expected_sample_rate: int,
    require_relative_artifacts: bool,
) -> tuple[dict[str, object], list[str], list[str]]:
    failures: list[str] = []
    warnings: list[str] = []
    missing_fields = [field for field in REQUIRED_METADATA_FIELDS if field not in metadata]
    if missing_fields:
        failures.append("metadata_missing_required_fields:" + ",".join(missing_fields))

    if metadata.get("protocol_version") != KX134_PROTOCOL_VERSION:
        failures.append("metadata_bad_protocol_version")
    if metadata.get("contract_version") != KX134_PROTOCOL_VERSION:
        failures.append("metadata_bad_contract_version")
    if metadata.get("expected_sample_rate_hz") != expected_sample_rate:
        failures.append("metadata_bad_expected_sample_rate")
    if metadata.get("firmware_configuration_sent") is not False:
        failures.append("metadata_firmware_configuration_sent_not_false")

    allowed_rates = metadata.get("allowed_sample_rates_hz", [])
    if allowed_rates != [100, 200, 400, 800]:
        failures.append("metadata_bad_allowed_sample_rates")
    if 500 in allowed_rates or 1000 in allowed_rates:
        failures.append("metadata_disallowed_sample_rate_present")

    nodes = metadata.get("nodes_expected", {})
    for key in ("sensor_1", "sensor_2", "receiver"):
        if not isinstance(nodes, dict) or key not in nodes:
            failures.append(f"metadata_missing_node_identity:{key}")

    summary = metadata.get("summary", {})
    for key in (
        "samples_by_sensor",
        "seq_gaps_by_sensor",
        "duplicate_keys_by_sensor",
        "invalid_lines",
        "forbidden_fields_detected",
    ):
        if not isinstance(summary, dict) or key not in summary:
            failures.append(f"metadata_summary_missing:{key}")

    artifacts = metadata.get("artifacts", {})
    relative = metadata.get("artifacts_relative_to_session_root")
    relative_artifacts_pass = isinstance(relative, dict) and all(
        key in relative for key in ("raw_csv", "session_json", "summary_md")
    )
    if require_relative_artifacts and not relative_artifacts_pass:
        failures.append("metadata_missing_relative_artifacts")
    if not isinstance(artifacts, dict):
        failures.append("metadata_artifacts_not_object")
    elif "artifact_paths_exist" not in artifacts and "artifact_paths_exist" not in metadata:
        warnings.append("metadata_artifact_paths_exist_missing")

    result = {
        "metadata_schema_pass": not failures,
        "missing_required_fields": missing_fields,
        "relative_artifacts_pass": relative_artifacts_pass,
        "firmware_configuration_sent": metadata.get("firmware_configuration_sent"),
        "allowed_sample_rates_hz": allowed_rates,
    }
    return result, failures, warnings


def validate_summary(summary_md: Path) -> tuple[dict[str, object], list[str]]:
    failures: list[str] = []
    text = summary_md.read_text(encoding="utf-8")
    checks = {
        "mentions_sensor_1": "Sensor 1" in text,
        "mentions_sensor_2": "Sensor 2" in text,
        "mentions_artifacts": "Artifacts" in text or "artefact" in text.lower(),
        "mentions_decision": "Decision" in text or "decisi" in text.lower(),
    }
    for key, passed in checks.items():
        if not passed:
            failures.append(f"summary_missing:{key}")
    return checks, failures


def main() -> int:
    args = parse_args()
    session_json = Path(args.session_json).resolve()
    raw_csv = Path(args.raw_csv).resolve()
    summary_md = Path(args.summary_md).resolve()
    output = Path(args.output).resolve()
    output.parent.mkdir(parents=True, exist_ok=True)

    failures: list[str] = []
    warnings: list[str] = []
    artifact_paths_exist = {
        "raw_csv": raw_csv.exists(),
        "session_json": session_json.exists(),
        "summary_md": summary_md.exists(),
    }
    for key, exists in artifact_paths_exist.items():
        if not exists:
            failures.append(f"missing_artifact:{key}")

    csv_result: dict[str, object] = {}
    if raw_csv.exists():
        csv_result, csv_failures, csv_warnings = validate_csv(
            raw_csv,
            expected_sample_rate=args.expected_sample_rate,
            expected_range_g=args.expected_range_g,
            min_rows_per_sensor=args.min_rows_per_sensor,
            require_pc_wall_positive=to_bool(args.require_pc_wall_positive),
        )
        failures.extend(csv_failures)
        warnings.extend(csv_warnings)

    metadata_result: dict[str, object] = {"metadata_schema_pass": False, "relative_artifacts_pass": False}
    metadata: dict[str, object] = {}
    if session_json.exists():
        metadata = json.loads(session_json.read_text(encoding="utf-8"))
        metadata_result, metadata_failures, metadata_warnings = validate_metadata(
            metadata,
            expected_sample_rate=args.expected_sample_rate,
            require_relative_artifacts=to_bool(args.require_relative_artifacts),
        )
        failures.extend(metadata_failures)
        warnings.extend(metadata_warnings)

    summary_result: dict[str, object] = {}
    if summary_md.exists():
        summary_result, summary_failures = validate_summary(summary_md)
        failures.extend(summary_failures)

    invalid_lines = metadata.get("invalid_lines")
    if invalid_lines is None and isinstance(metadata.get("summary"), dict):
        invalid_lines = metadata["summary"].get("invalid_lines")

    pass_value = not failures
    result = {
        "pass": pass_value,
        "decision": "PASS" if pass_value else "FAIL",
        "failures": failures,
        "warnings": warnings,
        "artifacts": {
            "raw_csv": str(raw_csv),
            "session_json": str(session_json),
            "summary_md": str(summary_md),
        },
        "artifact_paths_exist": artifact_paths_exist,
        "rows_by_sensor": csv_result.get("rows_by_sensor", {}),
        "effective_hz_by_sensor": csv_result.get("effective_hz_by_sensor", {}),
        "seq_gaps_by_sensor": csv_result.get("seq_gaps_by_sensor", {}),
        "timestamp_errors_by_sensor": csv_result.get("timestamp_errors_by_sensor", {}),
        "receiver_timestamp_errors_by_sensor": csv_result.get(
            "receiver_timestamp_errors_by_sensor", {}
        ),
        "duplicate_keys_by_sensor": csv_result.get("duplicate_keys_by_sensor", {}),
        "invalid_lines": invalid_lines,
        "pc_wall_s_positive": csv_result.get("pc_wall_s_positive", False),
        "receiver_t_us_valid": csv_result.get("receiver_t_us_valid", False),
        "forbidden_fields_detected": csv_result.get("forbidden_fields_detected", False),
        "csv_header_exact_kx134_v3": csv_result.get("csv_header_exact_kx134_v3", False),
        "metadata_schema_pass": metadata_result.get("metadata_schema_pass", False),
        "relative_artifacts_pass": metadata_result.get("relative_artifacts_pass", False),
        "csv": csv_result,
        "metadata": metadata_result,
        "summary": summary_result,
    }
    output.write_text(json.dumps(result, indent=2, ensure_ascii=True), encoding="utf-8")
    print(str(output))
    return 0 if pass_value else 1


if __name__ == "__main__":
    raise SystemExit(main())

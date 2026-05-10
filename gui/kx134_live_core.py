from __future__ import annotations

import csv
import json
import math
import threading
import time
import traceback
from collections import Counter
from dataclasses import asdict, dataclass, field, replace
from datetime import datetime, timezone
from pathlib import Path
from statistics import mean
from typing import Callable

try:
    from .kx134_stream_contract import (
        KX134_ALLOWED_RANGE_G,
        KX134_ALLOWED_SAMPLE_RATES,
        KX134_DEFAULT_BAUD,
        KX134_DEFAULT_SERIAL_WARMUP_S,
        KX134_DEFAULT_SAMPLE_RATE_HZ,
        KX134_EXPECTED_HEADER,
        KX134_EXPECTED_RANGE_G,
        KX134_FIRMWARE_CONFIGURATION_NOTE,
        KX134_FIRMWARE_CONFIGURATION_SENT,
        KX134_PROTOCOL_VERSION,
        KX134_SESSION_TYPE,
        KX134_TOPOLOGY_VERSION,
        KX134_TOTAL_ESP32_REQUIRED,
        expected_field_count,
        has_forbidden_kx134_fields,
        is_kx134_header,
    )
except ImportError:  # pragma: no cover - direct script execution support
    from kx134_stream_contract import (
        KX134_ALLOWED_RANGE_G,
        KX134_ALLOWED_SAMPLE_RATES,
        KX134_DEFAULT_BAUD,
        KX134_DEFAULT_SERIAL_WARMUP_S,
        KX134_DEFAULT_SAMPLE_RATE_HZ,
        KX134_EXPECTED_HEADER,
        KX134_EXPECTED_RANGE_G,
        KX134_FIRMWARE_CONFIGURATION_NOTE,
        KX134_FIRMWARE_CONFIGURATION_SENT,
        KX134_PROTOCOL_VERSION,
        KX134_SESSION_TYPE,
        KX134_TOPOLOGY_VERSION,
        KX134_TOTAL_ESP32_REQUIRED,
        expected_field_count,
        has_forbidden_kx134_fields,
        is_kx134_header,
    )


@dataclass
class Kx134ParsedLine:
    kind: str
    text: str = ""
    row: dict[str, object] | None = None
    error: str = ""
    sample: "Kx134Sample | None" = None


@dataclass
class Kx134Sample:
    protocol_version: str
    session_id: str
    sensor_id: int
    physical_label: str
    node_id: str
    node_mac: str
    seq: int
    sensor_t_us: int
    receiver_t_us: int
    pc_wall_s: float
    sync_group_id: str
    pair_seq: int
    x_raw: int
    y_raw: int
    z_raw: int
    x_g: float
    y_g: float
    z_g: float
    sample_rate_hz: int
    odr_hz: int
    range_g: int
    calibration_id: str
    calibration_applied: bool
    packet_status: str
    packet_error_code: str
    firmware_version: str
    contract_version: str


@dataclass
class Kx134SessionArtifacts:
    raw_csv_abs: Path
    session_json_abs: Path
    summary_abs: Path


@dataclass
class Kx134SessionResult:
    artifacts: Kx134SessionArtifacts
    samples: list[Kx134Sample]
    metadata_lines: list[str]
    header_seen: bool
    invalid_lines: int
    parse_errors: dict[str, int]
    summary: dict[str, object]
    warnings: list[str] = field(default_factory=list)


@dataclass
class Kx134CaptureConfig:
    port: str
    baud: int = KX134_DEFAULT_BAUD
    duration_s: float = 10.0
    warmup_s: float = KX134_DEFAULT_SERIAL_WARMUP_S
    expected_sample_rate_hz: int = KX134_DEFAULT_SAMPLE_RATE_HZ
    output_root: Path = Path(".")
    session_name: str = "kx134_live"
    file_prefix: str = "kx134_dual_live"
    raw_dir_relpath: str = "data/raw/kx134_dual_live"
    metadata_dir_relpath: str = "data/processed/kx134_dual_live"
    summary_dir_relpath: str = "reports/analysis_outputs/kx134_dual_live"


def _decode_line(line: str | bytes | None) -> str:
    if line is None:
        return ""
    if isinstance(line, bytes):
        return line.decode("utf-8", errors="ignore").strip().lstrip("\ufeff")
    return str(line).strip().lstrip("\ufeff")


def _parse_bool(text: str) -> bool:
    value = str(text).strip().lower()
    if value == "true":
        return True
    if value == "false":
        return False
    raise ValueError("bad_calibration_applied")


def _parse_int(text: str, field_name: str) -> int:
    if str(text).strip() == "":
        raise ValueError(f"missing_{field_name}")
    return int(str(text).strip())


def _parse_float(text: str, field_name: str) -> float:
    if str(text).strip() == "":
        raise ValueError(f"missing_{field_name}")
    return float(str(text).strip())


def parse_kx134_stream_line(line: str | bytes | None) -> Kx134ParsedLine:
    text = _decode_line(line)
    if not text:
        return Kx134ParsedLine(kind="empty")

    if text.startswith("#"):
        return Kx134ParsedLine(kind="metadata", text=text)

    if has_forbidden_kx134_fields(text):
        return Kx134ParsedLine(kind="invalid", text=text, error="forbidden_kx134_field")

    if is_kx134_header(text):
        return Kx134ParsedLine(kind="header", text=text)

    tokens = [token.strip() for token in text.split(",")]
    if len(tokens) != expected_field_count():
        return Kx134ParsedLine(kind="invalid", text=text, error="bad_field_count")

    try:
        sample = Kx134Sample(
            protocol_version=tokens[0],
            session_id=tokens[1],
            sensor_id=_parse_int(tokens[2], "sensor_id"),
            physical_label=tokens[3],
            node_id=tokens[4],
            node_mac=tokens[5],
            seq=_parse_int(tokens[6], "seq"),
            sensor_t_us=_parse_int(tokens[7], "sensor_t_us"),
            receiver_t_us=_parse_int(tokens[8], "receiver_t_us"),
            pc_wall_s=_parse_float(tokens[9], "pc_wall_s"),
            sync_group_id=tokens[10],
            pair_seq=_parse_int(tokens[11], "pair_seq"),
            x_raw=_parse_int(tokens[12], "x_raw"),
            y_raw=_parse_int(tokens[13], "y_raw"),
            z_raw=_parse_int(tokens[14], "z_raw"),
            x_g=_parse_float(tokens[15], "x_g"),
            y_g=_parse_float(tokens[16], "y_g"),
            z_g=_parse_float(tokens[17], "z_g"),
            sample_rate_hz=_parse_int(tokens[18], "sample_rate_hz"),
            odr_hz=_parse_int(tokens[19], "odr_hz"),
            range_g=_parse_int(tokens[20], "range_g"),
            calibration_id=tokens[21],
            calibration_applied=_parse_bool(tokens[22]),
            packet_status=tokens[23],
            packet_error_code=tokens[24],
            firmware_version=tokens[25],
            contract_version=tokens[26],
        )
    except (TypeError, ValueError) as exc:
        return Kx134ParsedLine(kind="invalid", text=text, error=str(exc))

    if sample.protocol_version != KX134_PROTOCOL_VERSION:
        return Kx134ParsedLine(kind="invalid", text=text, error="bad_protocol_version")
    if sample.contract_version != KX134_PROTOCOL_VERSION:
        return Kx134ParsedLine(kind="invalid", text=text, error="bad_contract_version")
    if sample.sensor_id not in (1, 2):
        return Kx134ParsedLine(kind="invalid", text=text, error="unsupported_sensor_id")
    if not sample.node_mac.strip():
        return Kx134ParsedLine(kind="invalid", text=text, error="missing_node_mac")
    if sample.sample_rate_hz not in KX134_ALLOWED_SAMPLE_RATES:
        return Kx134ParsedLine(kind="invalid", text=text, error="unsupported_sample_rate")
    if sample.range_g not in KX134_ALLOWED_RANGE_G:
        return Kx134ParsedLine(kind="invalid", text=text, error="unsupported_range_g")

    return Kx134ParsedLine(
        kind="data",
        text=text,
        row=kx134_sample_to_raw_row(sample),
        sample=sample,
    )


def kx134_sample_to_raw_row(sample: Kx134Sample) -> dict[str, object]:
    return {
        "protocol_version": sample.protocol_version,
        "session_id": sample.session_id,
        "sensor_id": sample.sensor_id,
        "physical_label": sample.physical_label,
        "node_id": sample.node_id,
        "node_mac": sample.node_mac,
        "seq": sample.seq,
        "sensor_t_us": sample.sensor_t_us,
        "receiver_t_us": sample.receiver_t_us,
        "pc_wall_s": round(sample.pc_wall_s, 9),
        "sync_group_id": sample.sync_group_id,
        "pair_seq": sample.pair_seq,
        "x_raw": sample.x_raw,
        "y_raw": sample.y_raw,
        "z_raw": sample.z_raw,
        "x_g": round(sample.x_g, 9),
        "y_g": round(sample.y_g, 9),
        "z_g": round(sample.z_g, 9),
        "sample_rate_hz": sample.sample_rate_hz,
        "odr_hz": sample.odr_hz,
        "range_g": sample.range_g,
        "calibration_id": sample.calibration_id,
        "calibration_applied": str(sample.calibration_applied).lower(),
        "packet_status": sample.packet_status,
        "packet_error_code": sample.packet_error_code,
        "firmware_version": sample.firmware_version,
        "contract_version": sample.contract_version,
    }


def _seq_gap_count(samples: list[Kx134Sample]) -> int:
    gaps = 0
    ordered = sorted(samples, key=lambda item: item.seq)
    for previous, current in zip(ordered, ordered[1:]):
        if current.seq > previous.seq + 1:
            gaps += current.seq - previous.seq - 1
    return gaps


def _timestamp_error_count(samples: list[Kx134Sample], field_name: str) -> int:
    values = [int(getattr(sample, field_name)) for sample in samples]
    return sum(1 for previous, current in zip(values, values[1:]) if current <= previous)


def _effective_hz(samples: list[Kx134Sample]) -> float:
    if len(samples) < 2:
        return 0.0
    ordered = sorted(samples, key=lambda item: item.sensor_t_us)
    delta_s = (ordered[-1].sensor_t_us - ordered[0].sensor_t_us) / 1_000_000.0
    if delta_s <= 0:
        return 0.0
    return (len(ordered) - 1) / delta_s


def _g_norm_values(samples: list[Kx134Sample]) -> list[float]:
    return [
        math.sqrt(sample.x_g * sample.x_g + sample.y_g * sample.y_g + sample.z_g * sample.z_g)
        for sample in samples
    ]


def summarize_kx134_samples(samples: list[Kx134Sample]) -> dict[str, object]:
    grouped: dict[int, list[Kx134Sample]] = {1: [], 2: []}
    for sample in samples:
        grouped.setdefault(sample.sensor_id, []).append(sample)

    samples_by_sensor = {str(sensor_id): len(rows) for sensor_id, rows in sorted(grouped.items())}
    seq_gaps_by_sensor = {
        str(sensor_id): _seq_gap_count(rows) for sensor_id, rows in sorted(grouped.items())
    }
    timestamp_errors_by_sensor = {
        str(sensor_id): _timestamp_error_count(rows, "sensor_t_us")
        for sensor_id, rows in sorted(grouped.items())
    }
    receiver_timestamp_errors_by_sensor = {
        str(sensor_id): _timestamp_error_count(rows, "receiver_t_us")
        for sensor_id, rows in sorted(grouped.items())
    }
    effective_hz_by_sensor = {
        str(sensor_id): _effective_hz(rows) for sensor_id, rows in sorted(grouped.items())
    }

    duplicate_keys_by_sensor: dict[str, int] = {}
    for sensor_id, rows in sorted(grouped.items()):
        keys = [(row.sensor_id, row.node_mac, row.seq) for row in rows]
        duplicate_keys_by_sensor[str(sensor_id)] = sum(
            count - 1 for count in Counter(keys).values() if count > 1
        )

    g_norm_mean_by_sensor: dict[str, float] = {}
    g_norm_min_by_sensor: dict[str, float] = {}
    g_norm_max_by_sensor: dict[str, float] = {}
    for sensor_id, rows in sorted(grouped.items()):
        values = _g_norm_values(rows)
        if values:
            g_norm_mean_by_sensor[str(sensor_id)] = mean(values)
            g_norm_min_by_sensor[str(sensor_id)] = min(values)
            g_norm_max_by_sensor[str(sensor_id)] = max(values)
        else:
            g_norm_mean_by_sensor[str(sensor_id)] = None
            g_norm_min_by_sensor[str(sensor_id)] = None
            g_norm_max_by_sensor[str(sensor_id)] = None

    return {
        "total_samples": len(samples),
        "samples_by_sensor": samples_by_sensor,
        "seq_gaps_by_sensor": seq_gaps_by_sensor,
        "timestamp_errors_by_sensor": timestamp_errors_by_sensor,
        "receiver_timestamp_errors": sum(receiver_timestamp_errors_by_sensor.values()),
        "receiver_timestamp_errors_by_sensor": receiver_timestamp_errors_by_sensor,
        "effective_hz_by_sensor": effective_hz_by_sensor,
        "packet_status_counts": dict(Counter(sample.packet_status for sample in samples)),
        "packet_error_code_counts": dict(Counter(sample.packet_error_code for sample in samples)),
        "duplicate_keys_by_sensor": duplicate_keys_by_sensor,
        "forbidden_fields_detected": False,
        "g_norm_mean_by_sensor": g_norm_mean_by_sensor,
        "g_norm_min_by_sensor": g_norm_min_by_sensor,
        "g_norm_max_by_sensor": g_norm_max_by_sensor,
    }


def validate_capture_duration(duration_s: object) -> float:
    try:
        value = float(duration_s)
    except (TypeError, ValueError) as exc:
        raise ValueError("duration_s must be a positive number") from exc
    if value <= 0:
        raise ValueError("duration_s must be greater than zero")
    return value


def validate_expected_sample_rate(expected_sample_rate_hz: object) -> int:
    try:
        value = int(expected_sample_rate_hz)
    except (TypeError, ValueError) as exc:
        raise ValueError("expected_sample_rate_hz must be one of 100, 200, 400, 800") from exc
    if value not in KX134_ALLOWED_SAMPLE_RATES:
        raise ValueError("expected_sample_rate_hz must be one of 100, 200, 400, 800")
    return value


def _session_base_name(session_name: str, file_prefix: str) -> str:
    safe_session = "".join(ch if ch.isalnum() or ch in "-_" else "_" for ch in session_name)
    stamp = time.strftime("%Y%m%d_%H%M%S")
    return f"{file_prefix}_{safe_session}_{stamp}"


def _utc_now_iso() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z")


def _relative_path(path: Path, root: Path) -> str:
    try:
        return path.resolve().relative_to(root.resolve()).as_posix()
    except ValueError:
        return path.resolve().as_posix()


def _first_sample_for_sensor(samples: list[Kx134Sample], sensor_id: int) -> Kx134Sample | None:
    return next((sample for sample in samples if sample.sensor_id == sensor_id), None)


def _metadata_token(metadata_lines: list[str], key: str) -> str:
    prefix = f"{key}="
    for line in metadata_lines:
        for token in str(line).lstrip("#").split(","):
            token = token.strip()
            if token.startswith(prefix):
                return token[len(prefix) :]
    return ""


def _node_identity(
    samples: list[Kx134Sample],
    *,
    sensor_id: int,
    fallback_label: str,
    fallback_node_id: str,
    fallback_mac: str,
    fallback_calibration_id: str,
) -> dict[str, object]:
    sample = _first_sample_for_sensor(samples, sensor_id)
    calibration_id = sample.calibration_id if sample else fallback_calibration_id
    return {
        "sensor_id": sensor_id,
        "physical_label": sample.physical_label if sample else fallback_label,
        "node_id": sample.node_id if sample else fallback_node_id,
        "node_mac": sample.node_mac if sample else fallback_mac,
        "calibration_id": calibration_id,
        "calibration_file": f"config/calibrations/{calibration_id}.json",
        "status": "validated_for_gui_export",
    }


def _receiver_identity(samples: list[Kx134Sample], metadata_lines: list[str]) -> dict[str, object]:
    first_sample = samples[0] if samples else None
    firmware_version = first_sample.firmware_version if first_sample else _metadata_token(
        metadata_lines, "firmware_version"
    )
    return {
        "node_id": "receiver_esp32",
        "node_mac": "00:4B:12:96:9A:80",
        "receiver_firmware": "kx134_dual_espnow",
        "receiver_firmware_version": firmware_version or "kx134_dual_espnow.0.1.0",
        "espnow_channel": 1,
        "status": "validated_for_gui_export",
    }


def _pc_wall_s_positive(samples: list[Kx134Sample]) -> bool:
    return bool(samples) and all(sample.pc_wall_s > 0 for sample in samples)


def _receiver_t_us_valid(samples: list[Kx134Sample]) -> bool:
    return bool(samples) and all(sample.receiver_t_us > 0 for sample in samples)


def _capture_duration_from_samples(samples: list[Kx134Sample]) -> float:
    if len(samples) < 2:
        return 0.0
    values = [sample.pc_wall_s for sample in samples]
    return max(values) - min(values)


def _session_decision(
    summary: dict[str, object],
    *,
    invalid_lines: int,
    warnings: list[str],
    expected_sample_rate_hz: int,
) -> dict[str, object]:
    samples_by_sensor = summary.get("samples_by_sensor", {})
    hz_by_sensor = summary.get("effective_hz_by_sensor", {})
    seq_gaps = summary.get("seq_gaps_by_sensor", {})
    duplicate_keys = summary.get("duplicate_keys_by_sensor", {})
    packet_status = summary.get("packet_status_counts", {})
    packet_errors = summary.get("packet_error_code_counts", {})
    failures: list[str] = []
    for sensor_id in ("1", "2"):
        if int(samples_by_sensor.get(sensor_id, 0)) <= 0:
            failures.append(f"sensor_{sensor_id}_missing")
        hz = float(hz_by_sensor.get(sensor_id, 0.0) or 0.0)
        if samples_by_sensor.get(sensor_id, 0) and expected_sample_rate_hz == 100 and not (
            98.0 <= hz <= 102.0
        ):
            failures.append(f"sensor_{sensor_id}_effective_hz_out_of_range")
        if int(seq_gaps.get(sensor_id, 0) or 0) > 0:
            failures.append(f"sensor_{sensor_id}_seq_gaps")
        if int(duplicate_keys.get(sensor_id, 0) or 0) > 0:
            failures.append(f"sensor_{sensor_id}_duplicate_keys")
    if invalid_lines:
        failures.append("invalid_lines_present")
    if any(key != "OK" for key in packet_status):
        failures.append("packet_status_not_ok")
    if any(key != "OK" for key in packet_errors):
        failures.append("packet_error_code_not_ok")
    if summary.get("forbidden_fields_detected"):
        failures.append("forbidden_fields_detected")
    return {
        "session_valid": not failures,
        "decision": "PASS" if not failures else "FAIL",
        "failures": failures,
        "warnings": warnings,
    }


def export_kx134_session(
    *,
    samples: list[Kx134Sample],
    metadata_lines: list[str],
    output_root: str | Path,
    session_name: str,
    expected_sample_rate_hz: int = KX134_DEFAULT_SAMPLE_RATE_HZ,
    port: str = "",
    baud: int = KX134_DEFAULT_BAUD,
    invalid_lines: int = 0,
    parse_errors: dict[str, int] | None = None,
    warnings: list[str] | None = None,
    file_prefix: str = "kx134_dual_live",
    raw_dir_relpath: str = "data/raw/kx134_dual_live",
    metadata_dir_relpath: str = "data/processed/kx134_dual_live",
    summary_dir_relpath: str = "reports/analysis_outputs/kx134_dual_live",
    started_at_iso: str | None = None,
    ended_at_iso: str | None = None,
    capture_duration_requested_s: float | None = None,
    capture_duration_actual_s: float | None = None,
    serial_warmup_s: float = KX134_DEFAULT_SERIAL_WARMUP_S,
    expected_range_g: int = KX134_EXPECTED_RANGE_G,
    expected_odr_hz: int | None = None,
) -> Kx134SessionResult:
    expected_sample_rate_hz = validate_expected_sample_rate(expected_sample_rate_hz)
    output_root = Path(output_root).resolve()
    raw_dir = output_root / raw_dir_relpath
    metadata_dir = output_root / metadata_dir_relpath
    summary_dir = output_root / summary_dir_relpath
    raw_dir.mkdir(parents=True, exist_ok=True)
    metadata_dir.mkdir(parents=True, exist_ok=True)
    summary_dir.mkdir(parents=True, exist_ok=True)

    base_name = _session_base_name(session_name, file_prefix)
    artifacts = Kx134SessionArtifacts(
        raw_csv_abs=raw_dir / f"{base_name}_raw.csv",
        session_json_abs=metadata_dir / f"{base_name}_session.json",
        summary_abs=summary_dir / f"{base_name}_summary.md",
    )

    with artifacts.raw_csv_abs.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=KX134_EXPECTED_HEADER)
        writer.writeheader()
        for sample in samples:
            writer.writerow(kx134_sample_to_raw_row(sample))

    summary = summarize_kx134_samples(samples)
    summary["valid_samples_total"] = summary["total_samples"]
    summary["invalid_lines"] = invalid_lines
    summary["metadata_lines"] = len(metadata_lines)
    summary["receiver_t_us_valid"] = _receiver_t_us_valid(samples)
    summary["pc_wall_s_positive"] = _pc_wall_s_positive(samples)
    stream_rates = sorted({sample.sample_rate_hz for sample in samples})
    warnings = list(warnings or [])
    if stream_rates and any(rate != expected_sample_rate_hz for rate in stream_rates):
        warnings.append(
            "stream_sample_rate_differs_from_expected:"
            + ",".join(str(rate) for rate in stream_rates)
        )
    if expected_odr_hz is None:
        expected_odr_hz = expected_sample_rate_hz
    created_at_iso = _utc_now_iso()
    started_at_iso = started_at_iso or created_at_iso
    ended_at_iso = ended_at_iso or created_at_iso
    if capture_duration_requested_s is None:
        capture_duration_requested_s = _capture_duration_from_samples(samples)
    if capture_duration_actual_s is None:
        capture_duration_actual_s = _capture_duration_from_samples(samples)

    raw_rel_session = _relative_path(artifacts.raw_csv_abs, output_root)
    json_rel_session = _relative_path(artifacts.session_json_abs, output_root)
    summary_rel_session = _relative_path(artifacts.summary_abs, output_root)
    artifact_paths_exist = {
        "raw_csv": True,
        "session_json": True,
        "summary_md": True,
    }
    decision = _session_decision(
        summary,
        invalid_lines=invalid_lines,
        warnings=warnings,
        expected_sample_rate_hz=expected_sample_rate_hz,
    )

    nodes_expected = {
        "sensor_1": _node_identity(
            samples,
            sensor_id=1,
            fallback_label="KX134_SENSOR_1",
            fallback_node_id="sensor_node_1",
            fallback_mac="D4:E9:F4:E9:8E:1C",
            fallback_calibration_id="kx134_sensor_1_20260508_234831",
        ),
        "sensor_2": _node_identity(
            samples,
            sensor_id=2,
            fallback_label="KX134_SENSOR_2",
            fallback_node_id="sensor_node_2",
            fallback_mac="D4:E9:F4:C3:37:14",
            fallback_calibration_id="kx134_sensor_2_20260509_180839",
        ),
        "receiver": _receiver_identity(samples, metadata_lines),
    }

    artifacts_payload = {
        "raw_csv": str(artifacts.raw_csv_abs),
        "session_json": str(artifacts.session_json_abs),
        "summary": str(artifacts.summary_abs),
        "summary_md": str(artifacts.summary_abs),
        "relative_to_session_root": {
            "raw_csv": raw_rel_session,
            "session_json": json_rel_session,
            "summary_md": summary_rel_session,
        },
        "artifacts_relative_to_session_root": True,
        "artifact_paths_exist": artifact_paths_exist,
    }

    payload = {
        "session_id": base_name,
        "source_stream_session_id": samples[0].session_id if samples else "",
        "session_name": session_name,
        "session_type": KX134_SESSION_TYPE,
        "protocol_version": KX134_PROTOCOL_VERSION,
        "contract_version": KX134_PROTOCOL_VERSION,
        "created_at_iso": created_at_iso,
        "started_at_iso": started_at_iso,
        "ended_at_iso": ended_at_iso,
        "capture_duration_requested_s": capture_duration_requested_s,
        "capture_duration_actual_s": capture_duration_actual_s,
        "timestamp_basis": (
            "pc_wall_s uses PC perf_counter seconds since GUI capture start; "
            "receiver_t_us is receiver micros; sensor_t_us clocks are per ESP32 node."
        ),
        "port": port,
        "baud": baud,
        "expected_sample_rate_hz": expected_sample_rate_hz,
        "allowed_sample_rates_hz": KX134_ALLOWED_SAMPLE_RATES,
        "expected_range_g": expected_range_g,
        "expected_odr_hz": expected_odr_hz,
        "serial_warmup_s": serial_warmup_s,
        "firmware_configuration_sent": KX134_FIRMWARE_CONFIGURATION_SENT,
        "firmware_configuration_note": KX134_FIRMWARE_CONFIGURATION_NOTE,
        "topology_version": KX134_TOPOLOGY_VERSION,
        "total_esp32_required": KX134_TOTAL_ESP32_REQUIRED,
        "transport": {
            "sensor_nodes_to_receiver": "ESP-NOW",
            "receiver_to_pc_gui": "USB Serial",
        },
        "nodes_expected": nodes_expected,
        "metadata_lines": metadata_lines,
        "metadata_line_count": len(metadata_lines),
        "invalid_lines": invalid_lines,
        "parse_errors": parse_errors or {},
        "warnings": warnings,
        "summary": summary,
        "capture_summary": summary,
        "decision": decision,
        "artifacts": artifacts_payload,
        "artifacts_relative_to_session_root": artifacts_payload["relative_to_session_root"],
        "artifact_paths_exist": artifact_paths_exist,
    }
    with artifacts.session_json_abs.open("w", encoding="utf-8") as handle:
        json.dump(payload, handle, indent=2, ensure_ascii=True)

    with artifacts.summary_abs.open("w", encoding="utf-8") as handle:
        handle.write("# KX134 dual live session summary\n\n")
        handle.write("## Session\n\n")
        handle.write(f"- session_id: `{base_name}`\n")
        handle.write(f"- session_name: `{session_name}`\n")
        handle.write(f"- protocol_version: `{KX134_PROTOCOL_VERSION}`\n")
        handle.write(f"- expected_sample_rate_hz: `{expected_sample_rate_hz}`\n")
        handle.write(f"- expected_range_g: `{expected_range_g}`\n")
        handle.write(f"- capture_duration_requested_s: `{capture_duration_requested_s}`\n")
        handle.write(f"- capture_duration_actual_s: `{capture_duration_actual_s}`\n")
        handle.write(f"- invalid_lines: `{invalid_lines}`\n")
        handle.write(f"- metadata_lines: `{len(metadata_lines)}`\n")
        handle.write(f"- receiver_t_us_valid: `{summary['receiver_t_us_valid']}`\n")
        handle.write(f"- pc_wall_s_positive: `{summary['pc_wall_s_positive']}`\n\n")
        handle.write("## Sensor Table\n\n")
        handle.write(
            "| Sensor | Rows | Effective Hz | Seq gaps | Timestamp errors | "
            "Receiver timestamp errors | Duplicate keys |\n"
        )
        handle.write("|---|---:|---:|---:|---:|---:|---:|\n")
        for sensor_id in ("1", "2"):
            handle.write(
                f"| Sensor {sensor_id} | {summary['samples_by_sensor'].get(sensor_id, 0)} | "
                f"{float(summary['effective_hz_by_sensor'].get(sensor_id, 0.0) or 0.0):.6f} | "
                f"{summary['seq_gaps_by_sensor'].get(sensor_id, 0)} | "
                f"{summary['timestamp_errors_by_sensor'].get(sensor_id, 0)} | "
                f"{summary['receiver_timestamp_errors_by_sensor'].get(sensor_id, 0)} | "
                f"{summary['duplicate_keys_by_sensor'].get(sensor_id, 0)} |\n"
            )
        handle.write("\n## Packet Counts\n\n")
        handle.write(f"- packet_status_counts: `{summary['packet_status_counts']}`\n")
        handle.write(f"- packet_error_code_counts: `{summary['packet_error_code_counts']}`\n")
        handle.write(f"- forbidden_fields_detected: `{summary['forbidden_fields_detected']}`\n")
        handle.write(f"- warnings: `{warnings}`\n\n")
        handle.write("## Artifacts\n\n")
        handle.write(f"- raw_csv: `{raw_rel_session}`\n")
        handle.write(f"- session_json: `{json_rel_session}`\n")
        handle.write(f"- summary_md: `{summary_rel_session}`\n\n")
        handle.write("## Decision\n\n")
        handle.write(f"- session_valid: `{decision['session_valid']}`\n")
        handle.write(f"- decision: `{decision['decision']}`\n")
        handle.write(f"- failures: `{decision['failures']}`\n")

    return Kx134SessionResult(
        artifacts=artifacts,
        samples=samples,
        metadata_lines=metadata_lines,
        header_seen=False,
        invalid_lines=invalid_lines,
        parse_errors=parse_errors or {},
        summary=summary,
        warnings=warnings,
    )


def capture_kx134_serial_session(
    *,
    port: str,
    baud: int = KX134_DEFAULT_BAUD,
    duration_s: float = 10.0,
    warmup_s: float = 2.0,
    expected_sample_rate_hz: int = KX134_DEFAULT_SAMPLE_RATE_HZ,
    output_root: str | Path = ".",
    session_name: str = "kx134_live",
    progress_callback: Callable[[str, dict[str, object]], None] | None = None,
    progress_interval_s: float = 0.2,
) -> Kx134SessionResult:
    if not str(port or "").strip():
        raise ValueError("port is required")
    duration_s = validate_capture_duration(duration_s)
    warmup_s = float(warmup_s)
    if warmup_s < 0:
        raise ValueError("warmup_s must be zero or positive")
    expected_sample_rate_hz = validate_expected_sample_rate(expected_sample_rate_hz)

    try:
        import serial
    except ModuleNotFoundError as exc:  # pragma: no cover - user-facing
        raise RuntimeError("pyserial is required for live KX134 capture") from exc

    samples: list[Kx134Sample] = []
    metadata_lines: list[str] = []
    parse_errors: Counter[str] = Counter()
    invalid_lines = 0
    header_seen = False
    pending_batch: list[Kx134Sample] = []
    live_counts: Counter[str] = Counter()
    live_duplicate_keys: Counter[str] = Counter()
    live_seen_keys: dict[int, set[tuple[int, str, int]]] = {1: set(), 2: set()}

    def emit_progress(event_type: str, payload: dict[str, object]) -> None:
        if progress_callback:
            progress_callback(event_type, payload)

    def emit_live_batch(*, elapsed_s: float, force: bool = False) -> None:
        nonlocal pending_batch
        if not pending_batch and not force:
            return
        remaining_s = max(duration_s - elapsed_s, 0.0)
        payload: dict[str, object] = {
            "samples": list(pending_batch),
            "emitted_at_s": elapsed_s,
            "elapsed_s": elapsed_s,
            "remaining_s": remaining_s,
            "percent": min(max((elapsed_s / duration_s) * 100.0, 0.0), 100.0) if duration_s else 100.0,
            "samples_by_sensor": dict(live_counts),
            "invalid_lines": invalid_lines,
            "duplicate_keys_by_sensor": dict(live_duplicate_keys),
        }
        if pending_batch:
            emit_progress("sample_batch", payload)
            pending_batch = []
        emit_progress(
            "capture_progress",
            {
                key: value
                for key, value in payload.items()
                if key != "samples"
            },
        )

    with serial.Serial(str(port), baudrate=int(baud), timeout=0.2) as ser:
        ser.reset_input_buffer()
        warmup_start = time.perf_counter()
        while time.perf_counter() - warmup_start < warmup_s:
            parsed = parse_kx134_stream_line(ser.readline())
            if parsed.kind == "metadata":
                metadata_lines.append(parsed.text)
            elif parsed.kind == "header":
                header_seen = True

        started_at_iso = _utc_now_iso()
        start_time = time.perf_counter()
        last_progress_emit = start_time
        while time.perf_counter() - start_time < duration_s:
            parsed = parse_kx134_stream_line(ser.readline())
            now = time.perf_counter()
            elapsed = now - start_time
            if parsed.kind == "metadata":
                metadata_lines.append(parsed.text)
            elif parsed.kind == "header":
                header_seen = True
            elif parsed.kind == "data" and parsed.sample is not None:
                sample = replace(parsed.sample, pc_wall_s=elapsed)
                samples.append(sample)
                pending_batch.append(sample)
                sensor_key = str(sample.sensor_id)
                live_counts[sensor_key] += 1
                duplicate_key = (sample.sensor_id, sample.node_mac, sample.seq)
                if duplicate_key in live_seen_keys.setdefault(sample.sensor_id, set()):
                    live_duplicate_keys[sensor_key] += 1
                else:
                    live_seen_keys.setdefault(sample.sensor_id, set()).add(duplicate_key)
            elif parsed.kind == "invalid":
                invalid_lines += 1
                parse_errors[parsed.error or "invalid"] += 1
            if now - last_progress_emit >= progress_interval_s:
                emit_live_batch(elapsed_s=elapsed)
                last_progress_emit = now
        capture_duration_actual_s = time.perf_counter() - start_time
        emit_live_batch(elapsed_s=capture_duration_actual_s, force=True)
        ended_at_iso = _utc_now_iso()

    result = export_kx134_session(
        samples=samples,
        metadata_lines=metadata_lines,
        output_root=output_root,
        session_name=session_name,
        expected_sample_rate_hz=expected_sample_rate_hz,
        port=port,
        baud=int(baud),
        invalid_lines=invalid_lines,
        parse_errors=dict(parse_errors),
        started_at_iso=started_at_iso,
        ended_at_iso=ended_at_iso,
        capture_duration_requested_s=duration_s,
        capture_duration_actual_s=capture_duration_actual_s,
        serial_warmup_s=warmup_s,
    )
    result.header_seen = header_seen
    return result


class Kx134CaptureWorker(threading.Thread):
    def __init__(
        self,
        config: Kx134CaptureConfig,
        event_callback: Callable[[str, dict[str, object]], None],
    ) -> None:
        super().__init__(daemon=True)
        self.config = config
        self.event_callback = event_callback

    def emit(self, event_type: str, **payload: object) -> None:
        self.event_callback(event_type, payload)

    def run(self) -> None:  # pragma: no cover - exercised by GUI
        try:
            result = capture_kx134_serial_session(
                port=self.config.port,
                baud=self.config.baud,
                duration_s=self.config.duration_s,
                warmup_s=self.config.warmup_s,
                expected_sample_rate_hz=self.config.expected_sample_rate_hz,
                output_root=self.config.output_root,
                session_name=self.config.session_name,
                progress_callback=lambda event_type, payload: self.emit(event_type, **payload),
            )
            self.emit("session_complete", result=result)
        except Exception as exc:
            self.emit("session_error", message=str(exc), traceback=traceback.format_exc())

from __future__ import annotations

import csv
import json
import math
import threading
import time
import traceback
from collections import Counter
from dataclasses import asdict, dataclass, field, replace
from pathlib import Path
from statistics import mean
from typing import Callable

try:
    from .kx134_stream_contract import (
        KX134_ALLOWED_RANGE_G,
        KX134_ALLOWED_SAMPLE_RATES,
        KX134_DEFAULT_BAUD,
        KX134_DEFAULT_SAMPLE_RATE_HZ,
        KX134_EXPECTED_HEADER,
        KX134_PROTOCOL_VERSION,
        expected_field_count,
        has_forbidden_kx134_fields,
        is_kx134_header,
    )
except ImportError:  # pragma: no cover - direct script execution support
    from kx134_stream_contract import (
        KX134_ALLOWED_RANGE_G,
        KX134_ALLOWED_SAMPLE_RATES,
        KX134_DEFAULT_BAUD,
        KX134_DEFAULT_SAMPLE_RATE_HZ,
        KX134_EXPECTED_HEADER,
        KX134_PROTOCOL_VERSION,
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
        "pc_wall_s": round(sample.pc_wall_s, 6),
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
            g_norm_mean_by_sensor[str(sensor_id)] = math.nan
            g_norm_min_by_sensor[str(sensor_id)] = math.nan
            g_norm_max_by_sensor[str(sensor_id)] = math.nan

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
    stream_rates = sorted({sample.sample_rate_hz for sample in samples})
    warnings = list(warnings or [])
    if stream_rates and any(rate != expected_sample_rate_hz for rate in stream_rates):
        warnings.append(
            "stream_sample_rate_differs_from_expected:"
            + ",".join(str(rate) for rate in stream_rates)
        )

    payload = {
        "session_name": session_name,
        "protocol_version": KX134_PROTOCOL_VERSION,
        "port": port,
        "baud": baud,
        "expected_sample_rate_hz": expected_sample_rate_hz,
        "metadata_lines": metadata_lines,
        "invalid_lines": invalid_lines,
        "parse_errors": parse_errors or {},
        "warnings": warnings,
        "summary": summary,
        "artifacts": {
            "raw_csv": str(artifacts.raw_csv_abs),
            "session_json": str(artifacts.session_json_abs),
            "summary": str(artifacts.summary_abs),
        },
    }
    with artifacts.session_json_abs.open("w", encoding="utf-8") as handle:
        json.dump(payload, handle, indent=2, ensure_ascii=True)

    with artifacts.summary_abs.open("w", encoding="utf-8") as handle:
        handle.write("# KX134 dual live session summary\n\n")
        handle.write(f"- session_name: `{session_name}`\n")
        handle.write(f"- protocol_version: `{KX134_PROTOCOL_VERSION}`\n")
        handle.write(f"- expected_sample_rate_hz: `{expected_sample_rate_hz}`\n")
        handle.write(f"- total_samples: `{summary['total_samples']}`\n")
        handle.write(f"- invalid_lines: `{invalid_lines}`\n")
        handle.write(f"- samples_by_sensor: `{summary['samples_by_sensor']}`\n")
        handle.write(f"- seq_gaps_by_sensor: `{summary['seq_gaps_by_sensor']}`\n")
        handle.write(f"- effective_hz_by_sensor: `{summary['effective_hz_by_sensor']}`\n")
        handle.write(f"- duplicate_keys_by_sensor: `{summary['duplicate_keys_by_sensor']}`\n")
        handle.write(f"- warnings: `{warnings}`\n")

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
    expected_sample_rate_hz: int = KX134_DEFAULT_SAMPLE_RATE_HZ,
    output_root: str | Path = ".",
    session_name: str = "kx134_live",
) -> Kx134SessionResult:
    if not str(port or "").strip():
        raise ValueError("port is required")
    duration_s = validate_capture_duration(duration_s)
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
    start_time = time.monotonic()

    with serial.Serial(str(port), baudrate=int(baud), timeout=0.2) as ser:
        ser.reset_input_buffer()
        while time.monotonic() - start_time < duration_s:
            parsed = parse_kx134_stream_line(ser.readline())
            if parsed.kind == "metadata":
                metadata_lines.append(parsed.text)
            elif parsed.kind == "header":
                header_seen = True
            elif parsed.kind == "data" and parsed.sample is not None:
                elapsed = time.monotonic() - start_time
                samples.append(replace(parsed.sample, pc_wall_s=elapsed))
            elif parsed.kind == "invalid":
                invalid_lines += 1
                parse_errors[parsed.error or "invalid"] += 1

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
                expected_sample_rate_hz=self.config.expected_sample_rate_hz,
                output_root=self.config.output_root,
                session_name=self.config.session_name,
            )
            self.emit("session_complete", result=result)
        except Exception as exc:
            self.emit("session_error", message=str(exc), traceback=traceback.format_exc())

from __future__ import annotations

import csv
import json
import math
import threading
import time
import traceback
from dataclasses import asdict, dataclass, field
from pathlib import Path
from statistics import median
from typing import Callable

try:
    import serial
    from serial.tools import list_ports
except ModuleNotFoundError as exc:  # pragma: no cover - import failure is user-facing
    raise RuntimeError(
        "pyserial no esta instalado. Ejecute scripts/install_gui_requirements.ps1 "
        "o instale requirements-gui.txt antes de abrir la GUI."
    ) from exc


EPS = 1e-9
DEFAULT_BIAS_SAMPLE_CAP = 200
DEFAULT_NOMINAL_SENS_MV_PER_G = 300.0
SATURATION_LOW = 5
SATURATION_HIGH = 4090
USB_HINTS = (
    "usb",
    "uart",
    "cp210",
    "ch340",
    "silicon labs",
    "serial",
    "esp32",
)


@dataclass
class ParsedLine:
    kind: str
    text: str = ""
    values: tuple[float, ...] = ()


@dataclass
class Sample:
    sensor_id: int
    seq: int
    t_us: int
    raw_x: int
    raw_y: int
    raw_z: int
    mv_x: float
    mv_y: float
    mv_z: float
    wall_s: float = 0.0
    gx_est: float = math.nan
    gy_est: float = math.nan
    gz_est: float = math.nan
    g_norm_est: float = math.nan

    def raw_row(self) -> dict[str, float | int]:
        return {
            "sensor_id": self.sensor_id,
            "seq": self.seq,
            "t_us": self.t_us,
            "wall_s": round(self.wall_s, 6),
            "raw_x": self.raw_x,
            "raw_y": self.raw_y,
            "raw_z": self.raw_z,
            "mv_x": round(self.mv_x, 6),
            "mv_y": round(self.mv_y, 6),
            "mv_z": round(self.mv_z, 6),
        }

    def processed_row(self) -> dict[str, float | int]:
        row = self.raw_row()
        row.update(
            {
                "gx_est": round(self.gx_est, 9),
                "gy_est": round(self.gy_est, 9),
                "gz_est": round(self.gz_est, 9),
                "g_norm_est": round(self.g_norm_est, 9),
            }
        )
        return row


@dataclass
class PortInventoryEntry:
    device: str
    description: str
    hwid: str
    usb_like: bool


@dataclass
class PortProbeResult:
    device: str
    saw_header: bool = False
    saw_metadata: bool = False
    saw_data: bool = False
    lines_seen: int = 0
    parse_hits: int = 0
    error: str = ""

    @property
    def score(self) -> int:
        return (
            (6 if self.saw_header else 0)
            + (3 if self.saw_data else 0)
            + (1 if self.saw_metadata else 0)
            + min(self.parse_hits, 10)
        )


@dataclass
class PortResolution:
    port: str
    selection_mode: str
    selection_detail: str
    inventory: list[PortInventoryEntry] = field(default_factory=list)
    probes: list[PortProbeResult] = field(default_factory=list)


@dataclass
class SensorSummary:
    sensor_id: int
    sensor_label: str
    samples: int
    seq_jumps: int
    stream_duration_s: float
    freq_hz: float
    g_norm_median: float
    max_saturation_pct: float
    min_mv_span: float
    logic_status: str
    logic_reason: str


@dataclass
class IntegritySensorCheck:
    sensor_id: int
    sensor_label: str
    samples: int
    freq_hz: float
    seq_jumps: int
    seq_backtracks: int
    t_backtracks: int
    max_saturation_pct: float
    max_zero_axis_pct: float
    max_flatline_142_pct: float
    g_norm_median: float
    logic_status: str
    logic_reason: str


@dataclass
class IntegrityResult:
    logic_status: str
    logic_reason: str
    samples: int
    invalid_lines: int
    header_seen: bool
    sensor_checks: list[IntegritySensorCheck]


@dataclass
class SessionArtifacts:
    raw_csv_abs: Path
    processed_csv_abs: Path
    session_json_abs: Path
    summary_txt_abs: Path
    precheck_txt_abs: Path


@dataclass
class LiveSessionConfig:
    repo_root: Path
    sensor_id: str = "sensor_B"
    plot_sensor_numeric_id: int = 1
    second_sensor_numeric_id: int = 2
    port: str = ""
    baud: int = 115200
    duration_s: float = 20.0
    session_name: str = "live"
    file_prefix: str = "sensor_B_live"
    output_dir_relpath: str = "data/raw/sensor_B_live"
    processed_dir_relpath: str = "data/processed"
    analysis_out_relpath: str = "reports/analysis_outputs"
    save_csv: bool = True
    save_session_json: bool = True
    dual_precheck_enabled: bool = True
    dual_precheck_duration_s: float = 10.0
    dual_precheck_min_samples_per_sensor: int = 250
    dual_precheck_max_seq_jump_ratio: float = 0.10
    dual_precheck_max_saturation_pct: float = 20.0
    dual_precheck_min_mv_axis_span: float = 0.5
    port_probe_timeout_s: float = 1.6
    bias_init_s: float = 2.0
    nominal_sens_mv_per_g: float = DEFAULT_NOMINAL_SENS_MV_PER_G
    sensorB_sens_mv_per_g: tuple[float, float, float] = (300.0, 300.0, 300.0)
    accel_mode: str = "nominal_quick_g"


@dataclass
class SessionResult:
    config: LiveSessionConfig
    requested_port: str
    port_resolution: PortResolution
    artifacts: SessionArtifacts
    metadata_lines: list[str]
    header_seen: bool
    invalid_lines: int
    samples: list[Sample]
    sensor_summaries: list[SensorSummary]
    capture_integrity: IntegrityResult
    seq_jumps: int
    stream_duration_s: float
    freq_hz: float
    primary_g_info: dict[str, object]


class LiveBiasEstimator:
    def __init__(
        self,
        nominal_sens_mv_per_g: float = DEFAULT_NOMINAL_SENS_MV_PER_G,
        sensor_sens_mv_per_g: tuple[float, float, float] = (300.0, 300.0, 300.0),
        bias_sample_cap: int = DEFAULT_BIAS_SAMPLE_CAP,
        mode: str = "nominal_quick_g",
    ) -> None:
        self.nominal_sens_mv_per_g = float(nominal_sens_mv_per_g)
        self.sensor_sens_mv_per_g = tuple(float(v) for v in sensor_sens_mv_per_g)
        self.bias_sample_cap = max(1, int(bias_sample_cap))
        self.mode = mode.lower().strip()
        self.bias_count = 0
        self.bias_sum = [0.0, 0.0, 0.0]

    def update(self, mv_xyz: tuple[float, float, float]) -> tuple[float, float, float, float]:
        if self.bias_count < self.bias_sample_cap:
            for idx, value in enumerate(mv_xyz):
                self.bias_sum[idx] += float(value)
            self.bias_count += 1

        bias = tuple(total / max(self.bias_count, 1) for total in self.bias_sum)
        if self.mode == "provisional_sensorb_g":
            sens = self.sensor_sens_mv_per_g
        else:
            sens = (
                self.nominal_sens_mv_per_g,
                self.nominal_sens_mv_per_g,
                self.nominal_sens_mv_per_g,
            )

        gx = (mv_xyz[0] - bias[0]) / sens[0]
        gy = (mv_xyz[1] - bias[1]) / sens[1]
        gz = (mv_xyz[2] - bias[2]) / sens[2]
        g_norm = math.sqrt(gx * gx + gy * gy + gz * gz)
        return gx, gy, gz, g_norm


def parse_adxl335_stream_line(line: str | bytes | None) -> ParsedLine:
    if line is None:
        return ParsedLine(kind="empty")

    if isinstance(line, bytes):
        text = line.decode("utf-8", errors="ignore")
    else:
        text = str(line)

    text = text.strip()
    if not text:
        return ParsedLine(kind="empty")

    if text.startswith("#"):
        return ParsedLine(kind="metadata", text=text)

    if text in (
        "seq,t_us,raw_x,raw_y,raw_z,mv_x,mv_y,mv_z",
        "sensor_id,seq,t_us,raw_x,raw_y,raw_z,mv_x,mv_y,mv_z",
    ):
        return ParsedLine(kind="header", text=text)

    tokens = [token.strip() for token in text.split(",")]
    if len(tokens) not in (8, 9):
        return ParsedLine(kind="invalid", text=text)

    try:
        values = [float(token) for token in tokens]
    except ValueError:
        return ParsedLine(kind="invalid", text=text)

    if len(values) == 8:
        values = [1.0] + values

    return ParsedLine(kind="data", text=text, values=tuple(values))


def sensor_label_from_numeric_id(sensor_id: int) -> str:
    if sensor_id == 1:
        return "sensor_B"
    if sensor_id == 2:
        return "sensor_A"
    return f"sensor_{sensor_id}"


def make_relpath(abs_path: Path, repo_root: Path) -> str:
    try:
        return abs_path.resolve().relative_to(repo_root.resolve()).as_posix()
    except ValueError:
        return abs_path.resolve().as_posix()


def ensure_output_paths(config: LiveSessionConfig) -> SessionArtifacts:
    stamp = time.strftime("%Y%m%d_%H%M%S")
    base_name = f"{config.file_prefix}_{config.session_name}_{stamp}"

    output_dir = (config.repo_root / config.output_dir_relpath).resolve()
    processed_dir = (config.repo_root / config.processed_dir_relpath).resolve()
    analysis_dir = (config.repo_root / config.analysis_out_relpath).resolve()

    output_dir.mkdir(parents=True, exist_ok=True)
    processed_dir.mkdir(parents=True, exist_ok=True)
    analysis_dir.mkdir(parents=True, exist_ok=True)

    return SessionArtifacts(
        raw_csv_abs=output_dir / f"{base_name}_raw.csv",
        processed_csv_abs=processed_dir / f"{base_name}_processed.csv",
        session_json_abs=processed_dir / f"{base_name}_session.json",
        summary_txt_abs=analysis_dir / f"{base_name}_summary.txt",
        precheck_txt_abs=analysis_dir / f"{base_name}_precheck.txt",
    )


def list_serial_inventory() -> list[PortInventoryEntry]:
    inventory: list[PortInventoryEntry] = []
    for port in list_ports.comports():
        description = (port.description or "").strip()
        hwid = (port.hwid or "").strip()
        label = f"{description} {hwid}".lower()
        usb_like = any(hint in label for hint in USB_HINTS)
        inventory.append(
            PortInventoryEntry(
                device=port.device,
                description=description or "(sin descripcion)",
                hwid=hwid or "(sin hwid)",
                usb_like=usb_like,
            )
        )
    inventory.sort(key=lambda item: item.device)
    return inventory


def probe_serial_candidate(device: str, baud: int, probe_timeout_s: float) -> PortProbeResult:
    result = PortProbeResult(device=device)
    deadline = time.monotonic() + max(probe_timeout_s, 0.3)

    try:
        with serial.Serial(device, baudrate=baud, timeout=0.25) as ser:
            ser.reset_input_buffer()
            time.sleep(0.15)
            while time.monotonic() < deadline:
                raw = ser.readline()
                if not raw:
                    continue
                result.lines_seen += 1
                parsed = parse_adxl335_stream_line(raw)
                if parsed.kind == "metadata":
                    result.saw_metadata = True
                elif parsed.kind == "header":
                    result.saw_header = True
                    result.parse_hits += 1
                elif parsed.kind == "data":
                    result.saw_data = True
                    result.parse_hits += 1

                if result.saw_header and result.saw_data:
                    break
    except Exception as exc:  # pragma: no cover - hardware dependent
        result.error = str(exc)

    return result


def resolve_adxl_serial_port(
    preferred_port: str,
    baud: int,
    probe_timeout_s: float,
) -> PortResolution:
    inventory = list_serial_inventory()
    if not inventory:
        raise RuntimeError(
            "No se detectaron puertos seriales. Conecte la ESP32 relay USB "
            "o cierre monitores seriales externos antes de continuar."
        )

    devices = {entry.device: entry for entry in inventory}
    preferred_port = preferred_port.strip()
    probes: list[PortProbeResult] = []

    if preferred_port:
        if preferred_port not in devices:
            listed = ", ".join(devices.keys())
            raise RuntimeError(
                f"El puerto solicitado {preferred_port} no existe en el inventario actual. "
                f"Puertos visibles: {listed}"
            )
        return PortResolution(
            port=preferred_port,
            selection_mode="preferred_port",
            selection_detail="puerto indicado explicitamente por el usuario",
            inventory=inventory,
            probes=probes,
        )

    if len(inventory) == 1:
        only = inventory[0]
        return PortResolution(
            port=only.device,
            selection_mode="single_port_inventory",
            selection_detail="solo existe un puerto serial disponible",
            inventory=inventory,
            probes=probes,
        )

    probes = [
        probe_serial_candidate(entry.device, baud=baud, probe_timeout_s=probe_timeout_s)
        for entry in inventory
    ]
    stream_matches = [probe for probe in probes if probe.saw_header or probe.saw_data]

    if len(stream_matches) == 1:
        match = stream_matches[0]
        return PortResolution(
            port=match.device,
            selection_mode="probe_match",
            selection_detail="stream serial ADXL335 identificado por sonda",
            inventory=inventory,
            probes=probes,
        )

    if len(stream_matches) > 1:
        usb_streams = [
            probe
            for probe in stream_matches
            if devices[probe.device].usb_like and not probe.error
        ]
        if len(usb_streams) == 1:
            chosen = usb_streams[0]
            return PortResolution(
                port=chosen.device,
                selection_mode="probe_match_usb_preferred",
                selection_detail="relay/stream USB serial priorizado por sonda",
                inventory=inventory,
                probes=probes,
            )

        details = []
        for probe in stream_matches:
            entry = devices[probe.device]
            details.append(f"{probe.device} ({entry.description})")
        raise RuntimeError(
            "Se detectaron multiples puertos compatibles con stream ADXL335: "
            + "; ".join(details)
            + ". Seleccione el puerto manualmente en la GUI para evitar ambiguedad."
        )

    usb_like = [entry for entry in inventory if entry.usb_like]
    if len(usb_like) == 1:
        chosen = usb_like[0]
        return PortResolution(
            port=chosen.device,
            selection_mode="usb_inventory_hint",
            selection_detail="unico puerto USB serial compatible segun inventario",
            inventory=inventory,
            probes=probes,
        )

    listed = "; ".join(f"{entry.device} ({entry.description})" for entry in inventory)
    raise RuntimeError(
        "No fue posible autodetectar el puerto correcto. Inventario visible: "
        + listed
        + ". Seleccione el COM manualmente en la GUI."
    )


def count_seq_jumps(seq_values: list[int]) -> int:
    return sum(1 for prev, cur in zip(seq_values, seq_values[1:]) if cur - prev != 1)


def count_backtracks(values: list[int]) -> int:
    return sum(1 for prev, cur in zip(values, values[1:]) if cur < prev)


def safe_pct(numerator: int, denominator: int) -> float:
    if denominator <= 0:
        return 0.0
    return (numerator / denominator) * 100.0


def estimate_sensor_accel_g(
    mv_rows: list[tuple[float, float, float]],
    *,
    mode: str,
    bias_init_samples: int,
    nominal_sens_mv_per_g: float,
    sensor_sens_mv_per_g: tuple[float, float, float],
) -> tuple[list[tuple[float, float, float]], list[float], dict[str, object]]:
    if not mv_rows:
        return [], [], {"route": mode, "bias_mv": [0.0, 0.0, 0.0], "sens_mv_per_g": [0.0, 0.0, 0.0]}

    n_bias = max(1, min(len(mv_rows), int(round(bias_init_samples))))
    bias = [0.0, 0.0, 0.0]
    for row in mv_rows[:n_bias]:
        for idx, value in enumerate(row):
            bias[idx] += float(value)
    bias = [value / n_bias for value in bias]

    if mode.lower().strip() == "provisional_sensorb_g":
        sens = [float(value) for value in sensor_sens_mv_per_g]
        route = "provisional_sensorB_g"
    else:
        sens = [float(nominal_sens_mv_per_g)] * 3
        route = "nominal_quick_g"

    g_xyz: list[tuple[float, float, float]] = []
    g_norm: list[float] = []
    for row in mv_rows:
        gx = (row[0] - bias[0]) / sens[0]
        gy = (row[1] - bias[1]) / sens[1]
        gz = (row[2] - bias[2]) / sens[2]
        g_xyz.append((gx, gy, gz))
        g_norm.append(math.sqrt(gx * gx + gy * gy + gz * gz))

    info = {
        "route": route,
        "bias_mv": [round(value, 6) for value in bias],
        "sens_mv_per_g": [round(value, 6) for value in sens],
        "samples_used_for_bias": n_bias,
    }
    return g_xyz, g_norm, info


def estimate_frequency(samples: list[Sample]) -> float:
    if len(samples) >= 2:
        t_delta = (samples[-1].t_us - samples[0].t_us) / 1_000_000.0
        if t_delta > 0:
            return (len(samples) - 1) / t_delta

        wall_delta = samples[-1].wall_s - samples[0].wall_s
        if wall_delta > 0:
            return (len(samples) - 1) / wall_delta

    if len(samples) == 1:
        return 1.0
    return 0.0


def build_processed_samples(
    samples: list[Sample],
    *,
    accel_mode: str,
    bias_init_s: float,
    nominal_sens_mv_per_g: float,
    sensor_sens_mv_per_g: tuple[float, float, float],
) -> tuple[list[Sample], list[SensorSummary], dict[str, object]]:
    grouped: dict[int, list[Sample]] = {}
    for sample in samples:
        grouped.setdefault(sample.sensor_id, []).append(sample)

    sensor_summaries: list[SensorSummary] = []
    primary_info: dict[str, object] = {}

    for sensor_id in sorted(grouped):
        sensor_samples = grouped[sensor_id]
        freq_hz = estimate_frequency(sensor_samples)
        bias_init_samples = max(1, round(max(freq_hz, 1.0) * bias_init_s))
        mv_rows = [(sample.mv_x, sample.mv_y, sample.mv_z) for sample in sensor_samples]
        g_xyz, g_norm, info = estimate_sensor_accel_g(
            mv_rows,
            mode=accel_mode,
            bias_init_samples=bias_init_samples,
            nominal_sens_mv_per_g=nominal_sens_mv_per_g,
            sensor_sens_mv_per_g=sensor_sens_mv_per_g,
        )

        for sample, g_xyz_row, g_norm_value in zip(sensor_samples, g_xyz, g_norm):
            sample.gx_est = g_xyz_row[0]
            sample.gy_est = g_xyz_row[1]
            sample.gz_est = g_xyz_row[2]
            sample.g_norm_est = g_norm_value

        summary = build_sensor_summary(
            sensor_samples,
            accel_mode=accel_mode,
            bias_init_s=bias_init_s,
            nominal_sens_mv_per_g=nominal_sens_mv_per_g,
            sensor_sens_mv_per_g=sensor_sens_mv_per_g,
        )
        sensor_summaries.append(summary)

        if sensor_id == 1 or not primary_info:
            primary_info = info

    return samples, sensor_summaries, primary_info


def build_sensor_summary(
    samples: list[Sample],
    *,
    accel_mode: str,
    bias_init_s: float,
    nominal_sens_mv_per_g: float,
    sensor_sens_mv_per_g: tuple[float, float, float],
) -> SensorSummary:
    sensor_id = samples[0].sensor_id if samples else -1
    sensor_label = sensor_label_from_numeric_id(sensor_id)

    if not samples:
        return SensorSummary(
            sensor_id=sensor_id,
            sensor_label=sensor_label,
            samples=0,
            seq_jumps=0,
            stream_duration_s=0.0,
            freq_hz=0.0,
            g_norm_median=math.nan,
            max_saturation_pct=math.nan,
            min_mv_span=math.nan,
            logic_status="fail",
            logic_reason="sensor_missing",
        )

    seq_values = [sample.seq for sample in samples]
    raw_axes = [
        [sample.raw_x for sample in samples],
        [sample.raw_y for sample in samples],
        [sample.raw_z for sample in samples],
    ]
    mv_axes = [
        [sample.mv_x for sample in samples],
        [sample.mv_y for sample in samples],
        [sample.mv_z for sample in samples],
    ]

    freq_hz = estimate_frequency(samples)
    bias_init_samples = max(1, round(max(freq_hz, 1.0) * bias_init_s))
    _, g_norm, _ = estimate_sensor_accel_g(
        [(sample.mv_x, sample.mv_y, sample.mv_z) for sample in samples],
        mode=accel_mode,
        bias_init_samples=bias_init_samples,
        nominal_sens_mv_per_g=nominal_sens_mv_per_g,
        sensor_sens_mv_per_g=sensor_sens_mv_per_g,
    )

    stream_duration_s = 0.0
    if len(samples) >= 2:
        stream_duration_s = max(0.0, (samples[-1].t_us - samples[0].t_us) / 1_000_000.0)

    sat_pct = [
        safe_pct(
            sum(1 for value in axis if value <= SATURATION_LOW or value >= SATURATION_HIGH),
            len(axis),
        )
        for axis in raw_axes
    ]
    mv_span = [max(axis) - min(axis) if axis else 0.0 for axis in mv_axes]
    g_norm_median = median(g_norm) if g_norm else math.nan

    status = "pass"
    reason = "basic_live_sanity_ok"
    if len(samples) < 30:
        status = "suspect"
        reason = "few_samples"
    elif max(sat_pct) > 20.0:
        status = "fail"
        reason = "adc_saturation"
    elif g_norm_median < 0.30 or g_norm_median > 1.70:
        status = "fail"
        reason = "g_norm_implausible"
    elif g_norm_median < 0.60 or g_norm_median > 1.40:
        status = "suspect"
        reason = "g_norm_borderline"
    elif min(mv_span) < 0.5:
        status = "suspect"
        reason = "low_signal_span"

    return SensorSummary(
        sensor_id=sensor_id,
        sensor_label=sensor_label,
        samples=len(samples),
        seq_jumps=count_seq_jumps(seq_values),
        stream_duration_s=stream_duration_s,
        freq_hz=freq_hz,
        g_norm_median=g_norm_median,
        max_saturation_pct=max(sat_pct),
        min_mv_span=min(mv_span),
        logic_status=status,
        logic_reason=reason,
    )


def build_integrity_sensor_check(
    samples: list[Sample],
    *,
    accel_mode: str,
    bias_init_s: float,
    nominal_sens_mv_per_g: float,
    sensor_sens_mv_per_g: tuple[float, float, float],
    min_samples_per_sensor: int,
    max_seq_jump_ratio: float,
    max_saturation_pct: float,
    min_mv_axis_span: float,
    require_static_gnorm: bool,
) -> IntegritySensorCheck:
    summary = build_sensor_summary(
        samples,
        accel_mode=accel_mode,
        bias_init_s=bias_init_s,
        nominal_sens_mv_per_g=nominal_sens_mv_per_g,
        sensor_sens_mv_per_g=sensor_sens_mv_per_g,
    )

    if not samples:
        return IntegritySensorCheck(
            sensor_id=summary.sensor_id,
            sensor_label=summary.sensor_label,
            samples=0,
            freq_hz=0.0,
            seq_jumps=0,
            seq_backtracks=0,
            t_backtracks=0,
            max_saturation_pct=math.nan,
            max_zero_axis_pct=math.nan,
            max_flatline_142_pct=math.nan,
            g_norm_median=math.nan,
            logic_status="fail",
            logic_reason="sensor_missing",
        )

    raw_axes = [
        [sample.raw_x for sample in samples],
        [sample.raw_y for sample in samples],
        [sample.raw_z for sample in samples],
    ]
    mv_axes = [
        [sample.mv_x for sample in samples],
        [sample.mv_y for sample in samples],
        [sample.mv_z for sample in samples],
    ]
    seq_values = [sample.seq for sample in samples]
    time_values = [sample.t_us for sample in samples]
    seq_jump_ratio = summary.seq_jumps / max(len(samples) - 1, 1)
    max_zero_axis_pct = max(
        safe_pct(sum(1 for value in axis if value == 0), len(axis)) for axis in raw_axes
    )
    max_flatline_142_pct = max(
        safe_pct(sum(1 for value in axis if round(value) == 142), len(axis)) for axis in mv_axes
    )

    status = "pass"
    reason = "integrity_ok"
    if len(samples) < min_samples_per_sensor:
        status = "fail"
        reason = "few_samples"
    elif count_backtracks(seq_values) > 0 or count_backtracks(time_values) > 0:
        status = "fail"
        reason = "counter_reset_detected"
    elif summary.max_saturation_pct > max_saturation_pct:
        status = "fail"
        reason = "adc_saturation"
    elif max_zero_axis_pct > 95.0 or max_flatline_142_pct > 95.0:
        status = "fail"
        reason = "dead_axis_or_disconnected"
    elif require_static_gnorm and summary.min_mv_span < min_mv_axis_span:
        status = "fail"
        reason = "low_signal_span_static"
    elif seq_jump_ratio > max_seq_jump_ratio:
        status = "fail"
        reason = "packet_loss_excessive"

    return IntegritySensorCheck(
        sensor_id=summary.sensor_id,
        sensor_label=summary.sensor_label,
        samples=summary.samples,
        freq_hz=summary.freq_hz,
        seq_jumps=summary.seq_jumps,
        seq_backtracks=count_backtracks(seq_values),
        t_backtracks=count_backtracks(time_values),
        max_saturation_pct=summary.max_saturation_pct,
        max_zero_axis_pct=max_zero_axis_pct,
        max_flatline_142_pct=max_flatline_142_pct,
        g_norm_median=summary.g_norm_median,
        logic_status=status,
        logic_reason=reason,
    )


def evaluate_dual_integrity_window(
    samples: list[Sample],
    *,
    required_sensor_ids: tuple[int, int],
    accel_mode: str,
    bias_init_s: float,
    nominal_sens_mv_per_g: float,
    sensor_sens_mv_per_g: tuple[float, float, float],
    min_samples_per_sensor: int,
    max_seq_jump_ratio: float,
    max_saturation_pct: float,
    min_mv_axis_span: float,
    invalid_lines: int,
    header_seen: bool,
    require_static_gnorm: bool,
) -> IntegrityResult:
    sensor_checks: list[IntegritySensorCheck] = []
    reasons: list[str] = []

    if not header_seen and not samples:
        return IntegrityResult(
            logic_status="fail",
            logic_reason="missing_header",
            samples=len(samples),
            invalid_lines=invalid_lines,
            header_seen=False,
            sensor_checks=[],
        )

    for sensor_id in required_sensor_ids:
        sensor_samples = [sample for sample in samples if sample.sensor_id == sensor_id]
        check = build_integrity_sensor_check(
            sensor_samples,
            accel_mode=accel_mode,
            bias_init_s=bias_init_s,
            nominal_sens_mv_per_g=nominal_sens_mv_per_g,
            sensor_sens_mv_per_g=sensor_sens_mv_per_g,
            min_samples_per_sensor=min_samples_per_sensor,
            max_seq_jump_ratio=max_seq_jump_ratio,
            max_saturation_pct=max_saturation_pct,
            min_mv_axis_span=min_mv_axis_span,
            require_static_gnorm=require_static_gnorm,
        )
        sensor_checks.append(check)
        if check.logic_status != "pass":
            reasons.append(f"sensor_{check.sensor_id}:{check.logic_reason}")

    if invalid_lines > 25:
        reasons.append("invalid_lines_excessive")

    if reasons:
        return IntegrityResult(
            logic_status="fail",
            logic_reason=";".join(reasons),
            samples=len(samples),
            invalid_lines=invalid_lines,
            header_seen=header_seen,
            sensor_checks=sensor_checks,
        )

    return IntegrityResult(
        logic_status="pass",
        logic_reason="dual_integrity_ok",
        samples=len(samples),
        invalid_lines=invalid_lines,
        header_seen=header_seen,
        sensor_checks=sensor_checks,
    )


def save_csv_rows(path: Path, rows: list[dict[str, object]]) -> None:
    if not rows:
        return
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)


def write_precheck_report(
    path: Path,
    result: IntegrityResult,
    *,
    config: LiveSessionConfig,
    requested_port: str,
    port_resolution: PortResolution,
) -> None:
    with path.open("w", encoding="utf-8") as handle:
        handle.write("script: gui/adxl_live_gui.py\n")
        handle.write("phase: dual_integrity_precheck\n")
        handle.write(f"requested_port: {requested_port or '(auto)'}\n")
        handle.write(f"port: {port_resolution.port}\n")
        handle.write(f"port_resolution_mode: {port_resolution.selection_mode}\n")
        handle.write(f"port_resolution_detail: {port_resolution.selection_detail}\n")
        handle.write(f"baud: {config.baud}\n")
        handle.write(f"precheck_duration_s: {config.dual_precheck_duration_s:.3f}\n")
        handle.write(f"samples: {result.samples}\n")
        handle.write(f"invalid_lines_ignored: {result.invalid_lines}\n")
        handle.write(f"header_seen: {str(result.header_seen).lower()}\n")
        handle.write(f"precheck_status: {result.logic_status}\n")
        handle.write(f"precheck_reason: {result.logic_reason}\n")
        for check in result.sensor_checks:
            handle.write(f"sensor_{check.sensor_id}_label: {check.sensor_label}\n")
            handle.write(f"sensor_{check.sensor_id}_samples: {check.samples}\n")
            handle.write(f"sensor_{check.sensor_id}_freq_hz: {check.freq_hz:.6f}\n")
            handle.write(f"sensor_{check.sensor_id}_seq_jumps: {check.seq_jumps}\n")
            handle.write(f"sensor_{check.sensor_id}_seq_backtracks: {check.seq_backtracks}\n")
            handle.write(f"sensor_{check.sensor_id}_t_backtracks: {check.t_backtracks}\n")
            handle.write(
                f"sensor_{check.sensor_id}_max_saturation_pct: {check.max_saturation_pct:.6f}\n"
            )
            handle.write(
                f"sensor_{check.sensor_id}_max_zero_axis_pct: {check.max_zero_axis_pct:.6f}\n"
            )
            handle.write(
                f"sensor_{check.sensor_id}_max_flatline_142_pct: {check.max_flatline_142_pct:.6f}\n"
            )
            handle.write(
                f"sensor_{check.sensor_id}_g_norm_median: {check.g_norm_median:.6f}\n"
            )
            handle.write(f"sensor_{check.sensor_id}_status: {check.logic_status}\n")
            handle.write(f"sensor_{check.sensor_id}_reason: {check.logic_reason}\n")


def write_summary_report(
    result: SessionResult,
    *,
    save_raw: bool,
    save_processed: bool,
    save_session_json: bool,
) -> None:
    artifacts = result.artifacts
    repo_root = result.config.repo_root
    raw_rel = make_relpath(artifacts.raw_csv_abs, repo_root) if save_raw else "not_saved"
    processed_rel = (
        make_relpath(artifacts.processed_csv_abs, repo_root) if save_processed else "not_saved"
    )
    session_rel = (
        make_relpath(artifacts.session_json_abs, repo_root) if save_session_json else "not_saved"
    )
    precheck_rel = make_relpath(artifacts.precheck_txt_abs, repo_root)
    summary_rel = make_relpath(artifacts.summary_txt_abs, repo_root)

    with artifacts.summary_txt_abs.open("w", encoding="utf-8") as handle:
        handle.write("script: gui/adxl_live_gui.py\n")
        handle.write(f"sensor_id: {result.config.sensor_id}\n")
        handle.write(f"plot_sensor_numeric_id: {result.config.plot_sensor_numeric_id}\n")
        handle.write(f"second_sensor_numeric_id: {result.config.second_sensor_numeric_id}\n")
        handle.write(f"requested_port: {result.requested_port or '(auto)'}\n")
        handle.write(f"port: {result.port_resolution.port}\n")
        handle.write(f"port_resolution_mode: {result.port_resolution.selection_mode}\n")
        handle.write(f"port_resolution_detail: {result.port_resolution.selection_detail}\n")
        handle.write(f"baud: {result.config.baud}\n")
        handle.write(f"duration_s: {result.config.duration_s:.3f}\n")
        handle.write(f"session_name: {result.config.session_name}\n")
        handle.write(f"file_prefix: {result.config.file_prefix}\n")
        handle.write(f"accel_mode: {result.config.accel_mode}\n")
        handle.write(f"samples: {len(result.samples)}\n")
        handle.write(f"stream_duration_s: {result.stream_duration_s:.6f}\n")
        handle.write(f"freq_hz: {result.freq_hz:.6f}\n")
        handle.write(f"seq_jumps: {result.seq_jumps}\n")
        handle.write(f"invalid_lines_ignored: {result.invalid_lines}\n")
        handle.write(f"header_seen: {str(result.header_seen).lower()}\n")
        handle.write(f"capture_integrity_status: {result.capture_integrity.logic_status}\n")
        handle.write(f"capture_integrity_reason: {result.capture_integrity.logic_reason}\n")
        bias_mv = result.primary_g_info.get("bias_mv", [0.0, 0.0, 0.0])
        sens_mv = result.primary_g_info.get("sens_mv_per_g", [0.0, 0.0, 0.0])
        handle.write("bias_mv: " + ",".join(f"{float(value):.6f}" for value in bias_mv) + "\n")
        handle.write(
            "sens_mv_per_g: " + ",".join(f"{float(value):.6f}" for value in sens_mv) + "\n"
        )
        for summary in result.sensor_summaries:
            handle.write(f"sensor_{summary.sensor_id}_label: {summary.sensor_label}\n")
            handle.write(f"sensor_{summary.sensor_id}_samples: {summary.samples}\n")
            handle.write(f"sensor_{summary.sensor_id}_freq_hz: {summary.freq_hz:.6f}\n")
            handle.write(f"sensor_{summary.sensor_id}_seq_jumps: {summary.seq_jumps}\n")
            handle.write(
                f"sensor_{summary.sensor_id}_g_norm_median: {summary.g_norm_median:.6f}\n"
            )
            handle.write(
                f"sensor_{summary.sensor_id}_max_saturation_pct: {summary.max_saturation_pct:.6f}\n"
            )
            handle.write(f"sensor_{summary.sensor_id}_logic_status: {summary.logic_status}\n")
            handle.write(f"sensor_{summary.sensor_id}_logic_reason: {summary.logic_reason}\n")
        handle.write(f"raw_csv_relpath: {raw_rel}\n")
        handle.write(f"processed_csv_relpath: {processed_rel}\n")
        handle.write(f"session_json_relpath: {session_rel}\n")
        handle.write(f"precheck_txt_relpath: {precheck_rel}\n")
        handle.write(f"summary_txt_relpath: {summary_rel}\n")
        handle.write(f"next_block_input_relpath: {processed_rel}\n")


def write_session_json(result: SessionResult) -> None:
    payload = {
        "config": {
            key: (str(value) if isinstance(value, Path) else value)
            for key, value in asdict(result.config).items()
        },
        "requested_port": result.requested_port,
        "port_resolution": {
            "port": result.port_resolution.port,
            "selection_mode": result.port_resolution.selection_mode,
            "selection_detail": result.port_resolution.selection_detail,
            "inventory": [asdict(entry) for entry in result.port_resolution.inventory],
            "probes": [asdict(entry) for entry in result.port_resolution.probes],
        },
        "metadata_lines": result.metadata_lines,
        "header_seen": result.header_seen,
        "invalid_lines": result.invalid_lines,
        "seq_jumps": result.seq_jumps,
        "stream_duration_s": result.stream_duration_s,
        "freq_hz": result.freq_hz,
        "sensor_summaries": [asdict(summary) for summary in result.sensor_summaries],
        "capture_integrity": {
            **asdict(result.capture_integrity),
            "sensor_checks": [asdict(check) for check in result.capture_integrity.sensor_checks],
        },
        "primary_g_info": result.primary_g_info,
        "artifacts": {
            "raw_csv_relpath": make_relpath(result.artifacts.raw_csv_abs, result.config.repo_root),
            "processed_csv_relpath": make_relpath(
                result.artifacts.processed_csv_abs, result.config.repo_root
            ),
            "session_json_relpath": make_relpath(
                result.artifacts.session_json_abs, result.config.repo_root
            ),
            "summary_txt_relpath": make_relpath(
                result.artifacts.summary_txt_abs, result.config.repo_root
            ),
            "precheck_txt_relpath": make_relpath(
                result.artifacts.precheck_txt_abs, result.config.repo_root
            ),
        },
    }
    with result.artifacts.session_json_abs.open("w", encoding="utf-8") as handle:
        json.dump(payload, handle, indent=2, ensure_ascii=True)


def build_session_result(
    *,
    config: LiveSessionConfig,
    requested_port: str,
    port_resolution: PortResolution,
    artifacts: SessionArtifacts,
    metadata_lines: list[str],
    header_seen: bool,
    invalid_lines: int,
    capture_samples: list[Sample],
) -> SessionResult:
    samples, sensor_summaries, primary_g_info = build_processed_samples(
        capture_samples,
        accel_mode=config.accel_mode,
        bias_init_s=config.bias_init_s,
        nominal_sens_mv_per_g=config.nominal_sens_mv_per_g,
        sensor_sens_mv_per_g=config.sensorB_sens_mv_per_g,
    )

    capture_integrity = evaluate_dual_integrity_window(
        samples,
        required_sensor_ids=(config.plot_sensor_numeric_id, config.second_sensor_numeric_id),
        accel_mode=config.accel_mode,
        bias_init_s=config.bias_init_s,
        nominal_sens_mv_per_g=config.nominal_sens_mv_per_g,
        sensor_sens_mv_per_g=config.sensorB_sens_mv_per_g,
        min_samples_per_sensor=config.dual_precheck_min_samples_per_sensor,
        max_seq_jump_ratio=config.dual_precheck_max_seq_jump_ratio,
        max_saturation_pct=config.dual_precheck_max_saturation_pct,
        min_mv_axis_span=config.dual_precheck_min_mv_axis_span,
        invalid_lines=invalid_lines,
        header_seen=header_seen,
        require_static_gnorm=False,
    )

    primary_sensor_samples = [sample for sample in samples if sample.sensor_id == config.plot_sensor_numeric_id]
    primary_seq_jumps = count_seq_jumps([sample.seq for sample in primary_sensor_samples])
    if len(samples) >= 2:
        stream_duration_s = max(0.0, samples[-1].wall_s - samples[0].wall_s)
        freq_hz = (len(samples) - 1) / max(stream_duration_s, EPS)
    else:
        stream_duration_s = 0.0
        freq_hz = float(len(samples))

    return SessionResult(
        config=config,
        requested_port=requested_port,
        port_resolution=port_resolution,
        artifacts=artifacts,
        metadata_lines=metadata_lines,
        header_seen=header_seen,
        invalid_lines=invalid_lines,
        samples=samples,
        sensor_summaries=sensor_summaries,
        capture_integrity=capture_integrity,
        seq_jumps=primary_seq_jumps,
        stream_duration_s=stream_duration_s,
        freq_hz=freq_hz,
        primary_g_info=primary_g_info,
    )


class LiveCaptureWorker(threading.Thread):
    def __init__(
        self,
        config: LiveSessionConfig,
        event_callback: Callable[[str, dict[str, object]], None],
    ) -> None:
        super().__init__(daemon=True)
        self.config = config
        self.event_callback = event_callback
        self.stop_event = threading.Event()

    def stop(self) -> None:
        self.stop_event.set()

    def emit(self, event_type: str, **payload: object) -> None:
        self.event_callback(event_type, payload)

    def run(self) -> None:  # pragma: no cover - exercised via GUI flow
        requested_port = self.config.port.strip()
        artifacts = ensure_output_paths(self.config)
        try:
            port_resolution = resolve_adxl_serial_port(
                preferred_port=requested_port,
                baud=self.config.baud,
                probe_timeout_s=self.config.port_probe_timeout_s,
            )
            self.emit("port_resolved", port_resolution=port_resolution)

            with serial.Serial(
                port_resolution.port,
                baudrate=self.config.baud,
                timeout=0.25,
            ) as ser:
                ser.reset_input_buffer()
                time.sleep(0.10)

                if self.config.dual_precheck_enabled:
                    self.emit("phase_changed", phase="precheck")
                    self.emit(
                        "log",
                        message=(
                            "Precheck dual iniciado. Mantenga ambos sensores quietos "
                            "durante la ventana de integridad."
                        ),
                    )
                    precheck = self._collect_window(
                        ser=ser,
                        duration_s=self.config.dual_precheck_duration_s,
                        phase="precheck",
                    )
                    precheck_result = evaluate_dual_integrity_window(
                        precheck["samples"],
                        required_sensor_ids=(
                            self.config.plot_sensor_numeric_id,
                            self.config.second_sensor_numeric_id,
                        ),
                        accel_mode=self.config.accel_mode,
                        bias_init_s=self.config.bias_init_s,
                        nominal_sens_mv_per_g=self.config.nominal_sens_mv_per_g,
                        sensor_sens_mv_per_g=self.config.sensorB_sens_mv_per_g,
                        min_samples_per_sensor=self.config.dual_precheck_min_samples_per_sensor,
                        max_seq_jump_ratio=self.config.dual_precheck_max_seq_jump_ratio,
                        max_saturation_pct=self.config.dual_precheck_max_saturation_pct,
                        min_mv_axis_span=self.config.dual_precheck_min_mv_axis_span,
                        invalid_lines=precheck["invalid_lines"],
                        header_seen=precheck["header_seen"],
                        require_static_gnorm=True,
                    )
                    write_precheck_report(
                        artifacts.precheck_txt_abs,
                        precheck_result,
                        config=self.config,
                        requested_port=requested_port,
                        port_resolution=port_resolution,
                    )
                    self.emit("precheck_complete", result=precheck_result)
                    if precheck_result.logic_status != "pass":
                        raise RuntimeError(
                            "Precheck dual no superado: "
                            f"{precheck_result.logic_reason}. "
                            f"Revise {make_relpath(artifacts.precheck_txt_abs, self.config.repo_root)}"
                        )
                    ser.reset_input_buffer()
                    time.sleep(0.10)
                else:
                    empty_precheck = IntegrityResult(
                        logic_status="not_run",
                        logic_reason="precheck_disabled",
                        samples=0,
                        invalid_lines=0,
                        header_seen=False,
                        sensor_checks=[],
                    )
                    write_precheck_report(
                        artifacts.precheck_txt_abs,
                        empty_precheck,
                        config=self.config,
                        requested_port=requested_port,
                        port_resolution=port_resolution,
                    )

                self.emit("phase_changed", phase="capture")
                self.emit("log", message="Captura principal iniciada.")
                capture = self._collect_window(
                    ser=ser,
                    duration_s=self.config.duration_s,
                    phase="capture",
                )

            if self.stop_event.is_set():
                self.emit("session_cancelled")
                return

            if not capture["samples"]:
                raise RuntimeError(
                    "Sesion live sin muestras validas. Verifique puerto, firmware y stream serial."
                )

            result = build_session_result(
                config=self.config,
                requested_port=requested_port,
                port_resolution=port_resolution,
                artifacts=artifacts,
                metadata_lines=capture["metadata_lines"],
                header_seen=capture["header_seen"],
                invalid_lines=capture["invalid_lines"],
                capture_samples=capture["samples"],
            )

            if self.config.save_csv:
                save_csv_rows(
                    artifacts.raw_csv_abs,
                    [sample.raw_row() for sample in result.samples],
                )
                save_csv_rows(
                    artifacts.processed_csv_abs,
                    [sample.processed_row() for sample in result.samples],
                )
            if self.config.save_session_json:
                write_session_json(result)
            write_summary_report(
                result,
                save_raw=self.config.save_csv,
                save_processed=self.config.save_csv,
                save_session_json=self.config.save_session_json,
            )

            self.emit("session_complete", result=result)
        except Exception as exc:
            self.emit(
                "session_error",
                message=str(exc),
                traceback=traceback.format_exc(),
            )

    def _collect_window(
        self,
        *,
        ser: serial.Serial,
        duration_s: float,
        phase: str,
    ) -> dict[str, object]:
        start_time = time.monotonic()
        next_progress = start_time
        samples: list[Sample] = []
        metadata_lines: list[str] = []
        header_seen = False
        invalid_lines = 0
        live_bias: dict[int, LiveBiasEstimator] = {}

        while not self.stop_event.is_set():
            now = time.monotonic()
            elapsed = now - start_time
            if elapsed >= duration_s:
                break

            raw = ser.readline()
            if raw:
                parsed = parse_adxl335_stream_line(raw)
                if parsed.kind == "metadata":
                    metadata_lines.append(parsed.text)
                    self.emit("metadata", phase=phase, text=parsed.text)
                elif parsed.kind == "header":
                    header_seen = True
                    self.emit("header_seen", phase=phase)
                elif parsed.kind == "data":
                    values = parsed.values
                    sample = Sample(
                        sensor_id=int(values[0]),
                        seq=int(values[1]),
                        t_us=int(values[2]),
                        raw_x=int(values[3]),
                        raw_y=int(values[4]),
                        raw_z=int(values[5]),
                        mv_x=float(values[6]),
                        mv_y=float(values[7]),
                        mv_z=float(values[8]),
                        wall_s=elapsed,
                    )
                    estimator = live_bias.setdefault(
                        sample.sensor_id,
                        LiveBiasEstimator(
                            nominal_sens_mv_per_g=self.config.nominal_sens_mv_per_g,
                            sensor_sens_mv_per_g=self.config.sensorB_sens_mv_per_g,
                            bias_sample_cap=DEFAULT_BIAS_SAMPLE_CAP,
                            mode=self.config.accel_mode,
                        ),
                    )
                    gx, gy, gz, g_norm = estimator.update(
                        (sample.mv_x, sample.mv_y, sample.mv_z)
                    )
                    sample.gx_est = gx
                    sample.gy_est = gy
                    sample.gz_est = gz
                    sample.g_norm_est = g_norm
                    samples.append(sample)
                    self.emit("sample", phase=phase, sample=sample)
                elif parsed.kind == "invalid":
                    invalid_lines += 1

            if now >= next_progress:
                counts = {
                    sensor_id: sum(1 for sample in samples if sample.sensor_id == sensor_id)
                    for sensor_id in (
                        self.config.plot_sensor_numeric_id,
                        self.config.second_sensor_numeric_id,
                    )
                }
                payload = {
                    "phase": phase,
                    "elapsed_s": elapsed,
                    "remaining_s": max(duration_s - elapsed, 0.0),
                    "samples": len(samples),
                    "sensor_counts": counts,
                }
                if phase == "precheck":
                    self.emit("precheck_progress", **payload)
                else:
                    payload["est_hz_total"] = len(samples) / max(elapsed, EPS)
                    self.emit("capture_progress", **payload)
                next_progress = now + 1.0

        return {
            "samples": samples,
            "metadata_lines": metadata_lines,
            "header_seen": header_seen,
            "invalid_lines": invalid_lines,
        }

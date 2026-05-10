from __future__ import annotations


KX134_PROTOCOL_VERSION = "kx134.v3"

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

KX134_FORBIDDEN_FIELDS = [
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
]

KX134_ALLOWED_SAMPLE_RATES = [100, 200, 400, 800]
KX134_DEFAULT_SAMPLE_RATE_HZ = 100
KX134_DEFAULT_BAUD = 921600
KX134_ALLOWED_RANGE_G = [8, 16, 32, 64]


def _tokens(text: str) -> list[str]:
    return [token.strip() for token in str(text or "").strip().split(",")]


def is_kx134_header(text: str) -> bool:
    return _tokens(text) == KX134_EXPECTED_HEADER


def has_forbidden_kx134_fields(header_or_text: str) -> bool:
    fields = {token.strip().lower() for token in _tokens(header_or_text)}
    forbidden = {field.lower() for field in KX134_FORBIDDEN_FIELDS}
    return bool(fields.intersection(forbidden))


def expected_field_count() -> int:
    return len(KX134_EXPECTED_HEADER)

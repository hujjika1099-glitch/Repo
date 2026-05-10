from __future__ import annotations

import unittest
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from gui.kx134_live_core import parse_kx134_stream_line
from gui.kx134_stream_contract import KX134_EXPECTED_HEADER


VALID_ROW = (
    "kx134.v3,ESPNOW_DUAL_PROTOTYPE,1,KX134_SENSOR_1,sensor_node_1,"
    "D4:E9:F4:E9:8E:1C,102541,1025890916,12682011,0,"
    "KX134_DUAL_BRINGUP,2515,115,-85,4233,0.026268,-0.036150,1.008363,"
    "100,100,8,kx134_sensor_1_20260508_234831,true,OK,OK,"
    "kx134_dual_espnow.0.1.0,kx134.v3"
)


def row_with(**changes: str | int) -> str:
    values = VALID_ROW.split(",")
    index = {name: idx for idx, name in enumerate(KX134_EXPECTED_HEADER)}
    for key, value in changes.items():
        values[index[key]] = str(value)
    return ",".join(values)


class TestKx134StreamParser(unittest.TestCase):
    def test_exact_header(self) -> None:
        parsed = parse_kx134_stream_line(",".join(KX134_EXPECTED_HEADER))
        self.assertEqual(parsed.kind, "header")

    def test_metadata(self) -> None:
        parsed = parse_kx134_stream_line("#STAT,role=receiver,rx_total=10")
        self.assertEqual(parsed.kind, "metadata")

    def test_valid_sensor_1(self) -> None:
        parsed = parse_kx134_stream_line(VALID_ROW)
        self.assertEqual(parsed.kind, "data")
        self.assertEqual(parsed.row["sensor_id"], 1)

    def test_valid_sensor_2(self) -> None:
        parsed = parse_kx134_stream_line(
            row_with(sensor_id=2, physical_label="KX134_SENSOR_2", node_id="sensor_node_2")
        )
        self.assertEqual(parsed.kind, "data")
        self.assertEqual(parsed.row["sensor_id"], 2)

    def test_reject_adxl_8_fields(self) -> None:
        parsed = parse_kx134_stream_line("1,2,3,4,5,6,7,8")
        self.assertEqual(parsed.kind, "invalid")

    def test_reject_adxl_9_fields(self) -> None:
        parsed = parse_kx134_stream_line("1,2,3,4,5,6,7,8,9")
        self.assertEqual(parsed.kind, "invalid")

    def test_reject_missing_sensor_id(self) -> None:
        parsed = parse_kx134_stream_line(row_with(sensor_id=""))
        self.assertEqual(parsed.kind, "invalid")

    def test_reject_forbidden_mv_header(self) -> None:
        header = KX134_EXPECTED_HEADER.copy()
        header[15] = "mv_x"
        parsed = parse_kx134_stream_line(",".join(header))
        self.assertEqual(parsed.kind, "invalid")
        self.assertEqual(parsed.error, "forbidden_kx134_field")

    def test_reject_sample_rate_500(self) -> None:
        parsed = parse_kx134_stream_line(row_with(sample_rate_hz=500))
        self.assertEqual(parsed.kind, "invalid")

    def test_reject_sample_rate_1000(self) -> None:
        parsed = parse_kx134_stream_line(row_with(sample_rate_hz=1000))
        self.assertEqual(parsed.kind, "invalid")

    def test_accept_sample_rate_200(self) -> None:
        parsed = parse_kx134_stream_line(row_with(sample_rate_hz=200, odr_hz=200))
        self.assertEqual(parsed.kind, "data")

    def test_accept_sample_rate_400(self) -> None:
        parsed = parse_kx134_stream_line(row_with(sample_rate_hz=400, odr_hz=400))
        self.assertEqual(parsed.kind, "data")

    def test_accept_sample_rate_800(self) -> None:
        parsed = parse_kx134_stream_line(row_with(sample_rate_hz=800, odr_hz=800))
        self.assertEqual(parsed.kind, "data")

    def test_accept_allowed_ranges(self) -> None:
        for range_g in (8, 16, 32, 64):
            with self.subTest(range_g=range_g):
                parsed = parse_kx134_stream_line(row_with(range_g=range_g))
                self.assertEqual(parsed.kind, "data")

    def test_reject_bad_contract_version(self) -> None:
        parsed = parse_kx134_stream_line(row_with(contract_version="kx134.v2"))
        self.assertEqual(parsed.kind, "invalid")

    def test_reject_empty_node_mac(self) -> None:
        parsed = parse_kx134_stream_line(row_with(node_mac=""))
        self.assertEqual(parsed.kind, "invalid")

    def test_parse_calibration_bool(self) -> None:
        true_parsed = parse_kx134_stream_line(row_with(calibration_applied="true"))
        false_parsed = parse_kx134_stream_line(row_with(calibration_applied="false"))
        self.assertTrue(true_parsed.sample.calibration_applied)
        self.assertFalse(false_parsed.sample.calibration_applied)


if __name__ == "__main__":
    unittest.main()

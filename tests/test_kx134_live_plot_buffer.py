from __future__ import annotations

import math
import unittest
from dataclasses import asdict

from gui.kx134_live_core import Kx134Sample
from gui.kx134_live_plots import Kx134LivePlotBuffer, Kx134LiveSamplePoint


def make_sample(sensor_id: int = 1, t_s: float = 0.0, seq: int = 1, x_g: float = 0.0, y_g: float = 0.0, z_g: float = 1.0) -> Kx134Sample:
    return Kx134Sample(
        protocol_version="kx134.v3",
        session_id="test",
        sensor_id=sensor_id,
        physical_label=f"KX134_SENSOR_{sensor_id}",
        node_id=f"sensor_node_{sensor_id}",
        node_mac="D4:E9:F4:E9:8E:1C" if sensor_id == 1 else "D4:E9:F4:C3:37:14",
        seq=seq,
        sensor_t_us=seq * 10000,
        receiver_t_us=seq * 10000,
        pc_wall_s=t_s,
        sync_group_id="KX134_DUAL_BRINGUP",
        pair_seq=seq,
        x_raw=0,
        y_raw=0,
        z_raw=4096,
        x_g=x_g,
        y_g=y_g,
        z_g=z_g,
        sample_rate_hz=100,
        odr_hz=100,
        range_g=8,
        calibration_id="cal",
        calibration_applied=True,
        packet_status="OK",
        packet_error_code="OK",
        firmware_version="kx134_dual_espnow.0.1.0",
        contract_version="kx134.v3",
    )


class Kx134LivePlotBufferTests(unittest.TestCase):
    def test_accepts_both_sensors_and_calculates_visual_abs_g(self) -> None:
        buffer = Kx134LivePlotBuffer(window_s=30)
        p1 = buffer.add_sample(make_sample(sensor_id=1, t_s=1.0, x_g=3.0, y_g=4.0, z_g=0.0))
        p2 = buffer.add_sample(make_sample(sensor_id=2, t_s=1.1, x_g=0.0, y_g=0.0, z_g=1.0))
        self.assertIsInstance(p1, Kx134LiveSamplePoint)
        self.assertAlmostEqual(p1.g_abs, 5.0)
        self.assertAlmostEqual(p2.g_abs, 1.0)
        self.assertEqual(buffer.counts(), {1: 1, 2: 1})

    def test_respects_window_and_maxlen(self) -> None:
        buffer = Kx134LivePlotBuffer(window_s=2, max_points_per_sensor=3)
        for index in range(5):
            buffer.add_sample(make_sample(sensor_id=1, t_s=float(index), seq=index))
        series = buffer.series(1, "x_g")
        self.assertLessEqual(len(series), 3)
        self.assertTrue(all(t_s >= 2.0 for t_s, _value in series))

    def test_does_not_modify_original_sample_or_export_forbidden_names(self) -> None:
        sample = make_sample(sensor_id=1, t_s=0.0, x_g=0.2, y_g=0.3, z_g=0.4)
        before = asdict(sample)
        buffer = Kx134LivePlotBuffer()
        point = buffer.add_sample(sample)
        after = asdict(sample)
        self.assertEqual(before, after)
        point_fields = set(asdict(point))
        self.assertIn("g_abs", point_fields)
        for forbidden in ("g_norm", "g_norm_est", "mv_x", "mv_y", "mv_z"):
            self.assertNotIn(forbidden, point_fields)

    def test_clear_and_window_change(self) -> None:
        buffer = Kx134LivePlotBuffer(window_s=30)
        buffer.add_sample(make_sample(sensor_id=1, t_s=1.0))
        buffer.set_window_s(10)
        self.assertEqual(buffer.window_s, 10.0)
        buffer.clear()
        self.assertEqual(buffer.counts(), {1: 0, 2: 0})

    def test_series_rejects_unknown_axis(self) -> None:
        buffer = Kx134LivePlotBuffer()
        with self.assertRaises(ValueError):
            buffer.series(1, "g_norm")


if __name__ == "__main__":
    unittest.main()

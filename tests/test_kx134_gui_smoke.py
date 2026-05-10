from __future__ import annotations

import unittest
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))


class TestKx134GuiSmoke(unittest.TestCase):
    def test_imports_and_validation_helpers(self) -> None:
        from gui import kx134_live_gui, ui_components, ui_theme

        self.assertEqual(ui_theme.DEFAULT_WINDOW_SIZE, "1180x760")
        self.assertLessEqual(ui_theme.MIN_WINDOW_SIZE[0], 980)
        self.assertLessEqual(ui_theme.MIN_WINDOW_SIZE[1], 640)
        self.assertTrue(hasattr(ui_components, "ScrollableFrame"))
        self.assertEqual(kx134_live_gui.validate_capture_duration(10), 10.0)
        self.assertEqual(kx134_live_gui.validate_capture_duration(1567), 1567.0)
        self.assertEqual(
            [kx134_live_gui.validate_expected_sample_rate(value) for value in (100, 200, 400, 800)],
            [100, 200, 400, 800],
        )
        with self.assertRaises(ValueError):
            kx134_live_gui.validate_capture_duration(0)
        with self.assertRaises(ValueError):
            kx134_live_gui.validate_expected_sample_rate(500)

    def test_parse_smoke_args(self) -> None:
        from gui import kx134_live_gui

        args = kx134_live_gui.parse_args(["--smoke", "--close-after-ms", "100", "--duration-s", "10"])
        self.assertTrue(args.smoke)
        self.assertEqual(args.close_after_ms, 100)
        self.assertEqual(args.duration_s, 10.0)


if __name__ == "__main__":
    unittest.main()

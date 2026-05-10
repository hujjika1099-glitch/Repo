from __future__ import annotations

import unittest
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))


class TestAppLauncherSmoke(unittest.TestCase):
    def test_import_and_entry_points(self) -> None:
        from gui import app_launcher

        self.assertTrue(hasattr(app_launcher, "AppLauncher"))
        self.assertTrue(hasattr(app_launcher, "create_app"))
        self.assertTrue(hasattr(app_launcher, "main"))
        self.assertEqual(app_launcher._module_command("gui.kx134_live_gui")[-1], "gui.kx134_live_gui")

    def test_parse_smoke_args(self) -> None:
        from gui import app_launcher

        args = app_launcher.parse_args(["--smoke", "--close-after-ms", "100"])
        self.assertTrue(args.smoke)
        self.assertEqual(args.close_after_ms, 100)


if __name__ == "__main__":
    unittest.main()

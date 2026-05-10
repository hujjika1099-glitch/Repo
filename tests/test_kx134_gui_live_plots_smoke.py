from __future__ import annotations

import argparse
import tkinter as tk
import unittest

from gui.kx134_live_gui import Kx134CaptureApp
from gui.kx134_live_plots import Kx134LivePlotsPanel

try:
    from tests.test_kx134_live_plot_buffer import make_sample
except ModuleNotFoundError:  # pragma: no cover - unittest discover path style
    from test_kx134_live_plot_buffer import make_sample


class Kx134GuiLivePlotsSmokeTests(unittest.TestCase):
    def test_plots_panel_builds_and_accepts_synthetic_samples(self) -> None:
        try:
            root = tk.Tk()
        except tk.TclError as exc:
            self.skipTest(f"tk unavailable: {exc}")
        root.withdraw()
        try:
            panel = Kx134LivePlotsPanel(root)
            panel.add_samples(
                [
                    make_sample(sensor_id=1, t_s=0.0, seq=1, x_g=0.0, y_g=0.0, z_g=1.0),
                    make_sample(sensor_id=2, t_s=0.0, seq=1, x_g=0.1, y_g=0.0, z_g=1.0),
                ]
            )
            panel.refresh(force=True)
            self.assertEqual(panel.buffer.counts(), {1: 1, 2: 1})
        finally:
            root.destroy()

    def test_kx134_gui_exposes_graphs_tab_without_hardware(self) -> None:
        args = argparse.Namespace(
            repo_root=".",
            port="",
            baud=921600,
            duration_s=10.0,
            expected_sample_rate=100,
            session_name="smoke",
            smoke=True,
            close_after_ms=0,
        )
        try:
            app = Kx134CaptureApp(args)
        except tk.TclError as exc:
            self.skipTest(f"tk unavailable: {exc}")
        app.withdraw()
        try:
            tabs = [app.notebook.tab(tab_id, "text") for tab_id in app.notebook.tabs()]
            self.assertIn("Graficas", tabs)
            self.assertTrue(hasattr(app, "live_plots"))
            app.live_plots.add_samples([make_sample(sensor_id=1, t_s=0.0, seq=1)])
            app.live_plots.refresh(force=True)
        finally:
            app.destroy()


if __name__ == "__main__":
    unittest.main()

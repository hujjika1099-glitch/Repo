from __future__ import annotations

import unittest
from unittest import mock

import gui.app_launcher as launcher


class AppLauncherFrozenRoutingTests(unittest.TestCase):
    def test_parse_args_modes_and_smoke(self) -> None:
        self.assertEqual(launcher.parse_args(["--mode", "launcher"]).mode, "launcher")
        self.assertEqual(launcher.parse_args(["--mode", "kx134"]).mode, "kx134")
        self.assertEqual(launcher.parse_args(["--mode", "adxl"]).mode, "adxl")
        self.assertTrue(launcher.parse_args(["--smoke"]).smoke)

    def test_is_frozen_exists(self) -> None:
        self.assertIsInstance(launcher.is_frozen(), bool)

    def test_frozen_child_command_uses_same_exe_without_module_flag(self) -> None:
        with mock.patch.object(launcher.sys, "executable", "Sistema_Captura_Acelerometria.exe"):
            command = launcher.child_command_for_mode("kx134", frozen=True)
        self.assertEqual(command, ["Sistema_Captura_Acelerometria.exe", "--mode", "kx134"])
        self.assertNotIn("-m", command)
        self.assertNotIn("gui.kx134_live_gui", command)

    def test_development_child_command_routes_through_launcher_module(self) -> None:
        command = launcher.child_command_for_mode("adxl", frozen=False)
        self.assertIn("-m", command)
        self.assertIn("gui.app_launcher", command)
        self.assertEqual(command[-2:], ["--mode", "adxl"])

    def test_bad_child_mode_rejected(self) -> None:
        with self.assertRaises(ValueError):
            launcher.child_command_for_mode("bad")


if __name__ == "__main__":
    unittest.main()

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Smoke test for KX134 GUI and app launcher")
    parser.add_argument("--output", default=str(ROOT / "reports/kx134_gui_validation/TICKET_018_gui_smoke_output.json"))
    return parser.parse_args()


def inspect_kx134() -> dict[str, object]:
    from gui import kx134_live_gui

    args = kx134_live_gui.parse_args(
        [
            "--repo-root",
            str(ROOT),
            "--port",
            "COM4",
            "--baud",
            "921600",
            "--duration-s",
            "10",
            "--expected-sample-rate",
            "100",
            "--session-name",
            "ticket018_smoke",
            "--smoke",
            "--close-after-ms",
            "10",
        ]
    )
    app = kx134_live_gui.create_app(args)
    app.update_idletasks()
    min_width, min_height = app.minsize()
    tabs = [app.notebook.tab(index, "text") for index in range(app.notebook.index("end"))]
    result = {
        "title": app.title(),
        "min_width": min_width,
        "min_height": min_height,
        "tabs": tabs,
        "has_start_button": hasattr(app, "start_button"),
        "has_file_panel": hasattr(app, "file_panel"),
        "duration_10_valid": kx134_live_gui.validate_capture_duration(10) == 10.0,
        "duration_1567_valid": kx134_live_gui.validate_capture_duration(1567) == 1567.0,
        "sample_rates_valid": [
            kx134_live_gui.validate_expected_sample_rate(value) for value in (100, 200, 400, 800)
        ],
        "baud_default": app.baud_var.get(),
    }
    app.destroy()
    return result


def inspect_launcher() -> dict[str, object]:
    from gui import app_launcher

    args = app_launcher.parse_args(["--smoke", "--close-after-ms", "10"])
    app = app_launcher.create_app(args)
    app.update_idletasks()
    min_width, min_height = app.minsize()
    result = {
        "title": app.title(),
        "min_width": min_width,
        "min_height": min_height,
        "has_open_kx134": hasattr(app, "open_kx134"),
        "has_open_adxl": hasattr(app, "open_adxl"),
    }
    app.destroy()
    return result


def main() -> int:
    args = parse_args()
    output = Path(args.output).resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    failures: list[str] = []
    try:
        kx134 = inspect_kx134()
    except Exception as exc:
        kx134 = {"error": str(exc)}
        failures.append(f"kx134_gui:{exc}")
    try:
        launcher = inspect_launcher()
    except Exception as exc:
        launcher = {"error": str(exc)}
        failures.append(f"app_launcher:{exc}")

    if not failures:
        if kx134["title"] != "Sistema de Captura Dual KX134":
            failures.append("kx134_title_unexpected")
        if int(kx134["min_width"]) > 980 or int(kx134["min_height"]) > 640:
            failures.append("kx134_min_size_too_large")
        expected_tabs = {"Conexion", "Captura", "Sensores", "Diagnostico", "Exportacion"}
        if set(kx134["tabs"]) != expected_tabs:
            failures.append("kx134_tabs_missing")
        if launcher["title"] != "Sistema de Captura de Acelerometria":
            failures.append("launcher_title_unexpected")

    result = {
        "pass": not failures,
        "failures": failures,
        "kx134_gui": kx134,
        "app_launcher": launcher,
        "visual_checks": {
            "default_window_size": "1180x760",
            "min_window_size": "980x640",
            "uses_tabs": not failures and len(kx134.get("tabs", [])) == 5,
            "requires_hardware": False,
        },
    }
    output.write_text(json.dumps(result, indent=2, ensure_ascii=True), encoding="utf-8")
    print(str(output))
    return 0 if result["pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())

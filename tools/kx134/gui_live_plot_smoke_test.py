from __future__ import annotations

import argparse
import json
import math
import sys
from dataclasses import asdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from gui.kx134_live_core import Kx134Sample  # noqa: E402
from gui.kx134_live_gui import create_app  # noqa: E402
from gui.kx134_stream_contract import KX134_EXPECTED_HEADER  # noqa: E402


def make_sample(sensor_id: int, t_s: float, seq: int) -> Kx134Sample:
    phase = seq / 10.0
    return Kx134Sample(
        protocol_version="kx134.v3",
        session_id="ticket019_smoke",
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
        x_raw=100 + seq,
        y_raw=200 + seq,
        z_raw=4200,
        x_g=0.08 * math.sin(phase),
        y_g=0.05 * math.cos(phase),
        z_g=1.0 + 0.12 * math.sin(phase * 0.5),
        sample_rate_hz=100,
        odr_hz=100,
        range_g=8,
        calibration_id=f"kx134_sensor_{sensor_id}_test",
        calibration_applied=True,
        packet_status="OK",
        packet_error_code="OK",
        firmware_version="kx134_dual_espnow.0.1.0",
        contract_version="kx134.v3",
    )


def run_smoke() -> dict[str, object]:
    errors: list[str] = []
    samples_s1 = [make_sample(1, index * 0.01, index) for index in range(120)]
    samples_s2 = [make_sample(2, index * 0.01, index) for index in range(120)]
    app = None
    try:
        app = create_app(
            argparse.Namespace(
                repo_root=str(ROOT),
                port="",
                baud=921600,
                duration_s=10.0,
                expected_sample_rate=100,
                session_name="ticket019_smoke",
                smoke=True,
                close_after_ms=0,
            )
        )
        app.withdraw()
        tabs = [app.notebook.tab(tab_id, "text") for tab_id in app.notebook.tabs()]
        app.live_plots.add_samples(samples_s1 + samples_s2)
        app.live_plots.refresh(force=True)
        app.update_idletasks()
        counts = app.live_plots.buffer.counts()
        visual_point = app.live_plots.buffer.add_sample(make_sample(1, 2.0, 999))
        header_text = ",".join(KX134_EXPECTED_HEADER)
        forbidden_export_fields = [field for field in ("g_norm", "g_norm_est", "mv_x", "mv_y", "mv_z", "voltage") if field in header_text]
        return {
            "pass": "Graficas" in tabs and counts.get(1, 0) >= 120 and counts.get(2, 0) >= 120 and not forbidden_export_fields,
            "plots_created": "Graficas" in tabs,
            "samples_injected_sensor_1": counts.get(1, 0),
            "samples_injected_sensor_2": counts.get(2, 0),
            "g_abs_visual_only": "g_abs" in asdict(visual_point) and "g_abs" not in KX134_EXPECTED_HEADER,
            "export_fields_unchanged": not forbidden_export_fields,
            "errors": errors,
        }
    except Exception as exc:  # pragma: no cover - user-facing smoke report
        errors.append(f"{type(exc).__name__}: {exc}")
        return {
            "pass": False,
            "plots_created": False,
            "samples_injected_sensor_1": 0,
            "samples_injected_sensor_2": 0,
            "g_abs_visual_only": False,
            "export_fields_unchanged": False,
            "errors": errors,
        }
    finally:
        if app is not None:
            app.destroy()


def main(argv: list[str] | None = None) -> None:
    parser = argparse.ArgumentParser(description="Smoke test for KX134 live plot UI")
    parser.add_argument("--output", default="reports/kx134_gui_validation/TICKET_019_live_plot_smoke_output.json")
    args = parser.parse_args(argv)
    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    payload = run_smoke()
    with output.open("w", encoding="utf-8") as handle:
        json.dump(payload, handle, indent=2, ensure_ascii=True)
    print(json.dumps(payload, indent=2, ensure_ascii=True))
    if not payload.get("pass"):
        raise SystemExit(1)


if __name__ == "__main__":
    main()

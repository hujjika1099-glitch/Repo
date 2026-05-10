from __future__ import annotations

import argparse
import json
import tempfile
from collections import Counter
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))

from gui.kx134_live_core import export_kx134_session, parse_kx134_stream_line


DEFAULT_LOG = (
    ROOT / "reports/kx134_test_runs/TICKET_014_static_receiver_monitor_20260510_112712.txt"
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Replay KX134 receiver logs through GUI core")
    parser.add_argument("--log", default=str(DEFAULT_LOG))
    parser.add_argument("--output-root", default=str(ROOT / "reports/kx134_gui_validation"))
    parser.add_argument("--session-name", default="ticket015_static_replay")
    parser.add_argument("--expected-sample-rate", type=int, default=100)
    parser.add_argument("--duration-label", default="")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    log_path = Path(args.log).resolve()
    output_root = Path(args.output_root).resolve()
    output_root.mkdir(parents=True, exist_ok=True)

    samples = []
    metadata_lines = []
    invalid_lines = 0
    header_seen = False
    parse_errors: Counter[str] = Counter()

    for line in log_path.read_text(encoding="utf-8").splitlines():
        parsed = parse_kx134_stream_line(line)
        if parsed.kind == "data" and parsed.sample is not None:
            samples.append(parsed.sample)
        elif parsed.kind == "metadata":
            metadata_lines.append(parsed.text)
        elif parsed.kind == "header":
            header_seen = True
        elif parsed.kind == "invalid":
            invalid_lines += 1
            parse_errors[parsed.error or "invalid"] += 1

    export_root = Path(tempfile.mkdtemp(prefix="kx134_ticket015_replay_"))
    result = export_kx134_session(
        samples=samples,
        metadata_lines=metadata_lines,
        output_root=export_root,
        session_name=args.session_name,
        expected_sample_rate_hz=args.expected_sample_rate,
        invalid_lines=invalid_lines,
        parse_errors=dict(parse_errors),
        file_prefix="ticket015_replay",
    )
    result.header_seen = header_seen

    validation = {
        "ticket": "TICKET_015",
        "log": str(log_path),
        "duration_label": args.duration_label,
        "header_seen": header_seen,
        "invalid_lines": invalid_lines,
        "parse_errors": dict(parse_errors),
        "summary": result.summary,
        "csv_exported": result.artifacts.raw_csv_abs.exists(),
        "metadata_json_exists": result.artifacts.session_json_abs.exists(),
        "summary_exists": result.artifacts.summary_abs.exists(),
        "export_artifacts": {
            "raw_csv": str(result.artifacts.raw_csv_abs),
            "session_json": str(result.artifacts.session_json_abs),
            "summary": str(result.artifacts.summary_abs),
        },
        "acceptance": {
            "both_sensors_present": result.summary["samples_by_sensor"].get("1", 0) > 0
            and result.summary["samples_by_sensor"].get("2", 0) > 0,
            "sensor_1_rows_gt_1000": result.summary["samples_by_sensor"].get("1", 0) > 1000,
            "sensor_2_rows_gt_1000": result.summary["samples_by_sensor"].get("2", 0) > 1000,
            "no_forbidden_fields": not result.summary["forbidden_fields_detected"],
            "csv_exported": result.artifacts.raw_csv_abs.exists(),
            "metadata_json_exists": result.artifacts.session_json_abs.exists(),
            "summary_exists": result.artifacts.summary_abs.exists(),
        },
    }
    validation["ready_for_gui_hardware_validation"] = all(validation["acceptance"].values())

    output_json = output_root / "TICKET_015_replay_validation_output.json"
    output_json.write_text(json.dumps(validation, indent=2, ensure_ascii=True), encoding="utf-8")

    output_summary = output_root / "TICKET_015_GUI_KX134_VALIDATION_SUMMARY.md"
    output_summary.write_text(
        "\n".join(
            [
                "# TICKET 015 - GUI KX134 validation",
                "",
                f"- Log usado: `{log_path}`",
                f"- Rows sensor 1: `{result.summary['samples_by_sensor'].get('1', 0)}`",
                f"- Rows sensor 2: `{result.summary['samples_by_sensor'].get('2', 0)}`",
                f"- Effective Hz sensor 1: `{result.summary['effective_hz_by_sensor'].get('1', 0.0):.6f}`",
                f"- Effective Hz sensor 2: `{result.summary['effective_hz_by_sensor'].get('2', 0.0):.6f}`",
                f"- Seq gaps sensor 1: `{result.summary['seq_gaps_by_sensor'].get('1', 0)}`",
                f"- Seq gaps sensor 2: `{result.summary['seq_gaps_by_sensor'].get('2', 0)}`",
                f"- Invalid lines: `{invalid_lines}`",
                f"- Campos prohibidos: `{result.summary['forbidden_fields_detected']}`",
                f"- CSV exportado: `{result.artifacts.raw_csv_abs}`",
                f"- Metadata JSON: `{result.artifacts.session_json_abs}`",
                f"- Summary: `{result.artifacts.summary_abs}`",
                f"- READY_FOR_GUI_HARDWARE_VALIDATION: `{validation['ready_for_gui_hardware_validation']}`",
                "",
            ]
        ),
        encoding="utf-8",
    )
    print(str(output_json))
    return 0 if validation["ready_for_gui_hardware_validation"] else 1


if __name__ == "__main__":
    raise SystemExit(main())

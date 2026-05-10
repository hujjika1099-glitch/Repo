from __future__ import annotations

import argparse
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]

PCB_BLOCKERS = [
    "final_power_source_not_defined",
    "sensor_connectors_not_defined",
    "final_cable_lengths_not_defined",
    "mechanical_mounting_not_defined",
    "axis_orientation_on_enclosure_or_pcb_not_defined",
    "receiver_and_sensor_node_physical_locations_not_defined",
]


EVIDENCE_FILES = {
    "sensor_1_calibration": "config/calibrations/kx134_sensor_1.json",
    "sensor_2_calibration": "config/calibrations/kx134_sensor_2.json",
    "dual_espnow": "reports/kx134_test_runs/TICKET_013_DUAL_ESPNOW_TEST_SUMMARY.md",
    "sync_precheck": "reports/kx134_test_runs/TICKET_014_DUAL_SYNC_PRECHECK_SUMMARY.md",
    "gui_hardware": "reports/kx134_gui_validation/TICKET_016_GUI_HARDWARE_VALIDATION_SUMMARY.md",
    "export_hardening": "reports/kx134_gui_validation/TICKET_017_EXPORT_HARDENING_SUMMARY.md",
    "visual_redesign": "reports/kx134_gui_validation/TICKET_018_GUI_VISUAL_REDESIGN_SUMMARY.md",
    "live_plots": "reports/kx134_gui_validation/TICKET_019_GUI_LIVE_PLOTS_SUMMARY.md",
    "windows_packaging": "reports/kx134_gui_validation/TICKET_020_WINDOWS_PACKAGING_SUMMARY.md",
    "external_visual_qa": "reports/kx134_gui_validation/TICKET_021_EXTERNAL_PC_QA_SUMMARY.md",
    "prototype_validation": "reports/prototype_validation/TICKET_022_PROTOTYPE_VALIDATION_SUMMARY.md",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Build KX134 prototype delivery readiness report")
    parser.add_argument("--output", required=True)
    return parser.parse_args()


def read_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def exists(relative_path: str) -> bool:
    return (ROOT / relative_path).exists()


def main() -> int:
    args = parse_args()
    node_map = read_json(ROOT / "config/kx134_node_map.json")
    prototype = read_json(ROOT / "reports/prototype_validation/TICKET_022_prototype_validation_output.json")
    blockers = list(node_map.get("pcb_design_blockers") or PCB_BLOCKERS)

    evidence = {
        key: {
            "path": path,
            "exists": exists(path),
        }
        for key, path in EVIDENCE_FILES.items()
    }
    missing_evidence = [key for key, item in evidence.items() if not item["exists"]]

    prototype_delivery_ready = bool(
        node_map.get("ready_for_prototype_delivery")
        and prototype.get("pass")
        and node_map.get("last_external_pc_qa_decision") == "YES"
        and not missing_evidence
    )
    pcb_authorized = False

    output = {
        "prototype_delivery_package_ready": prototype_delivery_ready,
        "pcb_design_authorized": pcb_authorized,
        "system_status": node_map.get("status"),
        "hardware": {
            "topology": node_map.get("topology_version"),
            "total_esp32_required": node_map.get("total_esp32_required"),
            "nodes": node_map.get("nodes", []),
        },
        "firmware": {
            "receiver_firmware": "kx134_dual_espnow",
            "receiver_firmware_version": "kx134_dual_espnow.0.1.0",
            "sample_rate_hz": 100,
            "odr_hz": 100,
            "range_g": 8,
            "espnow_channel": 1,
        },
        "gui": {
            "kx134_gui_validated": True,
            "live_plots_validated": True,
            "adxl335_preserved": True,
            "export_hardened": True,
        },
        "packaging": {
            "product": "Sistema de Captura de Acelerometria",
            "exe": "Sistema_Captura_Acelerometria.exe",
            "onedir": True,
            "external_visual_qa_passed": node_map.get("last_external_pc_qa_decision") == "YES",
            "external_hardware_capture_run": node_map.get("external_pc_hardware_capture_run"),
        },
        "validation": {
            "prototype_session_pass": prototype.get("pass"),
            "rows_by_sensor": prototype.get("rows_by_sensor"),
            "effective_hz_by_sensor": prototype.get("effective_hz_by_sensor"),
            "seq_gaps_by_sensor": prototype.get("seq_gaps_by_sensor"),
            "invalid_lines": prototype.get("invalid_lines"),
            "duplicate_keys_by_sensor": prototype.get("duplicate_keys_by_sensor"),
            "forbidden_fields_detected": prototype.get("forbidden_fields_detected"),
            "live_plot_confirmed": prototype.get("live_plot_confirmed"),
        },
        "evidence": evidence,
        "warnings": [
            "Sensor 1 had 2 seq gaps in the controlled 60 s prototype session.",
            "External hardware capture was not executed; development PC hardware capture was previously validated.",
            "Scaling 125% and 150% remain to be tested.",
            "Corporate icon pending.",
            "Digital signature pending.",
            "Firmware sample_rate_hz command from GUI remains pending.",
        ],
        "open_items": [
            "Define final physical/mechanical design before PCB.",
            "Decide whether external PC hardware capture is required for client QA.",
            "Decide whether corporate icon and digital signature are required.",
            "Decide whether firmware sample-rate control from GUI is required.",
        ],
        "pcb_blockers": blockers,
        "missing_evidence": missing_evidence,
        "next_recommended_ticket": "TICKET 024 - Documentacion de usuario/cliente y guia de operacion",
    }

    output_path = ROOT / args.output
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(output, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(output_path)
    return 0 if prototype_delivery_ready else 1


if __name__ == "__main__":
    raise SystemExit(main())

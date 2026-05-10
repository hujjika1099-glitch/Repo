from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parents[2]

REQUIRED_CLOSED_DECISIONS = {
    "power": [
        "final_source",
        "target_voltage",
        "estimated_current",
        "protection",
        "power_connector",
        "sensor_nodes_powering",
        "receiver_powered_by_pc_usb",
    ],
    "connectors": [
        "kx134_to_esp32",
        "qwiic_or_direct_pcb",
        "detachable_required",
        "preferred_family",
        "polarization_or_keying",
    ],
    "cabling": [
        "sensor_1_length",
        "sensor_2_length",
        "receiver_pc_length",
        "cable_type",
        "strain_relief_required",
    ],
    "mechanical_mounting": [
        "sensor_1_mount_location",
        "sensor_2_mount_location",
        "mounting_method",
        "esp32_with_sensor_or_separate",
        "enclosure_required",
        "reset_boot_usb_access",
    ],
    "axis_orientation": [
        "sensor_1_xyz_orientation",
        "sensor_2_xyz_orientation",
        "visible_axis_marks",
        "client_coordinate_alignment",
    ],
    "receiver_location": [
        "receiver_location",
        "always_connected_to_pc",
        "receiver_enclosure",
    ],
    "client_constraints": [
        "maximum_dimensions",
        "portable_system",
    ],
}


def _load_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def _status_of(decisions: dict[str, Any], category: str, key: str) -> str:
    value = decisions.get(category, {}).get(key, {})
    if isinstance(value, dict):
        return str(value.get("status", "missing")).lower()
    return "missing"


def validate(decisions_path: Path, node_map_path: Path) -> dict[str, Any]:
    failures: list[str] = []
    warnings: list[str] = []
    next_required_decisions: list[str] = []

    if not decisions_path.exists():
        failures.append(f"decisions file not found: {decisions_path}")
        decisions: dict[str, Any] = {}
    else:
        decisions = _load_json(decisions_path)

    if not node_map_path.exists():
        failures.append(f"node_map file not found: {node_map_path}")
        node_map: dict[str, Any] = {}
    else:
        node_map = _load_json(node_map_path)

    prototype_ready = bool(
        node_map.get("prototype_delivery_package_ready")
        or node_map.get("ready_for_prototype_delivery")
    )
    if not prototype_ready:
        failures.append("prototype is not marked as delivery-ready in node_map")

    physical_complete = bool(decisions.get("pcb_physical_decisions_complete"))
    pcb_authorized = bool(decisions.get("pcb_design_authorized"))
    critical_blockers = list(decisions.get("critical_blockers", []))
    all_decisions = decisions.get("decisions", {})

    for category, keys in REQUIRED_CLOSED_DECISIONS.items():
        for key in keys:
            status = _status_of(all_decisions, category, key)
            if status != "closed":
                next_required_decisions.append(f"{category}.{key}")

    if pcb_authorized:
        if not physical_complete:
            failures.append("pcb_design_authorized=true while pcb_physical_decisions_complete=false")
        if critical_blockers:
            failures.append("pcb_design_authorized=true while critical_blockers are present")
        if next_required_decisions:
            failures.append("pcb_design_authorized=true while required decisions are not closed")
    else:
        if critical_blockers or next_required_decisions:
            warnings.append("PCB remains blocked by pending physical decisions.")

    validation_pass = not failures
    return {
        "validation_pass": validation_pass,
        "prototype_ready": prototype_ready,
        "pcb_physical_decisions_complete": physical_complete,
        "pcb_design_authorized": pcb_authorized,
        "critical_blockers": critical_blockers,
        "warnings": warnings,
        "failures": failures,
        "next_required_decisions": next_required_decisions,
        "decision": "PCB_DESIGN_AUTHORIZED=YES" if pcb_authorized and validation_pass else "PCB_DESIGN_AUTHORIZED=NO",
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate KX134 PCB physical decisions.")
    parser.add_argument("--decisions", required=True, help="Physical decisions JSON path.")
    parser.add_argument("--node-map", required=True, help="KX134 node map JSON path.")
    parser.add_argument("--output", required=True, help="Output JSON path.")
    args = parser.parse_args()

    result = validate(REPO_ROOT / args.decisions, REPO_ROOT / args.node_map)
    output = REPO_ROOT / args.output
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(result, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(json.dumps(result, indent=2, ensure_ascii=False))
    return 0 if result["validation_pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())

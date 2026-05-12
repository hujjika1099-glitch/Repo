"""Validate the final KX134 project closeout state."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


REQUIRED_DOCS = [
    "docs/kx134_migration/PROJECT_FINAL_STATUS.md",
    "docs/kx134_migration/RELEASE_CANDIDATE_NOTES.md",
    "docs/kx134_migration/FINAL_HANDOVER_CHECKLIST.md",
    "docs/kx134_migration/PROTOTYPE_DELIVERY_PACKAGE.md",
    "docs/kx134_migration/client/DELIVERY_MANIFEST.md",
]


README_REQUIRED = [
    "KX134",
    "Sistema_Captura_Acelerometria.exe",
    "baquelada RevA",
    "funcional",
    "ADXL335",
    "legacy",
    "100",
    "8",
    "921600",
    "Produccion industrial",
]


AGENTS_REQUIRED = [
    "KX134",
    "baquelada RevA funcional validada por el experto",
    "ADXL335",
    "legacy",
    "No modificar firmware",
    "No modificar calibraciones",
]


OBSOLETE_PATTERNS = [
    "under_review",
    "no energizar",
    "no debe energizarse",
    "no aceptada para uso de prototipo",
    "BAQUELADA_REVA_ACCEPTED_FOR_PROTOTYPE_USE = NO",
    "PCB_DESIGN_AUTHORIZED = NO",
    "PCB no autorizada",
    "baquelada no autorizada",
    "decisiones fisicas pendientes",
    "decisiones físicas pendientes",
]


ALLOWED_CONTEXT_MARKERS = [
    "estado anterior",
    "historico",
    "historica",
    "legacy",
    "produccion",
    "fabricacion",
    "manufacturing",
    "no equivale",
    "no constituye",
    "mass production",
    "previous",
    "ticket 026",
    "no se declara producto comercial",
    "estado previo",
    "estado anterior",
    "antes de ticket 028",
    "reemplaza",
    "fue el estado anterior",
]


HISTORICAL_ALLOWED_PREFIXES = (
    "docs/kx134_migration/tickets/",
    "docs/kx134_migration/pcb/",
    "reports/final_release/TICKET_028_",
)


def read_text(rel_path: str) -> str:
    return (ROOT / rel_path).read_text(encoding="utf-8", errors="replace")


def load_json(rel_path: str) -> dict:
    return json.loads((ROOT / rel_path).read_text(encoding="utf-8"))


def pattern_key(pattern: str) -> str:
    return {
        "under_review": "old_review_status",
        "no energizar": "old_do_not_power_warning",
        "no debe energizarse": "old_do_not_power_warning",
        "no aceptada para uso de prototipo": "old_not_accepted_for_prototype",
        "BAQUELADA_REVA_ACCEPTED_FOR_PROTOTYPE_USE = NO": "old_baquelada_not_accepted_flag",
        "PCB_DESIGN_AUTHORIZED = NO": "old_pcb_design_not_authorized_flag",
        "PCB no autorizada": "old_pcb_not_authorized_text",
        "baquelada no autorizada": "old_baquelada_not_authorized_text",
        "decisiones fisicas pendientes": "old_pending_physical_decisions_text",
        "decisiones físicas pendientes": "old_pending_physical_decisions_text",
    }.get(pattern, "old_state_reference")


def sanitize_text(text: str) -> str:
    sanitized = text
    for pattern in OBSOLETE_PATTERNS:
        sanitized = sanitized.replace(pattern, f"<{pattern_key(pattern)}>")
    return sanitized


def classify_stale(file_rel: str, lower_line: str) -> str:
    if file_rel.startswith(HISTORICAL_ALLOWED_PREFIXES):
        return "historical_allowed"
    if any(marker in lower_line for marker in ALLOWED_CONTEXT_MARKERS):
        return "historical_allowed"
    if file_rel in {
        "README.md",
        "AGENTS.md",
        "config/kx134_node_map.json",
        "config/kx134_project_final_status.json",
        "config/kx134_baquelada_revA_review.json",
        "config/kx134_physical_design_decisions.json",
    }:
        return "blocking"
    if file_rel.startswith("docs/kx134_migration/client/"):
        return "blocking"
    if file_rel.startswith("hardware/pcb/baquelada_revA/"):
        return "blocking"
    if file_rel in {
        "docs/README.md",
        "docs/kx134_migration/INDEX.md",
        "docs/kx134_migration/REPOSITORY_STATUS.md",
        "docs/kx134_migration/PROTOTYPE_DELIVERY_PACKAGE.md",
        "docs/kx134_migration/PROJECT_FINAL_STATUS.md",
        "docs/kx134_migration/RELEASE_CANDIDATE_NOTES.md",
        "docs/kx134_migration/OPEN_ITEMS_AND_RISKS.md",
        "docs/kx134_migration/PCB_BAQUELADA_CRITERIA.md",
        "docs/kx134_migration/VALIDATION_SUMMARY.md",
        "docs/kx134_migration/VALIDATION_EVIDENCE_MATRIX.md",
    }:
        return "blocking"
    return "warning"


def scan_stale(output_rel_path: str) -> dict[str, list[dict[str, object]]]:
    paths = [
        ROOT / "README.md",
        ROOT / "AGENTS.md",
        ROOT / "docs" / "kx134_migration",
        ROOT / "hardware" / "pcb" / "baquelada_revA",
        ROOT / "config",
        ROOT / "reports" / "final_release",
    ]
    files: list[Path] = []
    for path in paths:
        if path.is_file():
            files.append(path)
        elif path.exists():
            files.extend([p for p in path.rglob("*") if p.suffix.lower() in {".md", ".json"}])

    findings: dict[str, list[dict[str, object]]] = {
        "blocking": [],
        "warning": [],
        "historical_allowed": [],
    }
    for path in sorted(files):
        file_rel = path.relative_to(ROOT).as_posix()
        if file_rel == output_rel_path.replace("\\", "/"):
            continue
        text = path.read_text(encoding="utf-8", errors="replace")
        for line_no, line in enumerate(text.splitlines(), start=1):
            lower = line.lower()
            for pattern in OBSOLETE_PATTERNS:
                if pattern.lower() in lower:
                    severity = classify_stale(file_rel, lower)
                    findings[severity].append(
                        {
                            "file": file_rel,
                            "line": line_no,
                            "pattern_key": pattern_key(pattern),
                            "severity": severity,
                            "text": sanitize_text(line.strip()[:220]),
                        }
                    )
    return findings


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--output",
        default="reports/final_release/TICKET_028_final_project_state_output.json",
    )
    args = parser.parse_args()

    failures: list[str] = []
    warnings: list[str] = []

    readme = read_text("README.md")
    agents = read_text("AGENTS.md")

    missing_readme = [term for term in README_REQUIRED if term not in readme]
    if missing_readme:
        failures.append(f"README missing final-state terms: {missing_readme}")

    forbidden_current = [
        phrase
        for phrase in (
            "Baquelada RevA registrada y en estado `under_review`",
            "Aceptada para uso de prototipo: NO",
            "No energizar RevA",
            "Proyecto de Maestria: ADXL335 + ESP32",
        )
        if phrase in readme
    ]
    if forbidden_current:
        failures.append(f"README has obsolete current-state phrases: {forbidden_current}")

    missing_agents = [term for term in AGENTS_REQUIRED if term not in agents]
    if missing_agents:
        failures.append(f"AGENTS missing final-state terms: {missing_agents}")

    for rel_path in REQUIRED_DOCS:
        if not (ROOT / rel_path).exists():
            failures.append(f"Missing final-state document: {rel_path}")

    node = load_json("config/kx134_node_map.json")
    final_status = load_json("config/kx134_project_final_status.json")
    review = load_json("config/kx134_baquelada_revA_review.json")

    checks = {
        "node_project_functional_complete": node.get("project_functional_complete") is True,
        "node_release_candidate_ready": node.get("prototype_release_candidate_ready") is True,
        "node_baquelada_validated": node.get("baquelada_revA_functional_validated_by_expert") is True,
        "node_baquelada_accepted": node.get("baquelada_revA_accepted_for_prototype_use") is True,
        "node_production_package_false": node.get("production_manufacturing_package_ready") is False,
        "final_project_complete": final_status.get("project_functional_complete") is True,
        "final_client_delivery": final_status.get("decision", {}).get("ready_for_client_functional_delivery") is True,
        "final_mass_production_false": final_status.get("decision", {}).get("ready_for_mass_production") is False,
        "review_status": review.get("status") == "functional_validated_by_expert",
        "review_accepted": review.get("decision", {}).get("baquelada_revA_accepted_for_prototype_use") is True,
    }
    failed_checks = {key: value for key, value in checks.items() if not value}
    if failed_checks:
        failures.append(f"Final-state checks failed: {failed_checks}")

    stale_by_severity = scan_stale(args.output)
    if stale_by_severity["blocking"]:
        failures.append(f"Blocking current-state stale references: {stale_by_severity['blocking']}")
    if stale_by_severity["warning"]:
        warnings.append("Non-blocking stale references remain outside final/current documentation scope.")

    output = {
        "pass": not failures,
        "failures": failures,
        "warnings": warnings,
        "project_functional_complete": checks["node_project_functional_complete"] and checks["final_project_complete"],
        "prototype_release_candidate_ready": checks["node_release_candidate_ready"],
        "baquelada_revA_functional_validated_by_expert": checks["node_baquelada_validated"],
        "baquelada_revA_accepted_for_prototype_use": checks["node_baquelada_accepted"],
        "production_manufacturing_package_ready": node.get("production_manufacturing_package_ready"),
        "prototype_revA_ready": node.get("prototype_pcb_revA_authorized_for_use") is True,
        "production_manufacturing_ready": node.get("production_manufacturing_package_ready") is True,
        "repository_final_state_ready": not failures,
        "checks": checks,
        "stale_references": (
            stale_by_severity["blocking"]
            + stale_by_severity["warning"]
            + stale_by_severity["historical_allowed"]
        ),
        "stale_references_by_severity": stale_by_severity,
        "blocking_stale_references": stale_by_severity["blocking"],
        "warning_stale_references": stale_by_severity["warning"],
        "historical_allowed_references": stale_by_severity["historical_allowed"],
        "docs_checked": [str(path) for path in REQUIRED_DOCS],
        "current_state_consistent": not stale_by_severity["blocking"] and not failures,
    }

    out_path = ROOT / args.output
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(output, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(json.dumps(output, indent=2, ensure_ascii=False))
    return 0 if output["pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())

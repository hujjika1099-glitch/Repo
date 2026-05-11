"""Validate repository production-readiness documentation for TICKET 027.

The validator is intentionally documentation-focused. It does not modify the
repository and uses only the Python standard library.
"""

from __future__ import annotations

import argparse
import json
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


REQUIRED_DOCS = [
    "docs/README.md",
    "docs/assets/README.md",
    "docs/assets/diagrams/kx134_architecture.md",
    "docs/assets/diagrams/kx134_export_flow.md",
    "docs/assets/diagrams/repository_structure.md",
    "docs/kx134_migration/INDEX.md",
    "docs/kx134_migration/REPOSITORY_STATUS.md",
    "docs/kx134_migration/ARCHITECTURE_OVERVIEW.md",
    "docs/kx134_migration/OPERATIONS_OVERVIEW.md",
    "docs/kx134_migration/DEVELOPMENT_GUIDE.md",
    "docs/kx134_migration/VALIDATION_SUMMARY.md",
    "docs/kx134_migration/LEGACY_ADXL335_NOTES.md",
    "docs/kx134_migration/REPOSITORY_MAINTENANCE.md",
    "docs/kx134_migration/client/QUICK_START_GUIDE.md",
    "docs/kx134_migration/client/USER_MANUAL_KX134_PROTOTYPE.md",
]


README_REQUIRED_TERMS = [
    "KX134",
    "Sistema_Captura_Acelerometria.exe",
    "Sensor 1",
    "Sensor 2",
    "ESP-NOW",
    "100",
    "8",
    "ADXL335",
    "legacy",
    "PCB final no autorizada",
]


AGENTS_REQUIRED_TERMS = [
    "KX134",
    "ADXL335",
    "legacy",
    "PCB final no autorizada",
    "No commitear binarios",
]


README_FORBIDDEN_CURRENT = [
    "ADXL335_Captura.exe",
    "ADXL335_Captura_dist.zip",
    "ADXL335 + ESP32",
    "GPIO32",
    "GPIO33",
    "GPIO34",
    "g_norm_est",
]


STALE_PATTERNS = [
    "ADXL335_Captura.exe",
    "ADXL335_Captura_dist.zip",
    "ADXL335 + ESP32",
    "sensor_B",
    "sensor_A",
    "GPIO32",
    "GPIO33",
    "GPIO34",
    "mv_x",
    "mv_y",
    "mv_z",
    "gx_est",
    "gy_est",
    "gz_est",
    "g_norm_est",
    "115200",
]


TRACKED_FORBIDDEN_PREFIXES = [
    "dist/",
    "build_work/",
    ".venv/",
    "data/raw/kx134_dual_live/",
    "data/processed/kx134_dual_live/",
    "reports/analysis_outputs/kx134_dual_live/",
]


def rel(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def read_text(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8", errors="replace")


def run_git_ls_files() -> list[str]:
    proc = subprocess.run(
        ["git", "ls-files"],
        cwd=ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if proc.returncode != 0:
        raise RuntimeError(proc.stderr.strip() or "git ls-files failed")
    return [line.strip().replace("\\", "/") for line in proc.stdout.splitlines() if line.strip()]


def scan_stale_references() -> list[dict[str, object]]:
    scan_paths = [
        ROOT / "README.md",
        ROOT / "AGENTS.md",
        ROOT / "docs" / "README.md",
        ROOT / "docs" / "kx134_migration",
    ]
    findings: list[dict[str, object]] = []
    files: list[Path] = []
    for path in scan_paths:
        if path.is_file():
            files.append(path)
        elif path.is_dir():
            files.extend(sorted(path.rglob("*.md")))

    for path in files:
        text = path.read_text(encoding="utf-8", errors="replace")
        for lineno, line in enumerate(text.splitlines(), start=1):
            for pattern in STALE_PATTERNS:
                if pattern in line:
                    lower = line.lower()
                    allowed = any(
                        marker in lower
                        for marker in (
                            "legacy",
                            "historico",
                            "historica",
                            "prohibido",
                            "no contiene",
                            "no son columnas actuales",
                            "no debe",
                            "preservado",
                            "deprecated",
                            "adxl335 legacy",
                        )
                    )
                    findings.append(
                        {
                            "file": rel(path),
                            "line": lineno,
                            "pattern": pattern,
                            "allowed_context": allowed,
                            "text": line.strip()[:220],
                        }
                    )
    return findings


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--output",
        default="reports/repository_health/TICKET_027_repository_readiness_output.json",
    )
    args = parser.parse_args()

    failures: list[str] = []
    warnings: list[str] = []

    readme_path = ROOT / "README.md"
    agents_path = ROOT / "AGENTS.md"
    if not readme_path.exists():
        failures.append("README.md missing")
        readme_text = ""
    else:
        readme_text = read_text("README.md")
    if not agents_path.exists():
        failures.append("AGENTS.md missing")
        agents_text = ""
    else:
        agents_text = read_text("AGENTS.md")

    missing_readme_terms = [term for term in README_REQUIRED_TERMS if term not in readme_text]
    if missing_readme_terms:
        failures.append(f"README missing terms: {missing_readme_terms}")

    missing_agents_terms = [term for term in AGENTS_REQUIRED_TERMS if term not in agents_text]
    if missing_agents_terms:
        failures.append(f"AGENTS missing terms: {missing_agents_terms}")

    forbidden_readme = [term for term in README_FORBIDDEN_CURRENT if term in readme_text]
    if forbidden_readme:
        failures.append(f"README has obsolete current-flow references: {forbidden_readme}")

    docs_present = {}
    for doc in REQUIRED_DOCS:
        exists = (ROOT / doc).exists()
        docs_present[doc] = exists
        if not exists:
            failures.append(f"Missing required documentation: {doc}")

    screenshot_dir = ROOT / "docs" / "assets" / "screenshots"
    screenshots = sorted(
        rel(path)
        for path in screenshot_dir.glob("*.png")
        if path.is_file()
    ) if screenshot_dir.exists() else []
    if not screenshots:
        warnings.append("GUI screenshots are pending; textual docs and diagrams remain complete.")

    node_map_pass = False
    node_map_path = ROOT / "config" / "kx134_node_map.json"
    try:
        node_map = json.loads(node_map_path.read_text(encoding="utf-8"))
        node_map_checks = {
            "prototype_delivery_package_ready": node_map.get("prototype_delivery_package_ready") is True,
            "client_user_docs_ready": node_map.get("client_user_docs_ready") is True,
            "pcb_design_authorized": node_map.get("pcb_design_authorized") is False,
            "baquelada_revA_registered": node_map.get("baquelada_revA_registered") is True,
            "baquelada_revA_status": node_map.get("baquelada_revA_status") == "under_review",
        }
        node_map_pass = all(node_map_checks.values())
        if not node_map_pass:
            failures.append(f"node_map checks failed: {node_map_checks}")
    except Exception as exc:  # pragma: no cover - defensive reporting
        failures.append(f"node_map invalid: {exc}")
        node_map_checks = {}

    try:
        tracked = run_git_ls_files()
        forbidden_tracked = [
            item
            for item in tracked
            if any(item.startswith(prefix) for prefix in TRACKED_FORBIDDEN_PREFIXES)
            or item.lower().endswith((".exe", ".zip"))
        ]
        git_hygiene_pass = not forbidden_tracked
        if forbidden_tracked:
            failures.append(f"Forbidden runtime/build artifacts tracked: {forbidden_tracked}")
    except Exception as exc:
        git_hygiene_pass = False
        forbidden_tracked = []
        failures.append(str(exc))

    stale_reference_findings = scan_stale_references()
    unallowed_stale = [
        item
        for item in stale_reference_findings
        if not item["allowed_context"]
        and item["file"] in {"README.md", "AGENTS.md", "docs/README.md"}
    ]
    if unallowed_stale:
        failures.append(f"Unallowed stale root references: {unallowed_stale}")

    if stale_reference_findings:
        warnings.append(
            "Stale/legacy reference scan found entries; allowed entries must remain explicitly legacy or forbidden-field context."
        )

    pass_value = not failures
    recommendation = (
        "REPOSITORY_PRODUCTION_READY=YES_WITH_SCREENSHOTS_PENDING"
        if pass_value and not screenshots
        else "REPOSITORY_PRODUCTION_READY=YES"
        if pass_value
        else "REPOSITORY_PRODUCTION_READY=NO"
    )

    output = {
        "pass": pass_value,
        "failures": failures,
        "warnings": warnings,
        "stale_reference_findings": stale_reference_findings,
        "docs_present": docs_present,
        "screenshots_present": screenshots,
        "git_hygiene_pass": git_hygiene_pass,
        "forbidden_tracked": forbidden_tracked,
        "node_map_pass": node_map_pass,
        "node_map_checks": node_map_checks,
        "recommendation": recommendation,
    }

    output_path = ROOT / args.output
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(output, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(json.dumps(output, indent=2, ensure_ascii=False))
    return 0 if pass_value else 1


if __name__ == "__main__":
    raise SystemExit(main())

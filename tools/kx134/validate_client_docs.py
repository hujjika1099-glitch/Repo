from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parents[2]

CLIENT_DOCS = [
    "docs/kx134_migration/client/QUICK_START_GUIDE.md",
    "docs/kx134_migration/client/USER_MANUAL_KX134_PROTOTYPE.md",
    "docs/kx134_migration/client/WINDOWS_INSTALLATION_GUIDE.md",
    "docs/kx134_migration/client/HARDWARE_CONNECTION_GUIDE.md",
    "docs/kx134_migration/client/CAPTURE_AND_EXPORT_GUIDE.md",
    "docs/kx134_migration/client/OUTPUT_FILES_REFERENCE.md",
    "docs/kx134_migration/client/TROUBLESHOOTING_GUIDE.md",
    "docs/kx134_migration/client/RELEASE_NOTES_PROTOTYPE.md",
    "docs/kx134_migration/client/DELIVERY_MANIFEST.md",
    "docs/kx134_migration/client/PRE_TEST_CHECKLIST.md",
    "docs/kx134_migration/client/POST_TEST_CHECKLIST.md",
    "docs/kx134_migration/client/LIMITATIONS_AND_WARNINGS.md",
]

REQUIRED_TERMS = [
    "KX134",
    "Sensor 1",
    "Sensor 2",
    "Receptor",
    "100 Hz",
    "8 g",
    "921600",
    "CSV",
    "JSON",
    "summary",
]

CONTRADICTION_PATTERNS = [
    r"PCB_DESIGN_AUTHORIZED\s*=\s*YES",
    r"PCB_DESIGN_AUTHORIZED\s*:\s*YES",
    r"PCB\s+autorizada\s*:\s*s[ií]",
    r"baquelada\s+autorizada\s*:\s*s[ií]",
    r"PCB/baquelada\s+final\s+autorizada",
]


def _read_docs() -> tuple[dict[str, str], list[str]]:
    texts: dict[str, str] = {}
    missing: list[str] = []
    for rel_path in CLIENT_DOCS:
        path = REPO_ROOT / rel_path
        if not path.exists():
            missing.append(rel_path)
            continue
        texts[rel_path] = path.read_text(encoding="utf-8")
    return texts, missing


def validate() -> dict[str, Any]:
    texts, missing_docs = _read_docs()
    corpus = "\n".join(texts.values())
    corpus_lower = corpus.lower()

    missing_terms = [
        term for term in REQUIRED_TERMS if term.lower() not in corpus_lower
    ]

    contradictions: list[str] = []
    for pattern in CONTRADICTION_PATTERNS:
        if re.search(pattern, corpus, flags=re.IGNORECASE):
            contradictions.append(pattern)

    warnings: list[str] = []
    if "pcb_design_authorized = no" not in corpus_lower and "pcb no autorizada" not in corpus_lower:
        contradictions.append("Missing explicit PCB_DESIGN_AUTHORIZED = NO / PCB no autorizada statement")

    if "sample_rate" not in corpus_lower or "pendiente" not in corpus_lower:
        missing_terms.append("sample_rate pendiente")

    if "range_g" not in corpus_lower or "recalibr" not in corpus_lower:
        missing_terms.append("range_g recalibrar")

    if "firma digital" in corpus_lower:
        warnings.append("Digital signature is documented as pending.")
    if "scaling" in corpus_lower and "125/150" in corpus_lower:
        warnings.append("Windows scaling 125/150 is documented as pending.")
    if "hardware externo" in corpus_lower:
        warnings.append("External PC hardware capture remains optional/pending if client requires it.")

    passed = not missing_docs and not missing_terms and not contradictions
    return {
        "pass": passed,
        "missing_docs": missing_docs,
        "missing_terms": missing_terms,
        "contradictions": contradictions,
        "warnings": warnings,
        "docs_checked": CLIENT_DOCS,
        "decision": "CLIENT_USER_DOCS_READY=YES" if passed else "CLIENT_USER_DOCS_READY=NO",
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate KX134 client documentation readiness.")
    parser.add_argument(
        "--output",
        default="reports/prototype_validation/TICKET_024_client_docs_readiness_output.json",
        help="Output JSON path.",
    )
    args = parser.parse_args()

    result = validate()
    output = REPO_ROOT / args.output
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(result, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(json.dumps(result, indent=2, ensure_ascii=False))
    return 0 if result["pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())

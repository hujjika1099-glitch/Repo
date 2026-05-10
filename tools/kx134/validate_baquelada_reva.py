from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parents[2]

REQUIRED_DOCS = [
    "hardware/pcb/baquelada_revA/README.md",
    "hardware/pcb/baquelada_revA/BAQUELADA_REVA_REVIEW.md",
    "hardware/pcb/baquelada_revA/BAQUELADA_REVA_CONTINUITY_CHECKLIST.md",
    "hardware/pcb/baquelada_revA/BAQUELADA_REVA_PINOUT_CHECK.md",
    "hardware/pcb/baquelada_revA/BAQUELADA_REVA_TEST_PLAN.md",
]


def _load_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def validate(review_path: Path) -> dict[str, Any]:
    warnings: list[str] = []
    blockers: list[str] = []

    missing_docs = [rel for rel in REQUIRED_DOCS if not (REPO_ROOT / rel).exists()]
    if missing_docs:
        blockers.extend(f"missing_doc:{doc}" for doc in missing_docs)

    if not review_path.exists():
        blockers.append(f"missing_review_json:{review_path}")
        review: dict[str, Any] = {}
    else:
        review = _load_json(review_path)

    artifacts = review.get("artifacts", {})
    for key in ("pdf", "svg"):
        rel_path = artifacts.get(key)
        if rel_path and rel_path != "PENDING" and not (REPO_ROOT / rel_path).exists():
            blockers.append(f"missing_artifact:{rel_path}")

    if artifacts.get("proteus_project") == "PENDING":
        warnings.append("Proteus project files were not provided.")

    decision = review.get("decision", {})
    if decision.get("pcb_design_authorized") is True:
        blockers.append("pcb_design_authorized must remain false for RevA review.")

    if review.get("board_role") == "PENDING":
        warnings.append("board_role is PENDING.")

    scale = review.get("scale_and_mirror", {})
    if not scale.get("scale_1_to_1_confirmed"):
        warnings.append("Scale 1:1 is not confirmed.")
    if not scale.get("mirror_orientation_confirmed"):
        warnings.append("Mirror/layer orientation is not confirmed.")

    continuity = review.get("continuity_test", {})
    if continuity.get("status") == "PENDING":
        warnings.append("Continuity test is PENDING.")

    pinout = review.get("pinout_review", {})
    if not pinout.get("confirmed"):
        warnings.append("Pinout is not confirmed.")

    readiness = review.get("test_readiness", {})
    if readiness.get("ready_to_power"):
        blockers.append("ready_to_power must remain false until continuity and shorts are completed.")

    validation_pass = not blockers
    return {
        "validation_pass": validation_pass,
        "warnings": warnings,
        "blockers": blockers,
        "missing_docs": missing_docs,
        "baquelada_revA_registered": bool(decision.get("baquelada_revA_registered")),
        "baquelada_revA_accepted_for_prototype_use": bool(
            decision.get("baquelada_revA_accepted_for_prototype_use")
        ),
        "pcb_design_authorized": bool(decision.get("pcb_design_authorized")),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate Baquelada RevA review package.")
    parser.add_argument("--review", required=True, help="Review JSON path.")
    parser.add_argument("--output", required=True, help="Output JSON path.")
    args = parser.parse_args()

    result = validate(REPO_ROOT / args.review)
    output = REPO_ROOT / args.output
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(result, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(json.dumps(result, indent=2, ensure_ascii=False))
    return 0 if result["validation_pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())

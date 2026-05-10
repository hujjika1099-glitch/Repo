from __future__ import annotations

import argparse
import json
from pathlib import Path


def _bool(value: str) -> bool:
    return str(value).strip().lower() in {"1", "true", "yes", "y", "si"}


def validate_external_qa(
    qa_json: Path,
    *,
    require_hardware_capture: bool = False,
    hardware_validation_json: Path | None = None,
) -> dict[str, object]:
    failures: list[str] = []
    warnings: list[str] = []
    if not qa_json.is_file():
        return {
            "pass": False,
            "ready_for_client_prototype_qa": "NO",
            "failures": ["qa_json_missing"],
            "warnings": [],
        }

    qa = json.loads(qa_json.read_text(encoding="utf-8-sig"))
    if not qa.get("exe_exists"):
        failures.append("exe_missing")
    if not qa.get("launcher_smoke_pass"):
        failures.append("launcher_smoke_failed")
    if not qa.get("kx134_smoke_pass"):
        failures.append("kx134_smoke_failed")
    if not qa.get("adxl_smoke_pass"):
        failures.append("adxl_smoke_failed")

    visual_manual_result = str(qa.get("visual_manual_result", "not_recorded"))
    if visual_manual_result in {"fail", "FAIL"}:
        failures.append("visual_layout_failed")
    elif visual_manual_result in {"not_recorded", "", "pending"}:
        warnings.append("visual_manual_result_pending")

    hardware_validation = None
    if hardware_validation_json and hardware_validation_json.is_file():
        hardware_validation = json.loads(hardware_validation_json.read_text(encoding="utf-8-sig"))

    hardware_capture_run = bool(qa.get("hardware_capture_run"))
    hardware_capture_pass = bool(qa.get("hardware_capture_pass"))
    export_validation_pass = bool(hardware_validation.get("pass") or hardware_validation.get("validation_pass")) if isinstance(hardware_validation, dict) else False

    if require_hardware_capture:
        if not hardware_capture_run:
            failures.append("hardware_capture_not_run")
        elif not hardware_capture_pass:
            failures.append("hardware_capture_failed")
        if hardware_validation_json and not export_validation_pass:
            failures.append("export_validation_failed")
    elif not hardware_capture_run:
        warnings.append("hardware_capture_not_run")

    ready = "YES" if not failures and visual_manual_result.lower() == "pass" and (hardware_capture_pass or not require_hardware_capture) else "PENDING"
    if failures:
        ready = "NO"

    return {
        "pass": not failures,
        "ready_for_client_prototype_qa": ready,
        "failures": failures,
        "warnings": warnings,
        "qa_json": str(qa_json),
        "hostname": qa.get("hostname", ""),
        "windows_version": qa.get("windows_version", ""),
        "resolution": qa.get("resolution", ""),
        "scaling_percent": qa.get("scaling_percent"),
        "launcher_smoke_pass": bool(qa.get("launcher_smoke_pass")),
        "kx134_smoke_pass": bool(qa.get("kx134_smoke_pass")),
        "adxl_smoke_pass": bool(qa.get("adxl_smoke_pass")),
        "visual_manual_result": visual_manual_result,
        "hardware_capture_run": hardware_capture_run,
        "hardware_capture_pass": hardware_capture_pass,
        "export_validation_pass": export_validation_pass,
        "decision": ready,
    }


def main(argv: list[str] | None = None) -> None:
    parser = argparse.ArgumentParser(description="Validate external Windows PC QA output")
    parser.add_argument("--qa-json", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--require-hardware-capture", default="false")
    parser.add_argument("--hardware-validation-json", default="")
    args = parser.parse_args(argv)

    hardware_json = Path(args.hardware_validation_json) if args.hardware_validation_json else None
    payload = validate_external_qa(
        Path(args.qa_json),
        require_hardware_capture=_bool(args.require_hardware_capture),
        hardware_validation_json=hardware_json,
    )
    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(payload, indent=2, ensure_ascii=True) + "\n", encoding="utf-8")
    print(str(output))
    if payload["failures"]:
        raise SystemExit(1)


if __name__ == "__main__":
    main()

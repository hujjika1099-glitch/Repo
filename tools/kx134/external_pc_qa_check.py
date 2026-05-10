from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


YES_VALUES = {"1", "true", "yes", "y", "pass", "passed", "ok"}
NO_VALUES = {"0", "false", "no", "n", "fail", "failed"}
PENDING_VALUES = {"", "none", "null", "pending", "not_run", "not run", "unknown"}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Validate external PC QA output for the Windows package")
    parser.add_argument("--qa-json", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--require-hardware-capture", default="false")
    parser.add_argument("--hardware-validation-json")
    return parser.parse_args()


def to_bool(value: object) -> bool:
    return str(value).strip().lower() in YES_VALUES


def status_bool(value: Any) -> bool | None:
    if isinstance(value, bool):
        return value
    if value is None:
        return None
    text = str(value).strip().lower()
    if text in YES_VALUES:
        return True
    if text in NO_VALUES:
        return False
    if text in PENDING_VALUES:
        return None
    return None


def smoke_pass(data: dict[str, Any], key: str) -> bool:
    explicit = status_bool(data.get(f"{key}_pass"))
    if explicit is not None:
        return explicit
    exit_code = data.get(f"{key}_exit_code")
    return exit_code == 0


def load_json(path: str | None) -> dict[str, Any] | None:
    if not path:
        return None
    json_path = Path(path)
    if not json_path.exists():
        return None
    return json.loads(json_path.read_text(encoding="utf-8-sig"))


def main() -> int:
    args = parse_args()
    qa_path = Path(args.qa_json)
    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    failures: list[str] = []
    warnings: list[str] = []

    if not qa_path.exists():
        failures.append("qa_json_missing")
        result = {
            "pass": False,
            "warnings": warnings,
            "failures": failures,
            "ready_for_client_prototype_qa": "NO",
        }
        output_path.write_text(json.dumps(result, indent=2, ensure_ascii=True), encoding="utf-8")
        print(str(output_path))
        return 1

    qa = json.loads(qa_path.read_text(encoding="utf-8-sig"))

    exe_exists = status_bool(qa.get("exe_exists"))
    if exe_exists is not True:
        failures.append("exe_missing")

    launcher_smoke_pass = smoke_pass(qa, "launcher_smoke")
    kx134_smoke_pass = smoke_pass(qa, "kx134_smoke")
    adxl_smoke_pass = smoke_pass(qa, "adxl_smoke")
    if not launcher_smoke_pass:
        failures.append("launcher_smoke_failed")
    if not kx134_smoke_pass:
        failures.append("kx134_smoke_failed")
    if not adxl_smoke_pass:
        failures.append("adxl_smoke_failed")

    visual_manual_result = status_bool(
        qa.get("visual_manual_result", qa.get("visual_layout_pass"))
    )
    visual_pending = visual_manual_result is None
    if visual_manual_result is False:
        failures.append("visual_manual_failed")
    elif visual_pending:
        warnings.append("visual_manual_pending")

    require_hardware = to_bool(args.require_hardware_capture)
    hardware_capture_result = status_bool(
        qa.get("hardware_capture_result", qa.get("hardware_capture_pass"))
    )
    hardware_capture_run = status_bool(qa.get("hardware_capture_run"))
    hardware_pending = hardware_capture_result is None and hardware_capture_run is not False
    if require_hardware and hardware_capture_result is not True:
        failures.append("hardware_capture_required_not_passed")
    elif hardware_capture_result is False:
        failures.append("hardware_capture_failed")
    elif hardware_capture_result is None:
        warnings.append("hardware_capture_not_run")

    hardware_validation = load_json(args.hardware_validation_json)
    if hardware_validation is None:
        hardware_validation = qa.get("hardware_validation") if isinstance(qa.get("hardware_validation"), dict) else None

    export_validation_pass = status_bool(qa.get("export_validation_pass"))
    if hardware_validation is not None:
        export_validation_pass = status_bool(hardware_validation.get("pass"))
    if require_hardware and export_validation_pass is not True:
        failures.append("export_validation_required_not_passed")
    elif hardware_capture_result is True and export_validation_pass is not True:
        failures.append("export_validation_failed_or_missing")
    elif export_validation_pass is None:
        warnings.append("export_validation_not_run")

    pending = bool(warnings) and not failures
    ready = "NO" if failures else ("PENDING" if pending or visual_pending or hardware_pending else "YES")

    result = {
        "pass": ready == "YES",
        "warnings": warnings,
        "failures": failures,
        "ready_for_client_prototype_qa": ready,
        "exe_exists": exe_exists is True,
        "launcher_smoke_pass": launcher_smoke_pass,
        "kx134_smoke_pass": kx134_smoke_pass,
        "adxl_smoke_pass": adxl_smoke_pass,
        "visual_manual_result": visual_manual_result,
        "hardware_capture_result": hardware_capture_result,
        "export_validation_pass": export_validation_pass,
        "hardware_validation_json": args.hardware_validation_json,
        "qa_json": str(qa_path),
    }
    output_path.write_text(json.dumps(result, indent=2, ensure_ascii=True), encoding="utf-8")
    print(str(output_path))
    return 0 if ready in {"YES", "PENDING"} else 1


if __name__ == "__main__":
    raise SystemExit(main())

from __future__ import annotations

import argparse
import json
import zipfile
from pathlib import Path


EXPECTED_EXE_NAME = "Sistema_Captura_Acelerometria.exe"
REQUIRED_CONFIG_NAMES = {
    "kx134_node_map.json",
    "kx134_transport_contract_v3.json",
    "kx134_sensor_1.json",
    "kx134_sensor_2.json",
}


def _find_names(root: Path, names: set[str]) -> dict[str, str | None]:
    found = {name: None for name in names}
    if not root.exists():
        return found
    for path in root.rglob("*"):
        if path.is_file() and path.name in found:
            found[path.name] = str(path)
    return found


def validate_package(dist_dir: Path, exe: Path, zip_path: Path) -> dict[str, object]:
    failures: list[str] = []
    warnings: list[str] = []
    dist_dir = dist_dir.resolve()
    exe = exe.resolve()
    zip_path = zip_path.resolve()

    package_exists = dist_dir.is_dir()
    exe_exists = exe.is_file()
    zip_exists = zip_path.is_file()
    exe_name_ok = exe.name == EXPECTED_EXE_NAME

    if not package_exists:
        failures.append("dist_dir_missing")
    if not exe_exists:
        failures.append("exe_missing")
    if not zip_exists:
        failures.append("zip_missing")
    if not exe_name_ok:
        failures.append("bad_exe_name")

    config_paths = _find_names(dist_dir, REQUIRED_CONFIG_NAMES)
    configs_present = all(config_paths.values())
    if not configs_present:
        failures.append("required_configs_missing")

    packaged_files = [path for path in dist_dir.rglob("*") if path.is_file()] if package_exists else []
    historical_data_packaged = any(
        "data" in path.parts and ("raw" in path.parts or "processed" in path.parts)
        for path in packaged_files
    )
    development_reports_packaged = any(
        "reports" in path.parts and "kx134_gui_validation" in path.parts
        for path in packaged_files
    )
    if historical_data_packaged:
        failures.append("historical_data_packaged")
    if development_reports_packaged:
        failures.append("development_reports_packaged")

    zip_contains_exe = False
    if zip_exists:
        try:
            with zipfile.ZipFile(zip_path) as archive:
                zip_contains_exe = any(Path(name).name == EXPECTED_EXE_NAME for name in archive.namelist())
        except zipfile.BadZipFile:
            failures.append("zip_invalid")
    if zip_exists and not zip_contains_exe:
        failures.append("zip_missing_exe")

    payload = {
        "validation_pass": not failures,
        "failures": failures,
        "warnings": warnings,
        "package_exists": package_exists,
        "exe_exists": exe_exists,
        "zip_exists": zip_exists,
        "exe_name_ok": exe_name_ok,
        "configs_present": configs_present,
        "config_paths": config_paths,
        "historical_data_packaged": historical_data_packaged,
        "development_reports_packaged": development_reports_packaged,
        "zip_contains_exe": zip_contains_exe,
        "dist_dir": str(dist_dir),
        "exe": str(exe),
        "zip": str(zip_path),
        "file_count": len(packaged_files),
        "exe_size_bytes": exe.stat().st_size if exe_exists else 0,
        "zip_size_bytes": zip_path.stat().st_size if zip_exists else 0,
    }
    return payload


def main(argv: list[str] | None = None) -> None:
    parser = argparse.ArgumentParser(description="Validate Sistema_Captura_Acelerometria Windows package")
    parser.add_argument("--dist-dir", required=True)
    parser.add_argument("--exe", required=True)
    parser.add_argument("--zip", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args(argv)
    payload = validate_package(Path(args.dist_dir), Path(args.exe), Path(args.zip))
    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(payload, indent=2, ensure_ascii=True) + "\n", encoding="utf-8")
    print(str(output))
    if not payload["validation_pass"]:
        raise SystemExit(1)


if __name__ == "__main__":
    main()

from __future__ import annotations

import csv
import json
import tempfile
import unittest
from dataclasses import replace
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from gui.kx134_live_core import export_kx134_session, parse_kx134_stream_line
from gui.kx134_stream_contract import KX134_EXPECTED_HEADER, KX134_FORBIDDEN_FIELDS


STATIC_LOG = ROOT / "reports/kx134_test_runs/TICKET_014_static_receiver_monitor_20260510_112712.txt"


def load_samples(limit: int = 240) -> list:
    samples = []
    for line in STATIC_LOG.read_text(encoding="utf-8").splitlines():
        parsed = parse_kx134_stream_line(line)
        if parsed.kind == "data" and parsed.sample is not None:
            index = len(samples) + 1
            samples.append(replace(parsed.sample, pc_wall_s=index / 100.0))
        if len(samples) >= limit:
            break
    return samples


class TestKx134ExportMetadataSchema(unittest.TestCase):
    def test_hardened_metadata_schema_and_relative_artifacts(self) -> None:
        samples = load_samples()
        with tempfile.TemporaryDirectory() as tmp:
            result = export_kx134_session(
                samples=samples,
                metadata_lines=["#STAT,role=receiver,rx_total=240"],
                output_root=tmp,
                session_name="ticket017_schema_unittest",
                expected_sample_rate_hz=100,
                invalid_lines=0,
                port="COM4",
                baud=921600,
                capture_duration_requested_s=10.0,
                capture_duration_actual_s=2.4,
            )
            payload = json.loads(result.artifacts.session_json_abs.read_text(encoding="utf-8"))

            for key in (
                "session_id",
                "session_type",
                "protocol_version",
                "contract_version",
                "created_at_iso",
                "capture_duration_requested_s",
                "capture_duration_actual_s",
                "nodes_expected",
                "artifacts_relative_to_session_root",
                "decision",
            ):
                self.assertIn(key, payload)

            self.assertEqual(payload["firmware_configuration_sent"], False)
            self.assertEqual(payload["allowed_sample_rates_hz"], [100, 200, 400, 800])
            self.assertNotIn(500, payload["allowed_sample_rates_hz"])
            self.assertNotIn(1000, payload["allowed_sample_rates_hz"])

            relative = payload["artifacts_relative_to_session_root"]
            self.assertEqual(
                relative["raw_csv"],
                "data/raw/kx134_dual_live/" + result.artifacts.raw_csv_abs.name,
            )
            self.assertTrue(result.artifacts.raw_csv_abs.exists())
            self.assertTrue(result.artifacts.session_json_abs.exists())
            self.assertTrue(result.artifacts.summary_abs.exists())

    def test_csv_and_summary_contract(self) -> None:
        samples = load_samples()
        with tempfile.TemporaryDirectory() as tmp:
            result = export_kx134_session(
                samples=samples,
                metadata_lines=[],
                output_root=tmp,
                session_name="ticket017_contract_unittest",
                expected_sample_rate_hz=100,
            )
            with result.artifacts.raw_csv_abs.open(newline="", encoding="utf-8") as handle:
                reader = csv.reader(handle)
                header = next(reader)
            self.assertEqual(header, KX134_EXPECTED_HEADER)
            header_text = ",".join(header)
            for forbidden in KX134_FORBIDDEN_FIELDS:
                self.assertNotIn(forbidden, header_text)

            summary_text = result.artifacts.summary_abs.read_text(encoding="utf-8")
            self.assertIn("Sensor 1", summary_text)
            self.assertIn("Sensor 2", summary_text)
            self.assertIn("Artifacts", summary_text)


if __name__ == "__main__":
    unittest.main()

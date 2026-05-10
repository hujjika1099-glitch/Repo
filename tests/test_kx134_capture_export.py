from __future__ import annotations

import csv
import json
import tempfile
import unittest
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from gui.kx134_live_core import export_kx134_session, parse_kx134_stream_line
from gui.kx134_stream_contract import KX134_EXPECTED_HEADER, KX134_FORBIDDEN_FIELDS


STATIC_LOG = ROOT / "reports/kx134_test_runs/TICKET_014_static_receiver_monitor_20260510_112712.txt"


class TestKx134CaptureExport(unittest.TestCase):
    def test_parse_and_export_static_ticket014_log(self) -> None:
        samples = []
        metadata = []
        invalid = 0
        for line in STATIC_LOG.read_text(encoding="utf-8").splitlines():
            parsed = parse_kx134_stream_line(line)
            if parsed.kind == "data":
                samples.append(parsed.sample)
            elif parsed.kind == "metadata":
                metadata.append(parsed.text)
            elif parsed.kind == "invalid":
                invalid += 1

        self.assertGreater(len(samples), 5000)
        self.assertEqual({sample.sensor_id for sample in samples}, {1, 2})
        self.assertEqual({sample.sample_rate_hz for sample in samples}, {100})

        with tempfile.TemporaryDirectory() as tmp:
            result = export_kx134_session(
                samples=samples,
                metadata_lines=metadata,
                output_root=tmp,
                session_name="ticket015_unittest",
                expected_sample_rate_hz=100,
                invalid_lines=invalid,
            )

            self.assertTrue(result.artifacts.raw_csv_abs.exists())
            self.assertTrue(result.artifacts.session_json_abs.exists())
            self.assertTrue(result.artifacts.summary_abs.exists())
            self.assertGreater(result.summary["samples_by_sensor"]["1"], 0)
            self.assertGreater(result.summary["samples_by_sensor"]["2"], 0)

            with result.artifacts.raw_csv_abs.open(newline="", encoding="utf-8") as handle:
                reader = csv.reader(handle)
                header = next(reader)
            self.assertEqual(header, KX134_EXPECTED_HEADER)

            header_text = ",".join(header)
            for forbidden in KX134_FORBIDDEN_FIELDS:
                self.assertNotIn(forbidden, header_text)
            self.assertNotIn("g_norm", header_text)

            payload = json.loads(result.artifacts.session_json_abs.read_text(encoding="utf-8"))
            self.assertEqual(payload["summary"]["samples_by_sensor"]["1"], 2999)
            self.assertEqual(payload["summary"]["samples_by_sensor"]["2"], 2999)


if __name__ == "__main__":
    unittest.main()

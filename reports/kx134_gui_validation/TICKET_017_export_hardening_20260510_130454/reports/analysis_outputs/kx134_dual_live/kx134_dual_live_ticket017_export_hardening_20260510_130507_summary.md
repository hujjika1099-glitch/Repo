# KX134 dual live session summary

## Session

- session_id: `kx134_dual_live_ticket017_export_hardening_20260510_130507`
- session_name: `ticket017_export_hardening`
- protocol_version: `kx134.v3`
- expected_sample_rate_hz: `100`
- expected_range_g: `8`
- capture_duration_requested_s: `10.0`
- capture_duration_actual_s: `10.0`
- invalid_lines: `0`
- metadata_lines: `1`
- receiver_t_us_valid: `True`
- pc_wall_s_positive: `True`

## Sensor Table

| Sensor | Rows | Effective Hz | Seq gaps | Timestamp errors | Receiver timestamp errors | Duplicate keys |
|---|---:|---:|---:|---:|---:|---:|
| Sensor 1 | 1001 | 100.000000 | 0 | 0 | 0 | 0 |
| Sensor 2 | 999 | 100.000020 | 0 | 0 | 0 | 0 |

## Packet Counts

- packet_status_counts: `{'OK': 2000}`
- packet_error_code_counts: `{'OK': 2000}`
- forbidden_fields_detected: `False`
- warnings: `[]`

## Artifacts

- raw_csv: `data/raw/kx134_dual_live/kx134_dual_live_ticket017_export_hardening_20260510_130507_raw.csv`
- session_json: `data/processed/kx134_dual_live/kx134_dual_live_ticket017_export_hardening_20260510_130507_session.json`
- summary_md: `reports/analysis_outputs/kx134_dual_live/kx134_dual_live_ticket017_export_hardening_20260510_130507_summary.md`

## Decision

- session_valid: `True`
- decision: `PASS`
- failures: `[]`

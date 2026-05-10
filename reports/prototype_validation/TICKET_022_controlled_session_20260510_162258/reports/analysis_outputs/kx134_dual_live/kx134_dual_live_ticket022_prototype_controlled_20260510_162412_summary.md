# KX134 dual live session summary

## Session

- session_id: `kx134_dual_live_ticket022_prototype_controlled_20260510_162412`
- session_name: `ticket022_prototype_controlled`
- protocol_version: `kx134.v3`
- expected_sample_rate_hz: `100`
- expected_range_g: `8`
- capture_duration_requested_s: `60.0`
- capture_duration_actual_s: `60.00012799999968`
- invalid_lines: `0`
- metadata_lines: `160`
- receiver_t_us_valid: `True`
- pc_wall_s_positive: `True`

## Sensor Table

| Sensor | Rows | Effective Hz | Seq gaps | Timestamp errors | Receiver timestamp errors | Duplicate keys |
|---|---:|---:|---:|---:|---:|---:|
| Sensor 1 | 5998 | 99.966656 | 2 | 0 | 0 | 0 |
| Sensor 2 | 6000 | 100.000007 | 0 | 0 | 0 | 0 |

## Packet Counts

- packet_status_counts: `{'OK': 11998}`
- packet_error_code_counts: `{'OK': 11998}`
- forbidden_fields_detected: `False`
- warnings: `[]`

## Artifacts

- raw_csv: `data/raw/kx134_dual_live/kx134_dual_live_ticket022_prototype_controlled_20260510_162412_raw.csv`
- session_json: `data/processed/kx134_dual_live/kx134_dual_live_ticket022_prototype_controlled_20260510_162412_session.json`
- summary_md: `reports/analysis_outputs/kx134_dual_live/kx134_dual_live_ticket022_prototype_controlled_20260510_162412_summary.md`

## Decision

- session_valid: `False`
- decision: `FAIL`
- failures: `['sensor_1_seq_gaps']`

# TICKET 011 - KX134 Sensor 2 six-position calibration

- session_id: kx134_sensor2_cal_20260509_180839
- calibration_id: kx134_sensor_2_20260509_180839
- port: COM5
- baud: 921600
- backend: PlatformIO
- sensor_id: 2
- physical_label: KX134_SENSOR_2
- node_id: sensor_node_2
- node_mac: D4:E9:F4:C3:37:14
- sample_rate_hz: 100
- odr_hz: 100
- range_g: 8
- SENSOR_2_CALIBRATION_VALID: YES
- header_detected_all_positions: False
- header_fallback_used: True

## Position summaries

### X_POS
- samples_count: 1909
- effective_hz: 100.000
- seq_gaps: 0
- timestamp_errors: 0
- mean_x_g: 1.000744
- mean_y_g: -0.009956
- mean_z_g: 0.032321
- g_norm_mean: 1.001468
- g_norm_std: 0.011384
- dominant_axis: x
- validation_status: pass
- accepted_with_warning: False
- header_detected: False
- header_fallback_used: True

### X_NEG
- samples_count: 1894
- effective_hz: 100.000
- seq_gaps: 0
- timestamp_errors: 0
- mean_x_g: -1.013040
- mean_y_g: 0.086084
- mean_z_g: -0.018127
- g_norm_mean: 1.016960
- g_norm_std: 0.010927
- dominant_axis: x
- validation_status: pass
- accepted_with_warning: False
- header_detected: False
- header_fallback_used: True

### Y_POS
- samples_count: 1909
- effective_hz: 100.000
- seq_gaps: 0
- timestamp_errors: 0
- mean_x_g: 0.018563
- mean_y_g: 1.038240
- mean_z_g: 0.020861
- g_norm_mean: 1.038727
- g_norm_std: 0.011167
- dominant_axis: y
- validation_status: pass
- accepted_with_warning: False
- header_detected: False
- header_fallback_used: True

### Y_NEG
- samples_count: 1907
- effective_hz: 100.000
- seq_gaps: 0
- timestamp_errors: 0
- mean_x_g: -0.009911
- mean_y_g: -0.952444
- mean_z_g: 0.038086
- g_norm_mean: 0.953374
- g_norm_std: 0.011534
- dominant_axis: y
- validation_status: pass
- accepted_with_warning: False
- header_detected: False
- header_fallback_used: True

### Z_POS
- samples_count: 1905
- effective_hz: 100.000
- seq_gaps: 0
- timestamp_errors: 0
- mean_x_g: -0.038046
- mean_y_g: 0.078889
- mean_z_g: 1.016702
- g_norm_mean: 1.020609
- g_norm_std: 0.009925
- dominant_axis: z
- validation_status: pass
- accepted_with_warning: False
- header_detected: False
- header_fallback_used: True

### Z_NEG
- samples_count: 1903
- effective_hz: 100.000
- seq_gaps: 0
- timestamp_errors: 0
- mean_x_g: 0.037959
- mean_y_g: 0.071543
- mean_z_g: -0.989231
- g_norm_mean: 0.992703
- g_norm_std: 0.011432
- dominant_axis: z
- validation_status: pass
- accepted_with_warning: False
- header_detected: False
- header_fallback_used: True

## Coefficients
- offset_x_g: -0.006147645
- offset_y_g: 0.042897817
- offset_z_g: 0.013735654
- scale_x: 0.993155216
- scale_y: 1.004679685
- scale_z: 0.997042002
- offset_x_raw: -25.180763
- offset_y_raw: 175.709423
- offset_z_raw: 56.261212
- sensitivity_x_counts_per_g: 4124.22948
- sensitivity_y_counts_per_g: 4076.921274
- sensitivity_z_counts_per_g: 4108.151911
- expected_counts_per_g: 4096
- sensitivity_x_deviation_pct: 0.689196
- sensitivity_y_deviation_pct: -0.465789
- sensitivity_z_deviation_pct: 0.296678

## Generated files
- config/calibrations/kx134_sensor_2.json
- config/kx134_node_map.json
- reports/kx134_calibration/sensor_2/kx134_sensor2_cal_20260509_180839/calibration_result.json
- reports/kx134_calibration/sensor_2/kx134_sensor2_cal_20260509_180839/captures/*.csv

## Restrictions
- Firmware was not modified by this calibration script.
- GUI was not modified by this calibration script.
- Packaging was not modified by this calibration script.
- Historical data under data/ was not modified.
- Calibration is not applied in firmware yet.

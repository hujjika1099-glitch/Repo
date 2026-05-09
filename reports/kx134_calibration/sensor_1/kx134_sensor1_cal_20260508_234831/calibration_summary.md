# TICKET 009 - KX134 Sensor 1 six-position calibration

- session_id: kx134_sensor1_cal_20260508_234831
- calibration_id: kx134_sensor_1_20260508_234831
- port: COM5
- baud: 921600
- backend: resume_existing_captures
- sensor_id: 1
- physical_label: KX134_SENSOR_1
- node_id: sensor_node_1
- node_mac: D4:E9:F4:E9:8E:1C
- sample_rate_hz: 100
- odr_hz: 100
- range_g: 8
- SENSOR_1_CALIBRATION_VALID: YES

## Position summaries

### X_POS
- samples_count: 1895
- effective_hz: 100.000
- seq_gaps: 0
- timestamp_errors: 0
- mean_x_g: 1.001012
- mean_y_g: -0.036785
- mean_z_g: 0.008633
- g_norm_mean: 1.001807
- g_norm_std: 0.009375
- dominant_axis: x
- validation_status: pass
- accepted_with_warning: False

### X_NEG
- samples_count: 1895
- effective_hz: 100.000
- seq_gaps: 0
- timestamp_errors: 0
- mean_x_g: -0.997353
- mean_y_g: 0.066387
- mean_z_g: -0.019648
- g_norm_mean: 0.999848
- g_norm_std: 0.009472
- dominant_axis: x
- validation_status: pass
- accepted_with_warning: False

### Y_POS
- samples_count: 1886
- effective_hz: 100.000
- seq_gaps: 0
- timestamp_errors: 0
- mean_x_g: 0.088546
- mean_y_g: 1.003418
- mean_z_g: 0.088320
- g_norm_mean: 1.011304
- g_norm_std: 0.010348
- dominant_axis: y
- validation_status: pass
- accepted_with_warning: False

### Y_NEG
- samples_count: 1905
- effective_hz: 100.000
- seq_gaps: 0
- timestamp_errors: 0
- mean_x_g: -0.082578
- mean_y_g: -0.973457
- mean_z_g: 0.064622
- g_norm_mean: 0.979214
- g_norm_std: 0.010832
- dominant_axis: y
- validation_status: pass
- accepted_with_warning: False

### Z_POS
- samples_count: 1900
- effective_hz: 100.000
- seq_gaps: 0
- timestamp_errors: 0
- mean_x_g: 0.017406
- mean_y_g: 0.005294
- mean_z_g: 1.025069
- g_norm_mean: 1.025327
- g_norm_std: 0.008705
- dominant_axis: z
- validation_status: pass
- accepted_with_warning: False

### Z_NEG
- samples_count: 1898
- effective_hz: 100.000
- seq_gaps: 0
- timestamp_errors: 0
- mean_x_g: -0.014950
- mean_y_g: -0.022195
- mean_z_g: -0.978439
- g_norm_mean: 0.978932
- g_norm_std: 0.010400
- dominant_axis: z
- validation_status: pass
- accepted_with_warning: False

## Coefficients
- offset_x_g: 0.001829774
- offset_y_g: 0.014980432
- offset_z_g: 0.023315356
- scale_x: 1.000818311
- scale_y: 1.011697845
- scale_z: 0.998249154
- offset_x_raw: 7.494723
- offset_y_raw: 61.35984
- offset_z_raw: 95.49964
- sensitivity_x_counts_per_g: 4092.650923
- sensitivity_y_counts_per_g: 4048.63963
- sensitivity_z_counts_per_g: 4103.184044
- expected_counts_per_g: 4096
- sensitivity_x_deviation_pct: -0.081765
- sensitivity_y_deviation_pct: -1.156259
- sensitivity_z_deviation_pct: 0.175392

## Generated files
- config/calibrations/kx134_sensor_1.json
- config/kx134_node_map.json
- reports/kx134_calibration/sensor_1/kx134_sensor1_cal_20260508_234831/calibration_result.json
- reports/kx134_calibration/sensor_1/kx134_sensor1_cal_20260508_234831/captures/*.csv

## Restrictions
- Firmware was not modified by this calibration script.
- GUI was not modified by this calibration script.
- Packaging was not modified by this calibration script.
- Historical data under data/ was not modified.
- Calibration is not applied in firmware yet.

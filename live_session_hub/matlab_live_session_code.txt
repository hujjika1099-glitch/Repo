% sensorB_live_prompt_session.m
% Lanzador para ejecutar sesiones live sin abrir nuevas instancias de MATLAB.
% Ejecutalo desde la misma consola de MATLAB:
% >> run('live_session_hub/sensorB_live_prompt_session.m')

hub_dir = fileparts(mfilename("fullpath"));
repo_dir = fileparts(hub_dir);

sensor_id = "sensor_B";
plot_sensor_numeric_id = 1;   % Sensor principal a visualizar en la grafica
second_sensor_numeric_id = 2; % Sensor secundario a evaluar en el resumen
prompt_user = true;           % Solo pide duracion y nombre base del archivo
show_live_plot = true;        % Grafica en vivo durante la sesion
save_csv = true;              % Siempre guarda CSV raw y processed
save_mat = true;              % Siempre guarda MAT de sesion
output_dir_relpath = "data/raw/sensor_B_live";
processed_dir_relpath = "data/processed";
session_name = "live";
live_plot_mode = "dual_g_norm";
dual_precheck_enabled = true;
dual_precheck_duration_s = 10.0;

run(fullfile(repo_dir, "matlab", "live", "run_sensorB_live_session.m"));

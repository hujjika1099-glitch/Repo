% sensorB_live_prompt_session.m
% Lanzador para ejecutar sesiones live sin abrir nuevas instancias de MATLAB.
% Ejecutalo desde la misma consola de MATLAB:
% >> run('live_session_hub/sensorB_live_prompt_session.m')

hub_dir = fileparts(mfilename("fullpath"));
repo_dir = fileparts(hub_dir);

sensor_id = "sensor_B";
prompt_user = true;      % Activa preguntas interactivas en consola MATLAB
show_live_plot = true;   % Grafica en vivo durante la sesion

run(fullfile(repo_dir, "matlab", "live", "run_sensorB_live_session.m"));

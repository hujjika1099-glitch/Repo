function idx = coupled_axis_to_index(axis_name)
switch string(axis_name)
    case "x"
        idx = 1;
    case "y"
        idx = 2;
    case "z"
        idx = 3;
    otherwise
        error("Eje no soportado: %s", string(axis_name));
end
end

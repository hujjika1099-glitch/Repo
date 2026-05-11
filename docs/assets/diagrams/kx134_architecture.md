# Arquitectura KX134 Dual

```mermaid
flowchart LR
    S1["KX134 Sensor 1"] --> E1["ESP32 Sensor Node 1"]
    S2["KX134 Sensor 2"] --> E2["ESP32 Sensor Node 2"]
    E1 -- "ESP-NOW" --> R["ESP32 Receiver"]
    E2 -- "ESP-NOW" --> R
    R -- "USB Serial 921600" --> GUI["Sistema_Captura_Acelerometria.exe"]
    GUI --> CSV["CSV KX134 v3"]
    GUI --> JSON["Session JSON"]
    GUI --> SUM["Summary MD"]
    GUI --> PLOTS["Live Plots"]
```

La sincronizacion primaria de eventos se apoya en `receiver_t_us` y secuencias
por sensor. `pc_wall_s` es util para trazabilidad en PC, pero no es la base
primaria para sincronizacion entre nodos.

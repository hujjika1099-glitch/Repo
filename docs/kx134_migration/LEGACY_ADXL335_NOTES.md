# Notas Legacy ADXL335

ADXL335 es un flujo historico preservado. No es el sistema principal actual.

## Archivos Relacionados

- `gui/adxl_live_gui.py`
- `gui/adxl_live_core.py`
- `adxl_captura.spec`
- `build_exe.ps1`
- `ADXL335_Captura_Manual.pdf`
- Documentos historicos en `docs/` y reportes previos.

## Como No Confundirlo Con KX134

El flujo ADXL335 historico usa conceptos analogicos y campos de voltaje. El
flujo KX134 actual usa sensores digitales SEN-17589/KX134, calibracion por
sensor y contrato CSV v3.

Campos ADXL335 historicos como `mv_x`, `mv_y`, `mv_z`, `gx_est`, `gy_est`,
`gz_est` y `g_norm_est` no son columnas actuales del CSV KX134.

Referencias a pines analogicos, cableado analogico o baudrate ADXL deben leerse
como contexto historico. Para KX134 actual, usar la documentacion KX134 y
`config/kx134_node_map.json`.

## Por Que Se Conserva

- Compatibilidad con trabajo historico.
- Trazabilidad academica.
- Posibilidad de abrir el modo ADXL335 desde el launcher.
- Comparacion con la migracion KX134.

No borrar el legado ADXL335 sin ticket explicito.

# Windows packaging

## Proposito

Este paquete genera la distribucion Windows onedir de `Sistema de Captura de Acelerometria`, con launcher principal para KX134 Dual Capture y ADXL335 historico.

## Preparar entorno

```powershell
python -m venv .venv
.venv\Scripts\python.exe -m pip install -r requirements-gui.txt
```

El script de build puede crear el venv local si se ejecuta con `-CreateVenv`.

## Build

```powershell
powershell -ExecutionPolicy Bypass -File .\build_windows_app.ps1 -CreateVenv -RunSmoke
```

Salidas locales:

- `dist\Sistema_Captura_Acelerometria\Sistema_Captura_Acelerometria.exe`
- `dist\Sistema_Captura_Acelerometria_dist.zip`

`dist/` y `build_work/` son artefactos locales y no se commitean.

## Smoke

```powershell
dist\Sistema_Captura_Acelerometria\Sistema_Captura_Acelerometria.exe --smoke --close-after-ms 1000
dist\Sistema_Captura_Acelerometria\Sistema_Captura_Acelerometria.exe --mode kx134 --smoke --close-after-ms 1000
dist\Sistema_Captura_Acelerometria\Sistema_Captura_Acelerometria.exe --mode adxl --smoke --close-after-ms 1000
```

## Distribucion

Copiar el ZIP o la carpeta onedir completa a la PC destino. El ejecutable no esta firmado digitalmente; si Windows Defender o SmartScreen bloquean el archivo, revisar cuarentena y permitir el ejecutable solo si proviene de este build local validado.

## Limitaciones

- Sin firma digital.
- Icono corporativo pendiente.
- QA en otro PC queda pendiente.
- No se incluye data historica ni reportes de desarrollo dentro del paquete.

# QA externo del ejecutable Windows

## Objetivo

Validar el paquete `Sistema_Captura_Acelerometria_dist.zip` en un PC distinto al de desarrollo.

## Preparacion

1. Copiar al PC externo:
   - `dist\Sistema_Captura_Acelerometria_dist.zip`
2. Descomprimir en una ruta simple, por ejemplo:
   - `C:\UQ_KX134_QA\Sistema_Captura_Acelerometria\`
3. No ejecutar desde dentro del ZIP.
4. Ejecutar:
   - `Sistema_Captura_Acelerometria.exe`

## Pruebas minimas sin hardware

1. Abrir launcher.
2. Abrir modo KX134.
3. Abrir modo ADXL335 historico.
4. Verificar que no aparece consola negra inesperada.
5. Verificar que la ventana no se corta.
6. Verificar pestanas KX134:
   - Conexion.
   - Captura.
   - Sensores.
   - Graficas.
   - Diagnostico.
   - Exportacion.
7. Verificar controles:
   - puerto;
   - baudrate 921600;
   - duracion manual;
   - frecuencia 100/200/400/800;
   - boton iniciar;
   - panel de graficas.
8. Verificar resolucion y scaling:
   - anotar resolucion;
   - anotar scaling;
   - confirmar si hay cortes visuales.

## Pruebas con hardware

1. Conectar receptor ESP32 al PC externo.
2. Alimentar Sensor 1 y Sensor 2.
3. Detectar puerto COM del receptor.
4. Abrir KX134.
5. Seleccionar:
   - puerto COM real;
   - baudrate 921600;
   - duracion 10 s o 20 s;
   - frecuencia esperada 100 Hz.
6. Iniciar captura.
7. Confirmar:
   - Sensor 1 muestra datos.
   - Sensor 2 muestra datos.
   - graficas se actualizan.
   - taps suaves se observan.
   - la GUI no se congela.
8. Confirmar que se exportan:
   - CSV raw;
   - metadata JSON;
   - summary MD.
9. Validar que CSV no tiene:
   - `mv_*`;
   - `gx_est/gy_est/gz_est`;
   - `g_norm`;
   - voltajes/milivoltios.

## Criterios de aceptacion

- El exe abre.
- KX134 abre.
- ADXL abre.
- No hay cortes visuales relevantes.
- Captura KX134 funciona si hay hardware.
- Exportacion KX134 funciona si hay hardware.
- No requiere Python instalado.
- No requiere modificar PATH.
- No requiere instalar dependencias.
- El ZIP contiene todo lo necesario.

## Datos a reportar

- PC/marca si se conoce.
- Windows version.
- Resolucion.
- Scaling.
- Puerto COM.
- Resultado launcher.
- Resultado KX134.
- Resultado ADXL.
- Resultado captura.
- Artefactos exportados.
- Errores/capturas si los hay.

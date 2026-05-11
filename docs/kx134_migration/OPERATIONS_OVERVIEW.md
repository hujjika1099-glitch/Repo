# Operacion Del Prototipo KX134

## Preparacion

1. Verificar que Sensor 1 y Sensor 2 esten identificados fisicamente.
2. Alimentar ambos nodos sensores.
3. Conectar la ESP32 receptora al PC por USB.
4. Confirmar el puerto COM en Windows.

## Inicio De Aplicacion

1. Ejecutar `Sistema_Captura_Acelerometria.exe`.
2. Abrir KX134 Dual Capture desde el launcher.
3. Seleccionar puerto COM del receptor.
4. Confirmar baudrate `921600`.
5. Definir duracion.
6. Usar frecuencia esperada `100 Hz` para la configuracion validada.

## Captura

- Empezar con una prueba corta de 10 a 20 segundos.
- Verificar que aparecen Sensor 1 y Sensor 2.
- Revisar que `invalid lines` y `duplicate keys` se mantengan en cero o dentro
  de advertencias documentadas.
- Confirmar que las graficas live responden a movimientos suaves.

## Exportacion

Al finalizar se generan:

- CSV raw KX134 v3.
- Session JSON.
- Summary MD.

Los archivos exportados son evidencia de la sesion. No sobrescribir capturas
historicas ni mezclar carpetas de runtime con documentos del repositorio.

## Cierre

1. Revisar CSV/JSON/summary.
2. Copiar artefactos relevantes si son parte de un ticket de validacion.
3. Registrar observaciones si hubo congelamiento visual, perdida de paquetes o
   comportamiento fisico inusual.

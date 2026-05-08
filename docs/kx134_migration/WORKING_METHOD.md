# Metodo de trabajo para migracion KX134

## Roles

### ChatGPT

- Define metodologia, tickets y criterios de aceptacion.
- Ayuda a descomponer el trabajo en pasos verificables.
- Mantiene el alcance tecnico claro antes de ejecutar cambios.

### CODEX

- Ejecuta cambios tecnicos sobre el repositorio.
- Verifica estado Git antes y despues de cada ticket.
- Modifica solo los archivos permitidos por el alcance.
- Reporta comandos, salidas relevantes y archivos modificados.

### Usuario

- Ejecuta pruebas fisicas con sensores, ESP32 y cableado real.
- Confirma topologia fisica disponible.
- Entrega retroalimentacion operativa y valida resultados.

## Flujo por ticket

1. Verificar `git status --short`.
2. Detenerse si existen cambios locales no confirmados.
3. Confirmar rama de trabajo.
4. Ejecutar solo el alcance del ticket.
5. Hacer validaciones minimas proporcionales al cambio.
6. Registrar cambios relevantes en `reports/change_log.md`.
7. Crear commit con mensaje claro.
8. Dejar `git status --short` limpio.
9. Subir la rama si hay credenciales disponibles.

## Separacion de responsabilidades

No se deben mezclar firmware, GUI y empaquetado en un mismo ticket salvo
instruccion explicita. La migracion KX134 debe avanzar en capas:

- Documentacion y contrato.
- Firmware de sensor individual.
- Firmware dual y sincronizacion.
- Calibracion individual.
- GUI.
- Exportacion.
- Empaquetado.
- Validacion fisica.

## Reporte de ejecucion

Cada ticket debe reportar:

- Rama activa.
- Commit generado.
- Archivos creados o modificados.
- Comandos de validacion ejecutados.
- Resultado de `git status --short`.
- Bloqueos o decisiones pendientes.

## Pruebas minimas

Cada ticket debe incluir pruebas minimas acordes al alcance:

- Documentacion: verificar existencia de archivos y diff limitado a docs.
- Firmware: compilar y, si aplica, validar en hardware real.
- GUI: validar arranque o prueba automatizada disponible.
- Exportacion: validar estructura de CSV/JSON.
- Empaquetado: validar build y arranque real en Windows.

## Registro de cambios

Todo cambio relevante debe quedar en `reports/change_log.md` con fecha, rama o
fase, archivos afectados, motivo, impacto y riesgo.

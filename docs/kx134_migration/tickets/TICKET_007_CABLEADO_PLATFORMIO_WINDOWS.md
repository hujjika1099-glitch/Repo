# TICKET 007 - Cableado KX134 I2C y helpers PlatformIO Windows

## Objetivo

Documentar el cableado ESP32 <-> SEN-17589/KX134 y crear herramientas para usar PlatformIO en Windows aunque `pio` no este en PATH.

## Rama

`feature/kx134-dual-capture`

## Entregables

- `tools/platformio/pio.ps1`
- `tools/platformio/pio.cmd`
- `tools/platformio/kx134_single_node.ps1`
- `tools/platformio/setup_platformio_user_path.ps1`
- `tools/platformio/README.md`
- `docs/kx134_migration/HARDWARE_WIRING_KX134_I2C.md`
- `docs/kx134_migration/PLATFORMIO_WINDOWS_SETUP.md`
- `docs/kx134_migration/tickets/TICKET_007_CABLEADO_PLATFORMIO_WINDOWS.md`
- Actualizacion de `firmware/kx134_single_node_i2c/README.md`
- Actualizacion de `docs/kx134_migration/TICKET_BACKLOG.md`
- Actualizacion de `reports/change_log.md`

## Restricciones

- No modificar `main.cpp` del firmware.
- No modificar firmware ADXL335 existente.
- No modificar receptor.
- No modificar GUI.
- No modificar empaquetado.
- No modificar datos historicos.
- No subir firmware automaticamente.
- No modificar PATH automaticamente.
- No commitear `.pio` ni binarios.

## Criterios de aceptacion

- El cableado queda documentado.
- Existen wrappers PlatformIO.
- Los wrappers permiten usar PlatformIO aunque `pio` no este en PATH.
- Existe script opcional para agregar PlatformIO al PATH de usuario.
- El build del firmware puede ejecutarse usando el wrapper si PlatformIO esta disponible.
- No hay cambios funcionales en firmware.
- No hay cambios en GUI.
- No hay cambios en empaquetado.
- Git queda limpio despues del commit.
- La rama queda publicada en origin si las credenciales lo permiten.

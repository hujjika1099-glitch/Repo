# Estado de sincronizacion del repositorio - 2026-05-08

## Resumen

Se reviso el repositorio local `Proyecto de Maestria: ADXL335 + ESP32` contra
los remotos configurados durante la auditoria.

Resultado final: **repositorio local limpio, documentado y listo para quedar en
linea con el remoto correcto de ADXL335/UQ por fast-forward**.

## Evidencia local

- Rama local: `main`.
- HEAD local antes del cierre: `2b348b9 feat: Phase 15.5-15.6 - exe packaging, user manual and full repo update`.
- El arbol local corresponde al sistema ADXL335/UQ:
  - `gui/adxl_live_gui.py`
  - `gui/adxl_live_core.py`
  - `firmware/single_node_calibration/`
  - `firmware/dual_node_espnow/`
  - `data/raw/`
  - `reports/analysis_outputs/`

## Evidencia remota

- Remoto incorrecto detectado inicialmente:
  - `origin https://github.com/okuajardinbiosonoro-art/Control-OK-A-v2.git`
- Despues de `git fetch origin --prune` sobre ese remoto, `origin/main` quedo en:
  - `6a16c33 docs(38.0): aceptacion operativa interna formal - plan de mantenimiento`
- Git reporto actualizacion forzada del remoto:
  - `2b348b9...6a16c33 main -> origin/main (forced update)`
- Comparacion posterior:
  - local `main`: `ahead 28, behind 186` antes del commit de cierre.
  - `origin/main` contiene estructura `src/control_okua/`, `ControlOkuaV2.spec`, `assets/branding/`, `docs/ui/`, `tests/`, etc.
- Remoto correcto informado posteriormente para ADXL335/UQ:
  - HTTPS: `https://github.com/hujjika1099-glitch/Repo.git`
  - SSH: `git@github.com:hujjika1099-glitch/Repo.git`
  - `origin/main` estaba en `2b348b9`, compatible con fast-forward desde el cierre local.
- El remoto incorrecto se conserva como referencia bajo el nombre:
  - `control-okua-v2 https://github.com/okuajardinbiosonoro-art/Control-OK-A-v2.git`

## Intento de publicacion

Se ejecuto `git push origin main` sin force contra el remoto incorrecto inicial.
GitHub rechazo el push con `non-fast-forward`, por lo que no se modifico esa nube.

Estado local posterior al commit de cierre:

- `main` queda limpio en working tree.
- La rama queda un commit adelante del remoto correcto antes del push final.

Intentos contra el remoto correcto:

- HTTPS: `git push -u origin main` fallo con `403`, porque las credenciales
  activas pertenecen a `okuajardinbiosonoro-art`, sin permiso sobre
  `hujjika1099-glitch/Repo.git`.
- SSH: `git push -u origin main` fallo con `Permission denied (publickey)`, por
  falta de una llave SSH autorizada para ese repositorio/cuenta.
- Despues de autorizar la llave SSH local, `git ls-remote origin` respondio
  correctamente sobre `git@github.com:hujjika1099-glitch/Repo.git`.

## Decision operativa

No se debe forzar `main` hacia `control-okua-v2/main`, porque eso pisaria una
linea remota que corresponde a Control OKUA v2 y no a la historia ADXL335/UQ.

La decision correcta es publicar el cierre local en:

- `https://github.com/hujjika1099-glitch/Repo.git`

Ese remoto contiene la historia ADXL335/UQ en `2b348b9` y acepta el cierre local
por fast-forward con la llave SSH autorizada.

El cierre local queda contenido en un unico commit posterior a `2b348b9`:

- `chore: preserve ADXL335 local state and sync audit`

## Limpieza aplicada

- Se normalizo el manual de usuario al nombre canonico documentado:
  `ADXL335_Captura_Manual.pdf`.
- Se preservaron los datos crudos y reportes de evidencia sin borrarlos.
- No se eliminaron carpetas generadas grandes (`.venv/`, `dist/`, `build_work/`)
  porque estan ignoradas por Git y pueden ser necesarias para operacion local.

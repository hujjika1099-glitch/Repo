# Criterios Rapidos de Aceptacion - Fase 12

## Criterios base (quickcheck)
1. Stream valido:
   - `samples >= 500`
   - `seq_jumps <= 1`
   - `85 <= freq_hz <= 115`
2. Saturacion:
   - `sat_pct_ready_max <= 1%` para estado listo
   - `sat_pct_review_max <= 5%` para estado provisional
   - `sat_pct_reject_min >= 80%` para rechazo directo
3. Coherencia minima por eje:
   - span bruto por eje >= 4 cuentas (evitar canal pegado)
   - sin canal clavado en riel (span <= 2 y media cerca de 0 o 4095)

## Decision automatica
- `ready_for_operational_use`:
  stream estricto + saturacion <= 1% + span minimo OK.
- `ready_for_operational_use_provisional`:
  stream base OK + saturacion <= 5%.
- `hardware_review_needed`:
  stream o saturacion fuera de rango provisional, sin hard-fail.
- `rejected_module`:
  saturacion dura (>=80%) o canal clavado a riel.

## Regla de tiempo
- No invertir mas de 15 minutos por modulo en Fase 12.
- Si falla quickcheck, se permite una sola repeticion tras correccion minima.
- Si vuelve a fallar, escalar segun estado y continuar con otro modulo.

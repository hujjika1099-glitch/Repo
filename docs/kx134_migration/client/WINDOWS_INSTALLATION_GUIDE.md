# Guia de instalacion Windows

## Requisitos

- Windows 10 o Windows 11.
- Puerto USB disponible para el Receptor.
- No requiere Python instalado.
- No requiere modificar PATH.

## Instalacion

1. Copie el ZIP `Sistema_Captura_Acelerometria_dist.zip` al PC.
2. Descomprima el ZIP en una carpeta simple, por ejemplo `C:\UQ_KX134_QA\Sistema_Captura_Acelerometria`.
3. No ejecute la aplicacion desde dentro del ZIP.
4. Abra `Sistema_Captura_Acelerometria.exe`.

## Seguridad Windows

El ejecutable puede activar SmartScreen o antivirus porque no tiene firma digital. Si el archivo proviene del paquete entregado y el usuario confia en el origen, puede usar la opcion de continuar/ejecutar de todas formas.

Pendientes conocidos:

- Firma digital.
- Icono corporativo.

## Ubicacion recomendada

Use una ruta corta y estable:

- `C:\UQ_KX134_QA\Sistema_Captura_Acelerometria`
- `C:\KX134\Sistema_Captura_Acelerometria`

Evite ejecutar desde carpetas temporales o desde el ZIP.

## Ejecucion

1. Abra `Sistema_Captura_Acelerometria.exe`.
2. En el launcher, seleccione KX134 Dual Capture.
3. Para compatibilidad historica, el launcher tambien permite abrir ADXL335.

## Problemas comunes

- SmartScreen bloquea: confirmar origen y usar ejecutar de todas formas.
- Antivirus bloquea: registrar el evento y consultar soporte.
- No aparece puerto COM: revisar cable USB, Administrador de dispositivos y driver.
- Error de permisos: mover carpeta a una ruta simple con permisos de escritura.
- GUI cortada: maximizar, revisar scaling, reportar resolucion y porcentaje de scaling.

## Estado de producto

El prototipo esta listo para entrega funcional. La baquelada RevA fue validada como funcional por el experto del proyecto y esta aceptada para uso de prototipo. La fabricacion repetible o industrial requiere un paquete adicional de DFM, BOM final, Gerbers y QA de manufactura si el cliente lo solicita.

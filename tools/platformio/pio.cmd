@echo off
setlocal

where pio.exe >nul 2>nul
if %ERRORLEVEL%==0 (
    pio.exe %*
    exit /b %ERRORLEVEL%
)

set "PIO_EXE=%USERPROFILE%\.platformio\penv\Scripts\pio.exe"
if exist "%PIO_EXE%" (
    "%PIO_EXE%" %*
    exit /b %ERRORLEVEL%
)

echo PlatformIO no esta disponible.
echo.
echo Ruta esperada:
echo   %%USERPROFILE%%\.platformio\penv\Scripts\pio.exe
echo.
echo Si PlatformIO ya esta instalado pero pio no esta en PATH, ejecute:
echo   powershell -ExecutionPolicy Bypass -File tools\platformio\setup_platformio_user_path.ps1
exit /b 1

# adxl_captura.spec
# Archivo de configuracion de PyInstaller para ADXL335_Captura.exe
#
# Uso:
#   Ejecutar build_exe.ps1 desde la raiz del repo, o manualmente:
#   .venv\Scripts\pyinstaller.exe adxl_captura.spec --noconfirm
#
# SPECPATH es la carpeta donde esta este archivo (raiz del repo).

from pathlib import Path

block_cipher = None

repo_root = Path(SPECPATH)
gui_dir   = str(repo_root / "gui")

a = Analysis(
    [str(repo_root / "gui" / "adxl_live_gui.py")],
    pathex=[gui_dir],           # permite resolver "from adxl_live_core import ..."
    binaries=[],
    datas=[],
    hiddenimports=[
        # pyserial puede necesitar estos modulos en Windows
        "serial",
        "serial.tools",
        "serial.tools.list_ports",
        "serial.tools.list_ports_common",
        "serial.tools.list_ports_windows",
    ],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[
        # Excluir lo que no se usa para reducir tamano
        "matplotlib",
        "numpy",
        "scipy",
        "pandas",
        "PIL",
        "IPython",
        "jupyter",
        "notebook",
    ],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.zipfiles,
    a.datas,
    [],
    name="ADXL335_Captura",
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=False,          # sin ventana de consola (app GUI)
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon=None,              # poner aqui la ruta a un .ico si se desea
)

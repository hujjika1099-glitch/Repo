# sistema_captura_acelerometria.spec
# PyInstaller onedir build for Sistema_Captura_Acelerometria.exe.

from pathlib import Path

block_cipher = None

repo_root = Path(SPECPATH)
gui_dir = repo_root / "gui"

datas = [
    (str(repo_root / "config" / "kx134_node_map.json"), "config"),
    (str(repo_root / "config" / "kx134_transport_contract_v3.json"), "config"),
    (str(repo_root / "config" / "calibrations" / "kx134_sensor_1.json"), "config/calibrations"),
    (str(repo_root / "config" / "calibrations" / "kx134_sensor_2.json"), "config/calibrations"),
]

a = Analysis(
    [str(repo_root / "gui" / "app_launcher.py")],
    pathex=[str(repo_root), str(gui_dir)],
    binaries=[],
    datas=datas,
    hiddenimports=[
        "gui",
        "gui.app_launcher",
        "gui.adxl_live_core",
        "gui.adxl_live_gui",
        "gui.kx134_live_core",
        "gui.kx134_live_gui",
        "gui.kx134_live_plots",
        "gui.kx134_stream_contract",
        "gui.ui_components",
        "gui.ui_theme",
        "serial",
        "serial.tools",
        "serial.tools.list_ports",
        "serial.tools.list_ports_common",
        "serial.tools.list_ports_windows",
        "tkinter",
        "tkinter.ttk",
        "queue",
        "threading",
    ],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[
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
    [],
    exclude_binaries=True,
    name="Sistema_Captura_Acelerometria",
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon=None,
    manifest=str(repo_root / "packaging" / "windows" / "dpi_aware.manifest"),
)

coll = COLLECT(
    exe,
    a.binaries,
    a.zipfiles,
    a.datas,
    strip=False,
    upx=True,
    upx_exclude=[],
    name="Sistema_Captura_Acelerometria",
)

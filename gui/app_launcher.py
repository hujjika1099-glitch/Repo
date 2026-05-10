from __future__ import annotations

import argparse
import subprocess
import sys
import tkinter as tk
from pathlib import Path
from tkinter import ttk

try:
    from . import ui_theme
except ImportError:  # pragma: no cover
    import ui_theme


APP_PRODUCT_TITLE = "Sistema de Captura de Acelerometria"
VALID_MODES = ("launcher", "kx134", "adxl")


def is_frozen() -> bool:
    return bool(getattr(sys, "frozen", False))


def _module_command(module_name: str) -> list[str]:
    return [sys.executable, "-m", module_name]


def child_command_for_mode(mode: str, *, frozen: bool | None = None) -> list[str]:
    if mode not in ("kx134", "adxl"):
        raise ValueError(f"unsupported child mode: {mode}")
    frozen = is_frozen() if frozen is None else frozen
    if frozen:
        return [sys.executable, "--mode", mode]
    return [sys.executable, "-m", "gui.app_launcher", "--mode", mode]


def launch_child_mode(mode: str, *, cwd: Path | None = None) -> subprocess.Popen:
    command = child_command_for_mode(mode)
    launch_cwd = cwd or (Path(sys.executable).resolve().parent if is_frozen() else Path(__file__).resolve().parents[1])
    return subprocess.Popen(command, cwd=launch_cwd)


class AppLauncher(tk.Tk):
    def __init__(self, args: argparse.Namespace | None = None) -> None:
        ui_theme.set_windows_dpi_awareness_best_effort()
        super().__init__()
        self.args = args or argparse.Namespace(close_after_ms=0)
        self.title(APP_PRODUCT_TITLE)
        self.geometry("820x520")
        self.minsize(720, 460)
        ui_theme.apply_base_theme(self)
        ui_theme.configure_ttk_styles(self)
        self.status_var = tk.StringVar(value="Seleccione un modo de captura.")
        self._build_layout()
        if getattr(self.args, "close_after_ms", 0):
            self.after(int(self.args.close_after_ms), self.destroy)

    def _build_layout(self) -> None:
        self.columnconfigure(0, weight=1)
        self.rowconfigure(1, weight=1)
        header = ttk.Frame(self, style="App.TFrame", padding=24)
        header.grid(row=0, column=0, sticky="ew")
        header.columnconfigure(0, weight=1)
        ttk.Label(header, text=APP_PRODUCT_TITLE, style="Header.TLabel").grid(row=0, column=0, sticky="w")
        ttk.Label(
            header,
            text="KX134 validado para captura dual y ADXL335 disponible como flujo historico.",
            style="Subheader.TLabel",
        ).grid(row=1, column=0, sticky="w", pady=(6, 0))

        body = ttk.Frame(self, style="App.TFrame", padding=(24, 0, 24, 24))
        body.grid(row=1, column=0, sticky="nsew")
        body.columnconfigure((0, 1), weight=1)
        body.rowconfigure(0, weight=1)
        self._mode_card(
            body,
            column=0,
            title="KX134 Dual Capture",
            detail="Flujo actual validado: dos sensores KX134 via ESP-NOW, receptor USB Serial y exportacion endurecida.",
            button_text="Abrir KX134 Dual Capture",
            command=self.open_kx134,
            primary=True,
        )
        self._mode_card(
            body,
            column=1,
            title="ADXL335 historico",
            detail="Modulo operativo previo para continuidad de capturas ADXL335 sin cambiar su logica.",
            button_text="Abrir ADXL335 historico",
            command=self.open_adxl,
            primary=False,
        )
        ttk.Label(body, textvariable=self.status_var, style="Subheader.TLabel").grid(row=1, column=0, columnspan=2, sticky="w", pady=(18, 0))

    def _mode_card(
        self,
        master: tk.Misc,
        *,
        column: int,
        title: str,
        detail: str,
        button_text: str,
        command: callable,
        primary: bool,
    ) -> None:
        card = ttk.Labelframe(master, text=title, style="Section.TLabelframe", padding=18)
        card.grid(row=0, column=column, sticky="nsew", padx=(0 if column == 0 else 10, 10 if column == 0 else 0))
        card.columnconfigure(0, weight=1)
        ttk.Label(card, text=detail, style="Body.TLabel", wraplength=300).grid(row=0, column=0, sticky="new")
        ttk.Button(
            card,
            text=button_text,
            style="Primary.TButton" if primary else "Secondary.TButton",
            command=command,
        ).grid(row=1, column=0, sticky="ew", pady=(24, 0))

    def open_kx134(self) -> None:
        self._launch_mode("kx134", "KX134 Dual Capture")

    def open_adxl(self) -> None:
        self._launch_mode("adxl", "ADXL335 historico")

    def _launch_mode(self, mode: str, label: str) -> None:
        try:
            launch_child_mode(mode)
            self.status_var.set(f"{label} abierto.")
        except Exception as exc:
            self.status_var.set(f"No se pudo abrir {label}: {exc}")


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Launcher principal de la aplicacion de acelerometria")
    parser.add_argument("--mode", choices=VALID_MODES, default="launcher")
    parser.add_argument("--smoke", action="store_true")
    parser.add_argument("--close-after-ms", type=int, default=0)
    return parser.parse_args(argv)


def create_app(args: argparse.Namespace | None = None) -> AppLauncher:
    return AppLauncher(args or parse_args([]))


def main(argv: list[str] | None = None) -> None:
    args = parse_args(argv)
    if args.smoke and not args.close_after_ms:
        args.close_after_ms = 1000
    if args.mode == "kx134":
        try:
            from . import kx134_live_gui
        except ImportError:  # pragma: no cover - direct script/frozen fallback
            import kx134_live_gui

        child_args = []
        if args.smoke:
            child_args.append("--smoke")
        if args.close_after_ms:
            child_args.extend(["--close-after-ms", str(args.close_after_ms)])
        kx134_live_gui.main(child_args)
        return
    if args.mode == "adxl":
        try:
            from . import adxl_live_gui
        except ImportError:  # pragma: no cover - direct script/frozen fallback
            import adxl_live_gui

        child_args = []
        if args.smoke:
            child_args.append("--smoke")
        if args.close_after_ms:
            child_args.extend(["--close-after-ms", str(args.close_after_ms)])
        adxl_live_gui.main(child_args)
        return
    app = AppLauncher(args)
    app.mainloop()


if __name__ == "__main__":
    main()

from __future__ import annotations

import ctypes
import sys
import tkinter as tk
from tkinter import ttk


APP_TITLE = "Sistema de Captura Dual KX134"
VERSION_LABEL = "KX134 GUI prototype"
DEFAULT_WINDOW_SIZE = "1180x760"
MIN_WINDOW_SIZE = (980, 640)
PADDING = 14
SECTION_PADDING = 12

APP_BG = "#eef3f5"
SURFACE = "#ffffff"
SURFACE_ALT = "#f6f8f9"
BORDER = "#d7e0e4"
TEXT_MAIN = "#15242b"
TEXT_MUTED = "#5f737b"
ACCENT = "#116a7b"
ACCENT_DARK = "#0d5360"
SUCCESS = "#167a45"
WARNING = "#9a6500"
DANGER = "#b42318"


def set_windows_dpi_awareness_best_effort() -> None:
    if not sys.platform.startswith("win"):
        return
    try:
        ctypes.windll.shcore.SetProcessDpiAwareness(1)
        return
    except Exception:
        pass
    try:
        ctypes.windll.user32.SetProcessDPIAware()
    except Exception:
        pass


def apply_base_theme(root: tk.Misc) -> None:
    if isinstance(root, (tk.Tk, tk.Toplevel)):
        root.configure(bg=APP_BG)


def configure_ttk_styles(root: tk.Misc) -> None:
    style = ttk.Style(root)
    try:
        style.theme_use("clam")
    except tk.TclError:
        pass

    style.configure(".", background=APP_BG, foreground=TEXT_MAIN, font=("Segoe UI", 10))
    style.configure("App.TFrame", background=APP_BG)
    style.configure("Surface.TFrame", background=SURFACE)
    style.configure("SurfaceAlt.TFrame", background=SURFACE_ALT)
    style.configure("Header.TLabel", background=APP_BG, foreground=TEXT_MAIN, font=("Segoe UI Semibold", 20))
    style.configure("Subheader.TLabel", background=APP_BG, foreground=TEXT_MUTED, font=("Segoe UI", 10))
    style.configure("Section.TLabelframe", background=SURFACE, bordercolor=BORDER, relief="solid")
    style.configure("Section.TLabelframe.Label", background=SURFACE, foreground=TEXT_MAIN, font=("Segoe UI Semibold", 11))
    style.configure("Body.TLabel", background=SURFACE, foreground=TEXT_MAIN)
    style.configure("Muted.TLabel", background=SURFACE, foreground=TEXT_MUTED)
    style.configure("StatusOk.TLabel", background=SURFACE, foreground=SUCCESS, font=("Segoe UI Semibold", 10))
    style.configure("StatusWarn.TLabel", background=SURFACE, foreground=WARNING, font=("Segoe UI Semibold", 10))
    style.configure("StatusError.TLabel", background=SURFACE, foreground=DANGER, font=("Segoe UI Semibold", 10))
    style.configure("Primary.TButton", background=ACCENT, foreground="#ffffff", padding=(14, 8), font=("Segoe UI Semibold", 10))
    style.map("Primary.TButton", background=[("active", ACCENT_DARK), ("disabled", "#8fa7ad")])
    style.configure("Secondary.TButton", background=SURFACE_ALT, foreground=TEXT_MAIN, padding=(12, 7))
    style.map("Secondary.TButton", background=[("active", "#e7eef1")])
    style.configure("TNotebook", background=APP_BG, borderwidth=0)
    style.configure("TNotebook.Tab", padding=(16, 8), font=("Segoe UI", 10))
    style.configure("TEntry", fieldbackground="#ffffff")
    style.configure("TCombobox", fieldbackground="#ffffff")

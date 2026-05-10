from __future__ import annotations

import os
import subprocess
import tkinter as tk
from pathlib import Path
from tkinter import ttk

try:
    from . import ui_theme
except ImportError:  # pragma: no cover
    import ui_theme


def safe_set_grid_weights(widget: tk.Misc, *, rows: tuple[int, ...] = (), columns: tuple[int, ...] = ()) -> None:
    for row in rows:
        widget.rowconfigure(row, weight=1)
    for column in columns:
        widget.columnconfigure(column, weight=1)


def section(master: tk.Misc, title: str) -> ttk.Labelframe:
    return ttk.Labelframe(master, text=title, style="Section.TLabelframe", padding=ui_theme.SECTION_PADDING)


class ScrollableFrame(ttk.Frame):
    def __init__(self, master: tk.Misc, **kwargs: object) -> None:
        super().__init__(master, style="Surface.TFrame", **kwargs)
        self.canvas = tk.Canvas(self, borderwidth=0, highlightthickness=0, background=ui_theme.SURFACE)
        self.scrollbar = ttk.Scrollbar(self, orient="vertical", command=self.canvas.yview)
        self.content = ttk.Frame(self.canvas, style="Surface.TFrame")
        self.window_id = self.canvas.create_window((0, 0), window=self.content, anchor="nw")
        self.canvas.configure(yscrollcommand=self.scrollbar.set)
        self.canvas.grid(row=0, column=0, sticky="nsew")
        self.scrollbar.grid(row=0, column=1, sticky="ns")
        safe_set_grid_weights(self, rows=(0,), columns=(0,))
        self.content.bind("<Configure>", self._on_content_configure)
        self.canvas.bind("<Configure>", self._on_canvas_configure)
        self.canvas.bind_all("<MouseWheel>", self._on_mousewheel, add="+")

    def _on_content_configure(self, _event: tk.Event) -> None:
        self.canvas.configure(scrollregion=self.canvas.bbox("all"))

    def _on_canvas_configure(self, event: tk.Event) -> None:
        self.canvas.itemconfigure(self.window_id, width=event.width)

    def _on_mousewheel(self, event: tk.Event) -> None:
        if not self.winfo_ismapped():
            return
        self.canvas.yview_scroll(int(-1 * (event.delta / 120)), "units")


class StatusCard(ttk.Frame):
    def __init__(self, master: tk.Misc, *, title: str, value: str = "--", detail: str = "") -> None:
        super().__init__(master, style="Surface.TFrame", padding=12)
        self.title_var = tk.StringVar(value=title)
        self.value_var = tk.StringVar(value=value)
        self.detail_var = tk.StringVar(value=detail)
        ttk.Label(self, textvariable=self.title_var, style="Muted.TLabel").grid(row=0, column=0, sticky="w")
        self.value_label = ttk.Label(self, textvariable=self.value_var, style="Body.TLabel")
        self.value_label.grid(row=1, column=0, sticky="w", pady=(5, 2))
        ttk.Label(self, textvariable=self.detail_var, style="Muted.TLabel", wraplength=260).grid(row=2, column=0, sticky="ew")
        self.columnconfigure(0, weight=1)

    def update(self, value: str, detail: str = "", *, tone: str = "neutral") -> None:
        self.value_var.set(value)
        self.detail_var.set(detail)
        style = {
            "ok": "StatusOk.TLabel",
            "warn": "StatusWarn.TLabel",
            "error": "StatusError.TLabel",
        }.get(tone, "Body.TLabel")
        self.value_label.configure(style=style)


class KeyValuePanel(ttk.Frame):
    def __init__(self, master: tk.Misc, rows: list[tuple[str, tk.StringVar]]) -> None:
        super().__init__(master, style="Surface.TFrame")
        self.value_labels: list[ttk.Label] = []
        for row_index, (label, variable) in enumerate(rows):
            ttk.Label(self, text=label, style="Muted.TLabel").grid(row=row_index, column=0, sticky="w", pady=4, padx=(0, 12))
            value_label = ttk.Label(self, textvariable=variable, style="Body.TLabel", wraplength=460)
            value_label.grid(row=row_index, column=1, sticky="ew", pady=4)
            self.value_labels.append(value_label)
        self.columnconfigure(1, weight=1)


class FileArtifactPanel(ttk.Frame):
    def __init__(self, master: tk.Misc) -> None:
        super().__init__(master, style="Surface.TFrame")
        self.path_vars = {
            "raw_csv": tk.StringVar(value="Pendiente"),
            "session_json": tk.StringVar(value="Pendiente"),
            "summary_md": tk.StringVar(value="Pendiente"),
        }
        labels = {
            "raw_csv": "CSV raw",
            "session_json": "Session JSON",
            "summary_md": "Summary MD",
        }
        for row_index, key in enumerate(("raw_csv", "session_json", "summary_md")):
            ttk.Label(self, text=labels[key], style="Muted.TLabel").grid(row=row_index, column=0, sticky="w", pady=5)
            entry = ttk.Entry(self, textvariable=self.path_vars[key], state="readonly")
            entry.grid(row=row_index, column=1, sticky="ew", padx=(10, 8), pady=5)
            ttk.Button(self, text="Copiar", command=lambda item=key: self.copy_path(item)).grid(row=row_index, column=2, sticky="ew", pady=5)
        ttk.Button(self, text="Abrir carpeta", command=self.open_first_folder).grid(row=3, column=1, sticky="w", pady=(10, 0))
        self.columnconfigure(1, weight=1)

    def set_paths(self, *, raw_csv: str, session_json: str, summary_md: str) -> None:
        self.path_vars["raw_csv"].set(raw_csv)
        self.path_vars["session_json"].set(session_json)
        self.path_vars["summary_md"].set(summary_md)

    def copy_path(self, key: str) -> None:
        text = self.path_vars[key].get()
        self.clipboard_clear()
        self.clipboard_append(text)

    def open_first_folder(self) -> None:
        for variable in self.path_vars.values():
            path = Path(variable.get())
            if path.exists():
                folder = path.parent
                if os.name == "nt":
                    os.startfile(folder)  # type: ignore[attr-defined]
                else:
                    subprocess.Popen(["xdg-open", str(folder)])
                return

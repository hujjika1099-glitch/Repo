from __future__ import annotations

import argparse
import math
import queue
import sys
from collections import deque
from pathlib import Path
from typing import Iterable

import tkinter as tk
from tkinter import ttk

from adxl_live_core import (
    LiveCaptureWorker,
    LiveSessionConfig,
    PortResolution,
    Sample,
    SessionResult,
    list_serial_inventory,
    make_relpath,
)


APP_BG = "#071219"
PANEL_BG = "#0d2230"
PANEL_ALT = "#133244"
CANVAS_BG = "#09161e"
TEXT_MAIN = "#eef6f8"
TEXT_MUTED = "#91afbb"
ACCENT = "#f2a65a"
ACCENT_ALT = "#7bdff2"
SUCCESS = "#78d6a3"
WARNING = "#ffd166"
DANGER = "#ff7b7b"
GRID_COLOR = "#234759"
AXIS_COLORS = {"x": "#ff8c61", "y": "#7bdff2", "z": "#b8f2e6"}
AUTO_PORT_LABEL = "Automatico"
PRIMARY_SENSOR_FULL = "Sensor principal"
SECONDARY_SENSOR_FULL = "Sensor secundario"
PRIMARY_SENSOR_SHORT = "Principal"
SECONDARY_SENSOR_SHORT = "Secundario"
SENSOR_VIEW_LABELS = {
    PRIMARY_SENSOR_SHORT: 1,
    SECONDARY_SENSOR_SHORT: 2,
}


def friendly_reason(reason: str) -> str:
    reason = str(reason or "").strip()
    mapping = {
        "dual_integrity_ok": "Todo listo para capturar.",
        "integrity_ok": "Comportamiento estable.",
        "basic_live_sanity_ok": "Senal dentro de lo esperado.",
        "few_samples": "Muy pocas muestras. Conviene repetir.",
        "packet_loss_excessive": "Se perdieron demasiados paquetes.",
        "adc_saturation": "La senal esta saturando el sensor.",
        "g_norm_implausible": "La norma |g| luce fisicamente incoherente.",
        "g_norm_borderline": "La norma |g| quedo en zona dudosa.",
        "low_signal_span": "La senal es demasiado plana.",
        "low_signal_span_static": "La senal casi no cambio en el chequeo previo.",
        "dead_axis_or_disconnected": "Se detecta un eje muerto o desconectado.",
        "counter_reset_detected": "Se detecto un reinicio del conteo.",
        "missing_header": "No llego el encabezado esperado del firmware.",
        "precheck_disabled": "Chequeo previo desactivado.",
        "sensor_missing": "No llegaron datos de este sensor.",
        "not_run": "Aun no se ha ejecutado.",
    }
    if ";" in reason:
        parts = [friendly_reason(part) for part in reason.split(";") if part.strip()]
        return " ".join(parts)
    if ":" in reason and reason.startswith("sensor_"):
        sensor_id, raw = reason.split(":", 1)
        label = PRIMARY_SENSOR_FULL if sensor_id == "sensor_1" else SECONDARY_SENSOR_FULL
        return f"{label}: {friendly_reason(raw)}"
    return mapping.get(reason, reason.replace("_", " ").capitalize() + ".")


def summarize_error_message(message: str) -> str:
    text = str(message or "").strip()
    if not text:
        return "Ocurrio un error inesperado."
    if text.startswith("Precheck dual no superado:"):
        detail = text.split(":", 1)[1].strip()
        detail = detail.split(". Revise ", 1)[0].strip()
        return friendly_reason(detail)
    if text.startswith("Sesion live sin muestras validas"):
        return "No entraron datos validos durante la sesion."
    if text.startswith("No se detectaron puertos seriales"):
        return "No se encontro el equipo."
    if text.startswith("El puerto solicitado"):
        return "El puerto seleccionado no esta disponible."
    first_sentence = text.split(". ", 1)[0].strip()
    return friendly_reason(first_sentence)


def status_to_badge(status: str) -> tuple[str, str]:
    status = str(status or "").strip().lower()
    mapping = {
        "pass": ("Listo", SUCCESS),
        "success": ("Listo", SUCCESS),
        "suspect": ("Revisar", WARNING),
        "warning": ("Revisar", WARNING),
        "fail": ("Fallo", DANGER),
        "error": ("Error", DANGER),
        "idle": ("En espera", TEXT_MAIN),
        "boot": ("Preparando", ACCENT_ALT),
        "precheck": ("Chequeando", ACCENT),
        "capture": ("Grabando", ACCENT_ALT),
        "completed": ("Completado", SUCCESS),
        "cancelled": ("Cancelado", WARNING),
    }
    return mapping.get(status, (status.capitalize() or "--", TEXT_MAIN))


def compact_port_label(device: str, description: str) -> str:
    text = (description or "").strip()
    replacements = {
        "USB-SERIAL CH340": "CH340",
        "USB Serial Device": "Serial USB",
        "Silicon Labs CP210x USB to UART Bridge": "CP210x",
    }
    for source, target in replacements.items():
        text = text.replace(source, target)
    if "(" in text:
        text = text.split("(", 1)[0].strip()
    if len(text) > 24:
        text = text[:21].rstrip() + "..."
    return f"{device} - {text or 'Dispositivo'}"


class LinePlot(ttk.Frame):
    def __init__(
        self,
        master: tk.Misc,
        *,
        title: str,
        subtitle: str,
        y_label: str,
        reference_lines: Iterable[float] | None = None,
        height: int = 300,
    ) -> None:
        super().__init__(master, style="Card.TFrame", padding=14)
        self.reference_lines = list(reference_lines or [])
        self.y_label = y_label
        self.height = height
        self.series: dict[str, dict[str, object]] = {}
        self._y_bounds: tuple[float, float] | None = None

        self.title_var = tk.StringVar(value=title)
        self.subtitle_var = tk.StringVar(value=subtitle)

        header = ttk.Frame(self, style="Card.TFrame")
        header.pack(fill="x")
        ttk.Label(header, textvariable=self.title_var, style="CardTitle.TLabel").pack(anchor="w")
        ttk.Label(header, textvariable=self.subtitle_var, style="BodyMuted.TLabel").pack(anchor="w", pady=(4, 0))

        self.canvas = tk.Canvas(
            self,
            background=CANVAS_BG,
            height=height,
            highlightthickness=0,
            bd=0,
        )
        self.canvas.pack(fill="both", expand=True, pady=(10, 0))
        self.legend_var = tk.StringVar(value="")
        ttk.Label(self, textvariable=self.legend_var, style="BodyMuted.TLabel").pack(anchor="w", pady=(8, 0))
        self.canvas.bind("<Configure>", lambda _event: self.redraw())

    def set_series(
        self,
        series: dict[str, dict[str, object]],
        *,
        subtitle: str | None = None,
        y_bounds: tuple[float, float] | None = None,
    ) -> None:
        self.series = series
        if subtitle is not None:
            self.subtitle_var.set(subtitle)
        self._y_bounds = y_bounds
        self.redraw()

    def redraw(self) -> None:
        width = max(self.canvas.winfo_width(), 320)
        height = max(self.canvas.winfo_height(), self.height)
        self.canvas.delete("all")

        left = 58
        right = width - 20
        top = 18
        bottom = height - 34
        plot_width = max(right - left, 60)
        plot_height = max(bottom - top, 60)

        self.canvas.create_rectangle(left, top, right, bottom, outline=GRID_COLOR, width=1)
        for step in range(1, 5):
            y = top + plot_height * step / 5
            self.canvas.create_line(left, y, right, y, fill=GRID_COLOR, dash=(3, 5))

        all_points: list[tuple[float, float]] = []
        for config in self.series.values():
            all_points.extend(config.get("points", []))

        if not all_points:
            self.canvas.create_text(
                width / 2,
                height / 2,
                text="La grafica aparecera cuando empiece a llegar senal.",
                fill=TEXT_MUTED,
                font=("Segoe UI", 12),
            )
            self.legend_var.set("")
            return

        x_values = [point[0] for point in all_points]
        y_values = [point[1] for point in all_points]
        x_min = min(x_values)
        x_max = max(x_values)
        if math.isclose(x_min, x_max, rel_tol=0.0, abs_tol=1e-9):
            x_min -= 1.0
            x_max += 1.0

        if self._y_bounds is None:
            y_min = min(y_values)
            y_max = max(y_values)
            if math.isclose(y_min, y_max, rel_tol=0.0, abs_tol=1e-9):
                y_min -= 0.5
                y_max += 0.5
            padding = max((y_max - y_min) * 0.14, 0.08)
            y_min -= padding
            y_max += padding
        else:
            y_min, y_max = self._y_bounds

        for ref_value in self.reference_lines:
            y = bottom - ((ref_value - y_min) / max(y_max - y_min, 1e-9)) * plot_height
            self.canvas.create_line(left, y, right, y, fill=ACCENT, dash=(8, 4), width=1.5)
            self.canvas.create_text(right - 4, y - 10, text=f"{ref_value:.2f}", fill=ACCENT, anchor="ne")

        legend_parts: list[str] = []
        for label, config in self.series.items():
            points = config.get("points", [])
            color = str(config.get("color", ACCENT_ALT))
            legend_parts.append(label)
            if not points:
                continue
            if len(points) == 1:
                x = left + ((points[0][0] - x_min) / max(x_max - x_min, 1e-9)) * plot_width
                y = bottom - ((points[0][1] - y_min) / max(y_max - y_min, 1e-9)) * plot_height
                self.canvas.create_oval(x - 3, y - 3, x + 3, y + 3, fill=color, outline=color)
                continue

            coords: list[float] = []
            for x_value, y_value in points:
                x = left + ((x_value - x_min) / max(x_max - x_min, 1e-9)) * plot_width
                y = bottom - ((y_value - y_min) / max(y_max - y_min, 1e-9)) * plot_height
                coords.extend([x, y])
            self.canvas.create_line(*coords, fill=color, width=2.2)

        self.legend_var.set("  |  ".join(legend_parts))
        self.canvas.create_text(18, top, text=self.y_label, fill=TEXT_MUTED, anchor="nw")
        self.canvas.create_text(left, bottom + 14, text=f"{x_min:.1f}s", fill=TEXT_MUTED, anchor="sw")
        self.canvas.create_text(right, bottom + 14, text=f"{x_max:.1f}s", fill=TEXT_MUTED, anchor="se")
        self.canvas.create_text(left - 8, top, text=f"{y_max:.2f}", fill=TEXT_MUTED, anchor="e")
        self.canvas.create_text(left - 8, bottom, text=f"{y_min:.2f}", fill=TEXT_MUTED, anchor="e")


class MetricTile(ttk.Frame):
    def __init__(self, master: tk.Misc, *, title: str) -> None:
        super().__init__(master, style="Metric.TFrame", padding=10)
        self.title_var = tk.StringVar(value=title)
        self.value_var = tk.StringVar(value="--")
        self.detail_var = tk.StringVar(value="")

        self.title_label = ttk.Label(self, textvariable=self.title_var, style="TileTitle.TLabel", anchor="w", justify="left")
        self.title_label.pack(anchor="w", fill="x")
        self.value_label = ttk.Label(self, textvariable=self.value_var, style="TileValue.TLabel", anchor="w", justify="left")
        self.value_label.pack(anchor="w", fill="x", pady=(6, 2))
        self.detail_label = ttk.Label(self, textvariable=self.detail_var, style="TileDetail.TLabel", anchor="w", justify="left")
        self.detail_label.pack(anchor="w", fill="x")
        self.bind("<Configure>", self._on_resize)

    def update(self, value: str, detail: str = "", *, tone: str = "neutral") -> None:
        self.value_var.set(value)
        self.detail_var.set(detail)
        _, color = status_to_badge(tone)
        self.value_label.configure(foreground=color)

    def _on_resize(self, _event: tk.Event) -> None:
        wrap = max(self.winfo_width() - 24, 90)
        self.title_label.configure(wraplength=wrap)
        self.value_label.configure(wraplength=wrap)
        self.detail_label.configure(wraplength=wrap)


class ActivityFeed(ttk.Frame):
    def __init__(self, master: tk.Misc) -> None:
        super().__init__(master, style="Card.TFrame", padding=14)
        ttk.Label(self, text="Actividad reciente", style="Section.TLabel").pack(anchor="w")
        self.text = tk.Text(
            self,
            height=6,
            background=CANVAS_BG,
            foreground=TEXT_MAIN,
            insertbackground=TEXT_MAIN,
            relief="flat",
            wrap="word",
            padx=10,
            pady=10,
        )
        self.text.pack(fill="both", expand=True)
        self.text.configure(state="disabled")

    def push(self, message: str) -> None:
        self.text.configure(state="normal")
        self.text.insert("end", message.strip() + "\n")
        self.text.see("end")
        self.text.configure(state="disabled")


class PlotPopoutWindow(tk.Toplevel):
    def __init__(self, master: tk.Misc, on_close: callable) -> None:
        super().__init__(master)
        self.on_close = on_close
        self.title("Vista ampliada de graficas")
        self.geometry("1460x940")
        self.minsize(1100, 760)
        self.configure(bg=APP_BG)
        self.protocol("WM_DELETE_WINDOW", self._close)
        self.after(40, self._maximize)

        wrapper = ttk.Frame(self, style="Card.TFrame", padding=18)
        wrapper.pack(fill="both", expand=True, padx=18, pady=18)
        wrapper.columnconfigure((0, 1), weight=1)
        wrapper.rowconfigure(0, weight=2)
        wrapper.rowconfigure(1, weight=1)

        self.g_plot = LinePlot(
            wrapper,
            title="Comparacion en tiempo real",
            subtitle="Vista ampliada de la norma |g| para comparar ambos sensores.",
            y_label="|g|",
            reference_lines=[1.0],
            height=470,
        )
        self.g_plot.grid(row=0, column=0, columnspan=2, sticky="nsew", pady=(0, 14))

        self.axis_plot = LinePlot(
            wrapper,
            title="Movimiento del sensor seleccionado",
            subtitle="Vista amplia de los ejes X, Y y Z.",
            y_label="mV",
            height=340,
        )
        self.axis_plot.grid(row=1, column=0, sticky="nsew", padx=(0, 7))

        self.compare_plot = LinePlot(
            wrapper,
            title="Comparativa de actividad",
            subtitle="Comparacion del eje Z para detectar diferencias rapidas.",
            y_label="mV",
            height=340,
        )
        self.compare_plot.grid(row=1, column=1, sticky="nsew", padx=(7, 0))

    def _close(self) -> None:
        self.on_close()
        self.destroy()

    def _maximize(self) -> None:
        try:
            self.state("zoomed")
            return
        except tk.TclError:
            pass
        try:
            self.attributes("-zoomed", True)
            return
        except tk.TclError:
            pass
        self.geometry(f"{self.winfo_screenwidth()}x{self.winfo_screenheight()}+0+0")


class App(tk.Tk):
    def __init__(self, args: argparse.Namespace) -> None:
        super().__init__()
        self.title("ADXL335 Live")
        self.geometry("1640x980")
        self.minsize(1280, 820)
        self.configure(bg=APP_BG)

        self.args = args
        self.repo_root = Path(args.repo_root).resolve()
        self.manual_port_override = args.port.strip()
        self.event_queue: queue.Queue[tuple[str, dict[str, object]]] = queue.Queue()
        self.worker: LiveCaptureWorker | None = None
        self.popout_window: PlotPopoutWindow | None = None
        self.session_running = False
        self.current_phase = "idle"
        self.current_port_resolution: PortResolution | None = None
        self.last_saved_summary = "Aun no se ha guardado una sesion."

        self.sensor_series = {
            1: {"g": deque(maxlen=2400), "x": deque(maxlen=2400), "y": deque(maxlen=2400), "z": deque(maxlen=2400)},
            2: {"g": deque(maxlen=2400), "x": deque(maxlen=2400), "y": deque(maxlen=2400), "z": deque(maxlen=2400)},
        }

        self.port_choice_var = tk.StringVar()
        self.duration_var = tk.StringVar()
        self.session_name_var = tk.StringVar()
        self.file_prefix_var = tk.StringVar()
        self.output_dir_var = tk.StringVar()
        self.processed_dir_var = tk.StringVar()
        self.precheck_var = tk.StringVar()
        self.baud_var = tk.StringVar()
        self.plot_window_var = tk.StringVar()
        self.sensor_view_var = tk.StringVar(value=list(SENSOR_VIEW_LABELS.keys())[0])
        self.show_advanced = tk.BooleanVar(value=False)
        self.port_choices: dict[str, str] = {AUTO_PORT_LABEL: ""}

        self._build_style()
        self._build_layout()
        self._set_defaults(args)
        self.protocol("WM_DELETE_WINDOW", self._on_close)
        self.after(40, self._maximize)
        self.refresh_ports()
        self.after(80, self._drain_events)
        self.after(220, self._refresh_plots)
        self.after(280, lambda: self.log("Interfaz lista. Puedes iniciar cuando quieras."))
        if args.autostart:
            self.after(650, self.start_session)

    def _build_style(self) -> None:
        style = ttk.Style(self)
        style.theme_use("clam")
        style.configure(".", background=APP_BG, foreground=TEXT_MAIN)
        style.configure("Card.TFrame", background=PANEL_BG)
        style.configure("Metric.TFrame", background=PANEL_ALT)
        style.configure("Sidebar.TFrame", background=PANEL_BG)
        style.configure("HeroTitle.TLabel", background=APP_BG, foreground=TEXT_MAIN, font=("Segoe UI Semibold", 28))
        style.configure("HeroBody.TLabel", background=APP_BG, foreground=TEXT_MUTED, font=("Segoe UI", 11))
        style.configure("CardTitle.TLabel", background=PANEL_BG, foreground=TEXT_MAIN, font=("Segoe UI Semibold", 16))
        style.configure("Section.TLabel", background=PANEL_BG, foreground=TEXT_MAIN, font=("Segoe UI Semibold", 12))
        style.configure("BodyMuted.TLabel", background=PANEL_BG, foreground=TEXT_MUTED, font=("Segoe UI", 10))
        style.configure("TileTitle.TLabel", background=PANEL_ALT, foreground=TEXT_MUTED, font=("Segoe UI", 10))
        style.configure("TileValue.TLabel", background=PANEL_ALT, foreground=TEXT_MAIN, font=("Segoe UI Semibold", 16))
        style.configure("TileDetail.TLabel", background=PANEL_ALT, foreground=TEXT_MUTED, font=("Segoe UI", 10))
        style.configure("Primary.TButton", background=ACCENT, foreground="#11212b", padding=(14, 10), font=("Segoe UI Semibold", 10))
        style.map("Primary.TButton", background=[("active", "#f7b36d")])
        style.configure("Secondary.TButton", background="#17394a", foreground=TEXT_MAIN, padding=(10, 8), font=("Segoe UI", 10))
        style.map("Secondary.TButton", background=[("active", "#23536c")])
        style.configure("Quiet.TButton", background=PANEL_BG, foreground=TEXT_MUTED, padding=(10, 7), font=("Segoe UI", 9))
        style.map("Quiet.TButton", background=[("active", PANEL_ALT)])
        style.configure("Field.TEntry", fieldbackground=PANEL_ALT, foreground=TEXT_MAIN, bordercolor=PANEL_ALT)
        style.configure("Field.TCombobox", fieldbackground=PANEL_ALT, foreground=TEXT_MAIN, bordercolor=PANEL_ALT)
        style.map("Field.TCombobox", fieldbackground=[("readonly", PANEL_ALT)], selectbackground=[("readonly", PANEL_ALT)])

    def _build_layout(self) -> None:
        self.columnconfigure(1, weight=1)
        self.rowconfigure(0, weight=1)

        sidebar = ttk.Frame(self, style="Sidebar.TFrame", padding=18, width=400)
        sidebar.grid(row=0, column=0, sticky="nsw", padx=(18, 12), pady=18)
        sidebar.grid_propagate(False)
        sidebar.columnconfigure(0, weight=1)

        main = ttk.Frame(self, style="Card.TFrame", padding=0)
        main.grid(row=0, column=1, sticky="nsew", padx=(0, 18), pady=18)
        main.columnconfigure(0, weight=1)
        main.rowconfigure(2, weight=1)

        ttk.Label(sidebar, text="ADXL335 Live", style="HeroTitle.TLabel").grid(row=0, column=0, sticky="w", pady=(0, 16))

        setup_card = ttk.Frame(sidebar, style="Card.TFrame", padding=16)
        setup_card.grid(row=1, column=0, sticky="ew")
        setup_card.columnconfigure(0, weight=1)
        ttk.Label(setup_card, text="Sesion", style="CardTitle.TLabel").grid(row=0, column=0, sticky="w")

        self.port_combo = self._add_labeled_combobox(
            setup_card,
            row=1,
            label="Equipo",
            variable=self.port_choice_var,
            values=[AUTO_PORT_LABEL],
            width=34,
        )
        self._add_labeled_combobox(
            setup_card,
            row=2,
            label="Duracion",
            variable=self.duration_var,
            values=["10", "20", "30", "60", "90"],
            suffix="segundos",
            width=14,
        )
        self._add_labeled_entry(
            setup_card,
            row=3,
            label="Nombre",
            variable=self.session_name_var,
        )

        action_row = ttk.Frame(setup_card, style="Card.TFrame")
        action_row.grid(row=8, column=0, sticky="ew", pady=(16, 0))
        action_row.columnconfigure(0, weight=1)
        action_row.columnconfigure(1, weight=1)
        self.start_button = ttk.Button(action_row, text="Iniciar", style="Primary.TButton", command=self.start_session)
        self.stop_button = ttk.Button(action_row, text="Detener", style="Secondary.TButton", command=self.stop_session)
        self.start_button.grid(row=0, column=0, sticky="ew", padx=(0, 6))
        self.stop_button.grid(row=0, column=1, sticky="ew", padx=(6, 0))

        tools_row = ttk.Frame(setup_card, style="Card.TFrame")
        tools_row.grid(row=9, column=0, sticky="ew", pady=(10, 0))
        tools_row.columnconfigure((0, 1), weight=1)
        ttk.Button(tools_row, text="Actualizar", style="Secondary.TButton", command=self.refresh_ports).grid(row=0, column=0, sticky="ew", padx=(0, 6))
        self.advanced_button = ttk.Button(tools_row, text="Opciones", style="Quiet.TButton", command=self._toggle_advanced)
        self.advanced_button.grid(row=0, column=1, sticky="ew", padx=(6, 0))

        self.advanced_frame = ttk.Frame(setup_card, style="Card.TFrame", padding=(0, 12, 0, 0))
        self._add_labeled_entry(self.advanced_frame, row=0, label="Prefijo interno", variable=self.file_prefix_var)
        self._add_labeled_entry(self.advanced_frame, row=1, label="Carpeta raw", variable=self.output_dir_var)
        self._add_labeled_entry(self.advanced_frame, row=2, label="Carpeta processed", variable=self.processed_dir_var)
        self._add_labeled_entry(self.advanced_frame, row=3, label="Chequeo previo [s]", variable=self.precheck_var)
        self._add_labeled_entry(self.advanced_frame, row=4, label="Ventana de grafica [s]", variable=self.plot_window_var)
        self._add_labeled_entry(self.advanced_frame, row=5, label="Baud", variable=self.baud_var)

        status_card = ttk.Frame(sidebar, style="Card.TFrame", padding=16)
        status_card.grid(row=2, column=0, sticky="ew", pady=(16, 0))
        status_card.columnconfigure((0, 1), weight=1, uniform="status")
        ttk.Label(status_card, text="Resumen", style="CardTitle.TLabel").grid(row=0, column=0, columnspan=2, sticky="w")
        self.general_tile = MetricTile(status_card, title="Estado")
        self.connection_tile = MetricTile(status_card, title="Conexion")
        self.primary_tile = MetricTile(status_card, title=PRIMARY_SENSOR_SHORT)
        self.secondary_tile = MetricTile(status_card, title=SECONDARY_SENSOR_SHORT)
        self.general_tile.grid(row=1, column=0, sticky="ew", padx=(0, 6), pady=(12, 0))
        self.connection_tile.grid(row=1, column=1, sticky="ew", padx=(6, 0), pady=(12, 0))
        self.primary_tile.grid(row=2, column=0, sticky="ew", padx=(0, 6), pady=(12, 0))
        self.secondary_tile.grid(row=2, column=1, sticky="ew", padx=(6, 0), pady=(12, 0))

        self.activity_feed = ActivityFeed(sidebar)
        self.activity_feed.grid(row=3, column=0, sticky="nsew", pady=(16, 0))
        sidebar.rowconfigure(3, weight=1)

        header = ttk.Frame(main, style="Card.TFrame", padding=14)
        header.grid(row=0, column=0, sticky="ew")
        header.columnconfigure(0, weight=1)
        ttk.Label(header, text="Monitoreo", style="HeroTitle.TLabel").grid(row=0, column=0, sticky="w")
        self.popout_button = ttk.Button(header, text="Vista ampliada", style="Secondary.TButton", command=self._toggle_popout)
        self.popout_button.grid(row=0, column=1, sticky="e")

        quick_strip = ttk.Frame(main, style="Card.TFrame", padding=(14, 0, 14, 10))
        quick_strip.grid(row=1, column=0, sticky="ew")
        quick_strip.columnconfigure((0, 1, 2, 3), weight=1)
        self.monitor_tile = MetricTile(quick_strip, title="Monitoreo")
        self.time_tile = MetricTile(quick_strip, title="Tiempo")
        self.samples_tile = MetricTile(quick_strip, title="Muestras")
        self.save_tile = MetricTile(quick_strip, title="Salida")
        self.monitor_tile.grid(row=0, column=0, sticky="ew", padx=(0, 8))
        self.time_tile.grid(row=0, column=1, sticky="ew", padx=4)
        self.samples_tile.grid(row=0, column=2, sticky="ew", padx=4)
        self.save_tile.grid(row=0, column=3, sticky="ew", padx=(8, 0))

        charts = ttk.Frame(main, style="Card.TFrame", padding=14)
        charts.grid(row=2, column=0, sticky="nsew")
        charts.columnconfigure((0, 1), weight=1)
        charts.rowconfigure(0, weight=2)
        charts.rowconfigure(1, weight=1)

        self.g_plot = LinePlot(
            charts,
            title="Comparacion principal",
            subtitle="|g| en vivo.",
            y_label="|g|",
            reference_lines=[1.0],
            height=320,
        )
        self.g_plot.grid(row=0, column=0, columnspan=2, sticky="nsew", pady=(0, 14))

        left_detail = ttk.Frame(charts, style="Card.TFrame")
        left_detail.grid(row=1, column=0, sticky="nsew", padx=(0, 7))
        left_detail.columnconfigure(0, weight=1)
        selector_row = ttk.Frame(left_detail, style="Card.TFrame", padding=(0, 0, 0, 8))
        selector_row.grid(row=0, column=0, sticky="ew")
        selector_row.columnconfigure(1, weight=1)
        ttk.Label(selector_row, text="Detalle", style="Section.TLabel").grid(row=0, column=0, sticky="w")
        self.sensor_view_combo = ttk.Combobox(
            selector_row,
            textvariable=self.sensor_view_var,
            values=list(SENSOR_VIEW_LABELS.keys()),
            style="Field.TCombobox",
            state="readonly",
            width=18,
        )
        self.sensor_view_combo.grid(row=0, column=2, sticky="e")
        self.axis_plot = LinePlot(
            left_detail,
            title="Movimiento del sensor seleccionado",
            subtitle="Ejes X, Y y Z.",
            y_label="mV",
            height=220,
        )
        self.axis_plot.grid(row=1, column=0, sticky="nsew")

        self.compare_plot = LinePlot(
            charts,
            title="Comparativa de actividad",
            subtitle="Eje Z.",
            y_label="mV",
            height=220,
        )
        self.compare_plot.grid(row=1, column=1, sticky="nsew", padx=(7, 0))

    def _maximize(self) -> None:
        try:
            self.state("zoomed")
            return
        except tk.TclError:
            pass
        try:
            self.attributes("-zoomed", True)
            return
        except tk.TclError:
            pass
        self.geometry(f"{self.winfo_screenwidth()}x{self.winfo_screenheight()}+0+0")

    def _add_labeled_entry(self, master: tk.Misc, *, row: int, label: str, variable: tk.StringVar) -> ttk.Entry:
        ttk.Label(master, text=label, style="BodyMuted.TLabel").grid(row=row * 2, column=0, sticky="w", pady=(0 if row == 0 else 10, 4))
        entry = ttk.Entry(master, textvariable=variable, style="Field.TEntry")
        entry.grid(row=row * 2 + 1, column=0, sticky="ew")
        if isinstance(master, ttk.Frame):
            master.columnconfigure(0, weight=1)
        return entry

    def _add_labeled_combobox(
        self,
        master: tk.Misc,
        *,
        row: int,
        label: str,
        variable: tk.StringVar,
        values: list[str],
        width: int = 20,
        suffix: str = "",
    ) -> ttk.Combobox:
        ttk.Label(master, text=label, style="BodyMuted.TLabel").grid(row=row * 2, column=0, sticky="w", pady=(0 if row == 0 else 10, 4))
        box = ttk.Combobox(master, textvariable=variable, values=values, style="Field.TCombobox", state="readonly", width=width)
        box.grid(row=row * 2 + 1, column=0, sticky="ew")
        if suffix:
            ttk.Label(master, text=suffix, style="BodyMuted.TLabel").grid(row=row * 2 + 1, column=1, sticky="w", padx=(8, 0))
        if isinstance(master, ttk.Frame):
            master.columnconfigure(0, weight=1)
        return box

    def _set_defaults(self, args: argparse.Namespace) -> None:
        self.port_choice_var.set(AUTO_PORT_LABEL)
        self.duration_var.set(str(int(args.duration_s)) if float(args.duration_s).is_integer() else str(args.duration_s))
        self.session_name_var.set(args.session_name or "sesion_live")
        self.file_prefix_var.set(args.file_prefix or "sensor_B_live")
        self.output_dir_var.set(args.output_dir_relpath)
        self.processed_dir_var.set(args.processed_dir_relpath)
        self.precheck_var.set(str(args.precheck_duration_s))
        self.plot_window_var.set(str(args.plot_window_s))
        self.baud_var.set(str(args.baud))

        self.general_tile.update("En espera", "Todo listo para empezar.", tone="idle")
        self.connection_tile.update("Automatica", "Seleccion automatica.", tone="idle")
        self.primary_tile.update("--", "Aun sin evaluar.", tone="idle")
        self.secondary_tile.update("--", "Aun sin evaluar.", tone="idle")
        self.monitor_tile.update("Listo", "Esperando inicio.", tone="idle")
        self.time_tile.update("0 s", "Sin captura activa.", tone="idle")
        self.samples_tile.update("0", "No hay muestras todavia.", tone="idle")
        self.save_tile.update("Pendiente", "Se guardara al terminar.", tone="idle")

    def log(self, message: str) -> None:
        self.activity_feed.push(message)

    def refresh_ports(self) -> None:
        inventory = list_serial_inventory()
        self.port_choices = {AUTO_PORT_LABEL: ""}
        for entry in inventory:
            label = compact_port_label(entry.device, entry.description)
            self.port_choices[label] = entry.device

        if self.manual_port_override:
            manual_label = f"Manual: {self.manual_port_override}"
            if self.manual_port_override not in self.port_choices.values():
                self.port_choices[manual_label] = self.manual_port_override

        values = list(self.port_choices.keys())
        current_port = self.manual_port_override or self._selected_port()
        selected_label = AUTO_PORT_LABEL
        for label, port in self.port_choices.items():
            if port and port == current_port:
                selected_label = label
                break
        if self.port_choice_var.get() in self.port_choices:
            selected_label = self.port_choice_var.get()
        self.port_choice_var.set(selected_label if selected_label in self.port_choices else AUTO_PORT_LABEL)
        self.port_combo.configure(values=values)

        if inventory:
            self.log("Lista de dispositivos actualizada.")
        else:
            self.log("No se detectaron dispositivos disponibles en este momento.")

    def _selected_port(self) -> str:
        label = self.port_choice_var.get().strip()
        return self.port_choices.get(label, "")

    def _toggle_advanced(self) -> None:
        self.show_advanced.set(not self.show_advanced.get())
        if self.show_advanced.get():
            self.advanced_frame.grid(row=10, column=0, sticky="ew")
            self.advanced_button.configure(text="Ocultar")
        else:
            self.advanced_frame.grid_forget()
            self.advanced_button.configure(text="Opciones")

    def _toggle_popout(self) -> None:
        if self.popout_window and self.popout_window.winfo_exists():
            self.popout_window.focus_force()
            return
        self.popout_window = PlotPopoutWindow(self, self._on_popout_closed)
        self.popout_button.configure(text="Traer al frente")

    def _on_popout_closed(self) -> None:
        self.popout_window = None
        self.popout_button.configure(text="Vista ampliada")

    def _compute_g_bounds(
        self,
        series: dict[str, dict[str, object]],
    ) -> tuple[float, float] | None:
        values: list[float] = [1.0]
        for config in series.values():
            for _x_value, y_value in config.get("points", []):
                values.append(float(y_value))
        if len(values) <= 1:
            return None
        y_min = min(values)
        y_max = max(values)
        if math.isclose(y_min, y_max, rel_tol=0.0, abs_tol=1e-9):
            y_min -= 0.05
            y_max += 0.05
        padding = max((y_max - y_min) * 0.22, 0.04)
        return max(0.0, y_min - padding), y_max + padding

    def _build_config(self) -> LiveSessionConfig:
        return LiveSessionConfig(
            repo_root=self.repo_root,
            port=self._selected_port(),
            baud=int(float(self.baud_var.get().strip() or "115200")),
            duration_s=float(self.duration_var.get().strip() or "20"),
            session_name=self.session_name_var.get().strip() or "sesion_live",
            file_prefix=self.file_prefix_var.get().strip() or "sensor_B_live",
            output_dir_relpath=self.output_dir_var.get().strip() or "data/raw/sensor_B_live",
            processed_dir_relpath=self.processed_dir_var.get().strip() or "data/processed",
            dual_precheck_enabled=float(self.precheck_var.get().strip() or "0") > 0,
            dual_precheck_duration_s=float(self.precheck_var.get().strip() or "10"),
        )

    def _reset_series(self) -> None:
        for sensor_data in self.sensor_series.values():
            for series in sensor_data.values():
                series.clear()

    def start_session(self) -> None:
        if self.session_running:
            self.log("Ya hay una captura en curso.")
            return

        try:
            config = self._build_config()
        except ValueError as exc:
            self.log(f"Revisa los campos antes de iniciar: {exc}")
            return

        self._reset_series()
        self.current_port_resolution = None
        self.session_running = True
        self.current_phase = "boot"
        self.start_button.state(["disabled"])
        self.last_saved_summary = "La sesion sigue en curso."

        self.general_tile.update("Preparando", "Buscando el puerto y alistando la captura.", tone="boot")
        self.monitor_tile.update("Preparando", "Organizando la sesion.", tone="boot")
        self.time_tile.update("0 s", f"Duracion objetivo: {config.duration_s:.0f} s.", tone="boot")
        self.samples_tile.update("0", "Muestras reiniciadas.", tone="boot")
        self.save_tile.update("Pendiente", "Se guardara al finalizar.", tone="boot")

        self.worker = LiveCaptureWorker(config, self._push_event)
        self.worker.start()
        self.log(f"Iniciando una sesion de {config.duration_s:.0f} s.")

    def stop_session(self) -> None:
        if not self.worker:
            return
        self.worker.stop()
        self.general_tile.update("Deteniendo", "Se solicito detener la captura.", tone="warning")
        self.log("Solicitud de parada enviada.")

    def _push_event(self, event_type: str, payload: dict[str, object]) -> None:
        self.event_queue.put((event_type, payload))

    def _drain_events(self) -> None:
        while True:
            try:
                event_type, payload = self.event_queue.get_nowait()
            except queue.Empty:
                break
            self._handle_event(event_type, payload)
        self.after(80, self._drain_events)

    def _handle_event(self, event_type: str, payload: dict[str, object]) -> None:
        if event_type == "log":
            self.log(str(payload["message"]))
            return

        if event_type == "port_resolved":
            resolution = payload["port_resolution"]
            assert isinstance(resolution, PortResolution)
            self.current_port_resolution = resolution
            self.connection_tile.update("Conectado", "Listo para usar.", tone="success")
            self.monitor_tile.update("Conectado", "Sesion preparada.", tone="success")
            self.log("Dispositivo conectado correctamente.")
            return

        if event_type == "phase_changed":
            phase = str(payload["phase"])
            self.current_phase = phase
            if phase == "capture":
                self._reset_series()
            label, _ = status_to_badge(phase)
            detail = "Revisando montaje." if phase == "precheck" else "Grabando en tiempo real."
            self.general_tile.update(label, detail, tone=phase)
            self.monitor_tile.update(label, detail, tone=phase)
            self.log("Chequeo previo en curso." if phase == "precheck" else "Captura principal en curso.")
            return

        if event_type == "sample":
            sample = payload["sample"]
            assert isinstance(sample, Sample)
            bucket = self.sensor_series.setdefault(
                sample.sensor_id,
                {"g": deque(maxlen=2400), "x": deque(maxlen=2400), "y": deque(maxlen=2400), "z": deque(maxlen=2400)},
            )
            bucket["g"].append((sample.wall_s, sample.g_norm_est))
            bucket["x"].append((sample.wall_s, sample.mv_x))
            bucket["y"].append((sample.wall_s, sample.mv_y))
            bucket["z"].append((sample.wall_s, sample.mv_z))
            return

        if event_type in {"precheck_progress", "capture_progress"}:
            counts = payload["sensor_counts"]
            elapsed = float(payload["elapsed_s"])
            remaining = float(payload["remaining_s"])
            total_samples = int(payload["samples"])
            self.time_tile.update(
                f"{elapsed:.1f} s",
                f"Restan {remaining:.1f} s." if event_type == "capture_progress" else "Chequeo previo en curso.",
                tone="capture" if event_type == "capture_progress" else "precheck",
            )
            self.samples_tile.update(
                str(total_samples),
                f"{PRIMARY_SENSOR_SHORT}: {int(counts.get(1, 0))} | {SECONDARY_SENSOR_SHORT}: {int(counts.get(2, 0))}",
                tone="capture" if event_type == "capture_progress" else "precheck",
            )
            if event_type == "capture_progress":
                hz = float(payload["est_hz_total"])
                self.monitor_tile.update("Grabando", f"Frecuencia estimada: {hz:.1f} Hz.", tone="capture")
            return

        if event_type == "precheck_complete":
            result = payload["result"]
            label, _ = status_to_badge(result.logic_status)
            tone_name = "success" if result.logic_status == "pass" else "warning"
            self.general_tile.update(label, friendly_reason(result.logic_reason), tone=tone_name)
            self.log(f"Chequeo previo: {friendly_reason(result.logic_reason)}")
            for check in result.sensor_checks:
                label, _ = status_to_badge(check.logic_status)
                detail = friendly_reason(check.logic_reason)
                if check.sensor_id == 1:
                    self.primary_tile.update(label, detail, tone=check.logic_status)
                elif check.sensor_id == 2:
                    self.secondary_tile.update(label, detail, tone=check.logic_status)
            return

        if event_type == "session_complete":
            result = payload["result"]
            assert isinstance(result, SessionResult)
            self.session_running = False
            self.worker = None
            self.start_button.state(["!disabled"])

            self.general_tile.update("Completada", "La sesion termino correctamente.", tone="completed")
            self.monitor_tile.update("Completada", "Puedes revisar la salida guardada.", tone="completed")
            self.time_tile.update(f"{result.stream_duration_s:.1f} s", "Duracion real de la sesion.", tone="completed")
            self.samples_tile.update(str(len(result.samples)), f"Frecuencia total: {result.freq_hz:.1f} Hz.", tone="completed")

            raw_rel = make_relpath(result.artifacts.raw_csv_abs, self.repo_root)
            processed_rel = make_relpath(result.artifacts.processed_csv_abs, self.repo_root)
            summary_rel = make_relpath(result.artifacts.summary_txt_abs, self.repo_root)
            self.last_saved_summary = processed_rel
            self.save_tile.update("Guardado", "Resultados y resumen disponibles.", tone="completed")

            for summary in result.sensor_summaries:
                detail = f"{summary.samples} muestras | {summary.freq_hz:.1f} Hz"
                if summary.sensor_id == 1:
                    self.primary_tile.update(status_to_badge(summary.logic_status)[0], detail, tone=summary.logic_status)
                elif summary.sensor_id == 2:
                    self.secondary_tile.update(status_to_badge(summary.logic_status)[0], detail, tone=summary.logic_status)

            self.log(f"Sesion guardada: {raw_rel}")
            self.log(f"Resultados listos en: {processed_rel}")
            self.log(f"Resumen disponible en: {summary_rel}")
            return

        if event_type == "session_cancelled":
            self.session_running = False
            self.worker = None
            self.start_button.state(["!disabled"])
            self.general_tile.update("Cancelada", "La sesion se detuvo antes de finalizar.", tone="cancelled")
            self.monitor_tile.update("Cancelada", "Puedes iniciar otra cuando quieras.", tone="cancelled")
            self.log("La sesion fue cancelada por el usuario.")
            return

        if event_type == "session_error":
            self.session_running = False
            self.worker = None
            self.start_button.state(["!disabled"])
            message = str(payload["message"])
            short_message = summarize_error_message(message)
            self.general_tile.update("Error", short_message, tone="error")
            self.monitor_tile.update("Error", "Sesion detenida.", tone="error")
            self.save_tile.update("Sin salida", "No se completo el guardado final.", tone="error")
            self.log(f"Error durante la captura: {short_message}")
            if short_message != message:
                self.log(message)
            return

    def _refresh_plots(self) -> None:
        window_s = max(float(self.plot_window_var.get() or "30"), 5.0)

        g_series = {
            PRIMARY_SENSOR_SHORT: {"color": ACCENT, "points": self._trim_points(self.sensor_series[1]["g"], window_s)},
            SECONDARY_SENSOR_SHORT: {"color": ACCENT_ALT, "points": self._trim_points(self.sensor_series[2]["g"], window_s)},
        }
        g_bounds = self._compute_g_bounds(g_series)
        self.g_plot.set_series(
            g_series,
            subtitle="Comparacion en vivo.",
            y_bounds=g_bounds,
        )

        selected_sensor_id = SENSOR_VIEW_LABELS.get(self.sensor_view_var.get(), 1)
        axis_bucket = self.sensor_series.get(selected_sensor_id, self.sensor_series[1])
        sensor_name = PRIMARY_SENSOR_FULL if selected_sensor_id == 1 else SECONDARY_SENSOR_FULL
        axis_series = {
            "Eje X": {"color": AXIS_COLORS["x"], "points": self._trim_points(axis_bucket["x"], window_s)},
            "Eje Y": {"color": AXIS_COLORS["y"], "points": self._trim_points(axis_bucket["y"], window_s)},
            "Eje Z": {"color": AXIS_COLORS["z"], "points": self._trim_points(axis_bucket["z"], window_s)},
        }
        self.axis_plot.set_series(
            axis_series,
            subtitle=sensor_name,
        )

        compare_series = {
            f"{PRIMARY_SENSOR_SHORT} Z": {"color": AXIS_COLORS["z"], "points": self._trim_points(self.sensor_series[1]["z"], window_s)},
            f"{SECONDARY_SENSOR_SHORT} Z": {"color": ACCENT_ALT, "points": self._trim_points(self.sensor_series[2]["z"], window_s)},
        }
        self.compare_plot.set_series(
            compare_series,
            subtitle="Actividad relativa.",
        )

        if self.popout_window and self.popout_window.winfo_exists():
            self.popout_window.g_plot.set_series(
                g_series,
                subtitle="Vista ampliada de |g| para ambos sensores.",
                y_bounds=g_bounds,
            )
            self.popout_window.axis_plot.set_series(
                axis_series,
                subtitle=f"Vista ampliada del sensor seleccionado ({sensor_name}).",
            )
            self.popout_window.compare_plot.set_series(
                compare_series,
                subtitle="Vista ampliada de la actividad relativa entre sensores.",
            )
        self.after(220, self._refresh_plots)

    def _trim_points(self, series: deque[tuple[float, float]], window_s: float) -> list[tuple[float, float]]:
        if not series:
            return []
        max_x = series[-1][0]
        min_x = max(0.0, max_x - window_s)
        return [(x_value, y_value) for x_value, y_value in series if x_value >= min_x]

    def _on_close(self) -> None:
        if self.worker:
            self.worker.stop()
        self.destroy()


def _resolve_repo_root() -> Path:
    """Devuelve la raiz de datos correcta tanto en desarrollo como en el .exe empaquetado.

    PyInstaller establece sys.frozen=True y sys.executable apunta al .exe.
    En ese caso, los datos se guardan junto al ejecutable.
    En desarrollo, se sube un nivel desde gui/ para llegar a la raiz del repo.
    """
    if getattr(sys, "frozen", False):
        return Path(sys.executable).resolve().parent
    return Path(__file__).resolve().parents[1]


def parse_args() -> argparse.Namespace:
    repo_root = _resolve_repo_root()
    parser = argparse.ArgumentParser(description="GUI live para ADXL335 + ESP32")
    parser.add_argument("--repo-root", default=str(repo_root))
    parser.add_argument("--port", default="")
    parser.add_argument("--baud", type=int, default=115200)
    parser.add_argument("--duration-s", type=float, default=20.0)
    parser.add_argument("--session-name", default="live")
    parser.add_argument("--file-prefix", default="sensor_B_live")
    parser.add_argument("--output-dir-relpath", default="data/raw/sensor_B_live")
    parser.add_argument("--processed-dir-relpath", default="data/processed")
    parser.add_argument("--precheck-duration-s", type=float, default=10.0)
    parser.add_argument("--plot-window-s", type=float, default=30.0)
    parser.add_argument("--autostart", action="store_true")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    app = App(args)
    app.mainloop()


if __name__ == "__main__":
    main()

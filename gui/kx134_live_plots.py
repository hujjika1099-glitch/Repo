from __future__ import annotations

import math
from collections import deque
from dataclasses import dataclass
from typing import Iterable

import tkinter as tk
from tkinter import ttk

try:
    from .kx134_live_core import Kx134Sample
    from .ui_components import safe_set_grid_weights
except ImportError:  # pragma: no cover - direct script execution support
    from kx134_live_core import Kx134Sample
    from ui_components import safe_set_grid_weights


@dataclass(frozen=True)
class Kx134LiveSamplePoint:
    sensor_id: int
    t_s: float
    x_g: float
    y_g: float
    z_g: float
    g_abs: float
    seq: int


class Kx134LivePlotBuffer:
    def __init__(self, window_s: float = 30.0, max_points_per_sensor: int = 6000) -> None:
        self.window_s = float(window_s)
        self.max_points_per_sensor = int(max_points_per_sensor)
        self._buffers: dict[int, deque[Kx134LiveSamplePoint]] = {
            1: deque(maxlen=self.max_points_per_sensor),
            2: deque(maxlen=self.max_points_per_sensor),
        }

    def clear(self) -> None:
        for buffer in self._buffers.values():
            buffer.clear()

    def set_window_s(self, window_s: float) -> None:
        value = float(window_s)
        if value <= 0:
            raise ValueError("window_s must be positive")
        self.window_s = value
        self._trim_to_window()

    def add_sample(self, sample: Kx134Sample | Kx134LiveSamplePoint) -> Kx134LiveSamplePoint:
        point = sample if isinstance(sample, Kx134LiveSamplePoint) else self._point_from_sample(sample)
        if point.sensor_id not in self._buffers:
            return point
        self._buffers[point.sensor_id].append(point)
        self._trim_to_window()
        return point

    def add_samples(self, samples: Iterable[Kx134Sample | Kx134LiveSamplePoint]) -> list[Kx134LiveSamplePoint]:
        return [self.add_sample(sample) for sample in samples]

    def counts(self) -> dict[int, int]:
        return {sensor_id: len(buffer) for sensor_id, buffer in self._buffers.items()}

    def series(self, sensor_id: int, axis: str) -> list[tuple[float, float]]:
        if axis not in {"x_g", "y_g", "z_g", "g_abs"}:
            raise ValueError(f"unsupported plot axis: {axis}")
        return [(point.t_s, float(getattr(point, axis))) for point in self._visible_points(sensor_id)]

    def latest_time_s(self) -> float | None:
        latest: float | None = None
        for buffer in self._buffers.values():
            if buffer:
                latest = buffer[-1].t_s if latest is None else max(latest, buffer[-1].t_s)
        return latest

    def _visible_points(self, sensor_id: int) -> list[Kx134LiveSamplePoint]:
        latest = self.latest_time_s()
        if latest is None:
            return []
        cutoff = latest - self.window_s
        return [point for point in self._buffers.get(sensor_id, ()) if point.t_s >= cutoff]

    def _trim_to_window(self) -> None:
        latest = self.latest_time_s()
        if latest is None:
            return
        cutoff = latest - self.window_s
        for buffer in self._buffers.values():
            while buffer and buffer[0].t_s < cutoff:
                buffer.popleft()

    @staticmethod
    def _point_from_sample(sample: Kx134Sample) -> Kx134LiveSamplePoint:
        g_abs = math.sqrt(sample.x_g * sample.x_g + sample.y_g * sample.y_g + sample.z_g * sample.z_g)
        return Kx134LiveSamplePoint(
            sensor_id=sample.sensor_id,
            t_s=float(sample.pc_wall_s),
            x_g=float(sample.x_g),
            y_g=float(sample.y_g),
            z_g=float(sample.z_g),
            g_abs=g_abs,
            seq=int(sample.seq),
        )


class Kx134CanvasPlot(ttk.Frame):
    COLORS = ("#43b5ff", "#ffbd59", "#7bd88f", "#ff6b6b")

    def __init__(self, master: tk.Misc, title: str) -> None:
        super().__init__(master, style="Surface.TFrame")
        self.title = title
        self._series: list[tuple[str, list[tuple[float, float]], str]] = []
        self._reference_lines: list[tuple[float, str]] = [(0.0, "0 g")]
        self.columnconfigure(0, weight=1)
        self.rowconfigure(1, weight=1)
        ttk.Label(self, text=title, style="Body.TLabel").grid(row=0, column=0, sticky="w")
        self.canvas = tk.Canvas(self, height=160, bg="#06161b", highlightthickness=1, highlightbackground="#21434d")
        self.canvas.grid(row=1, column=0, sticky="nsew", pady=(6, 0))
        self.canvas.bind("<Configure>", lambda _event: self.redraw())

    def set_series(
        self,
        series: list[tuple[str, list[tuple[float, float]]]],
        reference_lines: list[tuple[float, str]] | None = None,
    ) -> None:
        self._series = [
            (label, self._downsample(points), self.COLORS[index % len(self.COLORS)])
            for index, (label, points) in enumerate(series)
        ]
        if reference_lines is not None:
            self._reference_lines = reference_lines
        self.redraw()

    def redraw(self) -> None:
        canvas = self.canvas
        canvas.delete("all")
        width = max(canvas.winfo_width(), 320)
        height = max(canvas.winfo_height(), 120)
        pad_l, pad_r, pad_t, pad_b = 44, 16, 18, 26
        plot_w = max(width - pad_l - pad_r, 1)
        plot_h = max(height - pad_t - pad_b, 1)

        all_points = [point for _label, points, _color in self._series for point in points]
        if not all_points:
            canvas.create_text(width / 2, height / 2, text="Sin datos en vivo", fill="#d7edf1")
            return

        min_t = min(point[0] for point in all_points)
        max_t = max(point[0] for point in all_points)
        if math.isclose(min_t, max_t):
            max_t = min_t + 1.0
        min_y = min([point[1] for point in all_points] + [line[0] for line in self._reference_lines])
        max_y = max([point[1] for point in all_points] + [line[0] for line in self._reference_lines])
        if math.isclose(min_y, max_y):
            min_y -= 1.0
            max_y += 1.0
        margin = max((max_y - min_y) * 0.12, 0.05)
        min_y -= margin
        max_y += margin

        def x_to_px(value: float) -> float:
            return pad_l + ((value - min_t) / (max_t - min_t)) * plot_w

        def y_to_px(value: float) -> float:
            return pad_t + (1.0 - ((value - min_y) / (max_y - min_y))) * plot_h

        for index in range(5):
            y = pad_t + plot_h * index / 4
            canvas.create_line(pad_l, y, width - pad_r, y, fill="#14313a")
        for index in range(5):
            x = pad_l + plot_w * index / 4
            canvas.create_line(x, pad_t, x, height - pad_b, fill="#102a32")

        for value, label in self._reference_lines:
            y = y_to_px(value)
            canvas.create_line(pad_l, y, width - pad_r, y, fill="#4c6570", dash=(4, 3))
            canvas.create_text(pad_l - 6, y, text=label, fill="#a8c8d0", anchor="e")

        legend_x = pad_l
        for label, points, color in self._series:
            if len(points) >= 2:
                coords: list[float] = []
                for t_s, value in points:
                    coords.extend((x_to_px(t_s), y_to_px(value)))
                canvas.create_line(*coords, fill=color, width=2, smooth=False)
            elif points:
                canvas.create_oval(
                    x_to_px(points[0][0]) - 2,
                    y_to_px(points[0][1]) - 2,
                    x_to_px(points[0][0]) + 2,
                    y_to_px(points[0][1]) + 2,
                    fill=color,
                    outline=color,
                )
            canvas.create_rectangle(legend_x, height - 16, legend_x + 10, height - 6, fill=color, outline=color)
            canvas.create_text(legend_x + 14, height - 11, text=label, fill="#d7edf1", anchor="w")
            legend_x += max(82, len(label) * 8 + 28)

        canvas.create_text(pad_l, height - 6, text=f"{min_t:.1f}s", fill="#8fb0b8", anchor="sw")
        canvas.create_text(width - pad_r, height - 6, text=f"{max_t:.1f}s", fill="#8fb0b8", anchor="se")
        canvas.create_text(6, pad_t, text=f"{max_y:.2f}g", fill="#8fb0b8", anchor="nw")
        canvas.create_text(6, pad_t + plot_h, text=f"{min_y:.2f}g", fill="#8fb0b8", anchor="sw")

    @staticmethod
    def _downsample(points: list[tuple[float, float]], max_points: int = 650) -> list[tuple[float, float]]:
        if len(points) <= max_points:
            return points
        step = max(1, len(points) // max_points)
        return points[::step]


class Kx134LivePlotsPanel(ttk.Frame):
    def __init__(self, master: tk.Misc) -> None:
        super().__init__(master, style="Surface.TFrame")
        self.buffer = Kx134LivePlotBuffer(window_s=30.0)
        self.window_var = tk.StringVar(value="30")
        self.axis_var = tk.StringVar(value="X")
        self.paused_var = tk.BooleanVar(value=False)
        self.last_update_var = tk.StringVar(value="Sin datos")

        self.columnconfigure(0, weight=1)
        self.rowconfigure(1, weight=1)
        controls = ttk.Frame(self, style="Surface.TFrame")
        controls.grid(row=0, column=0, sticky="ew", pady=(0, 8))
        safe_set_grid_weights(controls, columns=(7,))
        ttk.Label(controls, text="Ventana visible", style="Muted.TLabel").grid(row=0, column=0, sticky="w", padx=(0, 6))
        window_combo = ttk.Combobox(controls, textvariable=self.window_var, values=("10", "20", "30", "60"), state="readonly", width=8)
        window_combo.grid(row=0, column=1, sticky="w", padx=(0, 14))
        window_combo.bind("<<ComboboxSelected>>", lambda _event: self._apply_window())
        ttk.Label(controls, text="Eje comparado", style="Muted.TLabel").grid(row=0, column=2, sticky="w", padx=(0, 6))
        axis_combo = ttk.Combobox(controls, textvariable=self.axis_var, values=("X", "Y", "Z"), state="readonly", width=8)
        axis_combo.grid(row=0, column=3, sticky="w", padx=(0, 14))
        axis_combo.bind("<<ComboboxSelected>>", lambda _event: self.refresh())
        ttk.Checkbutton(controls, text="Pausar vista", variable=self.paused_var).grid(row=0, column=4, sticky="w", padx=(0, 14))
        ttk.Button(controls, text="Limpiar grafica", command=self.clear).grid(row=0, column=5, sticky="w", padx=(0, 14))
        ttk.Label(controls, textvariable=self.last_update_var, style="Muted.TLabel").grid(row=0, column=6, sticky="w")
        ttk.Label(
            controls,
            text="Visualizacion solamente: no altera datos crudos ni exportacion.",
            style="Muted.TLabel",
            wraplength=360,
        ).grid(row=0, column=7, sticky="e")

        plots = ttk.Frame(self, style="Surface.TFrame")
        plots.grid(row=1, column=0, sticky="nsew")
        safe_set_grid_weights(plots, columns=(0, 1), rows=(0, 1))
        self.sensor1_plot = Kx134CanvasPlot(plots, "Sensor 1 - ejes en g")
        self.sensor2_plot = Kx134CanvasPlot(plots, "Sensor 2 - ejes en g")
        self.g_abs_plot = Kx134CanvasPlot(plots, "Comparacion |g| visual")
        self.axis_plot = Kx134CanvasPlot(plots, "Comparacion eje seleccionado")
        self.sensor1_plot.grid(row=0, column=0, sticky="nsew", padx=6, pady=6)
        self.sensor2_plot.grid(row=0, column=1, sticky="nsew", padx=6, pady=6)
        self.g_abs_plot.grid(row=1, column=0, sticky="nsew", padx=6, pady=6)
        self.axis_plot.grid(row=1, column=1, sticky="nsew", padx=6, pady=6)

    def add_samples(self, samples: Iterable[Kx134Sample | Kx134LiveSamplePoint]) -> None:
        added = self.buffer.add_samples(samples)
        if added:
            counts = self.buffer.counts()
            self.last_update_var.set(f"S1 {counts.get(1, 0)} pts | S2 {counts.get(2, 0)} pts")

    def clear(self) -> None:
        self.buffer.clear()
        self.last_update_var.set("Sin datos")
        self.refresh(force=True)

    def refresh(self, *, force: bool = False) -> None:
        if self.paused_var.get() and not force:
            return
        axis = self.axis_var.get().lower() + "_g"
        self.sensor1_plot.set_series(
            [
                ("x_g", self.buffer.series(1, "x_g")),
                ("y_g", self.buffer.series(1, "y_g")),
                ("z_g", self.buffer.series(1, "z_g")),
            ],
            reference_lines=[(0.0, "0 g")],
        )
        self.sensor2_plot.set_series(
            [
                ("x_g", self.buffer.series(2, "x_g")),
                ("y_g", self.buffer.series(2, "y_g")),
                ("z_g", self.buffer.series(2, "z_g")),
            ],
            reference_lines=[(0.0, "0 g")],
        )
        self.g_abs_plot.set_series(
            [
                ("|g| S1", self.buffer.series(1, "g_abs")),
                ("|g| S2", self.buffer.series(2, "g_abs")),
            ],
            reference_lines=[(1.0, "1 g"), (0.0, "0 g")],
        )
        self.axis_plot.title = f"Comparacion eje {self.axis_var.get()}"
        self.axis_plot.set_series(
            [
                (f"{self.axis_var.get()} S1", self.buffer.series(1, axis)),
                (f"{self.axis_var.get()} S2", self.buffer.series(2, axis)),
            ],
            reference_lines=[(0.0, "0 g")],
        )

    def _apply_window(self) -> None:
        self.buffer.set_window_s(float(self.window_var.get()))
        self.refresh(force=True)

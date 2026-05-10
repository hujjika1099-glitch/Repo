from __future__ import annotations

import argparse
import queue
import sys
from pathlib import Path

import tkinter as tk
from tkinter import ttk

try:
    from .kx134_live_core import Kx134CaptureConfig, Kx134CaptureWorker, Kx134SessionResult
    from .kx134_stream_contract import (
        KX134_ALLOWED_SAMPLE_RATES,
        KX134_DEFAULT_BAUD,
        KX134_DEFAULT_SAMPLE_RATE_HZ,
    )
except ImportError:  # pragma: no cover - direct script execution support
    from kx134_live_core import Kx134CaptureConfig, Kx134CaptureWorker, Kx134SessionResult
    from kx134_stream_contract import (
        KX134_ALLOWED_SAMPLE_RATES,
        KX134_DEFAULT_BAUD,
        KX134_DEFAULT_SAMPLE_RATE_HZ,
    )


APP_BG = "#0b1416"
PANEL_BG = "#102126"
TEXT_MAIN = "#edf7f4"
TEXT_MUTED = "#9dbab4"
ACCENT = "#e8b35f"
SUCCESS = "#79d49b"
DANGER = "#ff7a78"


def _resolve_repo_root() -> Path:
    if getattr(sys, "frozen", False):
        return Path(sys.executable).resolve().parent
    return Path(__file__).resolve().parents[1]


def list_ports() -> list[str]:
    try:
        from serial.tools import list_ports as serial_list_ports
    except ModuleNotFoundError:
        return []
    return [port.device for port in serial_list_ports.comports()]


class Kx134CaptureApp(tk.Tk):
    def __init__(self, args: argparse.Namespace) -> None:
        super().__init__()
        self.title("KX134 Dual Capture")
        self.geometry("980x700")
        self.minsize(860, 620)
        self.configure(bg=APP_BG)

        self.repo_root = Path(args.repo_root).resolve()
        self.events: queue.Queue[tuple[str, dict[str, object]]] = queue.Queue()
        self.worker: Kx134CaptureWorker | None = None

        self.port_var = tk.StringVar(value=args.port or "")
        self.baud_var = tk.StringVar(value=str(args.baud))
        self.duration_var = tk.StringVar(value=str(args.duration_s))
        self.sample_rate_var = tk.StringVar(value=str(args.expected_sample_rate))
        self.session_name_var = tk.StringVar(value=args.session_name)
        self.status_var = tk.StringVar(value="En espera")
        self.sensor1_var = tk.StringVar(value="Sensor 1: no presente")
        self.sensor2_var = tk.StringVar(value="Sensor 2: no presente")
        self.invalid_var = tk.StringVar(value="Invalid lines: 0")
        self.duplicates_var = tk.StringVar(value="Duplicate keys: 0")
        self.receiver_var = tk.StringVar(value="receiver_t_us: pendiente")
        self.files_var = tk.StringVar(value="Archivos generados: pendiente")

        self._build_style()
        self._build_layout()
        self.refresh_ports()
        self.after(120, self._drain_events)

    def _build_style(self) -> None:
        style = ttk.Style(self)
        style.theme_use("clam")
        style.configure(".", background=APP_BG, foreground=TEXT_MAIN)
        style.configure("Panel.TFrame", background=PANEL_BG)
        style.configure("Title.TLabel", background=APP_BG, foreground=TEXT_MAIN, font=("Segoe UI Semibold", 22))
        style.configure("Body.TLabel", background=PANEL_BG, foreground=TEXT_MAIN, font=("Segoe UI", 10))
        style.configure("Muted.TLabel", background=PANEL_BG, foreground=TEXT_MUTED, font=("Segoe UI", 9))
        style.configure("Primary.TButton", background=ACCENT, foreground="#101819", padding=(12, 8))
        style.configure("Field.TEntry", fieldbackground="#172d33", foreground=TEXT_MAIN)
        style.configure("Field.TCombobox", fieldbackground="#172d33", foreground=TEXT_MAIN)

    def _build_layout(self) -> None:
        wrapper = ttk.Frame(self, style="Panel.TFrame", padding=18)
        wrapper.pack(fill="both", expand=True, padx=18, pady=18)
        wrapper.columnconfigure(0, weight=1)
        wrapper.columnconfigure(1, weight=1)

        ttk.Label(self, text="KX134 Dual Capture", style="Title.TLabel").place(x=24, y=12)

        fields = ttk.Frame(wrapper, style="Panel.TFrame")
        fields.grid(row=0, column=0, sticky="nsew", padx=(0, 16), pady=(40, 0))
        fields.columnconfigure(0, weight=1)

        self.port_combo = self._field_combo(fields, "Puerto serial", self.port_var, [], row=0)
        self._field_entry(fields, "Baudrate", self.baud_var, row=1)
        self._field_entry(fields, "Duracion de captura (s)", self.duration_var, row=2)
        self._field_combo(
            fields,
            "Frecuencia esperada",
            self.sample_rate_var,
            [str(rate) for rate in KX134_ALLOWED_SAMPLE_RATES],
            row=3,
        )
        self._field_entry(fields, "Nombre de sesion", self.session_name_var, row=4)

        buttons = ttk.Frame(fields, style="Panel.TFrame")
        buttons.grid(row=10, column=0, sticky="ew", pady=(18, 0))
        buttons.columnconfigure((0, 1), weight=1)
        self.start_button = ttk.Button(
            buttons,
            text="Iniciar captura KX134",
            style="Primary.TButton",
            command=self.start_capture,
        )
        self.start_button.grid(row=0, column=0, sticky="ew", padx=(0, 8))
        ttk.Button(buttons, text="Actualizar puertos", command=self.refresh_ports).grid(
            row=0,
            column=1,
            sticky="ew",
        )

        status = ttk.Frame(wrapper, style="Panel.TFrame")
        status.grid(row=0, column=1, sticky="nsew", pady=(40, 0))
        status.columnconfigure(0, weight=1)
        for row, variable in enumerate(
            [
                self.status_var,
                self.sensor1_var,
                self.sensor2_var,
                self.invalid_var,
                self.duplicates_var,
                self.receiver_var,
                self.files_var,
            ]
        ):
            ttk.Label(status, textvariable=variable, style="Body.TLabel", wraplength=420).grid(
                row=row,
                column=0,
                sticky="ew",
                pady=(0 if row == 0 else 12, 0),
            )

        self.log_box = tk.Text(
            wrapper,
            height=12,
            background="#071013",
            foreground=TEXT_MAIN,
            insertbackground=TEXT_MAIN,
            relief="flat",
            wrap="word",
            padx=10,
            pady=10,
        )
        self.log_box.grid(row=1, column=0, columnspan=2, sticky="nsew", pady=(18, 0))
        wrapper.rowconfigure(1, weight=1)

    def _field_entry(self, parent: tk.Misc, label: str, variable: tk.StringVar, *, row: int) -> None:
        ttk.Label(parent, text=label, style="Muted.TLabel").grid(row=row * 2, column=0, sticky="w", pady=(8, 3))
        ttk.Entry(parent, textvariable=variable, style="Field.TEntry").grid(row=row * 2 + 1, column=0, sticky="ew")

    def _field_combo(
        self,
        parent: tk.Misc,
        label: str,
        variable: tk.StringVar,
        values: list[str],
        *,
        row: int,
    ) -> ttk.Combobox:
        ttk.Label(parent, text=label, style="Muted.TLabel").grid(row=row * 2, column=0, sticky="w", pady=(8, 3))
        combo = ttk.Combobox(parent, textvariable=variable, values=values, style="Field.TCombobox")
        combo.grid(row=row * 2 + 1, column=0, sticky="ew")
        return combo

    def refresh_ports(self) -> None:
        ports = list_ports()
        self.port_combo.configure(values=ports)
        if "COM4" in ports and not self.port_var.get().strip():
            self.port_var.set("COM4")
        elif ports and not self.port_var.get().strip():
            self.port_var.set(ports[0])
        self.log("Puertos actualizados: " + (", ".join(ports) if ports else "sin puertos visibles"))

    def log(self, message: str) -> None:
        self.log_box.insert("end", message.strip() + "\n")
        self.log_box.see("end")

    def _build_config(self) -> Kx134CaptureConfig:
        duration_s = float(self.duration_var.get().strip())
        if duration_s <= 0:
            raise ValueError("La duracion debe ser positiva.")
        sample_rate = int(self.sample_rate_var.get().strip())
        if sample_rate not in KX134_ALLOWED_SAMPLE_RATES:
            raise ValueError("La frecuencia esperada debe ser 100, 200, 400 u 800 Hz.")
        port = self.port_var.get().strip()
        if not port:
            raise ValueError("Seleccione un puerto serial.")
        return Kx134CaptureConfig(
            port=port,
            baud=int(self.baud_var.get().strip() or KX134_DEFAULT_BAUD),
            duration_s=duration_s,
            expected_sample_rate_hz=sample_rate,
            output_root=self.repo_root,
            session_name=self.session_name_var.get().strip() or "kx134_live",
        )

    def start_capture(self) -> None:
        if self.worker:
            self.log("Ya hay una captura KX134 en curso.")
            return
        try:
            config = self._build_config()
        except ValueError as exc:
            self.status_var.set(f"Error de configuracion: {exc}")
            self.log(str(exc))
            return
        self.status_var.set("Captura KX134 en curso")
        self.start_button.state(["disabled"])
        self.worker = Kx134CaptureWorker(config, self._push_event)
        self.worker.start()
        self.log(f"Capturando {config.duration_s:g} s en {config.port} a {config.baud}.")

    def _push_event(self, event_type: str, payload: dict[str, object]) -> None:
        self.events.put((event_type, payload))

    def _drain_events(self) -> None:
        while True:
            try:
                event_type, payload = self.events.get_nowait()
            except queue.Empty:
                break
            self._handle_event(event_type, payload)
        self.after(120, self._drain_events)

    def _handle_event(self, event_type: str, payload: dict[str, object]) -> None:
        self.worker = None
        self.start_button.state(["!disabled"])
        if event_type == "session_error":
            self.status_var.set("Error KX134")
            self.log(str(payload.get("message", "Error desconocido")))
            return
        result = payload.get("result")
        if isinstance(result, Kx134SessionResult):
            summary = result.summary
            samples = summary["samples_by_sensor"]
            duplicates = summary["duplicate_keys_by_sensor"]
            receiver_errors = int(summary["receiver_timestamp_errors"])
            self.status_var.set("Captura KX134 completada")
            self.sensor1_var.set(f"Sensor 1: {samples.get('1', 0)} muestras")
            self.sensor2_var.set(f"Sensor 2: {samples.get('2', 0)} muestras")
            self.invalid_var.set(f"Invalid lines: {result.invalid_lines}")
            self.duplicates_var.set(
                f"Duplicate keys: {int(duplicates.get('1', 0)) + int(duplicates.get('2', 0))}"
            )
            self.receiver_var.set(
                "receiver_t_us: valido" if receiver_errors == 0 else f"receiver_t_us errores: {receiver_errors}"
            )
            self.files_var.set(
                "Archivos generados: "
                + str(result.artifacts.raw_csv_abs)
                + " | "
                + str(result.artifacts.session_json_abs)
            )
            self.log("Sesion KX134 guardada correctamente.")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="GUI live para KX134 dual ESP-NOW")
    parser.add_argument("--repo-root", default=str(_resolve_repo_root()))
    parser.add_argument("--port", default="")
    parser.add_argument("--baud", type=int, default=KX134_DEFAULT_BAUD)
    parser.add_argument("--duration-s", type=float, default=10.0)
    parser.add_argument("--expected-sample-rate", type=int, default=KX134_DEFAULT_SAMPLE_RATE_HZ)
    parser.add_argument("--session-name", default="kx134_live")
    return parser.parse_args()


def main() -> None:
    app = Kx134CaptureApp(parse_args())
    app.mainloop()


if __name__ == "__main__":
    main()

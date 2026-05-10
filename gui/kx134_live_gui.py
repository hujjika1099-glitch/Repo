from __future__ import annotations

import argparse
import queue
import sys
from pathlib import Path

import tkinter as tk
from tkinter import ttk

try:
    from . import ui_theme
    from .kx134_live_core import (
        Kx134CaptureConfig,
        Kx134CaptureWorker,
        Kx134SessionResult,
        validate_capture_duration,
        validate_expected_sample_rate,
    )
    from .kx134_stream_contract import (
        KX134_ALLOWED_SAMPLE_RATES,
        KX134_DEFAULT_BAUD,
        KX134_DEFAULT_SAMPLE_RATE_HZ,
    )
    from .ui_components import FileArtifactPanel, KeyValuePanel, ScrollableFrame, StatusCard, safe_set_grid_weights, section
except ImportError:  # pragma: no cover - direct script execution support
    import ui_theme
    from kx134_live_core import (
        Kx134CaptureConfig,
        Kx134CaptureWorker,
        Kx134SessionResult,
        validate_capture_duration,
        validate_expected_sample_rate,
    )
    from kx134_stream_contract import (
        KX134_ALLOWED_SAMPLE_RATES,
        KX134_DEFAULT_BAUD,
        KX134_DEFAULT_SAMPLE_RATE_HZ,
    )
    from ui_components import FileArtifactPanel, KeyValuePanel, ScrollableFrame, StatusCard, safe_set_grid_weights, section


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


def validate_baudrate(value: object) -> int:
    try:
        baud = int(str(value).strip())
    except (TypeError, ValueError) as exc:
        raise ValueError("El baudrate debe ser un entero positivo.") from exc
    if baud <= 0:
        raise ValueError("El baudrate debe ser positivo.")
    return baud


class Kx134CaptureApp(tk.Tk):
    def __init__(self, args: argparse.Namespace) -> None:
        ui_theme.set_windows_dpi_awareness_best_effort()
        super().__init__()
        self.title(ui_theme.APP_TITLE)
        self.geometry(ui_theme.DEFAULT_WINDOW_SIZE)
        self.minsize(*ui_theme.MIN_WINDOW_SIZE)
        ui_theme.apply_base_theme(self)
        ui_theme.configure_ttk_styles(self)

        self.repo_root = Path(args.repo_root).resolve()
        self.events: queue.Queue[tuple[str, dict[str, object]]] = queue.Queue()
        self.worker: Kx134CaptureWorker | None = None

        self.port_var = tk.StringVar(value=args.port or "")
        self.baud_var = tk.StringVar(value=str(args.baud))
        self.duration_var = tk.StringVar(value=str(args.duration_s))
        self.sample_rate_var = tk.StringVar(value=str(args.expected_sample_rate))
        self.session_name_var = tk.StringVar(value=args.session_name)
        self.output_root_var = tk.StringVar(value=str(self.repo_root))

        self.status_var = tk.StringVar(value="En espera")
        self.connection_var = tk.StringVar(value="Puerto pendiente")
        self.capture_decision_var = tk.StringVar(value="Sin captura")
        self.invalid_var = tk.StringVar(value="0")
        self.duplicates_var = tk.StringVar(value="0")
        self.receiver_var = tk.StringVar(value="Pendiente")
        self.pc_wall_var = tk.StringVar(value="Pendiente")
        self.packet_status_var = tk.StringVar(value="Pendiente")
        self.packet_error_var = tk.StringVar(value="Pendiente")
        self.sensor1_samples_var = tk.StringVar(value="0")
        self.sensor2_samples_var = tk.StringVar(value="0")
        self.sensor1_gaps_var = tk.StringVar(value="0")
        self.sensor2_gaps_var = tk.StringVar(value="0")
        self.sensor1_status_var = tk.StringVar(value="No presente")
        self.sensor2_status_var = tk.StringVar(value="No presente")
        self.sensor1_id_var = tk.StringVar(value="1")
        self.sensor2_id_var = tk.StringVar(value="2")
        self.sensor1_mac_var = tk.StringVar(value="D4:E9:F4:E9:8E:1C")
        self.sensor2_mac_var = tk.StringVar(value="D4:E9:F4:C3:37:14")

        self._build_layout()
        self.refresh_ports()
        self.after(120, self._drain_events)
        if getattr(args, "close_after_ms", 0):
            self.after(int(args.close_after_ms), self.destroy)

    def _build_layout(self) -> None:
        self.columnconfigure(0, weight=1)
        self.rowconfigure(1, weight=1)

        header = ttk.Frame(self, style="App.TFrame", padding=(ui_theme.PADDING, ui_theme.PADDING, ui_theme.PADDING, 8))
        header.grid(row=0, column=0, sticky="ew")
        header.columnconfigure(0, weight=1)
        ttk.Label(header, text=ui_theme.APP_TITLE, style="Header.TLabel").grid(row=0, column=0, sticky="w")
        ttk.Label(header, text=ui_theme.VERSION_LABEL, style="Subheader.TLabel").grid(row=1, column=0, sticky="w")
        self.status_label = ttk.Label(header, textvariable=self.status_var, style="StatusWarn.TLabel")
        self.status_label.grid(row=0, column=1, rowspan=2, sticky="e")

        self.notebook = ttk.Notebook(self)
        self.notebook.grid(row=1, column=0, sticky="nsew", padx=ui_theme.PADDING, pady=(0, ui_theme.PADDING))
        self._build_connection_tab()
        self._build_capture_tab()
        self._build_sensors_tab()
        self._build_diagnostics_tab()
        self._build_export_tab()

    def _tab(self, title: str) -> ttk.Frame:
        outer = ttk.Frame(self.notebook, style="Surface.TFrame")
        outer.columnconfigure(0, weight=1)
        outer.rowconfigure(0, weight=1)
        scroller = ScrollableFrame(outer)
        scroller.grid(row=0, column=0, sticky="nsew")
        self.notebook.add(outer, text=title)
        return scroller.content

    def _build_connection_tab(self) -> None:
        tab = self._tab("Conexion")
        safe_set_grid_weights(tab, columns=(0,))
        conn = section(tab, "Puerto y enlace serial")
        conn.grid(row=0, column=0, sticky="ew", padx=10, pady=10)
        conn.columnconfigure(1, weight=1)
        ttk.Label(conn, text="Puerto serial", style="Muted.TLabel").grid(row=0, column=0, sticky="w", pady=6)
        self.port_combo = ttk.Combobox(conn, textvariable=self.port_var)
        self.port_combo.grid(row=0, column=1, sticky="ew", padx=(12, 8), pady=6)
        ttk.Button(conn, text="Actualizar puertos", command=self.refresh_ports).grid(row=0, column=2, sticky="ew", pady=6)
        ttk.Label(conn, text="Baudrate", style="Muted.TLabel").grid(row=1, column=0, sticky="w", pady=6)
        ttk.Entry(conn, textvariable=self.baud_var).grid(row=1, column=1, sticky="ew", padx=(12, 8), pady=6)
        KeyValuePanel(
            conn,
            [
                ("Estado", self.connection_var),
                ("Carpeta de salida", self.output_root_var),
            ],
        ).grid(row=2, column=0, columnspan=3, sticky="ew", pady=(12, 0))

    def _build_capture_tab(self) -> None:
        tab = self._tab("Captura")
        safe_set_grid_weights(tab, columns=(0,))
        capture = section(tab, "Configuracion de captura")
        capture.grid(row=0, column=0, sticky="ew", padx=10, pady=10)
        capture.columnconfigure(1, weight=1)
        ttk.Label(capture, text="Duracion (s)", style="Muted.TLabel").grid(row=0, column=0, sticky="w", pady=6)
        ttk.Entry(capture, textvariable=self.duration_var).grid(row=0, column=1, sticky="ew", padx=(12, 0), pady=6)
        ttk.Label(capture, text="Frecuencia esperada", style="Muted.TLabel").grid(row=1, column=0, sticky="w", pady=6)
        ttk.Combobox(
            capture,
            textvariable=self.sample_rate_var,
            values=[str(rate) for rate in KX134_ALLOWED_SAMPLE_RATES],
            state="readonly",
        ).grid(row=1, column=1, sticky="ew", padx=(12, 0), pady=6)
        ttk.Label(capture, text="Nombre de sesion", style="Muted.TLabel").grid(row=2, column=0, sticky="w", pady=6)
        ttk.Entry(capture, textvariable=self.session_name_var).grid(row=2, column=1, sticky="ew", padx=(12, 0), pady=6)
        button_row = ttk.Frame(capture, style="Surface.TFrame")
        button_row.grid(row=3, column=0, columnspan=2, sticky="ew", pady=(14, 0))
        button_row.columnconfigure(0, weight=1)
        button_row.columnconfigure(1, weight=1)
        self.start_button = ttk.Button(button_row, text="Iniciar captura KX134", style="Primary.TButton", command=self.start_capture)
        self.start_button.grid(row=0, column=0, sticky="ew", padx=(0, 8))
        self.stop_button = ttk.Button(button_row, text="Detener captura", state="disabled")
        self.stop_button.grid(row=0, column=1, sticky="ew")

        status = section(tab, "Estado de captura")
        status.grid(row=1, column=0, sticky="ew", padx=10, pady=10)
        KeyValuePanel(
            status,
            [
                ("Estado", self.status_var),
                ("Decision", self.capture_decision_var),
            ],
        ).grid(row=0, column=0, sticky="ew")

    def _build_sensors_tab(self) -> None:
        tab = self._tab("Sensores")
        safe_set_grid_weights(tab, columns=(0, 1))
        s1 = section(tab, "Sensor 1")
        s2 = section(tab, "Sensor 2")
        s1.grid(row=0, column=0, sticky="nsew", padx=10, pady=10)
        s2.grid(row=0, column=1, sticky="nsew", padx=10, pady=10)
        KeyValuePanel(
            s1,
            [
                ("sensor_id", self.sensor1_id_var),
                ("MAC", self.sensor1_mac_var),
                ("Muestras", self.sensor1_samples_var),
                ("Seq gaps", self.sensor1_gaps_var),
                ("Estado", self.sensor1_status_var),
            ],
        ).grid(row=0, column=0, sticky="ew")
        KeyValuePanel(
            s2,
            [
                ("sensor_id", self.sensor2_id_var),
                ("MAC", self.sensor2_mac_var),
                ("Muestras", self.sensor2_samples_var),
                ("Seq gaps", self.sensor2_gaps_var),
                ("Estado", self.sensor2_status_var),
            ],
        ).grid(row=0, column=0, sticky="ew")

    def _build_diagnostics_tab(self) -> None:
        tab = self._tab("Diagnostico")
        safe_set_grid_weights(tab, columns=(0, 1), rows=(1,))
        cards = ttk.Frame(tab, style="Surface.TFrame")
        cards.grid(row=0, column=0, columnspan=2, sticky="ew", padx=10, pady=10)
        safe_set_grid_weights(cards, columns=(0, 1, 2, 3))
        self.invalid_card = StatusCard(cards, title="Invalid lines", value="0")
        self.duplicate_card = StatusCard(cards, title="Duplicate keys", value="0")
        self.receiver_card = StatusCard(cards, title="receiver_t_us", value="Pendiente")
        self.pc_wall_card = StatusCard(cards, title="pc_wall_s", value="Pendiente")
        for index, card in enumerate((self.invalid_card, self.duplicate_card, self.receiver_card, self.pc_wall_card)):
            card.grid(row=0, column=index, sticky="ew", padx=6)

        detail = section(tab, "Detalle")
        detail.grid(row=1, column=0, sticky="nsew", padx=10, pady=10)
        detail.columnconfigure(0, weight=1)
        KeyValuePanel(
            detail,
            [
                ("packet_status", self.packet_status_var),
                ("packet_error_code", self.packet_error_var),
                ("receiver_t_us", self.receiver_var),
                ("pc_wall_s", self.pc_wall_var),
            ],
        ).grid(row=0, column=0, sticky="ew")

        messages = section(tab, "Mensajes recientes")
        messages.grid(row=1, column=1, sticky="nsew", padx=10, pady=10)
        messages.rowconfigure(0, weight=1)
        messages.columnconfigure(0, weight=1)
        self.log_box = tk.Text(messages, height=12, wrap="word", relief="solid", borderwidth=1)
        self.log_box.grid(row=0, column=0, sticky="nsew")

    def _build_export_tab(self) -> None:
        tab = self._tab("Exportacion")
        safe_set_grid_weights(tab, columns=(0,))
        artifacts = section(tab, "Archivos generados")
        artifacts.grid(row=0, column=0, sticky="ew", padx=10, pady=10)
        artifacts.columnconfigure(0, weight=1)
        self.file_panel = FileArtifactPanel(artifacts)
        self.file_panel.grid(row=0, column=0, sticky="ew")

    def refresh_ports(self) -> None:
        ports = list_ports()
        self.port_combo.configure(values=ports)
        if "COM4" in ports and not self.port_var.get().strip():
            self.port_var.set("COM4")
        elif ports and not self.port_var.get().strip():
            self.port_var.set(ports[0])
        self.connection_var.set(", ".join(ports) if ports else "Sin puertos visibles")
        self.log("Puertos actualizados: " + (", ".join(ports) if ports else "sin puertos visibles"))

    def log(self, message: str) -> None:
        self.log_box.insert("end", message.strip() + "\n")
        self.log_box.see("end")

    def _build_config(self) -> Kx134CaptureConfig:
        duration_s = validate_capture_duration(self.duration_var.get().strip())
        sample_rate = validate_expected_sample_rate(self.sample_rate_var.get().strip())
        baud = validate_baudrate(self.baud_var.get().strip())
        port = self.port_var.get().strip()
        if not port:
            raise ValueError("Seleccione un puerto serial.")
        return Kx134CaptureConfig(
            port=port,
            baud=baud,
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
            self.status_label.configure(style="StatusError.TLabel")
            self.log(str(exc))
            return
        self.status_var.set("Captura KX134 en curso")
        self.capture_decision_var.set("En progreso")
        self.status_label.configure(style="StatusWarn.TLabel")
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
            self.capture_decision_var.set("FAIL")
            self.status_label.configure(style="StatusError.TLabel")
            self.log(str(payload.get("message", "Error desconocido")))
            return

        result = payload.get("result")
        if not isinstance(result, Kx134SessionResult):
            return

        summary = result.summary
        samples = summary["samples_by_sensor"]
        gaps = summary["seq_gaps_by_sensor"]
        duplicates = summary["duplicate_keys_by_sensor"]
        receiver_errors = int(summary["receiver_timestamp_errors"])
        duplicate_total = int(duplicates.get("1", 0)) + int(duplicates.get("2", 0))
        session_valid = (
            result.invalid_lines == 0
            and duplicate_total == 0
            and receiver_errors == 0
            and int(samples.get("1", 0)) > 0
            and int(samples.get("2", 0)) > 0
        )

        self.status_var.set("Captura KX134 completada")
        self.capture_decision_var.set("PASS" if session_valid else "REVISAR")
        self.status_label.configure(style="StatusOk.TLabel" if session_valid else "StatusWarn.TLabel")
        self.sensor1_samples_var.set(str(samples.get("1", 0)))
        self.sensor2_samples_var.set(str(samples.get("2", 0)))
        self.sensor1_gaps_var.set(str(gaps.get("1", 0)))
        self.sensor2_gaps_var.set(str(gaps.get("2", 0)))
        self.sensor1_status_var.set("Presente" if int(samples.get("1", 0)) > 0 else "No presente")
        self.sensor2_status_var.set("Presente" if int(samples.get("2", 0)) > 0 else "No presente")
        self.invalid_var.set(str(result.invalid_lines))
        self.duplicates_var.set(str(duplicate_total))
        self.receiver_var.set("Valido" if receiver_errors == 0 else f"Errores: {receiver_errors}")
        self.pc_wall_var.set("Positivo" if summary.get("pc_wall_s_positive") else "Revisar")
        self.packet_status_var.set(str(summary.get("packet_status_counts", {})))
        self.packet_error_var.set(str(summary.get("packet_error_code_counts", {})))
        self.invalid_card.update(str(result.invalid_lines), tone="ok" if result.invalid_lines == 0 else "warn")
        self.duplicate_card.update(str(duplicate_total), tone="ok" if duplicate_total == 0 else "warn")
        self.receiver_card.update(self.receiver_var.get(), tone="ok" if receiver_errors == 0 else "warn")
        self.pc_wall_card.update(self.pc_wall_var.get(), tone="ok" if summary.get("pc_wall_s_positive") else "warn")
        self.file_panel.set_paths(
            raw_csv=str(result.artifacts.raw_csv_abs),
            session_json=str(result.artifacts.session_json_abs),
            summary_md=str(result.artifacts.summary_abs),
        )
        self.log("Sesion KX134 guardada correctamente.")


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="GUI live para KX134 dual ESP-NOW")
    parser.add_argument("--repo-root", default=str(_resolve_repo_root()))
    parser.add_argument("--port", default="")
    parser.add_argument("--baud", type=int, default=KX134_DEFAULT_BAUD)
    parser.add_argument("--duration-s", type=float, default=10.0)
    parser.add_argument("--expected-sample-rate", type=int, default=KX134_DEFAULT_SAMPLE_RATE_HZ)
    parser.add_argument("--session-name", default="kx134_live")
    parser.add_argument("--smoke", action="store_true")
    parser.add_argument("--close-after-ms", type=int, default=0)
    return parser.parse_args(argv)


def create_app(args: argparse.Namespace | None = None) -> Kx134CaptureApp:
    return Kx134CaptureApp(args or parse_args([]))


def main(argv: list[str] | None = None) -> None:
    args = parse_args(argv)
    if args.smoke and not args.close_after_ms:
        args.close_after_ms = 1000
    app = Kx134CaptureApp(args)
    app.mainloop()


if __name__ == "__main__":
    main()

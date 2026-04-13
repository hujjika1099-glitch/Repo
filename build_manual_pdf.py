"""
build_manual_pdf.py
Genera ADXL335_Captura_Manual.pdf en la raiz del repo.
Ejecutar: .venv\Scripts\python.exe build_manual_pdf.py
"""

from __future__ import annotations
import warnings
warnings.filterwarnings("ignore")

from pathlib import Path
from fpdf import FPDF, XPos, YPos

OUTPUT = Path(__file__).parent / "ADXL335_Captura_Manual.pdf"

# ── Paleta de colores (alto contraste) ────────────────────────────────────────
# Portada
COV_BG    = (7,  18,  25)
COV_ACC   = (242,166, 90)
COV_CYAN  = (100,210,230)
COV_TEXT  = (238,246,248)
COV_MUTED = (145,175,187)

# Texto principal (paginas de contenido)
T_DARK    = (15,  30,  45)   # texto principal
T_MED     = (55,  80, 105)   # texto secundario
T_CODE    = (20,  55, 130)   # nombres de campo (monospace)
T_WHITE   = (255,255,255)

# Fondos de pagina
PG_BG     = (255,255,255)    # paginas blancas

# Chapas de capitulo
CH_BG     = (20,  45,  70)   # banda de capitulo
CH_FG     = (255,255,255)    # texto en banda
CH_ACC    = (242,166, 90)    # linea acento

# Sub-titulos
SB_FG     = (20,  45,  70)

# Tablas
TH_BG     = (20,  45,  70)   # cabecera de tabla
TH_FG     = (255,255,255)
ROW_A     = (255,255,255)    # fila par
ROW_B     = (235,243,250)    # fila impar
ROW_BD    = (185,210,225)    # borde inferior de fila

# Codigos en linea / bloques de codigo
CB_BG     = (232,240,250)    # fondo bloque codigo
CB_FG     = (15,  50, 120)   # texto bloque codigo

# Estado / badges
S_PASS    = (34, 139,  60)   # verde
S_FAIL    = (185,  30,  30)  # rojo
S_SUSP    = (160, 110,   0)  # amarillo oscuro
S_NEUT    = ( 80, 100, 120)  # neutro

# Cajas de nota
NB_BG     = (235,245,255)
NB_BD     = ( 60,140,200)
WB_BG     = (255,250,225)
WB_BD     = (180,140,  0)
DB_BG     = (255,235,235)
DB_BD     = (180, 30,  30)

# Decoracion lateral de fases
PH_COLS   = [(60,160,210), (242,166,90), (34,139,60), (160,110,0)]


# ═══════════════════════════════════════════════════════════════════════════════
class PDF(FPDF):

    def __init__(self):
        super().__init__(orientation="P", unit="mm", format="A4")
        self.set_auto_page_break(auto=True, margin=22)
        self._epw = 180.0   # ancho util (210 - 15 - 15)

    # ── primitivas de color ─────────────────────────────────────────────────
    def fc(self, rgb): self.set_fill_color(*rgb)
    def tc(self, rgb): self.set_text_color(*rgb)
    def dc(self, rgb): self.set_draw_color(*rgb)

    # ── header / footer ─────────────────────────────────────────────────────
    def header(self):
        if self.page_no() == 1:
            return
        self.set_font("Helvetica", "", 7.5)
        self.tc(T_MED)
        self.cell(0, 7, "ADXL335 Captura  |  Manual de usuario",
                  new_x=XPos.RIGHT, new_y=YPos.TOP)
        self.cell(0, 7, f"Pagina {self.page_no()}",
                  new_x=XPos.LMARGIN, new_y=YPos.NEXT, align="R")
        self.fc(ROW_BD); self.rect(self.l_margin, self.get_y(), self._epw, 0.25, "F")
        self.ln(3)

    def footer(self):
        if self.page_no() == 1:
            return
        self.set_y(-13)
        self.fc(ROW_BD); self.rect(self.l_margin, self.get_y(), self._epw, 0.25, "F")
        self.ln(1)
        self.set_font("Helvetica", "I", 7)
        self.tc(T_MED)
        self.cell(0, 5, "Universidad del Quindio  |  2025-2026", align="C")

    # ── elementos de layout ─────────────────────────────────────────────────
    def chap(self, num: str, title: str):
        """Banda de capitulo."""
        self.ln(5)
        self.fc(CH_BG)
        self.rect(self.l_margin, self.get_y(), self._epw, 9.5, "F")
        self.fc(CH_ACC)
        self.rect(self.l_margin, self.get_y() + 9.5, self._epw, 0.9, "F")
        self.set_font("Helvetica", "B", 13)
        self.tc(CH_FG)
        self.cell(self._epw, 9.5, f"  {num}   {title}",
                  new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.ln(4)
        self.tc(T_DARK)

    def sub(self, text: str):
        """Sub-titulo de seccion."""
        self.ln(3)
        self.set_font("Helvetica", "B", 10.5)
        self.tc(SB_FG)
        self.cell(0, 6, text, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.fc(CH_ACC)
        self.rect(self.l_margin, self.get_y(), 36, 0.5, "F")
        self.ln(3)
        self.tc(T_DARK)

    def body(self, text: str, indent: float = 0):
        self.set_font("Helvetica", "", 10)
        self.tc(T_DARK)
        if indent:
            self.set_x(self.l_margin + indent)
        self.multi_cell(self._epw - indent, 5.5, text)
        self.ln(1)

    def bullet(self, label: str, value: str, lw: float = 50, indent: float = 4):
        x0 = self.l_margin + indent
        self.set_x(x0)
        self.set_font("Helvetica", "B", 9.5)
        self.tc(SB_FG)
        self.cell(lw, 5.5, label, new_x=XPos.RIGHT, new_y=YPos.TOP)
        self.set_font("Helvetica", "", 9.5)
        self.tc(T_DARK)
        self.multi_cell(self._epw - indent - lw, 5.5, value)

    def code_line(self, text: str):
        """Bloque de una linea estilo codigo/nombre de archivo."""
        self.ln(1)
        self.fc(CB_BG)
        self.rect(self.l_margin, self.get_y(), self._epw, 7, "F")
        self.set_font("Courier", "B", 9)
        self.tc(CB_FG)
        self.set_x(self.l_margin + 3)
        self.cell(self._epw - 3, 7, text, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.ln(1)
        self.tc(T_DARK)

    def note(self, text: str, bg=NB_BG, bd=NB_BD):
        """Caja de nota / advertencia."""
        self.ln(2)
        self.set_font("Helvetica", "", 9.5)
        lines = self.multi_cell(self._epw - 8, 5, text,
                                dry_run=True, output="LINES")
        h = len(lines) * 5 + 8
        x0, y0 = self.l_margin, self.get_y()
        self.fc(bg); self.dc(bd)
        self.set_line_width(0.5)
        self.rect(x0, y0, self._epw, h, "FD")
        self.set_line_width(0.2)
        self.set_xy(x0 + 4, y0 + 4)
        self.tc(T_DARK)
        self.multi_cell(self._epw - 8, 5, text)
        self.ln(3)

    def warn(self, text: str): self.note(text, WB_BG, WB_BD)
    def danger(self, text: str): self.note(text, DB_BG, DB_BD)

    # ── tablas robustas ──────────────────────────────────────────────────────
    def th(self, cols: list[tuple[str, float]]):
        """Cabecera de tabla: lista de (etiqueta, ancho_mm)."""
        self.fc(TH_BG); self.tc(TH_FG)
        self.set_font("Helvetica", "B", 9)
        for label, w in cols:
            self.cell(w, 7, f"  {label}",
                      new_x=XPos.RIGHT, new_y=YPos.TOP, fill=True)
        self.ln()
        self.dc(ROW_BD); self.set_line_width(0.3)

    def tr(self, cells: list[tuple[str, float, str, str]], alt: bool = False):
        """
        Fila de tabla con soporte multi-linea.
        cells = lista de (texto, ancho_mm, familia_fuente, estilo_fuente)
        Estilos comunes: "" normal  "B" bold  "I" italic  "C" = Courier bold
        """
        LINE_H = 5.0
        PAD    = 2.5   # padding horizontal interno
        PAD_V  = 1.5   # padding vertical

        # 1. calcular altura maxima de fila
        max_lines = 1
        for text, w, fam, sty in cells:
            fam_real = "Courier" if fam == "C" else "Helvetica"
            sty_real = "B" if fam == "C" else sty
            self.set_font(fam_real, sty_real, 9)
            ls = self.multi_cell(w - PAD * 2, LINE_H, text,
                                 dry_run=True, output="LINES")
            max_lines = max(max_lines, len(ls))
        row_h = max_lines * LINE_H + PAD_V * 2

        # 2. fondo de fila
        x0, y0 = self.l_margin, self.get_y()
        total_w = sum(w for _, w, _, _ in cells)
        self.fc(ROW_B if alt else ROW_A)
        self.rect(x0, y0, total_w, row_h, "F")

        # 3. texto de cada celda
        xc = x0
        for text, w, fam, sty in cells:
            fam_real = "Courier" if fam == "C" else "Helvetica"
            sty_real = "B" if fam == "C" else sty
            self.set_font(fam_real, sty_real, 9)

            if fam == "C":
                self.tc(T_CODE)
            elif sty == "I":
                self.tc(T_MED)
            else:
                self.tc(T_DARK)

            self.set_xy(xc + PAD, y0 + PAD_V)
            self.multi_cell(w - PAD * 2, LINE_H, text)
            xc += w

        # 4. linea inferior de fila
        self.dc(ROW_BD)
        self.line(x0, y0 + row_h, x0 + total_w, y0 + row_h)

        # 5. avanzar cursor
        self.set_xy(x0, y0 + row_h)

    def status_badge(self, code: str) -> str:
        """Devuelve el codigo con su color; se usa en texto inline."""
        return code   # simplificado: el color lo aplica la celda status

    # ── portada ─────────────────────────────────────────────────────────────
    def portada(self):
        # fondo completo
        self.fc(COV_BG); self.rect(0, 0, 210, 297, "F")

        # banda superior acento
        self.fc(COV_ACC); self.rect(0, 0, 210, 5, "F")

        # titulo principal
        self.set_xy(18, 62)
        self.set_font("Helvetica", "B", 34)
        self.tc(COV_ACC)
        self.cell(0, 14, "ADXL335 Captura",
                  new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.set_x(18)
        self.set_font("Helvetica", "", 16)
        self.tc(COV_TEXT)
        self.cell(0, 9, "Manual de usuario -- Guia de datos exportados",
                  new_x=XPos.LMARGIN, new_y=YPos.NEXT)

        # linea separadora
        self.set_y(98)
        self.fc(COV_CYAN); self.rect(18, self.get_y(), 174, 0.8, "F")
        self.ln(10)

        # descripcion
        self.set_x(18)
        self.set_font("Helvetica", "", 10.5)
        self.tc(COV_MUTED)
        self.multi_cell(174, 7,
            "Aplicacion de escritorio para la captura y monitoreo en tiempo real de\n"
            "acelerometros ADXL335 conectados a una ESP32 via USB.\n\n"
            "Este documento describe como usar la interfaz, que hace cada control,\n"
            "y que significa cada campo y nombre de archivo que el sistema genera."
        )

        # recuadro de hardware
        self.set_y(165)
        self.fc((13, 34, 48)); self.rect(18, self.get_y(), 174, 52, "F")
        self.fc(COV_CYAN); self.rect(18, self.get_y(), 3, 52, "F")
        self.set_xy(24, self.get_y() + 6)
        self.set_font("Helvetica", "B", 10)
        self.tc(COV_CYAN)
        self.cell(0, 6, "Hardware requerido",
                  new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        items = [
            "Sensor:          ADXL335 (acelerometro analogico triaxial 3.3 V)",
            "Microcontrolador: ESP32 con firmware ADXL335 preinstalado",
            "Interfaz USB:    CH340 / CP210x a 115200 baud",
            "Sistema operativo: Windows 10 / 11 de 64 bits",
        ]
        for item in items:
            self.set_x(24)
            self.set_font("Helvetica", "", 9.5)
            self.tc(COV_TEXT)
            self.cell(0, 6.5, item, new_x=XPos.LMARGIN, new_y=YPos.NEXT)

        # version
        self.set_y(240)
        self.set_x(18)
        self.set_font("Helvetica", "", 8.5)
        self.tc(COV_MUTED)
        self.cell(0, 6, "Version 1.0  |  Abril 2026  |  Python 3.11 + PyInstaller 6",
                  new_x=XPos.LMARGIN, new_y=YPos.NEXT)

        # banda inferior
        self.fc(COV_ACC); self.rect(0, 291, 210, 6, "F")


# ═══════════════════════════════════════════════════════════════════════════════
def build(p: PDF):

    # ── PORTADA ─────────────────────────────────────────────────────────────
    p.add_page()
    p.portada()

    # ── INDICE ──────────────────────────────────────────────────────────────
    p.add_page()
    p.set_font("Helvetica", "B", 16)
    p.tc(T_DARK)
    p.cell(0, 9, "Contenido", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
    p.fc(CH_ACC); p.rect(p.l_margin, p.get_y(), p._epw, 0.6, "F"); p.ln(4)

    toc = [
        ("1",  "Requisitos e instalacion"),
        ("2",  "Interfaz de la aplicacion -- descripcion de controles"),
        ("3",  "Flujo de una sesion de captura"),
        ("4",  "Archivos generados -- estructura de nombres"),
        ("5",  "Referencia de campos: CSV raw (_raw.csv)"),
        ("6",  "Referencia de campos: CSV processed (_processed.csv)"),
        ("7",  "Referencia de campos: JSON de sesion (_session.json)"),
        ("8",  "Referencia de campos: reporte precheck (_precheck.txt)"),
        ("9",  "Referencia de campos: reporte summary (_summary.txt)"),
        ("10", "Codigos de estado y razon -- interpretacion completa"),
        ("11", "Preguntas frecuentes y solucion de problemas"),
    ]
    for num, title in toc:
        p.set_font("Helvetica", "B", 9.5)
        p.tc(T_CODE)
        p.cell(12, 6.5, num, new_x=XPos.RIGHT, new_y=YPos.TOP)
        p.set_font("Helvetica", "", 10)
        p.tc(T_DARK)
        p.cell(0, 6.5, title, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
    p.ln(6)

    # ═══════════════════════════════════════════════════════════════════════
    # 1. REQUISITOS
    # ═══════════════════════════════════════════════════════════════════════
    p.add_page()
    p.chap("1", "Requisitos e instalacion")

    p.sub("Hardware")
    reqs = [
        ("Sensor principal:",   "ADXL335 conectado al ADC de la ESP32 (sensor_id = 1, etiqueta sensor_B)"),
        ("Sensor secundario:",  "Segundo ADXL335 opcional (sensor_id = 2, etiqueta sensor_A)"),
        ("Microcontrolador:",   "ESP32 con firmware de captura dual o single node"),
        ("Interfaz USB:",       "Adaptador CH340, CP210x o similar; driver de Windows instalado"),
    ]
    for k, v in reqs:
        p.bullet(k, v)

    p.sub("Software")
    p.body(
        "La aplicacion se distribuye como ejecutable autonomo (ADXL335_Captura.exe). "
        "No requiere instalar Python ni ninguna dependencia adicional. "
        "Solo es necesario Windows 10/11 de 64 bits."
    )

    p.sub("Pasos de instalacion")
    steps = [
        "Extraer ADXL335_Captura_dist.zip en la carpeta deseada (p.ej. C:\\Captura\\).",
        "Conectar la ESP32 via USB y esperar que Windows instale el driver automaticamente.",
        "Ejecutar ADXL335_Captura.exe. La primera vez crea automaticamente las carpetas de datos.",
        "No mover el .exe de su carpeta; los datos se guardan siempre a su lado.",
    ]
    for i, s in enumerate(steps, 1):
        p.set_font("Helvetica", "B", 10); p.tc(CH_ACC)
        p.set_x(p.l_margin + 4); p.cell(8, 6, f"{i}.", new_x=XPos.RIGHT, new_y=YPos.TOP)
        p.set_font("Helvetica", "", 10); p.tc(T_DARK)
        p.multi_cell(p._epw - 12, 6, s); p.ln(1)

    p.note(
        "Al primer arranque se crean automaticamente: data\\raw\\sensor_B_live\\, "
        "data\\processed\\ y reports\\analysis_outputs\\ junto al ejecutable. "
        "No es necesario crearlos manualmente."
    )

    # ═══════════════════════════════════════════════════════════════════════
    # 2. INTERFAZ
    # ═══════════════════════════════════════════════════════════════════════
    p.add_page()
    p.chap("2", "Interfaz de la aplicacion -- descripcion de controles")

    p.body(
        "La ventana tiene dos zonas: el panel lateral izquierdo (configuracion y estado) "
        "y el area central de monitoreo con graficas en tiempo real."
    )

    p.sub("Panel lateral -- seccion Sesion")
    controls = [
        ("Equipo (COM)",
         "Puerto serial de la ESP32. 'Automatico' detecta el puerto sondeando los "
         "dispositivos disponibles. Si hay varios puertos, seleccione el COM correcto manualmente."),
        ("Duracion",
         "Tiempo en segundos de la captura principal (10, 20, 30, 60 o 90 s). "
         "El chequeo previo (precheck) va aparte y NO cuenta dentro de este tiempo."),
        ("Nombre de sesion",
         "Etiqueta libre que se incrusta en el nombre del archivo: 'ensayo1', "
         "'estatico', 'vibracion'. Solo letras, numeros y guion bajo. Por defecto: 'live'."),
        ("Iniciar",
         "Inicia el ciclo completo: deteccion de puerto -> precheck -> captura -> guardado. "
         "Se deshabilita mientras corre una sesion."),
        ("Detener",
         "Cancela la sesion en cualquier fase. Los datos ya capturados se descartan; "
         "no se guarda ningun archivo de datos."),
        ("Actualizar",
         "Vuelve a escanear los puertos COM disponibles. Util si conectaste la ESP32 despues "
         "de abrir la aplicacion."),
        ("Opciones (avanzado)",
         "Muestra configuracion avanzada: prefijo de archivo, carpetas de salida, "
         "duracion del precheck, ventana de grafica y baud rate. En uso normal no es necesario cambiarlos."),
    ]
    for name, desc in controls:
        p.ln(1)
        p.set_font("Helvetica", "B", 10); p.tc(SB_FG)
        p.set_x(p.l_margin + 4); p.cell(0, 6, name, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        p.set_font("Helvetica", "", 9.5); p.tc(T_DARK)
        p.set_x(p.l_margin + 8); p.multi_cell(p._epw - 8, 5.5, desc)

    p.sub("Panel lateral -- indicadores de estado (Resumen)")
    tiles = [
        ("Estado:",     "Estado global: En espera / Preparando / Chequeando / Grabando / Completado / Error."),
        ("Conexion:",   "Puerto COM usado y modo de seleccion (auto o manual)."),
        ("Principal:",  "Calidad del sensor_id = 1 (sensor_B): pass / revisar / fallo."),
        ("Secundario:", "Calidad del sensor_id = 2 (sensor_A): pass / revisar / fallo."),
    ]
    for k, v in tiles:
        p.bullet(k, v)

    p.sub("Graficas de monitoreo (area central)")
    plots = [
        ("Comparacion principal (|g|)",
         "Norma del vector de aceleracion en tiempo real para ambos sensores. "
         "La linea de referencia a 1.0 g indica el valor esperado en reposo. "
         "Un sensor estatico deberia oscilar cerca de esa linea."),
        ("Detalle por sensor (ejes X, Y, Z)",
         "Muestra la tension en mV de cada eje del sensor seleccionado con el combo 'Detalle'. "
         "Permite detectar saturacion o eje muerto antes de que termine la sesion."),
        ("Comparativa de actividad (eje Z)",
         "Superpone el eje Z de ambos sensores para comparar si responden de forma "
         "similar ante el mismo estimulo mecanico."),
        ("Vista ampliada",
         "Boton en la esquina superior derecha. Abre una segunda ventana con las tres "
         "graficas a mayor resolucion, util en pantallas grandes o proyectores."),
    ]
    for name, desc in plots:
        p.ln(1)
        p.set_font("Helvetica", "B", 10); p.tc(SB_FG)
        p.set_x(p.l_margin + 4); p.cell(0, 6, name, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        p.set_font("Helvetica", "", 9.5); p.tc(T_DARK)
        p.set_x(p.l_margin + 8); p.multi_cell(p._epw - 8, 5.5, desc)

    p.sub("Tira de metricas rapidas")
    quick = [
        ("Monitoreo:", "Frecuencia de muestreo instantanea en Hz."),
        ("Tiempo:",    "Segundos transcurridos desde el inicio de la captura."),
        ("Muestras:",  "Total de muestras validas recibidas (suma de ambos sensores)."),
        ("Salida:",    "Ruta relativa del archivo processed CSV generado al finalizar."),
    ]
    for k, v in quick:
        p.bullet(k, v)

    p.sub("Actividad reciente")
    p.body(
        "Registro cronologico de eventos: deteccion de puerto, inicio de precheck, "
        "resultado del precheck, inicio de captura y resultado final. "
        "Permite seguir el estado paso a paso."
    )

    # ═══════════════════════════════════════════════════════════════════════
    # 3. FLUJO DE SESION
    # ═══════════════════════════════════════════════════════════════════════
    p.add_page()
    p.chap("3", "Flujo de una sesion de captura")

    p.body("Al presionar Iniciar, la aplicacion ejecuta cuatro fases en orden:")

    phases = [
        ("Fase 1 -- Autodeteccion de puerto",
         "Si Equipo esta en 'Automatico', la app escanea todos los puertos COM y sondea "
         "cada uno ~1.6 s buscando el encabezado del stream ADXL335. El puerto que responda "
         "correctamente se selecciona solo. Si hay solo un puerto disponible, se usa "
         "directamente sin sondear. Si el usuario elige un COM especifico, se usa ese.",
         PH_COLS[0]),
        ("Fase 2 -- Chequeo previo (precheck dual)",
         "Captura datos durante el tiempo configurado (por defecto 10 s) con ambos "
         "sensores activos. Evalua: suficientes muestras, sin saturacion ADC, sin ejes muertos, "
         "sin perdidas de paquetes excesivas. Si cualquier sensor falla, la sesion se cancela "
         "mostrando el motivo. El resultado se guarda en _precheck.txt siempre, incluso si falla.",
         PH_COLS[1]),
        ("Fase 3 -- Captura principal",
         "Graba datos durante el tiempo seleccionado (10-90 s). Las graficas se actualizan "
         "en tiempo real. El sensor principal (sensor_id = 1) se muestra en la grafica "
         "de detalle. Al finalizar el tiempo, pasa automaticamente a la fase 4.",
         PH_COLS[2]),
        ("Fase 4 -- Procesamiento y guardado",
         "Calcula la aceleracion en g para cada muestra, evalua la integridad de la "
         "captura completa, y guarda los cuatro archivos de salida: _raw.csv, _processed.csv, "
         "_session.json y _summary.txt. Actualiza el panel Resumen con el estado final.",
         PH_COLS[3]),
    ]

    for title, desc, col in phases:
        p.ln(2)
        x0, y0 = p.l_margin, p.get_y()
        # barra lateral de color de fase
        p.fc(col); p.rect(x0, y0, 3, 26, "F")
        p.set_xy(x0 + 6, y0 + 2)
        p.set_font("Helvetica", "B", 10); p.tc(SB_FG)
        p.cell(0, 6, title, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        p.set_x(x0 + 6)
        p.set_font("Helvetica", "", 9.5); p.tc(T_DARK)
        p.multi_cell(p._epw - 6, 5.5, desc)
        p.ln(2)

    p.warn(
        "IMPORTANTE: Si el precheck falla, NO se generan los archivos _raw.csv ni "
        "_processed.csv. Solo se guarda el _precheck.txt con el diagnostico. "
        "Revise la conexion fisica y vuelva a intentar."
    )

    # ═══════════════════════════════════════════════════════════════════════
    # 4. ESTRUCTURA DE NOMBRES
    # ═══════════════════════════════════════════════════════════════════════
    p.add_page()
    p.chap("4", "Archivos generados -- estructura de nombres")

    p.body(
        "Cada sesion exitosa genera hasta cinco archivos. Todos comparten el mismo "
        "nombre base para que sea facil asociarlos entre si."
    )

    p.sub("Patron de nombre")
    p.code_line("{prefijo}_{nombre_sesion}_{AAAAMMDD}_{HHMMSS}_{tipo}.{ext}")

    parts = [
        ("{prefijo}",
         "Identificador del experimento. Por defecto 'sensor_B_live'. "
         "Se puede cambiar en Opciones > Prefijo interno."),
        ("{nombre_sesion}",
         "El valor del campo 'Nombre' en la GUI. Por defecto 'live'. "
         "Cambialo para distinguir ensayos: 'estatico', 'vibracion', 'ensayo3', etc."),
        ("{AAAAMMDD}",
         "Fecha en que se inicio la captura. Ejemplo: 20260412 = 12 de abril de 2026."),
        ("{HHMMSS}",
         "Hora local de inicio en formato 24 h. Ejemplo: 134921 = 1:49:21 PM."),
        ("{tipo}",
         "Sufijo que indica el contenido: raw, processed, session, summary o precheck."),
        ("{ext}",
         ".csv para raw y processed, .json para session, .txt para los reportes de texto."),
    ]
    for k, v in parts:
        p.ln(1)
        p.set_x(p.l_margin + 4)
        p.set_font("Courier", "B", 9.5); p.tc(T_CODE)
        p.cell(52, 6, k, new_x=XPos.RIGHT, new_y=YPos.TOP)
        p.set_font("Helvetica", "", 9.5); p.tc(T_DARK)
        p.multi_cell(p._epw - 56, 6, v)

    p.sub("Ejemplo completo de un conjunto de archivos")
    for suf in ["raw.csv", "processed.csv", "session.json", "summary.txt", "precheck.txt"]:
        p.code_line(f"sensor_B_live_ensayo1_20260412_134921_{suf}")

    p.sub("Ubicacion de cada archivo")
    p.th([("Sufijo", 45), ("Carpeta destino", 72), ("Contenido", 63)])
    rows = [
        ("_raw.csv",       "data\\raw\\sensor_B_live\\",       "Lecturas crudas del firmware"),
        ("_processed.csv", "data\\processed\\",                "Datos con aceleracion en g"),
        ("_session.json",  "data\\processed\\",                "Metadatos completos"),
        ("_summary.txt",   "reports\\analysis_outputs\\",      "Resumen de calidad"),
        ("_precheck.txt",  "reports\\analysis_outputs\\",      "Diagnostico del precheck"),
    ]
    for i, (s, f, d) in enumerate(rows):
        p.tr([(s, 45, "C", "B"), (f, 72, "", ""), (d, 63, "", "")], alt=i % 2 == 1)

    p.note(
        "Todas las rutas son relativas a la carpeta donde esta el ejecutable. "
        "Si mueves el .exe, mueve tambien las carpetas data\\ y reports\\ para que "
        "los archivos anteriores sigan accesibles desde el nuevo lugar."
    )

    # ═══════════════════════════════════════════════════════════════════════
    # 5. CSV RAW
    # ═══════════════════════════════════════════════════════════════════════
    p.add_page()
    p.chap("5", "Referencia de campos: CSV raw  (_raw.csv)")

    p.body(
        "El archivo raw contiene exactamente lo que mando el firmware, sin calculos adicionales. "
        "Es la fuente primaria y no debe modificarse. Tiene una fila por muestra recibida "
        "de cualquiera de los dos sensores, intercaladas en orden de llegada."
    )
    p.code_line("sensor_id,seq,t_us,wall_s,raw_x,raw_y,raw_z,mv_x,mv_y,mv_z")

    raw_fields = [
        ("sensor_id", "entero",
         "Identificador numerico del sensor. 1 = sensor principal (sensor_B). "
         "2 = sensor secundario (sensor_A). Permite filtrar filas por sensor al analizar."),
        ("seq", "entero",
         "Numero de secuencia enviado por el firmware. Sube de 1 en 1 por sensor. "
         "Si dos filas consecutivas del mismo sensor_id tienen seq no consecutivos "
         "(salto > 1), hubo perdida de paquetes en esa ventana."),
        ("t_us", "entero",
         "Marca de tiempo del microcontrolador en microsegundos (us). "
         "Es el reloj interno de la ESP32, no el de la PC. "
         "Se usa para calcular la frecuencia de muestreo real y detectar jitter."),
        ("wall_s", "float",
         "Tiempo de pared (reloj de la PC) en segundos desde que llego la primera muestra "
         "de la sesion. Permite alinear los datos con eventos externos (video, otros registros)."),
        ("raw_x", "entero",
         "Lectura ADC cruda del eje X en cuentas (0 a 4095 para ADC de 12 bits). "
         "2048 representa el punto medio (~0 g). "
         "Valores <= 5 o >= 4090 indican saturacion del ADC."),
        ("raw_y", "entero",
         "Lectura ADC cruda del eje Y. Misma logica que raw_x."),
        ("raw_z", "entero",
         "Lectura ADC cruda del eje Z. Misma logica que raw_x."),
        ("mv_x", "float",
         "Tension del eje X en milivoltios convertida desde raw_x. "
         "Formula: mV = raw * (3300 / 4096). "
         "El punto de reposo del ADXL335 es ~1650 mV (mitad de 3.3 V)."),
        ("mv_y", "float",
         "Tension del eje Y en mV. Misma formula que mv_x."),
        ("mv_z", "float",
         "Tension del eje Z en mV. Misma formula que mv_x."),
    ]

    p.th([("Campo", 44), ("Tipo", 24), ("Descripcion", 112)])
    for i, (name, tipo, desc) in enumerate(raw_fields):
        p.tr([(name, 44, "C", "B"), (tipo, 24, "", "I"), (desc, 112, "", "")],
             alt=i % 2 == 1)

    p.note(
        "Saturacion ADC: raw_x, raw_y o raw_z con valor <= 5 o >= 4090 indican que "
        "la senal fisica desborda el rango del convertidor. En ese caso las columnas mv "
        "y g del archivo processed no son confiables para esas muestras."
    )

    # ═══════════════════════════════════════════════════════════════════════
    # 6. CSV PROCESSED
    # ═══════════════════════════════════════════════════════════════════════
    p.add_page()
    p.chap("6", "Referencia de campos: CSV processed  (_processed.csv)")

    p.body(
        "Contiene los mismos 10 campos que el raw mas cuatro columnas adicionales "
        "con la aceleracion estimada en unidades g. "
        "Este es el archivo que se usa normalmente en analisis posteriores."
    )
    p.code_line(
        "sensor_id,seq,t_us,wall_s,raw_x,raw_y,raw_z,mv_x,mv_y,mv_z,"
        "gx_est,gy_est,gz_est,g_norm_est"
    )

    p.body("Los primeros 10 campos son identicos al raw. Los campos adicionales son:")

    proc_extra = [
        ("gx_est", "float",
         "Aceleracion estimada del eje X en g. Formula: gx = (mv_x - bias_x) / sensibilidad_x. "
         "El bias se estima promediando las primeras muestras (ventana de bias). "
         "Un sensor horizontal en reposo deberia dar ~0 g en X e Y."),
        ("gy_est", "float",
         "Aceleracion estimada del eje Y en g. Misma logica que gx_est."),
        ("gz_est", "float",
         "Aceleracion estimada del eje Z en g. Misma logica que gx_est. "
         "Si el sensor esta plano, el eje Z apunta hacia arriba o abajo y "
         "la gravedad (~1 g) deberia aparecer aqui antes de restar el bias."),
        ("g_norm_est", "float",
         "Norma euclidiana: sqrt(gx^2 + gy^2 + gz^2). "
         "Para un sensor en reposo deberia ser ~1.0 g (solo gravedad). "
         "Valores muy alejados de 1.0 indican mal calibrado, movimiento, "
         "saturacion o eje desconectado."),
    ]

    p.th([("Campo", 44), ("Tipo", 24), ("Descripcion", 112)])
    for i, (name, tipo, desc) in enumerate(proc_extra):
        p.tr([(name, 44, "C", "B"), (tipo, 24, "", "I"), (desc, 112, "", "")],
             alt=i % 2 == 1)

    p.sub("Como se calcula el bias y la sensibilidad")
    p.body(
        "La aplicacion no usa calibracion externa en modo por defecto. Aplica un 'bias rapido':"
    )
    steps_g = [
        "Se promedian los primeros N valores de mv de cada eje (ventana de bias). "
        "N = max(freq_hz, 1) * bias_init_s. Con freq=100 Hz y bias_init_s=2 s -> N=200 muestras.",
        "Ese promedio se usa como punto de referencia (bias_mv) por eje.",
        "Sensibilidad nominal: 300 mV/g (valor tipico del ADXL335 a 3.3 V).",
        "gx = (mv_x - bias_x) / 300. Identico para Y y Z.",
        "Los valores bias_mv y sens_mv_per_g usados quedan registrados en el _summary.txt.",
    ]
    for i, s in enumerate(steps_g, 1):
        p.set_font("Helvetica", "B", 10); p.tc(CH_ACC)
        p.set_x(p.l_margin + 4); p.cell(8, 6, f"{i}.", new_x=XPos.RIGHT, new_y=YPos.TOP)
        p.set_font("Helvetica", "", 10); p.tc(T_DARK)
        p.multi_cell(p._epw - 12, 6, s); p.ln(1)

    # ═══════════════════════════════════════════════════════════════════════
    # 7. JSON
    # ═══════════════════════════════════════════════════════════════════════
    p.add_page()
    p.chap("7", "Referencia de campos: JSON de sesion  (_session.json)")

    p.body(
        "Contiene los metadatos completos de la sesion en formato estructurado. "
        "Es util para procesar resultados programaticamente o reproducir exactamente "
        "las mismas condiciones de captura. Se puede abrir con cualquier editor de texto."
    )

    json_rows = [
        ("config",
         "Toda la configuracion usada: puerto, baud, duracion, prefijo, carpetas, "
         "sensibilidad y parametros del precheck. Replica exactamente lo configurado en la GUI."),
        ("port_resolution",
         "Como se selecciono el puerto: modo (auto/manual/sonda), puerto final, "
         "inventario de todos los COM disponibles y resultados de sonda por cada uno."),
        ("metadata_lines",
         "Lista de comentarios del firmware (lineas que empiezan con #) recibidos al inicio. "
         "Contienen version del firmware y configuracion del hardware en la ESP32."),
        ("header_seen",
         "true si el firmware envio la cabecera CSV antes de los datos. "
         "false puede indicar que la ESP32 ya transmitia cuando la app se conecto."),
        ("invalid_lines",
         "Lineas recibidas que no pudieron parsearse como datos validos. "
         "Valor bajo (<10) es normal. Valor alto sugiere ruido en la linea serial o firmware incompatible."),
        ("seq_jumps",
         "Saltos de secuencia en el sensor principal durante la captura. "
         "Cada salto representa paquetes perdidos entre ESP32 y PC."),
        ("stream_duration_s",
         "Duracion real de la captura en segundos segun el reloj de la PC. "
         "Puede diferir ligeramente de la duracion configurada."),
        ("freq_hz",
         "Frecuencia de muestreo total estimada en muestras/s (ambos sensores combinados). "
         "Para dual a ~100 Hz por sensor, el valor esperado es ~200 Hz."),
        ("sensor_summaries",
         "Lista con resumen de calidad por sensor: muestras, frecuencia, saltos, "
         "mediana de |g|, saturacion, estado y razon. Un elemento por sensor_id presente."),
        ("capture_integrity",
         "Resultado del analisis de integridad post-captura. Mismo criterio que el precheck "
         "pero aplicado sobre la captura real, no sobre la ventana de calentamiento."),
        ("primary_g_info",
         "Informacion del calculo de aceleracion del sensor principal: ruta de calculo, "
         "bias_mv aplicado, sensibilidad mv/g y numero de muestras usadas para el bias."),
        ("artifacts",
         "Rutas relativas de todos los archivos generados. Permite saber exactamente que "
         "archivos pertenecen a esta sesion sin depender de patrones de nombre."),
    ]

    p.th([("Clave JSON", 52), ("Descripcion", 128)])
    for i, (key, desc) in enumerate(json_rows):
        p.tr([(f'"{key}"', 52, "C", "B"), (desc, 128, "", "")], alt=i % 2 == 1)

    p.note(
        "Para leer el JSON desde Python: "
        "import json; data = json.load(open('..._session.json', encoding='utf-8'))\n"
        "Luego accede a cada campo: data['config']['duration_s'], data['freq_hz'], etc."
    )

    # ═══════════════════════════════════════════════════════════════════════
    # 8. PRECHECK TXT
    # ═══════════════════════════════════════════════════════════════════════
    p.add_page()
    p.chap("8", "Referencia de campos: reporte precheck  (_precheck.txt)")

    p.body(
        "Texto plano con formato clave: valor. Se genera siempre que se ejecuta el precheck, "
        "independientemente de si la sesion continua o no. "
        "Sirve para diagnosticar problemas sin necesidad de abrir el JSON."
    )

    precheck_fields = [
        ("script",                     "Origen: 'gui/adxl_live_gui.py' indica que fue generado por la app de escritorio."),
        ("phase",                      "Siempre 'dual_integrity_precheck' en este archivo."),
        ("requested_port",             "Puerto pedido por el usuario. '(auto)' si se dejo en automatico."),
        ("port",                       "Puerto COM finalmente usado. Ejemplo: COM4."),
        ("port_resolution_mode",       "Metodo de seleccion: 'preferred_port' (usuario), 'single_port_inventory' (unico COM), 'probe_match' (sonda), 'usb_inventory_hint' (USB unico)."),
        ("port_resolution_detail",     "Descripcion en texto del metodo de seleccion de puerto."),
        ("baud",                       "Velocidad de comunicacion serial en bps (normalmente 115200)."),
        ("precheck_duration_s",        "Duracion en segundos de la ventana de chequeo (por defecto 10.0)."),
        ("samples",                    "Total de muestras recibidas durante el precheck (suma de ambos sensores)."),
        ("invalid_lines_ignored",      "Lineas recibidas que no se pudieron parsear. Deberia ser bajo."),
        ("header_seen",                "'true' si el firmware mando la cabecera CSV antes de los datos."),
        ("precheck_status",            "'pass' = todo correcto. 'fail' = al menos un criterio no se cumplio."),
        ("precheck_reason",            "Codigo(s) que explican el resultado. Ver Seccion 10."),
        ("sensor_N_label",             "Etiqueta del sensor N (1: sensor_B, 2: sensor_A)."),
        ("sensor_N_samples",           "Muestras recibidas del sensor N durante el precheck."),
        ("sensor_N_freq_hz",           "Frecuencia de muestreo estimada del sensor N en Hz."),
        ("sensor_N_seq_jumps",         "Saltos de secuencia en sensor N (paquetes perdidos)."),
        ("sensor_N_seq_backtracks",    "Veces que el numero de secuencia retrocedio. >0 puede indicar reinicio de la ESP32."),
        ("sensor_N_t_backtracks",      "Veces que el timestamp t_us retrocedio. >0 indica reinicio del reloj del MCU."),
        ("sensor_N_max_saturation_pct","Porcentaje maximo de saturacion ADC en cualquier eje (raw<=5 o raw>=4090)."),
        ("sensor_N_max_zero_axis_pct", "Porcentaje de muestras con raw=0 en algun eje. Valor alto -> eje desconectado."),
        ("sensor_N_max_flatline_142_pct","Porcentaje de muestras con mv=142. Puede indicar eje muerto con ese valor fijo."),
        ("sensor_N_g_norm_median",     "Mediana de |g| durante el precheck. En reposo estatico es muy bajo (~0.01) porque el bias elimina la gravedad dentro de la ventana."),
        ("sensor_N_status",            "'pass' o 'fail' para el sensor N individualmente."),
        ("sensor_N_reason",            "Codigo de razon para el sensor N. Ver Seccion 10."),
    ]

    p.th([("Campo", 68), ("Descripcion", 112)])
    for i, (name, desc) in enumerate(precheck_fields):
        p.tr([(name, 68, "C", "B"), (desc, 112, "", "")], alt=i % 2 == 1)

    # ═══════════════════════════════════════════════════════════════════════
    # 9. SUMMARY TXT
    # ═══════════════════════════════════════════════════════════════════════
    p.add_page()
    p.chap("9", "Referencia de campos: reporte summary  (_summary.txt)")

    p.body(
        "Similar al precheck pero describe la captura principal. "
        "Incluye ademas la informacion de calibracion de aceleracion y las rutas "
        "de todos los archivos generados en la sesion."
    )

    summary_fields = [
        ("sensor_id",               "Identificador de texto del experimento. Ejemplo: 'sensor_B'."),
        ("plot_sensor_numeric_id",  "sensor_id numerico del sensor principal (1 = sensor_B)."),
        ("second_sensor_numeric_id","sensor_id numerico del sensor secundario (2 = sensor_A)."),
        ("requested_port",          "Puerto pedido. '(auto)' si se dejo en automatico."),
        ("port",                    "Puerto COM usado en la captura."),
        ("port_resolution_mode",    "Metodo de seleccion del puerto."),
        ("baud",                    "Velocidad serial en bps."),
        ("duration_s",              "Duracion configurada de la captura en segundos."),
        ("session_name",            "Nombre de sesion usado (campo 'Nombre' de la GUI)."),
        ("file_prefix",             "Prefijo del nombre de archivo."),
        ("accel_mode",              "'nominal_quick_g' = sensibilidad nominal 300 mV/g. "
                                    "'provisional_sensorB_g' = sensibilidad personalizada por eje."),
        ("samples",                 "Total de muestras guardadas en la captura."),
        ("stream_duration_s",       "Duracion real de la captura (reloj de la PC) en segundos."),
        ("freq_hz",                 "Frecuencia total de muestreo en Hz (ambos sensores)."),
        ("seq_jumps",               "Saltos de secuencia en el sensor principal durante la captura."),
        ("invalid_lines_ignored",   "Lineas no parseables durante la captura."),
        ("header_seen",             "'true' si el firmware envio la cabecera CSV."),
        ("capture_integrity_status","'pass' o 'fail' del analisis post-captura."),
        ("capture_integrity_reason","Codigo(s) de razon del analisis post-captura. Ver Seccion 10."),
        ("bias_mv",                 "Bias estimado en mV para X, Y, Z del sensor principal, separados por comas."),
        ("sens_mv_per_g",           "Sensibilidad usada en mV/g para X, Y, Z, separados por comas."),
        ("sensor_N_label",          "Etiqueta del sensor N."),
        ("sensor_N_samples",        "Muestras capturadas del sensor N."),
        ("sensor_N_freq_hz",        "Frecuencia de muestreo del sensor N en Hz."),
        ("sensor_N_seq_jumps",      "Saltos de secuencia en la captura del sensor N."),
        ("sensor_N_g_norm_median",  "Mediana de |g| durante la captura. En reposo ~1.0 g."),
        ("sensor_N_max_saturation_pct","Saturacion maxima en la captura. >20% = senal fuera de rango."),
        ("sensor_N_logic_status",   "'pass', 'suspect' o 'fail' de la calidad de la captura por sensor."),
        ("sensor_N_logic_reason",   "Codigo de razon de calidad. Ver Seccion 10."),
        ("raw_csv_relpath",         "Ruta relativa al archivo _raw.csv de esta sesion."),
        ("processed_csv_relpath",   "Ruta relativa al archivo _processed.csv."),
        ("session_json_relpath",    "Ruta relativa al archivo _session.json."),
        ("precheck_txt_relpath",    "Ruta relativa al archivo _precheck.txt de esta sesion."),
        ("summary_txt_relpath",     "Ruta relativa a este mismo archivo _summary.txt."),
        ("next_block_input_relpath","Mismo valor que processed_csv_relpath. Indica el archivo de entrada para el siguiente bloque de analisis."),
    ]

    p.th([("Campo", 68), ("Descripcion", 112)])
    for i, (name, desc) in enumerate(summary_fields):
        p.tr([(name, 68, "C", "B"), (desc, 112, "", "")], alt=i % 2 == 1)

    # ═══════════════════════════════════════════════════════════════════════
    # 10. CODIGOS DE ESTADO Y RAZON
    # ═══════════════════════════════════════════════════════════════════════
    p.add_page()
    p.chap("10", "Codigos de estado y razon -- interpretacion completa")

    p.body(
        "Los archivos de texto y el JSON usan codigos estandarizados en los campos "
        "status, logic_status, precheck_status y los campos _reason. "
        "La siguiente tabla explica cada codigo, su significado y la accion recomendada."
    )

    p.sub("Codigos de estado")
    p.th([("Codigo", 30), ("Significado", 74), ("Accion recomendada", 76)])
    status_rows = [
        ("pass",      S_PASS,  "Todos los criterios superados.",                          "Ninguna. La sesion es valida y los datos son confiables."),
        ("suspect",   S_SUSP,  "Datos fuera del rango ideal pero no descartados.",        "Repetir la sesion. Usar los datos con precaucion."),
        ("fail",      S_FAIL,  "Al menos un criterio critico no se cumplio.",             "No usar estos datos. Ver razon y corregir el problema."),
        ("completed", S_NEUT,  "Sesion finalizada normalmente (indicador GUI).",          "Ninguna."),
        ("cancelled", S_SUSP,  "Sesion cancelada por el usuario (indicador GUI).",        "Ninguna."),
        ("error",     S_FAIL,  "Error inesperado del sistema.",                           "Revisar la conexion y reiniciar la aplicacion."),
    ]
    for i, (code, color, meaning, action) in enumerate(status_rows):
        # campo codigo con color de estado
        p.set_font("Courier", "B", 9)
        bg = ROW_B if i % 2 == 1 else ROW_A
        p.fc(bg); p.tc(color)
        x0, y0 = p.l_margin, p.get_y()
        # calcular altura de fila
        p.set_font("Helvetica", "", 9)
        ls1 = p.multi_cell(74 - 4, 5, meaning, dry_run=True, output="LINES")
        ls2 = p.multi_cell(76 - 4, 5, action,  dry_run=True, output="LINES")
        row_h = max(len(ls1), len(ls2), 1) * 5 + 4
        p.rect(x0, y0, 180, row_h, "F")
        # codigo
        p.set_font("Courier", "B", 9); p.tc(color)
        p.set_xy(x0 + 2, y0 + 2); p.cell(26, row_h - 4, code)
        # significado
        p.set_font("Helvetica", "", 9); p.tc(T_DARK)
        p.set_xy(x0 + 30 + 2, y0 + 2); p.multi_cell(70, 5, meaning)
        # accion
        p.set_xy(x0 + 30 + 74 + 2, y0 + 2); p.multi_cell(72, 5, action)
        # borde
        p.dc(ROW_BD); p.line(x0, y0 + row_h, x0 + 180, y0 + row_h)
        p.set_xy(x0, y0 + row_h)

    p.ln(4)
    p.sub("Codigos de razon (campos _reason / logic_reason / precheck_reason)")
    p.th([("Codigo de razon", 60), ("Estado", 22), ("Significado y como actuar", 98)])

    reason_rows = [
        ("dual_integrity_ok",          "pass",    S_PASS,
         "Ambos sensores superaron todos los criterios. Datos listos para usar."),
        ("integrity_ok",               "pass",    S_PASS,
         "El sensor individual supero todos los criterios."),
        ("basic_live_sanity_ok",       "pass",    S_PASS,
         "Verificacion basica de sanidad superada en la captura."),
        ("few_samples",                "fail",    S_FAIL,
         "Menos muestras de las requeridas. Causas: duracion muy corta, ESP32 no transmite, "
         "baud incorrecto, cable desconectado."),
        ("packet_loss_excessive",      "fail",    S_FAIL,
         "Mas del 10% de paquetes perdidos. Causas: cable USB de mala calidad, "
         "interferencia, monitor serial externo abierto, CPU saturada."),
        ("adc_saturation",             "fail",    S_FAIL,
         "Mas del 20% de muestras con raw <= 5 o raw >= 4090 en algun eje. "
         "El sensor esta fisicamente fuera de rango; revisar alimentacion y conexiones."),
        ("g_norm_implausible",         "fail",    S_FAIL,
         "Mediana de |g| fuera de [0.30, 1.70]. El sensor esta muy mal orientado, "
         "hay un eje muerto o la calibracion es incorrecta."),
        ("g_norm_borderline",          "suspect", S_SUSP,
         "Mediana de |g| en zona dudosa [0.30-0.60] o [1.40-1.70]. "
         "Orientacion inusual o perturbacion constante durante la captura."),
        ("low_signal_span",            "suspect", S_SUSP,
         "Variacion menor a 0.5 mV en algun eje durante la captura. "
         "La senal esta casi plana; el sensor puede estar inmovil o tener un problema."),
        ("low_signal_span_static",     "fail",    S_FAIL,
         "En el precheck (sensor en reposo), la senal vario menos de 0.5 mV. "
         "Puede indicar eje muerto o cortocircuito a tierra."),
        ("dead_axis_or_disconnected",  "fail",    S_FAIL,
         "Mas del 95% de muestras con raw=0 o mv=142 en algun eje. "
         "Un eje esta desconectado o en cortocircuito. Revisar soldaduras y cables."),
        ("counter_reset_detected",     "fail",    S_FAIL,
         "El numero de secuencia o el timestamp retrocedio durante la sesion. "
         "La ESP32 se reinicio. Verificar alimentacion y firmware."),
        ("missing_header",             "fail",    S_FAIL,
         "No se recibio la linea de encabezado del CSV del firmware. "
         "Puede ser firmware antiguo o conexion parcial al inicio."),
        ("precheck_disabled",          "--",      S_NEUT,
         "El precheck fue desactivado manualmente (modo especial de captura)."),
        ("sensor_missing",             "fail",    S_FAIL,
         "No se recibio ninguna muestra de ese sensor_id. "
         "Revisar la conexion fisica del ADXL335 al ADC de la ESP32."),
        ("not_run",                    "--",      S_NEUT,
         "El componente aun no se ha ejecutado (estado inicial de la GUI)."),
    ]

    for i, (code, status, color, desc) in enumerate(reason_rows):
        bg = ROW_B if i % 2 == 1 else ROW_A
        x0, y0 = p.l_margin, p.get_y()
        p.set_font("Helvetica", "", 9)
        ls = p.multi_cell(94, 5, desc, dry_run=True, output="LINES")
        row_h = max(len(ls), 1) * 5 + 4
        p.fc(bg); p.rect(x0, y0, 180, row_h, "F")
        # codigo
        p.set_font("Courier", "B", 8.5); p.tc(T_CODE)
        p.set_xy(x0 + 2, y0 + 2); p.cell(56, row_h - 4, code)
        # status badge
        p.set_font("Helvetica", "B", 8); p.tc(color)
        p.set_xy(x0 + 60 + 2, y0 + 2 + (row_h - 6) / 2)
        p.cell(18, 6, status, align="C")
        # descripcion
        p.set_font("Helvetica", "", 9); p.tc(T_DARK)
        p.set_xy(x0 + 60 + 22 + 2, y0 + 2); p.multi_cell(94, 5, desc)
        # borde
        p.dc(ROW_BD); p.line(x0, y0 + row_h, x0 + 180, y0 + row_h)
        p.set_xy(x0, y0 + row_h)

    # ═══════════════════════════════════════════════════════════════════════
    # 11. FAQ
    # ═══════════════════════════════════════════════════════════════════════
    p.add_page()
    p.chap("11", "Preguntas frecuentes y solucion de problemas")

    faqs = [
        ("La app dice 'No se encontro el equipo'.",
         "La ESP32 no esta conectada o Windows no instalo el driver. "
         "Verifica en Administrador de dispositivos que aparece un puerto COM al conectar el USB. "
         "Si no aparece, instala el driver CH340 o CP210x manualmente."),
        ("El precheck falla con 'sensor_missing'.",
         "La ESP32 esta conectada pero no llegan datos del sensor que falta. "
         "Verifica las conexiones fisicas del ADXL335: alimentacion 3.3 V, "
         "pines XOUT, YOUT, ZOUT a los pines ADC correctos de la ESP32."),
        ("El precheck falla con 'packet_loss_excessive'.",
         "Demasiados paquetes perdidos. Prueba: cambiar el cable USB, cerrar otras "
         "aplicaciones que usen el puerto serial (Arduino IDE, monitor serial), "
         "y asegurarte de que solo la app este leyendo el COM."),
        ("Los archivos se guardan en un lugar inesperado.",
         "Los datos se guardan siempre junto al .exe. Si moviste el ejecutable a otra "
         "carpeta, los nuevos datos iran a esa nueva ubicacion. Los datos anteriores "
         "permanecen donde estaban."),
        ("g_norm_median es ~0.01 en precheck pero ~1.0 en summary. Es normal?",
         "Si, es el comportamiento esperado. En el precheck el sensor esta en reposo "
         "y el bias se estima durante esa misma ventana, restando la gravedad estatica. "
         "Por eso |g| en precheck es casi 0. En el summary, el bias se estima sobre las "
         "primeras muestras de la captura; si el sensor no estuvo quieto al inicio el "
         "bias no cancela la gravedad y el resultado es ~1.0 g."),
        ("Cuantas sesiones puedo guardar?",
         "No hay limite en la app. El limite es el espacio en disco. "
         "Cada sesion de 60 s genera aproximadamente 1 a 3 MB entre todos los archivos."),
        ("Puedo abrir los CSV en Excel?",
         "Si. Son CSV estandar con separador de coma. En Excel: Datos -> Obtener datos "
         "-> Desde texto/CSV, selecciona el archivo y usa coma como delimitador."),
        ("Que diferencia hay entre raw y processed?",
         "raw contiene solo las lecturas directas del firmware (ADC y mV). "
         "processed agrega gx_est, gy_est, gz_est y g_norm_est (aceleracion en g). "
         "Para analisis mecanico usa processed. raw es util para verificar "
         "que el ADC no esta saturado."),
        ("Para que sirve el _session.json?",
         "Contiene todos los parametros de configuracion y los resultados de calidad "
         "en formato estructurado. Util si necesitas procesar resultados con Python: "
         "data = json.load(open('..._session.json', encoding='utf-8'))"),
        ("Puedo usar la app con un solo sensor?",
         "Si. Si solo hay un sensor conectado, el sensor secundario tendra status 'fail' "
         "y razon 'sensor_missing'. Los datos del sensor principal se guardan correctamente. "
         "El precheck dual fallara si espera ambos; en ese caso puedes ajustar la duracion "
         "del precheck a 0 en Opciones para saltarlo."),
    ]

    for q, a in faqs:
        p.ln(3)
        p.set_font("Helvetica", "B", 10); p.tc(SB_FG)
        p.set_x(p.l_margin + 2)
        p.multi_cell(p._epw - 4, 6, f"P: {q}")
        p.set_x(p.l_margin + 6)
        p.set_font("Helvetica", "", 9.5); p.tc(T_DARK)
        p.multi_cell(p._epw - 8, 5.5, f"R: {a}")
        p.dc(ROW_BD); p.set_line_width(0.2)
        p.line(p.l_margin, p.get_y() + 1, p.l_margin + p._epw, p.get_y() + 1)


# ── main ────────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    pdf = PDF()
    build(pdf)
    pdf.output(str(OUTPUT))
    size_kb = OUTPUT.stat().st_size / 1024
    print(f"PDF generado: {OUTPUT}  ({size_kb:.0f} KB)")

"""The dark Steam-style palette and the Qt stylesheet built from it.

Colours are lifted from the PowerShell version's FromArgb calls so the port
looks identical to the original WinForms window.
"""
from __future__ import annotations

# Surfaces
BG_WINDOW = "#0b0f19"
BG_HEADER = "#0f1626"
BG_PANEL = "#121a2a"
BG_INPUT = "#0a101c"
BG_SUNKEN = "#0a0f1a"
BG_GAME_HEADER = "#0c121e"
BG_FOOTER = "#080c16"

# Text
FG_PRIMARY = "#ffffff"
FG_MUTED = "#aabed7"
FG_HEADING = "#8fc8ff"
FG_INFO = "#aacdff"

# Accents
ACCENT_GREEN = "#76b900"          # NVIDIA green: install action, inspector rule
ACCENT_GREEN_TEXT = "#76e17d"     # Direct mode / success
ACCENT_BLUE = "#64b4ff"           # OptiScaler bridge mode
ACCENT_PURPLE = "#b48cff"         # Universal Feeder mode
ACCENT_AMBER = "#ffcd5a"          # Warnings, "already installed"
ACCENT_RED = "#ff6e6e"            # Errors, restore action
ACCENT_PATH = "#82e68c"           # Injection folder text
ACCENT_EXE = "#82d7ff"            # Executable name text

# Buttons
BTN_BLUE = "#2369b4"
BTN_BLUE_HOVER = "#2f7fd0"
BTN_GREEN = "#237823"
BTN_GREEN_HOVER = "#2d912d"
BTN_RED = "#a33030"
BTN_RED_HOVER = "#c03a3a"
BTN_SLATE = "#28466f"
BTN_SLATE_HOVER = "#35598c"
BTN_DISABLED = "#1a2438"

BORDER = "#23324f"
BORDER_FOCUS = "#3d6fb4"

# Log levels mapped onto their display colour.
LOG_COLORS = {
    "INFO": FG_INFO,
    "OK": ACCENT_GREEN_TEXT,
    "WARN": ACCENT_AMBER,
    "ERROR": ACCENT_RED,
}

# Level tags are symbols plus an English abbreviation, so the log reads the
# same in every interface language rather than mixing one in.
LOG_PREFIXES = {
    "INFO": "[i INFO]    ",
    "OK": "[✓ OK]      ",
    "WARN": "[! WARN]    ",
    "ERROR": "[✗ ERROR]   ",
}

STYLESHEET = f"""
QWidget {{
    background-color: {BG_WINDOW};
    color: #dcdcdc;
    font-family: "Segoe UI", "Noto Sans", sans-serif;
    font-size: 9.5pt;
}}

QFrame#Header {{
    background-color: {BG_HEADER};
    border-left: 6px solid {ACCENT_GREEN};
}}
QLabel#Eyebrow {{
    color: {ACCENT_GREEN};
    font-size: 8pt;
    font-weight: 600;
}}
QLabel#Title {{
    color: {FG_PRIMARY};
    font-size: 21pt;
    font-weight: 700;
}}
QLabel#Subtitle {{
    color: {FG_MUTED};
    font-size: 8.5pt;
}}

QFrame#Panel {{
    background-color: {BG_PANEL};
    border: none;
}}
QFrame#InspectorPanel {{
    background-color: {BG_PANEL};
    border-left: 4px solid {ACCENT_GREEN};
}}
QFrame#GameHeaderBox {{
    background-color: {BG_GAME_HEADER};
}}
QLabel#PanelHeading {{
    color: {FG_HEADING};
    font-weight: 600;
}}
QLabel#GameTitle {{
    color: {FG_PRIMARY};
    font-size: 13pt;
    font-weight: 700;
}}
QLabel#GameBadge {{
    color: {ACCENT_GREEN_TEXT};
    font-weight: 600;
}}
QLabel#FieldLabel {{
    color: {FG_MUTED};
}}
QLabel#FieldLabelGreen {{
    color: {ACCENT_GREEN};
    font-weight: 600;
}}
QLabel#FieldLabelBlue {{
    color: {FG_HEADING};
}}
QLabel#FieldLabelAmber {{
    color: {ACCENT_AMBER};
    font-weight: 600;
}}
QLabel#Footer {{
    color: #6f88ab;
    font-size: 8pt;
}}

QFrame#ReminderBox {{
    background-color: #1a1508;
    border-left: 4px solid {ACCENT_AMBER};
}}
QLabel#ReminderHeader {{
    font-weight: 700;
    background: transparent;
}}
QLabel#ReminderText {{
    color: #e6d8b0;
    background: transparent;
}}

QLineEdit {{
    background-color: {BG_INPUT};
    color: {FG_PRIMARY};
    border: 1px solid {BORDER};
    padding: 5px 7px;
    min-height: 18px;
    selection-background-color: {BTN_BLUE};
}}
QLineEdit:focus {{
    border: 1px solid {BORDER_FOCUS};
}}
QLineEdit[readOnly="true"] {{
    color: {FG_MUTED};
}}
QLineEdit#InjectPath {{
    color: {ACCENT_PATH};
}}
QLineEdit#ExeName {{
    color: {ACCENT_EXE};
}}

QComboBox {{
    background-color: {BG_INPUT};
    color: {FG_PRIMARY};
    border: 1px solid {BORDER};
    padding: 5px 8px;
    min-height: 20px;
}}
QComboBox:hover {{
    border: 1px solid {BORDER_FOCUS};
}}
QComboBox::drop-down {{
    border: none;
    width: 22px;
}}
QComboBox::down-arrow {{
    image: none;
    border-left: 5px solid transparent;
    border-right: 5px solid transparent;
    border-top: 6px solid {FG_MUTED};
    margin-right: 8px;
}}
QComboBox QAbstractItemView {{
    background-color: {BG_INPUT};
    color: {FG_PRIMARY};
    border: 1px solid {BORDER_FOCUS};
    selection-background-color: {BTN_BLUE};
    outline: none;
}}

QTreeWidget {{
    background-color: {BG_SUNKEN};
    alternate-background-color: #0c1220;
    color: {FG_PRIMARY};
    border: 1px solid {BORDER};
    outline: none;
}}
QTreeWidget::item {{
    padding: 4px 2px;
    border: none;
}}
QTreeWidget::item:selected {{
    background-color: {BTN_BLUE};
    color: {FG_PRIMARY};
}}
QTreeWidget::item:hover:!selected {{
    background-color: #16233a;
}}
QHeaderView::section {{
    background-color: #162034;
    color: {FG_HEADING};
    border: none;
    border-right: 1px solid {BORDER};
    border-bottom: 1px solid {BORDER};
    padding: 5px 6px;
    font-weight: 600;
}}

QPlainTextEdit#StatusLog {{
    background-color: #060a12;
    color: {FG_INFO};
    border: 1px solid {BORDER};
    font-family: Consolas, "Cascadia Mono", monospace;
    font-size: 9pt;
}}

QPushButton {{
    background-color: {BTN_SLATE};
    color: {FG_PRIMARY};
    border: none;
    padding: 8px 14px;
    font-weight: 600;
}}
QPushButton:hover {{ background-color: {BTN_SLATE_HOVER}; }}
QPushButton:disabled {{ background-color: {BTN_DISABLED}; color: #5a6784; }}

QPushButton#Primary {{ background-color: {BTN_BLUE}; }}
QPushButton#Primary:hover {{ background-color: {BTN_BLUE_HOVER}; }}

QPushButton#Install {{
    background-color: {BTN_GREEN};
    font-size: 10.5pt;
}}
QPushButton#Install:hover {{ background-color: {BTN_GREEN_HOVER}; }}

QPushButton#Danger {{ background-color: {BTN_RED}; }}
QPushButton#Danger:hover {{ background-color: {BTN_RED_HOVER}; }}

QCheckBox {{ color: {FG_MUTED}; spacing: 7px; }}
QCheckBox::indicator {{
    width: 15px; height: 15px;
    border: 1px solid {BORDER_FOCUS};
    background-color: {BG_INPUT};
}}
QCheckBox::indicator:checked {{
    background-color: {ACCENT_GREEN};
    border: 1px solid {ACCENT_GREEN};
    /* Qt draws no glyph for a styled indicator, so mark it with an image. */
    image: url(data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAxNiAxNiI+PHBhdGggZmlsbD0ibm9uZSIgc3Ryb2tlPSIjMGIwZjE5IiBzdHJva2Utd2lkdGg9IjIuNSIgc3Ryb2tlLWxpbmVjYXA9InJvdW5kIiBzdHJva2UtbGluZWpvaW49InJvdW5kIiBkPSJNMy41IDguNWwzIDMgNi02Ii8+PC9zdmc+);
}}
QCheckBox::indicator:hover {{
    border: 1px solid {ACCENT_GREEN};
}}

QProgressBar {{
    background-color: {BG_INPUT};
    border: 1px solid {BORDER};
    text-align: center;
    color: {FG_PRIMARY};
    height: 22px;
}}
QProgressBar::chunk {{ background-color: {ACCENT_GREEN}; }}

QScrollBar:vertical {{
    background: {BG_SUNKEN}; width: 12px; margin: 0;
}}
QScrollBar::handle:vertical {{
    background: #2a3a5a; min-height: 24px;
}}
QScrollBar::handle:horizontal {{
    background: #2a3a5a; min-width: 24px;
}}
QScrollBar:horizontal {{
    background: {BG_SUNKEN}; height: 12px; margin: 0;
}}
QScrollBar::add-line, QScrollBar::sub-line {{ height: 0; width: 0; }}
QScrollBar::add-page, QScrollBar::sub-page {{ background: none; }}

QToolTip {{
    background-color: {BG_HEADER};
    color: {FG_PRIMARY};
    border: 1px solid {BORDER_FOCUS};
    padding: 4px;
}}

QMessageBox {{ background-color: {BG_PANEL}; }}
QMessageBox QLabel {{ color: {FG_PRIMARY}; }}
"""

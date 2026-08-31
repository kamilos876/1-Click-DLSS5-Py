"""The diagnostics log must follow the selected interface language.

Core code used to build Portuguese sentences directly, so an English or Polish
user still saw Portuguese in the log. It now emits message keys instead.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

# Must precede any `ui` import: it redirects the cache away from the
# user's real library.
import isolation  # noqa: E402,F401

from PySide6.QtCore import QTimer
from PySide6.QtWidgets import QApplication

from core.detection import DetectionError, resolve_game_target
from core.messages import EN, PL, PT, msg, render
from ui import theme
from ui.main_window import MainWindow

TABLES = {"EN": EN, "PL": PL, "PT": PT}


def check_key_parity() -> list[str]:
    """Every language must define the same message keys."""
    problems = []
    for code, table in TABLES.items():
        missing = set(EN) - set(table)
        extra = set(table) - set(EN)
        if missing:
            problems.append(f"{code} missing keys: {sorted(missing)}")
        if extra:
            problems.append(f"{code} unknown keys: {sorted(extra)}")
    return problems


def check_placeholders() -> list[str]:
    """A key's placeholders must match across languages."""
    import re

    field_re = re.compile(r"\{(\d+)\}")
    problems = []
    for key, english in EN.items():
        expected = sorted(field_re.findall(english))
        for code, table in TABLES.items():
            got = sorted(field_re.findall(table[key]))
            if got != expected:
                problems.append(f"{key}: {code}{got} != EN{expected}")
    return problems


def check_detection_error_translates() -> list[str]:
    """A core error must render differently per language."""
    problems = []
    try:
        resolve_game_target(r"Z:\definitely\not\here")
    except DetectionError as err:
        rendered = {code: render(err.message, code) for code in TABLES}
        if len(set(rendered.values())) != len(TABLES):
            problems.append(f"error text not translated: {rendered}")
        if "nao existe" in rendered["EN"]:
            problems.append("English error still Portuguese")
    else:
        problems.append("expected a DetectionError")
    return problems


def check_window_log(app: QApplication) -> list[str]:
    """write_status must render into the language selected at the time."""
    problems = []
    window = MainWindow()
    window.show()

    for code in ("EN", "PL", "PT"):
        window._set_language(code)
        window.log.clear()
        window.write_status(msg("RestoreDone"), "OK")
        text = window.log.toPlainText()
        expected = TABLES[code]["RestoreDone"]
        if expected not in text:
            problems.append(f"{code}: log shows {text.strip()!r}, expected {expected!r}")

    # A plain string still passes through untouched.
    window.log.clear()
    window.write_status("literal text", "INFO")
    if "literal text" not in window.log.toPlainText():
        problems.append("plain strings no longer reach the log")

    window.close()
    return problems


def main() -> int:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    app = QApplication([])
    app.setStyleSheet(theme.STYLESHEET)

    problems: list[str] = []
    problems += check_key_parity()
    problems += check_placeholders()
    problems += check_detection_error_translates()

    result = {"problems": []}

    def run() -> None:
        result["problems"] = check_window_log(app)
        app.quit()

    QTimer.singleShot(300, run)
    app.exec()
    problems += result["problems"]

    if problems:
        print("  FAIL")
        for line in problems:
            print("          ", line)
        return 1

    print(f"  PASS  log language: {len(EN)} keys x {len(TABLES)} languages")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

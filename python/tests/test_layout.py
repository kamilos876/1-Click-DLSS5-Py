"""Guard against the inspector being squeezed until its text clips.

Qt shrinks widgets below their sizeHint when a panel has too little height,
which silently cuts label and field text in half. The window must always be
tall enough that every inspector control gets its full height.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

# Must precede any `ui` import: it redirects the cache away from the
# user's real library.
import isolation  # noqa: E402,F401

from PySide6.QtCore import QTimer
from PySide6.QtWidgets import QApplication

from ui import theme
from ui.main_window import MainWindow


def _check(window: MainWindow) -> list[str]:
    """Return a problem list; empty means the layout is sound."""
    problems: list[str] = []

    controls = {
        "lbl_root": window.lbl_root,
        "txt_root": window.txt_root,
        "lbl_inject": window.lbl_inject,
        "txt_inject": window.txt_inject,
        "lbl_exe": window.lbl_exe,
        "txt_exe": window.txt_exe,
        "lbl_mode": window.lbl_mode,
        "combo_mode": window.combo_mode,
        "lbl_payload": window.lbl_payload,
        "txt_zip": window.txt_zip,
    }

    for name, widget in controls.items():
        height = widget.geometry().height()
        wanted = widget.sizeHint().height()
        if height < wanted:
            problems.append(f"{name} clipped: {height}px < {wanted}px needed")

    panel = window.lbl_inspector.parentWidget()
    if panel.height() < panel.minimumSizeHint().height():
        problems.append(
            f"inspector squeezed: {panel.height()}px "
            f"< {panel.minimumSizeHint().height()}px minimum"
        )

    return problems


def main() -> int:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    app = QApplication([])
    app.setStyle("Fusion")
    app.setStyleSheet(theme.STYLESHEET)

    window = MainWindow()
    window.show()

    results: dict[str, list[str]] = {}

    def run() -> None:
        # Both orientations, each at its default and its minimum size.
        for label, stacked in (("side-by-side", False), ("stacked", True)):
            if window.stacked_layout != stacked:
                window._toggle_layout()
            app.processEvents()

            window.resize(window.sizeHint())
            app.processEvents()
            results[f"{label} default"] = _check(window)

            window.resize(window.minimumSize())
            app.processEvents()
            results[f"{label} minimum"] = _check(window)

        window.close()
        app.quit()

    QTimer.singleShot(400, run)
    app.exec()

    failed = False
    for label, problems in results.items():
        if problems:
            failed = True
            print(f"  FAIL  at {label} size:")
            for line in problems:
                print(f"          {line}")
        else:
            print(f"  PASS  at {label} size: no clipped controls")

    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())

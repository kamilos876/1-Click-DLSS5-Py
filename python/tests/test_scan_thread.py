"""Regression test: a scan must finish and leave the UI responsive.

Two bugs this guards against:
  1. The worker kept only in a local variable was garbage collected the moment
     _on_scan returned, so the thread span an empty loop and the dialog hung.
  2. Closing the progress dialog with accept()/deleteLater() from a worker
     signal killed the process.

The window's own slots are left untouched: wrapping them in the test created a
reference cycle that itself stalled the dialog.
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

SETTLE_MS = 12_000


def main() -> int:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    app = QApplication([])
    app.setStyleSheet(theme.STYLESHEET)

    window = MainWindow()
    window.show()
    window.offer_default_folders()
    if not window.library.folders:
        window.library.add_folder(str(Path.home()))
        window._refresh_folder_combo()

    window._on_scan()

    verdict = {"ok": False, "detail": ""}

    def check() -> None:
        thread_running = (
            window._scan_thread is not None and window._scan_thread.isRunning()
        )
        rows = window.tree.topLevelItemCount()

        # A responsive UI still appends to the log.
        before = window.log.toPlainText()
        window.write_status("probe", "INFO")
        responsive = window.log.toPlainText() != before

        if thread_running:
            verdict["detail"] = "scan thread still running (worker collected?)"
        elif window._scan_worker is not None:
            verdict["detail"] = "worker was never released"
        elif not responsive:
            verdict["detail"] = "UI stopped processing events"
        else:
            verdict["ok"] = True
            verdict["detail"] = f"{rows} rows listed, thread released, UI responsive"
        app.quit()

    QTimer.singleShot(SETTLE_MS, check)
    app.exec()

    if verdict["ok"]:
        print(f"  PASS  scan completed: {verdict['detail']}")
        return 0
    print(f"  FAIL  {verdict['detail']}")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())

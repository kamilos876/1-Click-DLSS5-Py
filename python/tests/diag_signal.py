"""Isolate where the scan signal chain stalls: worker -> thread -> UI slot."""
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from PySide6.QtCore import QThread, QTimer
from PySide6.QtWidgets import QApplication

from core.i18n import get_dict
from ui.workers import ScanWorker

MARKS: list[str] = []


def mark(text: str) -> None:
    MARKS.append(f"{time.time() % 1000:7.2f}  {text}")
    print(MARKS[-1], flush=True)


def main() -> int:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    app = QApplication([])

    folder = sys.argv[1] if len(sys.argv) > 1 else r"C:\Program Files\Epic Games"
    mark(f"scanning {folder}")

    worker = ScanWorker([folder], get_dict("PT"))
    thread = QThread()
    worker.moveToThread(thread)

    worker.progress.connect(lambda pct, name: mark(f"progress {pct}% {name}") if pct % 25 == 0 else None)
    worker.finished.connect(lambda games: mark(f"FINISHED signal: {len(games)} games"))
    worker.failed.connect(lambda msg: mark(f"FAILED signal: {msg}"))
    worker.finished.connect(thread.quit)
    worker.failed.connect(thread.quit)
    thread.started.connect(lambda: mark("thread started"))
    thread.started.connect(worker.run)
    thread.finished.connect(lambda: mark("thread finished"))
    thread.finished.connect(app.quit)

    QTimer.singleShot(45_000, lambda: (mark("TIMEOUT - stalled"), app.quit()))
    thread.start()
    app.exec()

    thread.wait(2000)
    got_finish = any("FINISHED signal" in m for m in MARKS)
    got_thread_end = any("thread finished" in m for m in MARKS)
    print()
    print(f"finished signal delivered : {got_finish}")
    print(f"thread finished delivered : {got_thread_end}")
    return 0 if (got_finish and got_thread_end) else 1


if __name__ == "__main__":
    raise SystemExit(main())

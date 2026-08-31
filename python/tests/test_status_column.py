"""The library list's Status column: what each entry reports about itself."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

# Must precede any `ui` import: it redirects the cache away from the
# user's real library.
import isolation  # noqa: E402,F401

from PySide6.QtCore import QTimer
from PySide6.QtWidgets import QApplication

from core import constants as C
from core.i18n import get_dict
from core.library import Library, LibraryEntry
from ui import theme
from ui.main_window import MainWindow

STATE_COLUMN = 2


def _entry(**kwargs) -> LibraryEntry:
    base = dict(
        name="Game",
        path=r"D:\Games\Game",
        badge_key="Badge100",
        order=1,
        exe_name="Game.exe",
        confidence="confirmed",
    )
    base.update(kwargs)
    return LibraryEntry(**base)


def main() -> int:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    app = QApplication([])
    app.setStyleSheet(theme.STYLESHEET)

    window = MainWindow()
    window.show()
    d = get_dict(window.lang)

    cases = [
        ("detected", _entry(), d["StateDetected"]),
        (
            "installed direct",
            _entry(path=r"D:\Games\A", installed_mode=C.MODE_DIRECT),
            d["StateInstalledDirect"],
        ),
        (
            "installed feeder",
            _entry(path=r"D:\Games\B", installed_mode=C.MODE_FEEDER),
            d["StateInstalledFeeder"],
        ),
        (
            "installed bridge",
            _entry(path=r"D:\Games\C", installed_mode=C.MODE_OPTISCALER),
            d["StateInstalledBridge"],
        ),
        (
            "unrecognised",
            _entry(path=r"D:\Games\D", confidence="not_a_game"),
            d["StateUnrecognised"],
        ),
        (
            "no executable",
            _entry(path=r"D:\Games\E", exe_name=""),
            d["StateNoExe"],
        ),
    ]

    library = Library()
    for _label, entry, _expected in cases:
        library.upsert(entry)

    missing = _entry(path=r"D:\Games\Gone")
    missing.missing = True
    library.upsert(missing)
    cases.append(("missing folder", missing, d["StateMissing"]))

    window.library = library
    # Unrecognised rows are hidden by default; show everything for the test.
    window.chk_show_uncertain.setChecked(True)
    window._apply_filter()

    problems: list[str] = []

    def check() -> None:
        rows = {}
        for index in range(window.tree.topLevelItemCount()):
            item = window.tree.topLevelItem(index)
            rows[item.text(0) + "|" + item.text(3)] = item.text(STATE_COLUMN)

        for label, entry, expected in cases:
            key = entry.name + "|" + entry.path
            got = rows.get(key)
            if got is None:
                problems.append(f"{label}: row not listed")
            elif got != expected:
                problems.append(f"{label}: {got!r} != {expected!r}")

        headers = [
            window.tree.headerItem().text(column)
            for column in range(window.tree.columnCount())
        ]
        if headers[STATE_COLUMN] != d["ColState"]:
            problems.append(f"header: {headers[STATE_COLUMN]!r} != {d['ColState']!r}")

        window.close()
        app.quit()

    QTimer.singleShot(400, check)
    app.exec()

    if problems:
        print("  FAIL")
        for line in problems:
            print("          ", line)
        return 1

    print(f"  PASS  status column: {len(cases)} states render correctly")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

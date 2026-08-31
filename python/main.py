"""1 Click DLSS 5 - Universal Neural Game Center (PySide6 edition).

Run with:  python main.py
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from core import constants as C


def _parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="1-click-dlss5",
        description=f"{C.PRODUCT_NAME} v{C.VERSION} - Universal Neural Game Center",
    )
    parser.add_argument(
        "--version", action="version", version=f"{C.PRODUCT_NAME} {C.VERSION}"
    )
    parser.add_argument(
        "--lang",
        choices=["EN", "PL", "PT"],
        default="EN",
        help="interface language (default: EN)",
    )
    parser.add_argument(
        "--game",
        metavar="PATH",
        help="preselect this game folder on startup",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = _parse_args(sys.argv[1:] if argv is None else argv)

    # Imported after argument parsing so --help and --version never start Qt.
    from PySide6.QtGui import QIcon
    from PySide6.QtWidgets import QApplication

    from ui import theme
    from ui.main_window import MainWindow

    app = QApplication(sys.argv[:1])
    app.setApplicationName(C.PRODUCT_NAME)
    app.setApplicationVersion(C.VERSION)
    app.setStyle("Fusion")
    app.setStyleSheet(theme.STYLESHEET)

    if C.ICON_PATH.is_file():
        app.setWindowIcon(QIcon(str(C.ICON_PATH)))

    window = MainWindow()
    if args.lang != window.lang:
        window._set_language(args.lang)
    window.show()

    if args.game:
        window.preselect_folder(args.game)

    return app.exec()


if __name__ == "__main__":
    raise SystemExit(main())

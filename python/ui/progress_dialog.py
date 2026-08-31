"""A modal progress dialog that is safe to drive from a worker thread.

QProgressDialog cannot be used here: when its value reaches the maximum it
runs a nested event loop inside setValue(), and closing it from a slot that was
invoked by a worker thread's signal deadlocks the UI — the bar sits at 100%
and the window stops responding. This is a plain QDialog with a bar, so
updating and closing it are ordinary widget calls with no hidden event loop.
"""
from __future__ import annotations

from PySide6.QtCore import Qt
from PySide6.QtWidgets import (
    QDialog,
    QLabel,
    QProgressBar,
    QVBoxLayout,
    QWidget,
)


class ProgressDialog(QDialog):
    """Modal 'please wait' dialog with a determinate bar."""

    def __init__(self, title: str, parent: QWidget | None = None) -> None:
        super().__init__(parent)
        self.setWindowTitle(title)
        self.setModal(True)
        self.setMinimumWidth(470)
        # No close button: the work cannot be cancelled halfway through.
        self.setWindowFlag(Qt.WindowType.WindowCloseButtonHint, False)
        self.setWindowFlag(Qt.WindowType.WindowContextHelpButtonHint, False)

        layout = QVBoxLayout(self)
        layout.setContentsMargins(20, 18, 20, 18)
        layout.setSpacing(10)

        self._title = QLabel(title)
        self._title.setObjectName("PanelHeading")
        layout.addWidget(self._title)

        self._bar = QProgressBar()
        self._bar.setRange(0, 100)
        self._bar.setValue(0)
        layout.addWidget(self._bar)

        self._detail = QLabel("")
        self._detail.setObjectName("FieldLabel")
        self._detail.setWordWrap(True)
        self._detail.setMinimumHeight(20)
        layout.addWidget(self._detail)

    def update_progress(self, percent: int, label: str) -> None:
        """Move the bar. Safe at 100%, unlike QProgressDialog."""
        self._bar.setValue(max(0, min(percent, 100)))
        self._detail.setText(label)

    def finish(self) -> None:
        """Hide the dialog.

        Only hide() is called: accept() on a modal dialog unwinds Qt's modal
        state from inside a worker-signal slot, and deleteLater() here can free
        the widget while Qt still holds it. The dialog is parented to the
        window, so it is destroyed with it.
        """
        self.hide()

    def reject(self) -> None:
        """Ignore Esc: the operation must run to completion."""

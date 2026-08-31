"""The main window: game library, injection inspector and diagnostics log."""
from __future__ import annotations

from pathlib import Path

from PySide6.QtCore import QSize, Qt, QThread, Signal
from PySide6.QtGui import QBrush, QColor, QIcon
from PySide6.QtWidgets import (
    QApplication,
    QCheckBox,
    QComboBox,
    QFileDialog,
    QFrame,
    QGridLayout,
    QHBoxLayout,
    QHeaderView,
    QLabel,
    QLineEdit,
    QMessageBox,
    QPlainTextEdit,
    QPushButton,
    QSplitter,
    QTreeWidget,
    QTreeWidgetItem,
    QVBoxLayout,
    QWidget,
)

from core import constants as C
from core.detection import DetectionError, detect_upscaler_type, resolve_game_target
from core.elevation import is_admin, needs_elevation, relaunch_as_admin
from core.i18n import LANGUAGES, get_dict, get_guide
from core.library import Library, LibraryEntry
from core.messages import Message, msg, render
from core.installer import (
    InstallError,
    check_compatibility,
    install_dlss5,
    is_installed,
    launch_game,
    uninstall_dlss5,
)
from core.payload import PayloadError, find_embedded_streamline_zip
from core.scanner import DiscoveredGame, default_library_folders
from core.utils import open_in_explorer

from . import theme
from .icons import extract_exe_icon
from .progress_dialog import ProgressDialog
from .workers import InstallWorker, RefreshWorker, ScanWorker


DEFAULT_LANG = "EN"

class MainWindow(QWidget):
    """Top-level window wiring the UI to the core install logic."""

    def __init__(self) -> None:
        super().__init__()
        self.lang = DEFAULT_LANG
        self.library = Library.load()
        self.selected_game: DiscoveredGame | None = None
        self.detected_upscaler: str | None = None
        # Workers must be held on the instance: a local reference is garbage
        # collected as soon as the starting method returns, which leaves the
        # thread running an empty event loop and the progress dialog stuck.
        self._scan_thread: QThread | None = None
        self._scan_worker: ScanWorker | None = None
        self._refresh_thread: QThread | None = None
        self._refresh_worker: RefreshWorker | None = None
        self._install_thread: QThread | None = None
        self._install_worker: InstallWorker | None = None
        self._blank_icon_cache: QIcon | None = None
        self._last_hidden_reported = 0
        # False = library and inspector side by side (the default).
        self.stacked_layout = False

        self.setWindowTitle(
            f"{C.PRODUCT_NAME} v{C.VERSION} • Universal Neural Game Center "
            "• RTX 20/30/40/50"
        )
        self.resize(1360, 1020)
        # _apply_orientation sets the real minimum for the active layout.
        self.setMinimumSize(1120, 990)
        if C.ICON_PATH.is_file():
            self.setWindowIcon(QIcon(str(C.ICON_PATH)))

        self._build_ui()
        self._retranslate()
        self._load_embedded_payload()

    # ---------------------------------------------------------------- layout

    def _build_ui(self) -> None:
        root = QVBoxLayout(self)
        root.setContentsMargins(0, 0, 0, 0)
        root.setSpacing(0)

        root.addWidget(self._build_header())

        body = QVBoxLayout()
        body.setContentsMargins(20, 14, 20, 10)
        body.setSpacing(12)

        body.addLayout(self._build_toolbar())

        # Side by side by default; the toolbar's layout button stacks the two
        # panels instead, which gives each the full window width.
        self.splitter = QSplitter(Qt.Orientation.Horizontal)
        self.splitter.addWidget(self._build_library_panel())
        self.splitter.addWidget(self._build_inspector_panel())
        self.splitter.setChildrenCollapsible(False)
        self._apply_orientation()
        body.addWidget(self.splitter, 1)

        body.addWidget(self._build_log_panel())
        root.addLayout(body, 1)
        root.addWidget(self._build_footer())

    def _build_header(self) -> QWidget:
        header = QFrame()
        header.setObjectName("Header")
        header.setFixedHeight(92)

        layout = QHBoxLayout(header)
        layout.setContentsMargins(24, 12, 20, 12)

        text_column = QVBoxLayout()
        text_column.setSpacing(2)
        self.lbl_eyebrow = QLabel()
        self.lbl_eyebrow.setObjectName("Eyebrow")
        self.lbl_title = QLabel()
        self.lbl_title.setObjectName("Title")
        self.lbl_subtitle = QLabel()
        self.lbl_subtitle.setObjectName("Subtitle")
        for widget in (self.lbl_eyebrow, self.lbl_title, self.lbl_subtitle):
            text_column.addWidget(widget)
        layout.addLayout(text_column, 1)

        self.combo_lang = QComboBox()
        self.combo_lang.setFixedSize(140, 34)
        self.combo_lang.setCursor(Qt.CursorShape.PointingHandCursor)
        # Data holds the language code so the visible labels can be anything.
        for code, label in LANGUAGES:
            self.combo_lang.addItem(label, code)
        self._select_language_in_combo()
        self.combo_lang.currentIndexChanged.connect(self._on_language_changed)

        lang_column = QVBoxLayout()
        lang_column.addWidget(self.combo_lang)
        lang_column.addStretch(1)
        layout.addLayout(lang_column)

        return header

    def _build_toolbar(self) -> QVBoxLayout:
        """Folder bar over a search row: the library is built from folders the
        user nominates, not from whole partitions."""
        column = QVBoxLayout()
        column.setSpacing(8)

        folders = QHBoxLayout()
        folders.setSpacing(8)

        self.lbl_folders = QLabel()
        self.lbl_folders.setObjectName("FieldLabel")
        folders.addWidget(self.lbl_folders)

        self.combo_folders = QComboBox()
        self.combo_folders.setMinimumWidth(320)
        self.combo_folders.setSizeAdjustPolicy(
            QComboBox.SizeAdjustPolicy.AdjustToMinimumContentsLengthWithIcon
        )
        folders.addWidget(self.combo_folders, 1)

        self.btn_add_folder = QPushButton()
        self.btn_add_folder.setObjectName("Primary")
        self.btn_add_folder.clicked.connect(self._on_add_folder)
        folders.addWidget(self.btn_add_folder)

        self.btn_remove_folder = QPushButton()
        self.btn_remove_folder.clicked.connect(self._on_remove_folder)
        folders.addWidget(self.btn_remove_folder)

        column.addLayout(folders)

        actions = QHBoxLayout()
        actions.setSpacing(8)

        self.btn_scan = QPushButton()
        self.btn_scan.setObjectName("Primary")
        self.btn_scan.setFixedWidth(200)
        self.btn_scan.clicked.connect(self._on_scan)
        actions.addWidget(self.btn_scan)

        self.btn_refresh = QPushButton()
        self.btn_refresh.setFixedWidth(190)
        self.btn_refresh.clicked.connect(self._on_refresh)
        actions.addWidget(self.btn_refresh)

        self.txt_search = QLineEdit()
        self.txt_search.textChanged.connect(self._apply_filter)
        actions.addWidget(self.txt_search, 1)

        self.btn_browse = QPushButton()
        self.btn_browse.setFixedWidth(180)
        self.btn_browse.clicked.connect(self._on_browse)
        actions.addWidget(self.btn_browse)

        self.btn_layout = QPushButton()
        self.btn_layout.setFixedWidth(120)
        self.btn_layout.setCursor(Qt.CursorShape.PointingHandCursor)
        self.btn_layout.clicked.connect(self._toggle_layout)
        actions.addWidget(self.btn_layout)

        column.addLayout(actions)
        return column

    def _apply_orientation(self) -> None:
        """Lay the two panels out for the current orientation.

        Side by side each panel takes half the width; stacked they each take
        the full width, which suits long paths and the location column.
        """
        if self.stacked_layout:
            self.splitter.setOrientation(Qt.Orientation.Vertical)
            self.splitter.setStretchFactor(0, 5)
            self.splitter.setStretchFactor(1, 4)
            self.splitter.setSizes([420, 430])
            self.setMinimumSize(1120, 1150)
        else:
            self.splitter.setOrientation(Qt.Orientation.Horizontal)
            self.splitter.setStretchFactor(0, 5)
            self.splitter.setStretchFactor(1, 6)
            self.splitter.setSizes([620, 720])
            # Side by side, the panels no longer stack, so the window can be
            # shorter without clipping the inspector.
            self.setMinimumSize(1120, 990)

    def _toggle_layout(self) -> None:
        self.stacked_layout = not self.stacked_layout
        self._apply_orientation()
        self._update_layout_button()
        # Grow the window if the new orientation needs more room than it has.
        minimum = self.minimumSize()
        self.resize(
            max(self.width(), minimum.width()),
            max(self.height(), minimum.height()),
        )

    def _update_layout_button(self) -> None:
        d = get_dict(self.lang)
        self.btn_layout.setText(d["BtnLayoutToggle"])
        self.btn_layout.setToolTip(
            d["TipLayoutVertical"] if self.stacked_layout else d["TipLayoutHorizontal"]
        )

    def _build_library_panel(self) -> QWidget:
        panel = QFrame()
        panel.setObjectName("Panel")
        layout = QVBoxLayout(panel)
        layout.setContentsMargins(14, 10, 12, 12)
        layout.setSpacing(8)

        heading_row = QHBoxLayout()
        heading_row.setSpacing(10)
        self.lbl_library = QLabel()
        self.lbl_library.setObjectName("PanelHeading")
        heading_row.addWidget(self.lbl_library)
        heading_row.addStretch(1)

        self.chk_show_uncertain = QCheckBox()
        self.chk_show_uncertain.setChecked(False)
        self.chk_show_uncertain.toggled.connect(self._apply_filter)
        heading_row.addWidget(self.chk_show_uncertain)
        layout.addLayout(heading_row)

        self.tree = QTreeWidget()
        self.tree.setColumnCount(4)
        self.tree.setRootIsDecorated(False)
        # A flat list: without this every row is indented for absent children.
        self.tree.setIndentation(0)
        self.tree.setAlternatingRowColors(True)
        self.tree.setIconSize(QSize(22, 22))
        self.tree.setUniformRowHeights(True)
        header = self.tree.header()
        for column in range(3):
            header.setSectionResizeMode(column, QHeaderView.ResizeMode.Interactive)
        header.setSectionResizeMode(3, QHeaderView.ResizeMode.Stretch)
        header.setStretchLastSection(True)
        self.tree.setColumnWidth(0, 240)
        self.tree.setColumnWidth(1, 185)
        self.tree.setColumnWidth(2, 190)
        # Paths are long; let the user read them without resizing columns.
        self.tree.setTextElideMode(Qt.TextElideMode.ElideMiddle)
        self.tree.setMinimumHeight(180)
        self.tree.currentItemChanged.connect(self._on_game_selected)
        layout.addWidget(self.tree, 1)

        return panel

    def _build_inspector_panel(self) -> QWidget:
        panel = QFrame()
        panel.setObjectName("InspectorPanel")
        layout = QVBoxLayout(panel)
        layout.setContentsMargins(18, 8, 18, 10)
        layout.setSpacing(6)

        self.lbl_inspector = QLabel()
        self.lbl_inspector.setObjectName("PanelHeading")
        layout.addWidget(self.lbl_inspector)

        layout.addWidget(self._build_game_header())
        layout.addLayout(self._build_path_fields())
        layout.addWidget(self._build_reminder_box())
        layout.addLayout(self._build_payload_row())
        layout.addLayout(self._build_options_row())
        layout.addStretch(1)
        layout.addLayout(self._build_action_buttons())

        return panel

    def _build_game_header(self) -> QWidget:
        box = QFrame()
        box.setObjectName("GameHeaderBox")
        box.setFixedHeight(64)

        layout = QHBoxLayout(box)
        layout.setContentsMargins(10, 8, 10, 8)
        layout.setSpacing(12)

        self.lbl_game_icon = QLabel()
        self.lbl_game_icon.setFixedSize(44, 44)
        self.lbl_game_icon.setScaledContents(True)
        layout.addWidget(self.lbl_game_icon)

        text_column = QVBoxLayout()
        text_column.setSpacing(2)
        self.lbl_game_title = QLabel()
        self.lbl_game_title.setObjectName("GameTitle")
        self.lbl_game_badge = QLabel()
        self.lbl_game_badge.setObjectName("GameBadge")
        text_column.addWidget(self.lbl_game_title)
        text_column.addWidget(self.lbl_game_badge)
        layout.addLayout(text_column, 1)

        return box

    def _build_path_fields(self) -> QGridLayout:
        grid = QGridLayout()
        grid.setContentsMargins(0, 4, 0, 0)
        grid.setHorizontalSpacing(10)
        # Enough vertical spacing that a label never touches the field above it.
        grid.setVerticalSpacing(9)
        # QGridLayout rounds row heights down when it distributes space, which
        # shaved a pixel off the fields and clipped their text. Pin the rows
        # that hold inputs to the height those inputs actually ask for.
        for row in (1, 3, 5):
            grid.setRowMinimumHeight(row, 31)

        self.lbl_root = QLabel()
        self.lbl_root.setObjectName("FieldLabel")
        grid.addWidget(self.lbl_root, 0, 0, 1, 2)

        self.txt_root = QLineEdit()
        self.txt_root.setReadOnly(True)
        grid.addWidget(self.txt_root, 1, 0, 1, 2)

        self.lbl_inject = QLabel()
        self.lbl_inject.setObjectName("FieldLabelGreen")
        grid.addWidget(self.lbl_inject, 2, 0)

        self.lbl_exe = QLabel()
        self.lbl_exe.setObjectName("FieldLabelBlue")
        grid.addWidget(self.lbl_exe, 2, 1)

        self.txt_inject = QLineEdit()
        self.txt_inject.setObjectName("InjectPath")
        self.txt_inject.setReadOnly(True)
        grid.addWidget(self.txt_inject, 3, 0)

        self.txt_exe = QLineEdit()
        self.txt_exe.setObjectName("ExeName")
        self.txt_exe.setReadOnly(True)
        grid.addWidget(self.txt_exe, 3, 1)

        self.lbl_mode = QLabel()
        self.lbl_mode.setObjectName("FieldLabelAmber")
        grid.addWidget(self.lbl_mode, 4, 0, 1, 2)

        self.combo_mode = QComboBox()
        self.combo_mode.currentIndexChanged.connect(self._update_reminder)
        grid.addWidget(self.combo_mode, 5, 0, 1, 2)

        grid.setColumnStretch(0, 3)
        grid.setColumnStretch(1, 2)
        return grid

    def _build_reminder_box(self) -> QWidget:
        box = QFrame()
        box.setObjectName("ReminderBox")
        box.setMinimumHeight(58)

        layout = QVBoxLayout(box)
        layout.setContentsMargins(12, 8, 12, 8)
        layout.setSpacing(3)

        self.lbl_reminder_header = QLabel()
        self.lbl_reminder_header.setObjectName("ReminderHeader")
        self.lbl_reminder_text = QLabel()
        self.lbl_reminder_text.setObjectName("ReminderText")
        self.lbl_reminder_text.setWordWrap(True)

        layout.addWidget(self.lbl_reminder_header)
        layout.addWidget(self.lbl_reminder_text)
        return box

    def _build_payload_row(self) -> QVBoxLayout:
        column = QVBoxLayout()
        column.setSpacing(5)

        self.lbl_payload = QLabel()
        self.lbl_payload.setObjectName("FieldLabel")
        column.addWidget(self.lbl_payload)

        row = QHBoxLayout()
        row.setSpacing(8)
        self.txt_zip = QLineEdit()
        row.addWidget(self.txt_zip, 1)

        self.btn_change_zip = QPushButton()
        self.btn_change_zip.setFixedWidth(150)
        self.btn_change_zip.clicked.connect(self._on_change_zip)
        row.addWidget(self.btn_change_zip)

        column.addLayout(row)
        return column

    def _build_options_row(self) -> QHBoxLayout:
        row = QHBoxLayout()
        self.chk_reshade = QCheckBox()
        self.chk_reshade.setChecked(True)
        self.chk_full = QCheckBox()
        self.chk_full.setChecked(True)
        row.addWidget(self.chk_reshade)
        row.addStretch(1)
        row.addWidget(self.chk_full)
        return row

    def _build_action_buttons(self) -> QVBoxLayout:
        column = QVBoxLayout()
        column.setSpacing(8)

        top = QHBoxLayout()
        top.setSpacing(10)
        self.btn_install = QPushButton()
        self.btn_install.setObjectName("Install")
        self.btn_install.setFixedHeight(42)
        self.btn_install.clicked.connect(self._on_install)
        self.btn_launch = QPushButton()
        self.btn_launch.setObjectName("Primary")
        self.btn_launch.setFixedHeight(42)
        self.btn_launch.clicked.connect(self._on_launch)
        top.addWidget(self.btn_install, 1)
        top.addWidget(self.btn_launch, 1)
        column.addLayout(top)

        bottom = QHBoxLayout()
        bottom.setSpacing(8)
        self.btn_restore = QPushButton()
        self.btn_restore.setObjectName("Danger")
        self.btn_restore.clicked.connect(self._on_restore)
        self.btn_open = QPushButton()
        self.btn_open.clicked.connect(self._on_open_folder)
        self.btn_guide = QPushButton()
        self.btn_guide.clicked.connect(self._on_guide)
        self.btn_verify = QPushButton()
        self.btn_verify.clicked.connect(self._on_verify)
        for button in (self.btn_restore, self.btn_open, self.btn_guide, self.btn_verify):
            button.setFixedHeight(34)
            bottom.addWidget(button, 1)
        column.addLayout(bottom)

        return column

    def _build_log_panel(self) -> QWidget:
        panel = QFrame()
        panel.setObjectName("Panel")
        panel.setMinimumHeight(110)
        panel.setMaximumHeight(150)

        layout = QVBoxLayout(panel)
        layout.setContentsMargins(14, 10, 14, 12)
        layout.setSpacing(6)

        self.lbl_log = QLabel()
        self.lbl_log.setObjectName("PanelHeading")
        layout.addWidget(self.lbl_log)

        self.log = QPlainTextEdit()
        self.log.setObjectName("StatusLog")
        self.log.setReadOnly(True)
        layout.addWidget(self.log, 1)

        return panel

    def _build_footer(self) -> QWidget:
        footer = QFrame()
        footer.setFixedHeight(30)
        footer.setStyleSheet(f"background-color: {theme.BG_FOOTER};")
        layout = QHBoxLayout(footer)
        layout.setContentsMargins(22, 0, 22, 0)
        self.lbl_footer = QLabel()
        self.lbl_footer.setObjectName("Footer")
        layout.addWidget(self.lbl_footer)
        return footer

    # ------------------------------------------------------------ log output

    def write_status(self, message: "Message | str", level: str = "INFO") -> None:
        """Append one colour-coded line to the diagnostics log.

        Core code emits Message keys rather than sentences, so the text is
        produced here, in whatever language the user has selected.
        """
        message = render(message, self.lang)
        color = theme.LOG_COLORS.get(level, theme.FG_INFO)
        prefix = theme.LOG_PREFIXES.get(level, theme.LOG_PREFIXES["INFO"])
        safe = (
            message.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
        )
        self.log.appendHtml(
            f'<span style="color:{color};white-space:pre">{prefix}{safe}</span>'
        )
        scrollbar = self.log.verticalScrollBar()
        scrollbar.setValue(scrollbar.maximum())

    # -------------------------------------------------------------- language

    def _select_language_in_combo(self) -> None:
        """Point the picker at the active language without re-triggering it."""
        index = self.combo_lang.findData(self.lang)
        self.combo_lang.blockSignals(True)
        self.combo_lang.setCurrentIndex(max(index, 0))
        self.combo_lang.blockSignals(False)

    def _on_language_changed(self, index: int) -> None:
        code = self.combo_lang.itemData(index)
        if code and code != self.lang:
            self._set_language(code)

    def _set_language(self, lang: str) -> None:
        self.lang = lang
        self._retranslate()

    def _retranslate(self) -> None:
        """Apply the active language to every visible string."""
        d = get_dict(self.lang)

        self.lbl_eyebrow.setText(d["Eyebrow"])
        self.lbl_title.setText(d["Title"])
        self.lbl_subtitle.setText(d["Subtitle"])
        self.lbl_folders.setText(d["FoldersLabel"])
        self.btn_add_folder.setText(d["BtnAddFolder"])
        self.btn_remove_folder.setText(d["BtnRemoveFolder"])
        self.btn_scan.setText(d["BtnScanFolders"])
        self.btn_refresh.setText(d["BtnRefresh"])
        self.btn_browse.setText(d["BtnBrowse"])
        self._update_layout_button()
        self.txt_search.setPlaceholderText(d["SearchPlaceholder"])
        self.lbl_library.setText(d["LibraryTitle"])
        self.chk_show_uncertain.setText(d["ShowUncertain"])
        self.lbl_inspector.setText(d["InspectorTitle"])
        self.lbl_root.setText(d["RootFolderLabel"])
        self.lbl_inject.setText(d["InjectFolderLabel"])
        self.lbl_exe.setText(d["TargetExeLabel"])
        self.lbl_mode.setText(d["LblInjectionMode"])
        self.lbl_payload.setText(d["PayloadTitle"])
        self.btn_change_zip.setText(d["BtnChangeZip"])
        self.chk_reshade.setText(d["OptReShade"])
        self.chk_full.setText(d["OptFull"])
        self.btn_install.setText(d["BtnInstall"])
        self.btn_launch.setText(d["BtnLaunch"])
        self.btn_restore.setText(d["BtnUninstall"])
        self.btn_open.setText(d["BtnOpenFolder"])
        self.btn_guide.setText(d["BtnInstructions"])
        self.btn_verify.setText(d["BtnVerify"])
        self.lbl_log.setText(d["StatusHeading"])
        self.lbl_footer.setText(d["Footer"])
        self.tree.setHeaderLabels(
            [d["ColGame"], d["ColStatus"], d["ColState"], d["ColPathShort"]]
        )

        self._select_language_in_combo()

        self._refresh_folder_combo()
        self._apply_filter()

        if self.selected_game is None:
            self.lbl_game_title.setText(d["MsgNoGameTitle"])
            self.lbl_game_badge.setText(d["NoGameSelected"])
            self.lbl_reminder_header.setText(d["ReminderHeader"])
            self.lbl_reminder_text.setText(d["ReminderText"])
        else:
            self._select_game(self.selected_game)

    def offer_default_folders(self) -> int:
        """Seed the folder list with detected store libraries on first run."""
        if self.library.folders:
            return 0

        added = 0
        for folder in default_library_folders():
            if self.library.add_folder(folder):
                added += 1

        if added:
            self.library.save()
            self._refresh_folder_combo()
            self.write_status(get_dict(self.lang)["MsgAddDefaults"].format(added), "OK")
        return added

    def _load_embedded_payload(self) -> None:
        d = get_dict(self.lang)
        embedded = find_embedded_streamline_zip()
        if embedded is not None:
            self.txt_zip.setText(str(embedded))
            self.write_status(d["MsgPayloadLoaded"], "OK")
        else:
            self.write_status(d["MsgPayloadNotFound"], "WARN")

        if self.library.entries:
            # The saved list is already on screen; no scan needed to start.
            self.write_status(
                d["MsgLibraryLoaded"].format(len(self.library.entries)), "OK"
            )
        elif not self.library.folders:
            self.offer_default_folders()
            self.write_status(d["NoFolders"], "INFO")
        else:
            self.write_status(d["MsgLibraryEmpty"], "INFO")

    # ---------------------------------------------------------------- scanning

    # ---------------------------------------------------------------- folders

    def _refresh_folder_combo(self) -> None:
        d = get_dict(self.lang)
        self.combo_folders.blockSignals(True)
        self.combo_folders.clear()
        if self.library.folders:
            self.combo_folders.addItems(self.library.folders)
        else:
            self.combo_folders.addItem(d["NoFolders"])
        self.combo_folders.blockSignals(False)

        has_folders = bool(self.library.folders)
        self.btn_remove_folder.setEnabled(has_folders)
        self.btn_scan.setEnabled(has_folders and self._scan_thread is None)

    def _on_add_folder(self) -> None:
        d = get_dict(self.lang)
        folder = QFileDialog.getExistingDirectory(self, d["DlgSelectScanFolder"])
        if not folder:
            return

        if self.library.add_folder(folder):
            self.library.save()
            self._refresh_folder_combo()
            self.combo_folders.setCurrentText(str(Path(folder)))
            self.write_status(d["FolderAdded"].format(folder), "OK")
        else:
            self.write_status(d["FolderExists"].format(folder), "WARN")

    def _on_remove_folder(self) -> None:
        if not self.library.folders:
            return

        d = get_dict(self.lang)
        folder = self.combo_folders.currentText()
        answer = QMessageBox.question(
            self,
            d["ConfirmRemoveFolderTitle"],
            d["ConfirmRemoveFolder"].format(folder),
            QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No,
        )
        if answer != QMessageBox.StandardButton.Yes:
            return

        self.library.remove_folder(folder)
        self.library.save()
        self._refresh_folder_combo()
        self._apply_filter()
        self.write_status(d["FolderRemoved"].format(folder), "OK")

    # --------------------------------------------------------------- scanning

    def _on_scan(self) -> None:
        if self._scan_thread is not None or not self.library.folders:
            return

        d = get_dict(self.lang)
        self.write_status(
            d["MsgScanningFolders"].format(len(self.library.folders)), "INFO"
        )

        self.btn_scan.setEnabled(False)
        self.btn_refresh.setEnabled(False)
        self.btn_browse.setEnabled(False)

        dialog = self._make_progress_dialog(d["MsgScanProgressTitle"])

        self._scan_worker = ScanWorker(list(self.library.folders), get_dict(self.lang))
        self._scan_thread = QThread(self)
        self._scan_worker.moveToThread(self._scan_thread)

        self._scan_worker.progress.connect(
            lambda pct, name: self._update_progress(dialog, pct, d["MsgScanFolder"].format(name))
        )
        self._scan_worker.finished.connect(lambda games: self._on_scan_done(games, dialog))
        self._scan_worker.failed.connect(lambda msg: self._on_worker_failed(msg, dialog))
        self._scan_worker.finished.connect(self._scan_thread.quit)
        self._scan_worker.failed.connect(self._scan_thread.quit)
        self._scan_thread.started.connect(self._scan_worker.run)
        self._scan_thread.finished.connect(self._on_scan_thread_finished)
        self._scan_thread.start()

    def _make_progress_dialog(self, title: str) -> ProgressDialog:
        """A plain modal dialog with a bar.

        QProgressDialog is deliberately avoided: reaching its maximum spins a
        nested event loop inside setValue, which deadlocks when the value is
        driven from a worker thread's signal.
        """
        dialog = ProgressDialog(title, self)
        dialog.show()
        QApplication.processEvents()
        return dialog

    @staticmethod
    def _update_progress(dialog: ProgressDialog, percent: int, label: str) -> None:
        dialog.update_progress(percent, label)

    @staticmethod
    def _close_progress(dialog: ProgressDialog | None) -> None:
        if dialog is not None:
            dialog.finish()

    def _on_worker_failed(
        self, message: "Message | str", dialog: ProgressDialog | None = None
    ) -> None:
        self._close_progress(dialog)
        self.write_status(message, "ERROR")

    def _on_scan_thread_finished(self) -> None:
        if self._scan_thread is not None:
            self._scan_thread.deleteLater()
        if self._scan_worker is not None:
            self._scan_worker.deleteLater()
        self._scan_thread = None
        self._scan_worker = None
        self.btn_scan.setEnabled(bool(self.library.folders))
        self.btn_refresh.setEnabled(True)
        self.btn_browse.setEnabled(True)

    def _on_scan_done(self, games: list[DiscoveredGame], dialog: ProgressDialog) -> None:
        self._close_progress(dialog)

        found_paths = {str(game.path).lower() for game in games}
        scanned_folders = {str(Path(f)).lower() for f in self.library.folders}

        # Drop stale entries from the folders we just re-scanned: a game that is
        # gone, or one that is now filtered out, must not linger in the list.
        for stale in [
            entry
            for entry in self.library.entries
            if entry.source_folder.lower() in scanned_folders
            and entry.path.lower() not in found_paths
        ]:
            self.library.remove(stale.path)

        for game in games:
            self.library.upsert(
                LibraryEntry(
                    name=game.name,
                    path=str(game.path),
                    badge_key=game.badge_key,
                    order=game.order,
                    exe_name=game.exe_name,
                    exe_path=str(game.icon_source) if game.icon_source else "",
                    source_folder=game.source_folder,
                    confidence=game.confidence,
                    identity_source=game.identity_source,
                    folder_name=game.folder_name,
                    installed_mode=game.installed_mode,
                )
            )
        self.library.save()
        self._apply_filter()

        d = get_dict(self.lang)
        self.write_status(d["MsgScanDone"].format(len(games)), "OK")
        self.write_status(d["MsgLibrarySaved"].format(len(self.library.entries)), "OK")

        if self.tree.topLevelItemCount() > 0:
            self.tree.setCurrentItem(self.tree.topLevelItem(0))

    # -------------------------------------------------------------- refreshing

    def _on_refresh(self) -> None:
        """Re-check every saved game: still installed? still the same status?"""
        if self._refresh_thread is not None or not self.library.entries:
            return

        d = get_dict(self.lang)
        self.write_status(d["MsgRefreshing"], "INFO")

        self.btn_refresh.setEnabled(False)
        self.btn_scan.setEnabled(False)

        dialog = self._make_progress_dialog(d["MsgRefreshTitle"])

        self._refresh_worker = RefreshWorker(self.library)
        self._refresh_thread = QThread(self)
        self._refresh_worker.moveToThread(self._refresh_thread)

        self._refresh_worker.progress.connect(
            lambda pct, name: self._update_progress(dialog, pct, d["MsgScanFolder"].format(name))
        )
        self._refresh_worker.finished.connect(
            lambda result: self._on_refresh_done(result, dialog)
        )
        self._refresh_worker.failed.connect(lambda msg: self._on_worker_failed(msg, dialog))
        self._refresh_worker.finished.connect(self._refresh_thread.quit)
        self._refresh_worker.failed.connect(self._refresh_thread.quit)
        self._refresh_thread.started.connect(self._refresh_worker.run)
        self._refresh_thread.finished.connect(self._on_refresh_thread_finished)
        self._refresh_thread.start()

    def _on_refresh_thread_finished(self) -> None:
        if self._refresh_thread is not None:
            self._refresh_thread.deleteLater()
        if self._refresh_worker is not None:
            self._refresh_worker.deleteLater()
        self._refresh_thread = None
        self._refresh_worker = None
        self.btn_refresh.setEnabled(True)
        self.btn_scan.setEnabled(bool(self.library.folders))

    def _on_refresh_done(self, result, dialog: ProgressDialog) -> None:
        self._close_progress(dialog)

        d = get_dict(self.lang)
        self.library.save()
        self._apply_filter()
        self.write_status(
            d["MsgRefreshDone"].format(len(result.present), len(result.missing)),
            "OK" if not result.missing else "WARN",
        )

        if result.missing:
            answer = QMessageBox.question(
                self,
                d["ConfirmPruneTitle"],
                d["ConfirmPrune"].format(len(result.missing)),
                QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No,
            )
            if answer == QMessageBox.StandardButton.Yes:
                removed = self.library.prune_missing()
                self.library.save()
                self._apply_filter()
                self.write_status(d["MsgPruned"].format(len(removed)), "OK")

    # ----------------------------------------------------------------- listing

    def _apply_filter(self) -> None:
        """Rebuild the list from the saved library, honouring the search box."""
        d = get_dict(self.lang)
        needle = self.txt_search.text().strip().lower()

        self.tree.blockSignals(True)
        self.tree.clear()

        show_uncertain = self.chk_show_uncertain.isChecked()
        for entry in self.library.sorted_entries(include_uncertain=show_uncertain):
            if needle and needle not in entry.name.lower() and needle not in entry.path.lower():
                continue

            badge = d["BadgeMissing"] if entry.missing else d.get(entry.badge_key, entry.badge_key)
            if entry.installed_mode and not entry.missing:
                badge = f"{d['InstalledTag']} {badge}"
            if not entry.is_game:
                badge = f"{d['TagUncertain']} {badge}"

            state_text, state_color = self._entry_state(entry, d)
            item = QTreeWidgetItem([entry.name, badge, state_text, entry.path])
            item.setForeground(2, QBrush(QColor(state_color)))
            item.setData(0, Qt.ItemDataRole.UserRole, self._entry_to_game(entry, d))
            item.setToolTip(0, entry.path)
            item.setToolTip(3, entry.path)
            item.setForeground(1, self._badge_brush(9 if entry.missing else entry.order))
            item.setIcon(0, self._entry_icon(entry))
            if not entry.is_game:
                item.setToolTip(1, entry.confidence)
            self.tree.addTopLevelItem(item)

        self.tree.blockSignals(False)

        hidden = 0 if show_uncertain else self.library.uncertain_count()
        if hidden and hidden != self._last_hidden_reported:
            self.write_status(d["UncertainHidden"].format(hidden), "INFO")
        self._last_hidden_reported = hidden

    def _entry_state(self, entry: LibraryEntry, d: dict[str, str]) -> tuple[str, str]:
        """The Status cell: what the app knows about this entry right now.

        Ordered by how much it matters to the user: a missing folder first,
        then an existing install, then whether the entry is a game at all.
        """
        if entry.missing:
            return d["StateMissing"], theme.ACCENT_RED

        if entry.installed_mode:
            key = {
                C.MODE_DIRECT: "StateInstalledDirect",
                C.MODE_OPTISCALER: "StateInstalledBridge",
                C.MODE_FEEDER: "StateInstalledFeeder",
            }.get(entry.installed_mode, "StateInstalledDirect")
            return d[key], theme.ACCENT_AMBER

        if not entry.is_game:
            return d["StateUnrecognised"], theme.FG_MUTED

        if not entry.exe_name:
            # Recognised as a game, but nothing we can inject into.
            return d["StateNoExe"], theme.ACCENT_AMBER

        return d["StateDetected"], theme.ACCENT_GREEN_TEXT

    def _entry_to_game(self, entry: LibraryEntry, d: dict[str, str]) -> DiscoveredGame:
        """Adapt a saved entry to the shape the inspector expects."""
        return DiscoveredGame(
            name=entry.name,
            path=Path(entry.path),
            badge=d.get(entry.badge_key, entry.badge_key),
            order=entry.order,
            exe_name=entry.exe_name,
            icon_source=Path(entry.exe_path) if entry.exe_path else None,
            badge_key=entry.badge_key,
            source_folder=entry.source_folder,
        )

    def _entry_icon(self, entry: LibraryEntry) -> QIcon:
        if entry.exe_path and not entry.missing:
            icon = extract_exe_icon(entry.exe_path)
            if icon is not None:
                return icon
        return self._blank_icon()

    def _game_icon(self, game: DiscoveredGame) -> QIcon:
        """The executable's icon, or a transparent placeholder of equal size."""
        if game.icon_source is not None:
            icon = extract_exe_icon(game.icon_source)
            if icon is not None:
                return icon
        return self._blank_icon()

    def _blank_icon(self) -> QIcon:
        if self._blank_icon_cache is None:
            from PySide6.QtGui import QPixmap

            pixmap = QPixmap(22, 22)
            pixmap.fill(Qt.GlobalColor.transparent)
            self._blank_icon_cache = QIcon(pixmap)
        return self._blank_icon_cache

    @staticmethod
    def _badge_brush(order: int):
        # Order 9 marks an entry whose folder no longer exists.
        return QBrush(
            QColor(
                {
                    1: theme.ACCENT_GREEN_TEXT,
                    2: theme.ACCENT_BLUE,
                    9: theme.ACCENT_RED,
                }.get(order, theme.ACCENT_PURPLE)
            )
        )

    # -------------------------------------------------------------- selection

    def _on_game_selected(self, current: QTreeWidgetItem | None) -> None:
        if current is None:
            return
        game = current.data(0, Qt.ItemDataRole.UserRole)
        if isinstance(game, DiscoveredGame):
            self._select_game(game)

    def _select_game(self, game: DiscoveredGame) -> None:
        """Fill the inspector for a game and recommend an injection mode."""
        self.selected_game = game
        d = get_dict(self.lang)

        self.lbl_game_title.setText(game.name)
        self.lbl_game_badge.setText(game.badge)
        self.txt_root.setText(str(game.path))
        self._set_badge_color(game.order)

        try:
            resolved = resolve_game_target(str(game.path))
        except DetectionError:
            self.txt_inject.setText(str(game.path))
            self.txt_exe.setText("")
            self.lbl_game_icon.clear()
            self._rebuild_mode_combo(C.UNIVERSAL_FEEDER)
            return

        self.txt_inject.setText(str(resolved.install_folder))
        self.txt_exe.setText(resolved.exe_name)
        # Show the start of a long path rather than its tail, and expose the
        # full value on hover since the fields are narrower than the paths.
        for field in (self.txt_root, self.txt_inject, self.txt_exe):
            field.setCursorPosition(0)
            field.setToolTip(field.text())

        icon = extract_exe_icon(resolved.executable)
        if icon is not None:
            self.lbl_game_icon.setPixmap(icon.pixmap(44, 44))
        else:
            self.lbl_game_icon.clear()

        self.write_status(d["MsgSelected"].format(game.name, resolved.exe_name), "INFO")

        self.detected_upscaler = detect_upscaler_type(resolved.install_folder, resolved.root)
        self._rebuild_mode_combo(self.detected_upscaler)

        state = is_installed(resolved.install_folder)
        if state is not None:
            self._show_installed_badge(state, d)

    def _show_installed_badge(self, state, d: dict[str, str]) -> None:
        from PySide6.QtGui import QColor, QPalette

        if state.mode == C.MODE_OPTISCALER:
            mode_text = d["MsgModeBridge"].format(state.upscaler_type)
        elif state.mode == C.MODE_FEEDER:
            mode_text = d["MsgModeFeeder"]
        else:
            mode_text = d["MsgModeDirect"]

        self.lbl_game_badge.setText(f"{d['MsgInstalledAlready']} {mode_text}")
        self.lbl_game_badge.setStyleSheet(f"color: {theme.ACCENT_AMBER}; font-weight: 600;")

    def _set_badge_color(self, order: int) -> None:
        color = {1: theme.ACCENT_GREEN_TEXT, 2: theme.ACCENT_BLUE}.get(
            order, theme.ACCENT_PURPLE
        )
        self.lbl_game_badge.setStyleSheet(f"color: {color}; font-weight: 600;")

    def _rebuild_mode_combo(self, detected: str) -> None:
        d = get_dict(self.lang)
        if detected == C.NATIVE_DLSS:
            recommended = d["ModeNameDirect"]
        elif detected in (C.FSR2_BRIDGE, C.XESS_BRIDGE):
            recommended = d["ModeNameBridge"]
        else:
            recommended = d["ModeNameFeeder"]

        self.combo_mode.blockSignals(True)
        self.combo_mode.clear()
        self.combo_mode.addItems(
            [
                d["OptAutoRecommended"].format(recommended),
                d["OptModeDirect"],
                d["OptModeBridge"],
                d["OptModeFeeder"],
            ]
        )
        self.combo_mode.setCurrentIndex(0)
        self.combo_mode.blockSignals(False)
        self._update_reminder()

    def _effective_upscaler(self) -> str:
        """The upscaler family implied by the current mode selection."""
        index = self.combo_mode.currentIndex()
        if index <= 0:
            return self.detected_upscaler or C.NATIVE_DLSS
        return {1: C.NATIVE_DLSS, 2: C.FSR2_BRIDGE, 3: C.UNIVERSAL_FEEDER}[index]

    def _selected_mode(self) -> str:
        return {1: C.MODE_DIRECT, 2: C.MODE_OPTISCALER, 3: C.MODE_FEEDER}.get(
            self.combo_mode.currentIndex(), C.MODE_AUTO
        )

    def _update_reminder(self) -> None:
        """Restate the in-game requirement for the chosen mode."""
        d = get_dict(self.lang)
        mode = self._effective_upscaler()

        if mode == C.NATIVE_DLSS:
            badge, color = d["Badge100"], theme.ACCENT_GREEN_TEXT
            header, text = d["RemHeaderDirect"], d["RemTextDirect"]
        elif mode in (C.FSR2_BRIDGE, C.XESS_BRIDGE):
            badge, color = d["BadgeBridge"], theme.ACCENT_BLUE
            header, text = d["RemHeaderBridge"], d["RemTextBridge"]
        else:
            badge, color = d["BadgeFeeder"], theme.ACCENT_PURPLE
            header, text = d["RemHeaderFeeder"], d["RemTextFeeder"]

        if self.selected_game is not None:
            self.lbl_game_badge.setText(badge)
            self.lbl_game_badge.setStyleSheet(f"color: {color}; font-weight: 600;")
        self.lbl_reminder_header.setText(header)
        self.lbl_reminder_header.setStyleSheet(f"color: {color}; font-weight: 700;")
        self.lbl_reminder_text.setText(text)

    # ---------------------------------------------------------------- actions

    def _target_path(self) -> str:
        return self.txt_root.text().strip()

    def _require_target(self) -> str | None:
        path = self._target_path()
        if not path:
            d = get_dict(self.lang)
            QMessageBox.warning(self, C.PRODUCT_NAME, d["NoGameSelected"])
            return None
        return path

    def _on_browse(self) -> None:
        d = get_dict(self.lang)
        folder = QFileDialog.getExistingDirectory(self, d["DlgSelectGameFolder"])
        if not folder:
            return

        try:
            resolve_game_target(folder)
        except DetectionError as err:
            self._report_error(err)
            return

        self.preselect_folder(folder)

    def preselect_folder(self, folder: str) -> None:
        """Load a game folder into the inspector, as --game does on startup."""
        d = get_dict(self.lang)
        try:
            resolved = resolve_game_target(folder)
        except DetectionError as err:
            self.write_status(err.message, "ERROR")
            return

        upscaler = detect_upscaler_type(resolved.install_folder, resolved.root)
        badge_key = {
            C.NATIVE_DLSS: "Badge100",
            C.FSR2_BRIDGE: "BadgeBridge",
            C.XESS_BRIDGE: "BadgeBridge",
        }.get(upscaler, "BadgeFeeder")

        self._select_game(
            DiscoveredGame(
                name=Path(folder).name,
                path=Path(folder),
                badge=d[badge_key],
                order={"Badge100": 1, "BadgeBridge": 2}.get(badge_key, 3),
                exe_name=resolved.exe_name,
                icon_source=resolved.executable,
            )
        )

    def _on_change_zip(self) -> None:
        d = get_dict(self.lang)
        path, _ = QFileDialog.getOpenFileName(self, d["DlgSelectZip"], "", d["ZipFilter"])
        if path:
            self.txt_zip.setText(path)
            self.write_status(msg("PayloadSelected", path), "INFO")

    def _on_verify(self) -> None:
        path = self._require_target()
        if path is None:
            return

        self.log.clear()
        d = get_dict(self.lang)
        report = check_compatibility(path, self.txt_zip.text().strip(), self.write_status)

        for line in report.info:
            self.write_status(line, "INFO")
        for line in report.warnings:
            self.write_status(line, "WARN")
        for line in report.fatal:
            self.write_status(line, "ERROR")
        if report.can_install:
            self.write_status(d["MsgVerifyOk"], "OK")

    def _on_install(self) -> None:
        path = self._require_target()
        if path is None or self._install_thread is not None:
            return

        d = get_dict(self.lang)
        exe_name = self.txt_exe.text() or Path(path).name
        mode = self._effective_upscaler()

        if mode == C.NATIVE_DLSS:
            message = d["ConfirmInstallDirect"].format(exe_name)
        elif mode in (C.FSR2_BRIDGE, C.XESS_BRIDGE):
            bridge = "FSR2/FSR3" if mode == C.FSR2_BRIDGE else "XeSS"
            message = d["ConfirmInstallBridge"].format(exe_name, bridge)
        else:
            message = d["ConfirmInstallFeeder"].format(exe_name)

        answer = QMessageBox.question(
            self,
            d["ConfirmInstallTitle"],
            message,
            QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No,
        )
        if answer != QMessageBox.StandardButton.Yes:
            self.write_status(msg("InstallCancelled"), "WARN")
            return

        if not self._confirm_elevation(self.txt_inject.text() or path):
            return

        self.btn_install.setEnabled(False)
        self._install_worker = InstallWorker(
            target_path=path,
            zip_path=self.txt_zip.text().strip(),
            install_reshade=self.chk_reshade.isChecked(),
            full_package=self.chk_full.isChecked(),
            selected_mode=self._selected_mode(),
        )
        self._install_thread = QThread(self)
        self._install_worker.moveToThread(self._install_thread)

        self._install_worker.log.connect(self.write_status)
        self._install_worker.finished.connect(self._on_install_done)
        self._install_worker.failed.connect(self._on_install_failed)
        self._install_worker.finished.connect(self._install_thread.quit)
        self._install_worker.failed.connect(self._install_thread.quit)
        self._install_thread.started.connect(self._install_worker.run)
        self._install_thread.finished.connect(self._on_install_thread_finished)
        self._install_thread.start()

    def _confirm_elevation(self, folder: str) -> bool:
        """Warn before writing into a protected folder without admin rights.

        Returns False when the user chose to relaunch elevated instead.
        """
        if not needs_elevation(folder):
            return True

        warning = (
            "Esta pasta exige direitos de Administrador:\n"
            f"{folder}\n\n"
            "Deseja reiniciar o programa como Administrador?"
            if self.lang == "PT"
            else (
                "This folder requires Administrator rights:\n"
                f"{folder}\n\n"
                "Restart the program as Administrator?"
            )
        )
        answer = QMessageBox.question(
            self,
            C.PRODUCT_NAME,
            warning,
            QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No,
        )
        if answer == QMessageBox.StandardButton.Yes:
            if relaunch_as_admin():
                QApplication.quit()
                return False
            self.write_status(msg("ElevationFailed"), "WARN")
        return True

    def _report_error(self, err: Exception) -> None:
        """Log an error and show it, translated when it carries a Message."""
        message = getattr(err, "message", None) or str(err)
        self.write_status(message, "ERROR")
        QMessageBox.critical(self, C.PRODUCT_NAME, render(message, self.lang))

    def _on_install_thread_finished(self) -> None:
        if self._install_thread is not None:
            self._install_thread.deleteLater()
        if self._install_worker is not None:
            self._install_worker.deleteLater()
        self._install_thread = None
        self._install_worker = None
        self.btn_install.setEnabled(True)

    def _on_install_done(self, _upscaler: str) -> None:
        d = get_dict(self.lang)
        QMessageBox.information(self, d["SuccessTitle"], d["SuccessMsg"])
        if self.selected_game is not None:
            self._select_game(self.selected_game)

    def _on_install_failed(self, message: "Message | str") -> None:
        # The worker emits a Message key, not a sentence: render it before it
        # reaches Qt, which only accepts str.
        self.write_status(message, "ERROR")
        QMessageBox.critical(self, C.PRODUCT_NAME, render(message, self.lang))

    def _on_restore(self) -> None:
        path = self._require_target()
        if path is None:
            return

        d = get_dict(self.lang)
        exe_name = self.txt_exe.text() or Path(path).name
        answer = QMessageBox.warning(
            self,
            d["ConfirmUninstallTitle"],
            d["ConfirmUninstall"].format(exe_name),
            QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No,
        )
        if answer != QMessageBox.StandardButton.Yes:
            self.write_status(msg("RestoreCancelled"), "WARN")
            return

        self.btn_restore.setEnabled(False)
        try:
            uninstall_dlss5(path, self.write_status)
            QMessageBox.information(self, d["RestoreTitle"], d["RestoreMsg"])
            if self.selected_game is not None:
                self._select_game(self.selected_game)
        except (DetectionError, InstallError, OSError) as err:
            self._report_error(err)
        finally:
            self.btn_restore.setEnabled(True)

    def _on_launch(self) -> None:
        path = self._require_target()
        if path is None:
            return
        try:
            launch_game(path, self.write_status)
        except (DetectionError, OSError) as err:
            self._report_error(err)

    def _on_open_folder(self) -> None:
        path = self._require_target()
        if path is None:
            return
        try:
            target = resolve_game_target(path)
            open_in_explorer(target.install_folder)
        except (DetectionError, OSError) as err:
            self._report_error(err)

    def _on_guide(self) -> None:
        d = get_dict(self.lang)
        box = QMessageBox(self)
        box.setWindowTitle(d["GuideTitle"])
        box.setText(get_guide(self.lang))
        box.setIcon(QMessageBox.Icon.Information)
        box.exec()

    def closeEvent(self, event) -> None:
        """Stop worker threads so the process can exit cleanly.

        Signals are disconnected before waiting: a worker that emits while Qt
        is tearing the window down delivers into half-destroyed widgets, which
        crashes the process.
        """
        for worker in (self._scan_worker, self._refresh_worker, self._install_worker):
            if worker is None:
                continue
            if hasattr(worker, "cancel"):
                worker.cancel()
            try:
                worker.disconnect()
            except (RuntimeError, TypeError):
                # Already disconnected or deleted; nothing to undo.
                pass

        for thread in (self._scan_thread, self._refresh_thread, self._install_thread):
            if thread is None:
                continue
            try:
                if thread.isRunning():
                    thread.quit()
                    thread.wait(5000)
            except RuntimeError:
                pass

        self.library.save()
        super().closeEvent(event)

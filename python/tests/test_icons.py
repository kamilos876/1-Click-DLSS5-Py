"""Icon extraction must survive 64-bit icon handles.

ctypes guesses a C int for HICON unless told otherwise, so a handle above 2^31
raised "int too long to convert" inside DestroyIcon. The wrapper swallowed that
exception and returned no icon, which is why only some games lost theirs.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

# Must precede any `ui` import: it redirects the cache away from the
# user's real library.
import isolation  # noqa: E402,F401

from PySide6.QtWidgets import QApplication

from ui.icons import extract_exe_icon

# System binaries that always exist and always carry an icon.
SYSTEM_EXES = [
    r"C:\Windows\System32\notepad.exe",
    r"C:\Windows\explorer.exe",
    r"C:\Windows\System32\mspaint.exe",
    r"C:\Windows\System32\calc.exe",
    r"C:\Windows\System32\cmd.exe",
]


def main() -> int:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    app = QApplication([])  # noqa: F841 - QIcon needs a QApplication

    problems: list[str] = []
    checked = 0

    for raw in SYSTEM_EXES:
        exe = Path(raw)
        if not exe.is_file():
            continue
        checked += 1
        # Repeat: the bug only bit on a handle that happened to be large, so a
        # single attempt could pass by luck.
        for attempt in range(5):
            icon = extract_exe_icon(exe)
            if icon is None:
                problems.append(f"{exe.name}: no icon on attempt {attempt + 1}")
                break
            if icon.pixmap(32, 32).isNull():
                problems.append(f"{exe.name}: null pixmap on attempt {attempt + 1}")
                break

    if checked == 0:
        print("  SKIP  no system executables available")
        return 0

    missing = extract_exe_icon(Path(r"C:\does\not\exist.exe"))
    if missing is not None:
        problems.append("a missing file should yield no icon")

    if problems:
        print("  FAIL")
        for line in problems:
            print("          ", line)
        return 1

    print(f"  PASS  icons: {checked} executables, 5 attempts each")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

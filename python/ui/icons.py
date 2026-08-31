"""Extracting a Windows executable's icon for display in the game list.

Replaces the PowerShell version's Icon::ExtractAssociatedIcon. Qt cannot read
an HICON directly, so the icon is drawn into a DIB and wrapped as a QImage.
"""
from __future__ import annotations

import sys
from pathlib import Path

from PySide6.QtGui import QIcon, QImage, QPixmap

_ICON_SIZE = 32


def extract_exe_icon(exe_path: str | Path, size: int = _ICON_SIZE) -> QIcon | None:
    """Return the executable's embedded icon, or None when it has none."""
    if sys.platform != "win32":
        return None

    path = Path(exe_path)
    if not path.is_file():
        return None

    try:
        return _extract_win32(path, size)
    except Exception:
        # An unreadable icon must never break the library listing.
        return None


def _extract_win32(path: Path, size: int) -> QIcon | None:
    import ctypes
    from ctypes import wintypes

    shell32 = ctypes.windll.shell32
    user32 = ctypes.windll.user32
    gdi32 = ctypes.windll.gdi32

    # Declare the handle-taking calls explicitly. Without this ctypes guesses a
    # C int for HICON, and a handle above 2^31 raises "int too long to convert"
    # inside DestroyIcon — which silently cost some games their icon.
    user32.DestroyIcon.argtypes = [wintypes.HICON]
    user32.DestroyIcon.restype = wintypes.BOOL
    user32.DrawIconEx.argtypes = [
        wintypes.HDC, ctypes.c_int, ctypes.c_int, wintypes.HICON,
        ctypes.c_int, ctypes.c_int, wintypes.UINT, wintypes.HBRUSH,
        wintypes.UINT,
    ]
    user32.DrawIconEx.restype = wintypes.BOOL
    shell32.ExtractIconExW.argtypes = [
        wintypes.LPCWSTR, ctypes.c_int,
        ctypes.POINTER(wintypes.HICON), ctypes.POINTER(wintypes.HICON),
        wintypes.UINT,
    ]
    shell32.ExtractIconExW.restype = wintypes.UINT

    large = (wintypes.HICON * 1)()
    small = (wintypes.HICON * 1)()

    # ExtractIconExW fills the arrays and returns the icon count in the file.
    count = shell32.ExtractIconExW(str(path), 0, large, small, 1)
    if count <= 0:
        return None

    hicon = large[0] or small[0]
    if not hicon:
        return None

    try:
        image = _hicon_to_qimage(hicon, size, ctypes, wintypes, user32, gdi32)
    finally:
        for handle in (large[0], small[0]):
            if not handle:
                continue
            try:
                user32.DestroyIcon(handle)
            except (ctypes.ArgumentError, OSError, OverflowError):
                # Leaking one icon handle beats losing the icon.
                pass

    if image is None or image.isNull():
        return None
    return QIcon(QPixmap.fromImage(image))


def _hicon_to_qimage(hicon, size, ctypes, wintypes, user32, gdi32) -> QImage | None:
    """Draw an HICON into a 32-bit top-down DIB and copy it into a QImage."""

    class BITMAPINFOHEADER(ctypes.Structure):
        _fields_ = [
            ("biSize", wintypes.DWORD),
            ("biWidth", wintypes.LONG),
            ("biHeight", wintypes.LONG),
            ("biPlanes", wintypes.WORD),
            ("biBitCount", wintypes.WORD),
            ("biCompression", wintypes.DWORD),
            ("biSizeImage", wintypes.DWORD),
            ("biXPelsPerMeter", wintypes.LONG),
            ("biYPelsPerMeter", wintypes.LONG),
            ("biClrUsed", wintypes.DWORD),
            ("biClrImportant", wintypes.DWORD),
        ]

    header = BITMAPINFOHEADER()
    header.biSize = ctypes.sizeof(BITMAPINFOHEADER)
    header.biWidth = size
    # A negative height requests a top-down bitmap, matching QImage's layout.
    header.biHeight = -size
    header.biPlanes = 1
    header.biBitCount = 32
    header.biCompression = 0  # BI_RGB

    screen_dc = user32.GetDC(0)
    if not screen_dc:
        return None

    memory_dc = gdi32.CreateCompatibleDC(screen_dc)
    bits = ctypes.c_void_p()
    bitmap = gdi32.CreateDIBSection(
        memory_dc, ctypes.byref(header), 0, ctypes.byref(bits), None, 0
    )

    try:
        if not bitmap or not bits:
            return None

        old = gdi32.SelectObject(memory_dc, bitmap)
        user32.DrawIconEx(memory_dc, 0, 0, hicon, size, size, 0, None, 0x0003)  # DI_NORMAL
        gdi32.SelectObject(memory_dc, old)

        buffer = ctypes.string_at(bits, size * size * 4)
        # The DIB is BGRA premultiplied; copy so the QImage owns its memory.
        return QImage(
            buffer, size, size, QImage.Format.Format_ARGB32_Premultiplied
        ).copy()
    finally:
        if bitmap:
            gdi32.DeleteObject(bitmap)
        gdi32.DeleteDC(memory_dc)
        user32.ReleaseDC(0, screen_dc)

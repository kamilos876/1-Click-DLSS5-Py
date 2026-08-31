"""Run every test module in one pass."""
import subprocess
import sys
from pathlib import Path

TESTS = [
    "test_i18n.py",
    "check_i18n_integrity.py",
    "test_library.py",
    "test_gameinfo.py",
    "test_detection.py",
    "test_reshade_ini.py",
    "test_installer.py",
    "test_gui_flow.py",
    "test_scan_thread.py",
    "test_layout.py",
    "test_status_column.py",
    "test_log_language.py",
    "test_icons.py",
]


def main() -> int:
    # Test output carries emoji; a cp1250 console would raise on write.
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    here = Path(__file__).resolve().parent
    failures: list[str] = []

    for name in TESTS:
        print(f"\n=== {name} ===")
        completed = subprocess.run(
            [sys.executable, str(here / name)],
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
        )
        sys.stdout.write(completed.stdout)
        if completed.returncode != 0:
            sys.stdout.write(completed.stderr)
            failures.append(name)

    print("\n" + "=" * 46)
    if failures:
        print(f"FAILED: {', '.join(failures)}")
        return 1
    print(f"ALL {len(TESTS)} TEST MODULES PASSED")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

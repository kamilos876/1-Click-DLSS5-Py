"""Guard against escape damage from bulk edits of the translation tables."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from core.i18n import EN, PL, PT

BACKSLASH = chr(92)


def main() -> int:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    problems: list[str] = []

    for lang, table in (("EN", EN), ("PL", PL), ("PT", PT)):
        for key, value in table.items():
            if not isinstance(value, str):
                problems.append(f"{lang}.{key}: not a string")
                continue
            # A literal backslash-n means the escape was double-written.
            if BACKSLASH + "n" in value:
                problems.append(f"{lang}.{key}: literal {BACKSLASH}n in text")
            if value.endswith(BACKSLASH):
                problems.append(f"{lang}.{key}: trailing backslash")

    # Multi-line messages must keep their real newlines.
    for key in ("SuccessMsg", "ConfirmInstallDirect", "ConfirmPrune", "ConfirmRemoveFolder"):
        for lang, table in (("EN", EN), ("PL", PL), ("PT", PT)):
            if "\n" not in table[key]:
                problems.append(f"{lang}.{key}: expected newlines, found none")

    if problems:
        print("PROBLEMS:")
        for line in problems:
            print("  -", line)
        return 1

    print(f"  PASS  i18n integrity: {len(EN)} keys x 3 languages, no escape damage")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

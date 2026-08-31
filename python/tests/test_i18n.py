"""Sanity checks for the translation tables."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from core.i18n import EN, LANGUAGES, PL, PT, get_dict, get_guide

TABLES = {"EN": EN, "PL": PL, "PT": PT}


def test_key_parity():
    """Every language must define exactly the same keys as English."""
    for code, table in TABLES.items():
        missing = set(EN) - set(table)
        extra = set(table) - set(EN)
        assert not missing, f"{code} missing: {sorted(missing)}"
        assert not extra, f"{code} has unknown keys: {sorted(extra)}"


def test_placeholders_match():
    """A key used with .format must take the same fields in every language."""
    import re

    field_re = re.compile(r"\{(\d+)\}")
    for key, english in EN.items():
        expected = sorted(field_re.findall(english))
        for code, table in TABLES.items():
            got = sorted(field_re.findall(table[key]))
            assert got == expected, f"{key}: {code}{got} != EN{expected}"


def test_get_dict_defaults_to_english():
    assert get_dict("EN") is EN
    assert get_dict("PL") is PL
    assert get_dict("PT") is PT
    assert get_dict("xx") is EN, "unknown codes must fall back to English"


def test_every_listed_language_resolves():
    for code, label in LANGUAGES:
        assert get_dict(code) is TABLES[code], f"{label} not wired up"
        assert get_guide(code), f"{label} has no guide text"


def test_guides_non_empty():
    assert "MODE 1" in get_guide("EN")
    assert "TRYB 1" in get_guide("PL")
    assert "MODO 1" in get_guide("PT")


if __name__ == "__main__":
    test_key_parity()
    test_placeholders_match()
    test_get_dict_defaults_to_english()
    test_every_listed_language_resolves()
    test_guides_non_empty()
    print(f"i18n OK - {len(EN)} keys x {len(TABLES)} languages")

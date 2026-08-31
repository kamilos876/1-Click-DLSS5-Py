"""Persistence and refresh behaviour of the saved game library."""
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from core import constants as C
from core.library import Library, LibraryEntry
from core.refresh import refresh_library

_PE64 = bytearray(512)
_PE64[0:2] = b"MZ"
_PE64[60:64] = (0x80).to_bytes(4, "little")
_PE64[0x80:0x84] = b"PE\0\0"
_PE64[0x84:0x86] = (0x8664).to_bytes(2, "little")


def _write_exe(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(bytes(_PE64))


def test_roundtrip_survives_restart(tmp: Path) -> None:
    """A saved library must come back identical on the next run."""
    store = tmp / "library.json"
    lib = Library()
    lib.add_folder(str(tmp / "Games"))
    lib.upsert(
        LibraryEntry(
            name="TestGame",
            path=str(tmp / "Games" / "TestGame"),
            badge_key="Badge100",
            order=1,
            exe_name="TestGame.exe",
        )
    )
    lib.save(store)

    reloaded = Library.load(store)
    assert reloaded.folders == lib.folders, reloaded.folders
    assert len(reloaded.entries) == 1
    assert reloaded.entries[0].name == "TestGame"
    assert reloaded.entries[0].badge_key == "Badge100"
    assert reloaded.entries[0].added_at, "added_at should be stamped on insert"


def test_missing_file_gives_empty_library(tmp: Path) -> None:
    assert Library.load(tmp / "nope.json").entries == []


def test_corrupt_file_gives_empty_library(tmp: Path) -> None:
    broken = tmp / "library.json"
    broken.write_text("{not json", encoding="utf-8")
    assert Library.load(broken).entries == []


def test_duplicate_folder_rejected(tmp: Path) -> None:
    lib = Library()
    assert lib.add_folder(str(tmp)) is True
    assert lib.add_folder(str(tmp)) is False
    assert len(lib.folders) == 1


def test_upsert_replaces_not_duplicates(tmp: Path) -> None:
    lib = Library()
    path = str(tmp / "G")
    lib.upsert(LibraryEntry(name="G", path=path, order=3))
    first_added = lib.entries[0].added_at
    lib.upsert(LibraryEntry(name="G", path=path, order=1, badge_key="Badge100"))
    assert len(lib.entries) == 1, "same path must not duplicate"
    assert lib.entries[0].order == 1, "entry should be refreshed"
    assert lib.entries[0].added_at == first_added, "added_at must be preserved"


def test_remove_folder_drops_its_games(tmp: Path) -> None:
    lib = Library()
    folder = str(tmp / "Lib")
    lib.add_folder(folder)
    lib.upsert(LibraryEntry(name="A", path=str(tmp / "Lib" / "A"), source_folder=folder))
    lib.upsert(LibraryEntry(name="B", path=str(tmp / "Other" / "B"), source_folder=str(tmp / "Other")))
    lib.remove_folder(folder)
    assert [e.name for e in lib.entries] == ["B"]


def test_refresh_flags_missing_and_keeps_present(tmp: Path) -> None:
    present = tmp / "Present"
    _write_exe(present / "Present.exe")
    absent = tmp / "Gone"

    lib = Library()
    lib.upsert(LibraryEntry(name="Present", path=str(present)))
    lib.upsert(LibraryEntry(name="Gone", path=str(absent)))

    result = refresh_library(lib)
    assert len(result.present) == 1, result.present
    assert len(result.missing) == 1, result.missing
    assert result.missing[0].name == "Gone"
    assert result.missing[0].missing is True
    # Nothing is deleted without the user's say-so.
    assert len(lib.entries) == 2


def test_refresh_updates_status_after_game_changes(tmp: Path) -> None:
    """A game that gains a DLSS DLL must be re-graded on refresh."""
    game = tmp / "Evolving"
    _write_exe(game / "Evolving.exe")

    lib = Library()
    lib.upsert(LibraryEntry(name="Evolving", path=str(game), badge_key="BadgeFeeder", order=3))
    refresh_library(lib)
    assert lib.entries[0].badge_key == "BadgeFeeder"

    (game / "nvngx_dlss.dll").write_bytes(b"x")
    result = refresh_library(lib)
    assert lib.entries[0].badge_key == "Badge100", lib.entries[0].badge_key
    assert lib.entries[0].order == 1
    assert lib.entries[0] in result.updated


def test_prune_removes_only_missing(tmp: Path) -> None:
    present = tmp / "Here"
    present.mkdir()
    lib = Library()
    lib.upsert(LibraryEntry(name="Here", path=str(present)))
    lib.upsert(LibraryEntry(name="Gone", path=str(tmp / "Nowhere")))
    removed = lib.prune_missing()
    assert [e.name for e in removed] == ["Gone"]
    assert [e.name for e in lib.entries] == ["Here"]


if __name__ == "__main__":
    tests = [
        test_roundtrip_survives_restart,
        test_missing_file_gives_empty_library,
        test_corrupt_file_gives_empty_library,
        test_duplicate_folder_rejected,
        test_upsert_replaces_not_duplicates,
        test_remove_folder_drops_its_games,
        test_refresh_flags_missing_and_keeps_present,
        test_refresh_updates_status_after_game_changes,
        test_prune_removes_only_missing,
    ]
    original = C.CACHE_ROOT
    for func in tests:
        with tempfile.TemporaryDirectory() as raw:
            C.CACHE_ROOT = Path(raw) / "cache"
            try:
                func(Path(raw))
            finally:
                C.CACHE_ROOT = original
        print(f"  PASS  {func.__name__}")
    print("library OK")

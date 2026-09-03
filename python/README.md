# 1 Click DLSS 5 — Python edition (PySide6)

A port of `1-Click-DLSS5.ps1` (PowerShell + WinForms) to a desktop application
built with PySide6 (Qt 6).

## Running it

```cmd
run.cmd
```

or manually:

```cmd
pip install -r requirements.txt
python main.py
```

### Command-line arguments

| Argument | Description |
|---|---|
| `--lang EN\|PL\|PT` | interface language (default: EN) |
| `--game PATH` | preselect this game folder on startup |
| `--version` | print the version and exit |

## Project layout

```
core/            GUI-independent logic (testable without Qt)
  constants.py     constants, payload file lists, game profiles
  utils.py         SHA256, PE validation, paths, GPU, drives
  detection.py     locating a game's executable and its upscaler family
  scanner.py       scanning nominated folders for games
  library.py       the saved list of games and folders (library.json)
  refresh.py       re-checking which games are still on disk
  gameinfo.py      recognising games and resolving their real titles
  payload.py       extracting the ZIP and installing ReShade
  reshade_ini.py   generating ReShade.ini for each injection mode
  installer.py     install, backup, restore, launch
  elevation.py     detecting and requesting administrator rights
  i18n.py          English and Portuguese strings, language registry
  i18n_pl.py       Polish strings
  messages.py      diagnostics-log message keys and their translations
ui/              Qt layer
  main_window.py   the main window
  theme.py         palette and stylesheet (dark theme)
  workers.py       threads: scan, refresh and install without freezing the UI
  progress_dialog.py  a thread-safe progress dialog
  icons.py         extracting icons from .exe files (WinAPI)
tests/           test suite
```

## Tests

```cmd
python tests/run_all.py
```

They cover: translation parity across all three languages, game detection (on
synthetic fixtures and real installs), game recognition, `ReShade.ini`
generation, the full install→restore cycle, a headless pass through the GUI,
scan-thread completion, and a layout check that no label or field is clipped.

## The game library

Instead of scanning whole partitions, you nominate the folders where your games
live:

- **ADD FOLDER** — registers a folder to scan. On first run, detected
  Steam/Epic/Xbox libraries are added automatically.
- **SCAN FOLDERS** — searches the registered folders and remembers what it finds
- **REFRESH LIST** — re-checks which games are still on disk and whether their
  status changed; missing ones are marked in red and can be pruned. It also
  re-resolves titles, so a name that was wrong when first scanned is corrected.
- **LAYOUT** — switches between the side-by-side layout (default) and a stacked
  one where the library sits above the inspector and both span the full width

The list is saved to `%LOCALAPPDATA%\1ClickDLSS5\library.json` and reloaded at
startup, so your games are there immediately without rescanning.

The list has four columns: the game's title, its **DLSS 5 Compatibility** (which
injection mode suits it), its **Status**, and its **Location** on disk.

| Status | Meaning |
|---|---|
| Detected | found and ready; nothing installed yet |
| DLSS 5 installed (Direct / OptiScaler / Feeder) | the mod is in place, in that mode |
| Folder missing | saved earlier, but the folder is gone |
| No 64-bit executable | recognised as a game, but nothing to inject into |
| Not recognised as a game | shown only with the checkbox ticked |

### Nested launchers

One folder is usually enough. Pointing the scanner at `D:\Games` also finds the
games kept by the launchers inside it, because store roots are followed into the
directory where their games actually live:

| Layout | Where the games are |
|---|---|
| Steam | `Steam\steamapps\common\<game>` |
| Ubisoft Connect | `Ubisoft Game Launcher\games\<game>` |
| GOG Galaxy | `GOG Galaxy\games\<game>` |
| Rockstar, Epic, EA, Battle.net | one game per subfolder |

A folder holding its own binaries is treated as a single game, so a game's own
`Data`, `Binaries` or `Content` subfolders are never listed separately.

### Recognising games

Not every folder holding an `.exe` is a game. This is decided locally — no
network, no API keys, and no list of your games leaving the machine:

| Source | What it provides |
|---|---|
| `goggame-*.info` (GOG) | the real title and the game's main executable |
| `MicrosoftGame.config` (Xbox) | the display name |
| `.mancpn` (Epic), `steam_appid.txt` | proof the folder is a store-installed game |
| Engine files (`UnityPlayer.dll`, `steam_api64.dll`, `Binaries\Win64`) | proof it is a game |
| The executable's version resource | the exact title, e.g. "Aliens: Fireteam Elite" |
| The folder name | last resort, after stripping release tags |

So `game-the.sinking.city.remastered-(88711)` is listed as **The Sinking City**,
and `HaloCampaignEvolved.exe` as **Halo: Campaign Evolved**.

The executable's title is only used when it beats the folder name. Some games
ship an internal codename (Palworld reports itself as "Pal") or write the
filename into the version resource (Control reports "Game_rmdwin10_f.exe"); in
those cases the cleaned-up folder name wins.

Rejected: launchers (GOG Galaxy, Steam, Epic), utilities (RivaTuner, MSI
Afterburner, benchmarks), and **installer folders** — a pile of `setup_*.bin`
files is not an installed game and nothing can be injected into it.

Folders with no evidence either way are **hidden, not deleted**. The
**Show items not recognised as games** checkbox above the list reveals them.

## Differences from the PowerShell version

The port keeps the original's logic. Deliberate changes:

**Bugs fixed**

- **Backups in Feeder and OptiScaler modes.** The original copied
  `nvngx_dlss.dll`, `nvngx_dlssnr.dll` and the addon with `Copy-Item -Force`
  and no backup, so the game's original files were lost for good on restore.
  Every overwritten file is now backed up first.
- **Switching Feeder → Direct.** The `[GENERAL]` section kept the
  `DLSS5_Feed.fx` techniques that the Direct installer had just deleted, so
  ReShade tried to load shaders that were no longer there. Those entries are
  now cleared.
- **Paths containing square brackets.** `Painkiller RTX [GOG]` was truncated by
  path sanitisation. An existing path is now taken as-is.
- **Administrator rights.** The original never checked; installing into
  `Program Files` failed with an opaque access error. The app now warns and
  offers to relaunch elevated.
- **The scan hanging forever.** A worker held only in a local variable was
  garbage collected before it ran, leaving the progress dialog stuck. Workers
  are now owned by the window.
- **Closing the progress dialog.** `QProgressDialog` runs a nested event loop
  at 100%, and calling `accept()`/`deleteLater()` from a worker signal crashed
  the process. Replaced with a plain dialog.
- **The diagnostics log ignored the interface language.** Core code built
  Portuguese sentences directly, so an English or Polish user still read
  Portuguese in the log. It now emits message keys that the UI renders in the
  selected language, and the level tags ([i INFO], [! WARN]) are neutral.
- **Missing game icons.** ctypes assumes a C int for a Windows icon handle, so
  a handle above 2^31 raised "int too long to convert" and the icon was lost —
  which is why only some games showed one. The WinAPI signatures are declared
  explicitly now.
- **Games wrongly graded as having native DLSS.** Compatibility was decided by
  looking for "dlss" anywhere in a filename, so another mod's `dlss-enabler.log`
  was enough to mark a game "100% COMPATIBLE" — Dying Light, which has no DLSS,
  was one. Only the actual runtime libraries (`nvngx_dlss*.dll`, `sl.dlss*.dll`)
  count now.

**Improvements**

- Scanning runs on a worker thread — the window never freezes (the original
  relied on `Application::DoEvents()`).
- Scanning is much faster: one directory walk instead of a separate
  `Get-ChildItem -Recurse` per file pattern.
- Non-game folders are filtered out (`GameSave`, `Minecraft Launcher`,
  `.egstore`), as is Xbox's `gamelaunchhelper.exe`, along with launcher
  plumbing such as updaters, crash handlers and redistributables.
- Launcher roots are followed into their real game directories, so a single
  registered folder covers Steam, Ubisoft, GOG and publisher folders alike.
- The dark theme lives in one stylesheet instead of per-control colour
  assignments.
- Language is chosen from a dropdown — English, Polish and Portuguese, with
  English as the default.
- Game recognition from local metadata: launchers, utilities and installer
  folders no longer reach the list, and titles come from store metadata or the
  executable rather than the folder name.
- The library and inspector can be laid out side by side (default) or stacked
  with the LAYOUT button; the splitter between them can be dragged either way.
- A layout test guards against any label or field being clipped, in both
  orientations — an under-tall window used to cut text in half in the
  injection panel.

## Known limitations

Xbox Game Pass titles (`XboxGames`) are encrypted on disk: their PE headers
cannot be parsed, so they are not recognised. No tool can inject DLLs into
them regardless.

## Payload

The app uses the same payload folder as the PowerShell version. Since v1.5.0
that folder lives at `core/payload/`; the older top-level `payload/` layout is
still detected automatically, so either checkout works.

`streamline.zip` is the one piece not committed to the repository (excluded for
size). Drop it into `core/payload/` and it is found on startup — the launcher
also probes the repository root and the current working directory. Without it,
no mode can install: all three need the neural runtime the ZIP carries. An
extracted copy left in the cache by an earlier run is reused, so a machine that
has installed once before keeps working without it.

The rest of the folder is live input, not decoration: the RenoDX add-on,
OptiScaler, the ReShade installer, and the Feeder's addons, shaders and textures
are all read from here and copied into the game. Pulling a newer payload from
upstream changes what gets installed with no code change on this side.

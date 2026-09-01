"""Polish interface strings.

Keys mirror core.i18n.EN one-for-one; the parity test enforces that.
"""
from __future__ import annotations

PL = {
    "Eyebrow": "OFICJALNY EKOSYSTEM RENO DX • UNIWERSALNY DLSS-NR (SERIE RTX 20 / 30 / 40 / 50)",
    "Title": "1 CLICK DLSS 5",
    "Subtitle": "Centrum gier w stylu Steam • Wstrzykiwanie sieci neuronowej jednym kliknięciem • Uniwersalny DLSS 5 dla KAŻDEJ gry PC",
    "LibraryTitle": "BIBLIOTEKA GIER I ZGODNOŚĆ",
    "SearchPlaceholder": "Szukaj zainstalowanych gier...",
    "DriveLabel": "Dysk:",
    "AllDrives": "Wszystkie dyski",
    "BtnScanDrives": "\U0001f50d SKANUJ DYSKI",
    "BtnBrowse": "\U0001f4c1 WSKAŻ GRĘ",
    "ColGame": "Tytuł gry",
    "ColStatus": "Zgodność z DLSS 5",
    "ColPath": "Lokalizacja instalacji",
    "InspectorTitle": "SZCZEGÓŁY GRY I PANEL INSTALACJI",
    "NoGameSelected": "Wybierz grę z biblioteki powyżej lub wskaż folder gry ręcznie.",
    "RootFolderLabel": "Folder główny gry:",
    "InjectFolderLabel": "Docelowy folder instalacji DLSS 5:",
    "TargetExeLabel": "Główny plik wykonywalny 64-bit:",
    "DlssStatusLabel": "Wykryto natywny DLSS:",
    "LblInjectionMode": "Tryb instalacji DLSS 5:",
    "OptAutoRecommended": "⚡ Automatycznie (zalecane: {0})",
    "OptModeDirect": "\U0001f7e2 Tryb 1: Bezpośredni (Streamline + natywny DLSS)",
    "OptModeBridge": "\U0001f535 Tryb 2: Mostek OptiScaler (FSR2/XeSS → DLSS 5)",
    "OptModeFeeder": "\U0001f7e3 Tryb 3: Uniwersalny Feeder (100% natywne DLAA)",
    "ModeNameDirect": "Tryb 1 - Bezpośredni",
    "ModeNameBridge": "Tryb 2 - Mostek OptiScaler",
    "ModeNameFeeder": "Tryb 3 - Uniwersalny Feeder",
    "ReminderHeader": "⚡ WYMAGANE USTAWIENIE W GRZE:",
    "ReminderText": "W grze koniecznie włącz 'NVIDIA DLSS Super Resolution' (Jakość/Zrównoważony/Wydajność) w ustawieniach grafiki, aby rekonstrukcja neuronowa DLSS 5 zadziałała!",
    "PayloadTitle": "Pakiet DLSS 5 (wbudowany Streamline 2.13):",
    "BtnChangeZip": "\U0001f4e6 ZMIEŃ ZIP",
    "OptReShade": "Zainstaluj ReShade 6.8.0 (obsługa dodatków)",
    "OptFull": "Pełna podmiana bibliotek Streamline",
    "BtnVerify": "\U0001f50d SPRAWDŹ",
    "BtnInstall": "\U0001f680 ZAINSTALUJ DLSS 5 JEDNYM KLIKNIĘCIEM",
    "BtnLaunch": "▶️ URUCHOM GRĘ",
    "BtnUninstall": "↩️ PRZYWRÓĆ ORYGINAŁ",
    "BtnOpenFolder": "\U0001f4c2 OTWÓRZ FOLDER",
    "BtnInstructions": "\U0001f4d6 PORADNIK",
    "StatusHeading": "DIAGNOSTYKA I DZIENNIK SYSTEMU NA ŻYWO",
    "Footer": "1 Click DLSS 5 v1.5.1 | Uniwersalny Feeder 2.0 (wszystkie gry PC) | RTX 20/30/40/50 | DX11 / DX12 / Vulkan / OpenGL",
    "Badge100": "✓ W 100% ZGODNA (natywny DLSS)",
    "BadgeDX12": "✓ ZGODNA (DirectX 12)",
    "BadgeBridge": "✓ ZGODNA PRZEZ OPTISCALER (FSR2/XeSS → DLSS 5)",
    "BadgeFeeder": "✓ UNIWERSALNA (Feeder DLSS 5 • 100% natywne DLAA)",
    "BadgeUnsupported": "✗ BRAK OBSŁUGI",
    "MsgReady": "Gotowe. Wybierz grę z biblioteki lub wskaż folder.",
    "MsgScanning": "Skanowanie dysków ({0}) i odczyt plików wykonywalnych oraz ikon...",
    "MsgScanDone": "Skanowanie zakończone! Wczytano {0} gier, posortowano według zgodności.",
    "MsgPayloadLoaded": "Oficjalny pakiet 1 Click DLSS 5 wczytany automatycznie.",
    "MsgPayloadNotFound": "Nie znaleziono pakietu streamline.zip w domyślnym folderze. W razie potrzeby użyj [ZMIEŃ ZIP].",
    "MsgScanProgressTitle": "Skanowanie gier...",
    "MsgScanFolder": "Skanowanie: {0}",
    "MsgScanProgressDrive": "Skanowanie dysku {0} ({1}/{2})...",
    "MsgLibraryEmpty": "Kliknij [SKANUJ FOLDERY], aby wykryć gry, lub [WSKAŻ GRĘ], aby wybrać folder ręcznie.",
    "MsgSelected": "Wybrana gra: {0} ({1})",
    "SuccessTitle": "1 Click DLSS 5 - Instalacja zakończona",
    "SuccessMsg": "DLSS 5 zainstalowany pomyślnie!\n\n1. Kliknij [URUCHOM GRĘ] lub otwórz grę.\n2. Naciśnij klawisz [Home] -> zakładka Add-ons -> DLSS 5.\n3. Ciesz się rekonstrukcją neuronową AI!",
    "RestoreTitle": "1 Click DLSS 5 - Przywracanie zakończone",
    "RestoreMsg": "Gra przywrócona do stanu fabrycznego! Usunięto wszystkie wstrzyknięte pliki, shadery i dzienniki.",
    "ConfirmInstallTitle": "1 Click DLSS 5 - Potwierdź instalację",
    "ConfirmInstallDirect": "Zainstalować DLSS 5 (tryb bezpośredni) w:\n{0}\n\nWykryto natywny DLSS. Zostaną wstrzyknięte Streamline + RenoDX.\n\nKontynuować?",
    "ConfirmInstallBridge": "Zainstalować DLSS 5 (mostek OptiScaler) w:\n{0}\n\nWykryto {1}. OptiScaler przekieruje wywołania do renderowania neuronowego DLSS.\n\nKontynuować?",
    "ConfirmInstallFeeder": "Zainstalować DLSS 5 (tryb uniwersalnego Feedera) w:\n{0}\n\nDLSS5-Feeder + LumeniteFX wygenerują w 100% natywny kontrakt DLAA dla renderowania neuronowego DLSS 5.\n\nKontynuować?",
    "ConfirmUninstallTitle": "1 Click DLSS 5 - Potwierdź przywracanie",
    "ConfirmUninstall": "Usunąć WSZYSTKIE pliki DLSS 5 i przywrócić grę do stanu fabrycznego?\n\n{0}\n\nTej operacji nie można cofnąć.",
    "MsgUnsupported": "W tej grze nie da się wykonać wstrzyknięcia.",
    "ConfirmForceInstallTitle": "1 Click DLSS 5 - Instalacja uniwersalnego Feedera",
    "ConfirmForceInstall": "Zainstalować DLSS 5 (tryb uniwersalnego Feedera) w:\n{0}\n\nZostanie wdrożony DLSS5-Feeder z przepływem optycznym LumeniteFX dla renderowania neuronowego DLSS 5.\n\nKontynuować?",
    "MsgInstalledAlready": "[JUŻ ZAINSTALOWANO]",
    "MsgModeDirect": "Tryb: Bezpośredni (natywny DLSS)",
    "MsgModeBridge": "Tryb: Mostek OptiScaler ({0})",
    "MsgModeFeeder": "Tryb: Uniwersalny Feeder (syntetyczne 100% natywne DLAA)",
    "RemHeaderDirect": "⚡ TRYB 1: BEZPOŚREDNI (DUŻY WZROST FPS Z NATYWNYM DLSS)",
    "RemTextDirect": "W menu gry: WŁĄCZ 'NVIDIA DLSS' (tryb Jakość lub Wydajność), aby uzyskać duży wzrost FPS dzięki rekonstrukcji neuronowej DLSS 5!",
    "RemHeaderBridge": "⚡ TRYB 2: MOSTEK OPTISCALER (WZROST FPS PRZEZ FSR2/XeSS)",
    "RemTextBridge": "W menu gry: WŁĄCZ FSR2 lub XeSS w trybie Jakość. Mostek OptiScaler przekieruje je do DLSS 5 wraz ze wzrostem FPS!",
    "RemHeaderFeeder": "⚡ TRYB 3: UNIWERSALNY FEEDER (100% NATYWNE DLAA BEZ SKALOWANIA)",
    "RemTextFeeder": "W menu gry: pozostaw DLSS/skalowanie WYŁĄCZONE (100% natywna rozdzielczość lub DLAA). DLSS 5 i przepływ optyczny zadziałają bezpośrednio na czystej klatce, bez konfliktu dwóch AI!",
    "GuideTitle": "1 Click DLSS 5 - Poradnik trybów i optymalizacji",
    "DlgSelectGameFolder": "Wybierz folder główny gry.",
    "DlgSelectZip": "Wybierz plik ZIP z pakietem 1 Click DLSS 5",
    "ZipFilter": "Pakiet ZIP (*.zip);;Wszystkie pliki (*.*)",
    "MsgVerifyOk": "Weryfikacja zakończona pomyślnie! Gra jest w 100% gotowa na 1 Click DLSS 5.",
    "MsgNoGameTitle": "Nie wybrano gry",
    # Folder-based library (replaces the drive picker).
    "FoldersLabel": "Foldery z grami:",
    "BtnAddFolder": "\U0001f4c1 DODAJ FOLDER",
    "BtnRemoveFolder": "✖ USUŃ FOLDER",
    "BtnScanFolders": "\U0001f50d SKANUJ FOLDERY",
    "BtnRefresh": "\U0001f504 ODŚWIEŻ LISTĘ",
    "ColPathShort": "Lokalizacja",
    "NoFolders": "Nie dodano żadnego folderu. Kliknij [DODAJ FOLDER], aby wskazać, gdzie szukać gier.",
    "FolderAdded": "Dodano folder: {0}",
    "FolderExists": "Ten folder jest już dodany: {0}",
    "FolderRemoved": "Usunięto folder: {0}",
    "MsgScanningFolders": "Skanowanie {0} dodanych folderów...",
    "MsgLibrarySaved": "Zapisano bibliotekę: {0} gier.",
    "MsgLibraryLoaded": "Wczytano bibliotekę: {0} zapisanych gier.",
    "MsgRefreshing": "Sprawdzanie, które gry nadal znajdują się na dysku...",
    "MsgRefreshDone": "Odświeżanie zakończone: {0} obecnych, {1} brakujących.",
    "MsgRefreshTitle": "Odświeżanie listy...",
    "BadgeMissing": "✗ NIE ZNALEZIONO FOLDERU",
    "ConfirmPruneTitle": "1 Click DLSS 5 - Usuń brakujące",
    "ConfirmPrune": "{0} gier nie istnieje już na dysku.\n\nUsunąć je z listy?",
    "MsgPruned": "Usunięto z listy {0} brakujących gier.",
    "ConfirmRemoveFolderTitle": "1 Click DLSS 5 - Usuń folder",
    "ConfirmRemoveFolder": "Usunąć ten folder wraz ze znalezionymi w nim grami?\n\n{0}",
    "DlgSelectScanFolder": "Wybierz folder zawierający gry",
    "MsgAddDefaults": "Wykryto i dodano {0} domyślnych folderów.",
    "ShowUncertain": "Pokaż pozycje nierozpoznane jako gry",
    "UncertainHidden": "Ukryto {0} folderów, które nie wyglądają na gry (zaznacz pole, aby je zobaczyć).",
    "TagUncertain": "?",
    "ColNameSource": "Źródło nazwy",
    "BtnLayoutToggle": "🔁 UKŁAD",
    "TipLayoutHorizontal": "Przełącz na układ pionowy (biblioteka u góry)",
    "TipLayoutVertical": "Przełącz na układ poziomy (obok siebie)",
    "ColState": "Status",
    "StateDetected": "Wykryta",
    "StateInstalledDirect": "DLSS 5 zainstalowany (Bezpośredni)",
    "StateInstalledBridge": "DLSS 5 zainstalowany (OptiScaler)",
    "StateInstalledFeeder": "DLSS 5 zainstalowany (Feeder)",
    "StateUnrecognised": "Nierozpoznana jako gra",
    "StateMissing": "Brak folderu",
    "StateNoExe": "Brak pliku 64-bit",
    "InstalledTag": "[ZAINSTALOWANO]",
}

GUIDE_PL = (
    "PEŁNY PORADNIK: KTÓRY TRYB WYBRAĆ W 1 CLICK DLSS 5?\n\n"
    "==================================================================\n"
    "\U0001f7e2 TRYB 1: BEZPOŚREDNI (dla gier z natywną obsługą DLSS)\n"
    " - CEL: Duży wzrost FPS (+50% do +100%) + rekonstrukcja neuronowa.\n"
    " - W MENU GRY: WŁĄCZ 'NVIDIA DLSS Super Resolution' (tryb Jakość, Zrównoważony lub Wydajność).\n"
    " - JAK TO DZIAŁA: Gra renderuje wewnętrznie w niższej rozdzielczości, a DLSS 5 rekonstruuje obraz do 4K/1440p na podstawie wektorów ruchu z silnika gry.\n\n"
    "\U0001f535 TRYB 2: MOSTEK OPTISCALER (dla gier mających tylko FSR2 lub XeSS)\n"
    " - CEL: Wzrost FPS w grach bez natywnego DLSS.\n"
    " - W MENU GRY: WŁĄCZ FSR2 lub XeSS w trybie JAKOŚĆ.\n"
    " - JAK TO DZIAŁA: Mostek przechwytuje wywołania FSR2 i przekazuje je do modelu neuronowego DLSS 5.\n\n"
    "\U0001f7e3 TRYB 3: UNIWERSALNY FEEDER (dla KAŻDEJ gry PC / 100% natywnie)\n"
    " - CEL: Neuronowa rekonstrukcja oświetlenia i materiałów w pełnej rozdzielczości natywnej.\n"
    " - W MENU GRY: Pozostaw DLSS/skalowanie WYŁĄCZONE (graj w 100% natywnej rozdzielczości z TAA/DLAA).\n"
    " - ZASADA KRYTYCZNA: W trybie 3 NIE włączaj DLSS Super Resolution w grze, aby uniknąć rozmycia od podwójnego AI. Feeder wstrzykuje AI i przepływ optyczny LumeniteFX bezpośrednio na czystą klatkę!\n\n"
    "==================================================================\n"
    "\U0001f4a1 ZŁOTA RADA NA MAKSYMALNĄ PŁYNNOŚĆ (VSYNC):\n"
    " - Wyłącz synchronizację pionową (V-Sync) w menu gry, aby uniknąć mikroprzycięć przy współpracy z łańcuchem wymiany DirectX/ReShade.\n"
    " - Użyj G-Sync / FreeSync albo ogranicz liczbę klatek w Panelu sterowania NVIDIA, aby uzyskać w pełni płynny obraz.\n\n"
    "==================================================================\n"
    "SKRÓTY KLAWISZOWE W GRZE:\n"
    " - [F6]: Włącza / wyłącza DLSS 5 w czasie rzeczywistym do porównania na tej samej klatce!\n"
    " - [F5]: Zrzut ekranu do porównania A/B.\n"
    " - [Home] lub [Pos1]: Otwiera pełne menu ReShade / RenoDX."
)

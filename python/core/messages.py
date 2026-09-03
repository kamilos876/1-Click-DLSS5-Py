"""Message keys for the diagnostics log, and their translations.

The core layer must not decide what language the user reads. Instead of
formatted sentences, it emits a key plus its arguments; the UI turns those into
text in the active language. Keeping the tables here rather than in i18n.py
keeps the UI's string table about the interface, not about internals.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any

SEPARATOR = "=" * 58


@dataclass(frozen=True)
class Message:
    """One log line: a key and the values that fill its placeholders."""

    key: str
    args: tuple[Any, ...] = field(default_factory=tuple)

    def render(self, table: dict[str, str]) -> str:
        """Format this message using ``table``; fall back to the key itself."""
        template = table.get(self.key)
        if template is None:
            # An untranslated key is still more useful than nothing.
            return f"{self.key} {' '.join(str(a) for a in self.args)}".strip()
        try:
            return template.format(*self.args)
        except (IndexError, KeyError):
            return template


def msg(key: str, *args: Any) -> Message:
    return Message(key, tuple(args))


EN = {
    # Compatibility report
    "GameRoot": "Game root directory: {0}",
    "TargetExe": "Target executable: {0}",
    "InjectFolder": "Exact injection folder: {0}",
    "NativeDlssFound": "Native DLSS detected: {0}",
    "NoNativeDlss": "No nvngx_dlss.dll found. Make sure the game supports DirectX 12.",
    "GpuFullySupported": "Fully supported GPU: {0} (universal RTX 20/30/40/50 support active)",
    "GpuDetected": "GPU detected: {0}",
    "DriverVersion": "NVIDIA driver: {0}",
    "FolderWritable": "Folder write permissions: the install folder is writable.",
    "FolderNotWritable": "No write permission for {0}. Run as Administrator.",
    "GameNotRunning": "Process status: the game is not currently running.",
    "GameIsRunning": "{0} is running. Close the game before installing.",
    "PayloadValidated": "1 Click DLSS 5 package validated successfully.",
    "VerifyFailed": "The compatibility check failed. Review the errors above.",
    # Install
    "ModeSelected": "Selected injection mode: {0} (detected in engine: {1})",
    "GraphicsApiDetected": "Graphics API detected: {0} (automated proxy injection)",
    "DependencyRestored": "Restored {0}: the executable imports it and the game's copy was missing.",
    "NativeStreamlineKept": "Game ships its own Streamline; keeping it and leaving {0} module(s) untouched.",
    "LegacyAddonRemoved": "Previous add-on version removed: {0}",
    "Separator": SEPARATOR,
    "InstallSucceeded": "1 CLICK DLSS 5 NEURAL INSTALLED SUCCESSFULLY!",
    "HintDirect": "Mode: DIRECT | In game: enable DLSS (Quality) -> [Home] -> Add-ons -> DLSS 5",
    "HintBridge": "Mode: OPTISCALER BRIDGE ({0}) | In game: press [Home] -> Add-ons -> DLSS 5",
    "HintFeeder": "Mode: UNIVERSAL FEEDER (100% native DLAA) | In game: press [Home] -> Add-ons -> DLSS 5",
    "ModeDirectStart": "DIRECT mode: injecting Streamline + RenoDX (native DLSS detected)...",
    "ModeBridgeStart": "OPTISCALER BRIDGE mode: {0} present. Redirecting to DLSS Neural...",
    "ModeFeederStart": "UNIVERSAL FEEDER mode: enabling DLSS5-Feeder with LumeniteFX optical flow (100% native DLAA)...",
    "PluginUpdated": "Updating engine plugin in: {0}",
    "OptiScalerInstalled": "OptiScaler installed as version.dll (proxy DLL).",
    "OptiScalerMissing": "OptiScaler.dll not found in payload\\optiscaler\\. Check the installation.",
    "FeederX64Installed": "DLSS5-Feeder x64 add-on installed successfully.",
    "FeederX86Installed": "DLSS5-Feeder x86 add-on installed for a 32-bit game.",
    "ShadersInstalled": "LumeniteFX and DLSS5_Feed.fx shaders installed in reshade-shaders\\Shaders\\.",
    "TexturesInstalled": "Blue-noise textures installed in reshade-shaders\\Textures\\.",
    "FeederConfigured": "Feeder configuration applied to ReShade.ini (LumeniteFX Kernel 2.0 -> DLSS5_Feed -> RenoDX).",
    # Restore
    "RestoreStart": "Restoring factory files in: {0}",
    "FileRestored": "File restored: {0}",
    "PluginFileRestored": "Plugin file restored: {0}",
    "RestoreDone": "Game fully restored to its factory state!",
    # Launch
    "Launching": "Launching: {0}",
    # Payload
    "PayloadSelectZip": "Select the 1 Click DLSS 5 package ZIP file.",
    "PayloadZipMissing": "The selected ZIP file does not exist: {0}",
    "PayloadAddonMissing": "{0} was not found in the payload folder.",
    "PayloadExtracting": "Extracting the 1 Click DLSS 5 package to the local cache...",
    "PayloadFromCache": "No ZIP found; reusing the DLSS 5 runtime extracted by an earlier run.",
    "PayloadExtractFailed": "Failed to extract the DLSS 5 package: {0}",
    "PayloadNoRuntime": "The supplied ZIP does not contain a valid 64-bit nvngx_dlssnr.dll.",
    "ReShadeDownloading": "Downloading the official ReShade 6.8.0 installer with add-on support...",
    "ReShadeDownloadFailed": "Failed to download ReShade: {0}",
    "ReShadePresent": "ReShade with add-on support ({0}) is active and intact.",
    "ReShadeRenamed": "ReShade configured as {0} for native {1} compatibility.",
    "ReShadeRunFailed": "Failed to run the ReShade installer: {0}",
    "ReShadeExitCode": "The ReShade installer returned error code {0}.",
    # Detection
    "SelectGameFirst": "Select a game from the library, or choose a folder.",
    "PathNotFound": "The path does not exist on disk: {0}",
    "NotAnExe": "The selected file is not an executable (.exe).",
    "NotAWindowsExe": "The selected file is not a valid Windows executable.",
    "NoMainExe": "No main executable was found in this game folder. Select the .exe directly.",
    # Install worker
    "FileAccessDenied": "File access failure: {0}. Close the game and run the program as Administrator.",
    "InstallUnexpected": "Unexpected error during installation: {0}",
    "ScanFailed": "Failed to scan folders: {0}",
    "RefreshFailed": "Failed to refresh the list: {0}",
    "InstallCancelled": "Installation cancelled by the user.",
    "RestoreCancelled": "Restoration cancelled by the user.",
    "PayloadSelected": "DLSS package selected: {0}",
    "ElevationFailed": "Could not elevate privileges. Continuing without Administrator rights.",
}

PL = {
    "GameRoot": "Folder główny gry: {0}",
    "TargetExe": "Docelowy plik wykonywalny: {0}",
    "InjectFolder": "Docelowy folder instalacji: {0}",
    "NativeDlssFound": "Wykryto natywny DLSS: {0}",
    "NoNativeDlss": "Nie znaleziono pliku nvngx_dlss.dll. Upewnij się, że gra obsługuje DirectX 12.",
    "GpuFullySupported": "W pełni obsługiwana karta: {0} (uniwersalne wsparcie RTX 20/30/40/50 aktywne)",
    "GpuDetected": "Wykryta karta graficzna: {0}",
    "DriverVersion": "Sterownik NVIDIA: {0}",
    "FolderWritable": "Uprawnienia zapisu: folder instalacji jest zapisywalny.",
    "FolderNotWritable": "Brak uprawnień do zapisu w {0}. Uruchom jako administrator.",
    "GameNotRunning": "Stan procesu: gra nie jest obecnie uruchomiona.",
    "GameIsRunning": "{0} jest uruchomiony. Zamknij grę przed instalacją.",
    "PayloadValidated": "Pakiet 1 Click DLSS 5 zweryfikowany pomyślnie.",
    "VerifyFailed": "Sprawdzenie zgodności nie powiodło się. Przejrzyj błędy powyżej.",
    "ModeSelected": "Wybrany tryb instalacji: {0} (wykryto w silniku: {1})",
    "GraphicsApiDetected": "Wykryte API graficzne: {0} (automatyczne wstrzykiwanie proxy)",
    "DependencyRestored": "Przywrócono {0}: plik wykonywalny go wymaga, a kopia gry była nieobecna.",
    "NativeStreamlineKept": "Gra ma własny Streamline; zachowuję go i pomijam {0} moduł(y).",
    "LegacyAddonRemoved": "Usunięto poprzednią wersję dodatku: {0}",
    "Separator": SEPARATOR,
    "InstallSucceeded": "1 CLICK DLSS 5 NEURAL ZAINSTALOWANY POMYŚLNIE!",
    "HintDirect": "Tryb: BEZPOŚREDNI | W grze: włącz DLSS (Jakość) -> [Home] -> Add-ons -> DLSS 5",
    "HintBridge": "Tryb: MOSTEK OPTISCALER ({0}) | W grze: naciśnij [Home] -> Add-ons -> DLSS 5",
    "HintFeeder": "Tryb: UNIWERSALNY FEEDER (100% natywne DLAA) | W grze: naciśnij [Home] -> Add-ons -> DLSS 5",
    "ModeDirectStart": "Tryb BEZPOŚREDNI: wstrzykiwanie Streamline + RenoDX (wykryto natywny DLSS)...",
    "ModeBridgeStart": "Tryb MOSTEK OPTISCALER: wykryto {0}. Przekierowanie do DLSS Neural...",
    "ModeFeederStart": "Tryb UNIWERSALNY FEEDER: włączanie DLSS5-Feeder z przepływem optycznym LumeniteFX (100% natywne DLAA)...",
    "PluginUpdated": "Aktualizowanie wtyczki silnika w: {0}",
    "OptiScalerInstalled": "OptiScaler zainstalowany jako version.dll (biblioteka pośrednicząca).",
    "OptiScalerMissing": "Nie znaleziono OptiScaler.dll w payload\\optiscaler\\. Sprawdź instalację programu.",
    "FeederX64Installed": "Dodatek DLSS5-Feeder x64 zainstalowany pomyślnie.",
    "FeederX86Installed": "Dodatek DLSS5-Feeder x86 zainstalowany dla gry 32-bitowej.",
    "ShadersInstalled": "Shadery LumeniteFX i DLSS5_Feed.fx zainstalowane w reshade-shaders\\Shaders\\.",
    "TexturesInstalled": "Tekstury szumu niebieskiego zainstalowane w reshade-shaders\\Textures\\.",
    "FeederConfigured": "Konfiguracja Feedera zastosowana w ReShade.ini (LumeniteFX Kernel 2.0 -> DLSS5_Feed -> RenoDX).",
    "RestoreStart": "Przywracanie plików fabrycznych w: {0}",
    "FileRestored": "Przywrócono plik: {0}",
    "PluginFileRestored": "Przywrócono plik wtyczki: {0}",
    "RestoreDone": "Gra w pełni przywrócona do stanu fabrycznego!",
    "Launching": "Uruchamianie: {0}",
    "PayloadSelectZip": "Wybierz plik ZIP z pakietem 1 Click DLSS 5.",
    "PayloadZipMissing": "Wybrany plik ZIP nie istnieje: {0}",
    "PayloadAddonMissing": "Nie znaleziono pliku {0} w folderze payload.",
    "PayloadExtracting": "Rozpakowywanie pakietu 1 Click DLSS 5 do lokalnej pamięci podręcznej...",
    "PayloadFromCache": "Nie znaleziono pliku ZIP; używam środowiska DLSS 5 rozpakowanego przy wcześniejszym uruchomieniu.",
    "PayloadExtractFailed": "Nie udało się rozpakować pakietu DLSS 5: {0}",
    "PayloadNoRuntime": "Podany plik ZIP nie zawiera prawidłowej 64-bitowej biblioteki nvngx_dlssnr.dll.",
    "ReShadeDownloading": "Pobieranie oficjalnego instalatora ReShade 6.8.0 z obsługą dodatków...",
    "ReShadeDownloadFailed": "Nie udało się pobrać ReShade: {0}",
    "ReShadePresent": "ReShade z obsługą dodatków ({0}) jest aktywny i nienaruszony.",
    "ReShadeRenamed": "ReShade skonfigurowany jako {0} dla natywnej zgodności z {1}.",
    "ReShadeRunFailed": "Nie udało się uruchomić instalatora ReShade: {0}",
    "ReShadeExitCode": "Instalator ReShade zwrócił kod błędu {0}.",
    "SelectGameFirst": "Wybierz grę z biblioteki lub wskaż folder.",
    "PathNotFound": "Ścieżka nie istnieje na dysku: {0}",
    "NotAnExe": "Wybrany plik nie jest plikiem wykonywalnym (.exe).",
    "NotAWindowsExe": "Wybrany plik nie jest prawidłowym plikiem wykonywalnym systemu Windows.",
    "NoMainExe": "Nie znaleziono głównego pliku wykonywalnego w tym folderze gry. Wskaż plik .exe bezpośrednio.",
    "FileAccessDenied": "Błąd dostępu do pliku: {0}. Zamknij grę i uruchom program jako Administrator.",
    "InstallUnexpected": "Nieoczekiwany błąd podczas instalacji: {0}",
    "ScanFailed": "Nie udało się przeskanować folderów: {0}",
    "RefreshFailed": "Nie udało się odświeżyć listy: {0}",
    "InstallCancelled": "Instalacja anulowana przez użytkownika.",
    "RestoreCancelled": "Przywracanie anulowane przez użytkownika.",
    "PayloadSelected": "Wybrano pakiet DLSS: {0}",
    "ElevationFailed": "Nie udało się podnieść uprawnień. Kontynuuję bez praw administratora.",
}

PT = {
    "GameRoot": "Pasta raiz do jogo: {0}",
    "TargetExe": "Executavel alvo: {0}",
    "InjectFolder": "Pasta exata de injecao: {0}",
    "NativeDlssFound": "DLSS nativo detectado: {0}",
    "NoNativeDlss": "Nenhuma nvngx_dlss.dll encontrada. Certifique-se de que o jogo suporta DirectX 12.",
    "GpuFullySupported": "GPU totalmente compativel: {0} (suporte universal RTX 20/30/40/50 ativo)",
    "GpuDetected": "GPU detectada: {0}",
    "DriverVersion": "Driver NVIDIA: {0}",
    "FolderWritable": "Permissoes de escrita: a pasta de instalacao e gravavel.",
    "FolderNotWritable": "Sem permissao de escrita em {0}. Execute como Administrador.",
    "GameNotRunning": "Status do processo: o jogo nao esta em execucao.",
    "GameIsRunning": "{0} esta em execucao. Feche o jogo antes de instalar.",
    "PayloadValidated": "Pacote 1 Click DLSS 5 validado com sucesso.",
    "VerifyFailed": "A verificacao de compatibilidade falhou. Verifique os erros acima.",
    "ModeSelected": "Modo de injecao selecionado: {0} (detectado na engine: {1})",
    "GraphicsApiDetected": "API grafica detectada: {0} (injecao de proxy automatizada)",
    "DependencyRestored": "Restaurado {0}: o executavel o importa e a copia do jogo estava ausente.",
    "NativeStreamlineKept": "O jogo tem seu proprio Streamline; mantendo-o e preservando {0} modulo(s).",
    "LegacyAddonRemoved": "Versao anterior do add-on removida: {0}",
    "Separator": SEPARATOR,
    "InstallSucceeded": "1 CLICK DLSS 5 NEURAL INSTALADO COM SUCESSO!",
    "HintDirect": "Modo: DIRETO | No jogo: ative DLSS (Qualidade) -> [Home] -> Add-ons -> DLSS 5",
    "HintBridge": "Modo: PONTE OPTISCALER ({0}) | No jogo: pressione [Home] -> Add-ons -> DLSS 5",
    "HintFeeder": "Modo: FEEDER UNIVERSAL (DLAA 100% nativo) | No jogo: pressione [Home] -> Add-ons -> DLSS 5",
    "ModeDirectStart": "Modo DIRETO: injetando Streamline + RenoDX (DLSS nativo detectado)...",
    "ModeBridgeStart": "Modo PONTE OPTISCALER: {0} ativo. Redirecionando para DLSS Neural...",
    "ModeFeederStart": "Modo FEEDER UNIVERSAL: ativando DLSS5-Feeder com fluxo optico LumeniteFX (DLAA 100% nativo)...",
    "PluginUpdated": "Atualizando plugin de engine em: {0}",
    "OptiScalerInstalled": "OptiScaler instalado como version.dll (proxy DLL).",
    "OptiScalerMissing": "OptiScaler.dll nao encontrado em payload\\optiscaler\\. Verifique a instalacao.",
    "FeederX64Installed": "Add-on DLSS5-Feeder x64 instalado com sucesso.",
    "FeederX86Installed": "Add-on DLSS5-Feeder x86 instalado para jogo de 32-bit.",
    "ShadersInstalled": "Shaders LumeniteFX e DLSS5_Feed.fx instalados em reshade-shaders\\Shaders\\.",
    "TexturesInstalled": "Texturas de ruido azul instaladas em reshade-shaders\\Textures\\.",
    "FeederConfigured": "Configuracao do Feeder aplicada no ReShade.ini (LumeniteFX Kernel 2.0 -> DLSS5_Feed -> RenoDX).",
    "RestoreStart": "Restaurando arquivos de fabrica em: {0}",
    "FileRestored": "Arquivo restaurado: {0}",
    "PluginFileRestored": "Arquivo de plugin restaurado: {0}",
    "RestoreDone": "Jogo 100% restaurado ao estado de fabrica!",
    "Launching": "Iniciando: {0}",
    "PayloadSelectZip": "Selecione o arquivo ZIP do pacote 1 Click DLSS 5.",
    "PayloadZipMissing": "O arquivo ZIP selecionado nao existe: {0}",
    "PayloadAddonMissing": "O arquivo {0} nao foi encontrado na pasta payload.",
    "PayloadExtracting": "Extraindo o pacote 1 Click DLSS 5 para o cache local...",
    "PayloadFromCache": "ZIP nao encontrado; reutilizando o runtime DLSS 5 extraido em uma execucao anterior.",
    "PayloadExtractFailed": "Falha ao extrair o pacote DLSS 5: {0}",
    "PayloadNoRuntime": "O ZIP fornecido nao contem uma nvngx_dlssnr.dll valida de 64-bit.",
    "ReShadeDownloading": "Baixando o instalador oficial do ReShade 6.8.0 com suporte a add-ons...",
    "ReShadeDownloadFailed": "Falha ao baixar o ReShade: {0}",
    "ReShadePresent": "ReShade com suporte a add-ons ({0}) ativo e integro.",
    "ReShadeRenamed": "ReShade configurado como {0} para compatibilidade nativa com {1}.",
    "ReShadeRunFailed": "Falha ao executar o instalador do ReShade: {0}",
    "ReShadeExitCode": "O instalador do ReShade retornou o codigo de erro {0}.",
    "SelectGameFirst": "Selecione um jogo na biblioteca ou informe a pasta.",
    "PathNotFound": "O caminho nao existe no disco: {0}",
    "NotAnExe": "O arquivo selecionado nao e um executavel (.exe).",
    "NotAWindowsExe": "O arquivo selecionado nao e um executavel valido do Windows.",
    "NoMainExe": "Nenhum executavel principal foi encontrado nesta pasta de jogo. Selecione o .exe diretamente.",
    "FileAccessDenied": "Falha de acesso a arquivo: {0}. Feche o jogo e execute o programa como Administrador.",
    "InstallUnexpected": "Erro inesperado durante a instalacao: {0}",
    "ScanFailed": "Falha ao escanear pastas: {0}",
    "RefreshFailed": "Falha ao atualizar a lista: {0}",
    "InstallCancelled": "Instalacao cancelada pelo usuario.",
    "RestoreCancelled": "Restauracao cancelada pelo usuario.",
    "PayloadSelected": "Pacote DLSS selecionado: {0}",
    "ElevationFailed": "Nao foi possivel elevar privilegios. Continuando sem direitos de Administrador.",
}

_TABLES = {"EN": EN, "PL": PL, "PT": PT}


def get_messages(lang: str) -> dict[str, str]:
    """Return the message table for ``lang``, falling back to English."""
    return _TABLES.get(lang, EN)


def render(message: "Message | str", lang: str) -> str:
    """Render a Message in ``lang``; plain strings pass through untouched."""
    if isinstance(message, Message):
        return message.render(get_messages(lang))
    return str(message)

"""UI strings for the Portuguese and English interfaces.

Keys mirror the PowerShell Get-Dict hashtable one-for-one so the two versions
of the app stay comparable. Placeholders use str.format positional fields.
"""
from __future__ import annotations

from .i18n_pl import GUIDE_PL, PL

PT = {
    "Eyebrow": "ECOSSISTEMA OFICIAL RENO DX • RUNTIME NEURAL UNIVERSAL (SÉRIES RTX 20 / 30 / 40 / 50)",
    "Title": "1 CLICK DLSS 5",
    "Subtitle": "Interface Estilo Steam • Injeção Neural em 1-Clique • DLSS 5 Universal Feeder para QUALQUER Jogo de PC",
    "LibraryTitle": "BIBLIOTECA DE JOGOS E COMPATIBILIDADE",
    "SearchPlaceholder": "Pesquisar jogos instalados...",
    "DriveLabel": "Disco:",
    "AllDrives": "Todos os Discos",
    "BtnScanDrives": "\U0001f50d ESCANEAR DISCOS",
    "BtnBrowse": "\U0001f4c1 PROCURAR JOGO",
    "ColGame": "Título do Jogo",
    "ColStatus": "Compatibilidade DLSS 5",
    "ColPath": "Local de Instalação",
    "InspectorTitle": "PAINEL DE INJEÇÃO E DETALHES DO JOGO",
    "NoGameSelected": "Selecione um jogo na biblioteca ao lado ou procure uma pasta manualmente.",
    "RootFolderLabel": "Pasta Raiz do Jogo:",
    "InjectFolderLabel": "Pasta Exata de Aplicação DLSS 5:",
    "TargetExeLabel": "Executável Principal do Jogo:",
    "DlssStatusLabel": "DLSS Nativo Detectado:",
    "LblInjectionMode": "Modo de Injeção DLSS 5:",
    "OptAutoRecommended": "⚡ Automático (Recomendado: {0})",
    "OptModeDirect": "\U0001f7e2 Modo 1: Direto (Streamline + DLSS Nativo)",
    "OptModeBridge": "\U0001f535 Modo 2: Ponte OptiScaler (FSR2/XeSS → DLSS 5)",
    "OptModeFeeder": "\U0001f7e3 Modo 3: Feeder Universal (DLAA 100% Nativo)",
    "ModeNameDirect": "Modo 1 - Direto",
    "ModeNameBridge": "Modo 2 - Ponte OptiScaler",
    "ModeNameFeeder": "Modo 3 - Feeder Universal",
    "ReminderHeader": "⚡ REQUISITO OBRIGATÓRIO NO JOGO:",
    "ReminderText": "Dentro do jogo, certifique-se de ATIVAR o 'NVIDIA DLSS Super Resolution' (Qualidade ou Desempenho) nas opções gráficas para que o DLSS 5 Neural funcione!",
    "PayloadTitle": "Pacote DLSS 5 (Streamline 2.13 Integrado):",
    "BtnChangeZip": "\U0001f4e6 TROCAR ZIP",
    "OptReShade": "Instalar ReShade 6.8.0 (Suporte a Add-ons)",
    "OptFull": "Substituição Completa de DLLs Streamline",
    "BtnVerify": "\U0001f50d VERIFICAR",
    "BtnInstall": "\U0001f680 1-CLIQUE: INSTALAR DLSS 5",
    "BtnLaunch": "▶️ INICIAR JOGO",
    "BtnUninstall": "↩️ RESTAURAR ORIGINAL",
    "BtnOpenFolder": "\U0001f4c2 ABRIR PASTA",
    "BtnInstructions": "\U0001f4d6 GUIA NO JOGO",
    "StatusHeading": "DIAGNÓSTICO E LOG DO SISTEMA EM TEMPO REAL",
    "Footer": "1 Click DLSS 5 v1.5.1 | Feeder Universal 2.0 (Qualquer Jogo de PC) | RTX 20/30/40/50 | DX11 / DX12 / Vulkan / OpenGL",
    "Badge100": "✓ 100% COMPATÍVEL (DLSS Nativo)",
    "BadgeDX12": "✓ COMPATÍVEL (DirectX 12)",
    "BadgeBridge": "✓ COMPATÍVEL VIA OPTISCALER (FSR2/XeSS → DLSS 5)",
    "BadgeFeeder": "✓ UNIVERSAL (Modo Feeder DLSS 5 • DLAA 100% Nativo)",
    "BadgeUnsupported": "✗ SEM SUPORTE",
    "MsgReady": "Pronto. Escolha um jogo na biblioteca visual ou selecione uma pasta.",
    "MsgScanning": "Escaneando discos ({0}) e extraindo ícones reais dos executáveis...",
    "MsgScanDone": "Varredura concluída! {0} jogos carregados na biblioteca e ordenados por compatibilidade.",
    "MsgPayloadLoaded": "Pacote oficial 1 Click DLSS 5 embutido carregado com sucesso.",
    "MsgPayloadNotFound": "Pacote streamline.zip nao encontrado na pasta padrao. Use [TROCAR ZIP] se necessario.",
    "MsgScanProgressTitle": "Escaneando Jogos...",
    "MsgScanFolder": "Escaneando: {0}",
    "MsgScanProgressDrive": "Escaneando disco {0} ({1}/{2})...",
    "MsgLibraryEmpty": "Clique em [ESCANEAR DISCOS] para descobrir seus jogos, ou [PROCURAR JOGO] para selecionar uma pasta manualmente.",
    "MsgSelected": "Jogo selecionado: {0} ({1})",
    "SuccessTitle": "1 Click DLSS 5 - Instalação Concluída",
    "SuccessMsg": "DLSS 5 instalado com sucesso!\n\n1. Clique em [INICIAR JOGO] ou abra o jogo.\n2. Pressione a tecla [Home] -> Verifique a aba Add-ons.\n3. Aproveite a Reconstrução Neural com IA!",
    "RestoreTitle": "1 Click DLSS 5 - Restauração Completa",
    "RestoreMsg": "Jogo restaurado com sucesso ao estado de fábrica original! Todos os arquivos injetados, shaders e logs foram removidos.",
    "ConfirmInstallTitle": "1 Click DLSS 5 - Confirmar Instalação",
    "ConfirmInstallDirect": "Instalar DLSS 5 (Modo Direto) em:\n{0}\n\nDLSS nativo detectado. Streamline + RenoDX será injetado.\n\nContinuar?",
    "ConfirmInstallBridge": "Instalar DLSS 5 (Ponte OptiScaler) em:\n{0}\n\n{1} detectado. O OptiScaler redirecionará para a Renderização Neural DLSS.\n\nContinuar?",
    "ConfirmInstallFeeder": "Instalar DLSS 5 (Modo Feeder Universal) em:\n{0}\n\nO DLSS5-Feeder + LumeniteFX sintetizará um contrato DLAA 100% Nativo para a Renderização Neural DLSS 5.\n\nContinuar?",
    "ConfirmUninstallTitle": "1 Click DLSS 5 - Confirmar Restauração",
    "ConfirmUninstall": "Remover TODOS os arquivos DLSS 5 e restaurar o jogo ao estado de fábrica?\n\n{0}\n\nEsta ação não pode ser desfeita.",
    "MsgUnsupported": "Este jogo não pode ser injetado.",
    "ConfirmForceInstallTitle": "1 Click DLSS 5 - Instalação Feeder Universal",
    "ConfirmForceInstall": "Instalar DLSS 5 (Modo Feeder Universal) em:\n{0}\n\nO DLSS5-Feeder com fluxo óptico LumeniteFX será implantado para Renderização Neural DLSS 5.\n\nContinuar?",
    "MsgInstalledAlready": "[JÁ INSTALADO]",
    "MsgModeDirect": "Modo: Direto (DLSS Nativo)",
    "MsgModeBridge": "Modo: Ponte OptiScaler ({0})",
    "MsgModeFeeder": "Modo: Feeder Universal (DLAA Sintético 100% Nativo)",
    # Mode reminder banner, driven by the injection-mode selector.
    "RemHeaderDirect": "⚡ MODO 1: DIRETO (GANHO DE FPS COM DLSS NATIVO)",
    "RemTextDirect": "No menu do jogo: ATIVE o 'NVIDIA DLSS' (no modo Qualidade ou Desempenho) para ganhar muito FPS com a Reconstrução Neural DLSS 5!",
    "RemHeaderBridge": "⚡ MODO 2: PONTE OPTISCALER (GANHO DE FPS VIA FSR2/XeSS)",
    "RemTextBridge": "No menu do jogo: ATIVE o FSR2 ou XeSS no modo Qualidade. A ponte OptiScaler redirecionará para o DLSS 5 com ganho de FPS!",
    "RemHeaderFeeder": "⚡ MODO 3: FEEDER UNIVERSAL (DLAA 100% NATIVO SEM UPSCALE)",
    "RemTextFeeder": "No menu do jogo: Deixe o DLSS/Upscaling DESLIGADO (100% Nativo ou DLAA). O DLSS 5 e o fluxo óptico atuarão direto no frame limpo sem conflito de IA!",
    "GuideTitle": "1 Click DLSS 5 - Guia de Modos e Otimizacao",
    "DlgSelectGameFolder": "Selecione a pasta raiz do jogo.",
    "DlgSelectZip": "Selecione o arquivo ZIP do pacote 1 Click DLSS 5",
    "ZipFilter": "Pacote ZIP (*.zip);;Todos os arquivos (*.*)",
    "MsgVerifyOk": "Verificacao concluida com sucesso! O jogo esta 100% pronto para receber o 1 Click DLSS 5.",
    "MsgNoGameTitle": "Nenhum jogo selecionado",
    # Folder-based library (replaces the drive picker).
    "FoldersLabel": "Pastas de Jogos:",
    "BtnAddFolder": "📁 ADICIONAR PASTA",
    "BtnRemoveFolder": "✖ REMOVER PASTA",
    "BtnScanFolders": "🔍 ESCANEAR PASTAS",
    "BtnRefresh": "🔄 ATUALIZAR LISTA",
    "ColPathShort": "Localizacao",
    "NoFolders": "Nenhuma pasta cadastrada. Clique em [ADICIONAR PASTA] para escolher onde procurar jogos.",
    "FolderAdded": "Pasta adicionada: {0}",
    "FolderExists": "Esta pasta ja esta cadastrada: {0}",
    "FolderRemoved": "Pasta removida: {0}",
    "MsgScanningFolders": "Escaneando {0} pasta(s) cadastrada(s)...",
    "MsgLibrarySaved": "Biblioteca salva: {0} jogo(s).",
    "MsgLibraryLoaded": "Biblioteca carregada: {0} jogo(s) salvos.",
    "MsgRefreshing": "Verificando quais jogos ainda existem no disco...",
    "MsgRefreshDone": "Verificacao concluida: {0} presente(s), {1} ausente(s).",
    "MsgRefreshTitle": "Atualizando Lista...",
    "BadgeMissing": "✗ PASTA NAO ENCONTRADA",
    "ConfirmPruneTitle": "1 Click DLSS 5 - Remover Ausentes",
    "ConfirmPrune": "{0} jogo(s) nao existem mais no disco.\n\nRemover da lista?",
    "MsgPruned": "{0} jogo(s) ausentes removidos da lista.",
    "ConfirmRemoveFolderTitle": "1 Click DLSS 5 - Remover Pasta",
    "ConfirmRemoveFolder": "Remover esta pasta e os jogos encontrados nela?\n\n{0}",
    "DlgSelectScanFolder": "Selecione uma pasta que contem jogos",
    "MsgAddDefaults": "{0} pasta(s) padrao detectada(s) e adicionada(s).",
    "ShowUncertain": "Pokazar itens nao reconhecidos como jogo",
    "UncertainHidden": "{0} pasta(s) ocultada(s) por nao parecerem jogos (marque a caixa para ver).",
    "TagUncertain": "?",
    "ColNameSource": "Fonte do Nome",
    "BtnLayoutToggle": "🔁 LAYOUT",
    "TipLayoutHorizontal": "Alternar para layout vertical (biblioteca em cima)",
    "TipLayoutVertical": "Alternar para layout lado a lado",
    "ColState": "Status",
    "StateDetected": "Detectado",
    "StateInstalledDirect": "DLSS 5 instalado (Direto)",
    "StateInstalledBridge": "DLSS 5 instalado (OptiScaler)",
    "StateInstalledFeeder": "DLSS 5 instalado (Feeder)",
    "StateUnrecognised": "Nao reconhecido como jogo",
    "StateMissing": "Pasta ausente",
    "StateNoExe": "Sem executavel",
    "InstalledTag": "[INSTALADO]",
}

EN = {
    "Eyebrow": "OFFICIAL RENO DX ECOSYSTEM • UNIVERSAL DLSS-NR (RTX 20 / 30 / 40 / 50 SERIES)",
    "Title": "1 CLICK DLSS 5",
    "Subtitle": "Steam-Style Game Center • 1-Click Neural Injection • Universal DLSS 5 Feeder for ANY PC Game",
    "LibraryTitle": "GAME LIBRARY & COMPATIBILITY",
    "SearchPlaceholder": "Search installed games...",
    "DriveLabel": "Drive:",
    "AllDrives": "All Drives",
    "BtnScanDrives": "\U0001f50d SCAN DISKS",
    "BtnBrowse": "\U0001f4c1 BROWSE GAME",
    "ColGame": "Game Title",
    "ColStatus": "DLSS 5 Compatibility",
    "ColPath": "Install Location",
    "InspectorTitle": "SELECTED GAME INSPECTOR & INJECTION",
    "NoGameSelected": "Select a game from the library on the left or browse a game folder.",
    "RootFolderLabel": "Game Root Directory:",
    "InjectFolderLabel": "Exact DLSS 5 Injection Folder:",
    "TargetExeLabel": "Target Game Executable:",
    "DlssStatusLabel": "Native DLSS Detected:",
    "LblInjectionMode": "DLSS 5 Injection Mode:",
    "OptAutoRecommended": "⚡ Automatic (Recommended: {0})",
    "OptModeDirect": "\U0001f7e2 Mode 1: Direct (Streamline + Native DLSS)",
    "OptModeBridge": "\U0001f535 Mode 2: OptiScaler Bridge (FSR2/XeSS → DLSS 5)",
    "OptModeFeeder": "\U0001f7e3 Mode 3: Universal Feeder (100% Native DLAA)",
    "ModeNameDirect": "Mode 1 - Direct",
    "ModeNameBridge": "Mode 2 - OptiScaler Bridge",
    "ModeNameFeeder": "Mode 3 - Universal Feeder",
    "ReminderHeader": "⚡ CRITICAL DLSS PREREQUISITE:",
    "ReminderText": "In-game, make sure to enable 'NVIDIA DLSS Super Resolution' (Quality/Balanced/Performance) in the graphics menu for DLSS 5 Neural Reconstruction to work!",
    "PayloadTitle": "DLSS 5 Payload (Embedded Streamline 2.13):",
    "BtnChangeZip": "\U0001f4e6 CHANGE ZIP",
    "OptReShade": "Install ReShade 6.8.0 (Add-on Support)",
    "OptFull": "Full Streamline DLL Replacement",
    "BtnVerify": "\U0001f50d VERIFY",
    "BtnInstall": "\U0001f680 1-CLICK INSTALL DLSS 5",
    "BtnLaunch": "▶️ LAUNCH GAME",
    "BtnUninstall": "↩️ RESTORE FACTORY",
    "BtnOpenFolder": "\U0001f4c2 OPEN FOLDER",
    "BtnInstructions": "\U0001f4d6 IN-GAME GUIDE",
    "StatusHeading": "REAL-TIME DIAGNOSTICS & SYSTEM LOG",
    "Footer": "1 Click DLSS 5 v1.5.1 | Universal Feeder 2.0 (All PC Games) | RTX 20/30/40/50 | DX11 / DX12 / Vulkan / OpenGL",
    "Badge100": "✓ 100% COMPATIBLE (Native DLSS)",
    "BadgeDX12": "✓ COMPATIBLE (DirectX 12)",
    "BadgeBridge": "✓ COMPATIBLE VIA OPTISCALER (FSR2/XeSS → DLSS 5)",
    "BadgeFeeder": "✓ UNIVERSAL (DLSS 5 Feeder • 100% Native DLAA)",
    "BadgeUnsupported": "✗ UNSUPPORTED",
    "MsgReady": "Ready. Pick a game from your Steam-style library or browse folder.",
    "MsgScanning": "Scanning drives ({0}) and reading game executables and icons...",
    "MsgScanDone": "Scan complete! {0} games loaded into your library, sorted by compatibility.",
    "MsgPayloadLoaded": "Official 1 Click DLSS 5 payload loaded automatically.",
    "MsgPayloadNotFound": "Payload streamline.zip not found in the default folder. Use [CHANGE ZIP] if required.",
    "MsgScanProgressTitle": "Scanning Games...",
    "MsgScanFolder": "Scanning: {0}",
    "MsgScanProgressDrive": "Scanning drive {0} ({1}/{2})...",
    "MsgLibraryEmpty": "Click [SCAN DISKS] to discover your games, or [BROWSE GAME] to select a folder manually.",
    "MsgSelected": "Selected game: {0} ({1})",
    "SuccessTitle": "1 Click DLSS 5 - Installation Complete",
    "SuccessMsg": "DLSS 5 successfully installed!\n\n1. Click [LAUNCH GAME] or open the game.\n2. Press [Home] key -> Check Add-ons tab for DLSS 5.\n3. Enjoy AI Neural Reconstruction!",
    "RestoreTitle": "1 Click DLSS 5 - Restoration Complete",
    "RestoreMsg": "Game successfully restored to clean factory state! All injected files, shaders, and logs were wiped.",
    "ConfirmInstallTitle": "1 Click DLSS 5 - Confirm Installation",
    "ConfirmInstallDirect": "Install DLSS 5 (Direct Mode) on:\n{0}\n\nNative DLSS detected. Streamline + RenoDX will be injected.\n\nContinue?",
    "ConfirmInstallBridge": "Install DLSS 5 (OptiScaler Bridge) on:\n{0}\n\n{1} detected. OptiScaler will redirect to DLSS Neural Rendering.\n\nContinue?",
    "ConfirmInstallFeeder": "Install DLSS 5 (Universal Feeder Mode) on:\n{0}\n\nDLSS5-Feeder + LumeniteFX will synthesize a 100% Native DLAA contract for DLSS 5 Neural Rendering.\n\nContinue?",
    "ConfirmUninstallTitle": "1 Click DLSS 5 - Confirm Restoration",
    "ConfirmUninstall": "Remove ALL DLSS 5 files and restore the game to factory state?\n\n{0}\n\nThis action cannot be undone.",
    "MsgUnsupported": "This game cannot be injected.",
    "ConfirmForceInstallTitle": "1 Click DLSS 5 - Universal Feeder Installation",
    "ConfirmForceInstall": "Install DLSS 5 (Universal Feeder Mode) on:\n{0}\n\nDLSS5-Feeder with LumeniteFX optical flow will be deployed for DLSS 5 Neural Rendering.\n\nContinue?",
    "MsgInstalledAlready": "[ALREADY INSTALLED]",
    "MsgModeDirect": "Mode: Direct (Native DLSS)",
    "MsgModeBridge": "Mode: OptiScaler Bridge ({0})",
    "MsgModeFeeder": "Mode: Universal Feeder (Synthetic 100% Native DLAA)",
    "RemHeaderDirect": "⚡ MODE 1: DIRECT (MASSIVE FPS BOOST WITH NATIVE DLSS)",
    "RemTextDirect": "In-game menu: ENABLE 'NVIDIA DLSS' (Quality or Performance mode) to get massive FPS boost with DLSS 5 Neural Reconstruction!",
    "RemHeaderBridge": "⚡ MODE 2: OPTISCALER BRIDGE (FPS BOOST VIA FSR2/XeSS)",
    "RemTextBridge": "In-game menu: ENABLE FSR2 or XeSS in Quality mode. OptiScaler bridge will redirect to DLSS 5 with FPS boost!",
    "RemHeaderFeeder": "⚡ MODE 3: UNIVERSAL FEEDER (100% NATIVE DLAA WITHOUT UPSCALE)",
    "RemTextFeeder": "In-game menu: Keep DLSS/Upscaling DISABLED (100% Native or DLAA). DLSS 5 & optical flow will operate directly on the clean frame without AI conflict!",
    "GuideTitle": "1 Click DLSS 5 - Mode Guide & Optimization",
    "DlgSelectGameFolder": "Select the game root folder.",
    "DlgSelectZip": "Select the 1 Click DLSS 5 package ZIP file",
    "ZipFilter": "ZIP package (*.zip);;All files (*.*)",
    "MsgVerifyOk": "Verification successful! The game is 100% ready to receive 1 Click DLSS 5.",
    "MsgNoGameTitle": "No game selected",
    # Folder-based library (replaces the drive picker).
    "FoldersLabel": "Game Folders:",
    "BtnAddFolder": "📁 ADD FOLDER",
    "BtnRemoveFolder": "✖ REMOVE FOLDER",
    "BtnScanFolders": "🔍 SCAN FOLDERS",
    "BtnRefresh": "🔄 REFRESH LIST",
    "ColPathShort": "Location",
    "NoFolders": "No folders registered. Click [ADD FOLDER] to choose where to look for games.",
    "FolderAdded": "Folder added: {0}",
    "FolderExists": "This folder is already registered: {0}",
    "FolderRemoved": "Folder removed: {0}",
    "MsgScanningFolders": "Scanning {0} registered folder(s)...",
    "MsgLibrarySaved": "Library saved: {0} game(s).",
    "MsgLibraryLoaded": "Library loaded: {0} saved game(s).",
    "MsgRefreshing": "Checking which games are still on disk...",
    "MsgRefreshDone": "Refresh complete: {0} present, {1} missing.",
    "MsgRefreshTitle": "Refreshing List...",
    "BadgeMissing": "✗ FOLDER NOT FOUND",
    "ConfirmPruneTitle": "1 Click DLSS 5 - Remove Missing",
    "ConfirmPrune": "{0} game(s) no longer exist on disk.\n\nRemove them from the list?",
    "MsgPruned": "{0} missing game(s) removed from the list.",
    "ConfirmRemoveFolderTitle": "1 Click DLSS 5 - Remove Folder",
    "ConfirmRemoveFolder": "Remove this folder and the games found in it?\n\n{0}",
    "DlgSelectScanFolder": "Select a folder that contains games",
    "MsgAddDefaults": "{0} default folder(s) detected and added.",
    "ShowUncertain": "Show items not recognised as games",
    "UncertainHidden": "{0} folder(s) hidden as not game-like (tick the box to show them).",
    "TagUncertain": "?",
    "ColNameSource": "Name Source",
    "BtnLayoutToggle": "🔁 LAYOUT",
    "TipLayoutHorizontal": "Switch to a stacked layout (library on top)",
    "TipLayoutVertical": "Switch to a side-by-side layout",
    "ColState": "Status",
    "StateDetected": "Detected",
    "StateInstalledDirect": "DLSS 5 installed (Direct)",
    "StateInstalledBridge": "DLSS 5 installed (OptiScaler)",
    "StateInstalledFeeder": "DLSS 5 installed (Feeder)",
    "StateUnrecognised": "Not recognised as a game",
    "StateMissing": "Folder missing",
    "StateNoExe": "No executable found",
    "InstalledTag": "[INSTALLED]",
}

GUIDE_PT = (
    "GUIA COMPLETO: QUAL MODO ESCOLHER NO 1 CLICK DLSS 5?\n\n"
    "==================================================================\n"
    "\U0001f7e2 MODO 1: DIRETO (Para jogos com suporte nativo a DLSS)\n"
    " - OBJETIVO: Ganho massivo de FPS (+50% a +100%) + Reconstrucao Neural.\n"
    " - NO MENU DO JOGO: ATIVE o 'NVIDIA DLSS Super Resolution' (modo Qualidade, Equilibrado ou Desempenho).\n"
    " - COMO FUNCIONA: O jogo renderiza internamente em resolucao menor e a IA do DLSS 5 reconstrói para 4K/1440p com vetores 3D do motor do jogo.\n\n"
    "\U0001f535 MODO 2: PONTE OPTISCALER (Para jogos que tem FSR2 ou XeSS)\n"
    " - OBJETIVO: Ganho de FPS em jogos sem DLSS nativo.\n"
    " - NO MENU DO JOGO: ATIVE o FSR2 ou XeSS no modo QUALIDADE.\n"
    " - COMO FUNCIONA: A ponte intercepta a chamada de FSR2 e entrega para o modelo neural DLSS 5.\n\n"
    "\U0001f7e3 MODO 3: FEEDER UNIVERSAL (Para QUALQUER jogo de PC / 100% Nativo)\n"
    " - OBJETIVO: Reconstrucao Neural de Iluminacao e Materiais em 100% Nativo.\n"
    " - NO MENU DO JOGO: Deixe o DLSS/Upscaling DESLIGADO (jogue em resolucao 100% nativa com TAA/DLAA).\n"
    " - REGRA CRITICA: No Modo 3 NAO ative DLSS Super Resolution no menu do jogo para evitar conflito de dupla IA e blur. O Feeder injeta a IA e o fluxo óptico LumeniteFX diretamente no frame limpo!\n\n"
    "==================================================================\n"
    "\U0001f4a1 DICA DE OURO PARA FLUIDEZ MÁXIMA (VSYNC):\n"
    " - Desative o 'Sincronismo Vertical' (V-Sync) dentro do menu do jogo para evitar micro-travamentos com a swapchain do DirectX/ReShade.\n"
    " - Use G-Sync / FreeSync ou limite a taxa de quadros no Painel NVIDIA para ter fluidez 100% lisa.\n\n"
    "==================================================================\n"
    "ATALHOS NO TECLADO DURANTE O JOGO:\n"
    " - [F6]: Liga / Desliga o DLSS 5 em tempo real para comparacao no mesmo frame!\n"
    " - [F5]: Captura screenshot de comparacao A/B.\n"
    " - [Home] ou [Pos1]: Abre o menu do ReShade / RenoDX para ajustes finos."
)

GUIDE_EN = (
    "COMPLETE GUIDE: HOW TO CHOOSE THE RIGHT MODE IN 1 CLICK DLSS 5:\n\n"
    "==================================================================\n"
    "\U0001f7e2 MODE 1: DIRECT (For games with native DLSS support)\n"
    " - PURPOSE: Massive FPS boost (+50% to +100%) + Neural Reconstruction.\n"
    " - IN-GAME MENU: ENABLE 'NVIDIA DLSS Super Resolution' (Quality, Balanced or Performance mode).\n"
    " - HOW IT WORKS: Game renders internally at lower res and DLSS 5 reconstructs to 4K/1440p with 3D engine motion vectors.\n\n"
    "\U0001f535 MODE 2: OPTISCALER BRIDGE (For games with FSR2 or XeSS only)\n"
    " - PURPOSE: FPS boost in games without native DLSS.\n"
    " - IN-GAME MENU: ENABLE FSR2 or XeSS in QUALITY mode.\n"
    " - HOW IT WORKS: The bridge intercepts FSR2 calls and routes them to DLSS 5 Neural.\n\n"
    "\U0001f7e3 MODE 3: UNIVERSAL FEEDER (For ANY PC Game / 100% Native DLAA)\n"
    " - PURPOSE: Neural Lighting & Material Reconstruction at 100% Native Resolution.\n"
    " - IN-GAME MENU: Keep DLSS/Upscaling DISABLED (play at 100% native resolution with standard TAA/DLAA).\n"
    " - CRITICAL RULE: In Mode 3 DO NOT enable in-game DLSS Super Resolution to prevent double-AI blur. Feeder injects AI & LumeniteFX optical flow over the clean frame!\n\n"
    "==================================================================\n"
    "\U0001f4a1 PRO-TIP FOR MAXIMUM FLUIDITY (VSYNC):\n"
    " - Disable in-game 'V-Sync' in the game graphics options to avoid frame pacing stalls with the DirectX/ReShade swapchain.\n"
    " - Use G-Sync / FreeSync or frame rate limiting in NVIDIA Control Panel for 100% smooth pacing.\n\n"
    "==================================================================\n"
    "IN-GAME HOTKEYS:\n"
    " - [F6]: Toggle DLSS 5 ON/OFF in real time for same-frame comparison!\n"
    " - [F5]: Capture A/B comparison screenshot.\n"
    " - [Home] / [Pos1]: Open full ReShade / RenoDX overlay menu."
)


# Language codes the UI offers, in the order they appear in the picker.
LANGUAGES = [
    ("EN", "EN-US"),
    ("PL", "PL-PL"),
    ("PT", "PT-BR"),
]

_TABLES = {"EN": EN, "PL": PL, "PT": PT}
_GUIDES = {"EN": GUIDE_EN, "PL": GUIDE_PL, "PT": GUIDE_PT}


def get_dict(lang: str) -> dict[str, str]:
    """Return the string table for ``lang``, falling back to English."""
    return _TABLES.get(lang, EN)


def get_guide(lang: str) -> str:
    """Return the long in-game guide text for ``lang``."""
    return _GUIDES.get(lang, GUIDE_EN)

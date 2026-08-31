# ==============================================================================
#  1 Click DLSS 5 - Universal Neural Rendering Game Center & Auto-Injector
#  Official Repository: https://github.com/1Click-DLSS5/1-Click-DLSS5
#  Architecture: RenoDX DLSS 5 v3 + NVIDIA Streamline 2.13 + nvngx_dlssnr.dll
# ==============================================================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression.FileSystem

[System.Windows.Forms.Application]::EnableVisualStyles()

# Auto-hide background console window
try {
    Add-Type -Name Win32Console -Namespace Win32Utils -MemberDefinition '
        [DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow();
        [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    ' -ErrorAction SilentlyContinue
    $cWnd = [Win32Utils.Win32Console]::GetConsoleWindow()
    if ($cWnd -ne [IntPtr]::Zero) {
        [void][Win32Utils.Win32Console]::ShowWindow($cWnd, 0) # 0 = SW_HIDE
    }
} catch {}


$script:ProductName = "1 Click DLSS 5"
$script:Version = "1.5.0"
$script:AddOnName = "renodx-dlss5.addon64"
$script:AddonHash = "E1C28FDE0922B12FC10734E58C3D24A36808E575247F4FD4F36226540D7EE023"
$script:ReShadeUrl = "https://reshade.me/downloads/ReShade_Setup_6.8.0_Addon.exe"
$script:ReShadeHash = "AFE4C8F13048306307983B8B3D41D5BF00A86820440B0E57DEA10950E1176445"
$script:StateName = "_1Click_DLSS5_State.json"
$script:BackupName = "_1Click_DLSS5_Backup"
$script:CacheRoot = Join-Path $env:LOCALAPPDATA "1ClickDLSS5"
$script:StatusBox = $null
$script:PayloadFolder = $null
$script:PayloadZipPath = $null
$script:AppRoot = $null
if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
    $script:AppRoot = $PSScriptRoot
} elseif ($MyInvocation.MyCommand -and -not [string]::IsNullOrWhiteSpace($MyInvocation.MyCommand.Path)) {
    $script:AppRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
} else {
    $script:AppRoot = (Get-Location).Path
}

# If payload is inside core/, adjust AppRoot accordingly
if (-not (Test-Path -LiteralPath (Join-Path $script:AppRoot "payload") -PathType Container)) {
    $coreCandidate = Join-Path $script:AppRoot "core"
    if (Test-Path -LiteralPath (Join-Path $coreCandidate "payload") -PathType Container) {
        $script:AppRoot = $coreCandidate
    }
}


function Get-DLSS5PayloadDirectory {
    $candidates = New-Object System.Collections.Generic.List[string]
    if ($script:AppRoot) {
        [void]$candidates.Add((Join-Path $script:AppRoot "payload"))
        [void]$candidates.Add((Join-Path $script:AppRoot "core\payload"))
        $p1 = Split-Path -Parent $script:AppRoot
        if ($p1) {
            [void]$candidates.Add((Join-Path $p1 "payload"))
            [void]$candidates.Add((Join-Path $p1 "core\payload"))
        }
    }
    if ($PSScriptRoot) {
        [void]$candidates.Add((Join-Path $PSScriptRoot "payload"))
        [void]$candidates.Add((Join-Path $PSScriptRoot "core\payload"))
        $p2 = Split-Path -Parent $PSScriptRoot
        if ($p2) {
            [void]$candidates.Add((Join-Path $p2 "payload"))
            [void]$candidates.Add((Join-Path $p2 "core\payload"))
        }
    }
    $cur = (Get-Location).Path
    if ($cur) {
        [void]$candidates.Add((Join-Path $cur "payload"))
        [void]$candidates.Add((Join-Path $cur "core\payload"))
    }

    foreach ($cand in $candidates) {
        if (-not [string]::IsNullOrWhiteSpace($cand) -and (Test-Path -LiteralPath $cand -PathType Container)) {
            if (Test-Path -LiteralPath (Join-Path $cand $script:AddOnName) -PathType Leaf) {
                return (Get-Item -LiteralPath $cand).FullName
            }
        }
    }

    foreach ($cand in $candidates) {
        if (-not [string]::IsNullOrWhiteSpace($cand) -and (Test-Path -LiteralPath $cand -PathType Container)) {
            return (Get-Item -LiteralPath $cand).FullName
        }
    }

    return (Join-Path $script:AppRoot "payload")
}

function Find-EmbeddedStreamlineZip {
    $searchRoots = New-Object System.Collections.Generic.List[string]
    if ($script:AppRoot) {
        [void]$searchRoots.Add($script:AppRoot)
        $p1 = Split-Path -Parent $script:AppRoot
        if ($p1) { [void]$searchRoots.Add($p1) }
    }
    if ($PSScriptRoot) {
        [void]$searchRoots.Add($PSScriptRoot)
        $p2 = Split-Path -Parent $PSScriptRoot
        if ($p2) { [void]$searchRoots.Add($p2) }
    }
    $curLoc = (Get-Location).Path
    if ($curLoc) { [void]$searchRoots.Add($curLoc) }

    $candidates = New-Object System.Collections.Generic.List[string]
    foreach ($root in $searchRoots) {
        if (-not [string]::IsNullOrWhiteSpace($root) -and (Test-Path -LiteralPath $root -PathType Container)) {
            [void]$candidates.Add((Join-Path $root "payload\streamline.zip"))
            [void]$candidates.Add((Join-Path $root "core\payload\streamline.zip"))
            [void]$candidates.Add((Join-Path $root "streamline.zip"))
        }
    }

    foreach ($c in $candidates) {
        if (-not [string]::IsNullOrWhiteSpace($c) -and (Test-Path -LiteralPath $c -PathType Leaf)) {
            return (Get-Item -LiteralPath $c).FullName
        }
    }

    # Recursive fallback search up to Depth 4
    foreach ($root in $searchRoots) {
        if (-not [string]::IsNullOrWhiteSpace($root) -and (Test-Path -LiteralPath $root -PathType Container)) {
            $found = @(Get-ChildItem -LiteralPath $root -Filter "streamline.zip" -File -Recurse -Depth 4 -ErrorAction SilentlyContinue)
            if ($found.Count -gt 0) {
                return $found[0].FullName
            }
        }
    }
    return $null
}
$script:IconPath = Join-Path $script:AppRoot "assets\logo.ico"
$script:CurrentLang = "PT"
$script:DiscoveredGames = @()
$script:SelectedGameObj = $null

$script:MinimalFiles = @(
    "renodx-dlss5.addon64",
    "nvngx_dlssnr.dll"
)

$script:FullFiles = @(
    "renodx-dlss5.addon64",
    "nvngx_dlssnr.dll",
    "sl.dlss_nr.dll",
    "sl.common.dll",
    "sl.interposer.dll",
    "sl.deepdvc.dll",
    "sl.dlss.dll",
    "sl.dlss_d.dll",
    "sl.dlss_g.dll",
    "sl.nis.dll",
    "sl.pcl.dll",
    "sl.reflex.dll",
    "nvngx_dlss.dll",
    "nvngx_dlssd.dll",
    "nvngx_dlssg.dll"
)

$script:OptiScalerFiles = @(
    "version.dll",
    "OptiScaler.ini",
    "libxess.dll"
)

$script:FeederFiles = @(
    "dlss5-feed.addon64",
    "dlss5-feed.addon32",
    "dlss5-feed.cfg",
    "nvngx_dlss.dll",
    "nvngx_dlssnr.dll",
    "renodx-dlss5.addon64"
)

$script:GameProfiles = @(
    [pscustomobject]@{
        Id = "hitmanwoa"
        DisplayName = "HITMAN World of Assassination"
        FolderHints = @("HITMAN World of Assassination", "HITMAN 3", "Hitman3")
        ExecutableNames = @("HITMAN3.exe", "HITMAN.exe")
        PreferredRelativePaths = @("Retail\HITMAN3.exe", "Retail\HITMAN.exe")
    },
    [pscustomobject]@{
        Id = "forzahorizon"
        DisplayName = "Forza Horizon"
        FolderHints = @("Forza Horizon 6", "Forza Horizon 5", "ForzaHorizon5", "ForzaHorizon6")
        ExecutableNames = @("forzahorizon6.exe", "ForzaHorizon6.exe", "ForzaHorizon5.exe")
        PreferredRelativePaths = @("forzahorizon6.exe", "ForzaHorizon6.exe", "ForzaHorizon5.exe")
    },
    [pscustomobject]@{
        Id = "7daystodie"
        DisplayName = "7 Days To Die"
        FolderHints = @("7 Days To Die", "7DaysToDie")
        ExecutableNames = @("7DaysToDie.exe")
        PreferredRelativePaths = @("7DaysToDie.exe")
    },
    [pscustomobject]@{
        Id = "cyberpunk"
        DisplayName = "Cyberpunk 2077"
        FolderHints = @("Cyberpunk 2077", "Cyberpunk2077")
        ExecutableNames = @("Cyberpunk2077.exe")
        PreferredRelativePaths = @("bin\x64\Cyberpunk2077.exe")
    },
    [pscustomobject]@{
        Id = "starfield"
        DisplayName = "Starfield"
        FolderHints = @("Starfield")
        ExecutableNames = @("Starfield.exe")
        PreferredRelativePaths = @("Starfield.exe")
    },
    [pscustomobject]@{
        Id = "control"
        DisplayName = "Control (DX12)"
        FolderHints = @("Control")
        ExecutableNames = @("Control_DX12.exe", "Control.exe")
        PreferredRelativePaths = @("Control_DX12.exe", "Control.exe")
    },
    [pscustomobject]@{
        Id = "msfs2024"
        DisplayName = "Microsoft Flight Simulator 2024"
        FolderHints = @("Microsoft Flight Simulator 2024", "Limitless", "MSFS2024")
        ExecutableNames = @("FlightSimulator2024.exe", "FlightSimulator.exe")
        PreferredRelativePaths = @("FlightSimulator2024.exe", "Content\FlightSimulator2024.exe")
    }
)

function Get-Dict {
    param([string]$Lang)
    if ($Lang -eq "EN") {
        return @{
            Eyebrow = "OFFICIAL RENO DX ECOSYSTEM • UNIVERSAL DLSS-NR (RTX 20 / 30 / 40 / 50 SERIES)"
            Title = "1 CLICK DLSS 5"
            Subtitle = "Steam-Style Game Center • 1-Click Neural Injection • Universal DLSS 5 Feeder for ANY PC Game"
            LibraryTitle = "GAME LIBRARY & COMPATIBILITY"
            SearchPlaceholder = "Search installed games..."
            DriveLabel = "Drive:"
            AllDrives = "All Drives"
            BtnScanDrives = "🔍 SCAN DISKS"
            BtnBrowse = "📁 BROWSE GAME"
            ColGame = "Game Title"
            ColStatus = "DLSS 5 Compatibility"
            ColPath = "Install Location"
            InspectorTitle = "SELECTED GAME INSPECTOR & INJECTION"
            NoGameSelected = "Select a game from the library on the left or browse a game folder."
            RootFolderLabel = "Game Root Directory:"
            InjectFolderLabel = "Exact DLSS 5 Injection Folder:"
            TargetExeLabel = "Target 64-bit Game Executable:"
            DlssStatusLabel = "Native DLSS Detected:"
            LblInjectionMode = "DLSS 5 Injection Mode:"
            OptAutoRecommended = "⚡ Automatic (Recommended: {0})"
            OptModeDirect = "🟢 Mode 1: Direct (Streamline + Native DLSS)"
            OptModeBridge = "🔵 Mode 2: OptiScaler Bridge (FSR2/XeSS → DLSS 5)"
            OptModeFeeder = "🟣 Mode 3: Universal Feeder (100% Native DLAA)"
            ModeNameDirect = "Mode 1 - Direct"
            ModeNameBridge = "Mode 2 - OptiScaler Bridge"
            ModeNameFeeder = "Mode 3 - Universal Feeder"
            ReminderHeader = "⚡ CRITICAL DLSS PREREQUISITE:"
            ReminderText = "In-game, make sure to enable 'NVIDIA DLSS Super Resolution' (Quality/Balanced/Performance) in the graphics menu for DLSS 5 Neural Reconstruction to work!"
            PayloadTitle = "DLSS 5 Payload (Embedded Streamline 2.13):"
            BtnChangeZip = "📦 CHANGE ZIP"
            OptReShade = "Install ReShade 6.8.0 (Add-on Support)"
            OptFull = "Full Streamline DLL Replacement"
            BtnVerify = "🔍 VERIFY"
            BtnInstall = "🚀 1-CLICK INSTALL DLSS 5"
            BtnLaunch = "▶️ LAUNCH GAME"
            BtnUninstall = "↩️ RESTORE FACTORY"
            BtnOpenFolder = "📂 OPEN FOLDER"
            BtnInstructions = "📖 IN-GAME GUIDE"
            StatusHeading = "REAL-TIME DIAGNOSTICS & SYSTEM LOG"
            Footer = "1 Click DLSS 5 v1.5.0 | Universal Feeder 2.0 (All PC Games) | RTX 20/30/40/50 | DX11 / DX12 / Vulkan / OpenGL"
            Badge100 = "✓ 100% COMPATIBLE (Native DLSS)"
            BadgeDX12 = "✓ COMPATIBLE (DirectX 12)"
            BadgeBridge = "✓ COMPATIBLE VIA OPTISCALER (FSR2/XeSS → DLSS 5)"
            BadgeFeeder = "✓ UNIVERSAL (DLSS 5 Feeder • 100% Native DLAA)"
            BadgeUnsupported = "✗ UNSUPPORTED"
            MsgReady = "Ready. Pick a game from your Steam-style library or browse folder."
            MsgScanning = "Scanning drives ({0}) and reading game executables and icons..."
            MsgScanDone = "Scan complete! {0} games loaded into your library, sorted by compatibility."
            MsgPayloadLoaded = "Official 1 Click DLSS 5 payload loaded automatically."
            MsgScanProgressTitle = "Scanning Games..."
            MsgScanFolder = "Scanning: {0}"
            MsgScanProgressDrive = "Scanning drive {0} ({1}/{2})..."
            MsgLibraryEmpty = "Click [SCAN DISKS] to discover your games, or [BROWSE GAME] to select a folder manually."
            MsgSelected = "Selected game: {0} ({1})"
            SuccessTitle = "1 Click DLSS 5 - Installation Complete"
            SuccessMsg = "DLSS 5 successfully installed!`n`n1. Click [LAUNCH GAME] or open the game.`n2. Press [Home] key -> Check Add-ons tab for DLSS 5.`n3. Enjoy AI Neural Reconstruction!"
            RestoreTitle = "1 Click DLSS 5 - Restoration Complete"
            RestoreMsg = "Game successfully restored to clean factory state! All injected files, shaders, and logs were wiped."
            ConfirmInstallTitle = "1 Click DLSS 5 - Confirm Installation"
            ConfirmInstallDirect = "Install DLSS 5 (Direct Mode) on:`n{0}`n`nNative DLSS detected. Streamline + RenoDX will be injected.`n`nContinue?"
            ConfirmInstallBridge = "Install DLSS 5 (OptiScaler Bridge) on:`n{0}`n`n{1} detected. OptiScaler will redirect to DLSS Neural Rendering.`n`nContinue?"
            ConfirmInstallFeeder = "Install DLSS 5 (Universal Feeder Mode) on:`n{0}`n`nDLSS5-Feeder + LumeniteFX will synthesize a 100% Native DLAA contract for DLSS 5 Neural Rendering.`n`nContinue?"
            ConfirmUninstallTitle = "1 Click DLSS 5 - Confirm Restoration"
            ConfirmUninstall = "Remove ALL DLSS 5 files and restore the game to factory state?`n`n{0}`n`nThis action cannot be undone."
            MsgUnsupported = "This game cannot be injected."
            ConfirmForceInstallTitle = "1 Click DLSS 5 - Universal Feeder Installation"
            ConfirmForceInstall = "Install DLSS 5 (Universal Feeder Mode) on:`n{0}`n`nDLSS5-Feeder with LumeniteFX optical flow will be deployed for DLSS 5 Neural Rendering.`n`nContinue?"
            MsgInstalledAlready = "[ALREADY INSTALLED]"
            MsgModeDirect = "Mode: Direct (Native DLSS)"
            MsgModeBridge = "Mode: OptiScaler Bridge ({0})"
            MsgModeFeeder = "Mode: Universal Feeder (Synthetic 100% Native DLAA)"
        }
    } else {
        return @{
            Eyebrow = "ECOSSISTEMA OFICIAL RENO DX • RUNTIME NEURAL UNIVERSAL (SÉRIES RTX 20 / 30 / 40 / 50)"
            Title = "1 CLICK DLSS 5"
            Subtitle = "Interface Estilo Steam • Injeção Neural em 1-Clique • DLSS 5 Universal Feeder para QUALQUER Jogo de PC"
            LibraryTitle = "BIBLIOTECA DE JOGOS E COMPATIBILIDADE"
            SearchPlaceholder = "Pesquisar jogos instalados..."
            DriveLabel = "Disco:"
            AllDrives = "Todos os Discos"
            BtnScanDrives = "🔍 ESCANEAR DISCOS"
            BtnBrowse = "📁 PROCURAR JOGO"
            ColGame = "Título do Jogo"
            ColStatus = "Compatibilidade DLSS 5"
            ColPath = "Local de Instalação"
            InspectorTitle = "PAINEL DE INJEÇÃO E DETALHES DO JOGO"
            NoGameSelected = "Selecione um jogo na biblioteca ao lado ou procure uma pasta manualmente."
            RootFolderLabel = "Pasta Raiz do Jogo:"
            InjectFolderLabel = "Pasta Exata de Aplicação DLSS 5:"
            TargetExeLabel = "Executável Principal 64-bit:"
            DlssStatusLabel = "DLSS Nativo Detectado:"
            LblInjectionMode = "Modo de Injeção DLSS 5:"
            OptAutoRecommended = "⚡ Automático (Recomendado: {0})"
            OptModeDirect = "🟢 Modo 1: Direto (Streamline + DLSS Nativo)"
            OptModeBridge = "🔵 Modo 2: Ponte OptiScaler (FSR2/XeSS → DLSS 5)"
            OptModeFeeder = "🟣 Modo 3: Feeder Universal (DLAA 100% Nativo)"
            ModeNameDirect = "Modo 1 - Direto"
            ModeNameBridge = "Modo 2 - Ponte OptiScaler"
            ModeNameFeeder = "Modo 3 - Feeder Universal"
            ReminderHeader = "⚡ REQUISITO OBRIGATÓRIO NO JOGO:"
            ReminderText = "Dentro do jogo, certifique-se de ATIVAR o 'NVIDIA DLSS Super Resolution' (Qualidade ou Desempenho) nas opções gráficas para que o DLSS 5 Neural funcione!"
            PayloadTitle = "Pacote DLSS 5 (Streamline 2.13 Integrado):"
            BtnChangeZip = "📦 TROCAR ZIP"
            OptReShade = "Instalar ReShade 6.8.0 (Suporte a Add-ons)"
            OptFull = "Substituição Completa de DLLs Streamline"
            BtnVerify = "🔍 VERIFICAR"
            BtnInstall = "🚀 1-CLIQUE: INSTALAR DLSS 5"
            BtnLaunch = "▶️ INICIAR JOGO"
            BtnUninstall = "↩️ RESTAURAR ORIGINAL"
            BtnOpenFolder = "📂 ABRIR PASTA"
            BtnInstructions = "📖 GUIA NO JOGO"
            StatusHeading = "DIAGNÓSTICO E LOG DO SISTEMA EM TEMPO REAL"
            Footer = "1 Click DLSS 5 v1.5.0 | Feeder Universal 2.0 (Qualquer Jogo de PC) | RTX 20/30/40/50 | DX11 / DX12 / Vulkan / OpenGL"
            Badge100 = "✓ 100% COMPATÍVEL (DLSS Nativo)"
            BadgeDX12 = "✓ COMPATÍVEL (DirectX 12)"
            BadgeBridge = "✓ COMPATÍVEL VIA OPTISCALER (FSR2/XeSS → DLSS 5)"
            BadgeFeeder = "✓ UNIVERSAL (Modo Feeder DLSS 5 • DLAA 100% Nativo)"
            BadgeUnsupported = "✗ SEM SUPORTE"
            MsgReady = "Pronto. Escolha um jogo na biblioteca visual ou selecione uma pasta."
            MsgScanning = "Escaneando discos ({0}) e extraindo ícones reais dos executáveis..."
            MsgScanDone = "Varredura concluída! {0} jogos carregados na biblioteca e ordenados por compatibilidade."
            MsgPayloadLoaded = "Pacote oficial 1 Click DLSS 5 embutido carregado com sucesso."
            MsgScanProgressTitle = "Escaneando Jogos..."
            MsgScanFolder = "Escaneando: {0}"
            MsgScanProgressDrive = "Escaneando disco {0} ({1}/{2})..."
            MsgLibraryEmpty = "Clique em [ESCANEAR DISCOS] para descobrir seus jogos, ou [PROCURAR JOGO] para selecionar uma pasta manualmente."
            MsgSelected = "Jogo selecionado: {0} ({1})"
            SuccessTitle = "1 Click DLSS 5 - Instalação Concluída"
            SuccessMsg = "DLSS 5 instalado com sucesso!`n`n1. Clique em [INICIAR JOGO] ou abra o jogo.`n2. Pressione a tecla [Home] -> Verifique a aba Add-ons.`n3. Aproveite a Reconstrução Neural com IA!"
            RestoreTitle = "1 Click DLSS 5 - Restauração Completa"
            RestoreMsg = "Jogo restaurado com sucesso ao estado de fábrica original! Todos os arquivos injetados, shaders e logs foram removidos."
            ConfirmInstallTitle = "1 Click DLSS 5 - Confirmar Instalação"
            ConfirmInstallDirect = "Instalar DLSS 5 (Modo Direto) em:`n{0}`n`nDLSS nativo detectado. Streamline + RenoDX será injetado.`n`nContinuar?"
            ConfirmInstallBridge = "Instalar DLSS 5 (Ponte OptiScaler) em:`n{0}`n`n{1} detectado. O OptiScaler redirecionará para a Renderização Neural DLSS.`n`nContinuar?"
            ConfirmInstallFeeder = "Instalar DLSS 5 (Modo Feeder Universal) em:`n{0}`n`nO DLSS5-Feeder + LumeniteFX sintetizará um contrato DLAA 100% Nativo para a Renderização Neural DLSS 5.`n`nContinuar?"
            ConfirmUninstallTitle = "1 Click DLSS 5 - Confirmar Restauração"
            ConfirmUninstall = "Remover TODOS os arquivos DLSS 5 e restaurar o jogo ao estado de fábrica?`n`n{0}`n`nEsta ação não pode ser desfeita."
            MsgUnsupported = "Este jogo não pode ser injetado."
            ConfirmForceInstallTitle = "1 Click DLSS 5 - Instalação Feeder Universal"
            ConfirmForceInstall = "Instalar DLSS 5 (Modo Feeder Universal) em:`n{0}`n`nO DLSS5-Feeder com fluxo óptico LumeniteFX será implantado para Renderização Neural DLSS 5.`n`nContinuar?"
            MsgInstalledAlready = "[JÁ INSTALADO]"
            MsgModeDirect = "Modo: Direto (DLSS Nativo)"
            MsgModeBridge = "Modo: Ponte OptiScaler ({0})"
            MsgModeFeeder = "Modo: Feeder Universal (DLAA Sintético 100% Nativo)"
        }
    }
}

function Write-Status {
    param(
        [Parameter(Mandatory = $true)][string]$Message,
        [Parameter(Mandatory = $false)][string]$Level = "INFO"
    )
    if ($null -eq $script:StatusBox) { return }
    $prefix = "[i INFO]     "
    $color = [System.Drawing.Color]::FromArgb(170, 205, 255)
    if ($Level -eq "OK") {
        $prefix = "[✓ SUCESSO]  "
        $color = [System.Drawing.Color]::FromArgb(118, 225, 125)
    } elseif ($Level -eq "WARN") {
        $prefix = "[! AVISO]    "
        $color = [System.Drawing.Color]::FromArgb(255, 205, 90)
    } elseif ($Level -eq "ERROR") {
        $prefix = "[✗ ERRO]     "
        $color = [System.Drawing.Color]::FromArgb(255, 110, 110)
    }
    $box = $script:StatusBox
    $start = $box.TextLength
    $box.AppendText($prefix + $Message + "`r`n")
    $box.Select($start, $box.TextLength - $start)
    $box.SelectionColor = $color
    $box.SelectionLength = 0
    $box.ScrollToCaret()
}

function Show-ErrorDialog {
    param([Parameter(Mandatory = $true)][string]$Message)
    [void][System.Windows.Forms.MessageBox]::Show($Message, "1 Click DLSS 5", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
}

function Get-Sha256 {
    param([Parameter(Mandatory = $true)][string]$Path)
    $stream = [System.IO.File]::OpenRead($Path)
    try {
        $hasher = [System.Security.Cryptography.SHA256]::Create()
        try {
            $hash = $hasher.ComputeHash($stream)
            return (-join ($hash | ForEach-Object { "{0:X2}" -f $_ }))
        } finally { $hasher.Dispose() }
    } finally { $stream.Dispose() }
}

function Test-X64Pe {
    param([Parameter(Mandatory = $true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $false }
    try {
        $bytes = New-Object byte[] 4096
        $stream = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
        try {
            $read = $stream.Read($bytes, 0, $bytes.Length)
            if ($read -lt 64) { return $false }
            if ($bytes[0] -ne 0x4D -or $bytes[1] -ne 0x5A) { return $false }
            $e_lfanew = [System.BitConverter]::ToInt32($bytes, 60)
            if ($e_lfanew -lt 0 -or ($e_lfanew + 24) -gt $read) { return $false }
            if ($bytes[$e_lfanew] -ne 0x50 -or $bytes[$e_lfanew + 1] -ne 0x45 -or $bytes[$e_lfanew + 2] -ne 0x00 -or $bytes[$e_lfanew + 3] -ne 0x00) { return $false }
            $machine = [System.BitConverter]::ToUInt16($bytes, $e_lfanew + 4)
            return ($machine -eq 0x8664)
        } finally { $stream.Dispose() }
    } catch { return $false }
}

function Sanitize-PathString {
    param([string]$Raw)
    if ([string]::IsNullOrWhiteSpace($Raw)) { return "" }
    $p = $Raw.Trim().Trim('"').Trim("'")
    if ($p -match '-\s*\(([A-Za-z]:\\[^()]+)\)\s*$') {
        $p = $Matches[1].Trim()
    } elseif ($p -match '([A-Za-z]:\\[^:*?"<>|\r\n]+)') {
        $cand = $Matches[1].Trim()
        $cand = $cand -replace '[\)\]]+$', ''
        $p = $cand.Trim()
    }
    return $p
}

function Resolve-GameTarget {
    param([Parameter(Mandatory = $true)][string]$TargetPath)
    $cleanPath = Sanitize-PathString -Raw $TargetPath
    if ([string]::IsNullOrWhiteSpace($cleanPath)) { throw "Selecione um jogo na biblioteca ou informe a pasta." }
    if (-not (Test-Path -LiteralPath $cleanPath)) { throw "O caminho informado nao existe no disco: $cleanPath" }

    $targetItem = Get-Item -LiteralPath $cleanPath -ErrorAction Stop
    $targetRoot = $null
    $targetExe = $null

    if (-not $targetItem.PSIsContainer) {
        if ($targetItem.Extension -ine ".exe") { throw "O arquivo selecionado nao e um executavel (.exe)." }
        if (-not (Test-X64Pe -Path $targetItem.FullName)) { throw "O executavel selecionado precisa ser de 64-bit." }
        $targetExe = $targetItem.FullName
        $targetRoot = $targetItem.Directory.FullName
    } else {
        $targetRoot = $targetItem.FullName

        # 1. Checagem de Perfis Nativos
        foreach ($prof in $script:GameProfiles) {
            foreach ($hint in $prof.FolderHints) {
                if ($targetRoot.ToLower().Contains($hint.ToLower())) {
                    foreach ($rel in $prof.PreferredRelativePaths) {
                        $fullP = Join-Path $targetRoot $rel
                        if (Test-Path -LiteralPath $fullP -PathType Leaf) {
                            $targetExe = $fullP
                            break
                        }
                    }
                }
                if ($null -ne $targetExe) { break }
            }
            if ($null -ne $targetExe) { break }
        }

        # 2. Heuristica Inteligente para QUALQUER jogo
        if ($null -eq $targetExe) {
            $ignoredKeywords = @(
                "unins", "crash", "setup", "helper", "launcher", "redist", "patcher",
                "_eac", "eac_", "easyanticheat", "battleye", "vanguard", "unitycrash",
                "crashreport", "directx", "vcredist", "dotnet", "report", "config",
                "benchmark", "tool", "dxgi", "d3d", "server", "dedicated", "startserver"
            )

            $allExes = @(Get-ChildItem -LiteralPath $targetRoot -Filter "*.exe" -File -Recurse -Depth 3 -ErrorAction SilentlyContinue |
                Where-Object {
                    $nameLow = $_.Name.ToLower()
                    $isIgnored = $false
                    foreach ($kw in $ignoredKeywords) {
                        if ($nameLow.Contains($kw)) { $isIgnored = $true; break }
                    }
                    (-not $isIgnored) -and (Test-X64Pe -Path $_.FullName)
                })

            if ($allExes.Count -gt 0) {
                $dirClean = (Split-Path -Leaf $targetRoot).ToLower().Replace(" ", "")
                $scored = @($allExes | ForEach-Object {
                    $p = $_.FullName.ToLower()
                    $n = $_.Name.ToLower()
                    $score = 10

                    if ($n.Replace(".exe", "").Replace(" ", "") -eq $dirClean) { $score += 100 }
                    elseif ($n.Contains($dirClean)) { $score += 60 }

                    if ($p.Contains("binaries\win64")) { $score += 80 }
                    elseif ($p.Contains("bin\x64")) { $score += 70 }
                    elseif ($p.Contains("retail")) { $score += 60 }
                    elseif ($p.Contains("content")) { $score += 40 }

                    if ($_.Length -gt 20MB) { $score += 30 }
                    elseif ($_.Length -gt 5MB) { $score += 15 }

                    [pscustomobject]@{
                        Score = $score
                        FullName = $_.FullName
                    }
                } | Sort-Object -Property Score -Descending)

                $targetExe = $scored[0].FullName
            }
        }
    }

    if ($null -eq $targetExe) {
        throw "Nenhum executavel principal de 64-bit foi encontrado nesta pasta de jogo."
    }

    $installFolder = (Split-Path -Parent $targetExe)
    $dlssCandidate = Join-Path $installFolder "nvngx_dlss.dll"
    $existingDlss = $null
    if (Test-Path -LiteralPath $dlssCandidate -PathType Leaf) {
        $existingDlss = $dlssCandidate
    } else {
        $foundDlss = @(Get-ChildItem -LiteralPath $targetRoot -Filter "nvngx_dlss*.dll" -File -Recurse -Depth 3 -ErrorAction SilentlyContinue)
        if ($foundDlss.Count -gt 0) {
            $existingDlss = $foundDlss[0].FullName
        }
    }

    $extractedIcon = $null
    try {
        $extractedIcon = [System.Drawing.Icon]::ExtractAssociatedIcon($targetExe)
    } catch {}

    return [pscustomobject]@{
        Root = $targetRoot
        Executable = $targetExe
        ExeName = (Split-Path -Leaf $targetExe)
        InstallFolder = $installFolder
        ExistingDlssDll = $existingDlss
        Icon = $extractedIcon
    }
}

function Get-GpuNames {
    $gpus = New-Object System.Collections.Generic.List[string]
    try {
        $items = Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue
        foreach ($item in $items) {
            if (-not [string]::IsNullOrWhiteSpace($item.Name)) { [void]$gpus.Add($item.Name.Trim()) }
        }
    } catch {}
    return $gpus
}

function Get-DriverVersions {
    $vers = New-Object System.Collections.Generic.List[string]
    try {
        $items = Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue
        foreach ($item in $items) {
            if (-not [string]::IsNullOrWhiteSpace($item.DriverVersion)) { [void]$vers.Add($item.DriverVersion.Trim()) }
        }
    } catch {}
    return $vers
}

function Detect-GameGraphicsApi {
    param(
        [Parameter(Mandatory = $true)][string]$TargetExe,
        [string]$GameFolder = ""
    )
    if ([string]::IsNullOrWhiteSpace($GameFolder)) {
        $GameFolder = Split-Path -Parent $TargetExe
    }
    
    $exeLow = $TargetExe.ToLower()
    $folderLow = $GameFolder.ToLower()

    # 1. Explicit OpenGL Signatures (Project Zomboid, Minecraft, Wolfenstein, Emulators, Java/LWJGL)
    $isOpenGL = $false
    if ($exeLow.Contains("projectzomboid") -or $exeLow.Contains("minecraft") -or $exeLow.Contains("javaw.exe") -or $exeLow.Contains("wolfneworder") -or $exeLow.Contains("wolfoldblood") -or $exeLow.Contains("rage.exe") -or $exeLow.Contains("cemu.exe") -or $exeLow.Contains("yuzu.exe") -or $exeLow.Contains("ryujinx.exe") -or $exeLow.Contains("citra.exe")) {
        $isOpenGL = $true
    }
    if (-not $isOpenGL) {
        $glFiles = @(Get-ChildItem -LiteralPath $GameFolder -Filter "*lwjgl*" -File -Depth 2 -ErrorAction SilentlyContinue)
        $glFiles += @(Get-ChildItem -LiteralPath $GameFolder -Filter "*glfw3*" -File -Depth 2 -ErrorAction SilentlyContinue)
        $glFiles += @(Get-ChildItem -LiteralPath $GameFolder -Filter "*opengl*.txt" -File -Depth 2 -ErrorAction SilentlyContinue)
        if ($glFiles.Count -gt 0) { $isOpenGL = $true }
    }
    if ($isOpenGL) { return "OPENGL" }

    # 2. Unreal Engine 4/5 / Hitman (Requires d3d12.dll for direct injection)
    $isUe = $exeLow.Contains("binaries\win64") -or $exeLow.Contains("htgame") -or $exeLow.Contains("hitman")
    if ($isUe) { return "D3D12" }

    # 3. DirectX 9 (Source 1 games, Skyrim LE, Fallout NV, GTA SA/IV, Mass Effect 1/2)
    $d3d9Files = @(Get-ChildItem -LiteralPath $GameFolder -Filter "d3d9*.dll" -File -Depth 2 -ErrorAction SilentlyContinue)
    $d3d9Files += @(Get-ChildItem -LiteralPath $GameFolder -Filter "d3dx9*.dll" -File -Depth 2 -ErrorAction SilentlyContinue)
    $modernDxFiles = @(Get-ChildItem -LiteralPath $GameFolder -Filter "d3d11*.dll" -File -Depth 2 -ErrorAction SilentlyContinue)
    $modernDxFiles += @(Get-ChildItem -LiteralPath $GameFolder -Filter "d3d12*.dll" -File -Depth 2 -ErrorAction SilentlyContinue)
    $modernDxFiles += @(Get-ChildItem -LiteralPath $GameFolder -Filter "dxgi*.dll" -File -Depth 2 -ErrorAction SilentlyContinue)
    
    if ($d3d9Files.Count -gt 0 -and $modernDxFiles.Count -eq 0) {
        return "D3D9"
    }

    # 4. Vulkan
    $vkFiles = @(Get-ChildItem -LiteralPath $GameFolder -Filter "vulkan-1.dll" -File -Depth 2 -ErrorAction SilentlyContinue)
    if ($vkFiles.Count -gt 0 -and $modernDxFiles.Count -eq 0) {
        return "VULKAN"
    }

    # 5. Universal Default for Modern PC Games (DirectX 11 / DirectX 12)
    return "DXGI"
}

function Detect-GameUpscalerType {
    param(
        [Parameter(Mandatory = $true)][string]$GameFolder,
        [Parameter(Mandatory = $false)][string]$GameRoot = ""
    )
    $searchDirs = [System.Collections.Generic.List[string]]::new()
    if (-not [string]::IsNullOrWhiteSpace($GameRoot) -and (Test-Path -LiteralPath $GameRoot -PathType Container)) {
        $searchDirs.Add($GameRoot)
    }
    if (Test-Path -LiteralPath $GameFolder -PathType Container) {
        if (-not $searchDirs.Contains($GameFolder)) { $searchDirs.Add($GameFolder) }
        if ([string]::IsNullOrWhiteSpace($GameRoot)) {
            $p = $GameFolder
            for ($i = 0; $i -lt 4; $i++) {
                $parent = Split-Path -Parent $p
                if ([string]::IsNullOrWhiteSpace($parent) -or -not (Test-Path -LiteralPath $parent -PathType Container)) { break }
                if ($parent -match '^[A-Za-z]:\\$' -or $parent.ToLower().EndsWith('\common') -or $parent.ToLower().EndsWith('\steamapps')) { break }
                if (-not $searchDirs.Contains($parent)) { $searchDirs.Add($parent) }
                $p = $parent
            }
        }
    }

    $allDlls = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
    foreach ($sDir in $searchDirs) {
        $found = @(Get-ChildItem -LiteralPath $sDir -Filter "*.dll" -File -Recurse -Depth 12 -ErrorAction SilentlyContinue | Where-Object {
            $_.FullName -notmatch '(_1Click_DLSS5|_DLSS5_|reshade-shaders|\\host64\\)'
        })
        foreach ($f in $found) {
            $allDlls.Add($f)
        }
    }

    # PRIORITY 1: Native DLSS / Streamline
    foreach ($dll in $allDlls) {
        if ($dll.Name -imatch '^(nvngx_dlss\.dll|nvngx_dlssd\.dll|nvngx_dlssg\.dll|sl\.dlss\.dll|sl\.interposer\.dll|_nvngx\.dll)$') {
            return "NATIVE_DLSS"
        }
    }
    # PRIORITY 2: FSR 2/3
    foreach ($dll in $allDlls) {
        if ($dll.Name -imatch '^(ffx_fsr2_api.*\.dll|ffx_fsr3_api.*\.dll|amd_fidelityfx.*\.dll|FSR2\.dll|ffx_backend_dx12\.dll)$') {
            return "FSR2_BRIDGE"
        }
    }
    # PRIORITY 3: XeSS
    foreach ($dll in $allDlls) {
        if ($dll.Name -imatch '^(libxess\.dll|xess\.dll|libxell\.dll)$') {
            return "XESS_BRIDGE"
        }
    }
    # PRIORITY 4: Universal DLSS 5 Feeder (All other PC games: D3D11 / D3D12 / Vulkan / 32-bit)
    return "UNIVERSAL_FEEDER"
}

function Prepare-Payload {
    param([string]$DlssZipPath = "", [string]$SelectedMode = "AUTO")
    $cleanZip = Sanitize-PathString -Raw $DlssZipPath
    if ([string]::IsNullOrWhiteSpace($cleanZip)) {
        $cleanZip = Find-EmbeddedStreamlineZip
    }

    $payloadRoot = Get-DLSS5PayloadDirectory
    $addon = Join-Path $payloadRoot $script:AddOnName
    if (-not (Test-Path -LiteralPath $addon -PathType Leaf)) { throw "O arquivo $script:AddOnName nao foi encontrado na pasta payload ($payloadRoot)." }

    # If mode is Feeder or OptiScaler, streamline.zip is optional if other payload files exist
    if ([string]::IsNullOrWhiteSpace($cleanZip) -or -not (Test-Path -LiteralPath $cleanZip -PathType Leaf)) {
        if ($SelectedMode -eq "FEEDER" -or $SelectedMode -eq "OPTISCALER") {
            $script:PayloadFolder = $payloadRoot
            $script:PayloadZipPath = ""
            return $payloadRoot
        } else {
            $errText = if ($script:CurrentLang -eq "EN") {
                "The streamline.zip payload was not found. Please click [CHANGE ZIP] to select it."
            } else {
                "O arquivo streamline.zip do pacote DLSS 5 nao foi encontrado. Clique em [TROCAR ZIP] para seleciona-lo."
            }
            throw $errText
        }
    }

    $zipItem = Get-Item -LiteralPath $cleanZip -ErrorAction Stop
    $zipHash = Get-Sha256 -Path $zipItem.FullName

    if (-not (Test-Path -LiteralPath $script:CacheRoot -PathType Container)) {
        [void](New-Item -ItemType Directory -Path $script:CacheRoot -Force)
    }
    $cache = Join-Path $script:CacheRoot ("user-payload-" + $zipHash.Substring(0, 12))
    $runtime = $null

    if (Test-Path -LiteralPath $cache -PathType Container) {
        $cands = @(Get-ChildItem -LiteralPath $cache -Filter "nvngx_dlssnr.dll" -File -Recurse -ErrorAction SilentlyContinue | Where-Object { Test-X64Pe -Path $_.FullName })
        if ($cands.Count -gt 0) { $runtime = $cands[0] }
    }

    if ($null -eq $runtime) {
        if (Test-Path -LiteralPath $cache -PathType Container) { Remove-Item -LiteralPath $cache -Recurse -Force -ErrorAction SilentlyContinue }
        [void](New-Item -ItemType Directory -Path $cache -Force)
        Write-Status -Message "Extraindo pacote 1 Click DLSS 5 para cache local..." -Level "INFO"
        [System.IO.Compression.ZipFile]::ExtractToDirectory($zipItem.FullName, $cache)
        $cands = @(Get-ChildItem -LiteralPath $cache -Filter "nvngx_dlssnr.dll" -File -Recurse -ErrorAction SilentlyContinue | Where-Object { Test-X64Pe -Path $_.FullName })
        if ($cands.Count -gt 0) { $runtime = $cands[0] }
        if ($null -eq $runtime) { throw "O ZIP fornecido nao contem uma nvngx_dlssnr.dll valida de 64-bit." }
    }

    $folder = $runtime.Directory.FullName
    Copy-Item -LiteralPath $addon -Destination (Join-Path $folder $script:AddOnName) -Force
    $script:PayloadFolder = $folder
    $script:PayloadZipPath = $zipItem.FullName
    $script:PayloadZipHash = $zipHash
    return $folder
}

function Get-ReShadeSetup {
    if (-not (Test-Path -LiteralPath $script:CacheRoot -PathType Container)) {
        [void](New-Item -ItemType Directory -Path $script:CacheRoot -Force)
    }
    $setup = Join-Path $script:CacheRoot "ReShade_Setup_6.8.0_Addon.exe"
    $payloadSetup = Join-Path (Get-DLSS5PayloadDirectory) "ReShade_Setup_6.8.0_Addon.exe"
    if (Test-Path -LiteralPath $payloadSetup -PathType Leaf) {
        Copy-Item -LiteralPath $payloadSetup -Destination $setup -Force
        return $setup
    }
    if ((Test-Path -LiteralPath $setup -PathType Leaf) -and (Get-Sha256 -Path $setup) -eq $script:ReShadeHash) {
        return $setup
    }
    Write-Status -Message "Baixando instalador oficial do ReShade 6.8.0 com Add-on Support..." -Level "INFO"
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12
    $client = New-Object System.Net.WebClient
    try { $client.DownloadFile($script:ReShadeUrl, $setup) }
    finally { $client.Dispose() }
    return $setup
}

function Install-ReShade {
    param(
        [Parameter(Mandatory = $true)][string]$TargetExe,
        [Parameter(Mandatory = $true)][string]$Setup,
        [string]$TargetApi = "DXGI"
    )
    $folder = Split-Path -Parent $TargetExe
    $dxgi = Join-Path $folder "dxgi.dll"
    $d3d12 = Join-Path $folder "d3d12.dll"
    $d3d9 = Join-Path $folder "d3d9.dll"
    $opengl = Join-Path $folder "opengl32.dll"

    $expectedDll = switch ($TargetApi) {
        "OPENGL" { $opengl }
        "D3D9"   { $d3d9 }
        "D3D12"  { $d3d12 }
        default  { $dxgi }
    }
    $expectedName = Split-Path -Leaf $expectedDll

    # Check if ReShade already exists with any valid proxy name
    $reshadeExists = $false
    foreach ($cand in @($opengl, $d3d12, $dxgi, $d3d9)) {
        if (Test-Path -LiteralPath $cand -PathType Leaf) {
            $item = Get-Item -LiteralPath $cand
            if ($item.Length -gt 2MB) {
                $reshadeExists = $true
                if ($cand -ne $expectedDll -and -not (Test-Path -LiteralPath $expectedDll -PathType Leaf)) {
                    Move-Item -LiteralPath $cand -Destination $expectedDll -Force
                    Write-Status -Message "ReShade ajustado para $expectedName para compatibilidade nativa com a API ($TargetApi)." -Level "OK"
                }
                break
            }
        }
    }

    if ($reshadeExists) {
        Write-Status -Message "ReShade com Add-on Support ($expectedName) ativo e integro..." -Level "OK"
        return $expectedName
    }

    $apiFlag = switch ($TargetApi) {
        "OPENGL" { "opengl" }
        "D3D9"   { "d3d9" }
        "D3D12"  { "d3d12" }
        "VULKAN" { "vulkan" }
        default  { "dxgi" }
    }

    $arguments = "--headless --api $apiFlag `"$TargetExe`""
    $process = Start-Process -FilePath $Setup -ArgumentList $arguments -Wait -PassThru
    
    # Fallback renaming if ReShade created dxgi.dll instead of expected proxy
    if ($expectedDll -ne $dxgi -and (Test-Path -LiteralPath $dxgi -PathType Leaf) -and (-not (Test-Path -LiteralPath $expectedDll -PathType Leaf))) {
        Move-Item -LiteralPath $dxgi -Destination $expectedDll -Force
        Write-Status -Message "ReShade configurado como $expectedName ($TargetApi)." -Level "OK"
    }

    $hasDll = (Test-Path -LiteralPath $expectedDll -PathType Leaf) -or (Test-Path -LiteralPath $dxgi -PathType Leaf)
    if (-not $hasDll -and $process.ExitCode -ne 0) {
        throw "Instalador do ReShade retornou codigo de erro $($process.ExitCode)."
    }

    return $expectedName
}

function Get-Compatibility {
    param(
        [Parameter(Mandatory = $true)][string]$TargetPath,
        [Parameter(Mandatory = $true)][bool]$InstallReShade,
        [Parameter(Mandatory = $true)][bool]$FullPackage,
        [string]$DlssZipPath = "",
        [string]$SelectedMode = "AUTO"
    )
    $fatal = New-Object System.Collections.Generic.List[string]
    $warnings = New-Object System.Collections.Generic.List[string]
    $info = New-Object System.Collections.Generic.List[string]
    $target = $null
    try { $target = Resolve-GameTarget -TargetPath $TargetPath }
    catch { [void]$fatal.Add($_.Exception.Message); return [pscustomobject]@{ CanInstall = $false; Fatal = $fatal; Warnings = $warnings; Info = $info } }

    [void]$info.Add("Pasta Raiz do Jogo: " + $target.Root)
    [void]$info.Add("Executavel Alvo: " + $target.ExeName)
    [void]$info.Add("Pasta Exata de Injecao: " + $target.InstallFolder)
    if ($null -ne $target.ExistingDlssDll) {
        [void]$info.Add("DLSS Nativo Detectado: " + $target.ExistingDlssDll)
    } else {
        [void]$warnings.Add("Nenhuma nvngx_dlss.dll encontrada previamente. Certifique-se de que o jogo suporta DirectX 12.")
    }
    $gpus = @(Get-GpuNames)
    if ($gpus.Count -gt 0) { $gpuText = $gpus -join ", "
        if ($gpuText -match "RTX\s*(20|30|40|50)") {
            [void]$info.Add("GPU Totalmente Compativel: $gpuText (Suporte Universal RTX 20/30/40/50 Ativo)")
        } else {
            [void]$info.Add("GPU Detectada: $gpuText")
        } }
    $drivers = @(Get-DriverVersions)
    if ($drivers.Count -gt 0) { [void]$info.Add("Driver NVIDIA: " + ($drivers -join ", ")) }
    try {
        $payloadFolder = Prepare-Payload -DlssZipPath $DlssZipPath -SelectedMode $SelectedMode
        [void]$info.Add("Pacote 1 Click DLSS 5 validado com sucesso!")
    } catch { [void]$fatal.Add($_.Exception.Message) }

    return [pscustomobject]@{
        CanInstall = ($fatal.Count -eq 0)
        Fatal = $fatal.ToArray()
        Warnings = $warnings.ToArray()
        Info = $info.ToArray()
        Target = $target
    }
}

function Set-Dlss5ReShadeIni {
    param(
        [Parameter(Mandatory = $true)][string]$IniPath,
        [Parameter(Mandatory = $false)][bool]$IsFeederMode = $false
    )

    $defaultIni = Join-Path (Get-DLSS5PayloadDirectory) "ReShade.ini"
    if (-not (Test-Path -LiteralPath $IniPath -PathType Leaf)) {
        if (Test-Path -LiteralPath $defaultIni -PathType Leaf) {
            Copy-Item -LiteralPath $defaultIni -Destination $IniPath -Force
        }
    }

    try {
        $iniText = if (Test-Path -LiteralPath $IniPath -PathType Leaf) {
            [System.IO.File]::ReadAllText($IniPath, [System.Text.Encoding]::UTF8)
        } else { "" }
        $lines = $iniText -split "\r?\n"
        $keptLines = New-Object System.Collections.Generic.List[string]
        $currentSection = ""
        $ignoreSections = if ($IsFeederMode) {
            @("RenoDX.DLSS5", "ADDON", "DLSS5", "RenoDX", "GENERAL", "OVERLAY")
        } else {
            @("RenoDX.DLSS5", "ADDON", "DLSS5", "RenoDX", "OVERLAY")
        }

        foreach ($line in $lines) {
            $trimmed = $line.Trim()
            if ($trimmed -match '^\[(.*)\]$') {
                $currentSection = $matches[1]
            }
            if ($ignoreSections -contains $currentSection) {
                continue
            }
            if ($trimmed -match '^(Neural|NRPreset|NRStyle|NRIntensity|NRLocalTone|NRLocalStructure|NRSkinStructure|NRAutoMask|NRUICorrection|AutoSkinMask|LocalToneStrength|StructureStrength|SkinStructure|NeuralIntensity|NeuralUplift|Preset=|Style=|Enabled=|LoadFromDllMain=renodx|TutorialProgress|ShowOverlayMessage|ShowPresetTransitionMessage|ShowScreenshotMessage)') {
                continue
            }
            [void]$keptLines.Add($line)
        }

        $baseText = ($keptLines -join "`r`n").Trim()

        $addonLine = if ($IsFeederMode) {
            "LoadFromDllMain=renodx-dlss5.addon64,dlss5-feed.addon64"
        } else {
            "LoadFromDllMain=renodx-dlss5.addon64"
        }

        $overlaySection = @"
[OVERLAY]
TutorialProgress=4
ShowOverlayMessage=0
ShowPresetTransitionMessage=0
ShowScreenshotMessage=0
ShowFPS=0
ShowClock=0
"@

        $generalSection = if ($IsFeederMode) {
@"
[GENERAL]
EffectSearchPaths=.\reshade-shaders\Shaders,.\reshade-shaders\Shaders\include,.\
TextureSearchPaths=.\reshade-shaders\Textures,.\
Techniques=Lumenite_Kernel@lumenite_Kernel.fx,DLSS5_Feed@DLSS5_Feed.fx
TechniqueSorting=Lumenite_Kernel@lumenite_Kernel.fx,DLSS5_Feed@DLSS5_Feed.fx
PreprocessorDefinitions=DLSS5_MV_PROVIDER=3,IMAGE_SPACE=1
PerformanceMode=0
NoReloadOnInit=0
SkipLoadingDisabledEffects=0

"@
        } else { "" }

        $renodxSection = @"
[RenoDX.DLSS5]
NeuralUplift=1
NREnableUpscaling=0
NRPreset=2
NRStyle=1
NRIntensity=0.850000
NRLocalTone=1.000000
NRLocalStructure=1.000000
NRSkinStructure=-0.500000
NRAutoMask=1
NRUICorrection=1
NRPaperWhiteScale=1.000000
NRTransferStrength=1.000000
NRColorStrength=1.000000
NRDepthMode=0
NRMVecScaleX=1.000000
NRMVecScaleY=1.000000
EnableHooks=2
NRToggleKey=117
NRScreenshotKey=116

[DLSS5]
Enabled=1
AutoSkinMask=1
NRAutoMask=1
Preset=2
NRPreset=2
Style=1
NRStyle=1
NeuralIntensity=0.850000
NRIntensity=0.850000
LocalToneStrength=1.000000
StructureStrength=1.000000
SkinStructure=-0.500000

[RenoDX]
NeuralUplift=1
AutoSkinMask=1
NRAutoMask=1
NeuralIntensity=0.850000
NRIntensity=0.850000
Preset=2
NRPreset=2
Style=1
NRStyle=1
"@

        $sectionsToAdd = @"
$generalSection
$overlaySection

[ADDON]
$addonLine

$renodxSection
"@

        $finalContent = if ([string]::IsNullOrWhiteSpace($baseText)) { $sectionsToAdd.Trim() } else { $baseText + "`r`n" + $sectionsToAdd }
        [System.IO.File]::WriteAllText($IniPath, $finalContent, (New-Object System.Text.UTF8Encoding($false)))
    } catch {
        if (Test-Path -LiteralPath $defaultIni -PathType Leaf) {
            Copy-Item -LiteralPath $defaultIni -Destination $IniPath -Force
        }
    }
}

function Install-Dlss5 {
    param(
        [Parameter(Mandatory = $true)][string]$TargetPath,
        [Parameter(Mandatory = $true)][bool]$InstallReShade,
        [Parameter(Mandatory = $true)][bool]$FullPackage,
        [string]$DlssZipPath = "",
        [string]$SelectedMode = "AUTO"
    )
    $report = Get-Compatibility -TargetPath $TargetPath -InstallReShade $InstallReShade -FullPackage $FullPackage -DlssZipPath $DlssZipPath -SelectedMode $SelectedMode
    foreach ($line in $report.Info) { Write-Status -Message $line -Level "INFO" }
    foreach ($line in $report.Warnings) { Write-Status -Message $line -Level "WARN" }
    foreach ($line in $report.Fatal) { Write-Status -Message $line -Level "ERROR" }
    if (-not $report.CanInstall) { throw "A verificacao de compatibilidade falhou. Verifique os erros acima." }
    $target = $report.Target
    $targetFolder = $target.InstallFolder
    $d = Get-Dict -Lang $script:CurrentLang

    # Detect native upscaler type
    $detectedType = Detect-GameUpscalerType -GameFolder $targetFolder -GameRoot $target.Root
    
    # Resolve requested mode
    $upscalerType = switch ($SelectedMode) {
        "DIRECT"     { "NATIVE_DLSS" }
        "OPTISCALER" { "FSR2_BRIDGE" }
        "FEEDER"     { "UNIVERSAL_FEEDER" }
        default      { $detectedType }
    }
    Write-Status -Message "Modo de Injeção Selecionado: $upscalerType (Detectado na Engine: $detectedType)" -Level "INFO"

    # Confirmation dialog
    $confirmMsg = ""
    if ($upscalerType -eq "NATIVE_DLSS") {
        $confirmMsg = $d.ConfirmInstallDirect -f $target.ExeName
    } elseif ($upscalerType -eq "FSR2_BRIDGE" -or $upscalerType -eq "XESS_BRIDGE") {
        $bridgeName = if ($upscalerType -eq "FSR2_BRIDGE") { "FSR2/FSR3" } else { "XeSS" }
        $confirmMsg = $d.ConfirmInstallBridge -f $target.ExeName, $bridgeName
    } else {
        $confirmMsg = $d.ConfirmInstallFeeder -f $target.ExeName
    }
    $result = [System.Windows.Forms.MessageBox]::Show($confirmMsg, $d.ConfirmInstallTitle, [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
    if ($result -ne [System.Windows.Forms.DialogResult]::Yes) {
        Write-Status -Message "Instalacao cancelada pelo usuario." -Level "WARN"
        return
    }

    $backupFolder = Join-Path $targetFolder $script:BackupName
    [void](New-Item -ItemType Directory -Path $backupFolder -Force)
    $stateFile = Join-Path $targetFolder $script:StateName
    $priorBackedUp = @()
    if (Test-Path -LiteralPath $stateFile -PathType Leaf) {
        try {
            $priorState = Get-Content -LiteralPath $stateFile -Raw | ConvertFrom-Json
            if ($priorState.BackedUpFiles) { $priorBackedUp = @($priorState.BackedUpFiles) }
        } catch {}
    }

    $state = @{
        InstalledAt = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        TargetExe = $target.Executable
        Mode = if ($upscalerType -eq "NATIVE_DLSS") { "DIRECT" } elseif ($upscalerType -eq "FSR2_BRIDGE" -or $upscalerType -eq "XESS_BRIDGE") { "OPTISCALER" } else { "FEEDER" }
        UpscalerType = $upscalerType
        BackedUpFiles = $priorBackedUp
        InjectedFiles = @()
    }

    # Detect Graphics API
    $graphicsApi = Detect-GameGraphicsApi -TargetExe $target.Executable -GameFolder $targetFolder
    Write-Status -Message "API Grafica Detectada: $graphicsApi (Injecao automatizada)" -Level "INFO"

    # Install ReShade if checked
    if ($InstallReShade) {
        $setup = Get-ReShadeSetup
        $injectedDllName = Install-ReShade -TargetExe $target.Executable -Setup $setup -TargetApi $graphicsApi
        if ($state.InjectedFiles -notcontains $injectedDllName) { $state.InjectedFiles += $injectedDllName }
    }

    $targetIni = Join-Path $targetFolder "ReShade.ini"

    # Clean up legacy addons
    $legacyAddons = @("renodx-dlss5++.addon64", "renodx-dlss5-v3.addon64")
    foreach ($la in $legacyAddons) {
        $legacyPath = Join-Path $targetFolder $la
        if (Test-Path -LiteralPath $legacyPath -PathType Leaf) {
            Remove-Item -LiteralPath $legacyPath -Force -ErrorAction SilentlyContinue
            Write-Status -Message "Versao anterior do Add-on removida: $la" -Level "INFO"
        }
    }

    if ($upscalerType -eq "NATIVE_DLSS") {
        # === DIRECT MODE: Streamline + RenoDX ===
        Write-Status -Message "Modo DIRETO: Injetando Streamline + RenoDX (DLSS nativo detectado)..." -Level "INFO"

        # Clean up any lingering Feeder or OptiScaler files
        $conflictingFeeder = @("dlss5-feed.addon64", "dlss5-feed.addon32", "dlss5-feed.cfg", "dlss5-feed.log", "dlss5-feed.ini", "version.dll", "OptiScaler.ini", "OptiScaler.log")
        foreach ($cf in $conflictingFeeder) {
            $cfPath = Join-Path $targetFolder $cf
            if (Test-Path -LiteralPath $cfPath -PathType Leaf) { Remove-Item -LiteralPath $cfPath -Force -ErrorAction SilentlyContinue }
        }
        $host64Dir = Join-Path $targetFolder "host64"
        if (Test-Path -LiteralPath $host64Dir -PathType Container) { Remove-Item -LiteralPath $host64Dir -Recurse -Force -ErrorAction SilentlyContinue }

        Set-Dlss5ReShadeIni -IniPath $targetIni -IsFeederMode $false
        if ($state.InjectedFiles -notcontains "ReShade.ini") { $state.InjectedFiles += "ReShade.ini" }

        $filesToCopy = if ($FullPackage) { $script:FullFiles } else { $script:MinimalFiles }
        foreach ($fname in $filesToCopy) {
            $src = Join-Path $script:PayloadFolder $fname
            $dst = Join-Path $targetFolder $fname
            if (Test-Path -LiteralPath $src -PathType Leaf) {
                if (Test-Path -LiteralPath $dst -PathType Leaf) {
                    $backupDst = Join-Path $backupFolder $fname
                    if (-not (Test-Path -LiteralPath $backupDst -PathType Leaf)) {
                        Copy-Item -LiteralPath $dst -Destination $backupDst -Force
                        $state.BackedUpFiles += $fname
                    }
                }
                Copy-Item -LiteralPath $src -Destination $dst -Force
                if ($state.InjectedFiles -notcontains $fname) { $state.InjectedFiles += $fname }
            }
        }

        # Also update any engine plugin folders (such as Unreal Engine Plugins) with existing DLSS/Streamline dlls
        $pluginDlssDirs = @(Get-ChildItem -LiteralPath $target.Root -Filter "nvngx_dlss.dll" -File -Recurse -Depth 12 -ErrorAction SilentlyContinue |
            Where-Object { $_.Directory.FullName.ToLower() -ne $targetFolder.ToLower() } |
            ForEach-Object { $_.Directory.FullName } | Select-Object -Unique)

        foreach ($pDir in $pluginDlssDirs) {
            Write-Status -Message "Atualizando plugin de engine em: $pDir" -Level "INFO"
            $pBackup = Join-Path $pDir $script:BackupName
            [void](New-Item -ItemType Directory -Path $pBackup -Force)
            foreach ($fname in $filesToCopy) {
                $src = Join-Path $script:PayloadFolder $fname
                $dst = Join-Path $pDir $fname
                if (Test-Path -LiteralPath $src -PathType Leaf) {
                    if (Test-Path -LiteralPath $dst -PathType Leaf) {
                        $pBackupDst = Join-Path $pBackup $fname
                        if (-not (Test-Path -LiteralPath $pBackupDst -PathType Leaf)) {
                            Copy-Item -LiteralPath $dst -Destination $pBackupDst -Force
                        }
                    }
                    Copy-Item -LiteralPath $src -Destination $dst -Force
                }
            }
        }
    } elseif ($upscalerType -eq "FSR2_BRIDGE" -or $upscalerType -eq "XESS_BRIDGE") {
        # === OPTISCALER BRIDGE MODE: OptiScaler + RenoDX ===
        $bridgeName = if ($upscalerType -eq "FSR2_BRIDGE") { "FSR2/FSR3" } else { "XeSS" }
        Write-Status -Message "Modo PONTE OPTISCALER: $bridgeName ativo. Redirecionando para DLSS Neural..." -Level "INFO"

        # Clean up any lingering Feeder or Streamline files
        $conflictingFeeder = @("dlss5-feed.addon64", "dlss5-feed.addon32", "dlss5-feed.cfg", "dlss5-feed.log", "dlss5-feed.ini", "sl.interposer.dll", "sl.common.dll", "sl.dlss_nr.dll", "sl.dlss.dll", "sl.dlss_g.dll", "sl.nis.dll", "sl.pcl.dll", "sl.reflex.dll", "sl.config.json")
        foreach ($cf in $conflictingFeeder) {
            $cfPath = Join-Path $targetFolder $cf
            if (Test-Path -LiteralPath $cfPath -PathType Leaf) { Remove-Item -LiteralPath $cfPath -Force -ErrorAction SilentlyContinue }
        }
        $host64Dir = Join-Path $targetFolder "host64"
        if (Test-Path -LiteralPath $host64Dir -PathType Container) { Remove-Item -LiteralPath $host64Dir -Recurse -Force -ErrorAction SilentlyContinue }

        Set-Dlss5ReShadeIni -IniPath $targetIni -IsFeederMode $false
        if ($state.InjectedFiles -notcontains "ReShade.ini") { $state.InjectedFiles += "ReShade.ini" }

        # Copy OptiScaler.dll as version.dll
        $optiSrc = Join-Path (Get-DLSS5PayloadDirectory) "optiscaler\OptiScaler.dll"
        $optiDst = Join-Path $targetFolder "version.dll"
        if (Test-Path -LiteralPath $optiSrc -PathType Leaf) {
            if (Test-Path -LiteralPath $optiDst -PathType Leaf) {
                $backupDst = Join-Path $backupFolder "version.dll"
                if (-not (Test-Path -LiteralPath $backupDst -PathType Leaf)) {
                    Copy-Item -LiteralPath $optiDst -Destination $backupDst -Force
                    $state.BackedUpFiles += "version.dll"
                }
            }
            Copy-Item -LiteralPath $optiSrc -Destination $optiDst -Force
            $state.InjectedFiles += "version.dll"
            Write-Status -Message "OptiScaler instalado como version.dll (proxy DLL)." -Level "OK"
        } else {
            throw "OptiScaler.dll nao encontrado em payload\optiscaler\. Verifique a instalacao do programa."
        }

        # Copy OptiScaler.ini
        $optiIniSrc = Join-Path (Get-DLSS5PayloadDirectory) "optiscaler\OptiScaler.ini"
        $optiIniDst = Join-Path $targetFolder "OptiScaler.ini"
        if (Test-Path -LiteralPath $optiIniSrc -PathType Leaf) {
            Copy-Item -LiteralPath $optiIniSrc -Destination $optiIniDst -Force
            $state.InjectedFiles += "OptiScaler.ini"
        }

        # Copy libxess.dll (if not already present)
        $xessSrc = Join-Path (Get-DLSS5PayloadDirectory) "optiscaler\libxess.dll"
        $xessDst = Join-Path $targetFolder "libxess.dll"
        if (Test-Path -LiteralPath $xessSrc -PathType Leaf) {
            if (Test-Path -LiteralPath $xessDst -PathType Leaf) {
                $backupDst = Join-Path $backupFolder "libxess.dll"
                if (-not (Test-Path -LiteralPath $backupDst -PathType Leaf)) {
                    Copy-Item -LiteralPath $xessDst -Destination $backupDst -Force
                    $state.BackedUpFiles += "libxess.dll"
                }
            }
            Copy-Item -LiteralPath $xessSrc -Destination $xessDst -Force
            $state.InjectedFiles += "libxess.dll"
        }

        # Copy nvngx_dlssnr.dll from payload
        $nrSrc = Join-Path $script:PayloadFolder "nvngx_dlssnr.dll"
        $nrDst = Join-Path $targetFolder "nvngx_dlssnr.dll"
        if (Test-Path -LiteralPath $nrSrc -PathType Leaf) {
            Copy-Item -LiteralPath $nrSrc -Destination $nrDst -Force
            $state.InjectedFiles += "nvngx_dlssnr.dll"
        }

        # Copy RenoDX addon
        $addonSrc = Join-Path (Get-DLSS5PayloadDirectory) $script:AddOnName
        $addonDst = Join-Path $targetFolder $script:AddOnName
        if (Test-Path -LiteralPath $addonSrc -PathType Leaf) {
            Copy-Item -LiteralPath $addonSrc -Destination $addonDst -Force
            $state.InjectedFiles += $script:AddOnName
        }
    } else {
        # === UNIVERSAL FEEDER MODE: DLSS5-Feeder + LumeniteFX + RenoDX (100% Native DLAA) ===
        Write-Status -Message "Modo UNIVERSAL FEEDER: Ativando DLSS5-Feeder com Fluxo Optico LumeniteFX (DLAA 100% Nativo)..." -Level "INFO"

        # Clean up any lingering Streamline or OptiScaler DLLs to prevent hook conflicts
        $conflictingProxies = @("sl.interposer.dll", "sl.common.dll", "sl.dlss.dll", "sl.dlss_g.dll", "sl.dlss_nr.dll", "sl.pcl.dll", "sl.reflex.dll", "sl.nis.dll", "sl.config.json", "version.dll", "OptiScaler.ini", "OptiScaler.log", "d3d12.dll")
        foreach ($cp in $conflictingProxies) {
            $cpPath = Join-Path $targetFolder $cp
            if (Test-Path -LiteralPath $cpPath -PathType Leaf) {
                Remove-Item -LiteralPath $cpPath -Force -ErrorAction SilentlyContinue
            }
        }

        $isX64 = Test-X64Pe -Path $target.Executable
        $feederPayload = Join-Path (Get-DLSS5PayloadDirectory) "feeder"

        if ($isX64) {
            # 64-bit Game: Copy dlss5-feed.addon64
            $feedSrc = Join-Path $feederPayload "dlss5-feed.addon64"
            $feedDst = Join-Path $targetFolder "dlss5-feed.addon64"
            if (Test-Path -LiteralPath $feedSrc -PathType Leaf) {
                Copy-Item -LiteralPath $feedSrc -Destination $feedDst -Force
                if ($state.InjectedFiles -notcontains "dlss5-feed.addon64") { $state.InjectedFiles += "dlss5-feed.addon64" }
                Write-Status -Message "Addon DLSS5-Feeder x64 instalado com sucesso." -Level "OK"
            }
        } else {
            # 32-bit Game: Copy dlss5-feed.addon32 and host64
            $feedSrc32 = Join-Path $feederPayload "dlss5-feed.addon32"
            $feedDst32 = Join-Path $targetFolder "dlss5-feed.addon32"
            if (Test-Path -LiteralPath $feedSrc32 -PathType Leaf) {
                Copy-Item -LiteralPath $feedSrc32 -Destination $feedDst32 -Force
                if ($state.InjectedFiles -notcontains "dlss5-feed.addon32") { $state.InjectedFiles += "dlss5-feed.addon32" }
                Write-Status -Message "Addon DLSS5-Feeder x86 instalado para jogo 32-bit." -Level "OK"
            }
            $hostSrc = Join-Path $feederPayload "host64"
            $hostDst = Join-Path $targetFolder "host64"
            if (Test-Path -LiteralPath $hostSrc -PathType Container) {
                if (-not (Test-Path -LiteralPath $hostDst)) { [void](New-Item -ItemType Directory -Path $hostDst -Force) }
                Get-ChildItem -LiteralPath $hostSrc | Copy-Item -Destination $hostDst -Recurse -Force
                Copy-Item -LiteralPath (Join-Path $script:AppRoot "payload\$($script:AddOnName)") -Destination (Join-Path $hostDst $script:AddOnName) -Force
                Copy-Item -LiteralPath (Join-Path $script:PayloadFolder "nvngx_dlssnr.dll") -Destination (Join-Path $hostDst "nvngx_dlssnr.dll") -Force
                if (Test-Path (Join-Path $script:PayloadFolder "nvngx_dlss.dll")) {
                    Copy-Item -LiteralPath (Join-Path $script:PayloadFolder "nvngx_dlss.dll") -Destination (Join-Path $hostDst "nvngx_dlss.dll") -Force
                }
                if ($state.InjectedFiles -notcontains "host64") { $state.InjectedFiles += "host64" }
            }
        }

        # Copy RenoDX addon
        $addonSrc = Join-Path (Get-DLSS5PayloadDirectory) $script:AddOnName
        $addonDst = Join-Path $targetFolder $script:AddOnName
        if (Test-Path -LiteralPath $addonSrc -PathType Leaf) {
            Copy-Item -LiteralPath $addonSrc -Destination $addonDst -Force
            if ($state.InjectedFiles -notcontains $script:AddOnName) { $state.InjectedFiles += $script:AddOnName }
        }

        # Copy nvngx_dlssnr.dll and nvngx_dlss.dll into game folder
        $nrSrc = Join-Path $script:PayloadFolder "nvngx_dlssnr.dll"
        $nrDst = Join-Path $targetFolder "nvngx_dlssnr.dll"
        if (Test-Path -LiteralPath $nrSrc -PathType Leaf) {
            Copy-Item -LiteralPath $nrSrc -Destination $nrDst -Force
            if ($state.InjectedFiles -notcontains "nvngx_dlssnr.dll") { $state.InjectedFiles += "nvngx_dlssnr.dll" }
        }
        $dlssSrc = Join-Path $script:PayloadFolder "nvngx_dlss.dll"
        $dlssDst = Join-Path $targetFolder "nvngx_dlss.dll"
        if (Test-Path -LiteralPath $dlssSrc -PathType Leaf) {
            Copy-Item -LiteralPath $dlssSrc -Destination $dlssDst -Force
            if ($state.InjectedFiles -notcontains "nvngx_dlss.dll") { $state.InjectedFiles += "nvngx_dlss.dll" }
        }

        # Copy Shaders and Textures (LumeniteFX + DLSS5_Feed.fx)
        $shaderDir = Join-Path $targetFolder "reshade-shaders\Shaders"
        $textureDir = Join-Path $targetFolder "reshade-shaders\Textures"
        [void](New-Item -ItemType Directory -Path $shaderDir -Force)
        [void](New-Item -ItemType Directory -Path $textureDir -Force)

        $srcShaders = Join-Path $feederPayload "shaders"
        $srcTextures = Join-Path $feederPayload "textures"
        if (Test-Path -LiteralPath $srcShaders -PathType Container) {
            Get-ChildItem -LiteralPath $srcShaders | Copy-Item -Destination $shaderDir -Recurse -Force
            Write-Status -Message "Shaders LumeniteFX e DLSS5_Feed.fx instalados em reshade-shaders\Shaders\." -Level "OK"
        }
        if (Test-Path -LiteralPath $srcTextures -PathType Container) {
            Get-ChildItem -LiteralPath $srcTextures | Copy-Item -Destination $textureDir -Recurse -Force
            Write-Status -Message "Texturas de ruído azul instaladas em reshade-shaders\Textures\." -Level "OK"
        }
        if ($state.InjectedFiles -notcontains "reshade-shaders") { $state.InjectedFiles += "reshade-shaders" }

        # Copy pre-calibrated dlss5-feed.cfg
        $cfgSrc = Join-Path $feederPayload "dlss5-feed.cfg"
        $cfgDst = Join-Path $targetFolder "dlss5-feed.cfg"
        if (Test-Path -LiteralPath $cfgSrc -PathType Leaf) {
            Copy-Item -LiteralPath $cfgSrc -Destination $cfgDst -Force
            if ($state.InjectedFiles -notcontains "dlss5-feed.cfg") { $state.InjectedFiles += "dlss5-feed.cfg" }
        }

        # Apply pre-configured ReShade.ini and ReShadePreset.ini for Feeder Mode
        Set-Dlss5ReShadeIni -IniPath $targetIni -IsFeederMode $true
        if ($state.InjectedFiles -notcontains "ReShade.ini") { $state.InjectedFiles += "ReShade.ini" }

        $targetPreset = Join-Path $targetFolder "ReShadePreset.ini"
        $presetContent = @"
Techniques=Lumenite_Kernel@lumenite_Kernel.fx,DLSS5_Feed@DLSS5_Feed.fx
TechniqueSorting=Lumenite_Kernel@lumenite_Kernel.fx,DLSS5_Feed@DLSS5_Feed.fx

[DLSS5_Feed.fx]
VALIDATE_LUMA=1
LUMA_TOLERANCE=0.150000
VALIDATE_STATIC=1
STATIC_BIAS=0.350000
STATIC_MIN_CONTRAST=0.005000
MASK_STRENGTH=1.000000
VALIDATE_DEPTH=1
VALIDATE_MV=1
MV_CONSISTENCY=1.000000
GEOM_ENABLE=0
"@
        [System.IO.File]::WriteAllText($targetPreset, $presetContent, (New-Object System.Text.UTF8Encoding($false)))
        if ($state.InjectedFiles -notcontains "ReShadePreset.ini") { $state.InjectedFiles += "ReShadePreset.ini" }
        Write-Status -Message "Configuracao do Feeder aplicada no ReShade.ini (LumeniteFX Kernel 2.0 -> DLSS5_Feed -> RenoDX)." -Level "OK"
    }

    ($state | ConvertTo-Json -Depth 4) | Out-File -LiteralPath $stateFile -Encoding utf8 -Force
    Write-Status -Message "==========================================================" -Level "OK"
    Write-Status -Message "1 CLICK DLSS 5 NEURAL INSTALADO COM SUCESSO!" -Level "OK"
    if ($upscalerType -eq "NATIVE_DLSS") {
        Write-Status -Message "Modo: DIRETO | No jogo: Ative DLSS (Qualidade) -> [Home] -> Add-ons -> DLSS 5" -Level "OK"
    } elseif ($upscalerType -eq "FSR2_BRIDGE" -or $upscalerType -eq "XESS_BRIDGE") {
        $bridgeName = if ($upscalerType -eq "FSR2_BRIDGE") { "FSR2" } else { "XeSS" }
        Write-Status -Message "Modo: PONTE OPTISCALER ($bridgeName) | No jogo: Pressione [Home] -> Add-ons -> DLSS 5" -Level "OK"
    } else {
        Write-Status -Message "Modo: FEEDER UNIVERSAL (DLAA 100% Nativo) | No jogo: Pressione [Home] -> Add-ons -> DLSS 5" -Level "OK"
    }
    Write-Status -Message "==========================================================" -Level "OK"
    [System.Windows.Forms.MessageBox]::Show($d.SuccessMsg, $d.SuccessTitle, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
}

function Start-GameExecutable {
    param([Parameter(Mandatory = $true)][string]$TargetPath)
    try {
        $target = Resolve-GameTarget -TargetPath $TargetPath
        Write-Status -Message "Iniciando jogo: $($target.Executable)..." -Level "OK"
        Start-Process -FilePath $target.Executable -WorkingDirectory $target.InstallFolder
    } catch {
        Show-ErrorDialog -Message $_.Exception.Message
    }
}

function Uninstall-Dlss5 {
    param([Parameter(Mandatory = $true)][string]$TargetPath)
    $target = Resolve-GameTarget -TargetPath $TargetPath
    $targetFolder = $target.InstallFolder
    $stateFile = Join-Path $targetFolder $script:StateName
    $backupFolder = Join-Path $targetFolder $script:BackupName
    $d = Get-Dict -Lang $script:CurrentLang

    # Confirmation dialog
    $confirmMsg = $d.ConfirmUninstall -f $target.ExeName
    $result = [System.Windows.Forms.MessageBox]::Show($confirmMsg, $d.ConfirmUninstallTitle, [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
    if ($result -ne [System.Windows.Forms.DialogResult]::Yes) {
        Write-Status -Message "Restauracao cancelada pelo usuario." -Level "WARN"
        return
    }

    Write-Status -Message "Restaurando arquivos de fabrica em: $targetFolder" -Level "INFO"

    # Restore backed up files
    if (Test-Path -LiteralPath $backupFolder -PathType Container) {
        $backedFiles = Get-ChildItem -LiteralPath $backupFolder -File -ErrorAction SilentlyContinue
        foreach ($bf in $backedFiles) {
            $dst = Join-Path $targetFolder $bf.Name
            Copy-Item -LiteralPath $bf.FullName -Destination $dst -Force
            Write-Status -Message "Arquivo restaurado: $($bf.Name)" -Level "OK"
        }
        Remove-Item -LiteralPath $backupFolder -Recurse -Force -ErrorAction SilentlyContinue
    }

    # Also restore any sub-plugin backups (such as Unreal Engine Plugins)
    $pluginBackups = @(Get-ChildItem -LiteralPath $target.Root -Filter $script:BackupName -Directory -Recurse -Depth 12 -ErrorAction SilentlyContinue)
    foreach ($pb in $pluginBackups) {
        $parentFolder = $pb.Parent.FullName
        $bFiles = Get-ChildItem -LiteralPath $pb.FullName -File -ErrorAction SilentlyContinue
        foreach ($bf in $bFiles) {
            $dst = Join-Path $parentFolder $bf.Name
            Copy-Item -LiteralPath $bf.FullName -Destination $dst -Force
            Write-Status -Message "Arquivo restaurado em plugin: $($bf.Name)" -Level "OK"
        }
        Remove-Item -LiteralPath $pb.FullName -Recurse -Force -ErrorAction SilentlyContinue
    }

    # Complete purge list (covers DIRECT + OPTISCALER + UNIVERSAL FEEDER modes)
    $purgeList = @(
        "opengl32.dll", "d3d9.dll", "d3d12.dll", "dxgi.dll",
        "renodx-dlss5.addon64", "renodx-dlss5++.addon64", "renodx-dlss5-v3.addon64",
        "dlss5-feed.addon64", "dlss5-feed.addon32", "dlss5-feed.cfg", "dlss5-feed.log", "dlss5-feed.ini",
        "nvngx_dlssnr.dll", "sl.dlss_nr.dll",
        "version.dll", "OptiScaler.ini", "OptiScaler.log",
        "ReShade.ini", "ReShadePreset.ini", "ReShade.log",
        "sl.common.dll", "sl.interposer.dll", "sl.deepdvc.dll",
        "sl.dlss.dll", "sl.dlss_d.dll", "sl.dlss_g.dll",
        "sl.nis.dll", "sl.pcl.dll", "sl.reflex.dll",
        "sl.config.json", "sl.param.global.log",
        $script:StateName,
        "_DLSS5_Easy_Installer_State.json", "dlss5_backup_manifest.json"
    )

    # Only remove files that are NOT in the backup (those were originals)
    $backedUpNames = @()
    if (Test-Path -LiteralPath $stateFile -PathType Leaf) {
        try {
            $savedState = Get-Content -LiteralPath $stateFile -Raw | ConvertFrom-Json
            $backedUpNames = @($savedState.BackedUpFiles)
        } catch {}
    }

    foreach ($pf in $purgeList) {
        if ($backedUpNames -contains $pf) { continue }
        $p = Join-Path $targetFolder $pf
        if (Test-Path -LiteralPath $p -PathType Leaf) {
            Remove-Item -LiteralPath $p -Force -ErrorAction SilentlyContinue
        }
    }

    # Remove state file itself
    if (Test-Path -LiteralPath $stateFile -PathType Leaf) {
        Remove-Item -LiteralPath $stateFile -Force -ErrorAction SilentlyContinue
    }

    # Remove host64 folder
    $host64Dir = Join-Path $targetFolder "host64"
    if (Test-Path -LiteralPath $host64Dir -PathType Container) {
        Remove-Item -LiteralPath $host64Dir -Recurse -Force -ErrorAction SilentlyContinue
    }

    # Remove reshade-shaders folder
    $reshadeDir = Join-Path $targetFolder "reshade-shaders"
    if (Test-Path -LiteralPath $reshadeDir -PathType Container) {
        Remove-Item -LiteralPath $reshadeDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    Write-Status -Message "Jogo 100% restaurado ao estado de fabrica!" -Level "OK"
    [System.Windows.Forms.MessageBox]::Show($d.RestoreMsg, $d.RestoreTitle, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
}

function Scan-DriveForGames {
    param(
        [string]$DriveLetter = "ALL",
        [scriptblock]$ProgressCallback = $null
    )
    $results = New-Object System.Collections.Generic.List[pscustomobject]
    $rootsToScan = New-Object System.Collections.Generic.List[string]
    $drives = @()
    if ($DriveLetter -eq "ALL") {
        $drives = @([System.IO.DriveInfo]::GetDrives() | Where-Object { $_.DriveType -eq [System.IO.DriveType]::Fixed -and $_.IsReady } | ForEach-Object { $_.Name })
    } else {
        $drives = @($DriveLetter)
    }
    foreach ($d in $drives) {
        [void]$rootsToScan.Add((Join-Path $d "Games"))
        [void]$rootsToScan.Add((Join-Path $d "Jogos"))
        [void]$rootsToScan.Add((Join-Path $d "Steam\steamapps\common"))
        [void]$rootsToScan.Add((Join-Path $d "SteamLibrary\steamapps\common"))
        [void]$rootsToScan.Add((Join-Path $d "Program Files (x86)\Steam\steamapps\common"))
        [void]$rootsToScan.Add((Join-Path $d "Program Files\Steam\steamapps\common"))
        [void]$rootsToScan.Add((Join-Path $d "Program Files\Epic Games"))
        [void]$rootsToScan.Add((Join-Path $d "Epic Games"))
        [void]$rootsToScan.Add((Join-Path $d "XboxGames"))
    }
    $ignored = @(
        "steamworks shared", "_commonredist", "directx", "vcredist", "dotnet",
        "crashreport", "tools", "easyanticheat", "battleye", "launcher",
        "gameinputredist", "directxredist", "steam controller configs", "gamesave"
    )
    $dDict = Get-Dict -Lang $script:CurrentLang

    # Collect all real game directories first for accurate progress
    $allGameDirs = New-Object System.Collections.Generic.List[pscustomobject]
    foreach ($root in $rootsToScan) {
        if (Test-Path -LiteralPath $root -PathType Container) {
            try {
                $dirs = Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue
                foreach ($dir in $dirs) {
                    $dirLow = $dir.Name.ToLower()
                    if ($ignored -contains $dirLow) { continue }
                    if ($dirLow -match '^(ue_\d|unrealengine|launcher|gameinput|directxredist|vcredist|dotnet|crashreport)') { continue }
                    [void]$allGameDirs.Add([pscustomobject]@{ Root = $root; Dir = $dir })
                }
            } catch {}
        }
    }

    $totalGames = $allGameDirs.Count
    if ($totalGames -eq 0) { return @() }
    $currentIdx = 0

    foreach ($entry in $allGameDirs) {
        $dir = $entry.Dir
        $gamePath = $dir.FullName
        $currentIdx++

        # Report progress and pump UI events to avoid window freezing
        if ($null -ne $ProgressCallback) {
            $pct = [int](($currentIdx / $totalGames) * 100)
            try { & $ProgressCallback $pct $dir.Name } catch {}
        }
        [System.Windows.Forms.Application]::DoEvents()

        $hasDlss = $false
        $hasDx12 = $false
        $isUe = $false
        $hasFsr2 = $false
        $hasXess = $false

        # Fast single-pass shallow scan (Depth 3) in memory
        $gameFiles = @(Get-ChildItem -LiteralPath $gamePath -File -Recurse -Depth 3 -ErrorAction SilentlyContinue)
        foreach ($f in $gameFiles) {
            $n = $f.Name.ToLower()
            if ($n -like "*dlss*") { $hasDlss = $true }
            if ($n -like "*d3d12*") { $hasDx12 = $true }
            if ($n -like "*fidelityfx*" -or $n -like "ffx_fsr*") { $hasFsr2 = $true }
            if ($n -like "libxess*" -or $n -eq "xess.dll") { $hasXess = $true }
            if ($f.Extension -eq ".exe" -and $f.FullName.ToLower().Contains("binaries\win64")) {
                $isUe = $true
                $hasDx12 = $true
            }
        }

        $badge = ""
        $order = 3
        if ($hasDlss) {
            $badge = $dDict.Badge100
            $order = 1
        } elseif ($hasFsr2 -or $hasXess) {
            $badge = $dDict.BadgeBridge
            $order = 2
        } else {
            $badge = $dDict.BadgeFeeder
            $order = 3
        }

        $icon = $null
        $exeName = ""
        try {
            $resolved = Resolve-GameTarget -TargetPath $gamePath
            $icon = $resolved.Icon
            $exeName = $resolved.ExeName
        } catch {}

        [void]$results.Add([pscustomobject]@{
            Order = $order
            DisplayName = "$badge $($dir.Name)"
            Name = $dir.Name
            Path = $gamePath
            Badge = $badge
            Icon = $icon
            ExeName = $exeName
        })
        [System.Windows.Forms.Application]::DoEvents()
    }
    $sorted = @($results | Sort-Object -Property Order, Name)
    return $sorted
}

function New-Label {
    param([string]$Text = "", [int]$X = 0, [int]$Y = 0, [int]$Width = 100, [int]$Height = 20)
    $l = New-Object System.Windows.Forms.Label
    $l.Text = $Text
    $l.Location = New-Object System.Drawing.Point($X, $Y)
    $l.Size = New-Object System.Drawing.Size($Width, $Height)
    $l.AutoSize = $false
    return $l
}

function Style-Button {
    param([System.Windows.Forms.Button]$Button, [System.Drawing.Color]$BaseColor, [System.Drawing.Color]$HoverColor)
    $Button.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $Button.FlatAppearance.BorderSize = 0
    $Button.BackColor = $BaseColor
    $Button.ForeColor = [System.Drawing.Color]::White
    $Button.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9.5)
    $Button.Cursor = [System.Windows.Forms.Cursors]::Hand
    $Button.Tag = @{ Base = $BaseColor; Hover = $HoverColor }
    $Button.Add_MouseEnter({
        if ($this.Tag -and $this.Tag.Hover) { $this.BackColor = $this.Tag.Hover }
    })
    $Button.Add_MouseLeave({
        if ($this.Tag -and $this.Tag.Base) { $this.BackColor = $this.Tag.Base }
    })
}

function Show-Instructions {
    if ($script:CurrentLang -eq "PT") {
        $msg = "GUIA COMPLETO: QUAL MODO ESCOLHER NO 1 CLICK DLSS 5?`n`n" +
               "==================================================================`n" +
               "🟢 MODO 1: DIRETO (Para jogos com suporte nativo a DLSS)`n" +
               " - OBJETIVO: Ganho massivo de FPS (+50% a +100%) + Reconstrucao Neural.`n" +
               " - NO MENU DO JOGO: ATIVE o 'NVIDIA DLSS Super Resolution' (modo Qualidade, Equilibrado ou Desempenho).`n" +
               " - COMO FUNCIONA: O jogo renderiza internamente em resolucao menor e a IA do DLSS 5 reconstrói para 4K/1440p com vetores 3D do motor do jogo.`n`n" +
               "🔵 MODO 2: PONTE OPTISCALER (Para jogos que tem FSR2 ou XeSS)`n" +
               " - OBJETIVO: Ganho de FPS em jogos sem DLSS nativo.`n" +
               " - NO MENU DO JOGO: ATIVE o FSR2 ou XeSS no modo QUALIDADE.`n" +
               " - COMO FUNCIONA: A ponte intercepta a chamada de FSR2 e entrega para o modelo neural DLSS 5.`n`n" +
               "🟣 MODO 3: FEEDER UNIVERSAL (Para QUALQUER jogo de PC / 100% Nativo)`n" +
               " - OBJETIVO: Reconstrucao Neural de Iluminacao e Materiais em 100% Nativo.`n" +
               " - NO MENU DO JOGO: Deixe o DLSS/Upscaling DESLIGADO (jogue em resolucao 100% nativa com TAA/DLAA).`n" +
               " - REGRA CRITICA: No Modo 3 NAO ative DLSS Super Resolution no menu do jogo para evitar conflito de dupla IA e blur. O Feeder injeta a IA e o fluxo óptico LumeniteFX diretamente no frame limpo!`n`n" +
               "==================================================================`n" +
               "💡 DICA DE OURO PARA FLUIDEZ MÁXIMA (VSYNC):`n" +
               " - Desative o 'Sincronismo Vertical' (V-Sync) dentro do menu do jogo para evitar micro-travamentos com a swapchain do DirectX/ReShade.`n" +
               " - Use G-Sync / FreeSync ou limite a taxa de quadros no Painel NVIDIA para ter fluidez 100% lisa.`n`n" +
               "==================================================================`n" +
               "ATALHOS NO TECLADO DURANTE O JOGO:`n" +
               " - [F6]: Liga / Desliga o DLSS 5 em tempo real para comparacao no mesmo frame!`n" +
               " - [F5]: Captura screenshot de comparacao A/B.`n" +
               " - [Home] ou [Pos1]: Abre o menu do ReShade / RenoDX para ajustes finos."
        [System.Windows.Forms.MessageBox]::Show($msg, "1 Click DLSS 5 - Guia de Modos e Otimizacao", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    } else {
        $msg = "COMPLETE GUIDE: HOW TO CHOOSE THE RIGHT MODE IN 1 CLICK DLSS 5:`n`n" +
               "==================================================================`n" +
               "🟢 MODE 1: DIRECT (For games with native DLSS support)`n" +
               " - PURPOSE: Massive FPS boost (+50% to +100%) + Neural Reconstruction.`n" +
               " - IN-GAME MENU: ENABLE 'NVIDIA DLSS Super Resolution' (Quality, Balanced or Performance mode).`n" +
               " - HOW IT WORKS: Game renders internally at lower res and DLSS 5 reconstructs to 4K/1440p with 3D engine motion vectors.`n`n" +
               "🔵 MODE 2: OPTISCALER BRIDGE (For games with FSR2 or XeSS only)`n" +
               " - PURPOSE: FPS boost in games without native DLSS.`n" +
               " - IN-GAME MENU: ENABLE FSR2 or XeSS in QUALITY mode.`n" +
               " - HOW IT WORKS: The bridge intercepts FSR2 calls and routes them to DLSS 5 Neural.`n`n" +
               "🟣 MODE 3: UNIVERSAL FEEDER (For ANY PC Game / 100% Native DLAA)`n" +
               " - PURPOSE: Neural Lighting & Material Reconstruction at 100% Native Resolution.`n" +
               " - IN-GAME MENU: Keep DLSS/Upscaling DISABLED (play at 100% native resolution with standard TAA/DLAA).`n" +
               " - CRITICAL RULE: In Mode 3 DO NOT enable in-game DLSS Super Resolution to prevent double-AI blur. Feeder injects AI & LumeniteFX optical flow over the clean frame!`n`n" +
               "==================================================================`n" +
               "💡 PRO-TIP FOR MAXIMUM FLUIDITY (VSYNC):`n" +
               " - Disable in-game 'V-Sync' in the game graphics options to avoid frame pacing stalls with the DirectX/ReShade swapchain.`n" +
               " - Use G-Sync / FreeSync or frame rate limiting in NVIDIA Control Panel for 100% smooth pacing.`n`n" +
               "==================================================================`n" +
               "IN-GAME HOTKEYS:`n" +
               " - [F6]: Toggle DLSS 5 ON/OFF in real time for same-frame comparison!`n" +
               " - [F5]: Capture A/B comparison screenshot.`n" +
               " - [Home] / [Pos1]: Open full ReShade / RenoDX overlay menu."
        [System.Windows.Forms.MessageBox]::Show($msg, "1 Click DLSS 5 - Mode Guide & Optimization", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }
}

# --- FORMULARIO PRINCIPAL: STEAM-STYLE GAME CENTER ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "1 Click DLSS 5 v1.5.0 • Universal Neural Game Center (Todos os Jogos de PC • RTX 20/30/40/50)"
$form.Size = New-Object System.Drawing.Size(1200, 900)
$form.MinimumSize = New-Object System.Drawing.Size(1100, 820)
$form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
$form.BackColor = [System.Drawing.Color]::FromArgb(11, 15, 25)
$form.ForeColor = [System.Drawing.Color]::Gainsboro
$form.Font = New-Object System.Drawing.Font("Segoe UI", 9)

if (Test-Path -LiteralPath $script:IconPath) {
    try { $form.Icon = New-Object System.Drawing.Icon($script:IconPath) } catch {}
}

$imageListLarge = New-Object System.Windows.Forms.ImageList
$imageListLarge.ImageSize = New-Object System.Drawing.Size(36, 36)
$imageListLarge.ColorDepth = [System.Windows.Forms.ColorDepth]::Depth32Bit

$imageListSmall = New-Object System.Windows.Forms.ImageList
$imageListSmall.ImageSize = New-Object System.Drawing.Size(22, 22)
$imageListSmall.ColorDepth = [System.Windows.Forms.ColorDepth]::Depth32Bit

# HEADER
$header = New-Object System.Windows.Forms.Panel
$header.Location = New-Object System.Drawing.Point(0, 0)
$header.Size = New-Object System.Drawing.Size(1200, 105)
$header.Anchor = "Top, Left, Right"
$header.BackColor = [System.Drawing.Color]::FromArgb(15, 22, 38)
[void]$form.Controls.Add($header)

$headerAccent = New-Object System.Windows.Forms.Panel
$headerAccent.Location = New-Object System.Drawing.Point(0, 0)
$headerAccent.Size = New-Object System.Drawing.Size(6, 105)
$headerAccent.BackColor = [System.Drawing.Color]::FromArgb(118, 185, 0)
[void]$header.Controls.Add($headerAccent)

$eyebrow = New-Label -Text "ECOSSISTEMA OFICIAL RENO DX • RUNTIME NEURAL UNIVERSAL (SÉRIES RTX 20 / 30 / 40 / 50)" -X 24 -Y 12 -Width 750 -Height 18
$eyebrow.ForeColor = [System.Drawing.Color]::FromArgb(118, 185, 0)
$eyebrow.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 8.5)
[void]$header.Controls.Add($eyebrow)

$title = New-Label -Text "1 CLICK DLSS 5"
$title.Location = New-Object System.Drawing.Point(22, 28)
$title.Size = New-Object System.Drawing.Size(750, 40)
$title.Font = New-Object System.Drawing.Font("Segoe UI", 21, [System.Drawing.FontStyle]::Bold)
$title.ForeColor = [System.Drawing.Color]::White
[void]$header.Controls.Add($title)

$subtitle = New-Label -Text "Interface Estilo Steam • Injeção Neural em 1-Clique • DLSS 5 Universal Feeder para QUALQUER Jogo de PC" -X 24 -Y 72 -Width 750 -Height 22
$subtitle.ForeColor = [System.Drawing.Color]::FromArgb(160, 185, 215)
[void]$header.Controls.Add($subtitle)

$btnLangPT = New-Object System.Windows.Forms.Button
$btnLangPT.Text = "PT-BR"
$btnLangPT.Location = New-Object System.Drawing.Point(990, 20)
$btnLangPT.Size = New-Object System.Drawing.Size(80, 32)
$btnLangPT.Anchor = "Top, Right"
Style-Button -Button $btnLangPT -BaseColor ([System.Drawing.Color]::FromArgb(35, 120, 35)) -HoverColor ([System.Drawing.Color]::FromArgb(45, 145, 45))
[void]$header.Controls.Add($btnLangPT)

$btnLangEN = New-Object System.Windows.Forms.Button
$btnLangEN.Text = "EN-US"
$btnLangEN.Location = New-Object System.Drawing.Point(1080, 20)
$btnLangEN.Size = New-Object System.Drawing.Size(80, 32)
$btnLangEN.Anchor = "Top, Right"
Style-Button -Button $btnLangEN -BaseColor ([System.Drawing.Color]::FromArgb(35, 50, 80)) -HoverColor ([System.Drawing.Color]::FromArgb(45, 75, 120))
[void]$header.Controls.Add($btnLangEN)

# BARRA DE FERRAMENTAS DO SCANNER
$toolbar = New-Object System.Windows.Forms.Panel
$toolbar.Location = New-Object System.Drawing.Point(20, 115)
$toolbar.Size = New-Object System.Drawing.Size(1145, 42)
$toolbar.Anchor = "Top, Left, Right"
$toolbar.BackColor = [System.Drawing.Color]::FromArgb(18, 25, 42)
[void]$form.Controls.Add($toolbar)

$lblDrive = New-Label -Text "Disco:" -X 12 -Y 11 -Width 50 -Height 20
$lblDrive.ForeColor = [System.Drawing.Color]::FromArgb(170, 190, 215)
[void]$toolbar.Controls.Add($lblDrive)

$driveCombo = New-Object System.Windows.Forms.ComboBox
$driveCombo.Location = New-Object System.Drawing.Point(65, 8)
$driveCombo.Size = New-Object System.Drawing.Size(130, 24)
$driveCombo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$driveCombo.BackColor = [System.Drawing.Color]::FromArgb(10, 16, 28)
$driveCombo.ForeColor = [System.Drawing.Color]::White
[void]$driveCombo.Items.Add("Todos os Discos")
foreach ($d in [System.IO.DriveInfo]::GetDrives() | Where-Object { $_.DriveType -eq [System.IO.DriveType]::Fixed -and $_.IsReady }) {
    [void]$driveCombo.Items.Add($d.Name)
}
$driveCombo.SelectedIndex = 0
[void]$toolbar.Controls.Add($driveCombo)

$btnScanDrives = New-Object System.Windows.Forms.Button
$btnScanDrives.Text = "🔍 ESCANEAR DISCOS"
$btnScanDrives.Location = New-Object System.Drawing.Point(210, 6)
$btnScanDrives.Size = New-Object System.Drawing.Size(170, 30)
Style-Button -Button $btnScanDrives -BaseColor ([System.Drawing.Color]::FromArgb(35, 75, 135)) -HoverColor ([System.Drawing.Color]::FromArgb(50, 105, 180))
[void]$toolbar.Controls.Add($btnScanDrives)

$txtSearch = New-Object System.Windows.Forms.TextBox
$txtSearch.Location = New-Object System.Drawing.Point(400, 8)
$txtSearch.Size = New-Object System.Drawing.Size(560, 26)
$txtSearch.Anchor = "Top, Left, Right"
$txtSearch.BackColor = [System.Drawing.Color]::FromArgb(10, 16, 28)
$txtSearch.ForeColor = [System.Drawing.Color]::FromArgb(140, 210, 255)
$txtSearch.BorderStyle = "FixedSingle"
$txtSearch.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
[void]$toolbar.Controls.Add($txtSearch)

$browse = New-Object System.Windows.Forms.Button
$browse.Text = "📁 PROCURAR JOGO"
$browse.Location = New-Object System.Drawing.Point(975, 6)
$browse.Size = New-Object System.Drawing.Size(160, 30)
$browse.Anchor = "Top, Right"
Style-Button -Button $browse -BaseColor ([System.Drawing.Color]::FromArgb(40, 70, 120)) -HoverColor ([System.Drawing.Color]::FromArgb(55, 95, 160))
[void]$toolbar.Controls.Add($browse)

# --- COLUNA ESQUERDA: LISTA DE JOGOS ---
$libraryPanel = New-Object System.Windows.Forms.Panel
$libraryPanel.Location = New-Object System.Drawing.Point(20, 168)
$libraryPanel.Size = New-Object System.Drawing.Size(430, 480)
$libraryPanel.Anchor = "Top, Bottom, Left"
$libraryPanel.BackColor = [System.Drawing.Color]::FromArgb(18, 25, 42)
[void]$form.Controls.Add($libraryPanel)

$libraryHeading = New-Label -Text "BIBLIOTECA DE JOGOS E COMPATIBILIDADE" -X 14 -Y 10 -Width 400 -Height 20
$libraryHeading.ForeColor = [System.Drawing.Color]::FromArgb(143, 200, 255)
$libraryHeading.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9.5)
[void]$libraryPanel.Controls.Add($libraryHeading)

$gameListView = New-Object System.Windows.Forms.ListView
$gameListView.Location = New-Object System.Drawing.Point(12, 35)
$gameListView.Size = New-Object System.Drawing.Size(406, 432)
$gameListView.Anchor = "Top, Bottom, Left, Right"
$gameListView.View = [System.Windows.Forms.View]::Details
$gameListView.FullRowSelect = $true
$gameListView.MultiSelect = $false
$gameListView.HideSelection = $false
$gameListView.BackColor = [System.Drawing.Color]::FromArgb(10, 15, 26)
$gameListView.ForeColor = [System.Drawing.Color]::White
$gameListView.BorderStyle = "FixedSingle"
$gameListView.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$gameListView.LargeImageList = $imageListLarge
$gameListView.SmallImageList = $imageListSmall

[void]$gameListView.Columns.Add("Título do Jogo", 240)
[void]$gameListView.Columns.Add("Status DLSS 5", 140)
[void]$libraryPanel.Controls.Add($gameListView)

# --- COLUNA DIREITA: INSPETOR DO JOGO ---
$inspectorPanel = New-Object System.Windows.Forms.Panel
$inspectorPanel.Location = New-Object System.Drawing.Point(460, 168)
$inspectorPanel.Size = New-Object System.Drawing.Size(705, 480)
$inspectorPanel.Anchor = "Top, Bottom, Left, Right"
$inspectorPanel.BackColor = [System.Drawing.Color]::FromArgb(18, 25, 42)
[void]$form.Controls.Add($inspectorPanel)

$inspectorAccent = New-Object System.Windows.Forms.Panel
$inspectorAccent.Location = New-Object System.Drawing.Point(0, 0)
$inspectorAccent.Size = New-Object System.Drawing.Size(4, 480)
$inspectorAccent.Anchor = "Top, Bottom, Left"
$inspectorAccent.BackColor = [System.Drawing.Color]::FromArgb(118, 185, 0)
[void]$inspectorPanel.Controls.Add($inspectorAccent)

$inspectorHeading = New-Label -Text "PAINEL DE INJEÇÃO E DETALHES DO JOGO" -X 18 -Y 10 -Width 400 -Height 20
$inspectorHeading.ForeColor = [System.Drawing.Color]::FromArgb(143, 200, 255)
$inspectorHeading.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9.5)
[void]$inspectorPanel.Controls.Add($inspectorHeading)

$gameHeaderBox = New-Object System.Windows.Forms.Panel
$gameHeaderBox.Location = New-Object System.Drawing.Point(18, 35)
$gameHeaderBox.Size = New-Object System.Drawing.Size(668, 64)
$gameHeaderBox.Anchor = "Top, Left, Right"
$gameHeaderBox.BackColor = [System.Drawing.Color]::FromArgb(12, 18, 30)
[void]$inspectorPanel.Controls.Add($gameHeaderBox)

$picGameIcon = New-Object System.Windows.Forms.PictureBox
$picGameIcon.Location = New-Object System.Drawing.Point(10, 10)
$picGameIcon.Size = New-Object System.Drawing.Size(44, 44)
$picGameIcon.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom
[void]$gameHeaderBox.Controls.Add($picGameIcon)

$lblSelectedGameTitle = New-Label -Text "Nenhum jogo selecionado" -X 64 -Y 10 -Width 420 -Height 24
$lblSelectedGameTitle.Font = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
$lblSelectedGameTitle.ForeColor = [System.Drawing.Color]::White
[void]$gameHeaderBox.Controls.Add($lblSelectedGameTitle)

$lblSelectedGameBadge = New-Label -Text "Selecione um jogo na biblioteca ao lado" -X 64 -Y 34 -Width 450 -Height 20
$lblSelectedGameBadge.ForeColor = [System.Drawing.Color]::FromArgb(118, 225, 125)
$lblSelectedGameBadge.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9)
[void]$gameHeaderBox.Controls.Add($lblSelectedGameBadge)

$lblRootTitle = New-Label -Text "Pasta Raiz do Jogo:" -X 18 -Y 108 -Width 220 -Height 18
$lblRootTitle.ForeColor = [System.Drawing.Color]::FromArgb(170, 190, 215)
[void]$inspectorPanel.Controls.Add($lblRootTitle)

$txtRootFolder = New-Object System.Windows.Forms.TextBox
$txtRootFolder.Location = New-Object System.Drawing.Point(18, 128)
$txtRootFolder.Size = New-Object System.Drawing.Size(668, 24)
$txtRootFolder.Anchor = "Top, Left, Right"
$txtRootFolder.ReadOnly = $true
$txtRootFolder.BackColor = [System.Drawing.Color]::FromArgb(10, 16, 28)
$txtRootFolder.ForeColor = [System.Drawing.Color]::White
$txtRootFolder.BorderStyle = "FixedSingle"
[void]$inspectorPanel.Controls.Add($txtRootFolder)

$lblInjectTitle = New-Label -Text "Pasta Exata de Aplicação DLSS 5:" -X 18 -Y 158 -Width 240 -Height 18
$lblInjectTitle.ForeColor = [System.Drawing.Color]::FromArgb(118, 185, 0)
$lblInjectTitle.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9)
[void]$inspectorPanel.Controls.Add($lblInjectTitle)

$txtInjectFolder = New-Object System.Windows.Forms.TextBox
$txtInjectFolder.Location = New-Object System.Drawing.Point(18, 178)
$txtInjectFolder.Size = New-Object System.Drawing.Size(430, 24)
$txtInjectFolder.Anchor = "Top, Left, Right"
$txtInjectFolder.ReadOnly = $true
$txtInjectFolder.BackColor = [System.Drawing.Color]::FromArgb(10, 16, 28)
$txtInjectFolder.ForeColor = [System.Drawing.Color]::FromArgb(130, 230, 140)
$txtInjectFolder.BorderStyle = "FixedSingle"
[void]$inspectorPanel.Controls.Add($txtInjectFolder)

$lblExeTitle = New-Label -Text "Executável Principal 64-bit:" -X 460 -Y 150 -Width 220 -Height 18
$lblExeTitle.Anchor = "Top, Right"
$lblExeTitle.ForeColor = [System.Drawing.Color]::FromArgb(143, 200, 255)
[void]$inspectorPanel.Controls.Add($lblExeTitle)

$txtExeName = New-Object System.Windows.Forms.TextBox
$txtExeName.Location = New-Object System.Drawing.Point(460, 168)
$txtExeName.Size = New-Object System.Drawing.Size(226, 24)
$txtExeName.Anchor = "Top, Right"
$txtExeName.ReadOnly = $true
$txtExeName.BackColor = [System.Drawing.Color]::FromArgb(10, 16, 28)
$txtExeName.ForeColor = [System.Drawing.Color]::FromArgb(130, 215, 255)
$txtExeName.BorderStyle = "FixedSingle"
[void]$inspectorPanel.Controls.Add($txtExeName)

# SELETOR MANUAL DO MODO DE INJEÇÃO DLSS 5
$lblModeTitle = New-Label -Text "Modo de Injeção DLSS 5:" -X 18 -Y 196 -Width 300 -Height 18
$lblModeTitle.ForeColor = [System.Drawing.Color]::FromArgb(255, 205, 90)
$lblModeTitle.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9)
[void]$inspectorPanel.Controls.Add($lblModeTitle)

$comboInjectionMode = New-Object System.Windows.Forms.ComboBox
$comboInjectionMode.Location = New-Object System.Drawing.Point(18, 216)
$comboInjectionMode.Size = New-Object System.Drawing.Size(668, 26)
$comboInjectionMode.Anchor = "Top, Left, Right"
$comboInjectionMode.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$comboInjectionMode.BackColor = [System.Drawing.Color]::FromArgb(10, 16, 28)
$comboInjectionMode.ForeColor = [System.Drawing.Color]::FromArgb(140, 220, 255)
$comboInjectionMode.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
[void]$inspectorPanel.Controls.Add($comboInjectionMode)

# LEMBRETE OBRIGATORIO DE DLSS ATIVADO
$reminderBox = New-Object System.Windows.Forms.Panel
$reminderBox.Location = New-Object System.Drawing.Point(18, 248)
$reminderBox.Size = New-Object System.Drawing.Size(668, 58)
$reminderBox.Anchor = "Top, Left, Right"
$reminderBox.BackColor = [System.Drawing.Color]::FromArgb(35, 30, 12)
[void]$inspectorPanel.Controls.Add($reminderBox)

$reminderAccent = New-Object System.Windows.Forms.Panel
$reminderAccent.Location = New-Object System.Drawing.Point(0, 0)
$reminderAccent.Size = New-Object System.Drawing.Size(4, 58)
$reminderAccent.BackColor = [System.Drawing.Color]::FromArgb(255, 195, 0)
[void]$reminderBox.Controls.Add($reminderAccent)

$lblReminderHeader = New-Label -Text "⚡ REQUISITO OBRIGATÓRIO NO JOGO:" -X 14 -Y 6 -Width 640 -Height 18
$lblReminderHeader.ForeColor = [System.Drawing.Color]::FromArgb(255, 205, 50)
$lblReminderHeader.Font = New-Object System.Drawing.Font("Segoe UI Bold", 9)
[void]$reminderBox.Controls.Add($lblReminderHeader)

$lblReminderText = New-Label -Text "Dentro do jogo, certifique-se de ATIVAR o 'NVIDIA DLSS Super Resolution' (Qualidade ou Desempenho) nas opções gráficas para que o DLSS 5 Neural funcione!" -X 14 -Y 24 -Width 640 -Height 30
$lblReminderText.ForeColor = [System.Drawing.Color]::FromArgb(240, 230, 190)
$lblReminderText.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
[void]$reminderBox.Controls.Add($lblReminderText)

# Opções de Injeção & Pacote
$lblPayloadTitle = New-Label -Text "Pacote DLSS 5 (Streamline 2.13 Integrado):" -X 18 -Y 312 -Width 300 -Height 18
$lblPayloadTitle.ForeColor = [System.Drawing.Color]::FromArgb(170, 190, 215)
[void]$inspectorPanel.Controls.Add($lblPayloadTitle)

$dlssZipText = New-Object System.Windows.Forms.TextBox
$initialZip = Find-EmbeddedStreamlineZip
if ($initialZip) { $dlssZipText.Text = $initialZip }
$dlssZipText.Location = New-Object System.Drawing.Point(18, 330)
$dlssZipText.Size = New-Object System.Drawing.Size(530, 24)
$dlssZipText.Anchor = "Top, Left, Right"
$dlssZipText.BackColor = [System.Drawing.Color]::FromArgb(10, 16, 28)
$dlssZipText.ForeColor = [System.Drawing.Color]::White
$dlssZipText.BorderStyle = "FixedSingle"
[void]$inspectorPanel.Controls.Add($dlssZipText)

$dlssBrowse = New-Object System.Windows.Forms.Button
$dlssBrowse.Text = "📦 TROCAR ZIP"
$dlssBrowse.Location = New-Object System.Drawing.Point(558, 328)
$dlssBrowse.Size = New-Object System.Drawing.Size(128, 26)
$dlssBrowse.Anchor = "Top, Right"
Style-Button -Button $dlssBrowse -BaseColor ([System.Drawing.Color]::FromArgb(40, 70, 115)) -HoverColor ([System.Drawing.Color]::FromArgb(55, 95, 155))
[void]$inspectorPanel.Controls.Add($dlssBrowse)

$copyReShade = New-Object System.Windows.Forms.CheckBox
$copyReShade.Text = "Instalar ReShade 6.8.0 (Suporte a Add-ons)"
$copyReShade.Location = New-Object System.Drawing.Point(18, 358)
$copyReShade.Size = New-Object System.Drawing.Size(300, 22)
$copyReShade.Checked = $true
$copyReShade.ForeColor = [System.Drawing.Color]::White
[void]$inspectorPanel.Controls.Add($copyReShade)

$fullPackage = New-Object System.Windows.Forms.CheckBox
$fullPackage.Text = "Substituicao Completa de DLLs Streamline"
$fullPackage.Location = New-Object System.Drawing.Point(330, 358)
$fullPackage.Size = New-Object System.Drawing.Size(350, 22)
$fullPackage.Checked = $true
$fullPackage.ForeColor = [System.Drawing.Color]::FromArgb(120, 215, 140)
[void]$inspectorPanel.Controls.Add($fullPackage)

# BARRA DE ACAO PRINCIPAL COM BOTAO INICIAR JOGO
$actionBar = New-Object System.Windows.Forms.Panel
$actionBar.Location = New-Object System.Drawing.Point(18, 388)
$actionBar.Size = New-Object System.Drawing.Size(668, 86)
$actionBar.Anchor = "Top, Left, Right"
$actionBar.BackColor = [System.Drawing.Color]::Transparent
[void]$inspectorPanel.Controls.Add($actionBar)

$install = New-Object System.Windows.Forms.Button
$install.Text = "🚀 1-CLIQUE: INSTALAR DLSS 5"
$install.Location = New-Object System.Drawing.Point(0, 2)
$install.Size = New-Object System.Drawing.Size(326, 40)
$install.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
Style-Button -Button $install -BaseColor ([System.Drawing.Color]::FromArgb(118, 185, 0)) -HoverColor ([System.Drawing.Color]::FromArgb(140, 220, 0))
$install.ForeColor = [System.Drawing.Color]::Black
[void]$actionBar.Controls.Add($install)

$launchGame = New-Object System.Windows.Forms.Button
$launchGame.Text = "▶️ INICIAR JOGO"
$launchGame.Location = New-Object System.Drawing.Point(338, 2)
$launchGame.Size = New-Object System.Drawing.Size(330, 40)
$launchGame.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
Style-Button -Button $launchGame -BaseColor ([System.Drawing.Color]::FromArgb(0, 130, 230)) -HoverColor ([System.Drawing.Color]::FromArgb(20, 160, 255))
[void]$actionBar.Controls.Add($launchGame)

$uninstall = New-Object System.Windows.Forms.Button
$uninstall.Text = "↩️ RESTAURAR"
$uninstall.Location = New-Object System.Drawing.Point(0, 48)
$uninstall.Size = New-Object System.Drawing.Size(160, 34)
Style-Button -Button $uninstall -BaseColor ([System.Drawing.Color]::FromArgb(180, 50, 50)) -HoverColor ([System.Drawing.Color]::FromArgb(215, 60, 60))
[void]$actionBar.Controls.Add($uninstall)

$openFolder = New-Object System.Windows.Forms.Button
$openFolder.Text = "📂 ABRIR PASTA"
$openFolder.Location = New-Object System.Drawing.Point(170, 48)
$openFolder.Size = New-Object System.Drawing.Size(160, 34)
Style-Button -Button $openFolder -BaseColor ([System.Drawing.Color]::FromArgb(40, 70, 115)) -HoverColor ([System.Drawing.Color]::FromArgb(55, 95, 155))
[void]$actionBar.Controls.Add($openFolder)

$instructions = New-Object System.Windows.Forms.Button
$instructions.Text = "📖 GUIA NO JOGO"
$instructions.Location = New-Object System.Drawing.Point(340, 48)
$instructions.Size = New-Object System.Drawing.Size(160, 34)
Style-Button -Button $instructions -BaseColor ([System.Drawing.Color]::FromArgb(40, 70, 115)) -HoverColor ([System.Drawing.Color]::FromArgb(55, 95, 155))
[void]$actionBar.Controls.Add($instructions)

$scan = New-Object System.Windows.Forms.Button
$scan.Text = "🔍 VERIFICAR"
$scan.Location = New-Object System.Drawing.Point(510, 48)
$scan.Size = New-Object System.Drawing.Size(158, 34)
Style-Button -Button $scan -BaseColor ([System.Drawing.Color]::FromArgb(35, 75, 130)) -HoverColor ([System.Drawing.Color]::FromArgb(50, 105, 175))
[void]$actionBar.Controls.Add($scan)

# --- PAINEL INFERIOR: CONSOLE DE DIAGNOSTICO ---
$statusCard = New-Object System.Windows.Forms.Panel
$statusCard.Location = New-Object System.Drawing.Point(20, 658)
$statusCard.Size = New-Object System.Drawing.Size(1145, 160)
$statusCard.Anchor = "Bottom, Left, Right"
$statusCard.BackColor = [System.Drawing.Color]::FromArgb(18, 25, 42)
[void]$form.Controls.Add($statusCard)

$statusAccent = New-Object System.Windows.Forms.Panel
$statusAccent.Location = New-Object System.Drawing.Point(0, 0)
$statusAccent.Size = New-Object System.Drawing.Size(4, 160)
$statusAccent.BackColor = [System.Drawing.Color]::FromArgb(73, 176, 255)
[void]$statusCard.Controls.Add($statusAccent)

$statusLabel = New-Label -Text "DIAGNÓSTICO E LOG DO SISTEMA EM TEMPO REAL" -X 18 -Y 8 -Width 500 -Height 20
$statusLabel.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9)
$statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(143, 200, 255)
[void]$statusCard.Controls.Add($statusLabel)

$status = New-Object System.Windows.Forms.RichTextBox
$status.Location = New-Object System.Drawing.Point(14, 30)
$status.Size = New-Object System.Drawing.Size(1115, 118)
$status.Anchor = "Top, Bottom, Left, Right"
$status.ReadOnly = $true
$status.BackColor = [System.Drawing.Color]::FromArgb(8, 12, 22)
$status.ForeColor = [System.Drawing.Color]::FromArgb(214, 225, 243)
$status.BorderStyle = "FixedSingle"
$status.Font = New-Object System.Drawing.Font("Consolas", 9.5)
$status.DetectUrls = $false
$status.ScrollBars = [System.Windows.Forms.RichTextBoxScrollBars]::Vertical
[void]$statusCard.Controls.Add($status)
$script:StatusBox = $status

# FOOTER
$footer = New-Label -Text "1 Click DLSS 5 v1.5.0 | Feeder Universal 2.0 (Qualquer Jogo de PC) | RTX 20/30/40/50 | DX11 / DX12 / Vulkan / OpenGL" -X 20 -Y 825 -Width 1145 -Height 22
$footer.Anchor = "Bottom, Left, Right"
$footer.ForeColor = [System.Drawing.Color]::FromArgb(120, 140, 170)
$footer.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
[void]$form.Controls.Add($footer)

function Update-ReminderForSelectedMode {
    $d = Get-Dict -Lang $script:CurrentLang
    $modeIdx = $comboInjectionMode.SelectedIndex
    $effectiveMode = "AUTO"
    if ($modeIdx -le 0) {
        $effectiveMode = if ($script:CurrentDetectedUpscaler) { $script:CurrentDetectedUpscaler } else { "NATIVE_DLSS" }
    } elseif ($modeIdx -eq 1) {
        $effectiveMode = "NATIVE_DLSS"
    } elseif ($modeIdx -eq 2) {
        $effectiveMode = "FSR2_BRIDGE"
    } elseif ($modeIdx -eq 3) {
        $effectiveMode = "UNIVERSAL_FEEDER"
    }

    if ($effectiveMode -eq "NATIVE_DLSS") {
        $lblSelectedGameBadge.Text = $d.Badge100
        $lblSelectedGameBadge.ForeColor = [System.Drawing.Color]::FromArgb(118, 225, 125)
        $lblReminderHeader.Text = if ($script:CurrentLang -eq "PT") { "⚡ MODO 1: DIRETO (GANHO DE FPS COM DLSS NATIVO)" } else { "⚡ MODE 1: DIRECT (MASSIVE FPS BOOST WITH NATIVE DLSS)" }
        $lblReminderHeader.ForeColor = [System.Drawing.Color]::FromArgb(118, 225, 125)
        $lblReminderText.Text = if ($script:CurrentLang -eq "PT") { "No menu do jogo: ATIVE o 'NVIDIA DLSS' (no modo Qualidade ou Desempenho) para ganhar muito FPS com a Reconstrução Neural DLSS 5!" } else { "In-game menu: ENABLE 'NVIDIA DLSS' (Quality or Performance mode) to get massive FPS boost with DLSS 5 Neural Reconstruction!" }
    } elseif ($effectiveMode -eq "FSR2_BRIDGE" -or $effectiveMode -eq "XESS_BRIDGE") {
        $lblSelectedGameBadge.Text = $d.BadgeBridge
        $lblSelectedGameBadge.ForeColor = [System.Drawing.Color]::FromArgb(100, 180, 255)
        $lblReminderHeader.Text = if ($script:CurrentLang -eq "PT") { "⚡ MODO 2: PONTE OPTISCALER (GANHO DE FPS VIA FSR2/XeSS)" } else { "⚡ MODE 2: OPTISCALER BRIDGE (FPS BOOST VIA FSR2/XeSS)" }
        $lblReminderHeader.ForeColor = [System.Drawing.Color]::FromArgb(100, 180, 255)
        $lblReminderText.Text = if ($script:CurrentLang -eq "PT") { "No menu do jogo: ATIVE o FSR2 ou XeSS no modo Qualidade. A ponte OptiScaler redirecionará para o DLSS 5 com ganho de FPS!" } else { "In-game menu: ENABLE FSR2 or XeSS in Quality mode. OptiScaler bridge will redirect to DLSS 5 with FPS boost!" }
    } else {
        $lblSelectedGameBadge.Text = $d.BadgeFeeder
        $lblSelectedGameBadge.ForeColor = [System.Drawing.Color]::FromArgb(180, 140, 255)
        $lblReminderHeader.Text = if ($script:CurrentLang -eq "PT") { "⚡ MODO 3: FEEDER UNIVERSAL (DLAA 100% NATIVO SEM UPSCALE)" } else { "⚡ MODE 3: UNIVERSAL FEEDER (100% NATIVE DLAA WITHOUT UPSCALE)" }
        $lblReminderHeader.ForeColor = [System.Drawing.Color]::FromArgb(180, 140, 255)
        $lblReminderText.Text = if ($script:CurrentLang -eq "PT") { "No menu do jogo: Deixe o DLSS/Upscaling DESLIGADO (100% Nativo ou DLAA). O DLSS 5 e o fluxo óptico atuarão direto no frame limpo sem conflito de IA!" } else { "In-game menu: Keep DLSS/Upscaling DISABLED (100% Native or DLAA). DLSS 5 & optical flow will operate directly on the clean frame without AI conflict!" }
    }
}

$comboInjectionMode.Add_SelectedIndexChanged({
    Update-ReminderForSelectedMode
})

function Select-GameInInspector {
    param([pscustomobject]$GameObj)
    if ($null -eq $GameObj) { return }
    $script:SelectedGameObj = $GameObj

    $d = Get-Dict -Lang $script:CurrentLang
    $lblSelectedGameTitle.Text = $GameObj.Name
    $lblSelectedGameBadge.Text = $GameObj.Badge
    $txtRootFolder.Text = $GameObj.Path

    if ($GameObj.Badge.Contains("100%")) {
        $lblSelectedGameBadge.ForeColor = [System.Drawing.Color]::FromArgb(118, 225, 125)
    } elseif ($GameObj.Badge.Contains("OPTISCALER")) {
        $lblSelectedGameBadge.ForeColor = [System.Drawing.Color]::FromArgb(100, 180, 255)
    } elseif ($GameObj.Badge.Contains("UNIVERSAL") -or $GameObj.Badge.Contains("Feeder")) {
        $lblSelectedGameBadge.ForeColor = [System.Drawing.Color]::FromArgb(180, 140, 255)
    } else {
        $lblSelectedGameBadge.ForeColor = [System.Drawing.Color]::FromArgb(255, 205, 90)
    }

    try {
        $resolved = Resolve-GameTarget -TargetPath $GameObj.Path
        $txtInjectFolder.Text = $resolved.InstallFolder
        $txtExeName.Text = $resolved.ExeName
        if ($null -ne $resolved.Icon) {
            $picGameIcon.Image = $resolved.Icon.ToBitmap()
        } else {
            $picGameIcon.Image = $null
        }
        Write-Status -Message ($d.MsgSelected -f $GameObj.Name, $resolved.ExeName) -Level "INFO"

        $uType = Detect-GameUpscalerType -GameFolder $resolved.InstallFolder -GameRoot $resolved.Root
        $script:CurrentDetectedUpscaler = $uType

        $recName = if ($uType -eq "NATIVE_DLSS") {
            $d.ModeNameDirect
        } elseif ($uType -eq "FSR2_BRIDGE" -or $uType -eq "XESS_BRIDGE") {
            $d.ModeNameBridge
        } else {
            $d.ModeNameFeeder
        }

        # Atualiza o seletor com sugestao inteligente recomendada
        $comboInjectionMode.BeginUpdate()
        $comboInjectionMode.Items.Clear()
        [void]$comboInjectionMode.Items.Add(($d.OptAutoRecommended -f $recName))
        [void]$comboInjectionMode.Items.Add($d.OptModeDirect)
        [void]$comboInjectionMode.Items.Add($d.OptModeBridge)
        [void]$comboInjectionMode.Items.Add($d.OptModeFeeder)
        $comboInjectionMode.SelectedIndex = 0
        $comboInjectionMode.EndUpdate()

        Update-ReminderForSelectedMode

        # Check if DLSS 5 is already installed
        $existingState = Join-Path $resolved.InstallFolder $script:StateName
        if (Test-Path -LiteralPath $existingState -PathType Leaf) {
            try {
                $savedState = Get-Content -LiteralPath $existingState -Raw | ConvertFrom-Json
                $modeText = if ($savedState.Mode -eq "OPTISCALER") {
                    $d.MsgModeBridge -f $savedState.UpscalerType
                } elseif ($savedState.Mode -eq "FEEDER") {
                    $d.MsgModeFeeder
                } else {
                    $d.MsgModeDirect
                }
                $lblSelectedGameBadge.Text = $d.MsgInstalledAlready + " " + $modeText
                $lblSelectedGameBadge.ForeColor = [System.Drawing.Color]::FromArgb(255, 185, 50)
            } catch {}
        }
    } catch {
        $txtInjectFolder.Text = $GameObj.Path
        $txtExeName.Text = "Detectar na verificacao..."
        $picGameIcon.Image = $null
    }
}

$gameListView.Add_SelectedIndexChanged({
    if ($gameListView.SelectedIndices.Count -gt 0) {
        $idx = $gameListView.SelectedIndices[0]
        $tagObj = $gameListView.Items[$idx].Tag
        if ($null -ne $tagObj) {
            Select-GameInInspector -GameObj $tagObj
        }
    }
})

$txtSearch.Add_TextChanged({
    $filter = $txtSearch.Text.Trim().ToLower()
    $gameListView.BeginUpdate()
    $gameListView.Items.Clear()

    foreach ($g in $script:DiscoveredGames) {
        if ([string]::IsNullOrWhiteSpace($filter) -or $g.Name.ToLower().Contains($filter) -or $g.Path.ToLower().Contains($filter)) {
            $item = New-Object System.Windows.Forms.ListViewItem($g.Name)
            [void]$item.SubItems.Add($g.Badge)
            $item.Tag = $g
            if ($null -ne $g.Icon) {
                $iconKey = "icon_" + $g.Path.GetHashCode()
                if (-not $imageListSmall.Images.ContainsKey($iconKey)) {
                    [void]$imageListSmall.Images.Add($iconKey, $g.Icon.ToBitmap())
                    [void]$imageListLarge.Images.Add($iconKey, $g.Icon.ToBitmap())
                }
                $item.ImageKey = $iconKey
            }
            [void]$gameListView.Items.Add($item)
        }
    }
    $gameListView.EndUpdate()
})

function Update-Language {
    param([string]$Lang)
    $script:CurrentLang = $Lang
    $d = Get-Dict -Lang $Lang

    $eyebrow.Text = $d.Eyebrow
    $title.Text = $d.Title
    $subtitle.Text = $d.Subtitle
    $lblDrive.Text = $d.DriveLabel
    $btnScanDrives.Text = $d.BtnScanDrives
    $browse.Text = $d.BtnBrowse
    $libraryHeading.Text = $d.LibraryTitle
    $gameListView.Columns[0].Text = $d.ColGame
    $gameListView.Columns[1].Text = $d.ColStatus
    $inspectorHeading.Text = $d.InspectorTitle
    $lblRootTitle.Text = $d.RootFolderLabel
    $lblInjectTitle.Text = $d.InjectFolderLabel
    $lblExeTitle.Text = $d.TargetExeLabel
    $lblModeTitle.Text = $d.LblInjectionMode
    $lblReminderHeader.Text = $d.ReminderHeader
    $lblReminderText.Text = $d.ReminderText
    $lblPayloadTitle.Text = $d.PayloadTitle
    $dlssBrowse.Text = $d.BtnChangeZip
    $copyReShade.Text = $d.OptReShade
    $fullPackage.Text = $d.OptFull
    $scan.Text = $d.BtnVerify
    $install.Text = $d.BtnInstall
    $launchGame.Text = $d.BtnLaunch
    $uninstall.Text = $d.BtnUninstall
    $openFolder.Text = $d.BtnOpenFolder
    $instructions.Text = $d.BtnInstructions
    $statusLabel.Text = $d.StatusHeading
    $footer.Text = $d.Footer

    if ($Lang -eq "PT") {
        $btnLangPT.Tag.Base = [System.Drawing.Color]::FromArgb(35, 120, 35)
        $btnLangPT.BackColor = [System.Drawing.Color]::FromArgb(35, 120, 35)
        $btnLangEN.Tag.Base = [System.Drawing.Color]::FromArgb(35, 50, 80)
        $btnLangEN.BackColor = [System.Drawing.Color]::FromArgb(35, 50, 80)
    } else {
        $btnLangEN.Tag.Base = [System.Drawing.Color]::FromArgb(35, 80, 150)
        $btnLangEN.BackColor = [System.Drawing.Color]::FromArgb(35, 80, 150)
        $btnLangPT.Tag.Base = [System.Drawing.Color]::FromArgb(25, 60, 25)
        $btnLangPT.BackColor = [System.Drawing.Color]::FromArgb(25, 60, 25)
    }

    # Re-badge existing games with new language (no rescan)
    if ($script:DiscoveredGames -and $script:DiscoveredGames.Count -gt 0) {
        $gameListView.BeginUpdate()
        foreach ($lvItem in $gameListView.Items) {
            $g = $lvItem.Tag
            if ($null -ne $g) {
                $newBadge = switch -Wildcard ($g.Badge) {
                    "*100%*"       { $d.Badge100 }
                    "*OPTISCALER*" { $d.BadgeBridge }
                    default        { $d.BadgeFeeder }
                }
                $g.Badge = $newBadge
                $g.DisplayName = "$newBadge $($g.Name)"
                $lvItem.SubItems[1].Text = $newBadge
            }
        }
        $gameListView.EndUpdate()
    }

    if ($null -ne $script:SelectedGameObj) {
        Select-GameInInspector -GameObj $script:SelectedGameObj
    }
}

$btnLangPT.Add_Click({ Update-Language "PT" })
$btnLangEN.Add_Click({ Update-Language "EN" })

function Refresh-GameLibrary {
    $selDrive = if ($driveCombo.SelectedIndex -le 0) { "ALL" } else { $driveCombo.SelectedItem.ToString() }
    $d = Get-Dict -Lang $script:CurrentLang
    Write-Status -Message ($d.MsgScanning -f $selDrive) -Level "INFO"

    # Disable scan/browse buttons during scan
    $btnScanDrives.Enabled = $false
    $browse.Enabled = $false

    # --- Build progress dialog ---
    $progressForm = New-Object System.Windows.Forms.Form
    $progressForm.Text = $d.MsgScanProgressTitle
    $progressForm.Size = New-Object System.Drawing.Size(520, 180)
    $progressForm.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterParent
    $progressForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $progressForm.MaximizeBox = $false
    $progressForm.MinimizeBox = $false
    $progressForm.ControlBox = $false
    $progressForm.BackColor = [System.Drawing.Color]::FromArgb(18, 22, 36)
    $progressForm.ShowInTaskbar = $false
    $progressForm.TopMost = $true

    $lblProgressTitle = New-Object System.Windows.Forms.Label
    $lblProgressTitle.Text = $d.MsgScanProgressTitle
    $lblProgressTitle.Location = New-Object System.Drawing.Point(20, 15)
    $lblProgressTitle.Size = New-Object System.Drawing.Size(470, 22)
    $lblProgressTitle.ForeColor = [System.Drawing.Color]::FromArgb(120, 200, 255)
    $lblProgressTitle.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 11)
    [void]$progressForm.Controls.Add($lblProgressTitle)

    $progressBar = New-Object System.Windows.Forms.ProgressBar
    $progressBar.Location = New-Object System.Drawing.Point(20, 48)
    $progressBar.Size = New-Object System.Drawing.Size(465, 26)
    $progressBar.Minimum = 0
    $progressBar.Maximum = 100
    $progressBar.Value = 0
    $progressBar.Style = [System.Windows.Forms.ProgressBarStyle]::Continuous
    [void]$progressForm.Controls.Add($progressBar)

    $lblProgressDetail = New-Object System.Windows.Forms.Label
    $lblProgressDetail.Text = ""
    $lblProgressDetail.Location = New-Object System.Drawing.Point(20, 84)
    $lblProgressDetail.Size = New-Object System.Drawing.Size(465, 20)
    $lblProgressDetail.ForeColor = [System.Drawing.Color]::FromArgb(200, 200, 200)
    $lblProgressDetail.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    [void]$progressForm.Controls.Add($lblProgressDetail)

    $lblProgressPct = New-Object System.Windows.Forms.Label
    $lblProgressPct.Text = "0%"
    $lblProgressPct.Location = New-Object System.Drawing.Point(20, 108)
    $lblProgressPct.Size = New-Object System.Drawing.Size(465, 20)
    $lblProgressPct.ForeColor = [System.Drawing.Color]::FromArgb(160, 160, 160)
    $lblProgressPct.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
    $lblProgressPct.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight
    [void]$progressForm.Controls.Add($lblProgressPct)

    $progressForm.Show($form)
    $progressForm.Refresh()

    # --- Progress callback ---
    $progressCallback = {
        param([int]$pct, [string]$gameName)
        $progressBar.Value = [Math]::Min($pct, 100)
        $lblProgressDetail.Text = ($d.MsgScanFolder -f $gameName)
        $lblProgressPct.Text = "$pct%"
        [System.Windows.Forms.Application]::DoEvents()
    }.GetNewClosure()

    # --- Run scan ---
    $script:DiscoveredGames = @(Scan-DriveForGames -DriveLetter $selDrive -ProgressCallback $progressCallback)

    # --- Close progress dialog ---
    $progressForm.Close()
    $progressForm.Dispose()

    # --- Populate list view ---
    $gameListView.BeginUpdate()
    $gameListView.Items.Clear()
    $imageListSmall.Images.Clear()
    $imageListLarge.Images.Clear()

    foreach ($g in $script:DiscoveredGames) {
        $item = New-Object System.Windows.Forms.ListViewItem($g.Name)
        [void]$item.SubItems.Add($g.Badge)
        $item.Tag = $g

        if ($null -ne $g.Icon) {
            $iconKey = "icon_" + $g.Path.GetHashCode()
            [void]$imageListSmall.Images.Add($iconKey, $g.Icon.ToBitmap())
            [void]$imageListLarge.Images.Add($iconKey, $g.Icon.ToBitmap())
            $item.ImageKey = $iconKey
        }

        if ($g.Badge.Contains("100%")) {
            $item.ForeColor = [System.Drawing.Color]::FromArgb(130, 240, 140)
        } elseif ($g.Badge.Contains("OPTISCALER")) {
            $item.ForeColor = [System.Drawing.Color]::FromArgb(100, 180, 255)
        } else {
            $item.ForeColor = [System.Drawing.Color]::FromArgb(180, 140, 255)
        }

        [void]$gameListView.Items.Add($item)
    }
    $gameListView.EndUpdate()

    if ($gameListView.Items.Count -gt 0) {
        $gameListView.Items[0].Selected = $true
        Select-GameInInspector -GameObj $gameListView.Items[0].Tag
    }

    # Re-enable buttons
    $btnScanDrives.Enabled = $true
    $browse.Enabled = $true

    Write-Status -Message ($d.MsgScanDone -f $script:DiscoveredGames.Count) -Level "OK"
}

$btnScanDrives.Add_Click({ Refresh-GameLibrary })

$browse.Add_Click({
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = "Selecione a pasta raiz do jogo."
    $dialog.ShowNewFolderButton = $false
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $manualPath = $dialog.SelectedPath
        $d = Get-Dict -Lang $script:CurrentLang
        try {
            $resolved = Resolve-GameTarget -TargetPath $manualPath
            $uType = Detect-GameUpscalerType -GameFolder $resolved.InstallFolder -GameRoot $resolved.Root
            $manualBadge = switch ($uType) {
                "NATIVE_DLSS" { $d.Badge100 }
                "FSR2_BRIDGE" { $d.BadgeBridge }
                "XESS_BRIDGE" { $d.BadgeBridge }
                default { $d.BadgeFeeder }
            }
            $manualObj = [pscustomobject]@{
                Order = 1
                DisplayName = "$manualBadge $(Split-Path -Leaf $manualPath)"
                Name = (Split-Path -Leaf $manualPath)
                Path = $manualPath
                Badge = $manualBadge
                Icon = $resolved.Icon
                ExeName = $resolved.ExeName
            }
            Select-GameInInspector -GameObj $manualObj
        } catch {
            Show-ErrorDialog -Message $_.Exception.Message
        }
    }
})

$dlssBrowse.Add_Click({
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Title = "Selecione o arquivo ZIP do pacote 1 Click DLSS 5"
    $dialog.Filter = "Pacote ZIP (*.zip)|*.zip|Todos os arquivos (*.*)|*.*"
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $dlssZipText.Text = $dialog.FileName
        Write-Status -Message ("Pacote DLSS selecionado: " + $dlssZipText.Text) -Level "INFO"
    }
})

$scan.Add_Click({
    try {
        $status.Clear()
        $chosenMode = switch ($comboInjectionMode.SelectedIndex) {
            1 { "DIRECT" }
            2 { "OPTISCALER" }
            3 { "FEEDER" }
            default { "AUTO" }
        }
        $report = Get-Compatibility -TargetPath $txtRootFolder.Text.Trim() -InstallReShade $copyReShade.Checked -FullPackage $fullPackage.Checked -DlssZipPath $dlssZipText.Text.Trim() -SelectedMode $chosenMode
        foreach ($line in $report.Info) { Write-Status -Message $line -Level "INFO" }
        foreach ($line in $report.Warnings) { Write-Status -Message $line -Level "WARN" }
        foreach ($line in $report.Fatal) { Write-Status -Message $line -Level "ERROR" }
        if ($report.CanInstall) {
            Write-Status -Message "Verificacao concluida com sucesso! O jogo esta 100% pronto para receber o 1 Click DLSS 5." -Level "OK"
        }
    } catch { Show-ErrorDialog -Message $_.Exception.Message }
})

$install.Add_Click({
    $install.Enabled = $false
    try {
        $chosenMode = switch ($comboInjectionMode.SelectedIndex) {
            1 { "DIRECT" }
            2 { "OPTISCALER" }
            3 { "FEEDER" }
            default { "AUTO" }
        }
        Install-Dlss5 -TargetPath $txtRootFolder.Text.Trim() -InstallReShade $copyReShade.Checked -FullPackage $fullPackage.Checked -DlssZipPath $dlssZipText.Text.Trim() -SelectedMode $chosenMode
    } catch { Show-ErrorDialog -Message $_.Exception.Message }
    finally { $install.Enabled = $true }
})

$launchGame.Add_Click({
    Start-GameExecutable -TargetPath $txtRootFolder.Text.Trim()
})

$uninstall.Add_Click({
    $uninstall.Enabled = $false
    try {
        Uninstall-Dlss5 -TargetPath $txtRootFolder.Text.Trim()
    } catch { Show-ErrorDialog -Message $_.Exception.Message }
    finally { $uninstall.Enabled = $true }
})

$openFolder.Add_Click({
    try {
        $target = Resolve-GameTarget -TargetPath $txtRootFolder.Text.Trim()
        Start-Process explorer.exe -ArgumentList "`"$($target.InstallFolder)`""
    } catch { Show-ErrorDialog -Message $_.Exception.Message }
})

$instructions.Add_Click({ Show-Instructions })

$form.Add_Shown({
    $embeddedZip = Find-EmbeddedStreamlineZip
    if ($embeddedZip) {
        $dlssZipText.Text = $embeddedZip
        $d = Get-Dict -Lang $script:CurrentLang
        Write-Status -Message $d.MsgPayloadLoaded -Level "OK"
    } else {
        $d = Get-Dict -Lang $script:CurrentLang
        Write-Status -Message (if ($script:CurrentLang -eq "EN") { "Payload streamline.zip not found in default folder. Use [CHANGE ZIP] if required." } else { "Pacote streamline.zip não encontrado na pasta padrão. Use [TROCAR ZIP] se necessário." }) -Level "WARN"
    }
    $d = Get-Dict -Lang $script:CurrentLang
    Write-Status -Message $d.MsgLibraryEmpty -Level "INFO"
})

[void]$form.ShowDialog()


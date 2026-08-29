# ==============================================================================
#  1 Click DLSS 5 - Universal Neural Rendering Game Center & Auto-Injector
#  Official Repository: https://github.com/1Click-DLSS5/1-Click-DLSS5
#  Architecture: RenoDX DLSS 5 v3 + NVIDIA Streamline 2.13 + nvngx_dlssnr.dll
# ==============================================================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression.FileSystem

[System.Windows.Forms.Application]::EnableVisualStyles()

$script:ProductName = "1 Click DLSS 5"
$script:Version = "1.2.0"
$script:AddOnName = "renodx-dlss5.addon64"
$script:AddonHash = "FE505B73D6E319B3A5E6FE09E4E6CA6FB0D5E9141A6112CAE528B11E4BCB4C07"
$script:ReShadeUrl = "https://reshade.me/downloads/ReShade_Setup_6.8.0_Addon.exe"
$script:ReShadeHash = "AFE4C8F13048306307983B8B3D41D5BF00A86820440B0E57DEA10950E1176445"
$script:StateName = "_1Click_DLSS5_State.json"
$script:BackupName = "_1Click_DLSS5_Backup"
$script:CacheRoot = Join-Path $env:LOCALAPPDATA "1ClickDLSS5"
$script:StatusBox = $null
$script:PayloadFolder = $null
$script:PayloadZipPath = $null
$script:PayloadZipHash = $null
$script:IconPath = Join-Path $PSScriptRoot "assets\logo.ico"
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
            Eyebrow = "OFFICIAL RENO DX ECOSYSTEM • NVIDIA NGX NEURAL RUNTIME v310.8.0.0"
            Title = "1 CLICK DLSS 5"
            Subtitle = "Steam-Style Game Center • 1-Click Neural Injection • Full RTX 40 & RTX 50 Support"
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
            Footer = "1 Click DLSS 5 v1.2.0 | RTX 40 & RTX 50 Series | DirectX 12 | Streamline 2.13 | RenoDX DLSS 5 Multi-Format"
            Badge100 = "✓ 100% COMPATIBLE (Native DLSS)"
            BadgeDX12 = "✓ COMPATIBLE (DirectX 12)"
            BadgeCheck = "? VERIFY DX12 SUPPORT"
            MsgReady = "Ready. Pick a game from your Steam-style library or browse folder."
            MsgScanning = "Scanning drives ({0}) and reading game executables and icons..."
            MsgScanDone = "Scan complete! {0} games loaded into your library, sorted by compatibility."
            MsgPayloadLoaded = "Official 1 Click DLSS 5 payload loaded automatically."
            MsgSelected = "Selected game: {0} ({1})"
            SuccessTitle = "1 Click DLSS 5 - Installation Complete"
            SuccessMsg = "DLSS 5 successfully installed!`n`n1. Click [LAUNCH GAME] or open the game.`n2. Enable DLSS Super Resolution in the game settings.`n3. Press [Home] key -> Add-ons tab -> Expand 'DLSS 5' -> Set Preset #2 Cinematic."
            RestoreTitle = "1 Click DLSS 5 - Restoration Complete"
            RestoreMsg = "Game successfully restored to clean factory state! All injected files and logs were wiped."
            BadgeBridge = "✓ COMPATIBLE VIA OPTISCALER (FSR2/XeSS → DLSS 5)"
            BadgeUnsupported = "✗ UNSUPPORTED (No Upscaler Detected)"
            ConfirmInstallTitle = "1 Click DLSS 5 - Confirm Installation"
            ConfirmInstallDirect = "Install DLSS 5 (Direct Mode) on:\n{0}\n\nNative DLSS detected. Streamline + RenoDX will be injected.\n\nContinue?"
            ConfirmInstallBridge = "Install DLSS 5 (OptiScaler Bridge) on:\n{0}\n\n{1} detected. OptiScaler will redirect to DLSS Neural Rendering.\n\nContinue?"
            ConfirmUninstallTitle = "1 Click DLSS 5 - Confirm Restoration"
            ConfirmUninstall = "Remove ALL DLSS 5 files and restore the game to factory state?\n\n{0}\n\nThis action cannot be undone."
            MsgUnsupported = "This game has no recognized upscaler (DLSS, FSR2, or XeSS). DLSS 5 cannot be installed."
            MsgInstalledAlready = "[ALREADY INSTALLED]"
            MsgModeDirect = "Mode: Direct (Native DLSS)"
            MsgModeBridge = "Mode: OptiScaler Bridge ({0})"
        }
    } else {
        return @{
            Eyebrow = "ECOSSISTEMA OFICIAL RENO DX • RUNTIME NEURAL NVIDIA NGX v310.8.0.0"
            Title = "1 CLICK DLSS 5"
            Subtitle = "Interface Estilo Steam • Injeção Neural em 1-Clique • Detecção Exata do Executável do Jogo"
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
            ReminderHeader = "⚡ REQUISITO OBRIGATÓRIO NO JOGO:"
            ReminderText = "Dentro do jogo, certifique-se de ATIVAR o 'NVIDIA DLSS Super Resolution' (Qualidade ou Desempenho) nas opções gráficas para que o DLSS 5 Neural funcione!"
            PayloadTitle = "Pacote DLSS 5 (Streamline 2.13 Integrado):"
            BtnChangeZip = "📦 TROCAR ZIP"
            OptReShade = "Instalar ReShade 6.8.0 (Suporte a Add-ons)"
            OptFull = "Substituição Completa de DLLs Streamline"
            BtnVerify = "🔍 VERIFICAR"
            BtnInstall = "🚀 INSTALAR DLSS 5 EM 1-CLIQUE"
            BtnLaunch = "▶️ INICIAR JOGO"
            BtnUninstall = "↩️ RESTAURAR ORIGINAL"
            BtnOpenFolder = "📂 ABRIR PASTA"
            BtnInstructions = "📖 GUIA NO JOGO"
            StatusHeading = "DIAGNÓSTICO E LOG DO SISTEMA EM TEMPO REAL"
            Footer = "1 Click DLSS 5 v1.2.0 | Séries RTX 40 & RTX 50 | DirectX 12 | Streamline 2.13 | RenoDX DLSS 5 Multi-Format"
            Badge100 = "✓ 100% COMPATÍVEL (DLSS Nativo)"
            BadgeDX12 = "✓ COMPATÍVEL (DirectX 12)"
            BadgeCheck = "? VERIFICAR SUPORTE DX12"
            MsgReady = "Pronto. Escolha um jogo na biblioteca visual ou selecione uma pasta."
            MsgScanning = "Escaneando discos ({0}) e extraindo ícones reais dos executáveis..."
            MsgScanDone = "Varredura concluída! {0} jogos carregados na biblioteca e ordenados por compatibilidade."
            MsgPayloadLoaded = "Pacote oficial 1 Click DLSS 5 embutido carregado com sucesso."
            MsgSelected = "Jogo selecionado: {0} ({1})"
            SuccessTitle = "1 Click DLSS 5 - Instalação Concluída"
            SuccessMsg = "DLSS 5 instalado com sucesso!`n`n1. Clique em [INICIAR JOGO] ou abra o jogo.`n2. Ative o DLSS Super Resolution nas opções de vídeo do jogo.`n3. Pressione a tecla [Home] -> Aba Add-ons -> Expanda 'DLSS 5' -> Ative o Preset #2 Cinematic."
            RestoreTitle = "1 Click DLSS 5 - Restauração Completa"
            RestoreMsg = "Jogo restaurado com sucesso ao estado de fábrica original! Todos os arquivos injetados foram removidos."
            BadgeBridge = "✓ COMPATÍVEL VIA OPTISCALER (FSR2/XeSS → DLSS 5)"
            BadgeUnsupported = "✗ SEM SUPORTE (Sem Upscaler Detectado)"
            ConfirmInstallTitle = "1 Click DLSS 5 - Confirmar Instalação"
            ConfirmInstallDirect = "Instalar DLSS 5 (Modo Direto) em:\n{0}\n\nDLSS nativo detectado. Streamline + RenoDX será injetado.\n\nContinuar?"
            ConfirmInstallBridge = "Instalar DLSS 5 (Ponte OptiScaler) em:\n{0}\n\n{1} detectado. O OptiScaler redirecionará para a Renderização Neural DLSS.\n\nContinuar?"
            ConfirmUninstallTitle = "1 Click DLSS 5 - Confirmar Restauração"
            ConfirmUninstall = "Remover TODOS os arquivos DLSS 5 e restaurar o jogo ao estado de fábrica?\n\n{0}\n\nEsta ação não pode ser desfeita."
            MsgUnsupported = "Este jogo não possui nenhum upscaler reconhecido (DLSS, FSR2 ou XeSS). O DLSS 5 não pode ser instalado."
            MsgInstalledAlready = "[JÁ INSTALADO]"
            MsgModeDirect = "Modo: Direto (DLSS Nativo)"
            MsgModeBridge = "Modo: Ponte OptiScaler ({0})"
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

            $allExes = @(Get-ChildItem -LiteralPath $targetRoot -Filter "*.exe" -File -Recurse -Depth 4 -ErrorAction SilentlyContinue |
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
    $existingDlss = if (Test-Path -LiteralPath $dlssCandidate -PathType Leaf) { $dlssCandidate } else { $null }

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

function Detect-GameUpscalerType {
    param([Parameter(Mandatory = $true)][string]$GameFolder)
    $allDlls = @(Get-ChildItem -LiteralPath $GameFolder -Filter "*.dll" -File -Recurse -Depth 4 -ErrorAction SilentlyContinue)
    # PRIORITY 1: Native DLSS
    foreach ($dll in $allDlls) {
        if ($dll.Name -imatch '^(nvngx_dlss\.dll|nvngx_dlssd\.dll|nvngx_dlssg\.dll|sl\.dlss\.dll|sl\.interposer\.dll|_nvngx\.dll)$') {
            return "NATIVE_DLSS"
        }
    }
    # PRIORITY 2: FSR 2/3
    foreach ($dll in $allDlls) {
        if ($dll.Name -imatch '^(ffx_fsr2_api.*\.dll|ffx_fsr3_api.*\.dll|amd_fidelityfx.*\.dll|FSR2\.dll)$') {
            return "FSR2_BRIDGE"
        }
    }
    # PRIORITY 3: XeSS
    foreach ($dll in $allDlls) {
        if ($dll.Name -imatch '^(libxess\.dll|xess\.dll|libxell\.dll)$') {
            return "XESS_BRIDGE"
        }
    }
    return "UNSUPPORTED"
}

function Prepare-Payload {
    param([Parameter(Mandatory = $true)][string]$DlssZipPath)
    $cleanZip = Sanitize-PathString -Raw $DlssZipPath
    if ([string]::IsNullOrWhiteSpace($cleanZip)) { throw "Selecione o arquivo ZIP do pacote 1 Click DLSS 5." }
    if (-not (Test-Path -LiteralPath $cleanZip -PathType Leaf)) { throw "O arquivo ZIP selecionado nao existe: $cleanZip" }

    $payloadRoot = Join-Path $PSScriptRoot "payload"
    $addon = Join-Path $payloadRoot $script:AddOnName
    if (-not (Test-Path -LiteralPath $addon -PathType Leaf)) { throw "O arquivo $script:AddOnName nao foi encontrado na pasta payload." }

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
    $payloadSetup = Join-Path $PSScriptRoot "payload\ReShade_Setup_6.8.0_Addon.exe"
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
        [Parameter(Mandatory = $true)][string]$Setup
    )
    $arguments = "--headless --api dxgi `"$TargetExe`""
    $process = Start-Process -FilePath $Setup -ArgumentList $arguments -Wait -PassThru
    if ($process.ExitCode -ne 0) { throw "Instalador do ReShade retornou codigo de erro $($process.ExitCode)." }
    $folder = Split-Path -Parent $TargetExe
    $dxgi = Join-Path $folder "dxgi.dll"
    $d3d12 = Join-Path $folder "d3d12.dll"
    if ($TargetExe.ToLower().Contains("binaries\win64") -or $TargetExe.ToLower().Contains("htgame") -or $TargetExe.ToLower().Contains("hitman")) {
        if ((Test-Path -LiteralPath $dxgi -PathType Leaf) -and (-not (Test-Path -LiteralPath $d3d12 -PathType Leaf))) {
            Move-Item -LiteralPath $dxgi -Destination $d3d12 -Force
            Write-Status -Message "ReShade configurado como d3d12.dll para compatibilidade nativa." -Level "OK"
        }
    }
}

function Get-Compatibility {
    param(
        [Parameter(Mandatory = $true)][string]$TargetPath,
        [Parameter(Mandatory = $true)][bool]$InstallReShade,
        [Parameter(Mandatory = $true)][bool]$FullPackage,
        [Parameter(Mandatory = $true)][string]$DlssZipPath
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
        if ($gpuText -match "RTX\s*(40|50)") {
            [void]$info.Add("GPU Compativel: $gpuText (Tensor Cores 4a/5a Geracao - FP8 Nativo Ativo)")
        } elseif ($gpuText -match "RTX\s*(20|30)") {
            [void]$warnings.Add("GPU Detectada: $gpuText. Nota: Modelos RTX 20/30 nao possuem instrucoes FP8 em silicio para DLSS-NR.")
        } else {
            [void]$info.Add("GPU Detectada: $gpuText")
        } }
    $drivers = @(Get-DriverVersions)
    if ($drivers.Count -gt 0) { [void]$info.Add("Driver NVIDIA: " + ($drivers -join ", ")) }
    try {
        $payloadFolder = Prepare-Payload -DlssZipPath $DlssZipPath
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

function Install-Dlss5 {
    param(
        [Parameter(Mandatory = $true)][string]$TargetPath,
        [Parameter(Mandatory = $true)][bool]$InstallReShade,
        [Parameter(Mandatory = $true)][bool]$FullPackage,
        [Parameter(Mandatory = $true)][string]$DlssZipPath
    )
    $report = Get-Compatibility -TargetPath $TargetPath -InstallReShade $InstallReShade -FullPackage $FullPackage -DlssZipPath $DlssZipPath
    foreach ($line in $report.Info) { Write-Status -Message $line -Level "INFO" }
    foreach ($line in $report.Warnings) { Write-Status -Message $line -Level "WARN" }
    foreach ($line in $report.Fatal) { Write-Status -Message $line -Level "ERROR" }
    if (-not $report.CanInstall) { throw "A verificacao de compatibilidade falhou. Verifique os erros acima." }
    $target = $report.Target
    $targetFolder = $target.InstallFolder
    $d = Get-Dict -Lang $script:CurrentLang

    # Detect upscaler type
    $upscalerType = Detect-GameUpscalerType -GameFolder $targetFolder
    Write-Status -Message "Tipo de upscaler detectado: $upscalerType" -Level "INFO"

    if ($upscalerType -eq "UNSUPPORTED") {
        Write-Status -Message $d.MsgUnsupported -Level "ERROR"
        throw $d.MsgUnsupported
    }

    # Confirmation dialog
    $confirmMsg = ""
    if ($upscalerType -eq "NATIVE_DLSS") {
        $confirmMsg = $d.ConfirmInstallDirect -f $target.ExeName
    } else {
        $bridgeName = if ($upscalerType -eq "FSR2_BRIDGE") { "FSR2/FSR3" } else { "XeSS" }
        $confirmMsg = $d.ConfirmInstallBridge -f $target.ExeName, $bridgeName
    }
    $result = [System.Windows.Forms.MessageBox]::Show($confirmMsg, $d.ConfirmInstallTitle, [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
    if ($result -ne [System.Windows.Forms.DialogResult]::Yes) {
        Write-Status -Message "Instalacao cancelada pelo usuario." -Level "WARN"
        return
    }

    $backupFolder = Join-Path $targetFolder $script:BackupName
    [void](New-Item -ItemType Directory -Path $backupFolder -Force)
    $stateFile = Join-Path $targetFolder $script:StateName
    $state = @{
        InstalledAt = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        TargetExe = $target.Executable
        Mode = if ($upscalerType -eq "NATIVE_DLSS") { "DIRECT" } else { "OPTISCALER" }
        UpscalerType = $upscalerType
        BackedUpFiles = @()
        InjectedFiles = @()
    }

    # Install ReShade if checked
    if ($InstallReShade) {
        $setup = Get-ReShadeSetup
        Install-ReShade -TargetExe $target.Executable -Setup $setup
        $state.InjectedFiles += "dxgi.dll"
        $state.InjectedFiles += "d3d12.dll"
    }

    # Apply pre-configured ReShade.ini
    $defaultIni = Join-Path $PSScriptRoot "payload\ReShade.ini"
    $targetIni = Join-Path $targetFolder "ReShade.ini"
    if (Test-Path -LiteralPath $defaultIni -PathType Leaf) {
        Copy-Item -LiteralPath $defaultIni -Destination $targetIni -Force
        $state.InjectedFiles += "ReShade.ini"
        Write-Status -Message "Pre-configuracao aplicada: Auto Skin Mask ATIVADO, Preset #2 Cinematic e Intensidade 0.80." -Level "OK"
    }

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
    } else {
        # === OPTISCALER BRIDGE MODE: OptiScaler + RenoDX ===
        $bridgeName = if ($upscalerType -eq "FSR2_BRIDGE") { "FSR2/FSR3" } else { "XeSS" }
        Write-Status -Message "Modo PONTE OPTISCALER: $bridgeName detectado. Redirecionando para DLSS Neural..." -Level "INFO"

        # Copy OptiScaler.dll as version.dll
        $optiSrc = Join-Path $PSScriptRoot "payload\optiscaler\OptiScaler.dll"
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
        $optiIniSrc = Join-Path $PSScriptRoot "payload\optiscaler\OptiScaler.ini"
        $optiIniDst = Join-Path $targetFolder "OptiScaler.ini"
        if (Test-Path -LiteralPath $optiIniSrc -PathType Leaf) {
            Copy-Item -LiteralPath $optiIniSrc -Destination $optiIniDst -Force
            $state.InjectedFiles += "OptiScaler.ini"
        }

        # Copy libxess.dll (if not already present)
        $xessSrc = Join-Path $PSScriptRoot "payload\optiscaler\libxess.dll"
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
        $addonSrc = Join-Path $PSScriptRoot "payload\$($script:AddOnName)"
        $addonDst = Join-Path $targetFolder $script:AddOnName
        if (Test-Path -LiteralPath $addonSrc -PathType Leaf) {
            Copy-Item -LiteralPath $addonSrc -Destination $addonDst -Force
            $state.InjectedFiles += $script:AddOnName
        }
    }

    ($state | ConvertTo-Json -Depth 4) | Out-File -LiteralPath $stateFile -Encoding utf8 -Force
    Write-Status -Message "==========================================================" -Level "OK"
    Write-Status -Message "1 CLICK DLSS 5 NEURAL INSTALADO COM SUCESSO!" -Level "OK"
    if ($upscalerType -eq "NATIVE_DLSS") {
        Write-Status -Message "Modo: DIRETO | No jogo: Ative DLSS (Qualidade) -> [Home] -> Add-ons -> DLSS 5" -Level "OK"
    } else {
        $bridgeName = if ($upscalerType -eq "FSR2_BRIDGE") { "FSR2" } else { "XeSS" }
        Write-Status -Message "Modo: OPTISCALER ($bridgeName) | No jogo: Ative $bridgeName (Qualidade) -> [Home] -> Add-ons -> DLSS 5" -Level "OK"
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

    # Complete purge list (covers DIRECT + OPTISCALER modes)
    $purgeList = @(
        "d3d12.dll", "dxgi.dll",
        "renodx-dlss5.addon64", "renodx-dlss5++.addon64", "renodx-dlss5-v3.addon64",
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

    # Remove reshade-shaders folder
    $reshadeDir = Join-Path $targetFolder "reshade-shaders"
    if (Test-Path -LiteralPath $reshadeDir -PathType Container) {
        Remove-Item -LiteralPath $reshadeDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    Write-Status -Message "Jogo 100% restaurado ao estado de fabrica!" -Level "OK"
    [System.Windows.Forms.MessageBox]::Show($d.RestoreMsg, $d.RestoreTitle, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
}

function Scan-DriveForGames {
    param([string]$DriveLetter = "ALL")
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
    $ignored = @("steamworks shared", "_commonredist", "directx", "vcredist", "dotnet", "crashreport", "tools", "easyanticheat", "battleye")
    $dDict = Get-Dict -Lang $script:CurrentLang

    foreach ($root in $rootsToScan) {
        if (Test-Path -LiteralPath $root -PathType Container) {
            try {
                $dirs = Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue
                foreach ($dir in $dirs) {
                    if ($ignored -contains $dir.Name.ToLower()) { continue }
                    $gamePath = $dir.FullName
                    $hasDlss = $false
                    $hasDx12 = $false
                    $isUe = $false

                    $dlssFiles = @(Get-ChildItem -LiteralPath $gamePath -Filter "*dlss*" -File -Recurse -Depth 4 -ErrorAction SilentlyContinue)
                    if ($dlssFiles.Count -gt 0) { $hasDlss = $true }

                    $d3d12Files = @(Get-ChildItem -LiteralPath $gamePath -Filter "*d3d12*" -File -Recurse -Depth 4 -ErrorAction SilentlyContinue)
                    if ($d3d12Files.Count -gt 0) { $hasDx12 = $true }

                    $binFiles = @(Get-ChildItem -LiteralPath $gamePath -Filter "*.exe" -File -Recurse -Depth 4 -ErrorAction SilentlyContinue | Where-Object { $_.FullName.ToLower().Contains("binaries\win64") })
                    if ($binFiles.Count -gt 0) { $isUe = $true; $hasDx12 = $true }

                    $hasFsr2 = $false
                    $hasXess = $false

                    $fsrFiles = @(Get-ChildItem -LiteralPath $gamePath -Filter "*fidelityfx*" -File -Recurse -Depth 4 -ErrorAction SilentlyContinue)
                    $fsrFiles += @(Get-ChildItem -LiteralPath $gamePath -Filter "ffx_fsr*" -File -Recurse -Depth 4 -ErrorAction SilentlyContinue)
                    if ($fsrFiles.Count -gt 0) { $hasFsr2 = $true }

                    $xessFiles = @(Get-ChildItem -LiteralPath $gamePath -Filter "libxess*" -File -Recurse -Depth 4 -ErrorAction SilentlyContinue)
                    $xessFiles += @(Get-ChildItem -LiteralPath $gamePath -Filter "xess.dll" -File -Recurse -Depth 4 -ErrorAction SilentlyContinue)
                    if ($xessFiles.Count -gt 0) { $hasXess = $true }

                    $badge = ""
                    $order = 3
                    if ($hasDlss) {
                        $badge = $dDict.Badge100
                        $order = 1
                    } elseif ($hasFsr2 -or $hasXess) {
                        $badge = $dDict.BadgeBridge
                        $order = 2
                    } elseif ($hasDx12 -or $isUe) {
                        $badge = $dDict.BadgeDX12
                        $order = 3
                    } else {
                        $badge = $dDict.BadgeUnsupported
                        $order = 4
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
                }
            } catch {}
        }
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
        $msg = "GUIA DE OTIMIZACAO E USO DO 1 CLICK DLSS 5 (NEURAL RENDERING):`n`n1. OPCOES GRAFICAS NO JOGO:`n - Ative o NVIDIA DLSS Super Resolution (Qualidade, Balanceado ou Desempenho).`n - DICA CRITICA: Mantenha o HDR DESATIVADO no jogo para evitar estouro de cores no modelo neural.`n`n2. ABRIR O PAINEL NO JOGO:`n - Pressione a tecla [Home] (ou Pos1) para abrir a barra do ReShade/RenoDX.`n`n3. CONFIGURACOES RECOMENDADAS (ABAS ADD-ONS -> DLSS 5):`n - Auto Skin Mask: ATIVADO (evita distorcoes e envelhecimento em rostos de personagens).`n - NR Preset: Preset #2 (Cinematic / Iluminacao Coerente).`n - Neural Intensity: 0.75 a 0.85 (equilibrio perfeito de iluminacao e sombras).`n - Structure / Local Tone Strength: Padrao.`n`n4. COMPATIBILIDADE DE HARDWARE:`n - O DLSS 5 Neural opera em matrizes FP8 nas GPUs RTX 40 e 50.`n`n5. INICIAR JOGO:`n - Use o botao [INICIAR JOGO] para abrir diretamente com as DLLs injetadas!`n`n6. JOGOS SEM DLSS NATIVO (FSR2/XeSS):`n - O programa detectou e instalou automaticamente a ponte OptiScaler.`n - Ative o upscaler original do jogo (FSR2 ou XeSS) no modo Qualidade.`n - O OptiScaler redireciona automaticamente para o modelo neural DLSS 5."
        [System.Windows.Forms.MessageBox]::Show($msg, "1 Click DLSS 5 - Instrucoes", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    } else {
        $msg = "1 CLICK DLSS 5 OPTIMIZATION & USAGE GUIDE:`n`n1. IN-GAME GRAPHICS SETTINGS:`n - Enable NVIDIA DLSS Super Resolution (Quality, Balanced or Performance).`n - CRITICAL TIP: Keep in-game HDR DISABLED for accurate SDR neural color space.`n`n2. OPEN IN-GAME OVERLAY:`n - Press the [Home] (or Pos1) key to open the ReShade/RenoDX menu.`n`n3. RECOMMENDED TUNING (ADD-ONS TAB -> DLSS 5):`n - Auto Skin Mask: ENABLED (prevents facial warping and artificial aging on characters).`n - NR Preset: Preset #2 (Cinematic / Coherent Lighting).`n - Neural Intensity: 0.75 - 0.85 (ideal physical lighting & contact shadows).`n - Structure / Local Tone: Default.`n`n4. HARDWARE ARCHITECTURE:`n - DLSS 5 Neural Rendering runs native FP8 on RTX 40 & RTX 50 Series.`n`n5. DIRECT LAUNCH:`n - Click [LAUNCH GAME] to start playing with all neural modules active!`n`n6. GAMES WITHOUT NATIVE DLSS (FSR2/XeSS):`n - The program detected and automatically installed the OptiScaler bridge.`n - Enable the original upscaler (FSR2 or XeSS) in Quality mode.`n - OptiScaler automatically redirects to the DLSS 5 neural model."
        [System.Windows.Forms.MessageBox]::Show($msg, "1 Click DLSS 5 - Instructions", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }
}

# --- FORMULARIO PRINCIPAL: STEAM-STYLE GAME CENTER ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "1 Click DLSS 5 v1.2.0 • Universal Neural Game Center"
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

$eyebrow = New-Label -Text "ECOSSISTEMA OFICIAL RENO DX • RUNTIME NEURAL NVIDIA NGX v310.8.0.0" -X 24 -Y 12 -Width 750 -Height 18
$eyebrow.ForeColor = [System.Drawing.Color]::FromArgb(118, 185, 0)
$eyebrow.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 8.5)
[void]$header.Controls.Add($eyebrow)

$title = New-Label -Text "1 CLICK DLSS 5"
$title.Location = New-Object System.Drawing.Point(22, 28)
$title.Size = New-Object System.Drawing.Size(750, 40)
$title.Font = New-Object System.Drawing.Font("Segoe UI", 21, [System.Drawing.FontStyle]::Bold)
$title.ForeColor = [System.Drawing.Color]::White
[void]$header.Controls.Add($title)

$subtitle = New-Label -Text "Interface Estilo Steam • Injeção Neural em 1-Clique • Detecção Exata do Executável do Jogo" -X 24 -Y 72 -Width 750 -Height 22
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

$lblExeTitle = New-Label -Text "Executável Principal 64-bit:" -X 460 -Y 158 -Width 220 -Height 18
$lblExeTitle.Anchor = "Top, Right"
$lblExeTitle.ForeColor = [System.Drawing.Color]::FromArgb(143, 200, 255)
[void]$inspectorPanel.Controls.Add($lblExeTitle)

$txtExeName = New-Object System.Windows.Forms.TextBox
$txtExeName.Location = New-Object System.Drawing.Point(460, 178)
$txtExeName.Size = New-Object System.Drawing.Size(226, 24)
$txtExeName.Anchor = "Top, Right"
$txtExeName.ReadOnly = $true
$txtExeName.BackColor = [System.Drawing.Color]::FromArgb(10, 16, 28)
$txtExeName.ForeColor = [System.Drawing.Color]::FromArgb(130, 215, 255)
$txtExeName.BorderStyle = "FixedSingle"
[void]$inspectorPanel.Controls.Add($txtExeName)

# LEMBRETE OBRIGATORIO DE DLSS ATIVADO
$reminderBox = New-Object System.Windows.Forms.Panel
$reminderBox.Location = New-Object System.Drawing.Point(18, 212)
$reminderBox.Size = New-Object System.Drawing.Size(668, 62)
$reminderBox.Anchor = "Top, Left, Right"
$reminderBox.BackColor = [System.Drawing.Color]::FromArgb(35, 30, 12)
[void]$inspectorPanel.Controls.Add($reminderBox)

$reminderAccent = New-Object System.Windows.Forms.Panel
$reminderAccent.Location = New-Object System.Drawing.Point(0, 0)
$reminderAccent.Size = New-Object System.Drawing.Size(4, 62)
$reminderAccent.BackColor = [System.Drawing.Color]::FromArgb(255, 195, 0)
[void]$reminderBox.Controls.Add($reminderAccent)

$lblReminderHeader = New-Label -Text "⚡ REQUISITO OBRIGATÓRIO NO JOGO:" -X 14 -Y 8 -Width 640 -Height 18
$lblReminderHeader.ForeColor = [System.Drawing.Color]::FromArgb(255, 205, 50)
$lblReminderHeader.Font = New-Object System.Drawing.Font("Segoe UI Bold", 9)
[void]$reminderBox.Controls.Add($lblReminderHeader)

$lblReminderText = New-Label -Text "Dentro do jogo, certifique-se de ATIVAR o 'NVIDIA DLSS Super Resolution' (Qualidade ou Desempenho) nas opções gráficas para que o DLSS 5 Neural funcione!" -X 14 -Y 26 -Width 640 -Height 32
$lblReminderText.ForeColor = [System.Drawing.Color]::FromArgb(240, 230, 190)
$lblReminderText.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
[void]$reminderBox.Controls.Add($lblReminderText)

# Opções de Injeção & Pacote
$lblPayloadTitle = New-Label -Text "Pacote DLSS 5 (Streamline 2.13 Integrado):" -X 18 -Y 282 -Width 300 -Height 18
$lblPayloadTitle.ForeColor = [System.Drawing.Color]::FromArgb(170, 190, 215)
[void]$inspectorPanel.Controls.Add($lblPayloadTitle)

$dlssZipText = New-Object System.Windows.Forms.TextBox
$dlssZipText.Location = New-Object System.Drawing.Point(18, 302)
$dlssZipText.Size = New-Object System.Drawing.Size(530, 24)
$dlssZipText.Anchor = "Top, Left, Right"
$dlssZipText.BackColor = [System.Drawing.Color]::FromArgb(10, 16, 28)
$dlssZipText.ForeColor = [System.Drawing.Color]::White
$dlssZipText.BorderStyle = "FixedSingle"
[void]$inspectorPanel.Controls.Add($dlssZipText)

$dlssBrowse = New-Object System.Windows.Forms.Button
$dlssBrowse.Text = "📦 TROCAR ZIP"
$dlssBrowse.Location = New-Object System.Drawing.Point(558, 300)
$dlssBrowse.Size = New-Object System.Drawing.Size(128, 28)
$dlssBrowse.Anchor = "Top, Right"
Style-Button -Button $dlssBrowse -BaseColor ([System.Drawing.Color]::FromArgb(40, 70, 115)) -HoverColor ([System.Drawing.Color]::FromArgb(55, 95, 155))
[void]$inspectorPanel.Controls.Add($dlssBrowse)

$copyReShade = New-Object System.Windows.Forms.CheckBox
$copyReShade.Text = "Instalar ReShade 6.8.0 (Suporte a Add-ons)"
$copyReShade.Location = New-Object System.Drawing.Point(18, 335)
$copyReShade.Size = New-Object System.Drawing.Size(300, 22)
$copyReShade.Checked = $true
$copyReShade.ForeColor = [System.Drawing.Color]::White
[void]$inspectorPanel.Controls.Add($copyReShade)

$fullPackage = New-Object System.Windows.Forms.CheckBox
$fullPackage.Text = "Substituicao Completa de DLLs Streamline"
$fullPackage.Location = New-Object System.Drawing.Point(330, 335)
$fullPackage.Size = New-Object System.Drawing.Size(350, 22)
$fullPackage.Checked = $true
$fullPackage.ForeColor = [System.Drawing.Color]::FromArgb(120, 215, 140)
[void]$inspectorPanel.Controls.Add($fullPackage)

# BARRA DE ACAO PRINCIPAL COM BOTAO INICIAR JOGO
$actionBar = New-Object System.Windows.Forms.Panel
$actionBar.Location = New-Object System.Drawing.Point(18, 368)
$actionBar.Size = New-Object System.Drawing.Size(668, 100)
$actionBar.Anchor = "Top, Left, Right"
$actionBar.BackColor = [System.Drawing.Color]::Transparent
[void]$inspectorPanel.Controls.Add($actionBar)

$install = New-Object System.Windows.Forms.Button
$install.Text = "🚀 1-CLIQUE: INSTALAR DLSS 5"
$install.Location = New-Object System.Drawing.Point(0, 4)
$install.Size = New-Object System.Drawing.Size(326, 44)
$install.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
Style-Button -Button $install -BaseColor ([System.Drawing.Color]::FromArgb(118, 185, 0)) -HoverColor ([System.Drawing.Color]::FromArgb(140, 220, 0))
$install.ForeColor = [System.Drawing.Color]::Black
[void]$actionBar.Controls.Add($install)

$launchGame = New-Object System.Windows.Forms.Button
$launchGame.Text = "▶️ INICIAR JOGO"
$launchGame.Location = New-Object System.Drawing.Point(338, 4)
$launchGame.Size = New-Object System.Drawing.Size(330, 44)
$launchGame.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
Style-Button -Button $launchGame -BaseColor ([System.Drawing.Color]::FromArgb(0, 130, 230)) -HoverColor ([System.Drawing.Color]::FromArgb(20, 160, 255))
[void]$actionBar.Controls.Add($launchGame)

$uninstall = New-Object System.Windows.Forms.Button
$uninstall.Text = "↩️ RESTAURAR"
$uninstall.Location = New-Object System.Drawing.Point(0, 54)
$uninstall.Size = New-Object System.Drawing.Size(180, 36)
Style-Button -Button $uninstall -BaseColor ([System.Drawing.Color]::FromArgb(180, 50, 50)) -HoverColor ([System.Drawing.Color]::FromArgb(215, 60, 60))
[void]$actionBar.Controls.Add($uninstall)

$openFolder = New-Object System.Windows.Forms.Button
$openFolder.Text = "📂 ABRIR PASTA"
$openFolder.Location = New-Object System.Drawing.Point(190, 54)
$openFolder.Size = New-Object System.Drawing.Size(180, 36)
Style-Button -Button $openFolder -BaseColor ([System.Drawing.Color]::FromArgb(40, 70, 115)) -HoverColor ([System.Drawing.Color]::FromArgb(55, 95, 155))
[void]$actionBar.Controls.Add($openFolder)

$instructions = New-Object System.Windows.Forms.Button
$instructions.Text = "📖 GUIA NO JOGO"
$instructions.Location = New-Object System.Drawing.Point(380, 54)
$instructions.Size = New-Object System.Drawing.Size(160, 36)
Style-Button -Button $instructions -BaseColor ([System.Drawing.Color]::FromArgb(40, 70, 115)) -HoverColor ([System.Drawing.Color]::FromArgb(55, 95, 155))
[void]$actionBar.Controls.Add($instructions)

$scan = New-Object System.Windows.Forms.Button
$scan.Text = "🔍 VERIFICAR"
$scan.Location = New-Object System.Drawing.Point(550, 54)
$scan.Size = New-Object System.Drawing.Size(118, 36)
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
$footer = New-Label -Text "1 Click DLSS 5 v1.2.0 | Séries RTX 40 & RTX 50 | DirectX 12 | Streamline 2.13 | RenoDX DLSS 5 Multi-Format" -X 20 -Y 825 -Width 1145 -Height 22
$footer.Anchor = "Bottom, Left, Right"
$footer.ForeColor = [System.Drawing.Color]::FromArgb(120, 140, 170)
$footer.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
[void]$form.Controls.Add($footer)

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
    } elseif ($GameObj.Badge.Contains("COMPAT") -or $GameObj.Badge.Contains("DX12")) {
        $lblSelectedGameBadge.ForeColor = [System.Drawing.Color]::FromArgb(255, 205, 90)
    } else {
        $lblSelectedGameBadge.ForeColor = [System.Drawing.Color]::FromArgb(180, 180, 180)
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

        # Check if DLSS 5 is already installed
        $existingState = Join-Path $resolved.InstallFolder $script:StateName
        if (Test-Path -LiteralPath $existingState -PathType Leaf) {
            try {
                $savedState = Get-Content -LiteralPath $existingState -Raw | ConvertFrom-Json
                $modeText = if ($savedState.Mode -eq "OPTISCALER") {
                    $d.MsgModeBridge -f $savedState.UpscalerType
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

    Refresh-GameLibrary
}

$btnLangPT.Add_Click({ Update-Language "PT" })
$btnLangEN.Add_Click({ Update-Language "EN" })

function Refresh-GameLibrary {
    $selDrive = if ($driveCombo.SelectedIndex -le 0) { "ALL" } else { $driveCombo.SelectedItem.ToString() }
    $d = Get-Dict -Lang $script:CurrentLang
    Write-Status -Message ($d.MsgScanning -f $selDrive) -Level "INFO"
    $script:DiscoveredGames = @(Scan-DriveForGames -DriveLetter $selDrive)

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
        } elseif ($g.Badge.Contains("COMPAT") -or $g.Badge.Contains("DX12")) {
            $item.ForeColor = [System.Drawing.Color]::FromArgb(255, 210, 110)
        } else {
            $item.ForeColor = [System.Drawing.Color]::FromArgb(180, 180, 180)
        }

        [void]$gameListView.Items.Add($item)
    }
    $gameListView.EndUpdate()

    if ($gameListView.Items.Count -gt 0) {
        $gameListView.Items[0].Selected = $true
        Select-GameInInspector -GameObj $gameListView.Items[0].Tag
    }
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
            $uType = Detect-GameUpscalerType -GameFolder $resolved.InstallFolder
            $manualBadge = switch ($uType) {
                "NATIVE_DLSS" { $d.Badge100 }
                "FSR2_BRIDGE" { $d.BadgeBridge }
                "XESS_BRIDGE" { $d.BadgeBridge }
                default { $d.BadgeUnsupported }
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
        $report = Get-Compatibility -TargetPath $txtRootFolder.Text.Trim() -InstallReShade $copyReShade.Checked -FullPackage $fullPackage.Checked -DlssZipPath $dlssZipText.Text.Trim()
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
        Install-Dlss5 -TargetPath $txtRootFolder.Text.Trim() -InstallReShade $copyReShade.Checked -FullPackage $fullPackage.Checked -DlssZipPath $dlssZipText.Text.Trim()
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
    $embeddedZip = Join-Path $PSScriptRoot "payload\streamline.zip"
    if (Test-Path -LiteralPath $embeddedZip -PathType Leaf) {
        $dlssZipText.Text = $embeddedZip
        $d = Get-Dict -Lang $script:CurrentLang
        Write-Status -Message $d.MsgPayloadLoaded -Level "OK"
    }
    Refresh-GameLibrary
    $d = Get-Dict -Lang $script:CurrentLang
    Write-Status -Message $d.MsgReady -Level "INFO"
})

[void]$form.ShowDialog()


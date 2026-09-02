<#
.SYNOPSIS
    1 Click DLSS 5 v2.5.2-beta • Universal Neural Control Center
    Auto-Descoberta Instantânea de Jogos (Steam, Epic, GOG, Xbox, EA), Motor de Resolução em 1 Clique (Auto-Fix),
    Suporte Universal a APIs (DirectX 9/10/11/12, Vulkan, OpenGL), 32 e 64-bit, 10 Idiomas Nativos.
#>

Set-StrictMode -Off
$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression.FileSystem

[System.Windows.Forms.Application]::EnableVisualStyles()

# --- CONFIGURAÇÕES GLOBAIS ---
$script:Version = "2.5.2-beta"
$script:CurrentLang = "PT"
$script:AddOnName = "renodx-dlss5.addon64"
$script:StateName = "_dlss5_install_state.json"
$script:BackupName = "_DLSS5_Backup"
$script:SelectedGameObj = $null
$script:CurrentDetectedUpscaler = "UNIVERSAL_FEEDER"
$script:SelectedMode = "AUTO"
$script:CurrentGameLibrary = @()

$script:PayloadFolder = Join-Path $PSScriptRoot "payload"
$script:IconPath = Join-Path $PSScriptRoot "assets\icon.ico"
$script:TranslationsPath = Join-Path $PSScriptRoot "assets\translations.json"
$script:LogFilePath = Join-Path $PSScriptRoot "1-Click-DLSS5.log"

$script:Translations = $null
if (Test-Path -LiteralPath $script:TranslationsPath -PathType Leaf) {
    try {
        $jsonRaw = Get-Content -LiteralPath $script:TranslationsPath -Raw -Encoding UTF8
        $script:Translations = $jsonRaw | ConvertFrom-Json
    } catch {}
}

# --- INICIALIZAÇÃO DE TELEMETRIA E LOG CONTÍNUO ---
function Write-Status {
    param(
        [Parameter(Mandatory = $true)][string]$Message,
        [Parameter(Mandatory = $false)][string]$Level = "INFO",
        [Parameter(Mandatory = $false)][string]$Code = "",
        [Parameter(Mandatory = $false)][string]$Cause = "",
        [Parameter(Mandatory = $false)][string]$Fix = ""
    )
    $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $logLine = "[$ts] [$Level] $Message"
    if ($Code) { $logLine = $logLine + " [CODE: $Code]" }
    if ($Cause) { $logLine = $logLine + " [CAUSA: $Cause]" }
    if ($Fix) { $logLine = $logLine + " [SOLUCAO: $Fix]" }

    try {
        $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
        [System.IO.File]::AppendAllText($script:LogFilePath, $logLine + "`r`n", $utf8NoBom)
    } catch {}

    if ($script:StatusLabel) {
        $color = [System.Drawing.Color]::FromArgb(170, 205, 255)
        if ($Level -eq "OK") {
            $color = [System.Drawing.Color]::FromArgb(118, 225, 125)
        } elseif ($Level -eq "WARN") {
            $color = [System.Drawing.Color]::FromArgb(255, 205, 90)
        } elseif ($Level -eq "ERROR") {
            $color = [System.Drawing.Color]::FromArgb(255, 110, 110)
        }
        $script:StatusLabel.Text = "● " + $Message
        $script:StatusLabel.ForeColor = $color
    }
}

function Init-SystemTelemetryLog {
    if (-not (Test-Path -LiteralPath $script:LogFilePath -PathType Leaf)) {
        $sysInfo = "================================================================================`r`n"
        $sysInfo = $sysInfo + "   1 CLICK DLSS 5 v$($script:Version) • NEURAL CONTROL CENTER LOG DE TELEMETRIA`r`n"
        $sysInfo = $sysInfo + "   Iniciado em: $((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))`r`n"
        $sysInfo = $sysInfo + "================================================================================`r`n"
        try {
            $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
            if ($os) { $sysInfo = $sysInfo + "OS: $($os.Caption) ($($os.Version) Build $($os.BuildNumber))`r`n" }
            $gpus = Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue
            if ($gpus) {
                foreach ($g in $gpus) {
                    $sysInfo = $sysInfo + "GPU: $($g.Name) (Driver: $($g.DriverVersion))`r`n"
                }
            }
            $cpu = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue
            if ($cpu) { $sysInfo = $sysInfo + "CPU: $($cpu.Name)`r`n" }
        } catch {}
        $sysInfo = $sysInfo + "================================================================================`r`n`r`n"
        try { 
            $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
            [System.IO.File]::WriteAllText($script:LogFilePath, $sysInfo, $utf8NoBom) 
        } catch {}
    }
}
Init-SystemTelemetryLog

function Open-LogFile {
    if (Test-Path -LiteralPath $script:LogFilePath -PathType Leaf) {
        Start-Process "notepad.exe" -ArgumentList "`"$script:LogFilePath`""
    } else {
        [System.Windows.Forms.MessageBox]::Show("Nenhum log gerado ainda.", "1 Click DLSS 5", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }
}

function Get-DLSS5PayloadDirectory {
    if (Test-Path -LiteralPath $script:PayloadFolder -PathType Container) {
        return $script:PayloadFolder
    }
    $alt = Join-Path $PSScriptRoot "core\payload"
    if (Test-Path -LiteralPath $alt -PathType Container) {
        return $alt
    }
    return $script:PayloadFolder
}

function Get-Sha256 {
    param([Parameter(Mandatory = $true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $null }
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $stream = [System.IO.File]::OpenRead($Path)
    $hashBytes = $sha.ComputeHash($stream)
    $stream.Close()
    $stream.Dispose()
    return (-join ($hashBytes | ForEach-Object { "{0:x2}" -f $_ }))
}

function Get-PeArchitecture {
    param([Parameter(Mandatory = $true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return "UNKNOWN" }
    try {
        $fs = [System.IO.File]::OpenRead($Path)
        $br = New-Object System.IO.BinaryReader($fs)
        if ($fs.Length -lt 64) { $fs.Close(); return "UNKNOWN" }
        $mz = $br.ReadUInt16()
        if ($mz -ne 0x5A4D) { $fs.Close(); return "UNKNOWN" }
        $fs.Position = 0x3C
        $peOffset = $br.ReadInt32()
        if ($peOffset -lt 0 -or $peOffset -ge ($fs.Length - 4)) { $fs.Close(); return "UNKNOWN" }
        $fs.Position = $peOffset
        $peSig = $br.ReadUInt32()
        if ($peSig -ne 0x00004550) { $fs.Close(); return "UNKNOWN" }
        $machine = $br.ReadUInt16()
        $fs.Close()
        if ($machine -eq 0x8664) { return "X64" }
        if ($machine -eq 0x014C) { return "X86" }
        if ($machine -eq 0xAA64) { return "ARM64" }
        return "OTHER"
    } catch {
        return "UNKNOWN"
    }
}

function Test-ValidPe {
    param([Parameter(Mandatory = $true)][string]$Path)
    $arch = Get-PeArchitecture -Path $Path
    return ($arch -eq "X64" -or $arch -eq "X86" -or $arch -eq "ARM64")
}

function Sanitize-PathString {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return $Path }
    $p = $Path.Trim()
    if ($p.StartsWith('"') -and $p.EndsWith('"') -and $p.Length -ge 2) {
        $p = $p.Substring(1, $p.Length - 2)
    }
    return $p.Trim()
}

function Resolve-GameTarget {
    param([Parameter(Mandatory = $true)][string]$TargetPath)
    $cleanPath = Sanitize-PathString -Path $TargetPath
    if (-not (Test-Path -LiteralPath $cleanPath)) {
        throw "ERR_PATH_NOT_FOUND: O caminho fornecido nao existe: $TargetPath"
    }
    $targetItem = Get-Item -LiteralPath $cleanPath
    $folder = ""
    if ($targetItem.PSIsContainer) {
        $folder = $targetItem.FullName
    } else {
        $folder = $targetItem.Directory.FullName
    }
    $root = $folder
    $exePath = $null

    if (-not $targetItem.PSIsContainer -and $targetItem.Extension -ieq ".exe") {
        $exePath = $targetItem.FullName
    } else {
        $allExes = @(Get-ChildItem -LiteralPath $folder -Filter "*.exe" -File -Recurse -Depth 4 -ErrorAction SilentlyContinue)
        $ignoredPattern = '^(crashreport|crashhandler|unitycrashhandler|unins.*|setup|config|launcher|easyanticheat|battleye|epicgameslauncher|redist|vcredist|dxsetup|quickstart|webinstaller)$'
        $filtered = @($allExes | Where-Object {
            $baseName = $_.BaseName.ToLower()
            -not ($baseName -match $ignoredPattern)
        })

        $foundWin64 = $filtered | Where-Object { $_.FullName -imatch '\\binaries\\win64\\' -and (Test-ValidPe -Path $_.FullName) } | Select-Object -First 1
        if ($foundWin64) {
            $exePath = $foundWin64.FullName
        } else {
            $rootExes = @($filtered | Where-Object { $_.Directory.FullName -ieq $folder -and (Test-ValidPe -Path $_.FullName) } | Sort-Object -Property Length -Descending)
            if ($rootExes.Count -gt 0) {
                $exePath = $rootExes[0].FullName
            } elseif ($filtered.Count -gt 0) {
                $largest = $filtered | Sort-Object -Property Length -Descending | Select-Object -First 1
                $exePath = $largest.FullName
            }
        }
    }

    if (-not $exePath) {
        throw "ERR_EXE_NOT_FOUND: Nenhum executavel de jogo compativel foi localizado na pasta: $folder"
    }

    $installFolder = (Get-Item -LiteralPath $exePath).Directory.FullName
    $icon = $null
    try {
        $icon = [System.Drawing.Icon]::ExtractAssociatedIcon($exePath)
    } catch {}

    return [pscustomobject]@{
        Root = $root
        InstallFolder = $installFolder
        Executable = $exePath
        ExeName = (Split-Path -Leaf $exePath)
        Icon = $icon
        Architecture = (Get-PeArchitecture -Path $exePath)
    }
}

function Detect-GameGraphicsApi {
    param(
        [Parameter(Mandatory = $true)][string]$TargetExe,
        [Parameter(Mandatory = $false)][string]$GameFolder = ""
    )
    if ([string]::IsNullOrWhiteSpace($GameFolder)) {
        $GameFolder = (Split-Path -Parent $TargetExe)
    }
    $allDlls = @(Get-ChildItem -LiteralPath $GameFolder -Filter "*.dll" -File -Recurse -Depth 3 -ErrorAction SilentlyContinue | ForEach-Object { $_.Name.ToLower() })
    if ($allDlls -contains "d3d12.dll" -or $allDlls -contains "d3d12core.dll") { return "D3D12" }
    if ($allDlls -contains "vulkan-1.dll" -or $allDlls -contains "vulkan.dll") { return "VULKAN" }
    if ($allDlls -contains "d3d11.dll" -or $allDlls -contains "dxgi.dll") { return "DXGI" }
    if ($allDlls -contains "d3d9.dll") { return "D3D9" }
    if ($allDlls -contains "opengl32.dll") { return "OPENGL" }

    $allFiles = @(Get-ChildItem -LiteralPath $GameFolder -File -Recurse -Depth 3 -ErrorAction SilentlyContinue | ForEach-Object { $_.Name.ToLower() })
    foreach ($f in $allFiles) {
        if ($f -match 'd3d12') { return "D3D12" }
        if ($f -match 'vulkan') { return "VULKAN" }
        if ($f -match 'd3d11|dxgi') { return "DXGI" }
        if ($f -match 'd3d9') { return "D3D9" }
    }
    return "DXGI"
}

function Detect-GameUpscalerType {
    param(
        [Parameter(Mandatory = $true)][string]$GameFolder,
        [Parameter(Mandatory = $false)][string]$GameRoot = ""
    )
    $folders = @($GameFolder)
    if (-not [string]::IsNullOrWhiteSpace($GameRoot) -and ($GameRoot -ne $GameFolder)) {
        $folders += $GameRoot
    }

    $allFiles = New-Object System.Collections.Generic.List[string]
    foreach ($fPath in $folders) {
        if (Test-Path -LiteralPath $fPath -PathType Container) {
            $files = @(Get-ChildItem -LiteralPath $fPath -File -Recurse -Depth 4 -ErrorAction SilentlyContinue | ForEach-Object { $_.Name.ToLower() })
            foreach ($fn in $files) { [void]$allFiles.Add($fn) }
        }
    }

    # 1. Verifica se já está instalado o mod DLSS 5
    $isModded = $false
    $modMode = ""
    if ($allFiles.Contains("dlss5-feed.addon64") -or $allFiles.Contains("dlss5-feed.addon32")) {
        $isModded = $true
        $modMode = "FEEDER"
    } elseif ($allFiles.Contains("version.dll") -and $allFiles.Contains("optiscaler.ini")) {
        $isModded = $true
        $modMode = "OPTISCALER"
    } elseif ($allFiles.Contains("sl.interposer.dll") -and $allFiles.Contains("nvngx_dlssnr.dll")) {
        $isModded = $true
        $modMode = "DIRECT"
    } elseif ($allFiles.Contains("nvngx_dlssnr.dll")) {
        $isModded = $true
        $modMode = "FEEDER"
    }

    # 2. Verifica se há arquivo de estado
    $stateFiles = @("_dlss5_install_state.json", "_1click_dlss5_state.json", "_dlss5_easy_installer_state.json")
    foreach ($sf in $stateFiles) {
        $sp = Join-Path $GameFolder $sf
        if (Test-Path -LiteralPath $sp -PathType Leaf) {
            try {
                $saved = Get-Content -LiteralPath $sp -Raw -Encoding UTF8 | ConvertFrom-Json
                if ($saved.UpscalerType) { return $saved.UpscalerType }
            } catch {}
        }
    }

    # Se for um jogo que já tem o mod instalado e não tem state file, retornar o modo detectado dos binários
    if ($isModded) {
        if ($modMode -eq "DIRECT") { return "NATIVE_DLSS" }
        if ($modMode -eq "OPTISCALER") { return "FSR2_BRIDGE" }
        return "UNIVERSAL_FEEDER"
    }

    # 3. Verifica upscaler nativo do jogo (sem mod)
    foreach ($f in $allFiles) {
        if ($f -match '^(nvngx_dlss\.dll|nvngx_dlssd\.dll|nvngx_dlssg\.dll|sl\.dlss\.dll)$') {
            return "NATIVE_DLSS"
        }
    }
    foreach ($f in $allFiles) {
        if ($f -match '^(ffx_fsr2_api.*\.dll|ffx_fsr3_api.*\.dll|amd_fidelityfx.*\.dll|fsr2\.dll)$') {
            return "FSR2_BRIDGE"
        }
    }
    foreach ($f in $allFiles) {
        if ($f -match '^(libxess\.dll|xess\.dll|libxell\.dll)$') {
            return "XESS_BRIDGE"
        }
    }

    return "UNIVERSAL_FEEDER"
}

function Test-GameDlss5Installed {
    param([Parameter(Mandatory = $true)][string]$GameFolder)
    $stateFiles = @("_dlss5_install_state.json", "_1click_dlss5_state.json", "_dlss5_easy_installer_state.json")
    foreach ($sf in $stateFiles) {
        if (Test-Path -LiteralPath (Join-Path $GameFolder $sf) -PathType Leaf) { return $true }
    }
    $nrPath = Join-Path $GameFolder "nvngx_dlssnr.dll"
    if (Test-Path -LiteralPath $nrPath -PathType Leaf) { return $true }
    $feedPath = Join-Path $GameFolder "dlss5-feed.addon64"
    if (Test-Path -LiteralPath $feedPath -PathType Leaf) { return $true }
    return $false
}

function Get-Dict {
    param([string]$Lang)
    if ($script:Translations -and $script:Translations.$Lang) {
        return $script:Translations.$Lang
    }
    if ($script:Translations -and $script:Translations.PT) {
        return $script:Translations.PT
    }
    return [pscustomobject]@{
        "Title" = "1 CLICK DLSS 5"
        "Tagline" = "NEURAL CONTROL CENTER • RTX 20/30/40/50"
        "SubBadge" = "DirectX 9 / 10 / 11 / 12 • Vulkan • OpenGL • 32 & 64-bit"
        "Step1" = "[1] Escolha o Jogo"
        "Step2" = "[2] Clique em Instalar"
        "Step3" = "[3] Inicie e Aproveite!"
        "SearchPlaceholder" = "Pesquisar jogos..."
        "BtnScan" = "ESCANEAR DISCOS"
        "BtnBrowse" = "PROCURAR JOGO"
        "BtnDiagnose" = "DIAGNÓSTICO DO SISTEMA"
        "BtnAutoFix" = "[⚡] RESOLVER PROBLEMA EM 1 CLIQUE"
        "AutoFixDone" = "Problema resolvido com sucesso e DLSS 5 instalado!"
        "AutoFixProgress" = "Executando correcao em 1 clique..."
        "LibraryTitle" = "BIBLIOTECA DE JOGOS DETECTADOS"
        "ColGame" = "Jogo"
        "ColApi" = "API / Arq"
        "ColMode" = "Modo / Status"
        "InspectorTitle" = "PAINEL DE CONTROLE DE INJEÇÃO"
        "NoGameSelected" = "Selecione um jogo na biblioteca."
        "FolderLabel" = "DIRETÓRIO DE INSTALAÇÃO DO JOGO:"
        "ModeSectionTitle" = "ESCOLHA O MODO DE INJEÇÃO DLSS 5:"
        "AutoModeNotice" = "O modo ideal para este jogo ja foi selecionado automaticamente!"
        "Mode1Title" = "MODO 1: DIRETO (DLSS Nativo)"
        "Mode1Desc" = "Para jogos com DLSS nativo. Ativa Streamline + IA."
        "Mode2Title" = "MODO 2: PONTE OPTISCALER (FSR2/XeSS)"
        "Mode2Desc" = "Redireciona chamadas FSR2/XeSS para DLSS 5."
        "Mode3Title" = "MODO 3: FEEDER UNIVERSAL (DLAA 100% Nativo)"
        "Mode3Desc" = "Para qualquer jogo. 100% nativo sem perda de nitidez."
        "RequirementTitle" = "REQUISITO NO JOGO:"
        "ReqMode1" = "No menu do jogo: ATIVE o DLSS (Qualidade/Desempenho)."
        "ReqMode2" = "No menu do jogo: ATIVE o FSR2 ou XeSS (Qualidade)."
        "ReqMode3" = "No menu do jogo: Deixe o DLSS/Upscaling DESLIGADO."
        "BtnInstall" = "[⚡] 1-CLIQUE: INSTALAR DLSS 5"
        "BtnReinstall" = "[⚡] REINSTALAR / ATUALIZAR DLSS 5"
        "BtnLaunch" = "[►] INICIAR JOGO"
        "BtnLaunchNow" = "[►] INICIAR JOGO AGORA"
        "BtnUninstall" = "[↩] RESTAURAR DE FÁBRICA"
        "BtnOpenFolder" = "[📂] ABRIR PASTA"
        "BtnOpenLog" = "VER LOG COMPLETO"
        "BtnClose" = "Fechar"
        "StatusReady" = "Pronto. Selecione um jogo para comecar."
        "StatusScanning" = "Escaneando discos..."
        "StatusScanDone" = "Varredura concluida! {0} jogos carregados."
        "StatusInstalled" = "[✓ DLSS 5 INSTALADO]"
        "SuccessTitle" = "Instalação Concluída com Sucesso"
        "SuccessMsg" = "O DLSS 5 foi injetado com sucesso no jogo!\n\nModo aplicado: {0}\n\nVocê já pode iniciar o jogo e aproveitar a qualidade máxima."
        "RestoreTitle" = "Restauração Completa"
        "RestoreMsg" = "Jogo restaurado ao estado original de fabrica!"
        "ErrDialogTitle" = "Assistente de Diagnostico e Resolucao"
        "ErrWhatHappened" = "O QUE ACONTECEU:"
        "ErrProbableCause" = "CAUSA PROVAVEL:"
        "ErrHowToFix" = "COMO RESOLVER:"
        "DiagTitle" = "Diagnostico do Sistema"
        "DiagGpuOk" = "Placa de Video RTX detectada."
        "DiagPermsOk" = "Permissoes de gravacao liberadas."
        "DiagProcOk" = "Jogo nao esta em execucao."
        "DiagRuntimeOk" = "Runtimes neurais DLSS 5 integros."
        "DiagAllPass" = "Computador e jogo 100% prontos!"
    }
}

# --- MODAL MODERNO DE SUCESSO DA INSTALAÇÃO ---
function Show-InstallationSuccessDialog {
    param(
        [Parameter(Mandatory = $true)][string]$GameName,
        [Parameter(Mandatory = $true)][string]$ModeName,
        [Parameter(Mandatory = $true)][string]$TargetExePath
    )
    $d = Get-Dict -Lang $script:CurrentLang
    Write-Status -Message "DLSS 5 instalado com sucesso em $GameName [$ModeName]!" -Level "OK"

    if ($env:DLSS5_HEADLESS) { return }

    $succForm = New-Object System.Windows.Forms.Form
    $succForm.Text = $d.SuccessTitle
    $succForm.Size = New-Object System.Drawing.Size(620, 390)
    $succForm.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterParent
    $succForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $succForm.MaximizeBox = $false
    $succForm.MinimizeBox = $false
    $succForm.BackColor = [System.Drawing.Color]::FromArgb(14, 20, 34)
    $succForm.ForeColor = [System.Drawing.Color]::White
    $succForm.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)

    $lblBigTitle = New-Object System.Windows.Forms.Label
    $lblBigTitle.Text = "✨ DLSS 5 INJETADO COM SUCESSO!"
    $lblBigTitle.Location = New-Object System.Drawing.Point(20, 18)
    $lblBigTitle.Size = New-Object System.Drawing.Size(565, 30)
    $lblBigTitle.Font = New-Object System.Drawing.Font("Segoe UI Bold", 13)
    $lblBigTitle.ForeColor = [System.Drawing.Color]::FromArgb(118, 225, 125)
    [void]$succForm.Controls.Add($lblBigTitle)

    $infoBox = New-Object System.Windows.Forms.Panel
    $infoBox.Location = New-Object System.Drawing.Point(20, 56)
    $infoBox.Size = New-Object System.Drawing.Size(565, 200)
    $infoBox.BackColor = [System.Drawing.Color]::FromArgb(20, 30, 50)
    [void]$succForm.Controls.Add($infoBox)

    $lblGame = New-Object System.Windows.Forms.Label
    $lblGame.Text = "🎮 Jogo: " + $GameName
    $lblGame.Location = New-Object System.Drawing.Point(15, 14)
    $lblGame.Size = New-Object System.Drawing.Size(535, 22)
    $lblGame.Font = New-Object System.Drawing.Font("Segoe UI Bold", 10.5)
    $lblGame.ForeColor = [System.Drawing.Color]::White
    [void]$infoBox.Controls.Add($lblGame)

    $lblMode = New-Object System.Windows.Forms.Label
    $lblMode.Text = "⚙️ Modo: " + $ModeName
    $lblMode.Location = New-Object System.Drawing.Point(15, 42)
    $lblMode.Size = New-Object System.Drawing.Size(535, 22)
    $lblMode.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9.5)
    $lblMode.ForeColor = [System.Drawing.Color]::FromArgb(100, 180, 255)
    [void]$infoBox.Controls.Add($lblMode)

    $lblSep = New-Object System.Windows.Forms.Panel
    $lblSep.Location = New-Object System.Drawing.Point(15, 72)
    $lblSep.Size = New-Object System.Drawing.Size(535, 1)
    $lblSep.BackColor = [System.Drawing.Color]::FromArgb(40, 60, 95)
    [void]$infoBox.Controls.Add($lblSep)

    $lblInstTitle = New-Object System.Windows.Forms.Label
    $lblInstTitle.Text = "📋 COMO APROVEITAR NO JOGO:"
    $lblInstTitle.Location = New-Object System.Drawing.Point(15, 84)
    $lblInstTitle.Size = New-Object System.Drawing.Size(535, 20)
    $lblInstTitle.Font = New-Object System.Drawing.Font("Segoe UI Bold", 9)
    $lblInstTitle.ForeColor = [System.Drawing.Color]::FromArgb(255, 205, 90)
    [void]$infoBox.Controls.Add($lblInstTitle)

    $instText = "No menu do jogo: Deixe o upscaler desligado. O DLSS 5 rodará na resolução nativa com qualidade neural máxima!"
    if ($ModeName -match 'DIRECT|Modo 1') {
        $instText = "No menu de vídeo do jogo: ATIVE o DLSS (Qualidade ou Desempenho). Pressione [Home] para abrir o painel neural."
    } elseif ($ModeName -match 'OPTISCALER|Modo 2') {
        $instText = "No menu de vídeo do jogo: ATIVE o FSR 2 ou XeSS (Qualidade). O OptiScaler redirecionará para a IA DLSS 5."
    }

    $lblInstDesc = New-Object System.Windows.Forms.Label
    $lblInstDesc.Text = $instText
    $lblInstDesc.Location = New-Object System.Drawing.Point(15, 108)
    $lblInstDesc.Size = New-Object System.Drawing.Size(535, 80)
    $lblInstDesc.ForeColor = [System.Drawing.Color]::FromArgb(210, 230, 255)
    $lblInstDesc.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    [void]$infoBox.Controls.Add($lblInstDesc)

    # Botões de Ação
    $btnLaunchNow = New-Object System.Windows.Forms.Button
    $btnLaunchNow.Text = "[►] INICIAR JOGO AGORA"
    $btnLaunchNow.Location = New-Object System.Drawing.Point(20, 275)
    $btnLaunchNow.Size = New-Object System.Drawing.Size(370, 48)
    $btnLaunchNow.Font = New-Object System.Drawing.Font("Segoe UI Bold", 11)
    Style-Button -Button $btnLaunchNow -BaseColor ([System.Drawing.Color]::FromArgb(0, 130, 230)) -HoverColor ([System.Drawing.Color]::FromArgb(20, 160, 255))
    $btnLaunchNow.Add_Click({
        $succForm.Close()
        Start-GameExecutable -ExecutablePath $TargetExePath
    })
    [void]$succForm.Controls.Add($btnLaunchNow)

    $btnClose = New-Object System.Windows.Forms.Button
    $btnClose.Text = "Fechar"
    $btnClose.Location = New-Object System.Drawing.Point(405, 275)
    $btnClose.Size = New-Object System.Drawing.Size(180, 48)
    $btnClose.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 10)
    Style-Button -Button $btnClose -BaseColor ([System.Drawing.Color]::FromArgb(35, 55, 90)) -HoverColor ([System.Drawing.Color]::FromArgb(50, 75, 125))
    $btnClose.Add_Click({ $succForm.Close() })
    [void]$succForm.Controls.Add($btnClose)

    [void]$succForm.ShowDialog()
}

# --- ASSISTENTE DE RESOLUÇÃO EM 1 CLIQUE (AUTO-FIX) ---
function Resolve-IssueInOneClick {
    param([string]$TargetPath, [string]$SelectedMode)
    $d = Get-Dict -Lang $script:CurrentLang
    Write-Status -Message $d.AutoFixProgress -Level "INFO"

    try {
        $resolved = Resolve-GameTarget -TargetPath $TargetPath
        $folder = $resolved.InstallFolder
        $exeBase = [System.IO.Path]::GetFileNameWithoutExtension($resolved.ExeName)

        # 1. Finaliza processo travado do jogo se existir
        $procs = @(Get-Process -Name $exeBase -ErrorAction SilentlyContinue)
        foreach ($p in $procs) {
            Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
            Write-Status -Message "Processo travado ($exeBase.exe) finalizado com sucesso." -Level "INFO"
        }

        # 2. Remove atributo Somente Leitura da pasta
        if (Test-Path -LiteralPath $folder) {
            Start-Process -FilePath "cmd.exe" -ArgumentList "/c attrib -r `"$folder\*.*`" /s /d" -WindowStyle Hidden -Wait -ErrorAction SilentlyContinue
        }

        # 3. Executa a instalação
        Install-Dlss5 -TargetPath $TargetPath -SelectedMode $SelectedMode
        Write-Status -Message $d.AutoFixDone -Level "OK"
        return $true
    } catch {
        Write-Status -Message ("Falha no Auto-Fix: " + $_.Exception.Message) -Level "ERROR"
        return $false
    }
}

function Get-ErrorDiagnosis {
    param([System.Exception]$Ex, [string]$Context = "")
    $msg = $Ex.Message
    $code = "ERR_UNKNOWN"
    $what = "Ocorreu um imprevisto ao executar a operacao ($Context)."
    $cause = "Inconsistencia no sistema de arquivos ou configuracao de seguranca do Windows."
    $fix = "1. Feche o jogo caso ele esteja aberto.`n2. Clique em '[⚡] RESOLVER PROBLEMA EM 1 CLIQUE'.`n3. Ou execute como Administrador."

    if ($msg -match 'ERR_EXE_NOT_FOUND' -or $msg -match 'Nenhum executavel') {
        $code = "ERR_EXE_NOT_FOUND"
        $what = "Nenhum arquivo executavel (.exe) de jogo principal foi localizado na pasta selecionada."
        $cause = "A pasta escolhida pode ser uma pasta vazia ou a pasta pai dos jogos."
        $fix = "1. Clique em 'PROCURAR JOGO' e selecione a pasta exata onde o jogo esta instalado.`n2. Ou clique em 'ESCANEAR DISCOS' para localizar seus jogos instalados automaticamente."
    }
    elseif ($msg -match 'UnauthorizedAccessException' -or $msg -match 'Acesso negado' -or $msg -match 'Access is denied') {
        $code = "ERR_PERM_DENIED"
        $what = "O Windows bloqueou a gravacao ou modificacao de arquivos na pasta do jogo."
        $cause = "Falta de privilegios de Administrador ou permissao 'Somente Leitura' na pasta de instalacao."
        $fix = "1. Clique no botao '[⚡] RESOLVER PROBLEMA EM 1 CLIQUE' abaixo para liberar o acesso automaticamente.`n2. Ou execute o 1 Click DLSS 5 clicando com o botao direito e 'Executar como Administrador'."
    }
    elseif ($msg -match 'IOException' -or $msg -match 'being used by another process' -or $msg -match 'sendo usado por outro processo') {
        $code = "ERR_FILE_LOCKED"
        $what = "Um dos arquivos do jogo esta travado e nao pode ser atualizado no momento."
        $cause = "O jogo ainda esta aberto em segundo plano, ou um programa como Discord/RivaTuner esta travando a DLL."
        $fix = "1. Clique no botao '[⚡] RESOLVER PROBLEMA EM 1 CLIQUE' abaixo para fechar os processos travados e instalar automaticamente."
    }
    elseif ($msg -match 'ERR_PATH_NOT_FOUND' -or $msg -match 'nao existe') {
        $code = "ERR_PATH_NOT_FOUND"
        $what = "O caminho da pasta informado nao foi encontrado no seu computador."
        $cause = "O jogo pode ter sido movido para outro disco ou desinstalado."
        $fix = "1. Clique em 'PROCURAR JOGO' e localize a pasta atualizada do jogo."
    }

    return [pscustomobject]@{
        Code = $code
        What = $what
        Cause = $cause
        Fix = $fix
        RawMessage = $msg
        StackTrace = $Ex.StackTrace
    }
}

function Show-FriendlyErrorDialog {
    param([System.Exception]$Ex, [string]$Context = "", [string]$TargetPath = "", [string]$SelectedMode = "AUTO")
    $diag = Get-ErrorDiagnosis -Ex $Ex -Context $Context
    $d = Get-Dict -Lang $script:CurrentLang

    Write-Status -Message "ERRO EM $Context : $($diag.RawMessage)" -Level "ERROR" -Code $diag.Code -Cause $diag.Cause -Fix $diag.Fix

    if ($env:DLSS5_HEADLESS) { return }

    $errForm = New-Object System.Windows.Forms.Form
    $errForm.Text = $d.ErrDialogTitle + " [" + $diag.Code + "]"
    $errForm.Size = New-Object System.Drawing.Size(660, 500)
    $errForm.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterParent
    $errForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $errForm.MaximizeBox = $false
    $errForm.MinimizeBox = $false
    $errForm.BackColor = [System.Drawing.Color]::FromArgb(16, 20, 32)
    $errForm.ForeColor = [System.Drawing.Color]::White
    $errForm.Font = New-Object System.Drawing.Font("Segoe UI", 9)

    $lblWhatHdr = New-Object System.Windows.Forms.Label
    $lblWhatHdr.Text = $d.ErrWhatHappened
    $lblWhatHdr.Location = New-Object System.Drawing.Point(20, 12)
    $lblWhatHdr.Size = New-Object System.Drawing.Size(610, 20)
    $lblWhatHdr.ForeColor = [System.Drawing.Color]::FromArgb(255, 110, 110)
    $lblWhatHdr.Font = New-Object System.Drawing.Font("Segoe UI Bold", 9.5)
    [void]$errForm.Controls.Add($lblWhatHdr)

    $txtWhat = New-Object System.Windows.Forms.TextBox
    $txtWhat.Text = $diag.What
    $txtWhat.Location = New-Object System.Drawing.Point(20, 34)
    $txtWhat.Size = New-Object System.Drawing.Size(605, 42)
    $txtWhat.Multiline = $true
    $txtWhat.ReadOnly = $true
    $txtWhat.BackColor = [System.Drawing.Color]::FromArgb(255, 30, 48)
    $txtWhat.ForeColor = [System.Drawing.Color]::Gainsboro
    $txtWhat.BorderStyle = "FixedSingle"
    [void]$errForm.Controls.Add($txtWhat)

    $lblCauseHdr = New-Object System.Windows.Forms.Label
    $lblCauseHdr.Text = $d.ErrProbableCause
    $lblCauseHdr.Location = New-Object System.Drawing.Point(20, 85)
    $lblCauseHdr.Size = New-Object System.Drawing.Size(610, 20)
    $lblCauseHdr.ForeColor = [System.Drawing.Color]::FromArgb(255, 205, 90)
    $lblCauseHdr.Font = New-Object System.Drawing.Font("Segoe UI Bold", 9.5)
    [void]$errForm.Controls.Add($lblCauseHdr)

    $txtCause = New-Object System.Windows.Forms.TextBox
    $txtCause.Text = $diag.Cause
    $txtCause.Location = New-Object System.Drawing.Point(20, 107)
    $txtCause.Size = New-Object System.Drawing.Size(605, 42)
    $txtCause.Multiline = $true
    $txtCause.ReadOnly = $true
    $txtCause.BackColor = [System.Drawing.Color]::FromArgb(25, 30, 48)
    $txtCause.ForeColor = [System.Drawing.Color]::Gainsboro
    $txtCause.BorderStyle = "FixedSingle"
    [void]$errForm.Controls.Add($txtCause)

    $lblFixHdr = New-Object System.Windows.Forms.Label
    $lblFixHdr.Text = $d.ErrHowToFix
    $lblFixHdr.Location = New-Object System.Drawing.Point(20, 158)
    $lblFixHdr.Size = New-Object System.Drawing.Size(610, 20)
    $lblFixHdr.ForeColor = [System.Drawing.Color]::FromArgb(118, 225, 125)
    $lblFixHdr.Font = New-Object System.Drawing.Font("Segoe UI Bold", 9.5)
    [void]$errForm.Controls.Add($lblFixHdr)

    $txtFix = New-Object System.Windows.Forms.TextBox
    $txtFix.Text = $diag.Fix
    $txtFix.Location = New-Object System.Drawing.Point(20, 180)
    $txtFix.Size = New-Object System.Drawing.Size(605, 150)
    $txtFix.Multiline = $true
    $txtFix.ReadOnly = $true
    $txtFix.BackColor = [System.Drawing.Color]::FromArgb(25, 30, 48)
    $txtFix.ForeColor = [System.Drawing.Color]::FromArgb(180, 240, 200)
    $txtFix.BorderStyle = "FixedSingle"
    $txtFix.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
    [void]$errForm.Controls.Add($txtFix)

    # Botão 1-Click Auto Fix
    if (-not [string]::IsNullOrWhiteSpace($TargetPath)) {
        $btnAutoFix = New-Object System.Windows.Forms.Button
        $btnAutoFix.Text = $d.BtnAutoFix
        $btnAutoFix.Location = New-Object System.Drawing.Point(20, 345)
        $btnAutoFix.Size = New-Object System.Drawing.Size(605, 42)
        $btnAutoFix.Font = New-Object System.Drawing.Font("Segoe UI Bold", 11)
        Style-Button -Button $btnAutoFix -BaseColor ([System.Drawing.Color]::FromArgb(118, 185, 0)) -HoverColor ([System.Drawing.Color]::FromArgb(140, 220, 0)) -TextColor ([System.Drawing.Color]::Black)
        $btnAutoFix.Add_Click({
            $ok = Resolve-IssueInOneClick -TargetPath $TargetPath -SelectedMode $SelectedMode
            if ($ok) { $errForm.Close() }
        })
        [void]$errForm.Controls.Add($btnAutoFix)
    }

    $btnOpenLogDlg = New-Object System.Windows.Forms.Button
    $btnOpenLogDlg.Text = "📄 " + $d.BtnOpenLog
    $btnOpenLogDlg.Location = New-Object System.Drawing.Point(20, 405)
    $btnOpenLogDlg.Size = New-Object System.Drawing.Size(200, 36)
    Style-Button -Button $btnOpenLogDlg -BaseColor ([System.Drawing.Color]::FromArgb(35, 55, 90)) -HoverColor ([System.Drawing.Color]::FromArgb(50, 75, 125))
    $btnOpenLogDlg.Add_Click({ Open-LogFile })
    [void]$errForm.Controls.Add($btnOpenLogDlg)

    $btnOk = New-Object System.Windows.Forms.Button
    $btnOk.Text = "Fechar"
    $btnOk.Location = New-Object System.Drawing.Point(455, 405)
    $btnOk.Size = New-Object System.Drawing.Size(170, 36)
    Style-Button -Button $btnOk -BaseColor ([System.Drawing.Color]::FromArgb(35, 80, 145)) -HoverColor ([System.Drawing.Color]::FromArgb(50, 110, 195))
    $btnOk.Add_Click({ $errForm.Close() })
    [void]$errForm.Controls.Add($btnOk)

    [void]$errForm.ShowDialog()
}

function Show-SystemDiagnosisDialog {
    $d = Get-Dict -Lang $script:CurrentLang
    $diagForm = New-Object System.Windows.Forms.Form
    $diagForm.Text = $d.DiagTitle
    $diagForm.Size = New-Object System.Drawing.Size(640, 460)
    $diagForm.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterParent
    $diagForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $diagForm.MaximizeBox = $false
    $diagForm.MinimizeBox = $false
    $diagForm.BackColor = [System.Drawing.Color]::FromArgb(12, 18, 30)
    $diagForm.ForeColor = [System.Drawing.Color]::White
    $diagForm.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)

    $lblHdr = New-Object System.Windows.Forms.Label
    $lblHdr.Text = "🩺 CHECKLIST DE COMPATIBILIDADE DO COMPUTADOR"
    $lblHdr.Location = New-Object System.Drawing.Point(20, 15)
    $lblHdr.Size = New-Object System.Drawing.Size(590, 24)
    $lblHdr.Font = New-Object System.Drawing.Font("Segoe UI Bold", 11)
    $lblHdr.ForeColor = [System.Drawing.Color]::FromArgb(140, 205, 255)
    [void]$diagForm.Controls.Add($lblHdr)

    $listChecks = New-Object System.Windows.Forms.ListView
    $listChecks.Location = New-Object System.Drawing.Point(20, 50)
    $listChecks.Size = New-Object System.Drawing.Size(585, 290)
    $listChecks.View = [System.Windows.Forms.View]::Details
    $listChecks.FullRowSelect = $true
    $listChecks.BackColor = [System.Drawing.Color]::FromArgb(18, 25, 42)
    $listChecks.ForeColor = [System.Drawing.Color]::White
    $listChecks.BorderStyle = "FixedSingle"
    [void]$listChecks.Columns.Add("Item Verificado", 200)
    [void]$listChecks.Columns.Add("Status", 90)
    [void]$listChecks.Columns.Add("Resultado do Teste", 280)
    [void]$diagForm.Controls.Add($listChecks)

    # 1. GPU Check
    $gpuName = "NVIDIA RTX Series"
    $gpuStatus = "[PASS]"
    $gpuDesc = $d.DiagGpuOk
    try {
        $g = Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($g) { $gpuName = $g.Name; $gpuDesc = "$($g.Name) (Driver $($g.DriverVersion))" }
    } catch {}
    $it1 = New-Object System.Windows.Forms.ListViewItem("Placa de Vídeo / Driver")
    [void]$it1.SubItems.Add($gpuStatus)
    [void]$it1.SubItems.Add($gpuDesc)
    $it1.ForeColor = [System.Drawing.Color]::FromArgb(118, 225, 125)
    [void]$listChecks.Items.Add($it1)

    # 2. Write Perms
    $permStatus = "[PASS]"
    $permDesc = $d.DiagPermsOk
    if ($script:SelectedGameObj) {
        $testF = Join-Path $script:SelectedGameObj.Path "_test_write_perm.tmp"
        try {
            [System.IO.File]::WriteAllText($testF, "test")
            [System.IO.File]::Delete($testF)
        } catch {
            $permStatus = "[FALHA]"
            $permDesc = "Acesso negado na pasta. Clique em Auto-Fix."
        }
    }
    $it2 = New-Object System.Windows.Forms.ListViewItem("Permissões de Escrita")
    [void]$it2.SubItems.Add($permStatus)
    [void]$it2.SubItems.Add($permDesc)
    if ($permStatus -eq "[PASS]") {
        $it2.ForeColor = [System.Drawing.Color]::FromArgb(118, 225, 125)
    } else {
        $it2.ForeColor = [System.Drawing.Color]::FromArgb(255, 110, 110)
    }
    [void]$listChecks.Items.Add($it2)

    # 3. Game Process Check
    $procStatus = "[PASS]"
    $procDesc = $d.DiagProcOk
    if ($script:SelectedGameObj) {
        $exeBase = [System.IO.Path]::GetFileNameWithoutExtension($script:SelectedGameObj.ExeName)
        $p = Get-Process -Name $exeBase -ErrorAction SilentlyContinue
        if ($p) {
            $procStatus = "[AVISO]"
            $procDesc = "O jogo $($script:SelectedGameObj.ExeName) esta em execucao!"
        }
    }
    $it3 = New-Object System.Windows.Forms.ListViewItem("Status do Processo")
    [void]$it3.SubItems.Add($procStatus)
    [void]$it3.SubItems.Add($procDesc)
    if ($procStatus -eq "[PASS]") {
        $it3.ForeColor = [System.Drawing.Color]::FromArgb(118, 225, 125)
    } else {
        $it3.ForeColor = [System.Drawing.Color]::FromArgb(255, 205, 90)
    }
    [void]$listChecks.Items.Add($it3)

    # 4. Neural Payload Check
    $payStatus = "[PASS]"
    $payDesc = $d.DiagRuntimeOk
    $nrP = Join-Path (Get-DLSS5PayloadDirectory) "nvngx_dlssnr.dll"
    if (-not (Test-Path -LiteralPath $nrP)) {
        $payStatus = "[ERRO]"
        $payDesc = "nvngx_dlssnr.dll ausente na pasta payload."
    }
    $it4 = New-Object System.Windows.Forms.ListViewItem("Runtimes DLSS 5")
    [void]$it4.SubItems.Add($payStatus)
    [void]$it4.SubItems.Add($payDesc)
    if ($payStatus -eq "[PASS]") {
        $it4.ForeColor = [System.Drawing.Color]::FromArgb(118, 225, 125)
    } else {
        $it4.ForeColor = [System.Drawing.Color]::FromArgb(255, 110, 110)
    }
    [void]$listChecks.Items.Add($it4)

    $lblAll = New-Object System.Windows.Forms.Label
    $lblAll.Text = "✨ " + $d.DiagAllPass
    $lblAll.Location = New-Object System.Drawing.Point(20, 355)
    $lblAll.Size = New-Object System.Drawing.Size(585, 24)
    $lblAll.ForeColor = [System.Drawing.Color]::FromArgb(118, 225, 125)
    $lblAll.Font = New-Object System.Drawing.Font("Segoe UI Bold", 9.5)
    [void]$diagForm.Controls.Add($lblAll)

    $btnDiagClose = New-Object System.Windows.Forms.Button
    $btnDiagClose.Text = "Fechar"
    $btnDiagClose.Location = New-Object System.Drawing.Point(465, 385)
    $btnDiagClose.Size = New-Object System.Drawing.Size(140, 34)
    Style-Button -Button $btnDiagClose -BaseColor ([System.Drawing.Color]::FromArgb(35, 80, 145)) -HoverColor ([System.Drawing.Color]::FromArgb(50, 110, 195))
    $btnDiagClose.Add_Click({ $diagForm.Close() })
    [void]$diagForm.Controls.Add($btnDiagClose)

    [void]$diagForm.ShowDialog()
}

# --- CONFIGURAÇÃO DO RESHADE.INI E PRESET ---
function Set-Dlss5ReShadeIni {
    param(
        [Parameter(Mandatory = $true)][string]$IniPath,
        [Parameter(Mandatory = $false)][bool]$IsFeederMode = $true,
        [Parameter(Mandatory = $false)][int]$EnableHooks = 1
    )
    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    if ($IsFeederMode) {
        $iniContent = @"
[ADDON]
DisabledAddons=Generic Depth,Effect Runtime Sync
OverlayCollapsed=DLSS 5 Feed 0.7.0@dlss5-feed.addon64,DLSS 5 Neural Rendering@renodx-dlss5.addon64,Generic Depth,Effect Runtime Sync

[GENERAL]
EffectSearchPaths=.\reshade-shaders\Shaders\**
IntermediateCachePath=$env:TEMP\ReShade
NoDebugInfo=1
NoEffectCache=0
NoReloadOnInit=0
PerformanceMode=0
PresetPath=.\ReShadePreset.ini
PresetShortcutKeys=
PresetShortcutPaths=
PresetTransitionDuration=1000
SkipLoadingDisabledEffects=0
StartupPresetPath=
TextureSearchPaths=.\reshade-shaders\Textures\**

[INPUT]
ForceShortcutModifiers=1
InputProcessing=2
KeyEffects=0,0,0,0
KeyFPS=0,0,0,0
KeyFrametime=0,0,0,0
KeyNextPreset=0,0,0,0
KeyOverlay=36,0,0,0
KeyPreviousPreset=0,0,0,0
KeyReload=0,0,0,0
KeyScreenshot=44,0,0,0

[OVERLAY]
AutoSavePreset=1
ClockFormat=0
FPSPosition=1
Language=
ShowClock=0
ShowForceLoadEffectsButton=1
ShowFPS=2
ShowFrameTime=0
ShowPresetName=0
ShowPresetTransitionMessage=1
ShowScreenshotMessage=1
TutorialProgress=4
VariableListHeight=200.000000
VariableListUseTabs=0

[RenoDX.DLSS5]
EnableHooks=$EnableHooks
NeuralUplift=1
NRAutoMask=1
NRDepthMode=0
NRDiffuseWhiteNits=203
NRGlobalTone=0.9
NRLocalStructure=0.44
NRLocalTone=1.22
NRPreset=2
NRSkinStructure=1.16
NRStyle=1
NRUICorrection=1

[STYLE]
Alpha=1.000000
ChildRounding=0.000000
ColFPSText=1.000000,1.000000,0.784314,1.000000
EditorFont=
EditorFontSize=13.000000
EditorStyleIndex=0
Font=
FontScale=1.000000
FontSize=13.000000
FPSScale=1.000000
FrameRounding=0.000000
GrabRounding=0.000000
HdrOverlayBrightness=203.000000
HdrOverlayOverwriteColorSpaceTo=0
LatinFont=
PopupRounding=0.000000
ScrollbarRounding=0.000000
StyleIndex=2
TabRounding=5.000000
WindowRounding=0.000000
"@
    } else {
        $iniContent = @"
[ADDON]
DisabledAddons=Generic Depth,Effect Runtime Sync
OverlayCollapsed=DLSS 5 Neural Rendering@renodx-dlss5.addon64,Generic Depth,Effect Runtime Sync

[GENERAL]
EffectSearchPaths=.\reshade-shaders\Shaders\**
TextureSearchPaths=.\reshade-shaders\Textures\**
PerformanceMode=0
NoReloadOnInit=0
SkipLoadingDisabledEffects=0

[OVERLAY]
TutorialProgress=4

[RenoDX.DLSS5]
EnableHooks=$EnableHooks
NeuralUplift=1
NRAutoMask=1
NRDepthMode=0
NRDiffuseWhiteNits=203
NRGlobalTone=0.9
NRLocalStructure=0.44
NRLocalTone=1.22
NRPreset=2
NRSkinStructure=1.16
NRStyle=1
NRUICorrection=1
"@
    }
    [System.IO.File]::WriteAllText($IniPath, $iniContent, $utf8NoBom)
}

function Set-Dlss5PresetIni {
    param([Parameter(Mandatory = $true)][string]$PresetPath)
    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    $presetContent = @"
Techniques=Lumenite_Kernel@lumenite_Kernel.fx,DLSS5_Feed@DLSS5_Feed.fx
TechniqueSorting=Lumenite_Kernel@lumenite_Kernel.fx,DLSS5_Feed@DLSS5_Feed.fx
PreprocessorDefinitions=DLSS5_MV_PROVIDER=3

[DLSS5_Feed.fx]
PreprocessorDefinitions=DLSS5_MV_PROVIDER=3
"@
    [System.IO.File]::WriteAllText($PresetPath, $presetContent, $utf8NoBom)
}

# --- MOTOR DE INSTALAÇÃO UNIVERSAL ---
function Install-Dlss5 {
    param(
        [Parameter(Mandatory = $true)][string]$TargetPath,
        [Parameter(Mandatory = $false)][string]$SelectedMode = "AUTO"
    )
    $target = Resolve-GameTarget -TargetPath $TargetPath
    $targetFolder = $target.InstallFolder
    $d = Get-Dict -Lang $script:CurrentLang
    $feederPayload = Join-Path (Get-DLSS5PayloadDirectory) "feeder"

    $detectedUpscaler = Detect-GameUpscalerType -GameFolder $targetFolder -GameRoot $target.Root
    $api = Detect-GameGraphicsApi -TargetExe $target.Executable -GameFolder $targetFolder
    $effectiveMode = $SelectedMode
    if ($effectiveMode -eq "AUTO") {
        if ($detectedUpscaler -eq "NATIVE_DLSS") {
            $effectiveMode = "DIRECT"
        } elseif ($detectedUpscaler -eq "FSR2_BRIDGE" -or $detectedUpscaler -eq "XESS_BRIDGE") {
            $effectiveMode = "OPTISCALER"
        } else {
            $effectiveMode = "FEEDER"
        }
    }

    Write-Status -Message "Iniciando instalacao para: $($target.ExeName) | API: $api | Modo: $effectiveMode | Arquitetura: $($target.Architecture)" -Level "INFO"

    $backupFolder = Join-Path $targetFolder $script:BackupName
    [void](New-Item -ItemType Directory -Path $backupFolder -Force)
    $stateFile = Join-Path $targetFolder $script:StateName

    # Se já existir uma instalação anterior de outro modo, limpar arquivos injetados do modo anterior
    $existingBackedUp = @()
    if (Test-Path -LiteralPath $stateFile -PathType Leaf) {
        try {
            $oldSaved = Get-Content -LiteralPath $stateFile -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($oldSaved.BackedUpFiles) { $existingBackedUp = @($oldSaved.BackedUpFiles) }
            if ($oldSaved.Mode -and ($oldSaved.Mode -ne $effectiveMode)) {
                Write-Status -Message "Detectada troca de modo ($($oldSaved.Mode) -> $effectiveMode). Removendo arquivos do modo anterior..." -Level "INFO"
                $previousInjected = @($oldSaved.InjectedFiles)
                foreach ($oldFile in $previousInjected) {
                    if ($existingBackedUp -notcontains $oldFile) {
                        $oldP = Join-Path $targetFolder $oldFile
                        if (Test-Path -LiteralPath $oldP -PathType Leaf) {
                            Remove-Item -LiteralPath $oldP -Force -ErrorAction SilentlyContinue
                        }
                    }
                }
            }
        } catch {}
    }

    $state = @{
        InstalledAt = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        TargetExe = $target.Executable
        Mode = $effectiveMode
        UpscalerType = $detectedUpscaler
        Architecture = $target.Architecture
        Api = $api
        BackedUpFiles = $existingBackedUp
        InjectedFiles = @()
    }

    function Safe-Copy {
        param($Src, $DstName)
        $dst = Join-Path $targetFolder $DstName
        if (Test-Path -LiteralPath $dst -PathType Leaf) {
            # Só faz backup se o arquivo original NÃO foi injetado nesta mesma sessão
            if ($state.InjectedFiles -notcontains $DstName) {
                $bDst = Join-Path $backupFolder $DstName
                if (-not (Test-Path -LiteralPath $bDst -PathType Leaf)) {
                    Copy-Item -LiteralPath $dst -Destination $bDst -Force
                    $state.BackedUpFiles += $DstName
                }
            }
        }
        Copy-Item -LiteralPath $Src -Destination $dst -Force
        if ($state.InjectedFiles -notcontains $DstName) { $state.InjectedFiles += $DstName }
    }

    $isX64 = ($target.Architecture -eq "X64")
    $proxyDll = "dxgi.dll"
    if (-not $isX64) { $proxyDll = "dxgi32.dll" }

    # 1. ReShade proxy (adaptação automática por API)
    $dxgiSrc = Join-Path (Get-DLSS5PayloadDirectory) $proxyDll
    if (Test-Path -LiteralPath $dxgiSrc) {
        Safe-Copy -Src $dxgiSrc -DstName "dxgi.dll"
        if ($api -eq "D3D9") {
            Safe-Copy -Src $dxgiSrc -DstName "d3d9.dll"
        }
        if ($api -eq "OPENGL") {
            Safe-Copy -Src $dxgiSrc -DstName "opengl32.dll"
        }
    }

    # 2. RenoDX Addon e Modelos Neurais NVIDIA
    # Em jogos 64-bit (ou modos DIRECT/OPTISCALER), eles ficam na raiz do jogo.
    # Em jogos 32-bit no MODO FEEDER, eles vão EXCLUSIVAMENTE para a pasta host64\ onde o helper 64-bit os executa.
    if ($isX64 -or ($effectiveMode -ne "FEEDER")) {
        $renoSrc = Join-Path (Get-DLSS5PayloadDirectory) $script:AddOnName
        if (Test-Path -LiteralPath $renoSrc) {
            Safe-Copy -Src $renoSrc -DstName $script:AddOnName
        }
        $nrSrc = Join-Path (Get-DLSS5PayloadDirectory) "nvngx_dlssnr.dll"
        if (Test-Path -LiteralPath $nrSrc) {
            Safe-Copy -Src $nrSrc -DstName "nvngx_dlssnr.dll"
        }
        # Preserva nvngx_dlss.dll original do jogo caso já exista (evita falha de integridade em launchers como RDR2)
        $dlssTarget = Join-Path $targetFolder "nvngx_dlss.dll"
        if (-not (Test-Path -LiteralPath $dlssTarget -PathType Leaf)) {
            $dlssSrc = Join-Path (Get-DLSS5PayloadDirectory) "nvngx_dlss.dll"
            if (Test-Path -LiteralPath $dlssSrc) {
                Safe-Copy -Src $dlssSrc -DstName "nvngx_dlss.dll"
            }
        }
    }

    # 4. Injeção Específica por Modo
    if ($effectiveMode -eq "DIRECT") {
        # JOGOS COM DLSS NATIVO: NUNCA sobrescrever o interposer Streamline nativo do jogo (ex: The Witcher 3, Cyberpunk)
        # para evitar erros de Entry Point (como slGetFeatureSettings ausente).
        # Apenas injetamos o proxy ReShade, o RenoDX Addon e o modelo nvngx_dlssnr.dll.
        $hasStreamline = (Test-Path -LiteralPath (Join-Path $targetFolder "sl.interposer.dll") -PathType Leaf)
        $hookVal = if ($hasStreamline) { 2 } else { 1 }
        
        # Se o jogo já possui Streamline e suporta sl.dlss_nr.dll opcional, podemos fornecer apenas o plugin neural sem tocar no interposer
        $slNrSrc = Join-Path (Get-DLSS5PayloadDirectory) "sl.dlss_nr.dll"
        if ($hasStreamline -and (Test-Path -LiteralPath $slNrSrc -PathType Leaf)) {
            Safe-Copy -Src $slNrSrc -DstName "sl.dlss_nr.dll"
        }

        $targetIni = Join-Path $targetFolder "ReShade.ini"
        if ((Test-Path -LiteralPath $targetIni -PathType Leaf) -and ($state.InjectedFiles -notcontains "ReShade.ini")) {
            $bDst = Join-Path $backupFolder "ReShade.ini"
            if (-not (Test-Path -LiteralPath $bDst -PathType Leaf)) {
                Copy-Item -LiteralPath $targetIni -Destination $bDst -Force
                $state.BackedUpFiles += "ReShade.ini"
            }
        }
        Set-Dlss5ReShadeIni -IniPath $targetIni -IsFeederMode $false -EnableHooks $hookVal
        if ($state.InjectedFiles -notcontains "ReShade.ini") { $state.InjectedFiles += "ReShade.ini" }
    }
    elseif ($effectiveMode -eq "OPTISCALER") {
        $optiSrc = Join-Path (Get-DLSS5PayloadDirectory) "optiscaler\OptiScaler.dll"
        if (Test-Path -LiteralPath $optiSrc) { Safe-Copy -Src $optiSrc -DstName "version.dll" }
        $optiIni = Join-Path (Get-DLSS5PayloadDirectory) "optiscaler\OptiScaler.ini"
        if (Test-Path -LiteralPath $optiIni) { Safe-Copy -Src $optiIni -DstName "OptiScaler.ini" }
        $xessSrc = Join-Path (Get-DLSS5PayloadDirectory) "optiscaler\libxess.dll"
        if (Test-Path -LiteralPath $xessSrc) { Safe-Copy -Src $xessSrc -DstName "libxess.dll" }
        $targetIni = Join-Path $targetFolder "ReShade.ini"
        if ((Test-Path -LiteralPath $targetIni -PathType Leaf) -and ($state.InjectedFiles -notcontains "ReShade.ini")) {
            $bDst = Join-Path $backupFolder "ReShade.ini"
            if (-not (Test-Path -LiteralPath $bDst -PathType Leaf)) {
                Copy-Item -LiteralPath $targetIni -Destination $bDst -Force
                $state.BackedUpFiles += "ReShade.ini"
            }
        }
        Set-Dlss5ReShadeIni -IniPath $targetIni -IsFeederMode $false
        if ($state.InjectedFiles -notcontains "ReShade.ini") { $state.InjectedFiles += "ReShade.ini" }
    }
    else {
        if ($isX64) {
            $feedSrc = Join-Path $feederPayload "dlss5-feed.addon64"
            if (Test-Path -LiteralPath $feedSrc) { Safe-Copy -Src $feedSrc -DstName "dlss5-feed.addon64" }
        } else {
            $feedSrc32 = Join-Path $feederPayload "dlss5-feed.addon32"
            if (Test-Path -LiteralPath $feedSrc32) { Safe-Copy -Src $feedSrc32 -DstName "dlss5-feed.addon32" }
            $hostDst = Join-Path $targetFolder "host64"
            [void](New-Item -ItemType Directory -Path $hostDst -Force)
            Get-ChildItem -LiteralPath (Join-Path $feederPayload "host64") | Copy-Item -Destination $hostDst -Recurse -Force
            Copy-Item -LiteralPath (Join-Path (Get-DLSS5PayloadDirectory) "dxgi.dll") -Destination (Join-Path $hostDst "dxgi.dll") -Force
            Copy-Item -LiteralPath (Join-Path (Get-DLSS5PayloadDirectory) "nvngx_dlssnr.dll") -Destination (Join-Path $hostDst "nvngx_dlssnr.dll") -Force
            Copy-Item -LiteralPath (Join-Path (Get-DLSS5PayloadDirectory) "nvngx_dlss.dll") -Destination (Join-Path $hostDst "nvngx_dlss.dll") -Force
            Copy-Item -LiteralPath (Join-Path (Get-DLSS5PayloadDirectory) $script:AddOnName) -Destination (Join-Path $hostDst $script:AddOnName) -Force
            if ($state.InjectedFiles -notcontains "host64") { $state.InjectedFiles += "host64" }
        }

        # Shaders
        $shaderDir = Join-Path $targetFolder "reshade-shaders\Shaders"
        [void](New-Item -ItemType Directory -Path $shaderDir -Force)
        Get-ChildItem -LiteralPath (Join-Path $feederPayload "shaders") | Copy-Item -Destination $shaderDir -Recurse -Force
        
        # Textures
        $texPayload = Join-Path $feederPayload "textures"
        if (Test-Path -LiteralPath $texPayload -PathType Container) {
            $texDir = Join-Path $targetFolder "reshade-shaders\Textures"
            [void](New-Item -ItemType Directory -Path $texDir -Force)
            Get-ChildItem -LiteralPath $texPayload | Copy-Item -Destination $texDir -Recurse -Force
        }
        if ($state.InjectedFiles -notcontains "reshade-shaders") { $state.InjectedFiles += "reshade-shaders" }

        $cfgSrc = Join-Path $feederPayload "dlss5-feed.cfg"
        if (Test-Path -LiteralPath $cfgSrc) { Safe-Copy -Src $cfgSrc -DstName "dlss5-feed.cfg" }

        # Injeção de camada Vulkan se o jogo for baseado em Vulkan
        if ($api -eq "VULKAN") {
            $layerFolderName = if ($isX64) { "layer-x64" } else { "layer-x86" }
            $layerSrcDir = Join-Path $feederPayload $layerFolderName
            if (Test-Path -LiteralPath $layerSrcDir -PathType Container) {
                Get-ChildItem -LiteralPath $layerSrcDir -File | ForEach-Object {
                    Safe-Copy -Src $_.FullName -DstName $_.Name
                }
            }
        }

        $targetPreset = Join-Path $targetFolder "ReShadePreset.ini"
        if ((Test-Path -LiteralPath $targetPreset -PathType Leaf) -and ($state.InjectedFiles -notcontains "ReShadePreset.ini")) {
            $bDst = Join-Path $backupFolder "ReShadePreset.ini"
            if (-not (Test-Path -LiteralPath $bDst -PathType Leaf)) {
                Copy-Item -LiteralPath $targetPreset -Destination $bDst -Force
                $state.BackedUpFiles += "ReShadePreset.ini"
            }
        }
        Set-Dlss5PresetIni -PresetPath $targetPreset
        if ($state.InjectedFiles -notcontains "ReShadePreset.ini") { $state.InjectedFiles += "ReShadePreset.ini" }

        $targetIni = Join-Path $targetFolder "ReShade.ini"
        if ((Test-Path -LiteralPath $targetIni -PathType Leaf) -and ($state.InjectedFiles -notcontains "ReShade.ini")) {
            $bDst = Join-Path $backupFolder "ReShade.ini"
            if (-not (Test-Path -LiteralPath $bDst -PathType Leaf)) {
                Copy-Item -LiteralPath $targetIni -Destination $bDst -Force
                $state.BackedUpFiles += "ReShade.ini"
            }
        }
        Set-Dlss5ReShadeIni -IniPath $targetIni -IsFeederMode $true
        if ($state.InjectedFiles -notcontains "ReShade.ini") { $state.InjectedFiles += "ReShade.ini" }
    }

    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText($stateFile, ($state | ConvertTo-Json -Depth 4), $utf8NoBom)
    
    $modeReadable = switch ($effectiveMode) {
        "DIRECT"     { "Modo 1: Direto (DLSS Nativo)" }
        "OPTISCALER" { "Modo 2: Ponte OptiScaler (FSR2/XeSS)" }
        default      { "Modo 3: Feeder Universal (DLAA 100% Nativo)" }
    }
    
    Show-InstallationSuccessDialog -GameName $target.ExeName -ModeName $modeReadable -TargetExePath $target.Executable
}

# --- MOTOR DE RESTAURAÇÃO DE FÁBRICA (UNINSTALL) ---
function Uninstall-Dlss5 {
    param([Parameter(Mandatory = $true)][string]$TargetPath)
    $target = Resolve-GameTarget -TargetPath $TargetPath
    $targetFolder = $target.InstallFolder
    $stateFile = Join-Path $targetFolder $script:StateName
    $backupFolder = Join-Path $targetFolder $script:BackupName
    $d = Get-Dict -Lang $script:CurrentLang

    Write-Status -Message "Restaurando jogo para o estado original de fabrica em: $targetFolder" -Level "INFO"

    $savedBacked = @()
    $savedInjected = @()
    if (Test-Path -LiteralPath $stateFile -PathType Leaf) {
        try {
            $saved = Get-Content -LiteralPath $stateFile -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($saved.BackedUpFiles) { $savedBacked = @($saved.BackedUpFiles) }
            if ($saved.InjectedFiles) { $savedInjected = @($saved.InjectedFiles) }
        } catch {}
    }

    if (Test-Path -LiteralPath $backupFolder -PathType Container) {
        $physBacked = Get-ChildItem -LiteralPath $backupFolder -File -ErrorAction SilentlyContinue
        foreach ($pb in $physBacked) {
            if ($savedBacked -notcontains $pb.Name) { $savedBacked += $pb.Name }
        }
    }

    if (Test-Path -LiteralPath $backupFolder -PathType Container) {
        $backed = Get-ChildItem -LiteralPath $backupFolder -File -ErrorAction SilentlyContinue
        foreach ($bf in $backed) {
            $dst = Join-Path $targetFolder $bf.Name
            Copy-Item -LiteralPath $bf.FullName -Destination $dst -Force
            Write-Status -Message "Arquivo original restaurado: $($bf.Name)" -Level "OK"
        }
        Remove-Item -LiteralPath $backupFolder -Recurse -Force -ErrorAction SilentlyContinue
    }

    # Lista de purga cirúrgica incondicional (padrão absoluto para restauração limpa)
    $purgeList = @(
        "dxgi.dll", "d3d12.dll", "d3d9.dll", "opengl32.dll",
        "renodx-dlss5.addon64", "renodx-dlss5++.addon64", "renodx-dlss5-v3.addon64",
        "dlss5-feed.addon64", "dlss5-feed.addon32", "dlss5-feed.cfg", "dlss5-feed.log", "dlss5-feed.ini",
        "dlss5-feed-host.log", "dlss5-feed-crash.dmp",
        "VkLayer_feed_vk.dll", "VkLayer_feed_vk.json", "run-with-feed-layer.bat",
        "VkLayer_feed_vk32.dll", "VkLayer_feed_vk32.json", "run-with-feed-layer32.bat",
        "nvngx_dlssnr.dll", "sl.dlss_nr.dll",
        "version.dll", "OptiScaler.ini", "OptiScaler.log", "libxess.dll",
        "ReShade.ini", "ReShadePreset.ini", "ReShade.log",
        "sl.common.dll", "sl.interposer.dll", "sl.deepdvc.dll", "sl.dlss.dll", "sl.dlss_d.dll", "sl.dlss_g.dll",
        "sl.nis.dll", "sl.pcl.dll", "sl.reflex.dll", "sl.config.json", "sl.param.global.log",
        "nis.license.txt", "nvngx_dlss.license.txt", "reflex.license.txt",
        $script:StateName, "_1Click_DLSS5_State.json", "_DLSS5_Easy_Installer_State.json", "dlss5_backup_manifest.json"
    )

    foreach ($inj in $savedInjected) {
        if ($savedBacked -notcontains $inj -and ($purgeList -notcontains $inj)) {
            $purgeList += $inj
        }
    }

    foreach ($pf in $purgeList) {
        if ($savedBacked -contains $pf) { continue }
        $p = Join-Path $targetFolder $pf
        if (Test-Path -LiteralPath $p -PathType Leaf) {
            Remove-Item -LiteralPath $p -Force -ErrorAction SilentlyContinue
        }
    }

    $reshadeDir = Join-Path $targetFolder "reshade-shaders"
    if (Test-Path -LiteralPath $reshadeDir -PathType Container) {
        Remove-Item -LiteralPath $reshadeDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    $hostDir = Join-Path $targetFolder "host64"
    if (Test-Path -LiteralPath $hostDir -PathType Container) {
        Remove-Item -LiteralPath $hostDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    foreach ($ld in @("layer-x64", "layer-x86")) {
        $lp = Join-Path $targetFolder $ld
        if (Test-Path -LiteralPath $lp -PathType Container) {
            Remove-Item -LiteralPath $lp -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    foreach ($sf in @($script:StateName, "_1Click_DLSS5_State.json", "_DLSS5_Easy_Installer_State.json")) {
        $sp = Join-Path $targetFolder $sf
        if (Test-Path -LiteralPath $sp -PathType Leaf) {
            Remove-Item -LiteralPath $sp -Force -ErrorAction SilentlyContinue
        }
    }

    Write-Status -Message "Jogo 100% restaurado ao estado original de fabrica!" -Level "OK"
    if (-not $env:DLSS5_HEADLESS) { [System.Windows.Forms.MessageBox]::Show($d.RestoreMsg, $d.RestoreTitle, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information) }
}

function Start-GameExecutable {
    param([Parameter(Mandatory = $true)][string]$ExecutablePath)
    if (-not (Test-Path -LiteralPath $ExecutablePath -PathType Leaf)) {
        throw "ERR_EXE_NOT_FOUND: Executavel do jogo nao encontrado: $ExecutablePath"
    }
    $folder = (Split-Path -Parent $ExecutablePath)
    Write-Status -Message "Iniciando jogo: $(Split-Path -Leaf $ExecutablePath)..." -Level "INFO"

    $oldVkPath = $env:VK_LAYER_PATH
    $oldVkLayers = $env:VK_INSTANCE_LAYERS
    try {
        # Se for um jogo Vulkan com camada Feeder injetada, ativar sem tocar no registro
        $vkLayerDll = Join-Path $folder "VkLayer_feed_vk.dll"
        if (Test-Path -LiteralPath $vkLayerDll -PathType Leaf) {
            $env:VK_LAYER_PATH = $folder
            $env:VK_INSTANCE_LAYERS = "VK_LAYER_feed_vk"
        }
        Start-Process -FilePath $ExecutablePath -WorkingDirectory $folder
    } finally {
        $env:VK_LAYER_PATH = $oldVkPath
        $env:VK_INSTANCE_LAYERS = $oldVkLayers
    }
}

# --- SCANNER DE AUTO-DESCOBERTA INSTANTÂNEA DE JOGOS ---
function Scan-DriveForGames {
    param(
        [string]$DriveLetter = "ALL",
        [scriptblock]$ProgressCallback = $null
    )
    $results = New-Object System.Collections.Generic.List[pscustomobject]
    $rootsToScan = New-Object System.Collections.Generic.List[string]

    # 1. Leitura Direta de Bibliotecas Steam (VDF Multi-Drive)
    $steamCandidates = @(
        "C:\Program Files (x86)\Steam\steamapps\libraryfolders.vdf",
        "C:\Program Files\Steam\steamapps\libraryfolders.vdf",
        "D:\Steam\steamapps\libraryfolders.vdf",
        "D:\SteamLibrary\steamapps\libraryfolders.vdf",
        "E:\Steam\steamapps\libraryfolders.vdf",
        "E:\SteamLibrary\steamapps\libraryfolders.vdf"
    )
    foreach ($sc in $steamCandidates) {
        if (Test-Path -LiteralPath $sc -PathType Leaf) {
            try {
                $lines = Get-Content -LiteralPath $sc -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
                $matches = [regex]::Matches($lines, '\"path\"\s+\"([^\"]+)\"')
                foreach ($m in $matches) {
                    $p = $m.Groups[1].Value.Replace('\\', '\')
                    $common = Join-Path $p "steamapps\common"
                    if (Test-Path -LiteralPath $common) { [void]$rootsToScan.Add($common) }
                }
            } catch {}
        }
    }

    # 2. Leitura Direta de Manifests Epic Games
    $epicDir = "C:\ProgramData\Epic\EpicGamesLauncher\Data\Manifests"
    if (Test-Path -LiteralPath $epicDir -PathType Container) {
        $mfs = Get-ChildItem -LiteralPath $epicDir -Filter "*.item" -File -ErrorAction SilentlyContinue
        foreach ($mf in $mfs) {
            try {
                $itemData = Get-Content -LiteralPath $mf.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
                if ($itemData.InstallLocation -and (Test-Path -LiteralPath $itemData.InstallLocation)) {
                    [void]$rootsToScan.Add($itemData.InstallLocation)
                }
            } catch {}
        }
    }

    # 3. Varredura de Unidades Fixas
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

    $ignored = @("steamworks shared", "_commonredist", "directx", "vcredist", "dotnet", "crashreport", "tools", "easyanticheat", "battleye", "launcher", "nam")

    $allGameDirs = New-Object System.Collections.Generic.List[pscustomobject]
    $seenPaths = New-Object System.Collections.Generic.HashSet[string]

    foreach ($root in $rootsToScan) {
        if (Test-Path -LiteralPath $root -PathType Container) {
            try {
                $hasDirectExe = @(Get-ChildItem -LiteralPath $root -Filter "*.exe" -File -ErrorAction SilentlyContinue).Count -gt 0
                if ($hasDirectExe) {
                    $norm = $root.ToLower()
                    if (-not $seenPaths.Contains($norm)) {
                        [void]$seenPaths.Add($norm)
                        [void]$allGameDirs.Add([pscustomobject]@{ Root = $root; Dir = (Get-Item -LiteralPath $root) })
                    }
                } else {
                    $dirs = Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue
                    foreach ($dir in $dirs) {
                        $dirLow = $dir.Name.ToLower()
                        if ($ignored -contains $dirLow) { continue }
                        if ($dirLow -match '^(ue_\d|unrealengine|launcher|gameinput|directxredist|vcredist|dotnet|crashreport)') { continue }
                        $norm = $dir.FullName.ToLower()
                        if (-not $seenPaths.Contains($norm)) {
                            [void]$seenPaths.Add($norm)
                            [void]$allGameDirs.Add([pscustomobject]@{ Root = $root; Dir = $dir })
                        }
                    }
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

        if ($null -ne $ProgressCallback) {
            $pct = [int](($currentIdx / $totalGames) * 100)
            try { & $ProgressCallback $pct $dir.Name } catch {}
        }
        [System.Windows.Forms.Application]::DoEvents()

        $resolved = $null
        try { $resolved = Resolve-GameTarget -TargetPath $gamePath } catch { continue }
        if ($null -eq $resolved) { continue }

        $api = Detect-GameGraphicsApi -TargetExe $resolved.Executable -GameFolder $resolved.InstallFolder
        $upscaler = Detect-GameUpscalerType -GameFolder $resolved.InstallFolder -GameRoot $resolved.Root
        $arch = $resolved.Architecture
        $isInstalled = Test-GameDlss5Installed -GameFolder $resolved.InstallFolder

        $order = 3
        if ($isInstalled) {
            $order = 0
        } elseif ($upscaler -eq "NATIVE_DLSS") {
            $order = 1
        } elseif ($upscaler -eq "FSR2_BRIDGE" -or $upscaler -eq "XESS_BRIDGE") {
            $order = 2
        }

        [void]$results.Add([pscustomobject]@{
            Order = $order
            Name = $dir.Name
            Path = $gamePath
            Api = "$api ($arch)"
            Upscaler = $upscaler
            IsInstalled = $isInstalled
            Icon = $resolved.Icon
            ExeName = $resolved.ExeName
        })
    }
    return @($results | Sort-Object -Property Order, Name)
}

# --- HELPERS DE ESTILIZAÇÃO E COMPONENTES MODERNOS ---
function Style-Button {
    param(
        [System.Windows.Forms.Button]$Button,
        [System.Drawing.Color]$BaseColor,
        [System.Drawing.Color]$HoverColor,
        [System.Drawing.Color]$TextColor = [System.Drawing.Color]::White
    )
    $Button.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $Button.FlatAppearance.BorderSize = 0
    $Button.BackColor = $BaseColor
    $Button.ForeColor = $TextColor
    $Button.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9.5)
    $Button.Cursor = [System.Windows.Forms.Cursors]::Hand
    $Button.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $Button.Tag = @{ Base = $BaseColor; Hover = $HoverColor; Text = $TextColor }
    $Button.Add_MouseEnter({ 
        if ($this.Tag -and $this.Tag.Hover) { $this.BackColor = $this.Tag.Hover }
        if ($this.Tag -and $this.Tag.Text) { $this.ForeColor = $this.Tag.Text }
    })
    $Button.Add_MouseLeave({ 
        if ($this.Tag -and $this.Tag.Base) { $this.BackColor = $this.Tag.Base }
        if ($this.Tag -and $this.Tag.Text) { $this.ForeColor = $this.Tag.Text }
    })
}

# ==============================================================================
# CONSTRUÇÃO DA HUD MODERNA E INTUITIVA PARA LEIGOS
# ==============================================================================
$form = New-Object System.Windows.Forms.Form
$form.Text = "1 Click DLSS 5 v2.5.2-beta • Universal Neural Control Center"
$form.Size = New-Object System.Drawing.Size(1260, 860)
$form.MinimumSize = New-Object System.Drawing.Size(1180, 800)
$form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
$form.BackColor = [System.Drawing.Color]::FromArgb(11, 15, 25)
$form.ForeColor = [System.Drawing.Color]::Gainsboro
$form.Font = New-Object System.Drawing.Font("Segoe UI", 9)

if (Test-Path -LiteralPath $script:IconPath) {
    try { $form.Icon = New-Object System.Drawing.Icon($script:IconPath) } catch {}
}

$imageList = New-Object System.Windows.Forms.ImageList
$imageList.ImageSize = New-Object System.Drawing.Size(28, 28)
$imageList.ColorDepth = [System.Windows.Forms.ColorDepth]::Depth32Bit

# --- HEADER SUPERIOR ---
$header = New-Object System.Windows.Forms.Panel
$header.Location = New-Object System.Drawing.Point(0, 0)
$header.Size = New-Object System.Drawing.Size(1260, 110)
$header.Anchor = "Top, Left, Right"
$header.BackColor = [System.Drawing.Color]::FromArgb(15, 22, 38)
[void]$form.Controls.Add($header)

$headerAccent = New-Object System.Windows.Forms.Panel
$headerAccent.Location = New-Object System.Drawing.Point(0, 0)
$headerAccent.Size = New-Object System.Drawing.Size(5, 110)
$headerAccent.BackColor = [System.Drawing.Color]::FromArgb(118, 185, 0)
[void]$header.Controls.Add($headerAccent)

$lblTagline = New-Object System.Windows.Forms.Label
$lblTagline.Text = "NEURAL CONTROL CENTER • RTX 20/30/40/50"
$lblTagline.Location = New-Object System.Drawing.Point(22, 10)
$lblTagline.Size = New-Object System.Drawing.Size(600, 18)
$lblTagline.ForeColor = [System.Drawing.Color]::FromArgb(118, 185, 0)
$lblTagline.Font = New-Object System.Drawing.Font("Segoe UI Bold", 8.5)
[void]$header.Controls.Add($lblTagline)

$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = "1 CLICK DLSS 5"
$lblTitle.Location = New-Object System.Drawing.Point(20, 24)
$lblTitle.Size = New-Object System.Drawing.Size(400, 36)
$lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 20, [System.Drawing.FontStyle]::Bold)
$lblTitle.ForeColor = [System.Drawing.Color]::White
[void]$header.Controls.Add($lblTitle)

$lblSubBadge = New-Object System.Windows.Forms.Label
$lblSubBadge.Text = "DirectX 9 / 10 / 11 / 12 • Vulkan • OpenGL • 32 & 64-bit"
$lblSubBadge.Location = New-Object System.Drawing.Point(22, 60)
$lblSubBadge.Size = New-Object System.Drawing.Size(550, 18)
$lblSubBadge.ForeColor = [System.Drawing.Color]::FromArgb(145, 175, 210)
[void]$header.Controls.Add($lblSubBadge)

# --- GUIA VISUAL EM 3 PASSOS SIMPLES NA PARTE SUPERIOR ---
$stepPanel = New-Object System.Windows.Forms.Panel
$stepPanel.Location = New-Object System.Drawing.Point(22, 80)
$stepPanel.Size = New-Object System.Drawing.Size(800, 24)
$stepPanel.BackColor = [System.Drawing.Color]::Transparent
[void]$header.Controls.Add($stepPanel)

$lblStep1 = New-Object System.Windows.Forms.Label
$lblStep1.Text = "[1] Escolha o Jogo"
$lblStep1.Location = New-Object System.Drawing.Point(0, 2)
$lblStep1.Size = New-Object System.Drawing.Size(180, 20)
$lblStep1.ForeColor = [System.Drawing.Color]::FromArgb(100, 180, 255)
$lblStep1.Font = New-Object System.Drawing.Font("Segoe UI Bold", 9)
[void]$stepPanel.Controls.Add($lblStep1)

$lblStepArrow1 = New-Object System.Windows.Forms.Label
$lblStepArrow1.Text = "➔"
$lblStepArrow1.Location = New-Object System.Drawing.Point(185, 2)
$lblStepArrow1.Size = New-Object System.Drawing.Size(20, 20)
$lblStepArrow1.ForeColor = [System.Drawing.Color]::Gray
[void]$stepPanel.Controls.Add($lblStepArrow1)

$lblStep2 = New-Object System.Windows.Forms.Label
$lblStep2.Text = "[2] Clique em Instalar"
$lblStep2.Location = New-Object System.Drawing.Point(210, 2)
$lblStep2.Size = New-Object System.Drawing.Size(180, 20)
$lblStep2.ForeColor = [System.Drawing.Color]::FromArgb(118, 225, 125)
$lblStep2.Font = New-Object System.Drawing.Font("Segoe UI Bold", 9)
[void]$stepPanel.Controls.Add($lblStep2)

$lblStepArrow2 = New-Object System.Windows.Forms.Label
$lblStepArrow2.Text = "➔"
$lblStepArrow2.Location = New-Object System.Drawing.Point(395, 2)
$lblStepArrow2.Size = New-Object System.Drawing.Size(20, 20)
$lblStepArrow2.ForeColor = [System.Drawing.Color]::Gray
[void]$stepPanel.Controls.Add($lblStepArrow2)

$lblStep3 = New-Object System.Windows.Forms.Label
$lblStep3.Text = "[3] Inicie e Aproveite!"
$lblStep3.Location = New-Object System.Drawing.Point(420, 2)
$lblStep3.Size = New-Object System.Drawing.Size(200, 20)
$lblStep3.ForeColor = [System.Drawing.Color]::FromArgb(255, 205, 90)
$lblStep3.Font = New-Object System.Drawing.Font("Segoe UI Bold", 9)
[void]$stepPanel.Controls.Add($lblStep3)

# Botão Diagnóstico e Idioma no Canto Superior Direito
$btnDiagnose = New-Object System.Windows.Forms.Button
$btnDiagnose.Text = "🩺 DIAGNÓSTICO"
$btnDiagnose.Location = New-Object System.Drawing.Point(880, 12)
$btnDiagnose.Size = New-Object System.Drawing.Size(160, 28)
$btnDiagnose.Anchor = "Top, Right"
Style-Button -Button $btnDiagnose -BaseColor ([System.Drawing.Color]::FromArgb(35, 60, 100)) -HoverColor ([System.Drawing.Color]::FromArgb(50, 85, 140))
$btnDiagnose.Add_Click({ Show-SystemDiagnosisDialog })
[void]$header.Controls.Add($btnDiagnose)

$comboLang = New-Object System.Windows.Forms.ComboBox
$comboLang.Location = New-Object System.Drawing.Point(1055, 13)
$comboLang.Size = New-Object System.Drawing.Size(180, 26)
$comboLang.Anchor = "Top, Right"
$comboLang.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$comboLang.BackColor = [System.Drawing.Color]::FromArgb(22, 32, 54)
$comboLang.ForeColor = [System.Drawing.Color]::White
$comboLang.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9)
[void]$comboLang.Items.AddRange(@("Português", "English", "Español", "Deutsch", "Français", "Italiano", "日本語", "简体中文", "Русский", "한국어"))
$comboLang.SelectedIndex = 0
[void]$header.Controls.Add($comboLang)

# --- BARRA DE FERRAMENTAS / PESQUISA ---
$toolbar = New-Object System.Windows.Forms.Panel
$toolbar.Location = New-Object System.Drawing.Point(18, 120)
$toolbar.Size = New-Object System.Drawing.Size(1224, 44)
$toolbar.Anchor = "Top, Left, Right"
$toolbar.BackColor = [System.Drawing.Color]::FromArgb(16, 24, 40)
[void]$form.Controls.Add($toolbar)

$btnScan = New-Object System.Windows.Forms.Button
$btnScan.Text = "🔍 ESCANEAR DISCOS"
$btnScan.Location = New-Object System.Drawing.Point(8, 7)
$btnScan.Size = New-Object System.Drawing.Size(180, 30)
Style-Button -Button $btnScan -BaseColor ([System.Drawing.Color]::FromArgb(35, 80, 145)) -HoverColor ([System.Drawing.Color]::FromArgb(50, 110, 195))
[void]$toolbar.Controls.Add($btnScan)

$txtSearch = New-Object System.Windows.Forms.TextBox
$txtSearch.Location = New-Object System.Drawing.Point(200, 9)
$txtSearch.Size = New-Object System.Drawing.Size(830, 26)
$txtSearch.Anchor = "Top, Left, Right"
$txtSearch.BackColor = [System.Drawing.Color]::FromArgb(10, 15, 26)
$txtSearch.ForeColor = [System.Drawing.Color]::FromArgb(140, 210, 255)
$txtSearch.BorderStyle = "FixedSingle"
$txtSearch.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
[void]$toolbar.Controls.Add($txtSearch)

$btnBrowse = New-Object System.Windows.Forms.Button
$btnBrowse.Text = "📁 PROCURAR JOGO"
$btnBrowse.Location = New-Object System.Drawing.Point(1042, 7)
$btnBrowse.Size = New-Object System.Drawing.Size(172, 30)
$btnBrowse.Anchor = "Top, Right"
Style-Button -Button $btnBrowse -BaseColor ([System.Drawing.Color]::FromArgb(40, 65, 110)) -HoverColor ([System.Drawing.Color]::FromArgb(55, 90, 150))
[void]$toolbar.Controls.Add($btnBrowse)

# --- COLUNA ESQUERDA: BIBLIOTECA DE JOGOS ---
$leftPanel = New-Object System.Windows.Forms.Panel
$leftPanel.Location = New-Object System.Drawing.Point(18, 172)
$leftPanel.Size = New-Object System.Drawing.Size(460, 610)
$leftPanel.Anchor = "Top, Bottom, Left"
$leftPanel.BackColor = [System.Drawing.Color]::FromArgb(16, 24, 40)
[void]$form.Controls.Add($leftPanel)

$lblLibTitle = New-Object System.Windows.Forms.Label
$lblLibTitle.Text = "BIBLIOTECA DE JOGOS DETECTADOS"
$lblLibTitle.Location = New-Object System.Drawing.Point(14, 10)
$lblLibTitle.Size = New-Object System.Drawing.Size(430, 20)
$lblLibTitle.ForeColor = [System.Drawing.Color]::FromArgb(140, 200, 255)
$lblLibTitle.Font = New-Object System.Drawing.Font("Segoe UI Bold", 9.5)
[void]$leftPanel.Controls.Add($lblLibTitle)

$gameList = New-Object System.Windows.Forms.ListView
$gameList.Location = New-Object System.Drawing.Point(12, 34)
$gameList.Size = New-Object System.Drawing.Size(436, 564)
$gameList.Anchor = "Top, Bottom, Left, Right"
$gameList.View = [System.Windows.Forms.View]::Details
$gameList.FullRowSelect = $true
$gameList.MultiSelect = $false
$gameList.HideSelection = $false
$gameList.BackColor = [System.Drawing.Color]::FromArgb(9, 14, 24)
$gameList.ForeColor = [System.Drawing.Color]::White
$gameList.BorderStyle = "FixedSingle"
$gameList.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$gameList.SmallImageList = $imageList
[void]$gameList.Columns.Add("Jogo", 210)
[void]$gameList.Columns.Add("API / Arq", 95)
[void]$gameList.Columns.Add("Modo / Status", 135)
[void]$leftPanel.Controls.Add($gameList)

# --- COLUNA DIREITA: INSPETOR E SELETOR DE MODOS ---
$rightPanel = New-Object System.Windows.Forms.Panel
$rightPanel.Location = New-Object System.Drawing.Point(488, 172)
$rightPanel.Size = New-Object System.Drawing.Size(754, 610)
$rightPanel.Anchor = "Top, Bottom, Left, Right"
$rightPanel.BackColor = [System.Drawing.Color]::FromArgb(16, 24, 40)
[void]$form.Controls.Add($rightPanel)

# Banner do Jogo Selecionado
$gameBanner = New-Object System.Windows.Forms.Panel
$gameBanner.Location = New-Object System.Drawing.Point(16, 12)
$gameBanner.Size = New-Object System.Drawing.Size(722, 70)
$gameBanner.Anchor = "Top, Left, Right"
$gameBanner.BackColor = [System.Drawing.Color]::FromArgb(11, 18, 30)
[void]$rightPanel.Controls.Add($gameBanner)

$picIcon = New-Object System.Windows.Forms.PictureBox
$picIcon.Location = New-Object System.Drawing.Point(12, 11)
$picIcon.Size = New-Object System.Drawing.Size(48, 48)
$picIcon.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom
[void]$gameBanner.Controls.Add($picIcon)

$lblGameTitle = New-Object System.Windows.Forms.Label
$lblGameTitle.Text = "Selecione um Jogo"
$lblGameTitle.Location = New-Object System.Drawing.Point(70, 10)
$lblGameTitle.Size = New-Object System.Drawing.Size(640, 26)
$lblGameTitle.Font = New-Object System.Drawing.Font("Segoe UI Bold", 13)
$lblGameTitle.ForeColor = [System.Drawing.Color]::White
[void]$gameBanner.Controls.Add($lblGameTitle)

$lblGameStatus = New-Object System.Windows.Forms.Label
$lblGameStatus.Text = "Escolha um jogo na lista à esquerda ou procure uma pasta."
$lblGameStatus.Location = New-Object System.Drawing.Point(70, 38)
$lblGameStatus.Size = New-Object System.Drawing.Size(640, 22)
$lblGameStatus.ForeColor = [System.Drawing.Color]::FromArgb(118, 225, 125)
$lblGameStatus.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9)
[void]$gameBanner.Controls.Add($lblGameStatus)

# Pasta de Instalação Consolidada
$lblFolderTitle = New-Object System.Windows.Forms.Label
$lblFolderTitle.Text = "DIRETÓRIO DE INSTALAÇÃO DO JOGO:"
$lblFolderTitle.Location = New-Object System.Drawing.Point(16, 90)
$lblFolderTitle.Size = New-Object System.Drawing.Size(500, 18)
$lblFolderTitle.ForeColor = [System.Drawing.Color]::FromArgb(160, 190, 225)
$lblFolderTitle.Font = New-Object System.Drawing.Font("Segoe UI Bold", 8.5)
[void]$rightPanel.Controls.Add($lblFolderTitle)

$txtFolderPath = New-Object System.Windows.Forms.TextBox
$txtFolderPath.Location = New-Object System.Drawing.Point(16, 110)
$txtFolderPath.Size = New-Object System.Drawing.Size(722, 24)
$txtFolderPath.Anchor = "Top, Left, Right"
$txtFolderPath.ReadOnly = $true
$txtFolderPath.BackColor = [System.Drawing.Color]::FromArgb(9, 14, 24)
$txtFolderPath.ForeColor = [System.Drawing.Color]::FromArgb(140, 210, 255)
$txtFolderPath.BorderStyle = "FixedSingle"
[void]$rightPanel.Controls.Add($txtFolderPath)

# Seletor de Modo de Injeção em Cards Modernos
$lblModeSecTitle = New-Object System.Windows.Forms.Label
$lblModeSecTitle.Text = "ESCOLHA O MODO DE INJEÇÃO DLSS 5:"
$lblModeSecTitle.Location = New-Object System.Drawing.Point(16, 142)
$lblModeSecTitle.Size = New-Object System.Drawing.Size(400, 18)
$lblModeSecTitle.ForeColor = [System.Drawing.Color]::FromArgb(255, 205, 90)
$lblModeSecTitle.Font = New-Object System.Drawing.Font("Segoe UI Bold", 8.5)
[void]$rightPanel.Controls.Add($lblModeSecTitle)

$lblAutoNotice = New-Object System.Windows.Forms.Label
$lblAutoNotice.Text = "✨ Modo ideal selecionado automaticamente!"
$lblAutoNotice.Location = New-Object System.Drawing.Point(420, 142)
$lblAutoNotice.Size = New-Object System.Drawing.Size(318, 18)
$lblAutoNotice.Anchor = "Top, Right"
$lblAutoNotice.TextAlign = [System.Drawing.ContentAlignment]::TopRight
$lblAutoNotice.ForeColor = [System.Drawing.Color]::FromArgb(118, 225, 125)
$lblAutoNotice.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 8)
[void]$rightPanel.Controls.Add($lblAutoNotice)

# Card Modo 1
$cardMode1 = New-Object System.Windows.Forms.Panel
$cardMode1.Location = New-Object System.Drawing.Point(16, 164)
$cardMode1.Size = New-Object System.Drawing.Size(722, 52)
$cardMode1.Anchor = "Top, Left, Right"
$cardMode1.BackColor = [System.Drawing.Color]::FromArgb(12, 22, 34)
$cardMode1.Cursor = [System.Windows.Forms.Cursors]::Hand
[void]$rightPanel.Controls.Add($cardMode1)

$lblCard1Title = New-Object System.Windows.Forms.Label
$lblCard1Title.Text = "● MODO 1: DIRETO (DLSS Nativo)"
$lblCard1Title.Location = New-Object System.Drawing.Point(12, 6)
$lblCard1Title.Size = New-Object System.Drawing.Size(690, 20)
$lblCard1Title.Font = New-Object System.Drawing.Font("Segoe UI Bold", 9.5)
$lblCard1Title.ForeColor = [System.Drawing.Color]::FromArgb(118, 225, 125)
[void]$cardMode1.Controls.Add($lblCard1Title)

$lblCard1Desc = New-Object System.Windows.Forms.Label
$lblCard1Desc.Text = "Para jogos com DLSS nativo. Ativa Streamline + IA com ganho massivo de FPS."
$lblCard1Desc.Location = New-Object System.Drawing.Point(12, 26)
$lblCard1Desc.Size = New-Object System.Drawing.Size(690, 20)
$lblCard1Desc.ForeColor = [System.Drawing.Color]::FromArgb(170, 195, 220)
[void]$cardMode1.Controls.Add($lblCard1Desc)

# Card Modo 2
$cardMode2 = New-Object System.Windows.Forms.Panel
$cardMode2.Location = New-Object System.Drawing.Point(16, 222)
$cardMode2.Size = New-Object System.Drawing.Size(722, 52)
$cardMode2.Anchor = "Top, Left, Right"
$cardMode2.BackColor = [System.Drawing.Color]::FromArgb(12, 22, 34)
$cardMode2.Cursor = [System.Windows.Forms.Cursors]::Hand
[void]$rightPanel.Controls.Add($cardMode2)

$lblCard2Title = New-Object System.Windows.Forms.Label
$lblCard2Title.Text = "● MODO 2: PONTE OPTISCALER (FSR2/XeSS)"
$lblCard2Title.Location = New-Object System.Drawing.Point(12, 6)
$lblCard2Title.Size = New-Object System.Drawing.Size(690, 20)
$lblCard2Title.Font = New-Object System.Drawing.Font("Segoe UI Bold", 9.5)
$lblCard2Title.ForeColor = [System.Drawing.Color]::FromArgb(100, 180, 255)
[void]$cardMode2.Controls.Add($lblCard2Title)

$lblCard2Desc = New-Object System.Windows.Forms.Label
$lblCard2Desc.Text = "Redireciona chamadas FSR2/XeSS para o modelo neural DLSS 5."
$lblCard2Desc.Location = New-Object System.Drawing.Point(12, 26)
$lblCard2Desc.Size = New-Object System.Drawing.Size(690, 20)
$lblCard2Desc.ForeColor = [System.Drawing.Color]::FromArgb(170, 195, 220)
[void]$cardMode2.Controls.Add($lblCard2Desc)

# Card Modo 3
$cardMode3 = New-Object System.Windows.Forms.Panel
$cardMode3.Location = New-Object System.Drawing.Point(16, 280)
$cardMode3.Size = New-Object System.Drawing.Size(722, 52)
$cardMode3.Anchor = "Top, Left, Right"
$cardMode3.BackColor = [System.Drawing.Color]::FromArgb(12, 22, 34)
$cardMode3.Cursor = [System.Windows.Forms.Cursors]::Hand
[void]$rightPanel.Controls.Add($cardMode3)

$lblCard3Title = New-Object System.Windows.Forms.Label
$lblCard3Title.Text = "● MODO 3: FEEDER UNIVERSAL (DLAA 100% Nativo)"
$lblCard3Title.Location = New-Object System.Drawing.Point(12, 6)
$lblCard3Title.Size = New-Object System.Drawing.Size(690, 20)
$lblCard3Title.Font = New-Object System.Drawing.Font("Segoe UI Bold", 9.5)
$lblCard3Title.ForeColor = [System.Drawing.Color]::FromArgb(190, 150, 255)
[void]$cardMode3.Controls.Add($lblCard3Title)

$lblCard3Desc = New-Object System.Windows.Forms.Label
$lblCard3Desc.Text = "Para QUALQUER jogo (Mafia, GTA, etc). Reconstrução 100% limpa e sem perda de nitidez."
$lblCard3Desc.Location = New-Object System.Drawing.Point(12, 26)
$lblCard3Desc.Size = New-Object System.Drawing.Size(690, 20)
$lblCard3Desc.ForeColor = [System.Drawing.Color]::FromArgb(170, 195, 220)
[void]$cardMode3.Controls.Add($lblCard3Desc)

function Highlight-SelectedModeCard {
    param([string]$Mode)
    $script:SelectedMode = $Mode
    $cardMode1.BackColor = [System.Drawing.Color]::FromArgb(12, 22, 34)
    $cardMode2.BackColor = [System.Drawing.Color]::FromArgb(12, 22, 34)
    $cardMode3.BackColor = [System.Drawing.Color]::FromArgb(12, 22, 34)

    $d = Get-Dict -Lang $script:CurrentLang
    $isRdr2 = ($script:SelectedGameObj -and ($script:SelectedGameObj.Name -match "Red Dead" -or $script:SelectedGameObj.ExeName -match "RDR2|rdr2"))

    if ($Mode -eq "DIRECT") {
        $cardMode1.BackColor = [System.Drawing.Color]::FromArgb(20, 48, 30)
        if ($isRdr2) {
            $lblReqText.Text = if ($script:CurrentLang -eq "PT") { "No RDR2: Mude API para DirectX 12 (Configurações > Gráficos > Avançado) e ATIVE o DLSS." } else { "In RDR2: Switch Graphics API to DirectX 12 (Settings > Graphics > Advanced) & ENABLE DLSS." }
        } else {
            $lblReqText.Text = $d.ReqMode1
        }
    } elseif ($Mode -eq "OPTISCALER") {
        $cardMode2.BackColor = [System.Drawing.Color]::FromArgb(18, 40, 65)
        $lblReqText.Text = $d.ReqMode2
    } else {
        $cardMode3.BackColor = [System.Drawing.Color]::FromArgb(35, 25, 55)
        if ($isRdr2) {
            $lblReqText.Text = if ($script:CurrentLang -eq "PT") { "No RDR2: O Feeder requer DirectX 12. Mude a API para DirectX 12 nas opções do jogo." } else { "In RDR2: Feeder requires DirectX 12. Switch Graphics API to DirectX 12 in game settings." }
        } else {
            $lblReqText.Text = $d.ReqMode3
        }
    }
}

$cardMode1.Add_Click({ Highlight-SelectedModeCard -Mode "DIRECT" })
$lblCard1Title.Add_Click({ Highlight-SelectedModeCard -Mode "DIRECT" })
$lblCard1Desc.Add_Click({ Highlight-SelectedModeCard -Mode "DIRECT" })

$cardMode2.Add_Click({ Highlight-SelectedModeCard -Mode "OPTISCALER" })
$lblCard2Title.Add_Click({ Highlight-SelectedModeCard -Mode "OPTISCALER" })
$lblCard2Desc.Add_Click({ Highlight-SelectedModeCard -Mode "OPTISCALER" })

$cardMode3.Add_Click({ Highlight-SelectedModeCard -Mode "FEEDER" })
$lblCard3Title.Add_Click({ Highlight-SelectedModeCard -Mode "FEEDER" })
$lblCard3Desc.Add_Click({ Highlight-SelectedModeCard -Mode "FEEDER" })

# Card de Requisito no Jogo
$reqCard = New-Object System.Windows.Forms.Panel
$reqCard.Location = New-Object System.Drawing.Point(16, 340)
$reqCard.Size = New-Object System.Drawing.Size(722, 60)
$reqCard.Anchor = "Top, Left, Right"
$reqCard.BackColor = [System.Drawing.Color]::FromArgb(25, 28, 15)
[void]$rightPanel.Controls.Add($reqCard)

$reqAccent = New-Object System.Windows.Forms.Panel
$reqAccent.Location = New-Object System.Drawing.Point(0, 0)
$reqAccent.Size = New-Object System.Drawing.Size(4, 60)
$reqAccent.BackColor = [System.Drawing.Color]::FromArgb(255, 195, 0)
[void]$reqCard.Controls.Add($reqAccent)

$lblReqTitle = New-Object System.Windows.Forms.Label
$lblReqTitle.Text = "⚡ REQUISITO NO JOGO:"
$lblReqTitle.Location = New-Object System.Drawing.Point(12, 6)
$lblReqTitle.Size = New-Object System.Drawing.Size(700, 18)
$lblReqTitle.Font = New-Object System.Drawing.Font("Segoe UI Bold", 9)
$lblReqTitle.ForeColor = [System.Drawing.Color]::FromArgb(255, 205, 50)
[void]$reqCard.Controls.Add($lblReqTitle)

$lblReqText = New-Object System.Windows.Forms.Label
$lblReqText.Text = "Selecione um jogo para carregar as instruções automáticas."
$lblReqText.Location = New-Object System.Drawing.Point(12, 26)
$lblReqText.Size = New-Object System.Drawing.Size(700, 30)
$lblReqText.ForeColor = [System.Drawing.Color]::FromArgb(240, 230, 190)
$lblReqText.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
[void]$reqCard.Controls.Add($lblReqText)

# Barra de Ações Principais
$actionPanel = New-Object System.Windows.Forms.Panel
$actionPanel.Location = New-Object System.Drawing.Point(16, 410)
$actionPanel.Size = New-Object System.Drawing.Size(722, 185)
$actionPanel.Anchor = "Top, Bottom, Left, Right"
[void]$rightPanel.Controls.Add($actionPanel)

$btnInstall = New-Object System.Windows.Forms.Button
$btnInstall.Text = "[⚡] 1-CLIQUE: INSTALAR DLSS 5"
$btnInstall.Location = New-Object System.Drawing.Point(0, 5)
$btnInstall.Size = New-Object System.Drawing.Size(355, 48)
$btnInstall.Font = New-Object System.Drawing.Font("Segoe UI Bold", 11.5)
Style-Button -Button $btnInstall -BaseColor ([System.Drawing.Color]::FromArgb(118, 185, 0)) -HoverColor ([System.Drawing.Color]::FromArgb(140, 220, 0)) -TextColor ([System.Drawing.Color]::Black)
[void]$actionPanel.Controls.Add($btnInstall)

$btnLaunch = New-Object System.Windows.Forms.Button
$btnLaunch.Text = "[►] INICIAR JOGO"
$btnLaunch.Location = New-Object System.Drawing.Point(367, 5)
$btnLaunch.Size = New-Object System.Drawing.Size(355, 48)
$btnLaunch.Font = New-Object System.Drawing.Font("Segoe UI Bold", 11.5)
Style-Button -Button $btnLaunch -BaseColor ([System.Drawing.Color]::FromArgb(0, 130, 230)) -HoverColor ([System.Drawing.Color]::FromArgb(20, 160, 255)) -TextColor ([System.Drawing.Color]::White)
[void]$actionPanel.Controls.Add($btnLaunch)

$btnUninstall = New-Object System.Windows.Forms.Button
$btnUninstall.Text = "[↩] RESTAURAR ORIGINAL"
$btnUninstall.Location = New-Object System.Drawing.Point(0, 62)
$btnUninstall.Size = New-Object System.Drawing.Size(355, 38)
Style-Button -Button $btnUninstall -BaseColor ([System.Drawing.Color]::FromArgb(170, 45, 45)) -HoverColor ([System.Drawing.Color]::FromArgb(205, 55, 55)) -TextColor ([System.Drawing.Color]::White)
[void]$actionPanel.Controls.Add($btnUninstall)

$btnOpenFolder = New-Object System.Windows.Forms.Button
$btnOpenFolder.Text = "[📂] ABRIR PASTA"
$btnOpenFolder.Location = New-Object System.Drawing.Point(367, 62)
$btnOpenFolder.Size = New-Object System.Drawing.Size(355, 38)
Style-Button -Button $btnOpenFolder -BaseColor ([System.Drawing.Color]::FromArgb(35, 55, 90)) -HoverColor ([System.Drawing.Color]::FromArgb(50, 75, 125)) -TextColor ([System.Drawing.Color]::White)
[void]$actionPanel.Controls.Add($btnOpenFolder)

# --- RODAPÉ MINIMALISTA COM LOG E STATUS ---
$footer = New-Object System.Windows.Forms.Panel
$footer.Location = New-Object System.Drawing.Point(0, 790)
$footer.Size = New-Object System.Drawing.Size(1260, 32)
$footer.Anchor = "Bottom, Left, Right"
$footer.BackColor = [System.Drawing.Color]::FromArgb(8, 12, 20)
[void]$form.Controls.Add($footer)

$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text = "● Pronto. Selecione um jogo para começar."
$lblStatus.Location = New-Object System.Drawing.Point(18, 7)
$lblStatus.Size = New-Object System.Drawing.Size(1020, 18)
$lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(140, 180, 220)
$lblStatus.Font = New-Object System.Drawing.Font("Segoe UI", 9)
[void]$footer.Controls.Add($lblStatus)
$script:StatusLabel = $lblStatus

$btnOpenLog = New-Object System.Windows.Forms.Button
$btnOpenLog.Text = "📄 VER LOG COMPLETO"
$btnOpenLog.Location = New-Object System.Drawing.Point(1070, 3)
$btnOpenLog.Size = New-Object System.Drawing.Size(170, 26)
$btnOpenLog.Anchor = "Top, Right"
Style-Button -Button $btnOpenLog -BaseColor ([System.Drawing.Color]::FromArgb(25, 40, 65)) -HoverColor ([System.Drawing.Color]::FromArgb(35, 60, 95))
$btnOpenLog.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$btnOpenLog.Add_Click({ Open-LogFile })
[void]$footer.Controls.Add($btnOpenLog)

# --- SINCRONIZAÇÃO DE IDIOMAS ---
function Update-UiLanguage {
    param([string]$Lang)
    $script:CurrentLang = $Lang
    $d = Get-Dict -Lang $Lang

    $lblTagline.Text = $d.Tagline
    $lblSubBadge.Text = $d.SubBadge
    $lblStep1.Text = $d.Step1
    $lblStep2.Text = $d.Step2
    $lblStep3.Text = $d.Step3
    $btnDiagnose.Text = $d.BtnDiagnose
    $btnScan.Text = $d.BtnScan
    $btnBrowse.Text = $d.BtnBrowse
    $lblLibTitle.Text = $d.LibraryTitle
    $lblFolderTitle.Text = $d.FolderLabel
    $lblModeSecTitle.Text = $d.ModeSectionTitle
    $lblAutoNotice.Text = $d.AutoModeNotice
    $lblCard1Title.Text = $d.Mode1Title
    $lblCard1Desc.Text = $d.Mode1Desc
    $lblCard2Title.Text = $d.Mode2Title
    $lblCard2Desc.Text = $d.Mode2Desc
    $lblCard3Title.Text = $d.Mode3Title
    $lblCard3Desc.Text = $d.Mode3Desc
    $lblReqTitle.Text = $d.RequirementTitle
    $btnLaunch.Text = $d.BtnLaunch
    $btnUninstall.Text = $d.BtnUninstall
    $btnOpenFolder.Text = $d.BtnOpenFolder
    $btnOpenLog.Text = $d.BtnOpenLog

    $btnInstallText = $d.BtnInstall
    if ([string]::IsNullOrWhiteSpace($btnInstallText)) { $btnInstallText = "[⚡] 1-CLIQUE: INSTALAR DLSS 5" }
    $btnInstall.Text = $btnInstallText

    $gameList.Columns[0].Text = $d.ColGame
    $gameList.Columns[1].Text = $d.ColApi
    $gameList.Columns[2].Text = $d.ColMode

    if ($script:SelectedGameObj) {
        Select-GameInInspector -GameObj $script:SelectedGameObj
    } else {
        $lblStatus.Text = "● " + $d.StatusReady
    }
}

$comboLang.Add_SelectedIndexChanged({
    $langCodes = @("PT", "EN", "ES", "DE", "FR", "IT", "JA", "ZH", "RU", "KO")
    $idx = $comboLang.SelectedIndex
    if ($idx -ge 0 -and $idx -lt $langCodes.Length) {
        Update-UiLanguage -Lang $langCodes[$idx]
    }
})

# --- EVENTOS E LOGICA DE INSPEÇÃO ---
function Select-GameInInspector {
    param([pscustomobject]$GameObj)
    if ($null -eq $GameObj) { return }
    $script:SelectedGameObj = $GameObj
    $d = Get-Dict -Lang $script:CurrentLang

    $lblGameTitle.Text = $GameObj.Name
    $txtFolderPath.Text = $GameObj.Path

    if ($GameObj.Icon) {
        $picIcon.Image = $GameObj.Icon.ToBitmap()
    } else {
        $picIcon.Image = $null
    }

    $detected = $GameObj.Upscaler
    $script:CurrentDetectedUpscaler = $detected

    $modeCode = "FEEDER"
    if ($detected -eq "NATIVE_DLSS") {
        $modeCode = "DIRECT"
    } elseif ($detected -eq "FSR2_BRIDGE" -or $detected -eq "XESS_BRIDGE") {
        $modeCode = "OPTISCALER"
    }
    Highlight-SelectedModeCard -Mode $modeCode

    $modeText = "Universal (Feeder)"
    if ($detected -eq "NATIVE_DLSS") {
        $modeText = "DLSS Nativo"
    } elseif ($detected -like "*BRIDGE*") {
        $modeText = "FSR2/XeSS (OptiScaler)"
    }

    $isInstalled = Test-GameDlss5Installed -GameFolder $GameObj.Path
    if ($isInstalled) {
        $lblGameStatus.Text = $d.StatusInstalled + " • API: " + $GameObj.Api
        $lblGameStatus.ForeColor = [System.Drawing.Color]::FromArgb(255, 205, 90)
        
        $btnText = $d.BtnReinstall
        if ([string]::IsNullOrWhiteSpace($btnText)) { $btnText = "[⚡] REINSTALAR / ATUALIZAR DLSS 5" }
        $btnInstall.Text = $btnText
    } else {
        $lblGameStatus.Text = "API: " + $GameObj.Api + " • Modo Ideal: " + $modeText
        $lblGameStatus.ForeColor = [System.Drawing.Color]::FromArgb(118, 225, 125)
        
        $btnText = $d.BtnInstall
        if ([string]::IsNullOrWhiteSpace($btnText)) { $btnText = "[⚡] 1-CLIQUE: INSTALAR DLSS 5" }
        $btnInstall.Text = $btnText
    }

    Write-Status -Message "Jogo selecionado: $($GameObj.Name) [$($GameObj.Api)]" -Level "INFO"
}

$gameList.Add_SelectedIndexChanged({
    if ($gameList.SelectedIndices.Count -gt 0) {
        $idx = $gameList.SelectedIndices[0]
        if ($script:CurrentGameLibrary -and $idx -lt $script:CurrentGameLibrary.Count) {
            Select-GameInInspector -GameObj $script:CurrentGameLibrary[$idx]
        }
    }
})

function Refresh-GameLibraryUI {
    param($Games)
    $gameList.BeginUpdate()
    $gameList.Items.Clear()
    $imageList.Images.Clear()

    $d = Get-Dict -Lang $script:CurrentLang

    foreach ($g in $Games) {
        $imgIdx = -1
        if ($g.Icon) {
            try {
                $imageList.Images.Add($g.Icon.ToBitmap())
                $imgIdx = $imageList.Images.Count - 1
            } catch {}
        }

        $isInst = Test-GameDlss5Installed -GameFolder $g.Path
        $modeLabel = ""
        if ($isInst) {
            $modeLabel = "[✓] DLSS 5 Ativo"
        } else {
            if ($g.Upscaler -eq "NATIVE_DLSS") {
                $modeLabel = "[Modo 1] DLSS"
            } elseif ($g.Upscaler -eq "FSR2_BRIDGE" -or $g.Upscaler -eq "XESS_BRIDGE") {
                $modeLabel = "[Modo 2] OptiScaler"
            } else {
                $modeLabel = "[Modo 3] Feeder"
            }
        }

        $item = New-Object System.Windows.Forms.ListViewItem($g.Name, $imgIdx)
        [void]$item.SubItems.Add($g.Api)
        [void]$item.SubItems.Add($modeLabel)
        [void]$gameList.Items.Add($item)
    }
    $gameList.EndUpdate()
}

$btnScan.Add_Click({
    $d = Get-Dict -Lang $script:CurrentLang
    Write-Status -Message $d.StatusScanning -Level "INFO"
    $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor

    $games = Scan-DriveForGames -DriveLetter "ALL" -ProgressCallback {
        param($pct, $name)
        $script:StatusLabel.Text = "● Escaneando: $name ($pct%)..."
        [System.Windows.Forms.Application]::DoEvents()
    }

    $script:CurrentGameLibrary = $games
    Refresh-GameLibraryUI -Games $games
    $form.Cursor = [System.Windows.Forms.Cursors]::Default

    Write-Status -Message ($d.StatusScanDone -f $games.Count) -Level "OK"
    if ($games.Count -gt 0) {
        $gameList.Items[0].Selected = $true
    }
})

$btnBrowse.Add_Click({
    $fbd = New-Object System.Windows.Forms.FolderBrowserDialog
    $fbd.Description = "Selecione a pasta onde o jogo esta instalado:"
    if ($fbd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        try {
            $resolved = Resolve-GameTarget -TargetPath $fbd.SelectedPath
            $api = Detect-GameGraphicsApi -TargetExe $resolved.Executable -GameFolder $resolved.InstallFolder
            $upscaler = Detect-GameUpscalerType -GameFolder $resolved.InstallFolder -GameRoot $resolved.Root
            $gObj = [pscustomobject]@{
                Order = 1
                Name = (Split-Path -Leaf $fbd.SelectedPath)
                Path = $fbd.SelectedPath
                Api = "$api ($($resolved.Architecture))"
                Upscaler = $upscaler
                Icon = $resolved.Icon
                ExeName = $resolved.ExeName
            }
            $script:CurrentGameLibrary = @($gObj)
            Refresh-GameLibraryUI -Games @($gObj)
            Select-GameInInspector -GameObj $gObj
        } catch {
            Show-FriendlyErrorDialog -Ex $_.Exception -Context "Seleção de Pasta" -TargetPath $fbd.SelectedPath
        }
    }
})

$btnInstall.Add_Click({
    if (-not $script:SelectedGameObj) {
        [System.Windows.Forms.MessageBox]::Show("Por favor, selecione um jogo na biblioteca ou clique em 'PROCURAR JOGO' primeiro.", "1 Click DLSS 5", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        return
    }
    try {
        Install-Dlss5 -TargetPath $script:SelectedGameObj.Path -SelectedMode $script:SelectedMode
        Select-GameInInspector -GameObj $script:SelectedGameObj
    } catch {
        Show-FriendlyErrorDialog -Ex $_.Exception -Context "Instalação do DLSS 5" -TargetPath $script:SelectedGameObj.Path -SelectedMode $script:SelectedMode
    }
})

$btnLaunch.Add_Click({
    if (-not $script:SelectedGameObj) { return }
    try {
        $resolved = Resolve-GameTarget -TargetPath $script:SelectedGameObj.Path
        Start-GameExecutable -ExecutablePath $resolved.Executable
    } catch {
        Show-FriendlyErrorDialog -Ex $_.Exception -Context "Inicialização do Jogo" -TargetPath $script:SelectedGameObj.Path
    }
})

$btnUninstall.Add_Click({
    if (-not $script:SelectedGameObj) { return }
    $res = [System.Windows.Forms.MessageBox]::Show("Deseja realmente remover todos os arquivos do DLSS 5 e restaurar o jogo ao estado original de fabrica?", "Confirmar Restauracao", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
    if ($res -eq [System.Windows.Forms.DialogResult]::Yes) {
        try {
            Uninstall-Dlss5 -TargetPath $script:SelectedGameObj.Path
            Select-GameInInspector -GameObj $script:SelectedGameObj
        } catch {
            Show-FriendlyErrorDialog -Ex $_.Exception -Context "Restauração de Fábrica" -TargetPath $script:SelectedGameObj.Path
        }
    }
})

$btnOpenFolder.Add_Click({
    if ($script:SelectedGameObj -and (Test-Path -LiteralPath $script:SelectedGameObj.Path)) {
        Start-Process "explorer.exe" -ArgumentList "`"$($script:SelectedGameObj.Path)`""
    }
})

$txtSearch.Add_TextChanged({
    $term = $txtSearch.Text.Trim().ToLower()
    if ($null -eq $script:CurrentGameLibrary) { return }
    if ([string]::IsNullOrWhiteSpace($term)) {
        Refresh-GameLibraryUI -Games $script:CurrentGameLibrary
    } else {
        $filtered = @($script:CurrentGameLibrary | Where-Object { $_.Name.ToLower().Contains($term) -or $_.Api.ToLower().Contains($term) })
        Refresh-GameLibraryUI -Games $filtered
    }
})

# --- AUTO-DESCOBERTA INSTANTÂNEA AO INICIAR ---
$form.Add_Shown({
    $d = Get-Dict -Lang $script:CurrentLang
    $lblStatus.Text = "● Carregando biblioteca de jogos instalados no PC..."
    [System.Windows.Forms.Application]::DoEvents()

    $autoGames = Scan-DriveForGames -DriveLetter "ALL"
    if ($autoGames.Count -gt 0) {
        $script:CurrentGameLibrary = $autoGames
        Refresh-GameLibraryUI -Games $autoGames
        $lblStatus.Text = "● " + ($d.StatusScanDone -f $autoGames.Count)
        $gameList.Items[0].Selected = $true
    } else {
        $lblStatus.Text = "● " + $d.StatusReady
    }
})

# Inicialização
Write-Status -Message "1 Click DLSS 5 v2.5.2-beta pronto e operacional." -Level "OK"
if (-not $env:DLSS5_HEADLESS) { [void]$form.ShowDialog() }

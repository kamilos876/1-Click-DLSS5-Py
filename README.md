# 1 Click DLSS 5 🚀

<div align="center">

**Universal Neural Rendering Game Center & 1-Click Injector**  
*Empowering RTX 40 & RTX 50 Series GPUs with Next-Generation DLSS 5 Neural Reconstruction*

[![Version](https://img.shields.io/badge/version-1.2.2-brightgreen.svg)](https://github.com/reiluisii/1-Click-DLSS5)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows%2010%20%7C%2011%20x64-0078D6.svg)](https://github.com/reiluisii/1-Click-DLSS5)
[![DirectX](https://img.shields.io/badge/DirectX-12%20%7C%20DXGI-orange.svg)](https://github.com/reiluisii/1-Click-DLSS5)
[![NVIDIA](https://img.shields.io/badge/NVIDIA-RTX%2040%20%26%2050%20Series-76B900.svg)](https://nvidia.com)
[![RenoDX](https://img.shields.io/badge/RenoDX-v4.x%20Addon-FF6B6B.svg)](https://github.com/reiluisii/1-Click-DLSS5)
[![OptiScaler](https://img.shields.io/badge/OptiScaler-v0.9.4%20Bridge-purple.svg)](https://github.com/reiluisii/1-Click-DLSS5)

[English](#english) • [Português (Brasil)](#português-brasil)

</div>

---

## English

### 🌟 Overview

**1 Click DLSS 5** is an all-in-one, automated Neural Rendering game center and injection engine for Windows. Built specifically for NVIDIA GeForce RTX 40 & RTX 50 Series GPUs (with native FP8 Tensor Cores), it provides:

- A modern **Steam-style visual library** with on-demand disk scanning
- **Real-time icon extraction** from 64-bit game executables
- **Intelligent heuristic detection** of the correct game binary (resolves `Retail\`, `bin\x64\`, `Binaries\Win64\`)
- **Universal Mode** — auto-detects Native DLSS, FSR 2/3, or XeSS and applies the optimal injection method
- **1-click installation** of DLSS 5 Neural Reconstruction powered by RenoDX v4.x, NVIDIA Streamline 2.13, and OptiScaler v0.9.4
- **Factory-calibrated default settings** auto-injected into every game with zero manual tweaking required

---

### ⚡ What's New in v1.2.2 (Major UX & Engine Upgrade)

#### 🚀 Instant Launch & On-Demand Scanning
- The application now launches instantly in milliseconds without running a blocking disk scan on startup.
- You can now choose exactly when to scan all drives or select a specific drive letter from the dropdown.

#### 📊 Real-Time Visual Progress Modal
- Scanning now displays a dedicated progress dialog with a live progress bar (0%–100%), the title of the game currently being scanned, and an accurate percentage counter.
- Buttons are safely disabled during scan to prevent double-clicks.

#### 🎮 Deep Unreal Engine Plugin Architecture Support
- Upgraded game tree resolution to search up to **12 directory levels deep**.
- Seamlessly discovers DLSS and Streamline plugins located deep inside engine directories (such as `Engine\Plugins\Runtime\Nvidia\DLSS\Binaries\ThirdParty\Win64\nvngx_dlss.dll` in *Icarus*, *S.T.A.L.K.E.R. 2*, *Satisfactory*, *Tekken 8*, etc.).
- Automatically mirrors and synchronizes runtime DLLs (`nvngx_dlssnr.dll`, Streamline) into engine plugin directories with full individual backup.

#### 🧠 Automatic Pre-Configured Community Settings
- ReShade configuration is now automatically written with the exact `[RenoDX.DLSS5]` section that the addon parses:
  - **`NeuralUplift = 1`** — DLSS 5 active immediately upon game launch
  - **`NRAutoMask = 1`** — Automatic Skin Masking enabled to prevent character facial warping
  - **`NRSkinStructure = -0.50`** — Facial smoothing to reduce harsh pores and artificial wrinkles
  - **`NRPreset = 2`** — Preset #2 (Cinematic / Physical Lighting & Contact Shadows)
  - **`NRStyle = 1`** — Cinematic Style with balanced dynamic range
  - **`NRIntensity = 0.85`** — Community sweet-spot intensity for crisp neural depth
  - **`NRUICorrection = 1`** — Protects HUD, crosshairs, and UI from color shifting
  - **`EnableHooks = 2`** — Safe NGX hook mode that prevents boot crashes
  - **Hotkey `[F6]` (VK 117)** — Real-time on/off comparison on the same frame
  - **Hotkey `[F5]` (VK 116)** — Perfect A/B screenshot mode

#### 🛡️ Safe Reinstallation ("Install Over")
- Fixed the ReShade installer error code 1 when installing over an existing install without removing first.
- The installer now reuses existing verified ReShade binaries (`d3d12.dll` / `dxgi.dll`) and updates configs, addons, and Streamline modules cleanly.
- Preserves the pristine initial factory backup across repeated reinstallations.

#### 🌐 Instant Language Switch
- Switching between English and Portuguese now re-badges all library items instantly without re-scanning disks.

---

### ✨ All Features

| Feature | Description |
|---|---|
| 🎮 **Steam-Style Game Library** | Scans drives (C:, D:, E:…) on demand for games from Steam, Epic, Xbox, GOG, EA, Ubisoft, and custom folders. |
| 📊 **Real-Time Progress Modal** | Visual scanning dialog with progress bar, active game path, and live percentage counter. |
| 🖼️ **Real Executable Icons** | Extracts high-resolution icons from 64-bit game binaries in real time. |
| 🎯 **Smart Executable Detection** | Heuristic resolver ignores anti-cheat wrappers (EAC, BattlEye, Vanguard), crash reporters, launchers, and server binaries. |
| 🏗️ **Unreal Engine Deep Support** | Detects engine-level DLSS plugins up to 12 levels deep (e.g. *Icarus*, *S.T.A.L.K.E.R. 2*). |
| 🌉 **Universal Mode** | Auto-detects Native DLSS, FSR2/3, or XeSS and chooses between Direct injection or OptiScaler Bridge. |
| ⚡ **1-Click Install** | Injects `renodx-dlss5.addon64`, `nvngx_dlssnr.dll`, Streamline 2.13 modules, or OptiScaler v0.9.4 bridge files. |
| ⚙️ **Auto-Injected Presets** | Injects Preset #2 Cinematic, Auto Skin Mask, 0.85 Intensity, and UI correction out of the box. |
| 📸 **F5 Screenshot A/B** | Capture perfect before/after comparison screenshots with DLSS 5 neural rendering on vs. off. |
| 🔄 **F6 On/Off Toggle** | Toggle neural rendering on the exact same frame for instant visual comparison. |
| ▶️ **Direct Game Launch** | Launch the game directly from the installer interface. |
| ↩️ **1-Click Factory Restore** | Backs up original files before modification. Removes all injected files and restores originals with zero corruption. |
| 🛡️ **Confirmation Dialogs** | Yes/No confirmation before install and before factory restore to prevent accidental modifications. |
| 🔍 **Installed State Detection** | Shows whether DLSS 5 is already installed on the selected game and which mode is active. |
| 🌐 **Bilingual UI (EN/PT-BR)** | Instant toggle between English and Portuguese — all labels, badges, messages, and dialogs switch in real time. |
| 📂 **Open Game Folder** | One-click button to open the injection folder in Windows Explorer. |
| 📖 **In-Game Optimization Guide** | Built-in step-by-step instructions for configuring DLSS 5 inside the game. |
| 🧹 **Legacy Addon Cleanup** | Automatically removes obsolete addon versions (++, v3) on reinstall. |
| 🔎 **Game Search Filter** | Type in the search bar to filter the game library by name or path in real time. |

---

### 🚀 Quick Start Guide

1. **Download & Extract:** Download `1-Click-DLSS5-v1.2.2.zip` and extract to any folder.
2. **Launch:** Double-click **`1-Click-DLSS5.cmd`** (opens instantly).
3. **Discover Games:** Click **`[🔍 SCAN DISKS]`** or click **`[📁 BROWSE GAME]`** to pick a specific folder.
4. **Install:** Click **`[🚀 1-CLICK INSTALL DLSS 5]`** and confirm.
5. **Play:** Click **`[▶️ LAUNCH GAME]`**.
6. **In-Game Activation:**
   - **Graphics menu:**
     - *Native DLSS games:* Set **NVIDIA DLSS Super Resolution** to Quality or Performance. (Keep HDR disabled in-game for SDR neural calibration).
     - *FSR2/XeSS games:* Set **AMD FSR 2** or **Intel XeSS** to Quality (OptiScaler bridges to DLSS-NR).
   - **Pre-configured settings are already active:**
     - Auto Skin Mask: ON
     - NR Preset: #2 Cinematic
     - NR Intensity: 0.85
     - UI Correction: ON
   - **Hotkeys:**
     - Press **`F6`** to toggle DLSS 5 on/off for instant comparison on the same frame.
     - Press **`F5`** for A/B comparison screenshot mode.
     - Press **`Home`** to open the full ReShade/RenoDX overlay.

---

### 📋 Compatibility Matrix

| Game Type | Detection | Method | In-Game Setting | Notes |
|---|---|---|---|---|
| **Native DLSS**<br>*Cyberpunk 2077, Forza Horizon 5/6, HITMAN WoA, Starfield, Control, MSFS 2024, Black Myth: Wukong…* | `nvngx_dlss.dll`, `sl.dlss.dll`, etc. | `Direct` | NVIDIA DLSS Quality | Streamline 2.13 + RenoDX v4.x injected directly. |
| **Unreal Engine 4/5**<br>*Icarus, S.T.A.L.K.E.R. 2, Satisfactory, Tekken 8, Wuthering Waves…* | Deep scan (`Engine\Plugins\...\nvngx_dlss.dll`) | `Direct (Engine Synced)` | NVIDIA DLSS Quality | Automatically mirrors runtime DLLs into engine plugin directory. |
| **FSR 2/3 only**<br>*God of War, Horizon Zero Dawn, The Last of Us Part I, Ratchet & Clank…* | `ffx_fsr2_api*.dll`, `amd_fidelityfx*.dll` | `OptiScaler Bridge` | AMD FSR 2 Quality | OptiScaler v0.9.4 (`version.dll`) translates FSR2 → DLSS-NR. |
| **XeSS only**<br>*Shadow of the Tomb Raider, Dying Light 2, Arc Raiders…* | `libxess.dll`, `xess.dll` | `OptiScaler Bridge` | Intel XeSS Quality | OptiScaler v0.9.4 (`version.dll`) translates XeSS → DLSS-NR. |
| **No upscaler** | No DLSS/FSR/XeSS DLLs found | `Blocked` | N/A | Clear diagnostic message. |

---

### 📦 Package Contents

| File | Size | Description |
|---|---|---|
| `1-Click-DLSS5.cmd` | < 1 KB | Windows launcher with error trapping |
| `1-Click-DLSS5.ps1` | ~97 KB | Main program (WinForms GUI, engine sync, auto-config) |
| `payload/renodx-dlss5.addon64` | 560 KB | **RenoDX DLSS 5 Addon v4.x** — F5 A/B, F6 toggle |
| `payload/ReShade_Setup_6.8.0_Addon.exe` | 4.1 MB | Official ReShade installer with addon support |
| `payload/ReShade.ini` | < 1 KB | Pre-configured: `[RenoDX.DLSS5]` Preset #2, Skin Mask ON, Intensity 0.85 |
| `payload/streamline.zip` | 144 MB | NVIDIA Streamline 2.13 + `nvngx_dlssnr.dll` neural runtime |
| `payload/optiscaler/OptiScaler.dll` | 24.2 MB | OptiScaler v0.9.4 Universal Bridge |
| `payload/optiscaler/OptiScaler.ini` | < 1 KB | Pre-configured: overlay OFF, DLSS upscaler forced |
| `payload/optiscaler/libxess.dll` | 74.2 MB | Intel XeSS translation runtime |

---

### ⚙️ System Requirements

| Requirement | Minimum |
|---|---|
| **GPU** | NVIDIA GeForce RTX 40 Series (RTX 4060 or above) |
| **Optimal GPU** | NVIDIA GeForce RTX 50 Series |
| **OS** | Windows 10/11 x64 |
| **Graphics API** | DirectX 12 |
| **NVIDIA Driver** | 560.xx or newer |
| **PowerShell** | 5.1+ (included in Windows) |

---

### 🛡️ How It Works (Technical)

```
Game with Native DLSS / Unreal Engine:
┌──────────┐    ┌────────────────┐    ┌─────────────────────────┐
│ Game.exe │───▶│ dxgi/d3d12.dll │───▶│ renodx-dlss5            │
│          │    │ (ReShade 6.8)  │    │ .addon64 (v4.x)         │
│          │    └────────────────┘    └─────────────────────────┘
│          │───▶│ nvngx_dlssnr.dll (Streamline 2.13 Neural Runtime)
│          │───▶│ ReShade.ini [RenoDX.DLSS5] (Preset #2, 0.85, AutoMask)
└──────────┘
      │
      └──▶ [Engine\Plugins\...\nvngx_dlss.dll synced & backed up]

Game with FSR2/XeSS only:
┌──────────┐    ┌────────────────┐    ┌─────────────────────────┐
│ Game.exe │───▶│ dxgi.dll       │───▶│ renodx-dlss5            │
│          │    │ (ReShade 6.8)  │    │ .addon64 (v4.x)         │
│          │    └────────────────┘    └─────────────────────────┘
│          │───▶│ version.dll (OptiScaler v0.9.4)                │
│          │    │  ├─ Hooks FSR2/XeSS API calls                  │
│          │    │  ├─ Redirects to nvngx_dlssnr.dll              │
│          │    │  └─ Uses libxess.dll for XeSS translation       │
└──────────┘
```

---

<br>

## Português (Brasil)

### 🌟 Visão Geral

O **1 Click DLSS 5** é uma central completa e automatizada de injeção e gerenciamento de Renderização Neural DLSS 5 para Windows. Projetado especificamente para GPUs NVIDIA GeForce Séries RTX 40 e RTX 50 (com Tensor Cores FP8 nativos de 4ª e 5ª Geração), oferece:

- **Biblioteca visual estilo Steam** com escaneamento sob demanda (sem travamento ao abrir)
- **Janela de progresso visual em tempo real** durante a varredura dos jogos
- **Extração de ícones em tempo real** dos executáveis de 64-bit
- **Detecção inteligente** do executável correto (resolve `Retail\`, `bin\x64\`, `Binaries\Win64\`)
- **Suporte profundo à Unreal Engine 4/5** com detecção de plugins até 12 níveis de profundidade
- **Modo Universal** — detecta automaticamente DLSS nativo, FSR 2/3 ou XeSS e aplica o método ideal
- **Instalação em 1-clique** com configurações ideais de fábrica auto-aplicadas

---

### ⚡ Novidades da Versão 1.2.2 (Atualização de UX e Engine)

#### 🚀 Abertura Instantânea & Escaneamento Sob Demanda
- O programa agora abre em milissegundos sem travar ou forçar escaneamento de todos os discos na inicialização.
- Você escolhe quando escanear todos os discos ou seleciona uma unidade específica no menu dropdown.

#### 📊 Janela Visual de Progresso em Tempo Real
- Ao clicar em `ESCANEAR DISCOS`, abre-se uma tela dedicada com barra de progresso animada (0%–100%), nome do jogo sendo analisado no momento e contador de porcentagem.
- Os botões de scan e busca ficam protegidos contra cliques duplos.

#### 🎮 Suporte Profundo à Arquitetura de Plugins da Unreal Engine
- Varredura aprofundada em até **12 níveis de pastas**.
- Reconhece automaticamente plugins de DLSS da Unreal Engine localizados no diretório `Engine\Plugins\Runtime\Nvidia\DLSS\...` (como no *Icarus*, *S.T.A.L.K.E.R. 2*, *Satisfactory*, *Tekken 8*, etc.).
- Sincroniza e espelha os binários neurais (`nvngx_dlssnr.dll` e Streamline) na pasta de plugins com backup individual de segurança.

#### 🧠 Configurações Ideais de Fábrica Pré-Injetadas
- O `ReShade.ini` agora recebe automaticamente a seção exata **`[RenoDX.DLSS5]`** que o addon lê no binário:
  - **`NeuralUplift = 1`** — DLSS 5 Neural ativo imediatamente ao iniciar o jogo
  - **`NRAutoMask = 1`** — Auto Skin Mask ativado para evitar distorção ou envelhecimento em rostos
  - **`NRSkinStructure = -0.50`** — Suavização de pele natural para modelos humanos
  - **`NRPreset = 2`** — Preset #2 (Cinematic / Iluminação Coerente e Sombras de Contato)
  - **`NRStyle = 1`** — Estilo Cinematográfico
  - **`NRIntensity = 0.85`** — Ponto ideal (*sweet spot*) de intensidade e nitidez neural
  - **`NRUICorrection = 1`** — Protege miras, HUD e textos contra troca de cores
  - **`EnableHooks = 2`** — Modo Seguro NGX que evita travamentos no boot do jogo
  - **Tecla `[F6]`** — Atalho para ligar/desligar em tempo real no mesmo frame
  - **Tecla `[F5]`** — Modo screenshot comparativo A/B

#### 🛡️ Reinstalação Segura ("Instalar por Cima")
- Corrigido o erro de código de saída 1 do instalador do ReShade quando você tenta instalar novamente sem remover antes.
- O programa agora reconhece que o ReShade já está funcional, reutiliza o binário e atualiza instantaneamente as configurações e DLLs do Streamline/RenoDX.
- O backup original da primeira instalação é 100% preservado.

#### 🌐 Troca Instantânea de Idioma
- A alternância entre Português e Inglês atualiza os selos e textos da biblioteca na hora sem re-escanear o disco.

---

### ✨ Todos os Recursos

| Recurso | Descrição |
|---|---|
| 🎮 **Biblioteca Estilo Steam** | Escaneia discos (C:, D:, E:…) sob demanda para jogos da Steam, Epic, Xbox, GOG, EA, Ubisoft e pastas personalizadas. |
| 📊 **Janela de Progresso em Tempo Real** | Modal visual com barra de carregamento, caminho do jogo e porcentagem exata. |
| 🖼️ **Ícones Reais do Executável** | Extrai ícones de alta resolução dos binários de 64-bit em tempo real. |
| 🎯 **Detecção Inteligente de Executável** | Ignora anti-cheat (EAC, BattlEye, Vanguard), crash reporters, launchers e binários de servidor. |
| 🏗️ **Suporte a Plugins Unreal Engine** | Detecção profunda em até 12 níveis para jogos UE4/UE5 com injeção sincronizada. |
| 🌉 **Modo Universal** | Detecta automaticamente DLSS nativo, FSR 2/3 ou XeSS e escolhe entre injeção Direta ou Ponte OptiScaler. |
| ⚡ **Instalação em 1-Clique** | Injeta `renodx-dlss5.addon64`, `nvngx_dlssnr.dll`, módulos Streamline 2.13 ou ponte OptiScaler v0.9.4. |
| ⚙️ **Padrões de Fábrica Ideais** | Grava automaticamente Preset #2 Cinematic, Auto Skin Mask, Intensidade 0.85 e correção de UI. |
| 📸 **F5 Screenshot A/B** | Capture comparações antes/depois com renderização neural ligada vs. desligada. |
| 🔄 **F6 Toggle On/Off** | Alterne a renderização neural no mesmo frame para comparação visual instantânea. |
| ▶️ **Iniciar Jogo Direto** | Abra o jogo diretamente pela interface do instalador. |
| ↩️ **Restauração de Fábrica em 1-Clique** | Faz backup dos originais, remove todos os arquivos injetados e restaura os originais com zero corrupção. |
| 🛡️ **Diálogos de Confirmação** | Confirmação Sim/Não antes de instalar e antes de restaurar para prevenir modificações acidentais. |
| 🔍 **Detecção de Estado Instalado** | Mostra se o DLSS 5 já está instalado no jogo selecionado e qual modo está ativo. |
| 🌐 **Interface Bilíngue (EN/PT-BR)** | Alternância instantânea entre Inglês e Português — todos os textos, badges e mensagens mudam em tempo real. |
| 📂 **Abrir Pasta do Jogo** | Botão para abrir a pasta de injeção no Windows Explorer. |
| 📖 **Guia de Otimização no Jogo** | Instruções passo-a-passo integradas para configurar o DLSS 5 dentro do jogo. |
| 🧹 **Limpeza de Addons Legados** | Remove automaticamente versões antigas do addon (++, v3) ao reinstalar. |
| 🔎 **Filtro de Pesquisa** | Digite na barra de pesquisa para filtrar a biblioteca de jogos por nome ou caminho em tempo real. |

---

### 🚀 Guia de Uso Rápido

1. **Baixar e Extrair:** Baixe `1-Click-DLSS5-v1.2.2.zip` e extraia para qualquer pasta.
2. **Executar:** Dê dois cliques em **`1-Click-DLSS5.cmd`** (abre na hora).
3. **Escanear Jogos:** Clique em **`[🔍 ESCANEAR DISCOS]`** ou em **`[📁 PROCURAR JOGO]`**.
4. **Instalar:** Clique em **`[🚀 INSTALAR DLSS 5 EM 1-CLIQUE]`** e confirme.
5. **Jogar:** Clique em **`[▶️ INICIAR JOGO]`**.
6. **No Jogo:**
   - **Menu gráfico:**
     - *Jogos com DLSS nativo:* Ative **NVIDIA DLSS Super Resolution** (Qualidade ou Desempenho). (Mantenha o HDR desativado no jogo para calibração SDR precisa).
     - *Jogos com FSR2/XeSS:* Ative **AMD FSR 2** ou **Intel XeSS** no modo Qualidade (OptiScaler redireciona para DLSS-NR).
   - **Configurações recomendadas já ativas:**
     - Auto Skin Mask: ATIVADO
     - NR Preset: #2 Cinematic
     - Intensidade Neural: 0.85
     - Correção de UI: ATIVADO
   - **Teclas de atalho:**
     - **`F6`** para ligar/desligar no mesmo frame para comparação.
     - **`F5`** para screenshot A/B.
     - **`Home`** para abrir o menu do ReShade/RenoDX.

---

### 📋 Matriz de Compatibilidade

| Tipo de Jogo | Detecção | Método | Opção no Jogo | Observações |
|---|---|---|---|---|
| **DLSS Nativo**<br>*Cyberpunk 2077, Forza Horizon 5/6, HITMAN WoA, Starfield, Control, MSFS 2024, Black Myth: Wukong…* | `nvngx_dlss.dll`, `sl.dlss.dll`, etc. | `Direto` | NVIDIA DLSS Qualidade | Streamline 2.13 + RenoDX v4.x injetados diretamente. |
| **Unreal Engine 4/5**<br>*Icarus, S.T.A.L.K.E.R. 2, Satisfactory, Tekken 8, Wuthering Waves…* | Varredura profunda (`Engine\Plugins\...\nvngx_dlss.dll`) | `Direto (Sync de Engine)` | NVIDIA DLSS Qualidade | Sincroniza e faz backup automático nos diretórios de plugins. |
| **Apenas FSR 2/3**<br>*God of War, Horizon Zero Dawn, The Last of Us Part I, Ratchet & Clank…* | `ffx_fsr2_api*.dll`, `amd_fidelityfx*.dll` | `Ponte OptiScaler` | AMD FSR 2 Qualidade | OptiScaler v0.9.4 (`version.dll`) converte FSR2 → DLSS-NR. |
| **Apenas XeSS**<br>*Shadow of the Tomb Raider, Dying Light 2, Arc Raiders…* | `libxess.dll`, `xess.dll` | `Ponte OptiScaler` | Intel XeSS Qualidade | OptiScaler v0.9.4 (`version.dll`) converte XeSS → DLSS-NR. |
| **Sem upscaler** | Nenhuma DLL DLSS/FSR/XeSS encontrada | `Bloqueado` | N/A | Mensagem clara de diagnóstico. |

---

### 🛡️ License & Disclaimer / Licença & Isenção de Responsabilidade

Distributed under the [MIT](LICENSE) License. / Distribuído sob a licença [MIT](LICENSE).

*Disclaimer: This software is an independent utility and is not affiliated with, endorsed by, or sponsored by NVIDIA Corporation, AMD, or Intel. NVIDIA, DLSS, RTX, GeForce, Streamline, AMD, FSR, Intel, and XeSS are trademarks or registered trademarks of their respective owners. RenoDX addon credits: Lecram-Technology Denier & @speedlemur (ControlDLSS5).*

*Aviso: Este software é uma ferramenta utilitária independente e não é afiliado, endossado ou patrocinado pela NVIDIA Corporation, AMD ou Intel. NVIDIA, DLSS, RTX, GeForce, Streamline, AMD, FSR, Intel e XeSS são marcas comerciais ou registradas de seus respectivos proprietários. Créditos do addon RenoDX: Lecram-Technology Denier & @speedlemur (ControlDLSS5).*
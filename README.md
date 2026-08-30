# 1 Click DLSS 5 🚀

<div align="center">

**Universal Neural Rendering Game Center & 1-Click Injector**  
*Empowering NVIDIA GeForce RTX 20, RTX 30, RTX 40 & RTX 50 Series GPUs with DLSS 5 Neural Reconstruction*

[![Version](https://img.shields.io/badge/version-1.3.0-brightgreen.svg)](https://github.com/reiluisii/1-Click-DLSS5)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows%2010%20%7C%2011%20x64-0078D6.svg)](https://github.com/reiluisii/1-Click-DLSS5)
[![DirectX](https://img.shields.io/badge/DirectX-12%20%7C%20DXGI-orange.svg)](https://github.com/reiluisii/1-Click-DLSS5)
[![NVIDIA](https://img.shields.io/badge/NVIDIA-RTX%2020%2C%2030%2C%2040%20%26%2050%20Series-76B900.svg)](https://nvidia.com)
[![RenoDX](https://img.shields.io/badge/RenoDX-v4.55%20Addon-FF6B6B.svg)](https://github.com/reiluisii/1-Click-DLSS5)
[![OptiScaler](https://img.shields.io/badge/OptiScaler-v0.9.4%20Bridge-purple.svg)](https://github.com/reiluisii/1-Click-DLSS5)

[English](#english) • [Português (Brasil)](#português-brasil)

</div>

---

## English

### 🌟 Overview

**1 Click DLSS 5** is an all-in-one, automated Neural Rendering game center and injection engine for Windows. Built for the entire **NVIDIA GeForce RTX lineup (RTX 20, RTX 30, RTX 40 & RTX 50 Series)**, it provides:

- A modern **Steam-style visual library** with on-demand disk scanning (zero startup lag)
- **Universal GPU Architecture** — patched `nvngx_dlssnr.dll` neural runtime running natively across RTX 20, 30, 40, and 50 Series GPUs
- **RE Engine Support** — enhanced compatibility for Capcom's RE Engine (*Resident Evil 4 Remake*, *Resident Evil Village*, *Dragon's Dogma 2*, *Monster Hunter*, etc.) via RenoDX v4.55
- **Real-time icon extraction** from 64-bit game executables
- **Intelligent heuristic detection** of the correct game binary (resolves `Retail\`, `bin\x64\`, `Binaries\Win64\`)
- **Universal Mode** — auto-detects Native DLSS, FSR 2/3, or XeSS and applies the optimal injection method
- **1-click installation** of DLSS 5 Neural Reconstruction powered by RenoDX v4.55, NVIDIA Streamline 2.13, and OptiScaler v0.9.4
- **Factory-calibrated default settings** auto-injected into every game with zero manual tweaking required

---

### ⚡ What's New in v1.3.0

#### 🎮 Full Universal RTX 20, 30, 40 & 50 Series Support
- Integrated the new patched **`nvngx_dlssnr.dll`** neural runtime (158.16 MB) by ShortFuse.
- Enables DLSS 5 Neural Reconstruction across **Turing (RTX 20 Series)**, **Ampere (RTX 30 Series)**, **Ada Lovelace (RTX 40 Series)**, and **Blackwell (RTX 50 Series)** GPUs with identical rendering quality!

#### 🧟 RE Engine & Universal Engine Compatibility (RenoDX v4.55)
- Upgraded to **`renodx-dlss5.addon64` v4.55** (1.62 MB) by Krish.
- Delivers native hook compatibility for Capcom RE Engine titles (*Resident Evil 4 Remake*, *Resident Evil 2/3/7/Village*, *Dragon's Dogma 2*, *Street Fighter 6*, *Monster Hunter*) and other custom DirectX 12 game engines.

#### 🧪 Experimental Mode for Non-Upscaled Games
- Allows users to test the OptiScaler Universal Bridge on unsupported games with explicit safety warnings and 1-click factory restore.

---

### ✨ All Features

| Feature | Description |
|---|---|
| 🎮 **Steam-Style Game Library** | Scans drives (C:, D:, E:…) on demand for games from Steam, Epic, Xbox, GOG, EA, Ubisoft, and custom folders. |
| ⚡ **Universal GPU Support** | Fully supports NVIDIA GeForce RTX 2060 all the way up to RTX 5090. |
| 🧟 **RE Engine Compatible** | Full support for Resident Evil, Dragon's Dogma, Monster Hunter, and other RE Engine games. |
| 📊 **Real-Time Progress Modal** | Visual scanning dialog with progress bar, active game path, and live percentage counter. |
| 🖼️ **Real Executable Icons** | Extracts high-resolution icons from 64-bit game binaries in real time. |
| 🎯 **Smart Executable Detection** | Heuristic resolver ignores anti-cheat wrappers (EAC, BattlEye, Vanguard), crash reporters, launchers, and server binaries. |
| 🏗️ **Unreal Engine Deep Support** | Detects engine-level DLSS plugins up to 12 levels deep (e.g. *Icarus*, *S.T.A.L.K.E.R. 2*). |
| 🌉 **Universal Mode** | Auto-detects Native DLSS, FSR2/3, or XeSS and chooses between Direct injection or OptiScaler Bridge. |
| ⚡ **1-Click Install** | Injects `renodx-dlss5.addon64` v4.55, `nvngx_dlssnr.dll`, Streamline 2.13 modules, or OptiScaler v0.9.4 bridge files. |
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

---

### 🚀 Quick Start Guide

1. **Download & Extract:** Download `1-Click-DLSS5-v1.3.0.zip` and extract to any folder.
2. **Launch:** Double-click **`1-Click-DLSS5.cmd`** (opens instantly).
3. **Discover Games:** Click **`[🔍 SCAN DISKS]`** or click **`[📁 BROWSE GAME]`** to pick a specific folder.
4. **Install:** Click **`[🚀 1-CLICK INSTALL DLSS 5]`** and confirm.
5. **Play:** Click **`[▶️ LAUNCH GAME]`**.
6. **In-Game Activation:**
   - **Graphics menu:**
     - *Native DLSS games:* Set **NVIDIA DLSS Super Resolution** to Quality or Performance.
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

| Game Type / Engine | Detection | Method | In-Game Setting | Notes |
|---|---|---|---|---|
| **Native DLSS Games**<br>*Cyberpunk 2077, Forza Horizon 5/6, HITMAN WoA, Starfield, Control, MSFS 2024, Black Myth: Wukong…* | `nvngx_dlss.dll`, `sl.dlss.dll`, etc. | `Direct` | NVIDIA DLSS Quality | Streamline 2.13 + RenoDX v4.55 injected directly. |
| **Capcom RE Engine**<br>*Resident Evil 4 Remake, RE Village, RE 2/3 Remake, Dragon's Dogma 2, Monster Hunter, Street Fighter 6…* | RE Engine DLSS binaries | `Direct (RE Engine)` | NVIDIA DLSS Quality | RenoDX v4.55 native RE Engine hook support. |
| **Unreal Engine 4/5**<br>*Icarus, S.T.A.L.K.E.R. 2, Satisfactory, Tekken 8, Wuthering Waves…* | Deep scan (`Engine\Plugins\...\nvngx_dlss.dll`) | `Direct (Engine Synced)` | NVIDIA DLSS Quality | Automatically mirrors runtime DLLs into engine plugin directory. |
| **FSR 2/3 only**<br>*God of War, Horizon Zero Dawn, The Last of Us Part I, Ratchet & Clank…* | `ffx_fsr2_api*.dll`, `amd_fidelityfx*.dll` | `OptiScaler Bridge` | AMD FSR 2 Quality | OptiScaler v0.9.4 (`version.dll`) translates FSR2 → DLSS-NR. |
| **XeSS only**<br>*Shadow of the Tomb Raider, Dying Light 2, Arc Raiders…* | `libxess.dll`, `xess.dll` | `OptiScaler Bridge` | Intel XeSS Quality | OptiScaler v0.9.4 (`version.dll`) translates XeSS → DLSS-NR. |

---

### 📦 Package Contents

| File | Size | Description |
|---|---|---|
| `1-Click-DLSS5.cmd` | < 1 KB | Windows launcher with error trapping |
| `1-Click-DLSS5.ps1` | ~97 KB | Main program (WinForms GUI, engine sync, auto-config) |
| `payload/renodx-dlss5.addon64` | 1.62 MB | **RenoDX DLSS 5 Addon v4.55** — RE Engine support, F5 A/B, F6 toggle |
| `payload/ReShade_Setup_6.8.0_Addon.exe` | 4.1 MB | Official ReShade installer with addon support |
| `payload/ReShade.ini` | < 1 KB | Pre-configured: `[RenoDX.DLSS5]` Preset #2, Skin Mask ON, Intensity 0.85 |
| `payload/streamline.zip` | 147 MB | NVIDIA Streamline 2.13 + **Universal RTX 20/30/40/50 `nvngx_dlssnr.dll`** |
| `payload/optiscaler/OptiScaler.dll` | 24.2 MB | OptiScaler v0.9.4 Universal Bridge |
| `payload/optiscaler/OptiScaler.ini` | < 1 KB | Pre-configured: overlay OFF, DLSS upscaler forced |
| `payload/optiscaler/libxess.dll` | 74.2 MB | Intel XeSS translation runtime |

---

<br>

## Português (Brasil)

### 🌟 Visão Geral

O **1 Click DLSS 5** é uma central completa e automatizada de injeção e gerenciamento de Renderização Neural DLSS 5 para Windows. Projetado para **toda a linha NVIDIA GeForce RTX (Séries RTX 20, RTX 30, RTX 40 e RTX 50)**, oferece:

- **Biblioteca visual estilo Steam** com escaneamento sob demanda (sem travamento na inicialização)
- **Arquitetura Universal de GPUs** — runtime neural `nvngx_dlssnr.dll` patcheado para rodar nativamente em placas RTX 20, 30, 40 e 50 com a mesma qualidade de renderização
- **Suporte Oficial à RE Engine** — compatibilidade aprimorada para os jogos da Capcom (*Resident Evil 4 Remake*, *Resident Evil Village*, *Dragon's Dogma 2*, *Monster Hunter*, etc.) via RenoDX v4.55
- **Janela de progresso visual em tempo real** durante a varredura dos jogos
- **Extração de ícones em tempo real** dos executáveis de 64-bit
- **Detecção inteligente** do executável correto (resolve `Retail\`, `bin\x64\`, `Binaries\Win64\`)
- **Suporte profundo à Unreal Engine 4/5** com detecção de plugins até 12 níveis de profundidade
- **Modo Universal** — detecta automaticamente DLSS nativo, FSR 2/3 ou XeSS e aplica o método ideal
- **Instalação em 1-clique** com configurações ideais de fábrica auto-aplicadas

---

### ⚡ Novidades da Versão 1.3.0

#### 🎮 Suporte Universal Completo a GPUs RTX Séries 20, 30, 40 e 50
- Integrado o novo runtime neural **`nvngx_dlssnr.dll`** (158.16 MB) patcheado por ShortFuse.
- Permite que placas **RTX 2060/2070/2080 (Turing)** e **RTX 3060/3070/3080/3090 (Ampere)** executem a reconstrução neural DLSS 5 com a mesma fidelidade das séries RTX 40 e 50!

#### 🧟 Suporte à RE Engine da Capcom e Outras Engines (RenoDX v4.55)
- Atualizado para o **`renodx-dlss5.addon64` v4.55** (1.62 MB) criado por Krish.
- Traz compatibilidade nativa de injeção para jogos na RE Engine (*Resident Evil 4 Remake*, *Resident Evil 2/3/7/Village*, *Dragon's Dogma 2*, *Street Fighter 6*, *Monster Hunter*) e outros motores DirectX 12 customizados.

#### 🧪 Modo Experimental com Ponte Universal
- Permite aos usuários testarem a Ponte Universal OptiScaler em jogos sem upscaler nativo com avisos de segurança claros e restauração original em 1-clique.

---

### ✨ Todos os Recursos

| Recurso | Descrição |
|---|---|
| 🎮 **Biblioteca Estilo Steam** | Escaneia discos (C:, D:, E:…) sob demanda para jogos da Steam, Epic, Xbox, GOG, EA, Ubisoft e pastas personalizadas. |
| ⚡ **Suporte Universal a RTX** | Compatível com toda a linha NVIDIA GeForce: RTX 2060 até RTX 5090. |
| 🧟 **Compatível com RE Engine** | Suporte a Resident Evil, Dragon's Dogma, Monster Hunter e outros títulos Capcom. |
| 📊 **Janela de Progresso em Tempo Real** | Modal visual com barra de carregamento, caminho do jogo e porcentagem exata. |
| 🖼️ **Ícones Reais do Executável** | Extrai ícones de alta resolução dos binários de 64-bit em tempo real. |
| 🎯 **Detecção Inteligente de Executável** | Ignora anti-cheat (EAC, BattlEye, Vanguard), crash reporters, launchers e binários de servidor. |
| 🏗️ **Suporte a Plugins Unreal Engine** | Detecção profunda em até 12 níveis para jogos UE4/UE5 com injeção sincronizada. |
| 🌉 **Modo Universal** | Detecta automaticamente DLSS nativo, FSR 2/3 ou XeSS e escolhe entre injeção Direta ou Ponte OptiScaler. |
| ⚡ **Instalação em 1-Clique** | Injeta `renodx-dlss5.addon64` v4.55, `nvngx_dlssnr.dll`, módulos Streamline 2.13 ou ponte OptiScaler v0.9.4. |
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

---

### 🚀 Guia de Uso Rápido

1. **Baixar e Extrair:** Baixe `1-Click-DLSS5-v1.3.0.zip` e extraia para qualquer pasta.
2. **Executar:** Dê dois cliques em **`1-Click-DLSS5.cmd`** (abre na hora).
3. **Escanear Jogos:** Clique em **`[🔍 ESCANEAR DISCOS]`** ou em **`[📁 PROCURAR JOGO]`**.
4. **Instalar:** Clique em **`[🚀 INSTALAR DLSS 5 EM 1-CLIQUE]`** e confirme.
5. **Jogar:** Clique em **`[▶️ INICIAR JOGO]`**.
6. **No Jogo:**
   - **Menu gráfico:**
     - *Jogos com DLSS nativo:* Ative **NVIDIA DLSS Super Resolution** (Qualidade ou Desempenho).
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

| Tipo de Jogo / Engine | Detecção | Método | Opção no Jogo | Observações |
|---|---|---|---|---|
| **DLSS Nativo**<br>*Cyberpunk 2077, Forza Horizon 5/6, HITMAN WoA, Starfield, Control, MSFS 2024, Black Myth: Wukong…* | `nvngx_dlss.dll`, `sl.dlss.dll`, etc. | `Direto` | NVIDIA DLSS Qualidade | Streamline 2.13 + RenoDX v4.55 injetados diretamente. |
| **Capcom RE Engine**<br>*Resident Evil 4 Remake, RE Village, RE 2/3 Remake, Dragon's Dogma 2, Monster Hunter, Street Fighter 6…* | Binários DLSS da RE Engine | `Direto (RE Engine)` | NVIDIA DLSS Qualidade | RenoDX v4.55 com hooks nativos da engine. |
| **Unreal Engine 4/5**<br>*Icarus, S.T.A.L.K.E.R. 2, Satisfactory, Tekken 8, Wuthering Waves…* | Varredura profunda (`Engine\Plugins\...\nvngx_dlss.dll`) | `Direto (Sync de Engine)` | NVIDIA DLSS Qualidade | Sincroniza e faz backup automático nos diretórios de plugins. |
| **Apenas FSR 2/3**<br>*God of War, Horizon Zero Dawn, The Last of Us Part I, Ratchet & Clank…* | `ffx_fsr2_api*.dll`, `amd_fidelityfx*.dll` | `Ponte OptiScaler` | AMD FSR 2 Qualidade | OptiScaler v0.9.4 (`version.dll`) converte FSR2 → DLSS-NR. |
| **Apenas XeSS**<br>*Shadow of the Tomb Raider, Dying Light 2, Arc Raiders…* | `libxess.dll`, `xess.dll` | `Ponte OptiScaler` | Intel XeSS Qualidade | OptiScaler v0.9.4 (`version.dll`) converte XeSS → DLSS-NR. |

---

### 🛡️ License & Disclaimer / Licença & Isenção de Responsabilidade

Distributed under the [MIT](LICENSE) License. / Distribuído sob a licença [MIT](LICENSE).

*Disclaimer: This software is an independent utility and is not affiliated with, endorsed by, or sponsored by NVIDIA Corporation, AMD, Capcom, or Intel. NVIDIA, DLSS, RTX, GeForce, Streamline, AMD, FSR, Intel, XeSS, RE Engine, and Capcom are trademarks or registered trademarks of their respective owners. RenoDX addon credits: ShortFuse, Krish, Lecram-Technology Denier & @speedlemur (ControlDLSS5).*
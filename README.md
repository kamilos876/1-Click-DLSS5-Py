# 1 Click DLSS 5 🚀

<div align="center">

**Universal Neural Rendering Game Center & 1-Click Injector**  
*Empowering RTX 40 & RTX 50 Series GPUs with Next-Generation DLSS 5 Neural Reconstruction*

[![Version](https://img.shields.io/badge/version-1.2.0-brightgreen.svg)](https://github.com/reiluisii/1-Click-DLSS5)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows%2010%20%7C%2011%20x64-0078D6.svg)](https://github.com/reiluisii/1-Click-DLSS5)
[![DirectX](https://img.shields.io/badge/DirectX-12%20%7C%20DXGI-orange.svg)](https://github.com/reiluisii/1-Click-DLSS5)
[![NVIDIA](https://img.shields.io/badge/NVIDIA-RTX%2040%20%26%2050%20Series-76B900.svg)](https://nvidia.com)
[![RenoDX](https://img.shields.io/badge/RenoDX-v4.1%20Addon-FF6B6B.svg)](https://github.com/reiluisii/1-Click-DLSS5)
[![OptiScaler](https://img.shields.io/badge/OptiScaler-v0.9.4%20Bridge-purple.svg)](https://github.com/reiluisii/1-Click-DLSS5)

[English](#english) • [Português (Brasil)](#português-brasil)

</div>

---

## English

### 🌟 Overview

**1 Click DLSS 5** is an all-in-one, automated Neural Rendering game center and injection engine for Windows. Built for NVIDIA GeForce RTX 40 & RTX 50 Series GPUs, it provides:

- A modern **Steam-style visual library** with automatic game discovery across all drives
- **Real-time icon extraction** from 64-bit game executables
- **Intelligent heuristic detection** of the correct game binary (resolves `Retail\`, `bin\x64\`, `Binaries\Win64\`)
- **Universal Mode** — auto-detects Native DLSS, FSR2/3, or XeSS and applies the optimal injection method
- **1-click installation** of DLSS 5 Neural Reconstruction powered by RenoDX v4.1, NVIDIA Streamline 2.13, and OptiScaler v0.9.4

---

### ⚡ What's New in v1.2.0

#### 🌉 Universal Mode / OptiScaler Bridge
Automatically detects the upscaler technology present in each game and applies the optimal method:
- **Games with native DLSS** → Direct injection of Streamline 2.13 + `renodx-dlss5.addon64`
- **Games with FSR 2/3 or XeSS only** → OptiScaler v0.9.4 Bridge (`version.dll` + `dxgi.dll`) transparently translates FSR2/XeSS calls to DLSS-NR neural reconstruction
- **Games without any upscaler** → Installation blocked with clear diagnostic guidance

#### 🎯 RenoDX Addon v4.1 (Upgraded from Build 2.5)
- **F5 — Screenshot A/B Mode:** Capture perfect side-by-side comparison screenshots
- **F6 — On/Off Comparison Hotkey (WIP):** Toggle neural rendering on the same frame for instant A/B comparison
- **Improved RTX 3000–5000 Series Compatibility:** Better support across all RTX generations with correct DLL

#### 🛡️ Safety & UX
- **Confirmation dialogs** before install and before factory restore
- **Installed state detection** — shows `[ALREADY INSTALLED]` with active mode (Direct or OptiScaler Bridge)
- **Granular backup & restore** — every file is backed up individually; factory restore is 100% clean
- **Legacy addon auto-cleanup** — removes obsolete addon versions on reinstall
- **Pre-configured ReShade.ini** — Auto Skin Mask ON, Preset #2 Cinematic, Neural Intensity 0.80, HDR OFF

#### 🐛 Bug Fixes
- Fixed language toggle not updating Verify button text
- Fixed manual browse not detecting FSR2/XeSS games
- Fixed duplicate entries in uninstall purge list
- Fixed encoding crash on PowerShell 5.1 (UTF-8 BOM enforced)
- CMD launcher now shows errors instead of closing silently

---

### ✨ All Features

| Feature | Description |
|---|---|
| 🎮 **Steam-Style Game Library** | Scans all drives (C:, D:, E:…) for games from Steam, Epic, Xbox, GOG, EA, Ubisoft, and custom folders. Games are ranked by DLSS 5 compatibility. |
| 🖼️ **Real Executable Icons** | Extracts high-resolution icons from 64-bit game binaries in real time. |
| 🎯 **Smart Executable Detection** | Heuristic resolver ignores anti-cheat wrappers (EAC, BattlEye, Vanguard), crash reporters, launchers, and server binaries. Finds the correct game executable automatically. |
| 🌉 **Universal Mode** | Auto-detects Native DLSS, FSR2/3, or XeSS and chooses between Direct injection or OptiScaler Bridge. |
| ⚡ **1-Click Install** | Injects `renodx-dlss5.addon64` v4.1, `nvngx_dlssnr.dll`, Streamline 2.13 modules, or OptiScaler v0.9.4 bridge files — all in under a second. |
| 🔍 **Pre-Install Verification** | Checks GPU model, driver version, DirectX support, payload integrity, and upscaler availability before installing. |
| 📸 **F5 Screenshot A/B** | Capture perfect before/after comparison screenshots with DLSS 5 neural rendering on vs. off. |
| 🔄 **F6 On/Off Toggle (WIP)** | Toggle neural rendering on the same frozen frame for instant visual comparison. |
| ▶️ **Direct Game Launch** | Launch the game directly from the installer interface. |
| ↩️ **1-Click Factory Restore** | Backs up original files before modification. Removes all injected files and restores originals with zero corruption. |
| 🛡️ **Confirmation Dialogs** | Yes/No confirmation before install and before factory restore to prevent accidental modifications. |
| 🔍 **Installed State Detection** | Shows whether DLSS 5 is already installed on the selected game and which mode is active. |
| 🌐 **Bilingual UI (EN/PT-BR)** | Instant toggle between English and Portuguese — all labels, badges, messages, and dialogs switch in real time. |
| 📂 **Open Game Folder** | One-click button to open the injection folder in Windows Explorer. |
| 📖 **In-Game Optimization Guide** | Built-in step-by-step instructions for configuring DLSS 5 inside the game. |
| 🧹 **Legacy Addon Cleanup** | Automatically removes obsolete addon versions (++, v3) on reinstall. |
| ⚙️ **Pre-Configured Settings** | ReShade.ini ships with optimal defaults: Auto Skin Mask enabled, Preset #2 Cinematic, Neural Intensity 0.80, HDR disabled. |
| 🔎 **Game Search Filter** | Type in the search bar to filter the game library by name or path in real time. |

---

### 🚀 Quick Start Guide

1. **Download & Extract:** Download `1-Click-DLSS5-v1.2.0.zip` and extract to any folder.
2. **Launch:** Double-click **`1-Click-DLSS5.cmd`**.
3. **Select Your Game:** Pick from the auto-populated library or click **`[📁 BROWSE GAME]`**.
4. **Install:** Click **`[🚀 1-CLICK INSTALL DLSS 5]`** and confirm.
5. **Play:** Click **`[▶️ LAUNCH GAME]`**.
6. **In-Game Activation:**
   - **Graphics menu:**
     - *Native DLSS games:* Set **NVIDIA DLSS Super Resolution** to Quality or Performance.
     - *FSR2/XeSS games:* Set **AMD FSR 2** or **Intel XeSS** to Quality (OptiScaler bridges to DLSS-NR).
   - **ReShade/RenoDX overlay:**
     - Press **`[Home]`** → **Add-ons** tab → expand **DLSS 5** → set **NR Preset #2** and **NR Style: Cinematic**.
   - **Comparison hotkeys:**
     - Press **`F5`** for screenshot A/B comparison.
     - Press **`F6`** to toggle on/off on the same frame (WIP).

---

### 📋 Compatibility Matrix

| Game Type | Detection | Method | In-Game Setting | Notes |
|---|---|---|---|---|
| **Native DLSS**<br>*Cyberpunk 2077, Forza Horizon 5/6, HITMAN WoA, Starfield, Control, MSFS 2024, Black Myth: Wukong…* | `nvngx_dlss.dll`, `sl.dlss.dll`, etc. | `Direct` | NVIDIA DLSS Quality | Streamline 2.13 + RenoDX v4.1 injected directly. |
| **FSR 2/3 only**<br>*God of War, Horizon Zero Dawn, The Last of Us Part I, Ratchet & Clank…* | `ffx_fsr2_api*.dll`, `amd_fidelityfx*.dll` | `OptiScaler Bridge` | AMD FSR 2 Quality | OptiScaler v0.9.4 (`version.dll`) translates FSR2 → DLSS-NR. |
| **XeSS only**<br>*Shadow of the Tomb Raider, Dying Light 2, Arc Raiders…* | `libxess.dll`, `xess.dll` | `OptiScaler Bridge` | Intel XeSS Quality | OptiScaler v0.9.4 (`version.dll`) translates XeSS → DLSS-NR. |
| **UE4/UE5**<br>*S.T.A.L.K.E.R. 2, Tekken 8, Wuthering Waves…* | Auto-detected | `Direct or Bridge` | DLSS / FSR2 / XeSS | Injects into `Binaries\Win64\`. Method depends on available upscaler. |
| **No upscaler** | No DLSS/FSR/XeSS DLLs found | `Blocked` | N/A | Clear diagnostic message. |

---

### 📦 Package Contents

| File | Size | Description |
|---|---|---|
| `1-Click-DLSS5.cmd` | < 1 KB | Windows launcher with error trapping |
| `1-Click-DLSS5.ps1` | ~82 KB | Main program (1657 lines, WinForms GUI) |
| `payload/renodx-dlss5.addon64` | 547 KB | **RenoDX DLSS 5 Addon v4.1** — F5 A/B, F6 toggle |
| `payload/ReShade_Setup_6.8.0_Addon.exe` | 4.1 MB | Official ReShade installer with addon support |
| `payload/ReShade.ini` | < 1 KB | Pre-configured: Skin Mask ON, Preset #2, Intensity 0.80 |
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

> **Note:** RTX 3000 series is supported with improved compatibility in RenoDX v4.1 when using the correct DLL. RTX 2000 series does not have native FP8 tensor cores required for optimal DLSS-NR performance.

---

### 🛡️ How It Works (Technical)

```
Game with Native DLSS:
┌──────────┐    ┌────────────────┐    ┌───────────────────┐
│ Game.exe │───▶│ dxgi.dll       │───▶│ renodx-dlss5      │
│          │    │ (ReShade 6.8)  │    │ .addon64 (v4.1)   │
│          │    └────────────────┘    └───────────────────┘
│          │───▶│ nvngx_dlssnr.dll (Streamline 2.13 Neural Runtime)
└──────────┘

Game with FSR2/XeSS only:
┌──────────┐    ┌────────────────┐    ┌───────────────────┐
│ Game.exe │───▶│ dxgi.dll       │───▶│ renodx-dlss5      │
│          │    │ (ReShade 6.8)  │    │ .addon64 (v4.1)   │
│          │    └────────────────┘    └───────────────────┘
│          │───▶│ version.dll (OptiScaler v0.9.4)          │
│          │    │  ├─ Hooks FSR2/XeSS API calls            │
│          │    │  ├─ Redirects to nvngx_dlssnr.dll        │
│          │    │  └─ Uses libxess.dll for XeSS translation │
└──────────┘
```

---

<br>

## Português (Brasil)

### 🌟 Visão Geral

O **1 Click DLSS 5** é uma central completa e automatizada de injeção e gerenciamento de Renderização Neural DLSS 5 para Windows. Projetado para GPUs NVIDIA GeForce Séries RTX 40 e RTX 50, oferece:

- **Biblioteca visual estilo Steam** com varredura automática de jogos em todos os discos
- **Extração de ícones em tempo real** dos executáveis de 64-bit
- **Detecção inteligente** do executável correto (resolve `Retail\`, `bin\x64\`, `Binaries\Win64\`)
- **Modo Universal** — detecta automaticamente DLSS nativo, FSR2/3 ou XeSS e aplica o método ideal
- **Instalação em 1-clique** via RenoDX v4.1, NVIDIA Streamline 2.13 e OptiScaler v0.9.4

---

### ⚡ Novidades da Versão 1.2.0

#### 🌉 Modo Universal / Ponte OptiScaler
Detecta automaticamente a tecnologia de upscaling de cada jogo:
- **Jogos com DLSS nativo** → Injeção direta de Streamline 2.13 + `renodx-dlss5.addon64`
- **Jogos só com FSR 2/3 ou XeSS** → Ponte OptiScaler v0.9.4 (`version.dll` + `dxgi.dll`) converte transparentemente as chamadas FSR2/XeSS para DLSS-NR
- **Jogos sem upscaler** → Instalação bloqueada com mensagem de diagnóstico clara

#### 🎯 Addon RenoDX v4.1 (Atualizado do Build 2.5)
- **F5 — Modo Screenshot A/B:** Capture comparações perfeitas lado a lado
- **F6 — Tecla On/Off no Mesmo Frame (WIP):** Alterne a renderização neural instantaneamente para comparação visual
- **Compatibilidade RTX 3000–5000 Melhorada:** Suporte aprimorado para todas as gerações RTX com a DLL correta

#### 🛡️ Segurança e Interface
- **Diálogos de confirmação** antes de instalar e antes de restaurar de fábrica
- **Detecção de estado instalado** — badge exibe `[JÁ INSTALADO]` com o modo ativo
- **Backup e restauração granular** — cada arquivo é salvo individualmente; restauração 100% limpa
- **Limpeza automática de addons antigos** — remove versões obsoletas ao reinstalar
- **ReShade.ini pré-configurado** — Auto Skin Mask ON, Preset #2 Cinematic, Intensidade Neural 0.80, HDR OFF

#### 🐛 Correções de Bugs
- Corrigido botão Verificar que não atualizava ao trocar idioma
- Corrigida detecção manual de jogos FSR2/XeSS pelo botão Procurar
- Corrigidas entradas duplicadas na lista de desinstalação
- Corrigido crash de encoding no PowerShell 5.1 (UTF-8 BOM)
- Inicializador CMD agora mostra erros ao invés de fechar sozinho

---

### ✨ Todos os Recursos

| Recurso | Descrição |
|---|---|
| 🎮 **Biblioteca Estilo Steam** | Escaneia todos os discos (C:, D:, E:…) para jogos da Steam, Epic, Xbox, GOG, EA, Ubisoft e pastas personalizadas. Jogos são ordenados por compatibilidade. |
| 🖼️ **Ícones Reais do Executável** | Extrai ícones de alta resolução dos binários de 64-bit em tempo real. |
| 🎯 **Detecção Inteligente de Executável** | Ignora anti-cheat (EAC, BattlEye, Vanguard), crash reporters, launchers e binários de servidor. Encontra o executável correto automaticamente. |
| 🌉 **Modo Universal** | Detecta automaticamente DLSS nativo, FSR2/3 ou XeSS e escolhe entre injeção Direta ou Ponte OptiScaler. |
| ⚡ **Instalação em 1-Clique** | Injeta `renodx-dlss5.addon64` v4.1, `nvngx_dlssnr.dll`, módulos Streamline 2.13 ou ponte OptiScaler v0.9.4 em menos de um segundo. |
| 🔍 **Verificação Pré-Instalação** | Verifica GPU, driver, DirectX, integridade do pacote e disponibilidade de upscaler antes de instalar. |
| 📸 **F5 Screenshot A/B** | Capture comparações antes/depois com renderização neural ligada vs. desligada. |
| 🔄 **F6 Toggle On/Off (WIP)** | Alterne a renderização neural no mesmo frame congelado para comparação visual instantânea. |
| ▶️ **Iniciar Jogo Direto** | Abra o jogo diretamente pela interface do instalador. |
| ↩️ **Restauração de Fábrica em 1-Clique** | Faz backup dos originais, remove todos os arquivos injetados e restaura os originais com zero corrupção. |
| 🛡️ **Diálogos de Confirmação** | Confirmação Sim/Não antes de instalar e antes de restaurar para prevenir modificações acidentais. |
| 🔍 **Detecção de Estado Instalado** | Mostra se o DLSS 5 já está instalado no jogo selecionado e qual modo está ativo. |
| 🌐 **Interface Bilíngue (EN/PT-BR)** | Alternância instantânea entre Inglês e Português — todos os textos, badges e mensagens mudam em tempo real. |
| 📂 **Abrir Pasta do Jogo** | Botão para abrir a pasta de injeção no Windows Explorer. |
| 📖 **Guia de Otimização no Jogo** | Instruções passo-a-passo integradas para configurar o DLSS 5 dentro do jogo. |
| 🧹 **Limpeza de Addons Legados** | Remove automaticamente versões antigas do addon (++, v3) ao reinstalar. |
| ⚙️ **Configurações Pré-Definidas** | ReShade.ini com padrões otimizados: Auto Skin Mask ativado, Preset #2 Cinematic, Intensidade Neural 0.80, HDR desativado. |
| 🔎 **Filtro de Pesquisa** | Digite na barra de pesquisa para filtrar a biblioteca de jogos por nome ou caminho em tempo real. |

---

### 🚀 Guia de Uso Rápido

1. **Baixar e Extrair:** Baixe `1-Click-DLSS5-v1.2.0.zip` e extraia para qualquer pasta.
2. **Executar:** Dê dois cliques em **`1-Click-DLSS5.cmd`**.
3. **Escolha o Jogo:** Selecione na biblioteca ou clique em **`[📁 PROCURAR JOGO]`**.
4. **Instalar:** Clique em **`[🚀 INSTALAR DLSS 5 EM 1-CLIQUE]`** e confirme.
5. **Jogar:** Clique em **`[▶️ INICIAR JOGO]`**.
6. **No Jogo:**
   - **Menu gráfico:**
     - *Jogos com DLSS nativo:* Ative **NVIDIA DLSS Super Resolution** (Qualidade ou Desempenho).
     - *Jogos com FSR2/XeSS:* Ative **AMD FSR 2** ou **Intel XeSS** no modo Qualidade (OptiScaler redireciona para DLSS-NR).
   - **Overlay ReShade/RenoDX:**
     - Pressione **`[Home]`** → aba **Add-ons** → expanda **DLSS 5** → selecione **NR Preset #2** e **NR Style: Cinematic**.
   - **Teclas de comparação:**
     - **`F5`** para screenshot A/B.
     - **`F6`** para ligar/desligar no mesmo frame (WIP).

---

### 📋 Matriz de Compatibilidade

| Tipo de Jogo | Detecção | Método | Opção no Jogo | Observações |
|---|---|---|---|---|
| **DLSS Nativo**<br>*Cyberpunk 2077, Forza Horizon 5/6, HITMAN WoA, Starfield, Control, MSFS 2024, Black Myth: Wukong…* | `nvngx_dlss.dll`, `sl.dlss.dll`, etc. | `Direto` | NVIDIA DLSS Qualidade | Streamline 2.13 + RenoDX v4.1 injetados diretamente. |
| **Apenas FSR 2/3**<br>*God of War, Horizon Zero Dawn, The Last of Us Part I, Ratchet & Clank…* | `ffx_fsr2_api*.dll`, `amd_fidelityfx*.dll` | `Ponte OptiScaler` | AMD FSR 2 Qualidade | OptiScaler v0.9.4 (`version.dll`) converte FSR2 → DLSS-NR. |
| **Apenas XeSS**<br>*Shadow of the Tomb Raider, Dying Light 2, Arc Raiders…* | `libxess.dll`, `xess.dll` | `Ponte OptiScaler` | Intel XeSS Qualidade | OptiScaler v0.9.4 (`version.dll`) converte XeSS → DLSS-NR. |
| **UE4/UE5**<br>*S.T.A.L.K.E.R. 2, Tekken 8, Wuthering Waves…* | Auto-detectado | `Direto ou Ponte` | DLSS / FSR2 / XeSS | Injeta em `Binaries\Win64\`. Método depende do upscaler disponível. |
| **Sem upscaler** | Nenhuma DLL DLSS/FSR/XeSS encontrada | `Bloqueado` | N/A | Mensagem clara de diagnóstico. |

---

### 📦 Conteúdo do Pacote

| Arquivo | Tamanho | Descrição |
|---|---|---|
| `1-Click-DLSS5.cmd` | < 1 KB | Inicializador Windows com captura de erros |
| `1-Click-DLSS5.ps1` | ~82 KB | Programa principal (1657 linhas, GUI WinForms) |
| `payload/renodx-dlss5.addon64` | 547 KB | **Addon RenoDX DLSS 5 v4.1** — F5 A/B, F6 toggle |
| `payload/ReShade_Setup_6.8.0_Addon.exe` | 4.1 MB | Instalador oficial do ReShade com suporte a add-ons |
| `payload/ReShade.ini` | < 1 KB | Pré-configurado: Skin Mask ON, Preset #2, Intensidade 0.80 |
| `payload/streamline.zip` | 144 MB | NVIDIA Streamline 2.13 + `nvngx_dlssnr.dll` (runtime neural) |
| `payload/optiscaler/OptiScaler.dll` | 24.2 MB | Ponte Universal OptiScaler v0.9.4 |
| `payload/optiscaler/OptiScaler.ini` | < 1 KB | Pré-configurado: overlay OFF, upscaler DLSS forçado |
| `payload/optiscaler/libxess.dll` | 74.2 MB | Runtime de tradução Intel XeSS |

---

### ⚙️ Requisitos do Sistema

| Requisito | Mínimo |
|---|---|
| **GPU** | NVIDIA GeForce RTX 40 (RTX 4060 ou superior) |
| **GPU Ideal** | NVIDIA GeForce RTX 50 |
| **SO** | Windows 10/11 x64 |
| **API Gráfica** | DirectX 12 |
| **Driver NVIDIA** | 560.xx ou superior |
| **PowerShell** | 5.1+ (incluído no Windows) |

> **Nota:** A série RTX 3000 é suportada com compatibilidade melhorada no RenoDX v4.1 quando usando a DLL correta. A série RTX 2000 não possui Tensor Cores FP8 nativos necessários para desempenho ideal do DLSS-NR.

---

### 🛡️ Como Funciona (Técnico)

```
Jogo com DLSS Nativo:
┌──────────┐    ┌────────────────┐    ┌───────────────────┐
│ Game.exe │───▶│ dxgi.dll       │───▶│ renodx-dlss5      │
│          │    │ (ReShade 6.8)  │    │ .addon64 (v4.1)   │
│          │    └────────────────┘    └───────────────────┘
│          │───▶│ nvngx_dlssnr.dll (Streamline 2.13 Neural Runtime)
└──────────┘

Jogo com FSR2/XeSS:
┌──────────┐    ┌────────────────┐    ┌───────────────────┐
│ Game.exe │───▶│ dxgi.dll       │───▶│ renodx-dlss5      │
│          │    │ (ReShade 6.8)  │    │ .addon64 (v4.1)   │
│          │    └────────────────┘    └───────────────────┘
│          │───▶│ version.dll (OptiScaler v0.9.4)          │
│          │    │  ├─ Intercepta chamadas FSR2/XeSS        │
│          │    │  ├─ Redireciona para nvngx_dlssnr.dll    │
│          │    │  └─ Usa libxess.dll para tradução XeSS   │
└──────────┘
```

---

### 🛡️ License & Disclaimer / Licença & Isenção de Responsabilidade

Distributed under the [MIT](LICENSE) License. / Distribuído sob a licença [MIT](LICENSE).

*Disclaimer: This software is an independent utility and is not affiliated with, endorsed by, or sponsored by NVIDIA Corporation, AMD, or Intel. NVIDIA, DLSS, RTX, GeForce, Streamline, AMD, FSR, Intel, and XeSS are trademarks or registered trademarks of their respective owners. RenoDX addon credits: Lecram-Technology Denier & @speedlemur (ControlDLSS5).*

*Aviso: Este software é uma ferramenta utilitária independente e não é afiliado, endossado ou patrocinado pela NVIDIA Corporation, AMD ou Intel. NVIDIA, DLSS, RTX, GeForce, Streamline, AMD, FSR, Intel e XeSS são marcas comerciais ou registradas de seus respectivos proprietários. Créditos do addon RenoDX: Lecram-Technology Denier & @speedlemur (ControlDLSS5).*

# 1 Click DLSS 5 ðŸš€

<div align="center">

**Universal Neural Rendering Game Center & 1-Click Injector**  
*Empowering ANY PC Game (DX11/DX12/Vulkan) & All NVIDIA GeForce RTX 20, 30, 40 & 50 Series GPUs with DLSS 5 Neural Reconstruction*

[![Version](https://img.shields.io/badge/version-1.4.0-brightgreen.svg)](https://github.com/reiluisii/1-Click-DLSS5)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows%2010%20%7C%2011%20x64-0078D6.svg)](https://github.com/reiluisii/1-Click-DLSS5)
[![DirectX](https://img.shields.io/badge/Graphics-DX11%20%7C%20DX12%20%7C%20Vulkan-orange.svg)](https://github.com/reiluisii/1-Click-DLSS5)
[![NVIDIA](https://img.shields.io/badge/NVIDIA-RTX%2020%2C%2030%2C%2040%20%26%2050%20Series-76B900.svg)](https://nvidia.com)
[![Feeder](https://img.shields.io/badge/DLSS5%20Feeder-100%25%20Native%20DLAA-9B51E0.svg)](https://github.com/reiluisii/1-Click-DLSS5)
[![RenoDX](https://img.shields.io/badge/RenoDX-Stable%20Build-FF6B6B.svg)](https://github.com/reiluisii/1-Click-DLSS5)
[![OptiScaler](https://img.shields.io/badge/OptiScaler-v0.9.4%20Bridge-purple.svg)](https://github.com/reiluisii/1-Click-DLSS5)

[English](#english) â€¢ [PortuguÃªs (Brasil)](#portuguÃªs-brasil)

</div>

---

## English

### ðŸŒŸ Overview

**1 Click DLSS 5** is an all-in-one, automated Neural Rendering game center and injection engine for Windows. Built for the entire **NVIDIA GeForce RTX lineup (RTX 20, RTX 30, RTX 40 & RTX 50 Series)**, it introduces full **Universal Feeder Mode**, enabling DLSS 5 Neural Reconstruction in **virtually ANY PC game** (DirectX 11, DirectX 12, and Vulkan) at **100% Native Resolution (DLAA)** without requiring native game upscalers or resolution downscaling.

---

### ðŸŽ® The 3 Operating Modes

| Mode | Target Games | Injection Stack | Resolution Mode | In-Game Setting |
| :--- | :--- | :--- | :--- | :--- |
| **1. Direct Mode** | Games with native DLSS (*Cyberpunk 2077*, *Control*, *Forza*, *Witcher 3*) | NVIDIA Streamline 2.13 + enodx-dlss5.addon64 + 
vngx_dlssnr.dll | DLSS Quality / Balanced / Performance | **Enable DLSS** in game menu |
| **2. OptiScaler Bridge** | Games with FSR 2/3 or XeSS only (*God of War*, *The Last of Us*) | OptiScaler v0.9.4 (ersion.dll) + enodx-dlss5.addon64 + 
vngx_dlssnr.dll | FSR2/XeSS Redirected to DLSS 5 | **Enable FSR2/XeSS** in Quality mode |
| **3. Universal Feeder** ðŸ†• | **ALL OTHER GAMES** (*Green Hell*, *FF XII*, *Elden Ring*, *Dark Souls*, *Skyrim*, *GTA V*, etc.) | dlss5-feed.addon64 + LumeniteFX Kernel Optical Flow + enodx-dlss5.addon64 + 
vngx_dlssnr.dll | **100% Native DLAA** (.0\times$ scale, zero downscaling) | **Keep Upscaling OFF** (100% Native + TAA) |

---

### âŒ¨ï¸ In-Game Controls & Hotkeys

* **[F6]**: Toggle DLSS 5 Neural Rendering **ON / OFF in real-time** for immediate same-frame comparisons!
* **[F5]**: Capture uncompressed A/B comparison screenshot.
* **[Home] / [Pos1]**: Open ReShade / RenoDX in-game overlay menu for fine-tuning.

---

### ðŸ’¡ Pro-Tip for Maximum Fluidity (V-Sync Recommendation)
* **Disable In-Game V-Sync**: In games using the Unity Engine or certain DirectX pipelines, in-game V-Sync can cause frame pacing stalls when coupled with post-process neural injection. Disabling in-game V-Sync unlocks buttery smooth 80+ FPS presentations.
* **Tear-Free Gaming**: Use **NVIDIA G-Sync / FreeSync** or set a global Max Frame Rate limit in the **NVIDIA Control Panel** for flawless frame pacing.

---

### âš¡ What's New in v1.4.0

#### ðŸš€ Universal Feeder Mode (Synthetic DLAA at 100% Native Resolution)
- Automated injection of DLSS5-Feeder paired with GPU-accelerated **LumeniteFX Kernel Optical Flow**.
- Synthesizes exact motion vectors (RG16_FLOAT) and depth buffers (R32_FLOAT) directly via ReShade compute shaders.
- **Zero Downscaling / DLAA**: Runs DLSS 5 Neural Reconstruction at native .0\times$ screen scale with maximum texture clarity and generative lighting coherence.
- Supports **DirectX 11, DirectX 12, and Vulkan**, as well as legacy 32-bit (x86) titles via automated dlss5-feed-host64.exe IPC bridging.

#### ðŸ›¡ï¸ Rock-Solid Stability & Universal Hardware
- Retains the battle-tested RenoDX stable detour build (zero flickering, no swapchain race conditions).
- Retains universal 
vngx_dlssnr.dll (158 MB) with full support for **RTX 20, 30, 40, and 50 Series** GPUs.
- **100% Clean Factory Restoration**: 1-click restore purges all injected addons, shaders, and configs, restoring original game files cleanly.

---

### ðŸ“‹ System Requirements

* **GPU:** NVIDIA GeForce RTX Series (RTX 2060+, RTX 3050+, RTX 4060+, RTX 50-Series)
* **OS:** Windows 10 / Windows 11 (64-bit)
* **Graphics API:** DirectX 11, DirectX 12, or Vulkan
* **Storage:** ~380 MB free disk space for runtime payload

---

<br>

## PortuguÃªs (Brasil)

### ðŸŒŸ VisÃ£o Geral

O **1 Click DLSS 5** Ã© uma central completa e automatizada de injeÃ§Ã£o e gerenciamento de RenderizaÃ§Ã£o Neural DLSS 5 para Windows. Projetado para **toda a linha NVIDIA GeForce RTX (SÃ©ries RTX 20, RTX 30, RTX 40 e RTX 50)**, a versÃ£o 1.4.0 introduz o **Modo Feeder Universal**, permitindo rodar a ReconstruÃ§Ã£o Neural DLSS 5 em **praticamente QUALQUER jogo de PC** (DirectX 11, DirectX 12 e Vulkan) em **ResoluÃ§Ã£o 100% Nativa (DLAA)** sem precisar de DLSS nativo ou reduÃ§Ã£o de resoluÃ§Ã£o.

---

### ðŸŽ® Os 3 Modos de OperaÃ§Ã£o Inteligentes

| Modo | Jogos Alvo | Pilha de InjeÃ§Ã£o | Modo de ResoluÃ§Ã£o | ConfiguraÃ§Ã£o no Jogo |
| :--- | :--- | :--- | :--- | :--- |
| **1. Modo Direto** | Jogos com DLSS nativo (*Cyberpunk 2077*, *Control*, *Forza*, *Witcher 3*) | NVIDIA Streamline 2.13 + enodx-dlss5.addon64 + 
vngx_dlssnr.dll | DLSS Qualidade / Balanceado / Desempenho | **Ative o DLSS** no menu do jogo |
| **2. Ponte OptiScaler** | Jogos apenas com FSR 2/3 ou XeSS (*God of War*, *The Last of Us*) | OptiScaler v0.9.4 (ersion.dll) + enodx-dlss5.addon64 + 
vngx_dlssnr.dll | FSR2/XeSS Redirecionado para DLSS 5 | **Ative FSR2/XeSS** em modo Qualidade |
| **3. Feeder Universal** ðŸ†• | **TODOS OS OUTROS JOGOS** (*Green Hell*, *FF XII*, *Elden Ring*, *Dark Souls*, *Skyrim*, *GTA V*, etc.) | dlss5-feed.addon64 + Fluxo Ã“ptico LumeniteFX Kernel + enodx-dlss5.addon64 + 
vngx_dlssnr.dll | **DLAA 100% Nativo** (escala .0\times$, sem borrÃ£o nem upscaling) | **Deixe Upscaling DESLIGADO** (Nativo + TAA) |

---

### âŒ¨ï¸ Teclas de Atalho no Jogo

* **[F6]**: Liga / Desliga o DLSS 5 **em tempo real** para comparar o antes e depois no mesmo frame!
* **[F5]**: Captura screenshot sem compressÃ£o para comparaÃ§Ã£o A/B.
* **[Home] / [Pos1]**: Abre o menu completo do ReShade / RenoDX para ajustes finos.

---

### ðŸ’¡ Dica de Ouro para Fluidez MÃ¡xima (RecomendaÃ§Ã£o de VSync)
* **Desative o V-Sync dentro do Jogo**: Em jogos desenvolvidos na Unity Engine ou em certos pipelines DirectX, o V-Sync interno do jogo pode travar a entrega de frames (stalling da swapchain) quando combinado com pÃ³s-processamento neural. Desativar o VSync interno libera 80+ FPS fluidos e constantes.
* **Sem cortes de tela (Tearing)**: Utilize **G-Sync / FreeSync** ou limite a taxa mÃ¡xima de quadros diretamente no **Painel de Controle da NVIDIA**.

---

### âš¡ Novidades da VersÃ£o 1.4.0 (EdiÃ§Ã£o Feeder Universal)

#### ðŸš€ Modo Feeder Universal (DLAA SintÃ©tico em ResoluÃ§Ã£o 100% Nativa)
- IntegraÃ§Ã£o automÃ¡tica do DLSS5-Feeder em conjunto com os shaders de fluxo Ã³ptico de alta precisÃ£o **LumeniteFX Kernel**.
- Sintetiza vetores de movimento (RG16_FLOAT) e buffers de profundidade (R32_FLOAT) diretamente no pipeline de pÃ³s-processamento do ReShade.
- **DLAA 100% Nativo**: Permite aplicar a ReconstruÃ§Ã£o Neural DLSS 5 diretamente sobre a resoluÃ§Ã£o nativa do monitor, entregando mÃ¡xima nitidez, sombras coerentes e iluminaÃ§Ã£o fÃ­sica sem perdas.
- Suporta **DirectX 11, DirectX 12 e Vulkan**, alÃ©m de jogos legados de 32 bits (x86) via processo auxiliar dlss5-feed-host64.exe.

#### ðŸ›¡ï¸ Estabilidade Absoluta e Suporte Universal a Hardware
- MantÃ©m a build estÃ¡vel e comprovada do RenoDX (zero piscamentos ou congelamentos).
- MantÃ©m o runtime neural universal 
vngx_dlssnr.dll (158 MB) com suporte nativo a **RTX 20, 30, 40 e 50**.
- **RestauraÃ§Ã£o de FÃ¡brica 100% Limpa**: O botÃ£o Restaurar remove com seguranÃ§a todos os arquivos injetados (addons, shaders, configs) e recupera os executÃ¡veis originais.

---

### ðŸ“‹ Requisitos de Sistema

* **Placa de VÃ­deo:** Linha NVIDIA GeForce RTX (RTX 2060+, RTX 3050+, RTX 4060+, SÃ©rie RTX 50)
* **Sistema Operacional:** Windows 10 ou Windows 11 (64 bits)
* **API GrÃ¡fica:** DirectX 11, DirectX 12 ou Vulkan
* **Armazenamento:** ~380 MB de espaÃ§o em disco para o payload completo

---

### ðŸ›¡ï¸ License & Disclaimer / LicenÃ§a & IsenÃ§Ã£o de Responsabilidade

Distributed under the [MIT](LICENSE) License. / DistribuÃ­do sob a licenÃ§a [MIT](LICENSE).

This project is an open-source research and modding tool developed for educational, enhancement, and compatibility purposes. NVIDIA, DLSS, Streamline, GeForce, RTX, OptiScaler, ReShade, and RenoDX are trademarks or registered trademarks of their respective owners.
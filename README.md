# 1 Click DLSS 5 🚀

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

[English](#english) • [Português (Brasil)](#português-brasil)

</div>

---

## English

### 🌟 Overview

**1 Click DLSS 5** is an all-in-one, automated Neural Rendering game center and injection engine for Windows. Built for the entire **NVIDIA GeForce RTX lineup (RTX 20, RTX 30, RTX 40 & RTX 50 Series)**, it introduces full **Universal Feeder Mode**, enabling DLSS 5 Neural Reconstruction in **virtually ANY PC game** (DirectX 11, DirectX 12, and Vulkan) at **100% Native Resolution (DLAA)** without requiring native game upscalers or resolution downscaling.

---

### 🎮 The 3 Operating Modes

| Mode | Target Games | Injection Stack | Resolution Mode |
| :--- | :--- | :--- | :--- |
| **1. Direct Mode** | Games with native DLSS (*Cyberpunk 2077*, *Control*, *Forza*, *Witcher 3*) | NVIDIA Streamline 2.13 + `renodx-dlss5.addon64` + `nvngx_dlssnr.dll` | DLSS Quality / Balanced / Performance |
| **2. OptiScaler Bridge** | Games with FSR 2/3 or XeSS only (*God of War*, *The Last of Us*) | OptiScaler v0.9.4 (`version.dll`) + `renodx-dlss5.addon64` + `nvngx_dlssnr.dll` | FSR2/XeSS Redirected to DLSS 5 |
| **3. Universal Feeder** 🆕 | **ALL OTHER GAMES** (*Green Hell*, *Elden Ring*, *Dark Souls 3*, *Skyrim*, *GTA V*, *Metro*, etc.) | `dlss5-feed.addon64` + LumeniteFX Kernel 2.0 Optical Flow + `renodx-dlss5.addon64` + `nvngx_dlssnr.dll` | **100% Native DLAA** ($1.0\times$ scale, zero downscaling) |

---

### ⚡ What's New in v1.4.0 (Universal Feeder Edition)

#### 🚀 Universal Feeder Mode (Synthetic DLAA at 100% Native Resolution)
- Implemented automated injection of `DLSS5-Feeder` paired with GPU-accelerated **LumeniteFX Kernel 2.0 Optical Flow**.
- Synthesizes exact motion vectors (`RG16_FLOAT`) and depth buffers (`R32_FLOAT`) directly via ReShade compute shaders.
- **Zero Downscaling / DLAA**: Runs DLSS 5 Neural Reconstruction at native $1.0\times$ screen scale with zero blur, maximum texture clarity, and generative lighting coherence.
- Supports **DirectX 11, DirectX 12, and Vulkan**, as well as legacy 32-bit (x86) titles via automated `dlss5-feed-host64.exe` IPC bridging.

#### 🛡️ Rock-Solid Stability & Universal Hardware
- Retains the battle-tested RenoDX stable detour build (zero flickering, no swapchain race conditions).
- Retains universal `nvngx_dlssnr.dll` (158 MB) with full support for **RTX 20, 30, 40, and 50 Series** GPUs.
- **100% Clean Factory Restoration**: 1-click restore purges all injected addons, shaders, and configs, restoring original game binaries cleanly.

---

<br>

## Português (Brasil)

### 🌟 Visão Geral

O **1 Click DLSS 5** é uma central completa e automatizada de injeção e gerenciamento de Renderização Neural DLSS 5 para Windows. Projetado para **toda a linha NVIDIA GeForce RTX (Séries RTX 20, RTX 30, RTX 40 e RTX 50)**, a versão 1.4.0 introduz o **Modo Feeder Universal**, permitindo rodar a Reconstrução Neural DLSS 5 em **praticamente QUALQUER jogo de PC** (DirectX 11, DirectX 12 e Vulkan) em **Resolução 100% Nativa (DLAA)** sem precisar de DLSS nativo ou redução de resolução.

---

### 🎮 Os 3 Modos de Operação Inteligentes

| Modo | Jogos Alvo | Pilha de Injeção | Modo de Resolução |
| :--- | :--- | :--- | :--- |
| **1. Modo Direto** | Jogos com DLSS nativo (*Cyberpunk 2077*, *Control*, *Forza*, *Witcher 3*) | NVIDIA Streamline 2.13 + `renodx-dlss5.addon64` + `nvngx_dlssnr.dll` | DLSS Qualidade / Balanceado / Desempenho |
| **2. Ponte OptiScaler** | Jogos apenas com FSR 2/3 ou XeSS (*God of War*, *The Last of Us*) | OptiScaler v0.9.4 (`version.dll`) + `renodx-dlss5.addon64` + `nvngx_dlssnr.dll` | FSR2/XeSS Redirecionado para DLSS 5 |
| **3. Feeder Universal** 🆕 | **TODOS OS OUTROS JOGOS** (*Green Hell*, *Elden Ring*, *Dark Souls 3*, *Skyrim*, *GTA V*, *Metro*, etc.) | `dlss5-feed.addon64` + Fluxo Óptico LumeniteFX Kernel 2.0 + `renodx-dlss5.addon64` + `nvngx_dlssnr.dll` | **DLAA 100% Nativo** (escala $1.0\times$, sem borrão nem upscaling) |

---

### ⚡ Novidades da Versão 1.4.0 (Edição Feeder Universal)

#### 🚀 Modo Feeder Universal (DLAA Sintético em Resolução 100% Nativa)
- Integração automática do `DLSS5-Feeder` em conjunto com os shaders de fluxo óptico de alta precisão **LumeniteFX Kernel 2.0**.
- Sintetiza vetores de movimento (`RG16_FLOAT`) e buffers de profundidade (`R32_FLOAT`) diretamente no pipeline de pós-processamento do ReShade.
- **DLAA 100% Nativo**: Permite aplicar a Reconstrução Neural DLSS 5 diretamente sobre a resolução nativa do monitor, entregando máxima nitidez, sombras coerentes e iluminação física sem perdas.
- Suporta **DirectX 11, DirectX 12 e Vulkan**, além de jogos legados de 32 bits (x86) via processo auxiliar `dlss5-feed-host64.exe`.

#### 🛡️ Estabilidade Absoluta e Suporte Universal a Hardware
- Mantém a build estável e comprovada do RenoDX (zero piscamentos ou congelamentos).
- Mantém o runtime neural universal `nvngx_dlssnr.dll` (158 MB) com suporte nativo a **RTX 20, 30, 40 e 50**.
- **Restauração de Fábrica 100% Limpa**: O botão Restaurar remove com segurança todos os arquivos injetados (addons, shaders, configs) e recupera os executáveis originais.

---

### 🛡️ License & Disclaimer / Licença & Isenção de Responsabilidade

Distributed under the [MIT](LICENSE) License. / Distribuído sob a licença [MIT](LICENSE).
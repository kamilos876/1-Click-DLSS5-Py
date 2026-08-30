# 1 Click DLSS 5 🚀

<div align="center">

**Universal Neural Rendering Game Center & 1-Click Injector**  
*Empowering NVIDIA GeForce RTX 20, RTX 30, RTX 40 & RTX 50 Series GPUs with DLSS 5 Neural Reconstruction*

[![Version](https://img.shields.io/badge/version-1.3.1-brightgreen.svg)](https://github.com/reiluisii/1-Click-DLSS5)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows%2010%20%7C%2011%20x64-0078D6.svg)](https://github.com/reiluisii/1-Click-DLSS5)
[![DirectX](https://img.shields.io/badge/DirectX-12%20%7C%20DXGI-orange.svg)](https://github.com/reiluisii/1-Click-DLSS5)
[![NVIDIA](https://img.shields.io/badge/NVIDIA-RTX%2020%2C%2030%2C%2040%20%26%2050%20Series-76B900.svg)](https://nvidia.com)
[![RenoDX](https://img.shields.io/badge/RenoDX-Stable%20Build-FF6B6B.svg)](https://github.com/reiluisii/1-Click-DLSS5)
[![OptiScaler](https://img.shields.io/badge/OptiScaler-v0.9.4%20Bridge-purple.svg)](https://github.com/reiluisii/1-Click-DLSS5)

[English](#english) • [Português (Brasil)](#português-brasil)

</div>

---

## English

### 🌟 Overview

**1 Click DLSS 5** is an all-in-one, automated Neural Rendering game center and injection engine for Windows. Built for the entire **NVIDIA GeForce RTX lineup (RTX 20, RTX 30, RTX 40 & RTX 50 Series)**, it provides:

- A modern **Steam-style visual library** with on-demand disk scanning (zero startup lag)
- **Universal GPU Architecture** — patched `nvngx_dlssnr.dll` neural runtime running natively across RTX 20, 30, 40, and 50 Series GPUs
- **Rock-Solid Stability** — uses the proven, crash-free, zero-flicker RenoDX export detour hook architecture
- **Real-time icon extraction** from 64-bit game executables
- **Intelligent heuristic detection** of the correct game binary (resolves `Retail\`, `bin\x64\`, `Binaries\Win64\`)
- **Universal Mode** — auto-detects Native DLSS, FSR 2/3, or XeSS and applies the optimal injection method
- **1-click installation** of DLSS 5 Neural Reconstruction powered by RenoDX, NVIDIA Streamline 2.13, and OptiScaler v0.9.4
- **Factory-calibrated default settings** auto-injected into every game with zero manual tweaking required

---

### ⚡ What's New in v1.3.1 (Stability & Hotfix Release)

#### 🛡️ Reverted Experimental Addon to Rock-Solid Stable Build
- Replaced the experimental v4.55 addon (which introduced VTable swapchain race conditions, texture flickering, and potential crashes) with the battle-tested, zero-flicker **RenoDX stable build (573 KB)** with F5 A/B screenshot mode and F6 toggle.

#### 🎮 Full Universal RTX 20, 30, 40 & 50 Series Support
- Retained the new patched **`nvngx_dlssnr.dll`** neural runtime (158.16 MB) by ShortFuse.
- Enables DLSS 5 Neural Reconstruction across **Turing (RTX 20 Series)**, **Ampere (RTX 30 Series)**, **Ada Lovelace (RTX 40 Series)**, and **Blackwell (RTX 50 Series)** GPUs with identical rendering quality!

---

<br>

## Português (Brasil)

### 🌟 Visão Geral

O **1 Click DLSS 5** é uma central completa e automatizada de injeção e gerenciamento de Renderização Neural DLSS 5 para Windows. Projetado para **toda a linha NVIDIA GeForce RTX (Séries RTX 20, RTX 30, RTX 40 e RTX 50)**, oferece:

- **Biblioteca visual estilo Steam** com escaneamento sob demanda (sem travamento na inicialização)
- **Arquitetura Universal de GPUs** — runtime neural `nvngx_dlssnr.dll` patcheado para rodar nativamente em placas RTX 20, 30, 40 e 50 com a mesma qualidade de renderização
- **Estabilidade Absoluta** — utiliza a arquitetura comprovada de hook do RenoDX livre de piscamentos (*flicker*) ou quedas de driver
- **Janela de progresso visual em tempo real** durante a varredura dos jogos
- **Extração de ícones em tempo real** dos executáveis de 64-bit
- **Suporte profundo à Unreal Engine 4/5** com detecção de plugins até 12 níveis de profundidade
- **Modo Universal** — detecta automaticamente DLSS nativo, FSR 2/3 ou XeSS e aplica o método ideal
- **Instalação em 1-clique** com configurações ideais de fábrica auto-aplicadas

---

### ⚡ Novidades da Versão 1.3.1 (Hotfix de Estabilidade)

#### 🛡️ Reversão para a Build Estável do RenoDX (Sem Piscamento)
- Identificado que o addon experimental v4.55 continha hooks invasivos de VTable e debug que causavam piscamento de tela (*flicker*) e risco de travamento em motores DirectX 12.
- O programa agora inclui a **build estável do RenoDX (573 KB)** com zero piscamento, F5 Screenshot A/B e F6 Toggle.

#### 🎮 Suporte Universal Completo a GPUs RTX Séries 20, 30, 40 e 50
- Mantido o novo runtime neural **`nvngx_dlssnr.dll`** (158.16 MB) patcheado por ShortFuse, permitindo que placas **RTX Séries 20, 30, 40 e 50** rodem a reconstrução neural com máxima estabilidade!

---

### 🛡️ License & Disclaimer / Licença & Isenção de Responsabilidade

Distributed under the [MIT](LICENSE) License. / Distribuído sob a licença [MIT](LICENSE).
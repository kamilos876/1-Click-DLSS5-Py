# Changelog — 1 Click DLSS 5

All notable changes to this project will be documented in this file.

## [v2.5.0-beta] - 2026-09-02

### 🚀 Novidades e Destaques (Major Features)
- **✨ Redesign Completo da Interface Gráfica (HUD v2):**
  - Layout moderno, limpo e intuitivo projetado para usuários leigos e entusiastas.
  - Guia visual passo a passo em 3 etapas claras: `[1] Escolha o Jogo` ➔ `[2] Clique em Instalar` ➔ `[3] Inicie e Aproveite!`.
  - Remoção de botões redundantes e duplicados para eliminar poluição visual.
  - Seleção de modos em cards modernos interativos com cores distintas e instruções contextuais dinâmicas.
  - Banner do jogo selecionado com extração automática do ícone do executável, status de instalação em tempo real e badge colorido de API.

- **⚡ Motor de Resolução de Problemas em 1 Clique (Auto-Fix):**
  - Assistente inteligente de diagnóstico de erros com análise tripla: O que aconteceu, Causa provável e Como resolver.
  - Botão `[⚡] RESOLVER PROBLEMA EM 1 CLIQUE` capaz de finalizar processos travados em segundo plano, corrigir permissões e reaplicar a injeção automaticamente sem intervenção manual.
  - Painel de diagnóstico do sistema (`🩺 DIAGNÓSTICO`) para validar GPU RTX, permissões de gravação, processos em execução e integridade dos runtimes neurais.

- **🌍 Suporte Multi-Idioma Nativo Expandido (10 Idiomas):**
  - Suporte completo com troca dinâmica instantânea para 10 idiomas: Português (PT-BR), English (EN-US), Español (ES), Deutsch (DE), Français (FR), Italiano (IT), 日本語 (JA), 简体中文 (ZH), Русский (RU), 한국어 (KO).
  - Centralização de todas as strings no arquivo `core/assets/translations.json`.

- **🎮 Auto-Descoberta Instantânea e Scanner Multi-Plataforma:**
  - Varredura automática e inteligente de jogos instalados nas plataformas **Steam** (via parsing multi-drive de `libraryfolders.vdf`), **Epic Games** (via manifests `.item`), **GOG**, **Xbox App / XboxGames**, **EA App** e pastas padrão de jogos.
  - Barra de pesquisa instantânea para filtrar jogos por nome ou API gráfica.

- **⚙️ Suporte Universal a Todas as APIs e Arquiteturas:**
  - Suporte nativo completo a **DirectX 12, DirectX 11, DirectX 9, Vulkan e OpenGL**.
  - Suporte total a jogos **32-bit (x86)** e **64-bit (x64)** com ponte de comunicação IPC via `host64`.

- **🎯 Estabilidade e Nitidez Máxima no Feeder Universal (Modo 3 - DLAA 100% Nativo):**
  - Resolução definitiva de crashes na inicialização e perda de nitidez em jogos DirectX 11 (ex: *Mafia Definitive Edition*).
  - Integração da suíte Lumenite Kernel (`Lumenite_Kernel.fx`) no cabeçalho da cadeia de técnicas do ReShade para cálculo preciso de vetores de movimento ópticos (*Motion Vectors*).
  - Configuração de `preset=6` no `dlss5-feed.cfg` para estabilidade máxima e resolução 100% nativa.
  - Caminhos de busca recursivos no ReShade (`.eshade-shaders\Shaders\**` e `.eshade-shaders\Textures\**`).
  - Calibração de nitidez e tonalidade neural no RenoDX (`NRGlobalTone=0.9`, `NRLocalStructure=0.44`, `NRLocalTone=1.22`, `NRSkinStructure=1.16`).

- **🛡️ Restauração de Fábrica e Desinstalação 100% Limpa:**
  - Desinstalador inteligente que restaura os arquivos originais salvos no backup e remove com precisão cirúrgica todas as DLLs, Add-ons, shaders e arquivos temporários.

---

## [v1.5.1] - Hotfix Release
- Correção de resolver de caminhos multi-drive.
- Suporte inicial a detecção de binários 32-bit PE.
- Perfis para Final Fantasy X HD Remaster e série Falcom / Cold Steel.
- Otimização do scanner de discos com profundidade controlada.

## [v1.5.0] - Universal API Detection
- Detector determinístico de APIs gráficas (D3D12, D3D11, D3D9, Vulkan, OpenGL).
- Integração da suíte de shaders e calibração de máscaras de luma.

## [v1.4.0] - Dual Engine & OptiScaler Integration
- Introdução do Modo 2: Ponte OptiScaler para jogos com suporte apenas a FSR2/XeSS.

## [v1.3.0] - Streamline & Direct Injection
- Suporte completo ao Modo 1: Injeção direta de Streamline + RenoDX para jogos com DLSS nativo.

## [v1.2.0] - Multi-Language & Confirmation System
- Sistema bilíngue PT-BR e EN-US com caixas de confirmação de segurança.

## [v1.1.0] - Initial Public Release
- Lançamento inicial com injeção de ReShade + RenoDX DLSS 5.

# ⚡ 1-Click DLSS 5 — Release Notes (v2.6.0-release)
### **Universal Neural Control Center • RTX 20/30/40/50 Series**

---

## 🇧🇷 Português

### 🌟 Destaques da Versão v2.6.0
A versão **v2.6.0** representa um salto crucial em **estabilidade arquitetural**, **experiência visual (UI/UX)** e **integridade operacional**. Introduzimos o novo **Motor de Autocura e Proteção de Runtimes**, eliminamos bugs visuais de tema escuro, adicionamos barra de progresso visual de alta visibilidade e expandimos a suíte de filtros ReShade com atalhos universais.

---

### 🛡️ 1. Motor de Integridade e Autocura Ativa (Game Integrity Engine)
* **Proteção Definitiva de Runtimes Nativos (`libxess.dll`, `nvngx_dlss.dll`, etc.):**
  * Corrigida a exclusão indevida de bibliotecas nativas de upscalers do jogo (ex: `libxess.dll` no *Forza Horizon 5/6*, *Cyberpunk 2077*, *Deathloop*, *Tomb Raider*) durante a desinstalação ou troca de modo.
  * Implementada lista negra estrita de deleção que blinda permanentemente DLLs nativas de fornecedores: `libxess*.dll`, `nvngx_dlss*.dll`, `sl.*.dll`, `amd_fidelityfx_*.dll`, `dxcompiler.dll`, `d3d12core.dll`, `steam_api*.dll`.
* **Scanner Preditivo de Importações PE e Autocura (`Repair-GameCriticalDependencies`):**
  * O instalador inspeciona a tabela de importação (PE IAT) do executável do jogo.
  * Se o executável exigir o Intel XeSS (`libxess.dll`) ou DLSS (`nvngx_dlss.dll`) e o arquivo estiver ausente da pasta, o sistema o **restaura automaticamente a partir do pacote interno** antes de iniciar o jogo ou exibir qualquer erro do Windows.
  * A autocura atua preventivamente em 4 momentos: na instalação, na desinstalação, ao clicar no jogo na lista e no botão `[▶] INICIAR JOGO`.
* **Restauração Bidirecional de Backups na Troca de Modo:**
  * Transições entre Modo 1, Modo 2 e Modo 3 agora restauram arquivos originais de fábrica antes de injetar os componentes do novo modo.

---

### 🎨 2. Barra de Progresso Visual e Painel de Status em Tempo Real
* **Painel de Progresso In-Line:**
  * Nova barra de progresso contínua de 692px e painel de status integrados diretamente no container de ações (`$actionPanel`), no campo de visão imediato do usuário.
  * Progressão em 6 marcos percentuais graduais (15% ➔ 35% ➔ 55% ➔ 70% ➔ 85% ➔ 95% ➔ 100%) com descrições detalhadas de cada etapa.
  * Bloqueio dinâmico do botão durante a injeção (`⏳ INSTALANDO DLSS 5...`) com animação fluida a 60 FPS (`Application::DoEvents`).
* **Modal de Sucesso Modernizado (`Show-InstallationSuccessDialog`):**
  * Diálogo pós-instalação exibindo o executável do jogo, o modo ativo selecionado, guia de atalhos e botão direto `[▶] Iniciar Jogo Agora`.

---

### 🎮 3. Suíte de Filtros ReShade Pré-Configurada (Modos 1 e 3)
* **Filtros Integrados Prontos para Ativação:**
  * **AMD FidelityFX CAS (Contrast Adaptive Sharpening):** Nitidez adaptativa e clareza cristalina sem artefatos.
  * **Vibrance:** Realce de cores e saturação natural da imagem.
  * **SMAA / FXAA:** Suavização de bordas de alta performance.
  * Instalados pré-configurados em `ReShadePreset.ini`, porém desligados por padrão para não alterar a imagem sem a permissão do usuário.
* **Atalhos Globais de Controle:**
  * Tecla **`[End]`**: Alterna instantaneamente todos os filtros (LIGADO / DESLIGADO) para comparação A/B em tempo real.
  * Tecla **`[Home]`**: Abre o menu de sobreposição do ReShade para personalização fina.

---

### 🌐 4. Estabilização de Tipografia UTF-8 e 10 Idiomas Nativos
* **Eliminação de Caracteres Corrompidos:**
  * Arquivos de tradução e o script principal agora são gravados com **UTF-8 BOM (`0xEF, 0xBB, 0xBF`)**, resolvendo falhas de renderização de acentos no Windows PowerShell 5.1 (`Português`, `Español`, `Français`, `DIRETÓRIO`, `INJEÇÃO`).
  * Símbolos modernos e limpos em todos os botões (`[⚡]`, `[✓]`, `[▶]`, `[↩]`, `[📁]`).

---

### 🖥️ 5. Limpeza de Redundâncias e Polish Visual
* **Eliminação da Barra de Rolagem Branca:**
  * Larguras de coluna do ListView otimizadas para 405px (área útil de 432px), eliminando o artefato de scrollbar branca nativa do WinForms no modo escuro.
  * Redimensionamento automático dinâmico de colunas via evento `Add_Resize` e aplicação de tema dark do Windows Explorer (`uxtheme.dll`).
* **Executável Único e Nativo 64-Bit:**
  * Removidos executadores redundantes (`.bat` e `.vbs`). O aplicativo agora roda exclusivamente pelo executável compilado nativo **`1-Click-DLSS5.exe`** com ícone embutido de alta resolução e suporte a telas High-DPI (1080p, 1440p, 4K).

---

### 🧪 6. Auditoria e Confiabilidade
* **Suíte de Testes Automatizados Expandida para 29 Testes (100% PASS):**
  * Incluído o **Teste 29**, que valida a blindagem de integridade do `libxess.dll` e a autocura preventiva sob condições extremas de estresse.

---
---

## 🇺🇸 English

### 🌟 Release Highlights (v2.6.0)
Version **v2.6.0** delivers monumental improvements in **engine architecture**, **visual progress tracking**, and **game file integrity**. Introducing the **Vigilant Game Integrity & Auto-Healing Engine**, full UTF-8 BOM typography stabilization, high-visibility installation progress bar, and turnkey ReShade filter integration with master hotkey toggles.

### Key Changes:
1. **Game Integrity & Auto-Healing:** Protected vendor libraries (`libxess.dll`, `nvngx_dlss.dll`, `sl.*.dll`, AMD FSR) from inadvertent deletion. Automatic PE inspection detects and restores missing libraries from payload before launch.
2. **Prominent In-Line Progress Bar:** Real-time 6-stage milestone tracker (15% ➔ 100%) with step descriptions, button state locking, and modern success dialog.
3. **ReShade Post-Processing Filters (Modes 1 & 3):** AMD CAS Sharpening, Vibrance, and SMAA bundled and toggleable via `[End]` (master toggle) and `[Home]` (menu).
4. **UTF-8 BOM Stabilization:** Perfect character rendering for all 10 native languages without Windows-1252 corruption.
5. **Dark Mode Polish:** Eliminated white horizontal scrollbar glitch in game library list with dynamic column autosizing and `uxtheme.dll` integration.
6. **Unified Native 64-Bit Launcher:** Standalone `1-Click-DLSS5.exe` with embedded icon and DPI awareness (redundant `.bat`/`.vbs` eliminated).
7. **29/29 Automated Tests Passed (100%):** Validated across all injection modes and factory resets.

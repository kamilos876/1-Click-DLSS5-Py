# 🚀 MASTER HANDOFF — CONTEXTO COMPLETO DE DESENVOLVIMENTO
## Projeto: 1 Click DLSS 5 (Universal Neural Control Center)
**Versão Atual:** `v2.5.2-beta`  
**Repositório Local:** `C:\Users\Luis Eduardo\Downloads\dlss5\1-Click-DLSS5`  
**Último Commit:** `125b0d8` | **Tag:** `v2.5.2-beta`  
**Pacote de Distribuição:** `1-Click-DLSS5-v2.5.2-beta.zip` (217.60 MB)

---

## 1. 🎯 O QUE É O PROJETO E QUAL O SEU OBJETIVO?
O **1 Click DLSS 5** é um aplicativo desktop nativo para Windows (desenvolvido em PowerShell 5.1+ com interface Windows Forms em tema dark moderno) cujo objetivo é **democratizar e instalar com 1 clique a tecnologia DLSS 5 (DLSS Neural Rendering / DLSS-NR)** em **QUALQUER jogo de PC**, seja ele DirectX 9, DirectX 10, DirectX 11, DirectX 12, Vulkan ou OpenGL, em arquiteturas de 32 ou 64 bits.

O usuário apenas:
1. Abre o programa (via `1-Click-DLSS5.bat` ou `1-Click-DLSS5.vbs`).
2. O aplicativo escaneia todos os discos (`C:`, `D:`, `E:` etc.) e bibliotecas (Steam, Epic, Xbox, pastas manuais) e exibe os jogos em uma biblioteca com ícones de alta resolução e badges de compatibilidade.
3. O programa seleciona automaticamente o melhor modo de injeção para aquele jogo (ou o usuário pode escolher manualmente).
4. O usuário clica em `[⚡] 1-CLIQUE: INSTALAR DLSS 5` e depois em `[►] INICIAR JOGO AGORA`.
5. Se quiser remover tudo, o botão `[↩] RESTAURAR ESTADO DE FÁBRICA` remove 100% dos arquivos injetados e devolve o jogo ao estado original sem deixar lixo.

---

## 2. 🧠 O QUE É O "DLSS 5" E COMO ELE FUNCIONA?
* **DLSS-NR (Neural Reconstruction / Neural Rendering):** É a evolução da tecnologia da NVIDIA (`nvngx_dlssnr.dll`), onde um modelo de rede neural profunda convolucional/transformer substitui os passos manuais de denoiser, anti-aliasing e reconstrução de detalhes finos na GPU (Tensor Cores das placas RTX 20, 30, 40 e 50).
* **RenoDX Add-on:** Criado por **clshortfuse**, é um add-on oficial para ReShade 6.x (`renodx-dlss5.addon64`) que intercepta o pipeline gráfico do jogo, detecta chamadas de renderização e injeta o modelo DLSS-NR, oferecendo abas de ajuste in-game de contraste, tom HDR e reconstrução neural.

---

## 3. 🕹️ OS 3 MODOS DE OPERAÇÃO DO 1-CLICK DLSS 5

O programa possui 3 motores de injeção distintos e cirúrgicos:

### 🟢 MODO 1: DIRETO (DLSS Nativo)
* **Público-alvo:** Jogos modernos que **já possuem DLSS nativo** (Ex: *Cyberpunk 2077, Red Dead Redemption 2, The Witcher 3 Next-Gen, Forza Horizon 5*).
* **Mecânica:**
  * O jogo já chama a NVIDIA NGX API (`nvngx_dlss.dll`).
  * Injeta-se o ReShade proxy (`dxgi.dll`), o add-on `renodx-dlss5.addon64` e o modelo `nvngx_dlssnr.dll`.
  * **Salvaguardas críticas desenvolvidas:**
    * **The Witcher 3:** NUNCA sobrescrever o `sl.interposer.dll` ou `sl.common.dll` nativo do jogo (evita o crash `slGetFeatureSettings Entry Point Not Found`).
    * **Red Dead Redemption 2:** O jogo não usa Streamline, chama NGX direto. O `ReShade.ini` deve ter `EnableHooks=1`. Manter o `nvngx_dlss.dll` nativo intocado (evita falha de integridade do Rockstar Games Launcher). O jogo DEVE rodar em DirectX 12.

### 🔵 MODO 2: PONTE OPTISCALER (Jogos com FSR 2 ou XeSS)
* **Público-alvo:** Jogos que **não possuem DLSS nativo, mas possuem AMD FSR 2/3 ou Intel XeSS** (Ex: *God of War 2018, Horizon Zero Dawn, Dead Space Remake*).
* **Mecânica:**
  * Injeta o **OptiScaler** como proxy DLL (`version.dll`) + `OptiScaler.ini` + `libxess.dll`.
  * O ReShade atua como `dxgi.dll`.
  * O OptiScaler intercepta as chamadas de FSR2/XeSS do jogo e as redireciona para a renderização neural do DLSS 5.
  * O jogador ativa "FSR 2 (Qualidade)" no menu do jogo e o OptiScaler converte para DLSS-NR em tempo real.

### 🟣 MODO 3: FEEDER UNIVERSAL (DLAA 100% Nativo)
* **Público-alvo:** Jogos que **NÃO possuem nenhum upscaler nativo**, jogos DirectX 11, DirectX 9, DirectX 12 clássicos, Vulkan ou OpenGL (Ex: *Mafia: Definitive Edition, BeamNG.drive, 7 Days to Die, Final Fantasy X, Skyrim, Fable*).
* **Mecânica Profunda:**
  * Utiliza o **DLSS5-Feeder** (criado por **jlrouzies-fr**, atualmente na versão oficial **v0.12.0**).
  * Cria uma fila de comandos D3D12 oculta privada compartilhada via NT Handles (`WDDM Cross-API Sharing`).
  * Constrói um contrato sintético de DLSS em **100% de Resolução Nativa ($1.0\times$ DLAA)**.
  * **Zero Blur / Sem Letras Embaçadas:** O arquivo `dlss5-feed.cfg` é forçado com `preset=6` e `work_resolution=100`, eliminando interpolação bilinear ou perda de nitidez.
  * **Zero Crashes no DirectX 11 (Suíte Lumenite Kernel):** O Feeder precisa de vetores de movimento. Nós acoplamos a suíte **LumeniteFX** (`lumenite_Kernel.fx`), configurando `DLSS5_MV_PROVIDER=3` e garantindo que o `lumenite_Kernel.fx` execute antes do `DLSS5_Feed.fx` no `ReShadePreset.ini`.
  * **Jogos 32-bit (x86):** O Feeder opera com `dlss5-feed.addon32` + processo auxiliar de 64-bit `host64\dlss5-feed-host64.exe`. O RenoDX de 64 bits fica restrito à pasta `host64\` e o painel in-game do v0.12.0 é desenhado no canto da tela sem precisar de Alt-Tab.
  * **Jogos Vulkan:** Camada dedicada `VkLayer_feed_vk.dll` acionada via variáveis de ambiente de processo (`VK_LAYER_PATH` e `VK_INSTANCE_LAYERS`) sem tocar no Registro do Windows.

---

## 4. 📂 ESTRUTURA COMPLETA DE PASTAS E ARQUIVOS

```text
1-Click-DLSS5/
├── 1-Click-DLSS5.bat             # Launcher universal .bat (compatível com caminhos com espaços/acentos)
├── 1-Click-DLSS5.vbs             # Launcher silencioso .vbs sem janela de prompt
├── 1-Click-DLSS5-v2.5.2-beta.zip # Pacote oficial limpo pronto para download
├── README.md                     # Documentação completa em inglês com prévias dos 3 modos
├── CHANGELOG.md                  # Histórico de todas as versões (v2.5.0, v2.5.1, v2.5.2-beta)
├── CONTRIBUTING.md               # Diretrizes de contribuição
├── LICENSE                       # Licença MIT
├── docs/                         # Capturas de tela e assets de documentação
│   ├── mode1_direct_preview.png  # Print do Modo 1 no Cyberpunk 2077
│   ├── mode2_optiscaler_preview.png # Print do Modo 2 no God of War
│   └── mode3_feeder_preview.png  # Print do Modo 3 no Mafia Definitive Edition
└── core/                         # Núcleo da aplicação
    ├── 1-Click-DLSS5.ps1         # Script principal (UI WinForms + Motores de Injeção e Scanner)
    ├── 1-Click-DLSS5.log         # Log contínuo de telemetria
    ├── assets/
    │   ├── icon.ico              # Ícone oficial de alta resolução
    │   └── translations.json     # Dicionário dinâmico completo em 10 idiomas (EN, PT, ES, DE, FR, IT, JA, ZH, RU, KO)
    └── payload/                  # Binários e bibliotecas de injeção
        ├── dxgi.dll              # ReShade 6.8.0 com suporte a Add-on (64-bit)
        ├── dxgi32.dll            # ReShade 6.8.0 com suporte a Add-on (32-bit)
        ├── nvngx_dlss.dll        # NVIDIA DLSS 3.10.8 runtime
        ├── nvngx_dlssnr.dll      # NVIDIA DLSS-NR (Neural Rendering) runtime
        ├── renodx-dlss5.addon64  # Add-on oficial do RenoDX DLSS 5 Generic v4.7
        ├── sl.dlss_nr.dll        # Plugin Streamline para DLSS-NR
        ├── optiscaler/           # Payload do Modo 2 (OptiScaler)
        │   ├── OptiScaler.dll    # Binário do OptiScaler v0.9.4
        │   ├── OptiScaler.ini    # Configuração pré-calibrada
        │   └── libxess.dll       # Biblioteca de compatibilidade XeSS
        └── feeder/               # Payload do Modo 3 (Feeder v0.12.0)
            ├── dlss5-feed.addon64 # Feeder Add-on oficial 64-bit (v0.12.0)
            ├── dlss5-feed.addon32 # Feeder Add-on oficial 32-bit (v0.12.0)
            ├── dlss5-feed.cfg    # Configuração pré-calibrada (preset=6 DLAA 100% nativo)
            ├── host64/           # Processo auxiliar de 64-bit para jogos 32-bit
            │   └── dlss5-feed-host64.exe (v0.12.0)
            ├── layer-x64/        # Camada Vulkan 64-bit (VkLayer_feed_vk.dll + json)
            ├── layer-x86/        # Camada Vulkan 32-bit (VkLayer_feed_vk32.dll + json)
            ├── textures/         # Texturas ReShade (lumenite_bluenoise256.png)
            └── shaders/          # Shaders do ReShade
                ├── DLSS5_Feed.fx # Shader oficial companion do Feeder v0.12.0
                ├── lumenite_Kernel.fx # Kernel de Optical Flow do Lumenite
                ├── lumenite_TRAA.fx
                ├── ReShade.fxh, ReShadeUI.fxh, DrawText.fxh
                └── include/      # Headers matemáticos do Lumenite
```

---

## 5. 🛠️ ARQUITETURA DO CÓDIGO (`core/1-Click-DLSS5.ps1`)

O arquivo `1-Click-DLSS5.ps1` (~2250 linhas) possui as seguintes funções e blocos estruturais vitais:

1. **`Resolve-GameTarget`:**
   * Recebe um caminho de pasta ou executável.
   * **Inteligência de Subpastas de Motores 64-bit:** Prioriza executáveis 64-bit em pastas como `Bin64\` (BeamNG.drive, CryEngine), `bin\x64\` (Cyberpunk, Witcher 3), `binaries\win64\` (Unreal Engine), `x64\`. Se a raiz contiver um launcher de 32 bits (como no BeamNG.drive), ele ignora o launcher e mira diretamente no motor de 64 bits na subpasta.
2. **`Scan-DriveForGames`:**
   * Detecta discos fixos e bibliotecas Steam (`libraryfolders.vdf`), Epic Games (`Manifests\*.item`) e pastas de jogos personalizadas.
   * Imune a colchetes `[...]`, espaços e caracteres especiais em nomes de pastas.
3. **`Install-Dlss5`:**
   * Executa a injeção do Modo 1, 2 ou 3.
   * **Isolamento de Modos:** Se o jogo já tinha outro modo instalado, purga cirurgicamente os arquivos do modo anterior antes de injetar o novo, evitando conflitos de dois proxies simultâneos (`version.dll` + `dxgi.dll`).
   * **Backup Automático (`Safe-Copy`):** Qualquer arquivo do jogo que seria substituído é copiado com segurança para `_1Click_DLSS5_Backup\` e registrado no estado JSON.
   * **Proteção de Preexistentes:** Faz backup de `ReShade.ini` e `ReShadePreset.ini` se o jogador já usava ReShade.
4. **`Uninstall-Dlss5` (Restauração de Fábrica):**
   * Purgador cirúrgico incondicional que remove proxies, add-ons, shaders e logs, e restaura fielmente os arquivos originais do backup bit a bit.
5. **`Auto-Fix Engine` (`Invoke-1ClickAutoFix`):**
   * Finaliza processos travados do jogo em segundo plano.
   * Limpa atributos de somente leitura do Windows (`attrib -r`).
   * Limpa caches corrompidos e reinstala o DLSS 5.
6. **Interface Gráfica WinForms (HUD v2):**
   * Modo escuro moderno, banner com ícone em alta definição extraído do executável, cartões interativos dos 3 modos, seletor de 10 idiomas em tempo real e painel de diagnóstico do sistema (`🩺 Diagnóstico`).

---

## 6. 🏆 CASOS RESOLVIDOS RECENTEMENTE (HISTÓRICO TÉCNICO)

1. **The Witcher 3 Next-Gen:** Crash `slGetFeatureSettings Entry Point Not Found` corrigido protegendo o interposer nativo do Streamline no Modo 1.
2. **Red Dead Redemption 2:** Erro `0xBAD00007 / NO DLSS CREATE SEEN` corrigido configurando `EnableHooks=1` no ReShade.ini (já que RDR2 usa NGX direto sem Streamline) e instruindo o uso de DirectX 12.
3. **Mafia: Definitive Edition:** Eliminação de crashes e texturas embaçadas no Feeder combinando o `DLSS5_Feed.fx` com o `lumenite_Kernel.fx` (`DLSS5_MV_PROVIDER=3`) e `preset=6` no `dlss5-feed.cfg`.
4. **Feeder v0.12.0:** Atualização do Feeder para a versão lançada em 02/09/2026 com dreno de GPU antes de rebuild, FSR 1 expand-back e painel in-game para 32-bit.
5. **BeamNG.drive:** Corrigido o bug onde o instalador pegava o launcher de 32 bits da raiz (`BeamNG.drive.exe`) em vez do motor de 64 bits em `Bin64\BeamNG.drive.x64.exe`.

# Changelog — 1 Click DLSS 5

All notable changes, architectural overhauls, and bug fixes for the **1 Click DLSS 5** project are documented in this file.

---

## [v2.5.2-beta] - 2026-09-02

### 🚀 Major Engine Upgrades & DLSS 5 Feeder v0.12.0
- **Feeder Core Upgraded to Official v0.12.0 (Mode 3):**
  - Updated all bundled Feeder binaries (`dlss5-feed.addon64`, `dlss5-feed.addon32`, `host64/dlss5-feed-host64.exe`, and `DLSS5_Feed.fx`) to the latest official v0.12.0 release.
  - **GPU Drain Before Rebuild:** Added command queue draining prior to D3D12 feature recreation, eliminating Device Removal (TDR) crashes.
  - **AMD FSR 1 Expand-Back (EASU + RCAS):** Replaced legacy bilinear stretching with AMD FSR 1 spatial upscaling + sharpening when operating at lower work resolutions.
  - **In-Game Overlay for 32-bit Games:** Added live in-game panel mirroring for 32-bit titles without requiring Alt-Tab.
- **Pristine 100% Native DLAA Clarity (Zero Blurry Text):**
  - Strictly enforced native resolution DLAA profile (`preset=6` and `work_resolution=100`) in `dlss5-feed.cfg`.
  - Preserved the full **LumeniteFX Kernel** suite (`lumenite_Kernel.fx`, `lumenite_TRAA.fx`, headers and blue noise texture) at the top of the execution chain (`DLSS5_MV_PROVIDER=3`).
- **Dynamic Cross-Mode Isolation:**
  - Automatically detects and cleanly purges inactive mode files when switching between Mode 1 (Direct), Mode 2 (OptiScaler), and Mode 3 (Feeder), preventing dual-proxy conflicts (`version.dll` + `dxgi.dll`).
  - Preserves original game file backups across mode changes.
- **Preexisting ReShade Configuration Protection:**
  - Preexisting `ReShade.ini` and `ReShadePreset.ini` are now safely preserved in `_1Click_DLSS5_Backup\` and restored with 100% byte-fidelity on factory reset.
- **Native Game `nvngx_dlss.dll` Integrity Protection (Mode 1):**
  - Mode 1 strictly preserves native game DLSS binaries, preventing hash mismatch flags in third-party launchers (Rockstar Games Launcher in RDR2, EA App, Ubisoft Connect).
- **Universal Launcher & Path Resiliency:**
  - Added standalone `1-Click-DLSS5.bat` launcher in repository root with robust `%~dp0` quote handling.
  - Hardened game drive scanner with bracket `[...]` and non-ASCII character immunity.
  - Added non-invasive runtime Vulkan layer binding (`VK_LAYER_PATH` / `VK_INSTANCE_LAYERS`) without Windows Registry modifications.

---

## [v2.5.1] - 2026-09-02

### 🛡️ Critical Engine Fixes & Game Compatibility
- **Witcher 3 Next-Gen Streamline Protection (Mode 1):**
  - Resolved `Entry Point Not Found: slGetFeatureSettings` crash on startup in *The Witcher 3: Complete Edition*.
  - Mode 1 strictly preserves native game `sl.interposer.dll` and `sl.common.dll` binaries, avoiding DLL version conflicts.
- **Red Dead Redemption 2 & NGX Direct Games (Mode 1):**
  - Fixed `0xBAD00007 / HOOKS ARMED - NO DLSS CREATE SEEN` issue in non-Streamline games like *Red Dead Redemption 2*.
  - Automatically configures `EnableHooks=1` for pure NGX titles.
  - Added smart guidance: RDR2 requires setting the in-game Graphics API to **DirectX 12** (*Settings > Graphics > Advanced > Graphics API = DirectX 12*).
- **Bulletproof 1-Click Factory Restoration:**
  - Guaranteed unconditional removal of proxy DLLs (`dxgi.dll`, `d3d12.dll`, `d3d9.dll`, `opengl32.dll`), add-ons, and shader caches on factory reset.
- **DLSS 5 Feeder Core Updated to v0.12.0 (Mode 3):**
  - Updated bundled Feeder binaries (`dlss5-feed.addon64`, `dlss5-feed.addon32`, `dlss5-feed-host64.exe`, and `DLSS5_Feed.fx`) to the official v0.12.0 release.
  - Preserved 100% native DLAA image clarity (`preset=6` and `work_resolution=100`) with zero text or texture blur.
  - Maintained full LumeniteFX Kernel motion vector estimation (`DLSS5_MV_PROVIDER=3` and `Lumenite_Kernel.fx` execution priority).
  - Integrated GPU drain before teardown to eliminate device-removal crashes during texture rebuilds.
  - Added FSR 1 (EASU + RCAS) expand-back upscaling and sharpness filter for lower work resolutions.
  - Integrated live in-game settings panel mirroring for 32-bit games without needing Alt-Tab.
  - Added dedicated non-intrusive Vulkan layer packages (`layer-x64` / `layer-x86`) and updated uninstaller purge list to ensure 100% clean factory restoration.
- **UI & Documentation Sync:**
  - Integrated 3 dedicated individual interface previews for Modes 1, 2, and 3 in the documentation.


## [v2.5.0-beta] - 2026-09-02

### 🚀 Major Features & Architectural Redesign (HUD v2)
- **🛡️ The Witcher 3 & Streamline Interposer Protection (Mode 1):**
  - Eliminated `Entry Point Not Found: slGetFeatureSettings` startup crashes in *The Witcher 3: Complete Edition* and Streamline games.
  - The installer now strictly preserves the game's native `sl.interposer.dll` and `sl.common.dll`, injecting only ReShade proxy, RenoDX addon, and `nvngx_dlssnr.dll`.

- **🎯 Red Dead Redemption 2 & Non-Streamline NGX Hooking:**
  - Fixed `HOOKS ARMED - NO DLSS CREATE SEEN` / `0xBAD00007` in *Red Dead Redemption 2* and native NGX games.
  - Automatically configures `EnableHooks=1` for non-Streamline games to hook the NVIDIA NGX export directly.
  - Added smart guidance: RDR2 requires setting the in-game Graphics API to **DirectX 12** (*Settings > Graphics > Advanced > Graphics API = DirectX 12*).

- **↩️ Bulletproof 1-Click Factory Restoration:**
  - Restored unconditional, guaranteed purging of proxy DLLs (`dxgi.dll`, `d3d12.dll`, `d3d9.dll`, `opengl32.dll`), addons, and shaders during factory reset, preventing broken game states.
- **✨ Complete UI Overhaul (HUD v2):**
  - Modern, minimalist, high-contrast dark theme built from the ground up for both beginner and advanced users.
  - Streamlined 3-step visual workflow: `[1] Select Game` ➔ `[2] Click Install` ➔ `[3] Launch & Enjoy!`.
  - Removed all duplicate buttons and legacy cluttered options.
  - Interactive mode selection cards with distinct accent colors and contextual in-game requirement instructions.
  - Selected Game Banner displays the extracted high-resolution application icon, real-time injection status, and API badge.

- **⚡ 1-Click Auto-Fix Engine & Smart Diagnosis:**
  - Automated issue resolution assistant: analyzes *What Happened*, *Probable Cause*, and *How to Fix*.
  - `[⚡] 1-CLICK AUTO-FIX` button automatically terminates stuck game processes, clears read-only permission locks (`attrib -r`), and reapplies injection cleanly.
  - Interactive `🩺 SYSTEM DIAGNOSTICS` checklist validating RTX GPU tensor support, directory write access, active game processes, and neural runtime file integrity.

- **🌍 Native 10-Language Support:**
  - Full dynamic real-time language switching without restart for:
    - 🇺🇸 English (EN-US)
    - 🇧🇷 Portuguese (PT-BR)
    - 🇪🇸 Spanish (ES)
    - 🇩🇪 German (DE)
    - 🇫🇷 French (FR)
    - 🇮🇹 Italian (IT)
    - 🇯🇵 Japanese (JA)
    - 🇨🇳 Simplified Chinese (ZH)
    - 🇷🇺 Russian (RU)
    - 🇰🇷 Korean (KO)
  - All localization dictionaries unified in `core/assets/translations.json`.

- **🎮 Instant Game Auto-Discovery & Multi-Platform Scanner:**
  - Fast, non-blocking multi-drive scanner detecting games across **Steam** (`libraryfolders.vdf`), **Epic Games** (`.item` manifests), **GOG**, **Xbox Games**, and **EA App**.
  - Real-time search bar for filtering titles by name or graphics API.

- **⚙️ Universal Graphics API & Architecture Support:**
  - Full native support for **DirectX 12, DirectX 11, DirectX 9, Vulkan, and OpenGL**.
  - Complete support for **32-bit (x86)** and **64-bit (x64)** games via `host64` IPC texture transport.

- **🎯 Critical Fix for Universal Feeder (Mode 3 - 100% Native DLAA):**
  - Resolved DX11 startup crashes and texture blurring (e.g., in *Mafia Definitive Edition*).
  - Integrated **Lumenite Kernel** (`Lumenite_Kernel.fx`) at the head of ReShade's technique chain for accurate optical flow motion vector calculation.
  - Configured `preset=6` in `dlss5-feed.cfg` for maximum frame stability.
  - Added recursive search paths (`\**`) in `ReShade.ini` (`EffectSearchPaths=.
eshade-shaders\Shaders\**`).
  - Calibrated RenoDX neural tone & structure parameters (`NRGlobalTone=0.9`, `NRLocalStructure=0.44`, `NRLocalTone=1.22`, `NRSkinStructure=1.16`).

- **↩️ 100% Clean Factory Restoration:**
  - Smart uninstaller restores original backed-up executables/DLLs and surgically purges all injected files, shaders, and logs.

---

## [v1.5.1] - Hotfix & Multi-Drive Resolver
- Fixed multi-drive Steam library resolution when installed across secondary volumes.
- Added 32-bit PE machine type header detection.
- Added profiles for Final Fantasy X HD Remaster and Falcom / Cold Steel titles.
- Optimized drive scanner with depth-controlled traversal.

## [v1.5.0] - Universal API Detection Engine
- Implemented deterministic graphics API detector for D3D12, D3D11, D3D9, Vulkan, and OpenGL.
- Initial integration of shader suite and luma mask calibration.

## [v1.4.0] - OptiScaler Bridge Mode (Mode 2)
- Added Mode 2 for games with FSR 2/3 or XeSS support, redirecting calls to DLSS-NR via OptiScaler.

## [v1.3.0] - Direct Injection Mode (Mode 1)
- Implemented Mode 1 for native DLSS games using Streamline interposer and RenoDX DLSS-NR addon.

## [v1.2.0] - Multi-Language & Confirmation System
- Introduced bilingual English/Portuguese UI and confirmation dialogs.

## [v1.1.0] - Initial Public Release
- Initial release featuring ReShade + RenoDX DLSS 5 injection.

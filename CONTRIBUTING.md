# Contributing to 1 Click DLSS 5

Thank you for your interest in improving **1 Click DLSS 5**!

## How to Contribute

1. **Add Game Profiles:** If you found a game that requires a specific subdirectory structure (e.g. `Engine/Binaries/Win64`), you can submit a pull request adding the profile to `$script:GameProfiles` in `1-Click-DLSS5.ps1`.
2. **Report Issues:** Open an issue on GitHub detailing:
   * Game title and store platform (Steam, Epic, Xbox Game Pass, GOG).
   * Exact GPU model and NVIDIA driver version.
   * Diagnostic log copied from the real-time status window.
3. **Submit Enhancements:** Fork the repository, create a descriptive branch, commit your changes, and open a Pull Request.

## Guidelines
* Ensure all scripts pass syntax checks (`[System.Management.Automation.Language.Parser]::ParseFile(...)`).
* Save PowerShell files with UTF-8 BOM (`utf-8-sig`) to ensure proper rendering across Windows PowerShell 5.1 and modern PowerShell 7+.
* Test with both `PT-BR` and `EN-US` language modes.

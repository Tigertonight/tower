# Environment Setup

Project codename: **Tower**

Date: 2026-05-10

## Installed Tools

| Tool | Version | Install Method | Notes |
| --- | --- | --- | --- |
| Godot Engine | 4.6.2 stable | winget | Standard edition, suitable for GDScript-first development. |
| Git | Installed | Existing local install | Available through Scoop shim. |

## Godot Installation

Package:

```text
GodotEngine.GodotEngine
```

Installed executable paths:

```text
C:\Users\admin\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.6.2-stable_win64.exe
C:\Users\admin\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.6.2-stable_win64_console.exe
```

Command shims:

```text
C:\Users\admin\scoop\shims\godot.cmd
C:\Users\admin\scoop\shims\godot_console.cmd
```

## Verification

Verified command:

```powershell
godot_console --version
```

Verified output:

```text
4.6.2.stable.official.71f334935
```

## Notes

- Godot Mono/C# edition is not installed because the current technical plan uses GDScript first.
- If the project later chooses C#, install `GodotEngine.GodotEngine.Mono` and the appropriate .NET SDK.
- Export templates are not required for early development. Install them later when packaging builds for Windows, macOS, Linux, Web, or mobile.

# SubtitleShade

A tiny always-on-top bar you park over burned-in movie subtitles to hide them.
Borderless, draggable, resizable, recolorable, and it remembers where you left it.

Available for **Windows** and **macOS**.

---

## Features

- Stays on top of all other windows
- No title bar — just a clean bar
- Drag anywhere to move; drag edges/corners to resize
- Adjustable color (presets + full custom color picker)
- Adjustable opacity (aim it while semi-transparent, then make it fully opaque)
- Hint text auto-switches between light/dark for readability on any color
- Remembers color, size, opacity, and position between launches

## Controls

| Action | How |
|---|---|
| Move | Drag anywhere on the bar |
| Resize | Drag an edge or corner |
| Nudge position | Arrow keys |
| Resize by keyboard | Shift + Arrow keys |
| Opacity | `+` / `-` |
| Color / opacity / help | Right-click for the menu |
| Quit | `Esc` (Windows) · `Esc` or `Cmd+Q` (macOS) |

> Tip: switch to **Semi-transparent** to line the bar up over the subtitles, then switch to **Fully opaque** to hide them. Works over windowed/borderless-fullscreen video; true exclusive-fullscreen players can't be overlaid by any app.

---

## Windows

**Just run it:** download `SubtitleShade.exe` and double-click. No install.

**Build it yourself** (optional) — Windows already ships the C# compiler, no Visual Studio needed:

```bat
build.bat
```

There's also a no-compile PowerShell version: run `SubtitleShade.bat`.

Files: `SubtitleShade.cs` (source) · `build.bat` (compiler) · `SubtitleShade.ps1` + `SubtitleShade.bat` (script version).

## macOS

**Build it** (requires the Xcode Command Line Tools — `xcode-select --install`):

```bash
chmod +x build-macos.sh
./build-macos.sh
```

This produces `SubtitleShade.app`. Because the app is **unsigned**, macOS Gatekeeper will block the first launch. Either:

- Right-click `SubtitleShade.app` → **Open** → **Open**, or
- Clear the quarantine flag:

```bash
xattr -dr com.apple.quarantine SubtitleShade.app
```

Files: `SubtitleShade.swift` (source) · `build-macos.sh` (builder).

---

## Notes

- Windows settings are stored in `SubtitleShade.config.txt` (next to the `.exe`) or `SubtitleShade.config.json` (script version).
- macOS settings are stored in the app's `UserDefaults`.
- Delete those to reset to defaults.

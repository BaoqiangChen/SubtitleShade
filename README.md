# SubtitleShade

A tiny always-on-top bar you park over burned-in movie subtitles to hide them.
Borderless, draggable, resizable, recolorable, and it remembers where you left it.

Available for **Windows** and **macOS**.

## Download

Grab the latest build from the **[Releases page](https://github.com/BaoqiangChen/SubtitleShade/releases/latest)** — no building required:

- **Windows** → `SubtitleShade.exe`
- **macOS** → `SubtitleShade-macOS.zip`

> **macOS users:** the app is **not signed** by Apple, so macOS won't trust it on the first launch. This is normal for free open-source apps — see [Trusting the app on macOS](#trusting-the-app-on-macos) below for the one-time steps to open it.

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

**Just run it:** [download `SubtitleShade.exe`](https://github.com/BaoqiangChen/SubtitleShade/releases/latest) and double-click. No install.

**Build it yourself** (optional) — Windows already ships the C# compiler, no Visual Studio needed:

```bat
build.bat
```

There's also a no-compile PowerShell version: run `SubtitleShade.bat`.

Files: `SubtitleShade.cs` (source) · `build.bat` (compiler) · `SubtitleShade.ps1` + `SubtitleShade.bat` (script version).

## macOS

**Just run it:** [download `SubtitleShade-macOS.zip`](https://github.com/BaoqiangChen/SubtitleShade/releases/latest), double-click to unzip, then open `SubtitleShade.app`. No install.

### Trusting the app on macOS

`SubtitleShade.app` isn't signed with an Apple Developer certificate, so on the **first launch** macOS shows a warning like *"SubtitleShade can't be opened because Apple cannot check it for malicious software."* This is expected for free unsigned apps. To open it, do this **once**:

**Option A — Right-click to open (easiest):**
1. In Finder, **right-click** (or Control-click) `SubtitleShade.app`.
2. Choose **Open**.
3. In the dialog, click **Open** again.

That's it — macOS remembers your choice, and afterwards you can open it normally by double-clicking.

**Option B — From System Settings** (if you already double-clicked and got blocked):
1. Open  → **System Settings** → **Privacy & Security**.
2. Scroll to the **Security** section — you'll see *"SubtitleShade was blocked…"*.
3. Click **Open Anyway**, then confirm.

**Option C — Terminal** (removes the quarantine flag directly):

```bash
xattr -dr com.apple.quarantine /path/to/SubtitleShade.app
```

> Why the warning? Signing an app requires a paid Apple Developer account. Since this is a free open-source tool, it's distributed unsigned — the source code is right here in this repo if you'd like to inspect or build it yourself.

### Build it yourself (optional)

Requires the Xcode Command Line Tools (`xcode-select --install`):

```bash
chmod +x build-macos.sh
./build-macos.sh
```

This produces `SubtitleShade.app`. Files: `SubtitleShade.swift` (source) · `build-macos.sh` (builder).

---

## Notes

- Windows settings are stored in `SubtitleShade.config.txt` (next to the `.exe`) or `SubtitleShade.config.json` (script version).
- macOS settings are stored in the app's `UserDefaults`.
- Delete those to reset to defaults.

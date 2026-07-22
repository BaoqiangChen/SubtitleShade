// SubtitleShade (macOS) - an always-on-top, borderless, adjustable bar to shade movie subtitles.
// Build with build-macos.sh (uses swiftc from the Xcode Command Line Tools).
import Cocoa

// A borderless window normally can't receive keyboard focus; allow it.
final class ShadeWindow: NSWindow {
    override var canBecomeKey: Bool { return true }
    override var canBecomeMain: Bool { return true }

    override func keyDown(with event: NSEvent) {
        let step: CGFloat = 10
        let shift = event.modifierFlags.contains(.shift)

        // Opacity: + / = to increase, - / _ to decrease
        if let ch = event.charactersIgnoringModifiers {
            if ch == "+" || ch == "=" { alphaValue = min(1.0, alphaValue + 0.05); return }
            if ch == "-" || ch == "_" { alphaValue = max(0.1, alphaValue - 0.05); return }
        }

        var f = self.frame // macOS origin is bottom-left
        switch event.keyCode {
        case 53: NSApp.terminate(nil)                                             // Esc
        case 123: if shift { f.size.width  = max(80, f.size.width  - step) } else { f.origin.x -= step } // Left
        case 124: if shift { f.size.width += step }                         else { f.origin.x += step } // Right
        case 126: if shift { f.size.height += step }                        else { f.origin.y += step } // Up
        case 125: if shift { f.size.height = max(20, f.size.height - step) } else { f.origin.y -= step } // Down
        default: super.keyDown(with: event); return
        }
        setFrame(f, display: true)
    }
}

// A label that lets clicks pass through so drag-to-move and right-click hit the window.
final class PassthroughLabel: NSTextField {
    override func hitTest(_ point: NSPoint) -> NSView? { return nil }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    var window: ShadeWindow!
    var label: PassthroughLabel!

    let presets: [(String, NSColor)] = [
        ("Black",     NSColor(srgbRed: 0,     green: 0,     blue: 0,     alpha: 1)),
        ("Dark gray", NSColor(srgbRed: 0.41,  green: 0.41,  blue: 0.41,  alpha: 1)),
        ("White",     NSColor(srgbRed: 1,     green: 1,     blue: 1,     alpha: 1)),
        ("Blue",      NSColor(srgbRed: 0.098, green: 0.098, blue: 0.439, alpha: 1)),
        ("Green",     NSColor(srgbRed: 0,     green: 0.392, blue: 0,     alpha: 1)),
    ]

    func applicationDidFinishLaunching(_ note: Notification) {
        let d = UserDefaults.standard

        // ---- defaults, overwritten by saved settings ----
        let w = d.object(forKey: "W") != nil ? CGFloat(d.double(forKey: "W")) : 900
        let h = d.object(forKey: "H") != nil ? CGFloat(d.double(forKey: "H")) : 70
        let opacity = d.object(forKey: "Opacity") != nil ? d.double(forKey: "Opacity") : 0.85
        let bg = colorFromHex(d.string(forKey: "Color") ?? "#000000")

        window = ShadeWindow(
            contentRect: NSRect(x: 0, y: 0, width: w, height: h),
            styleMask: [.borderless, .resizable],
            backing: .buffered, defer: false)
        window.isMovableByWindowBackground = true          // drag anywhere to move
        window.level = .floating                            // stay above normal windows
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.backgroundColor = bg
        window.alphaValue = CGFloat(opacity)
        window.hasShadow = false
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 80, height: 20)

        // ---- position: saved, else centered near the bottom ----
        if d.object(forKey: "X") != nil, d.object(forKey: "Y") != nil {
            window.setFrameOrigin(NSPoint(x: d.double(forKey: "X"), y: d.double(forKey: "Y")))
        } else if let vf = NSScreen.main?.visibleFrame {
            window.setFrameOrigin(NSPoint(x: vf.midX - w / 2, y: vf.minY + 60))
        }

        // ---- hint label (configured manually so the subclass is used) ----
        label = PassthroughLabel(frame: .zero)
        label.stringValue = "drag to move  |  edges to resize  |  right-click for menu  |  Esc to quit"
        label.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        label.alignment = .center
        label.drawsBackground = false
        label.isBordered = false
        label.isBezeled = false
        label.isEditable = false
        label.isSelectable = false
        label.lineBreakMode = .byClipping
        label.translatesAutoresizingMaskIntoConstraints = false
        let cv = window.contentView!
        cv.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: cv.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: cv.centerYAnchor),
        ])
        updateHintColor()

        // ---- right-click menu on the window background ----
        cv.menu = buildMenu()

        buildMainMenu() // gives Cmd+Q
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationWillTerminate(_ note: Notification) { saveConfig() }

    // ---- Hint contrast: light text on dark bg, dark text on light bg ----
    func updateHintColor() {
        let c = (window.backgroundColor.usingColorSpace(.sRGB)) ?? NSColor.black
        let lum = 0.299 * c.redComponent + 0.587 * c.greenComponent + 0.114 * c.blueComponent // 0..1
        label.textColor = lum < 0.5
            ? NSColor(white: 210.0 / 255.0, alpha: 1)
            : NSColor(white: 40.0 / 255.0, alpha: 1)
    }

    // ---- Menus ----
    func buildMenu() -> NSMenu {
        let menu = NSMenu()

        let colorItem = NSMenuItem(title: "Color", action: nil, keyEquivalent: "")
        let colorMenu = NSMenu()
        for (name, color) in presets {
            let it = NSMenuItem(title: name, action: #selector(setPresetColor(_:)), keyEquivalent: "")
            it.target = self
            it.representedObject = color
            colorMenu.addItem(it)
        }
        colorMenu.addItem(.separator())
        let custom = NSMenuItem(title: "Custom…", action: #selector(pickColor(_:)), keyEquivalent: "")
        custom.target = self
        colorMenu.addItem(custom)
        colorItem.submenu = colorMenu
        menu.addItem(colorItem)

        let opaque = NSMenuItem(title: "Fully opaque (block completely)", action: #selector(setOpaque), keyEquivalent: "")
        opaque.target = self; menu.addItem(opaque)
        let semi = NSMenuItem(title: "Semi-transparent (aim mode)", action: #selector(setSemi), keyEquivalent: "")
        semi.target = self; menu.addItem(semi)

        menu.addItem(.separator())
        let help = NSMenuItem(title: "Help / controls", action: #selector(showHelp), keyEquivalent: "")
        help.target = self; menu.addItem(help)

        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Close", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "")
        menu.addItem(quit)
        return menu
    }

    func buildMainMenu() {
        let mainMenu = NSMenu()
        let appItem = NSMenuItem()
        mainMenu.addItem(appItem)
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "Quit SubtitleShade",
                        action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu
        NSApp.mainMenu = mainMenu
    }

    // ---- Menu actions ----
    @objc func setPresetColor(_ sender: NSMenuItem) {
        if let c = sender.representedObject as? NSColor {
            window.backgroundColor = c
            updateHintColor()
        }
    }
    @objc func pickColor(_ sender: Any?) {
        let panel = NSColorPanel.shared
        panel.setTarget(self)
        panel.setAction(#selector(colorPanelChanged(_:)))
        panel.color = window.backgroundColor
        panel.showsAlpha = false
        panel.makeKeyAndOrderFront(nil)
    }
    @objc func colorPanelChanged(_ sender: NSColorPanel) {
        window.backgroundColor = sender.color
        updateHintColor()
    }
    @objc func setOpaque() { window.alphaValue = 1.0 }
    @objc func setSemi()   { window.alphaValue = 0.6 }
    @objc func showHelp() {
        let a = NSAlert()
        a.messageText = "SubtitleShade controls"
        a.informativeText =
            "• Drag anywhere on the bar to move it.\n" +
            "• Drag the bar's edges/corners to resize.\n" +
            "• Arrow keys: nudge position.\n" +
            "• Shift + Arrow keys: resize.\n" +
            "• + / - : increase / decrease opacity.\n" +
            "• Right-click: color, opacity, and this menu.\n" +
            "• Esc or Cmd+Q: quit.\n\n" +
            "Your color, size, opacity and position are saved and\n" +
            "restored the next time you open it.\n\n" +
            "Tip: use Semi-transparent to line the bar up over the\n" +
            "subtitles, then switch to Fully opaque to hide them."
        a.runModal()
    }

    // ---- Settings load / save (UserDefaults) ----
    func saveConfig() {
        let d = UserDefaults.standard
        d.set(hexString(window.backgroundColor), forKey: "Color")
        d.set(Double(window.alphaValue), forKey: "Opacity")
        d.set(Double(window.frame.origin.x), forKey: "X")
        d.set(Double(window.frame.origin.y), forKey: "Y")
        d.set(Double(window.frame.size.width), forKey: "W")
        d.set(Double(window.frame.size.height), forKey: "H")
    }

    // ---- Color <-> hex helpers ----
    func hexString(_ color: NSColor) -> String {
        let c = color.usingColorSpace(.sRGB) ?? NSColor.black
        let r = Int((c.redComponent   * 255).rounded())
        let g = Int((c.greenComponent * 255).rounded())
        let b = Int((c.blueComponent  * 255).rounded())
        return String(format: "#%02X%02X%02X", r, g, b)
    }
    func colorFromHex(_ hex: String) -> NSColor {
        var s = hex
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let v = Int(s, radix: 16) else { return .black }
        return NSColor(srgbRed: CGFloat((v >> 16) & 0xFF) / 255.0,
                       green:   CGFloat((v >> 8)  & 0xFF) / 255.0,
                       blue:    CGFloat(v         & 0xFF) / 255.0,
                       alpha: 1)
    }
}

// ---- Entry point ----
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()

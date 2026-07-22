// SubtitleShade - an always-on-top, borderless, adjustable bar to shade movie subtitles.
// Compile with build.bat (uses the C# compiler that ships with .NET Framework).
using System;
using System.Drawing;
using System.Globalization;
using System.IO;
using System.Windows.Forms;

public class ShadeForm : Form {
    // ---- Native constants / P-Invoke for drag + edge-resize -----------------
    private const int WM_NCHITTEST     = 0x84;
    private const int WM_NCLBUTTONDOWN = 0xA1;
    private const int HTCAPTION = 2, HTCLIENT = 1, HTLEFT = 10, HTRIGHT = 11,
                      HTTOP = 12, HTTOPLEFT = 13, HTTOPRIGHT = 14, HTBOTTOM = 15,
                      HTBOTTOMLEFT = 16, HTBOTTOMRIGHT = 17;
    private const int GRIP = 8; // px thickness of the resize border

    [System.Runtime.InteropServices.DllImport("user32.dll")]
    private static extern bool ReleaseCapture();
    [System.Runtime.InteropServices.DllImport("user32.dll")]
    private static extern IntPtr SendMessage(IntPtr hWnd, int Msg, IntPtr wParam, IntPtr lParam);

    private Label hint;

    private string ConfigPath {
        get {
            return Path.Combine(
                Path.GetDirectoryName(Application.ExecutablePath),
                "SubtitleShade.config.txt");
        }
    }

    public ShadeForm() {
        // ---- defaults, then overwrite from saved config --------------------
        Color bg = Color.Black;
        double op = 0.85;
        int w = 900, h = 70;
        int? x = null, y = null;
        LoadConfig(ref bg, ref op, ref w, ref h, ref x, ref y);

        FormBorderStyle = FormBorderStyle.None;   // no title bar
        TopMost         = true;                    // stay above all windows
        BackColor       = bg;
        Opacity         = op;
        ShowInTaskbar   = true;
        MinimumSize     = new Size(80, 20);
        StartPosition   = FormStartPosition.Manual;
        Size            = new Size(w, h);

        Rectangle wa = Screen.PrimaryScreen.WorkingArea;
        if (x.HasValue && y.HasValue)
            Location = new Point(x.Value, y.Value);
        else
            Location = new Point((wa.Width - w) / 2, wa.Height - h - 60);

        // ---- hint label ----------------------------------------------------
        hint = new Label();
        hint.Text      = "drag to move  |  edges to resize  |  right-click for menu  |  Esc to quit";
        hint.BackColor  = Color.Transparent;
        hint.TextAlign  = ContentAlignment.MiddleCenter;
        hint.Location   = new Point(8, 8);
        hint.Size       = new Size(ClientSize.Width - 16, ClientSize.Height - 16);
        hint.Anchor     = AnchorStyles.Top | AnchorStyles.Bottom | AnchorStyles.Left | AnchorStyles.Right;
        hint.MouseDown += OnDragDown;
        Controls.Add(hint);
        UpdateHintColor();                                   // set contrast now...
        BackColorChanged += delegate { UpdateHintColor(); }; // ...and whenever color changes

        MouseDown  += OnDragDown;
        KeyPreview  = true;
        KeyDown    += OnKey;
        Deactivate += delegate { TopMost = true; };
        FormClosing += delegate { SaveConfig(); };

        BuildMenu();
    }

    // ---- Let Windows perform a native window-move drag ---------------------
    private void StartDrag() {
        ReleaseCapture();
        SendMessage(this.Handle, WM_NCLBUTTONDOWN, (IntPtr)HTCAPTION, IntPtr.Zero);
    }

    private void OnDragDown(object sender, MouseEventArgs e) {
        if (e.Button == MouseButtons.Left) StartDrag();
    }

    // Pick light or dark hint text based on the background's perceived brightness.
    private void UpdateHintColor() {
        Color b = BackColor;
        double luminance = 0.299 * b.R + 0.587 * b.G + 0.114 * b.B; // 0..255
        hint.ForeColor = (luminance < 128)
            ? Color.FromArgb(210, 210, 210)   // light text on dark background
            : Color.FromArgb(40, 40, 40);     // dark text on light background
    }

    // ---- Keyboard controls -------------------------------------------------
    private void OnKey(object sender, KeyEventArgs e) {
        const int step = 10;
        switch (e.KeyCode) {
            case Keys.Escape: Close(); break;
            case Keys.Left:  if (e.Shift) Width  = Math.Max(80, Width  - step); else Left -= step; break;
            case Keys.Right: if (e.Shift) Width += step;                        else Left += step; break;
            case Keys.Up:    if (e.Shift) Height = Math.Max(20, Height - step); else Top  -= step; break;
            case Keys.Down:  if (e.Shift) Height += step;                       else Top  += step; break;
            case Keys.Oemplus:
            case Keys.Add:      Opacity = Math.Min(1.0, Opacity + 0.05); break;
            case Keys.OemMinus:
            case Keys.Subtract: Opacity = Math.Max(0.1, Opacity - 0.05); break;
        }
    }

    // ---- Right-click menu --------------------------------------------------
    private void BuildMenu() {
        ContextMenuStrip menu = new ContextMenuStrip();

        ToolStripMenuItem colorMenu = new ToolStripMenuItem("Color");
        AddColor(colorMenu, "Black",     Color.Black);
        AddColor(colorMenu, "Dark gray", Color.DimGray);
        AddColor(colorMenu, "White",     Color.White);
        AddColor(colorMenu, "Blue",      Color.MidnightBlue);
        AddColor(colorMenu, "Green",     Color.DarkGreen);
        colorMenu.DropDownItems.Add(new ToolStripSeparator());
        ToolStripMenuItem custom = new ToolStripMenuItem("Custom...");
        custom.Click += delegate {
            using (ColorDialog dlg = new ColorDialog()) {
                dlg.Color = BackColor; dlg.FullOpen = true; dlg.AnyColor = true;
                if (dlg.ShowDialog() == DialogResult.OK) BackColor = dlg.Color;
            }
        };
        colorMenu.DropDownItems.Add(custom);
        menu.Items.Add(colorMenu);

        ToolStripMenuItem opaque = new ToolStripMenuItem("Fully opaque (block completely)");
        opaque.Click += delegate { Opacity = 1.0; };
        menu.Items.Add(opaque);

        ToolStripMenuItem semi = new ToolStripMenuItem("Semi-transparent (aim mode)");
        semi.Click += delegate { Opacity = 0.6; };
        menu.Items.Add(semi);

        menu.Items.Add(new ToolStripSeparator());

        ToolStripMenuItem help = new ToolStripMenuItem("Help / controls");
        help.Click += delegate {
            MessageBox.Show(
                "SubtitleShade controls\n\n" +
                "- Drag anywhere on the bar to move it.\n" +
                "- Drag the bar's edges/corners to resize (width & height).\n" +
                "- Arrow keys: nudge position.\n" +
                "- Shift + Arrow keys: resize.\n" +
                "- + / - : increase / decrease opacity.\n" +
                "- Right-click: color, opacity, and this menu.\n" +
                "- Esc or 'Close': quit.\n\n" +
                "Your color, size, opacity and position are saved and\n" +
                "restored the next time you open it.\n\n" +
                "Tip: use Semi-transparent to line the bar up over the\n" +
                "subtitles, then switch to Fully opaque to hide them.",
                "SubtitleShade", MessageBoxButtons.OK, MessageBoxIcon.Information);
        };
        menu.Items.Add(help);

        menu.Items.Add(new ToolStripSeparator());

        ToolStripMenuItem close = new ToolStripMenuItem("Close");
        close.Click += delegate { Close(); };
        menu.Items.Add(close);

        this.ContextMenuStrip = menu;
        hint.ContextMenuStrip = menu;
    }

    private void AddColor(ToolStripMenuItem parent, string name, Color c) {
        ToolStripMenuItem item = new ToolStripMenuItem(name);
        item.Click += delegate { BackColor = c; };
        parent.DropDownItems.Add(item);
    }

    // ---- Edge-resize hit testing -------------------------------------------
    protected override void WndProc(ref Message m) {
        if (m.Msg == WM_NCHITTEST) {
            int lp = (int)m.LParam;
            Point p = PointToClient(new Point((short)(lp & 0xFFFF), (short)((lp >> 16) & 0xFFFF)));
            int w = ClientSize.Width, h = ClientSize.Height;
            bool L = p.X <= GRIP, R = p.X >= w - GRIP, T = p.Y <= GRIP, B = p.Y >= h - GRIP;
            if (T && L) { m.Result = (IntPtr)HTTOPLEFT;     return; }
            if (T && R) { m.Result = (IntPtr)HTTOPRIGHT;    return; }
            if (B && L) { m.Result = (IntPtr)HTBOTTOMLEFT;  return; }
            if (B && R) { m.Result = (IntPtr)HTBOTTOMRIGHT; return; }
            if (L)      { m.Result = (IntPtr)HTLEFT;        return; }
            if (R)      { m.Result = (IntPtr)HTRIGHT;       return; }
            if (T)      { m.Result = (IntPtr)HTTOP;         return; }
            if (B)      { m.Result = (IntPtr)HTBOTTOM;      return; }
            m.Result = (IntPtr)HTCLIENT;
            return;
        }
        base.WndProc(ref m);
    }

    // ---- Settings load / save (simple key=value text file) -----------------
    private void LoadConfig(ref Color bg, ref double op, ref int w, ref int h, ref int? x, ref int? y) {
        try {
            if (!File.Exists(ConfigPath)) return;
            foreach (string line in File.ReadAllLines(ConfigPath)) {
                int eq = line.IndexOf('=');
                if (eq <= 0) continue;
                string key = line.Substring(0, eq).Trim();
                string val = line.Substring(eq + 1).Trim();
                switch (key) {
                    case "Color":   try { bg = ColorTranslator.FromHtml(val); } catch { } break;
                    case "Opacity": double.TryParse(val, NumberStyles.Float, CultureInfo.InvariantCulture, out op); break;
                    case "W": int.TryParse(val, out w); break;
                    case "H": int.TryParse(val, out h); break;
                    case "X": { int t; if (int.TryParse(val, out t)) x = t; } break;
                    case "Y": { int t; if (int.TryParse(val, out t)) y = t; } break;
                }
            }
        } catch { }
    }

    private void SaveConfig() {
        try {
            string[] lines = new string[] {
                "Color="   + ColorTranslator.ToHtml(BackColor),
                "Opacity=" + Opacity.ToString(CultureInfo.InvariantCulture),
                "X="       + Location.X.ToString(CultureInfo.InvariantCulture),
                "Y="       + Location.Y.ToString(CultureInfo.InvariantCulture),
                "W="       + Width.ToString(CultureInfo.InvariantCulture),
                "H="       + Height.ToString(CultureInfo.InvariantCulture),
            };
            File.WriteAllLines(ConfigPath, lines);
        } catch { }
    }
}

public class Program {
    [STAThread]
    public static void Main() {
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);
        Application.Run(new ShadeForm());
    }
}

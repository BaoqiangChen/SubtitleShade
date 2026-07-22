# SubtitleShade - an always-on-top, borderless, adjustable bar to shade movie subtitles
# Usage: run SubtitleShade.bat (or right-click this file -> Run with PowerShell)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ---- Custom borderless form with edge-resize support ------------------------
# FormBorderStyle 'None' removes the title bar but also the resize grips, so we
# re-implement resizing by answering WM_NCHITTEST on the window edges/corners.
Add-Type -ReferencedAssemblies System.Windows.Forms, System.Drawing -TypeDefinition @"
using System;
using System.Drawing;
using System.Windows.Forms;

public class ShadeForm : Form {
    private const int WM_NCHITTEST = 0x84;
    private const int WM_NCLBUTTONDOWN = 0xA1;
    private const int HTCAPTION = 2;
    private const int HTCLIENT = 1,  HTLEFT = 10, HTRIGHT = 11, HTTOP = 12,
                      HTTOPLEFT = 13, HTTOPRIGHT = 14, HTBOTTOM = 15,
                      HTBOTTOMLEFT = 16, HTBOTTOMRIGHT = 17;
    private const int GRIP = 8; // px thickness of the resize border

    [System.Runtime.InteropServices.DllImport("user32.dll")]
    private static extern bool ReleaseCapture();
    [System.Runtime.InteropServices.DllImport("user32.dll")]
    private static extern IntPtr SendMessage(IntPtr hWnd, int Msg, IntPtr wParam, IntPtr lParam);

    // Let Windows perform a native window-move drag (rock solid, no offset math).
    // Works even when the click started on a child control (e.g. the hint label).
    public void StartDrag() {
        ReleaseCapture();
        SendMessage(this.Handle, WM_NCLBUTTONDOWN, (IntPtr)HTCAPTION, IntPtr.Zero);
    }

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
            m.Result = (IntPtr)HTCLIENT; // interior: normal mouse events (drag/menu)
            return;
        }
        base.WndProc(ref m);
    }
}
"@

# ---- Settings load / save ---------------------------------------------------
$configPath = Join-Path $PSScriptRoot 'SubtitleShade.config.json'
$cfg = [ordered]@{ Color = 'Black'; Opacity = 0.85; X = $null; Y = $null; W = 900; H = 70 }
if (Test-Path $configPath) {
    try {
        $loaded = Get-Content -Raw $configPath | ConvertFrom-Json
        foreach ($k in @('Color','Opacity','X','Y','W','H')) {
            if ($null -ne $loaded.$k) { $cfg[$k] = $loaded.$k }
        }
    } catch { }
}

# ---- Main bar form ----------------------------------------------------------
$form = New-Object ShadeForm
$form.FormBorderStyle = 'None'             # no title bar
$form.TopMost         = $true              # 置于所有窗口的顶层
$form.BackColor       = [System.Drawing.ColorTranslator]::FromHtml($cfg.Color)
$form.Opacity         = [double]$cfg.Opacity
$form.ShowInTaskbar   = $true
$form.MinimumSize     = New-Object System.Drawing.Size(80, 20)
$form.StartPosition   = 'Manual'
$form.Size            = New-Object System.Drawing.Size([int]$cfg.W, [int]$cfg.H)

$screen = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
if ($null -ne $cfg.X -and $null -ne $cfg.Y) {
    $form.Location = New-Object System.Drawing.Point([int]$cfg.X, [int]$cfg.Y)
} else {
    $form.Location = New-Object System.Drawing.Point(
        [int](($screen.Width - $form.Width) / 2),
        [int]($screen.Height - $form.Height - 60))
}

# ---- Drag-to-move (grab anywhere on the interior) ---------------------------
# Hand the drag to Windows on left-button press; it moves the window natively.
$startDrag = {
    param($s, $e)
    if ($e.Button -eq 'Left') { $form.StartDrag() }
}
$form.Add_MouseDown($startDrag)

# ---- Keyboard controls ------------------------------------------------------
$form.KeyPreview = $true
$form.Add_KeyDown({
    param($s, $e)
    $step = 10
    switch ($e.KeyCode) {
        'Escape' { $form.Close() }
        'Left'   { if ($e.Shift) { $form.Width  = [Math]::Max(80, $form.Width  - $step) } else { $form.Left -= $step } }
        'Right'  { if ($e.Shift) { $form.Width  += $step } else { $form.Left += $step } }
        'Up'     { if ($e.Shift) { $form.Height = [Math]::Max(20, $form.Height - $step) } else { $form.Top  -= $step } }
        'Down'   { if ($e.Shift) { $form.Height += $step } else { $form.Top  += $step } }
        'Oemplus'  { $form.Opacity = [Math]::Min(1.0, $form.Opacity + 0.05) }
        'Add'      { $form.Opacity = [Math]::Min(1.0, $form.Opacity + 0.05) }
        'OemMinus' { $form.Opacity = [Math]::Max(0.1, $form.Opacity - 0.05) }
        'Subtract' { $form.Opacity = [Math]::Max(0.1, $form.Opacity - 0.05) }
    }
})

# ---- Right-click menu -------------------------------------------------------
$menu = New-Object System.Windows.Forms.ContextMenuStrip

# --- Color submenu (presets + custom picker) ---
$colorMenu = New-Object System.Windows.Forms.ToolStripMenuItem 'Color'
$presets = [ordered]@{
    'Black'       = 'Black'
    'Dark gray'   = 'DimGray'
    'White'       = 'White'
    'Blue'        = 'MidnightBlue'
    'Green'       = 'DarkGreen'
}
foreach ($name in $presets.Keys) {
    $item = New-Object System.Windows.Forms.ToolStripMenuItem $name
    $clr  = [System.Drawing.Color]::FromName($presets[$name])
    $item.Tag = $clr
    $item.Add_Click({ param($s,$e) $form.BackColor = $s.Tag })
    [void]$colorMenu.DropDownItems.Add($item)
}
[void]$colorMenu.DropDownItems.Add((New-Object System.Windows.Forms.ToolStripSeparator))
$customColor = New-Object System.Windows.Forms.ToolStripMenuItem 'Custom...'
$customColor.Add_Click({
    $dlg = New-Object System.Windows.Forms.ColorDialog
    $dlg.Color         = $form.BackColor
    $dlg.FullOpen      = $true
    $dlg.AnyColor      = $true
    if ($dlg.ShowDialog() -eq 'OK') { $form.BackColor = $dlg.Color }
})
[void]$colorMenu.DropDownItems.Add($customColor)
[void]$menu.Items.Add($colorMenu)

# --- Opacity presets ---
$mOpaque = $menu.Items.Add('Fully opaque (block completely)')
$mOpaque.Add_Click({ $form.Opacity = 1.0 })
$mSemi = $menu.Items.Add('Semi-transparent (aim mode)')
$mSemi.Add_Click({ $form.Opacity = 0.6 })

[void]$menu.Items.Add('-')

$mHelp = $menu.Items.Add('Help / controls')
$mHelp.Add_Click({
    [System.Windows.Forms.MessageBox]::Show(
@"
SubtitleShade controls

- Drag anywhere on the bar to move it.
- Drag the bar's edges/corners to resize (width & height).
- Arrow keys: nudge position.
- Shift + Arrow keys: resize.
- + / - : increase / decrease opacity.
- Right-click: color, opacity, and this menu.
- Esc or 'Close': quit.

Your color, size, opacity and position are saved and
restored the next time you open it.

Tip: use Semi-transparent to line the bar up over the
subtitles, then switch to Fully opaque to hide them.
"@, 'SubtitleShade', 'OK', 'Information') | Out-Null
})

[void]$menu.Items.Add('-')

$mClose = $menu.Items.Add('Close')
$mClose.Add_Click({ $form.Close() })

$form.ContextMenuStrip = $menu

# ---- Faint hint label -------------------------------------------------------
$hint = New-Object System.Windows.Forms.Label
$hint.Text      = 'drag to move  |  edges to resize  |  right-click for menu  |  Esc to quit'
$hint.BackColor = [System.Drawing.Color]::Transparent

# Pick light or dark hint text based on the background's perceived brightness.
$updateHintColor = {
    $b = $form.BackColor
    $luminance = 0.299 * $b.R + 0.587 * $b.G + 0.114 * $b.B
    if ($luminance -lt 128) {
        $hint.ForeColor = [System.Drawing.Color]::FromArgb(210, 210, 210)
    } else {
        $hint.ForeColor = [System.Drawing.Color]::FromArgb(40, 40, 40)
    }
}
$hint.AutoSize  = $false
# Leave the resize border uncovered so edge-drags still hit the form:
$hint.Dock      = 'None'
$hint.Location  = New-Object System.Drawing.Point(8, 8)
$hint.Anchor    = 'Top,Bottom,Left,Right'
$hint.TextAlign = 'MiddleCenter'
$syncHint = { $hint.Size = New-Object System.Drawing.Size(($form.ClientSize.Width - 16), ($form.ClientSize.Height - 16)) }
& $syncHint
$form.Add_Resize($syncHint)
# Pass label drags/right-clicks through to the form:
$hint.Add_MouseDown($startDrag)
$hint.ContextMenuStrip = $menu
$form.Controls.Add($hint)

& $updateHintColor                              # set contrast now...
$form.Add_BackColorChanged($updateHintColor)    # ...and whenever color changes

# Keep it on top even if other apps steal foreground
$form.Add_Deactivate({ $form.TopMost = $true })

# ---- Save settings on close -------------------------------------------------
$form.Add_FormClosing({
    try {
        $out = [ordered]@{
            Color   = [System.Drawing.ColorTranslator]::ToHtml($form.BackColor)
            Opacity = $form.Opacity
            X       = $form.Location.X
            Y       = $form.Location.Y
            W       = $form.Width
            H       = $form.Height
        }
        $out | ConvertTo-Json | Set-Content -Path $configPath -Encoding UTF8
    } catch { }
})

[void]$form.ShowDialog()

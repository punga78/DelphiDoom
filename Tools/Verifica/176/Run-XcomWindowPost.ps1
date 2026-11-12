<#
  Guida la finestra vera di Xcom32 senza mouse vero e senza tasti veri (issue #183): il mouse e i tasti sono messaggi
  WM_MOUSEMOVE / WM_LBUTTONDOWN / WM_LBUTTONUP / WM_KEYDOWN / WM_KEYUP inviati con PostMessage alla finestra del
  processo, le schermate sono PrintWindow, la misura si cambia con SetWindowPos. Un solo giro alla volta sulla
  macchina (il lock globale dei giochi).

  Uso: Run-XcomWindowPost.ps1 -Exe <Xcom32.exe> -Arguments '<argomenti>' -Out <cartella> -Steps 'wait:5','shot:a'
  Passi (separati da virgola o in un array): wait:<secondi>  move:x,y  click:x,y  rclick:x,y  key:<vk>
    map:<x>,<y>,<larghezza> (dove sta l'immagine nel client: schermo intero)  shot:<nome>  size:<larghezza>,<altezza> (misura del client)  rect  close
  Le coordinate sono quelle di una finestra 640x400 e si portano alla larghezza attuale del client.
  Stampa per ogni schermata la misura e al termine "vivo=<si'|no>" e la misura del client.
#>
param(
  [Parameter(Mandatory = $true)][string]$Exe,
  [string]$Arguments = '',
  [Parameter(Mandatory = $true)][string]$Out,
  [string[]]$Steps = @('wait:3', 'shot:screen', 'close'),
  [int]$TimeoutSeconds = 300
)
$ErrorActionPreference = 'Stop'
$Steps = @($Steps | ForEach-Object { $_ } | Where-Object { $_ -ne '' })
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System; using System.Text; using System.Runtime.InteropServices; using System.Drawing; using System.Drawing.Imaging;
public static class XcomWin {
  delegate bool EnumProc(IntPtr h, IntPtr l);
  [DllImport("user32.dll")] static extern bool EnumWindows(EnumProc p, IntPtr l);
  [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
  [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr h);
  [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
  [DllImport("user32.dll")] static extern bool PrintWindow(IntPtr h, IntPtr dc, uint flags);
  [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] static extern bool SetWindowPos(IntPtr h, IntPtr after, int x, int y, int cx, int cy, uint flags);
  [DllImport("user32.dll")] static extern uint MapVirtualKey(uint code, uint type);
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L, T, R, B; }
  public static IntPtr Find(uint pid) {
    IntPtr found = IntPtr.Zero;
    EnumWindows((h, l) => {
      uint p; GetWindowThreadProcessId(h, out p);
      if (p == pid && IsWindowVisible(h)) { found = h; return false; }
      return true;
    }, IntPtr.Zero);
    return found;
  }
  static IntPtr Pack(int x, int y) { return (IntPtr)((y << 16) | (x & 0xFFFF)); }
  public static void Move(IntPtr h, int x, int y) { PostMessage(h, 0x0200, IntPtr.Zero, Pack(x, y)); }
  public static void Down(IntPtr h, int x, int y, bool right) { PostMessage(h, right ? 0x0204u : 0x0201u, (IntPtr)(right ? 2 : 1), Pack(x, y)); }
  public static void Up(IntPtr h, int x, int y, bool right) { PostMessage(h, right ? 0x0205u : 0x0202u, IntPtr.Zero, Pack(x, y)); }
  public static void Key(IntPtr h, int vk, bool down) {
    uint sc = MapVirtualKey((uint)vk, 0);
    PostMessage(h, down ? 0x0100u : 0x0101u, (IntPtr)vk, (IntPtr)(down ? (1 | (sc << 16)) : (1 | (sc << 16) | unchecked((int)0xC0000000))));
  }
  public static void Client(IntPtr h, out int w, out int hh) { RECT r; GetClientRect(h, out r); w = r.R; hh = r.B; }
  public static string Rects(IntPtr h) { RECT c, w; GetClientRect(h, out c); GetWindowRect(h, out w); return "client " + c.R + "x" + c.B + " window " + (w.R - w.L) + "x" + (w.B - w.T) + " at " + w.L + "," + w.T; }
  public static void Resize(IntPtr h, int cw, int ch) {
    RECT c, w; GetClientRect(h, out c); GetWindowRect(h, out w);
    int dx = (w.R - w.L) - c.R, dy = (w.B - w.T) - c.B;
    // SWP_NOMOVE | SWP_NOZORDER | SWP_NOACTIVATE
    SetWindowPos(h, IntPtr.Zero, 0, 0, cw + dx, ch + dy, 0x0002 | 0x0004 | 0x0010);
  }
  public static void Shot(IntPtr h, string path) {
    RECT r; GetClientRect(h, out r); RECT w; GetWindowRect(h, out w);
    // the client area is the part of the window that starts after the border: its origin comes from the window rect
    var pt = new POINT(); ClientToScreen(h, ref pt);
    using (Bitmap full = new Bitmap(w.R - w.L, w.B - w.T)) {
      using (Graphics g = Graphics.FromImage(full)) { IntPtr dc = g.GetHdc(); PrintWindow(h, dc, 2); g.ReleaseHdc(dc); }
      using (Bitmap b = full.Clone(new Rectangle(pt.X - w.L, pt.Y - w.T, r.R, r.B), full.PixelFormat)) b.Save(path, ImageFormat.Png);
    }
  }
  [StructLayout(LayoutKind.Sequential)] public struct POINT { public int X, Y; }
  [DllImport("user32.dll")] static extern bool ClientToScreen(IntPtr h, ref POINT p);
}
'@
New-Item -ItemType Directory -Force $Out | Out-Null
$mutex = New-Object System.Threading.Mutex($false, 'Global\DelphiDoomEsecuzioneGioco')
$got = $false
try {
  try { $got = $mutex.WaitOne([TimeSpan]::FromSeconds(900)) } catch [System.Threading.AbandonedMutexException] { $got = $true }
  if (-not $got) { Write-Output 'LOCK-NON-OTTENUTO'; exit 2 }
  $p = Start-Process $Exe -ArgumentList $Arguments -WorkingDirectory (Split-Path -Parent $Exe) -PassThru
  try {
    $h = [IntPtr]::Zero
    for ($i = 0; $i -lt 100 -and $h -eq [IntPtr]::Zero; $i++) { Start-Sleep -Milliseconds 200; $h = [XcomWin]::Find([uint32]$p.Id) }
    if ($h -eq [IntPtr]::Zero) { Write-Output 'NESSUNA-FINESTRA'; return }
    # the picture of the game inside the client (a full screen window has black bands): map:<x>,<y>,<width> sets it
    $script:OriginX = 0; $script:OriginY = 0; $script:PictureWidth = 0
    function ScaleX([int]$v) { $w = 0; $hh = 0; [XcomWin]::Client($h, [ref]$w, [ref]$hh); if ($script:PictureWidth -gt 0) { $w = $script:PictureWidth }; [int]($script:OriginX + $v * $w / 640) }
    function ScaleY([int]$v) { $w = 0; $hh = 0; [XcomWin]::Client($h, [ref]$w, [ref]$hh); if ($script:PictureWidth -gt 0) { $w = $script:PictureWidth }; [int]($script:OriginY + $v * $w / 640) }
    foreach ($s in $Steps) {
      $a = $s.Split(':', 2)
      switch ($a[0]) {
        'wait' { Start-Sleep -Milliseconds ([int]([double]::Parse($a[1], [Globalization.CultureInfo]::InvariantCulture) * 1000)) }
        'move' { $xy = $a[1].Split(','); [XcomWin]::Move($h, (ScaleX ([int]$xy[0])), (ScaleY ([int]$xy[1]))) }
        'click' {
          $xy = $a[1].Split(','); $x = ScaleX ([int]$xy[0]); $y = ScaleY ([int]$xy[1])
          [XcomWin]::Move($h, $x, $y); Start-Sleep -Milliseconds 120
          [XcomWin]::Down($h, $x, $y, $false); Start-Sleep -Milliseconds 100; [XcomWin]::Up($h, $x, $y, $false)
        }
        'rclick' {
          $xy = $a[1].Split(','); $x = ScaleX ([int]$xy[0]); $y = ScaleY ([int]$xy[1])
          [XcomWin]::Move($h, $x, $y); Start-Sleep -Milliseconds 120
          [XcomWin]::Down($h, $x, $y, $true); Start-Sleep -Milliseconds 100; [XcomWin]::Up($h, $x, $y, $true)
        }
        'key' { [XcomWin]::Key($h, [int]$a[1], $true); Start-Sleep -Milliseconds 80; [XcomWin]::Key($h, [int]$a[1], $false) }
        'size' { $wh = $a[1].Split(','); [XcomWin]::Resize($h, [int]$wh[0], [int]$wh[1]) }
        'map' { $m = $a[1].Split(','); $script:OriginX = [int]$m[0]; $script:OriginY = [int]$m[1]; $script:PictureWidth = [int]$m[2] }
        'rect' { Write-Output ([XcomWin]::Rects($h)) }
        'shot' { $f = Join-Path $Out ($a[1] + '.png'); [XcomWin]::Shot($h, $f); Write-Output "$f $([XcomWin]::Rects($h))" }
        'close' { [XcomWin]::PostMessage($h, 0x0010, [IntPtr]::Zero, [IntPtr]::Zero) | Out-Null; $p.WaitForExit(10000) | Out-Null }
      }
    }
    $p.Refresh(); Write-Output "vivo=$(-not $p.HasExited)"
  } finally { if (-not $p.HasExited) { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue } }
} finally { if ($got) { $mutex.ReleaseMutex() } }

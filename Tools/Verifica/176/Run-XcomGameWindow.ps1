<#
  Avvia Xcom32 con la finestra vera (GDI), esegue dei passi (attese, clic, tasti) e salva schermate della finestra con
  PrintWindow (il contenuto della finestra, anche se un'altra le sta sopra). Prende il lock globale dei giochi.
  Uso: Run-XcomGameWindow.ps1 -Exe <Xcom32.exe> -Args '<argomenti>' -Out <cartella> -Steps 'wait:6','shot:a','click:420,312'
  Passi: wait:s, click:x,y (client), move:x,y, key:vk, shot:nome. Stampa se il processo e' ancora vivo alla fine.
#>
param(
  [Parameter(Mandatory = $true)][string]$Exe,
  [Parameter(Mandatory = $true)][string]$Args,
  [Parameter(Mandatory = $true)][string]$Out,
  [string[]]$Steps = @()
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @"
using System; using System.Runtime.InteropServices; using System.Drawing; using System.Drawing.Imaging;
public class XgWin {
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr h, ref POINT p);
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
  [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint x, uint y, uint d, UIntPtr e);
  [DllImport("user32.dll")] public static extern void keybd_event(byte vk, byte sc, uint fl, UIntPtr ex);
  [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h, IntPtr dc, uint flags);
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L, T, R, B; }
  [StructLayout(LayoutKind.Sequential)] public struct POINT { public int X, Y; }
  public static void Move(IntPtr h, int x, int y) { POINT p = new POINT(); p.X = x; p.Y = y; ClientToScreen(h, ref p); SetCursorPos(p.X, p.Y); }
  public static void Click(IntPtr h, int x, int y) {
    Move(h, x, y); System.Threading.Thread.Sleep(200);
    mouse_event(2, 0, 0, 0, UIntPtr.Zero); System.Threading.Thread.Sleep(100); mouse_event(4, 0, 0, 0, UIntPtr.Zero);
  }
  public static void Key(byte vk) { keybd_event(vk, 0, 0, UIntPtr.Zero); System.Threading.Thread.Sleep(60); keybd_event(vk, 0, 2, UIntPtr.Zero); }
  public static void Shot(IntPtr h, string path) {
    RECT r; GetClientRect(h, out r);
    // the whole window is printed, then the client area is cut out
    RECT w; GetWindowRect(h, out w);
    POINT c = new POINT(); ClientToScreen(h, ref c);
    using (Bitmap full = new Bitmap(w.R - w.L, w.B - w.T)) {
      using (Graphics g = Graphics.FromImage(full)) { IntPtr dc = g.GetHdc(); PrintWindow(h, dc, 2); g.ReleaseHdc(dc); }
      using (Bitmap b = full.Clone(new Rectangle(c.X - w.L, c.Y - w.T, r.R, r.B), full.PixelFormat)) b.Save(path, ImageFormat.Png);
    }
  }
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
}
"@
New-Item -ItemType Directory -Force $Out | Out-Null
$m = New-Object System.Threading.Mutex($false, 'Global\DelphiDoomEsecuzioneGioco')
$ok = $false
try {
  try { $ok = $m.WaitOne([TimeSpan]::FromSeconds(900)) } catch [System.Threading.AbandonedMutexException] { $ok = $true }
  if (-not $ok) { Write-Output 'LOCK-NON-OTTENUTO'; exit 2 }
  $p = Start-Process $Exe -ArgumentList $Args -WorkingDirectory (Split-Path -Parent $Exe) -PassThru
  try {
    Start-Sleep 3
    $p.Refresh(); $h = $p.MainWindowHandle
    [XgWin]::SetForegroundWindow($h) | Out-Null; Start-Sleep 1
    foreach ($s in $Steps) {
      $a = $s.Split(':')
      switch ($a[0]) {
        'wait' { Start-Sleep ([double]$a[1]) }
        'click' { $xy = $a[1].Split(','); [XgWin]::Click($h, [int]$xy[0], [int]$xy[1]) }
        'move' { $xy = $a[1].Split(','); [XgWin]::Move($h, [int]$xy[0], [int]$xy[1]) }
        'key' { [XgWin]::Key([byte][int]$a[1]) }
        'shot' { $f = Join-Path $Out ($a[1] + '.png'); [XgWin]::Shot($h, $f); Write-Output $f }
      }
    }
    $p.Refresh(); Write-Output "vivo=$(-not $p.HasExited)"
  } finally { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue }
} finally { if ($ok) { $m.ReleaseMutex() } }

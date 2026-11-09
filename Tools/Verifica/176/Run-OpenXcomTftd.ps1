<#
  Avvia OpenXcom (nightly ufficiale, mod standard xcom2 = TFTD) con i dati di TFTD estratti da Make-TftdLayout.ps1
  e salva schermate della finestra (menu, nuova partita, geoscape, basescape).
  Uso: powershell -NoProfile -File Run-OpenXcomTftd.ps1 -Root <cartella con openxcom\ e openxcom_user\> -Out <cartella>
  La finestra e' 640x400 senza OpenGL; i clic sono in coordinate dell'area client (il gioco scala x2 se serve).
#>
param(
  [Parameter(Mandatory = $true)][string]$Root,
  [Parameter(Mandatory = $true)][string]$Out,
  [string[]]$Steps = @()
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @"
using System; using System.Runtime.InteropServices; using System.Drawing; using System.Drawing.Imaging;
public class OxcWin {
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr h, ref POINT p);
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
  [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint x, uint y, uint d, UIntPtr e);
  [DllImport("user32.dll")] public static extern void keybd_event(byte vk, byte sc, uint fl, UIntPtr ex);
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L, T, R, B; }
  [StructLayout(LayoutKind.Sequential)] public struct POINT { public int X, Y; }
  public static void Click(IntPtr h, int x, int y) {
    POINT p = new POINT(); p.X = x; p.Y = y; ClientToScreen(h, ref p);
    SetCursorPos(p.X, p.Y); System.Threading.Thread.Sleep(150);
    mouse_event(2, 0, 0, 0, UIntPtr.Zero); System.Threading.Thread.Sleep(80); mouse_event(4, 0, 0, 0, UIntPtr.Zero);
  }
  public static void Key(byte vk) { keybd_event(vk, 0, 0, UIntPtr.Zero); System.Threading.Thread.Sleep(60); keybd_event(vk, 0, 2, UIntPtr.Zero); }
  public static void Shot(IntPtr h, string path) {
    RECT r; GetClientRect(h, out r); POINT p = new POINT(); ClientToScreen(h, ref p);
    using (Bitmap b = new Bitmap(r.R, r.B)) { using (Graphics g = Graphics.FromImage(b)) g.CopyFromScreen(p.X, p.Y, 0, 0, b.Size); b.Save(path, ImageFormat.Png); }
  }
}
"@
New-Item -ItemType Directory -Force $Out | Out-Null
$exe = Join-Path $Root 'openxcom\OpenXcom.exe'
$p = Start-Process $exe -ArgumentList "-data `"$(Join-Path $Root 'openxcom')`" -user `"$(Join-Path $Root 'openxcom_user')`"" -WorkingDirectory (Join-Path $Root 'openxcom') -PassThru
try {
  Start-Sleep 8
  $p.Refresh(); $h = $p.MainWindowHandle
  [OxcWin]::SetForegroundWindow($h) | Out-Null; Start-Sleep 1
  foreach ($s in $Steps) {
    $a = $s.Split(':')
    switch ($a[0]) {
      'wait' { Start-Sleep ([double]$a[1]) }
      'click' { $xy = $a[1].Split(','); [OxcWin]::Click($h, [int]$xy[0], [int]$xy[1]) }
      'key' { [OxcWin]::Key([byte][int]$a[1]) }
      'shot' { [OxcWin]::Shot($h, (Join-Path $Out ($a[1] + '.png'))); Write-Output (Join-Path $Out ($a[1] + '.png')) }
    }
  }
} finally { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue }


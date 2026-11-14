<#
  Runs Radix32 (or another game of the engine of Doom) and looks at its window without the mouse and without
  real key presses (issue #169): the pictures are taken with PrintWindow, the keys are WM_KEYDOWN/WM_KEYUP posted
  to the window, the game is closed with WM_CLOSE so that it writes its logs. One run at a time on the machine
  (the lock of Tools\Esegui-gioco.ps1).

    powershell -NoProfile -File Tools\Verifica\169\Prova-Radix.ps1 -Exe bin\Win32\Release\Radix\Radix32.exe `
      -Arguments '-devparm -nomusic -nosound -warp 1 1' -Out C:\ddpar169\e1m1 `
      -Steps 'wait:15000','shot:level','close'

  Steps: wait:<ms>  key:<virtual key>[:<ms held>]  down:<vk>  up:<vk>  shot:<name>  windows  close
  "windows" lists the windows of the process (class, title, size): an error box shows up there.
  Prints a line for each picture (size, FNV-1a of the pixels, number of colours), then the exit code.
#>
param(
  [Parameter(Mandatory = $true)][string]$Exe,
  [string]$Arguments = '',
  [Parameter(Mandatory = $true)][string]$Out,
  [string[]]$Steps = @('wait:15000', 'shot:screen', 'close'),
  # a second run under the same lock (the wait for the lock can be long): its arguments and its steps
  [string]$Arguments2 = '',
  [string[]]$Steps2 = @('wait:15000', 'shot:screen2', 'close'),
  [int]$TimeoutSeconds = 30
)
$ErrorActionPreference = 'Stop'
# with -File the steps come as one string with commas
$Steps = @($Steps | ForEach-Object { $_.Split(',') } | Where-Object { $_ -ne '' })
$Steps2 = @($Steps2 | ForEach-Object { $_.Split(',') } | Where-Object { $_ -ne '' })
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System; using System.Text; using System.Collections.Generic; using System.Runtime.InteropServices;
using System.Drawing; using System.Drawing.Imaging;
public static class RadixWindow {
  delegate bool EnumProc(IntPtr h, IntPtr l);
  [DllImport("user32.dll")] static extern bool EnumWindows(EnumProc p, IntPtr l);
  [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
  [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern int GetClassName(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr h);
  [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
  [DllImport("user32.dll")] static extern bool PrintWindow(IntPtr h, IntPtr dc, uint flags);
  [DllImport("user32.dll")] static extern bool GetClientRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] static extern uint MapVirtualKey(uint code, uint type);
  [StructLayout(LayoutKind.Sequential)] struct RECT { public int L, T, R, B; }
  public static List<string> List(uint pid) {
    var result = new List<string>();
    EnumWindows((h, l) => {
      uint p; GetWindowThreadProcessId(h, out p);
      if (p == pid && IsWindowVisible(h)) {
        var c = new StringBuilder(128); GetClassName(h, c, 128);
        var t = new StringBuilder(256); GetWindowText(h, t, 256);
        RECT r; GetClientRect(h, out r);
        result.Add(c + " | " + t + " | " + (r.R - r.L) + "x" + (r.B - r.T)); }
      return true; }, IntPtr.Zero);
    return result;
  }
  // the visible window of the process with the largest client area
  public static IntPtr Find(uint pid) {
    IntPtr found = IntPtr.Zero; int best = 0;
    EnumWindows((h, l) => {
      uint p; GetWindowThreadProcessId(h, out p);
      if (p == pid && IsWindowVisible(h)) {
        RECT r; GetClientRect(h, out r);
        int area = (r.R - r.L) * (r.B - r.T);
        if (area > best) { best = area; found = h; } }
      return true; }, IntPtr.Zero);
    return found;
  }
  public static void Key(IntPtr h, int vk, bool down) {
    uint scan = MapVirtualKey((uint)vk, 0);
    long l = 1 | ((long)scan << 16);
    if (!down) l |= (1L << 30) | (1L << 31);
    PostMessage(h, down ? 0x100u : 0x101u, (IntPtr)vk, (IntPtr)l);
  }
  public static void Close(IntPtr h) { PostMessage(h, 0x10, IntPtr.Zero, IntPtr.Zero); }
  public static string Shot(IntPtr h, string path) {
    RECT r; GetClientRect(h, out r);
    int w = r.R - r.L, hh = r.B - r.T;
    if (w <= 0 || hh <= 0) return "no client area";
    using (var b = new Bitmap(w, hh, PixelFormat.Format32bppArgb)) {
      using (var g = Graphics.FromImage(b)) { IntPtr dc = g.GetHdc(); PrintWindow(h, dc, 3); g.ReleaseHdc(dc); }
      b.Save(path, ImageFormat.Png);
      var d = b.LockBits(new Rectangle(0, 0, w, hh), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
      byte[] px = new byte[d.Stride * hh]; Marshal.Copy(d.Scan0, px, 0, px.Length); b.UnlockBits(d);
      uint f = 2166136261; var seen = new HashSet<int>();
      for (int i = 0; i < px.Length; i += 4) { f = (f ^ px[i]) * 16777619; f = (f ^ px[i + 1]) * 16777619; f = (f ^ px[i + 2]) * 16777619;
        seen.Add(px[i] | (px[i + 1] << 8) | (px[i + 2] << 16)); }
      return w + "x" + hh + " fnv " + f.ToString("X8") + " colors " + seen.Count;
    }
  }
}
'@
if (-not (Test-Path $Out)) { New-Item -ItemType Directory $Out | Out-Null }
$exePath = (Resolve-Path -LiteralPath $Exe).Path
$mutex = New-Object System.Threading.Mutex($false, 'Global\DelphiDoomEsecuzioneGioco')
$waited = [Diagnostics.Stopwatch]::StartNew()
try { $got = $mutex.WaitOne([TimeSpan]::FromSeconds(3600)) } catch [System.Threading.AbandonedMutexException] { $got = $true }
if (-not $got) { throw 'the lock of the games was not taken' }
"lock waited $([int]$waited.Elapsed.TotalSeconds) s"
function Invoke-RadixRun([string]$Arguments, [string[]]$Steps) {
  "run: $Arguments"
  $crash = Join-Path (Split-Path -Parent $exePath) 'crash.txt'
  Remove-Item -LiteralPath $crash -ErrorAction SilentlyContinue
  $p = Start-Process -FilePath $exePath -ArgumentList $Arguments -WorkingDirectory (Split-Path -Parent $exePath) -PassThru
  $null = $p.Handle
  try { $p.PriorityClass = 'BelowNormal' } catch { }
  foreach ($step in $Steps) {
    if ($p.HasExited) { "the program ended before the step $step"; break }
    $parts = $step.Split(':')
    $h = [RadixWindow]::Find([uint32]$p.Id)
    switch ($parts[0]) {
      'wait' { Start-Sleep -Milliseconds ([int]$parts[1]) }
      'key' {
        $held = 120; if ($parts.Count -gt 2) { $held = [int]$parts[2] }
        [RadixWindow]::Key($h, [int]$parts[1], $true); Start-Sleep -Milliseconds $held; [RadixWindow]::Key($h, [int]$parts[1], $false)
        Start-Sleep -Milliseconds 80
      }
      'down' { [RadixWindow]::Key($h, [int]$parts[1], $true) }
      'up' { [RadixWindow]::Key($h, [int]$parts[1], $false) }
      'shot' {
        if ($h -eq [IntPtr]::Zero) { "shot $($parts[1]): NO WINDOW" }
        else { "shot $($parts[1]): " + [RadixWindow]::Shot($h, (Join-Path $Out ($parts[1] + '.png'))) }
      }
      'windows' { [RadixWindow]::List([uint32]$p.Id) | ForEach-Object { "window: $_" } }
      'close' { if ($h -ne [IntPtr]::Zero) { [RadixWindow]::Close($h) } }
      default { throw "unknown step $step" }
    }
  }
  if (-not $p.WaitForExit($TimeoutSeconds * 1000)) { 'STILL RUNNING: killed'; Stop-Process -Id $p.Id -Force }
  $p.WaitForExit()
  "exit code: $($p.ExitCode)  crash.txt: $(Test-Path -LiteralPath $crash)"
}
try {
  Invoke-RadixRun $Arguments $Steps
  if ($Arguments2 -ne '') { Invoke-RadixRun $Arguments2 $Steps2 }
} finally { $mutex.ReleaseMutex() }

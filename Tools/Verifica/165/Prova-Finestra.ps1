<#
  Drives the window of Keen32 without the mouse and without real key presses (issue #165): the keys are WM_KEYDOWN
  and WM_KEYUP posted to the window of the process, the pictures are taken with PrintWindow. One run at a time on
  the machine (the lock of Tools\Esegui-gioco.ps1).

    powershell -NoProfile -File Tools\Verifica\165\Prova-Finestra.ps1 -Exe bin\Win32\Release\Keen\Keen32.exe `
      -Arguments '-data <folder> -save <folder> -nodevice -report' -Out <folder> `
      -Steps 'wait:1500','shot:title','key:32','wait:800','shot:panel','close'

  Steps: wait:<ms>  key:<virtual key>[:<ms held>]  down:<vk>  up:<vk>  shot:<name>  close
  Prints a line for each picture (its size and an FNV-1a of its pixels), then the exit code and the output of
  the program.
#>
param(
  [Parameter(Mandatory = $true)][string]$Exe,
  [string]$Arguments = '',
  [Parameter(Mandatory = $true)][string]$Out,
  [string[]]$Steps = @('wait:2000', 'shot:screen', 'close'),
  [int]$TimeoutSeconds = 120
)
$ErrorActionPreference = 'Stop'
# with -File the steps come as one string with commas
$Steps = @($Steps | ForEach-Object { $_.Split(',') } | Where-Object { $_ -ne '' })
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System; using System.Text; using System.Runtime.InteropServices; using System.Drawing; using System.Drawing.Imaging;
public static class KeenWindow {
  delegate bool EnumProc(IntPtr h, IntPtr l);
  [DllImport("user32.dll")] static extern bool EnumWindows(EnumProc p, IntPtr l);
  [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
  [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern int GetClassName(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
  [DllImport("user32.dll")] static extern bool PrintWindow(IntPtr h, IntPtr dc, uint flags);
  [DllImport("user32.dll")] static extern bool GetClientRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] static extern uint MapVirtualKey(uint code, uint type);
  [StructLayout(LayoutKind.Sequential)] struct RECT { public int L, T, R, B; }
  public static IntPtr Find(uint pid) {
    IntPtr found = IntPtr.Zero;
    EnumWindows((h, l) => {
      uint p; GetWindowThreadProcessId(h, out p);
      if (p == pid) { var s = new StringBuilder(128); GetClassName(h, s, 128);
        if (s.ToString() == "DelphiDoomGameHostWindow") { found = h; return false; } }
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
      using (var g = Graphics.FromImage(b)) { IntPtr dc = g.GetHdc(); PrintWindow(h, dc, 1); g.ReleaseHdc(dc); }
      b.Save(path, ImageFormat.Png);
      var d = b.LockBits(new Rectangle(0, 0, w, hh), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
      byte[] px = new byte[d.Stride * hh]; Marshal.Copy(d.Scan0, px, 0, px.Length); b.UnlockBits(d);
      uint f = 2166136261; int colors = 0; var seen = new System.Collections.Generic.HashSet<int>();
      for (int i = 0; i < px.Length; i += 4) { f = (f ^ px[i]) * 16777619; f = (f ^ px[i + 1]) * 16777619; f = (f ^ px[i + 2]) * 16777619;
        if (seen.Add(px[i] | (px[i + 1] << 8) | (px[i + 2] << 16))) colors++; }
      return w + "x" + hh + " fnv " + f.ToString("X8") + " colors " + colors;
    }
  }
}
'@
if (-not (Test-Path $Out)) { New-Item -ItemType Directory $Out | Out-Null }
$mutex = New-Object System.Threading.Mutex($false, 'Global\DelphiDoomEsecuzioneGioco')
try { $got = $mutex.WaitOne([TimeSpan]::FromSeconds(3600)) } catch [System.Threading.AbandonedMutexException] { $got = $true }
if (-not $got) { throw 'the lock of the games was not taken' }
try {
  $stdout = Join-Path $Out 'stdout.txt'
  $stderr = Join-Path $Out 'stderr.txt'
  $p = Start-Process -FilePath $Exe -ArgumentList $Arguments -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
  # the handle is asked for now: without it the exit code of a process that ended is not there
  $null = $p.Handle
  $h = [IntPtr]::Zero
  $watch = [Diagnostics.Stopwatch]::StartNew()
  while ($h -eq [IntPtr]::Zero -and -not $p.HasExited -and $watch.Elapsed.TotalSeconds -lt 20) {
    Start-Sleep -Milliseconds 100
    $h = [KeenWindow]::Find([uint32]$p.Id)
  }
  if ($h -eq [IntPtr]::Zero) { "NO WINDOW (exited: $($p.HasExited))" }
  else {
    foreach ($step in $Steps) {
      if ($p.HasExited) { "the program ended before the step $step"; break }
      $parts = $step.Split(':')
      switch ($parts[0]) {
        'wait' { Start-Sleep -Milliseconds ([int]$parts[1]) }
        'key' {
          $held = 120; if ($parts.Count -gt 2) { $held = [int]$parts[2] }
          [KeenWindow]::Key($h, [int]$parts[1], $true); Start-Sleep -Milliseconds $held; [KeenWindow]::Key($h, [int]$parts[1], $false)
          Start-Sleep -Milliseconds 80
        }
        'down' { [KeenWindow]::Key($h, [int]$parts[1], $true) }
        'up' { [KeenWindow]::Key($h, [int]$parts[1], $false) }
        'shot' { "shot $($parts[1]): " + [KeenWindow]::Shot($h, (Join-Path $Out ($parts[1] + '.png'))) }
        'close' { [KeenWindow]::Close($h) }
        default { throw "unknown step $step" }
      }
    }
  }
  if (-not $p.WaitForExit($TimeoutSeconds * 1000)) { 'STILL RUNNING: killed'; Stop-Process -Id $p.Id -Force }
  # the handle of the process gives the exit code only after WaitForExit without a timeout
  $p.WaitForExit()
  "exit code: $($p.ExitCode)"
  if (Test-Path $stdout) { Get-Content $stdout | ForEach-Object { "stdout: $_" } }
  if (Test-Path $stderr) { Get-Content $stderr | ForEach-Object { "stderr: $_" } }
} finally { $mutex.ReleaseMutex() }

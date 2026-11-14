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
  [DllImport("kernel32.dll")] static extern IntPtr OpenThread(uint access, bool inherit, uint id);
  [DllImport("kernel32.dll")] static extern uint Wow64SuspendThread(IntPtr h);
  [DllImport("kernel32.dll")] static extern uint ResumeThread(IntPtr h);
  [DllImport("kernel32.dll")] static extern bool Wow64GetThreadContext(IntPtr h, byte[] context);
  [DllImport("kernel32.dll")] static extern bool ReadProcessMemory(IntPtr p, IntPtr address, byte[] buffer, int size, out int read);
  [DllImport("kernel32.dll")] static extern bool CloseHandle(IntPtr h);
  // Where a 32 bit thread is: its instruction pointer and the code addresses that are on its stack (the callers,
  // with some old ones among them). For a game that hangs: the addresses go to the .map file
  public static uint[] Where(IntPtr process, uint threadId, uint codeLow, uint codeHigh) {
    var result = new List<uint>();
    IntPtr t = OpenThread(0x0002 | 0x0008 | 0x0040, false, threadId);
    if (t == IntPtr.Zero) return result.ToArray();
    try {
      Wow64SuspendThread(t);
      byte[] context = new byte[716];
      BitConverter.GetBytes(0x00010007u).CopyTo(context, 0);   // WOW64_CONTEXT_FULL
      if (Wow64GetThreadContext(t, context)) {
        result.Add(BitConverter.ToUInt32(context, 184));        // Eip
        uint esp = BitConverter.ToUInt32(context, 196);
        byte[] stack = new byte[4 * 600]; int read;
        if (ReadProcessMemory(process, (IntPtr)esp, stack, stack.Length, out read))
          for (int i = 0; i + 4 <= read; i += 4) {
            uint v = BitConverter.ToUInt32(stack, i);
            if (v >= codeLow && v < codeHigh) result.Add(v); }
      }
      ResumeThread(t);
    } finally { CloseHandle(t); }
    return result.ToArray();
  }
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
# The publics of the .map (segment 0001, the code), sorted by address, for the step "where"
$script:mapOffsets = New-Object System.Collections.Generic.List[uint32]
$script:mapNames = New-Object System.Collections.Generic.List[string]
$script:mapCodeSize = 0x1000000
$script:mapCodeBase = 0x401000
$mapPath = [IO.Path]::ChangeExtension($exePath, '.map')
if ((@($Steps) + @($Steps2)) -contains 'where' -and (Test-Path -LiteralPath $mapPath)) {
  $inPublics = $false
  foreach ($line in [IO.File]::ReadLines($mapPath)) {
    # the first lines tell where the code is in memory and how long it is: " 0001:01001000 008C69F0H .text"
    if ($line -match '^\s*0001:([0-9A-Fa-f]{8})\s+([0-9A-Fa-f]{8})H\s+\.text') {
      $script:mapCodeBase = [Convert]::ToUInt32($Matches[1], 16); $script:mapCodeSize = [Convert]::ToUInt32($Matches[2], 16)
    }
    if ($line -match 'Publics by Value') { $inPublics = $true; continue }
    if ($inPublics -and $line -match '^\s*0001:([0-9A-Fa-f]{8})\s+(\S+)') {
      $script:mapOffsets.Add([Convert]::ToUInt32($Matches[1], 16)); $script:mapNames.Add($Matches[2])
    } elseif ($inPublics -and $line -match '^\s*000[2-9]:') { break }
  }
}
function Resolve-MapAddress([uint32]$Address) {
  $offset = [uint32]($Address - $script:mapCodeBase)
  $index = $script:mapOffsets.BinarySearch($offset)
  if ($index -lt 0) { $index = (-bnot $index) - 1 }
  if ($index -lt 0 -or $index -ge $script:mapNames.Count) { return ('{0:X8}' -f $Address) }
  return ('{0}+{1:X}' -f $script:mapNames[$index], ($offset - $script:mapOffsets[$index]))
}
function Invoke-RadixRun([string]$Arguments, [string[]]$Steps) {
  "run: $Arguments"
  $crash = Join-Path (Split-Path -Parent $exePath) 'crash.txt'
  Remove-Item -LiteralPath $crash -ErrorAction SilentlyContinue
  $p = Start-Process -FilePath $exePath -ArgumentList $Arguments -WorkingDirectory (Split-Path -Parent $exePath) -PassThru
  $null = $p.Handle
  # normal priority: with the machine busy (other agents compile) a game at low priority did not finish its
  # startup in two minutes
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
      'where' {
        # where every thread is, by the names of the .map beside the program (for a game that hangs)
        $p.Refresh()
        # the program can be loaded at another address than the one of the .map (ASLR): the code starts one page
        # after the base of the module
        try { $script:mapCodeBase = [uint32]($p.MainModule.BaseAddress.ToInt64() + 0x1000) } catch { "module base not read: $_" }
        "code base: $('{0:X8}' -f $script:mapCodeBase)"
        foreach ($thread in $p.Threads) {
          $addresses = [RadixWindow]::Where($p.Handle, [uint32]$thread.Id, [uint32]$script:mapCodeBase, [uint32]($script:mapCodeBase + $script:mapCodeSize))
          if ($addresses.Count -gt 0) {
            # the names once each, in the order of the stack (the same frame comes back many times)
            $names = @($addresses | ForEach-Object { Resolve-MapAddress $_ } | Select-Object -Unique | Select-Object -First 60)
            "thread $($thread.Id): " + ($names -join ' < ')
          }
        }
      }
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

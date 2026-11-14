<#
  Moves the REAL mouse of the system over the window of Keen32 (issue #165): KDREAMS.CFG has the mouse as the
  control of the player 0, the window is brought to the foreground and SetCursorPos puts the cursor on the right of
  its middle again and again (the game reads the distance from the middle, uses it as "right" and brings the cursor
  back). The report at the end has where Keen is: it must be to the right of where he is in a run where the cursor
  stays still. The pointer of the machine is moved: do not touch the mouse during the run (about 25 seconds).

    powershell -NoProfile -File Tools\Verifica\165\Prova-Mouse-Vero.ps1 -Exe bin\Win32\Release\Keen\Keen32.exe `
      -DataFolders <folder>,<folder>,<folder>
#>
param(
  [Parameter(Mandatory = $true)][string]$Exe,
  [Parameter(Mandatory = $true)][string[]]$DataFolders
)
$ErrorActionPreference = 'Stop'
$DataFolders = @($DataFolders | ForEach-Object { $_.Split(',') } | Where-Object { $_ -ne '' })
Add-Type -TypeDefinition @'
using System; using System.Text; using System.Runtime.InteropServices;
public static class MouseTest {
  delegate bool EnumProc(IntPtr h, IntPtr l);
  [DllImport("user32.dll")] static extern bool EnumWindows(EnumProc p, IntPtr l);
  [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
  [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr h);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
  [DllImport("user32.dll")] public static extern bool GetCursorPos(out POINT p);
  [DllImport("user32.dll")] static extern bool GetClientRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] static extern bool ClientToScreen(IntPtr h, ref POINT p);
  [DllImport("user32.dll")] public static extern void keybd_event(byte vk, byte scan, uint flags, UIntPtr extra);
  [StructLayout(LayoutKind.Sequential)] public struct POINT { public int X, Y; }
  [StructLayout(LayoutKind.Sequential)] struct RECT { public int L, T, R, B; }
  public static IntPtr Find(uint pid) {
    IntPtr found = IntPtr.Zero;
    EnumWindows((h, l) => { uint p; GetWindowThreadProcessId(h, out p); if (p == pid && IsWindowVisible(h)) { found = h; return false; } return true; }, IntPtr.Zero);
    return found;
  }
  public static POINT Middle(IntPtr h) {
    RECT r; GetClientRect(h, out r);
    POINT p; p.X = (r.R - r.L) / 2; p.Y = (r.B - r.T) / 2; ClientToScreen(h, ref p); return p;
  }
}
'@
$save = Join-Path $env:TEMP 'keen_mouse_real'
if (Test-Path $save) { Remove-Item -Recurse -Force $save }
New-Item -ItemType Directory -Force $save | Out-Null
# the configuration of the original: the mouse (4) as the control; the keys are zeros, the keyboard does not play
$cfg = New-Object byte[] 656
[BitConverter]::GetBytes([uint16]4).CopyTo($cfg, 644)
[BitConverter]::GetBytes([uint16]1).CopyTo($cfg, 640)
[IO.File]::WriteAllBytes((Join-Path $save 'KDREAMS.CFG'), $cfg)
$data = @()
foreach ($folder in $DataFolders) { $data += '-data'; $data += $folder }
function Run-Keen([bool]$MoveMouse) {
  $out = Join-Path $env:TEMP 'keen_mouse_real.txt'
  $arguments = ($data + @('-save', $save, '-warp', '1', '-quitafter', '16', '-report', '-nodevice')) | ForEach-Object { '"' + $_ + '"' }
  $process = Start-Process $Exe -ArgumentList ($arguments -join ' ') -RedirectStandardOutput $out -PassThru -WindowStyle Normal
  $watch = [Diagnostics.Stopwatch]::StartNew()
  $window = [IntPtr]::Zero
  $foreground = $false
  while (-not $process.HasExited) {
    Start-Sleep -Milliseconds 100
    if ($window -eq [IntPtr]::Zero) { $window = [MouseTest]::Find([uint32]$process.Id); continue }
    if ($watch.Elapsed.TotalSeconds -lt 6) { continue }
    # Windows lets a program take the foreground only after a key event of its own: Alt down and up first
    [MouseTest]::keybd_event(0x12, 0, 0, [UIntPtr]::Zero); [MouseTest]::keybd_event(0x12, 0, 2, [UIntPtr]::Zero)
    [void][MouseTest]::SetForegroundWindow($window)
    $foreground = ([MouseTest]::GetForegroundWindow() -eq $window)
    $middle = [MouseTest]::Middle($window)
    if ($MoveMouse) { [void][MouseTest]::SetCursorPos($middle.X + 40, $middle.Y) } else { [void][MouseTest]::SetCursorPos($middle.X, $middle.Y) }
  }
  $text = Get-Content $out -Raw
  Write-Host "run with the mouse moved: $MoveMouse, window seen in the foreground: $foreground"
  $m = [regex]::Match($text, 'keen at (\d+),(\d+)')
  if (-not $m.Success) { throw "No position in the report: $text" }
  [int]$m.Groups[1].Value
}
$still = Run-Keen $false
$moved = Run-Keen $true
"Keen at X = $still with the cursor still, $moved with the mouse pushed to the right"
if ($moved -le $still) { Write-Error 'The real mouse did not move Keen'; exit 1 }
'OK'

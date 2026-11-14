<#
  Runs a DOS program of Keen Dreams in DOSBox Staging (a copy of the data in a work folder outside the repository),
  types keys with the AUTOTYPE of DOSBox and takes pictures of the DOSBox window (PrintWindow) at the given seconds
  (issue #165, saved games of the original). The process is stopped by its PID, never by name.

    powershell -NoProfile -File Esegui-Dosbox-Con-Immagini.ps1 -Work <folder> -AutoType 'space enter enter' `
      -AutoTypeWait 20 -AutoTypePace 3 -Seconds 80 -ShotAt 10,25,40 -Out <folder> [-Program KDREAMS.EXE]
  The work folder has the files of the game; the pictures are Out\dos_<second>.png.
#>
param(
  [Parameter(Mandatory = $true)][string]$Work,
  [string]$AutoType = '',
  [int]$AutoTypeWait = 15,
  [double]$AutoTypePace = 2,
  [int]$Seconds = 60,
  [string[]]$ShotAt = @(),
  [string]$Out = $Work,
  # keys that are held: seconds:action:key, comma separated (action down, up or key = down and up after 150 ms), for
  # example '30:down:left,30.6:up:left,31.5:key:ctrl'. They are WM_KEYDOWN and WM_KEYUP posted to the DOSBox window
  [string]$KeyPlan = '',
  [string]$Program = 'KDREAMS.EXE',
  [string]$Dosbox = 'C:\Progetti\DelphiDoom\Reference\_dati\_strumenti\dosbox\dosbox-staging-v0.83.0\dosbox.exe'
)
$ErrorActionPreference = 'Stop'
# with -File the seconds come as one string with commas
$ShotAt = @($ShotAt | ForEach-Object { $_.Split(',') } | Where-Object { $_ -ne '' } | ForEach-Object { [int]$_ })
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System; using System.Text; using System.Runtime.InteropServices; using System.Drawing; using System.Drawing.Imaging;
public static class DosWindow {
  delegate bool EnumProc(IntPtr h, IntPtr l);
  [DllImport("user32.dll")] static extern bool EnumWindows(EnumProc p, IntPtr l);
  [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
  [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr h);
  [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll")] static extern bool PrintWindow(IntPtr h, IntPtr dc, uint flags);
  [DllImport("user32.dll")] static extern bool GetWindowRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] static extern bool PostMessage(IntPtr h, uint m, UIntPtr w, UIntPtr l);
  [DllImport("user32.dll")] static extern uint MapVirtualKey(uint code, uint type);
  [DllImport("user32.dll")] static extern bool SetForegroundWindow(IntPtr h);
  public static void Key(IntPtr h, byte vk, bool down) {
    SetForegroundWindow(h);
    uint sc = MapVirtualKey(vk, 0);
    UIntPtr l = (UIntPtr)(down ? (1u | (sc << 16)) : (1u | (sc << 16) | 0xC0000000u));
    PostMessage(h, down ? 0x100u : 0x101u, (UIntPtr)vk, l);
  }
  [StructLayout(LayoutKind.Sequential)] struct RECT { public int L, T, R, B; }
  public static IntPtr Find(uint pid) {
    IntPtr found = IntPtr.Zero;
    EnumWindows((h, l) => { uint p; GetWindowThreadProcessId(h, out p); if (p == pid && IsWindowVisible(h)) { var s = new StringBuilder(256); GetWindowText(h, s, 256); if (s.Length > 0) { found = h; return false; } } return true; }, IntPtr.Zero);
    return found;
  }
  public static bool Shot(IntPtr h, string path) {
    RECT r; GetWindowRect(h, out r); int w = r.R - r.L, hh = r.B - r.T; if (w <= 0 || hh <= 0) return false;
    using (var bmp = new Bitmap(w, hh)) { using (var g = Graphics.FromImage(bmp)) { IntPtr dc = g.GetHdc(); bool ok = PrintWindow(h, dc, 2); g.ReleaseHdc(dc); if (!ok) g.CopyFromScreen(r.L, r.T, 0, 0, new Size(w, hh)); } bmp.Save(path, ImageFormat.Png); }
    return true;
  }
}
'@
$virtualKeys = @{ left = 0x25; right = 0x27; up = 0x26; down = 0x28; ctrl = 0x11; alt = 0x12; space = 0x20; enter = 0x0D; esc = 0x1B; f6 = 0x75; a = 0x41; b = 0x42; c = 0x43; d = 0x44; e = 0x45 }
$plan = @()
foreach ($item in ($KeyPlan -split ',' | Where-Object { $_ -ne '' })) {
  $part = $item.Split(':')
  $plan += [pscustomobject]@{ At = [double]::Parse($part[0], [cultureinfo]::InvariantCulture); Action = $part[1]; Vk = [byte]$virtualKeys[$part[2]]; Done = $false }
}
$conf = Join-Path $Work '_run.conf'
$typeLine = if ($AutoType) { "autotype -w $AutoTypeWait -p $AutoTypePace $AutoType" } else { '' }
@"
[sdl]
fullscreen = false
window_size = 640x480
[dosbox]
machine = ega
memsize = 16
[cpu]
core = normal
cycles = max
[mixer]
nosound = true
[sblaster]
sbtype = none
[speaker]
pcspeaker = off
[midi]
mididevice = none
[joystick]
joysticktype = none
[autoexec]
mount c "$Work"
c:
$typeLine
$Program
exit
"@ | Set-Content -Encoding ascii $conf
New-Item -ItemType Directory -Force $Out | Out-Null
$process = Start-Process $Dosbox -ArgumentList "-conf `"$conf`" -noconsole" -WorkingDirectory $Work -PassThru
$watch = [Diagnostics.Stopwatch]::StartNew()
$done = @{}
try {
  while (-not $process.HasExited -and $watch.Elapsed.TotalSeconds -lt $Seconds) {
    Start-Sleep -Milliseconds 400
    $window = [DosWindow]::Find([uint32]$process.Id)
    if ($window -eq [IntPtr]::Zero) { continue }
    foreach ($step in $plan) {
      if (-not $step.Done -and $watch.Elapsed.TotalSeconds -ge $step.At) {
        $step.Done = $true
        switch ($step.Action) {
          'down' { [DosWindow]::Key($window, $step.Vk, $true) }
          'up' { [DosWindow]::Key($window, $step.Vk, $false) }
          'key' { [DosWindow]::Key($window, $step.Vk, $true); Start-Sleep -Milliseconds 150; [DosWindow]::Key($window, $step.Vk, $false) }
        }
      }
    }
    foreach ($second in $ShotAt) {
      if ($watch.Elapsed.TotalSeconds -ge $second -and -not $done[$second]) {
        $done[$second] = $true
        $ok = [DosWindow]::Shot($window, (Join-Path $Out ("dos_{0:D3}.png" -f $second))); Write-Host "shot $second ok=$ok"
      }
    }
  }
}
finally {
  if (-not $process.HasExited) { Stop-Process -Id $process.Id -Force }
}
'seconds: {0:N0}, exited by itself: {1}' -f $watch.Elapsed.TotalSeconds, ($watch.Elapsed.TotalSeconds -lt $Seconds)

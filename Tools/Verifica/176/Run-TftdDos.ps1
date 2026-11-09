<#
  Avvia il TFTD originale (DOS, DOS4GW) dai dati estratti in DOSBox Staging e salva schermate con la cattura di DOSBox
  (Ctrl+F5, cartella %LOCALAPPDATA%\DOSBox\capture). I dati si copiano in <Out>\gioco: mai dentro Reference\.
  Uso: powershell -NoProfile -File Run-TftdDos.ps1 -Data <cartella DOS con GEODATA, GEOSCAPE.EXE...> -Out <cartella>
         -Command "geoscape.exe 0" -Steps wait:10,shot:1-avvio,key:enter ...
#>
param(
  [Parameter(Mandatory = $true)][string]$Data,
  [Parameter(Mandatory = $true)][string]$Out,
  [string]$Command = 'terror.com',
  [string[]]$Steps = @(),
  [string]$DosBox = ''
)
$ErrorActionPreference = 'Stop'
if ($DosBox -eq '') {
  $dir = $PSScriptRoot
  while ($dir -and -not (Test-Path (Join-Path $dir 'Reference\_dati\_strumenti\dosbox'))) { $dir = Split-Path -Parent $dir }
  if (-not $dir) { throw 'dosbox.exe non trovato: passare -DosBox' }
  $DosBox = Get-ChildItem (Join-Path $dir 'Reference\_dati\_strumenti\dosbox') -Recurse -Filter dosbox.exe | Select-Object -First 1 -ExpandProperty FullName
}
$game = Join-Path $Out 'gioco'
$shots = Join-Path $Out 'schermate'
New-Item -ItemType Directory -Force $game, $shots | Out-Null
if (-not (Test-Path (Join-Path $game 'GEODATA'))) { Copy-Item (Join-Path $Data '*') $game -Recurse -Force }
$conf = Join-Path $Out 'tftd.conf'
@"
[sdl]
fullscreen = false
windowresolution = 960x600
[cpu]
core = normal
cycles = max
[dosbox]
memsize = 32
[sblaster]
sbtype = none
[gus]
gus = false
[autoexec]
mount c "$game"
c:
$Command
"@ | Set-Content $conf
Add-Type @"
using System; using System.Runtime.InteropServices;
public class TftdKeys {
  [DllImport("user32.dll")] public static extern void keybd_event(byte vk, byte sc, uint fl, UIntPtr ex);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern uint MapVirtualKey(uint c, uint t);
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
  [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint x, uint y, uint d, UIntPtr e);
  [DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr h, ref POINT p);
  [StructLayout(LayoutKind.Sequential)] public struct POINT { public int X, Y; }
  public static void Click(IntPtr h, int x, int y) {
    POINT p = new POINT(); p.X = x; p.Y = y; ClientToScreen(h, ref p);
    SetCursorPos(p.X, p.Y); System.Threading.Thread.Sleep(200);
    mouse_event(2, 0, 0, 0, UIntPtr.Zero); System.Threading.Thread.Sleep(100); mouse_event(4, 0, 0, 0, UIntPtr.Zero);
  }
}
"@
$vk = @{ enter = 0x0D; esc = 0x1B; space = 0x20; up = 0x26; down = 0x28; left = 0x25; right = 0x27; ctrl = 0x11; f5 = 0x74; y = 0x59; n = 0x4E; a = 0x41 }
function Send-Keys([string]$seq) {
  $p = Get-Process dosbox | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
  [TftdKeys]::SetForegroundWindow($p.MainWindowHandle) | Out-Null
  Start-Sleep -Milliseconds 300
  foreach ($item in $seq.Split(',')) {
    $keys = $item.Split('+') | ForEach-Object { [byte]$vk[$_] }
    foreach ($k in $keys) { [TftdKeys]::keybd_event($k, [byte][TftdKeys]::MapVirtualKey($k, 0), 0, [UIntPtr]::Zero); Start-Sleep -Milliseconds 40 }
    Start-Sleep -Milliseconds 120
    [array]::Reverse($keys)
    foreach ($k in $keys) { [TftdKeys]::keybd_event($k, [byte][TftdKeys]::MapVirtualKey($k, 0), 2, [UIntPtr]::Zero); Start-Sleep -Milliseconds 40 }
    Start-Sleep -Milliseconds 200
  }
}
$capture = Join-Path $env:LOCALAPPDATA 'DOSBox\capture'
Stop-Process -Name dosbox -Force -ErrorAction SilentlyContinue
$proc = Start-Process $DosBox -ArgumentList '-conf', $conf, '-noprimaryconf' -WorkingDirectory $Out -PassThru
try {
  foreach ($s in $Steps) {
    if ($s.StartsWith('wait:')) { Start-Sleep ([double]$s.Substring(5)); continue }
    if ($s.StartsWith('shot:')) {
      Send-Keys 'ctrl+f5'; Start-Sleep 1
      $last = Get-ChildItem $capture | Sort-Object LastWriteTime | Select-Object -Last 1
      $dest = Join-Path $shots ($s.Substring(5) + '.png'); Copy-Item $last.FullName $dest -Force; Write-Output $dest; continue
    }
    if ($s.StartsWith('click:')) {   # click:x,y in pixel dell'immagine catturata (1600x1200) -> finestra 960x600, area di gioco 800 px al centro
      $xy = $s.Substring(6).Split(','); $p = Get-Process dosbox | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
      [TftdKeys]::SetForegroundWindow($p.MainWindowHandle) | Out-Null; Start-Sleep -Milliseconds 300
      [TftdKeys]::Click($p.MainWindowHandle, [int](80 + [int]$xy[0] / 2), [int]([int]$xy[1] / 2)); Start-Sleep -Milliseconds 400; continue }
    Send-Keys $s.Substring(4)   # key:enter  /  key:ctrl+f5
  }
} finally { Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue }


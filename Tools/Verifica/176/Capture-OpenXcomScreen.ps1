<#
  Cattura i frame veri di OpenXcom (il nightly ufficiale) con il suo tasto degli screenshot (F12): sono i pixel del
  gioco, non una cattura dello schermo (che puo' mostrare un'altra finestra). Avvia OpenXcom.exe di <Root>\openxcom con
  una cartella utente propria (options.cfg con lingua en-US, 640x400, senza OpenGL), esegue i passi e copia i file
  screenNNN.png in <Out> col nome dato.

  Uso: powershell -NoProfile -File Capture-OpenXcomScreen.ps1 -Root <cartella con openxcom\> -Out <cartella> `
         -Steps 'wait:40','click:320,200','wait:2','shot:menu'
  Passi: wait:s, click:x,y (client 640x400), key:vk (codice virtuale di Windows), chord:mod,vk (un tasto con un modificatore tenuto: chord:17,68 = Ctrl+D), shot:nome (premere F12 e copiare il file).
  Va eseguito dentro il lock globale dei giochi (come Esegui-gioco.ps1): chi lo chiama prende il mutex
  Global\DelphiDoomEsecuzioneGioco.
#>
param(
  [Parameter(Mandatory = $true)][string]$Root,
  [Parameter(Mandatory = $true)][string]$Out,
  [string[]]$Steps = @(),
  [string]$Language = 'en-US',
  # own user folder per run (unique name): two runs, or two agents, never share screenshots
  # a folder whose contents (for example saved games in xcom2\) are copied into the user folder before the start
  [string]$SeedFolder = '',
  # option overrides written into the options.cfg of the run, as 'key=value' (for example 'mute=true')
  [string[]]$Option = @(),
  # makes SDL fail to open the audio (a driver that does not exist): OpenXcom runs with Options::mute on
  [switch]$NoAudio,
  # before the user folder is deleted, the saved games (*.sav) that the program wrote in it are copied here
  [string]$SaveCopyTo = '',
  [string]$UserName =('openxcom_user_cmp_' + [guid]::NewGuid().ToString('N').Substring(0, 8))
)
$ErrorActionPreference = 'Stop'
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @"
using System; using System.Runtime.InteropServices;
public class OxcCap {
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr h, ref POINT p);
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
  [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint x, uint y, uint d, UIntPtr e);
  [DllImport("user32.dll")] public static extern void keybd_event(byte vk, byte sc, uint fl, UIntPtr ex);
  [StructLayout(LayoutKind.Sequential)] public struct POINT { public int X, Y; }
  public static void Click(IntPtr h, int x, int y) {
    POINT p = new POINT(); p.X = x; p.Y = y; ClientToScreen(h, ref p);
    SetCursorPos(p.X, p.Y); System.Threading.Thread.Sleep(150);
    mouse_event(2, 0, 0, 0, UIntPtr.Zero); System.Threading.Thread.Sleep(80); mouse_event(4, 0, 0, 0, UIntPtr.Zero);
  }
  public static void Chord(byte mod, byte vk) { keybd_event(mod, 0, 0, UIntPtr.Zero); System.Threading.Thread.Sleep(60); keybd_event(vk, 0, 0, UIntPtr.Zero); System.Threading.Thread.Sleep(60); keybd_event(vk, 0, 2, UIntPtr.Zero); System.Threading.Thread.Sleep(60); keybd_event(mod, 0, 2, UIntPtr.Zero); }
  public static void Key(byte vk) { keybd_event(vk, 0, 0, UIntPtr.Zero); System.Threading.Thread.Sleep(60); keybd_event(vk, 0, 2, UIntPtr.Zero); }
}
"@
New-Item -ItemType Directory -Force $Out | Out-Null
$user = Join-Path $Root $UserName
if (Test-Path $user) { Remove-Item -Recurse -Force $user }
New-Item -ItemType Directory -Force $user | Out-Null
if ($SeedFolder -ne '') { Copy-Item -Path (Join-Path $SeedFolder '*') -Destination $user -Recurse -Force }
$cfg = (Get-Content (Join-Path $Root 'openxcom_user\options.cfg') -Raw) -replace '(?m)^  language: .*$', "  language: $Language"
foreach ($o in $Option) {
  $kv = $o.Split('=', 2)
  $cfg = $cfg -replace ('(?m)^  ' + [regex]::Escape($kv[0]) + ': .*$'), ('  ' + $kv[0] + ': ' + $kv[1])
}
Set-Content -Path (Join-Path $user 'options.cfg') -Value $cfg -Encoding ASCII
$exe = Join-Path $Root 'openxcom\OpenXcom.exe'
if ($NoAudio) { $env:SDL_AUDIODRIVER = 'nonexistentdriver' }
$p = Start-Process $exe -ArgumentList "-data `"$(Join-Path $Root 'openxcom')`" -user `"$user`"" -WorkingDirectory (Join-Path $Root 'openxcom') -PassThru
try {
  Start-Sleep 8
  $p.Refresh(); $h = $p.MainWindowHandle
  [OxcCap]::SetForegroundWindow($h) | Out-Null; Start-Sleep 1
  foreach ($s in $Steps) {
    $a = $s.Split(':')
    switch ($a[0]) {
      'wait' { Start-Sleep ([double]$a[1]) }
      'click' { $xy = $a[1].Split(','); [OxcCap]::Click($h, [int]$xy[0], [int]$xy[1]) }
      'key' { [OxcCap]::Key([byte][int]$a[1]) }
    'chord' { $k = $a[1].Split(','); [OxcCap]::Chord([byte][int]$k[0], [byte][int]$k[1]) }
      'shot' {
        $before = @(Get-ChildItem $user -Recurse -Filter 'screen*.png' -ErrorAction SilentlyContinue | ForEach-Object FullName)
        [OxcCap]::Key(123); Start-Sleep 2
        $new = Get-ChildItem $user -Recurse -Filter 'screen*.png' | Where-Object { $before -notcontains $_.FullName } | Select-Object -First 1
        if ($new) { Write-Output ('from ' + $new.FullName); Copy-Item $new.FullName (Join-Path $Out ($a[1] + '.png')) -Force; Write-Output (Join-Path $Out ($a[1] + '.png')) }
        else { Write-Output "NESSUN FILE per $($a[1])" }
      }
    }
  }
} finally {
  if ($NoAudio) { Remove-Item Env:SDL_AUDIODRIVER -ErrorAction SilentlyContinue }
  Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
  Start-Sleep 1
  if ($SaveCopyTo -ne '') {
    New-Item -ItemType Directory -Force $SaveCopyTo | Out-Null
    Get-ChildItem $user -Recurse -Filter '*.sav' -ErrorAction SilentlyContinue | ForEach-Object { Copy-Item $_.FullName (Join-Path $SaveCopyTo $_.Name) -Force }
  }
  Remove-Item -Recurse -Force $user -ErrorAction SilentlyContinue
}

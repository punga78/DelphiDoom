<#
  Avvia il GREED.EXE originale (DOS, DOS4GW) del gioco completo in DOSBox Staging e salva le schermate
  (menu, introduzione, livello 1) con la cattura di DOSBox (Ctrl+F5).

  Uso:
    powershell -NoProfile -File Tools\Verifica\175\Run-GreedDos.ps1 `
      -Data <cartella con GREED.EXE e GREED.BLO> -Cd <cartella del CD-ROM con GREED.SHR e MOVIES> -Out <cartella>

  Cosa fa: copia i dati in <Out>\gioco (mai dentro Reference\), copia MOVIES e GREED.SHR del CD accanto al BLO,
  scrive la configurazione di DOSBox (C: = la copia; A: = la stessa cartella come floppy, perche' i filmati si
  cercano in A:\MOVIES), lancia "greed.exe nocdromcheck" (senza SETUP.CFG: il gioco completo e' la versione
  CD-ROM e dice "CDROM not found" senza l'argomento; con il SETUP.CFG di Sound Blaster in DOSBox si blocca dopo
  il banner di DOS4GW) e manda i tasti con keybd_event. Le immagini sono in <Out>\schermate.
  Il percorso della cattura di DOSBox e' %LOCALAPPDATA%\DOSBox\capture.
#>
param(
  [Parameter(Mandatory = $true)][string]$Data,
  [string]$Cd = '',
  [Parameter(Mandatory = $true)][string]$Out,
  [string]$DosBox = ''
)
$ErrorActionPreference = 'Stop'
if ($DosBox -eq '') {
  # Reference\ sta nel checkout principale: si risale (anche da un worktree) fino a trovarla
  $dir = $PSScriptRoot
  while ($dir -and -not (Test-Path (Join-Path $dir 'Reference\_dati\_strumenti\dosbox'))) { $dir = Split-Path -Parent $dir }
  if (-not $dir) { throw 'dosbox.exe non trovato: passare -DosBox' }
  $DosBox = Get-ChildItem (Join-Path $dir 'Reference\_dati\_strumenti\dosbox') -Recurse -Filter dosbox.exe | Select-Object -First 1 -ExpandProperty FullName
}
$game = Join-Path $Out 'gioco'
$shots = Join-Path $Out 'schermate'
New-Item -ItemType Directory -Force $game, $shots | Out-Null
Copy-Item (Join-Path $Data '*') $game -Recurse -Force
Remove-Item (Join-Path $game 'SETUP.CFG') -ErrorAction SilentlyContinue
if ($Cd -ne '') {
  Copy-Item (Join-Path $Cd 'MOVIES') $game -Recurse -Force
  Copy-Item (Join-Path $Cd 'GREED.SHR'), (Join-Path $Cd 'TMASTER.SHR') $game -Force
}
$conf = Join-Path $Out 'greed.conf'
@"
[sdl]
fullscreen = false
windowresolution = 960x600
[cpu]
core = normal
cycles = fixed 60000
[dosbox]
memsize = 32
[sblaster]
sbtype = none
[gus]
gus = false
[autoexec]
mount c "$game"
mount a "$game" -t floppy
c:
greed.exe nocdromcheck
"@ | Set-Content $conf

Add-Type @"
using System; using System.Runtime.InteropServices;
public class GreedKeys {
  [DllImport("user32.dll")] public static extern void keybd_event(byte vk, byte sc, uint fl, UIntPtr ex);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern uint MapVirtualKey(uint c, uint t);
}
"@
$vk = @{ enter = 0x0D; esc = 0x1B; space = 0x20; up = 0x26; down = 0x28; left = 0x25; right = 0x27; ctrl = 0x11; f5 = 0x74 }
function Send-Keys([string]$seq) {
  $p = Get-Process dosbox | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
  [GreedKeys]::SetForegroundWindow($p.MainWindowHandle) | Out-Null
  Start-Sleep -Milliseconds 300
  foreach ($item in $seq.Split(',')) {
    if ($item.StartsWith('wait:')) { Start-Sleep -Milliseconds ([int]([double]$item.Substring(5) * 1000)); continue }
    $keys = $item.Split('+') | ForEach-Object { [byte]$vk[$_] }
    foreach ($k in $keys) { [GreedKeys]::keybd_event($k, [byte][GreedKeys]::MapVirtualKey($k, 0), 0, [UIntPtr]::Zero); Start-Sleep -Milliseconds 40 }
    Start-Sleep -Milliseconds 120
    [array]::Reverse($keys)
    foreach ($k in $keys) { [GreedKeys]::keybd_event($k, [byte][GreedKeys]::MapVirtualKey($k, 0), 2, [UIntPtr]::Zero); Start-Sleep -Milliseconds 40 }
    Start-Sleep -Milliseconds 200
  }
}
$capture = Join-Path $env:LOCALAPPDATA 'DOSBox\capture'
function Save-Shot([string]$name, [string]$keys = '') {
  if ($keys -ne '') { Send-Keys $keys }
  Send-Keys 'ctrl+f5,wait:1'
  $last = Get-ChildItem $capture | Sort-Object LastWriteTime | Select-Object -Last 1
  Copy-Item $last.FullName (Join-Path $shots "$name.png") -Force
  Write-Output (Join-Path $shots "$name.png")
}

Stop-Process -Name dosbox -Force -ErrorAction SilentlyContinue
$proc = Start-Process $DosBox -ArgumentList '-conf', $conf, '-noprimaryconf' -WorkingDirectory $Out -PassThru
try {
  Start-Sleep 38
  Save-Shot '1-logo' 'wait:0'
  Save-Shot '2-personaggio' 'esc,wait:6'
  Save-Shot '3-menu' 'esc,wait:2,esc,wait:2,esc,wait:3'
  Save-Shot '4-nuova-partita' 'enter,wait:3'
  Save-Shot '5-missione' 'space,wait:4,space,wait:4'
  # le schermate della missione scrivono il testo lettera per lettera e il numero di spazi che servono dipende
  # dai tempi: la sequenza e' un tentativo, si guardano le immagini (il livello 1 e' arrivato dopo 3 o 4 spazi)
  foreach ($n in 6..9) { Save-Shot "$n-avanti" 'space,wait:5' }
  Save-Shot '10-su-su' 'up,wait:0.6,up,wait:0.6'
} finally {
  Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
}

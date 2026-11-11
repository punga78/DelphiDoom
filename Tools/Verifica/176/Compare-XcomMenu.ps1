<#
  Avvia Xcom32 e il vero OpenXcom dal menu principale (nessun salvataggio caricato dallo script), esegue i passi e
  confronta pixel per pixel le schermate (Compare-Png.ps1). Serve per cio' che parte dal menu: partita nuova, opzioni,
  liste dei salvataggi con una cartella di salvataggi preparata.

  Uso: Compare-XcomMenu.ps1 -Root <worktree> -Data <Reference\_dati\xcom_tftd o xcom_ufo> -Out <cartella tua>
         -Delphi 'wait:5000;move:220,180;click:220,180;wait:1500;shot:new.png'
         -Real 'wait:3','click:220,180','wait:2','shot:new' -Names new [-Game 'openxcom\UFO' -ModId xcom1]

  -Delphi   i passi di Xcom32 (millisecondi)
  -Real     i passi di Capture-OpenXcomScreen.ps1 (secondi); senza, gira solo Xcom32
  -Saves    file .sav copiati nella cartella dei salvataggi del mod (intestazione adattata come Compare-XcomScreens.ps1)
  -Option   opzioni da cambiare in options.cfg per entrambi, 'chiave=valore'
  -Seed     il seme del generatore di Xcom32 per una partita nuova (il vero non lo ha: la partita nuova non e' uguale)
  La cartella utente e' <Out>\user per Xcom32 e <Out>\realuser per il vero: mai dentro i dati del gioco. Con -Real
  prende il lock globale dei giochi (Global\DelphiDoomEsecuzioneGioco) e cattura una volta sola.
#>
param(
  [Parameter(Mandatory = $true)][string]$Root,
  [Parameter(Mandatory = $true)][string]$Data,
  [Parameter(Mandatory = $true)][string]$Out,
  [Parameter(Mandatory = $true)][string]$Delphi,
  [string[]]$Real = @(),
  [string[]]$Names = @(),
  [string[]]$Saves = @(),
  [string[]]$Option = @(),
  [string]$Game = 'TFTD',
  [string]$ModId = 'xcom2',
  [string]$Seed = ''
)
$ErrorActionPreference = 'Stop'
if (Test-Path "$Out\user") { Remove-Item -Recurse -Force "$Out\user" }
if (Test-Path "$Out\seed") { Remove-Item -Recurse -Force "$Out\seed" }
New-Item -ItemType Directory -Force "$Out\real", "$Out\delphi", "$Out\user", "$Out\seed\$ModId" | Out-Null
foreach ($f in $Saves) {
  $name = [IO.Path]::GetFileNameWithoutExtension($f)
  $t = [IO.File]::ReadAllText($f)
  $t = $t.Replace('name: ""', 'name: "' + $name + '"').Replace('  - "xcom2 ver: 1.0"', '  - xcom2').Replace('  - "xcom1 ver: 1.0"', '  - xcom1').Replace("`r`n", "`n")
  [IO.File]::WriteAllText("$Out\seed\$ModId\$name.sav", $t)
}
Copy-Item "$Out\seed\$ModId" "$Out\user" -Recurse -Force
$cfg = Get-Content "$Data\openxcom_user\options.cfg" -Raw
foreach ($o in $Option) {
  $kv = $o.Split('=', 2)
  $cfg = $cfg -replace ('(?m)^  ' + [regex]::Escape($kv[0]) + ': .*$'), ('  ' + $kv[0] + ': ' + $kv[1])
}
Set-Content -Path "$Out\user\options.cfg" -Value $cfg -Encoding ASCII
$arguments = @('-data', "$Data\openxcom", '-game', "$Data\$Game", '-mod', $ModId, '-user', "$Out\user")
if ($Seed -ne '') { $arguments += '-seed', $Seed }
$arguments += '-script', $Delphi
Push-Location "$Out\delphi"
& "$Root\bin\OpenXcom\Xcom32.exe" @arguments | Out-Null
Pop-Location
if ($Real.Count -eq 0) { return }
$m = New-Object Threading.Mutex($false, 'Global\DelphiDoomEsecuzioneGioco')
$got = $m.WaitOne(300000)
try {
  & "$Root\Tools\Verifica\176\Capture-OpenXcomScreen.ps1" -Root $Data -Out "$Out\real" -SeedFolder "$Out\seed" -UserRoot "$Out\realuser" -Steps $Real -Option $Option | Out-Null
}
finally { if ($got) { $m.ReleaseMutex() } }
foreach ($n in $Names) {
  Write-Output "== $n"
  if (-not ((Test-Path "$Out\real\$n.png") -and (Test-Path "$Out\delphi\$n.png"))) { Write-Output 'MANCA'; continue }
  & "$Root\Tools\Verifica\176\Compare-Png.ps1" -A "$Out\real\$n.png" -B "$Out\delphi\$n.png" 2>&1 | Select-Object -First 4
}

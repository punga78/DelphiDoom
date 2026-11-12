<#
  Carica un salvataggio di battaglia (testo .sav) in Xcom32 -script a una scala e con o senza -truecolor e salva le
  schermate (issue #183). Le coordinate dei passi sono quelle di una finestra 640x400 e il programma le porta alla
  scala chiesta (click/move/drag); le schermate vanno in <Out>\<nome>.png.

  Uso: Run-XcomBattleScene.ps1 -Exe <Xcom32.exe> -Data <xcom_tftd|xcom_ufo> -Game TFTD|UFO -SaveFile <.sav>
         -Out <cartella> -Scale 1|2|3|4 [-TrueColor] -Steps 'wait:1500;shot:a.png'
  La cartella utente e' <Out>\user (mai quella dell'utente); i dati si leggono soltanto.
#>
param(
  [Parameter(Mandatory = $true)][string]$Exe,
  [Parameter(Mandatory = $true)][string]$Data,
  [Parameter(Mandatory = $true)][string]$SaveFile,
  [Parameter(Mandatory = $true)][string]$Out,
  [Parameter(Mandatory = $true)][string]$Steps,
  [string]$Game = 'TFTD',
  # folder of the game inside -Data (the UFO data of the repository keep it in 'openxcom\UFO')
  [string]$GameDir = '',
  [double]$Scale = 2,
  [switch]$TrueColor,
  [string[]]$Option = @(),
  [string]$ExtraArgs = '',
  # no saved game: the script starts at the main menu (the steps are then the whole script)
  [switch]$NoLoad,
  # writes the CPU seconds of the process as "cpu=<seconds>" (the frames of a script run as fast as they can)
  [switch]$Measure
)
$ErrorActionPreference = 'Stop'
$modId = if ($Game -eq 'UFO') { 'xcom1' } else { 'xcom2' }
if ($GameDir -eq '') { $GameDir = if ($Game -eq 'UFO') { 'openxcom\UFO' } else { $Game } }
if (Test-Path "$Out\user") { Remove-Item -Recurse -Force "$Out\user" }
New-Item -ItemType Directory -Force "$Out\user\$modId" | Out-Null
$t = [IO.File]::ReadAllText($SaveFile).Replace("`r`n", "`n")
$t = [regex]::Replace($t, '(?m)^name: .*$', 'name: "Battle"', 1)
$t = $t.Replace('  - "xcom2 ver: 1.0"', '  - xcom2').Replace('  - "xcom1 ver: 1.0"', '  - xcom1')
[IO.File]::WriteAllText("$Out\user\$modId\battle.sav", $t, (New-Object Text.UTF8Encoding($false)))
$cfg = Get-Content "$Data\openxcom_user\options.cfg" -Raw
$Option = @("displayWidth=$(320 * $Scale)", "displayHeight=$(200 * $Scale)") + $Option
foreach ($o in $Option) {
  $kv = $o.Split('=', 2)
  if ($cfg -match ('(?m)^  ' + [regex]::Escape($kv[0]) + ': ')) { $cfg = $cfg -replace ('(?m)^  ' + [regex]::Escape($kv[0]) + ': .*$'), ('  ' + $kv[0] + ': ' + $kv[1]) }
  else { $cfg = $cfg -replace '(?m)^options:\r?$', ("options:`n  " + $kv[0] + ': ' + $kv[1]) }
}
Set-Content -Path "$Out\user\options.cfg" -Value $cfg -Encoding ASCII
function ScaleStep([string]$step) {
  # click:x,y  move:x,y  rclick  drag:x1,y1,x2,y2,button  with the coordinates of a 640x400 window
  $k = $step.Split(':', 2)
  if ($k[0] -in 'click', 'move', 'rclick', 'drag') {
    $v = $k[1].Split(',')
    $n = for ($i = 0; $i -lt $v.Count; $i++) { if ($k[0] -eq 'drag' -and $i -eq 4) { $v[$i] } else { [int]([int]$v[$i] * $Scale / 2) } }
    return $k[0] + ':' + ($n -join ',')
  }
  return $step
}
$load = 'wait:5000;move:220,256;click:220,256;wait:2000;move:80,92;click:80,92;wait:1000'
$whole = if ($NoLoad) { $Steps } else { $load + ';' + $Steps }
$script = (($whole).Split(';') | ForEach-Object { ScaleStep $_ }) -join ';'
New-Item -ItemType Directory -Force $Out | Out-Null
$argList = "-data `"$Data\openxcom`" -game `"$Data\$GameDir`" -mod $modId -user `"$Out\user`" -script $script $ExtraArgs"
if ($TrueColor) { $argList = '-truecolor ' + $argList }
Push-Location $Out
$p = Start-Process $Exe -ArgumentList $argList -RedirectStandardError "$Out\stderr.txt" -RedirectStandardOutput "$Out\stdout.txt" -PassThru -Wait
Pop-Location
if ($Measure) { Write-Output ('cpu=' + [Math]::Round($p.TotalProcessorTime.TotalSeconds, 3).ToString([Globalization.CultureInfo]::InvariantCulture)) }
else { Get-Content "$Out\stderr.txt", "$Out\stdout.txt" }

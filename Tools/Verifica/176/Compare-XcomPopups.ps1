<#
  Carica un salvataggio vero (Tests\Data\XcomSave\realsave\saveNN.sav) sia nel vero OpenXcom sia in Xcom32, lascia
  scorrere il tempo e confronta pixel per pixel le schermate dei popup del geoscape (Compare-Png.ps1).

  Uso: Compare-XcomPopups.ps1 -Root <worktree> -Data <Reference\_dati\xcom_tftd> -Out <cartella> -Save 5
         -Delphi 'wait:3000;shot:a.png;move:320,326;click:320,326;wait:1500;shot:b.png'
         -Real 'wait:3','shot:a','click:320,326','wait:2','shot:b'
         -Names a,b

  -Delphi  il resto dello script di Xcom32 dopo il caricamento del salvataggio (millisecondi; il caricamento
           e' gia' fatto: menu, Load Game, il salvataggio)
  -Real    i passi di Capture-OpenXcomScreen.ps1 dopo il caricamento (secondi)
  -Names   i nomi delle schermate da confrontare
  Il salvataggio e' copiato con l'intestazione adattata al catalogo (come Compare-XcomScreens.ps1). Prende il lock
  globale dei giochi (Global\DelphiDoomEsecuzioneGioco).
#>
param(
  [Parameter(Mandatory = $true)][string]$Root,
  [Parameter(Mandatory = $true)][string]$Data,
  [Parameter(Mandatory = $true)][string]$Out,
  [Parameter(Mandatory = $true)][string]$Delphi,
  [Parameter(Mandatory = $true)][string[]]$Real,
  [Parameter(Mandatory = $true)][string[]]$Names,
  [int]$Save = 5,
  # a saved game in place of realsave\saveNN.sav; the game folder in <Data> and the id of its mod (UFO:
  # 'openxcom\UFO' and xcom1)
  [string]$SaveFile = '',
  [string]$Game = 'TFTD',
  [string]$ModId = 'xcom2',
  # options changed in options.cfg for both programs, 'key=value'
  [string[]]$Option = @(),
  # seconds the real program gets before the first click on its menu
  [int]$StartWait = 3,
  # how many times the capture of the real program is tried when a file is missing (real mouse clicks)
  [int]$Tries = 1,
  # only Xcom32 runs (no real mouse click); only the real program runs
  [switch]$NoReal,
  [switch]$NoDelphi
)
$ErrorActionPreference = 'Stop'
if (Test-Path "$Out\user") { Remove-Item -Recurse -Force "$Out\user" }
New-Item -ItemType Directory -Force "$Out\real", "$Out\delphi", "$Out\user", "$Out\seed\$ModId" | Out-Null
$name = 'save{0:00}' -f $Save
$src = if ($SaveFile) { $SaveFile } else { "$Root\Tests\Data\XcomSave\realsave\$name.sav" }
$t = [IO.File]::ReadAllText($src)
$t = $t.Replace('name: ""', 'name: "Save ' + ('{0:00}' -f $Save) + '"').Replace('  - "xcom2 ver: 1.0"', '  - xcom2').Replace('  - "xcom1 ver: 1.0"', '  - xcom1').Replace("`r`n", "`n")
[IO.File]::WriteAllText("$Out\seed\$ModId\$name.sav", $t)
Copy-Item "$Out\seed\$ModId" "$Out\user" -Recurse -Force
$cfg = Get-Content "$Data\openxcom_user\options.cfg" -Raw
foreach ($o in $Option) {
  $kv = $o.Split('=', 2)
  $cfg = $cfg -replace ('(?m)^  ' + [regex]::Escape($kv[0]) + ': .*$'), ('  ' + $kv[0] + ': ' + $kv[1])
}
Set-Content -Path "$Out\user\options.cfg" -Value $cfg -Encoding ASCII
$script = 'wait:5000;move:220,256;click:220,256;wait:2000;move:80,92;click:80,92;wait:1000;' + $Delphi
$realSteps = @("wait:$StartWait", 'click:220,256', 'wait:3', 'click:80,92') + $Real
if (-not $NoDelphi) {
  Push-Location "$Out\delphi"
  & "$Root\bin\OpenXcom\Xcom32.exe" -data "$Data\openxcom" -game "$Data\$Game" -mod $ModId -user "$Out\user" -script $script | Out-Null
  Pop-Location
}
if ($NoReal) { return }
$m = New-Object Threading.Mutex($false, 'Global\DelphiDoomEsecuzioneGioco')
$got = $m.WaitOne(300000)
try {
  for ($try = 0; $try -lt $Tries; $try++) {
    & "$Root\Tools\Verifica\176\Capture-OpenXcomScreen.ps1" -Root $Data -Out "$Out\real" -SeedFolder "$Out\seed" -UserRoot "$Out\realuser" -Steps $realSteps -Option $Option | Out-Null
    $missing = @($Names | Where-Object { -not (Test-Path "$Out\real\$_.png") })
    if ($missing.Count -eq 0) { break }
  }
}
finally { if ($got) { $m.ReleaseMutex() } }
foreach ($n in $Names) {
  Write-Output "== $n"
  if (-not ((Test-Path "$Out\real\$n.png") -and (Test-Path "$Out\delphi\$n.png"))) { Write-Output 'MANCA'; continue }
  & "$Root\Tools\Verifica\176\Compare-Png.ps1" -A "$Out\real\$n.png" -B "$Out\delphi\$n.png" 2>&1 | Select-Object -First 4
}

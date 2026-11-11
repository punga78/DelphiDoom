<#
  Carica un salvataggio vero (Tests\Data\XcomSave\realsave\saveNN.sav) sia nel vero OpenXcom sia in XcomGame, lascia
  scorrere il tempo e confronta pixel per pixel le schermate dei popup del geoscape (Compare-Png.ps1).

  Uso: Compare-XcomPopups.ps1 -Root <worktree> -Data <Reference\_dati\xcom_tftd> -Out <cartella> -Save 5
         -Delphi 'wait:3000;shot:a.png;move:320,326;click:320,326;wait:1500;shot:b.png'
         -Real 'wait:3','shot:a','click:320,326','wait:2','shot:b'
         -Names a,b

  -Delphi  il resto dello script di XcomGame dopo il caricamento del salvataggio (millisecondi; il caricamento
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
  [int]$Save = 5
)
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force "$Out\real", "$Out\delphi", "$Out\user", "$Out\seed\xcom2" | Out-Null
$name = 'save{0:00}' -f $Save
$t = [IO.File]::ReadAllText("$Root\Tests\Data\XcomSave\realsave\$name.sav")
$t = $t.Replace('name: ""', 'name: "Save ' + ('{0:00}' -f $Save) + '"').Replace('  - "xcom2 ver: 1.0"', '  - xcom2').Replace("`r`n", "`n")
[IO.File]::WriteAllText("$Out\seed\xcom2\$name.sav", $t)
Copy-Item "$Out\seed\xcom2" "$Out\user" -Recurse -Force
Copy-Item "$Data\openxcom_user\options.cfg" "$Out\user\options.cfg" -Force
$script = 'wait:5000;move:220,256;click:220,256;wait:2000;move:80,92;click:80,92;wait:1000;' + $Delphi
$realSteps = @('wait:3', 'click:220,256', 'wait:3', 'click:80,92') + $Real
Push-Location "$Out\delphi"
& "$Root\bin\OpenXcom\XcomGame.exe" -data "$Data\openxcom" -game "$Data\TFTD" -user "$Out\user" -script $script | Out-Null
Pop-Location
$m = New-Object Threading.Mutex($false, 'Global\DelphiDoomEsecuzioneGioco')
$got = $m.WaitOne(300000)
try {
  for ($try = 0; $try -lt 3; $try++) {
    & "$Root\Tools\Verifica\176\Capture-OpenXcomScreen.ps1" -Root $Data -Out "$Out\real" -SeedFolder "$Out\seed" -Steps $realSteps | Out-Null
    $missing = @($Names | Where-Object { -not (Test-Path "$Out\real\$_.png") })
    if ($missing.Count -eq 0) { break }
  }
}
finally { if ($got) { $m.ReleaseMutex() } }
foreach ($n in $Names) {
  Write-Output "== $n"
  & "$Root\Tools\Verifica\176\Compare-Png.ps1" -A "$Out\real\$n.png" -B "$Out\delphi\$n.png" 2>&1 | Select-Object -First 4
}

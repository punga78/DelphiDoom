<#
  Carica un salvataggio vero (Tests\Data\XcomSave\realsave\saveNN.sav, scritto dagli oggetti veri di OpenXcom) sia
  nel vero OpenXcom sia in XcomGame e confronta le schermate pixel per pixel (Compare-Png.ps1).

  Uso: Compare-XcomScreens.ps1 -Root <worktree> -Data <cartella di Reference\_dati\xcom_tftd> -Out <cartella>
         -Screens 'soldiers=512,180','crafts=512,206','stores=512,154>344,374' [-Save 2]

  -Screens  elenco nome=x,y: dalla schermata di base (menu, Load Game, il salvataggio, Bases) si fa clic in (x,y) e
            si salva la schermata col nome; coordinate del client 640x400 (la base 320x200 raddoppiata). Il clic
            sull'OK della schermata aperta ((476,368) per le liste con OK in basso a destra) torna alla base.
  Il salvataggio e' copiato con l'intestazione adattata al catalogo (nome "Save NN", mods: xcom2) in una cartella
  nuova (-UserName unico). Prende il lock globale dei giochi (Global\DelphiDoomEsecuzioneGioco).
#>
param(
  [Parameter(Mandatory = $true)][string]$Root,
  [Parameter(Mandatory = $true)][string]$Data,
  [Parameter(Mandatory = $true)][string]$Out,
  [string[]]$Screens = @(),
  [int]$Save = 2,
  [string]$Back = '476,368',
  [switch]$Geoscape
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
function Test-ValidPng([string]$Path) {
  if (-not (Test-Path $Path)) { return $false }
  if ((Get-Item $Path).Length -lt 100) { return $false }
  try {
    $img = [System.Drawing.Image]::FromFile($Path)
    $ok = $img.Width -gt 0 -and $img.Height -gt 0
    $img.Dispose()
    return $ok
  }
  catch { return $false }
}
New-Item -ItemType Directory -Force "$Out\real", "$Out\delphi", "$Out\user", "$Out\seed\xcom2" | Out-Null
$name = 'save{0:00}' -f $Save
$t = [IO.File]::ReadAllText("$Root\Tests\Data\XcomSave\realsave\$name.sav")
$t = $t.Replace('name: ""', 'name: "Save ' + ('{0:00}' -f $Save) + '"').Replace('  - "xcom2 ver: 1.0"', '  - xcom2').Replace("`r`n", "`n")
[IO.File]::WriteAllText("$Out\seed\xcom2\$name.sav", $t)
Copy-Item "$Out\seed\xcom2" "$Out\user" -Recurse -Force
Copy-Item "$Data\openxcom_user\options.cfg" "$Out\user\options.cfg" -Force
# XcomGame: the steps in milliseconds
$script = 'wait:5000;move:220,256;click:220,256;wait:2000;move:80,92;click:80,92;wait:4000'
$real = @('wait:3', 'click:220,256', 'wait:3', 'click:80,92', 'wait:10')
if (-not $Geoscape) { $script += ';move:575,34;click:575,34;wait:2000'; $real += 'click:575,34', 'wait:4' } else { $script += ';wait:1000'; $real += 'wait:2' }
$first = $true
foreach ($s in $Screens) {
  $n, $xy = $s.Split('=')
  $cont = $n.StartsWith('+'); if ($cont) { $n = $n.Substring(1) }
  if (-not $first -and -not $cont) { $script += ";move:$Back;click:$Back;wait:1500"; $real += "click:$Back", 'wait:3' }
  # name=x,y or name=x1,y1>x2,y2 (a chain of clicks: the screen of a screen)
  foreach ($part in $xy.Split('>')) { $script += ";move:$part;click:$part;wait:2000"; $real += "click:$part", 'wait:5' }
  $script += ";shot:$n.png"; $real += "shot:$n"
  $first = $false
}
Push-Location "$Out\delphi"
& "$Root\bin\OpenXcom\XcomGame.exe" -data "$Data\openxcom" -game "$Data\TFTD" -user "$Out\user" -script $script | Out-Null
Pop-Location
$m = New-Object Threading.Mutex($false, 'Global\DelphiDoomEsecuzioneGioco')
$got = $m.WaitOne(300000)
try {
  # the capture of the real program sometimes gives no file: it is repeated (up to three times)
  for ($try = 0; $try -lt 3; $try++) {
    & "$Root\Tools\Verifica\176\Capture-OpenXcomScreen.ps1" -Root $Data -Out "$Out\real" -SeedFolder "$Out\seed" -Steps $real | Out-Null
    # a file that exists is not enough: the capture can leave an empty or truncated PNG
    $missing = @($Screens | Where-Object { -not (Test-ValidPng "$Out\real\$($_.Split('=')[0].TrimStart('+')).png") })
    if ($missing.Count -eq 0) { break }
  }
}
finally { if ($got) { $m.ReleaseMutex() } }
foreach ($s in $Screens) {
  $n = $s.Split('=')[0].TrimStart('+')
  Write-Output "== $n"
  & "$Root\Tools\Verifica\176\Compare-Png.ps1" -A "$Out\real\$n.png" -B "$Out\delphi\$n.png" 2>&1 | Select-Object -First 4
}

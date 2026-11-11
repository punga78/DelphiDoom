<#
  Prepara un salvataggio in cui il Triton della prima base, con sei soldati a bordo, e' gia' sul bersaglio di una
  missione: al primo passo del tempo il geoscape apre ConfirmLandingState. Parte da
  Tests\Data\XcomSave\variants\save02_dogfight.sav (fatto a mano, nessun dato del gioco) e mette nomi veri di TFTD
  al posto delle razze finte.

  Uso: Make-XcomMissionSave.ps1 -Root <worktree> -Out <file.sav> -Kind crash|landed|site|alienbase|defense|final
         [-Deployment STR_PORT_TERROR] [-Race STR_AQUATOID] [-Name "Mission"]

  -Kind crash|landed  l'UFO del salvataggio a terra (stato 2 o 1), il Triton sopra
        site          un sito di missione (-Deployment: STR_PORT_TERROR, STR_CARGO_SHIP_P1, STR_ARTIFACT_SITE_P1...)
        alienbase     la base aliena numero 2 (scoperta)
        defense       un UFO di ritorsione a un passo dalla base (BaseDefenseState)
        final         solo i soldati sul Triton (per ConfirmCydoniaState: il Triton non e' un velivolo "spacecraft",
                      serve -Craft STR_LEVIATHAN)
#>
param(
  [Parameter(Mandatory = $true)][string]$Root,
  [Parameter(Mandatory = $true)][string]$Out,
  [Parameter(Mandatory = $true)][ValidateSet('crash', 'landed', 'site', 'alienbase', 'defense', 'final')][string]$Kind,
  [string]$Deployment = 'STR_PORT_TERROR',
  [string]$Race = 'STR_AQUATOID',
  [string]$Craft = 'STR_TRITON',
  [string]$Name = 'Mission',
  [int]$Soldiers = 6,
  # the transport starts this far (radians of longitude) from the target and flies there
  [double]$Away = 0
)
$ErrorActionPreference = 'Stop'
$t = [IO.File]::ReadAllText("$Root\Tests\Data\XcomSave\variants\save02_dogfight.sav").Replace("`r`n", "`n")
$t = $t.Replace('name: ""', "name: `"$Name`"").Replace('  - "xcom2 ver: 1.0"', '  - xcom2')
$t = [regex]::Replace($t, 'STR_RACE_\d|STR_SOMETHING_\d', $Race)

switch ($Kind) {
  'crash' { $lon = '0.80000000000000004'; $lat = '0.20000000000000001'; $destType = 'STR_UFO'; $destId = 1 }
  'landed' { $lon = '0.80000000000000004'; $lat = '0.20000000000000001'; $destType = 'STR_UFO'; $destId = 1 }
  'site' { $lon = '0.90000000000000002'; $lat = '0.29999999999999999'; $destType = 'STR_MISSION_SITE'; $destId = 1 }
  'alienbase' { $lon = '2'; $lat = '0.29999999999999999'; $destType = 'STR_ALIEN_BASE'; $destId = 2 }
  default { $lon = '0.69999999999999996'; $lat = '0.20000000000000001'; $destType = ''; $destId = 0 }
}

# the interceptor that follows the UFO stays home
$t = $t.Replace("        lat: 0.20000000000000001`n        dest:`n          lon: 0.80000000000000004`n          lat: 0.20000000000000001`n          type: STR_UFO`n          id: 1`n        id: 1`n", "        id: 1`n")
$t = $t.Replace("        items:`n          {}`n        status: STR_OUT`n", "        items:`n          {}`n")
$t = [regex]::Replace($t, "(?m)^      - lon: 0\.80000000000000004\n        lat: 0\.20000000000000001\n        id: 1\n(?=        speedLon: 0\n        speedLat: 0\n        speedRadian: 0\n        speed: 0\n        type: STR_BARRACUDA)", "      - lon: 0.69999999999999996`n        lat: 0.20000000000000001`n        id: 1`n")

# the soldiers board the transport
$craftRef = "        craft:`n          lon: $lon`n          lat: $lat`n          type: $Craft`n          id: 1`n"
$count = 0
$t = [regex]::Replace($t, '(?m)^        armor: STR_NONE_UC\n', {
    param($m)
    $script:count++
    if ($script:count -le $Soldiers) { $m.Value + $craftRef } else { $m.Value }
  })

# the transport: on the target, out, with fuel
$old = "      - lon: 0.69999999999999996`n        lat: 0.20000000000000001`n        id: 1`n        speedLon: 0`n        speedLat: 0`n        speedRadian: 0`n        speed: 0`n        type: STR_TRITON`n        fuel: 12`n        damage: 61`n"
if (-not $t.Contains($old)) { throw 'The transport of the save was not found' }
$startLon = if ($Away -ne 0) { ([double]::Parse($lon, [Globalization.CultureInfo]::InvariantCulture) - $Away).ToString('R', [Globalization.CultureInfo]::InvariantCulture) } else { $lon }
$speed = if ($Away -ne 0) { 1000 } else { 0 }
$new = "      - lon: $startLon`n        lat: $lat`n"
if ($destType -ne '') { $new += "        dest:`n          lon: $lon`n          lat: $lat`n          type: $destType`n          id: $destId`n" }
$new += "        id: 1`n        speedLon: 0`n        speedLat: 0`n        speedRadian: 0`n        speed: $speed`n        type: $Craft`n        fuel: 1000`n        damage: 0`n"
if ($destType -ne '') { $new += "        status: STR_OUT`n" }
$t = $t.Replace($old, $new)
if ($Craft -ne 'STR_TRITON') { $t = $t.Replace("  STR_TRITON: 2`n", "  STR_TRITON: 2`n  ${Craft}: 2`n") }
$ufoOld = "    speed: 1500`n    type: STR_SURVEY_SHIP`n    damage: 0`n    altitude: STR_VERY_LOW`n    direction: STR_EAST`n    status: 0`n"
if (-not $t.Contains($ufoOld)) { throw 'The UFO of the save was not found' }
switch ($Kind) {
  'crash' {
    $t = $t.Replace($ufoOld, "    speed: 0`n    type: STR_SURVEY_SHIP`n    crashId: 1`n    damage: 30`n    altitude: STR_GROUND`n    direction: STR_EAST`n    status: 2`n    secondsRemaining: 200000`n")
    $t = $t.Replace("  STR_BARRACUDA: 3`n", "  STR_BARRACUDA: 3`n  STR_CRASH_SITE: 2`n")
  }
  'landed' {
    $t = $t.Replace($ufoOld, "    speed: 0`n    type: STR_SURVEY_SHIP`n    landId: 1`n    damage: 0`n    altitude: STR_GROUND`n    direction: STR_EAST`n    status: 1`n    secondsRemaining: 200000`n")
    $t = $t.Replace("  STR_BARRACUDA: 3`n", "  STR_BARRACUDA: 3`n  STR_LANDING_SITE: 2`n")
  }
  'site' {
    $mission = if ($Deployment -like 'STR_ARTIFACT*') { 'STR_ALIEN_ARTIFACT' } elseif ($Deployment -like '*SHIP*') { 'STR_ALIEN_SHIP_ATTACK' } else { 'STR_ALIEN_SURFACE_ATTACK' }
    $site = "missionSites:`n  - lon: $lon`n    lat: $lat`n    id: 1`n    type: $mission`n    deployment: $Deployment`n    texture: -1`n    secondsRemaining: 200000`n    race: $Race`n    detected: true`n"
    $t = $t.Replace("alienMissions:`n", $site + "alienMissions:`n")
    $marker = if ($Deployment -like 'STR_ARTIFACT*') { 'STR_ARTIFACT_SITE' } else { 'STR_TERROR_SITE' }
    $t = $t.Replace("  STR_BARRACUDA: 3`n", "  STR_BARRACUDA: 3`n  ${marker}: 2`n")
  }
  'defense' {
    # the UFO of a retaliation one step away from the base, on its assault run
    $t = $t.Replace("  - lon: 0.80000000000000004`n    lat: 0.20000000000000001`n    id: 1`n    speedLon: 0`n    speedLat: 0`n    speedRadian: 0`n    speed: 1500`n    type: STR_SURVEY_SHIP",
      "  - lon: 0.70009999999999994`n    lat: 0.20000000000000001`n    dest:`n      lon: 0.69999999999999996`n      lat: 0.20000000000000001`n      type: STR_BASE`n      id: 0`n    id: 1`n    speedLon: 0`n    speedLat: 0`n    speedRadian: 0`n    speed: 1500`n    type: STR_BATTLESHIP")
    $t = $t.Replace("    mission: 1`n    trajectory: P0`n    trajectoryPoint: 1`n", "    mission: 1`n    trajectory: __RETALIATION_ASSAULT_RUN`n    trajectoryPoint: 0`n")
    $t = $t.Replace("  - type: STR_ALIEN_RESOURCE_RAID`n    region: STR_NORTH_ATLANTIC", "  - type: STR_ALIEN_RETALIATION`n    region: STR_NORTH_ATLANTIC")
  }
}
New-Item -ItemType Directory -Force (Split-Path $Out) | Out-Null
[IO.File]::WriteAllText($Out, $t)
Write-Output "$Out ($Kind)"

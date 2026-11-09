# Rewrites Tests\Data\XcomMod\tftd.*.golden.txt: builds modload.exe (build3.cmd: the real OpenXcom objects) and runs
# the real Mod::loadAll on the mods of the TFTD nightly (Reference\_dati\xcom_tftd\openxcom).
# usage: .\regen-real.ps1 [-Work <folder>]   (Work: where obj.a and the exe go; default: %TEMP%\modload)
param([string]$Work = (Join-Path $env:TEMP 'modload'))
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = (Resolve-Path (Join-Path $here '..\..\..\..')).Path
$data = 'C:\Progetti\DelphiDoom\Reference\_dati\xcom_tftd\openxcom'
$golden = Join-Path $root 'Tests\Data\XcomMod'
New-Item -ItemType Directory -Force $Work | Out-Null
& cmd.exe /c "`"$here\build3.cmd`" $Work"
if (-not (Test-Path "$Work\modload.exe")) { throw 'build failed' }
Copy-Item 'C:\Progetti\DelphiDoom\Reference\_dati\openxcom_build\build\bin\*.dll' $Work -ErrorAction SilentlyContinue
# first run: only xcom2; second run: xcom2 and the TFTD mods that work on it (delete and overwrite of rules)
$cfg = Get-Content 'C:\Progetti\DelphiDoom\Reference\_dati\xcom_tftd\openxcom_user\options.cfg' -Raw
$extra = 'Aliens_Pick_Up_Weapons_TFTD', 'Limit_Craft_Item_Capacities_TFTD', 'XcomUtil_Fighter_Transports_TFTD',
  'XcomUtil_Triton_Weapon_Slot', 'XcomUtil_Starting_Improved_Base_TFTD', 'XcomUtil_Infinite_Gauss', 'XCOM_Damage',
  'Demigod_Difficulty_TFTD', 'UFOextender_Gun_Melee_TFTD', 'XcomUtil_No_Psionics_TFTD', 'StrategyCore_Swap_Small_USOs_TFTD'
$runs = @(, @('user1', 'tftd.xcom2.golden.txt', $cfg))
foreach ($m in $extra) { $cfg = $cfg -replace "active: false(\r?\n\s+id: $m\r?\n)", 'active: true$1' }
$runs += , @('user2', 'tftd.mods.golden.txt', $cfg)
foreach ($r in $runs) {
  $user = Join-Path $Work $r[0]
  New-Item -ItemType Directory -Force $user | Out-Null
  Set-Content (Join-Path $user 'options.cfg') $r[2] -NoNewline
  $p = Start-Process -FilePath "$Work\modload.exe" -ArgumentList $data, $user, (Join-Path $golden $r[1]) -Wait -PassThru -NoNewWindow
  if ($p.ExitCode -ne 0) { throw "modload failed for $($r[1])" }
}

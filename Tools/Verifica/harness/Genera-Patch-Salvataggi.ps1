# TEMPORARY HARNESS: writes hook-<gioco>-save.patch (Doom, Heretic, Strife, Hexen) starting from a clean tree.
# The patch touches only <Gioco>32.dpr and <Gioco>\g_game.pas and applies on master and on 31ee71e3.
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
Set-Location $root
foreach ($game in 'Doom', 'Heretic', 'Strife', 'Hexen') {
  & (Join-Path $PSScriptRoot 'Prepara-Patch.ps1') -Game $game -Variant S
  $out = Join-Path $PSScriptRoot "hook-$($game.ToLower())-save.patch"
  cmd /c "git diff -- ${game}32.dpr $game\g_game.pas > `"$out`""
  git checkout -- "${game}32.dpr" "$game\g_game.pas"
  Write-Host "$out : $((Get-Item $out).Length) bytes"
}

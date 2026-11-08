# TEMPORARY HARNESS: writes the six patches of this folder (hook-<gioco>-all.patch, hook-<gioco>-plane.patch)
# starting from a clean tree (the Tools\ folder is not touched). Needs no arguments.
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
Set-Location $root
foreach ($game in 'Heretic', 'Strife', 'Hexen') {
  foreach ($variant in 'H', 'P') {
    & (Join-Path $PSScriptRoot 'Prepara-Patch.ps1') -Game $game -Variant $variant
    if ($variant -eq 'H') { $name = "hook-$($game.ToLower())-all.patch" } else { $name = "hook-$($game.ToLower())-plane.patch" }
    $out = Join-Path $PSScriptRoot $name
    # cmd redirection: the bytes of git diff are not re-encoded
    cmd /c "git diff -- Base Heretic Strife Hexen Heretic32.dpr Strife32.dpr Hexen32.dpr > `"$out`""
    git checkout -- Base Heretic Strife Hexen Heretic32.dpr Strife32.dpr Hexen32.dpr
    Write-Host "$name : $((Get-Item $out).Length) bytes"
  }
}

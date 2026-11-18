<#
  Issue #247 (ondata 12): lancia Converti-Renderer.ps1 nei due modi (Interface e poi Impl) su una unit di IdTech1\Base e
  fa un commit. Uso: Converti-Unita.ps1 -Unit r_plane -Class TRendererPlane [-Names a,b] [-Dir IdTech1\Base]
#>
param(
  [Parameter(Mandatory = $true)][string]$Unit,
  [Parameter(Mandatory = $true)][string]$Class,
  [string]$Names = '',
  [string]$Dir = 'IdTech1/Base',
  [switch]$NoCommit
)
$S = Join-Path $PSScriptRoot 'Converti-Renderer.ps1'
$common = @('-NoProfile', '-File', $S, '-Unit', "$Dir/$Unit.pas")
$namesArg = @(); if ($Names -ne '') { $namesArg = @('-Names', $Names) }
Write-Output "== $Unit"
& powershell @($common + @('-Class', $Class, '-Mode', 'Interface', '-CallerDirs', 'IdTech1,Games,Tests') + $namesArg) 2>&1 | Select-Object -Last 3
& powershell @($common + @('-Class', ($Class + 'Local'), '-Mode', 'Impl') + $namesArg) 2>&1 | Select-Object -Last 2
if (-not $NoCommit) {
  git add -A 2>$null
  git commit -qm "refs #247: $Unit in classi" 2>$null
}

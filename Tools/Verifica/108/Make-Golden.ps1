# Issue #108: runs the harness (Build-Harness.ps1) on the synthetic maps and writes, in Tests\Data\Collision\Doom3,
#   <map>.cm                    the collision models that the REAL Doom 3 code builds and writes for the map
#   <map>.queries.golden.txt    translations, rotations, position tests and contacts on those models
# Usage: Tools\Verifica\108\Make-Golden.ps1 [-Work <scratch folder of Build-Harness>] [-Count <queries per kind>]
param(
	[string]$Work = (Join-Path $env:TEMP 'dd108harness'),
	[int]$Count = 150
)
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$data = (Resolve-Path (Join-Path $here '..\..\..\Tests\Data\Collision\Doom3')).Path
$exe = Join-Path $Work 'harness.exe'
if (-not (Test-Path $exe)) { throw "build the harness first: $exe" }
$seed = 1
foreach ($name in 'room', 'tiles') {
	$map = Join-Path $data "$name.map"
	Remove-Item -ErrorAction SilentlyContinue (Join-Path $data "$name.cm")
	# the harness writes its warnings to stderr; PowerShell 5.1 would turn them into errors
	cmd /c "`"$exe`" `"$map`" `"$(Join-Path $data "$name.queries.golden.txt")`" $seed $Count 2>nul"
	if ($LASTEXITCODE -ne 0) { throw "harness failed on $name ($LASTEXITCODE)" }
	$seed++
	Write-Host "$name done"
}

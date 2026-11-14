# Issue #118: the answers of the REAL Quake III collision code (cm_load.c, cm_test.c, cm_trace.c, cm_patch.c,
# cm_polylib.c, built by build.sh) on the maps of OpenArena, for the test TTestQ3OpenArena.
#
# For every .bsp of pak1-maps.pk3, pak6-patch085.pk3 and pak6-patch088.pk3 it runs `cmgen runmap` (the counts of
# the loaded data, one hash of the collision geometry of every patch and 300 traces and position tests spread over the
# world) and writes Tests\Data\Collision\OpenArena\<map>.golden.txt. Nothing of OpenArena is committed: that folder is
# ignored by git; the test is ignored when it is empty.
#
# Usage: Tools\Verifica\118\Make-OpenArena-Golden.ps1 -Cmgen <cmgen.exe built by build.sh> [-BaseOa <baseoa folder>]
param(
	[Parameter(Mandatory = $true)][string]$Cmgen,
	[string]$BaseOa = 'C:\Progetti\DelphiDoom\Reference\openarena\openarena-0.8.8\baseoa',
	[int]$Count = 300
)
Add-Type -AssemblyName System.IO.Compression.FileSystem
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$out = Join-Path $here '..\..\..\Tests\Data\Collision\OpenArena'
New-Item -ItemType Directory -Force $out | Out-Null
$out = (Resolve-Path $out).Path
$tmp = Join-Path $env:TEMP 'dd118oa'
New-Item -ItemType Directory -Force $tmp | Out-Null
$done = @{}
# the patches replace the maps of the first pak: the last one wins, so the paks are read in the reverse order
foreach ($pak in 'pak6-patch088.pk3', 'pak6-patch085.pk3', 'pak1-maps.pk3') {
	$path = Join-Path $BaseOa $pak
	if (-not (Test-Path $path)) { continue }
	$zip = [IO.Compression.ZipFile]::OpenRead($path)
	try {
		foreach ($entry in $zip.Entries) {
			if ($entry.FullName -notlike '*.bsp') { continue }
			$name = [IO.Path]::GetFileNameWithoutExtension($entry.FullName)
			if ($done.ContainsKey($name)) { continue }
			$done[$name] = $true
			$bsp = Join-Path $tmp "$name.bsp"
			[IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $bsp, $true)
			$seed = 1000 + $done.Count
			$golden = Join-Path $out "$name.golden.txt"
			cmd /c "`"$Cmgen`" runmap `"$bsp`" $seed $Count > `"$golden`" 2>nul"
			if ($LASTEXITCODE -ne 0) { Write-Warning "$name : cmgen failed ($LASTEXITCODE)"; Remove-Item $golden; continue }
			Write-Host "$name done"
		}
	} finally {
		$zip.Dispose()
	}
}

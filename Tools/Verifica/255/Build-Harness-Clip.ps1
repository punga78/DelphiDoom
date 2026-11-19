# Issue #255 (Doom 3, phase 3, ondata 13: idClip): builds and runs the fifth parity harness against the REAL Doom 3 sources.
#
# Reads Reference\doom3\neo (never copies anything into the repository). It reuses the build of Tools\Verifica\108 (the real idlib,
# framework\File.cpp and neo\cm, patched in the scratch COPY as that script says) and adds, cut out of the source at build time:
#   the REAL Clip.h and the REAL Clip.cpp, without idClipModel::Save/Restore, SaveTraceModels, RestoreTraceModels, PrintStatistics and the
#   debug drawing (they need the save game and the renderer); the render world is a stub that finds nothing
#   the REAL bodies of idEntity::TouchTriggers and of idPhysics_Static (GetClipModel, GetNumClipModels, GetAbsBounds, SetClipModel, LinkClip,
#   ClipContents)
# and compiles them with harness_clip.cpp (fakes: the entities, gameLocal.Printf/Warning/Error, the render world).
# The world is the collision model "worldMap" of Tests\Data\Collision\Doom3\room.map (a synthetic room written for the repository; a COPY
# of the map is used, so the .cm file that the real code writes does not touch the repository).
# Scenarios Tests\Data\D3Clip\scenarios\<name>.scn give Tests\Data\D3Clip\golden\<name>.golden.txt.
#
# Usage: Tools\Verifica\255\Build-Harness-Clip.ps1 [-Reference <path>] [-Work <scratch>] [-Only <scenario>] [-NoBuild]
param(
	[string]$Reference = 'C:\Progetti\DelphiDoom\Reference',
	[string]$Work = (Join-Path $env:TEMP 'dd255clip'),
	[string]$Only = '',
	[switch]$NoBuild
)

$ErrorActionPreference = 'Continue'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = (Resolve-Path (Join-Path $here '..\..\..')).Path
$neo = Join-Path $Reference 'doom3\neo'
$data = Join-Path $root 'Tests\Data\D3Clip'
$src = Join-Path $env:TEMP 'dd255clipsrc'

function Read-Text($path) { [IO.File]::ReadAllText($path, [Text.Encoding]::GetEncoding(1252)).Replace("`r`n", "`n") }
function Write-Text($path, $text) { [IO.File]::WriteAllText($path, $text, [Text.Encoding]::GetEncoding(1252)) }
function Remove-Member($text, $class, $name) {
	$m = [regex]::Match($text, "(?m)^(?:[A-Za-z_][^\n]*?)?$([regex]::Escape($class))::$([regex]::Escape($name))\([^\n]*\{[ \t]*\n.*?\n\}\n", 'Singleline')
	if (-not $m.Success) { throw "function not found: ${class}::${name}" }
	return $text.Remove($m.Index, $m.Length)
}
function Get-Member($text, $class, $name) {
	$m = [regex]::Match($text, "(?m)^(?:[A-Za-z_][^\n]*?)?$([regex]::Escape($class))::$([regex]::Escape($name))\([^\n]*\{[ \t]*\n.*?\n\}\n", 'Singleline')
	if (-not $m.Success) { throw "function not found: ${class}::${name}" }
	return $m.Value
}

$exe = Join-Path $Work 'harness.exe'
if (-not $NoBuild) {
	if (Test-Path $src) { Remove-Item -Recurse -Force $src }
	New-Item -ItemType Directory -Force $src | Out-Null
	Copy-Item (Join-Path $root 'Tools\Verifica\108\*') $src -Recurse -Force

	$clip = Read-Text (Join-Path $neo 'game\physics\Clip.cpp')
	$clip = $clip.Replace('#include "../Game_local.h"', '').Replace('#include "../../idlib/precompiled.h"', '').Replace('#pragma hdrstop', '')
	$clipH = Read-Text (Join-Path $neo 'game\physics\Clip.h')
	foreach ($n in 'Save', 'Restore', 'SaveTraceModels', 'RestoreTraceModels') { $clip = Remove-Member $clip 'idClipModel' $n }
	foreach ($n in 'PrintStatistics', 'DrawClipModels', 'DrawModelContactFeature') { $clip = Remove-Member $clip 'idClip' $n }
	$clip = $clip.Replace('gameRenderWorld', 'harnessRenderWorld')

	$en = Read-Text (Join-Path $neo 'game\Entity.cpp')
	$ps = Read-Text (Join-Path $neo 'game\physics\Physics_Static.cpp')
	$sb = New-Object System.Text.StringBuilder
	[void]$sb.Append((Get-Member $en 'idEntity' 'TouchTriggers')).Append("`n")
	foreach ($n in 'GetClipModel', 'GetNumClipModels', 'GetAbsBounds', 'SetClipModel', 'LinkClip', 'ClipContents') {
		[void]$sb.Append((Get-Member $ps 'idPhysics_Static' $n)).Append("`n")
	}

	$main = Read-Text (Join-Path $here 'harness_clip.cpp')
	$main = $main.Replace('@@CLIP_H@@', $clipH).Replace('@@CLIP_REAL@@', $clip).Replace('@@ENTITY_REAL@@', $sb.ToString())
	Write-Text (Join-Path $src 'main_clip_full.cpp') $main

	# the C++ library headers of bcc32c need this define with the options of the 108 build
	$b = Read-Text (Join-Path $src 'Build-Harness.ps1')
	Write-Text (Join-Path $src 'Build-Harness.ps1') $b.Replace('-c -w -std=c++11 -I. "harness\$Main"', '-c -w -D_HAS_NOEXCEPT_FUNCTION_TYPE=0 -I. "harness\$Main"')
	& (Join-Path $src 'Build-Harness.ps1') -Reference $Reference -Work $Work -Main 'main_clip_full.cpp'
	if (-not (Test-Path $exe)) { throw 'harness not built' }
	New-Item -ItemType Directory -Force (Join-Path $Work 'map') | Out-Null
	Copy-Item (Join-Path $root 'Tests\Data\Collision\Doom3\room.map') (Join-Path $Work 'map\room.map') -Force
}

$env:HARNESS_MAPDIR = Join-Path $Work 'map'
New-Item -ItemType Directory -Force (Join-Path $data 'golden') | Out-Null
$total = 0
foreach ($scn in Get-ChildItem (Join-Path $data 'scenarios\*.scn') | Sort-Object Name) {
	$name = [IO.Path]::GetFileNameWithoutExtension($scn.Name)
	if ($Only -and ($name -ne $Only)) { continue }
	$golden = Join-Path $data "golden\$name.golden.txt"
	& $exe $scn.FullName $golden
	if ($LASTEXITCODE -ne 0) { Write-Host "FAILED $name (exit $LASTEXITCODE)"; continue }
	$n = (Get-Content $golden | Measure-Object -Line).Lines
	$total += $n
	Write-Host ("{0,-28} {1,6} lines" -f $name, $n)
}
Write-Host "Total golden lines: $total"

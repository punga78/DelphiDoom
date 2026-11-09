# TEMPORARY HARNESS (issue #177, slice 2): runs GLDoom_GL_OLD.exe and GLDoom_GL_NEW.exe (Compila.ps1) with the
# PK3 of Tests\Data\Pk3 (a KVX, a VOX and a DDVOX voxel) and compares the lines "TVoxelMeshOptimizer...: Mesh reduced
# from X to Y quads" that the engine prints when it builds the display lists of the voxels: the same numbers mean the
# same optimization. Prints UGUALE or DIVERSO; leaves the logs in harness_out\voxel.
#
#   .\Tools\Verifica\opengl\Prova-Voxel.ps1 [-Seconds 40]  (the pass count is the one of the .ini: 0 = fast optimizer; the full one is covered by the unit tests)
param([int[]]$Passes = @(0), [int]$Seconds = 40)
$ErrorActionPreference = 'Stop'
$here = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$common = 'C:\Progetti\DelphiDoom'
$runner = Join-Path $common 'Tools\Esegui-gioco.ps1'
$bin = Join-Path $common 'bin\Doom'
$pk3 = Join-Path $here 'Tests\Data\Pk3\zpktest.pk3'
$out = Join-Path $here 'harness_out\voxel'
New-Item -ItemType Directory -Force $out | Out-Null
$results = @{}
foreach ($pass in $Passes) {
  foreach ($version in 'OLD', 'NEW') {
    $copy = Join-Path $bin "GLDoom32_V$version.exe"
    Copy-Item (Join-Path $here "harness_out\GLDoom_GL_$version.exe") $copy -Force
    try {
      & powershell -NoProfile -File $runner -Exe $copy -Arguments "-iwad DOOM1.WAD -warp 1 1 -devparm -nomusic -nosound -nomouse -windowed -file `"$pk3`"" -WorkDir $bin -Seconds $Seconds
    }
    finally { Remove-Item $copy -Force -ErrorAction SilentlyContinue }
    $log = Join-Path $bin "DATA\LOGS\GLDoom32_V${version}_stdout.txt"
    if (-not (Test-Path $log)) { $log = Join-Path $bin "DATA\LOGS\GLDoom32_stdout.txt" }
    $lines = @(Select-String -Path $log -Pattern 'TVoxelMeshOptimizer' | ForEach-Object { $_.Line })
    Set-Content (Join-Path $out "pass${pass}_$version.txt") $lines
    $results["$pass$version"] = $lines
  }
  $same = (($results["${pass}OLD"] -join "`n") -ceq ($results["${pass}NEW"] -join "`n"))
  Write-Host "passi=$pass : righe vecchio $($results["${pass}OLD"].Count), nuovo $($results["${pass}NEW"].Count) : $(if ($same) { 'UGUALE' } else { 'DIVERSO' })"
}

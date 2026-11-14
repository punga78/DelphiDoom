# Issue #122: builds the routing tool of Quake III (build.sh with the gcc of w64devkit) and writes the golden files
#   Tests\Data\Aas\route_<map>.golden.txt, route_<map>_small.golden.txt (maps of OpenArena, if Reference\openarena has them;
#                                                                         _small: the memory is short, caches are dropped)
# Nothing of a game is copied into the repository except these lines of numbers: the .aas files are read from
# Reference\openarena (not in git) and the work is done in $Dir.
param(
  [string]$Repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')).Path,
  [string]$Root = 'C:/Progetti/DelphiDoom',
  [string]$Dir = 'C:/harness/q3route',
  [string[]]$Maps = @('fan', 'oa_bases3', 'blitzkrieg3'),
  [int]$SmallLimit = 1048576 + 20000
)
$ErrorActionPreference = 'Continue'
$env:DELPHIDOOM_ROOT = $Root
$sh = "$Root\Reference\_dati\_strumenti\w64devkit\w64devkit\bin\sh.exe"
$data = Join-Path $Repo 'Tests\Data\Aas'
New-Item -ItemType Directory -Force "$Dir/aas" | Out-Null
& $sh "$Repo\Tools\Verifica\122\route\build.sh" $Dir


# the maps of OpenArena, from the paks
Add-Type -AssemblyName System.IO.Compression.FileSystem
$baseoa = "$Root\Reference\openarena\openarena-0.8.8\baseoa"
foreach ($p in 'pak6-misc.pk3', 'pak6-patch085.pk3', 'pak6-patch088.pk3') {
  if (-not (Test-Path "$baseoa\$p")) { continue }
  $z = [System.IO.Compression.ZipFile]::OpenRead("$baseoa\$p")
  foreach ($e in $z.Entries) {
    if ($e.FullName.EndsWith('.aas')) { [System.IO.Compression.ZipFileExtensions]::ExtractToFile($e, (Join-Path "$Dir\aas" ([IO.Path]::GetFileName($e.FullName))), $true) }
  }
  $z.Dispose()
}
function Golden($name, $file, $limit) {
  $out = Join-Path $data $name
  & "$Dir\routegen.exe" $limit $file | Set-Content $out -Encoding ascii
  Write-Host "$name : $((Get-Content $out).Count) lines"
}

foreach ($m in $Maps) {
  if (-not (Test-Path "$Dir\aas\$m.aas")) { Write-Host "$m.aas is missing"; continue }
  Golden "route_$m.golden.txt" "$Dir\aas\$m.aas" 0
  Golden "route_${m}_small.golden.txt" "$Dir\aas\$m.aas" $SmallLimit
}

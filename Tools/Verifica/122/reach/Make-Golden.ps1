# Issue #122: builds the tool of the reachabilities of Quake III (build.sh with the gcc of w64devkit) and writes the golden files
#   Tests\Data\Aas\reach_<map>.golden.txt          (digest: a hash per area and the lines of the first area of each travel type;
#                                                    the 3 maps of the repository)
#   <Dir>\goldens\reach_<map>.golden.txt           (full: every reachability; every map of OpenArena; DELPHIDOOM_REACH_GOLDENS)
# Nothing of a game is copied into the repository except these lines of numbers: the .aas and .bsp files are read from
# Reference\openarena (not in git) and the work is done in $Dir. The grapple reachabilities are calculated (grapplereach 1).
param(
  [string]$Repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')).Path,
  [string]$Root = 'C:/Progetti/DelphiDoom',
  [string]$Dir = 'C:/harness/q3reach',
  [string[]]$Maps = @('fan', 'oa_bases5', 'oa_dm4'),
  [switch]$All
)
$ErrorActionPreference = 'Continue'
$env:DELPHIDOOM_ROOT = $Root
$sh = "$Root\Reference\_dati\_strumenti\w64devkit\w64devkit\bin\sh.exe"
$data = Join-Path $Repo 'Tests\Data\Aas'
New-Item -ItemType Directory -Force "$Dir/aas", "$Dir/bsp", "$Dir/goldens" | Out-Null
& $sh "$Repo\Tools\Verifica\122\reach\build.sh" $Dir

# the maps of OpenArena, from the paks (the later paks replace the earlier ones)
Add-Type -AssemblyName System.IO.Compression.FileSystem
$baseoa = "$Root\Reference\openarena\openarena-0.8.8\baseoa"
foreach ($p in 'pak1-maps.pk3', 'pak6-misc.pk3', 'pak6-patch085.pk3', 'pak6-patch088.pk3') {
  if (-not (Test-Path "$baseoa\$p")) { continue }
  $z = [System.IO.Compression.ZipFile]::OpenRead("$baseoa\$p")
  foreach ($e in $z.Entries) {
    if ($e.FullName.EndsWith('.aas')) { [System.IO.Compression.ZipFileExtensions]::ExtractToFile($e, (Join-Path "$Dir\aas" ([IO.Path]::GetFileName($e.FullName))), $true) }
    if ($e.FullName -like 'maps/*.bsp') { [System.IO.Compression.ZipFileExtensions]::ExtractToFile($e, (Join-Path "$Dir\bsp" ([IO.Path]::GetFileName($e.FullName))), $true) }
  }
  $z.Dispose()
}
function Run($mode, $map, $out) {
  $aas = "$Dir\aas\$map.aas"; $bsp = "$Dir\bsp\$map.bsp"
  if (-not (Test-Path $aas)) { Write-Host "$map.aas is missing"; return }
  & "$Dir\reachgen.exe" $mode 1 $aas $bsp | Set-Content $out -Encoding ascii
  Write-Host "$out : $((Get-Content $out).Count) lines"
}
foreach ($m in $Maps) { Run 'digest' $m (Join-Path $data "reach_$m.golden.txt") }
if ($All) {
  foreach ($f in Get-ChildItem "$Dir\aas" -Filter *.aas) {
    $m = [IO.Path]::GetFileNameWithoutExtension($f.Name)
    Run 'full' $m "$Dir\goldens\reach_$m.golden.txt"
  }
}

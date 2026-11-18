# Writes Tests\Data\Q3Render\image.golden.txt (issue #254, renderer phase R0): the answers of the real LoadTGA and
# LoadJPG of Quake III (imagegen.exe, Tools\Verifica\254\build-image.sh) for
#   1. the small files of the repository (Tests\Data\IdImages\tga, Tests\Data\Q3Render\tga, the baseline JPEGs
#      of Tests\Data\Jpeg\encoder-*-c3-*.jpg), line "tga|jpg <file> ok <w> <h> <hash>" or "... error <message>";
#   2. a deterministic selection of the images of OpenArena 0.8.8 (pak0.pk3 of baseoa, read only, nothing is
#      copied into the repository): every 3rd .jpg and every 12th .tga of the sorted names, extracted to a
#      temporary folder with the "/" of the path written as "__"; those lines have the prefix "oa " and the name of
#      the entry, and the test that checks them is skipped when OpenArena is not there.
# Usage: Make-Image-Golden.ps1 [-OpenArena <folder of openarena-0.8.8>] [-Work <temporary folder>]
param(
  [string]$OpenArena = 'C:\Progetti\DelphiDoom\Reference\openarena\openarena-0.8.8',
  [string]$Work = (Join-Path $env:TEMP 'q3img')
)
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$kit = 'C:\Progetti\DelphiDoom\Reference\_dati\_strumenti\w64devkit\w64devkit\bin'
$out = Join-Path $repo 'Tests\Data\Q3Render\image.golden.txt'
$env:PATH = "$kit;$env:PATH"
$env:DELPHIDOOM_ROOT = 'C:/Progetti/DelphiDoom'
$shell = (Join-Path $kit 'sh.exe')

# 1. the repository files (the grayscale JPEGs of the encoder cases are left out: with a grayscale JPEG the real
#    LoadJPG writes 4 bytes per pixel into a 1 byte buffer and hangs; t2_trunc: the C reads past the file)
$files = @()
foreach ($f in (Get-ChildItem (Join-Path $repo 'Tests\Data\IdImages\tga\*.tga'), (Join-Path $repo 'Tests\Data\Q3Render\tga\*.tga') | Sort-Object Name)) {
  if ($f.Name -ne 't2_trunc.tga') { $files += ('tga:' + ($f.FullName -replace '\\', '/')) }
}
foreach ($f in (Get-ChildItem (Join-Path $repo 'Tests\Data\Jpeg\encoder-*-c3-*.jpg') | Sort-Object Name)) {
  $files += ('jpg:' + ($f.FullName -replace '\\', '/'))
}
$lines = & $shell (Join-Path $repo 'Tools\Verifica\254\build-image.sh') ($Work -replace '\\', '/') @files

# 2. OpenArena
Add-Type -AssemblyName System.IO.Compression.FileSystem
$pack = Join-Path $OpenArena 'baseoa\pak0.pk3'
$zip = [IO.Compression.ZipFile]::OpenRead($pack)
$oaFolder = Join-Path $Work 'oa'
New-Item -ItemType Directory -Force -Path $oaFolder | Out-Null
$names = @($zip.Entries | Where-Object { $_.FullName -notmatch '/$' } | ForEach-Object { $_.FullName })
[Array]::Sort($names, [StringComparer]::Ordinal)
$jpg = @($names | Where-Object { $_ -like '*.jpg' })
$tga = @($names | Where-Object { $_ -like '*.tga' })
$selected = @()
for ($i = 0; $i -lt $jpg.Count; $i += 3) { $selected += $jpg[$i] }
for ($i = 0; $i -lt $tga.Count; $i += 12) { $selected += $tga[$i] }
$arguments = @()
foreach ($name in $selected) {
  $flat = $name -replace '/', '__'
  $target = Join-Path $oaFolder $flat
  [IO.Compression.ZipFileExtensions]::ExtractToFile($zip.GetEntry($name), $target, $true)
  $kind = if ($name -like '*.jpg') { 'jpg' } else { 'tga' }
  $arguments += ($kind + ':' + ($target -replace '\\', '/'))
}
$zip.Dispose()
$exe = Join-Path $Work 'imagegen.exe'
# one process per file with a time limit: a grayscale JPEG makes the real LoadJPG loop or crash
$oaLines = @()
foreach ($argument in $arguments) {
  $info = New-Object System.Diagnostics.ProcessStartInfo
  $info.FileName = $exe
  $info.Arguments = '"' + $argument + '"'
  $info.RedirectStandardOutput = $true
  $info.UseShellExecute = $false
  $process = [System.Diagnostics.Process]::Start($info)
  $text = $process.StandardOutput.ReadToEndAsync()
  if ($process.WaitForExit(30000)) {
    $oaLines += ($text.Result -split "`r?`n" | Where-Object { $_ })
    if ($process.ExitCode -ne 0 -and -not $text.Result) {
      $oaLines += (($argument.Substring(0, 3)) + ' ' + (Split-Path $argument.Substring(4) -Leaf) + ' crash')
    }
  }
  else {
    $process.Kill()
    $oaLines += (($argument.Substring(0, 3)) + ' ' + (Split-Path $argument.Substring(4) -Leaf) + ' hang')
  }
}
$result = @()
foreach ($l in $lines) { if ($l -match '^(tga|jpg) ') { $result += $l } }
foreach ($l in $oaLines) {
  if ($l -match '^(tga|jpg) (\S+) (.*)$') {
    $entry = ($Matches[2] -replace '__', '/')
    $result += ('oa ' + $Matches[1] + ' ' + $entry + ' ' + $Matches[3])
  }
}
[IO.File]::WriteAllLines($out, $result)
Write-Host "$($result.Count) lines in $out"
Remove-Item -Recurse -Force $oaFolder

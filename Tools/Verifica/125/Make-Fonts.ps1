# Writes the three font files of Tests\Data\Gui\files\fonts: two valid .dat files of 20548 bytes
# (sizeof(fontInfo_t) of Quake III: 256 glyphs of 80 bytes + glyphScale + name[64]) with values from a
# fixed linear congruential generator, and one of 100 bytes (wrong length: RE_RegisterFont refuses it).
param([string]$Folder = (Join-Path $PSScriptRoot '..\..\..\Tests\Data\Gui\files\fonts'))
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force $Folder | Out-Null
function Make([int64]$seed, [string]$prefix, [string]$path) {
  $ms = New-Object IO.MemoryStream
  $bw = New-Object IO.BinaryWriter($ms)
  [int64]$x = $seed
  for ($i = 0; $i -lt 256; $i++) {
    foreach ($k in 1..7) { $x = ($x * 1664525 + 1013904223) % 4294967296; $bw.Write([int]($x % 200) - 20) }
    foreach ($k in 1..4) { $x = ($x * 1664525 + 1013904223) % 4294967296; $bw.Write([single](($x % 10000) / 10000.0)) }
    $bw.Write([int](1000 + $i))
    $name = ''
    if (($i -ge 32 -and $i -lt 127) -or $i -eq 255) { $name = "$prefix$i" }
    $bb = New-Object byte[] 32
    $nb = [Text.Encoding]::ASCII.GetBytes($name)
    [Array]::Copy($nb, $bb, $nb.Length)
    $bw.Write($bb)
  }
  $bw.Write([single]0.75)
  $bb = New-Object byte[] 64
  $nb = [Text.Encoding]::ASCII.GetBytes('stored/name')
  [Array]::Copy($nb, $bb, $nb.Length)
  $bw.Write($bb)
  $bw.Flush()
  [IO.File]::WriteAllBytes($path, $ms.ToArray())
}
Make 16 'gfx/f16_' (Join-Path $Folder 'fontImage_16.dat')
Make 12 'gfx/f12_' (Join-Path $Folder 'fontImage_12.dat')
[IO.File]::WriteAllBytes((Join-Path $Folder 'fontImage_24.dat'), [byte[]](1..100))

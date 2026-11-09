<#
  Estrae i file (e le sottocartelle) di un'immagine floppy FAT12 in una cartella nuova.
  Uso: powershell -NoProfile -File Extract-Fat12.ps1 -Image disk.img -Out <cartella>
  Non esegue nulla dell'immagine: legge solo byte.
#>
param([Parameter(Mandatory)][string]$Image, [Parameter(Mandatory)][string]$Out)
$ErrorActionPreference = 'Stop'
$b = [IO.File]::ReadAllBytes($Image)
$bps = [BitConverter]::ToUInt16($b, 11); $spc = $b[13]; $res = [BitConverter]::ToUInt16($b, 14)
$nfat = $b[16]; $rootN = [BitConverter]::ToUInt16($b, 17); $spf = [BitConverter]::ToUInt16($b, 22)
$fat = $res * $bps; $root = ($res + $nfat * $spf) * $bps
$data = $root + $rootN * 32; $cl = $spc * $bps
function Next($c) { $o = $fat + [int][Math]::Floor($c * 3 / 2); $v = [BitConverter]::ToUInt16($b, $o); if ($c % 2) { $v -shr 4 } else { $v -band 0xFFF } }
function Chain($c, $size, $isDir) {
  $ms = New-Object IO.MemoryStream
  while ($c -ge 2 -and $c -lt 0xFF8) { $ms.Write($b, $data + ($c - 2) * $cl, $cl); $c = Next $c }
  $a = $ms.ToArray(); if (-not $isDir -and $a.Length -gt $size) { $a = $a[0..($size - 1)] }
  , $a
}
function Walk($bytes, $path) {
  New-Item -ItemType Directory -Force $path | Out-Null
  for ($o = 0; $o + 32 -le $bytes.Length; $o += 32) {
    if ($bytes[$o] -eq 0) { break }; if ($bytes[$o] -eq 0xE5) { continue }
    $attr = $bytes[$o + 11]; if ($attr -eq 0x0F -or ($attr -band 0x08)) { continue }
    $n = ([Text.Encoding]::ASCII.GetString($bytes, $o, 8)).TrimEnd(); $e = ([Text.Encoding]::ASCII.GetString($bytes, $o + 8, 3)).TrimEnd()
    if ($n -eq '.' -or $n -eq '..') { continue }
    $name = if ($e) { "$n.$e" } else { $n }
    $c = [BitConverter]::ToUInt16($bytes, $o + 26); $sz = [BitConverter]::ToUInt32($bytes, $o + 28)
    if ($attr -band 0x10) { Walk (Chain $c 0 $true) (Join-Path $path $name) }
    else { $content = if ($sz -eq 0) { [byte[]]@() } else { Chain $c $sz $false }; [IO.File]::WriteAllBytes((Join-Path $path $name), $content) }
  }
}
Walk ([byte[]]$b[$root..($data - 1)]) $Out

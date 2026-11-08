<#
  Genera il PK3 di prova della issue #48 e i file sciolti da cui nasce.

  Tutti i dati sono sintetici e scritti qui (dominio pubblico / CC0): nessun asset di un gioco.
  Uso (dalla cartella Tests\Data\Pk3 o da qualsiasi altra):
    powershell -NoProfile -ExecutionPolicy Bypass -File Tests\Data\Pk3\Make-Pk3.ps1

  Scrive, accanto allo script:
    src\...            i file sciolti (le stesse voci del PK3, con gli stessi percorsi)
    zpktest.pk3        lo ZIP: textures\, flats\, voxels\, sounds\ e VOXELDEF
    zpkhires.wad       un PWAD con HI_START/HI_END, TX_START/TX_END e PK3ENTRY

  L'uscita e' deterministica (nessun orario, nessun numero casuale): rigenerarlo da' gli stessi byte,
  tranne PNG e JPEG che dipendono dall'encoder di System.Drawing della macchina.
#>
param(
  [string]$OutDir = $PSScriptRoot
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$src = Join-Path $OutDir 'src'
if (Test-Path -LiteralPath $src) { Remove-Item -LiteralPath $src -Recurse -Force }
foreach ($d in 'textures', 'flats', 'voxels', 'sounds') {
  $null = New-Item -ItemType Directory -Force -Path (Join-Path $src $d)
}

# ---------------------------------------------------------------------------------------------
# utilita'
# ---------------------------------------------------------------------------------------------
function New-Bytes { return ,(New-Object 'System.Collections.Generic.List[byte]') }

function Add-U16([System.Collections.Generic.List[byte]]$L, [int]$V) {
  $L.Add([byte]($V -band 255)); $L.Add([byte](($V -shr 8) -band 255))
}
function Add-U32([System.Collections.Generic.List[byte]]$L, [long]$V) {
  for ($i = 0; $i -lt 4; $i++) { $L.Add([byte](($V -shr (8 * $i)) -band 255)) }
}
function Add-U64([System.Collections.Generic.List[byte]]$L, [long]$V) {
  for ($i = 0; $i -lt 8; $i++) { $L.Add([byte](($V -shr (8 * $i)) -band 255)) }
}
function Add-Text([System.Collections.Generic.List[byte]]$L, [string]$S) {
  foreach ($c in $S.ToCharArray()) { $L.Add([byte][int]$c) }
}
function Save-Bytes([string]$Path, $Bytes) {
  [System.IO.File]::WriteAllBytes($Path, [byte[]]$Bytes.ToArray())
}

# il pixel di prova (x, y): ogni componente tra 32 e 221, mai nero
function Get-PixelRgb([int]$X, [int]$Y) {
  return @((32 + 3 * $X), (32 + 3 * $Y), (32 + 3 * ($X -bxor $Y)))
}
# l'indice di palette di prova per patch, flat e PCX (da 1 a 250)
function Get-PatchIndex([int]$X, [int]$Y) { return 1 + (($X * 3 + $Y * 5) % 250) }
function Get-FlatIndex([int]$X, [int]$Y) { return 1 + (($X * 7 + $Y * 11) % 250) }
function Get-PcxIndex([int]$X, [int]$Y) { return 1 + (($X + $Y * 4) % 250) }

$Size = 64

# ---------------------------------------------------------------------------------------------
# PNG e JPEG (System.Drawing), BMP e TGA a 24 bit scritti a mano
# ---------------------------------------------------------------------------------------------
function New-Bitmap32 {
  $bmp = New-Object System.Drawing.Bitmap($Size, $Size, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
  for ($y = 0; $y -lt $Size; $y++) {
    for ($x = 0; $x -lt $Size; $x++) {
      $c = Get-PixelRgb $x $y
      $bmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($c[0], $c[1], $c[2]))
    }
  }
  return $bmp
}

$bmp = New-Bitmap32
$bmp.Save((Join-Path $src 'textures\ZPKPNG.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Save((Join-Path $src 'flats\ZPKFLAT.png'), [System.Drawing.Imaging.ImageFormat]::Png)

# JPEG baseline con la qualita' massima (JFIF: e' cio' che il riconoscimento di w_pak cerca)
$codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
$params = New-Object System.Drawing.Imaging.EncoderParameters(1)
$params.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [long]100)
$bmp.Save((Join-Path $src 'textures\ZPKJPG.jpg'), $codec, $params)
$bmp.Dispose()

# BMP 24 bit, righe dal basso, BGR (64 * 3 = 192 byte per riga: nessun padding)
$b = New-Bytes
Add-Text $b 'BM'
Add-U32 $b (54 + $Size * $Size * 3)
Add-U32 $b 0
Add-U32 $b 54
Add-U32 $b 40; Add-U32 $b $Size; Add-U32 $b $Size
Add-U16 $b 1; Add-U16 $b 24
Add-U32 $b 0; Add-U32 $b ($Size * $Size * 3); Add-U32 $b 2835; Add-U32 $b 2835; Add-U32 $b 0; Add-U32 $b 0
for ($y = $Size - 1; $y -ge 0; $y--) {
  for ($x = 0; $x -lt $Size; $x++) {
    $c = Get-PixelRgb $x $y
    $b.Add([byte]$c[2]); $b.Add([byte]$c[1]); $b.Add([byte]$c[0])
  }
}
Save-Bytes (Join-Path $src 'textures\ZPKBMP.bmp') $b

# TGA tipo 2 (true color non compresso) a 24 bit, origine in basso a sinistra
$b = New-Bytes
$b.Add(0); $b.Add(0); $b.Add(2)
for ($i = 0; $i -lt 5; $i++) { $b.Add(0) }
Add-U16 $b 0; Add-U16 $b 0; Add-U16 $b $Size; Add-U16 $b $Size
$b.Add(24); $b.Add(0)
for ($y = $Size - 1; $y -ge 0; $y--) {
  for ($x = 0; $x -lt $Size; $x++) {
    $c = Get-PixelRgb $x $y
    $b.Add([byte]$c[2]); $b.Add([byte]$c[1]); $b.Add([byte]$c[0])
  }
}
Save-Bytes (Join-Path $src 'textures\ZPKTGA.tga') $b

# PCX versione 5, RLE, 8 bit con la palette in fondo (0x0C + 256 * RGB)
function Get-PcxRow([int]$Y) {
  $row = New-Bytes
  $x = 0
  while ($x -lt $Size) {
    $v = Get-PcxIndex $x $Y
    $n = 1
    while (($x + $n -lt $Size) -and ($n -lt 63) -and ((Get-PcxIndex ($x + $n) $Y) -eq $v)) { $n++ }
    if (($n -gt 1) -or ($v -ge 192)) { $row.Add([byte](192 + $n)) }
    $row.Add([byte]$v)
    $x += $n
  }
  return $row
}
$b = New-Bytes
$b.Add(10); $b.Add(5); $b.Add(1); $b.Add(8)
Add-U16 $b 0; Add-U16 $b 0; Add-U16 $b ($Size - 1); Add-U16 $b ($Size - 1)
Add-U16 $b 72; Add-U16 $b 72
for ($i = 0; $i -lt 48; $i++) { $b.Add(0) }
$b.Add(0); $b.Add(1)
Add-U16 $b $Size; Add-U16 $b 1
for ($i = 0; $i -lt 58; $i++) { $b.Add(0) }
for ($y = 0; $y -lt $Size; $y++) { foreach ($v in (Get-PcxRow $y)) { $b.Add($v) } }
$b.Add(12)
for ($i = 0; $i -lt 256; $i++) {
  $b.Add([byte]$i); $b.Add([byte](255 - $i)); $b.Add([byte](($i * 37) % 256))
}
Save-Bytes (Join-Path $src 'textures\ZPKPCX.pcx') $b

# patch di Doom 64x64: gli otto pixel in alto a sinistra sono trasparenti; un solo post per colonna
$patchColumns = @()
for ($x = 0; $x -lt $Size; $x++) {
  $col = New-Bytes
  $top = 0; $len = $Size
  if ($x -lt 8) { $top = 8; $len = $Size - 8 }
  $col.Add([byte]$top); $col.Add([byte]$len); $col.Add(0)
  for ($i = 0; $i -lt $len; $i++) { $col.Add([byte](Get-PatchIndex $x ($top + $i))) }
  $col.Add(0); $col.Add(255)
  $patchColumns += , $col
}
$b = New-Bytes
Add-U16 $b $Size; Add-U16 $b $Size; Add-U16 $b 32; Add-U16 $b 60
$ofs = 8 + 4 * $Size
foreach ($col in $patchColumns) { Add-U32 $b $ofs; $ofs += $col.Count }
foreach ($col in $patchColumns) { foreach ($v in $col) { $b.Add($v) } }
Save-Bytes (Join-Path $src 'textures\ZPKPAT.patch') $b

# flat 64x64: un byte per pixel, per righe
$b = New-Bytes
for ($y = 0; $y -lt $Size; $y++) { for ($x = 0; $x -lt $Size; $x++) { $b.Add([byte](Get-FlatIndex $x $y)) } }
Save-Bytes (Join-Path $src 'textures\ZPKFLT.flat') $b

# ---------------------------------------------------------------------------------------------
# voxel: KVX (Build), VOX (Slab6) e DDVOX (testo), tutti 8x8x8
# ---------------------------------------------------------------------------------------------
function Add-Palette6([System.Collections.Generic.List[byte]]$L) {
  for ($i = 0; $i -lt 256; $i++) {
    $L.Add([byte](($i * 3) % 64)); $L.Add([byte](($i * 5 + 7) % 64)); $L.Add([byte](($i * 11 + 13) % 64))
  }
}

$n = 8
# KVX: una piramide a gradini (altezza 7, 5, 3 e 1 dal centro ai bordi), z = 0 e' in alto
$columns = @(); $rowOffsets = @()
for ($x = 0; $x -lt $n; $x++) {
  $col = New-Bytes; $rows = @()
  for ($y = 0; $y -lt $n; $y++) {
    $rows += $col.Count
    $d = [Math]::Max([Math]::Abs(2 * $x - 7), [Math]::Abs(2 * $y - 7))
    $h = 8 - $d
    $col.Add([byte](8 - $h)); $col.Add([byte]$h); $col.Add(63)
    for ($z = 8 - $h; $z -lt 8; $z++) { $col.Add([byte](1 + (($x * 5 + $y * 3 + $z) % 200))) }
  }
  $rows += $col.Count
  $columns += , $col; $rowOffsets += , $rows
}
$base = ($n + 1) * 4 + $n * ($n + 1) * 2
$total = 0; foreach ($c in $columns) { $total += $c.Count }
$b = New-Bytes
Add-U32 $b (24 + $base + $total)
Add-U32 $b $n; Add-U32 $b $n; Add-U32 $b $n
# pivot at the center of the base: x and y in the middle, z (it points down) at the bottom, as in the real files
Add-U32 $b (($n / 2) * 256); Add-U32 $b (($n / 2) * 256); Add-U32 $b ($n * 256)
$acc = $base
for ($x = 0; $x -lt $n; $x++) { Add-U32 $b $acc; $acc += $columns[$x].Count }
Add-U32 $b $acc
for ($x = 0; $x -lt $n; $x++) { foreach ($r in $rowOffsets[$x]) { Add-U16 $b $r } }
foreach ($c in $columns) { foreach ($v in $c) { $b.Add($v) } }
Add-Palette6 $b
Save-Bytes (Join-Path $src 'voxels\ZVKAA.KVX') $b

# VOX di Slab6: intestazione di tre interi, n^3 byte (255 = vuoto), palette
$b = New-Bytes
Add-U32 $b $n; Add-U32 $b $n; Add-U32 $b $n
for ($x = 0; $x -lt $n; $x++) {
  for ($y = 0; $y -lt $n; $y++) {
    for ($z = 0; $z -lt $n; $z++) {
      $dx = $x - 3.5; $dy = $y - 3.5; $dz = $z - 3.5
      if (($dx * $dx + $dy * $dy + $dz * $dz) -le 12.25) { $b.Add([byte](1 + (($x * 7 + $y * 3 + $z * 5) % 200))) } else { $b.Add(255) }
    }
  }
}
Add-Palette6 $b
Save-Bytes (Join-Path $src 'voxels\ZVSAA.VOX') $b

# DDVOX: testo, il lato e poi per ogni colonna (x, y) i colori da z = 0; "skip n" salta n celle vuote
$text = New-Object System.Text.StringBuilder
$null = $text.Append("$n`r`n")
for ($x = 0; $x -lt $n; $x++) {
  for ($y = 0; $y -lt $n; $y++) {
    $d = [Math]::Max([Math]::Abs(2 * $x - 7), [Math]::Abs(2 * $y - 7))
    $h = [Math]::Max(0, 7 - $d) + 1
    if ($h -gt 8) { $h = 8 }
    if ($n - $h -gt 0) { $null = $text.Append("skip $($n - $h)`r`n") }
    for ($z = $n - $h; $z -lt $n; $z++) {
      $color = ((40 + $x * 20) -shl 16) -bor ((40 + $y * 20) -shl 8) -bor (60 + $z * 20)
      $null = $text.Append("$color`r`n")
    }
  }
}
[System.IO.File]::WriteAllBytes((Join-Path $src 'voxels\ZVDAA.DDVOX'), [System.Text.Encoding]::ASCII.GetBytes($text.ToString()))

$voxeldef = @'
// DelphiDoom: VOXELDEF del PK3 di prova della issue #48 (dominio pubblico)
// I tre voxel sostituiscono tre sprite di Doom; negli altri giochi lo sprite non esiste e il
// parser avvisa "sprite not found": e' atteso.

voxeldef "zvkaa.kvx"
{
	Scale = 0.9
	replaces sprite treda
}

voxeldef "zvdaa.ddvox"
{
	Scale = 0.9
	replaces sprite tblua
}

voxeldef "zvsaa.vox"
{
	Scale = 0.9
	replaces sprite tgrna
}
'@
[System.IO.File]::WriteAllBytes((Join-Path $src 'VOXELDEF'), [System.Text.Encoding]::ASCII.GetBytes($voxeldef.Replace("`r`n", "`n").Replace("`n", "`r`n")))

# ---------------------------------------------------------------------------------------------
# suoni: WAV PCM 16 bit, FLAC (frame verbatim), Ogg Vorbis (intestazioni fatte a mano)
# ---------------------------------------------------------------------------------------------
function New-SineSamples([int]$Count, [double]$Rate, [double]$Frequency, [double]$Amplitude) {
  $s = New-Object 'int[]' $Count
  for ($i = 0; $i -lt $Count; $i++) {
    $env = [Math]::Min(1.0, [Math]::Min($i, $Count - 1 - $i) / 64.0)
    $s[$i] = [int][Math]::Round($Amplitude * $env * [Math]::Sin(2 * [Math]::PI * $Frequency * $i / $Rate))
  }
  return , $s
}

# WAV: 11025 Hz mono, 0,25 s
$samples = New-SineSamples 2756 11025 440 16000
$b = New-Bytes
Add-Text $b 'RIFF'; Add-U32 $b (36 + $samples.Length * 2); Add-Text $b 'WAVE'
Add-Text $b 'fmt '; Add-U32 $b 16; Add-U16 $b 1; Add-U16 $b 1; Add-U32 $b 11025; Add-U32 $b 22050; Add-U16 $b 2; Add-U16 $b 16
Add-Text $b 'data'; Add-U32 $b ($samples.Length * 2)
foreach ($v in $samples) { Add-U16 $b ($v -band 0xFFFF) }
Save-Bytes (Join-Path $src 'sounds\zpkwav.wav') $b
$wavBytes = $b.ToArray()

# FLAC: STREAMINFO + un frame di 512 campioni con sottoframe verbatim
function Get-Crc8([byte[]]$Data) {
  $crc = 0
  foreach ($v in $Data) {
    $crc = $crc -bxor $v
    for ($i = 0; $i -lt 8; $i++) {
      if ($crc -band 0x80) { $crc = (($crc -shl 1) -bxor 0x07) -band 0xFF } else { $crc = ($crc -shl 1) -band 0xFF }
    }
  }
  return $crc
}
function Get-Crc16([byte[]]$Data) {
  $crc = 0
  foreach ($v in $Data) {
    $crc = $crc -bxor ($v -shl 8)
    for ($i = 0; $i -lt 8; $i++) {
      if ($crc -band 0x8000) { $crc = (($crc -shl 1) -bxor 0x8005) -band 0xFFFF } else { $crc = ($crc -shl 1) -band 0xFFFF }
    }
  }
  return $crc
}
$flacCount = 512
$samples = New-SineSamples $flacCount 8000 500 12000
$frame = New-Bytes
$frame.Add(0xFF); $frame.Add(0xF8)       # sincronismo, blocco fisso
$frame.Add(0x90)                         # 512 campioni (1001), frequenza dallo STREAMINFO (0000)
$frame.Add(0x08)                         # un canale (0000), 16 bit (100), riservato
$frame.Add(0)                            # numero del frame (UTF-8)
$frame.Add([byte](Get-Crc8 $frame.ToArray()))
$frame.Add(0x02)                         # sottoframe verbatim, nessun bit sprecato
foreach ($v in $samples) { $frame.Add([byte](($v -shr 8) -band 255)); $frame.Add([byte]($v -band 255)) }
$crc = Get-Crc16 $frame.ToArray()
$frame.Add([byte]($crc -shr 8)); $frame.Add([byte]($crc -band 255))

$b = New-Bytes
Add-Text $b 'fLaC'
$b.Add(0x80); $b.Add(0); $b.Add(0); $b.Add(34)       # STREAMINFO, ultimo blocco, 34 byte
$b.Add([byte]($flacCount -shr 8)); $b.Add([byte]($flacCount -band 255))    # blocco minimo
$b.Add([byte]($flacCount -shr 8)); $b.Add([byte]($flacCount -band 255))    # blocco massimo
$fs = $frame.Count
$b.Add([byte]($fs -shr 16)); $b.Add([byte](($fs -shr 8) -band 255)); $b.Add([byte]($fs -band 255))   # frame minimo
$b.Add([byte]($fs -shr 16)); $b.Add([byte](($fs -shr 8) -band 255)); $b.Add([byte]($fs -band 255))   # frame massimo
# frequenza (20 bit), canali - 1 (3 bit), bit - 1 (5 bit), campioni totali (36 bit)
[long]$packed = (([long]8000) -shl 44) -bor (([long]0) -shl 41) -bor (([long]15) -shl 36) -bor ([long]$flacCount)
for ($i = 7; $i -ge 0; $i--) { $b.Add([byte](($packed -shr (8 * $i)) -band 255)) }
for ($i = 0; $i -lt 16; $i++) { $b.Add(0) }          # MD5 non dato
foreach ($v in $frame) { $b.Add($v) }
Save-Bytes (Join-Path $src 'sounds\zpkflc.flac') $b

# Ogg Vorbis: e' il costruttore di Tests\Source\DelphiDoom.Tests.Sound.VorbisFile.pas (intestazioni
# a mano: quattro codebook, un floor di tipo 1, un residuo, un modo corto e uno lungo) scritto in
# PowerShell; i pacchetti audio sono bit casuali dopo i bit del modo: un rumore che ogni decoder
# decodifica allo stesso modo.
$script:bitBytes = New-Bytes
$script:bitCount = 0
function Write-Bits([long]$Value, [int]$Bits) {
  for ($i = 0; $i -lt $Bits; $i++) {
    if (($script:bitCount -shr 3) -ge $script:bitBytes.Count) { $script:bitBytes.Add(0) }
    if ((($Value -shr $i) -band 1) -ne 0) {
      $idx = $script:bitCount -shr 3
      $script:bitBytes[$idx] = [byte]($script:bitBytes[$idx] -bor (1 -shl ($script:bitCount -band 7)))
    }
    $script:bitCount++
  }
}
function Write-BitText([string]$Text) { foreach ($c in $Text.ToCharArray()) { Write-Bits ([int]$c) 8 } }
function Start-Bits { $script:bitBytes = New-Bytes; $script:bitCount = 0 }
function Stop-Bits { return , $script:bitBytes.ToArray() }
function Get-PackFloat([double]$V) {
  $sign = 0L
  if ($V -lt 0) { $sign = 0x80000000L; $V = -$V }
  $e = [int][Math]::Floor([Math]::Log($V) / [Math]::Log(2) + 0.001)
  $m = [long][Math]::Round($V * [Math]::Pow(2, 20 - $e))
  return ($sign -bor ([long]($e + 768) -shl 21) -bor $m)
}
function Write-Book([int]$Dim, [int]$Count, [int]$Length) {
  Write-Bits 0x564342 24; Write-Bits $Dim 16; Write-Bits $Count 24
  Write-Bits 0 1; Write-Bits 0 1
  for ($i = 0; $i -lt $Count; $i++) { Write-Bits ($Length - 1) 5 }
}

$channels = 1; $rate = 22050; $packets = 24; $residueType = 1

Start-Bits
Write-Bits 1 8; Write-BitText 'vorbis'
Write-Bits 0 32; Write-Bits $channels 8; Write-Bits $rate 32; Write-Bits 0 32; Write-Bits 128000 32; Write-Bits 0 32
Write-Bits 8 4; Write-Bits 11 4; Write-Bits 1 1
$idHeader = Stop-Bits

Start-Bits
Write-Bits 3 8; Write-BitText 'vorbis'
Write-Bits 16 32; Write-BitText 'DelphiDoom tests'
Write-Bits 1 32; Write-Bits 10 32; Write-BitText 'TITLE=test'; Write-Bits 1 1
$commentHeader = Stop-Bits

Start-Bits
Write-Bits 5 8; Write-BitText 'vorbis'
Write-Bits 3 8
Write-Book 1 16 4;  Write-Bits 0 4
Write-Book 1 256 8; Write-Bits 0 4
Write-Bits 0x564342 24; Write-Bits 1 16; Write-Bits 1 24; Write-Bits 0 1; Write-Bits 0 1; Write-Bits 0 5; Write-Bits 0 4
Write-Book 2 64 6;  Write-Bits 1 4
Write-Bits (Get-PackFloat ([double]-0.4)) 32; Write-Bits (Get-PackFloat ([double]0.1)) 32; Write-Bits 3 4; Write-Bits 0 1
for ($i = 0; $i -lt 8; $i++) { Write-Bits $i 4 }
Write-Bits 0 6; Write-Bits 0 16
Write-Bits 0 6; Write-Bits 1 16; Write-Bits 1 5; Write-Bits 0 4; Write-Bits 1 3; Write-Bits 1 2; Write-Bits 0 8; Write-Bits 2 8
Write-Bits 0 8; Write-Bits 0 2; Write-Bits 8 4; Write-Bits 64 8; Write-Bits 192 8
Write-Bits 0 6; Write-Bits $residueType 16; Write-Bits 0 24; Write-Bits 1024 24; Write-Bits 15 24; Write-Bits 0 6
Write-Bits 2 8; Write-Bits 1 3; Write-Bits 0 1; Write-Bits 3 8
Write-Bits 0 6; Write-Bits 0 16; Write-Bits 0 1; Write-Bits 0 1
Write-Bits 0 2; Write-Bits 0 8; Write-Bits 0 8; Write-Bits 0 8
Write-Bits 1 6
Write-Bits 0 1; Write-Bits 0 16; Write-Bits 0 16; Write-Bits 0 8
Write-Bits 1 1; Write-Bits 0 16; Write-Bits 0 16; Write-Bits 0 8
Write-Bits 1 1
$setupHeader = Stop-Bits

# CRC di Ogg: polinomio 0x04C11DB7, senza riflessione ne' xor finale
$crcTable = New-Object 'long[]' 256
for ($i = 0; $i -lt 256; $i++) {
  [long]$r = ([long]$i) -shl 24
  for ($k = 0; $k -lt 8; $k++) {
    if ($r -band 0x80000000L) { $r = (($r -shl 1) -bxor 0x04C11DB7L) -band 0xFFFFFFFFL } else { $r = ($r -shl 1) -band 0xFFFFFFFFL }
  }
  $crcTable[$i] = $r
}
$script:oggOut = New-Bytes
$script:pageNumber = 0
function Write-OggPage([int]$Flags, [long]$Granule, [object[]]$PacketList) {
  $lacing = New-Bytes; $body = New-Bytes
  foreach ($p in $PacketList) {
    $len = $p.Length
    while ($len -ge 255) { $lacing.Add(255); $len -= 255 }
    $lacing.Add([byte]$len)
    foreach ($v in $p) { $body.Add($v) }
  }
  $page = New-Bytes
  Add-Text $page 'OggS'; $page.Add(0); $page.Add([byte]$Flags)
  Add-U64 $page $Granule
  Add-U32 $page 4711
  Add-U32 $page $script:pageNumber
  Add-U32 $page 0
  $page.Add([byte]$lacing.Count)
  foreach ($v in $lacing) { $page.Add($v) }
  foreach ($v in $body) { $page.Add($v) }
  [long]$crc = 0
  foreach ($v in $page) { $crc = (($crc -shl 8) -bxor $crcTable[(($crc -shr 24) -band 255) -bxor $v]) -band 0xFFFFFFFFL }
  for ($i = 0; $i -lt 4; $i++) { $page[22 + $i] = [byte](($crc -shr (8 * $i)) -band 255) }
  foreach ($v in $page) { $script:oggOut.Add($v) }
  $script:pageNumber++
}

Write-OggPage 2 0 @(, $idHeader)
Write-OggPage 0 0 @($commentHeader, $setupHeader)

[long]$seed = 12345
function Get-Next { $script:seed = (($script:seed * 1664525) + 1013904223) -band 0xFFFFFFFFL; return ($script:seed -shr 8) }
$script:seed = $seed
$granule = 0L; $previousLong = $false
$pending = @(); $perPage = 8
for ($index = 0; $index -lt $packets; $index++) {
  $last = ($index -eq $packets - 1)
  $long = ((Get-Next) -band 3) -eq 0
  if ($long) { $length = 200 + [int]((Get-Next) % 400) } else { $length = 40 + [int]((Get-Next) % 120) }
  $payload = New-Object 'byte[]' $length
  for ($i = 0; $i -lt $length; $i++) { $payload[$i] = [byte]((Get-Next) -band 255) }
  $modeBits = 0; $mask = 3
  if ($long) { $modeBits = 2 -bor ([int]$previousLong -shl 2) -bor 8; $mask = 15 }
  $payload[0] = [byte](($payload[0] -band (-bnot $mask -band 255)) -bor $modeBits)
  if ($index -gt 0) {
    if ($long) { $granule += 2048 / 4 } else { $granule += 256 / 4 }
    if ($previousLong) { $granule += 2048 / 4 } else { $granule += 256 / 4 }
  }
  $pending += , $payload
  $previousLong = $long
  if (($pending.Count -eq $perPage) -or $last) {
    $flags = 0; if ($last) { $flags = 4 }
    Write-OggPage $flags $granule $pending
    $pending = @()
  }
}
Save-Bytes (Join-Path $src 'sounds\zpkogg.ogg') $script:oggOut

# ---------------------------------------------------------------------------------------------
# PK3 (ZIP con i nomi a barre dritte) e PWAD
# ---------------------------------------------------------------------------------------------
$pk3 = Join-Path $OutDir 'zpktest.pk3'
if (Test-Path -LiteralPath $pk3) { Remove-Item -LiteralPath $pk3 -Force }
$zip = [System.IO.Compression.ZipFile]::Open($pk3, [System.IO.Compression.ZipArchiveMode]::Create)
try {
  $files = Get-ChildItem -LiteralPath $src -Recurse -File | Sort-Object FullName
  foreach ($f in $files) {
    $name = $f.FullName.Substring($src.Length + 1).Replace('\', '/')
    $entry = $zip.CreateEntry($name, [System.IO.Compression.CompressionLevel]::Optimal)
    $stream = $entry.Open()
    try { $bytes = [System.IO.File]::ReadAllBytes($f.FullName); $stream.Write($bytes, 0, $bytes.Length) } finally { $stream.Dispose() }
  }
} finally { $zip.Dispose() }

function Read-Src([string]$Relative) { return , [System.IO.File]::ReadAllBytes((Join-Path $src $Relative)) }

# PWAD: HI_START ... HI_END con un'immagine per ogni formato, TX_START ... TX_END con due, un
# lump di suono e PK3ENTRY che lo lega al nome lungo "sounds/zwsnd.wav"
$lumps = @(
  @('HI_START', @()),
  @('ZWTGA', (Read-Src 'textures\ZPKTGA.tga')),
  @('ZWPNG', (Read-Src 'textures\ZPKPNG.png')),
  @('ZWBMP', (Read-Src 'textures\ZPKBMP.bmp')),
  @('ZWJPG', (Read-Src 'textures\ZPKJPG.jpg')),
  @('ZWPCX', (Read-Src 'textures\ZPKPCX.pcx')),
  @('ZWPAT', (Read-Src 'textures\ZPKPAT.patch')),
  @('ZWFLT', (Read-Src 'textures\ZPKFLT.flat')),
  @('HI_END', @()),
  @('TX_START', @()),
  @('ZXPNG', (Read-Src 'flats\ZPKFLAT.png')),
  @('ZXTGA', (Read-Src 'textures\ZPKTGA.tga')),
  @('TX_END', @()),
  @('ZWSND', $wavBytes),
  @('PK3ENTRY', [System.Text.Encoding]::ASCII.GetBytes("// alias del suono`r`nZWSND=sounds/zwsnd.wav`r`n"))
)
$wad = New-Bytes
Add-Text $wad 'PWAD'; Add-U32 $wad $lumps.Count; Add-U32 $wad 0
$positions = @()
foreach ($l in $lumps) {
  while (($wad.Count % 4) -ne 0) { $wad.Add(0) }
  $positions += $wad.Count
  foreach ($v in $l[1]) { $wad.Add($v) }
}
while (($wad.Count % 4) -ne 0) { $wad.Add(0) }
$directory = $wad.Count
for ($i = 0; $i -lt $lumps.Count; $i++) {
  Add-U32 $wad $positions[$i]; Add-U32 $wad $lumps[$i][1].Length
  $name = $lumps[$i][0]
  for ($k = 0; $k -lt 8; $k++) { if ($k -lt $name.Length) { $wad.Add([byte][int]$name[$k]) } else { $wad.Add(0) } }
}
$dirBytes = [BitConverter]::GetBytes([int]$directory)
for ($i = 0; $i -lt 4; $i++) { $wad[8 + $i] = $dirBytes[$i] }
Save-Bytes (Join-Path $OutDir 'zpkhires.wad') $wad

Write-Output ("zpktest.pk3 {0} byte, zpkhires.wad {1} byte, {2} file in src" -f (Get-Item $pk3).Length, $wad.Count, (Get-ChildItem -LiteralPath $src -Recurse -File).Count)

# Writes the small TGA files of Tests\Data\Q3Render\tga (issue #254, renderer phase R0): the cases of LoadTGA of
# Quake III that the files of Tests\Data\IdImages\tga (made for Doom 3) do not have. Deterministic: run it again and
# the bytes are the same. Usage: Make-Q3Tga.ps1 [-Folder <output folder>]
param([string]$Folder = (Join-Path $PSScriptRoot '..\..\..\Tests\Data\Q3Render\tga'))

New-Item -ItemType Directory -Force -Path $Folder | Out-Null
$Folder = (Resolve-Path $Folder).Path

function Header([int]$IdLength, [int]$ColorMap, [int]$Type, [int]$Width, [int]$Height, [int]$PixelSize, [int]$Attributes) {
  $bytes = New-Object System.Collections.Generic.List[byte]
  $bytes.Add($IdLength); $bytes.Add($ColorMap); $bytes.Add($Type)
  foreach ($i in 1..5) { $bytes.Add(0) }   # colormap index, length (2 bytes each) and size
  foreach ($i in 1..4) { $bytes.Add(0) }   # x and y origin
  $bytes.Add($Width -band 255); $bytes.Add(($Width -shr 8) -band 255)
  $bytes.Add($Height -band 255); $bytes.Add(($Height -shr 8) -band 255)
  $bytes.Add($PixelSize); $bytes.Add($Attributes)
  return ,$bytes
}

function Save([string]$Name, $Bytes) {
  [System.IO.File]::WriteAllBytes((Join-Path $Folder $Name), $Bytes.ToArray())
}

function Pixels([int]$Count, [int]$Size, [int]$Seed) {
  $out = New-Object System.Collections.Generic.List[byte]
  for ($i = 0; $i -lt $Count; $i++) {
    for ($c = 0; $c -lt $Size; $c++) { $out.Add((($Seed + 37 * $i + 91 * $c + 7 * $i * $c) -band 255)) }
  }
  return ,$out
}

# type 2, 24 and 32 bit, with an image id (the comment is skipped)
$b = Header 5 0 2 4 3 24 0; $b.AddRange([byte[]](65, 66, 67, 68, 69)); $b.AddRange((Pixels 12 3 10)); Save 'rgb24-id.tga' $b
$b = Header 0 0 2 3 5 32 0; $b.AddRange((Pixels 15 4 20)); Save 'rgba32.tga' $b
# type 3 (gray) 8 bit, and type 3 with 24 bit (the switch is on the pixel size)
$b = Header 0 0 3 5 2 8 0; $b.AddRange((Pixels 10 1 30)); Save 'gray8.tga' $b
$b = Header 0 0 3 2 2 24 0; $b.AddRange((Pixels 4 3 40)); Save 'gray-type-rgb24.tga' $b
# the top-down bit: the C only warns
$b = Header 0 0 2 2 2 24 32; $b.AddRange((Pixels 4 3 50)); Save 'topdown.tga' $b
# RLE: a run that spans rows (5 pixels in a 3 x 3 image), raw packets, then runs to the end
$b = Header 0 0 10 3 3 24 0
$b.Add(0x84); $b.AddRange([byte[]](1, 2, 3))          # run of 5
$b.Add(0x02); $b.AddRange((Pixels 3 3 60))            # raw packet of 3
$b.Add(0x81); $b.AddRange([byte[]](9, 8, 7))          # run of 2 (fills the image)
Save 'rle24-span.tga' $b
# RLE 32 bit with the alpha, and more pixels than the image: the C stops at the last row
$b = Header 0 0 10 2 2 32 0
$b.Add(0x83); $b.AddRange([byte[]](10, 20, 30, 40))   # run of 4 (fills the image)
$b.Add(0x83); $b.AddRange([byte[]](50, 60, 70, 80))   # one packet too many: never read by the C
Save 'rle32-fill.tga' $b
$b = Header 0 0 10 2 2 32 0
$b.Add(0x87); $b.AddRange([byte[]](10, 20, 30, 40))   # run of 8 in a 4 pixel image: stops at the last row
Save 'rle32-overrun.tga' $b
# errors of the C
$b = Header 0 0 1 2 2 8 0; $b.AddRange((Pixels 4 1 1)); Save 'bad-type.tga' $b
$b = Header 0 1 2 2 2 24 0; $b.AddRange((Pixels 4 3 1)); Save 'colormap.tga' $b
$b = Header 0 0 2 2 2 16 0; $b.AddRange((Pixels 4 2 1)); Save 'bad-depth-type2.tga' $b
$b = Header 0 0 3 2 2 16 0; $b.AddRange((Pixels 4 2 1)); Save 'bad-depth-type3.tga' $b
$b = Header 0 0 10 2 2 8 0; $b.AddRange((Pixels 4 1 1)); Save 'bad-depth-rle.tga' $b
# empty images: width 0 and height 0
$b = Header 0 0 2 0 4 24 0; Save 'width0.tga' $b
$b = Header 0 0 2 4 0 24 0; Save 'height0.tga' $b
Write-Host "Files in $Folder"

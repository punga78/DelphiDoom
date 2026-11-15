<#
  Genera i PK3 di prova dei modelli MD2 nel renderer OpenGL (issue #177, fetta 11, prerequisito).

  Dati sintetici scritti qui (dominio pubblico / CC0): nessun asset di un gioco.
  Uso:
    powershell -NoProfile -ExecutionPolicy Bypass -File Tests\Data\ModelsGl\Make-ModelPk3.ps1

  Scrive, accanto allo script, un PK3 per gioco (zmdl_d.pk3 Doom, zmdl_h Heretic, zmdl_x Hexen, zmdl_s Strife;
  il nome del file non supera 8 caratteri: lo vuole ExtractFileBase di -file; in piu' zmdl_t = Doom con una
  trasparenza di 0.5 ogni tre stati) con:
    models/ZCUBE.MD2      un cubo (8 vertici, 12 triangoli, 4 punti di texture) in 2 fotogrammi (il secondo piu' piccolo)
    textures/ZMDLTEX.png  una texture 64x64
    MODELDEF              lega OGNI stato del gioco (da <Gioco>\info_h.pas) al cubo e alla texture, con i fotogrammi 0 e 1
                          alternati (stato pari: da 0 a 1, dispari: da 1 a 0), cosi' qualunque cosa disegnata dal motore
                          (oggetti, mostri, proiettili) diventa il modello: statici, animati e interpolati.
  L'uscita e' deterministica tranne il PNG (encoder di System.Drawing).
  Si usa con  -file Tests\Data\ModelsGl\zmdl_<d|h|x|s>.pk3  (Tools\Verifica\opengl\Confronta.ps1 -More "-file ...").
#>
param(
  [string]$OutDir = $PSScriptRoot
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path

function Add-I32([System.Collections.Generic.List[byte]]$L, [int]$V) {
  $L.AddRange([System.BitConverter]::GetBytes([int]$V))
}
function Add-I16([System.Collections.Generic.List[byte]]$L, [int]$V) {
  $L.AddRange([System.BitConverter]::GetBytes([int16]$V))
}
function Add-F32([System.Collections.Generic.List[byte]]$L, [single]$V) {
  $L.AddRange([System.BitConverter]::GetBytes([single]$V))
}

# ---------------------------------------------------------------------------------------------
# MD2: un cubo con due fotogrammi
# ---------------------------------------------------------------------------------------------
function New-CubeMd2 {
  $vertexCount = 8
  $texturePointCount = 4
  $faces = @(@(0,1,3,2), @(4,6,7,5), @(0,4,5,1), @(2,3,7,6), @(0,2,6,4), @(1,5,7,3))  # quattro vertici per faccia
  $triangleCount = 12
  $frameCount = 2
  $frameSize = 40 + 4 * $vertexCount
  $headerSize = 68
  $texOffset = $headerSize
  $triOffset = $texOffset + 4 * $texturePointCount
  $frameOffset = $triOffset + 12 * $triangleCount
  $end = $frameOffset + $frameCount * $frameSize

  $b = New-Object 'System.Collections.Generic.List[byte]'
  $b.AddRange([byte[]][char[]]'IDP2')
  Add-I32 $b 8                 # version
  Add-I32 $b 64                # skin width
  Add-I32 $b 64                # skin height
  Add-I32 $b $frameSize
  Add-I32 $b 0                 # skins
  Add-I32 $b $vertexCount
  Add-I32 $b $texturePointCount
  Add-I32 $b $triangleCount
  Add-I32 $b 0                 # GL commands
  Add-I32 $b $frameCount
  Add-I32 $b $headerSize       # skins offset (none)
  Add-I32 $b $texOffset
  Add-I32 $b $triOffset
  Add-I32 $b $frameOffset
  Add-I32 $b $end              # GL commands offset
  Add-I32 $b $end

  foreach ($p in @(@(0,0), @(63,0), @(63,63), @(0,63))) { Add-I16 $b $p[0]; Add-I16 $b $p[1] }
  foreach ($f in $faces) {
    # due triangoli per faccia: (0,1,2) e (0,2,3); il punto di texture e' l'angolo della faccia
    foreach ($t in @(@(0,1,2), @(0,2,3))) {
      foreach ($c in $t) { Add-I16 $b $f[$c] }
      foreach ($c in $t) { Add-I16 $b $c }
    }
  }
  for ($frame = 0; $frame -lt $frameCount; $frame++) {
    $low = if ($frame -eq 0) { 0 } else { 60 }
    $high = if ($frame -eq 0) { 255 } else { 195 }
    $scale = 0.2                      # 255 * 0.2 = 51 unita' di mondo
    $translate = -25.5 * 1.0
    Add-F32 $b $scale; Add-F32 $b $scale; Add-F32 $b $scale
    Add-F32 $b $translate; Add-F32 $b $translate; Add-F32 $b 0
    $name = [System.Text.Encoding]::ASCII.GetBytes("frame$frame")
    $nameBytes = New-Object byte[] 16
    [Array]::Copy($name, $nameBytes, $name.Length)
    $b.AddRange($nameBytes)
    for ($v = 0; $v -lt 8; $v++) {
      $x = if ($v -band 1) { $high } else { $low }
      $y = if ($v -band 2) { $high } else { $low }
      $z = if ($v -band 4) { $high } else { $low }
      $b.Add([byte]$x); $b.Add([byte]$y); $b.Add([byte]$z); $b.Add([byte]($v % 162))
    }
  }
  return , $b.ToArray()
}

# ---------------------------------------------------------------------------------------------
# texture
# ---------------------------------------------------------------------------------------------
function New-TexturePng([string]$Path) {
  $bitmap = New-Object System.Drawing.Bitmap 64, 64, ([System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
  for ($y = 0; $y -lt 64; $y++) {
    for ($x = 0; $x -lt 64; $x++) {
      $bitmap.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(40 + 3 * $x, 40 + 3 * $y, 40 + 3 * ($x -bxor $y)))
    }
  }
  $bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
  $bitmap.Dispose()
}

# ---------------------------------------------------------------------------------------------
# MODELDEF: ogni stato del gioco (dall'elenco di <Gioco>\info_h.pas)
# ---------------------------------------------------------------------------------------------
function Get-StateNames([string]$Game) {
  $lines = [System.IO.File]::ReadAllLines((Join-Path $root "$Game\info_h.pas"))
  $names = New-Object 'System.Collections.Generic.List[string]'
  $inside = $false
  foreach ($line in $lines) {
    $text = ($line -replace '//.*$', '') -replace '\{[^}]*\}', ''
    if (-not $inside) {
      if ($text -match '^\s*S_NULL\b') { $inside = $true } else { continue }
    }
    if ($text -match 'NUMSTATES') { break }
    foreach ($m in [regex]::Matches($text, '\bS_[A-Z0-9_]+\b')) { $names.Add($m.Value) }
  }
  return , $names.ToArray()
}

$md2 = New-CubeMd2
$work = Join-Path ([System.IO.Path]::GetTempPath()) 'zpkmodel_work'
if (Test-Path -LiteralPath $work) { Remove-Item -LiteralPath $work -Recurse -Force }
New-Item -ItemType Directory -Force (Join-Path $work 'models') | Out-Null
New-Item -ItemType Directory -Force (Join-Path $work 'textures') | Out-Null
[System.IO.File]::WriteAllBytes((Join-Path $work 'models\ZCUBE.MD2'), $md2)
New-TexturePng (Join-Path $work 'textures\ZMDLTEX.png')

# the last pack is Doom with a transparency of 0.5 on every third state (the branch of gld_DrawModel of the MODELDEF transparency)
foreach ($variant in @('Doom', 'd', 0), @('Heretic', 'h', 0), @('Hexen', 'x', 0), @('Strife', 's', 0), @('Doom', 't', 3)) {
  $game = $variant[0]; $letter = $variant[1]; $transparentEvery = $variant[2]
  $states = Get-StateNames $game
  $text = New-Object System.Text.StringBuilder
  [void]$text.AppendLine("// MODELDEF di prova ($game): ogni stato e' il cubo ZCUBE.MD2 con la texture ZMDLTEX")
  for ($i = 1; $i -lt $states.Count; $i++) {
    $start = $i % 2
    $endFrame = 1 - $start
    $line = "state $($states[$i]) model zcube.md2 texture zmdltex"
    $line += " frame $start endframe $endFrame"
    if ($transparentEvery -gt 0 -and $i % $transparentEvery -eq 0) { $line += ' transparency 0.5' }
    [void]$text.AppendLine($line)
  }
  [System.IO.File]::WriteAllText((Join-Path $work 'MODELDEF'), $text.ToString(), (New-Object System.Text.UTF8Encoding($false)))

  $pk3 = Join-Path $OutDir ("zmdl_{0}.pk3" -f $letter)
  if (Test-Path -LiteralPath $pk3) { Remove-Item -LiteralPath $pk3 -Force }
  $zip = [System.IO.Compression.ZipFile]::Open($pk3, [System.IO.Compression.ZipArchiveMode]::Create)
  try {
    foreach ($f in (Get-ChildItem -LiteralPath $work -Recurse -File | Sort-Object FullName)) {
      $name = $f.FullName.Substring($work.Length + 1).Replace('\', '/')
      $entry = $zip.CreateEntry($name, [System.IO.Compression.CompressionLevel]::Optimal)
      $stream = $entry.Open()
      try { $bytes = [System.IO.File]::ReadAllBytes($f.FullName); $stream.Write($bytes, 0, $bytes.Length) } finally { $stream.Dispose() }
    }
  } finally { $zip.Dispose() }
  Write-Host ("{0}: {1} stati, {2} byte" -f $pk3, ($states.Count - 1), (Get-Item $pk3).Length)
}
Remove-Item -LiteralPath $work -Recurse -Force

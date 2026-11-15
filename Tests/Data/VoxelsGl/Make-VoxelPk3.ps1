<#
  Genera i PK3 di prova dei voxel nel renderer OpenGL (issue #177, fetta 12, prerequisito).

  Dati sintetici scritti qui (dominio pubblico / CC0): nessun asset di un gioco.
  Uso:
    powershell -NoProfile -ExecutionPolicy Bypass -File Tests\Data\VoxelsGl\Make-VoxelPk3.ps1

  Scrive, accanto allo script, un PK3 per gioco (zvox_d.pk3 Doom, zvox_h Heretic, zvox_x Hexen, zvox_s Strife;
  il nome del file non supera 8 caratteri: lo vuole ExtractFileBase di -file; in piu' zvox_p = Doom con
  rotazione e scostamento d'angolo sugli oggetti) con:
    voxels/ZVOXAA.DDVOX   una piramide a gradini 8x8x8 (testo DDVOX: nessuna palette, colori RGB)
    VOXELDEF              lega OGNI stato del gioco (da <Gioco>\info_h.pas) a quel voxel ("state <S_xxx> voxel ..."),
                          cosi' qualunque cosa disegnata dal motore come sprite (oggetti, mostri, proiettili) diventa
                          il voxel; i voxel sono gli stessi (VX_FindVoxel li riconosce per nome): la lista di
                          visualizzazione si costruisce una volta sola
  L'uscita e' deterministica.
  Si usa con  -file Tests\Data\VoxelsGl\zvox_<d|h|x|s>.pk3  (Tools\Verifica\opengl\Confronta.ps1 -Voxels).
#>
param(
  [string]$OutDir = $PSScriptRoot
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path

function New-PyramidDdvox {
  $n = 8
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
  return , [System.Text.Encoding]::ASCII.GetBytes($text.ToString())
}

# the names of the states of the game, from the list of <Game>\info_h.pas (S_NULL excluded below)
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

$ddvox = New-PyramidDdvox
$work = Join-Path ([System.IO.Path]::GetTempPath()) 'zpkvoxel_work'
if (Test-Path -LiteralPath $work) { Remove-Item -LiteralPath $work -Recurse -Force }
New-Item -ItemType Directory -Force (Join-Path $work 'voxels') | Out-Null
[System.IO.File]::WriteAllBytes((Join-Path $work 'voxels\ZVOXAA.DDVOX'), $ddvox)

# the last pack is Doom with a spin (and an angle offset) on the voxel: the branch of gld_DrawVoxel of the rotation
foreach ($variant in @('Doom', 'd', 0), @('Heretic', 'h', 0), @('Hexen', 'x', 0), @('Strife', 's', 0), @('Doom', 'p', 1)) {
  $game = $variant[0]; $letter = $variant[1]; $spin = $variant[2]
  $states = Get-StateNames $game
  $text = New-Object System.Text.StringBuilder
  [void]$text.AppendLine("// VOXELDEF di prova ($game): ogni stato e' il voxel ZVOXAA.DDVOX")
  for ($i = 1; $i -lt $states.Count; $i++) {
    $line = "state $($states[$i]) voxel `"zvoxaa.ddvox`""
    [void]$text.AppendLine($line)
  }
  if ($spin -ne 0) {
    # the options of the voxel are those of the first state that names it (the manager keeps the voxel by name):
    # a second voxel (the same file under another name is not possible: the file name is the key), so the spin
    # pack uses the VOXELDEF form with the options on a voxel of its own
    [void]$text.Clear()
    [void]$text.AppendLine("// VOXELDEF di prova ($game): ogni stato e' il voxel ZVOXAA.DDVOX con rotazione e scostamento d'angolo")
    [void]$text.AppendLine('voxeldef "zvoxaa.ddvox"')
    [void]$text.AppendLine('{')
    [void]$text.AppendLine("`tScale = 0.9")
    [void]$text.AppendLine("`tAngleOffset = 45")
    [void]$text.AppendLine("`tDroppedSpin = 60")
    [void]$text.AppendLine("`tPlacedSpin = 90")
    [void]$text.AppendLine('}')
    for ($i = 1; $i -lt $states.Count; $i++) {
      [void]$text.AppendLine("state $($states[$i]) voxel `"zvoxaa.ddvox`"")
    }
  }
  [System.IO.File]::WriteAllText((Join-Path $work 'VOXELDEF'), $text.ToString().Replace("`r`n", "`n").Replace("`n", "`r`n"), (New-Object System.Text.UTF8Encoding($false)))

  $pk3 = Join-Path $OutDir ("zvox_{0}.pk3" -f $letter)
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

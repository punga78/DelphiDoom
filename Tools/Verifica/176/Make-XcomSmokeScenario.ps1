<#
  Scrive un salvataggio di battaglia (testo .sav) con fumo e fuoco sulle tegole intorno a due soldati, per vedere in
  una battaglia vera le sfumature a 32 bit (issue #183). Parte da uno scenario del repository (start.sav.gz) o da un
  .sav, cambia i byte di `binTiles` (record di `tileTotalBytesPer` byte: indice, 4 id, 4 id di set, fumo, fuoco, flag;
  i campi sono di testo YAML in base64, non c'e' altro formato da editare) e scrive il file.
  Il fumo vale 1..15 (densita'), il fuoco 1..n (combustibile); una tegola con fuoco e' disegnata con i fotogrammi del
  fuoco, una con solo fumo con quelli del fumo. Una tegola si vede solo se e' scoperta (flag 4): qui si accende.

  Uso: Make-XcomSmokeScenario.ps1 -In <start.sav.gz|.sav> -Out <file.sav> [-Units 1,3]
#>
param(
  [Parameter(Mandatory = $true)][string]$In,
  [Parameter(Mandatory = $true)][string]$Out,
  [int[]]$Units = @(1, 3),
  [int]$Radius = 3
)
$ErrorActionPreference = 'Stop'
function ReadText($p) {
  if ($p -like '*.gz') {
    $gz = New-Object IO.Compression.GZipStream([IO.File]::OpenRead($p), [IO.Compression.CompressionMode]::Decompress)
    $r = New-Object IO.StreamReader($gz); $t = $r.ReadToEnd(); $r.Close(); $t
  } else { [IO.File]::ReadAllText($p) }
}
$L = New-Object 'System.Collections.Generic.List[string]'
$L.AddRange([string[]]((ReadText $In).Replace("`r`n", "`n").Split("`n")))
function Field([string]$name) { $i = $L.FindIndex({ param($s) $s -match ('^  ' + $name + ':') }); if ($i -lt 0) { throw $name }; $i }
$width = [int]($L[(Field 'width')] -replace '\D', '')
$length = [int]($L[(Field 'length')] -replace '\D', '')
$total = [int]($L[(Field 'tileTotalBytesPer')] -replace '\D', '')
$bin = Field 'binTiles'
$data = [Convert]::FromBase64String(($L[$bin] -replace '^  binTiles: ', '').Trim())
$positions = @{}
$u = $L.IndexOf('  units:')
for ($i = $u; $i -lt $L.Count; $i++) {
  if ($L[$i] -match '^    - id: (\d+)$') {
    $id = [int]$Matches[1]
    for ($k = $i + 1; $k -lt $i + 80; $k++) {
      if ($L[$k] -match '^      position:') { $positions[$id] = @([int]($L[$k + 1] -replace '\D', ''), [int]($L[$k + 2] -replace '\D', ''), [int]($L[$k + 3] -replace '\D', '')); break }
    }
  }
}
$index = @{}
for ($o = 0; $o -lt $data.Length; $o += $total) { $index[[BitConverter]::ToInt32($data, $o)] = $o }
$smoke = 20; $fire = 21; $flags = 22
$put = 0
foreach ($id in $Units) {
  $p = $positions[$id]
  for ($dy = -$Radius; $dy -le $Radius; $dy++) {
    for ($dx = -$Radius; $dx -le $Radius; $dx++) {
      $x = $p[0] + $dx; $y = $p[1] + $dy; $z = $p[2]
      if ($x -lt 0 -or $y -lt 0 -or $x -ge $width -or $y -ge $length) { continue }
      $t = $z * $width * $length + $y * $width + $x
      if (-not $index.ContainsKey($t)) { continue }
      $o = $index[$t]
      # a diagonal gradient of smoke from 1 to 15; the fire (drawn only on a tile that also has smoke) on the east side
      $d = [Math]::Max(1, [Math]::Min(15, 8 + $dx * 3 - $dy * 2 + $(if ($id -eq 3) { 4 } else { 0 })))
      if ($dx -eq 0 -and $dy -eq 0) { $data[$o + $smoke] = 0; $data[$o + $fire] = 0 }
      elseif ($dx -ge 2 -and [Math]::Abs($dy) -le 1) { $data[$o + $smoke] = 8; $data[$o + $fire] = [byte](2 + $dy + 2) }
      else { $data[$o + $smoke] = [byte]$d; $data[$o + $fire] = 0 }
      $data[$o + $flags] = $data[$o + $flags] -bor 7
      $put++
    }
  }
}
$L[$bin] = '  binTiles: ' + [Convert]::ToBase64String($data)
[IO.File]::WriteAllText($Out, ($L -join "`n"), (New-Object Text.UTF8Encoding($false)))
Write-Output "tegole cambiate: $put"

<#
  L'installazione di TFTD su floppy dopo la decompressione ha tutti i file nella stessa cartella (l'installer li
  sistema in sottocartelle). Questo script copia i file di <Flat> nella struttura che si aspetta OpenXcom
  (GEODATA, GEOGRAPH, UFOGRAPH, UNITS, TERRAIN, MAPS, ROUTES, SOUND, FLOP_INT) in una cartella nuova <Out>.
  I file ambigui si copiano in piu' cartelle (inutile ma innocuo). Non modifica <Flat>.
  Uso: powershell -NoProfile -File Make-TftdLayout.ps1 -Flat <cartella> -Out <cartella nuova>
#>
param([Parameter(Mandatory)][string]$Flat, [Parameter(Mandatory)][string]$Out)
$ErrorActionPreference = 'Stop'
$cursorSets = 'CURSOR', 'SMOKE', 'HIT', 'X1'
$files = Get-ChildItem $Flat -File
$terrainBases = @{}
foreach ($f in $files) { if ($f.Extension -ieq '.MCD') { $terrainBases[$f.BaseName.ToUpper()] = $true } }
function Put($f, $dir) {
  $d = Join-Path $Out $dir; New-Item -ItemType Directory -Force $d | Out-Null
  Copy-Item $f.FullName (Join-Path $d $f.Name) -Force
}
foreach ($f in $files) {
  $b = $f.BaseName.ToUpper()
  switch ($f.Extension.ToUpper()) {
    '.MAP' { Put $f 'MAPS' }
    '.RMP' { Put $f 'ROUTES' }
    '.MCD' { Put $f 'TERRAIN' }
    '.CAT' { Put $f 'SOUND' }
    '.LBM' { Put $f 'FLOP_INT'; Put $f 'UFOGRAPH'; Put $f 'GEOGRAPH' }
    '.SCR' { Put $f 'GEOGRAPH'; Put $f 'UFOGRAPH' }
    '.BDY' { Put $f 'UFOGRAPH'; Put $f 'GEOGRAPH' }
    '.SPK' { Put $f 'UFOGRAPH'; Put $f 'GEOGRAPH' }
    { $_ -in '.PCK', '.TAB' } {
      if ($b -in $cursorSets -or $b -eq 'UNIBORD') { Put $f 'UFOGRAPH' }
      elseif ($b -in 'BASEBITS', 'INTICON') { Put $f 'GEOGRAPH'; Put $f 'UNITS' }
      elseif ($terrainBases.ContainsKey($b) -or $b -eq 'BLANKS') { Put $f 'TERRAIN' }
      else { Put $f 'UNITS' }
    }
    '.DAT' {
      if ($b -in 'SPICONS', 'MEDIBITS', 'DETBLOB') { Put $f 'UFOGRAPH' }
      elseif ($b -eq 'LOFTEMPS') { Put $f 'TERRAIN'; Put $f 'GEODATA' }
      else { Put $f 'GEODATA'; if ($b -eq 'TEXTURE') { Put $f 'GEOGRAPH' } }
    }
  }
}
# I file che due archivi hanno con lo stesso nome (Extract-TftdZips.ps1 tiene il primo in _doppi): il LOFTEMPS.DAT
# lungo (114 forme) e' quello di TERRAIN, il corto (112, quello di UFO) di GEODATA; lo SCANG.DAT del primo archivio
# (quello dei terreni) va in TERRAIN. Senza _doppi (estrazione fatta col vecchio script) TERRAIN\LOFTEMPS.DAT resta
# quello corto: lo si dice.
$dup = Join-Path $Flat '_doppi'
$lofts = @(Get-ChildItem $Flat -File -Filter 'LOFTEMPS.DAT')
if (Test-Path $dup) {
  $lofts += @(Get-ChildItem $dup -File -Filter '*_LOFTEMPS.DAT')
  foreach ($s in Get-ChildItem $dup -File -Filter '*_SCANG.DAT') { Copy-Item $s.FullName (Join-Path $Out 'TERRAIN\SCANG.DAT') -Force }
}
if ($lofts.Count -gt 0) {
  $sorted = $lofts | Sort-Object Length
  Copy-Item $sorted[0].FullName (Join-Path $Out 'GEODATA\LOFTEMPS.DAT') -Force
  Copy-Item $sorted[-1].FullName (Join-Path $Out 'TERRAIN\LOFTEMPS.DAT') -Force
  if ($sorted[-1].Length -lt 3648) { "ATTENZIONE: TERRAIN\LOFTEMPS.DAT ha $($sorted[-1].Length) byte (112 forme): quello di TFTD ne ha 3648 (114). Rifare l'estrazione con Extract-TftdZips.ps1." }
}
Get-ChildItem $Out -Directory | ForEach-Object { '{0}: {1} file' -f $_.Name, (Get-ChildItem $_.FullName -File).Count }



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
Get-ChildItem $Out -Directory | ForEach-Object { '{0}: {1} file' -f $_.Name, (Get-ChildItem $_.FullName -File).Count }



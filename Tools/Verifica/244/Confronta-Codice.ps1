<#
  Issue #244, ondata 5: confronta il codice di due eseguibili (prima e dopo uno spostamento di variabili globali in
  una classe) routine per routine, partendo dai .map di Delphi.

  Per ogni routine di codice (sezione 0001) delle unit indicate (o di tutte con -Units '*') che ha lo stesso nome
  nei due .map:
    - la dimensione (differenza tra l'indirizzo del simbolo e quello del successivo) deve essere uguale;
    - i byte devono essere uguali, salvo gli operandi a 32 bit che sono indirizzi di dati in tutti e due gli
      eseguibili (una variabile che cambia posto cambia solo il suo indirizzo assoluto: stessa istruzione,
      stesso opcode, stesso modo di indirizzamento). Un byte diverso fuori da un indirizzo di dati e' un errore.
  Non avvia nessun eseguibile: legge solo i file.

  Uso:  powershell -NoProfile -File Tools\Verifica\244\Confronta-Codice.ps1 -MapA a.map -ExeA a.exe -MapB b.map -ExeB b.exe [-Units p_map,p_sight] [-Verbose]
  Esce con il numero delle routine con differenze di dimensione, di nome o di byte non ammesse.
#>
param(
  [Parameter(Mandatory)][string]$MapA,
  [Parameter(Mandatory)][string]$ExeA,
  [Parameter(Mandatory)][string]$MapB,
  [Parameter(Mandatory)][string]$ExeB,
  [string[]]$Units = @('*')
)
$ErrorActionPreference = 'Stop'
$Units = @($Units | ForEach-Object { $_ -split ',' } | Where-Object { $_ -ne '' })

function Read-Pe([string]$Path) {
  $bytes = [System.IO.File]::ReadAllBytes($Path)
  $pe = [BitConverter]::ToInt32($bytes, 0x3C)
  $count = [BitConverter]::ToUInt16($bytes, $pe + 6)
  $optSize = [BitConverter]::ToUInt16($bytes, $pe + 20)
  $opt = $pe + 24
  $magic = [BitConverter]::ToUInt16($bytes, $opt)
  if ($magic -ne 0x10B) { throw "$Path non e' un PE32" }
  $imageBase = [BitConverter]::ToUInt32($bytes, $opt + 28)
  $sections = @()
  for ($i = 0; $i -lt $count; $i++) {
    $s = $opt + $optSize + 40 * $i
    $sections += [pscustomobject]@{
      Name = [System.Text.Encoding]::ASCII.GetString($bytes, $s, 8).TrimEnd([char]0)
      VirtualSize = [BitConverter]::ToUInt32($bytes, $s + 8)
      Rva = [BitConverter]::ToUInt32($bytes, $s + 12)
      RawSize = [BitConverter]::ToUInt32($bytes, $s + 16)
      RawPtr = [BitConverter]::ToUInt32($bytes, $s + 20)
    }
  }
  return [pscustomobject]@{ Bytes = $bytes; ImageBase = $imageBase; Sections = $sections }
}

function Read-Routines([string]$MapFile) {
  $inSection = $false
  $rows = New-Object System.Collections.Generic.List[object]
  foreach ($line in [System.IO.File]::ReadLines($MapFile)) {
    if ($line -match 'Publics by Value') { $inSection = $true; continue }
    if (-not $inSection) { continue }
    if ($line -match '^\s*0001:([0-9A-F]{8})\s+(\S+)') {
      $rows.Add([pscustomobject]@{ Address = [Convert]::ToInt64($Matches[1], 16); Name = $Matches[2] })
    }
  }
  $result = @{}
  for ($i = 0; $i -lt $rows.Count - 1; $i++) {
    $result[$rows[$i].Name] = [pscustomobject]@{ Address = $rows[$i].Address; Size = $rows[$i + 1].Address - $rows[$i].Address }
  }
  return $result
}

function Test-Wanted([string]$Name) {
  if ($Units -contains '*') { return $true }
  foreach ($u in $Units) { if ($Name -like "$u.*") { return $true } }
  return $false
}

# L'indirizzo dei simboli del .map (0001:xxxxxxxx) e' la distanza dall'inizio della sezione del codice
# (.text): verificato sul prologo `55 8B EC` della prima routine.
function Get-FileOffset($Pe, [int64]$Address) {
  $text = $Pe.Sections | Where-Object { $_.Name -eq '.text' -or $_.Name -eq 'CODE' } | Select-Object -First 1
  return [int64]$text.RawPtr + $Address
}

# nome e distanza dall'inizio della routine che contiene l'indirizzo (per confrontare i salti e le chiamate relativi)
function Resolve-Target($Index, [int64]$Address) {
  $pos = [Array]::BinarySearch($Index.Addresses, $Address)
  if ($pos -lt 0) { $pos = (-$pos - 1) - 1 }
  if ($pos -lt 0) { return '?' }
  return ('{0}+{1}' -f $Index.Names[$pos], ($Address - $Index.Addresses[$pos]))
}

function New-Index($Routines) {
  $sorted = $Routines.GetEnumerator() | Sort-Object { $_.Value.Address }
  return [pscustomobject]@{ Addresses = [int64[]]@($sorted | ForEach-Object { $_.Value.Address }); Names = [string[]]@($sorted | ForEach-Object { $_.Key }) }
}

function Test-DataAddress($Pe, [uint32]$Value) {
  if ($Value -lt $Pe.ImageBase) { return $false }
  $rva = [int64]$Value - [int64]$Pe.ImageBase
  foreach ($s in $Pe.Sections) {
    if ($s.Name -eq '.text' -or $s.Name -eq 'CODE') { continue }
    if ($rva -ge $s.Rva -and $rva -lt $s.Rva + [Math]::Max($s.VirtualSize, $s.RawSize)) { return $true }
  }
  return $false
}

$peA = Read-Pe $ExeA
$peB = Read-Pe $ExeB
$routinesA = Read-Routines $MapA
$routinesB = Read-Routines $MapB
$indexA = New-Index $routinesA
$indexB = New-Index $routinesB
$bad = 0; $compared = 0; $identical = 0; $operandOnly = 0; $shifted = 0
$onlyA = @(); $onlyB = @()
# Confronta i byte di una routine: uguali, oppure diversi solo negli operandi che sono indirizzi di dati in tutti e
# due gli eseguibili o nel bersaglio (per nome) di una chiamata o di un salto relativo.
function Compare-Routine($PeA, $PeB, $A, $B, [int64]$OffA, [int64]$OffB, $IndexA, $IndexB, [int]$Shift) {
  $diffs = New-Object System.Collections.Generic.List[int]
  for ($i = 0; $i -lt $A.Size; $i++) {
    if ($PeA.Bytes[$OffA + $i] -ne $PeB.Bytes[$OffB + $i]) { $diffs.Add($i) }
  }
  if ($diffs.Count -eq 0) { return [pscustomobject]@{ Ok = $true; Exact = $true; At = -1 } }
  $covered = -1
  foreach ($p in $diffs) {
    if ($p -le $covered) { continue }
    $found = $false
    for ($s = [Math]::Max(0, $p - 3); $s -le $p; $s++) {
      if ($s + 4 -gt $A.Size) { continue }
      $va = [BitConverter]::ToUInt32($PeA.Bytes, [int]($OffA + $s))
      $vb = [BitConverter]::ToUInt32($PeB.Bytes, [int]($OffB + $s))
      if ((Test-DataAddress $PeA $va) -and (Test-DataAddress $PeB $vb)) { $covered = $s + 3; $found = $true; break }
      $isRel = $s -ge 1 -and ($PeA.Bytes[$OffA + $s - 1] -eq 0xE8 -or $PeA.Bytes[$OffA + $s - 1] -eq 0xE9 -or
        ($s -ge 2 -and $PeA.Bytes[$OffA + $s - 2] -eq 0x0F -and $PeA.Bytes[$OffA + $s - 1] -ge 0x80 -and $PeA.Bytes[$OffA + $s - 1] -le 0x8F))
      if ($isRel) {
        $ta = Resolve-Target $IndexA ($A.Address + $Shift + $s + 4 + [BitConverter]::ToInt32($PeA.Bytes, [int]($OffA + $s)))
        $tb = Resolve-Target $IndexB ($B.Address + $s + 4 + [BitConverter]::ToInt32($PeB.Bytes, [int]($OffB + $s)))
        if ($ta -eq $tb -and $ta -ne '?') { $covered = $s + 3; $found = $true; break }
      }
    }
    if (-not $found) { return [pscustomobject]@{ Ok = $false; Exact = $false; At = $p } }
  }
  return [pscustomobject]@{ Ok = $true; Exact = $false; At = -1 }
}

foreach ($name in ($routinesA.Keys | Sort-Object)) {
  if (-not (Test-Wanted $name)) { continue }
  if (-not $routinesB.ContainsKey($name)) { $onlyA += $name; continue }
  $a = $routinesA[$name]; $b = $routinesB[$name]
  $compared++
  if ($a.Size -ne $b.Size) {
    $bad++
    Write-Host ('DIMENSIONE  {0}: {1} -> {2}' -f $name, $a.Size, $b.Size)
    continue
  }
  $offA = Get-FileOffset $peA $a.Address
  $offB = Get-FileOffset $peB $b.Address
  $shiftUsed = $null
  $result = $null
  foreach ($shift in @(0, 4, -4, 8, -8, 1, -1, 2, -2, 3, -3)) {
    $result = Compare-Routine $peA $peB $a $b ($offA + $shift) $offB $indexA $indexB $shift
    if ($result.Ok) { $shiftUsed = $shift; break }
  }
  if ($null -eq $shiftUsed) {
    $bad++
    $first = (Compare-Routine $peA $peB $a $b $offA $offB $indexA $indexB 0)
    Write-Host ('BYTE        {0}: diverso al byte +{1} fuori da un indirizzo di dati' -f $name, $first.At)
  }
  elseif ($shiftUsed -ne 0) { $shifted++ }
  elseif ($result.Exact) { $identical++ }
  else { $operandOnly++ }
}
foreach ($name in $routinesB.Keys) {
  if ((Test-Wanted $name) -and -not $routinesA.ContainsKey($name)) { $onlyB += $name }
}
Write-Host ('Routine confrontate: {0}; byte identici: {1}; diverse solo negli indirizzi di dati o nei bersagli delle chiamate: {2}; traslate nel .map ma uguali: {4}; con differenze non ammesse: {3}' -f $compared, $identical, $operandOnly, $bad, $shifted)
if ($onlyA.Count -gt 0) { Write-Host ('Solo nel primo: ' + ($onlyA -join ', ')) }
if ($onlyB.Count -gt 0) { Write-Host ('Solo nel secondo: ' + ($onlyB -join ', ')) }
exit $bad

<#
  Issue #245, sesta tornata: confronta le dimensioni di tutte le routine di codice (sezione 0001) di due .map di
  Delphi (prima e dopo lo spostamento di variabili globali in TGameSession). La dimensione di un simbolo e' la
  differenza tra il suo indirizzo e quello del simbolo seguente. Stampa le routine con la stessa sigla e dimensione
  diversa, quelle che compaiono in un solo .map e un riepilogo; esce con il numero delle diverse.
  Non avvia nessun eseguibile: legge solo i file.

  Uso:  powershell -NoProfile -File Tools\Verifica\245\Confronta-Mappe.ps1 -MapA base.map -MapB nuova.map
#>
param(
  [Parameter(Mandatory)][string]$MapA,
  [Parameter(Mandatory)][string]$MapB
)
$ErrorActionPreference = 'Stop'

function Read-Sizes([string]$MapFile) {
  $inSection = $false
  $names = New-Object System.Collections.Generic.List[string]
  $addresses = New-Object System.Collections.Generic.List[long]
  foreach ($line in [System.IO.File]::ReadLines($MapFile)) {
    if (-not $inSection) {
      if ($line -match 'Publics by Value') { $inSection = $true }
      continue
    }
    if ($line -match '^\s*0001:([0-9A-F]{8})\s+(\S+)') {
      $addresses.Add([Convert]::ToInt64($Matches[1], 16))
      $names.Add($Matches[2])
    }
  }
  $result = New-Object 'System.Collections.Generic.Dictionary[string,long]'
  for ($i = 0; $i -lt $names.Count - 1; $i++) {
    $result[$names[$i]] = $addresses[$i + 1] - $addresses[$i]
  }
  return $result
}

$a = Read-Sizes $MapA
$b = Read-Sizes $MapB
$different = 0
$onlyA = 0
$onlyB = 0
foreach ($name in $a.Keys) {
  if ($b.ContainsKey($name)) {
    if ($a[$name] -ne $b[$name]) {
      $different++
      '{0,-70} {1,6} -> {2,6}' -f $name, $a[$name], $b[$name]
    }
  }
  else { $onlyA++; 'SOLO-A     ' + $name }
}
foreach ($name in $b.Keys) {
  if (-not $a.ContainsKey($name)) { $onlyB++; 'SOLO-B     ' + $name }
}
'Routine: A {0}, B {1}; dimensione diversa {2}; solo in A {3}; solo in B {4}' -f $a.Count, $b.Count, $different, $onlyA, $onlyB
exit $different

# Dimensioni delle routine di un'unit da un .map di Delphi (issue #244): la dimensione e' la
# differenza tra l'indirizzo di un simbolo del codice (sezione 0001) e quello del successivo.
# Uso: .\Dimensioni-Routine.ps1 -Map <file.map> [-Unit p_map] [-Out <file>]
param(
  [Parameter(Mandatory)][string]$Map,
  [string]$Unit = 'p_map',
  [string]$Out
)

$LInSection = $false
$LRows = New-Object System.Collections.Generic.List[object]
foreach ($LLine in [System.IO.File]::ReadLines($Map)) {
  if ($LLine -match 'Publics by Value') { $LInSection = $true; continue }
  if (-not $LInSection) { continue }
  if ($LLine -match '^\s*0001:([0-9A-F]{8})\s+(\S+)') {
    $LRows.Add([pscustomobject]@{ Address = [Convert]::ToInt64($Matches[1], 16); Name = $Matches[2] })
  }
}
$LResult = @()
for ($LIndex = 0; $LIndex -lt $LRows.Count - 1; $LIndex++) {
  if ($LRows[$LIndex].Name -like "$Unit.*") {
    $LResult += ('{0,-45} {1,6}' -f $LRows[$LIndex].Name, ($LRows[$LIndex + 1].Address - $LRows[$LIndex].Address))
  }
}
if ($Out) { $LResult | Set-Content -Encoding ascii $Out } else { $LResult }

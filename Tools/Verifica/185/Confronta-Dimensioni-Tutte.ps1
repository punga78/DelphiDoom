# Issue #185: confronta la dimensione di TUTTE le routine di due .map di Delphi (base e nuovo), senza avviare nulla.
# La dimensione e' la differenza tra l'indirizzo di un simbolo del codice (sezione 0001) e quello del successivo.
# Uso: .\Confronta-Dimensioni-Tutte.ps1 -MapBase <a.map> -MapNew <b.map> [-Filter '^(g_game|p_)']
# Stampa: routine con dimensione diversa (base -> nuovo, differenza), routine solo nella base, solo nel nuovo.
param(
  [Parameter(Mandatory)][string]$MapBase,
  [Parameter(Mandatory)][string]$MapNew,
  [string]$Filter = ''
)

function Read-Sizes([string]$Map) {
  $LRows = New-Object System.Collections.Generic.List[object]
  $LIn = $false
  foreach ($LLine in [System.IO.File]::ReadLines($Map)) {
    if ($LLine -match 'Publics by Value') { $LIn = $true; continue }
    if (-not $LIn) { continue }
    if ($LLine -match '^\s*0001:([0-9A-F]{8})\s+(\S+)') {
      $LRows.Add([pscustomobject]@{ Address = [Convert]::ToInt64($Matches[1], 16); Name = $Matches[2] })
    }
  }
  $LResult = @{}
  for ($LIndex = 0; $LIndex -lt $LRows.Count - 1; $LIndex++) {
    $LResult[$LRows[$LIndex].Name] = $LRows[$LIndex + 1].Address - $LRows[$LIndex].Address
  }
  $LResult
}

$LBase = Read-Sizes $MapBase
$LNew = Read-Sizes $MapNew
$LDiff = 0
foreach ($LName in ($LBase.Keys | Sort-Object)) {
  if ($Filter -ne '' -and $LName -notmatch $Filter) { continue }
  if ($LNew.ContainsKey($LName)) {
    if ($LNew[$LName] -ne $LBase[$LName]) {
      '{0,-60} {1,7} -> {2,7} ({3:+#;-#;0})' -f $LName, $LBase[$LName], $LNew[$LName], ($LNew[$LName] - $LBase[$LName])
      $LDiff++
    }
  }
  else { 'SOLO BASE  {0} ({1})' -f $LName, $LBase[$LName] }
}
foreach ($LName in ($LNew.Keys | Sort-Object)) {
  if ($Filter -ne '' -and $LName -notmatch $Filter) { continue }
  if (-not $LBase.ContainsKey($LName)) { 'SOLO NUOVO {0} ({1})' -f $LName, $LNew[$LName] }
}
"Routine con dimensione diversa: $LDiff"

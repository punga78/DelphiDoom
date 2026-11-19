# Issue #185 (ondata 13): confronta due .map (base e nuovo): ordine e dimensione del codice di ogni unit e ordine relativo delle unit con initialization/finalization. Da usare con build pulite (clean): le incrementali danno differenze di 4 byte senza causa.
# Confronta ordine e dimensione del codice per unit tra due .map (segmento CODE) e l'ordine relativo delle unit con initialization/finalization.
param([Parameter(Mandatory)][string]$BaseMap, [Parameter(Mandatory)][string]$NewMap, [string]$Root = (Get-Location).Path)
function Get-Units([string]$map) {
  $r = New-Object System.Collections.Generic.List[object]
  $in = $false
  foreach ($l in [IO.File]::ReadLines($map)) {
    if ($l -match 'Detailed map of segments') { $in = $true; continue }
    if (-not $in) { continue }
    if ($l -match '^\s*0001:([0-9A-F]{8}) ([0-9A-F]{8}) C=CODE\s+S=\S+\s+G=\S+\s+M=(\S+)') { $r.Add([pscustomobject]@{ Name = $Matches[3]; Len = [Convert]::ToInt64($Matches[2], 16) }) }
    elseif ($l -match 'Line numbers') { break }
  }
  $r
}
$b = Get-Units $BaseMap; $n = Get-Units $NewMap
"unit in base {0}, in nuovo {1}" -f $b.Count, $n.Count
# unit con initialization/finalization (nei sorgenti del repository)
$initUnits = @{}
Get-ChildItem -Path $Root -Recurse -Include *.pas -File -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notmatch '\\(bin|dcu|Reference)\\' } | ForEach-Object {
  $t = [IO.File]::ReadAllText($_.FullName, [Text.Encoding]::GetEncoding(28591))
  if ($t -match '(?im)^\s*(initialization|finalization)\b') { $initUnits[$_.BaseName] = 1 }
}
$bo = ($b | Where-Object { $initUnits.ContainsKey($_.Name) } | ForEach-Object { $_.Name }) -join ','
$no = ($n | Where-Object { $initUnits.ContainsKey($_.Name) } | ForEach-Object { $_.Name }) -join ','
"unit con initialization: base {0}, nuovo {1}; ordine relativo uguale: {2}" -f @($b | Where-Object { $initUnits.ContainsKey($_.Name) }).Count, @($n | Where-Object { $initUnits.ContainsKey($_.Name) }).Count, ($bo -eq $no)
if ($bo -ne $no) {
  $ba = $bo -split ','; $na = $no -split ','
  $diff = Compare-Object $ba $na -SyncWindow 0 | Select-Object -First 10
  $diff | ForEach-Object { "   " + $_.SideIndicator + " " + $_.InputObject }
}
# dimensioni per unit
$bm = @{}; foreach ($u in $b) { $bm[$u.Name] = $u.Len }
$diffs = @(); foreach ($u in $n) { if ($bm.ContainsKey($u.Name)) { if ($bm[$u.Name] -ne $u.Len) { $diffs += ("{0} {1} -> {2}" -f $u.Name, $bm[$u.Name], $u.Len) } } else { $diffs += ("SOLO NUOVA " + $u.Name) } }
foreach ($u in $b) { if (-not ($n | Where-Object Name -eq $u.Name)) { $diffs += ("SOLO BASE " + $u.Name) } }
"unit con dimensione diversa o assenti: " + $diffs.Count
$diffs | Select-Object -First 30
$sameOrder = (($b | ForEach-Object Name) -join ',') -eq (($n | ForEach-Object Name) -join ',')
"ordine completo delle unit uguale: $sameOrder"


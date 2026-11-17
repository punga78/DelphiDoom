<#
  Issue #185 (ondata 11): prova del costo di una conversione routine libera -> metodo statico, senza avviare nulla.
  Legge due .map (base e nuovo) e i due exe, toglie dal nome nuovo il segmento della classe (-Classes), e per ogni
  routine confronta DIMENSIONE e BYTE del codice. Stampa le routine con dimensione diversa, quelle con byte diversi
  (con il numero di byte e la posizione del primo: di solito un indirizzo assoluto di dato o un salto verso una routine
  che si e' spostata; poi si guarda con Confronta-Routine.ps1) e i totali.
  Uso: Prova-Costo.ps1 -BaseExe a.exe -BaseMap a.map -NewExe b.exe -NewMap b.map -Classes TDoomWeaponActions,... [-Only <regex sul nome nuovo>]
#>
param(
  [Parameter(Mandatory)][string]$BaseExe, [Parameter(Mandatory)][string]$BaseMap,
  [Parameter(Mandatory)][string]$NewExe, [Parameter(Mandatory)][string]$NewMap,
  [Parameter(Mandatory)][string[]]$Classes,
  [string]$Only = '',
  [switch]$Win64
)
$Classes = @($Classes | ForEach-Object { $_ -split ',' } | Where-Object { $_ -ne '' })
function Get-CodeBase([byte[]]$Bytes) {
  $pe = [BitConverter]::ToInt32($Bytes, 0x3C)
  $sections = [BitConverter]::ToUInt16($Bytes, $pe + 6)
  $optSize = [BitConverter]::ToUInt16($Bytes, $pe + 20)
  $sec = $pe + 24 + $optSize
  # la prima sezione e' il codice: RVA e posizione nel file
  @{ Rva = [BitConverter]::ToUInt32($Bytes, $sec + 12); Raw = [BitConverter]::ToUInt32($Bytes, $sec + 20) }
}
function Read-Routines([string]$Exe, [string]$Map, [bool]$Strip) {
  $bytes = [IO.File]::ReadAllBytes($Exe)
  $cb = Get-CodeBase $bytes
  $rows = New-Object System.Collections.Generic.List[object]
  $in = $false
  foreach ($line in [IO.File]::ReadLines($Map)) {
    if ($line -match 'Publics by Value') { $in = $true; continue }
    if (-not $in) { continue }
    if ($line -match '^\s*0001:([0-9A-F]{8})\s+(\S+)') { $rows.Add([pscustomobject]@{ A = [Convert]::ToInt64($Matches[1], 16); N = $Matches[2] }) }
  }
  $res = @{}
  for ($i = 0; $i -lt $rows.Count - 1; $i++) {
    $name = $rows[$i].N
    if ($Strip) { foreach ($c in $Classes) { $name = $name.Replace('.' + $c + '.', '.') } }
    $size = $rows[$i + 1].A - $rows[$i].A
    $off = $cb.Raw + $rows[$i].A
    if ($size -le 0 -or $size -gt 200000 -or $off + $size -gt $bytes.Length) { continue }
    $res[$name] = @{ Size = $size; Bytes = $bytes; Off = $off; Addr = $rows[$i].A }
  }
  $res
}
$base = Read-Routines $BaseExe $BaseMap $false
$new = Read-Routines $NewExe $NewMap $true
$same = 0; $sizeDiff = 0; $byteDiff = 0; $missing = 0; $checked = 0
foreach ($k in ($new.Keys | Sort-Object)) {
  if ($Only -ne '' -and $k -notmatch $Only) { continue }
  if (-not $base.ContainsKey($k)) { Write-Output ('SOLO NUOVO ' + $k); $missing++; continue }
  $checked++
  $b = $base[$k]; $n = $new[$k]
  if ($b.Size -ne $n.Size) { Write-Output ('DIMENSIONE   {0}  {1} -> {2}' -f $k, $b.Size, $n.Size); $sizeDiff++; continue }
  $d = 0; $first = -1
  for ($j = 0; $j -lt $b.Size; $j++) {
    if ($b.Bytes[$b.Off + $j] -ne $n.Bytes[$n.Off + $j]) { $d++; if ($first -lt 0) { $first = $j } }
  }
  if ($d -gt 0) { Write-Output ('BYTE DIVERSI {0}  {1} byte su {2}, il primo a +{3}' -f $k, $d, $b.Size, $first); $byteDiff++ } else { $same++ }
}
Write-Output ('Controllate {0}: uguali byte per byte {1}, byte diversi {2}, dimensione diversa {3}, solo nuove {4}' -f $checked, $same, $byteDiff, $sizeDiff, $missing)

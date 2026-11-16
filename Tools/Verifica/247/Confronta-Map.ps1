<#
  Issue #247: prova del costo del codice caldo con i file .map di Delphi (due eseguibili, vecchio e nuovo).
  Per ogni unit confronta la dimensione del segmento di codice (C=CODE) e, con -Routine, di ogni routine (una routine
  va dal suo indirizzo al successivo nella tabella "Publics by Value"). Stampa solo cio' che e' diverso.
  Una routine che e' passata in una classe cambia nome (unit.Classe.Metodo): con -Rename 'vecchio=nuovo' si
  confrontano a coppie.

  Uso:
    powershell -NoProfile -File Tools\Verifica\247\Confronta-Map.ps1 -Old base\Doom32.map -New bin\...\Doom32.map
      [-Unit 'r_*'] [-Routine] [-Rename 'r_draw.R_DrawColumn=r_draw.TColumnDrawer.DrawColumn']
#>
param(
  [Parameter(Mandatory = $true)][string]$Old,
  [Parameter(Mandatory = $true)][string]$New,
  [string]$Unit = '*',
  [switch]$Routine,
  [string[]]$Rename = @()
)
function Read-Map([string]$Path) {
  $units = @{}
  $routines = @{}
  $starts = New-Object System.Collections.Generic.List[object]
  $section = ''
  foreach ($line in [IO.File]::ReadLines($Path)) {
    if ($line -match '^Detailed map of segments') { $section = 'seg'; continue }
    if ($line -match 'Publics by Name') { $section = 'name'; continue }
    if ($line -match 'Publics by Value') { $section = 'value'; continue }
    if ($section -eq 'seg' -and $line -match '^\s*0001:([0-9A-F]{8})\s+([0-9A-F]{8})\s+C=CODE\s+S=\S+\s+G=\S+\s+M=(\S+)') {
      $units[$Matches[3]] = [Convert]::ToInt64($Matches[2], 16) + $(if ($units.ContainsKey($Matches[3])) { $units[$Matches[3]] } else { 0 })
    }
    if ($section -eq 'value' -and $line -match '^\s*0001:([0-9A-F]{8})\s+(\S+)') {
      $starts.Add(@([Convert]::ToInt64($Matches[1], 16), $Matches[2]))
    }
  }
  for ($i = 0; $i -lt $starts.Count - 1; $i++) {
    $size = $starts[$i + 1][0] - $starts[$i][0]
    $routines[$starts[$i][1]] = $size
  }
  @{ Units = $units; Routines = $routines }
}
$a = Read-Map $Old
$b = Read-Map $New
$renames = @{}
foreach ($r in $Rename) { $p = $r -split '=', 2; $renames[$p[0]] = $p[1] }
$diff = 0
$same = 0
foreach ($u in ($a.Units.Keys | Sort-Object)) {
  if ($u -notlike $Unit) { continue }
  if (-not $b.Units.ContainsKey($u)) { Write-Output "unit $u : assente nel nuovo"; $diff++; continue }
  if ($a.Units[$u] -ne $b.Units[$u]) { Write-Output ("unit {0,-40} codice {1} -> {2} ({3:+#;-#;0})" -f $u, $a.Units[$u], $b.Units[$u], ($b.Units[$u] - $a.Units[$u])); $diff++ } else { $same++ }
}
foreach ($u in ($b.Units.Keys | Sort-Object)) { if ($u -like $Unit -and -not $a.Units.ContainsKey($u)) { Write-Output ("unit {0,-40} nuova: codice {1}" -f $u, $b.Units[$u]) } }
Write-Output "unit uguali: $same, diverse o assenti: $diff"
if ($Routine) {
  $rd = 0; $rs = 0
  foreach ($r in ($a.Routines.Keys | Sort-Object)) {
    $unitName = ($r -split '\.')[0]
    if ($unitName -notlike $Unit) { continue }
    $target = $r
    if ($renames.ContainsKey($r)) { $target = $renames[$r] }
    if (-not $b.Routines.ContainsKey($target)) { continue }
    if ($a.Routines[$r] -ne $b.Routines[$target]) { Write-Output ("  {0} {1} -> {2}" -f $r, $a.Routines[$r], $b.Routines[$target]); $rd++ } else { $rs++ }
  }
  Write-Output "routine uguali: $rs, diverse: $rd"
}

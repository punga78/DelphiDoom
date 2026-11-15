<#
  Issue #197: confronta riga per riga i pixel di due fotogrammi RGBA di 320 x 200 x 4 byte (quelli che scrive il comando
  "rgba FILE" del C, war_frame_ref.c, e quello di Delphi: TWarUiScriptRunner e il test DelphiDoom.Tests.War.UiParity con
  DELPHIDOOM_WAR_UI_DUMP). Dice la prima riga che differisce, i primi pixel diversi (x, y, i quattro canali dei due), e quanti
  pixel differiscono in ogni riga (le righe con differenze, in ordine).

  Il fotogramma del C si ottiene con Confronta-Traccia.ps1 -Pixel (scrive <script>.c.rgba: l'ULTIMO fotogramma dello script);
  quello di Delphi e' <cartella>\<script>.delphi.rgba, scritto dal test quando un'impronta differisce.

  Uso:
    powershell -NoProfile -File Tools\Verifica\197\Confronta-Pixel.ps1 -C <file>.c.rgba -Delphi <file>.delphi.rgba [-Primi 20]
#>
param(
  [Parameter(Mandatory)][string]$C,
  [Parameter(Mandatory)][string]$Delphi,
  [int]$Primi = 20,
  [int]$Larghezza = 320,
  [int]$Altezza = 200
)
$ErrorActionPreference = 'Stop'
$a = [IO.File]::ReadAllBytes($C)
$b = [IO.File]::ReadAllBytes($Delphi)
$expected = $Larghezza * $Altezza * 4
if ($a.Length -ne $expected -or $b.Length -ne $expected) {
  throw "Misure diverse da $expected byte: C $($a.Length), Delphi $($b.Length)"
}
$rows = @{}
$first = New-Object System.Collections.Generic.List[string]
$total = 0
for ($y = 0; $y -lt $Altezza; $y++) {
  for ($x = 0; $x -lt $Larghezza; $x++) {
    $i = ($y * $Larghezza + $x) * 4
    if ($a[$i] -ne $b[$i] -or $a[$i + 1] -ne $b[$i + 1] -or $a[$i + 2] -ne $b[$i + 2] -or $a[$i + 3] -ne $b[$i + 3]) {
      $total++
      if (-not $rows.ContainsKey($y)) { $rows[$y] = 0 }
      $rows[$y]++
      if ($first.Count -lt $Primi) {
        $first.Add(("  x={0} y={1}  C {2},{3},{4},{5}  Delphi {6},{7},{8},{9}" -f $x, $y, $a[$i], $a[$i + 1], $a[$i + 2], $a[$i + 3], $b[$i], $b[$i + 1], $b[$i + 2], $b[$i + 3]))
      }
    }
  }
}
if ($total -eq 0) { 'Pixel uguali (' + ($Larghezza * $Altezza) + ' su ' + ($Larghezza * $Altezza) + ')'; return }
"Pixel diversi: $total su $($Larghezza * $Altezza)"
"Prima riga con differenze: $(($rows.Keys | Sort-Object | Select-Object -First 1))"
'Primi pixel diversi (R,G,B,A):'
$first
'Pixel diversi per riga:'
$rows.Keys | Sort-Object | ForEach-Object { "  riga {0}: {1}" -f $_, $rows[$_] }

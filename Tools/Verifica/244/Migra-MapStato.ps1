<#
  Issue #244, ondata 5: sostituzione meccanica dei nomi storici dello scorrimento, del tiro e dell'uso di p_map
  (bestslidefrac, linetarget, usething, ...) con i campi delle classi dichiarate in IdTech1\Base\p_map.pas
  (TMapSlide, TMapAim, TMapUse, TMapBlast e TMapCheck), come Migra-MapCheck.ps1 fa per tm* e spechit.
  Per ogni nome: parola intera, senza distinguere maiuscole, in ogni .pas sotto IdTech1 (o solo nei file di 'Solo'
  della tabella); in p_map.pas toglie prima le righe di dichiarazione. BOM, fine riga e codifica restano (Latin-1).

  Uso:  powershell -NoProfile -File Tools\Verifica\244\Migra-MapStato.ps1 -Group Slide|Aim|Use [-WhatIf]
#>
param(
  [Parameter(Mandatory)][ValidateSet('Slide', 'Aim', 'Use')][string]$Group,
  [switch]$WhatIf
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
. (Join-Path $PSScriptRoot 'MapStato-Nomi.ps1')
$latin1 = [System.Text.Encoding]::GetEncoding(28591)
$entries = $MapStatoGroups[$Group]
$changed = @()
foreach ($file in Get-ChildItem -Path (Join-Path $root 'IdTech1') -Recurse -Filter *.pas) {
  if ($file.Name -eq 'po_man.pas') { continue }
  $text = $latin1.GetString([System.IO.File]::ReadAllBytes($file.FullName))
  $new = $text
  $counter = New-Object 'int[]' 1
  foreach ($entry in $entries) {
    if ($entry.Solo -and ($entry.Solo -notcontains $file.Name)) { continue }
    $old = [regex]::Escape($entry.Old)
    if ($file.Name -eq 'p_map.pas') {
      $new = [regex]::Replace($new, "^[ \t]*$old[ \t]*:(?!=)[^\r\n]*\r?\n", '', 'IgnoreCase, Multiline')
    }
    $replacement = $entry.Class + '.' + $entry.Field
    $evaluator = [System.Text.RegularExpressions.MatchEvaluator] {
      param($m)
      $counter[0]++
      return $replacement
    }.GetNewClosure()
    $new = [regex]::Replace($new, "(?<![\w.])$old(?!\w)", $evaluator, 'IgnoreCase')
  }
  if ($new -ne $text) {
    $changed += [pscustomobject]@{ File = $file.FullName.Substring($root.Length + 1); Count = $counter[0] }
    if (-not $WhatIf) { [System.IO.File]::WriteAllBytes($file.FullName, $latin1.GetBytes($new)) }
  }
}
$changed | Format-Table -AutoSize
'Totale sostituzioni: ' + ($changed | Measure-Object Count -Sum).Sum

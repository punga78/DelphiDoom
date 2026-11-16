<#
  Issue #244, passo di migrazione di p_map: sostituzione meccanica dei nomi dello stato di P_CheckPosition
  (tmthing, tmbbox, ...) con i campi della classe TMapCheck, dichiarata in IdTech1\Base\p_map.pas (la classe
  sta nella stessa unit delle routine PIT_* e P_CheckPosition apposta: un class var di un'altra unit e'
  raggiunto da p_map con un indirizzo in piu' da caricare, vedi docs\PIANO_TUTTO_A_CLASSI.md par. 11.16).

  Che cosa fa, per il gruppo scelto (-Group Tm | Spec):
    1. in ogni .pas sotto IdTech1 (tranne po_man.pas, che ha una sua variabile locale tmbbox) cambia ogni parola
       intera col campo di TMapCheck (senza distinguere maiuscole, anche nei commenti);
    2. in p_map.pas toglie prima le righe di dichiarazione delle variabili migrate (la classe e i commenti
       si sistemano a mano).
  Nessuna uses e nessun .dpr cambia: tutte le unit che usavano i nomi usavano gia' p_map.
  Preserva byte per byte tutto il resto (BOM, CRLF o LF, codifica): legge e scrive in Latin-1.

  Uso:  powershell -NoProfile -File Tools\Verifica\244\Migra-MapCheck.ps1 -Group Tm [-WhatIf]
#>
param(
  [Parameter(Mandatory)][ValidateSet('Tm', 'Spec')][string]$Group,
  [switch]$WhatIf
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
. (Join-Path $PSScriptRoot 'MapCheck-Nomi.ps1')

$map = $MapCheckGroups[$Group]
$alternation = ($map.Keys | ForEach-Object { [regex]::Escape($_) }) -join '|'
$wordRegex = New-Object System.Text.RegularExpressions.Regex("(?<![\w.])($alternation)(?!\w)", 'IgnoreCase')
# una dichiarazione e' "nome: tipo", mai "nome := valore"
$declRegex = New-Object System.Text.RegularExpressions.Regex("^[ \t]*($alternation)[ \t]*:(?!=)[^\r\n]*\r?\n", 'IgnoreCase, Multiline')
$latin1 = [System.Text.Encoding]::GetEncoding(28591)

$changed = @()
foreach ($file in Get-ChildItem -Path (Join-Path $root 'IdTech1') -Recurse -Filter *.pas) {
  if ($file.Name -eq 'po_man.pas') { continue }
  $text = $latin1.GetString([System.IO.File]::ReadAllBytes($file.FullName))
  if (-not $wordRegex.IsMatch($text)) { continue }
  $new = $text
  if ($file.Name -eq 'p_map.pas') { $new = $declRegex.Replace($new, '') }
  $script:count = 0
  $new = $wordRegex.Replace($new, {
      param($m)
      $script:count++
      return 'TMapCheck.' + $map[$m.Value.ToLowerInvariant()]
    })
  $changed += [pscustomobject]@{ File = $file.FullName.Substring($root.Length + 1); Count = $script:count }
  if (-not $WhatIf) { [System.IO.File]::WriteAllBytes($file.FullName, $latin1.GetBytes($new)) }
}
$changed | Format-Table -AutoSize
'Totale sostituzioni: ' + ($changed | Measure-Object Count -Sum).Sum

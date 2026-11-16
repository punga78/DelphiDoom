<#
  Issue #244, passo di migrazione di p_map: sostituzione meccanica dei nomi dello stato di P_CheckPosition
  (tmthing, tmbbox, ...) con i campi della classe TMapCheck (IdTech1\Base\DelphiDoom.Engine.World.MapCheck.pas).

  Che cosa fa, per il gruppo scelto (-Group Tm | Spec):
    1. in ogni .pas sotto IdTech1 (tranne po_man.pas, che ha una sua variabile locale tmbbox) cambia ogni parola
       intera col campo di TMapCheck (senza distinguere maiuscole, anche nei commenti);
    2. in p_map.pas toglie prima le righe di dichiarazione delle variabili migrate;
    3. nei .pas che hanno usato la classe aggiunge DelphiDoom.Engine.World.MapCheck alla clausola uses della
       sezione implementation (o, se manca, lo dice);
    4. nei .dpr che elencano p_map aggiunge l'unit nuova (se manca).
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

$unit = 'DelphiDoom.Engine.World.MapCheck'
$map = $MapCheckGroups[$Group]
$names = $map.Keys
$alternation = ($names | ForEach-Object { [regex]::Escape($_) }) -join '|'
$wordRegex = New-Object System.Text.RegularExpressions.Regex("(?<![\w.])($alternation)(?!\w)", 'IgnoreCase')
$declRegex = New-Object System.Text.RegularExpressions.Regex("^[ \t]*($alternation)[ \t]*:[^\r\n]*\r?\n", 'IgnoreCase, Multiline')
$latin1 = [System.Text.Encoding]::GetEncoding(28591)

$changed = @()
foreach ($file in Get-ChildItem -Path (Join-Path $root 'IdTech1') -Recurse -Filter *.pas) {
  if ($file.Name -eq 'po_man.pas' -or $file.Name -eq "$unit.pas") { continue }
  $text = $latin1.GetString([System.IO.File]::ReadAllBytes($file.FullName))
  if (-not $wordRegex.IsMatch($text)) { continue }
  $isPMap = $file.Name -eq 'p_map.pas'
  $new = $text
  if ($isPMap) { $new = $declRegex.Replace($new, '') }
  $script:count = 0
  $new = $wordRegex.Replace($new, {
      param($m)
      $script:count++
      return 'TMapCheck.' + $map[$m.Value.ToLowerInvariant()]
    })
  # la clausola uses della sezione implementation
  $nl = if ($new.Contains("`r`n")) { "`r`n" } else { "`n" }
  if ($new -notmatch [regex]::Escape($unit)) {
    $usesRegex = New-Object System.Text.RegularExpressions.Regex('(?<=\r?\nimplementation\r?\n(?:\s*\r?\n)*uses\r?\n)', 'IgnoreCase')
    $m = $usesRegex.Match($new)
    if ($m.Success) {
      $new = $new.Insert($m.Index, "  $unit,$nl")
    } else {
      Write-Warning "$($file.Name): nessuna uses di implementation, da aggiungere a mano"
    }
  }
  $changed += [pscustomobject]@{ File = $file.FullName.Substring($root.Length + 1); Count = $script:count }
  if (-not $WhatIf) { [System.IO.File]::WriteAllBytes($file.FullName, $latin1.GetBytes($new)) }
}
$changed | Format-Table -AutoSize
'Totale sostituzioni: ' + ($changed | Measure-Object Count -Sum).Sum

# i .dpr
foreach ($dpr in Get-ChildItem -Path (Join-Path $root 'IdTech1') -Recurse -Filter *.dpr) {
  $text = $latin1.GetString([System.IO.File]::ReadAllBytes($dpr.FullName))
  if ($text -notmatch "p_map in '\.\.\\Base\\p_map\.pas'" -or $text -match [regex]::Escape($unit)) { continue }
  $nl = if ($text.Contains("`r`n")) { "`r`n" } else { "`n" }
  $line = "  $unit in '..\Base\$unit.pas',$nl"
  $new = $text -replace "(?m)^(  p_map in '\.\.\\Base\\p_map\.pas',\r?\n)", ($line.Replace('$', '$$') + '$1')
  Write-Host "dpr: $($dpr.Name)"
  if (-not $WhatIf) { [System.IO.File]::WriteAllBytes($dpr.FullName, $latin1.GetBytes($new)) }
}

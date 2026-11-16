<#
  Issue #244, ondata 5: prova meccanica sul testo della migrazione dello scorrimento, del tiro e dell'uso di p_map
  (Migra-MapStato.ps1), come Prova-MapCheck.ps1 per tm* e spechit.

  Per ogni .pas modificato rispetto al commit di partenza (-Base, predefinito HEAD: un commit per gruppo) rifa'
  la strada al contrario sul testo nuovo (ogni Classe.Campo del gruppo torna al suo nome storico) e lo confronta
  riga per riga col vecchio. Le differenze ammesse sono le righe di dichiarazione delle variabili migrate in
  p_map.pas (con le righe vuote, i `var` e i commenti attorno) e il blocco `type` delle classi. Inoltre i nomi
  storici non devono piu' comparire nel testo nuovo (parola intera, fuori dai commenti) nei file in cui valgono.

  Uso:  powershell -NoProfile -File Tools\Verifica\244\Prova-MapStato.ps1 -Group Slide|Aim|Use [-Base HEAD]
  Esce con il numero dei file con differenze.
#>
param(
  [Parameter(Mandatory)][ValidateSet('Slide', 'Aim', 'Use')][string]$Group,
  [string]$Base = 'HEAD'
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
. (Join-Path $PSScriptRoot 'MapStato-Nomi.ps1')
$latin1 = [System.Text.Encoding]::GetEncoding(28591)
$entries = $MapStatoGroups[$Group]
$typeBlock = '(?s)\r?\ntype\r?\n(?:  ///[^\r\n]*\r?\n)+  TMapCheck = class sealed.*?\r?\n  end;\r?\n(?:\r?\n(?:  ///[^\r\n]*\r?\n)+  TMap\w+ = class sealed.*?\r?\n  end;\r?\n)*'
$declAlternation = ($entries | ForEach-Object { [regex]::Escape($_.Old) }) -join '|'
$declRegex = New-Object System.Text.RegularExpressions.Regex("^\s*($declAlternation)\s*:(?!=)", 'IgnoreCase')

$files = & git -C $root diff --name-only $Base -- IdTech1 | Where-Object { $_ -match '\.(pas|dpr)$' }
$bad = 0
$total = 0
foreach ($rel in $files) {
  $leaf = Split-Path -Leaf $rel
  $newText = $latin1.GetString([System.IO.File]::ReadAllBytes((Join-Path $root $rel)))
  $tmp = [System.IO.Path]::GetTempFileName()
  & cmd /c "git -C `"$root`" show ${Base}:$rel > `"$tmp`""
  $oldText = $latin1.GetString([System.IO.File]::ReadAllBytes($tmp))
  Remove-Item -LiteralPath $tmp
  $newText = [regex]::Replace($newText, $typeBlock, '')
  $oldText = [regex]::Replace($oldText, $typeBlock, '')
  $back = $newText
  foreach ($entry in $entries) {
    $field = [regex]::Escape($entry.Class + '.' + $entry.Field)
    $oldName = $entry.Old
    $back = [regex]::Replace($back, "(?<![\w.])$field(?!\w)", { param($m) $oldName }.GetNewClosure(), 'IgnoreCase')
  }
  $newLines = @($back -split "`r?`n" | Where-Object { $_ -notmatch 'issue #244|(is|are) in TMap\w+' })
  $oldLines = @($oldText -split "`r?`n")
  $i = 0; $j = 0; $diffs = @()
  while ($i -lt $oldLines.Count) {
    if ($j -lt $newLines.Count -and $oldLines[$i] -eq $newLines[$j]) { $i++; $j++; continue }
    if ($leaf -eq 'p_map.pas' -and ($declRegex.IsMatch($oldLines[$i]) -or $oldLines[$i].Trim() -eq '' -or
        $oldLines[$i].Trim() -match '^(var|//.*)$')) { $i++; continue }
    $diffs += "riga vecchia $($i + 1): $($oldLines[$i])"
    break
  }
  if ($diffs.Count -eq 0 -and $j -lt $newLines.Count) {
    foreach ($r in @($newLines[$j..($newLines.Count - 1)] | Where-Object { $_.Trim() -ne '' })) { $diffs += "riga nuova in coda: $r" }
  }
  if ($diffs.Count -eq 0 -and $leaf -ne 'po_man.pas') {
    $code = (($newText -split "`r?`n") | Where-Object { $_.TrimStart() -notmatch '^(//|{)' }) -join "`n"
    foreach ($entry in $entries) {
      if ($entry.Solo -and ($entry.Solo -notcontains $leaf)) { continue }
      if ([regex]::IsMatch($code, "(?<![\w.])$([regex]::Escape($entry.Old))(?!\w)", 'IgnoreCase')) {
        $diffs += "il nome storico $($entry.Old) compare ancora nel testo nuovo"
      }
    }
  }
  $total++
  if ($diffs.Count -gt 0) { $bad++; Write-Host "DIVERSO  $rel"; $diffs | ForEach-Object { Write-Host "    $_" } }
  else { Write-Host "UGUALE   $rel" }
}
Write-Host "File provati: $total, con differenze: $bad"
exit $bad

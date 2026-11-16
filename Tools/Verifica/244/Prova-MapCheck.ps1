<#
  Issue #244: prova meccanica sul testo della migrazione dello stato di p_map in TMapCheck.

  Per ogni .pas e .dpr modificato rispetto al commit di partenza (-Base, predefinito il commit prima della
  migrazione) rifa' la strada al contrario sul testo nuovo: ogni TMapCheck.<Campo> torna al suo nome storico,
  la riga della uses col DelphiDoom.Engine.World.MapCheck sparisce, e il risultato si confronta riga per riga
  con il testo vecchio. Le uniche differenze ammesse sono:
    - le righe di dichiarazione delle variabili migrate in p_map.pas (e quelle che le seguono sole);
    - le due modifiche dichiarate a mano alle clausole var di p_map.pas (righe vuote e commenti).
  Ogni altra differenza e' un errore (per esempio una riga cancellata per sbaglio) e viene stampata.
  Inoltre le routine PIT_*/P_* non cambiano nei nomi dei campi: i nomi storici non devono piu' comparire
  (parola intera, senza distinguere maiuscole) nel testo nuovo, tranne in po_man.pas (variabile propria).

  Uso:  powershell -NoProfile -File Tools\Verifica\244\Prova-MapCheck.ps1 -Group Tm [-Base HEAD]
  Esce con il numero dei file con differenze.
#>
param(
  [Parameter(Mandatory)][ValidateSet('Tm', 'Spec')][string]$Group,
  [string]$Base = 'HEAD'
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
. (Join-Path $PSScriptRoot 'MapCheck-Nomi.ps1')
$unit = 'DelphiDoom.Engine.World.MapCheck'
$latin1 = [System.Text.Encoding]::GetEncoding(28591)
$map = $MapCheckGroups[$Group]
$reverse = @{}
foreach ($k in $map.Keys) { $reverse[$map[$k].ToLowerInvariant()] = $k }
$alternation = ($map.Keys | ForEach-Object { [regex]::Escape($_) }) -join '|'
$declRegex = New-Object System.Text.RegularExpressions.Regex("^\s*($alternation)\s*:(?!=)", 'IgnoreCase')
$fieldPattern = 'TMapCheck\.(' + (($map.Values | ForEach-Object { [regex]::Escape($_) }) -join '|') + ')(?!\w)'
$fieldRegex = New-Object System.Text.RegularExpressions.Regex($fieldPattern, 'IgnoreCase')
$oldNameRegex = New-Object System.Text.RegularExpressions.Regex("(?<![\w.])($alternation)(?!\w)", 'IgnoreCase')

$files = & git -C $root diff --name-only $Base -- IdTech1 | Where-Object { $_ -match '\.(pas|dpr)$' }
$bad = 0
$total = 0
foreach ($rel in $files) {
  $newText = $latin1.GetString([System.IO.File]::ReadAllBytes((Join-Path $root $rel)))
  # i byte veri del commit (git show passerebbe dal testo)
  $tmp = [System.IO.Path]::GetTempFileName()
  & cmd /c "git -C `"$root`" show ${Base}:$rel > `"$tmp`""
  $oldText = $latin1.GetString([System.IO.File]::ReadAllBytes($tmp))
  Remove-Item -LiteralPath $tmp
  # la classe TMapCheck dichiarata in p_map.pas e' testo nuovo ammesso
  # (anche nel testo di partenza, se il passo viene dopo quello che l'ha introdotta)
  $classRegex = '(?s)\r?\ntype\r?\n(?:  ///[^\r\n]*\r?\n)+  TMapCheck = class sealed.*?\r?\n  end;\r?\n'
  $newText = [regex]::Replace($newText, $classRegex, '')
  $oldText = [regex]::Replace($oldText, $classRegex, '')
  $back = $fieldRegex.Replace($newText,{ param($m) $reverse[$m.Groups[1].Value.ToLowerInvariant()] })
  $newLines = @($back -split "`r?`n" | Where-Object { $_ -notmatch [regex]::Escape($unit) -and $_ -notmatch 'issue #244|in TMapCheck too' })
  $oldLines = @($oldText -split "`r?`n")
  # allineamento: ogni riga vecchia o c'e' (nello stesso ordine) o e' una dichiarazione ammessa
  $i = 0; $j = 0; $diffs = @()
  while ($i -lt $oldLines.Count) {
    if ($j -lt $newLines.Count -and $oldLines[$i] -eq $newLines[$j]) { $i++; $j++; continue }
    if ($rel -like '*p_map.pas' -and ($declRegex.IsMatch($oldLines[$i]) -or $oldLines[$i].Trim() -eq '' -or
        $oldLines[$i].Trim() -match '^(var|//.*)$')) { $i++; continue }
    $diffs += "riga vecchia $($i + 1): $($oldLines[$i])"
    break
  }
  if ($diffs.Count -eq 0 -and $j -lt $newLines.Count) {
    $rest = @($newLines[$j..($newLines.Count - 1)] | Where-Object { $_.Trim() -ne '' })
    # nei .dpr la riga dell'unit e' gia' tolta; nel resto non devono avanzare righe nuove
    foreach ($r in $rest) { $diffs += "riga nuova in coda: $r" }
  }
  if ($diffs.Count -eq 0 -and $oldNameRegex.IsMatch((($newText -split "`r?`n") | Where-Object { $_.TrimStart() -notmatch "^(//|{)" }) -join "`n") -and $rel -notlike '*po_man.pas') {
    $diffs += 'un nome storico compare ancora nel testo nuovo'
  }
  $total++
  if ($diffs.Count -gt 0) { $bad++; Write-Host "DIVERSO  $rel"; $diffs | ForEach-Object { Write-Host "    $_" } }
  else { Write-Host "UGUALE   $rel" }
}
Write-Host "File provati: $total, con differenze: $bad"
exit $bad

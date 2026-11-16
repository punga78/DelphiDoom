<#
  Issue #245, settima tornata: sostituzione meccanica di `leveltime` e `thinkercap` (dichiarati in p_tick.pas) con i
  campi della classe TTickState, dichiarata nella stessa unit (stato 1,5 del par. 11.22 del piano: la memoria resta
  una variabile ad indirizzo fisso, ma ha un solo posto in cui e' dichiarata e documentata; nella stessa unit di
  P_Ticker e delle altre routine che la usano, cosi' per loro il costo non cambia). Stesse regole di
  Migra-Sessione.ps1: parola intera, in ogni .pas sotto IdTech1, senza toccare stringhe, commenti, nomi con il punto
  davanti (campi di record, metodi di classe) ne' seguiti da ':' (dichiarazioni); `p_tick.nome` diventa il campo.
  Le dichiarazioni in p_tick.pas si tolgono a mano prima. BOM, fine riga e codifica restano (Latin-1).

  Uso:  powershell -NoProfile -File Tools\Verifica\245\Migra-Tempo.ps1 [-WhatIf]
#>
param(
  [switch]$WhatIf
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$latin1 = [System.Text.Encoding]::GetEncoding(28591)
$fields = @{ leveltime = 'TTickState.LevelTime'; thinkercap = 'TTickState.ThinkerCap' }
$alternation = ($fields.Keys | ForEach-Object { [regex]::Escape($_) }) -join '|'
$pattern = "('(?:[^'\r\n]|'')*')|(//[^\r\n]*)|(\{[^}\r\n]*\})|(?<![\w.])(?:p_tick\.)?($alternation)(?![\w])(?!\s*:(?!=))"
$regex = New-Object System.Text.RegularExpressions.Regex($pattern, 'IgnoreCase')
$total = 0
$changed = @()
foreach ($file in Get-ChildItem -Path (Join-Path $root 'IdTech1') -Recurse -Filter *.pas) {
  if ($file.FullName -match '[\\/]IdTech1[\\/](Net|Demo|EngineSystem|GameState|Hud|MapInfo|Thinkers|Acs)[\\/]') { continue }
  $text = $latin1.GetString([System.IO.File]::ReadAllBytes($file.FullName))
  $counter = New-Object 'int[]' 1
  $evaluator = [System.Text.RegularExpressions.MatchEvaluator] {
    param($m)
    if ($m.Groups[4].Success) {
      $counter[0]++
      return $fields[$m.Groups[4].Value.ToLowerInvariant()]
    }
    return $m.Value
  }
  $new = $regex.Replace($text, $evaluator)
  if ($new -ne $text) {
    $changed += [pscustomobject]@{ File = $file.FullName.Substring($root.Length + 1); Count = $counter[0] }
    $total += $counter[0]
    if (-not $WhatIf) { [System.IO.File]::WriteAllBytes($file.FullName, $latin1.GetBytes($new)) }
  }
}
$changed | Format-Table -AutoSize
'Totale sostituzioni: ' + $total

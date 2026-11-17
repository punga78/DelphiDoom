<#
  Issue #245, ottava tornata: porta nei campi (class var) di TGameSession, dichiarata in ogni g_game.pas, i nomi
  storici gametic, gameaction, paused, playeringame (dichiarati in g_game), gamestate e oldgamestate (doomdef) e
  players (d_player), come Migra-Sessione.ps1 ha fatto per i nomi della sesta e settima tornata.
  Fa tre cose, in quest'ordine: (1) toglie la dichiarazione globale dall'unit che la ha e aggiunge la class var dopo
  DemoRecording di ogni g_game.pas; (2) sostituisce ogni lettore sotto IdTech1 (parola intera, senza distinguere le
  maiuscole, non dentro stringhe e commenti, non preceduto da un punto, non seguito da ':' = dichiarazione; i nomi
  qualificati con g_game./doomdef./d_player. diventano il campo); (3) aggiunge g_game in testa alla clausola uses di
  implementation delle unit che lo leggono e non lo usano ancora. oldgamestate valeva -1: l'azzeramento sta in testa
  alla initialization di g_game. BOM, fine riga e codifica restano (Latin-1).

  Uso:  powershell -NoProfile -File Tools\Verifica\248\Migra-Stato.ps1 -Names gametic,gameaction,paused [-WhatIf]
#>
param(
  [Parameter(Mandatory)][string[]]$Names,
  [switch]$WhatIf
)
$ErrorActionPreference = 'Stop'
$Names = @($Names | ForEach-Object { $_ -split ',' } | Where-Object { $_ -ne '' })
$root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$latin1 = [System.Text.Encoding]::GetEncoding(28591)
$members = [ordered]@{
  gametic       = @('GameTic', 'integer', 'The tic of the game in progress', 'g_game')
  gameaction    = @('GameAction', 'gameaction_t', 'The action the game loop does at the start of the next tic', 'g_game')
  paused        = @('Paused', 'boolean', 'The game is paused', 'g_game')
  playeringame  = @('PlayerInGame', 'array[0..MAXPLAYERS - 1] of boolean', 'The player slots in use', 'g_game')
  gamestate     = @('GameState', 'gamestate_t', 'Level, intermission, finale or demo screen', 'doomdef')
  oldgamestate  = @('OldGameState', 'integer', 'The game state of the last frame drawn', 'doomdef')
  players       = @('Players', 'array[0..MAXPLAYERS - 1] of player_t', 'The player records', 'd_player')
}
$games = 'Doom', 'Heretic', 'Hexen', 'Strife'

# (1) dichiarazioni
foreach ($game in $games) {
  $added = @()
  foreach ($name in $members.Keys) {
    if ($Names -notcontains $name) { continue }
    $path = Join-Path $root "IdTech1\$game\$($members[$name][3]).pas"
    $text = $latin1.GetString([System.IO.File]::ReadAllBytes($path))
    $pattern = "(?im)^  $name\s*:(?!=)\s*[^;\r\n]*;[^\r\n]*\r?\n"
    if ([regex]::IsMatch($text, $pattern)) {
      $text = [regex]::Replace($text, $pattern, '')
      $added += $name
      if (-not $WhatIf) { [System.IO.File]::WriteAllBytes($path, $latin1.GetBytes($text)) }
    }
    else { Write-Warning "$game : dichiarazione di $name non trovata in $path" }
  }
  $path = Join-Path $root "IdTech1\$game\g_game.pas"
  $text = $latin1.GetString([System.IO.File]::ReadAllBytes($path))
  $anchor = "    class var DemoRecording: boolean;`r`n"
  if (-not $text.Contains($anchor)) { throw "ancora non trovata in $path" }
  $insert = ''
  foreach ($name in $members.Keys) {
    if ($added -contains $name) {
      $m = $members[$name]
      $insert += "    /// <summary>$($m[2])</summary>`r`n    class var $($m[0]): $($m[1]);`r`n"
    }
  }
  $text = $text.Replace($anchor, $anchor + $insert)
  if ($added -contains 'oldgamestate') {
    $init = "initialization`r`n`r`n"
    if (-not $text.Contains($init)) { throw "initialization non trovata in $path" }
    $text = $text.Replace($init, $init + "  TGameSession.OldGameState := -1;`r`n")
  }
  if (-not $WhatIf) { [System.IO.File]::WriteAllBytes($path, $latin1.GetBytes($text)) }
  "$game : " + ($added -join ', ')
}

# (2) lettori
$alternation = ($Names | ForEach-Object { [regex]::Escape($_) }) -join '|'
$pattern = "('(?:[^'\r\n]|'')*')|(//[^\r\n]*)|(\{[^}\r\n]*\})|(?<![\w.])(?:g_game\.|doomdef\.|d_player\.)?($alternation)(?![\w])(?!\s*:(?!=))"
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
      return 'TGameSession.' + $members[$m.Groups[4].Value.ToLowerInvariant()][0]
    }
    return $m.Value
  }
  $new = $regex.Replace($text, $evaluator)
  if ($new -ne $text) {
    # (3) g_game nelle uses di implementation
    if ($file.Name -ne 'g_game.pas' -and $new -notmatch '(?is)\buses\b[^;]*\bg_game\b[^;]*;') {
      $impl = [regex]::Match($new, '(?im)^implementation\s*$')
      if (-not $impl.Success) { throw "implementation non trovata in $($file.FullName)" }
      $after = $new.Substring($impl.Index + $impl.Length)
      $uses = [regex]::Match($after, '(?im)^uses\b[ \t]*\r?\n')
      $nextSection = [regex]::Match($after, '(?im)^(const|type|var|procedure|function|class|initialization)\b')
      if ($uses.Success -and (-not $nextSection.Success -or $uses.Index -lt $nextSection.Index)) {
        $pos = $impl.Index + $impl.Length + $uses.Index + $uses.Length
        $new = $new.Substring(0, $pos) + "  g_game,`r`n" + $new.Substring($pos)
      }
      else {
        $pos = $impl.Index + $impl.Length
        $new = $new.Substring(0, $pos) + "`r`n`r`nuses`r`n  g_game;" + $new.Substring($pos)
      }
    }
    $changed += [pscustomobject]@{ File = $file.FullName.Substring($root.Length + 1); Count = $counter[0] }
    $total += $counter[0]
    if (-not $WhatIf) { [System.IO.File]::WriteAllBytes($file.FullName, $latin1.GetBytes($new)) }
  }
}
$changed | Format-Table -AutoSize
'Totale sostituzioni: ' + $total

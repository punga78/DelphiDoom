<#
  Issue #245, sesta tornata: sostituzione meccanica dei nomi storici della partita (demoplayback, netdemo,
  timingdemo, consoleplayer, netgame, deathmatch, gamemap, gameskill, gameepisode) con i campi di TGameSession
  (class var dichiarata in ogni g_game.pas, vedi par. 11.20/11.21 del piano), come Migra-MapStato.ps1 fa per p_map.
  Parola intera, senza distinguere maiuscole, in ogni .pas sotto IdTech1; non tocca stringhe, commenti di riga e
  direttive/commenti { } su una riga, ne' i nomi preceduti da un punto (campi di record) o seguiti da ':' (dichiarazioni
  e parametri); `g_game.nome` diventa `TGameSession.Campo`. BOM, fine riga e codifica restano (Latin-1).
  Le dichiarazioni in g_game.pas e g_demo.pas si tolgono a mano prima.

  Uso:  powershell -NoProfile -File Tools\Verifica\245\Migra-Sessione.ps1 [-Names a,b] [-WhatIf]
#>
param(
  [string[]]$Names = @('consoleplayer', 'netgame', 'deathmatch', 'gamemap', 'gameskill', 'gameepisode'),
  [switch]$WhatIf
)
$ErrorActionPreference = 'Stop'
$Names = @($Names | ForEach-Object { $_ -split ',' } | Where-Object { $_ -ne '' })
$root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$latin1 = [System.Text.Encoding]::GetEncoding(28591)
$fields = @{
  demoplayback = 'DemoPlayback'; netdemo = 'NetDemo'; timingdemo = 'TimingDemo'; consoleplayer = 'ConsolePlayer'
  netgame = 'NetGame'; deathmatch = 'DeathMatch'; gamemap = 'GameMap'; gameskill = 'GameSkill'; gameepisode = 'GameEpisode'
  preparingdemoplayback = 'PreparingDemoPlayback'; nomonsters = 'NoMonsters'; fastparm = 'FastParm'; respawnparm = 'RespawnParm'
  secretexit = 'SecretExit'; pistolstart = 'PistolStart'; singledemo = 'SingleDemo'; precache = 'Precache'
  demostarttic = 'DemoStartTic'; gamemapinfo = 'GameMapInfo'; wminfo = 'WmInfo'
  forcecompatibilitymode = 'ForceCompatibilityMode'; compatibilitymode = 'CompatibilityMode'
  oldcompatibilitymode = 'OldCompatibilityMode'
}
$alternation = ($Names | ForEach-Object { [regex]::Escape($_) }) -join '|'
$pattern = "('(?:[^'\r\n]|'')*')|(//[^\r\n]*)|(\{[^}\r\n]*\})|(?<![\w.])(?:g_game\.)?($alternation)(?![\w])(?!\s*:(?!=))"
$regex = New-Object System.Text.RegularExpressions.Regex($pattern, 'IgnoreCase')
$total = 0
$changed = @()
foreach ($file in Get-ChildItem -Path (Join-Path $root 'IdTech1') -Recurse -Filter *.pas) {
  # le librerie fredde (Net, Demo, ...) hanno campi con questi nomi e non usano g_game
  if ($file.FullName -match '[\\/]IdTech1[\\/](Net|Demo|EngineSystem|GameState|Hud|MapInfo|Thinkers|Acs)[\\/]') { continue }
  $text = $latin1.GetString([System.IO.File]::ReadAllBytes($file.FullName))
  $counter = New-Object 'int[]' 1
  $evaluator = [System.Text.RegularExpressions.MatchEvaluator] {
    param($m)
    if ($m.Groups[4].Success) {
      $counter[0]++
      return 'TGameSession.' + $fields[$m.Groups[4].Value.ToLowerInvariant()]
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

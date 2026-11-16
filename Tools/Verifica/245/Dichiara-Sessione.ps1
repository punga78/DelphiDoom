<#
  Issue #245, sesta tornata: toglie da ogni g_game.pas (e da g_demo.pas di Hexen) la dichiarazione globale dei nomi
  che passano in TGameSession e aggiunge i campi (class var) alla classe di quell'unit, dopo DemoRecording.
  Da lanciare una volta, prima di Migra-Sessione.ps1. BOM, fine riga e codifica restano (Latin-1).
#>
param(
  [string[]]$Names = @('consoleplayer', 'netgame', 'deathmatch', 'gamemap', 'gameskill', 'gameepisode')
)
$ErrorActionPreference = 'Stop'
$Names = @($Names | ForEach-Object { $_ -split ',' } | Where-Object { $_ -ne '' })
$root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$latin1 = [System.Text.Encoding]::GetEncoding(28591)
$members = [ordered]@{
  demoplayback  = @('DemoPlayback', 'boolean', 'A demo is being played back')
  netdemo       = @('NetDemo', 'boolean', 'The demo being played was recorded in a net game')
  timingdemo    = @('TimingDemo', 'boolean', 'If true, exit with a report when the demo ends')
  consoleplayer = @('ConsolePlayer', 'integer', 'Player taking events and displaying')
  netgame       = @('NetGame', 'boolean', 'Only true if packets are broadcast')
  deathmatch    = @('DeathMatch', 'integer', 'Only if started as net death')
  gamemap       = @('GameMap', 'integer', 'Map of the level in progress')
  gameskill     = @('GameSkill', 'skill_t', 'Skill of the game in progress')
  gameepisode   = @('GameEpisode', 'integer', 'Episode of the level in progress')
  preparingdemoplayback = @('PreparingDemoPlayback', 'boolean', 'The level of a demo is being set up, before the demo plays')
  nomonsters    = @('NoMonsters', 'boolean', 'Checkparm of -nomonsters (or the demo header)')
  fastparm      = @('FastParm', 'boolean', 'Checkparm of -fast (or the demo header)')
  respawnparm   = @('RespawnParm', 'boolean', 'Checkparm of -respawn (or the demo header)')
}
foreach ($game in 'Doom', 'Heretic', 'Hexen', 'Strife') {
  $files = @("IdTech1\$game\g_game.pas")
  if ($game -eq 'Hexen') { $files += 'IdTech1\Hexen\g_demo.pas' }
  $files += "IdTech1\$game\d_main.pas"
  $added = @()
  foreach ($rel in $files) {
    $path = Join-Path $root $rel
    $text = $latin1.GetString([System.IO.File]::ReadAllBytes($path))
    foreach ($name in $members.Keys) {
      if ($Names -notcontains $name) { continue }
      $pattern = "(?im)^  $name\s*:(?!=)\s*[^;\r\n]*;[^\r\n]*\r?\n"
      if ([regex]::IsMatch($text, $pattern)) {
        $text = [regex]::Replace($text, $pattern, '')
        $added += $name
      }
    }
    [System.IO.File]::WriteAllBytes($path, $latin1.GetBytes($text))
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
  # Strife had gameskill = sk_medium: a class var has no initial value, so the value is set at unit initialization
  if ($game -eq 'Strife' -and ($added -contains 'gameskill')) {
    $init = "initialization`r`n`r`n"
    if (-not $text.Contains($init)) { throw "initialization non trovata in $path" }
    $text = $text.Replace($init, $init + "  TGameSession.GameSkill := sk_medium;`r`n")
  }
  [System.IO.File]::WriteAllBytes($path, $latin1.GetBytes($text))
  "$game : " + ($added -join ', ')
}

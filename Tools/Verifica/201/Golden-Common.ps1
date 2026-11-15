<#
  Issue #201: parte comune di Confronta-Golden.ps1 e Registra-Golden.ps1 (si include con ". .\Golden-Common.ps1").

  Il criterio di parita' di Libs\War: ogni golden di Tests\Data\War e' l'uscita di un programma in C che contiene il
  codice ORIGINALE del remake (acoto87/war1) estratto alla lettera e compilato con gcc (w64devkit); questa tabella
  dice quale programma fa quale golden. Niente e' modificato in Reference\.
#>

$script:Here = $PSScriptRoot
$script:Verifica = Split-Path $PSScriptRoot
$script:Repo = Split-Path (Split-Path (Split-Path $PSScriptRoot))
$script:GoldenDir = Join-Path $script:Repo 'Tests\Data\War'

# Gruppo = una cartella di Tools\Verifica con il suo Compila-*.ps1; Jobs = una riga di comando del programma e il golden che scrive.
# {DATA} si sostituisce con il DATA.WAR vero; un job con NeedsData si salta se il DATA.WAR non c'e'.
$script:Groups = @(
  @{ Name = '191 archivio'; Dir = '191'; Script = 'Compila-WarRef.ps1'; Jobs = @(
      @{ Exe = 'war_ref.exe'; Args = @('{DATA}', 'list'); Golden = 'datawar.retail.golden.txt'; NeedsData = $true },
      @{ Exe = 'war_ref.exe'; Args = @('{DATA}', 'list', 'noskip'); Golden = 'datawar.retail.noskip.golden.txt'; NeedsData = $true },
      @{ Exe = 'war_ref.exe'; Args = @('-', 'catalog'); Golden = 'catalog.golden.txt'; NeedsData = $false }) },
  @{ Name = '192 grafica'; Dir = '192'; Script = 'Compila-GfxRef.ps1'; Jobs = @(
      @{ Exe = 'war_gfx_ref.exe'; Args = @('{DATA}', 'gfx'); Golden = 'graphics.golden.txt'; NeedsData = $true },
      @{ Exe = 'war_gfx_ref.exe'; Args = @('-', 'fonts'); Golden = 'fonts.golden.txt'; NeedsData = $false }) },
  @{ Name = '193 livelli'; Dir = '193'; Script = 'Compila-LevelRef.ps1'; Jobs = @(
      @{ Exe = 'war_lvl_ref.exe'; Args = @('{DATA}', 'levels'); Golden = 'levels.golden.txt'; NeedsData = $true },
      @{ Exe = 'war_lvl_ref.exe'; Args = @('-', 'campaigns'); Golden = 'campaigns.golden.txt'; NeedsData = $false },
      @{ Exe = 'war_lvl_ref.exe'; Args = @('-', 'objectives'); Golden = 'objectives.golden.txt'; NeedsData = $false },
      @{ Exe = 'war_lvl_ref.exe'; Args = @('-', 'tables'); Golden = 'autotile.tables.golden.txt'; NeedsData = $false },
      @{ Exe = 'war_lvl_ref.exe'; Args = @('-', 'autotile'); Golden = 'autotile.golden.txt'; NeedsData = $false },
      @{ Exe = 'war_lvl_ref.exe'; Args = @('-', 'grid'); Golden = 'grid.golden.txt'; NeedsData = $false }) },
  @{ Name = '198 suoni'; Dir = '198'; Script = 'Compila-AudioRef.ps1'; Jobs = @(
      @{ Exe = 'war_audio_ref.exe'; Args = @('-', 'synth'); Golden = 'audio.synth.golden.txt'; NeedsData = $false },
      @{ Exe = 'war_audio_ref.exe'; Args = @('-', 'mix'); Golden = 'audio.mixer.golden.txt'; NeedsData = $false },
      @{ Exe = 'war_audio_ref.exe'; Args = @('-', 'position'); Golden = 'audio.position.golden.txt'; NeedsData = $false },
      @{ Exe = 'war_audio_ref.exe'; Args = @('{DATA}', 'list'); Golden = 'audio.records.golden.txt'; NeedsData = $true }) },
  @{ Name = '198 musica'; Dir = '198'; Script = 'Compila-MusicRef.ps1'; Jobs = @(
      @{ Exe = 'war_music_ref.exe'; Args = @('scenarios'); Golden = 'music.golden.txt'; NeedsData = $false }) },
  @{ Name = '198 scelta dei suoni'; Dir = '198'; Script = 'Compila-SoundRef.ps1'; Jobs = @(
      @{ Exe = 'war_sound_ref.exe'; Args = @('tables'); Golden = 'sounds.tables.golden.txt'; NeedsData = $false },
      @{ Exe = 'war_ranges.exe'; Args = @(); Golden = 'sounds.ranges.golden.txt'; NeedsData = $false }) },
  @{ Name = '194 modello'; Dir = '194'; Script = 'Compila-ModelRef.ps1'; Jobs = @(
      @{ Exe = 'war_model_ref.exe'; Args = @('tables'); Golden = 'model.tables.golden.txt'; NeedsData = $false },
      @{ Exe = 'war_model_ref.exe'; Args = @('scenarios', '20'); Golden = 'model.friendly.golden.txt'; NeedsData = $false },
      @{ Exe = 'war_model_ref.exe'; Args = @('hostile', '16'); Golden = 'model.hostile.golden.txt'; NeedsData = $false },
      @{ Exe = 'war_model_ref.exe'; Args = @('dump', 'friendly', '3', '120'); Golden = 'model.dump.golden.txt'; NeedsData = $false }) },
  @{ Name = '194 attacco'; Dir = '194'; Script = 'Compila-ModelRef.ps1'; Jobs = @(
      @{ Exe = 'war_model_ref.exe'; Args = @('actions'); Golden = 'model.steps.golden.txt'; NeedsData = $false },
      @{ Exe = 'war_model_ref.exe'; Args = @('combat', '16'); Golden = 'model.combat.golden.txt'; NeedsData = $false },
      @{ Exe = 'war_model_ref.exe'; Args = @('dump', 'combat', '3', '200'); Golden = 'model.combat.dump.golden.txt'; NeedsData = $false }) },
  @{ Name = '194 raccolta'; Dir = '194'; Script = 'Compila-ModelRef.ps1'; Jobs = @(
      @{ Exe = 'war_model_ref.exe'; Args = @('gather-tables'); Golden = 'gather.tables.golden.txt'; NeedsData = $false },
      @{ Exe = 'war_model_ref.exe'; Args = @('gather', '10'); Golden = 'gather.golden.txt'; NeedsData = $false },
      @{ Exe = 'war_model_ref.exe'; Args = @('dump', 'gather', '2', '900'); Golden = 'gather.dump.golden.txt'; NeedsData = $false }) }
  # seconda fetta della #194: costruzione, riparazione, crollo, addestramento e miglioramenti (stesso programma, altri scenari)
  @{ Name = '194 costruzione'; Dir = '194'; Script = 'Compila-ModelRef.ps1'; Jobs = @(
      @{ Exe = 'war_model_ref.exe'; Args = @('construction-tables'); Golden = 'model.construction.tables.golden.txt'; NeedsData = $false },
      @{ Exe = 'war_model_ref.exe'; Args = @('construction', '24'); Golden = 'model.construction.golden.txt'; NeedsData = $false },
      @{ Exe = 'war_model_ref.exe'; Args = @('dump', 'construction', '17', '200'); Golden = 'model.construction.dump.golden.txt'; NeedsData = $false }) },
  # completamento della #194 (war_full_ref.inc): il tic INTERO di wmap_updateMap (stati, griglia, azioni, animazioni, proiettili,
  # mana, incantesimi) con gli ordini dati dai veri wcmd_executeCommand e updateCommandFromRightClick
  @{ Name = '194 comandi'; Dir = '194'; Script = 'Compila-ModelRef.ps1'; Jobs = @(
      @{ Exe = 'war_model_ref.exe'; Args = @('command-tables'); Golden = 'model.commands.tables.golden.txt'; NeedsData = $false },
      @{ Exe = 'war_model_ref.exe'; Args = @('commands', '12'); Golden = 'model.commands.golden.txt'; NeedsData = $false },
      @{ Exe = 'war_model_ref.exe'; Args = @('dump', 'commands', '6', '450'); Golden = 'model.commands.dump.golden.txt'; NeedsData = $false }) },
  @{ Name = '194 incantesimi'; Dir = '194'; Script = 'Compila-ModelRef.ps1'; Jobs = @(
      @{ Exe = 'war_model_ref.exe'; Args = @('spells', '12'); Golden = 'model.spells.golden.txt'; NeedsData = $false },
      @{ Exe = 'war_model_ref.exe'; Args = @('dump', 'spells', '3', '450'); Golden = 'model.spells.dump.golden.txt'; NeedsData = $false }) },
  @{ Name = '194 completo'; Dir = '194'; Script = 'Compila-ModelRef.ps1'; Jobs = @(
      @{ Exe = 'war_model_ref.exe'; Args = @('full', '12'); Golden = 'model.full.golden.txt'; NeedsData = $false },
      @{ Exe = 'war_model_ref.exe'; Args = @('dump', 'full', '11', '450'); Golden = 'model.full.dump.golden.txt'; NeedsData = $false }) },
  # issue #195 (war_path_ref.inc): lo stesso programma con le funzioni ORIGINALI di war_pathfinder.c, war_rvo.c e la nebbia di guerra
  # (updateFoW, determineFoWTypes) al posto degli stub della #194: A star e campi di flusso su mappe sintetiche, la scelta della
  # velocita', gruppi che si incrociano e il tic intero con percorsi, evitamento e nebbia. I golden del gruppo '194 ...' non cambiano
  @{ Name = '195 percorsi'; Dir = '194'; Script = 'Compila-ModelRef.ps1'; Jobs = @(
      @{ Exe = 'war_model_ref.exe'; Args = @('paths', '36'); Golden = 'path.paths.golden.txt'; NeedsData = $false },
      @{ Exe = 'war_model_ref.exe'; Args = @('rvo', '20'); Golden = 'path.rvo.golden.txt'; NeedsData = $false },
      # la mappa hash di shl (ordine dei bucket) e il candidato piu' vicino di A star con due caselle a pari distanza
      @{ Exe = 'war_model_ref.exe'; Args = @('units'); Golden = 'path.units.golden.txt'; NeedsData = $false },
      @{ Exe = 'war_model_ref.exe'; Args = @('move', '12'); Golden = 'path.move.golden.txt'; NeedsData = $false },
      @{ Exe = 'war_model_ref.exe'; Args = @('dump', 'move', '2', '300'); Golden = 'path.move.dump.golden.txt'; NeedsData = $false },
      @{ Exe = 'war_model_ref.exe'; Args = @('real', 'combat', '12'); Golden = 'path.combat.golden.txt'; NeedsData = $false },
      @{ Exe = 'war_model_ref.exe'; Args = @('real', 'commands', '12'); Golden = 'path.commands.golden.txt'; NeedsData = $false },
      @{ Exe = 'war_model_ref.exe'; Args = @('real', 'spells', '12'); Golden = 'path.spells.golden.txt'; NeedsData = $false },
      @{ Exe = 'war_model_ref.exe'; Args = @('real', 'full', '12'); Golden = 'path.full.golden.txt'; NeedsData = $false },
      @{ Exe = 'war_model_ref.exe'; Args = @('real', 'dump', 'full', '11', '450'); Golden = 'path.full.dump.golden.txt'; NeedsData = $false },
      # le mappe dei passaggi dei 36 livelli di DATA.WAR (war_file.c originale): A star e campi di flusso
      @{ Exe = 'war_model_ref.exe'; Args = @('levelpaths', '{DATA}'); Golden = 'path.levels.golden.txt'; NeedsData = $true }) },
  # issue #196 (war_ai_ref.inc): war_ai.c INTERO del remake (l'IA: un copione per il giocatore 1, richieste di unita', attese e pause)
  # sul mondo di 'completo': le tabelle (produttori, copione per razza), 8 scenari di 3000 tic con il giocatore 1 guidato dall'IA
  # (razza, economia, fattorie, centri urbani, ordini del giocatore ai suoi edifici, annullamenti, danni, tempo reale, trucco del tempo)
  @{ Name = '196 ia'; Dir = '194'; Script = 'Compila-ModelRef.ps1'; Jobs = @(
      @{ Exe = 'war_model_ref.exe'; Args = @('ai-tables'); Golden = 'ai.tables.golden.txt'; NeedsData = $false },
      @{ Exe = 'war_model_ref.exe'; Args = @('ai', '8'); Golden = 'ai.scenarios.golden.txt'; NeedsData = $false },
      @{ Exe = 'war_model_ref.exe'; Args = @('dump', 'ai', '5', '1200'); Golden = 'ai.dump.golden.txt'; NeedsData = $false },
      @{ Exe = 'war_model_ref.exe'; Args = @('dump', 'ai', '6', '2999'); Golden = 'ai.dump2.golden.txt'; NeedsData = $false }) },
  # issue #197 (war_frame_ref.c): il remake INTERO con la SDL3 vera, gli script di Tools\Verifica\197\scripts; "H n impronta" per
  # fotogramma. Il programma cerca ./DATA.WAR e i PNG dei font nella cartella corrente: WorkDir = $true lo lancia dalla cartella
  # della compilazione ({SCRIPTS197} e' la cartella degli script)
  @{ Name = '197 render'; Dir = '197'; Script = 'Compila-FrameRef.ps1'; Jobs = @(
      @{ Exe = 'war_frame_ref.exe'; Args = @('{SCRIPTS197}\blizzard.script'); Golden = 'ui.blizzard.golden.txt'; NeedsData = $true; WorkDir = $true },
      @{ Exe = 'war_frame_ref.exe'; Args = @('{SCRIPTS197}\menu.script'); Golden = 'ui.menu.golden.txt'; NeedsData = $true; WorkDir = $true },
      @{ Exe = 'war_frame_ref.exe'; Args = @('{SCRIPTS197}\singleplayer.script'); Golden = 'ui.singleplayer.golden.txt'; NeedsData = $true; WorkDir = $true },
      @{ Exe = 'war_frame_ref.exe'; Args = @('{SCRIPTS197}\customgame.script'); Golden = 'ui.customgame.golden.txt'; NeedsData = $true; WorkDir = $true },
      @{ Exe = 'war_frame_ref.exe'; Args = @('{SCRIPTS197}\briefing_human.script'); Golden = 'ui.briefing_human.golden.txt'; NeedsData = $true; WorkDir = $true },
      @{ Exe = 'war_frame_ref.exe'; Args = @('{SCRIPTS197}\briefing_orc.script'); Golden = 'ui.briefing_orc.golden.txt'; NeedsData = $true; WorkDir = $true },
      @{ Exe = 'war_frame_ref.exe'; Args = @('{SCRIPTS197}\briefing_end.script'); Golden = 'ui.briefing_end.golden.txt'; NeedsData = $true; WorkDir = $true },
      @{ Exe = 'war_frame_ref.exe'; Args = @('{SCRIPTS197}\briefing_enter.script'); Golden = 'ui.briefing_enter.golden.txt'; NeedsData = $true; WorkDir = $true },
      @{ Exe = 'war_frame_ref.exe'; Args = @('{SCRIPTS197}\cheats.script'); Golden = 'ui.cheats.golden.txt'; NeedsData = $true; WorkDir = $true },
      @{ Exe = 'war_frame_ref.exe'; Args = @('{SCRIPTS197}\cursor.script'); Golden = 'ui.cursor.golden.txt'; NeedsData = $true; WorkDir = $true },
      @{ Exe = 'war_frame_ref.exe'; Args = @('{SCRIPTS197}\pause.script'); Golden = 'ui.pause.golden.txt'; NeedsData = $true; WorkDir = $true },
      # la mappa (parte B): entrata, camera, mappe di campagna delle due razze
      @{ Exe = 'war_frame_ref.exe'; Args = @('{SCRIPTS197}\map_enter.script'); Golden = 'ui.map_enter.golden.txt'; NeedsData = $true; WorkDir = $true },
      @{ Exe = 'war_frame_ref.exe'; Args = @('{SCRIPTS197}\map_still.script'); Golden = 'ui.map_still.golden.txt'; NeedsData = $true; WorkDir = $true },
      @{ Exe = 'war_frame_ref.exe'; Args = @('{SCRIPTS197}\map_scroll.script'); Golden = 'ui.map_scroll.golden.txt'; NeedsData = $true; WorkDir = $true },
      @{ Exe = 'war_frame_ref.exe'; Args = @('{SCRIPTS197}\map_orc.script'); Golden = 'ui.map_orc.golden.txt'; NeedsData = $true; WorkDir = $true },
      @{ Exe = 'war_frame_ref.exe'; Args = @('{SCRIPTS197}\map_select.script'); Golden = 'ui.map_select.golden.txt'; NeedsData = $true; WorkDir = $true },
      @{ Exe = 'war_frame_ref.exe'; Args = @('{SCRIPTS197}\map_orders.script'); Golden = 'ui.map_orders.golden.txt'; NeedsData = $true; WorkDir = $true },
      @{ Exe = 'war_frame_ref.exe'; Args = @('{SCRIPTS197}\map_long.script'); Golden = 'ui.map_long.golden.txt'; NeedsData = $true; WorkDir = $true },
      @{ Exe = 'war_frame_ref.exe'; Args = @('{SCRIPTS197}\map_pause.script'); Golden = 'ui.map_pause.golden.txt'; NeedsData = $true; WorkDir = $true },
      # i comandi con bersaglio e i bottoni del pannello (parte C): addestrare, costruire
      @{ Exe = 'war_frame_ref.exe'; Args = @('{SCRIPTS197}\map_cmd_train.script'); Golden = 'ui.map_cmd_train.golden.txt'; NeedsData = $true; WorkDir = $true },
      @{ Exe = 'war_frame_ref.exe'; Args = @('{SCRIPTS197}\map_cmd_build.script'); Golden = 'ui.map_cmd_build.golden.txt'; NeedsData = $true; WorkDir = $true },
      @{ Exe = 'war_frame_ref.exe'; Args = @('{SCRIPTS197}\map_cmd_orders.script'); Golden = 'ui.map_cmd_orders.golden.txt'; NeedsData = $true; WorkDir = $true },
      @{ Exe = 'war_frame_ref.exe'; Args = @('{SCRIPTS197}\map_cmd_town.script'); Golden = 'ui.map_cmd_town.golden.txt'; NeedsData = $true; WorkDir = $true },
      @{ Exe = 'war_frame_ref.exe'; Args = @('{SCRIPTS197}\map_cmd_extra.script'); Golden = 'ui.map_cmd_extra.golden.txt'; NeedsData = $true; WorkDir = $true },
      @{ Exe = 'war_frame_ref.exe'; Args = @('{SCRIPTS197}\map_cursors.script'); Golden = 'ui.map_cursors.golden.txt'; NeedsData = $true; WorkDir = $true },
      # combattimento e incantesimi: proiettili, animazioni, suoni come entita' (parte C, punto 2)
      @{ Exe = 'war_frame_ref.exe'; Args = @('{SCRIPTS197}\map_war_melee.script'); Golden = 'ui.map_war_melee.golden.txt'; NeedsData = $true; WorkDir = $true },
      @{ Exe = 'war_frame_ref.exe'; Args = @('{SCRIPTS197}\map_war_siege.script'); Golden = 'ui.map_war_siege.golden.txt'; NeedsData = $true; WorkDir = $true },
      @{ Exe = 'war_frame_ref.exe'; Args = @('{SCRIPTS197}\map_spells.script'); Golden = 'ui.map_spells.golden.txt'; NeedsData = $true; WorkDir = $true },
      @{ Exe = 'war_frame_ref.exe'; Args = @('{SCRIPTS197}\map_spells_orc.script'); Golden = 'ui.map_spells_orc.golden.txt'; NeedsData = $true; WorkDir = $true },
      # i menu della mappa (parte D): F10, opzioni, obiettivi, ricomincia
      @{ Exe = 'war_frame_ref.exe'; Args = @('{SCRIPTS197}\map_menu.script'); Golden = 'ui.map_menu.golden.txt'; NeedsData = $true; WorkDir = $true },
      @{ Exe = 'war_frame_ref.exe'; Args = @('{SCRIPTS197}\map_menu_quit.script'); Golden = 'ui.map_menu_quit.golden.txt'; NeedsData = $true; WorkDir = $true },
      @{ Exe = 'war_frame_ref.exe'; Args = @('{SCRIPTS197}\map_menu_restart.script'); Golden = 'ui.map_menu_restart.golden.txt'; NeedsData = $true; WorkDir = $true },
      # i trucchi sulla mappa e la fine della mappa (parte D)
      @{ Exe = 'war_frame_ref.exe'; Args = @('{SCRIPTS197}\map_cheats.script'); Golden = 'ui.map_cheats.golden.txt'; NeedsData = $true; WorkDir = $true },
      @{ Exe = 'war_frame_ref.exe'; Args = @('{SCRIPTS197}\map_gameover_win.script'); Golden = 'ui.map_gameover_win.golden.txt'; NeedsData = $true; WorkDir = $true },
      @{ Exe = 'war_frame_ref.exe'; Args = @('{SCRIPTS197}\map_gameover_lose.script'); Golden = 'ui.map_gameover_lose.golden.txt'; NeedsData = $true; WorkDir = $true },
      @{ Exe = 'war_frame_ref.exe'; Args = @('{SCRIPTS197}\map_demo_end.script'); Golden = 'ui.map_demo_end.golden.txt'; NeedsData = $true; WorkDir = $true },
      @{ Exe = 'war_frame_ref.exe'; Args = @('{SCRIPTS197}\map_skip.script'); Golden = 'ui.map_skip.golden.txt'; NeedsData = $true; WorkDir = $true },
      # le partite personalizzate: dal menu col mouse, e "custom N" dell'harness
      @{ Exe = 'war_frame_ref.exe'; Args = @('{SCRIPTS197}\map_custom_menu.script'); Golden = 'ui.map_custom_menu.golden.txt'; NeedsData = $true; WorkDir = $true },
      @{ Exe = 'war_frame_ref.exe'; Args = @('{SCRIPTS197}\map_custom_swamp.script'); Golden = 'ui.map_custom_swamp.golden.txt'; NeedsData = $true; WorkDir = $true },
      @{ Exe = 'war_frame_ref.exe'; Args = @('{SCRIPTS197}\map_custom_forest.script'); Golden = 'ui.map_custom_forest.golden.txt'; NeedsData = $true; WorkDir = $true },
      # il disegno di debug (flag, griglie, caselle che non si passano)
      @{ Exe = 'war_frame_ref.exe'; Args = @('{SCRIPTS197}\map_debug.script'); Golden = 'ui.map_debug.golden.txt'; NeedsData = $true; WorkDir = $true },
      @{ Exe = 'war_frame_ref.exe'; Args = @('{SCRIPTS197}\map_edit.script'); Golden = 'ui.map_edit.golden.txt'; NeedsData = $true; WorkDir = $true }) }
)

# Il testo di un golden senza le differenze che non contano: BOM, fine riga (CRLF o LF), righe vuote in coda.
function Get-NormalizedText([string[]]$Lines) {
  $list = New-Object System.Collections.Generic.List[string]
  foreach ($line in $Lines) { $list.Add($line.TrimStart([char]0xFEFF).TrimEnd("`r")) }
  while ($list.Count -gt 0 -and $list[$list.Count - 1] -eq '') { $list.RemoveAt($list.Count - 1) }
  , $list.ToArray()
}

function Read-GoldenFile([string]$Path) {
  Get-NormalizedText ([IO.File]::ReadAllLines($Path))
}

# Compila il gruppo in una cartella nuova di $Root (un sottocartella per gruppo) e dice dove sta.
function Build-Group($Group, [string]$Root) {
  $out = Join-Path $Root ($Group.Name -replace '[^0-9A-Za-z]+', '_')
  $script = Join-Path (Join-Path $script:Verifica $Group.Dir) $Group.Script
  $built = & $script -Out $out
  if (-not (Test-Path $out)) { throw "Il gruppo $($Group.Name) non ha compilato." }
  $out
}

# Esegue un job e da' le righe che il programma scrive; $null se serve il DATA.WAR e non c'e'.
function Invoke-Job($Job, [string]$BuildDir, [string]$DataWar) {
  if ($Job.NeedsData -and (-not $DataWar -or -not (Test-Path $DataWar))) { return $null }
  $scripts197 = Join-Path $script:Verifica '197\scripts'
  $arguments = @($Job.Args | ForEach-Object { if ($_ -eq '{DATA}') { $DataWar } else { $_ -replace '\{SCRIPTS197\}', $scripts197 } })
  # WorkDir: il programma cerca i suoi file (DATA.WAR, PNG dei font) nella cartella corrente, che e' quella della compilazione
  if ($Job.WorkDir) { Push-Location $BuildDir }
  try {
    $lines = & (Join-Path $BuildDir $Job.Exe) @arguments
    if ($LASTEXITCODE -ne 0) { throw "$($Job.Exe) $($arguments -join ' ') e' uscito con $LASTEXITCODE" }
  } finally {
    if ($Job.WorkDir) { Pop-Location }
  }
  , @($lines)
}

function Select-Groups([string]$Only) {
  if ($Only -eq '') { return $script:Groups }
  $script:Groups | Where-Object { $_.Name -like "*$Only*" -or $_.Dir -eq $Only }
}

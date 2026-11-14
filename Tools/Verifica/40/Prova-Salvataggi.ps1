<#
  Issue #40 (sotto-issue #43): i salvataggi tra il programma a 32 bit e quello a 64 bit.

  Per ogni scenario di Scenari.psd1 (un livello di un gioco e un seme del pilota automatico):
    1. ESPLORA: il programma a 32 bit gioca il livello col pilota (-autodemo) e scrive l'impronta dello stato
       (-statehash); dai tic si scelgono quelli dei salvataggi: quello con piu' thinker di settore attivi (porte,
       piattaforme, luci, script ACS), quello con piu' mobj (proiettili in volo), uno avanti nella partita.
    2. SALVA: per ogni tic scelto, ogni programma "scrittore" (32 bit, 64 bit e, se dato, il riferimento a 32 bit
       del codice di partenza) rigioca fino a quel tic e salva (-autosave tic slot). Lo stato prima del
       salvataggio deve essere uguale nei tre.
    3. CONFRONTA I FILE: i salvataggi di 32 e 64 bit (e del riferimento) byte per byte.
    4. CARICA: ogni programma "lettore" carica il salvataggio di ogni scrittore (-loadgame slot) e gioca altri
       -LoadTics tic col pilota, scrivendo l'impronta dello stato: tutte le combinazioni lettore x scrittore devono
       dare le stesse righe. In piu' il mondo (settori, lati, linee) al primo tic dopo il caricamento deve essere
       quello che il programma che ha salvato aveva un tic dopo il salvataggio.

  Uso (dalla radice del repository):
    powershell -NoProfile -File Tools\Verifica\40\Prova-Salvataggi.ps1 [-Game Doom,Hexen] [-Name 'd1_*']
       [-RefExe "Doom=C:\rif\Doom32.exe;Heretic=..."] [-Exe32 "..."] [-Exe64 "..."] [-LoadTics 300] [-Picks 3]
       [-DataRoot <bin coi WAD>] [-WorkRoot C:\ddsave40] [-AllLoads] [-NoLock]

  Senza riferimento i caricamenti sono 4 per stato (32<-32, 32<-64, 64<-32, 64<-64); col riferimento 6 (in piu' il
  64 bit nuovo che legge il riferimento e il riferimento che legge il 64 bit nuovo), 9 con -AllLoads.

  Gli eseguibili predefiniti sono bin\Win32\Release\<Gioco>\<Gioco>32.exe e bin\Win64\Release\... (Tools\build.bat
  giochi Release both). I WAD si prendono da -DataRoot (predefinito: la cartella bin del repository principale).
  Con -NoLock i giochi partono senza il lock globale di Tools\Esegui-gioco.ps1 e a priorita' normale (una
  esecuzione per volta comunque): serve quando la macchina e' carica e il lock fa aspettare minuti per esecuzione;
  le esecuzioni usano l'orologio virtuale, quindi il carico non cambia il risultato.

  Codice di uscita: 0 se ogni combinazione di caricamento e' uguale, 1 altrimenti. Il riepilogo va anche in
  <WorkRoot>\risultati.csv; le differenze tra i file in <WorkRoot>\<Gioco>\store\<scenario>\<tic>\differenze.txt.
#>
param(
  [string[]]$Game = @(),
  [string]$Name = '*',
  $Exe32 = @{},
  $Exe64 = @{},
  $RefExe = @{},
  [string]$DataRoot = '',
  [string]$WorkRoot = 'C:\ddsave40',
  [int]$LoadTics = 300,
  [int]$Picks = 3,
  [int]$Slot = 2,
  [switch]$AllLoads,
  [switch]$LoadPilot,
  [switch]$NoLock
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\185\Parity-Common.ps1')
. (Join-Path $PSScriptRoot 'Salvataggi-Common.ps1')

$root = Get-ParityRoot
$Exe32 = ConvertTo-ParityMap $Exe32
$Exe64 = ConvertTo-ParityMap $Exe64
$RefExe = ConvertTo-ParityMap $RefExe
$scenarios = Import-PowerShellDataFile (Join-Path $PSScriptRoot 'Scenari.psd1')
$entries = @($scenarios.Entries | Where-Object { $_.Name -like $Name })
if ($Game.Count -gt 0) { $entries = @($entries | Where-Object { $Game -contains $_.Game }) }
if ($entries.Count -eq 0) { throw 'Nessuno scenario scelto' }
$games = Get-ParityGames
$results = New-Object System.Collections.ArrayList
$failed = 0

foreach ($gameName in @($entries | ForEach-Object { $_.Game } | Select-Object -Unique)) {
  $info = $games[$gameName]
  $exeName = $info.Exe
  $programs = [ordered]@{}
  $source32 = $Exe32[$gameName]; if (-not $source32) { $source32 = Join-Path $root "bin\Win32\Release\$($info.Folder)\$exeName" }
  $source64 = $Exe64[$gameName]; if (-not $source64) { $source64 = Join-Path $root "bin\Win64\Release\$($info.Folder)\$exeName" }
  $programs['n32'] = $source32
  $programs['n64'] = $source64
  if ($RefExe[$gameName]) { $programs['r32'] = $RefExe[$gameName] }
  $copies = @{}
  foreach ($key in $programs.Keys) {
    if (-not (Test-Path $programs[$key])) { throw "Eseguibile non trovato: $($programs[$key])" }
    $copies["sv_${key}_$exeName"] = $programs[$key]
  }
  # finestra piccola: lo stato non dipende dalla risoluzione e ogni tic disegna un fotogramma
  $dir = Initialize-ParityRunDir -Game $gameName -WorkRoot $WorkRoot -DataRoot $DataRoot -Executables $copies `
    -ExtraIni @('soft_screenwidth=320', 'soft_screenheight=200')
  $saveDirs = @($scenarios.Games[$gameName].SaveDirs)
  $common = "-config p8.ini -dontsavedefaults -nomusic -nosound -noblit -singletics"

  foreach ($entry in @($entries | Where-Object { $_.Game -eq $gameName })) {
    $extra = ''
    if ($entry.ContainsKey('Extra')) { $extra = ' ' + $entry.Extra }
    $start = "-iwad $($entry.Iwad) $common -warp $($entry.Warp) -skill $($entry.Skill)$extra"

    # ---- 1. esplora
    if ($entry.ContainsKey('SaveTics')) { $chosen = @($entry.SaveTics | ForEach-Object { [pscustomobject]@{ Tic = [int]$_; Specials = -1; Mobjs = -1 } }) }
    else {
      $scout = Join-Path $dir 'sc.txt'
      Remove-Item $scout -ErrorAction SilentlyContinue
      $null = Invoke-SaveRun -Exe (Join-Path $dir "sv_n32_$exeName") -Arguments "$start -autodemo $($entry.Seed) $($entry.Tics) -statehash sc.txt" -WorkDir $dir -NoLock:$NoLock
      $chosen = @(Select-SaveTics -StateFile $scout -Count $Picks)
      if ($chosen.Count -eq 0) { Write-Output ("{0,-8} {1,-10} ESPLORAZIONE FALLITA (nessun tic col giocatore vivo)" -f $gameName, $entry.Name); $failed++; continue }
    }

    foreach ($pick in $chosen) {
      $tic = $pick.Tic
      $store = Join-Path $dir ("store\{0}\{1}" -f $entry.Name, $tic)
      if (Test-Path $store) { Remove-Item $store -Recurse -Force }
      New-Item -ItemType Directory -Force $store | Out-Null
      $row = [ordered]@{ Game = $gameName; Scenario = $entry.Name; Tic = $tic; Specials = $pick.Specials; Mobjs = $pick.Mobjs
        PreState = ''; Files3264 = ''; FilesRef32 = ''; Loads = 0; LoadsEqual = ''; LoadTics = 0; World = ''; Note = '' }

      # ---- 2. salva con ogni scrittore
      $writers = @()
      foreach ($key in $programs.Keys) {
        Clear-SaveDirs -WorkDir $dir -SaveDirs $saveDirs
        $state = Join-Path $dir 'sv.txt'
        Remove-Item $state -ErrorAction SilentlyContinue
        $null = Invoke-SaveRun -Exe (Join-Path $dir "sv_${key}_$exeName") -Arguments "$start -autodemo $($entry.Seed) $($tic + 2) -autosave $tic $Slot -statehash sv.txt" -WorkDir $dir -NoLock:$NoLock
        $count = Copy-SaveDirs -WorkDir $dir -SaveDirs $saveDirs -Target (Join-Path $store $key)
        if (Test-Path $state) { Move-Item $state (Join-Path $store "sv_$key.txt") -Force }
        if ($count -eq 0) { $row.Note += "$key non ha salvato; "; continue }
        $writers += $key
      }
      if ($writers -notcontains 'n32' -or $writers -notcontains 'n64') {
        $failed++; $null = $results.Add([pscustomobject]$row)
        Write-Output ("{0,-8} {1,-10} tic {2,5}: SALVATAGGIO MANCANTE ({3})" -f $gameName, $entry.Name, $tic, $row.Note)
        continue
      }
      # lo stato fino al salvataggio deve essere lo stesso per tutti gli scrittori
      $pre = 'uguale'
      foreach ($key in $writers) {
        if ($key -eq 'n32') { continue }
        $difference = Compare-StateLogs (Join-Path $store 'sv_n32.txt') (Join-Path $store "sv_$key.txt") -MaxTic $tic
        if ($difference -ne '') { $pre = "DIVERSO n32/${key}: $difference" }
      }
      $row.PreState = $pre

      # ---- 3. i file
      $report = Join-Path $store 'differenze.txt'
      $row.Files3264 = Compare-SaveTrees (Join-Path $store 'n32') (Join-Path $store 'n64') $report 'n32 e n64'
      if ($writers -contains 'r32') {
        $row.FilesRef32 = Compare-SaveTrees (Join-Path $store 'r32') (Join-Path $store 'n32') $report 'r32 e n32'
        # i byte diversi dal riferimento devono essere solo indirizzi di memoria (gli stessi che cambiano tra 32 e 64 bit)
        $inside = Test-SaveDifferencesInside (Join-Path $store 'r32') (Join-Path $store 'n32') (Join-Path $store 'n64')
        if ($row.FilesRef32 -notlike 'uguali*') { $row.FilesRef32 += " (solo dove cambiano anche 32/64: $inside)" }
        if ($inside -eq 'NO') { $row.Note += 'il programma a 32 bit non scrive i byte del riferimento; '; $failed++ }
      }

      # ---- 4. carica: ogni lettore con ogni scrittore
      $reference = ''
      $equal = $true
      $loadNote = ''
      $world = ''
      $minTics = [int]::MaxValue
      foreach ($reader in $programs.Keys) {
        foreach ($writer in $writers) {
          # col riferimento bastano i due incroci che contano (il nuovo a 64 bit legge il vecchio, il vecchio legge
          # il nuovo a 64 bit); -AllLoads li fa tutti e nove
          if (-not $AllLoads -and ($reader -eq 'r32' -or $writer -eq 'r32') -and
            -not (($reader -eq 'n64' -and $writer -eq 'r32') -or ($reader -eq 'r32' -and $writer -eq 'n64'))) { continue }
          Clear-SaveDirs -WorkDir $dir -SaveDirs $saveDirs
          Restore-SaveDirs -WorkDir $dir -Source (Join-Path $store $writer)
          $state = Join-Path $dir 'ld.txt'
          Remove-Item $state -ErrorAction SilentlyContinue
          # dopo il caricamento il giocatore sta fermo e il mondo va avanti (-autoquit chiude il programma; il
          # riferimento non ha l'opzione e si chiude quando il log ha abbastanza righe); con -LoadPilot gioca il pilota
          $after = "-autoquit $LoadTics"
          if ($LoadPilot) { $after = "-autodemo $($entry.Seed + 1000) $LoadTics" }
          $null = Invoke-SaveRun -Exe (Join-Path $dir "sv_${reader}_$exeName") -Arguments "-iwad $($entry.Iwad) $common -loadgame $Slot $after -statehash ld.txt" `
            -WorkDir $dir -NoLock:$NoLock -StateFile $state -EnoughLines $LoadTics -TimeoutSeconds 240
          $kept = Join-Path $store "ld_${reader}_$writer.txt"
          if (Test-Path $state) { Move-Item $state $kept -Force }
          $row.Loads++
          $lines = Get-StateLineCount $kept
          if ($lines -lt $minTics) { $minTics = $lines }
          if ($lines -lt $LoadTics) { $equal = $false; $loadNote += "$reader<-${writer}: solo $lines tic; " }
          if ($reference -eq '') {
            $reference = $kept
            $world = Test-LoadedWorld -SaverLog (Join-Path $store "sv_$writer.txt") -LoaderLog $kept -SaveTic $tic
          }
          else {
            $difference = Compare-StateLogs $reference $kept -MaxTic ($LoadTics - 1)
            if ($difference -ne '') { $equal = $false; $loadNote += "$reader<-${writer}: $difference; " }
          }
        }
      }
      $row.LoadTics = $minTics
      $row.World = $world
      if ($equal) { $row.LoadsEqual = 'uguali' } else { $row.LoadsEqual = 'DIVERSI'; $failed++ }
      if ($pre -ne 'uguale') { $failed++ }
      $row.Note += $loadNote
      $null = $results.Add([pscustomobject]$row)
      Write-Output ("{0,-8} {1,-10} tic {2,5} (speciali {3,3}, mobj {4,4}): prima={5}; file 32/64: {6}; rif/32: {7}; caricamenti {8}: {9} per {10} tic; mondo: {11} {12}" -f `
        $gameName, $entry.Name, $tic, $row.Specials, $row.Mobjs, $pre, $row.Files3264, $row.FilesRef32, $row.Loads, $row.LoadsEqual, $row.LoadTics, $row.World, $row.Note)
    }
  }
}

$csv = Join-Path $WorkRoot 'risultati.csv'
$results | Export-Csv -Path $csv -NoTypeInformation -Encoding UTF8
Write-Output ''
foreach ($group in ($results | Group-Object Game)) {
  $ok = @($group.Group | Where-Object { $_.LoadsEqual -eq 'uguali' -and $_.PreState -eq 'uguale' }).Count
  $loads = ($group.Group | Measure-Object Loads -Sum).Sum
  $same = @($group.Group | Where-Object { $_.Files3264 -like 'uguali*' }).Count
  Write-Output ("{0,-8}: {1} stati, {2} con tutti i caricamenti uguali ({3} caricamenti), {4} con i file di 32 e 64 bit uguali byte per byte" -f $group.Name, $group.Count, $ok, $loads, $same)
}
Write-Output "Riepilogo: $csv"
if ($failed -gt 0) { Write-Output "$failed problemi"; exit 1 }
exit 0

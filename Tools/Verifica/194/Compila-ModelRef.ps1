<#
  Issue #194 (prima fetta): compila il modello di gioco ORIGINALE del remake (acoto87/war1, zlib) con gcc: entita' e unita'
  (war_entities.c, war_units.c), la macchina a stati (war_state_machine*.c), le azioni (war_actions.c), il generatore dei
  vettori (war_math.c), la griglia di occupazione (war_pathfinder.c), la scelta della velocita' (war_rvo.c) e il tempo
  della mappa (war_map.c). Il remake e' una "unity build" (un solo file che include tutti i .c): qui si include lo stesso
  insieme senza i .c della grafica, dell'audio, dell'interfaccia e dell'IA. I sorgenti non sono modificati e non sono
  copiati: le intestazioni (le prime righe di tests\test_main.c, fino a war_game.h) si estraggono in war_head.inc; gli
  stub e gli scenari sono in war_model_ref.c (vedi l'intestazione di quel file).

  Niente e' modificato in Reference\: il programma sta in -Out (una cartella NUOVA fuori da Reference e dal repository).

  Uso:
    powershell -NoProfile -File Compila-ModelRef.ps1 -Out <cartella> [-War1 <...\Reference\war1>] [-Gcc <gcc.exe>]
#>
param(
  [Parameter(Mandatory)][string]$Out,
  [string]$War1 = 'C:\Progetti\DelphiDoom\Reference\war1',
  [string]$Gcc = 'C:\Progetti\DelphiDoom\Reference\_dati\_strumenti\w64devkit\w64devkit\bin\gcc.exe',
  # il livello di ottimizzazione: i golden si fanno con -O1; -O2 serve solo a misurare (war_model_ref bench, benchfull)
  [string]$Opt = '-O1'
)
$ErrorActionPreference = 'Stop'
if ((Test-Path $Out) -and (Get-ChildItem $Out -Force | Select-Object -First 1)) { throw "La cartella $Out non e' vuota." }
New-Item -ItemType Directory -Force $Out | Out-Null

# le intestazioni: dalla prima riga di tests\test_main.c a #include "war_game.h" (compreso), cercate per testo
$lines = [IO.File]::ReadAllLines((Join-Path $War1 'tests\test_main.c'))
$end = ($lines | Select-String -SimpleMatch '#include "war_game.h"' | Select-Object -First 1).LineNumber
if (-not $end) { throw 'war_game.h non trovato in tests\test_main.c' }
$lines[0..($end - 1)] | Set-Content (Join-Path $Out 'war_head.inc') -Encoding ASCII
Copy-Item (Join-Path $PSScriptRoot 'war_model_ref.c') (Join-Path $Out 'war_model_ref.c')
# gli scenari della seconda fetta (costruzione e addestramento) sono inclusi da war_model_ref.c
Copy-Item (Join-Path $PSScriptRoot 'war_construction_ref.inc') (Join-Path $Out 'war_construction_ref.inc')
# gli scenari dei comandi, degli incantesimi e del tic intero (completamento della #194)
Copy-Item (Join-Path $PSScriptRoot 'war_full_ref.inc') (Join-Path $Out 'war_full_ref.inc')

$exe = Join-Path $Out 'war_model_ref.exe'
$obj = Join-Path $Out 'war_model_ref.o'
$flags = @('-std=gnu11', $Opt, '-ffunction-sections', '-fdata-sections', '-Wno-misleading-indentation',
           "-I$Out", "-I$(Join-Path $War1 'deps\include')", "-I$(Join-Path $War1 'src')")
$ErrorActionPreference = 'Continue'   # gcc scrive gli avvisi su stderr
& $Gcc @flags -c (Join-Path $Out 'war_model_ref.c') -o $obj 2>&1 | Out-Null
if (-not (Test-Path $obj)) { & $Gcc @flags -c (Join-Path $Out 'war_model_ref.c') -o $obj 2>&1 | Out-String; throw 'Compilazione fallita' }

# il remake e' un solo file: una parte del codice che non si esegue mai (il disegno, l'audio, i menu) resta nell'eseguibile e
# chiede funzioni di SDL e delle librerie. Si danno a tutte le funzioni non definite un corpo che ferma il programma se viene
# chiamato: se uno scenario le raggiungesse, il golden non si produce (non si ottiene una risposta sbagliata in silenzio)
$link = & $Gcc -o $exe $obj '-Wl,--gc-sections' -lm 2>&1 | Out-String
if (-not (Test-Path $exe)) {
  $names = [regex]::Matches($link, 'undefined reference to .([A-Za-z_][A-Za-z0-9_]*).') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
  $stubs = New-Object System.Collections.Generic.List[string]
  $stubs.Add('#include <stdio.h>')
  $stubs.Add('#include <stdlib.h>')
  $stubs.Add('static void war_stub_called(const char* name) { fprintf(stderr, "funzione non portata chiamata: %s\n", name); abort(); }')
  foreach ($n in $names) { $stubs.Add("void $n(void) { war_stub_called(`"$n`"); }") }
  $stubFile = Join-Path $Out 'war_stubs.c'
  $stubs | Set-Content $stubFile -Encoding ASCII
  & $Gcc -o $exe $obj $stubFile '-Wl,--gc-sections' -lm 2>&1 | Out-String
}
$ErrorActionPreference = 'Stop'
if (-not (Test-Path $exe)) { throw 'Collegamento fallito' }
"Compilato: $exe"
# Parita' di Warcraft: Orcs & Humans (issue #201, indice #203)

Il criterio con cui si prova che `Games\War` e `Framework\Cinematic` fanno quello che fa il remake in C (`Reference\war1`,
acoto87/war1, zlib), come per Greed (#175) e Rad-X. Le regole generali del repository (golden, test DUnitX, copertura)
sono in `CLAUDE.md`; qui c'e' cio' che e' specifico di War e i comandi per ripeterlo.

## Il criterio

1. **Il riferimento e' il C, non un'opinione.** Ogni golden di `Tests\Data\War` e' l'uscita di un programma in C che contiene
   il codice **originale** del remake, estratto alla lettera (per intervalli di righe cercati per testo: se il remake cambia
   l'estrazione fallisce, non si adatta in silenzio) e compilato con il gcc di `Reference\_dati\_strumenti\w64devkit`
   (non c'e' un compilatore C nel PATH). Gli unici pezzi scritti da noi sono gli **stub** di cio' che non e' logica del gioco
   (SDL, Tracy, `wm_alloc`, il log, il sintetizzatore `tsf_*`, i modelli di `WarContext`) e i **generatori di scenari**
   (seme fisso, nessun materiale commerciale). Niente e' modificato in `Reference\`.
2. **Il test di Delphi legge lo stesso file** e deve dare le stesse righe: impronte CRC-32 dei record e delle mappe,
   campioni PCM (anche i bit dei `float`), eventi del sintetizzatore con il campione in cui avvengono. Zero differenze e'
   l'unico risultato accettato; una tolleranza si dichiara nel test e nel README della libreria con il motivo (qui non ce ne sono).
3. **Dove il C ha un difetto** si decide caso per caso (come in `CLAUDE.md`): se l'uscita e' consumata da altri (i byte di un
   formato) il difetto si **conserva**; se e' un crash, una lettura fuori dal buffer o un errore evidente si **corregge**, con
   un test e una riga tra le "differenze volute" del README. Gli scenari dei golden **evitano** i difetti non conservati
   (e lo dicono nel generatore), perche' un golden che li contiene non si puo' ripetere.
4. **Dati commerciali**: `DATA.WAR` e i filmati non sono nel repository. I golden contengono solo numeri (CRC e conteggi).
   Un test che vuole il `DATA.WAR` vero si **ignora** se manca (`DELPHIDOOM_WAR_DATA` o `Reference\_dati\warcraft`); gli
   altri si costruiscono in memoria.
5. **Prestazioni**: il percorso caldo di War (il mixer, poi il gioco) deve stare entro il 5% del remake. `Tools\Misura-Coppie.ps1`
   misura due eseguibili del motore con `-timedemo`: serve un gioco, quindi si potra' usare quando esistera' `Warcraft32`
   (#200); finche' non c'e', la misura sul mixer non e' stata fatta (vedi "Cosa non e' coperto").

## Cosa prova cosa

| Area | Programma C (`Tools\Verifica\...`) | Golden (`Tests\Data\War`) | Test (`Tests\Source\DelphiDoom.Tests.War.*`) |
|---|---|---|---|
| Archivio `DATA.WAR` (#191) | `191\war_ref.c` (`wfile_loadWarFile`) | `datawar.retail*.golden.txt`, `catalog.golden.txt` | `Parity`, `Archive`, `Catalog` |
| Palette, immagini, sprite, cursori, tileset, font (#192) | `192\war_gfx_ref.c` (`wres_*`) | `graphics.golden.txt`, `fonts.golden.txt` | `GraphicsParity` |
| Livelli, campagne, raccordi, griglia (#193) | `193\war_lvl_ref.c` | `levels`, `campaigns`, `objectives`, `autotile*`, `grid` | `LevelParity`, `Campaign`, `Autotile`, `MapGrid` |
| Suoni, ricampionatore, mixer, volume posizionale (#198) | `198\war_audio_ref.c` | `audio.synth/mixer/position/records` | `AudioDecoders`, `AudioMixer`, `AudioMixParity` |
| **Tempo e eventi della musica** (#198) | `198\war_music_ref.c` (`wa_playMidi` + `tml.h`) | `music.golden.txt` (12 canzoni, 842 righe) | `MusicParity` |
| **Scelta dei suoni** (#198, #194) | `198\war_sound_ref.c` (`wa_play*Sound`) | `sounds.tables.golden.txt` (497), `sounds.ranges.golden.txt` (9) | `SoundPicker` |
| **Modello di gioco** (#194, prima fetta) | `194\war_model_ref.c` (il modello del remake come unity build: entita', unita', macchina a stati, economia, danni) | `model.tables` (253), `model.friendly` (20 scenari x 300 tic), `model.hostile` (16 scenari fino al primo ordine di attacco), `model.dump` | `ModelParity` |
| **Attacco** (#194, seconda fetta) | `194\war_model_ref.c` (stesso unity build con `war_projectiles.c`; `actions`, `combat 16`, `dump combat`) | `model.steps` (379: i passi di 378 azioni, la tabella unica di tutte le aree), `model.combat` (16 scenari x 600 tic: attacco, proiettili, danno a zona, inseguire, pattugliare), `model.combat.dump` | `CombatParity` |
| **Raccolta** (#194, seconda fetta) | `194\war_model_ref.c` (stessa unity build; scenario gather: 10 scenari x 1800 tic con due fazioni, miniere, foreste, municipi e sei lavoratori) | `gather.tables` (3: le immagini dei trasportatori), `gather` (10 x 1800 impronte + 10 riassunti = 18010), `gather.dump` (34) | `GatherParity` |
| **Costruzione, riparazione, crollo, addestramento e miglioramenti** (#194, seconda fetta) | `194\war_model_ref.c` con `war_commands.c` intero e `war_construction_ref.inc` (gli ordini sono i veri `wcmd_*`) | `model.construction.tables` (21: risorse di costruzione, costi, trucco), `model.construction` (24 scenari x 400 tic = 9600 righe), `model.construction.dump` | `ConstructionParity` |
| **Comandi** (#194, completamento) | `194\war_model_ref.c` + `war_full_ref.inc`: il **tic intero** di `wmap_updateMap` (`tickFull`: stati, griglia, azioni, `wanim_updateAnimations`, proiettili, `updateMagic`, `updateSpells`); gli ordini dai veri `wcmd_executeCommand` (clic sintetico), `updateCommandFromRightClick`, `updateSelectionFromList`, `updateSelectionGroups`, `wcmd_cancel` | `model.commands.tables` (70: cio' che ogni `wcmd_train*`/`upgrade*`/`build*` mette nel comando), `model.commands` (12 scenari x 900 tic = 10800), `model.commands.dump` | `FullParity`, `ModelCommands` (tabelle) |
| **Incantesimi, mana, animazioni** (#194, completamento) | lo stesso (`spells 12`): stato `cast`, tutti gli incantesimi, evocazioni, nube, vista, pioggia di fuoco, resurrezione | `model.spells` (10800), `model.spells.dump` | `FullParity` |
| **Tic intero con tutto insieme** (#194, completamento) | lo stesso (`full 12`): raccolta, combattimento, costruzione, muri, strade, incantesimi, comandi e l'ordine dell'IA nello stesso scenario | `model.full` (10800), `model.full.dump` | `FullParity` |
| **Percorsi, evitamento e nebbia** (#195) | `194\war_model_ref.c` con `war_path_ref.inc` e `war_levels_ref.inc`: le funzioni **originali** di `war_pathfinder.c` (A star, campi di flusso), `war_rvo.c` (scelta della velocita', vicini) e `updateFoW`/`determineFoWTypes` al posto degli stub della #194 (interruttore `gRealPaths`/`gRealFog`); `war_file.c` e `assets[]` originali per i livelli | `path.paths` (936: 36 mappe x 20 A star e 6 campi), `path.rvo` (2419: 16 coseni e seni a bit, costanti e 2400 scelte), `path.units` (24: ordine dei bucket della mappa hash e candidato piu' vicino a pari distanza), `path.levels` (432: 36 livelli di `DATA.WAR`, **si salta senza dati**), `path.move` (12 x 600), `path.move.dump`, `path.combat` (12 x 600), `path.commands`, `path.spells`, `path.full` (12 x 900 ciascuno, con percorsi, evitamento e nebbia), `path.full.dump` | `PathParity`, `PathHeap`, `PathFinding`, `ModelFlowSteering`, `ModelFogRevealer` |
| Filmati FLIC (#199) | `199\flc*.cpp` (`FlcPlayer` di OpenXcom: il remake **non** ha codice FLIC) | `Tests\Data\Cinematic\flic-*` | `Tests\...Cinematic.FlicParity` |
| **Menu F10, trucchi, fine, partite personalizzate, debug** (#197, parte D) | lo stesso `197\war_frame_ref.c` (volumi a 1 come `wa_initAudio`); gruppo `197 render` | `ui.map_menu*`, `ui.map_cheats`, `ui.map_gameover_*`, `ui.map_demo_end`, `ui.map_skip`, `ui.map_custom_*`, `ui.map_debug`, `ui.map_edit`, `ui.map_edit_terrain`, `ui.map_debug_units` (15 script, gli ultimi due della #238) | `MapUiParity`, `MapUiMenu`, `MapUiCheats`, `MapUiCustom`, `RenderLines`, `MapUiScene` |
| **Righe oblique e i flag di debug restanti** (#197, ultima fetta) | `197\war_frame_ref.c` e `197\sdl_raster_ref.c` (le righe sulla SDL3 vera, sezioni `L` di `raster.golden.txt`); gruppo `197 render` | `raster.golden.txt` (1800 scenari di righe), `ui.map_debug_font`, `_near`, `_projectiles`, `_flow`, `_rvo`, `_state` (1400 impronte) | `Raster`, `RenderLines`, `MapUiParity`, `DebugRender` |
| **Comandi con bersaglio, edifici, combattimento e incantesimi** (#197, parte C) | lo stesso `197\war_frame_ref.c` con i comandi `unit`, `building`, `upgrade`, `feature`, `gold` (e `WAR_REF_RNGTRACE`, `WAR_REF_RNGWHO` per cercare chi estrae un numero casuale); gruppo `197 render` | `ui.map_cmd_{train,build,orders,town,extra}`, `ui.map_cursors`, `ui.map_war_{melee,siege}`, `ui.map_spells`, `ui.map_spells_orc` (10 script, 2065 impronte `H n FNV-1a`) | `MapUiParity` (10 casi in piu'), `MapUiCommands` (8), `MapUiScene` (5), `MapUiPanel` (15), `RenderCopy` (3) |
| **La mappa di gioco** (#197, parte B) | lo stesso `197\war_frame_ref.c` (con i comandi `campaign`, `custom`, e per le prestazioni `fog`, `spawn`, `time`, `timerender`); gruppo `197 render` | `ui.map_*.golden.txt` (8 script, 3533 impronte `H n FNV-1a`: ogni fotogramma) | `MapUiParity` (8), `MapUiUnits` (20), `MapUiPanel` (11), `MapUiWorld` (9), `MapUiBench` (1) |
| **Scene e interfaccia immediata** (#197, parte A) | `197\war_frame_ref.c`: il remake **intero** (`src\war1.c`) con la SDL3 vera (renderer software su 320 x 200 RGBA), tempo fisso 1/60 s, generatore con seme, ingresso da script; gruppo `197 render` (`Registra-GoldenUi.ps1`) | `ui.<script>.golden.txt` (11 script, 4276 impronte `H n FNV-1a`) | `UiParity` (9), `UiImui`, `UiCheats`, `UiScenes`, `UiHost` (con finti) |

**Scene e interfaccia immediata (issue #197, parte A, 2026-11-15)**: `Tools\Verifica\197\war_frame_ref.c` compila il remake **intero e originale** con la SDL3 vera (nessuna finestra, tempo e generatore fissi) e legge gli script di `Tools\Verifica\197\scripts` (`scene`, `briefing`, `move`, `lbutton`, `rbutton`, `key`, `text`, `run N K`, `hash`, `rgba`, `trace`; `campaign` e `custom` servono la mappa, parte B). Il gruppo `197 render` di `Golden-Common.ps1` (con `WorkDir`: l'harness cerca `./DATA.WAR` e i PNG dei font nella cartella corrente) e `Tools\Verifica\197\Registra-GoldenUi.ps1` scrivono 11 golden (4276 righe `H n impronta`); `TWarUiScriptRunner` (`Games\War`) legge gli stessi script e scrive le stesse righe: **zero differenze** a Win32 e a Win64. Se un'impronta differisce: `DELPHIDOOM_WAR_UI_DUMP=<cartella>` fa scrivere al test la traccia delle chiamate di disegno di Delphi e `Tools\Verifica\197\Confronta-Traccia.ps1 -Script X -Out <cartella nuova> -Delphi <traccia>` la confronta con quella del C (`trace on`, senza l'indirizzo delle texture) e dice la prima chiamata diversa (provato: le 41162 chiamate di `cheats.script` coincidono; con `-Pixel` scrive anche i pixel del C, `rgba`). Il sensore e' provato (un golden con un'impronta cambiata fa fallire il test con riga e valori). **Cosa non si prova con uno script**: il tooltip (si disegna solo con una mappa, nessun bottone di scena ne imposta uno), la scena di download (rete), l'audio, la mappa. Dettagli: `Games\War\CLAUDE.md`. Parita' di Warcraft: Orcs & Humans (issue #201, indice #203)

## Come si ripete

```
:: tutti i golden di War rifatti dal C e confrontati con quelli del repository (e i numeri dei test di Delphi)
powershell -NoProfile -File Tools\Verifica\201\Confronta-Golden.ps1 -Test bin\Win32\Release\Tests\DelphiDoom.Tests.War.exe

:: un solo gruppo (191, 192, 193, 198, musica, suoni)
powershell -NoProfile -File Tools\Verifica\201\Confronta-Golden.ps1 -Solo musica

:: solo se il C e' cambiato di proposito: riscrive i golden (poi si guarda il diff e si rifanno i test)
powershell -NoProfile -File Tools\Verifica\201\Registra-Golden.ps1 -Solo musica
```

`Confronta-Golden.ps1` compila ogni gruppo in una cartella temporanea nuova, esegue i programmi, confronta riga per riga
(senza BOM e fine riga) e dice la prima riga che differisce; esce con 1 se qualcosa differisce o se il test fallisce.
Senza il `DATA.WAR` salta i golden che lo vogliono (lo dice), senza gcc non parte il gruppo. Ultima esecuzione
(2026-11-14): **18 golden su 18 identici** (6 gruppi, non toccati da #194) e **7 su 7 dei gruppi `194 modello` e `194 costruzione`** (rifatti dal C e confrontati con `Confronta-Golden.ps1 -Solo 194`), `DelphiDoom.Tests.War` 898 passati, 0 falliti, 1 ignorato (il PNG
di ispezione, `DELPHIDOOM_WAR_PNG_OUT`), a Win32 e a Win64.
**Completamento della #194 (2026-11-14)**: `Confronta-Golden.ps1 -Solo 194` = **20 golden su 20 identici** rifatti dal C (i 13
di prima piu' i 7 dei gruppi `194 comandi`, `194 incantesimi`, `194 completo`); `DelphiDoom.Tests.War` 1191 test, 1190
passati, 1 ignorato, 0 falliti a Win32 e a Win64 (a 64 bit con `dcc64` a parte, vedi sotto).

Per compilare i test: `Tools\build.bat DelphiDoom.Tests.War Release` (e `DelphiDoom.Tests.Cinematic`); in un worktree sotto
`.claude\worktrees\` serve la variabile `DCC_UnitSearchPath` con la cartella `DUnitX\Source` (vedi `Games\War\CLAUDE.md`).
I test risalgono dalla cartella dell'exe fino a `Tests\Data` (dalla #230 `build.bat` non copia più nulla).
A 64 bit `DelphiDoom.Tests.Cinematic` compila e passa. `DelphiDoom.Tests.War` compila e passa per intero a 64 bit; il suo
`.dproj` dichiara oggi solo Win32 (lo estende la #40), quindi per provarlo a 64 bit si compila il `.dpr` con `dcc64` a
parte (da `Tests\`): `dcc64 -B -Q -$O+ -NSSystem;Winapi;System.Win;Xml;Data;Vcl -U..\Framework\AudioMix;<DUnitX\Source>;..\Games\War;..\Framework\MathCore;.\Source
-I..\Games\War;.\Include;<DUnitX\Source> -E..\bin\Win64\Release\Tests -N0..\dcu\Win64\Release\DelphiDoom.Tests.War.manual -DRELEASE DelphiDoom.Tests.War.dpr`.

## Copertura

`Tools\Copertura.ps1 -Test War -Cartella Games\War` e `-Test Cinematic -Cartella Framework\Cinematic` (richiede CodeCoverage.exe,
`DELPHI_CODECOVERAGE`; compila in Debug). Obiettivo 90% sulle librerie nuove. Risultato (2026-11-13): `Games\War` 99%
(2107 righe su 2118), `Framework\Cinematic` 99% (1119 su 1130); le unit nuove di #198 e #199: 97-100% ciascuna.
Dopo il completamento della #194 (2026-11-14): `Games\War` 98% (7923 righe su 8004), le unit dei comandi, degli
incantesimi e delle animazioni 97-100%. Dopo la #195: `Games\War` 98% (8646 su 8740), 1291 test (1290 passati, 1 ignorato) a Win32 e a Win64,
`Confronta-Golden.ps1 -Solo 194` 31 golden su 31 identici; le unit nuove 94-100% (gli `inline` non sono contati dallo strumento).
Dopo la #196 (l'IA, 2026-11-14): `Games\War` 98% (8940 righe su 9046), 1335 test (1334 passati, 1 ignorato) a Win32 e a Win64, `Confronta-Golden.ps1 -Solo 194` 35 golden su 35 identici (31 + 4 del gruppo `196 ia`); le unit dell'IA 94-100% (`Ai.Command` e `Model.UnitProducers` meno solo per gli `inline`).

Dopo la parte D (#197): `Games\War` 98% (13804 su 13986), 1623 test (1622 passati, 1 ignorato) a Win32 e a Win64 (a 64 bit con `dcc64` e il DUnitX di `Skema\SupervisioneNats\lib\DUnitX\Source`), `Confronta-Golden.ps1 -Solo 197` 42 golden su 42 identici.

## Cosa non e' coperto

- **L'ascolto**: nessuna delle tre parti nuove (musica, scelta dei suoni, scena di filmato) e' stata ascoltata o vista in una
  finestra. Il sintetizzatore e' un'interfaccia (`IWarMusicSynth`) con un finto nei test e un sintetizzatore muto: il
  SoundFont `GMGeneric.SF2` del remake non ha una licenza dichiarata e TinySoundFont non si porta.
- **Le misure a coppie** del percorso caldo (vedi sopra): il mixer e' stato confrontato per i **campioni** (identici),
  non per il tempo.
- **Il gioco originale DOS** come secondo riferimento dove il remake si discosta (IA, regole): il modello di gioco c'e' (#194-#196; l'IA del remake e' solo un copione, vedi `Games\War\README.md`) ma non c'e' un modo di far girare il DOS in modo ripetibile e confrontabile qui;
  per l'audio e i filmati il remake e' l'unico riferimento tranne per i FLIC (OpenXcom).
- **Gli stati per tic** esistono dalla prima fetta del modello (#194: gruppo `194 modello`, vedi `Games\War\README.md`, sezione `Modello di gioco`), dalla seconda (quattro gruppi: `194 attacco`, `194 raccolta`, `194 costruzione`, uniti il 2026-11-14 in un solo modello con **un solo** esecutore dei passi delle azioni, `TWarActionRunner`, e una sola tabella dei passi, `model.steps`); coprono solo cio' che il modello porta (idle, move in linea retta o, dalla #195, con i campi di flusso, l'evitamento tra unita' e la nebbia per tic: gruppo `195 percorsi`, death, wait, economia, danni, attacco, proiettili, inseguire, pattugliare, raccolta, costruzione, riparazione, crollo, addestramento, miglioramenti, mura); dal completamento (gruppi `194 comandi`, `194 incantesimi`, `194 completo`) anche comandi, incantesimi, mana, animazioni e muri hanno un golden per tic con il tic intero; l'IA (#196: gruppo `196 ia`, `war_ai.c` intero nell'unity build, 8 scenari di 3000 tic) anche. Gli scenari di raccolta mettono lo stand-in del seguimento e del crollo e fanno girare solo le azioni di raccolta (come il C dello scenario, `gatherTick`): misurano gli stati di raccolta; il giro intero di `wmap_updateMap` e' in `tickModel` (attacco e costruzione). I fotogrammi dei punti 3-5 dell'issue #201 aspettano il renderer: per aggiungere un gruppo basta una voce in `Tools\Verifica\201\Golden-Common.ps1` (programma C, argomenti, golden).

**La mappa di gioco (issue #197, parte B, 2026-11-15)**: gli script `map_*.script` di `Tools\Verifica\197\scripts` (`campaign human|orc N`, `move`, `lbutton`, `rbutton`, `key`, `run N 1`) fanno entrare nella mappa, scorrere la camera, selezionare (clic, rettangolo, Ctrl, gruppi), dare ordini col clic destro, mettere in pausa e lasciare giocare il computer per 40 secondi; il C vero (SDL3) e Delphi danno **la stessa impronta in ognuno dei 3533 fotogrammi** (`ui.map_*.golden.txt`, Win32 e Win64). Un'impronta che differisce si cerca con `DELPHIDOOM_WAR_UI_DUMP`, `Confronta-Traccia.ps1` (la traccia di Delphi ora e' completa: anche le tegole e gli sprite della mappa) e `Confronta-Pixel.ps1`; cosi' si sono trovati il cursore (la lente su un'unita'), il rettangolo di selezione senza area (quattro pixel, non zero) e l'ordine di disegno che il C **fa sul posto** sulle liste del modello. **Non provato** perche' non portato (parte B): costruzione con l'anteprima, incantesimi, menu F10, trucchi sulla mappa, partite personalizzate, animazioni, proiettili e nuvole di veleno, suoni del combattimento. Prestazioni, difetti conservati e differenze: `Games\War\CLAUDE.md`.

**Comandi, edifici, combattimento e incantesimi (issue #197, parte C, 2026-11-15)**: gli script `map_cmd_*`, `map_cursors`, `map_war_*` e `map_spells*` di `Tools\Verifica\197\scripts` mettono unita' ed edifici sulla mappa con i comandi dell'harness (`unit TIPO X Y GIOCATORE`, `building ...`, `upgrade INDICE PERMESSO LIVELLO`, `feature INDICE VALORE`, `gold ORO LEGNA`: X e Y sono punti dello schermo, il tipo e' il numero di `WarUnitType`), poi giocano con il mouse e i tasti (comando con bersaglio dai bottoni e dai tasti, costruzione con l'anteprima, strada e muro, addestramento, miglioramenti, incantesimi, due eserciti, assedio con pietre ed esplosioni, nemico che brucia): C vero e Delphi danno **la stessa impronta in ognuno dei 2065 fotogrammi** (Win32 e Win64). Come si cerca una differenza, nell'ordine: `Confronta-Golden.ps1 -Solo 197` (o una prova diretta: `DELPHIDOOM_WAR_RUNSCRIPT=<script>` + `DELPHIDOOM_WAR_RUNSCRIPT_OUT=<file>` con `MapUiParity` scrivono le impronte di Delphi); se un'impronta differisce, `WAR_REF_RNGTRACE=1` (C) e `DELPHIDOOM_WAR_RNGTRACE=1` (Delphi) scrivono lo stato del generatore a ogni fotogramma (righe `D n stato`): la prima riga diversa e' il fotogramma dove un numero e' stato estratto da una parte sola (cosi' si e' trovato il "segui" dato a un edificio, che il C fa e il modello no); `WAR_REF_RNGWHO=1` con una compilazione `gcc -g -O0 -fno-omit-frame-pointer` e `addr2line` (l'indirizzo di `main` stampato per spostare la base) dice quale funzione del C ha estratto; poi la traccia delle chiamate di disegno (`Confronta-Traccia.ps1`) e i pixel (`Confronta-Pixel.ps1`). **Prestazioni** (non e' un golden, e' una misura): `scripts\map_bench.script` (C) e `TTestWarMapUiBench` (Delphi, `DELPHIDOOM_WAR_BENCH_OUT`) disegnano la mappa con 400 fanti e la nebbia spenta: Delphi Win32 Release 1,91-1,92 ms per fotogramma, C `-O1` 1,89-1,90 (minimo di 4 esecuzioni ciascuno, macchina scarica). **Non provato** perche' non portato: menu F10, trucchi sulla mappa, debug render, partite personalizzate (`custom N`). Dettagli: `Games\War\CLAUDE.md` e `Games\War\README.md`, sezione "Parte C".

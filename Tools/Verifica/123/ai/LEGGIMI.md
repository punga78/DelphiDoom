# Verifica #123 (seconda parte): obiettivi, movimento, azioni elementari e selezione genetica

Produce `Tests\Data\BotAi\goal\goalmove.golden.txt` con il codice **vero** di Quake III: `build.sh` copia in una cartella di lavoro `code/botlib/be_ai_goal.c`, `be_ai_move.c`, `be_ai_gen.c`, `be_ea.c`, `be_ai_weight.c`, `be_aas_file.c`, `be_aas_sample.c`, `be_aas_route.c`, `be_aas_routealt.c`, `be_aas_move.c`, `be_aas_bspq3.c`, `l_struct.c`, `l_libvar.c`, `l_script.c`, `l_precomp.c` (e gli header, ognuno con la guardia di inclusione che l'originale non ha), piu' alcuni intervalli di righe di `game/q_math.c`, `game/q_shared.c`, `game/be_aas.h`, `botlib/be_aas_main.c` e `be_aas_reach.c`. **Le uniche modifiche alle copie** sono dichiarate in `build.sh` (tre della rotta di `Tools\Verifica\122\route`, `BotClearMoveResult` che azzera tutto il risultato, `BotResetLastAvoidReach` che legge `avoidreachtries[latest]`, `BotSetBrushModelTypes` che controlla `modelnum >= MAX_MODELS`): sono gli unici punti dove il C vero legge o scrive fuori dai suoi array o usa memoria non inizializzata. `stub/` sostituisce il resto (`q_shared.h`, `botlib.h`, memoria, log, file system su cartella).

```
DELPHIDOOM_ROOT=/c/Progetti/DelphiDoom sh Tools/Verifica/123/ai/build.sh <cartella di uscita>
<cartella>/aigen.exe Tests/Data/BotAi/goal Tests/Data/BotAi/goal/goalmove.txt > Tests/Data/BotAi/goal/goalmove.golden.txt
```

(`cmd /c` e non `>` di Windows PowerShell 5.1, che scrive UTF-16.)

- `aigen.c` e' il pilota: un mondo **gemello** (le stesse regole in C e in Delphi: `TTwinBsp`, `TTwinModels`, `TTwinEntities` in `Tests\Source\DelphiDoom.Tests.BotAi.GoalMoveScenario.pas`) con la trace e il contenuto dei punti fatti sull'AAS, le scatole solide (`solid`), i liquidi (`liquid`), le entita' e i modelli del mondo. **Cambiando uno si cambia l'altro** e si rifa la golden. `commands.inc` ha i comandi (variabili, tempo, generatore, `gen`, `gensel`, `ea*`, `goal*`, `gs*`, `mv*`).
- `Make-Scenario.ps1` scrive `Tests\Data\BotAi\goal\goalmove.txt` (e' piu' comodo di un file scritto a mano: gli scenari ripetitivi sono cicli). `Tests\Data\BotAi\goal\botworld.aas` e' fatto dal Delphi (`TBotTestWorld` in `DelphiDoom.Tests.BotAi.World.pas`, la ricetta di `TAasSample` variante 1 con le raggiungibilita' di ogni tipo di viaggio) e letto **dallo stesso file** dal C e da Delphi. I file di oggetti e di pesi (`goal\botfiles`) sono scritti per i test.
- Compilatore: gcc a 64 bit di `Reference\_dati\_strumenti\w64devkit` (`-O1 -ffp-contract=off`, SSE). `random()` e' `rand()` del runtime Microsoft con `srand(seme)`. I `float` sono stampati come i loro bit (`#%08x`).
- Per ogni comando una riga `>comando` ripete l'ingresso; seguono i risultati (`RES` e `IN` per `BotMoveToGoal` e `EA_GetInput`, `TIC`, ` R` e ` I` per la simulazione `mvsim`, `AREA`, `GOAL`, `TOP`, `GEN`, stampe a ogni livello, comandi inviati).

## Come si e' provato che lo scenario copre il C

Ogni tipo di viaggio (`TRAVEL_*`, 15) ha una riga `RES ... TT n` e il test `DovrebbeAvereNelloScenarioOgniTipoDiViaggio` lo controlla. Le prove piu' difficili e come si ottengono:

- **grapple hook**: il gancio parte solo se il bot e' a meno di 5 unita' dall'inizio e guarda entro 2 gradi dalla direzione del gancio (con `viewoffset` 0 e angoli 0) e la trace verso la fine e' libera (il punto finale e' nella stessa area); i flag `MFL_ACTIVEGRAPPLE` e `MFL_GRAPPLERESET` rimangono nello stato fra due `mvgoal`, mentre `mvinit` azzera solo `ONGROUND`, `TELEPORTED`, `WATERJUMP`, `WALK` e `GRAPPLEPULL` (cosi' si prova il gancio attivo, perso, ripartito e tirato).
- **elevatore e func_bobbing**: `BotOnMover` traccia con una scatola verso il basso: la scatola solida del modello deve stare **sopra il pavimento dell'AAS** altrimenti vince la trace dell'AAS (`solid` con la cima a 0).
- **uscita dall'acqua e arrivi in aria**: `liquid|contenuto|min|max` mette uno strato d'acqua; un bot in aria sopra la mappa ha l'ultimo `reachnum` (`FinishTravel` di ogni tipo).
- **salti con le armi**: i salti hanno bisogno degli angoli di vista (90 gradi verso il basso, `viewangles` di `mvinit`) e poi di un bot in aria con la velocita' giusta.

Non provato sul C: le `AAS_*` di tutto il resto (sono in `Tools\Verifica\122`). Il mondo e' gemello, non il BSP di un gioco: la parita' prova la logica dei bot, non le trace contro un BSP vero.

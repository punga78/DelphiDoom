# Libs\Racing - auto, fisica, IA e gara di Speed Haste (issue #168, fetta S4)

> Note per Claude e paragrafi di dettaglio: [CLAUDE.md](CLAUDE.md).

Speed (`Reference\Speed`, `GLSpeed`) e un fork di DelphiDoom 2.05 che fa girare **Speed Haste** (Noriaworks, 1995) sul motore di Doom. Le sue regole di corsa stanno
in cinque unit del fork (`speed_cars`, `speed_path`, `speed_race`, `speed_score`, `speed_particles`, piu `speed_championship`) e leggono e scrivono i campi del `mobj_t`
e dei globali del motore. Questa libreria porta a classi **la parte pura**: la meccanica delle auto, i guidatori, il percorso, i giri, la classifica, la griglia di partenza
e le tabelle dei tempi. Tutto cio che crea oggetti o suona (particelle, suoni, il lancio degli oggetti dei punti) lo fa il gioco, dietro interfacce piccole.

## Che cosa c'e

| Unit | Classe | Ruolo (funzione originale) |
|---|---|---|
| `Types` | record e costanti | `TRacingCarState` (i campi del `mobj_t` che riguardano le auto: `double` delle ruote compresi), `TRacingCarInfo`, comandi, percorso, punteggi, tabella dei record (`packed`-compatibile con il file `.lap`) |
| `Intf` | interfacce | `IRacingRaceState` (e la parte che scrive il gioco, `IRacingRaceSettings`), `IRacingGeometry`, `IRacingEffects`, `IRacingPlayerEvents`, `IRacingGround`, `IRacingTrack`, `IRacingDriver`, `IRacingPlayerDriver`, `IRacingPhysics`, `IRacingCarSounds`, `IRacingParticles`, `IRacingGridAssigner`, `IRacingScoreTable` |
| `CarData` | `RACING_CAR_DATA` | la tabella `carinfo` delle 40 auto (20 formula, 20 di serie), **generata dal testo originale** (`Tools\Verifica\168\Racing`) |
| `Math` | `TRacingMath` | `GetIntegerInRange`, `IsIntegerInRange`, `iSign`, `MinI`, `P_Distance` |
| `GearBox` | `TRacingGearBox` | `SH_SetGear`, `SH_AutoGearBox`, `SH_ManualGearBox`, `SH_CalcRPM`, `SH_GearAccelerationFactor` e la tabella `GEAR_ACCEL_FACTORS` |
| `Ground` | `TRacingGround` | `SH_GroundTypeAtXY`, `SH_SlipperFactorAtXY`, `SH_SlipCalculation` (la mappa di 4096x4096 byte e del chiamante, non copiata) |
| `Particles` | `TRacingParticles` | `SH_SpawnParticleCheck` (dove e quando; il gioco crea l'oggetto) |
| `CarSounds` | `TRacingCarSounds` | `SH_EngineSound`, `SH_BrakeSound` (quale suono e quando; il gioco lo suona e dice quanto dura) |
| `Track` | `TRacingTrack` | `SH_GroupPathSequence`, `SH_GetNextPath`, `SH_NotifyPath`, `SH_GetTimeLaps`, `SH_CalculatePositions` |
| `Physics` | `TRacingPhysics` | `SH_ExecuteDrivingCmd` (marce, spinta, sterzo, derapata, quantita di moto, ruote, suoni, giri) |
| `AiDriver` | `TRacingAiDriver` | `SH_BuildDrivingCmdAI` |
| `PlayerDriver` | `TRacingPlayerDriver` | `SH_BuildDrivingCmdPlayer`, `SH_StorePlayerLapTimes` |
| `GridAssigner` | `TRacingGridAssigner` | la scelta delle auto di `SH_InitLevelCars` |
| `ScoreTable` | `TRacingScoreTableStore` | `SH_SortScoreTable`, `SH_UpdateScoreTable`, `SH_CheckLapRecord`, il file dei record (`SaveToBytes`/`LoadFromBytes`) |
| `RaceState` | `TRacingRaceState` | i campi di `race_t` che le auto leggono, piu i tic e la difficolta |
| `Championship` | `TRacingChampionshipSettings` | `SH_SaveChampionShipData` |
| `PathReader` | `TRacingPathReader` | la lettura di `SH_LoadPath`: lump `THINGS` e `PATH`, o il testo `<livello>_PATH.txt` |
| `Factory` | `TRacingFactory` | l'unico punto che conosce le classi |

Non fa parte della libreria (resta al gioco, S5): creare e spostare gli oggetti (`P_SpawnMobj`, `P_SetMobjState`), HUD, menu, la lettura dei file dal WAD e dal PAK, il file dei record su disco,
i savegame.

## Come si collega (per S5)

1. Il gioco tiene un `IRacingRaceSettings` (`TRacingFactory.CreateRaceState`) e a ogni tic scrive `SetRaceTime`, `SetLevelTime`, `SetStatus`; a ogni livello `SetNumLaps`, `SetCarType`, ... (le impostazioni del campionato:
   `TRacingChampionshipSettings.Build`).
2. Per ogni auto, a ogni tic: copia i campi dell'oggetto in un `TRacingCarState`, chiama `IRacingDriver.BuildCommand` (computer) o `IRacingPlayerDriver.BuildCommand` (giocatore, con `TRacingPlayerInput`
   dal `ticcmd_t`) e poi `IRacingPhysics.Execute`, e riscrive i campi nell'oggetto (`MomentumX/Y` sono la quantita di moto che il motore applica come sempre). `oldx/oldy` sono la posizione del tic prima: la
   velocita dell'auto e la distanza da li.
3. `IRacingEffects` e `IRacingGeometry` li risponde il motore (`R_PointToAngle2`, `P_AproxDistance` dalla vista; `P_SpawnMobj` con le sue estrazioni casuali per la particella A o B; `S_StartSound`).
4. `TRacingTrack.Load` riceve i punti dopo che il gioco ha creato l'oggetto di ognuno (`TRacingPathReader` da la lista da creare); `CalculatePositions` riceve le auto e il gioco scrive le posizioni.
5. `TRacingScoreTableStore.LoadFromBytes`/`SaveToBytes` sono i byte del file `<APPNAME>.lap` (230400 byte), lo stesso formato del vecchio gioco.

Il `double` del `mobj_t` (`tiredistance[0..3]`) resta un `Double` nel `TRacingCarState` e il gioco lo copia da e verso l'oggetto: la libreria non tocca il layout dell'oggetto, quindi non cambia i savegame.

## Verifica

* **Parita con il vecchio codice** (`Tests\Data\Racing\racing.golden.txt`, 111 righe): `Tools\Verifica\168\Racing\Run-Golden.ps1` taglia dai sorgenti originali (`Reference\Speed\Speed`) le funzioni di `speed_cars`, `speed_race`,
  `speed_path`, `speed_score` e `speed_particles` **senza ricopiarle a mano** (`Extract-Old.ps1`) e le compila con Delphi 11 Win32 in un harness (`OldRacing.pas`: gli oggetti, i thinker, i lump, i suoni ridotti ai campi che il vecchio
  codice legge; `FixedMul` in `asm` e `P_Distance` copiati da `m_fixed` e `p_maputl`). Gli stessi scenari (`Tests\Source\DelphiDoom.Tests.Racing.Scenarios.pas`) girano sul vecchio e sulla libreria e danno le stesse righe:
  terreno (600 punti con aderenza, un'altra dimensione, 800 prodotti di `SH_SlipCalculation`), tabelle dei tempi (400 aggiornamenti casuali, i 230400 byte del file e 400 controlli), griglia (3 famiglie x 4 insiemi di giocatori x 7 numeri di posizioni),
  percorso (3 giri con 24, 40 e 12 punti, quest'ultimo fuori ordine; 200 ricerche casuali del punto successivo piu una su ogni punto), fisica (4 auto x 3 difficolta x 3 guide x 2 terreni, 450 tic, **ogni campo dell'auto, i `double` delle ruote a bit, le particelle, i suoni e il risultato del giocatore ad ogni tic**) e
  gare (8 auto, 3 piste, 2 difficolta, 4800 tic, con la classifica ogni 5 tic, anche con auto che finiscono e un giro al contrario). **Zero differenze.** Una mutazione di prova (7 al posto di 6 nel calcolo della perdita di velocita) fa fallire 3 test: il confronto vede.
* Test in `Tests\DelphiDoom.Tests.Racing` (187: 8 di parita, il resto sulle singole classi con finti; `Tools\build.bat Tests\DelphiDoom.Tests.Racing`). La libreria compila anche a 64 bit (la parita e provata solo a 32: il vecchio codice usa `Extended`).

## Differenze dal vecchio codice

* **Un solo difetto per cui il vecchio leggeva memoria a caso e la libreria da un valore**: a 305 km/h, in sesta, il passo di velocita e 16 e `GEAR_ACCEL_FACTORS[6, 16]` e un elemento dopo la fine della tabella (`TRacingGearBox.Factor` dice 0;
  nell'harness il vecchio ha una riga di zeri in piu, e` l'unica modifica al testo originale). Il passo 16 delle altre marce e la prima colonna della marcia dopo, come nel vecchio (la tabella si legge come un blocco unico).
* Gli errori di dati danno `ERacingException` invece di leggere o scrivere fuori dai limiti: un punto del percorso che non esiste, un percorso non caricato, piu di 40 auto nella classifica, piu di 19 posizioni di partenza (era `I_Error`), `SH_CheckLapRecord` con
  episodio, mappa o famiglia di auto fuori dalle tabelle (ora `False`; il vecchio leggeva altra memoria).
* `SH_SpawnParticle` dereferenziava la particella senza controllare il nil: il gioco ora riceve la richiesta (con posizione e quantita di moto) e decide.
* `SH_BuildDrivingCmdPlayer` chiamava `SH_StorePlayerLapTimes` solo se esiste il tipo di oggetto `MT_CHECKLAPRECORD`; la libreria dice sempre al gioco che si e finito un giro (`IRacingPlayerEvents.LapCompleted`) e il gioco decide se creare l'oggetto.
* `SH_GetNextPath` e `SH_GroupPathSequence` non allocano piu una lista a ogni chiamata: stessa risposta (stessa scansione, stesso `<` stretto).
* Il testo `<livello>_PATH.txt` e diviso a spazi, virgole e righe (`//` e un commento), non con `TScriptEngine`: nessuna virgoletta.
* Il campo `mo` dei punti del percorso e della classifica e ora un indice (`TRacingPath.X/Y/Angle`, `TRacingPositionItem.Index`).

## Difetti del vecchio conservati (tutti con la parita)

* Dopo `SH_GroupPathSequence` i record dei punti sono riordinati ma i loro numeri (`id`, `next`, `prev`) restano quelli della mappa: una pista i cui punti non sono elencati nell'ordine del giro usa il punto sbagliato (le piste del gioco sono in ordine).
* La classifica tiene la tabella tra una chiamata e l'altra e per un'auto che ha finito non riscrive i suoi giri: sono quelli dell'ultimo calcolo in quel posto della tabella (la tabella e ordinata a ogni chiamata, quindi non e l'auto che si crede). Il pivot del quicksort e il posto della tabella e non una copia.
* `SH_SlipCalculation` moltiplica due interi a 32 bit prima di allargare: una forza grande cambia segno (test `DovrebbeConservareIlGiroDelProdottoAVentiduebit`).
* I tipi misti con segno e senza segno (`angle_t` con `fixed_t`) sono gli stessi: lo sterzo del computer e Int64 poi troncato, `-maxturn` e un `Cardinal` negato, la differenza tra due chiavi e come la fa Delphi.
* La derapata e lo sterzo sono sempre fatti a ogni tic anche con l'auto ferma; l'autista del computer non fa mai retromarcia.

## Non verificato

* **A runtime nel motore** (non esiste ancora un eseguibile Speed con le regole: S5): le auto sul serio con i `mobj_t`, i suoni, le particelle e i savegame.
* La parita a 64 bit (Win64 usa SSE al posto di `Extended`: `TireDistance` e `TRacingMath.Distance` possono differire negli ultimi bit).
* I lump `THINGS` e `PATH` veri di Speed Haste con `TRacingPathReader` (vedi lo stato in `Libs\Speed\README.md`).

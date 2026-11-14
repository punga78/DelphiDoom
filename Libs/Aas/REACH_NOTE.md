# Raggiungibilita' di Quake III (`be_aas_reach.c`) - nota da fondere in README.md e CLAUDE.md

Issue #122, quarta fetta. Port di `Reference\quake3\code\botlib\be_aas_reach.c` (4548 righe, GPL v2 o successiva, "Based on the
Quake III Arena GPL Source Code (id Software)" in ogni unit) in classi `DelphiDoom.Aas.Reach.*`: il calcolo di **tutte** le
raggiungibilita' di un file `.aas` (nessun globale: `aasworld`, `aassettings`, l'heap e i contatori `reach_*` sono nel contesto).
**Percorso freddo, nessun chiamante nel motore.**

## Mappa C -> Delphi

| C (`be_aas_reach.c`) | Delphi |
|---|---|
| `aas_lreachability_t`, costanti (`INSIDEUNITS` ...), `reach_*` | `Reach.Types` (`TAasLinkedReach`, `PAasLinkedReach`, `TAasReachCounters`, `EAasReachException`) |
| `AAS_SetupReachabilityHeap`, `AAS_AllocReachability`, `AAS_FreeReachability`, `areareachability`, `AAS_ReachabilityExists` | `Reach.Heap` (`TAasReachHeap`) |
| `AAS_FaceArea`, `AAS_AreaVolume`, `AAS_AreaGroundFaceArea`, `AAS_FaceCenter` | `Reach.Geometry` (`TAasReachGeometry`, `IAasReachGeometry`) |
| `AAS_FallDamageDistance`, `AAS_FallDelta`, `AAS_MaxJumpHeight`, `AAS_MaxJumpDistance`, `AAS_BarrierJumpTravelTime` | `Reach.Physics` (`TAasReachPhysics`, `IAasReachPhysics`) |
| `AAS_AreaGrounded`, `AAS_AreaSwim`, `AAS_AreaCrouch`, `AAS_AreaLadder`, `AAS_AreaJumpPad`, `AAS_AreaTeleporter`, `AAS_AreaClusterPortal`, `AAS_TravelFlagsForTeam` | `Reach.Context` (`TAasReachContext`); per `AAS_AreaLava/Slime/Liquid/DoNotEnter/Reachability` resta `IAasAreaQuery` |
| macro `VectorMA` con scala int o float, `VectorScale`, `VectorMiddle`, `VectorDistance`, `VectorBetweenVectors`, `traveltime += x` | `Reach.Vectors` (`TAasReachVectors`; `VectorMA` con scala `double` e' `TAasVectorMath.MultiplyAdd`) |
| `AAS_ClosestEdgePoints` | `Reach.EdgePoints` |
| `AAS_Reachability_Swim` | `Reach.Swim` |
| `AAS_Reachability_EqualFloorHeight` | `Reach.EqualFloor` |
| `AAS_Reachability_Step_Barrier_WaterJump_WalkOffLedge` | `Reach.Step` |
| `AAS_Reachability_Jump` | `Reach.Jump` |
| `AAS_Reachability_Ladder` | `Reach.Ladder` |
| `AAS_Reachability_Grapple` | `Reach.Grapple` |
| `AAS_Reachability_WeaponJump`, `AAS_SetWeaponJumpAreaFlags` | `Reach.WeaponJump`, `Reach.WeaponFlags` |
| `AAS_Reachability_WalkOffLedge` | `Reach.WalkOffLedge` |
| `AAS_GetJumpPadInfo` | `Reach.JumpPadInfo` |
| `AAS_Reachability_JumpPad` | `Reach.JumpPad` |
| `AAS_Reachability_Teleport` | `Reach.Teleport` |
| `AAS_Reachability_Elevator` (func_plat) | `Reach.Elevator` |
| `AAS_FindFaceReachabilities`, `AAS_Reachability_FuncBobbing` | `Reach.FuncBobbing` |
| `AAS_BestReachableLinkArea`, `AAS_BestReachableArea`, `AAS_BestReachableFromJumpPadArea` | `Reach.BestReachable` (`TAasReachBest`; sull'interfaccia `IAasBestReachable` sta il calcolatore) |
| `AAS_InitReachability`, `AAS_ContinueInitReachability`, `AAS_StoreReachability` | `Reach.Calculator` (`TAasReachCalculator`: `IAasReachInitializer` e `IAasBestReachable`) |
| creazione | `Reach.Factory` (`TAasReachFactory`) |
| contratti | `Reach.Intf` (`IAasReachGeometry`, `IAasReachPhysics`, `IAasBestReachable`, `IAasReachInitializer`, `IAasReachabilityEditor`) |

`TAasFile` implementa anche `IAasReachabilityEditor` (`ReplaceReachability`: `AAS_StoreReachability` alloca una tabella nuova); `TAasBspTrace`
(`Move.Types`) ha il campo nuovo `SurfaceFlags` (`bsp_trace_t.surface.flags`, la fune non si attacca al cielo: `SURF_SKY`),
riempito da `TAasCollisionWorld` dal `SurfaceFlags` della trace di `Libs\Collision`. Il resto di `Move.*`, `Links`, `Bsp.*` e'
usato com'e'.

## Cosa e' diverso da quello che diceva il compito

* **Non ci sono "15 aree per ciclo"**: `REACHABILITYAREASPERCYCLE` e' definita e mai usata. Il ciclo vero fa `todo = numreachabilityareas +
  framereachability` con `framereachability = 2000`, si ferma se `Sys_MilliSeconds() - start_time > reachability_delay (1000)` e
  **dopo ogni area** quando `numreachabilityareas * 1000 / numareas > lastpercentage` (`lastpercentage` resta a 0 fino alla fine della
  chiamata: con meno di 1000 aree ogni chiamata fa un'area). Il parametro `time` non e' usato. L'orologio e' dato dal costruttore
  (`TAasMilliseconds`, nil = 0). I tre `static` (`framereachability`, `reachability_delay`, `lastpercentage`) sono campi.
  `ContinueInitReachability` da' `True` anche alla chiamata che memorizza la tabella: si ripete finche' da' `False`.
* **`AAS_RandomGoalArea` e' in `be_aas_route.c`** (riga 2001), non in reach: non e' portata qui (serve la traccia del box e `random()`;
  resta fuori come scritto nel README del routing).
* **Le mappe di OpenArena non hanno la geometria quasi mai**: sono state ottimizzate (`bspc -optimize`): 52 file su 71 hanno 1 faccia, 1 spigolo
  e 0 vertici (`GEO 1 1 0 0` nelle golden). Li' i calcoli sulle facce non trovano niente e restano solo quelli delle entita' (ascensori,
  teletrasporti, trampolini). Hanno la geometria `am_galmevish`, `ce1m7`, `dm4ish`, `dm6ish`, `islanddm`, `kaos`, `oa_bases3cl`, `oa_bases5`,
  `oa_dm1`..`oa_dm7`, `oa_rpg3dm2`, `oa_shine`, `ps37ctf`, `q3dm6ish`: le golden del repository sono `fan` (entita'), `oa_bases5` e `oa_dm4`
  (geometria, tutti i tipi), non `oa_bases3` e `blitzkrieg3`.

## Parita' col C vero

`Tools\Verifica\122\reach`: `reachgen.c` include i VERI `be_aas_file.c`, `be_aas_sample.c`, `be_aas_move.c`, `be_aas_reach.c` (copiati da
`build.sh`, **nessuna modifica** al codice vero), butta via le raggiungibilita' del file, chiama il vero `AAS_InitReachability` e
`AAS_ContinueInitReachability` finche' non finisce e stampa per ogni area `A <area> <n> <areaflags> <hash>` (e le `R` complete: tutte in
`full`, solo quelle della prima area con ogni tipo di viaggio in `digest`), i contatori `reach_*`, i messaggi (le righe di percentuale, circa una
per area, sono solo contate e fatte hash: `PCT`). Gemello Delphi: `TAasReachScenario` (`Tests\Source\DelphiDoom.Tests.Aas.Reach.Scenario.pas`);
**se si cambia uno si cambia l'altro** e si rifanno le golden (`Make-Golden.ps1`, con `-All` anche le 71 complete in
`C:\harness\q3reach\goldens`, da dare in `DELPHIDOOM_REACH_GOLDENS`). La parita' prova la **logica**: il BSP del gioco e' sostituito da
gemelli uguali in C e in Delphi (il contenuto di un punto e la trace sono quelli del file AAS, `surface.flags` 0; le entita' e i limiti dei
modelli vengono dal `.bsp` di OpenArena, lump 0 e 7, con i limiti allargati di un'unita' come fa `cm_load.c`; le funzioni `AAS_*BSPEpairKey` sono un
piccolo gemello del parser: l'ultima coppia con la stessa chiave vince come nell'originale), quindi le raggiungibilita' calcolate **non sono
quelle del file del gioco** (che erano per il BSP vero): conta solo che C e Delphi diano le stesse righe. Le trace con grapple 1
(`grapplereach`) sono nelle golden.

## Difetti del C vero conservati

* **`AAS_FaceCenter(face2num)` con il numero con segno** (`WeaponJump`, `JumpPad`, `Grapple`): un numero negativo legge `faces[-n]`, la memoria
  prima delle facce. Il pilota ci mette facce a zero (`calloc` prima del vettore, `reachgen.c`); una faccia a zero ha centro `0 * inf` = NaN.
  `TAasReachGeometry.FaceCenter` da' un centro NaN per un numero negativo; `WeaponJump` e `JumpPad` saltano la faccia (nel C nessun confronto
  con NaN e' vero e non succede niente: provato leggendo `AAS_HorizontalVelocityForJump`), `Grapple` segue il percorso del C con il NaN.
* **`abs()` e' intero** nel ladder: `abs(DotProduct(..)) < 0.1` e' vero per ogni prodotto tra -1 e 1 (il float e' troncato a 0); `0.7` idem.
* **`AAS_Reachability_Jump` e `_Grapple` danno sempre `qfalse`** anche se creano la raggiungibilita': `ContinueInit` non fa `continue`.
* **`AAS_Reachability_JumpPad` esce con `continue` senza `AAS_UnlinkFromAreas`** quando la velocita' orizzontale supera 100: i link restano nello
  heap (qui lo stesso, `Links.FreeCount` scende).
* **`lreach = AAS_AllocReachability()` senza controllo in `FuncBobbing`**: heap esaurito = NULL e crash nel C; qui `EAasReachException`.
* **`AAS_Reachability_Step_..._WalkOffLedge` riusa `dist`** (la distanza del piano) come distanza minima dentro il ciclo sugli spigoli di area 2:
  il valore cambia per gli spigoli dopo il primo; conservato (stessa variabile).
* `FuncBobbing` modifica `startreach->start` dentro il ciclo su `endreach` (si vede dalle coppie successive); `Elevator` allarga `mins` e `maxs` a
  ogni giro e non li ripristina; `AAS_GetJumpPadInfo` con un bersaglio sopra il trampolino da' `sqrt` di un numero negativo: NaN, e `!time` non lo prende.
* L'heap: l'errore `AAS_MAX_REACHABILITYSIZE` si stampa quando si da' l'**ultimo** link (che e' dato lo stesso); il successivo da' NULL.

## Trappole viste

1. **`VectorMA` con scala intera o float** (5, 2, 48, 64, -32, -3, -15, 8, 16, 1, -500, 4) fa due arrotondamenti a float (`float(v + float(b*s))`):
   `TAasReachVectors.MultiplyAdd`; con scala `double` (`0.1`, `0.5`) e' `TAasVectorMath.MultiplyAdd` (un arrotondamento a double).
2. **`fabs` da' un `double`**: `rs_startwalkoffledge + fabs(d) * 50 / gravity` e `rs_startgrapple + VectorLength(dir) * 0.25` sono interamente double e
   si troncano una volta a `unsigned short`; le espressioni senza `fabs` (Jump, Elevator, FuncBob) sono float. `traveltime += float` e' float e poi
   `unsigned short` (`AddTravelTime`, `Word(Trunc(x) and $FFFF)`).
3. **Confronti con un'espressione** (`mins > maxs + 10`, `dist < bestdist + 1`, `facecenter[2] < areastart[2] + 64`): float nel C, in una variabile
   `Single` prima di confrontare; quelli con `0.1`, `0.5`, `0.7` sono double (costanti `Double` tipate).
4. **Indici dei `for` dopo il ciclo** (`i >= 3`, `l >= 16`, `p >= 3`, `n = 9999` negli ascensori, `l != numedges` nel ladder): cicli `while` con un flag.
5. **`dir[p] < origin[p] + mins[p] || ...`** negli ascensori: `break` = fuori dal box, `p >= 3` = dentro e si salta.
6. **Eccezioni della FPU e precisione**: `TAasReachFloatMode` mette la maschera di tutte le eccezioni e la precisione `double` dell'x87 per la durata di
   ogni chiamata (Delphi a 32 bit arrotonda due volte un'operazione `double`); a 64 bit e' SSE e non cambia niente.
7. **Stampe con `%f`**: `printf` arrotonda al pari sul valore esatto, `Format` di Delphi no: `TAasReachFormat.Fixed`.
8. **`AAS_BestReachableArea(origin, mins, maxs, origin)`** passa lo stesso vettore due volte (`AAS_SetWeaponJumpAreaFlags`): il codice cambia `goalorigin`
   e poi legge `origin`: `TAasReachBest.BestReachableAreaInPlace`.
9. **Gli indici dei vettori del file** si controllano con `{$R+}` nelle unit di calcolo; `ERangeError` diventa `EAasReachException`.
10. Una `TAasReachContext` non e' contata: la possiede `TAasReachCalculator`, che e' un `TInterfacedObject` (l'interfaccia che si tiene vivo basta).
    La factory da' `IAasReachInitializer`; `Supports(x, IAasBestReachable)` da' le tre funzioni per `be_ai_goal.c`.

## Interfacce per la #123 (`be_ai_goal.c`, `be_ai_move.c`) e per `be_aas_entity.c`

* `IAasBestReachable`: `BestReachableArea(origin, mins, maxs, var goalorigin)`, `BestReachableLinkArea(head)` (**la testa e' una lista di
  `TAasEntityLinks`**: e' quello che chiama `AAS_BestReachableEntityArea` di `be_aas_entity.c`), `BestReachableFromJumpPadArea`.
* `IAasReachGeometry`: `FaceArea`, `AreaVolume`, `AreaGroundFaceArea`, `FaceCenter`. `IAasReachPhysics`: `FallDamageDistance`, `FallDelta`,
  `MaxJumpHeight`, `MaxJumpDistance`, `BarrierJumpTravelTime`.
* `IAasReachInitializer`: `InitReachability`, `ContinueInitReachability(time)` (per `AAS_ContinueInit` di `be_aas_main.c`: reach -> `AAS_InitClustering`
  -> `AAS_InitRouting`), `NumReachabilityAreas`, `Counters`.
* I predicati sulle aree (`AAS_AreaSwim`, `AAS_AreaGrounded`, `AAS_AreaLadder`, `AAS_AreaJumpPad` ...) sono `IAasAreaQuery`, gia' esistente.

## Non portato

`AAS_RandomGoalArea` (in `be_aas_route.c`), `AAS_PermanentLine` e le funzioni di disegno (`AAS_DebugLine`: nessun disegno), `Log_Write` (il registro
dei `funcbob`), `REACH_DEBUG`, il ramo `BSPC` (il compilatore di mappe), `bot_visualizejumppads` (le chiamate di movimento hanno `visualize` falso),
l'avviso `AAS_BestReachableArea: aas not loaded` (il file e' sempre caricato).

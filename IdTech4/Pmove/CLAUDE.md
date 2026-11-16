# IdTech4\Pmove — note per Claude

Descrizione, tabella C -> Pascal, difetti e differenze: [README.md](README.md). Questo file ha il **metodo** e le trappole che hanno fatto perdere tempo.

## Il movimento del giocatore di Quake III (issue #127, della #115)

Unit `DelphiDoom.Pmove.*`, una classe per unit, percorso freddo (nessun chiamante nel motore di Doom). `TPmoveFactory.CreateMover(IPmoveTrace, ...)` / `CreateForMap(IQ3CollisionModel)` -> `IPmove.Execute(var TPmove)`.
Le classi condividono un `TPmoveState` (i globali `pm`, `pml`, `c_pmove`); le parti sono oggetti semplici (`TPmoveParts` li costruisce e li libera, i movimenti sono `TSingletonImplementation`: non contati, mai un riferimento a interfaccia e uno a oggetto sulla stessa istanza che li possiede).
`IdTech4\Collision` non e' toccata (l'adattatore `TPmoveCollisionTrace` sta qui); `TQ3PlayerState` e `TQ3UserCmd` sono quelli di `IdTech4\NetQ3` (spostati da `Libs\Net` nella #237: l'eccezione di strato `Pmove -> Net` non c'e' piu').

### Virgola mobile: come si ottiene l'identita' bit per bit (Win32 x87 e Win64 SSE)

La parita' e' **esatta** (nessuna tolleranza) con il C compilato da gcc/SSE. Regole che l'hanno data, da seguire in ogni modifica:

- **Una operazione float per istruzione, in una variabile `Single`** (`LTerm := A * B; LValue := C + LTerm;`): e' esatta su x87 (il prodotto di due float sta in un extended, un solo arrotondamento al `Single` memorizzato; per somme e divisioni il doppio arrotondamento 64 -> 24 bit e' innocuo) e dcc64 non promuove le catene di `Single`. **Mai** `A * B + C * D` in un'espressione.
- **I punti che nel C passano per un double** si riproducono con locali `Double` nello stesso ordine: `pml.msec * 0.001` (`Q3_MSEC_TO_SECONDS`), `SHORT2ANGLE`, ogni `sqrt` (somma float, radice double, risultato float: `TPmoveVector.SquareRoot`), `delta*delta*0.0001`, `waterlevel / 3.0` e `1.0 - (1.0 - swimScale) * waterScale` (ogni passaggio e' un float `waterScale` assegnato da un double), `(-b - sqrt(den)) / (2*a)` in `PM_CrashLand`, `pm_friction*1.5`, `addTime /= 1.3` (tronca), `(float)speed * max / (127.0 * total)` in `PM_CmdScale` (**`total` e' un `float`**: e' una dichiarazione, non un double come sembra dall'espressione; cosi' e' stato trovato da un 1 ulp nella velocita' di noclip).
- Le **costanti double** sono `Q3_*` in `Types` e un test (`TTestPmoveTuning`) ne confronta i bit con quelli del compilatore C: un literal decimale passa per Extended a Win32 e potrebbe doppio-arrotondare.
- I confronti `float < 0.7` del C sono contro un double (`Q3_STEP_NORMAL`), `trace.plane.normal[2] < MIN_WALK_NORMAL` contro un float (`Q3_MIN_WALK_NORMAL`): una normale con z = `0.7f` e' camminabile ma non e' "piana" per il gradino; il mondo del golden ha una rampa cosi'.
- **Gli interi in float** si convertono in una variabile a parte (`LGravity := Ps.Gravity; LStep := LGravity * FrameTime`).
- `M_PI` e' un **float** (`q_shared.h` di MSVC); il `math.h` di mingw lo fa double. `Tools\Verifica\127\premath.h` rimette quello dell'originale: senza, `AngleVectors` del C dava 1-2 ulp di differenza dal Pascal.
- A Win64 le eccezioni in virgola mobile sono quelle di SSE: `TPmover.Execute` le maschera per la durata della chiamata (`SetExceptionMask`) e le rimette; il caso di `PM_CrashLand` a gravita' 0 (`0/0`, `x/0`) e' comunque risolto a parole (un confronto con un NaN su x87 non e' affidabile in Delphi).
- Tipi in un record con layout: `TQ3PlayerState.Origin/Velocity/ViewAngles/GrapplePoint` sono array anonimi e **non convertono** in `TQ3Vec3`: `TPmoveState.Origin/Velocity/ViewAngles/GrapplePoint` danno un `PQ3Vec3` sullo stesso indirizzo.

### Il golden e come si regge

`Tests\Data\Pmove\pmove-golden.txt` (430 KB, 32220 comandi) e' scritto da `Tools\Verifica\127` (vedi `LEGGIMI.md` li'): il vero `bg_pmove.c`, `bg_slidemove.c`, `bg_misc.c` con un mondo finto (brush e sweep di `CM_TraceThroughBrush`) che il Pascal rilegge **dal golden** (piani come bit). Il golden ha mondo, scenari, comandi e un'impronta per comando: il test non genera niente. Quando un'impronta differisce il test scrive `%TEMP%\pmove-scenario-<id>.txt` (stesso formato di `pmgen dump <id>`): `diff` in minuscolo da' il primo comando e il campo.
Se si cambia `pmgen.c` il golden **cambia per intero** (la generazione e' a seme fisso ma sequenziale): rifarlo con `make-golden.sh`, controllare le coperture (stderr) e rieseguire i test a Win32 e Win64.

### Cose da sapere

- `Pmove` taglia il comando in passi da 66 msec (`pmove_msec` con `pmove_fixed`); un passo ha `Msec` fra 1 e 200 (200 solo con un tempo fisso oltre 200). `Msec < 1` non si raggiunge mai (la guardia di `Execute` lancia prima).
- L'anello degli eventi e' di 2 (`MAX_PS_EVENTS`): chi legge `Ps.Events` dopo la chiamata vede gli ultimi due.
- Il `pmove_t` e' per valore: `Execute` lo copia nello stato, lavora e lo rimette (anche se solleva). `Cmd` ed `TraceMask` tornano cambiati, come nel C.
- Il catalogo degli oggetti (`IPmoveItemCatalog`) e' del gioco: `TPmoveBaseItemCatalog` ha i 36 tag di baseq3; un gioco con un'altra lista da' il suo.
- Aggiungere un tipo di movimento: una classe con `IPmoveMovement`, un campo in `TPmoveParts` e il ramo in `TPmover.PmoveSingle` (la scelta `fly / grapple / waterjump / water / walk / air` e' li').

### Non portato, resta

Vedi README: MISSIONPACK (Team Arena), `PM_CheckStuck`, il ramo `_DEBUG` di `BG_AddPredictableEventToPlayerstate`; il mondo vero con entita'; le patch nella collisione (`IdTech4\Collision`).
Un altro uso di `PlayerState`/animazioni dei giocatori Q3 e' in `Framework\Models` (`TQ3PlayerAnimator`, `Models.Q3Player.*`): legge `legsAnim`/`torsoAnim` e i campi dello stesso stato; non e' stato toccato.

# Libs\Pmove — il movimento del giocatore di Quake III (id Tech 3) a classi

> Note per Claude e trappole di virgola mobile (issue #178): [CLAUDE.md](CLAUDE.md).

Port a classi di `Reference\quake3\code\game\bg_pmove.c` (2069 righe), `bg_slidemove.c` (325) e delle parti di `bg_public.h`, `bg_local.h`,
`bg_misc.c` (`BG_AddPredictableEventToPlayerstate`, `bg_itemlist`) che il movimento usa: la fisica del giocatore condivisa da client e server
(camminata, aria, acqua, salto, accovacciata, gradini, attrito, accelerazione, gravita', rampe, timer, eventi, armi nella parte che gira nel
movimento). Dato lo stato del giocatore (`playerState_t`) e il comando dell'utente (`usercmd_t`) calcola lo stato successivo. **Non e' collegato al
motore** (DelphiDoom e' id Tech 1; vedi `WIRING.md` della libreria `Libs\Collision` per il modello di collisione di Quake III che gli da' il mondo).

Licenza: Quake III Arena e' GPL v2 o successiva (`Reference\quake3\code\COPYING.txt`), compatibile con il repository. Ogni unit porta
"Based on the Quake III Arena GPL Source Code (id Software)" e il copyright di id Software. Nessun sorgente C e' copiato nel repository (il C
che produce il golden sta in `Reference\`, ignorato da git, e `Tools\Verifica\127` lo ritaglia e lo compila da li').

## Perche' una libreria nuova e non dentro `Libs\Collision`

`Libs\Collision` e' il modello di collisione (mondo, brush, trace): sa rispondere "dove si ferma questa scatola". Il movimento e' un'altra
responsabilita': ha uno stato (il giocatore), il tempo, gli eventi, le animazioni e le armi, e **dal mondo vuole solo due risposte** (`trace` e
`pointcontents`), che arrivano da un'interfaccia piccola (`IPmoveTrace`). Tenerlo fuori fa si' che il movimento si provi con un mondo finto (il golden), con
il modello di una mappa (`TPmoveCollisionTrace` sopra `IQ3CollisionModel`) o con quello che un gioco compone (mondo piu' entita': il server di Quake III aggiunge
mover e corpi al trace del mondo). `Libs\Collision` non e' stata toccata. Riusa e non duplica: `TQ3PlayerState` e `TQ3UserCmd` di `Libs\Net`
(`Net.Q3.Types`, i record verificati sul C), `TQ3Vec3`, `TQ3Trace`, `TQ3Math.AngleVectors` e `TQ3Math.Dot` di `Libs\Collision` (gia' provate sul C), le costanti delle animazioni di
`Libs\Models` (`Models.Q3Player.Types`, le stesse del `TQ3PlayerAnimator`), `ILog` di `Libs\Logging`; nei test `TTestFnv`, `TTestFiles`, `TTestSkip`
(`Tests.Shared.*`) e `BitsOfFloat`/`FloatOfBits`/`BuildRoomBsp` di `Tests.Collision.Q3Support`.
**`Libs\MathCore` e' stata esaminata e non e' usata**: `TVectorMath` (`DelphiDoom.MathCore.VectorMath`) e' il port del vecchio `m_vectors` di DelphiDoom, verificato bit per
bit contro il vecchio codice Pascal e non contro il C di Quake III; lavora su `TVec3` (un altro tipo, non assegnabile a `TQ3Vec3` e ai campi di `TQ3PlayerState`), vieta lo stesso
vettore in ingresso e in uscita (il movimento lavora sul posto: `PM_ClipVelocity (v, n, v)`) e non ha `VectorNormalize2` ne' `PM_ClipVelocity`. `TPmoveVector` e' un
guscio sottile (un'operazione float per istruzione) sulla stessa funzione di `Libs\Collision` per il prodotto scalare e provato sul C vero dalla parita' a ogni comando.

## Cosa c'e'

| C | Pascal (`DelphiDoom.Pmove.*`) |
|---|---|
| `pmove_t` | `TPmove` (`Types`): lo stato in/out, il comando, `tracemask`, i risultati (`numtouch`, `touchents`, `mins`, `maxs`, `watertype`, `waterlevel`, `xyspeed`), `pmove_fixed`, `pmove_msec` |
| `pml_t` | `TPmoveLocals` (`Types`), azzerato a ogni passo |
| `pm`, `pml`, `c_pmove`, `pm_stopspeed` ... `pm_spectatorfriction` | `TPmoveState` (`State`): i globali diventano un oggetto; `TPmoveTuning` (`Types`) con i valori di `bg_pmove.c`; `Counter` = `c_pmove` |
| `pm->trace`, `pm->pointcontents` | `IPmoveTrace` (`Intf`); `TPmoveCollisionTrace` (`CollisionTrace`) sul modello di una mappa |
| `bg_itemlist[...].giTag` | `IPmoveItemCatalog` (`Intf`), `TPmoveBaseItemCatalog` (`Items`, i 36 oggetti di baseq3) |
| `Pmove`, `PmoveSingle`, `PM_DropTimers`, snap della velocita' | `TPmover` (`Mover`, implementa `IPmove`): sotto-passi da 66 msec o `pmove_msec`, tempo, `pmove_framecount`; `trap_SnapVector` = arrotondamento al pari |
| `PM_UpdateViewAngles` | `TPmoveViewAngles.Update` (`ViewAngles`), anche come `IPmove.UpdateViewAngles` |
| `PM_AddEvent`, `BG_AddPredictableEventToPlayerstate`, `PM_AddTouchEnt`, `PM_StartTorsoAnim`, `PM_StartLegsAnim`, `PM_ContinueLegsAnim`, `PM_ContinueTorsoAnim`, `PM_ForceLegsAnim` | `TPmoveEvents` (`Events`) |
| `PM_Friction`, `PM_Accelerate`, `PM_CmdScale`, `PM_SetMovementDir` | `TPmovePhysics` (`Physics`) |
| `PM_SlideMove`, `PM_StepSlideMove` (`bg_slidemove.c`) | `TPmoveSlider` (`Slider`) |
| `PM_SetWaterLevel`, `PM_CheckDuck` | `TPmoveBody` (`Body`) |
| `PM_GroundTrace`, `PM_GroundTraceMissed`, `PM_CorrectAllSolid`, `PM_CrashLand`, `PM_FootstepForSurface` | `TPmoveGround` (`Ground`) |
| `PM_AirMove`, `PM_GrappleMove` | `TPmoveAirMover` (`AirMover`) |
| `PM_WaterMove`, `PM_CheckWaterJump`, `PM_WaterJumpMove` | `TPmoveWaterMover` (`WaterMover`) |
| `PM_FlyMove`, `PM_NoclipMove` | `TPmoveFlyMover` (`FlyMover`) |
| `PM_WalkMove`, `PM_CheckJump`, `PM_DeadMove` | `TPmoveWalkMover` (`WalkMover`) |
| `PM_Weapon`, `PM_BeginWeaponChange`, `PM_FinishWeaponChange`, `PM_TorsoAnimation`, `PM_Animate` | `TPmoveWeapon` (`Weapon`) |
| `PM_Footsteps`, `PM_WaterEvents` | `TPmoveFootsteps` (`Footsteps`) |
| `PM_ClipVelocity`, `VectorLength`, `VectorNormalize(2)`, `VectorMA`, `CrossProduct` ... | `TPmoveVector` (`Vector`): un'operazione float per istruzione, come le arrotonda il C |
| composizione | `TPmoveParts` (`Parts`, costruisce e libera le parti), `TPmoveFactory` (`Factory`, l'unico che conosce le classi) |

```pascal
LMover := TPmoveFactory.CreateForMap(LModel);        // IQ3CollisionModel di una mappa; o CreateMover(IPmoveTrace, ...)
LPmove.Ps := ...;  LPmove.Cmd := ...;  LPmove.TraceMask := Q3_MASK_PLAYERSOLID;
LMover.Execute(LPmove);                              // LPmove.Ps e' lo stato successivo
```

Il tempo e' sempre un argomento (`Cmd.ServerTime` contro `Ps.CommandTime`); nessun globale; due `IPmove` non condividono niente (un mover per thread).
Come `ClientThink_real` il chiamante azzera il `pmove_t` a ogni comando: la chiamata cambia `Cmd` e `TraceMask`.

## Cosa non e' portato

- **MISSIONPACK** (Team Arena, tutto cio' che sta sotto `#ifdef MISSIONPACK`): `PM_InvulnerabilityMove`, le armi `WP_NAILGUN`, `WP_PROX_LAUNCHER`, `WP_CHAINGUN` e i loro tempi,
  `STAT_PERSISTANT_POWERUP`, `PW_SCOUT` e `PW_AMMOREGEN` in `PM_Weapon`, le animazioni dei gesti di squadra. Il port e' di baseq3 e baseoa (nessun `MISSIONPACK`), con le costanti
  di baseq3 (`STAT_WEAPONS` = 2, 11 armi); `PW_INVULNERABILITY` in `PM_CheckDuck` non e' sotto `#ifdef` ed e' portato. Per Team Arena servono costanti e tabella delle armi diverse.
- `PM_CheckStuck` (commentato nel C), `pm_wadeScale` e `pml.impactSpeed` (calcolati, non letti da nessuno: restano nei record), `pmove_t.framecount` (non e' usato dal C).
- Il ramo `_DEBUG` di `BG_AddPredictableEventToPlayerstate` (stampa con `showevents`).
- Il mondo vero di un gioco: entita', mover, corpi, trigger (la libreria da' il modello della mappa); `Com_Printf` di `debugLevel` va all'`ILog` iniettato (nil = niente).

## Difetti e particolarita' del C conservati (servono a dare gli stessi byte)

Ognuno e' coperto dal golden o ha un test.

- `EF_FIRING` si calcola **prima** che il tasto delle chiacchiere (`BUTTON_TALK`) azzeri gli altri tasti: parlando con attacco premuto e munizioni il flag resta (`DovrebbeIgnorareIlComandoSeIlTastoDelleChiacchiereEPremuto`).
- `PM_CrashLand` aggiunge `PM_FootstepForSurface()` anche per le superfici `SURF_NOSTEPS`, che ritorna 0: un evento `EV_NONE` occupa un posto dell'anello degli eventi.
- `PM_CrashLand` ritorna prima di azzerare `bobCycle` con `den < 0`, sott'acqua (livello 3) o con danno sotto 1.
- Con **gravita' 0** `PM_CrashLand` divide per zero: il tempo e' infinito o non un numero, `delta` non un numero e nessun confronto lo accetta, quindi l'atterraggio e' un passo (`EV_FOOTSTEP`, `bobCycle` a 0). Il Pascal fa lo stesso senza eccezioni (`DovrebbeAtterrareSenzaGravitaComeUnPassoSenzaEccezioni`).
- `PM_WalkMove` ha due rami che il dispatcher di `PmoveSingle` non raggiunge (acqua oltre il livello 2, salto con acqua oltre il livello 1: con quel livello va a `PM_WaterMove`): sono portati e provati chiamando `TPmoveWalkMover` da solo.
- `MAXTOUCH` (32) non si raggiunge in un passo (un passo ha poche collisioni e `numtouch` si azzera a ogni passo): il limite e' portato e provato direttamente su `TPmoveEvents`.
- `PM_SlideMove(qfalse)` legge `endVelocity` non inizializzato (il risultato non e' usato): il Pascal lo azzera.
- La velocita' e' arrotondata dal motore dopo il movimento (`trap_SnapVector`): al pari, e un valore fuori da 32 bit (o non un numero) da' l'"integer indefinite" `-2^31`.
- Il comando e' cambiato dalla chiamata: dopo un passo con il salto tenuto, `Cmd.UpMove` vale 20 per i passi seguenti dello stesso comando (e il chiamante lo vede).

## Differenze volute

| Differenza | Test |
|---|---|
| `pmove_fixed` con `pmove_msec` minore di 1: l'originale **non finisce** (il tempo non avanza o torna indietro); qui `EPmoveException` | `DovrebbeRifiutareUnTempoFissoMinoreDiUno` |
| La chiamata maschera le eccezioni della virgola mobile e rimette la maschera com'era (il C gira con le eccezioni spente: uno stato non finito dà il risultato IEEE, non un'eccezione) | `DovrebbeNonSollevareEccezioniConUnoStatoNonFinito`, `DovrebbeLasciareLaMascheraDelleEccezioniComeLAveva` |
| Un indice fuori dalla lista degli oggetti: `giTag` 0 (il C legge fuori dalla tabella) | `DovrebbeDareZeroPerUnIndiceFuoriDallaLista` |
| `Pmove` e' chiamabile con un solo mover per thread; niente stato globale | — |

Contratto non verificato: `ps.weapon` deve essere 0..15 (indice di `ammo`) e `stats[STAT_HOLDABLE_ITEM]` un oggetto della lista, come nel C.

## Parita'

Con il codice **vero** (`Tools\Verifica\127`, gcc di w64devkit, SSE, vedi `LEGGIMI.md` e `Tests\Data\README.md`): `bg_pmove.c`, `bg_slidemove.c` e `bg_misc.c` compilati tali e quali con un mondo finto scritto da noi (90 brush: pavimento, scale, ostacoli, rampe, acqua, melma, lava, corridoio basso, creste a 45 gradi, 36 pali, mover) implementato in modo identico in C e in Pascal.
**192 scenari, 32220 comandi, 16 tipi di movimento**: dopo ogni comando l'impronta dello stato (117 parole, risultati, comando, testo di diagnostica) e' **identica bit per bit** a Win32 (x87) e a Win64 (SSE). Nessuna tolleranza.
Secondo livello: sul modello di collisione di Quake III (`TPmoveCollisionTrace` su `IQ3CollisionModel`) con mappe di OpenArena 0.8.8 (`pak1-maps.pk3`, lette dove sono e ignorate se mancano): 18 partenze su 6 mappe, 500 comandi ciascuna (corsa, giri, salti, tempi diversi), **mai dentro un muro** e risultato uguale a ogni esecuzione.
Il caricatore del modello (`Libs\Collision`, #118) rifiuta con il suo validatore una mappa di OpenArena su 50 di `pak1-maps.pk3` (`aggressor.bsp`: "fog 0 is outside the 0 fogs", 74 problemi; le altre 49 si caricano): il test passa alla mappa successiva. E' una segnalazione per chi ha in carico la #118 (il motore vero la carica).

## Test

`Tests\DelphiDoom.Tests.Pmove` (`Tools\build.bat Tests\DelphiDoom.Tests.Pmove Release [Win64]`): 85 test (parita' 20, mover 28, parti 28, collisione 7 e OpenArena 2), copertura di `Libs\Pmove` **98%** (`Tools\Copertura.ps1 -Test Pmove`); le righe non coperte (18 su 1371) sono: `Msec < 1` di `PmoveSingle` (la guardia di `Execute` lancia prima: non raggiungibile), `numplanes >= MAX_CLIP_PLANES` e lo stop a tre piani di `PM_SlideMove`
(raggiungibili nel C ma non da nessuno degli scenari: servono quattro piani diversi in quattro urti o una cresta non assiale con un terzo piano; nemmeno la valle a 45 gradi del golden ci arriva),
il ramo di errore di `TPmoveFactory` (`except`, libera lo stato) e `Copy`/`Clear` di `TPmoveVector`, che il compilatore espande in linea.

**Teletrasporto**: `bg_pmove.c` non ha codice di teletrasporto. Il lato del movimento di `TeleportPlayer` (`g_misc.c`) e' lo stato che lascia: `pm_time` 160, `PMF_TIME_KNOCKBACK`, la velocita' di 400 unita' al secondo lungo
la vista e i `delta_angles` del bersaglio; il golden parte da quello stato (modo 12, `pm_time` 160 e velocita' 400) e dai `delta_angles` casuali del modo 14.

## Resta da fare

- Collegamento a un motore di Quake III: il mondo vero (entita', mover, corpi) come `IPmoveTrace`; ora c'e' solo il modello della mappa.
- Team Arena (MISSIONPACK).
- Le patch (superfici curve) nella collisione: dipende da `Libs\Collision` (`IQ3PatchCollideBuilder`); senza, una patch non collide e il giocatore la attraversa.

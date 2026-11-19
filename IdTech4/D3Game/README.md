# IdTech4\D3Game

Il lato gioco di Doom 3 (id Tech 4) senza renderer: le classi del gioco con la loro riflessione (`idClass`, `idTypeInfo`), l'entita' di base, la tabella delle entita' di `idGameLocal` con la generazione dalle `entityDef` e dalla mappa, il ciclo di think di un fotogramma e il collegamento alla macchina degli script. Issue #255, fase 3 (`docs\DOOM3_CENSIMENTO.md`). Port di `game\gamesys\Class.cpp`, `Class.h`, `game\Entity.cpp`, `game\Game_local.cpp` di `Reference\doom3`. **Licenza**: GPL v3 o successiva con gli "Additional Terms" di Doom 3 (`Reference\doom3\COPYING.txt`) per le unit derivate, dichiarata nell'intestazione; il motore di Doom resta GPL v2 o successiva. Nessun chiamante nel motore.

```pascal
// il sistema delle classi: dichiarazioni in qualunque ordine, poi Init
LClasses := TD3ClassSystem.Create(LPrinter, LEvents, LEventPoster);   // dichiara idClass
LClasses.Declare('idEntity', 'idClass', nil, TD3Entity.SpawnClass, True);          // ABSTRACT_DECLARATION
LDoor := LClasses.Declare('idDoor', 'idEntity',
  function: TD3Class begin Result := TMyDoor.Create(LGame, LGame); end, TMyDoor.SpawnClass);
LDoor.AddEvent(LEvents.FindEvent('open'), procedure(const ATarget: TD3Class; ...) begin ... end);
LClasses.Init;

// il gioco: la tabella delle entita' e lo spawn
LGame := TD3GameLocal.Create(LServices, LClasses);   // TD3GameServices: interfacce piccole
LGame.NewMap;
LGame.MapSource := TD3MapFileSource.Create(LMapFile);
LGame.MapPopulate;                                   // worldspawn nel numero 4094, le altre da 32
LGame.RunFrameThink;                                 // fa pensare le entita' attive
LEntity := LGame.FindEntity('door1');
```

| C++ | Pascal |
|---|---|
| `idTypeInfo`, `idClass` | `TD3TypeInfo`, `TD3Class` (`ClassBase`) |
| i membri statici di `idClass`, `idClass::Init` | `TD3ClassSystem` |
| `idEntity` | `TD3Entity` |
| `idGameLocal` (tabella delle entita', spawn, mappa, think) | `TD3GameLocal` |
| `common`, `declManager`, `program`, `idEvent`, cvar | `ID3GamePrinter`, `ID3EntityDefs`, `ID3SpawnFunctions`, `ID3ScriptNames`, `ID3MapSource`, `ID3GameSettings`, `ID3MapSteps`, `ID3EventCanceller`, `ID3EventPoster`, `ID3EntityObserver` |
| adattatori sopra `Decl`, `MapFile`, `IdLib`, `DoomScript` | `TD3DeclEntityDefs`, `TD3MapFileSource`, `TD3GameLogPrinter`, `TD3GameSettings`, `TD3ScriptBridge` |

Dettagli, decisioni, difetti del C++ conservati e parita' (7 scenari su 1410 righe del C++ vero, Win32 e Win64) in `IdTech4\D3Game\CLAUDE.md`; harness in `Tools\Verifica\255\Build-Harness-Game.ps1`; test in `Tests\DelphiDoom.Tests.D3Game` (13 test).

**Ondata 12a**: target (`idEntityPtr`), nascondere/mostrare, fisica parametrica lineare, i trigger (`TD3TriggerMulti`, `Timer`, `Count`, `Hurt`, `Fade`; `trigger_once` e `trigger_relay` sono entityDef di `idTrigger_Multi`, ipotesi), `TD3MoverBinary`, `TD3Door` e `TD3Mover` (movimento lineare). Si dichiarano con `TD3WorldClasses.Declare( LClasses, LEntityEvents, LGame )` (gli eventi nel registro della macchina prima di compilare gli script); il ponte degli script porta le code degli eventi e i valori di ritorno. Parita' sul C++ vero con un quarto harness (`Tools\Verifica\255\Build-Harness-World.ps1`: `Trigger.h`, `Mover.h`, la coda degli eventi vera e i corpi veri di `Trigger.cpp`, `Mover.cpp`, `Physics_Parametric.cpp`), 5 scenari, 1834 righe, zero differenze a Win32 e Win64; prova senza dati con un `trigger_once` che apre una porta e un `main` che l'aspetta (`Tests.D3Host.WorldProof`). Test: `Tests\DelphiDoom.Tests.D3Game` (47), `Tests\DelphiDoom.Tests.D3Host` (45).

**Ondata 13**: `TD3ClipModel` e `TD3Clip` (`idClipModel` e `idClip`: settori, `Translation`, `Rotation`, `Motion`, `Contents`, i modelli che toccano un volume) sopra `IdTech4\Collision`, le fisiche con clip model (`TD3PhysicsClip`), `idEntity::TouchTriggers` (i trigger sono clip model `CONTENTS_TRIGGER`, il `<touch>` lo manda il clip), il trigger clip model della porta con il suo `Event_Touch`, `idEntity::Damage` vero (il trigger `Hurt` toglie salute). Si usa dando al gioco un clip (`TD3GameServices.Clip`, costruito su un `ICollisionModelManager` che ha il modello `worldMap`: `Clip.Init`); senza clip tutto e' come prima. Parita' col `Clip.cpp` vero e con `neo\cm` (`Tools\Verifica\255\Build-Harness-Clip.ps1`, 265 righe di golden, tolleranza 4 ULP sulle righe `TRACE`); test 61 (Win32 e Win64). Resta fuori: bind, il giocatore (nessuno chiama `TouchTriggers` da solo), `idPush`, gli angoli, `Contacts`, `idTrigger_EntityName`/`_Touch` (par. 8 di `docs\DOOM3_CENSIMENTO.md`).

Cosa non c'e' ancora: bind, i contatti del clip, il giocatore, le luci, gli oggetti, `idWorldspawn` vero, le animazioni, l'IA, i salvataggi, il `RunFrame` intero (elenco con i motivi nel par. 7 di `docs\DOOM3_CENSIMENTO.md`).

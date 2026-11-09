# Piano: `Libs\ScriptHost` a classi (issue #172, fetta 2)

Analisi in sola lettura, fatta sul sorgente di `master` (919a19ef). Conteggi ricavati con `grep`/`wc`/`awk` sulle unit di `Libs\ScriptHost`; dove un numero e una stima lo dico. Nessun file di codice e stato modificato, nessuna build e stata eseguita.

Letti prima: `CLAUDE.md`, `docs\FACCIATE.md`, `Libs\ScriptHost\README.md`, `Libs\PascalScript\README.md`, `Libs\Script\README.md`, `docs\SCRIPT.txt`.

---

## 1. Che cosa c'e oggi

### 1.1 Righe e routine per unit

| Unit | Righe | Routine `PS_*` (nomi distinti) | Altre classi / routine | `{$IFDEF}` di gioco |
|---|---:|---:|---|---:|
| `psi_game` | 14.064 | **412** | 13 classi (`TActorKeyList`, `TRTLActor(s)`, `TRTLVertex(es)`, `TRTLSide(s)`, `TRTLLine(s)`, `TRTLSector(s)`, `TRTLMobjInfo(Item)`) e **289 helper di proprieta** `TRTL*_R/_W` | 37 righe (57 con le `{$IF`) |
| `psi_map` | 1.979 | **77** | nessuna classe | 1 |
| `psi_overlay` | 2.849 | **12** | `TOverlayDrawer` (34 metodi) | 4 |
| `psi_globals` | 1.928 | **16** | 12 classi (`THashTable`, `THashStringList`, `TGlobalVariablesList`, `TMap/World Strings/Integers/Floats`...) | 0 |
| `psi_system` | 955 | **40** | solo tipi array | 0 |
| `ps_main` | 1.201 | 25 (eventi, salvataggio, `PS_Init`...) | `TPSExecManager` (classe privata), `A_RunScript` | 0 |
| `ps_import` | 1.646 | 5 | `TDoomCompiler`, `TDoomExec`, `TPSDoomRuntimeClassImporter`, **579 registrazioni** | 37 righe |
| `ps_serializer` | 563 | 0 | `TScriptSerializer` (gia classe) | 3 |
| `ps_events` | 406 | 0 | `TScriptEvents` (gia classe) + tabella `EventExportedProcs` | 11 |
| `ps_proclist` | 270 | 0 | `TProcedureList` | 0 |
| `ps_dll` | 216 | 4 | procedure `PS_PAKLoadDll`... | 0 |
| **Totale** | **26.077** | **591 definizioni (557 in `psi_*`)** | | |

Il README parla di "circa 1.600 routine `PS_*`": e il conteggio delle righe `procedure/function` (1.212 in `psi_game` da sola), che conta due volte ogni funzione (dichiarazione in `interface` e corpo) e include i metodi delle classi. Le routine **registrate come funzioni di script** sono **572 simboli** (`@nome` in `ps_import`; 579 dichiarazioni), le **proprieta di classe** di `SIRegister_Game` sono **406** (`RegisterProperty`) su 12 classi.

### 1.2 Quello che gli script vedono (le "API")

1. **Funzioni libere**: 579 dichiarazioni testuali in `ps_import.PS_InitProcLists` (`baseproclist.Add('function Nome(...): T;', @PS_Nome)` e 5 `AddWithCustomResult`), in 4 "unit" di script (`units: TStringList` ordinata): `SYSTEM` **56**, `PS_GAME` **504**, `PS_FIXED` **9**, `PS_OVERLAY` **10**. Lo script scrive `uses all;` (le carica tutte tranne `SYSTEM`, in ordine alfabetico) o il nome di una singola unit; `SYSTEM` e sempre implicita.
2. **Classi "finte"** registrate sul compilatore (`SIRegister_*`: `AddClassN` + `RegisterProperty`/`RegisterMethod`) e sull'interprete (`RIRegister_*`: `Add2(TClasseDelphi, '!NOME')` + `RegisterPropertyHelper(@helper_R, @helper_W, 'Nome')`): `Actors`, `Lines`, `Sides`, `Sectors`, `Vertexes`, `MobjInfo` (psi_game: 12 classi), `MapStrings/WorldStrings/MapIntegers/WorldIntegers/MapFloats/WorldFloats` (psi_globals: 6 classi e 6 variabili), `Overlay` (psi_overlay: e proprio il `TOverlayDrawer` del motore a essere la classe dello script).
   Trucco centrale: un `TActor`/`TLine`/`TSector` dello script **non e un oggetto**: e la chiave (`LongWord`, o l'indice) travestita da puntatore, e gli helper la ricavano con `LongWord(Self)` (`TRTLActorX_R(Self: TRTLActor; var T: Integer)` fa `T := PS_GetActorX(LongWord(Self))`). Quindi ogni proprieta di attore esiste **due volte**: come funzione `GetActorX(key)`/`SetActorX(key, v)` e come `Actor.X`; le 98 proprieta di `TRTLActor` ripetono le `GetActor*`/`SetActor*` (58+42).
3. **Costanti e tipi** aggiunti da `PS_ScriptOnUses('SYSTEM')`: circa 290 righe di `AddConstant` (flag dei mobj da `mobj_flags*`, nomi degli stati da `statenames`, `GetEnumName(TypeInfo(...))` per mobjtype/skill/card/weapon/power/gender/..., costanti `GEN*`, `ANG*`, `QF_QUEST1..31` in Strife...), molto sotto `{$IFDEF}` di gioco.
4. **Eventi** chiamati dal motore (`TScriptEvents`, 10): `OnActorDied`, `OnPlayerEnter`, `OnPlayerDied`, `OnCrossLine`, `OnShootLine`, `OnUseLine`, `OnTick`, `OnTimerEverySecond`, `OnTimerEveryMinute`, `OnMapStart`; la tabella `EventExportedProcs` va "tenuta in sincronia a mano" con `ScriptOnExportCheck` e con `TScriptEvents`.

### 1.3 Chi chiama ScriptHost dal motore (superficie da non rompere)

* **Ciclo di vita**: `Doom|Heretic|Hexen|Strife\d_main.pas` (`PS_Init`, `PS_CompileAllScripts`, `PS_ShutDown`), `Base\DelphiDoom.Engine.ActorDef.Hooks` (`PS_AddSourceScript`, `PS_AddCompiledScript`), `TLevelLoader` (`PS_LinkScriptEvents`), `g_game` x4 (`PS_NewMap`, `PS_NewWorld`, `PS_MapScriptSaveSize`), `Libs\Ddc\dd_compiler` (`PS_InitProcLists`, anche nelle DLL `ddc_*` per DD_IDE).
* **Eventi**: `Base\p_tick` (MapStart, PlayerEnter, Tick, Second, Minute), `p_inter` x4 (PlayerDied, ActorDied), `p_map` x4 (CrossLine, ShootLine, UseLine), `p_enemy` x4 (UseLine), `Strife\p_mobj` (ShootLine x2).
* **Salvataggi**: `p_saveg` Doom/Heretic/Strife e `Hexen\sv_save` (`PS_MapScriptSaveToFile/LoadFromFile`, `vars.SaveToBuffer` sui `mapvars`/`worldvars`, `overlay.SaveToBuffer`).
* **Variabili di script usate dal motore**: `Base\p_common` (circa 40 usi di `mapvars`/`worldvars` e `PS_Set*` nei comandi di stato), `Base\sc_params` (24 chiamate `PS_Get*` per valutare i parametri), overlay visto da `v_video`, `v_displaymode`, `gl_main` (`overlay.ReCalcOverlayLookUp`, `OVR_OverlayHeight`).
* `ComposeEngine` conosce gia `PS_ConfigureConsole` (psi_system, `IEngineConsole`), `PS_ConfigureDefaults` (`IEngineDefaults`) e `PS_ConfigureFiles` (psi_globals, `IEngineFiles`): **tre iniezioni gia fatte a facciata**.

---

## 2. Inventario per categoria e dipendenze dal motore

Conteggi delle funzioni `PS_*` per sezione di `psi_game` (banner dei corpi, righe 3222-13454; i helper `TRTL*` tra parentesi) e delle altre unit. "Caldo" = costo per tic o per fotogramma anche con script semplici.

| Gruppo | Dove | `PS_*` | Globali del motore letti/scritti | Per gioco | Caldo |
|---|---|---:|---|---|---|
| **Attori / mobj** (get/set, flag, target, suoni, rimozione, sposta, spawn, vista, `Actors.All*`) | `psi_game` ACTORS | 115 (112) | `mobjlist.FindMobjFromKey`, `Pmobj_t`, `p_mobj/p_map/p_maputl/p_inter/p_sight`, `S_StartSound`, `r_translations` (sangue), `ps_currentactor` (variabile del modulo) | si: `flags2`, argomenti, `special` (la maggior parte delle 37 `{$IFDEF}` e qui e nei settori) | `Actors.All*` alloca un array a ogni chiamata; il resto e per chiamata di script |
| **MobjInfo** (`mobjinfo[]` in sola lettura, `GetMobj*`) | MOBJS | 72 (71) | `mobjinfo[]` (69 rif.), `info`, `info_common`, `p_params`, `statenames` | campi MBF21/Hexen | no |
| **Linee** | LINES | 34 (34) | `lines[]`, `numlines` (43+), `p_setup`, `p_local` | tag/trasparenza non in Hexen | no |
| **Lati** | SIDES | 26 (27) | `sides[]`, `r_data` (`R_TextureNumForName`) | no | no |
| **Settori** (altezze, luce, pendenze, special, offset, nebbia, attori/linee) | SECTORS | 60 (61) | `sectors[]`, `numsectors` (77 rif.), `p_slopes`, `p_maputl` | offset flat solo `DOOM_OR_STRIFE` | no |
| **Vertici** | VERTEXES | 5 (6) | `vertexes[]` | no | no |
| **Giocatore** (presenza, arma, salute, chiavi, artefatti, missioni Strife) | PLAYERS | 29 | `players[]` (40 rif.), `consoleplayer`, `p_user` | molto: artefatti, chiavi, classi, quest | no |
| **Texture** | TEXTURES | 3 | `r_data`, `w_wad` | no | no |
| **Partita** (`_GAME`, `GameSkill`, `GameEpisode`, `GameMap`, `SkyPicture`, terremoto) | GAME | 6 | `gameskill`, `gameepisode`, `gamemap`, `p_tick`, `r_sky` | si | no |
| **Tastiera** (`key_*`, `mousebfire`... come funzioni, `gamekeydown`) | KEYBOARD CONTROL | 59 | `gamekeydown`, `key_*`, `mousebuttons` | si (inventario, volo, ...) | no |
| **Thinker e speciali di settore** (porte, soffitti, pavimenti, piattaforme, pilastri, luci, polyobj) | `psi_map` | **77** | nessun globale letto: pacchetto `argsbuffer_t` di 8 byte + `EVH_DoDoor/EVH_DoCeiling/EVH_DoFloor/EVH_DoPlat/EVH_SpawnLight/PO_*` di `udmf_*`, `p_spec`, `po_man`, `p_anim` (Hexen) | 1 `{$IFDEF HEXEN}` | no |
| **Console, math, stringhe, tempo** | `psi_system` | 40 | `leveltime`, `P_Random`, `finesine`, `IEngineConsole`/`IEngineDefaults` (gia iniettati), `I_Error`/`I_Warning` (7) | no | no |
| **Variabili di mappa/mondo** (`Get/SetMap/World*` e le 6 classi) | `psi_globals` | 16 (12 classi) | `IEngineFiles` (gia iniettato), `c_cmds`, `z_zone`, `I_Error` (8) | no | **si per `sc_params`**: ogni parametro di un `A_*MapVar*` fa una ricerca hash (8192 catene) |
| **Overlay/HUD** | `psi_overlay` | 12 | `v_video`, `v_data`, `r_hires`, `hu_stuff`, `w_wad`, `z_zone`, `mt_utils` (thread), `leveltime`, `d_net`, `sc_params`, `I_Error`/`printf` (25) | `{$IFDEF OPENGL}` (4 righe) | **si**: `FlashToScreen8/32` e `DrawDrawers` a ogni fotogramma, tabelle `lookup` da `MAXWIDTH*MAXHEIGHT` puntatori |
| **Fixed point** (9 registrazioni `PS_FIXED`) | in `ps_import` | 0 (puntano a `m_fixed`) | `m_fixed` | no | si, ma sono funzioni gia esistenti |
| **Dispatch, compilazione, esecuzione** | `ps_main`, `ps_import`, `ps_events`, `ps_serializer` | 25 + 5 | `players[]`, `P_CheckStateParams`, `w_pak`, `c_cmds` (`compile`/`compilescript`/`pscomp`), `w_folders` | no | `PS_EventTick` per tic (esce subito se lo script non ha l'evento) |
| **DLL in PAK** | `ps_dll` | 4 | `w_pak`, `i_tmp`, `w_folders`, `LoadLibrary` | no | no |

**Dipendenze da gioco**: le differenze sono in 37 righe `{$IFDEF}` di `psi_game` (artefatti, chiavi, classi, offset flat, quest di Strife, `FLOATRANDZ` di Hexen) e 37 di `ps_import` (costanti e tipi di `PS_ScriptOnUses`). Non servono quattro profili: serve una **lista di funzioni e costanti che dipende dal gioco** (cosa registrare) e pochi corpi che cambiano.

---

## 3. Come funziona la registrazione e come puo diventare un registro a gruppi

### 3.1 Il meccanismo attuale

* `PS_InitProcLists` crea 4 `TProcedureList` (`ps_proclist`: `(decl, puntatore, nome calcolato, risultato custom)`) e li mette in `units` (maiuscolo, `Sorted := True`).
* Compilatore: `PS_ScriptOnUses(Sender, Name)` (`TDoomCompiler.OnUses`): per `SYSTEM` registra le classi (`SIRegister_GlobalVars`, `SIRegister_Game`, `SIRegister_TOverlay`), la lista `SYSTEM` (`RegisterProcsComp` -> `AddDelphiFunction(decl)`), costanti e tipi; per `ALL` richiama se stessa sulle altre unit; per un nome noto registra la sua lista; altrimenti `ecUnknownIdentifier`. Ricorda i nomi in `TDoomCompiler.unitnames`.
* Interprete: `TDoomExec.LoadData` riregistra per ogni unit usata `RegisterProcsExec` -> `RegisterDelphiFunction(@proc, nome, cdRegister)` e `RIRegisterRTL_*` (`SetVariantToClass` per `Actors`, `Lines`...). `TPSDoomRuntimeClassImporter.Create` registra le classi con `Add2`.
* Vincolo: **un solo `TDoomCompiler`** alla volta (`dccnt` e `I_Error` se ne nasce un secondo).

Punto critico: `RegisterDelphiFunction(codice, nome, cdRegister)` vuole un **puntatore a codice semplice**, senza `Self`. Opzioni:

* **A. Gruppi a classi con thunk procedurali** (la facciata del progetto, come `PS_ConfigureFiles`): il corpo vive nella classe, `PS_GetActorX` resta come `begin Result := ScriptActors.GetX(key); end;`. Stessa firma, stessa dichiarazione testuale, nessun rischio di convenzione di chiamata. Costo: fino a 557 thunk di una riga, generabili da script a partire da `ps_import`.
* **B. `RegisterDelphiMethod(Slf, ProcPtr, Name, CC)`** (esiste in `ps_runtime.pas:614`): lega l'istanza e toglie i thunk. **Non e mai usata nel repository** (nessun chiamante fuori dal nucleo): da provare con una spike su un metodo con risultato `string`, uno con `array of const`, uno con risultato `TActorArray` (array dinamico) e uno con parametro `Extended`, a 32 bit e poi a 64 bit (`x64.inc`).
* **Raccomandazione**: partire con A, tenere B come passo successivo se la spike passa.

### 3.2 Interfacce proposte (schema `Libs\`)

```
DelphiDoom.ScriptHost.Intf.pas        IScriptFunctionGroup, IScriptFunctionRegistry, IScriptFunctionTable
DelphiDoom.ScriptHost.Types.pas       EScriptHostException
DelphiDoom.ScriptHost.Registry.pas    TScriptFunctionRegistry  (sostituisce TProcedureList + units)
DelphiDoom.ScriptHost.Factory.pas     TScriptHostFactory (unico punto che conosce le classi)
```

```pascal
IScriptFunctionTable = interface   // dove un gruppo scrive le sue funzioni
  procedure Add(const ADeclaration: string; const ACode: Pointer);
  procedure AddWithCustomResult(const ADeclaration, AResultType, AExportDeclaration: string;
    const ACode: Pointer);
end;

IScriptFunctionGroup = interface   // una classe per gruppo
  function UnitName: string;                         // 'SYSTEM', 'PS_GAME', ...
  procedure Describe(const ATable: IScriptFunctionTable);
end;

IScriptFunctionRegistry = interface
  procedure AddGroup(const AGroup: IScriptFunctionGroup);
  function Contains(const AUnitName: string): Boolean;
  procedure RegisterCompiler(const AUnitName: string; const ACompiler: TPSPascalCompiler);
  procedure RegisterExecutor(const AUnitName: string; const AExec: TPSExec);
  function Declarations(const AUnitName: string): string;  // per DD_IDE / dd_compiler
  function UnitNames: TStringList;                          // ordine alfabetico come oggi
end;
```

Un gruppo concreto (es. `TScriptSystemFunctions`) riceve dal costruttore le sue dipendenze come interfacce piccole (`IEngineConsole`, `IEngineDefaults`, `IGameContext` per `LevelTime`, `IGameRandom` per `P_Random`/`RandomRange`, `ILog`). Le classi "variabile" (`Actors`, `Lines`...) sono un secondo contratto (`IScriptClassGroup`: `SIRegister`, `RIRegister`, `Bind`), che nel primo giro **resta nelle unit attuali**.

Il contratto verso lo script **non cambia**: stesse stringhe di dichiarazione, stessi nomi (anche gli incoerenti: `_GAME`, `TActor` come procedura, i `Polyobj_OR_*` doppi in `PS_GAME`), stesso ordine, stesse unit, `uses all` che salta `SYSTEM`.

### 3.3 Classi dei gruppi (una per unit `DelphiDoom.ScriptHost.<Area>.<Nome>`)

| Classe | Prende | Dipendenze iniettate |
|---|---|---|
| `TScriptSystemFunctions` (40) | `psi_system` | `IEngineConsole`, `IEngineDefaults`, `IGameContext`, `IGameRandom`, `ILog` |
| `TScriptFixedFunctions` (9) | tabella `PS_FIXED` | nessuna |
| `TScriptVariables` + `IScriptVariables` (16 + 12 classi) | `psi_globals` | `IEngineFiles`, `ILog` |
| 7 classi piccole Door/Ceiling/Floor/Light/Plat/Pillar/Polyobj (77) | `psi_map` | **un solo** gateway `IScriptSectorSpecials` (le `EVH_*`/`PO_*` procedurali) |
| `TScriptOverlay` (12) | `psi_overlay` | `IOverlayCanvas`, `IGameContext`, `ILog` |
| `TScriptGameInfo`, `TScriptKeys`, `TScriptTextures` | GAME/KEYBOARD/TEXTURES | `IGameContext`, `IScriptWorld` |
| `TScriptVertexes`, `TScriptSides`, `TScriptLines`, `TScriptSectors`, `TScriptPlayers`, `TScriptMobjInfo` | blocchi di `psi_game` | `IScriptWorld`, ciascuna con una interfaccia stretta |
| `TScriptActors` | ACTORS + `TActorKeyList` | `IScriptActorContext` (attore corrente, ricerca per chiave, spawn/remove, suoni) |
| `TScriptManager` (ex `TPSExecManager`) | `ps_main` | `IScriptFunctionRegistry`, `IScriptSourceProvider`, `ILog`, `ITempFiles`/`IPakFileSystem` |
| `TScriptEventDispatcher` | `ps_events` | l'esecutore PS |
| `TScriptStateSerializer` | `ps_serializer` | `TStream` |
| `TScriptDllLoader` | `ps_dll` | `IPakFileSystem`, `ITempFiles` |

`IScriptWorld`/`IScriptActorContext` nominano tipi del motore (`Pmobj_t`, `Psector_t`): vanno in `Base\DelphiDoom.Engine.Script.*` (classi `TEngine*` create da `ComposeEngine`, come `TEngineAcsHost` per l'ACS), non in `Libs\`.

---

## 4. Strategia di parita

### 4.1 Cosa esiste gia e cosa no

* **Esiste**: `Tests\DelphiDoom.Tests.Script*` prova `DDScript` (10 unit `Tests\Source\DelphiDoom.Tests.Script.*`, sorgenti PS in memoria in `...Script.Samples`). **Non tocca `Libs\ScriptHost`**.
* **Non esiste**: nessuno script di gioco di esempio nel repository (`docs\SCRIPT.txt` ha 5 frammenti; gli esempi stanno su SourceForge); `Tests\Data\ActorDef\*\scripts2.in.txt` e solo parsing delle direttive `SCRIPT/ENDSCRIPT`; nessun golden di una `PS_*`; nessun test di `ps_events`, `ps_serializer`, `ps_import`. **La rete di sicurezza va costruita prima di toccare codice** (fetta 2a-0).

### 4.2 Tre livelli di prova

**L1 - Tabella di registrazione (golden, senza partita).** Una build di prova per gioco (Doom, Heretic, Hexen, Strife, con i `uses` reali, come i `ddc_*`) che chiama `PS_InitProcLists` e scrive:
 * per ogni `TProcedureList` (`PS_ImportUnits`): unit e `GetDeclarations` (le 579 stringhe, in ordine);
 * un `uses all;` compilato in un programma vuoto con `TDoomCompiler`, poi `GetTypeCount/GetType`, `GetProcCount/GetProc`, `GetConstCount/GetConst` (esistono, `ps_compiler.pas:830-837`) con nome e tipo, e i membri delle classi: prova che le 406 proprieta, le classi e le circa 290 costanti sono identiche;
 * gli indirizzi non sono confrontabili fra due eseguibili: la corrispondenza "dichiarazione -> routine" si prova a L2.
 Golden in `Tests\Data\ScriptHost\<Gioco>.registration.golden.txt`, prodotti dal codice **attuale** prima di toccarlo (come `Tests\Data\TableExport\<Gioco>.golden.txt`).

**L2 - Batteria di script nel motore (vecchio/nuovo eseguibile).** E la tecnica di #142, #146, #148, #150: si compila il vecchio eseguibile da `HEAD` prima della modifica e il nuovo, si esegue la stessa sequenza deterministica e si confronta l'uscita.
 * Un generatore (script in `Tools\Verifica\<n>\`) legge le 579 dichiarazioni (golden L1) e per ognuna produce una chiamata con argomenti presi da una serie a seme fisso (validi, fuori intervallo, invalidi: chiavi di attori veri, 0, `ACTOR_INVALID`, linee e settori nel limite e oltre) dentro uno script `OnMapStart`/`OnTick` che scrive il risultato con `Writeln` e rilegge lo stato (`GetActorX` dopo `SetActorX`).
 * Un PWAD di prova con un ACTORDEF `script map01 ... endscript` (sintassi di `docs\SCRIPT.txt`) su un livello vero (WAD in `bin\<Gioco>`: Freedoom 2, Heretic, Hexen, Strife demo), avviato con `-warp` e `Tools\Esegui-gioco.ps1`; uscita in `DATA\LOGS\*_stdout.txt`.
 * Impronta FNV-1a dello stato (mobj, settori, linee, lati, giocatori: il codice c'e nell'harness di #142) dopo ogni passo; gametic e posizione finale del `-timedemo` identici.
 * Le funzioni che cambiano il mondo (spawn, remove, sposta, speciali) si provano in una seconda esecuzione, per non dipendere dal ripristino dello stato.
 Fattibile con quello che c'e; richiede il generatore e un PWAD per gioco (stima nella fetta 2a-0). Limite: le build OpenGL si provano solo come "partono".

**L3 - DUnitX con finti (solo la parte pura).** Come per l'ACS (`Libs\Acs` si prova, `TEngineAcsHost` no): cio che **non nomina tipi del motore** si prova in `Tests\DelphiDoom.Tests.ScriptHost`:
 * registro (`SYSTEM` sempre implicita, `ALL` salta `SYSTEM` ed e in ordine alfabetico, nome sconosciuto = errore, doppioni) con un `TPSPascalCompiler` vero (`Libs\PascalScript` si puo linkare da test, come fa DDScript);
 * `TScriptVariables`, con **golden dei byte di `SaveToBuffer`** del vecchio `TGlobalVariablesList` e `StructureSize` uguale ai byte scritti;
 * `TScriptStateSerializer` sul nucleo PS reale: compilare, scrivere lo stato, rileggerlo, confrontare con i byte del vecchio `TScriptSerializer`;
 * tabella degli eventi: `EventExportedProcs` e `ScriptOnExportCheck` con firme giuste e sbagliate;
 * `psi_map` con gateway finto che registra `args[0..7]` (golden = pacchetto del vecchio per ognuna delle 77 funzioni, con stub di `EVH_*`, tecnica `Libs\Script\Shim`).
 I gruppi di `psi_game` leggono `Pmobj_t`, `lines[]`...: **non si testano cosi**, si coprono con L1+L2 (come `p_acs`, `p_setup`, `p_inter`).

### 4.3 Formati che non possono cambiare (golden dei byte prima di toccare)

| Cosa | Dove | Note |
|---|---|---|
| `mapvars`/`worldvars` | `TGlobalVariablesList.SaveToBuffer/LoadFromBuffer/StructureSize` (`p_saveg` x3, `sv_save`) | interi a 4 byte, stringhe con lunghezza e **`PUT_CHAR` = `Char` (2 byte, UTF-16)** per carattere; ordine: stringhe, interi, reali (`float`) |
| overlay | `TOverlayDrawer.SaveToBuffer/LoadFromBuffer/SaveSize` | `MT_memcpy` grezzo di `overlaydrawer_t` (record non `packed`, con **`sparam: string[255]`**): `SizeOf` e offset in un test |
| stato degli script di mappa | `TScriptSerializer.SaveToStream/LoadFromStream/SaveSize` | prefisso `size` + `ElemCount` + variabili per tipo; `btExtended` scrive `SizeOf(TbtExtended)` (**10 byte a 32 bit, 8 a 64**) e le stringhe `SizeOf(Char)`: da decidere nella #43, non qui |
| bytecode compilato `.ddout` | `ID_DDPS` in `ps_import` | non cambia: nessuna fetta tocca `ps_compiler`/`ps_runtime` |

---

## 5. Fette proposte (ordinate per rischio)

XS 25m, S 1h30, M 3h, L 1d, XL 2d+. Ogni fetta: collegare, verificare, **poi** cancellare il vecchio (Strangler Fig). Per ognuna: `build.bat all`, i test di `Tests\DelphiDoom.Tests.ScriptHost`, i due eseguibili di confronto per L2.

| Fetta | Contenuto | Stima | Dipende da | Criterio di verifica |
|---|---|---|---|---|
| **2a-0** | **Rete di sicurezza, nessuna modifica al codice**: harness L1 (dump della registrazione per i 4 giochi), generatore e PWAD per L2 (almeno SYSTEM, FIXED, globali, 5 funzioni per gruppo), golden dei byte dei 3 salvataggi prodotti dal **vecchio** codice; spike di `RegisterDelphiMethod` (4 casi di 3.1) a 32 bit; `Tools\Verifica\<n>\LEGGIMI.md` | **M-L** | - | golden riproducibili (due esecuzioni uguali); spike con esito scritto |
| **2a** | **Registro e gruppi `SYSTEM`+`PS_FIXED`** (56+9 voci): `IScriptFunctionGroup/Registry/Table`, `TScriptFunctionRegistry` al posto di `TProcedureList`+`units`, `TScriptSystemFunctions` (da `psi_system`, 40 `PS_*`), `TScriptFixedFunctions`; `ps_proclist` diventa facciata e poi sparisce | **M** | 2a-0 | L1 identico (579 dichiarazioni, costanti, tipi, classi); L3 sul registro; L2 sulle 65 voci; `-timedemo` e gli 8 eseguibili partono con uno script `OnTick` |
| **2b** | **Variabili** (`psi_globals`): `TScriptVariables` (`THashTable`, `THashStringList` e le 6 classi) e `IScriptVariables`; `sc_params`/`p_common` la ricevono dal costruttore (`ComposeScanner`); le 16 `PS_*` restano facciata | **S-M** | 2a | byte dei `SaveToBuffer` identici; L2 con `A_*MapVar*` e `MapIntegers[...]`; microbenchmark della ricerca hash (limite +5%) |
| **2c** | **Eventi e serializzatore** (`ps_events`, `ps_serializer`): sono gia classi, si spostano in `DelphiDoom.ScriptHost.*`, si toglie la dipendenza da `TDoomExec` e dal globale `psmanager` | **M** | 2a-0 | L3 (eventi con firme giuste/sbagliate, serializzatore con byte golden e rilettura); L2 con salvataggio e caricamento di Doom/Heretic/Strife; Hexen (`sv_save`) a mano |
| **2d** | **Speciali di settore** (`psi_map`, 77): 7 classi piccole + `IScriptSectorSpecials` (gateway verso `EVH_*`/`PO_*`, in `Base\DelphiDoom.Engine.Script.SectorSpecials`) | **M** | 2a | L3 con gateway finto (`args[0..7]` uguale al vecchio per le 77); L2 con una porta, un soffitto, una luce e un polyobj (Hexen); le 4 build (1 `{$IFDEF HEXEN}`) |
| **2e** | **`ps_dll`** (4) in `TScriptDllLoader` | **S** | 2a | prova con una DLL in un PK3, o "non provato" se non c'e una DLL di prova |
| **2f-1** | **Partita, texture, tastiera** (68 funzioni quasi tutte di sola lettura): `TScriptGameInfo`, `TScriptKeys`, `TScriptTextures`; la tastiera e 59 funzioni uguali che leggono una variabile: **tabella dati** (nome -> variabile) invece di 59 corpi | **M** | 2a | L1 + L2 |
| **2f-2** | **Vertici, lati, linee** (65 + 67 helper): `IScriptWorld` | **L** | 2f-1 | L2 (get/set con indici validi e non validi, flag, tag, trigger script); Hexen senza tag/trasparenza |
| **2f-3** | **Settori** (60 + 61): pendenze (`P_SlopesAlignPlane`), luce, conteggio attori | **L** | 2f-2 | L2 + impronta FNV-1a dei settori dopo ogni passo |
| **2f-4** | **MobjInfo** (72 + 71, sola lettura) e **Giocatore** (29) | **L** | 2f-1 | L2 (tutte le `GetMobj*` per 20 tipi; `GetPlayer*` con 1 giocatore e in rete finta) |
| **2f-5** | **Attori** (115 + 112 + `TActorKeyList`): `TScriptActors`, `ps_currentactor` diventa `IScriptActorContext` | **XL** | 2f-2..4 | L2 con spawn/remove/sposta in una seconda esecuzione; `-timedemo demo1/2/3` di Doom: stesso gametic e stessa posizione finale; salvataggio e caricamento con un attore creato da script |
| **2g** | **Tabelle di registrazione delle classi** (`SIRegister_Game` 406 proprieta, `RIRegister_*`, costanti di `SYSTEM`): un descrittore dati per classe (`AddProperty('X', 'fixed_t', getter, setter)`) che alimenta compilatore e runtime; le costanti in un `IScriptConstantProvider` per gioco (le 37 `{$IFDEF}` diventano strategie) | **L-XL** | 2f | L1 (compile-surface identico per i 4 giochi); L2 che usa **ogni** proprieta |
| **2h** | **`ps_import` e `ps_main`**: `TDoomCompiler`/`TDoomExec` con le dipendenze iniettate (`DllExternalProc`, `FPPNeedFile` -> `IScriptSourceProvider`, `OnUses` -> registro); `TPSExecManager` -> `TScriptManager`; `psmanager` sparisce; `ComposeEngine` crea tutto e lo da con un `PS_Configure...` (i circa 25 file chiamanti restano) | **L-XL** | 2a, 2c, 2e, 2f | L1+L2+L3, i quattro `d_main`, `compile`/`compilescript`/`pscomp`, `ddc` e DD_IDE (le `ddc_*` creano gli stessi gruppi senza motore: `ComposeEngine` nel `begin`) |
| **2i** | **`psi_overlay`** (12 + `TOverlayDrawer` 34 metodi): **per ultima**: per fotogramma (lookup con `MT_memseti`/`MT_memcpy`), `Overlay` dello script e la stessa istanza del motore, salvataggio = memcpy di un record con `string[255]`. `IOverlayCanvas` (v_video/hires) | **L** | 2h | golden dei byte; `-timedemo` +-5%; Doom e GL con un overlay di testo e patch |

### 5.2 Stato (issue #173)

* **2a-0: fatta** (parte 1 della #173, nessuna modifica al codice di produzione; tutto in `Tools\Verifica\scripthost\`, istruzioni in `LEGGIMI.md`):
  * **L1**: golden della registrazione per i 4 giochi, prodotti dal codice di `919a19ef` con un programma console (`Dump-L1.ps1`, non avvia il gioco) in `Tests\Data\ScriptHost\<Gioco>.registration.golden.txt` (Doom 6577 righe, Heretic 3809, Hexen 5694, Strife 4483; Doom rifatto due volte: uguale). Nota: il compilatore di Pascal Script libera le tabelle dopo `Compile`, quindi il dump si fa dentro `OnUses`.
  * **L2**: `HarnessScriptHost.pas` genera da solo la batteria (un script per ogni funzione host, argomenti fissi) leggendo l'elenco dal compilatore, la esegue su un livello e scrive risultato e impronta FNV-1a dello stato; `Compila-ScriptHost.ps1`, `Confronta.ps1`, patch `hook-scripthost.patch`. Gli exe vecchio/nuovo si producono e si confrontano con gli script; **le esecuzioni toccano a chi avvia i giochi**.
  * **Salvataggi**: `-vsh save` carica per le mappe di prova uno script che scrive `mapvars`, `worldvars` e variabili globali; `hook-save-<gioco>.patch`, `Confronta-Salvataggi.ps1` (riusa `harness_sweep`).
  * **Spike `RegisterDelphiMethod`**: **passa**, 5 casi su 5 (risultato `string`, `array of const`, array dinamico `array of LongWord`, `Extended`/`Double`/`Single`, `Self` corretto), a **Win32 e Win64** (`dcc32`/`dcc64`, 16 prove PASS e 0 FAIL, ogni caso anche con la funzione procedurale classica: stesso comportamento), senza toccare il nucleo. Attenzione: il tipo `string` dello script è `UnicodeString`, quindi i metodi host devono usare `string` (come già fanno `ps_import`/`psi_system`), mai `TbtString`. Sorgente: `Tools\Verifica\scripthost\spike\`. **Raccomandazione: la strada B è praticabile** e toglie i thunk; la fetta 2a è stata fatta con la strada A (come chiesto), le fette seguenti possono passare a B senza cambiare le dichiarazioni.

* **2a: fatta** (parte 2 della #173): registro (`IScriptFunctionGroup`, `IScriptFunctionRegistry`, `IScriptFunctionTable`, `TScriptFunctionRegistry`, `TScriptFunctionList`, `TScriptCallbackGroup`, `TScriptHostFactory`), `TScriptSystemFunctions` (56 voci) e `TScriptFixedFunctions` (9), strada A (thunk `PS_*` in `psi_system`), `ps_import` e `dd_compiler` chiedono al registro, `ComposeScriptHost`, `ps_proclist` cancellata. L1 identico ai golden nei 4 giochi; 67 test (`Tests\DelphiDoom.Tests.ScriptHost`, copertura 95%). Dettagli in `Libs\ScriptHost\README.md`. L2 e salvataggi: eseguibili e comandi in `Tools\Verifica\scripthost\LEGGIMI.md`, da eseguire a cura di chi avvia i giochi.

* **2b e 2c: fatte** (issue #174): `TScriptVariables`/`IScriptVariables` (con `TScriptHashTable` e `TScriptHashStringList`) al posto di `TGlobalVariablesList`, `THashTable` e `THashStringList`; `TScriptEvents` (`IScriptEvents`, tabella `SCRIPT_EVENT_SIGNATURES`) e `TScriptSerializer` (`IScriptSerializer`) in `DelphiDoom.ScriptHost.*` con `TPSExec` e `ILog` dal costruttore (`ps_events.pas` e `ps_serializer.pas` cancellate); `psi_globals` resta facciata (`mapvars`/`worldvars`, alias `TGlobalVariablesList`, le sei classi importate da Pascal Script e le 16 `PS_*`). **Scarti dal piano**: le sei classi `TMap/World...` non sono state spostate (sono shim di registrazione di Pascal Script, legati a `ps_runtime`); `sc_params` e `p_common` non ricevono le variabili dal costruttore (leggono `mapvars`/`worldvars` della facciata, come i `p_saveg`): la ricerca hash non cambia e cambiarli tocca circa 40 punti per nessun guadagno ora. L1 identico ai golden nei 4 giochi, 134 test (copertura 95%, unit nuove 91-100%), byte del salvataggio e di `StructureSize` provati a mano. **Da eseguire a cura di chi avvia i giochi**: L2 (con `A_*MapVar*` e `MapIntegers[...]`) e il caricamento di un salvataggio con variabili degli script (`LEGGIMI.md`).
* **2d e 2e: fatte** (issue #172): speciali di settore (`psi_map`: 7 classi + gateway `IScriptSectorSpecials`, `Base\DelphiDoom.Engine.Script.SectorSpecials`) e `ps_dll` (`TScriptDllLoader`), strada A (thunk). L1 identico, L2 UGUALE in Doom, Heretic, Hexen e Strife, 161 test, copertura 96%; dettagli, difetti conservati e non provato in `Libs\ScriptHost\CLAUDE.md`.

* **2f-1: fatta** (issue #172): `TScriptGameInfo` (6 funzioni), `TScriptTextures` (3) e `TScriptKeys` (3 con parametro + 56 da tabella dati) in `DelphiDoom.ScriptHost.*`, con `IScriptFunctionSection` e `IScriptFunctionTable.AddMethod`: **strada B** (`RegisterDelphiMethod`, la spike della 2a-0), quindi i 68 `PS_*` di `psi_game` sono stati cancellati senza thunk; la tastiera e' una tabella + un oggetto per riga (stesso metodo, `Self` diverso). Nel motore `Base\DelphiDoom.Engine.Script.GameInfo/Textures/Keyboard`; `ps_import` le riceve da `PS_ConfigureGameFunctions`. Dettagli e verifica in `Libs\ScriptHost\CLAUDE.md`.

* **2f-2: fatta** (issue #172): `TScriptVertices` (5 funzioni), `TScriptSides` (26) e `TScriptLines` (34, 29 in Hexen) in `DelphiDoom.ScriptHost.World.*` su un solo gateway `IScriptWorld` (nel motore `TEngineScriptWorld`), strada B con `AddMethod` e il nuovo `AddMethodWithCustomResult` per `TVertex/TSide/TLine`; i 65 `PS_*` cancellati, i 67 helper delle classi di script restano in `psi_game` e chiamano le interfacce. Difetto conservato: `Get/SetSideMidRowOffset` usano `bottomrowoffset`. L1 uguale, L2 vecchio contro nuovo uguale in 5 eseguibili, 222 test. Dettagli in `Libs\ScriptHost\CLAUDE.md`.
Totale: circa 8-12 giorni, consegnabile a fette indipendenti dopo 2a; ci si puo fermare in qualsiasi fetta perche ogni facciata `PS_*` resta quella di prima.

### 5.1 Perche questo ordine

1. La rete di sicurezza (2a-0) e l'unica cosa che manca: costo alto, rischio zero.
2. **2a** e la fetta piu piccola che cambia l'architettura: introduce il registro (che tutti i gruppi useranno) e muove i due gruppi **senza record del motore** (`SYSTEM`, `PS_FIXED`), la cui iniezione (`IEngineConsole`, `IEngineDefaults`) esiste gia. Se la spike su `RegisterDelphiMethod` passa, i gruppi seguenti non avranno thunk.
3. Variabili, eventi e speciali di settore (2b-2d) non leggono i record del livello: si provano in DUnitX con un finto.
4. `psi_game` (2f, 14.064 righe) per blocchi: prima sola lettura, poi settori e mobjinfo, poi attori (scrittura, spawn, contesto).
5. `ps_import`/`ps_main` (2h) dopo: toccano il ciclo di vita dell'interprete, i quattro `d_main` e circa 25 chiamanti.
6. Overlay per ultimo: e il solo gruppo con costo per fotogramma.

---

## 6. Fetta 2a: dettaglio (da eseguire per prima, dopo 2a-0)

1. **Nuovo** in `Libs\ScriptHost`: `DelphiDoom.ScriptHost.Intf.pas`, `...Types.pas` (`EScriptHostException`), `...Registry.pas` (`TScriptFunctionRegistry`: `AddGroup`, `RegisterCompiler`, `RegisterExecutor`, `Declarations`, `UnitNames`; ordine alfabetico e regola `ALL` come oggi), `...Factory.pas`, `...System.Functions.pas` (`TScriptSystemFunctions`), `...Fixed.Functions.pas` (`TScriptFixedFunctions`).
2. **Modifica minima**: `ps_import.pas` non crea piu le `TProcedureList` di `SYSTEM` e `PS_FIXED` ma le chiede al registro; `PS_ScriptOnUses` e `TDoomExec.LoadData` chiamano `Registry.RegisterCompiler/RegisterExecutor(unit)` al posto di `(units.Objects[i] as TProcedureList)`; `PS_ImportUnits` (usata da `dd_compiler`) ritorna la stessa forma. Un `ComposeScriptHost` accanto a `ComposeScanner` in `ComposeEngine` crea il registro e lo da con `PS_ConfigureRegistry` (senza di esso `I_Error`, come le altre facciate).
3. **Cancellato** a fine fetta, dopo la verifica: le 65 `baseproclist.Add` dei due gruppi in `ps_import` e i corpi delle 40 `PS_*` di `psi_system` (restano i thunk, vedi 3.1).
4. **Test**: `Tests\DelphiDoom.Tests.ScriptHost` (nuovo progetto, una fixture per unit, nomi in italiano): registro con gruppi finti (ordine, `ALL`, `SYSTEM` implicita, nome sconosciuto, doppio nome), gruppo vero `SYSTEM` con compilatore PS vero che compila `uses all; begin Writeln('x'); end.` con console finta, golden delle 65 dichiarazioni.
5. **Verifica**: L1 identico per i 4 giochi; L2 sulle 65 funzioni; gli 8 eseguibili partono 25 s senza `crash.txt`; `ddc` produce lo stesso `.ddout` (byte) su uno script d'esempio; stesso esito di `compile` da console.
6. **Rischio basso**: nessuna `PS_*` cambia semantica e nessun record del motore entra in gioco. Il solo pericolo e l'ordine di registrazione (`units.Sorted`, doppioni) e `TProcedureList.Reset` (`PS_ResetProcLists`: ricostruire lo stesso effetto).

---

## 7. Rischi e cose da non fare

### 7.1 Rischi

* **Unicode**: le dichiarazioni usano `string` nelle firme e le funzioni Delphi sono `string` (UTF-16), mentre il nucleo PS usa `TbtString = AnsiString` e `PS_NOWIDESTRING` e definito solo per Delphi 2 (`btUnicodeString` esiste): **verificare nella spike** che `Writeln`, `Format`, `ConsoleCommand`, `GetMapString` con caratteri non ASCII diano lo stesso risultato prima e dopo, prima di toccare firme. `PS_AddCompiledScript` costruisce il bytecode concatenando `Chr(b[i])` in una `string` e lo passa come `TbtString` (avvisi W1057/W1058 gia noti): non cambiare senza un test. I salvataggi scrivono i caratteri con `SizeOf(Char)` (2): il formato e UTF-16 e non va "corretto".
* **64 bit**: le chiamate native a `cdRegister` usano `x86.inc`/`x64.inc` (assembler del nucleo); il ramo `x64.inc` oggi lo usa solo `mdl_script_proclist`. I thunk non cambiano nulla; `RegisterDelphiMethod` a 64 bit va provato a parte. Nelle classi nuove: `LongWord(Self)` -> `LongWord(NativeUInt(Self))`; `Extended` (16 occorrenze in `psi_system`, 10 in `ps_import`: a 64 bit sono 8 byte, tipo di script `extended` ma parametro Delphi `Double`: da provare); il formato `btExtended` del serializzatore; gli `array[0..$FFF]` con `realloc` manuale (`TActorKeyList`, `TProcedureList`, `psscriptitem_tArray`) -> `TArray<>`/`TList<>`.
* **Classi di runtime non coerenti**: `RIRegister_Game` fa `rsector := CLI.Add2(TRTLLine, '!TSECTOR')` e `rsectors := CLI.Add2(TRTLLines, '!TSECTORS')` mentre i metodi sono di `TRTLSector` (`RegisterMethod(@TRTLSector.PlaySound)`). Funziona perche lo script manda sempre la chiave nel `Self`: **va conservato** finche non c'e un test su `Sector`/`Sectors`.
* **Un solo compilatore** (`dccnt`): nei test usare il compilatore del nucleo (non `TDoomCompiler`) o un finto.
* **Contesto implicito**: `ps_currentactor` e impostata da `PS_Event*` e letta da `PS_Actor` e da `mobj_from_key(0)`; `A_RunScript` passa l'attore a `RunScript` per un'altra strada: due percorsi da lasciare cosi fino a 2f-5 e da testare entrambi.
* **Prestazioni**: `psi_overlay` per fotogramma e `psi_globals` per parametro valutato; limite +5% con `-timedemo` e microbenchmark (come #148/#150). Non aggiungere allocazioni per chiamata (le `Actors.All*` allocano gia: non peggiorarle).
* **Errori di dichiarazione invisibili**: un refuso in una delle 579 stringhe si vede solo quando uno script usa la funzione. Per questo L1 e L2 sono parte di ogni fetta.
* **DD_IDE e le DLL `ddc_*`**: usano `PS_InitProcLists`/`PS_ImportUnits`/`GetDeclarations` (suggerimenti di `Libs\Ide`); la nuova API deve restare usabile senza partita (`ComposeEngine` nel `begin` del `.dpr`) e dare le stesse stringhe.
* Le copie sotto `Reference\Mars3D` sono un'altra linea: non toccarle.

### 7.2 Cosa NON conviene fare

1. **Non fare il ponte verso `DDScript`/`IScriptEngine`**: resta valida la decisione #10 (`Libs\Script\README.md`): `Actors`, `Lines`, `MapStrings` sono registrati con puntatori a metodi Delphi e non attraversano il confine di una DLL.
2. **Non cambiare nomi, firme, ordine o unit di una funzione di script**: sono l'API di tutti gli script ACTORDEF/DECORATE esistenti, anche i nomi "brutti" (`_GAME`, `TActor` come procedura, `IsSingleInRange` che punta a `IsFloatInRange`, i `Polyobj_OR_*` doppi).
3. **Non fare una classe per funzione** (557) ne una interfaccia unica con 557 metodi: gruppi coesi (una sezione di `psi_game`, una famiglia di `psi_map`), interfacce strette.
4. **Non portare in `Libs\` codice che usa `mobj_t`, `sector_t`...**: va in `Base\DelphiDoom.Engine.Script.*`.
5. **Non toccare `Libs\PascalScript`** (codice di terzi): niente modifiche al nucleo se non per un bisogno dimostrato dalla spike.
6. **Non convertire i thinker** che le funzioni di `psi_map` creano: restano record nella zone memory con il puntatore a funzione salvato grezzo (decisione di `FACCIATE.md`).
7. **Non cambiare il formato dei salvataggi** (UTF-8, `Double` fisso a 64 bit): e un cambio di formato, da decidere nella #43 con un convertitore.
8. **Non togliere una delle due API della stessa proprieta** (`GetActorX(key)` e `Actor.X`): gli script usano entrambe; si fanno **convergere i corpi** in una classe, non le registrazioni.
9. **Non partire dagli attori** (la parte piu grossa e con scrittura sul mondo): senza la rete L1/L2 e senza i gruppi di sola lettura che alimentano `IScriptWorld` si perde tempo.
10. **Non dichiarare "fatto" senza i golden prima/dopo, una build verde e l'esito reale dei test**; cio che non e provato (OpenGL, Win64, DLL in PK3, `sv_save` di Hexen con uno script sospeso) va scritto come "non provato".

---

## 8. Appendice: dati di base

* Registrazioni in `PS_InitProcLists`: `SYSTEM` 56, `PS_GAME` 504, `PS_FIXED` 9, `PS_OVERLAY` 10 (= 579, di cui 5 `AddWithCustomResult`); 572 simboli `@...` distinti.
* `PS_*` definite: `psi_game` 412, `psi_map` 77, `psi_system` 40, `ps_main` 25, `psi_globals` 16, `psi_overlay` 12, `ps_import` 5, `ps_dll` 4 = 591. Registrate come funzioni di script: `psi_game` 408, `psi_map` 77, `psi_system` 36, `psi_globals` 12, `psi_overlay` 10 (le altre sono interne: `PS_Init*`, `PS_Configure*`, `PS_ShutDown*`). Altre registrazioni puntano a routine di altre unit (`FixedMulEx`, `P_Random`, `G_ExitLevel`, `P_AproxDistance`, `R_PointToAngle`, `IsIntegerInRange`...).
* Helper `TRTL*_R/_W` in `psi_game`: 289 distinti (`TRTLActor` 98, `TRTLMobj*` 71, `TRTLSector` 55, `TRTLLine` 31, `TRTLSide` 24, vertici, collezioni).
* `RegisterDelphiMethod` nel repository fuori dal nucleo: 0 usi. `RegisterDelphiFunction`: solo `ps_proclist` e `Libs\OpenGl\Legacy\mdl_script_proclist`.
* Chiamanti esterni: `d_main` x4, `g_game` x4, `p_saveg` x3 + `sv_save`, `p_inter` x4, `p_map` x4, `p_enemy` x4, `Strife\p_mobj`, `Base\p_tick`, `p_common`, `sc_params`, `v_video`, `v_displaymode`, `gl_main`, `ActorDef.Hooks`, `TLevelLoader`, `Composition`, `Scanner.ActorFunctions`, `dd_compiler`, `deh_main` x4, `mdl_script_proclist`, `mdl_dllmodel`.

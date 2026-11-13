# Libs\Gui

Lettura e modello dei menu di Team Arena (`.menu`) e dei font di Quake III (`.dat`), a classi (issue #125, parte della #115). Port di `ui_shared.c` (parser e script degli eventi), delle funzioni di caricamento di `ui_main.c` (`Asset_Parse`, `UI_ParseMenu`, `Load_Menu`, `UI_LoadMenus`) e del formato di `tr_font.c` (`RE_RegisterFont`, ramo `.dat`). Quake III Arena: id Software, GPL v2 o successiva, "Based on the Quake III Arena GPL Source Code (id Software)" in ogni unit.

**Percorso freddo, nessun chiamante nel motore.** Le classi leggono e modellano: non disegnano e non gestiscono l'input. Il disegno e' `IGuiDeviceContext` (solo dichiarata), il gioco dietro gli script e' `IGuiScriptHost` e `IGuiMediaHost`, i handle di shader, modelli e suoni li da' `IGuiAssetRegistry`.

## Cosa e' portato

| C (Quake III) | Pascal |
|---|---|
| `String_Alloc`, il pool di stringhe (384 KB) | `TGuiStringPool` |
| `trap_PC_LoadSource` / `ReadToken` / `SourceFileAndLine` | `IGuiSourceLoader`, `IGuiTokenSource`; `TGuiPrecompilerLoader`, `TGuiPrecompilerSource` sopra `TIdParser` |
| `PC_Float_Parse`, `PC_Int_Parse`, `PC_Color_Parse`, `PC_Rect_Parse`, `PC_String_Parse`, `PC_Script_Parse`, `PC_SourceError` | `TGuiValueReader` |
| `windowDef_t`, `Window_Init` | `TGuiWindowDef` (`DelphiDoom.Gui.Types`) |
| `itemDef_t`, `Item_Init`, `Item_ValidateTypeData`, `Item_SetScreenCoords`, `Item_UpdatePosition`, `listBoxDef_t`, `editFieldDef_t`, `multiDef_t`, `modelDef_t` | `TGuiItem` e i record di `DelphiDoom.Gui.Types` |
| `menuDef_t`, `Menu_Init`, `Menu_UpdatePosition`, `Menu_PostParse`, `Menu_FindItemByName`, `Menu_ItemsMatchingGroup`, `Menu_GetMatchingItemByNumber` | `TGuiMenu` |
| `Item_Parse`, `itemParseKeywords`, `ItemParse_*` (62 parole chiave) | `TGuiItemParser` |
| `Menu_Parse`, `menuParseKeywords`, `MenuParse_*` (28 parole chiave) | `TGuiMenuParser` |
| `Menus[]`, `menuCount`, `Menu_New`, `Menu_Count`, `Menu_Reset`, `Menus_FindByName` | `TGuiMenuSet` (con pool e asset) |
| `cachedAssets_t` (la parte che si legge o si imposta) | `TGuiAssets` |
| `Asset_Parse` | `TGuiAssetParser` |
| `UI_ParseMenu`, `Load_Menu`, `UI_LoadMenus` | `TGuiMenuFileReader` |
| `COM_ParseExt`, `Float_Parse`, `Int_Parse`, `Color_Parse`, `Rect_Parse`, `String_Parse` (su `char **`) | `TGuiScriptCursor` |
| `Item_RunScript`, `commandList`, i `Script_*`, `Menu_ShowItemByName`, `Menu_FadeItemByName`, `Menu_TransitionItemByName`, `Menu_OrbitItemByName`, `Menu_ClearFocus` | `TGuiScriptRunner` |
| `glyphInfo_t`, `fontInfo_t` | `TGuiGlyph` (`packed`, 80 byte), `TGuiFont` |
| `readInt`, `readFloat`, ramo `.dat` di `RE_RegisterFont` | `TGuiFontReader`, `TGuiFontRegistry` |

Una `TGuiFactory` assembla le classi; nessuna variabile globale (gli array statici di `ui_shared.c` sono campi di `TGuiMenuSet`).

## Cosa non e' portato

Il disegno (`Item_Paint`, `Menu_Paint`, `Window_Paint`, `Fade`, bordi, gradienti), l'input (`Menu_HandleKey`, `Item_*_HandleKey`, mouse, cattura), i feeder e gli owner draw (`feederCount`, `ownerDrawItem`...: sono del chiamante), la pila dei menu aperti (`Menus_Activate`, `Menus_ActivateByName`, `Menus_CloseByName`, `menuStack`: `open`, `close` e `conditionalopen` vanno a `IGuiScriptHost`), `Item_EnableShowViaCvar`, i comandi di scorciatoia (`Controls_*`), `Display_*`, il pool di memoria da 1 MB (`UI_Alloc`), la generazione dei font con FreeType (`BUILD_FREETYPE`, spento nel gioco distribuito), `q3_ui\*` (menu di Quake III base: sono codice C, non dati). La GUI di Doom 3 (`.gui`, #111) non e' fatta: la libreria e' pensata per ospitarla (`IGuiDeviceContext` e' l'interfaccia di disegno comune, le sue classi andranno in `DelphiDoom.Gui.Window.*` accanto a `DelphiDoom.Gui.Menu`).

## Lexer

I `.menu` si leggono con `TIdParser` (`Libs\Scanner`, sopra `TIdLexer` di `Libs\IdLib`) con `LEXFL_NOFATALERRORS or LEXFL_NODOLLARPRECOMPILE`, **non** con un secondo port del precompilatore di botlib (`l_script.c`, `l_precomp.c`, che il modulo ui raggiunge con `trap_PC_*`): idLexer e idParser discendono da quel codice. Le differenze trovate col vero botlib sono sotto.

## Differenze dal C e difetti

Difetti del C **conservati** (provati dal golden):

- `PC_Float_Parse` e `PC_Int_Parse` guardano il primo carattere del token: `--` e `-=` sono segni meno.
- Un blocco `{ ... }` di script e' tagliato a 1023 caratteri; un blocco `{ }` vuoto da una stringa vuota.
- Le stringhe adiacenti si uniscono (`"a" "b"` e' `ab`): vale anche per `loadmenu { "a.menu" "b.menu" }`, che apre un file di nome `a.menub.menu`.
- Dopo 96 item il C da' successo **senza leggere il blocco** dell'item: `{` e le sue parole sono lette come parole del menu (un `name` lo rinomina, un `}` lo chiude).
- Un menu che fallisce non e' tenuto, e il file finisce al primo `}` che resta (`UI_ParseMenu`).
- Una parola chiave di un item che chiede dati di un altro tipo (`elementwidth` su un item di testo) scrive sui campi dell'altro tipo; qui gli argomenti si leggono e il successo e' lo stesso, senza scrivere (e' cosi' che OpenArena legge `score.menu` e `videomodes.menu`).
- `Menu_TransitionItemByName` usa `abs()` di C, che prende un `int`: `0.9` diventa `0` prima del valore assoluto; la divisione per `amt` zero da infinito o NaN senza eccezioni.
- `COM_ParseExt`: i byte da 128 in su sono caratteri negativi (spazi all'inizio di una parola, fine di una parola); una parola di 1024 caratteri e' scartata (vuota).
- `ItemParse_asset_model` usa `rand() % 360` per l'angolo: qui un `IGuiRandom` (0 senza).

Differenze **volute** (tutte con un test):

- `elementwidth`, `elementheight`, `elementtype`, `columns`, `doubleclick`, le parole del modello, `maxChars`, `maxPaintChars`, `cvarFloat`, `cvarStrList` e `cvarFloatList` su un item **senza** dati di tipo (un bottone): il C dereferenzia un puntatore nullo (crash) o lo controlla e da falso; qui sempre falso, senza consumare gli argomenti dove il C li controlla prima.
- `setitemcolor`, `transition`, `orbit`, `setfocus` e i comandi che cercano nel menu padre su un item senza padre: il C dereferenzia un puntatore nullo; qui non fanno niente (gli argomenti sono letti lo stesso).
- Il pool di stringhe pieno da' la stringa vuota (il C da' `NULL` con successo); una stringa `NULL` e una vuota non si distinguono.
- `UI_LoadMenus`: se manca la lista chiesta e anche `ui/menus.txt`, `EGuiFileNotFoundException` (il C chiama `trap_Error`, che ferma il gioco); se manca solo la prima si legge quella di default, come dice il messaggio. Non si misura il tempo.
- Un comando che `Item_RunScript` non conosce passa al gioco con gli argomenti **fino al prossimo `;`**; nel C li legge `DC->runScript` da solo.
- Le righe di errore dicono file e riga come il C ma il numero di riga dell'idLexer puo' differire di uno (vedi sotto). Gli errori sono avvisi a `IGuiLog`, non eccezioni: il C continua e il menu che fallisce non e' tenuto.

Differenze del **lexer** (idLexer rispetto a botlib), non riprodotte:

- `1e2`: botlib legge il numero `1` e il nome `e2`; idLexer legge `100`.
- `12.` (punto finale): `NumberValue` di botlib legge il terminatore come una cifra e da `7.2` (e poi legge il buffer oltre il token); qui `12`.
- Il numero di riga di un errore puo' differire di una unita' dopo le direttive `#` e a fine file.
- Nessun limite di 1024 caratteri per un token (botlib: errore).
- `long double`: i valori numerici di botlib sono `long double`; MSVC lo ha a 64 bit come il `Double` qui, e il golden e' fatto con `-mlong-double-64`.

## Verifica

`Tools\Verifica\125` compila con il gcc di w64devkit il **vero** `ui_shared.c`, il precompilatore di botlib e `q_shared.c`, piu' due ritagli per intervalli di righe di `ui_main.c` e `tr_font.c`; il pilota esegue scenari (`Tests\Data\Gui\scenarios`) su menu **scritti per i test** (mai file di Team Arena) e scrive il dump del modello (float come bit): i golden stanno in `Tests\Data\Gui\golden`, i test Delphi rifanno gli scenari con le classi e confrontano riga per riga (unica tolleranza: la riga di un errore, +-1). Test: `Tests\DelphiDoom.Tests.Gui` (171 test, copertura 97%, Win32 e Win64); in piu' i 26 `.menu` e i 3 `.dat` di OpenArena (`Reference\openarena`, o `DELPHIDOOM_OPENARENA`) si leggono senza errori, e il test e' saltato se mancano.


# La GUI di Doom 3 (`.gui`, issue #111)

Prima fetta della GUI di id Tech 4 a classi, **accanto** ai menu di Quake III (che non sono toccati): lettura dei `.gui` in un albero di finestre con variabili, registri e script, e il passo del tempo (valutazione delle espressioni, transizioni, eventi del tempo e con nome) **senza disegno e senza input**. Port di `neo\ui` di Doom 3 (id Software, **GPL v3 con i termini aggiuntivi di Doom 3**, "Based on the Doom 3 GPL Source Code (id Software)" nell'intestazione di ogni unit; il repository e' GPL v2 o successiva, come in `Libs\IdLib`). **Percorso freddo, nessun chiamante nel motore.**

## Cosa e' portato

| C++ (Doom 3) | Pascal |
|---|---|
| `idUserInterfaceLocal`: `InitFromFile`, `HandleNamedEvent`, `StateChanged`, `Activate`, `Trigger`, lo stato (`SetStateString`...) | `TGuiUserInterface` (`DelphiDoom.Gui.UserInterface`); lo stato condiviso dalle finestre e' `TGuiContext` |
| `idWindow`: `Parse`, `ParseInternalVar`, `ParseRegEntry`, `GetWinVarByName`, `FixupParms`, `CalcClientRect`, `CalcRects`, `RunTimeEvents`, `Time`, `Transition`, `EvalRegs`, `ResetTime`, `Activate`, `Trigger`, `RunNamedEvent`, `IsSimple` | `TGuiWindow` (`DelphiDoom.Gui.Window`) |
| `idSimpleWindow` (una finestra senza script, figli ne operazioni) | la stessa finestra, in `DrawWindows` con `IsSimple`; non e' un figlio (come l'originale) e il padre aggiorna le sue variabili legate allo stato |
| `idChoiceWindow`, `idEditWindow`, `idListWindow`, `idSliderWindow`, `idBindWindow`, `idRenderWindow`, `idMarkerWindow`, `idFieldWindow` (parse, chiavi, variabili, `PostParse`) | `TGuiChoiceWindow` ... `TGuiFieldWindow` (`DelphiDoom.Gui.Window.*`), fabbrica `TGuiWindowFactory` |
| `idWinVar`, `idWinBool`, `idWinInt`, `idWinFloat`, `idWinStr`, `idWinBackground`, `idWinVec2`, `idWinVec3`, `idWinVec4`, `idWinRectangle` | `TGuiWinVar` e le sottoclassi (`DelphiDoom.Gui.WinVar.*`) |
| `idRegister`, `idRegisterList` | `TGuiRegister`, `TGuiRegisterList` (`DelphiDoom.Gui.Regs.*`) |
| `ExpressionConstant`, `ExpressionTemporary`, `EmitOp`, `ParseExpression`, `ParseTerm`, `EvaluateRegisters`, `wexpOp_t` | `TGuiExpressionStore`, `TGuiExpressionParser`, `TGuiExpressionEvaluator`, `TGuiOp` |
| `idGuiScript`, `idGuiScriptList`, `Script_*` (`set`, `setFocus`, `endGame`, `resetTime`, `showCursor`, `resetCinematics`, `transition`, `localSound`, `runScript`, `evalRegs`), `ParseScript` | `TGuiScript`, `TGuiScriptList`, `TGuiScriptParser` |
| `idTimeLineEvent`, `rvNamedEvent`, `idTransitionData` | `TGuiTimeLineEvent`, `TGuiNamedEvent`, `TGuiTransition` |
| `idInterpolateAccelDecelLinear<idVec4>`, `idExtrapolate<idVec4>` (modi none, linear, accel, decel) | `TGuiInterpolator` |
| `idRectangle` | `TGuiRectangle` (record) |

Il gioco passa da interfacce piccole e opzionali: `IGuiGameHost` (`localSound`, `endGame`, `resetCinematics`), `IGuiLanguage` (le stringhe `#str_`), `IGuiTables` (le tabelle `idDeclTable` che un'espressione indicizza), `IGuiFontLookup` (`font`). Una finestra si vede dagli script e dalle altre finestre come `IGuiWindowNode` (non conta i riferimenti: la possiede il padre). Nessuna variabile globale: gli statici di `idWindow::EvalRegs` (array dei registri e ultima finestra valutata) sono in `TGuiContext`. Errori: avvisi a `IIdLibLog` come `idParser` (`file, line n: testo`); `EGuiWindowException` per i `FatalError`, `EGuiWindowParseException` (file e riga) in modalita' severa (`StrictParsing`).

## Cosa non e' portato

Disegno (`Redraw`, `Draw`, `DrawBackground`, `DeviceContext`), input (`HandleEvent`, mouse, tastiera, cattura e routing del focus), file di salvataggio e di demo, l'editor delle GUI (`rvGEWindowWrapper`), i materiali (lo sfondo e' il nome), le cinematiche, i cvar (`cvar` e `InitCvar` di choice, edit e slider; resta l'avviso dello slider senza `cvar`), le barre di scorrimento, il file `source` di `editDef`, l'elenco delle liste (arriva dal gioco), i giochi (`gameSSDDef`, `gameBearShootDef`, `gameBustOutDef`: non sono parole chiave, il parse li tratta come chiavi sconosciute), il gestore delle GUI (`idUserInterfaceManagerLocal`: elenco, ricarica, unicita'), `FixupTransitions` (serve solo al caricamento di un salvataggio).

## Difetti del C++ conservati (provati dal golden o da un test)

- `idWinVar::Init` con un nome che non comincia per `gui:` **assegna il nome come valore** (`Set(name)`): citare una variabile non legata in un'espressione (`float f 3` e poi `f * 2`) la azzera.
- Una variabile `gui::nome` si lega con `Right(len - 5)` dopo aver confrontato solo `gui:` (quattro caratteri); un nome di cinque caratteri o meno non lega.
- `EvaluateRegisters` azzera i **temporanei** a ogni valutazione e la `COND` (`a ? b : c`) sta **prima** delle operazioni del ramo `c`: un ramo `c` che non e' una costante o una variabile vale 0.
- Le espressioni additive e moltiplicative sono associative **a destra** (`10 - 4 - 3` fa 9).
- La prima costante lascia un segnaposto (-9999999) nel registro 0 (il tempo); un temporaneo creato per primo prende il registro 0 e il tempo non e' piu' leggibile.
- `animationDef` nasconde e svuota la finestra che lo **contiene**, non la nuova.
- Un `windowDef` col nome di un figlio esistente rilegge quel figlio (e il nome del padre rilegge il padre).
- `transition` accetta solo `rect`, vec4 e float; `$nome` come inizio o fine copia il testo della variabile (a due decimali, senza zeri finali) e solo per `rect` aggiusta le coordinate tra gli spazi dei padri.
- `ClientToScreen` e `ScreenToClient` sommano i rettangoli in **interi**.
- `idRectangle::operator==` confronta `a.h` come booleano (qui `IsEqual` confronta i quattro campi).
- `Script_SetFocus`, `showCursor` e `resetTime` senza parametri leggono `(*src)[0]` fuori dalla lista (con `assert` attivo il motore si ferma); qui non fanno niente.
- Lettura di una componente di un vec4 in un'espressione (`op->b >= 0 && registers[op->b] < 4`): l'originale legge `((idVec4&)var)[n]` che reinterpreta la **variabile puntatore** e non il vettore (memoria dello stack); qui si legge la componente voluta. Con `b = 0` (nessun indice) il registro 0 e' il tempo, e nei primi 3 ms la componente e' il tempo.
- Il puntatore `oop` di `ParseExpressionPriority` (il ramo `else` di `?:`) punta in una lista di operazioni che puo' riallocarsi: qui l'operazione si indica per indice.
- `idEditWindow` costruisce un `idSliderWindow` e `idChoiceWindow::UpdateChoice` valida la scelta solo se c'e' una variabile `gui` o un cvar.

## Verifica

`Tools\Verifica\111` (`LEGGIMI.md`, `Build-Harness.ps1`): compila con `bcc32c` (clang 32 bit di Delphi 11) il **vero** `ui\Window.cpp`, `Winvar.h`, `RegExp.cpp`, `GuiScript.cpp`, `SimpleWindow.cpp`, `ChoiceWindow.cpp`, `SliderWindow.cpp`, `BindWindow.cpp`, `FieldWindow.cpp`, `idlib` e le funzioni di `idUserInterfaceLocal` ritagliate da `UserInterface.cpp`, con stub scritti per il test (contesto del dispositivo, materiali, gestore delle dichiarazioni). Scenari **scritti per il test** (`Tests\Data\Gui\window\window.input.txt`, 13 casi, nessun `.gui` di Doom 3) e risposta del C++ (`window.golden.txt`: alberi di finestre, flag, rettangoli e colori come bit, variabili, comandi, avvisi). `TTestGuiWindowParity` rifa gli scenari con le classi e confronta riga per riga, **senza tolleranza**, a 32 e a 64 bit. Non compresi dal C++ (la finestra non regge senza il motore): `editDef` (si ferma nel costruttore dello scroller), `listDef`, `markerDef`, `renderDef`, i giochi; hanno test Delphi. Le tabelle (`FindType` degli stub e' sempre vuoto) hanno test Delphi con una tabella finta.

Test: `Tests\DelphiDoom.Tests.Gui` (316 test in tutto, 145 nuovi, Win32 e Win64), copertura delle unit nuove: tutte sopra il 90% (`Tools\Copertura.ps1 -Test Gui -Cartella Libs\Gui`: 96% su tutta la cartella).

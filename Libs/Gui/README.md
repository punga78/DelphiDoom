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

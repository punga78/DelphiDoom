# Verifica #125: menu di Team Arena (`.menu`) e font `.dat`

Produce i golden di `Tests\Data\Gui\golden` con il codice **vero** di Quake III, non riscritto. `build.sh` compila con il gcc di `Reference\_dati\_strumenti\w64devkit`:

- `code\ui\ui_shared.c` intero (`Menu_New`, `Menu_Parse`, `Item_Parse`, `MenuParse_*`, `ItemParse_*`, `PC_*_Parse`, `String_Alloc`, `Item_RunScript` e i `Script_*`), senza modifiche;
- il precompilatore di botlib `code\botlib\l_script.c`, `l_precomp.c`, `l_memory.c` (e' quello che le chiamate `trap_PC_*` del modulo ui raggiungono nel gioco), senza modifiche;
- `code\game\q_shared.c` (`Q_stricmp`, `COM_ParseExt`, `va`, `Q_strcat`...). `q_math.c` non si compila (assembler di MSVC); `AxisClear` e `AnglesToAxis` sono stub vuoti in `stubs.c`;
- due ritagli per intervalli di righe, fatti da `build.sh` in `ui_main_original.inc` (`Asset_Parse`, `UI_ParseMenu`, `Load_Menu`, `UI_LoadMenus` di `code\ui\ui_main.c`) e `tr_font_original.inc` (`readInt`, `readFloat`, `RE_RegisterFont` di `code\renderer\tr_font.c`, ramo `.dat`: `BUILD_FREETYPE` e' spento come nel gioco distribuito).

`stubs.c` sostituisce i servizi del motore (file da una cartella, memoria da `malloc`, log come righe) e `uiparse.c` e' il pilota: un display context finto che registra cio' che il motore avrebbe ricevuto (`reg shader|model|sound`, `host ...`), le funzioni di dump e il lettore degli scenari. Opzioni: `-mlong-double-64` (i valori dei token di `l_script.c` sono `long double`; MSVC, che compilava l'originale, ha il `long double` a 64 bit), `-ffp-contract=off`, `-DBOTLIB -DMISSIONPACK`.

```
sh Tools/Verifica/125/golden.sh <cartella di lavoro>
```

- I menu sono **scritti per i test** (`Tests\Data\Gui\files\ui`), mai file di Team Arena o di OpenArena. `Make-Fonts.ps1` fa i `.dat` (due validi da 20548 byte con valori da un generatore lineare con seme fisso, uno da 100 byte).
- Gli scenari (`Tests\Data\Gui\scenarios\*.txt`) sono le righe `menu`, `menus`, `font`, `run`, `dump`, `state`, `reset` descritte in `uiparse.c`; i test Delphi riesegono gli stessi scenari con le classi di `Libs\Gui` e confrontano riga per riga col golden.
- Formato del dump: ogni `float` come bit esadecimali, le stringhe tra virgolette con escape; una stringa `NULL` e una vuota si scrivono uguali; l'angolo di un `asset_model` (`rand() % 360`) non si scrive.
- Il programma non si deve chiamare `patch*.exe`/`setup*.exe`: Windows lo prende per un installatore.
- `open`, `conditionalopen` e `close` di `Item_RunScript` (pila dei menu aperti) **non** sono negli scenari: in `Libs\Gui` sono del chiamante (`IGuiScriptHost`).

## Scenari di input (seconda fetta, issue #125)

`uiparse.c` ha anche i comandi dell'input (`cursor`, `time`, `feeder`, `cvar`, `textrect`, `cinematic`, `open`, `activate`, `key`, `menukey`, `move`, `drag`, `capture`, `focus`, `next`, `prev`, `feedersel`, `scrollfeeder`, `mouseenter`, `istate`, ...: l'elenco e' in `InputCommand`). `build.sh` compila `ui_shared.c` in un oggetto a parte e con `objcopy` rende globali le sue variabili `static` di stato (`itemCapture`, `captureFunc`, `captureData`, `g_editingField`, `g_editItem`, `debugMode`): il sorgente non cambia. Il display context finto ha una tabella di cvar (un nome che non c'e' risponde come prima: `zero` = 0, il resto 1), feeder con conteggio, overstrike, `ownerDrawHandleKey` che accetta solo `K_ENTER`, e scrive una riga `host ...` per ogni chiamata. Scenari `input.txt` e `input2.txt` sui menu `Tests\Data\Gui\files\ui\input.menu`; `golden.sh` scrive anche `input.golden.txt` e `input2.golden.txt`. Le funzioni di `ui_shared.c` che `ui_shared.h` non dichiara hanno il prototipo in `uiparse.c`: senza, i `float` passano come `double`.

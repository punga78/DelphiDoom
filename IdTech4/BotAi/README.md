# IdTech4\BotAi

Port a classi dell'IA dei bot di **Quake III Arena** (`code\botlib`, GPL v2 o successiva, id Software). Prima fetta (issue #124): la **chat dei bot** (`be_ai_chat.c`). Seconda fetta (issue #123, vedi "Caratteri, pesi fuzzy, armi e strutture" piu' sotto): **caratteri** (`be_ai_char.c`), **pesi fuzzy** (`be_ai_weight.c`), **armi** (`be_ai_weap.c`), la lettura di strutture dei file di configurazione (`l_struct.c`) e le variabili della libreria complete (`l_libvar.c`). La libreria non ha chiamanti nel motore (percorso freddo). Terza fetta (#123, vedi "Obiettivi, movimento, azioni elementari e selezione genetica"): `be_ai_goal.c`, `be_ai_move.c`, `be_ai_gen.c` e `be_ea.c`, con la facciata `TBotAiFactory`. L'AAS e' in `IdTech4\Aas` (#122). Il codice comune sta nella stessa cartella: `DelphiDoom.BotAi.Types`, `Import.Intf` (`IBotImport`, `IBotFileSource`, `IBotRandom`, `IBotLibVars`), `LibVars.Intf` (`IBotLibVarStore`), `Random.MsvcRand`, `LibVars.Table`, `Exceptions` e `Text.CFormat` sono comuni; la chat sta in `DelphiDoom.BotAi.Chat.*`, le strutture in `Struct.*`, i caratteri in `Character.*`, i pesi in `Weight.*`, le armi in `Weapon.*`.

## Uso

```pascal
LChat := TBotChatFactory.CreateChatSystem(Import, Files, LibVars, Random);
LChat.Setup;                       // synfile, rndfile, matchfile, rchatfile (variabili della libreria)
LState := LChat.AllocChatState;
LChat.SetChatName(LState, 'Zed', ClientNumber);
LChat.LoadChatFile(LState, 'chats.c', 'bot1');
LChat.InitialChat(LState, 'game_enter', 2, TBotChatVariables.FromTexts(['Bob']));
LChat.EnterChat(LState, 0, CHAT_ALL);  // Import.Command(client, 'say ...')
```

Le dipendenze verso il gioco sono interfacce iniettate (`Import.Intf`): `IBotImport` (stampa, log, tempo, comando del bot), `IBotFileSource` (i file `botfiles/...`), `IBotRandom` (`random()`), `IBotLibVars`. `TBotMsvcRandom` e' `srand`/`rand` del runtime Microsoft (stessa sequenza del C a parita' di seme), `TBotLibVarTable` le variabili della libreria. I test usano finti in memoria (`Tests\Source\DelphiDoom.Tests.BotAi.Support`).

## Mappa C -> Delphi

| C (`be_ai_chat.c` salvo dove detto) | Delphi |
|---|---|
| `BotSetupChatAI`, `BotShutdownChatAI`, `BotAllocChatState`, `BotFreeChatState`, `BotLoadChatFile`, `BotInitialChat`, `BotNumInitialChats`, `BotReplyChat`, `BotChatLength`, `BotEnterChat`, `BotGetChatMessage`, `BotSetChatGender`, `BotSetChatName`, `BotResetChatAI`, code della console, `BotFindMatch`, `BotMatchVariable`, `BotReplaceSynonyms` | `IBotChatSystem` / `TBotChatSystem` (`Chat.System`), creato da `TBotChatFactory` |
| stato `bot_chatstate_t`, `bot_chat_t`, `bot_chattype_t`, `bot_chatmessage_t`, `bot_replychat_t`, `bot_synonymlist_t`, `bot_randomlist_t` | `TBotChatState`, `TBotChat`, `TBotChatType`, `TBotChatMessage`, `TBotReplyChat`, `TBotSynonymList`, `TBotRandomList`; le liste globali (`synonyms`, `randomstrings`, `matchtemplates`, `replychats`) in `TBotChatTables`; record `TBotMatchTemplate`, `TBotMatchPiece`, `TBotReplyChatKey`, `TBotMatch` in `Chat.Types` |
| `InitConsoleMessageHeap`, `AllocConsoleMessage`, `FreeConsoleMessage` | `TBotConsoleMessageHeap` (conta i messaggi liberi, `max_messages`) |
| `BotLoadSynonyms`, `BotLoadRandomStrings`, `BotLoadMatchTemplates`, `BotLoadReplyChat`, `BotLoadInitialChat` (due passate come il C) | `TBotSynonymLoader`, `TBotRandomListLoader`, `TBotMatchTemplateLoader`, `TBotReplyChatLoader`, `TBotInitialChatLoader` |
| `BotLoadChatMessage`, `BotLoadMatchPieces` | `TBotChatMessageReader`, `TBotMatchPieceReader` |
| `BotCheckValidReplyChatKeySet`, `BotCheck*Integrety` | `TBotReplyKeyChecker`, `TBotChatIntegrityChecker` |
| `StringsMatch`, `BotFindMatch`, `BotMatchVariable` | `TBotChatMatcher` |
| `BotReplaceSynonyms`, `BotReplaceWeightedSynonyms`, `BotReplaceReplySynonyms` | `TBotSynonymReplacer` |
| `RandomString` | `TBotRandomStrings` |
| `BotExpandChatMessage`, `BotConstructChatMessage` | `TBotChatMessageBuilder` (scrive nel buffer del messaggio dello stato, come il C) |
| `IsWhiteSpace`, `BotRemoveTildes`, `UnifyWhiteSpaces`, `StringContains`, `StringContainsWord`, `StringReplaceWords` | `TBotChatText` |
| `LoadSourceFile`, `PC_ReadToken`, `PC_Expect*`, `PC_Check*`, `SourceError`, `SourceWarning` (`l_precomp.c`) | `TBotChatSource` sopra `TIdParser` di `Framework\Scanner` |
| `LoadScriptFile` (con `COM_Compress` di `q_shared.c`) | `TBotScriptFileSystem` (file system di `TIdParser`), `TBotScriptCompressor` |
| `ScriptWarning`, `SourceWarning` del preprocessore | `TBotScriptLog` -> `IBotImport.Print(PRT_WARNING)` |
| `random()` di `q_shared.h`; `LibVarValue/GetValue/String` (`l_libvar.c`) | `IBotRandom` / `TBotMsvcRandom`; `IBotLibVars` / `TBotLibVarTable` |

**Non portato**: `BotDumpSynonymList`, `BotDumpRandomStringList`, `BotDumpMatchTemplates`, `BotDumpReplyChat`, `BotDumpInitialChat`, `BotPrintReplyChatKeys` (scritture di debug: i `Dump` sono commentati nel C e scrivono su un `FILE *` del log), `BotFreeMatchPieces`/`BotFreeReplyChat`/... (memoria automatica), `l_memory.c`, `l_log.c`, `be_interface.c` (`l_struct.c` e `l_libvar.c` sono nella fetta #123).

## Lexer e preprocessore: riuso di TIdParser

`l_script.c` e `l_precomp.c` sono gli antenati di `idLexer`/`idParser`, gia' portati (`TIdLexer`, `TIdParser`). **Non si e' scritto un lexer a parte**: `TBotChatSource` usa `TIdParser` con flag 0 e aggiunge sopra i messaggi e il comportamento di `PC_*`; `TBotScriptFileSystem` applica `COM_Compress` a ogni file (anche agli `#include`), come `LoadScriptFile`, quindi i numeri di riga dei messaggi sono quelli del testo compresso. Provato sul vero `l_script.c`/`l_precomp.c` (harness in `Tools\Verifica\124`). **Differenze note del lexer** (tutte fuori dai file normali): in `l_script.c` un numero esadecimale accetta solo `a..f` minuscole e la `A` (`c <= 'A'`): `0xFF` e' `0x` seguito dal nome `FF`; `TIdLexer` legge `0xFF` come 255 (differenza voluta). I messaggi di errore del **preprocessore** (`#define` sbagliato, include mancante) hanno le parole di idParser ("file 'x' not found") e non quelle di `l_precomp.c` ("file x not found"); gli errori della chat (`expected {, found X`, ...) sono quelli del C. Un errore dello scanner e' stampato a `PRT_ERROR` e la lettura finisce come a fine file, come nel C. Numeri in virgola: `long double` del C diventa `Double` (un peso e' poi `Single`).

## Difetti del C conservati (servono per dare le stesse risposte)

- `bot_matchvariable_t.offset` e' un `char` con segno: un offset da 128 in su diventa negativo e la variabile e' "non impostata" (`TBotMatchVariable.Offset: ShortInt`); la lunghezza si calcola con l'offset troncato.
- `UnifyWhiteSpaces` non riparte dal puntatore spostato dopo `memmove`: con piu' di due spazi consecutivi seguiti da altri gruppi di spazi ne lascia (`"a    b  c"` -> `"a b  c"`); riprodotto sul buffer, comprese le letture dei byte vecchi dopo la fine.
- `BotRemoveTildes` salta il carattere che prende il posto della tilde (`"~~~"` -> `"~"`).
- `bestpriority` di `BotReplyChat` e' un `int`: le priorita' 2.5 e 2.7 pareggiano; nel camminare ai messaggi della risposta il C conta anche quelli troppo recenti.
- `RandomString` e `BotCheck*Integrety` consumano numeri casuali (il controllo di `bot_developer` cambia la sequenza).
- La chat e il match tengono gli offset in `char` e il testo in 256 byte; `BotReplyChat` non azzera le variabili tra una chiave e l'altra.
- Dopo un errore di `BotExpandChatMessage` il buffer del messaggio ha i caratteri nuovi seguiti dai vecchi (nessuno zero scritto): `TBotMessageBuffer` si comporta cosi'.
- `ExpectTokenType` con un sottotipo di numero sbagliato stampa un buffer non inizializzato prima dei nomi: qui e' vuoto (`"expected  integer"`).
- `BotLoadSynonyms` ignora i token che non sono numeri o punteggiatura (un nome di contesto non definito sparisce in silenzio).

## Differenze volute (difetti del C corretti, ognuna con un test in `TTestBotChatSystem`)

1. `BotLoadSynonyms` con un `}` mancante riporta "missing }" sul sorgente **gia' liberato** (use after free): qui lo riporta con file e riga prima e il file non e' caricato.
2. `BotLoadChatFile` libera la chat dello stato anche se e' nella cache `ichatdata`, lasciando un puntatore pendente: qui la chat in cache resta valida finche' non si fa `Shutdown`.
3. `BotNumInitialChats` senza chat nello stato dereferenzia NULL: qui da 0.
4. Una variabile `\v8` (il controllo e' `> MAX_MATCHVARIABLES`) legge fuori dal match: qui e' un errore come per le altre fuori intervallo.
5. Un nome di stringa casuale lungo (`"%cr%s%c"`, controllo solo di 7 caratteri) sfora il buffer: qui "chat message too long".
6. `strncpy` senza zero e `strcpy`/`strcat` senza limite nei messaggi di 256 byte (`BotFindMatch`, `BotReplyChat`, `BotInitialChat`, `BotQueueConsoleMessage`, il nome del tipo di chat): qui il testo e' tagliato a 255 caratteri (31 per il nome del bot e del tipo).
7. Un messaggio che riempie il buffer scrive lo zero oltre la fine: qui il testo e' tagliato a 255.
8. Una variabile il cui offset negativo (>= 128) e' l'ultima di un match leggerebbe prima del testo: lunghezza 0.
9. `BotShutdownChatAI` non libera lo stato 64 (il ciclo e' `< MAX_CLIENTS`): qui si libera in silenzio.
10. `0xFF` maiuscolo (vedi sopra).

## Caratteri, pesi fuzzy, armi e strutture (issue #123)

Percorso freddo, come la chat: nessun chiamante nel motore. Il file e' letto dallo stesso `TBotChatSource` (sopra `TIdParser`), le variabili da `IBotLibVars` (per scrivere `IBotLibVarStore`, che la estende: i finti della chat continuano a compilare), il generatore da `IBotRandom`. Nessun globale: `botcharacters`, `weightFileList`, `weaponconfig` e `botweaponstates` sono campi.

```pascal
LVars := TBotLibVarTable.Create;                         // IBotLibVarStore
LCharacters := TBotCharacterFactory.CreateCharacterSystem(Import, Files, LVars);
LHandle := LCharacters.LoadCharacter('bots/sarge_c.c', 2.5);   // 1..64, 0 se non si e' potuto
LAim := LCharacters.CharacteristicBoundedFloat(LHandle, 3, 0, 1);

LWeights := TBotWeightFactory.CreateWeightCache(Import, Files, LVars);
LWeapons := TBotWeaponFactory.CreateWeaponSystem(Import, Files, LVars, LWeights);
LWeapons.Setup;                                          // variabile weaponconfig (weapons.c)
LState := LWeapons.AllocWeaponState;
LWeapons.LoadWeaponWeights(LState, 'bots/sarge_w.c');
LBest := LWeapons.ChooseBestFightWeapon(LState, Inventory);   // TArray<Integer>
```

### Mappa C -> Delphi

| C | Delphi |
|---|---|
| `fielddef_t`, `structdef_t`, `FT_*` (`l_struct.h`) | `TBotFieldDefinition` (record), `TBotStructDefinition` (`Struct.Types`) |
| `ReadStructure`, `ReadNumber`, `ReadChar`, `ReadString` | `TBotStructReader` (`Struct.Reader`): legge in un `TBytes` con gli offset del C |
| `WriteStructure`, `WriteIndent`, `WriteFloat` | `TBotStructWriter` (`Struct.Writer`): scrive in una `AnsiString` (righe CR LF) |
| `LibVar*` (`l_libvar.c`) | `TBotLibVarTable` + `IBotLibVarStore` (`LibVars.*`): `LibVarStringValue` vero, `LibVarSet`, `LibVarGetString`, `LibVarChanged`, `LibVarSetNotModified` |
| `bot_character_t`, `bot_characteristic_t`, `BotDumpCharacter`, `BotDefaultCharacteristics` | `TBotCharacter`, `TBotCharacteristic` (`Character.Data`, `Character.Types`) |
| `BotLoadCharacterFromFile` | `TBotCharacterLoader` |
| `BotInterpolateCharacters` | `TBotCharacterInterpolator` |
| `BotLoadCharacter`, `BotLoadCharacterSkill`, `BotLoadCachedCharacter`, `BotFindCachedCharacter`, `BotFreeCharacter`, `BotShutdownCharacters`, `Characteristic_*` | `IBotCharacterSystem` / `TBotCharacterSystem` (`Character.System`), creato da `TBotCharacterFactory` |
| `fuzzyseperator_t` | `TBotFuzzySeparator` |
| `weightconfig_t`, `FindFuzzyWeight` | `TBotWeightConfig` (`Weight.Config`) |
| `ReadValue`, `ReadFuzzyWeight`, `ReadFuzzySeperators_r`, parte di lettura di `ReadWeightConfig` | `TBotWeightReader` |
| `weightFileList`, cache di `ReadWeightConfig`, `FreeWeightConfig`, `BotShutdownWeights` | `IBotWeightCache` / `TBotWeightCache` (`Weight.Cache`, `Weight.Factory`) |
| `FuzzyWeight`, `FuzzyWeightUndecided` | `TBotFuzzyEvaluator` |
| `ScaleWeight`, `ScaleFuzzyBalanceRange` (nell'header `ScaleBalanceRange`) | `TBotWeightScaler` |
| `EvolveWeightConfig`, `InterbreedWeightConfigs` | `TBotWeightBreeder` |
| `weaponinfo_t`, `projectileinfo_t` | `TBotWeaponInfo` (552 byte), `TBotProjectileInfo` (208 byte), `packed`, con il layout del C (`Weapon.Types`) |
| `weaponinfo_fields`, `projectileinfo_fields` (con gli offset) | `TBotWeaponDefinitions` (gli offset si calcolano con un record di prova, come `offsetof`) |
| `weaponconfig_t` | `TBotWeaponConfig` |
| `LoadWeaponConfig` | `TBotWeaponConfigLoader` |
| `bot_weaponstate_t` | `TBotWeaponState` |
| `BotSetupWeaponAI`, `BotShutdownWeaponAI`, `BotAllocWeaponState`, `BotFreeWeaponState`, `BotResetWeaponState`, `BotLoadWeaponWeights`, `BotGetWeaponInfo`, `BotChooseBestFightWeapon`, `WeaponWeightIndex` | `IBotWeaponSystem` / `TBotWeaponSystem` (`Weapon.System`, `Weapon.Factory`) |

**Non portato** (fetta #123): `be_ai_goal.c` (obiettivi e oggetti: 1821 righe, la fetta successiva), `be_ai_gen.c` (`GeneticParentsAndChildSelection`: 134 righe), `be_ai_move.c`, `WriteWeightConfig` (nel C e' sotto `#if 0`), `DumpWeaponConfig` (solo `DEBUG_AI_WEAP`; `TBotStructWriter` ha la stessa uscita ed e' provata), `LibVarDeAllocAll` (le variabili sono un oggetto). `bot_developer` e i tempi sotto `#ifdef DEBUG` non ci sono.

### Difetti del C conservati (servono per dare le stesse risposte)

- **Interpolazione dei pesi**: `FuzzyWeight` calcola la posizione fra due casi con una divisione **intera** (`(inventory - value) / (next->value - value)`), che per costruzione e' sempre 0: il peso fra due casi e' quello del caso successivo (`FuzzyWeightUndecided` fa lo stesso e valuta il figlio del caso successivo come peso deciso).
- `ReadValue`: dopo un `-` stampa "negative value set to zero" ma legge il numero senza segno (`return -5;` pesa 5).
- `InterbreedFuzzySeperator_r` passa due volte `fs2->child` (`fs1->child` non si legge mai) e alza il minimo con lo stesso confronto del massimo (`weight > minweight`).
- `BotDefaultCharacteristics` modifica **sul posto** il carattere in cache (anche quello di un altro file con lo stesso nome e skill).
- Un livello che finisce a fine file senza `}` (`while (PC_ExpectAnyToken...)`) e' **accettato**, con il messaggio "couldn't read expected token".
- Gli indici dei caratteri sono 0..80 nel file (`index > MAX_CHARACTERISTICS`) ma si leggono solo 0..79; i valori negativi non si possono scrivere (`-` e' una punteggiatura e il file non la accetta); le skill 2, 3 e 4.5 si ottengono interpolando solo i `float` presenti in entrambi i livelli (un intero scritto `2` e un reale `1.5` non si interpolano: resta quello del primo livello, o manca).
- `LibVarStringValue`: solo cifre e al piu' un punto, senza segno ne' esponente (`-1`, `1e3` danno 0); il carattere dopo il punto si converte senza controllo (`1.x` = 8.2).
- `ReadNumber` (`l_struct.c`): un `FT_INT` e' un intero a 16 bit (-32768..32767, `FT_UNSIGNED` 0..65535) e un `FT_CHAR` e' 8 bit; i limiti `FT_BOUNDED` si confrontano come `float` (`Maximum`/`Minimum` mescolano `long` e `float`); `ReadStructure` ignora il risultato di una sottostruttura; `WriteStructWithIndent` passa alla sottostruttura l'inizio della struttura esterna e non il campo; in un array una virgola finale dopo l'ultimo elemento lascia la `}` all'esterno, che chiude la struttura.
- Il `model` di un `projectileinfo` usa `WEAPON_OFS(model)` (88): si scrive 8 byte dentro `model` e **azzera** `flags` e `gravity` se erano gia' stati letti; l'ordine dei campi nel file decide il risultato (`TBotWeaponDefinitions`, provato con l'impronta dei byte).
- `LoadWeaponConfig`: `numweapons` e' la dimensione della tabella (`max_weaponinfo`), non il numero di armi; le armi non definite hanno `valid` a 0; il numero di un `weaponinfo` e' un indice nella tabella (`number 32` con la tabella da 32 e' un errore); `BotWeaponStateFromHandle` parla di "move state" anche per le armi.
- Il `scale` di `BotInterpolateCharacters` e' `(skill - skill1) / (skill2 - skill1)` in virgola mobile **senza controllo**: se un file ha un solo livello la divisione per 0 da' infinito e le caratteristiche interpolate sono infinito o NaN (`Characteristic_Integer` di un NaN e' `$80000000`). L'ambiente della FPU e' mascherato solo dentro `TBotCharacterInterpolator` e poi ripristinato.
- I messaggi di `SourceError`/`SourceWarning` dei caratteri e dei pesi hanno un `\n` finale e quindi due righe; quelli di `l_struct.c` no.

### Differenze volute (difetti del C corretti, ognuna con un test)

1. `FuzzyWeight` con un indice di inventario che non esiste (il C legge fuori dall'array): `EBotAiException`. L'inventario e' un `TArray<Integer>` (il pilota del C ne ha 1024, il resto zero).
2. `BotGetWeaponInfo`: un numero di arma uguale a `numweapons`, o chiamato prima di `Setup` (il C legge fuori dalla tabella o dereferenzia `NULL`), stampa "weapon number out of range".
3. `BotFreeWeaponWeights` non lascia puntatori pendenti e `FreeWeightConfig` con `bot_reloadcharacters` acceso non lascia la configurazione in `weightFileList` (il C la libera due volte a `BotShutdownWeights`). Le configurazioni sono di proprieta' di `IBotWeightCache`: `Shutdown` le libera tutte e quelle in mano a un `TBotWeaponState` non vanno piu' usate.
4. `Characteristic_String` con una dimensione <= 0 (crash nel C) da' la stringa vuota. Un nome di file di piu' di 63 caratteri (il C sfora la struttura) e' accettato per intero.
5. Un campo di una struttura che cadrebbe fuori dal buffer (`ReadStructure`/`WriteStructure`: il C scrive o legge fuori dalla struttura) e' una `EBotAiException`.
6. `LibVarStringValue("5.")` si ferma alla fine del testo (il C legge oltre il terminatore).
7. **`0..30`** (numero con piu' punti): `TIdLexer` lo rifiuta ("more than one dot in number") e il carattere di `sergei_c.c` di OpenArena e' sostituito da quello di default; `l_script.c` lo legge come un numero. E' una differenza del lexer (`TIdLexer` e' la base comune del repository), non della libreria: provata da `TTestBotOpenArenaAi`.
8. `BLERR_CANNOTLOADICHAT` valeva 20 (un valore inventato dallo stub di #124): il valore di `botlib.h` e' 8 (anche negli stub e nel golden della chat). Aggiunti `BLERR_CANNOTLOADITEMWEIGHTS` (9), `..ITEMCONFIG` (10), `..WEAPONWEIGHTS` (11), `..WEAPONCONFIG` (12).
9. Virgola mobile: `float` e' `Single`, ogni operazione e' fatta e arrotondata da sola come con SSE (`-ffp-contract=off`); le espressioni miste `float`/`double` del C (`crandom()`, `random() < 0.01`, `skill + 0.5`, `fabs(...) < 0.01`) sono fatte in `Double`; i numeri dei file sono letti da un `Double` (il C da un `long double`). Il C compilato con MSVC puo' differire di un ulp dal golden dove usa l'x87.

### Parita' col C

`Tools\Verifica\123` (vedi `LEGGIMI.md`) compila con gcc di `w64devkit` il vero `be_ai_char.c`, `be_ai_weight.c`, `be_ai_weap.c`, `l_struct.c`, `l_libvar.c`, `l_script.c` e `l_precomp.c` con stub minimi e `botgen.c`. `Tests\Data\BotAi\botscenario.txt` (variabili, 24 file di struttura con ogni tipo di campo e ogni errore, pesi con switch annidati, bilanciamenti, evoluzione e incrocio, caratteri con ogni percorso della cache e del default, armi e proiettili con tutti gli errori, stati) e `botscenario.golden.txt` sono l'uscita del C (4058 righe); `botscenario_alt.txt` su `alt1` (default con la sola skill 5) e `alt2` (senza default) in `botscenario_alt1.golden.txt` e `botscenario_alt2.golden.txt` (2175 e 2712 righe, compresi NaN e il pool di 64 caratteri pieno). `TBotAiScenarioRunner` rifa lo scenario con le classi Delphi e confronta riga per riga, con i float come bit: **zero differenze** (Win32 e Win64). Tolleranza: nessuna. In piu', con `DELPHIDOOM_OA_PARITY` (vedi `LEGGIMI.md`), 13751 righe sui file veri di OpenArena 0.8.8 (tutti i caratteri a 5 skill, tutti i `*_w.c` e `*_i.c`, le armi): zero differenze, tranne `sergei_c.c` (escluso, vedi sopra).

## Obiettivi, movimento, azioni elementari e selezione genetica (issue #123, seconda parte)

Percorso freddo: nessun chiamante nel motore. `be_ai_goal.c`, `be_ai_move.c`, `be_ai_gen.c` e `be_ea.c` (+ le `AAS_*` che chiamano, in `IdTech4\Aas`) sono a classi con gli **handle del C** (stati 1..64). Il gioco e' dietro interfacce: `IBotImport` (`Print`, `LogWrite`, `Time`, `Command`), `IBotFileSource`, `IBotLibVarStore`, `IBotRandom`, `IBotAasWorld` (l'AAS caricata e le entita': `World.*`) e `IBotElementaryActions` (gli ingressi `bot_input_t` per client: `Ea.*`). La facciata `TBotAiFactory.CreateAi` (`Facade.Factory`) e' l'unico posto che conosce le classi e da' un `IBotAi` con `Characters`, `Chat`, `Weights`, `Weapons`, `Goals`, `Moves`, `Genetics`, `Actions`.

```pascal
LAi := TBotAiFactory.CreateAi(Import, Files, LibVars, Random, World, MaxClients, Developer);
LAi.Goals.Setup;  LAi.Moves.Setup;                        // max_levelitems, max_iteminfo, ...
LGoal := LAi.Goals.AllocGoalState(Client);                // 1..64
LAi.Goals.LoadItemWeights(LGoal, 'bots/sarge_i.c');
LAi.Goals.ChooseLTGItem(LGoal, Origin, Inventory, TravelFlags, LItemGoal);
LMove := LAi.Moves.AllocMoveState;
LResult := LAi.Moves.MoveToGoal(LMove, @LItemGoal, TravelFlags);   // bot_moveresult_t
LInput := LAi.Actions.GetInput(Client, 0.1);                       // bot_input_t
```

### Mappa C -> Delphi

| C | Delphi |
|---|---|
| `itemconfig_t`, `iteminfo_t` (236 byte, layout del C), `LoadItemConfig` | `TBotItemConfig`, `TBotItemInfo` (`Goal.ItemConfig`, `Goal.Types`), `TBotItemConfigLoader` sopra `TBotChatSource` e `TBotStructReader` |
| `iteminfo_fields` e le altre definizioni di struttura | `TBotItemDefinitions` |
| `levelitem_t`, `levelitems`, `freelevelitems`, `itemtargets` (lista e heap) | `TBotLevelItems` (`Goal.LevelItems`) |
| `BotInitInfoEntities`, `BotInitLevelItems`, `BotGoalName` e le entita' del BSP (`info_*`, `target_location`, `info_camp`) | `TBotInfoEntities`, `TBotLevelItemInitializer` (`Goal.ItemInitializer`) |
| `BotUpdateEntityItems` | `TBotEntityItemUpdater` (`Goal.EntityItems`) |
| `BotChooseLTGItem`, `BotChooseNBGItem` (peso fuzzy e tempo di viaggio AAS, `BotGoalForLevelItem`) | `TBotGoalChooser` (`Goal.Chooser`) |
| `bot_goalstate_t`, pila degli obiettivi (`MAX_GOALSTACK`), `avoidgoals`, `BotPushGoal`, `BotPopGoal`, `BotAvoidGoalTime`, `BotSetAvoidGoalTime`, `BotTouchingGoal`, `BotItemGoalInVisButNotVisible`, `BotGetLevelItemGoal`, `BotGetNextCampSpotGoal`, `BotGetMapLocationGoal`, `BotLoadItemWeights`, `BotInterbreedGoalFuzzyLogic`, `BotMutateGoalFuzzyLogic`, `BotSetupGoalAI` e gli altri `Bot*GoalState` | `IBotGoalSystem` / `TBotGoalSystem` (`Goal.System`, `Goal.State`, `Goal.Context`), creato da `TBotGoalFactory` |
| `bot_movestate_t`, `bot_initmove_t`, `bot_moveresult_t`, `MFL_*`, `MOVERESULT_*` | `TBotMoveState`, `TBotInitMove`, `TBotMoveResult` e le costanti (`Move.Types`, `Move.State`) |
| `BotMoveToGoal` e `BotMoveInGoalArea` | `TBotMoveSystem.MoveToGoal` (`Move.System`) |
| `BotTravel_*` e `BotFinishTravel_*` per ogni tipo (walk, crouch, barrier jump, swim, water jump, walk off ledge, jump, ladder, teleport, elevator, func bobbing, grapple hook, rocket jump, BFG jump, jump pad) | una classe per unit, `Move.Travel.*` (derivata da `TBotTravelBase`, contratto `IBotTravelType`); il registro e' un dizionario per tipo in `Move.Factory` (al posto del grande `switch`) |
| `BotCheckBlocked`, `BotOnTopOfEntity`, `BotCheckBarrierJump`, `BotGapDistance`, `BotAirControl`, `AngleDiff` | `TBotMoveBasics` (`Move.Basics`) |
| `BotOnMover`, `MoverDown`, `MoverBottomCenter`, `BotFuncBobStartEnd` | `TBotMovers` (`Move.Movers`) |
| `BotAddToAvoidReach`, `BotAddAvoidSpot`, `BotAvoidSpots`, `BotResetAvoidReach`, `BotResetLastAvoidReach` | `TBotAvoidSpotChecker` (`Move.AvoidSpots`) e `TBotMoveSystem` |
| `BotReachabilityArea`, `BotFuzzyPointReachabilityArea` | `TBotReachabilityLocator` (`Move.Locator`, `IBotReachabilityLocator`) |
| `BotGetReachabilityToGoal` | `TBotReachabilityChooser` (`Move.ReachChooser`) |
| `BotMovementViewTarget`, `BotPredictVisiblePosition`, `BotAddToTarget` | `TBotMovePredictor` (`Move.Predictor`) |
| `BotMoveInDirection`, `BotSetBrushModelTypes` | `TBotMoveSystem`, `TBotBrushModelTypes` (`Move.ModelTypes`) |
| variabili `sv_*`, `weapindex_*`, `entitytypemissile`, `offhandgrapple`, `cmd_grappleon` ... | `TBotMoveVars` (`Move.Vars`): si leggono a ogni uso, come i puntatori del C |
| macro di vettori (`VectorMA`, `VectorNormalize`, `Vector2Angles`, ...) | `TBotVectorMath` (`Move.VectorMath`), con l'aritmetica `float` o `double` del C |
| `GeneticParentsAndChildSelection`, `GeneticSelection` | `TBotGeneticSelector` (`IBotGenetics`) |
| `EA_*` (28 funzioni) e `botinputs` | `TBotElementaryActions` (`IBotElementaryActions`, `Ea.*`) |
| `AAS_*` usate (vedi `IdTech4\Aas\CLAUDE.md`) | `IBotAasWorld` (`World.*`): `TBotAasWorld` raccoglie le parti dell'AAS caricata, `TBotAasEntitySource` adatta `TAasEntityTable` |

**Non portato** (#123): `BotSaveGoalFuzzyLogic` e' una chiamata che non scrive (`WriteWeightConfig` e' commentata nel C: si controlla solo l'handle), `EA_EndRegular` (vuota nel C), le funzioni di disegno e diagnostica (`AAS_DebugLine`, `AAS_ShowReachability`, `BotDumpGoalStack` scrive il testo ma non disegna), `BotShutdownGoalAI`/`BotShutdownMoveAI` si chiamano `Shutdown`. Non c'e' un collegamento a un gioco (`IBotImport` del motore): resta della #123 solo quello.

### Difetti del C conservati (servono per dare le stesse risposte)

- **Costanti `double`**: `avoidtime - t * 0.009` e `weight / (t * 0.01)` (`BotChooseLTGItem`, `BotChooseNBGItem`) e `M_PI` sono in `Double`; gli altri `float` sono `Single` con ogni operazione assegnata a una variabile `Single` (SSE).
- `BotGoalForLevelItem`/`BotGetLevelItemGoal`: **somma le `mins` alle `mins`** (non le `maxs`).
- **`BotInitLevelItems`**: l'ultima entita' della mappa e' la prima della lista (il C inserisce in testa); l'ordine decide a pari peso.
- **Avoid spot** (`BotAvoidSpots`): la distanza dalla fine della raggiungibilita' si calcola e si scarta; il difetto del ramo `else` e' conservato (`Move.AvoidSpots`).
- **Elevatore** e func_bobbing: il controllo `abs(origin[2] - end[2]) < sv_maxbarrier` usa `abs` intera; `BotMoveToGoal` controlla `MOVERESULT_ONTOPOF_FUNCBOB` due volte (non cambia nulla); `BotTravel_FuncBobbing` manda `dir` e non `hordir`; senza entita' del modello usa un'origine non inizializzata (qui azzerata).
- **BFG jump**: il test della vista usa gli angoli ideali prima di scriverli (il C li legge dal risultato, che il pilota C ora azzera: `BotClearMoveResult`).
- **Selezione genetica**: `GeneticSelection` calcola `select = random() * sum` e non lo usa; il numero casuale si consuma comunque.
- `BotWalk`/finish: `BotFinishTravel_Walk` non e' mai usato, in aria si chiama `BotTravel_Walk`.
- `BotMoveInGoalArea` e `BotMoveToGoal` conservano gli ordini di valutazione dei float del C (visto con Win64: `Tools\Verifica\123\ai` e gli `Single` espliciti).

### Differenze volute (difetti del C corretti, ognuna con un test)

1. `BotSetBrushModelTypes` con `modelnum == MAX_MODELS` passava il controllo e scriveva dopo la tabella: ora e' fuori intervallo (e il pilota C ha la stessa correzione, dichiarata in `build.sh`).
2. `BotResetLastAvoidReach` leggeva `avoidreachtries[MAX_AVOIDREACH]`, una voce dopo l'array: legge quella che azzera (correzione anche nel pilota C).
3. `BotInitLevelItems` con `max_levelitems` 0 scriveva prima dello heap; `InitLevelItemHeap` con 0 voci e' gestito.
4. `BotClearMoveResult` lascia `weapon`, `movedir` e `ideal_viewangles` come li aveva lo stack: sono azzerati (anche nel pilota C).
5. Un numero di cliente fuori dalla tabella delle azioni, un indice di oggetto fuori dalla tabella, un handle che non esiste, un `BotInterbreedGoalFuzzyLogic` o un `BotFreeItemWeights` su stati senza pesi (il C legge fuori o lascia puntatori pendenti): `EBotAiException` o nessun effetto con l'avviso del C (`FreeItemWeights` azzera tutti e due i puntatori).
6. `GeneticSelection` con un `random()` esattamente 1.0 leggeva `rankings[numranks]`: l'indice e' l'ultimo.

### Parita' col C (seconda parte)

`Tools\Verifica\123\ai` (vedi `LEGGIMI.md`) compila il vero `be_ai_goal.c`, `be_ai_move.c`, `be_ai_gen.c`, `be_ea.c` sopra il vero `be_aas_*.c` con gcc di `w64devkit`. `Tests\Data\BotAi\goal\goalmove.txt` (scritto da `Make-Scenario.ps1`: oggetti, scelte dell'obiettivo e tempi di viaggio, pile, oggetti a tempo, ogni tipo di viaggio a terra, in aria, in acqua, sull'elevatore e sul func_bobbing, grapple hook attivo e perso, salti con le armi, avoid spot, `mvsim` con la simulazione a tic, selezione genetica, azioni elementari) e `goalmove.golden.txt` (l'uscita del C: scelte, tempi, pile, ingressi per tic, i float come bit) sono lo stesso scenario eseguito dal pilota C e da `TGoalMoveScenario` (Delphi, mondo gemello). **Zero differenze** (Win32 e Win64). Tolleranza: nessuna. La parita' prova la logica; il mondo e' l'AAS di prova con scatole solide e liquidi, non un BSP vero (prova delle `AAS_*` sul BSP: `IdTech4\Aas`).

## Prove

`Tests\DelphiDoom.Tests.BotAi` (192 test; 8 si ignorano senza i file di OpenArena; copertura 95%, 124 unit; Win32 e Win64): le unit di #123 della prima parte (170 test, vedi sotto) piu' la parita' del movimento (`TTestBotGoalMoveParity`), le azioni elementari (`TTestBotElementaryActions`), le parti del mondo (`TTestBotWorldUnits`), il file degli oggetti con errori e 300 file alterati con seme fisso (`TTestBotItemConfigLoader`), la facciata (`TTestBotAiFacade`) e `Fixed1`. Le unit sotto il 90% sono quasi tutte `Move.Travel.*`: i rami che restano (WeaponJump, WalkOffLedge, JumpPad, Base) sono casi di posizione e velocita' che lo scenario non ha ancora (vedi `CLAUDE.md`). Prima parte (#123, caratteri, pesi, armi): `Tests\DelphiDoom.Tests.BotAi` (170 test: 63 della chat, 107 di #123, di cui 8 sui file di OpenArena che si ignorano se mancano; copertura 98%, ogni unit >= 90%; Win32 e Win64). Parita': `Tests\Data\BotAi\scenario.txt` (269 comandi: testo, setup, sinonimi, match, costruzione dei messaggi, file di chat, risposte, invio, coda della console, handle, cache, file con errori) e `chat.golden.txt` sono l'uscita del **vero** `be_ai_chat.c` + `l_script.c` + `l_precomp.c` compilati con gcc di `Reference\_dati\_strumenti\w64devkit` con stub minimi (`Tools\Verifica\124`); `TBotScenarioRunner` rifa lo scenario con le classi Delphi e confronta riga per riga (stampe a ogni livello, log, comandi, messaggi, variabili, handle). Zero differenze. I file di chat di `Tests\Data\BotAi\botfiles` sono scritti per i test (nessun file di Quake III nel repository). Tolleranza in virgola mobile: nessuna sui numeri casuali (stessa sequenza di `rand`); i pesi dei sinonimi sono `Single` come `float` e sono letti da un `Double` (il C da un `long double`: uguali per i pesi con poche cifre).

## Cosa manca

Il collegamento a un gioco (`IBotImport` e `IBotAasWorld` di `ComposeEngine`, `bot_input_t` verso il ticcmd del motore): nessun chiamante. Coprire i rami di posizione che lo scenario non ha ancora (Move.Travel.WeaponJump, WalkOffLedge, JumpPad, Base: sotto il 90%) e la prova delle AAS_* su un BSP vero. I file di OpenArena 0.8.8 (`botfiles` di `pak6-misc.pk3`, GPL v2) sono letti da `TTestBotOpenArena` (setup e chat dei 24 bot senza errori; variabile `DELPHIDOOM_OPENARENA` o `Reference\openarena`); i file di chat di Quake III non sono nel repository.

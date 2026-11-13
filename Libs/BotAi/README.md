# Libs\BotAi

Port a classi dell'IA dei bot di **Quake III Arena** (`code\botlib`, GPL v2 o successiva, id Software). Prima fetta (issue #124): la **chat dei bot** (`be_ai_chat.c`). La libreria non ha chiamanti nel motore (percorso freddo). Le altre parti di botlib (#123: caratteri, pesi fuzzy, armi, obiettivi; #122: AAS; movimento) si aggiungono nella stessa cartella: `DelphiDoom.BotAi.Types`, `Import.Intf` (`IBotImport`, `IBotFileSource`, `IBotRandom`, `IBotLibVars`), `Random.MsvcRand` e `LibVars.Table` sono comuni e non dipendono dalla chat; tutto cio' che e' della chat sta in `DelphiDoom.BotAi.Chat.*`.

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
| `LoadSourceFile`, `PC_ReadToken`, `PC_Expect*`, `PC_Check*`, `SourceError`, `SourceWarning` (`l_precomp.c`) | `TBotChatSource` sopra `TIdParser` di `Libs\Scanner` |
| `LoadScriptFile` (con `COM_Compress` di `q_shared.c`) | `TBotScriptFileSystem` (file system di `TIdParser`), `TBotScriptCompressor` |
| `ScriptWarning`, `SourceWarning` del preprocessore | `TBotScriptLog` -> `IBotImport.Print(PRT_WARNING)` |
| `random()` di `q_shared.h`; `LibVarValue/GetValue/String` (`l_libvar.c`) | `IBotRandom` / `TBotMsvcRandom`; `IBotLibVars` / `TBotLibVarTable` |

**Non portato**: `BotDumpSynonymList`, `BotDumpRandomStringList`, `BotDumpMatchTemplates`, `BotDumpReplyChat`, `BotDumpInitialChat`, `BotPrintReplyChatKeys` (scritture di debug: i `Dump` sono commentati nel C e scrivono su un `FILE *` del log), `BotFreeMatchPieces`/`BotFreeReplyChat`/... (memoria automatica), `l_struct.c`, `l_memory.c`, `l_log.c` e il resto di `l_libvar.c` (servono a #123; qui solo la tabella delle variabili), `be_interface.c`.

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

## Prove

`Tests\DelphiDoom.Tests.BotAi` (63 test, di cui 3 sui file di OpenArena che si ignorano se mancano; copertura 97%, ogni unit >= 90%; Win32 e Win64). Parita': `Tests\Data\BotAi\scenario.txt` (269 comandi: testo, setup, sinonimi, match, costruzione dei messaggi, file di chat, risposte, invio, coda della console, handle, cache, file con errori) e `chat.golden.txt` sono l'uscita del **vero** `be_ai_chat.c` + `l_script.c` + `l_precomp.c` compilati con gcc di `Reference\_dati\_strumenti\w64devkit` con stub minimi (`Tools\Verifica\124`); `TBotScenarioRunner` rifa lo scenario con le classi Delphi e confronta riga per riga (stampe a ogni livello, log, comandi, messaggi, variabili, handle). Zero differenze. I file di chat di `Tests\Data\BotAi\botfiles` sono scritti per i test (nessun file di Quake III nel repository). Tolleranza in virgola mobile: nessuna sui numeri casuali (stessa sequenza di `rand`); i pesi dei sinonimi sono `Single` come `float` e sono letti da un `Double` (il C da un `long double`: uguali per i pesi con poche cifre).

## Cosa manca

`#123` (caratteri `be_ai_char`, pesi fuzzy `be_ai_weight`, armi, obiettivi: useranno `IBotImport`, `IBotLibVars` e il lexer di `TBotChatSource`/`TIdParser`; `l_libvar.c` si estende in `TBotLibVarTable`), `#122` AAS e movimento; il collegamento a un gioco (nel `IBotImport` di `ComposeEngine`) non c'e': nessun chiamante. I file di OpenArena 0.8.8 (`botfiles` di `pak6-misc.pk3`, GPL v2) sono letti da `TTestBotOpenArena` (setup e chat dei 24 bot senza errori; variabile `DELPHIDOOM_OPENARENA` o `Reference\openarena`); i file di chat di Quake III non sono nel repository.

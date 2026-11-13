# Verifica #124: chat dei bot di Quake III

Produce `Tests\Data\BotAi\chat.golden.txt` con il codice **vero** di Quake III: `build.sh` copia senza modifiche `code/botlib/be_ai_chat.c`, `l_script.c`, `l_precomp.c` (e gli header) in una cartella di lavoro, con le righe 315-381 di `code/game/q_shared.c` (`COM_Compress`, che `LoadScriptFile` applica a ogni file); `stub/` sostituisce il resto (memoria, variabili della libreria, log, file system su cartella, `q_shared.h`, `botlib.h`); `chatgen.c` e' il pilota che esegue i comandi di `Tests\Data\BotAi\scenario.txt`.

```
sh Tools/Verifica/124/build.sh <cartella di uscita>
<cartella>/chatgen.exe Tests/Data/BotAi Tests/Data/BotAi/scenario.txt > Tests/Data/BotAi/chat.golden.txt
```

- Compilatore: gcc a 64 bit di `Reference\_dati\_strumenti\w64devkit` (SSE, `-ffp-contract=off`). `random()` e' `rand()` del runtime Microsoft con `srand(seme)`: il Delphi ne ha la stessa sequenza (`TBotMsvcRandom`).
- I file dei bot (`Tests\Data\BotAi\botfiles`) sono scritti per questi test, non sono quelli di Quake III.
- Ogni stringa e' stampata con i byte sotto 32, sopra 126 e la barra rovesciata come `\xNN`; `P<livello>|testo` e' `botimport.Print`, `L|testo` e' il log, `E|client|comando` e' `EA_Command`.
- Difetti del C emersi (non nel golden perche' indefiniti): `bad_syn3.c` ("missing }") usa il sorgente dopo `FreeSource` (use after free); `BotLoadChatFile` libera la chat di uno stato anche se e' nella cache `ichatdata` (puntatore pendente); `BotNumInitialChats` senza chat caricata dereferenzia NULL; `0xFF` con lettere maiuscole non e' un numero esadecimale in `l_script.c` (`c <= 'A'`), per questo `match.h` usa `0xffffffff`.

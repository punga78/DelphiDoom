# Verifica #123: caratteri, pesi fuzzy, armi e strutture dei bot di Quake III

Produce `Tests\Data\BotAi\botscenario.golden.txt` (e `botscenario_alt1.golden.txt`, `botscenario_alt2.golden.txt`) con il codice **vero** di Quake III: `build.sh` copia `code/botlib/be_ai_char.c`, `be_ai_weight.c`, `be_ai_weap.c`, `l_struct.c`, `l_libvar.c`, `l_script.c`, `l_precomp.c` (e gli header, e `game/be_ai_char.h`, `game/be_ai_weap.h`) in una cartella di lavoro, con le righe 315-381 di `code/game/q_shared.c` (`COM_Compress`, che `LoadScriptFile` applica a ogni file); `stub/` sostituisce il resto (memoria, log, file system su cartella, `q_shared.h`, `botlib.h`); `botgen.c` e' il pilota che esegue i comandi di `Tests\Data\BotAi\botscenario.txt`.

```
sh Tools/Verifica/123/build.sh <cartella di uscita>
<cartella>/botgen.exe Tests/Data/BotAi Tests/Data/BotAi/botscenario.txt > Tests/Data/BotAi/botscenario.golden.txt
<cartella>/botgen.exe Tests/Data/BotAi/alt1 Tests/Data/BotAi/botscenario_alt.txt > Tests/Data/BotAi/botscenario_alt1.golden.txt
<cartella>/botgen.exe Tests/Data/BotAi/alt2 Tests/Data/BotAi/botscenario_alt.txt > Tests/Data/BotAi/botscenario_alt2.golden.txt
```

(la redirezione va fatta con una shell che non cambia i byte: `cmd /c` o `sh`, non il `>` di Windows PowerShell 5.1, che scrive UTF-16).

- Compilatore: gcc a 64 bit di `Reference\_dati\_strumenti\w64devkit` (SSE, `-ffp-contract=off`). `random()` e' `rand()` del runtime Microsoft con `srand(seme)`: il Delphi ne ha la stessa sequenza (`TBotMsvcRandom`).
- **Sui sorgenti del C**: i `.c` sono copiati senza modifiche tranne due cose, dichiarate in `build.sh`: gli header di botlib non hanno guardie di inclusione e `be_ai_char.c`, `be_ai_weight.c` e `be_ai_weap.c` sono una sola unita' di traduzione in `botgen.c` (cosi' si vedono i dati `static`), quindi ogni header e' avvolto in `#ifndef/#define/#endif`; le macro `WEAPON_OFS` e `PROJECTILE_OFS` di `be_ai_weap.c`, che convertono un puntatore in `int` (un compilatore a 64 bit non lo accetta in un inizializzatore), sono scritte con `offsetof` (stesso valore).
- I file dei bot (`Tests\Data\BotAi\botfiles`, `alt1`, `alt2`) sono scritti per questi test, non sono quelli di Quake III ne' di OpenArena.
- Ogni stringa e' stampata con i byte sotto 32, sopra 126 e la barra rovesciata come `\xNN`; `P<livello>|testo` e' `botimport.Print`, `L|testo` e' il log. I float sono stampati come i loro bit (`3F800000(1.000000)`; `nan`/`inf` senza decimali). `weaponinfo_t` e `projectileinfo_t` sono stampati con l'impronta FNV-1a dei loro byte e con `WriteStructure` del C.
- La riga `skill %d` di `BotDumpCharacter` (passa un `float` a `%d`: comportamento indefinito) il pilota non la scrive e il Delphi nemmeno.

## Prova sui file di OpenArena (locale, mai nel repository)

`TTestBotOpenArenaAi.DovrebbeDareLeStesseRisposteDelCSuiFileDiOpenArena` si esegue solo con la variabile `DELPHIDOOM_OA_PARITY` che indica una cartella con `botfiles\` estratta da `pak6-misc.pk3` di OpenArena 0.8.8, `oa_scenario.txt` e `oa_golden.txt`. Si fanno cosi': estrarre `botfiles/*` del pk3 nella cartella; scrivere in `oa_scenario.txt` un `char|bots/X_c.c|S` per ogni personaggio e skill (con `charshutdown` dopo ognuno), un `wread|0|F` e `wdump|0` per ogni file `*_w.c` e `*_i.c` (salvo `default_*`, che sono modelli con macro non definite, e con `wshutdown` ogni 40), `wpsetup`, `wpdump` e, per ogni `bots/*_w.c`, `wpalloc`, `wpweights|1|F`, `wpbest|1|0|1|...|20`, `wpfree|1`; poi `botgen.exe <cartella> <cartella>\oa_scenario.txt > <cartella>\oa_golden.txt`. Con OpenArena 0.8.8 sono 13751 righe, zero messaggi di errore nel C e zero differenze nel Delphi. **`bots/sergei_c.c` e' escluso**: ha un refuso (`0..30`) che `l_script.c` legge come numero e il lexer di id Tech 4 (`TIdLexer`) rifiuta ("more than one dot in number").

## Difetti del C emersi (non nel golden perche' indefiniti)

- `BotLoadCharacterFromFile`: il nome del file e' copiato con `strcpy` in 64 byte.
- `Characteristic_String` con `size <= 0` (`strncpy` con un conteggio negativo) manda in crash.
- `BotGetWeaponInfo` con il numero di arma uguale a `numweapons` (`BotValidWeaponNumber` controlla `>`) legge fuori dalla tabella: nel C legge il primo proiettile.
- `FreeWeightConfig` con `bot_reloadcharacters` acceso libera una configurazione che e' ancora in `weightFileList`: `BotShutdownWeights` la libera una seconda volta (crash).
- `LibVarStringValue("5.")` legge il carattere dopo il terminatore.
- `max_weaponinfo` e `max_projectileinfo` non sono mai negativi (`LibVarStringValue("-5")` e' 0): i due rami di `LoadWeaponConfig` che li riportano a 32 non si raggiungono con le variabili vere (il Delphi li prova con un finto che risponde -5).

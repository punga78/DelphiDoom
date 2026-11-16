# Salvataggi uguali a 32 e a 64 bit

Issue #40, sotto-issue #43 (punto "record scritti su disco"). Un salvataggio fatto da `Doom32.exe`, `Heretic32.exe`,
`Hexen32.exe` o `Strife32.exe` a 32 bit si carica con lo stesso programma a 64 bit e viceversa; il formato su disco e'
quello che il programma a 32 bit ha sempre scritto. Librerie: `Framework\Serializer` (`Framework\Serializer\CLAUDE.md`) e
`IdTech1\Parity` (le opzioni di prova); script: `Tools\Verifica\40`.

## 1. Che cosa c'era

Un salvataggio contiene due tipi di dati:

- **record scritti campo per campo** dal serializzatore (`Framework\Serializer`): i mobj, i settori, le linee, i lati. Il
  formato (numero del campo a 16 bit, valore) non dipende dalla macchina, con due eccezioni: `special1`/`special2`
  dei mobj di Heretic e Hexen (dalla #44 sono `NativeInt`, 8 byte a 64 bit, ma la tabella li dichiarava `st_integer`:
  si scrivevano i 4 byte bassi e al caricamento i 4 alti restavano quelli di prima, cosi' un -1 tornava 4294967295)
  e `customparams` (un blocco generico di `SizeOf(pointer)` byte: 4 a 32 bit, 8 a 64);
- **record scritti interi** (`memcpy` del record nel buffer): i giocatori (`player_t`), la traccia del giocatore, i
  parametri dei mobj, i thinker dei settori (porte, piattaforme, soffitti, pavimenti, luci, scorrimenti, script ACS,
  poliobj) e i record dei vecchi formati (`mobj_t113`... `mobj_t206`, `player_t114`...). Questi record hanno puntatori
  (`thinker_t` ne ha tre, poi `sector`, `line`, `mo`, `state`...): a 64 bit ogni puntatore e' 8 byte allineato a 8, il
  record e' piu' lungo e i campi stanno ad altri offset. Il programma a 64 bit scriveva quindi un file diverso e non
  leggeva quello a 32 bit.

Il significato dei puntatori nei record interi non cambia: il codice li trasforma gia' in numeri prima di scrivere
(indice del settore, della linea, dello stato; chiave del mobj; -1 per "nessuno") o li lascia come sono e li
ricostruisce al caricamento (`thinker.prev/next`, la funzione del thinker, `mo`, `attacker`: del valore scritto conta
al piu' se e' nil).

## 2. Che cosa c'e' ora

**Sul disco un record intero ha il layout che il compilatore a 32 bit gli da' in memoria**, chiunque lo scriva: un
puntatore e un `NativeInt` sono 4 byte allineati a 4, gli altri campi tengono dimensione e allineamento. A 32 bit il
record su disco e quello in memoria sono gli stessi byte (il record si copia intero, padding compreso, come prima); a
64 bit si converte.

- `TDiskLayoutBuilder` (`Framework\Serializer`) ricava il layout su disco di un record **dalle informazioni di tipo del
  compilatore** (RTTI): non c'e' una seconda dichiarazione dei record da tenere allineata a mano. Prima dimostra di
  aver capito il record ricalcolando il layout in memoria del programma che gira (offset e dimensione devono essere
  quelli del compilatore, altrimenti errore), poi applica le stesse regole con le dimensioni a 32 bit. A 32 bit il
  risultato deve essere l'identita', altrimenti errore.
- Un campo con un tipo senza nome (`psprites: array[0..NUMPSPRITES - 1] of pspdef_t`) non ha informazioni di tipo: se
  e' certo che sono byte semplici il costruttore lo copia com'e'; se contiene puntatori o precede un puntatore va
  descritto (`DescribeArray`). Le descrizioni e l'elenco dei record di ogni gioco sono in `P_DeclareSaveRecords`
  (`Doom\p_saveg.pas`, `Heretic\p_saveg.pas`, `Strife\p_saveg.pas`, `Hexen\sv_save.pas`), chiamata da
  `SV_InitializeSerializers`. Un campo incerto non descritto e' un errore che dice quale campo descrivere, mai un
  layout sbagliato in silenzio.
- Un valore largo come un puntatore va su disco coi 32 bit bassi e torna in memoria col segno (-1 resta -1, un
  indice resta l'indice); un indirizzo a 64 bit non nil con la meta' bassa a zero si scrive 1, cosi' chi lo legge lo
  vede ancora "non nil" (`TSerializerNativeValue`).
- Nel codice storico (`p_saveg`, `sv_save`) le `memcpy` sono diventate chiamate alla facciata `p_serializer`:
  `P_GetRecord`/`P_UnpackRecord` (leggere), `P_PutRecord`/`P_PackRecord` (scrivere), `P_ReserveRecord` +
  `P_CommitRecords` (il codice copia il thinker nel buffer e poi cambia i puntatori della copia: ora lavora su una
  copia in memoria che `P_CommitRecords` scrive al suo posto), `P_GetRecordPrefix`/`P_UnpackRecordPrefix` (un record di
  un formato vecchio letto sopra l'inizio del record di oggi: a 32 bit il vecchio e' un prefisso del nuovo, a 64 bit
  in memoria no, per esempio `special1: integer` diventato `NativeInt`).
- Nel serializzatore il tipo nuovo `st_nativeint` (`TSerializerFieldKind.NativeInteger`): 4 byte col segno nel
  flusso, la larghezza di un puntatore nel record. Lo usano `special1`, `special2` e `customparams`.

A 32 bit i byte scritti sono quelli di prima (verificato col riferimento, vedi sotto).

## 3. Come si prova

```
Tools\build.bat giochi Release both
powershell -NoProfile -File Tools\Verifica\40\Prova-Layout.ps1                      # i layout dei record, 32 contro 64 bit
powershell -NoProfile -File Tools\Verifica\40\Prova-Salvataggi.ps1 -RefExe "Doom=C:\rif\Doom32.exe;Heretic=...;Hexen=...;Strife=..."
```

Opzioni del motore (di `IdTech1\Parity`, inerti se non passate):

| Opzione | Cosa fa |
|---|---|
| `-autosave tic slot` | salva nello slot dopo quel tic (all'inizio del tic seguente, con lo stato della fine di quello) |
| `-savelayouts file` | scrive i layout su disco dei record dei salvataggi (dimensione, offset e dimensione di ogni campo, offset dei puntatori); non dice niente della memoria: 32 e 64 bit devono scrivere le stesse righe |
| `-autoquit tic` | il programma esce dopo quel tic (per un'esecuzione senza pilota, come una partita caricata) |
| `-loadgame slot` | (c'era gia') carica lo slot all'avvio; in Strife ora fa i passi del menu (`M_LoadSelect`) |

`Prova-Layout.ps1` lancia i due programmi di ogni gioco con `-savelayouts` e confronta le righe tra loro e con i
golden `Tests\Data\SaveLayout\<Gioco>.txt` (i layout del programma a 32 bit, cioe' il formato dei salvataggi: se
cambiano e' cambiato il formato).

`Prova-Salvataggi.ps1`, per ogni scenario di `Scenari.psd1` (un livello e un seme del pilota automatico):

1. **esplora**: gioca il livello col pilota e sceglie i tic dei salvataggi: quello con piu' thinker che non sono mobj
   (porte, piattaforme, luci, script ACS in corso), quello con piu' mobj (proiettili in volo), uno avanti nella partita;
2. **salva** a quel tic con ogni programma: 32 bit, 64 bit e, con `-RefExe`, il riferimento a 32 bit del codice di
   partenza (il commit che aggiunge solo le opzioni di prova); lo stato fino al salvataggio deve essere uguale nei tre;
3. **confronta i file** byte per byte (32 contro 64, riferimento contro 32); gli offset diversi vanno in
   `<WorkRoot>\<Gioco>\store\<scenario>\<tic>\differenze.txt`;
4. **carica** il salvataggio di ogni scrittore con ogni lettore (`-loadgame slot -autoquit 300 -statehash`) e lascia andare
   il mondo per 300 tic col giocatore fermo: tutte le combinazioni devono dare le stesse righe (32<-32, 32<-64, 64<-32,
   64<-64; col riferimento anche 64<-riferimento e riferimento<-64; tutte e nove con `-AllLoads`; il riferimento non
   ha `-autoquit` e lo script lo chiude quando il log ha abbastanza righe). In piu' il tempo del livello, settori,
   lati, linee, numero di thinker e di mobj al primo tic dopo il caricamento devono essere quelli che il programma
   che ha salvato aveva un tic dopo. `-LoadPilot` fa giocare il pilota anche dopo il caricamento (in Hexen non
   funziona: `-loadgame` con `-autodemo` chiude il programma, anche col codice di partenza).

`-NoLock` lancia i giochi senza il lock globale di `Tools\Esegui-gioco.ps1` (una esecuzione per volta comunque): serve
su una macchina carica, dove il lock fa aspettare minuti a ogni esecuzione; con le opzioni di parita' l'orologio e'
virtuale e il carico non cambia il risultato.

Altri due script: `Prova-Esistenti.ps1` (una copia di salvataggi gia' fatti caricata da ogni programma) e
`Confronta-Stato.ps1` (i golden di stato della parita', `Tests\Data\Parity`, senza il lock; a 640x480 come i golden,
perche' il renderer segna le linee viste e l'impronta delle linee dipende da cio' che si vede).

## 4. Risultati (2026-11-14)

Eseguibili: `Tools\build.bat giochi Release both` del ramo; riferimento = gli eseguibili Win32 del commit che aggiunge
solo `-autosave` (`bc21e033`). Comando: `Prova-Salvataggi.ps1 -Game <gioco> -Picks 2 -NoLock -RefExe ...`, 6 caricamenti
per stato, 300 tic dopo il caricamento.

| Gioco | Stati | Livelli | Caricamenti | Tutti uguali | Mondo uguale al tic dopo il salvataggio | Thinker di settore (max) | Mobj (max) |
|---|---|---|---|---|---|---|---|
| Doom | 8 | E1M1, E1M3 (DOOM1), MAP02, MAP07 (Freedoom 2) | 48 | 8 su 8 | 8 | 13 | 277 |
| Heretic | 6 | E1M1, E1M3, E1M6 | 36 | 6 su 6 | 6 | 19 | 428 |
| Hexen | 8 | MAP01..MAP04 (tre classi) | 48 | 7 su 8 (l'ottavo: vedi sotto) | 6 | 21 | 468 |
| Strife | 6 | MAP32, MAP33, MAP34 | 36 | 6 su 6 | 6 | 6 | 391 |

- **Lo stato prima del salvataggio** e' uguale nei tre programmi in tutti i 28 stati.
- **Hexen, MAP03 al tic 34 (una sequenza sonora attiva): due difetti del codice di partenza, corretti.** Alla prima
  campagna il programma usciva dopo il primo tic in 4 caricamenti su 6, anche il riferimento col proprio
  salvataggio. (1) `ArchiveSounds` cercava il poliobj del suono con un `for` che, senza poliobj nella mappa, non
  gira e lascia l'indice a caso: il suono di un settore si salvava come "suono del poliobj numero a caso" (nel file
  del riferimento: tipo 1, numero 19404436) e il caricamento leggeva `polyobjs[]` fuori dai limiti; (2)
  `S_GetSequenceOffset` faceva `integer(puntatore)`: a 64 bit lo scostamento salvato era spazzatura (3221225476
  invece di 4). Ora un `while`, `NativeInt`, e `UnarchiveSounds` salta con un avviso una sequenza con un numero
  fuori dai limiti (un salvataggio fatto prima della correzione si carica senza quel suono). Rifatta la campagna di
  Hexen: in quello stato i 4 incroci tra 32 e 64 bit e il riferimento che legge il 64 bit sono uguali per 300 tic;
  resta diverso (indice del casuale di presentazione, dal tic 1) solo il 64 bit che legge il file del riferimento,
  che ha il suono sbagliato, e i byte del 32 bit nuovo differiscono da quelli del riferimento in quei due campi:
  sono le due differenze volute. Gli altri 7 stati come prima. I due "mondo diverso" di Hexen
  (MAP01 al tic 399: settori; MAP02 al tic 34: numero di thinker e di mobj) sono il limite di quel controllo: chi ha
  salvato ha giocato il tic seguente col pilota (un colpo sparato, una porta usata), chi carica sta fermo; i 6
  caricamenti di quegli stati sono uguali tra loro.
- **Byte per byte**: i file di 32 e 64 bit hanno sempre la stessa dimensione e **non sono mai uguali**: differiscono
  da 8 a 482 byte per stato, tutti in posti da 4 byte che sono indirizzi di memoria del programma che ha salvato e
  che il caricamento ignora o usa solo come "nil o no": i tre puntatori di `thinker_t` di ogni thinker di settore
  (12 byte per thinker) e `player_t.mo`. Per farli uguali bisognerebbe azzerarli, cioe' cambiare anche cio' che
  scrive il programma a 32 bit; non fatto, perche' la funzione del thinker conta come "nil o no" (un soffitto fermo)
  e il formato deve restare quello di prima.
- **Il programma a 32 bit scrive i byte di prima**: riferimento contro 32 bit nuovo, stessa dimensione e differenze
  (da 5 a 388 byte) solo negli stessi posti da 4 byte che cambiano anche tra 32 e 64 bit, in tutti i 28 stati (sono
  indirizzi: cambiano da un eseguibile all'altro).
- **Col pilota anche dopo il caricamento** (prima versione dello script, Doom E1M1, tic 225, 599 e 1272): 27
  caricamenti (9 per stato, riferimento compreso) uguali per 300 tic.
- **Salvataggi che esistevano gia'** (`Prova-Esistenti.ps1`, copie di `bin\Hexen\HEXNDATA` dell'11 novembre e di
  `bin\Strife\strfsav0.ssg` del 9 novembre, versione 207): Hexen slot 9 (MAP02, 15 thinker di settore, 388 mobj) e
  Strife slot 0 (MAP32) si caricano con 32 bit, 64 bit e riferimento con le stesse righe per 300 tic. Di Doom e
  Heretic non c'erano salvataggi; di nessun gioco c'erano salvataggi di una versione vecchia del formato.
- **Senza opzioni di prova** (la memoria non e' azzerata come con le opzioni di parita'): il programma a 64 bit che
  carica un salvataggio del 32 bit resta in gioco 20 secondi senza `crash.txt` in Hexen (MAP02), Strife (MAP34) e
  Heretic (E1M6), e il 32 bit con un salvataggio del 64 bit in Heretic. E' servito: le tabelle di Hexen dichiaravano
  `state`, `target`, `tracer`, `master` e `player` come interi da 4 byte su campi puntatore, quindi a 64 bit la meta'
  alta restava quella della memoria appena allocata (ora `st_nativeint`).
- **Layout** (`Prova-Layout.ps1`): 32 e 64 bit scrivono le stesse righe e sono uguali ai golden: Doom 42 record,
  Heretic 30, Hexen 24, Strife 34.
- **Golden di stato della parita'** (`Confronta-Stato.ps1`, Win32, modo 8): 44 voci su 44 uguali (Doom 21, Heretic 9,
  Hexen 8, Strife 6).

## 5. Che cosa non e' provato

- I formati vecchi dei salvataggi (nessun file con cui provarli): il codice passa dagli stessi layout, i record
  vecchi sono nei golden dei layout.
- Poliobj in movimento (nessuna mappa di MAP01-04 di Hexen ne ha), dialoghi di Strife, porte scorrevoli di Strife in
  movimento al momento del salvataggio (il difetto corretto non e' stato esercitato a runtime), script PascalScript
  di mappa, overlay e variabili globali non vuoti, piu' giocatori.
- Gli eseguibili OpenGL (usano lo stesso codice dei salvataggi; compilano, non avviati).
- Il caricamento a mano dal menu (le prove usano `-loadgame`).

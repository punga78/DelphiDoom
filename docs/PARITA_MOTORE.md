# Parita' del motore: come si usano gli strumenti

Issue #185, fase 0 del piano `docs\PIANO_TUTTO_A_CLASSI.md`. Prima di riscrivere logica o renderer di un gioco si registra come si comporta oggi (**golden**); dopo ogni passo si rilancia il confronto: dice se qualcosa e' cambiato, **dove** (gioco, demo, tic, oggetto, campo, pixel) e **quanto costa** in tempo. Le librerie sono in `Libs\Parity` (`Libs\Parity\CLAUDE.md`), gli script in `Tools\Verifica\185` e `Tools\Misura-Coppie.ps1`.

## 1. Che cosa c'e'

| Strumento | Opzione o script | Cosa dice |
|---|---|---|
| Impronta dello stato | `-statehash file` | una riga per tic: hash di mobj (nell'ordine dei thinker), settori, lati, linee, giocatori e, in chiaro, `leveltime`, thinker, mobj, indici del casuale, posizione e salute del primo giocatore |
| Dettaglio dello stato | `-statehash-detail primo ultimo` | per i tic dell'intervallo il valore di ogni campo (`D tic categoria indice campo valore`) |
| Impronta del fotogramma | `-framehash file` | per ogni fotogramma (prima della presentazione) hash della vista 3D, del resto (bordo, HUD, menu) e dell'insieme; modi a 8 bit (indici + tavolozza) e a 32 bit |
| Fotogramma in un file | `-framedump tic file` | il primo fotogramma dal tic dato come BMP a 32 bit |
| Pilota automatico | `-autodemo seme tic` | genera i ticcmd (corsa, curve, passi laterali, sparo, uso, cambio arma, uscita dagli angoli) con un generatore proprio, senza toccare quello del gioco; con `-record` scrive la demo |
| Copione di comandi | `-autoscript file` | il primo giocatore fa cio' che dice un file di testo (tasti tenuti per N tic, "vai al punto x y", "guarda il punto", "sali alla quota"): stesso punto d'ingresso del pilota automatico, per percorrere un livello di cui si conosce la strada (vedi 2 bis) |
| Corpus | `Tools\Verifica\185\Corpus.psd1` | le demo interne dei WAD e quelle del pilota, per i quattro giochi |
| Golden | `Registra-Golden.ps1`, `Confronta-Golden.ps1` | le impronte del codice di partenza, compresse, in `Tests\Data\Parity\<Gioco>\` e il confronto |
| Rumore zero | `Rumore-Zero.ps1` | due esecuzioni dello stesso eseguibile devono dare impronte uguali |
| Misura a coppie | `Tools\Misura-Coppie.ps1` | vecchio contro nuovo, alternati, con rifiuto della misura non affidabile |

**Inerti se spenti.** Senza opzioni il motore non costruisce niente: l'unico costo e' il controllo di un puntatore a interfaccia (`parity_hooks`) in `P_Ticker`, in `D_FinishUpdate` e in `BuildTicCmd`.

**Con un'opzione accesa l'esecuzione e' ripetibile**: orologio virtuale (un tic a ogni fine fotogramma, wipe compreso), tastiera, mouse e joystick chiusi, numeri casuali "imprevedibili" (`I_Random` del wipe) con seme fisso, nessuna finestra di errore. In piu' serve una configurazione fissa: gli script passano `-config p8.ini` o `p32.ini` (640x480, `detaillevel=2` a 8 bit o `3` a 32 bit, `usemultithread=0`, niente interpolazione); **i fili del renderer danno pixel diversi tra due esecuzioni**, quindi le impronte dei fotogrammi si confrontano solo con `usemultithread=0`. Le demo si riproducono con `-timedemo` (un fotogramma per tic) e `-noblit` (la presentazione e' legata al vsync).

## 2. Registrare

```
powershell -NoProfile -File Tools\Verifica\185\Registra-Demo.ps1  -Name 'a_*'      # le demo del pilota (una volta)
powershell -NoProfile -File Tools\Verifica\185\Registra-Golden.ps1 -Exe "Doom=C:\...\Doom32.exe;Heretic=...;Hexen=...;Strife=..."
```

I golden si registrano **con un eseguibile del codice di partenza** (il commit prima della fase che si sta per fare, piu' gli strumenti), mai con quello che si vuole provare; conservare quell'eseguibile come riferimento (serve a `-RefExe`). I WAD non sono nel repository: gli script li prendono da `-DataRoot` (predefinito: `bin` del repository principale). Cartella di lavoro: `-WorkRoot` (predefinita `C:\ddparity`: stesso percorso su ogni macchina, perche' la lunghezza degli argomenti puo' spostare i blocchi di memoria, vedi i limiti). Le demo del pilota stanno in `Tests\Data\Parity\<Gioco>\*.lmp` (solo ticcmd, nessun dato del gioco); servono il WAD e la mappa di `Corpus.psd1`.

## 2 bis. Copione di comandi (`-autoscript file`)

Il pilota automatico non sa la strada: per attraversare un livello (aprire una porta con un trigger, raggiungere i nemici, arrivare all'uscita) si scrive un copione. `-autoscript file` usa lo stesso punto d'ingresso di `-autodemo` (il comando entra nel `ticcmd` in `BuildTicCmd`, con tastiera e mouse chiusi e orologio virtuale) e non si puo' usare insieme a lui; con `-record` la partita diventa una demo. Alla fine del copione il gioco si chiude come con `-autodemo` (con `-record` e' l'`I_Error` "Demo ... recorded").

Un passo per riga, parole separate da spazi, maiuscole indifferenti, `#` apre un commento. Le coordinate sono unita' di mappa (quelle di `px`/`py` di `-statehash`).

| Passo | Cosa fa |
|---|---|
| `hold tic [forward n] [back n] [side n] [turn n] [look n] [center] [fire] [use] [jump] [crouch] [weapon n] [afterburner] [bomb]` | tiene premuti quei tasti per `tic` tic. `forward`/`back` 0..50, `side` -40..40 (positivo = destra), `turn` -5..5 passi da 256/65536 di giro a tic (1,4 gradi; positivo = sinistra), `look` -7..7 (positivo = su; serve `zaxisshift=1`), `center` riporta lo sguardo all'orizzonte, `weapon` 1..8 (chiesta al primo tic), `use` premuto un tic ogni 6, `jump`/`crouch` a ogni tic (in Radix sono "vola su"/"vola giu'"); `afterburner` e `bomb` sono i due tasti "di un gioco" (i bit liberi `CMD_GAMEKEY1_MASK`/`CMD_GAMEKEY2_MASK` di `jump_crouch`: in Radix postbruciatore e bomba al plasma, negli altri giochi niente); `bomb` e' premuto solo al primo tic del passo |
| `goto x y [z quota] [radius n] [speed n] [timeout tic] [fire] [use] [fight] [range n] [afterburner]` | gira verso il punto (al massimo 5 passi a tic) e spinge avanti quando il punto e' entro 22,5 gradi dal muso; finisce entro `radius` (48) dal punto; con `z` preme `jump`/`crouch` per tenere la quota (tolleranza 8); con `fight` si ferma a combattere i nemici in vista entro `range` (1200) e poi riprende |
| `face x y [timeout tic] [fire]` | gira verso il punto senza muoversi; finisce quando e' allineato |
| `climb quota [timeout tic]` | `jump` o `crouch` fino alla quota (tolleranza 8) |
| `hunt tic [range n]` | combatte il nemico in vista piu' vicino; finisce dopo 20 tic senza nemici o dopo `tic` tic (non e' una rinuncia) |
| `heal salute tic [range n]` | aspetta (combattendo chi si avvicina) che la salute torni almeno a `salute`, al massimo per `tic` tic (in Radix lo scudo si rigenera da solo) |
| `save slot`, `load slot` | salva la partita nello slot (0..5, quelli dei menu) o la carica. Non occupano un tic: la richiesta parte insieme al comando del passo seguente e il gioco salva o carica tra due tic (il salvataggio due tic dopo, come dal menu: un tic con i bottoni speciali, nel quale i tasti del pilota sono persi ma i movimenti no). **Solo nei giochi che danno le loro routine** a `TEngineParityPilotCommand.ConfigureSaveGames` (oggi Radix; negli altri i due passi non fanno niente) e **non con `-record`** (una demo toglie i bottoni speciali). Un `save` in fondo al copione non fa in tempo: mettere un `hold` dopo |
| `key codice` | un tasto del motore (il suo codice: 27 esc, 13 invio, 127 backspace, 172..175 sinistra, su, destra, giu', le lettere minuscole in ASCII) va giu' e su come due eventi della coda del gioco (`D_PostEvent`): un tic. Serve per i menu, che la tastiera chiusa non raggiunge; il copione gira solo dentro un livello (il giocatore deve esistere) |
| `shot numero` | il fotogramma che segue e' scritto come `<copione>.<numero>.bmp` (1..999): un tic. I menu fermano i tic del gioco, quindi `-framedump` non li puo' chiedere |

**Radix**: con uno strumento acceso il briefing della missione non parte (un copione vola il livello come una demo); `-briefing` lo fa partire (i passi `hold ... fire`/`use` lo fanno avanzare). `-radixendlevel tic next` fa finire il livello a quel tic come dalla sua uscita (`next`: 0 il livello dopo, -1 la fine dell'episodio, un numero quel livello).

**Menu**: `key 27`, `hold 4`, `shot 1` apre il menu principale e lo fotografa; mettere un `hold` di qualche tic dopo ogni `key` (l'evento e' letto al giro dopo). Esempio: i menu di Radix in `Libs\Radix\CLAUDE.md`.

**Salva in una esecuzione, carica in un'altra**: per avere le stesse righe nelle due esecuzioni dopo il caricamento, nel copione che salva mettere `save 0` e poi `hold 3`, in quello che carica `hold 10`, `load 0`, `hold 2` e poi gli stessi passi (il gioco salvato ha gia' fatto due dei tre tic fermi; il caricato fa il terzo). Esempio: `Tests\Data\Parity\Radix\e1m1_save.script` e `e1m1_load.script`.

**Combattere** (`fight`, `hunt`, `heal`): il motore dice al pilota il mostro vivo piu' vicino entro il raggio che il giocatore vede (`MF_COUNTKILL`, `P_CheckSight`: la ricerca si fa solo se il copione ha un passo che combatte, mai per `-autodemo`); il pilota gira verso di lui, spara quando e' entro 5,6 gradi dal muso, si mette alla sua quota (`jump`/`crouch`), si sposta di lato 16 tic di qua e 16 di la', si avvicina se e' oltre 900 unita' (la mira automatica del gioco arriva a 1024) e arretra sotto 300.

`goto`, `face` e `climb` guardano la posizione del giocatore: se non arrivano entro `timeout` tic (700 se non detto) **il copione rinuncia e il gioco si chiude** (meglio fermarsi che proseguire da un posto sbagliato); lo stesso se il giocatore muore. Accanto al copione il pilota scrive `<file>.log`: una riga per ogni passo finito (`line 12 goto: done at tic 345 after 80 tics, player at -13538 -683 576`), `GAVE UP`, `THE PLAYER DIED`, `script complete at tic N`. Non ci sono numeri casuali: lo stesso copione sullo stesso eseguibile da' la stessa partita.

```
# Radix E1M1: dalla partenza alla porta B
goto -13500 -684          # la cella del trigger apre la porta
hold 70                   # la porta sale
goto -12900 -684 fire
```

```
Radix32.exe -warp 1 1 -skill 2 -record prova -autoscript C:\ddpar169\e1m1.script -statehash C:\ddpar169\s.txt -framedump 500 C:\ddpar169\f.bmp
```

Un copione intero: `Tests\Data\Parity\Radix\e1m1.script` porta la navetta dall'hangar alla fine di E1M1 di Radix 2.0 shareware (circa 10000 tic), passa il debriefing e entra in E1M2. Per trovare la strada di un livello di Radix: `Tools\Verifica\169\RadixMapDump` (cose con quota e numero, linee, settori, `RMAP`, azioni, trigger, celle della griglia con il loro posto nella mappa) e `px`/`py` di `-statehash`.

## 3. Confrontare e localizzare una differenza

```
powershell -NoProfile -File Tools\Verifica\185\Confronta-Golden.ps1 [-Game Doom] [-Name 'd1_*'] [-Modes 8,32] `
   -Exe "Doom=<nuovo>\Doom32.exe" -RefExe "Doom=<riferimento>\Doom32.exe"
```

Per ogni voce e modo stampa `UGUALE` o la prima differenza. Con `-RefExe` la localizza da sola.

**Altra configurazione (`-ExtraIni`).** I golden valgono per la configurazione fissa degli strumenti (`drawfps=0`, `screenblocks=10`...). Per coprire i rami che quella configurazione non esercita (contatore FPS, mirino, vista ridotta, avanzamento della demo, statistiche dell'automap...) si confrontano **vecchio e nuovo tra loro**, senza golden:

```
powershell -NoProfile -File Tools\Verifica\185\Confronta-Golden.ps1 -Modes 8 -ExtraIni 'drawfps=1;drawcrosshair=1;screenblocks=8' `
   -Exe "Doom=<nuovo>\Doom32.exe" -RefExe "Doom=<riferimento>\Doom32.exe"
```

Le chiavi `chiave=valore` (separate da `;`) sostituiscono quelle di partenza o si aggiungono; `-RefExe` e' obbligatorio. Con `-ExtraArgs '-file x.wad'` (o `-deh x.deh`) si danno argomenti in piu' a entrambi gli eseguibili, per caricare ACTORDEF e DEHACKED di prova (fetta 1b, `Tools\Verifica\185\Fetta-1b.txt`; anche li' `-RefExe` e' obbligatorio). Un solo modo per invocazione quando si usa `powershell -File` (la virgola di `-Modes 8,32` non separa). Esempi reali (le quattro modifiche finte di sotto):

**1. Un tic di ritardo su una porta** (`Libs\Thinkers\DelphiDoom.Thinkers.Door.Runner.pas`: `TopCountdown := TopWait + 1`), demo `d1_demo1`, modo 8:

```
Doom  d1_demo1  modo  8 : STATO DIFFERENT at line 274 (tic 272): total,rnd | expected: T 272 b210ee27f6e2ce00 mobj=c7265520 ... rnd=44 prnd=24 | actual: T 272 1f75708b18388782 ... rnd=45 ...
      localizzazione: DIFFERENT at line 31696 (tic 272): total,rnd ...
Doom  d1_demo1  modo  8 : FOTOGRAMMA DIFFERENT at line 1738 (tic 1695): full,view ...
      localizzazione: fotogramma del tic 1695: 827 pixel diversi, il primo in (532,148), contenuti in x 421..532 y 148..170
```

La prima differenza e' al tic 272 (il numero casuale "di presentazione" cambia perche' il suono della porta parte un tic dopo) e poi nel fotogramma del tic 1695 (la porta si vede). L'impronta dei settori cambia quando la porta si muove.

**2. Un'unita' di differenza nella gravita' dei mostri** (`Doom\p_mobj.pas`: `grav := grav + 1` se `MF_COUNTKILL`):

```
Doom  d1_demo1  modo  8 : STATO DIFFERENT at line 3562 (tic 3560): total,mobj | ...
      localizzazione: DIFFERENT at line 19370 (tic 3560): mobj 10 momz | expected: D 3560 mobj 10 momz -131072 | actual: D 3560 mobj 10 momz -131074
Doom  d1_demo1  modo  8 : FOTOGRAMMA DIFFERENT at line 3605 (tic 3562): full,view ...
      localizzazione: fotogramma del tic 3562: 4 pixel diversi, il primo in (333,201), contenuti in x 333..336 y 201..201
```

Al tic giusto, sul mobj giusto (il decimo della lista dei thinker), nel campo giusto (`momz`).

**3. Un `P_Random()` in piu' in `A_Chase`** (`Doom\p_enemy.pas`):

```
Doom  d1_demo1  modo  8 : STATO DIFFERENT at line 49 (tic 47): total,prnd | ... prnd=137 | ...
      localizzazione: DIFFERENT at line 31771 (tic 47): total,prnd ...
Doom  d1_demo1  modo  8 : FOTOGRAMMA DIFFERENT at line 115 (tic 72): full,view ...
      localizzazione: fotogramma del tic 72: 2510 pixel diversi, il primo in (548,182), contenuti in x 534..576 y 182..285
```

L'indice del generatore del gioco (`prnd`) cambia al primo mostro che insegue: tic 47.

**4. Un pixel diverso nella colonna di un muro** (`Base\r_batchcolumn.pas`: un pixel in (150,100) con `xor 1` dopo `R_DrawColumnMedium_Batch`):

```
Doom  d1_demo1  modo  8 : FOTOGRAMMA DIFFERENT at line 1021 (tic 978): full,view | ...
      localizzazione: fotogramma del tic 978: 1 pixel diversi, il primo in (150,100), contenuti in x 150..150 y 100..100 (file: C:\ddparity\Doom\dump_ref.bmp e dump_new.bmp)
```

Lo stato non cambia (nessuna riga `STATO`): e' un difetto del solo renderer, visto dal fotogramma (l'impronta `view`, non `hud`) e localizzato al pixel; i due BMP si aprono per vedere la differenza.

**Con le mani**, senza `-RefExe`: `ParityTool.exe compare golden.state.gz mio.state.txt` dice la prima riga diversa; si rilancia il gioco con `-statehash-detail primo ultimo` (e lo stesso con l'eseguibile di riferimento) e `ParityTool.exe compare` sui due file dice categoria, indice e campo; per un fotogramma `-framedump tic file.bmp` sui due eseguibili.

## 4. Misurare

```
powershell -NoProfile -File Tools\Misura-Coppie.ps1 -Vecchio <exe> -Nuovo <exe> -Demo demo1 -Iwad DOOM1.WAD -Coppie 5
```

Alterna vecchio e nuovo (ordine invertito a ogni coppia), un'esecuzione per volta con `Tools\Esegui-gioco.ps1`, con la configurazione fissa e l'orologio vero (nessuna opzione degli strumenti), e riporta minimo, mediana, media e dispersione `(max-min)/min` in tic reali, la differenza percentuale di mediane e minimi e il verdetto "entro il 5%" / "oltre il 5%". **Rifiuta il verdetto** ("misura non affidabile", codice di uscita 3) se la dispersione del vecchio supera `-MaxDispersione` (3%) o se ci sono altri processi pesanti (compilatore, altri giochi) o la CPU e' occupata. Misurare a macchina scarica.

## 5. Limiti noti

- **Solo software.** Impronte dei fotogrammi e `-framedump` sono per i renderer software (8 e 32 bit); negli eseguibili OpenGL dicono "non supportato" e restano il registratore delle chiamate GL (`Libs\OpenGl\Recorder`) e i suoi script. Lo stato, l'orologio, l'input e il pilota funzionano anche li' (non provato a runtime negli eseguibili GL: compilano).
- **I fili.** Le impronte dei fotogrammi valgono solo con `usemultithread=0` (la configurazione fissa lo imposta). Con i fili accesi due esecuzioni danno pixel diversi (provato: con la configurazione di partenza, a 1920x1080 e con i fili accesi, 86 fotogrammi su 5070 di `d1_demo1` erano diversi tra due esecuzioni, per qualche pixel con il canale verde di una unita' in piu' o in meno).
- **Memoria.** Il motore legge a volte memoria che non ha scritto o che e' oltre la fine di un buffer, e un `tracer`/`target` puo' restare puntato a un mobj liberato. Con un'opzione accesa le allocazioni partono da zero con 512 byte di zeri in coda e i riferimenti si controllano con la `key` del mobj (vedi `Libs\Parity\CLAUDE.md`); senza queste misure due esecuzioni dello stesso eseguibile davano impronte diverse in 5 voci su 88. Residuo: un indirizzo in `special1`/`special2` di Heretic o Hexen che non e' un mobj vivo si hasha com'e'.
- **Percorsi.** Gli script usano `C:\ddparity` come cartella di lavoro (stesso percorso su ogni macchina) e nomi fissi per i log (`ps.txt`, `pf.txt`): la riga di comando fa parte dell'ambiente in cui gira il motore.
- **Demo interne.** Quelle di Heretic (versione 0.03), Hexen (0.02) e Strife non sono riproducibili dal motore ("Demo is from an unsupported game version"): nel corpus ci sono solo quelle di Doom e Freedoom 2, piu' le demo del pilota. Le demo del pilota di Hexen e Strife finiscono presto quando il giocatore muore (la registrazione si chiude o il motore la prosegue da un altro livello): i tic sono in `Tests\Data\Parity\<Gioco>\golden.csv`.
- **Rami non coperti dal corpus**: 3D floor (nessun livello dei cinque WAD li usa: sono di UDMF), poliobj (nessuna mappa di Hexen MAP01-04 ha un `PO_ANCHOR`/`PO_SPAWN`: `po_man` non e' esercitato), dialoghi di Strife (il pilota non parla con i personaggi: `p_dialog` non e' esercitato), script ACS di Hexen avviati da linee (solo gli script `OPEN` dei `BEHAVIOR` di MAP01-04 girano al caricamento; gli altri se il pilota passa sulla linea giusta: non misurato), salvataggi, rete e multigiocatore (le demo sono a un giocatore), UDMF, DECORATE/ACTORDEF con mappe proprie, difficolta' 4 e 5 (il pilota muore subito: le demo usano le difficolta' 1-3), modi video diversi da 640x480 (8 bit con `detaillevel=2`, 32 bit con `3`; `-detaillevel` 4 e 5 e le altre risoluzioni non provati), automap e menu aperti.

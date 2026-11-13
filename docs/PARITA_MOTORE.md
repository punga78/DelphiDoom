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

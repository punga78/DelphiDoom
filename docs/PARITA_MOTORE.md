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

I golden si registrano **con un eseguibile del codice di partenza** (il commit prima della fase che si sta per fare, piu' gli strumenti), mai con quello che si vuole provare; conservare quell'eseguibile come riferimento (serve a `-RefExe`). I WAD non sono nel repository: gli script li prendono da `-DataRoot` (predefinito: `bin` del repository principale). Cartella di lavoro: `-WorkRoot` (predefinita `%TEMP%\ddparity`). Le demo del pilota stanno in `Tests\Data\Parity\<Gioco>\*.lmp` (solo ticcmd, nessun dato del gioco); servono il WAD e la mappa di `Corpus.psd1`.

## 3. Confrontare e localizzare una differenza

```
powershell -NoProfile -File Tools\Verifica\185\Confronta-Golden.ps1 [-Game Doom] [-Name 'd1_*'] [-Modes 8,32] `
   -Exe "Doom=<nuovo>\Doom32.exe" -RefExe "Doom=<riferimento>\Doom32.exe"
```

Per ogni voce e modo stampa `UGUALE` o la prima differenza. Con `-RefExe` la localizza da sola. Esempi reali (le quattro modifiche finte di sotto):

SEGUONO_ESEMPI

## 4. Misurare

```
powershell -NoProfile -File Tools\Misura-Coppie.ps1 -Vecchio <exe> -Nuovo <exe> -Demo demo1 -Iwad DOOM1.WAD -Coppie 5
```

Alterna vecchio e nuovo (ordine invertito a ogni coppia), un'esecuzione per volta con `Tools\Esegui-gioco.ps1`, con la configurazione fissa e l'orologio vero (nessuna opzione degli strumenti), e riporta minimo, mediana, media e dispersione `(max-min)/min` in tic reali, la differenza percentuale di mediane e minimi e il verdetto "entro il 5%" / "oltre il 5%". **Rifiuta il verdetto** ("misura non affidabile", codice di uscita 3) se la dispersione del vecchio supera `-MaxDispersione` (3%) o se ci sono altri processi pesanti (compilatore, altri giochi) o la CPU e' occupata. Misurare a macchina scarica.

## 5. Limiti noti

SEGUONO_LIMITI

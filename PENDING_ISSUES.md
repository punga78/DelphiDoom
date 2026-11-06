# Attività in sospeso

Registro delle issue non completate. Si aggiorna quando una issue viene saltata, quando emergono nuove informazioni e si svuota quando la issue è chiusa.

## Limiti noti del decoder Pascal rispetto al C (non bloccanti)

Il C è stato cancellato (ultimo commit che lo contiene: `a449cacd`). Queste differenze restano documentate in `CLAUDE.md`:

- **Non portati**: ALAC dentro CAF (nessun file di prova nel repository e l'encoder del C andava in access violation), Vorbis con floor di tipo 0 (nessun encoder lo produce), FLAC/Speex/PCM dentro Ogg, scrittura di qualsiasi formato, PVF, NIST, DWD, TXW, REX2 (nel C falliscono sempre). Se serve uno di questi: portarlo da `a449cacd`, costruire i file di prova in memoria e aggiungere gli scenari a `Tests\Data\sound_golden.txt`.
- Vorbis: un `Seek` oltre i dati decodificabili si ferma alla fine dei dati (come il C), ma non si emulano le letture a pezzi di un flusso in catena.
- FLAC: una lettura singola che attraversa un resync e la fine del suono perde l'ultimo frame nel C e non nel Pascal (coperto a pezzi).
- PAF a 24 bit e SDS: il C azzerava l'ultimo pacchetto dopo un `Seek` o a cavallo di due letture (difetto del C), il Pascal no.
- Tag ID3v2: dopo il tag si apre solo FLAC (WAV, AIFF e AU fallivano anche nel C di questa versione).
- Il test di parità non può più generare nuove risposte "dal C": i valori in `Tests\Data\sound_golden.txt` sono fissi.

## #12 — chiusa

Fatta: DD_IDE usa `System.ZLib` (tolti `zlibpas.pas` e i `.obj`), cancellati `C_LIB`, `Libs\Sndfile\Native`, `AUDIOLIB`, `MP3LIB`, `XMILIB`, `MIKWIN` e l'unica unit orfana. `ZLIB` (`z_files.pas`), `JPEGLIB`, `SCRIPT` e `FASTCODE` restano perché referenziate. Prova a runtime: Doom, Heretic, Hexen e Strife girano 25 s senza crash né `I_Error` (shareware: i warning sulle patch mancanti sono normali). Non ho potuto ascoltare l'audio.

## #1 — Porting a Delphi 11 (XE11) e build da riga di comando

- **Stato**: issue contenitore ("Stato": Heretic con crash dopo il caricamento del livello, circa 900 warning di conversione tra stringhe). Non è chiudibile dal lavoro sul suono.
- **Domanda per una persona**: va chiusa quando #12 è finita, o resta aperta per i warning e il crash di Heretic?

## #46 — Libreria Libs\Wad (in corso)

- **Fatto**:
  - Passo 1: `Libs\Wad` (sorgenti WAD, PAK, PK3, cartella, file singolo; directory con precedenza dell'ultimo lump; ricerca per nome con flag dei marcatori e per intervallo; cache; `IWadBuilder`; record dei lump di livello). 81 test, anche sui WAD reali.
  - Passo 2 (parziale): `Base\w_wad.pas` usa la libreria per la directory. `W_AddFile`, `W_RuntimeLoad` e `W_Reload` costruiscono le sorgenti con `TWadFileSource`/`TSingleFileSource` sopra un adattatore degli stream del motore; `lumpinfo[]` è una vista di sola lettura rifatta da `W_SyncLumpInfo`; `W_CheckNumForName`, `W_CheckFirstNumForName` e `W_CheckNumForName2` chiamano il finder; sono spariti la tabella hash e i 38 marcatori duplicati. Verificato: `lumpinfo[]` (nome, posizione, dimensione, flag, handle) identico al vecchio codice per Doom, Heretic, Hexen e Strife, e per Doom con due WAD caricati a runtime; i giochi girano fino al livello (`-warp`); `W_Reload` esercitato con un file `~`.
  - Difetto del vecchio codice non riprodotto: caricare due volte a runtime lo stesso WAD con lo stesso numero di lump liberava più volte lo stesso stream (il gioco si fermava). Ora si sostituisce la sorgente e si libera lo stream una volta; non l'ho provato nel gioco (nessun percorso lo raggiunge nelle prove fatte).
- **Manca**:
  1. La lettura dei byte dei lump dalla libreria (`W_ReadLump` legge ancora da `lumpinfo[].handle`, `position`, `size`) e la cache di `ILumpCache` al posto dello zone memory (`lumpcache[]`, tag `PU_STATIC`/`PU_CACHE`): è la parte con più rischio.
  2. Passare i chiamanti da `lumpinfo[]` (32 accessi in `nd_main`, `p_setup`, `p_udmf`, `r_data`, `r_things`, `s_externalmusic`) all'interfaccia, poi cancellare la facciata.
  3. PAK e cartelle: `w_pak.pas`, `w_wadreader.pas`, `w_wadwriter.pas` non usano ancora `Libs\Wad` (scrittura dal motore e dagli strumenti `ddc*`, DD_IDE).
  4. Contratto attraverso una DLL (solo buffer e interi): oggi le interfacce usano `TBytes` e `string`.
  5. Build a 64 bit (#40).
- **Domanda per una persona**: nessuna per ora.
- **Prossima azione**: leggere i byte dei lump attraverso `IWadDirectory` mantenendo gli stream del motore (reload e `OnBeginBusy`), poi i chiamanti di `lumpinfo[]` uno alla volta.
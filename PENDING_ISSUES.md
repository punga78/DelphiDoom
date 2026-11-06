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

- **Fatto (passo 1)**: `Libs\Wad` con lettura di WAD, PAK, ZIP, cartelle e file singoli, directory con precedenza dell'ultimo lump, ricerca per nome con flag dei marcatori e per intervallo, cache a due livelli, scrittura e modifica di WAD (`IWadBuilder`), record dei lump di livello senza puntatori. 78 test in `Tests\DelphiDoom.Tests.Wad`, anche su `DOOM1.WAD`, `FREEDOOM2.WAD`, `HERETIC1.WAD`, `HEXEN.WAD`, `STRIFE0.WAD` (directory confrontata con una seconda lettura indipendente; riscrittura di DOOM1.WAD con gli stessi lump).
- **Manca (passi 2–4 e criteri "Fatto quando")**:
  1. `Base\w_wad.pas` come facciata con le stesse firme `W_*`. Ostacoli trovati: `lumpinfo[]` è letto direttamente da `nd_main`, `p_setup`, `p_udmf`, `r_data`, `r_things`, `s_externalmusic` (32 accessi); i lump possono venire da stream di PAK (`W_RuntimeLoad`, `W_AddPendingWADfromPAK`) e dal reload con `~`, che oggi non passano da un percorso di file; la cache usa i tag dello zone memory (`PU_STATIC`, `PU_CACHE`).
  2. Passare i chiamanti uno alla volta all'interfaccia e cancellare la facciata.
  3. Scrittura di WAD dal motore e dagli strumenti (`ddc*`, DD_IDE, `w_wadwriter.pas`), parità con `w_wadreader`.
  4. Contratto attraverso una DLL (solo buffer e interi): oggi le interfacce usano `TBytes` e `string`.
  5. Prova a runtime dei quattro giochi dopo il collegamento e build a 64 bit (#40).
- **Domanda per una persona**: va bene tenere `lumpinfo[]` come vista di sola lettura generata dalla libreria (meno rischio) o si vuole cambiare subito i 32 accessi diretti?
- **Prossima azione**: collegare `W_AddFile` per i file WAD alla libreria, tenendo `lumpinfo[]` popolato, e provare i giochi.

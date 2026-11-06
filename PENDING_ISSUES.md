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

## #12 — Cancellare i sorgenti inutili dopo il collegamento alle DLL

- **Stato**: quasi fatta. Sono spariti `C_LIB`, `Libs\Sndfile\Native`, `AUDIOLIB`, `MP3LIB`, `XMILIB`, `MIKWIN` e l'unica unit orfana (`OPENGL\gl_skybox.pas`, mai compilata). Le issue #2–#11 sono chiuse. `ZLIB` (`z_files.pas`), `JPEGLIB`, `SCRIPT` e `FASTCODE` sono ancora referenziate dai `.dpr` e restano (JPEGLIB e SCRIPT sono l'implementazione dietro `TJpegEngine` e il motore degli script, come descritto in `CLAUDE.md`). `build.bat all Release clean` e `build.bat tests` sono verdi, tutti i test passano.
- **Mancano**:
  1. La prova a runtime di Doom, Heretic, Hexen e Strife richiesta dai criteri di accettazione: nel repository non ci sono WAD (`bin\<Gioco>` non li contiene) e nessun `*.swd`; partono ma non si può arrivare al livello né sentire l'audio.
  2. `DD_IDE\zlibpas.pas` e `DD_IDE\obj\*.obj` (zlib 1.1.4 in OMF) sono ancora linkati da `ide_binary.pas` e `ide_zipfile.pas` (undo compresso e file zip): sostituirli con `System.ZLib` cambia il comportamento dell'editor, è lavoro della #42 (Win64: niente `.obj` OMF).
- **Domanda per una persona**: i WAD per la prova (Doom, Heretic, Hexen, Strife) e un parere se `DD_IDE` va migrato a `System.ZLib` dentro la #12 o resta alla #42.
- **Prossima azione**: prova a runtime con i WAD; poi chiudere la #12.

## #1 — Porting a Delphi 11 (XE11) e build da riga di comando

- **Stato**: issue contenitore ("Stato": Heretic con crash dopo il caricamento del livello, circa 900 warning di conversione tra stringhe). Non è chiudibile dal lavoro sul suono.
- **Domanda per una persona**: va chiusa quando #12 è finita, o resta aperta per i warning e il crash di Heretic?

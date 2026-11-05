# Attività in sospeso

Registro delle issue non completate. Si aggiorna quando una issue viene saltata, quando emergono nuove informazioni e si svuota quando la issue è chiusa.

## Blocco generale: push e chiusura delle issue

- **Motivo**: `git push` chiede le credenziali di GitHub (`credential.helper = manager`, finestra interattiva) e in questa sessione non c'è un terminale che le possa dare (`GIT_TERMINAL_PROMPT=0` → `could not read Username`). `gh` non è installato, nessun MCP per le issue di GitHub è collegato: le issue non si possono né chiudere né commentare da qui.
- **Stato**: i commit sono tutti in locale su `master`, sopra `f722b8f5` (il solo commit remoto tirato giù è quello che aggiorna `CLAUDE.md`).
- **Prossima azione**: da un terminale con le credenziali, `git push`; poi chiudere a mano le issue qui sotto quando la decisione sulla cancellazione del C è presa.

## #32 / #31 / #30 — libsndfile, libflac, libvorbis → Pascal (`Libs\Sound`)

- **Stato**: fatto e in uso. I giochi (tutti e otto i progetti) usano `TSoundFactory.CreateEngine` tramite `TSndfileProvider`; non linkano più i `.obj` di libsndfile/libvorbis/libflac né il guscio `libogg.pas`. Build di `giochi` e suite di test verdi (Sndfile 105, Ogg 37, Mp3 63, ecc.); Doom32 parte e gira.
- **Fatto**: WAV (con ADPCM, GSM, G.72x), AIFF/AIFC, AU, VOC, AVR, HTK, W64, RF64, CAF (PCM), SVX, IRCAM, MAT4, MAT5, WVE, MPC2K, PAF, SDS, XI, FLAC, Ogg Vorbis, tag ID3v2 davanti a un FLAC. Parità con il C verificata bit a bit dai test.
- **Non portato (decisione da prendere)**:
  - **ALAC dentro CAF** (~2000 righe tra decoder e colla): non servono al port, e non ho dati di prova: l'encoder del C va in access violation (come quello di Vorbis) e non c'è un file ALAC nel repository. Se serve: portare `ALAC\*.c` e `alac.c`, e costruire i file di prova (anche con pacchetti casuali dopo un cookie valido, come per Vorbis).
  - Vorbis con **floor di tipo 0** (nessun encoder lo produce), FLAC/Speex/PCM dentro Ogg, scrittura di qualsiasi formato.
  - PVF, NIST, DWD, TXW, REX2 (in C falliscono sempre).
- **Domanda per una persona**: si possono cancellare i sorgenti e gli `.obj` del C (`Libs\Sndfile\Native\*`, `libogg.pas`, `libvorbis.pas`, `libflac.pas`, `TSndfileEngine`, la DLL `DDSndfile`) e i test di parità che li usano come riferimento? Finché c'è il C i test di parità girano; senza il C vanno sostituiti con test su dati fissi (golden). Non l'ho fatto perché cancella il riferimento dei test e perché mancano ALAC e gli altri formati qui sopra.
- **Prossima azione**: decisione sopra; poi #33 (C_LIB), #34 (AUDIOLIB vuota), #12, #1 (non ne conosco il testo: servono i titoli).

## Limiti noti del Pascal rispetto al C

- Vorbis: il C accetta floor 0, il Pascal rifiuta il file. Un `Seek` oltre i dati decodificabili si ferma alla fine dei dati (come il C), ma non si emulano le letture a pezzi di un flusso in catena.
- FLAC: una lettura singola che attraversa un resync e la fine del suono perde l'ultimo frame nel C e non nel Pascal (coperto a pezzi).
- PAF a 24 bit e SDS: il C azzera l'ultimo pacchetto dopo un `Seek` o a cavallo di due letture (difetto del C), il Pascal no.
- Tag ID3v2: dopo il tag si apre solo FLAC (WAV, AIFF e AU falliscono anche nel C di questa versione).

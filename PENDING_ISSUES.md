# Attività in sospeso

Registro delle issue non completate. Si aggiorna quando una issue viene saltata, quando emergono nuove informazioni e si svuota quando la issue è chiusa.

## Blocco generale: push e chiusura delle issue

- **Motivo**: `git push` chiede le credenziali di GitHub (`credential.helper = manager`, finestra interattiva) e in questa sessione non c'è un terminale che le possa dare (`GIT_TERMINAL_PROMPT=0` → `could not read Username`). `gh` non è installato, nessun MCP per le issue di GitHub è collegato: le issue non si possono né chiudere né commentare da qui.
- **Stato**: i commit sono tutti in locale su `master` (il remoto è fermo a `f722b8f5`, la sola cosa tirata giù è il nuovo `CLAUDE.md`).
- **Prossima azione**: da un terminale con le credenziali, `git push`; poi chiudere a mano le issue elencate sotto quando sono completate.

## #32 libsndfile → Pascal (`Libs\Sound`) — in corso

- **Fatto** (commit `✨ feat(sound): …` con `refs #32`): WAV, AIFF/AIFC, AU, VOC, AVR, HTK, W64, RF64, CAF (PCM), SVX, IRCAM, MAT4, MAT5, WVE, MPC2K, MS ADPCM, IMA ADPCM, GSM 6.10, G.721/G.723, DWVW. Parità bit a bit col motore C verificata da `Tests\DelphiDoom.Tests.Sndfile` (101 test).
- **Manca**: ALAC (dentro CAF), XI, SDS, PAF, salto del prefisso ID3v2.
- **Non portati di proposito** (in C falliscono sempre): PVF, NIST, DWD, TXW, REX2.
- **Dopo**: portare `TSndfileProvider` sul motore Pascal, cancellare `libogg.pas`/`libvorbis`/`libflac`/`libsndfile` (sorgenti, `.obj`, binding), aggiornare `CLAUDE.md`, poi #33 (C_LIB), #34 (AUDIOLIB vuota), #12, #1.
- **Prossima azione**: ALAC.

## #31 libflac → Pascal — decoder fatto, manca la rimozione del C

- **Fatto**: `Codec.Flac`/`Format.Flac` con gli errori di libFLAC visti da libsndfile; test di parità.
- **Limite noto**: una lettura singola che attraversa un resync e la fine del suono perde l'ultimo frame nel C e non nel Pascal (non emulato; coperto in letture a pezzi). Il dato danneggiato "garbage prima dell'ultimo frame" idem.
- **Non fatto**: FLAC dentro Ogg (`SF_FORMAT_OGGFLAC`).
- **Prossima azione**: chiudere dopo il cambio di provider e la cancellazione di libflac.

## #30 libvorbis → Pascal — decoder fatto, manca la rimozione del C

- **Fatto**: `Codec.Vorbis`, `Format.Ogg`, `Vorbis.*`: header, codebook, floor 1, residui 0/1/2, mapping 0, MDCT, finestre, lunghezza con le granule position, flussi in catena. Test di parità con flussi sintetici (headers costruiti a mano, pacchetti casuali), bit a bit anche in `double`.
- **Non fatto**: floor di tipo 0 (nessun encoder lo produce; il C lo accetta, il Pascal rifiuta il file), scrittura Ogg (il motore è di sola lettura), Speex/Opus/PCM in Ogg.
- **Tentativo scartato**: usare l'encoder di libvorbis linkato nei test per fare i file → il C va in access violation dentro `vorbis_analysis_blockout` (l'encoder non è mai stato usato in questo progetto).
- **Prossima azione**: chiudere dopo il cambio di provider e la cancellazione di libvorbis.

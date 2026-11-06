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

## #48 — Prova dei percorsi PK3 (texture, voxel, suoni) con un PK3 reale

- **Stato**: aperta (nata dalla chiusura della #46). `w_pak.pas` legge i contenitori con `Libs\Wad` ed è stato provato solo con file sintetici. Mancano texture PNG/TGA/BMP/JPG, voxel e suoni reali (`r_pk3textures`, `vx_voxelsprite`, `s_pk3sounds`) e `HI_START`/`TX_START` con immagini vere. Un PK3 con un "wav" finto da 60 byte non ha fatto generare il WAD dei suoni temporanei: da capire.
- **Informazione mancante**: un PK3 reale (con licenza libera, se deve finire in `Tests\Data`).
- **Prossima azione**: provarlo con `-iwad FREEDOOM2.WAD -pakfile <file>.pk3` su Doom, Heretic, Hexen e Strife.

## Lavoro rimasto dalla chiusura della #46

- **Test a 64 bit di `Libs\Wad`**: dipendono dalla compilazione a 64 bit dell'intero progetto (#40–#44).
- `TEngineWadServices` e `ComposeEngine` non hanno test DUnitX (dipendono da `d_delphi`, che i progetti di test non linkano): sono coperti dall'avvio dei giochi.
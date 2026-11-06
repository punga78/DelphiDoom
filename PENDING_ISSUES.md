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
  - Passo 1: `Libs\Wad` (sorgenti WAD, PAK, PK3, cartella, file singolo; directory con precedenza dell'ultimo lump; ricerca per nome con flag dei marcatori e per intervallo; cache; `IWadBuilder`; record dei lump di livello). 83 test, anche sui WAD reali.
  - Passo 2: `Base\w_wad.pas` usa la libreria per la directory (`lumpinfo[]` è una vista di sola lettura rifatta da `W_SyncLumpInfo`), per la ricerca per nome e per i flag dei marcatori, e ora anche per leggere i byte: `W_ReadLump` chiama `ILumpReader.ReadLumpInto` (nuovo `IWadSource.ReadEntryInto`, lettura nel buffer senza copie). I file `~` sono `TReloadableWadSource` (riaperti a ogni lettura, come prima). Un lump vuoto non richiede una posizione valida (come nel vecchio codice). Verificato con un controllo temporaneo (tolto): per ogni lump di Doom, Heretic, Hexen e Strife (1507, 1576, 2984, 2135) la lettura della libreria coincide byte per byte con la lettura diretta dallo stream; lettura di un lump di un file `~` corretta; i giochi arrivano al livello (`-warp`) senza crash.
  - Difetto del vecchio codice non riprodotto: caricare due volte a runtime lo stesso WAD con lo stesso numero di lump liberava più volte lo stesso stream. Ora la sorgente viene sostituita e lo stream liberato una volta (percorso non raggiunto nelle prove).
  - Passo 3: i 32 accessi a `lumpinfo[]` fuori da `w_wad.pas` (`nd_main`, `p_setup`, `p_udmf`, `r_data`, `r_things`, `s_externalmusic`) usano `W_GetNameForNum`, `W_LumpLength`, `W_LumpFlags` e `W_LumpIsNamed`; `lumpinfo[]` ora è privato di `w_wad.pas`. Decisione presa: la cache dei lump resta lo zone memory del motore.
  - Passo 4: `w_wadreader.pas` e `w_wadwriter.pas` sono facciate sopra la libreria (`TWadFactory.OpenPath`, `IWadBuilder`). Nomi di lump: ora accettano qualsiasi byte tranne #0 (spazi e caratteri a 8 bit come prima). `TWadReader.EntryInfo` e `FileSize` (senza chiamanti) sono stati tolti; `AddString` scriveva due byte per carattere (difetto Unicode del vecchio codice, nessun chiamante), ora uno. Verificato con un controllo temporaneo (tolto) in-game: scrittura di un WAD con separatori, dati, stringa e lump vuoto da stream e da file, riletto da `TWadReader` (nomi, `EntryAsString`, `EntryId`, `ReadEntry`, avvisi per file mancante o non WAD); `d_check` legge i WAD di Doom, Heretic, Hexen e Strife.
  - Non verificato in gioco: il percorso PK3 (`s_pk3sounds`, `r_pk3textures`, `vx_voxelsprite`) che usa `TWadWriter`: con un PK3 di prova il gioco non ha generato il WAD temporaneo e non ho capito perché (non dipende dalla libreria: non è arrivato a chiamare il writer). Servirebbe un PK3 reale.
- **Manca**:
  1. Il PAK/PK3 del motore (`w_pak.pas`, 1963 righe, con ZIP, WAD2/WAD3, hash dei nomi, cartelle preferite) non usa `Libs\Wad`; il caricamento dei WAD dentro un PAK (`W_AddPendingWADfromPAK`) passa da lì.
  2. Cancellare la facciata `W_*` quando i chiamanti usano l'interfaccia (`wad_directory`/`wad_finder`/`wad_reader` sono ancora globali di `w_wad.pas`: servono un composition root e chiamanti che ricevano le interfacce).
  3. Contratto attraverso una DLL (solo buffer e interi): oggi le interfacce usano `TBytes` e `string`.
  4. Build a 64 bit (#40).
- **Domanda per una persona**: hai un PK3 reale (con suoni, texture o voxel) per provare i percorsi che scrivono WAD temporanei?
- **Prossima azione**: portare `w_pak.pas` su `Libs\Wad` (sorgenti PAK/ZIP già nella libreria).
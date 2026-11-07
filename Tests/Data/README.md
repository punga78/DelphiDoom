# Dati di prova

## glbsp_map01.wad / glbsp_map01.gwa

- `glbsp_map01.wad`: il livello MAP01 di Freedoom (licenza BSD) con i suoi dieci lump, estratto da `FREEDOOM2.WAD`.
- `glbsp_map01.gwa`: l'uscita dell'eseguibile glbsp incorporato (2.24) su quel WAD, con `-q -xp`.

Il GWA contiene `GL_MAP01` (testo con data e checksum: la riga `TIME=` cambia a ogni esecuzione), `GL_VERT`, `GL_SEGS`, `GL_SSECT`, `GL_NODES` e `GL_PVS`.

Il confronto con un'altra implementazione **non può essere byte per byte**: glbsp calcola in virgola mobile i vertici creati dalle divisioni dei seg, e compilatori diversi arrotondano diversamente. Su questo livello, due compilazioni C dei sorgenti 2.24 (MSVC con SSE e MSVC con x87 a precisione estesa) differiscono da quello incorporato (Borland) in 3–5 vertici di ±1 su 65536 e in 10–12 campi dei nodi che ne derivano. I lump `GL_SEGS` e `GL_SSECT` sono invece **identici byte per byte**. Il criterio di confronto è quindi: `GL_SEGS`, `GL_SSECT` e numero di vertici e di nodi identici; coordinate di `GL_VERT` e `GL_NODES` uguali a meno di ±1 unità a 16.16.

## glbsp_map01_normal.wad

L'uscita dell'eseguibile glbsp incorporato (2.24) su `glbsp_map01.wad` con `-q -xp -n` (ricostruisce anche i nodi normali): `VERTEXES`, `SEGS`, `SSECTORS`, `NODES`, `BLOCKMAP`, `REJECT` e i lump GL. `Tests\Source\DelphiDoom.Tests.Glbsp.Wad.Builder.pas` confronta con questo file l'uscita del porting in Pascal, con la stessa tolleranza (±1 su vertici, angoli, distanze e coordinate dei nodi; tutto il resto identico).

I riferimenti sono stati prodotti con l'eseguibile glbsp 2.24 che era incorporato nel motore (poi sostituito dal porting in Pascal, issue #2); i sorgenti C 2.24 sono nella storia di git.

## Altri riferimenti di glbsp (issue #139)

Prodotti dai sorgenti C 2.24 (`glbsp-2.24-source` nel commit prima di `4e4e8cd5`) compilati fuori dal repository con `bcc32c` di RAD Studio (`bcc32c -O2 -DWIN32 -DINLINE_G=inline -Isrc src\*.c cmdline\main.c cmdline\display.c`). Al posto di zlib c'è uno `zlib.h` finto in cui `deflate` copia i byte senza comprimerli: il lump `NODES` del formato ZDBSP è quindi `ZNOD` seguito dal flusso in chiaro, e il test decomprime quello del Pascal prima del confronto. Sullo stesso `glbsp_map01.wad` questa compilazione dà con `-n` gli stessi byte di `glbsp_map01_normal.wad` tranne 5 byte di `GL_VERT`, 16 di `NODES`, 16 di `GL_NODES` e la riga `TIME` di `GL_MAP01`: il criterio di confronto è quello sopra. Nei WAD `.wad` qui sotto mancano i lump che glbsp copia identici dall'ingresso (il test li prende dall'ingresso); i marcatori dei livelli ci sono sempre.

- `glbsp_map01_v5.wad`: `-q -xp -n -v5` (nodi GL V5 e nodi normali ZDBSP).
- `glbsp_map01_v3.gwa`, `glbsp_map01_v1.gwa`, `glbsp_map01_fast.gwa`: `-q -xp -v3`, `-v1`, `-f`.
- `glbsp_map01_options.wad`: `-q -xp -n -p -m -u -y -w -xr`, con due correzioni nel C (le stesse del Pascal): `SidedefCompare` metteva i sidedef delle linee speciali in ordine di indice rispetto a tutti gli altri, che non è un ordine (A < S < B con A = B): con `-p` i duplicati si univano o no secondo l'algoritmo di `qsort`; ora i sidedef speciali vengono dopo gli altri. E `qsort` di sidedef e vertici rompe la parità con l'indice, così il primo di un gruppo di duplicati non dipende da `qsort`.
- `glbsp_hexen.wad`: MAP01 di Freedoom portato al formato Hexen (THINGS da 20 byte, LINEDEFS da 16, un lump `BEHAVIOR`), la linea 0 con lo special 1 (inizio di un polyobj); in MAP01 tre punti di polyobj di Hexen (3001/3002: dentro un settore, sotto la mappa, a destra della mappa), in MAP02 uno di ZDoom (9301). `glbsp_hexen_normal.wad`: `-q -xp -n -w`; glbsp avvisa per i due punti fuori dai settori.
- `glbsp_odd.wad`: tre livelli piccoli fatti a mano (una stanza con una linea a un lato che la attraversa, la "finestra a un lato"; linee senza sidedef destro, a due lati senza sinistro e un settore non chiuso; una stanza di 40000 unità con linee e nodi oltre i 16 bit e la blockmap troncata). `glbsp_odd_normal.wad`: `-q -xp -n -y -w`; `glbsp_odd_warnings.txt` gli avvisi stampati da glbsp, nell'ordine.

## sound_golden.txt

Le risposte di libsndfile (C) per i suoni di prova di `Tests\Source\DelphiDoom.Tests.Sound.Parity.pas`, una riga per scenario: `nome#impronta-dei-byte|scenario<TAB>impronta a 64 bit` (FNV-1a di `DelphiDoom.Tests.Sound.Digest` su codici di ritorno, frame letti e byte dei buffer). Sono state scritte con il motore C `TSndfileEngine` (libsndfile 1.x + libvorbis 1.3.7 + libFLAC) quando era ancora nel repository, confrontandolo prima con il motore Pascal (105 test, 3900 scenari identici).

Il C è nell'ultimo commit che lo contiene (`a449cacd`); per aggiungere un caso nuovo si può ricostruire da quel commit un progetto con `TSndfileEngine` e registrare l'impronta con la stessa funzione `Observe*`, oppure, se il comportamento voluto è quello del decoder Pascal già verificato, aggiungere la riga con il valore calcolato dal Pascal e motivarlo nel commit.

## Jpeg

- `Jpeg\jpeg_golden.txt`: le risposte del vecchio decoder JPEG (`JPEGLIB\jpg_*.pas`, port letterale di libjpeg 6b, cancellato con la sostituzione in `Libs\Jpeg`) per i 949 flussi di `Tests\Source\DelphiDoom.Tests.Jpeg.Cases.pas`, una riga per flusso: `nome<TAB>impronta a 64 bit` (FNV-1a di `DelphiDoom.Tests.Jpeg.Digest` sui codici di ritorno di `GetInfo` e `Decode`, sulle dimensioni e, quando la decodifica riesce, su tutti i pixel; la funzione è `TJpegObserver.Fingerprint`). Il test `TTestJpegParity` richiede che il decoder di oggi dia le stesse impronte.
- `Jpeg\encoder-*.jpg`: sette immagini (gradienti e rumore a 4:4:4, qualità da 10 a 100) scritte da `TJpegEncoder`, tenute come file perché la risposta non dipenda da come l'encoder arrotonda.
- I flussi sono costruiti dal codice con semi fissi: `TJpegSynthesizer` scrive JPEG con coefficienti casuali (qualsiasi campionamento, intervallo di restart, spazio colore, tabelle standard o proprie, DQT a 8 e 16 bit, script progressivo con approssimazione successiva e raffinamento AC), poi gli stessi flussi sono tagliati in 8 punti, alterati di 1 o 3 byte e con i campi delle intestazioni (SOF, SOS, DHT, DQT, DRI) messi a valori che un decoder deve rifiutare; più due immagini vere di un altro encoder, flussi minimi e flussi che non sono JPEG. Più della metà dei 949 si decodifica; gli altri danno errori di dati, flussi troncati, funzioni non supportate o niente flusso (il test `TestSomeStreamsAreDecoded` controlla che la parte che si decodifica non diventi piccola).
- Come sono state prodotte: con `TJpegEngine` ancora sopra `JPEGLIB`, un test temporaneo (non nel repository) scriveva nome e impronta di ogni caso. Il vecchio decoder aveva tre difetti (vedi `Libs\Jpeg\README.md`): prima di scrivere il file sono stati corretti nel vecchio codice, ma nessuno dei 949 flussi ne dipende (la risposta è la stessa con e senza correzione). Il confronto dei due decoder nello stesso eseguibile, su circa un milione di flussi alterati a caso e 160000 specifiche casuali, è descritto nel README della libreria.
- Per aggiungere un caso: nuovo flusso in `TJpegCases` e riga con l'impronta che dà il decoder (solo se il comportamento voluto è quello già verificato, e motivandolo nel commit); le righe già presenti non si cambiano.

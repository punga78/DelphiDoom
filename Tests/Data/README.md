# Dati di prova

## glbsp_map01.wad / glbsp_map01.gwa

- `glbsp_map01.wad`: il livello MAP01 di Freedoom (licenza BSD) con i suoi dieci lump, estratto da `FREEDOOM2.WAD`.
- `glbsp_map01.gwa`: l'uscita dell'eseguibile glbsp incorporato (2.24) su quel WAD, con `-q -xp`.

Il GWA contiene `GL_MAP01` (testo con data e checksum: la riga `TIME=` cambia a ogni esecuzione), `GL_VERT`, `GL_SEGS`, `GL_SSECT`, `GL_NODES` e `GL_PVS`.

Il confronto con un'altra implementazione **non può essere byte per byte**: glbsp calcola in virgola mobile i vertici creati dalle divisioni dei seg, e compilatori diversi arrotondano diversamente. Su questo livello, due compilazioni C dei sorgenti 2.24 (MSVC con SSE e MSVC con x87 a precisione estesa) differiscono da quello incorporato (Borland) in 3–5 vertici di ±1 su 65536 e in 10–12 campi dei nodi che ne derivano. I lump `GL_SEGS` e `GL_SSECT` sono invece **identici byte per byte**. Il criterio di confronto è quindi: `GL_SEGS`, `GL_SSECT` e numero di vertici e di nodi identici; coordinate di `GL_VERT` e `GL_NODES` uguali a meno di ±1 unità a 16.16.

## glbsp_map01_normal.wad

L'uscita dell'eseguibile glbsp incorporato (2.24) su `glbsp_map01.wad` con `-q -xp -n` (ricostruisce anche i nodi normali): `VERTEXES`, `SEGS`, `SSECTORS`, `NODES`, `BLOCKMAP`, `REJECT` e i lump GL. `Tests\Source\DelphiDoom.Tests.Glbsp.Wad.Builder.pas` confronta con questo file l'uscita del porting in Pascal, con la stessa tolleranza (±1 su vertici, angoli, distanze e coordinate dei nodi; tutto il resto identico).

I riferimenti sono stati prodotti con l'eseguibile glbsp 2.24 che era incorporato nel motore (poi sostituito dal porting in Pascal, issue #2); i sorgenti C 2.24 sono nella storia di git.

## sound_golden.txt

Le risposte di libsndfile (C) per i suoni di prova di `Tests\Source\DelphiDoom.Tests.Sound.Parity.pas`, una riga per scenario: `nome#impronta-dei-byte|scenario<TAB>impronta a 64 bit` (FNV-1a di `DelphiDoom.Tests.Sound.Digest` su codici di ritorno, frame letti e byte dei buffer). Sono state scritte con il motore C `TSndfileEngine` (libsndfile 1.x + libvorbis 1.3.7 + libFLAC) quando era ancora nel repository, confrontandolo prima con il motore Pascal (105 test, 3900 scenari identici).

Il C è nell'ultimo commit che lo contiene (`a449cacd`); per aggiungere un caso nuovo si può ricostruire da quel commit un progetto con `TSndfileEngine` e registrare l'impronta con la stessa funzione `Observe*`, oppure, se il comportamento voluto è quello del decoder Pascal già verificato, aggiungere la riga con il valore calcolato dal Pascal e motivarlo nel commit.

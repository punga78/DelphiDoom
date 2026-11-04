# Dati di prova

## glbsp_map01.wad / glbsp_map01.gwa

- `glbsp_map01.wad`: il livello MAP01 di Freedoom (licenza BSD) con i suoi dieci lump, estratto da `FREEDOOM2.WAD`.
- `glbsp_map01.gwa`: l'uscita dell'eseguibile glbsp incorporato (2.24) su quel WAD, con `-q -xp`.

Il GWA contiene `GL_MAP01` (testo con data e checksum: la riga `TIME=` cambia a ogni esecuzione), `GL_VERT`, `GL_SEGS`, `GL_SSECT`, `GL_NODES` e `GL_PVS`.

Il confronto con un'altra implementazione **non può essere byte per byte**: glbsp calcola in virgola mobile i vertici creati dalle divisioni dei seg, e compilatori diversi arrotondano diversamente. Su questo livello, due compilazioni C dei sorgenti 2.24 (MSVC con SSE e MSVC con x87 a precisione estesa) differiscono da quello incorporato (Borland) in 3–5 vertici di ±1 su 65536 e in 10–12 campi dei nodi che ne derivano. I lump `GL_SEGS` e `GL_SSECT` sono invece **identici byte per byte**. Il criterio di confronto è quindi: `GL_SEGS`, `GL_SSECT` e numero di vertici e di nodi identici; coordinate di `GL_VERT` e `GL_NODES` uguali a meno di ±1 unità a 16.16.

## glbsp_map01_normal.wad

L'uscita dell'eseguibile glbsp incorporato (2.24) su `glbsp_map01.wad` con `-q -xp -n` (ricostruisce anche i nodi normali): `VERTEXES`, `SEGS`, `SSECTORS`, `NODES`, `BLOCKMAP`, `REJECT` e i lump GL. `Tests\Source\DelphiDoom.Tests.Glbsp.Wad.Builder.pas` confronta con questo file l'uscita del porting in Pascal, con la stessa tolleranza (±1 su vertici, angoli, distanze e coordinate dei nodi; tutto il resto identico).

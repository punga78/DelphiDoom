# Tests\Data\TextureDefs

Dati di `Tests\DelphiDoom.Tests.TextureDefs` (issue #73).

- `cases.txt`: i casi (grammatica in testa al file). I lump `PNAMES`, `TEXTURE1/2/3`, `TEXTURE0` si costruiscono in
  memoria da qui (`Tests\Source\DelphiDoom.Tests.TextureDefs.Corpus.pas`, con gli offset scritti a mano: non usa i record
  della libreria) e il testo di `FLATINFO` con la lista dei flat.
- `textures.standard.golden.txt`, `textures.strife.golden.txt`: l'uscita del **vecchio codice**. Contengono i casi di
  texture (`T|nome|L|A|masked|npatch`, `P|indice|nome|ox|oy`, `K|` per `TEXTURE0`, `E|` per un errore) e, nel file
  standard, anche quelli dei flat (`S|indice|codice` per ogni flat, `W|` per ogni avviso).
- `wad.standard.golden.txt`, `wad.strife.golden.txt`: per ogni WAD reale trovato in `bin\` (numero di righe del dump,
  FNV-1a a 32 bit del dump intero, prima e ultima riga). Non contengono dati dei WAD: i test sui WAD si saltano se
  mancano.

## Come sono stati generati

Con un harness **temporaneo, fuori dal repository** (non si committa): un programma console che ha le unit
`Libs\Logging`, `Libs\Scanner` e `Corpus` e che contiene, **copiati alla lettera** con le chiamate al motore sostituite
da finti, i cicli di `R_InitTextures` di `Base\r_data.pas` (PNAMES, TEXTURE1/2/3 e la parte `TEXTURE0`, con i `maptexture_t`/`mappatch_t`
di `r_defs.pas` compilati con e senza `STRIFE`) e `R_ParseFlatInfoText`/`R_FlatSizeFromSize` di `Base\r_flatinfo.pas`.
Finti: `W_CheckNumForName` (l'indice del nome), `I_Error` (eccezione), `I_Warning` (registratore). Compilato due volte
(`-DSTRIFE` e senza) e lanciato con la cartella dei dati e quella dei WAD. Per rigenerare i golden bisogna rifarlo.

## Differenze e difetti

Vedi il punto 6 di `Libs\TextureDefs\WIRING.md`. I casi dei golden sono solo quelli che il vecchio codice gestiva
senza comportamento indefinito (il solo errore è `bad texture directory` con `offset > maxoff`); gli errori nuovi
(texture che non entra nel lump, indice di patch fuori da PNAMES, conteggi negativi) sono provati nei test di classe.

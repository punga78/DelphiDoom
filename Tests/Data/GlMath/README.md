# Dati di prova di Libs\GlMath (issue #45)

`glmath.golden.txt` è l'uscita del **vecchio codice del motore** (`OPENGL\gl_clipper.pas` e `gld_FrustumAngle`), compilato con
Delphi 11 Win32, con ottimizzazioni attive, in un programma di prova **fuori dal repository** (l'harness non si committa; ha una copia
di ciascuna unit in cui sono tolte solo le dipendenze dal motore: `r_main`, `viewplayer`). Ogni riga è
`chiave=impronta/conteggio`: l'impronta è un FNV-1a a 64 bit (`DelphiDoom.Tests.GlMath.Fingerprint`), il conteggio il numero di valori.
Nello stesso eseguibile il vecchio codice e le classi nuove hanno dato le stesse impronte (zero differenze); i test confrontano
le classi nuove con queste righe.

Gli ingressi sono gli stessi in harness e test (`DelphiDoom.Tests.GlMath.Scenarios`, xorshift32 con semi fissi).

| Chiave | Contenuto |
|---|---|
| `clipper.sequences` | 40 sequenze di 400 passi (aggiunte, controlli, `Clear`) con intervalli di tutte le larghezze, anche attorno allo zero e al massimo; la lista dopo ogni quarto passo |
| `viewangle.sweep` | `gld_FrustumAngle` per 8 aspetti e per tutte le direzioni di sguardo da -2400 a 2400 |

Le righe `frustum.*` (i piani e i test del vecchio `gl_frustum`) sono state tolte con `TGlFrustum` dalla #145: la classe non aveva
chiamanti nel motore.

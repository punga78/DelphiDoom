# Dati di prova di Libs\GlMath (issue #45)

`glmath.golden.txt` è l'uscita del **vecchio codice del motore** (`OPENGL\gl_frustum.pas` e `gl_clipper.pas`), compilato con
Delphi 11 Win32, con ottimizzazioni attive, in un programma di prova **fuori dal repository** (l'harness non si committa; ha una copia
di ciascuna unit in cui sono tolte solo le dipendenze dal motore: `glGetFloatv`, `r_main`, `viewplayer`). Ogni riga è
`chiave=impronta/conteggio`: l'impronta è un FNV-1a a 64 bit (`DelphiDoom.Tests.GlMath.Fingerprint`), il conteggio il numero di valori.
Nello stesso eseguibile il vecchio codice e le classi nuove hanno dato le stesse impronte (zero differenze); i test confrontano
le classi nuove con queste righe.

Gli ingressi sono gli stessi in harness e test (`DelphiDoom.Tests.GlMath.Scenarios`, xorshift32 con semi fissi).

| Chiave | Contenuto |
|---|---|
| `frustum.planes` | i 24 valori dei sei piani (bit delle `Single`) per 80 coppie di matrici (prospettive con fov 20..130, aspetto 0,5..2,5, vista ruotata e traslata; una coppia su otto è di valori qualsiasi) |
| `frustum.points`, `.spheres`, `.boxes`, `.cubes` | 250 prove di ogni tipo per ogni coppia (20000 risposte) |
| `clipper.sequences` | 40 sequenze di 400 passi (aggiunte, controlli, `Clear`) con intervalli di tutte le larghezze, anche attorno allo zero e al massimo; la lista dopo ogni quarto passo |
| `viewangle.sweep` | `gld_FrustumAngle` per 8 aspetti e per tutte le direzioni di sguardo da -2400 a 2400 |

A 32 bit i piani hanno gli stessi bit del vecchio codice (le espressioni sono le stesse, calcolate in `Extended`). A 64 bit i
valori intermedi sono `Single` e l'ultimo bit di un piano può cambiare: i golden `frustum.*` vanno rigenerati dal vecchio codice a 64 bit.

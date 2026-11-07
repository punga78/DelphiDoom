# Libs\GlMath (issue #45, fetta "geometria del renderer OpenGL")

Il clipper degli angoli e l'ampiezza della vista di `OPENGL\gl_clipper.pas`, a classi e senza chiamate a OpenGL. L'analisi
di tutta la cartella `OPENGL\` (cosa è stato portato e cosa no, e perché), il collegamento al motore e il costo misurato sono
in `Libs\Models\README.md`, paragrafo 3. Il motore usa il clipper (`gl_clipper.pas`). Il frustum della vista (`TGlFrustum`,
port di `gl_frustum.pas`) è stato cancellato con i suoi test dalla #145: `gl_frustum.pas` non c'era più dalla #134 (i piani
non li leggeva nessuno) e la classe non aveva chiamanti; resta nella storia di git (prima del commit della #145 che la toglie).

Parità con il vecchio codice: i test in `Tests\DelphiDoom.Tests.GlMath` (golden in `Tests\Data\GlMath`, vedi il suo `README.md`).

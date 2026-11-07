# Libs\GlMath (issue #45, fetta "geometria del renderer OpenGL")

Il frustum della vista, il clipper degli angoli e l'ampiezza della vista di `OPENGL\gl_frustum.pas` e `gl_clipper.pas`,
a classi e senza chiamate a OpenGL. L'analisi di tutta la cartella `OPENGL\` (cosa è stato portato e cosa no, e perché),
il collegamento al motore e il costo misurato sono in `Libs\Models\README.md`, paragrafo 3. Dalla #134 il motore usa solo
il clipper (`gl_clipper.pas`); `gl_frustum.pas` è stata cancellata perché i piani del frustum non li leggeva nessuno, e
`TGlFrustum` resta qui senza chiamanti.

Parità con il vecchio codice: 30 test in `Tests\DelphiDoom.Tests.GlMath` (golden in `Tests\Data\GlMath`, vedi il suo `README.md`).

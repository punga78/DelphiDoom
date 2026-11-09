# Dati di prova di Libs\Models (issue #45)

`models.golden.txt` è l'uscita del **vecchio codice del motore** (`Libs\OpenGl\Legacy\mdl_md2.pas`: costruttore e `MergeFrames`; `mdl_base.pas`;
`mdl_script_model.pas`: `TDDModelLoader` senza lo script), compilato con Delphi 11 Win32 in un programma di prova **fuori dal
repository** (l'harness non si committa). Nell'harness il flusso è un `TDMemoryStream`, le chiamate OpenGL del disegno vanno a un
registratore e gli offset e le scale arrivano già divisi per `MAP_COEFF`; il resto è la copia del vecchio testo. Ogni riga è
`chiave=impronta/conteggio` (FNV-1a a 64 bit, `DelphiDoom.Tests.Models.Fingerprint`). Nello stesso eseguibile il vecchio codice e le
classi nuove hanno dato le stesse impronte (zero differenze); i test confrontano le classi nuove con queste righe.

I file MD2 sono costruiti in memoria (`DelphiDoom.Tests.Models.Samples`, xorshift32 con semi fissi), con il layout standard di Quake 2.

| Chiave | Contenuto |
|---|---|
| `md2.models` | 40 modelli (0..39 triangoli, 3..62 vertici, 1..12 fotogrammi, nomi con e senza numeri, spazi, maiuscole) con la posizione identità o casuale: vertici di ogni fotogramma, punti di texture, gruppi con primo e ultimo fotogramma |
| `md2.groupnames` | la regola del nome del gruppo su 26 nomi di fotogramma (`stand01`, `stand1`, `a`, `12`, ` pain1 `...); i nomi vuoti o di soli spazi non sono nel confronto: il vecchio codice non terminava |
| `md2.merges` | 15 unioni di due file con un solo fotogramma nel secondo (l'unico caso in cui il vecchio `MergeFrames` è giusto), di cui 3 rifiutate perché i triangoli sono diversi |
| `dmx.streams` | 30 serie di comandi di modelli procedurali (da 6 a 125 comandi, con cambi di fotogramma e chiamate): fotogrammi, posizione di ogni fotogramma, file binario byte per byte, file riletto, riproduzione di ogni fotogramma con profondità 20, 2 e 0 |

Dal confronto con il vecchio codice com'è oggi (record con `Char` da 2 byte) escono le differenze volute: vedi `Libs\Models\README.md`.
Le serie di `dmx.streams` hanno sempre il fotogramma 0 per primo e i nuovi fotogrammi in ordine crescente: sono gli unici casi in cui
l'elenco dei fotogrammi del vecchio codice è giusto (il difetto ha un test a parte).

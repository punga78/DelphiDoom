# Framework\Serializer

Serializzatore dei record dei salvataggi.

Il testo di riferimento (paragrafi spostati dal CLAUDE.md di radice, issue #178) sta in [CLAUDE.md](CLAUDE.md).

## Contenuto

- Unit nella cartella: 10 (nome a punti `DelphiDoom.Serializer.*`).
- Record salvati interi, uguali a 32 e a 64 bit (issue #40): `IDiskLayout`, `IDiskLayouts`, `IDiskRecordWriter`; prove con i salvataggi veri in `Tools\Verifica\40`, descritte in [docs\SALVATAGGI_32_64.md](../../docs/SALVATAGGI_32_64.md).
- Interfacce dichiarate: `ISerializer`, `ISerializerFactory`, `ISerializerMobjResolver`, `ISerializerPlayerResolver`, `ISerializerStateResolver`.
- Punto di creazione delle classi: `DelphiDoom.Serializer.Factory`.

## Prova

- Progetto di test in `Tests\`: `DelphiDoom.Tests.Serializer`. Si compila con `Tools\build.bat` (vedi "Build e prove" nel [CLAUDE.md di radice](../../CLAUDE.md)).

## Legami

- Indice delle librerie e regole generali: [CLAUDE.md di radice](../../CLAUDE.md).

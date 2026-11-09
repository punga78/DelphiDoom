# Libs\XcomSurface

> Note per Claude: [CLAUDE.md](CLAUDE.md).

Superficie indicizzata a 8 bit di **OpenXcom** (`Surface`, `Font`, `ShaderDraw`/`ShaderMove`) senza SDL, issue #176 (terza fetta, dopo `Libs\XcomFormats` e `Libs\Yaml`). Solo classi pure; usa `TXcomImage` e `TXcomPalette` di `Libs\XcomFormats`.

Non e' un gioco del motore Doom: nessun collegamento a `ComposeEngine` ne' a `TIdTechGeneration`.

## Licenza (da decidere)

Il codice deriva da OpenXcom, **GPL v3 o successiva** (intestazione di ogni unit); il comportamento di SDL 1.2 (fill, blit con color key, mappatura di palette) e' riscritto dal comportamento documentato di SDL 1.2.15 (LGPL), senza copiare sorgenti. La licenza dell'opera che lo contiene la decide il proprietario del repository: questa fetta non cambia quella del repository. Nessun sorgente C++ e' nel repository (l'harness di parita' sta fuori, vedi sotto).

## Cosa c'e'

| C++ (OpenXcom / SDL 1.2) | Delphi |
|---|---|
| `SDL_Rect` (x, y `Sint16`; w, h `Uint16`) | `TXcomRect` (`Make` converte come il C: una misura negativa diventa grande) |
| `GraphSubset` | `TXcomGraphSubset` (`Offset`, `SizeX/Y`, `Intersection`) |
| `Surface` (8 bit, palette di 256, posizione, crop, color key 0) | `TXcomSurface` |
| `Surface::clear/offset/offsetBlock/invert/copy/drawRect/blit/draw/setWidth/setHeight/copy constructor` | metodi di `TXcomSurface` (`Clear`, `Offset`, `OffsetBlock`, `Invert`, `Copy`, `DrawRect`, `Blit`, `Draw`, `SetWidth`, `SetHeight`, `Clone`) |
| `SDL_FillRect`, `SDL_IntersectRect`, `SDL_UpperBlit` (8 bit -> 8 bit con color key e mappa delle palette, `SDL_Map1to1`/`SDL_FindColor`) | `TXcomSdl` (`FillRect`, `IntersectRect`, `BlitKeyed`, `FindColor`) |
| `ColorReplace`, `StandardShade`, `ShaderDraw` | `TXcomColorReplaceShade`, `TXcomStandardShade` (dietro `IXcomShadeFunction`), `TXcomShadeDrawer` |
| `Surface::blitNShade` (due varianti) | `TXcomSurfaceShader.Blit` |
| `Font` (`init`, `getChar`, `getCharSize`, `load`) | `TXcomFont`, `TXcomFontDefinition`; `IXcomSurfaceLoader` e' cio' che carica un'immagine (`Surface::loadImage`) |
| composition root | `TXcomSurfaceFactory` |

## Parita'

L'harness C++ (fuori dal repository, compilato con g++ MinGW) **collega i veri `Surface.cpp`, `Font.cpp`, `Palette.cpp`, `Unicode.cpp` di OpenXcom e la vera SDL 1.2.15** (`SDL.dll` di `Reference\_dati\openxcom_build\deps`): non sono copie. Esegue uno script casuale con seme fisso e stampa, dopo ogni operazione, dimensioni, posizione e impronta FNV-1a a 64 bit dei pixel. Lo script e' `Tests\Data\XcomSurface\surface.script.txt` (3000 operazioni: superfici di 1..40 pixel con 0, 25 o 60 per cento di pixel trasparenti, palette uguali, diverse e con colori ripetuti, riempimenti con rettangoli anche negativi o fuori dalla superficie, `clear`, `offset`, `offsetBlock`, `invert`, `copy`, `blit` con crop, posizione e nascosta, `blitNShade` con half, con cambio del gruppo di colore e con intervallo, ridimensionamento, copia, `draw`) piu' 60 caratteri di font monospace e proporzionali; il golden e' `surface.golden.txt` (5232 righe) e il test lo riproduce con un generatore Mersenne Twister identico a `std::mt19937`: **zero differenze**.

## Differenze volute e cose trovate

- `Surface::offset`/`offsetBlock` con moltiplicatore (o blocco) zero sono una divisione per zero nel C++: qui `EXcomSurfaceException`.
- `Font::init` con una cella piu' larga dell'immagine dividerebbe per zero: `EXcomSurfaceException`.
- Una dimensione non positiva e' rifiutata (`EXcomException` da `TXcomImage`).
- **Comportamenti del C++ conservati**: la copia (`Clone`) copia solo 255 colori della palette (l'ultimo resta nero) e quindi due superfici copiate possono avere palette diverse e un blit con mappatura; dopo `SetWidth`/`SetHeight` il blit successivo prima ripulisce la superficie; `getCharSize` e `getChar` inseriscono nella mappa un `?` vuoto se manca (come `operator[]` di `std::map`), cambiando le risposte seguenti; una cella vuota di un font proporzionale ha x = -1 e larghezza 1; con spaziatura negativa le dimensioni usano l'aritmetica `Uint16` di `SDL_Rect`.
- `blitNShade`: le coordinate sono nello stesso sistema della posizione della superficie di destinazione (il `ShaderSurface` della destinazione e' mosso di `getX()`, `getY()`).

## Non portato

- **Le primitive di SDL_gfx** (`drawLine`, `drawCircle`, `drawPolygon`, `drawTexturedPolygon`, `drawString`): sono SDL_gfx 2.0.26 su una superficie a 8 bit con palette, la cui mappatura del colore (`SDL_MapRGBA`) e' parte del comportamento; vedi l'elenco in `CLAUDE.md`.
- Il caricamento di file di immagine (`loadImage`, `loadScr`, `loadSpk`, `loadBdy`): i decoder sono in `Libs\XcomFormats`; `loadImage` (PNG/BMP/...) e' dietro `IXcomSurfaceLoader`.
- `Font::loadTerminal` (il BMP del font DOS incorporato) e i `Surface` di sottoclassi con disegno proprio (`Text`, `Window`, ...), parte di `XcomUi`.
- I campi di `_tooltip`, la lista di `invalidate`, i colori di `setColor`: sono dell'interfaccia.

## Test

`Tests\DelphiDoom.Tests.XcomSurface` (34 test, Release e Debug Win32; copertura 99%, 458 righe su 459): `TTestXcomSurfaceGolden` (la parita'), `TTestXcomSurface` (le regole una per una e gli errori). Win64 non provato.

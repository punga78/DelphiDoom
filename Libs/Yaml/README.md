# Libs\Yaml

Port a classi di **yaml-cpp 0.7.0** (parser YAML, albero `YAML::Node`, conversioni `as<T>`, `Emitter`), la
libreria che OpenXcom usa per i rulesets e i salvataggi (issue #176). Delphi 11, Win32 e Win64, nessuna
dipendenza dal resto del motore.

## Licenza

yaml-cpp e' **MIT**, Copyright (c) 2008-2015 Jesse Beder. Ogni unit dice "Port of yaml-cpp 0.7.0 (MIT, Jesse
Beder)". La nota MIT va conservata dove si distribuisce questo codice:

> Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
> associated documentation files (the "Software"), to deal in the Software without restriction, including
> without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
> copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the
> following conditions: The above copyright notice and this permission notice shall be included in all copies
> or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND.

E' una traduzione fedele (stesso algoritmo, stessi messaggi di errore e stesse posizioni riga:colonna), quindi
codice derivato, non una riscrittura da zero. Il repository e' GPL v2 o successiva: la MIT e' compatibile.

## Uso

```pascal
Parser := TYamlFactory.CreateParser(MiaSorgenteDiFile);   // IYamlFileSource: la libreria non tocca il disco
Doc := Parser.LoadFile('rules.yml');                       // oppure Load(testo), LoadAll(byte)
Cost := Doc.Find('weapons').Items[0].Find('cost').AsInteger(0);   // node["k"] const + as<int>(0)
Doc.Child('nuovo').AssignScalar('1');                       // node["k"] = "1" (non const)
Doc.Child('x').AssignInteger(5);  // anche AssignInt64, AssignDouble (17 cifre), AssignSingle, AssignBoolean, AssignNull
Emitter := TYamlFactory.CreateEmitter;  Emitter.WriteNode(Doc);  Testo := Emitter.Text;
```

I testi sono **byte UTF-8** (`TYamlText` = `RawByteString`): yaml-cpp lavora su `std::string`, e un file con
byte non UTF-8 deve restare com'e'. `ScalarString` e `YamlTextToString`/`YamlStringToText` convertono da e verso
`string`. Una stringa letterale con caratteri sopra #127 in un `TYamlText` verrebbe convertita dalla code
page: i byte esatti si fanno con `YamlBytes([...])`.

## Mappa classe C++ -> unit Delphi

| yaml-cpp | Delphi |
|---|---|
| `YAML::Mark`, `NodeType`, `EmitterStyle`, `EMITTER_MANIP`, `ErrorMsg::*`, `Exception` e derivate | `DelphiDoom.Yaml.Types`: `TYamlMark`, `TYamlNodeType`, `TYamlEmitterStyle`, `TYamlManip`, `SYaml*`, `EYamlException` (con `Mark` e `Msg`), `EYamlParserException`, `EYamlDeepRecursion`, `EYamlRepresentationException`, `EYamlInvalidNode`, `EYamlBadConversion`, `EYamlBadSubscript`, `EYamlBadPushback`, `EYamlBadInsert`, `EYamlBadFile`, `EYamlEmitterException` |
| `EventHandler` | `IYamlEventHandler` (`.Intf`) |
| `Node` | `IYamlNode` (`.Intf`) implementato da `TYamlNode` (`.Node`) |
| `Parser`, `YAML::Load*` | `IYamlParser` (`.Intf`) implementato da `TYamlLoader` (`.Loader`); `TYamlDocumentParser` (`.DocumentParser`) e `TYamlSingleDocParser` (`.SingleDocParser`) |
| `Stream`, `StreamCharSource`, `StringCharSource` | `TYamlStream` (`.Stream`), `TYamlCharSource` (`.RegEx`) |
| `RegEx`, `Exp::*`, `Exp::Escape`, `Keys::*` | `TYamlRegEx` (`.RegEx`), `TYamlExp` (`.Exp`) |
| `Token` | `TYamlToken` (`.Token`) |
| `Scanner` (scanner, scantoken, simplekey) | `TYamlScanner` (`.Scanner`) |
| `ScanScalar`, `ScanTag`, `Directives`, `Tag` | `TYamlScalarScanner` (`.ScanScalar`), `TYamlTagScanner` (`.ScanTag`), `TYamlDirectives`, `TYamlTag` (`.Directives`) |
| `NodeBuilder`, `NodeEvents` | `TYamlNodeBuilder`, `TYamlNodeEvents` |
| `detail::memory`, `memory_holder`, `node_data`, `node_ref`, `node` | `.Detail`: `TYamlMemory`, `TYamlMemoryHolder`, `TYamlNodeData`, `TYamlNodeRef`, `TYamlDetailNode` (quattro viste dello stesso dato che si usano i campi privati a vicenda: una unit sola) |
| `convert<T>`, `IsNullString`, base64 | `TYamlConvert` (`.Convert`) |
| `Emitter` | `IYamlEmitter` (`.Intf`) implementato da `TYamlEmitter` (`.Emitter`) |
| `EmitterState`, `Setting*`, `GroupType`... | `TYamlEmitterState`, `TYamlSettingChanges` (`.EmitterState`) |
| `emitterutils` | `TYamlEmitterUtils` (`.EmitterUtils`) |
| `ostream_wrapper` | `TYamlOutputWriter` (`.OutputWriter`, solo la forma "buffer in memoria") |
| `EmitFromEvents`, `operator<<(Emitter&, Node)`, `Dump`, `Clone` | `TYamlEmitFromEvents`, `IYamlEmitter.WriteNode`, `TYamlFactory.Dump`, `TYamlFactory.Clone` |
| (file) | `IYamlFileSource` e `TYamlDiskFileSource` (`.DiskFileSource`) |
| | `TYamlFactory` (`.Factory`): l'unico punto che conosce le classi |

## Proprieta' della memoria

Un `YAML::Node` e' un puntatore a un nodo di una memoria condivisa; due handle possono essere lo stesso nodo
(alias, `Assign`) e un nodo puo' contenere se stesso (`&a [*a]`). Qui:

- `IYamlNode` e' contato (interfaccia): non si tengono riferimenti a classe e a interfaccia sullo stesso oggetto.
- I nodi (`TYamlDetailNode`), i `node_ref` e i `node_data` hanno un **conteggio esplicito** (`TYamlShared`,
  come i `shared_ptr` di yaml-cpp) e le **memorie** (`TYamlMemory`: l'insieme dei nodi che vivono insieme) li
  possiedono; i riferimenti tra nodi sono puntatori semplici. `merge` riunisce le memorie come in yaml-cpp
  (`memory_holder::merge`): dopo `Add`, `Assign`, `AssignData`, `Child(nodo)` le due memorie sono una sola.
- Un nodo vive finche' vive una memoria che lo contiene, cioe' finche' esiste un handle che puo' raggiungerlo.
  I cicli dentro un albero non perdono memoria (non ci sono riferimenti contati tra i nodi): vale anche in
  Debug con `ReportMemoryLeaksOnShutdown`.
- Non c'e' sicurezza tra thread (nemmeno in yaml-cpp). `Items` e `Pairs` danno un'istantanea (array); gli
  iteratori lazy di yaml-cpp non ci sono, e cambiare l'albero durante un giro non si ripercuote sull'array.
- L'insieme delle dipendenze di un nodo non definito (`std::set<node*, less>` ordinato per `m_index`) e'
  riprodotto: due nodi con lo stesso indice (mai spinti in una sequenza) sono "equivalenti" e il secondo non
  entra (comportamento vero di yaml-cpp, che si vede solo con `Child`/`Find` su nodi mai definiti).

## Verifica: parita' con il C++ vero

Nessun sorgente C++ e' nel repository. L'harness (`Tools\Verifica\176\yaml`) e' codice nostro che si compila con
**g++ MinGW** (`Reference\_dati\_strumenti\w64devkit`) contro la **libreria vera** `libyaml-cpp.a` 0.7.0
(`Reference\_dati\openxcom_build`); `regen.cmd` la ricompila e riscrive corpora e golden in `Tests\Data\Yaml`
(generatore con seme fisso nell'harness; stdout binario: LF e nessun BOM).

| File | Contenuto | Casi |
|---|---|---|
| `corpus.txt` -> `parse.golden.txt` | 153 casi scritti a mano, 600 documenti casuali (anche mutati per gli errori, seme 176), 294 casi di escape (ogni codice, errori, fine del testo) e di codifica (UTF-16/32 LE/BE con e senza BOM, troncati, surrogati sbagliati, il carattere $04 e oltre $10FFFF, BOM finti). Per ogni caso: `OK docs=n` e il dump di ogni documento (tipo, stile, tag, scalare, `as<>` di int, unsigned, long long, short, char, double, float e bool), oppure `ERR messaggio @riga:colonna`, piu' il testo di `Emitter << node` | 1047 |
| `emit_strings.*` | ogni stringa (controlli, Unicode valido e non, `:` `#` spazi `---` `null` numeri, vuota, oltre 1024 byte...) come scalare di documento, in sequenza, chiave e valore, con Block/Flow e Auto/Single/Double/Literal, con i tre charset | 4212 |
| `emit_values.*` | interi di ogni larghezza in Dec/Hex/Oct, bool, null in ogni formato, double e float con precisioni 0..18 (anche inf, nan, denormali), char, binario | 480 |
| `emit_settings.*` | ogni setter globale con ogni valore (anche sbagliato), indentazioni, impostazioni locali e `RestoreGlobalModifiedSettings` | 319 |
| `emit_random.*` | sequenze casuali di operazioni (Begin/End, Key/Value, Comment, Anchor, Alias, Tag, Newline, documenti, manipolatori, precisione) con stato di errore, `GetLastError` e testo | 4000 |

Il formato degli script dell'emitter e' in `Tools\Verifica\176\yaml\emitcases.h`; il test li riesegue con
`TYamlEmitScript` e confronta riga per riga (`DelphiDoom.Tests.Yaml.Parity`). **0 differenze** su tutti i
10.058 casi, in Win32 (Release e Debug) e Win64 (Debug e Release, con dcc64). La prima esecuzione ne ha mostrati due: vedi sotto.

## Test

`Tests\DelphiDoom.Tests.Yaml` (`Tools\build.bat Tests\DelphiDoom.Tests.Yaml`): **95 test** (6 di parita' sui
corpora, il resto sul nodo, sulle conversioni, sul parser e sull'emitter), copertura **92%** delle righe
(`Tools\Copertura.ps1 -Test Yaml`; 4325 su 4652). Senza DUnitX nel percorso relativo (un worktree) si imposta
la variabile d'ambiente `DCC_UnitSearchPath` con la cartella `DUnitX\Source`.

## Differenze volute dal C++ (e difetti trovati)

1. **`LoadAll` di un testo che non consuma un token** (per esempio che comincia con una virgola): yaml-cpp
   legge documenti vuoti all'infinito fino a `std::bad_alloc` (un errore che non e' un `YAML::Exception`). La
   libreria si ferma al primo con `EYamlEndlessDocumentsException` (che non e' un `EYamlException`, come
   l'`ERR other` del golden). `Load` (un solo documento) non cambia. Trovato dalla parita': 2 casi su 753.
2. **Numeri**: sono letti con le regole di `std::stringstream` di libstdc++ (provate con un programma C++:
   `010` = 8, `0x1F`, `0x` senza cifre e' un errore, spazi solo dopo, fuori misura = errore, `5.` e `.5`
   si leggono, `1e` no, `.inf`/`.nan` solo dopo il fallimento della lettura). La conversione di testo in
   `Double` usa `TryStrToFloat` di Delphi (via `Extended`): e' esatta per i decimali brevi (fino a 15 cifre
   significative); con 17 cifre una rara cifra finale puo' differire dal `strtod` esatto. `Single` passa
   da `Double` (doppio arrotondamento possibile, rarissimo).
3. **Scrittura dei `double`/`float`**: `%.*g` della libreria C (`TYamlConvert.FormatGeneral`) con le **cifre
   decimali esatte** del numero (numeri grandi in base 10^9) e arrotondamento al pari come glibc/mingw:
   `0.1` con 17 cifre da `0.10000000000000001`. Inf = `.inf`/`-.inf`, NaN = `.nan` (come l'emitter) o
   `inf`/`nan` nel dump.
4. **Interi dell'emitter**: `long` di MinGW a 64 bit vale 4 byte (LLP64): l'API ha `WriteInteger/Cardinal`
   (32), `WriteSmallInt/Word` (16), `WriteInt64/UInt64` (64). In Hex e Oct un negativo e' il suo schema di bit
   della larghezza del tipo (come `std::hex`).
5. **Base64**: un byte oltre 127 in `DecodeBase64` e' non valido (il C++ indicizza la tabella con un `char`
   negativo: comportamento indefinito).
6. `IYamlNode.Find` con una chiave `IYamlNode` mancante mette nel messaggio di `InvalidNode` il testo
   dello scalare della chiave (yaml-cpp scrive la chiave come YAML con l'`operator<<`).
7. `LocalIndent` con un numero negativo e' un `size_t` enorme in C++ (si scrivono spazi fino a esaurire la
   memoria): non c'e' nessuna protezione, come l'originale; l'harness non lo prova.
8. L'emitter scrive solo in memoria (`Text`, intero: `c_str()` taglia al primo byte zero, il dump dei test lo
   riproduce) e il programma chiamante decide dove metterlo.

## Non portato

Le conversioni di contenitori STL (`std::map`, `std::vector`, `std::list`, `std::array`, `std::pair`: si usano
`Items`/`Pairs`), `convert<T>` per tipi dell'utente, gli iteratori lazy, `YAML::Parser` come classe pubblica
(`PrintTokens`, `operator bool`), `Load(std::istream&)`, `Emitter(std::ostream&)`, `operator<<(std::ostream&,
Node)`, `YAML::Null`/`IsNull(Node)` (API vecchia), `YAML::Binary` come classe (c'e' `TBytes`), la cartella
`contrib` (`anchordict`, `graphbuilder`) e il codice di esportazione DLL.

## Non verificato

- Win64 con il compilatore dell'IDE sul .dproj (il progetto ha solo Win32: Win64 e' stato provato con dcc64 sul .dpr).
- `TYamlDiskFileSource` su file reali in sola lettura o bloccati (un file normale si, nel test).
- I file di dati veri di OpenXcom (rulesets, salvataggi): non sono sul PC; le primitive che servono a
  `XcomMod` e `XcomSave` sono provate con i corpora, non con i loro file.

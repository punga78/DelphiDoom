# Libs\IdLib - come usarla (issue #45)

idLib **non e collegata al motore** di Doom, Heretic, Hexen e Strife: e una base per codice ispirato a idTech 4 (il modello
di collisione di `cm`, un lettore di mappe `.map`, un parser dei file `.def`...). Nessun file di `Base\`, `Doom\` ecc. e
stato toccato. Le dipendenze iniettate sostituiscono i singleton di idLib.

## 1. Servizi da dare alle classi

| In idLib | Qui | Chi lo usa |
|---|---|---|
| `idLib::common->Warning/Printf` | `IIdLibLog` (`DelphiDoom.IdLib.Core.Intf`) | `TIdLexer` (anche nil: silenzio) |
| `idLib::common->Error/FatalError` | `EIdLibException`, `EIdLibFatalException`, `EIdLexerException` (`Core.Exceptions`) | lexer, `TIdStrPool`, `TIdHierarchy` |
| `idLib::fileSystem` | `IIdLibFileSystem` (`TryReadFile`, `WriteFile`) | `TIdLexer.LoadFile` |
| `idLib::cvarSystem` | `IIdLibCVars` | `TIdCmdArgs` (la forma `$nome`) |
| `idLexer::SetBaseFolder` (statico) | proprieta `BaseFolder` dell'istanza | `TIdLexer` |

Un'implementazione di `IIdLibFileSystem` sopra `Libs\Wad` (`ILumpReader` / un `IWadDirectory`) o sopra una cartella e
quello che serve per leggere i file di una mappa; i test hanno `TIdLibMemoryFileSystem` e `TIdLibLogRecorder` in
`Tests\Source\DelphiDoom.Tests.IdLib.Fakes.pas`.

## 2. Esempio

```pascal
var
  LLexer: TIdLexer;
  LToken: TIdToken;
begin
  LLexer := TIdLexer.Create(LEXFL_NOFATALERRORS, MyLog, MyFileSystem);
  try
    LLexer.LoadFile('maps/game/mp/d3dm1.proc');
    LToken := TIdToken.Create;
    while LLexer.ReadToken(LToken) do
      Writeln(LToken.Text, ' ', LToken.TokenType);
  finally
    LLexer.Free;
  end;
end;
```

## 3. Regole da ricordare

* **FPU**: idLib suppone le eccezioni mascherate (una divisione per zero da infinito): chiamare
  `SetExceptionMask(exAllArithmeticExceptions)` prima, come fanno i test. Il motore di Doom usa `Set8087CW` in
  `i_system.pas`: se si mescola, ripristinare la maschera dopo.
* **Win64**: `Extended` e `Double`; `Single` e SSE. Il codice non usa `Extended` ne `asm`: a 64 bit i risultati possono
  differire dall'x87 nell'ultimo bit (i golden sono dell'x87 a 32 bit).
* **Stringhe**: tutto il testo e `AnsiString` (byte); `string` solo per i messaggi.
* **Proprieta**: i contenitori intrusivi (`TIdLinkList`, `TIdHierarchy`) non possiedono gli oggetti; `TIdBTree` e
  `TIdStrPool` possiedono i propri nodi/stringhe.
* **Thread**: nessuna classe ha stato globale, tranne la tabella della radice inversa di `TIdMath` (immutabile dopo
  l'avvio dell'unit).

## 4. Ordine di lavoro per il resto di idLib

1. `idDict` + `idLangDict` (stringhe: pronte le basi `TIdStr`, `TIdLexer`).
2. `idPlane`, `idBounds`, `idSphere`, `idQuat`/`idCQuat`, `idAngles`, `idMat3` (servono i vettori che ci sono) con lo stesso
   metodo: golden dal vero idLib con `bcc32c`.
3. `idWinding`, `idTraceModel` (dopo piano e bounds; per il lavoro su `cm`).
4. `idMatX`, `idVecX`, `idLCP` (le matrici grandi, dopo `idMat3`).
5. `idParser` (preprocessore) e `idMapFile`.
6. `idBitMsg`.

## 5. Collegamenti ad altri moduli del repository

* `Libs\MathCore`: `TCrc32` e il CRC-32 di idLib; `TVec3`/`TMat3` sono gli array di Doom (tipi diversi dai `TIdVec*`).
* `Libs\Scanner`: scanner dei testi di Doom (`#define`, `#ifdef`), alternativo a `TIdLexer` quando il dialetto e quello di Doom.
* `Libs\Wad`: puo fornire i byte dei file di una mappa dietro `IIdLibFileSystem`.

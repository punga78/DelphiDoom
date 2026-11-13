# Libs\Decl

Gestore delle dichiarazioni di id Tech 4 (Doom 3): tipi registrati, lettura a richiesta, `table`, `skin`, `entityDef` con `inherit`, `pda`. Issue #100, parte della #94.

Il testo di riferimento (contratto per i tipi delle altre issue, riuso, differenze dal C++, difetti trovati, cosa resta) sta in [CLAUDE.md](CLAUDE.md).

## Contenuto

- Unit nella cartella: 18 (nome a punti `DelphiDoom.Decl.*`), una classe per unit. Non hanno chiamanti nel motore.
- Interfacce: `IDeclManager`, `IDeclFinder`, `IDeclRegistry`, `IDeclHost`, `IDecl`, `IDeclBase`, `IDeclType`, `IDeclSource`, e per i dati `IDeclTable`, `IDeclSkin`, `IDeclEntityDef`, `IDeclPda`, `IDeclEmail`, `IDeclVideo`, `IDeclAudio`.
- Licenza: GPL v3 con i termini aggiuntivi di Doom 3 nelle unit portate dal suo codice ("Based on the Doom 3 GPL Source Code", intestazione di ogni unit); GPL v2 o successiva per `Source.Intf`, `Source.Memory` e `Factory`.

## Uso

```pascal
LSource := TDeclMemorySource.Create;            // o un IDeclSource sopra il file system del gioco
LSource.Add('skins/a.skin', 'skin one { model "m" "mat/a" "mat/b" }');
LManager := TDeclFactory.CreateStandardManager(LSource, LLog);   // tipi di Doom 3 e cartelle standard
if Supports(LManager.FindType(DECL_SKIN, 'one'), IDeclSkin, LSkin) then
  ...                                           // il file e' gia' letto, la dichiarazione si interpreta qui
```

Un tipo nuovo: una classe che deriva da `TDecl` e `Registry.RegisterDeclType(...)`, vedi il contratto in CLAUDE.md.

## Prova

- Progetto di test `Tests\DelphiDoom.Tests.Decl`: `Tools\build.bat DelphiDoom.Tests.Decl Release`. 109 test, copertura 96%. Parita' con il vero C++ in `Tests\Data\Decl` ([README dei dati](../../Tests/Data/Decl/README.md)).

## Legami

- Sopra `Libs\IdLib` (`TIdLexer`, `TIdHashIndex`, `TIdMd5`, `TIdStrings`, `TIdMath`) e `Libs\Scanner` (`TIdDict`).
- Indice delle librerie e regole generali: [CLAUDE.md di radice](../../CLAUDE.md).

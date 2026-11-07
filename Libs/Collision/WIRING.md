# Libs\Collision — collegamento

**Oggi nessun chiamante**: DelphiDoom è un port di id Tech 1 (Doom, Heretic, Hexen, Strife) e usa i suoi blockmap e
`P_*Move`; il modello di collisione di id Tech 4 non entra in nessun gioco. Le unit non sono nei `.dpr` dei giochi; le
include da solo `Tests\DelphiDoom.Tests.Collision`. Questo file dice cosa userebbe un chiamante (per esempio un port
id Tech 4, uno strumento che esamina file `.cm`, o un server MCP che risponde a domande di geometria).

## Composition root

Un solo posto crea le classi concrete: `TCollisionFactory` (`DelphiDoom.Collision.Factory`).

```pascal
var
  LCatalog: ICollisionMaterialCatalog;   // dal chiamante: nome -> TCollisionMaterial
  LManager: ICollisionModelManager;
  LBuilder: TCollisionModelBuilder;
  LModel: TCollisionModel;
begin
  LManager := TCollisionFactory.CreateManager(LCatalog, LLog);   // LLog: ILog di Libs\Logging, può essere nil
  // 1. da un file .cm
  LManager.LoadModelFile(LStream, LMapFileCrc);
  // 2. da brush e poligoni
  LBuilder := TCollisionFactory.CreateBuilder(LLog);
  try
    LModel := LBuilder.Build(LGeometrySource);    // ICollisionGeometrySource
  finally
    LBuilder.Free;
  end;
  LHandle := LManager.AddModel(LModel);            // il manager ne diventa proprietario
  // 3. interrogazioni
  LManager.Translation(LTrace, LStart, LEnd, LTrm, LTrmAxis, LContentMask, LHandle, LOrigin, LAxis);
end;
```

## Cosa deve dare il chiamante

| Servizio | Interfaccia | Cosa sostituisce |
|---|---|---|
| materiali: nome, `Contents`, due facce | `ICollisionMaterialCatalog` (`FindMaterial`) con `TCollisionMaterial` | `idMaterial`, `declManager->FindMaterial`; deve contenere `_tracemodel` e vivere quanto i modelli |
| geometria da convertire | `ICollisionGeometrySource` (brush con i lati, poligoni sciolti con piano e materiale) | `idMapEntity`/`idMapBrush`; per una mappa Doom 3 serve un adattatore dal parser del `.map`; per patch o modelli ASE/LWO, i poligoni già triangolati |
| log | `ILog` (`Libs\Logging`), opzionale | `common->Printf/Warning` |
| file | `TStream` per `LoadModelFile` e `TCollisionFileWriter.ToStream`; testo per `Parse`/`ToText` | `fileSystem` (aprire, nominare e chiudere i file è del chiamante) |
| disegno di debug | nessuno oggi | `DrawModel`, `cm_draw*`: se serve, un `ICollisionDebugDraw` con `DrawLine`/`DrawText` dato al manager; la camminata dei poligoni di un modello è già in `TCollisionModel.TreePolygons` |

Il chiamante possiede i `TTraceModel` che passa e il catalogo; il manager possiede i modelli e il suo slot del trace
model. Una traccia alla volta per manager (come il C++).

## Come passare dal C++ al Delphi, punto per punto

| Chi chiama nel motore C++ | Chiamata Delphi |
|---|---|
| `collisionModelManager->Translation( &trace, start, end, trm, trmAxis, mask, model, origin, axis )` | `ICollisionModelManager.Translation( LTrace, ... )`; `trm = nil` traccia un punto |
| `collisionModelManager->Contents( start, trm, axis, mask, model, origin, axis )` | `ICollisionModelManager.Contents( ... )` |
| `collisionModelManager->Contacts( contacts, max, start, dir6, depth, ... )` | `Contacts( LList, max, start, dir3, depth, ... )`: la parte rotazionale di `idVec6` non esiste (nel C++ è un FIXME) |
| `LoadModel( name )` / `FindModel` | `FindModel( name )` dopo `LoadModelFile` o `AddModel`: il nome è il campo `Name` del modello |
| `SetupTrmModel( trm, material )` | `SetupTrmModel( LTrm, LMaterial )`: il modello resta valido fino alla chiamata successiva (handle `TRACE_MODEL_HANDLE`) |
| `TrmFromModel( name, trm )` | `TrmFromModel( handle, LTrm )` |
| `GetModelVertex/Edge/Polygon/Bounds/Contents/Name` | stessi nomi, con `TGeoWinding` (da liberare) per il poligono; il numero del poligono è l'`Id` di un contatto (`C.ModelFeature`) |
| `Rotation( ... )` | **non c'è** (vedi `README.md`): un chiamante che la usa va fermato prima |

## Prestazioni e thread

- Le tracce allocano un `TCmTraceWork` (circa 13 KB) per chiamata e liberano a fine chiamata: se il chiamante ne fa
  decine di migliaia al secondo, un pool è il passo successivo (un campo del manager, dietro la stessa interfaccia).
- Gli elenchi di riferimenti dei nodi sono `TList` con inserimento in testa (O(n)): costruire modelli con decine di
  migliaia di poligoni nello stesso nodo è lento; la costruzione si fa una volta, fuori dal percorso caldo.
- Il manager non è thread safe; più manager indipendenti sì (nessuno stato globale).

## Win64

Le unit compilano e i test passano sia a Win32 sia a Win64 (`dcc64`): nessun puntatore in un intero, nessun `asm`, nessun
`{$L}`. Le risposte possono differire all'ultimo bit del `Single` tra le due piattaforme (vedi `README.md`).

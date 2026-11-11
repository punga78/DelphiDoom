# Libs\XcomUfopaedia

L'**Ufopaedia** di OpenXcom (`src\Ufopaedia\*`) a classi senza SDL, una classe per unit, sopra `Libs\XcomEngine`,
`XcomUi`, `XcomSurface`, `XcomMod`, `XcomSave`, `XcomBasescape` (`TXcomFunding`) e `XcomGeoscape` (`TXcomStrategy`,
solo nella factory). Issue #176.

**Licenza**: codice derivato da OpenXcom (GPL v3 o successiva, vedi le intestazioni e `Libs\XcomFormats\README.md`);
la sceglie l'utente.

## Classi

| C++ (`src\Ufopaedia`) | Unit / classe | Note |
|---|---|---|
| `Ufopaedia::isArticleAvailable`, `getAvailableArticles`, `list`, `getArticleIndex` | `DelphiDoom.XcomUfopaedia.Catalog` / `TXcomUfopaediaCatalog` (`IXcomUfopaediaCatalog`) | logica pura: regole e una funzione "queste ricerche sono fatte?"; `NextIndex`/`PreviousIndex` sono l'aritmetica di `next`/`prev` |
| `Ufopaedia::open`, `openArticle` (x2), `next`, `prev`, `createArticleState`, `_current_index` | `DelphiDoom.XcomUfopaedia.Navigator` / `TXcomUfopaediaNavigator` (`IXcomUfopaediaNavigator`) | lo `static _current_index` e' un campo: un navigatore per visita, condiviso dalle schermate |
| `UfopaediaStartState` | `...StartState` / `TXcomUfopaediaStartState` | al massimo 10 pulsanti, frecce e rotella per le altre sezioni |
| `UfopaediaSelectState` | `...SelectState` / `TXcomUfopaediaSelectState` | |
| `ArticleState` | `...ArticleState` / `TXcomArticleState` (astratta, costruttore virtuale) | sfondo, OK, `<<`, `>>` |
| `ArticleStateText`, `TextImage`, `Armor`, `BaseFacility`, `Craft`, `CraftWeapon`, `Item`, `Ufo`, `Vehicle` | `...ArticleStateText` ... / `TXcomArticleStateText` ... | tipi 1-9 (UFO: Enemy Unknown) |
| `ArticleStateTFTD`, `TFTDArmor`, `TFTDCraft`, `TFTDCraftWeapon`, `TFTDFacility`, `TFTDItem`, `TFTDUso`, `TFTDVehicle` | `...ArticleStateTftd` ... / `TXcomArticleStateTftd` ... | tipi 10-17 (Terror from the Deep) |
| `ArticleState::getDamageTypeText`, le righe di statistiche scritte due volte (UFO e TFTD) | `...ArticleFormat` / `TXcomArticleFormat` | senza widget: righe `TXcomArticleRow` (id dell'etichetta, valore) |
| - | `...Factory` / `TXcomUfopaediaFactory` | l'unica unit che sa dov'e' il salvataggio (`TXcomStrategy`) |
| `ArticleDefinition*` (`src\Mod`) | gia' in `Libs\XcomMod` (`TXcomArticleDefinition`, `TXcomRuleset.Articles`) | non toccato |

## Proprieta'

Le schermate sono del gioco (pila degli stati). Catalogo e navigatore sono interfacce contate: ogni schermata ne
tiene un riferimento, il navigatore tiene l'host senza possederlo. Regole, articoli e set di sprite sono delle risorse
del gioco.

## Collegamenti

- Pulsante Ufopaedia del geoscape: `TXcomGameNavigator.OpenUfopaedia` (`OpenXcom\DelphiDoom.Xcom.GeoscapeNavigator.pas`).
- "View reports" di una ricerca finita: `TXcomPopupGeoscapeEvents` riceve dal composition root una procedura che apre
  gli articoli (`OpenXcom\DelphiDoom.Xcom.GameComposition.pas`).

Stato, verifiche e differenze dichiarate: `CLAUDE.md` di questa cartella.

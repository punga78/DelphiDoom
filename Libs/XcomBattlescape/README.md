# Libs\XcomBattlescape

> Note per Claude: [CLAUDE.md](CLAUDE.md).

Il **disegno della battaglia** di **OpenXcom** a classi, senza SDL (issue #176): la mappa tattica (`Map`), la camera (`Camera`) e lo sprite delle unita' (`UnitSprite`), sopra `Libs\XcomBattle` (il modello e le regole della battaglia), `Libs\XcomSurface` (`TXcomSurface`, i blit con ombreggiatura) e `Libs\XcomFormats` (PCK/TAB). Licenza: derivato da OpenXcom, GPL v3 o successiva (da decidere per l'opera, `Libs\XcomFormats\README.md`).

| C++ | Delphi | Stato |
|---|---|---|
| `Camera` (offset, livello, conversioni tegola/voxel/schermo, scorrimento, `isOnScreen`) | `TXcomCamera` | portata |
| `Map::draw`/`drawTerrain`/`drawUnit` (pavimento, muri, oggetti, oggetto sul pavimento, unita' con maschera di tegola, fuoco, fumo, cursore 3D, freccia dell'unita' scelta) | `TXcomBattleMap` | portata; **77 mappe su 77 identiche** al vero `Map::draw()` (14 scenari) e 27 mappe di tre scenari di scena (esplosioni, lampo) identiche (vedi CLAUDE.md) |
| `Map::animate`, `cacheUnit(s)`, `calculateWalkingOffset`, `setCursorType` | `TXcomBattleMap` | portati |
| `UnitSprite` (routine 0 con 10, 13, 14, 15; 4 con 17 e 18; 11; 12 con 16; 19; 20; 21: quelle di TFTD; `drawRecolored`, `sortRifles`) | `TXcomUnitSprite` | portata (i colori dei soldati sono verificati; vedi le differenze aperte nel CLAUDE.md) |
| `Mod::getSurfaceSet` (UNITS, UFOGRAPH, TERRAIN) e la "correzione" dei colori delle armature TFTD (`TDXCOM_0..2`) | `IXcomBattleSprites`, `TXcomModSprites` | portati |
| la vista di `BattlescapeGame` su `Map` e `Camera` | `TXcomBattleMapView` (`IXcomBattleView`) | portata |
| `Particle` (vapore sott'acqua) e `Mod::createTransparencyLUT` (tabelle di trasparenza, identiche alle vere) | `TXcomParticle`, `TXcomTransparencyTable` | portate |
| `Explosion`, `Map::setExplosionInFOV`/`setBlastFlash` e il disegno di esplosioni, colpi e lampo; `enableObstacles`/`resetObstacles` e l'ombra degli ostacoli | `TXcomExplosion`, `TXcomBattleMap` | portati (27 mappe di scena identiche); l'animazione che fa da sola `ExplosionBState` non e' collegata alla vista |
| routine di `UnitSprite` 1-3, 5-9 (Enemy Unknown: nessuno scenario di TFTD le raggiunge), proiettili in volo (`Projectiles`, `castedShade`), anteprima del percorso, waypoint e numeri dei TU, messaggio del movimento nascosto, bolle del respiro | | **non portati** |
| `BattlescapeState`, `InventoryState`, `UnitInfoState`, `DebriefingState`, `NextTurnState`, `ActionMenuState`... | | **non portati** |

# XcomBattle

Modello e logica della battaglia tattica di OpenXcom (Battlescape), senza interfaccia: tegole, unita', oggetti, battaglia salvata, percorsi, luce e visibilita', esplosioni e generazione di una missione (mappa dallo script, UFO e velivoli, X-COM, alieni, civili); nelle fette successive proiettili, azioni, intelligenza artificiale.

- **Derivato da OpenXcom** (GPL v3 o successiva). La licenza del derivato la decide l'utente (README di `Libs\XcomFormats`).
- Dipende da `Libs\XcomMod`, `Libs\XcomSave` e `Libs\Yaml`.
- Parita': `Tools\Verifica\176\battle` (oggetti di una vera build di OpenXcom collegati a un harness), dati in `Tests\Data\XcomBattle`.
- Test: `Tests\DelphiDoom.Tests.XcomBattle`.
- Dettagli per chi lavora sul codice: [CLAUDE.md](CLAUDE.md).

Fatto anche: proiettili (`TXcomProjectile`), tiro e lancio (`getOriginVoxel`, `validateThrow`), colpi (`TileEngine::hit`) e l'intelligenza artificiale (`TXcomAIThinker`), con parita' sul vero OpenXcom. Non fatto: `BattlescapeGame` e gli stati delle azioni, il disegno e gli stati dell'interfaccia (vedi CLAUDE.md).

Aggiornamento (sessione "collegamenti", #176): `TXcomBattlescapeGenerator.NextStage` (seconda fase di una missione) con parita' sul vero `nextStage` (18 casi, 0 differenze).

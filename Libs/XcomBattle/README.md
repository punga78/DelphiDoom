# XcomBattle

Modello e logica della battaglia tattica di OpenXcom (Battlescape), senza interfaccia: tegole, unita', oggetti, battaglia salvata e, nelle fette successive, percorsi, luce e visibilita', esplosioni, intelligenza artificiale e generazione della mappa.

- **Derivato da OpenXcom** (GPL v3 o successiva). La licenza del derivato la decide l'utente (README di `Libs\XcomFormats`).
- Dipende da `Libs\XcomMod`, `Libs\XcomSave` e `Libs\Yaml`.
- Parita': `Tools\Verifica\176\battle` (oggetti di una vera build di OpenXcom collegati a un harness), dati in `Tests\Data\XcomBattle`.
- Test: `Tests\DelphiDoom.Tests.XcomBattle`.
- Dettagli per chi lavora sul codice: [CLAUDE.md](CLAUDE.md).

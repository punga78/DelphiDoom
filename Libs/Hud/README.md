# Libs\Hud

HUD del motore (messaggi in alto, chat in rete, widget di testo, contatore dei fotogrammi al secondo, tempo del livello, mirino, layout dei glifi) a classi. Prima fetta della fase 1 del piano "tutto a classi" (issue #185, `docs\PIANO_TUTTO_A_CLASSI.md`): `Base\hu_stuff.pas` e `Base\hu_lib.pas` sono facciate sopra questa libreria.

Il testo di riferimento sta in [CLAUDE.md](CLAUDE.md).

## Contenuto

- Unit nella cartella: 18 (nome a punti `DelphiDoom.Hud.*`), 15 classi.
- Interfacce dichiarate: `IHeadsUp`, `IHudView`, `IHudFlags`, `IHudPlayers`, `IHudPlayerMessage`, `IHudSettings`, `IHudChatSound`, `IHudEcho`, `IHudMessageTarget`.
- Punto di creazione delle classi: `DelphiDoom.Hud.Factory`.
- Il disegno (V_DrawPatch) e il collegamento ai globali del motore stanno fuori dalla libreria, in `Base\DelphiDoom.Engine.Hud.*`.

## Prova

- Progetto di test in `Tests\`: `DelphiDoom.Tests.Hud` (167 test, copertura 100%, con la parita' contro il codice vecchio in `DelphiDoom.Tests.Hud.Legacy`). Si compila con `Tools\build.bat` (vedi "Build e prove" nel [CLAUDE.md di radice](../../CLAUDE.md)).

## Legami

- Indice delle librerie e regole generali: [CLAUDE.md di radice](../../CLAUDE.md).
- Piano e stato della fetta: `docs\PIANO_TUTTO_A_CLASSI.md` (par. 8), facciate: `docs\FACCIATE.md`.

# Libs\XcomUi

> Note per Claude: [CLAUDE.md](CLAUDE.md).

I widget di `Interface\` di **OpenXcom** a classi e senza SDL (issue #176): derivano da `TXcomWidget` / `TXcomInteractiveSurface` di `Libs\XcomEngine` e disegnano su `TXcomSurface` di `Libs\XcomSurface`. Licenza: derivato da OpenXcom, GPL v3 o successiva (da decidere per l'opera, `Libs\XcomFormats\README.md`).

| C++ | Delphi | Stato |
|---|---|---|
| `Text` (misura, a capo per parole o lettere, rientro, allineamenti, colori, `PaletteShift`, scorrimento) | `TXcomText`, `TXcomPaletteShift` | portato, parita' sui pixel col vero OpenXcom |
| `Window` (bordo in 5 sfumature o sottile, sfondo, popup) | `TXcomWindow` | portato, parita' sui pixel |
| `TextButton` (bordo, inversione, gruppo, combo) | `TXcomTextButton`, `TXcomButtonGroup` | portato, parita' sui pixel |
| `Frame`, `NumberText`, `Cursor`, `FpsCounter` | `TXcomFrame`, `TXcomNumberText`, `TXcomCursor`, `TXcomFpsCounter` | portati (il cursore con Bresenham: SDL_gfx non c'e') |
| `TextList`, `ComboBox`, `TextEdit`, `Slider`, `ScrollBar`, `ArrowButton`, `ToggleTextButton`, `Bar`, `ImageButton`, `BattlescapeButton` | | **non portati** |

Differenze: il suono dei pulsanti e dei popup non c'e'; `TextButton.SetGroup` prende un `TXcomButtonGroup` (il `TextButton **` del C++); `SetComboToggle` prende una chiusura (il `ComboBox *`). Test e copertura: `Tests\DelphiDoom.Tests.XcomEngine` (96%).

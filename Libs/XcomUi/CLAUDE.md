# Libs\XcomUi - note per Claude

`Libs\XcomUi` (issue #176, fetta "interfaccia") e' `Interface\` di **OpenXcom** a classi senza SDL: `TXcomText` (con `TXcomPaletteShift`, il `ShaderDraw<PaletteShift>` dei caratteri), `TXcomWindow`, `TXcomTextButton` (+ `TXcomButtonGroup`), `TXcomFrame`, `TXcomNumberText`, `TXcomCursor`, `TXcomFpsCounter`; tipi in `DelphiDoom.XcomUi.Types` (`TXcomTextHAlign`, `TXcomTextVAlign`, `TXcomWindowPopup`, i token `#1` colore alternato e `#2` nuova riga piccola). Sopra `Libs\XcomEngine` e `Libs\XcomSurface`. **Non tocca** `ComposeEngine` ne' `TIdTechGeneration`. **Licenza**: derivato da OpenXcom, GPL v3 o successiva; la decide l'utente.

**Parita'**: `Text`, `Window` e `TextButton` sono verificati sul frame vero del menu principale (0 pixel diversi su 256000, vedi `Libs\XcomEngine\CLAUDE.md`). `Frame`, `NumberText`, `Cursor`, `FpsCounter` hanno solo i test sui valori dei pixel calcolati dal C++ (non c'e' un confronto col programma vero: non sono nei frame confrontati).

**Trappole**: un testo ha il suo font solo dopo `InitText` (lo fa `TXcomState.Add`); `Text.SetText` passa al font piccolo se il testo grande non sta e non finisce con un punto; `Window` con popup nasconde le altre superfici e toglie lo stato da "schermo" finche' non e' aperta; il testo di un pulsante e' una `TXcomText` posseduta; `TXcomPaletteShift` scrive `Byte(colore + pixel * mul + inverso)` con avvolgimento a 8 bit.

**Non portato**: `TextList`, `ComboBox`, `TextEdit`, `Slider`, `ScrollBar`, `ArrowButton`, `ToggleTextButton`, `Bar`, `ImageButton`, `BattlescapeButton`.

Test: `Tests\DelphiDoom.Tests.XcomEngine` (copertura XcomUi 96%).

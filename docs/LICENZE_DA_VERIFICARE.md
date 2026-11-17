# Intestazioni di licenza non uniformate (da verificare)

Documento della issue #157 (refs), 2026-11-17. Elenco delle unit che parlano di Doom 3 o di OpenXcom e che lo script Tools\Verifica\157\Uniforma-Intestazioni.ps1 **non ha toccato**, con il motivo. Si decide una per una; lo script e' ripetibile (una unit gia' uniforme non cambia) e riconosce solo le formule note, quindi dopo la decisione basta aggiungere la formula o correggere a mano il solo blocco dell'intestazione.

Cosa ha fatto lo script (decisioni dell'utente del 2026-11-17): nelle unit derivate da **Doom 3** il paragrafo di licenza dice ora *GNU General Public License, version 3 or (at your option) any later version, con gli additional terms of the Doom 3 Source Code License (Reference\doom3\COPYING.txt: avvisi legali e di marchio, nessun uso dei nomi dei licenzianti, manleva)*; in quelle derivate da **OpenXcom** (Games\Xcom*, Games\OpenXcom) la dicitura *GPL v3 or later* e' scritta per esteso con la stessa formula. Cambia solo il blocco {***} in testa; corpo, BOM e fine riga sono identici (prova con -Verify).

## Unit derivate da Doom 3 non toccate

### Dicono v2 o successive e citano Doom 3 senza i termini aggiuntivi (17 + 63 test)

Probabile codice scritto per il repository (contratti, registrazioni, test) o riscrittura da una RFC (Md4/Md5: *rewrite from RFC 1320*): non derivano da un file di Doom 3, quindi restano v2 o successive. Se invece una di queste copia codice di Doom 3 va portata a v3 o successive.

- `Framework\IdLib\Hashing\DelphiDoom.IdLib.Hashing.Md4.pas`
- `Framework\IdLib\Hashing\DelphiDoom.IdLib.Hashing.Md5.pas`
- `Framework\IdLib\Hashing\DelphiDoom.IdLib.Hashing.Types.pas`
- `Framework\MathCore\DelphiDoom.MathCore.Float.GeometryAdapter.pas`
- `Framework\Texture\DelphiDoom.Texture.Dds.BlockDecoder.pas`
- `Framework\Texture\DelphiDoom.Texture.Dds.Reader.pas`
- `IdTech4\Decl\DelphiDoom.Decl.ArticulatedFigure.Intf.pas`
- `IdTech4\Decl\DelphiDoom.Decl.Fx.Intf.pas`
- `IdTech4\Decl\DelphiDoom.Decl.Fx.Registration.pas`
- `IdTech4\Decl\DelphiDoom.Decl.Particle.Intf.pas`
- `IdTech4\Decl\DelphiDoom.Decl.Particle.Registration.pas`
- `IdTech4\Decl\DelphiDoom.Decl.Sound.CacheCatalog.pas`
- `IdTech4\Decl\DelphiDoom.Decl.Sound.Intf.pas`
- `IdTech4\Decl\DelphiDoom.Decl.Sound.NameCatalog.pas`
- `IdTech4\Decl\DelphiDoom.Decl.Sound.Registration.pas`
- `IdTech4\Gui\DelphiDoom.Gui.Window.Intf.pas`
- `Tests\DelphiDoom.Tests.D3Host.dpr`
- tutti i file di `Tests\Source` che citano Doom 3 (63) e `Tests\DelphiDoom.Tests.D3Host.dpr`: i test non sono derivati dai sorgenti di Doom 3

### Citano Doom 3 e Quake III e dichiarano v2 o successive (2)

- `IdTech4\Decl\DelphiDoom.Decl.FileScanner.Intf.pas`
- `IdTech4\Gui\DelphiDoom.Gui.PrecompilerSource.pas`

### Unit miste Quake III (GPL v2 o successive) e Doom 3 (GPL v3), con formula non standard (7)

Il decoder RoQ di Quake III e di Doom 3 e il disegno di Gui: l'opera combinata ricade nella v3, ma la formula non e' quella delle altre unit e serve scegliere come scriverla.

- `Framework\Cinematic\DelphiDoom.Cinematic.Codebook.pas`
- `Framework\Cinematic\DelphiDoom.Cinematic.Decoder.pas`
- `Framework\Cinematic\DelphiDoom.Cinematic.FramePainter.pas`
- `Framework\Cinematic\DelphiDoom.Cinematic.QuadMap.pas`
- `Framework\Cinematic\DelphiDoom.Cinematic.Types.pas`
- `Framework\Cinematic\DelphiDoom.Cinematic.YuvConverter.pas`
- `IdTech4\Gui\DelphiDoom.Gui.DeviceContext.Intf.pas`

### Termini aggiuntivi di Doom 3 scritti con parole diverse (6)

- `Framework\Audio\DelphiDoom.Audio.D3.Intf.pas`
- `Framework\Audio\DelphiDoom.Audio.WaveFile.Intf.pas`
- `Framework\Cinematic\DelphiDoom.Cinematic.Player.pas`
- `IdTech4\Collision\DelphiDoom.Collision.CmFile.Tokenizer.pas`
- `IdTech4\Collision\DelphiDoom.Collision.Factory.pas`
- `Tests\DelphiDoom.Tests.Collision.dpr`
- `Tests\DelphiDoom.Tests.Collision.dpr`

### Unit v2 o successive con "le parti derivate da Doom 3 sono v3" (3)

Dicono che la unit e' v2 o successive e che solo alcune parti sono v3: da decidere quali parti (contratti e eccezioni scritti per il repository, o porting).

- `Framework\IdLib\Core\DelphiDoom.IdLib.Core.Exceptions.pas`
- `Framework\IdLib\Core\DelphiDoom.IdLib.Core.Intf.pas`
- `IdTech4\Decl\DelphiDoom.Decl.Source.Intf.pas`

## Unit derivate da OpenXcom non toccate

### Intestazione rovinata (12)

Dicono gia' *GPL v3 or later*, ma la riga del titolo non ha la graffa di chiusura e il bordo inferiore e' attaccato alla riga `unit` (difetto preesistente dell'intestazione). Lo script non scrive un blocco che non sa leggere: va corretta a mano, poi rilanciare lo script.

- `Games\XcomEngine\DelphiDoom.XcomEngine.DiskSaveCatalog.pas`
- `Games\XcomEngine\DelphiDoom.XcomEngine.SaveCatalog.Intf.pas`
- `Games\XcomEngine\DelphiDoom.XcomEngine.SaveInfo.pas`
- `Games\XcomMenu\DelphiDoom.XcomMenu.DeleteGameState.pas`
- `Games\XcomMenu\DelphiDoom.XcomMenu.ListGamesState.pas`
- `Games\XcomMenu\DelphiDoom.XcomMenu.ListLoadState.pas`
- `Games\XcomMenu\DelphiDoom.XcomMenu.LoadGameState.pas`
- `Games\XcomMenu\DelphiDoom.XcomMenu.OptionsAdvancedState.pas`
- `Games\XcomMenu\DelphiDoom.XcomMenu.OptionsBattlescapeState.pas`
- `Games\XcomMenu\DelphiDoom.XcomMenu.OptionsControlsState.pas`
- `Games\XcomMenu\DelphiDoom.XcomMenu.OptionsFoldersState.pas`
- `Games\XcomMenu\DelphiDoom.XcomMenu.OptionsGeoscapeState.pas`

### Dichiarano v2 o successive e citano OpenXcom: unit miste (4)

- `Games\OpenXcom\DelphiDoom.Xcom.ExportArguments.pas`
- `Games\XcomEngine\DelphiDoom.XcomEngine.ExtraChoiceOptions.Intf.pas`
- `Games\XcomEngine\DelphiDoom.XcomEngine.ExtraOptionSet.pas`
- `Games\XcomEngine\DelphiDoom.XcomEngine.FontGridGenerator.pas`

### Dichiarano v2 o successive e non dicono di derivare da OpenXcom (36)

Codice nato per questo repository (caratteri di sistema, overlay dei font, file atomici, log degli errori, uscita PCM: non c'e' codice di OpenXcom). Non classificabili con certezza: se non derivano da OpenXcom restano v2 o successive, ma `Xcom32` (che le usa) e' v3 o successive come eseguibile. `Xcom.MemoryCount` ha il testo intero della GPL v2 ("either version 2 of the License").

- `Games\OpenXcom\DelphiDoom.Xcom.LoggingBattleAudio.pas`
- `Games\OpenXcom\DelphiDoom.Xcom.MemoryCount.pas`
- `Games\OpenXcom\DelphiDoom.Xcom.ScriptPcmOutput.pas`
- `Games\OpenXcom\DelphiDoom.Xcom.StackScan.pas`
- `Games\OpenXcom\DelphiDoom.Xcom.Win.GdiGlyphRasterizer.pas`
- `Games\OpenXcom\DelphiDoom.Xcom.Win.GdiGlyphRasterizerFactory.pas`
- `Games\OpenXcom\DelphiDoom.Xcom.Win.GdiSystemFonts.pas`
- `Games\XcomBattleStates\DelphiDoom.XcomBattleStates.OffsetBlit.pas`
- `Games\XcomEngine\DelphiDoom.XcomEngine.AtomicFiles.Intf.pas`
- `Games\XcomEngine\DelphiDoom.XcomEngine.AtomicFileWriter.pas`
- `Games\XcomEngine\DelphiDoom.XcomEngine.DetailFont.pas`
- `Games\XcomEngine\DelphiDoom.XcomEngine.ErrorLog.pas`
- `Games\XcomEngine\DelphiDoom.XcomEngine.ErrorLog.Types.pas`
- `Games\XcomEngine\DelphiDoom.XcomEngine.FontChoices.pas`
- `Games\XcomEngine\DelphiDoom.XcomEngine.FontReapplier.Intf.pas`
- `Games\XcomEngine\DelphiDoom.XcomEngine.FontReloader.Intf.pas`
- `Games\XcomEngine\DelphiDoom.XcomEngine.FontReloader.pas`
- `Games\XcomEngine\DelphiDoom.XcomEngine.FontSettingsReader.pas`
- `Games\XcomEngine\DelphiDoom.XcomEngine.FontSettingsSource.Intf.pas`
- `Games\XcomEngine\DelphiDoom.XcomEngine.FontSettingsWriter.pas`
- `Games\XcomEngine\DelphiDoom.XcomEngine.OptionsAudit.Intf.pas`
- `Games\XcomEngine\DelphiDoom.XcomEngine.OptionsAuditLog.pas`
- `Games\XcomEngine\DelphiDoom.XcomEngine.RasterFontOverlay.pas`
- `Games\XcomEngine\DelphiDoom.XcomEngine.SystemFonts.Intf.pas`
- `Games\XcomSurface\DelphiDoom.XcomSurface.DetailGlyphBuilder.pas`
- `Games\XcomSurface\DelphiDoom.XcomSurface.FontDetail.Intf.pas`
- `Games\XcomSurface\DelphiDoom.XcomSurface.FontOverlay.Intf.pas`
- `Games\XcomSurface\DelphiDoom.XcomSurface.FontOverlayBuilder.pas`
- `Games\XcomSurface\DelphiDoom.XcomSurface.Glyph.Types.pas`
- `Games\XcomSurface\DelphiDoom.XcomSurface.GlyphLevels.pas`
- `Games\XcomSurface\DelphiDoom.XcomSurface.GlyphRasterizer.Intf.pas`
- `Games\XcomSurface\DelphiDoom.XcomSurface.Ink.Types.pas`
- `Games\XcomSurface\DelphiDoom.XcomSurface.InkPainter.pas`
- `Games\XcomSurface\DelphiDoom.XcomSurface.TtfFamilyName.pas`
- `Games\XcomUi\DelphiDoom.XcomUi.TextInk.pas`
- `Games\XcomUi\DelphiDoom.XcomUi.WidgetInk.pas`

### Formula non prevista (1)

- `Games\OpenXcom\DelphiDoom.Xcom.TrueColorOption.pas` dice *Licensed under the GNU General Public License, version 3 or later*: gia' v3 o successive, scritta in altra forma.

### Fuori dall'ambito dello script (gia' v3 o successive, non normalizzate)

Le unit derivate da OpenXcom che stanno fuori da `Games\` (`Framework\Opl` con XcomAdlib.*, `Framework\GameHost`, `Framework\Flic`, `Framework\Bytes`, `Framework\AudioMix`, `Framework\Cinematic\Flic`) hanno gia' *GPL v3 or later* e non sono state toccate (`Opl` ha anche il mopl LGPL 2.1 da conservare; `Bytes` ha unit con entrambe le diciture). Le terze parti di `Games\XcomSurface` (SDL_gfx zlib/LGPL) conservano la propria licenza.

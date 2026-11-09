{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TFontEditorPresenter (issue #167)                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.FontEditor.Presenter;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.Tools.Intf,
  DelphiDoom.Font.Types,
  DelphiDoom.Font.Settings,
  DelphiDoom.Font.Intf,
  DelphiDoom.FontEditor.Types,
  DelphiDoom.FontEditor.Intf,
  DelphiDoom.FontEditor.Presenter,
  DelphiDoom.Tests.ToolsCore.Fakes,
  DelphiDoom.Tests.Font.Fakes,
  DelphiDoom.Tests.FontEditor.Fakes;

type
  /// <summary>
  ///   The presenter with the real model (composers of the font library drawing the characters of the tests, the
  ///   WAD generator, undo, recent files, settings, backup) and fakes for what is the system: the window, the
  ///   dialogs, the fonts of the machine, the exporter of pictures and the files
  /// </summary>
  [TestFixture]
  [Category('fonteditor')]
  TTestFontEditorPresenter = class(TObject)
  strict private
    const
      INI_FILE = 'C:\tools\tools.ini';
      PROJECT_FILE = 'C:\work\mine.ddp';
    var
      FView: TFakeFontView;
      FViewIntf: IFontEditorView;
      FDialogs: TFakeFontDialogs;
      FDialogsIntf: IFontEditorDialogs;
      FCatalog: TFakeFontCatalog;
      FCatalogIntf: IFontCatalog;
      FInstaller: TFakeFontInstaller;
      FInstallerIntf: IFontInstaller;
      FExporter: TFakeFontImageExporter;
      FExporterIntf: IFontEditorImageExporter;
      FRasterizer: TSyntheticRasterizer;
      FRasterizerIntf: IFontRasterizer;
      FFileSystem: TFakeToolFileSystem;
      FFileSystemIntf: IToolFileSystem;
      FPresenter: TFontEditorPresenter;
    function NewPresenter: TFontEditorPresenter;
    procedure StartFresh;
    function Wad(const AFileName: string): TBytes;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeMostrareAllAvvioLaGrigliaLAnteprimaEIlTitolo;
    [Test]
    procedure DovrebbeElencareIFontDellaMacchina;
    [Test]
    procedure DovrebbeLeggereLeImpostazioniDelVecchio;
    [Test]
    procedure DovrebbeLimitareLaCellaELoZoomLetti;
    [Test]
    procedure DovrebbeSalvareLeImpostazioniAllaChiusura;
    [Test]
    procedure DovrebbeRifiutareLeDipendenzeNil;
    [Test]
    procedure DovrebbeScegliereUnFontDellElencoEIgnorareUnNomeCheNonCe;
    [Test]
    procedure DovrebbeAnnullareERifareUnCambiamento;
    [Test]
    procedure DovrebbeAccendereEspegnereGliStili;
    [Test]
    procedure DovrebbeIngrandireEImpicciolireIlFontNeiPassiDelVecchio;
    [Test]
    procedure DovrebbeScegliereIColoriDalDialogo;
    [Test]
    procedure DovrebbeNonCambiareIColoriSeIlDialogoEAnnullato;
    [Test]
    procedure DovrebbeLimitareLaCellaDa5A32;
    [Test]
    procedure DovrebbeNonSegnareModificatoSeNienteCambia;
    [Test]
    procedure DovrebbeDisegnareLaGrigliaDiNuovoQuandoCambiaIlFont;
    [Test]
    procedure DovrebbeFarePassareLoZoomEIlReticolo;
    [Test]
    procedure DovrebbeDareLAnteprimaDellaPaginaScelta;
    [Test]
    procedure DovrebbeNonPermetterediFareIlWadDiUnTestoDiSoliSpazi;
    [Test]
    procedure DovrebbeFareIlWadDelTestoEScriverloConLaCopiaDiSicurezza;
    [Test]
    procedure DovrebbeFareIlWadDeiCaratteriEDelleCifre;
    [Test]
    procedure DovrebbeUsareLaPaletteDiUnFileOLaScalaDiGrigi;
    [Test]
    procedure DovrebbeNonFareIlWadSeLUtenteAnnulla;
    [Test]
    procedure DovrebbeAvvisareSeIlWadNonSiScrive;
    [Test]
    procedure DovrebbeEsportareLaGrigliaInUnaImmagine;
    [Test]
    procedure DovrebbeAvvisareSeLEsportazioneFallisce;
    [Test]
    procedure DovrebbeUsareUnFontDaFile;
    [Test]
    procedure DovrebbeAvvisareUnFontGiaCaricatoOCheNonSiCarica;
    [Test]
    procedure DovrebbeRestituireIFontCaricatiAllaChiusura;
    [Test]
    procedure DovrebbeSalvareEAprireUnProgetto;
    [Test]
    procedure DovrebbeChiedereIlNomeSeIlProgettoNonLoHa;
    [Test]
    procedure DovrebbeAvvisareSeIlProgettoNonSiLegge;
    [Test]
    procedure DovrebbeTenereIlProgettoDellaRigaDiComando;
    [Test]
    procedure DovrebbeRicordareIFileRecenti;
    [Test]
    procedure DovrebbeChiedereSeSalvareLeModificheAllaChiusura;
    [Test]
    procedure DovrebbeRipartireDaUnProgettoNuovo;
  end;

implementation

uses
  DelphiDoom.Tools.Factory, DelphiDoom.Tools.Types,
  DelphiDoom.Wad.Types, DelphiDoom.Wad.Intf, DelphiDoom.Wad.Factory,
  DelphiDoom.Palette.GamePalettes,
  DelphiDoom.Font.Factory, DelphiDoom.Font.SettingsFormat;

{ TTestFontEditorPresenter }

procedure TTestFontEditorPresenter.Setup;
begin
  FView := TFakeFontView.Create;
  FViewIntf := FView;
  FDialogs := TFakeFontDialogs.Create;
  FDialogsIntf := FDialogs;
  FCatalog := TFakeFontCatalog.Create;
  FCatalog.Names := ['Arial', 'Doom', 'Verdana'];
  FCatalogIntf := FCatalog;
  FInstaller := TFakeFontInstaller.Create;
  FInstaller.Catalog := FCatalog;
  FInstallerIntf := FInstaller;
  FExporter := TFakeFontImageExporter.Create;
  FExporterIntf := FExporter;
  FRasterizer := TSyntheticRasterizer.Create;
  FRasterizerIntf := FRasterizer;
  FFileSystem := TFakeToolFileSystem.Create;
  FFileSystemIntf := FFileSystem;
  FPresenter := NewPresenter;
end;

procedure TTestFontEditorPresenter.TearDown;
begin
  FreeAndNil(FPresenter);
  FFileSystemIntf := nil;
  FRasterizerIntf := nil;
  FExporterIntf := nil;
  FInstallerIntf := nil;
  FCatalogIntf := nil;
  FDialogsIntf := nil;
  FViewIntf := nil;
end;

function TTestFontEditorPresenter.NewPresenter: TFontEditorPresenter;
begin
  Result := TFontEditorPresenter.Create(FViewIntf, FDialogsIntf, FCatalogIntf, FInstallerIntf, FExporterIntf,
    FFileSystemIntf, TToolsFactory.CreateFileBackup(FFileSystemIntf),
    TToolsFactory.CreateSettings(FFileSystemIntf, INI_FILE), TToolsFactory.CreateRecentFiles(TOOLS_RECENT_FILES_LIMIT),
    TToolsFactory.CreateUndoHistory(TOOLS_UNDO_LIMIT), TFontFactory.CreateGridComposer(FRasterizerIntf),
    TFontFactory.CreateTextComposer(FRasterizerIntf),
    TFontFactory.CreateWadGenerator(FRasterizerIntf, TWadFactory.CreateBuilder));
end;

procedure TTestFontEditorPresenter.StartFresh;
begin
  FPresenter.Start('');
end;

function TTestFontEditorPresenter.Wad(const AFileName: string): TBytes;
begin
  Assert.IsTrue(FFileSystem.TryReadAllBytes(AFileName, Result), 'il file ' + AFileName + ' deve esistere');
end;

procedure TTestFontEditorPresenter.DovrebbeMostrareAllAvvioLaGrigliaLAnteprimaEIlTitolo;
begin
  StartFresh;
  Assert.AreEqual(1, FView.GridCount);
  Assert.AreEqual(256, FView.Grid.Width);
  Assert.AreEqual(256, FView.Grid.Height);
  Assert.AreEqual(16, FView.GridColumns);
  Assert.AreEqual(16, FView.GridRows);
  Assert.IsTrue(FView.PreviewCount >= 1);
  Assert.AreEqual(FONT_EDITOR_TITLE, FView.Title);
  Assert.AreEqual('Image Size: 256x256   Character Rect Size: 16x16', FView.Display.Info);
  Assert.AreEqual('Doom', FView.Display.FontName);
  Assert.IsFalse(FPresenter.Modified);
  Assert.IsFalse(FView.State.CanUndo);
  Assert.IsTrue(FView.State.CanGenerate);
end;

procedure TTestFontEditorPresenter.DovrebbeElencareIFontDellaMacchina;
begin
  StartFresh;
  Assert.AreEqual(3, Length(FView.FontNames));
  Assert.AreEqual('Verdana', FView.FontNames[2]);
end;

procedure TTestFontEditorPresenter.DovrebbeLeggereLeImpostazioniDelVecchio;
begin
  FFileSystem.PutText(INI_FILE,
    '[Generate Font Options]'#13#10'FONTSIZE=12'#13#10'FONTNAME=Arial'#13#10'BOLD=1'#13#10'FGCOLOR=255'#13#10 +
    'BKCOLOR=4096'#13#10'FIXEDPITCH=1'#13#10'PALETTE=HERETIC'#13#10'TEXTEXPORTSTRING=Hello'#13#10 +
    'FONTSEQUENCEPREFIX=AAA'#13#10'NUMBERSEQUENCEPREFIX=BBB'#13#10 +
    '[General Options]'#13#10'SHOWGRID=1'#13#10'ZOOM=4'#13#10'DRAWWIDTH=20'#13#10'DRAWHEIGHT=24'#13#10);
  StartFresh;
  Assert.AreEqual(12, FPresenter.Font.FontSize);
  Assert.AreEqual('Arial', FPresenter.Font.FontName);
  Assert.IsTrue(FPresenter.Font.IsBold);
  Assert.AreEqual(255, FPresenter.Font.FrontColor);
  Assert.AreEqual(4096, FPresenter.Font.BackColor);
  Assert.AreEqual(20, FPresenter.Font.DrawWidth);
  Assert.AreEqual(24, FPresenter.Font.DrawHeight);
  Assert.IsTrue(FPresenter.FixedPitch);
  Assert.AreEqual(Ord(epHeretic), Ord(FPresenter.Palette));
  Assert.AreEqual('Hello', FPresenter.Text);
  Assert.AreEqual('AAA', FPresenter.CharacterPrefix);
  Assert.AreEqual('BBB', FPresenter.DigitPrefix);
  Assert.IsTrue(FPresenter.ShowGridLines);
  Assert.AreEqual(4, FPresenter.Zoom);
  Assert.AreEqual(20 * 16, FView.Grid.Width);
end;

procedure TTestFontEditorPresenter.DovrebbeLimitareLaCellaELoZoomLetti;
begin
  FFileSystem.PutText(INI_FILE, '[General Options]'#13#10'ZOOM=99'#13#10'DRAWWIDTH=1'#13#10'DRAWHEIGHT=500'#13#10);
  StartFresh;
  Assert.AreEqual(FONT_EDITOR_MAX_ZOOM, FPresenter.Zoom);
  Assert.AreEqual(FONT_EDITOR_MIN_CELL, FPresenter.Font.DrawWidth);
  Assert.AreEqual(FONT_EDITOR_MAX_CELL, FPresenter.Font.DrawHeight);
end;

procedure TTestFontEditorPresenter.DovrebbeSalvareLeImpostazioniAllaChiusura;
var
  LText: string;
begin
  StartFresh;
  FPresenter.SelectFontName('Arial');
  FPresenter.SetBold(True);
  FPresenter.SetDrawWidth(18);
  FPresenter.SetText('Hi there');
  FPresenter.SetCharacterPrefix('XYZ');
  FPresenter.SelectPalette(epOther);
  FPresenter.SetExternalPalette('C:\p.pal');
  FPresenter.ToggleGrid;
  FPresenter.ZoomIn;
  FPresenter.Shutdown;
  LText := FFileSystem.TextOf(INI_FILE);
  Assert.IsTrue(LText.Contains('FONTNAME=Arial'), 'font');
  Assert.IsTrue(LText.Contains('BOLD=1'), 'grassetto');
  Assert.IsTrue(LText.Contains('DRAWWIDTH=18'), 'cella');
  Assert.IsTrue(LText.Contains('TEXTEXPORTSTRING=Hi there'), 'testo');
  Assert.IsTrue(LText.Contains('FONTSEQUENCEPREFIX=XYZ'), 'prefisso');
  Assert.IsTrue(LText.Contains('PALETTE=OTHER'), 'palette');
  Assert.IsTrue(LText.Contains('EXTERNALPALETTE=C:\p.pal'), 'file della palette');
  Assert.IsTrue(LText.Contains('SHOWGRID=1'), 'griglia');
  Assert.IsTrue(LText.Contains('ZOOM=1'), 'zoom');
end;

procedure TTestFontEditorPresenter.DovrebbeRifiutareLeDipendenzeNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TFontEditorPresenter.Create(nil, FDialogsIntf, FCatalogIntf, FInstallerIntf, FExporterIntf, FFileSystemIntf,
        TToolsFactory.CreateFileBackup(FFileSystemIntf), TToolsFactory.CreateSettings(FFileSystemIntf, INI_FILE),
        TToolsFactory.CreateRecentFiles(1), TToolsFactory.CreateUndoHistory(1),
        TFontFactory.CreateGridComposer(FRasterizerIntf), TFontFactory.CreateTextComposer(FRasterizerIntf),
        TFontFactory.CreateWadGenerator(FRasterizerIntf, TWadFactory.CreateBuilder));
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TFontEditorPresenter.Create(FViewIntf, FDialogsIntf, FCatalogIntf, FInstallerIntf, FExporterIntf,
        FFileSystemIntf, TToolsFactory.CreateFileBackup(FFileSystemIntf),
        TToolsFactory.CreateSettings(FFileSystemIntf, INI_FILE), TToolsFactory.CreateRecentFiles(1),
        TToolsFactory.CreateUndoHistory(1), TFontFactory.CreateGridComposer(FRasterizerIntf),
        TFontFactory.CreateTextComposer(FRasterizerIntf), nil);
    end, EArgumentNilException);
end;

procedure TTestFontEditorPresenter.DovrebbeScegliereUnFontDellElencoEIgnorareUnNomeCheNonCe;
begin
  StartFresh;
  FPresenter.SelectFontName('Verdana');
  Assert.AreEqual('Verdana', FPresenter.Font.FontName);
  Assert.AreEqual('Verdana', FView.Display.FontName);
  FPresenter.SelectFontName('Nessuno');
  Assert.AreEqual('Verdana', FPresenter.Font.FontName);
end;

procedure TTestFontEditorPresenter.DovrebbeAnnullareERifareUnCambiamento;
begin
  StartFresh;
  FPresenter.SelectFontName('Arial');
  Assert.IsTrue(FView.State.CanUndo);
  Assert.IsFalse(FView.State.CanRedo);
  FPresenter.Undo;
  Assert.AreEqual('Doom', FPresenter.Font.FontName);
  Assert.IsTrue(FView.State.CanRedo);
  Assert.IsTrue(FPresenter.Modified, 'come il vecchio: annullare segna modificato');
  FPresenter.Redo;
  Assert.AreEqual('Arial', FPresenter.Font.FontName);
  FPresenter.Redo;
  Assert.AreEqual('Arial', FPresenter.Font.FontName, 'niente da rifare');
end;

procedure TTestFontEditorPresenter.DovrebbeAccendereEspegnereGliStili;
begin
  StartFresh;
  FPresenter.SetBold(True);
  FPresenter.SetItalic(True);
  FPresenter.SetUnderline(True);
  FPresenter.SetStrikeOut(True);
  Assert.AreEqual(15, FPresenter.Font.Style);
  Assert.IsTrue(FView.Display.Bold and FView.Display.Italic and FView.Display.Underline and FView.Display.StrikeOut);
  FPresenter.SetBold(False);
  Assert.AreEqual(14, FPresenter.Font.Style);
  Assert.IsFalse(FView.Display.Bold);
end;

procedure TTestFontEditorPresenter.DovrebbeIngrandireEImpicciolireIlFontNeiPassiDelVecchio;
var
  LIndex: Integer;
begin
  StartFresh;
  FPresenter.MakeBigger;
  Assert.AreEqual(9, FPresenter.Font.FontSize);
  for LIndex := 1 to 20 do
    FPresenter.MakeBigger;
  Assert.AreEqual(FONT_MAX_SIZE, FPresenter.Font.FontSize, 'il massimo');
  for LIndex := 1 to 30 do
    FPresenter.MakeSmaller;
  Assert.AreEqual(FONT_MIN_SIZE, FPresenter.Font.FontSize, 'il minimo');
end;

procedure TTestFontEditorPresenter.DovrebbeScegliereIColoriDalDialogo;
begin
  StartFresh;
  FDialogs.ColorResult := True;
  FDialogs.ColorValue := $0000FF;
  FPresenter.ChooseFrontColor;
  Assert.AreEqual($0000FF, FPresenter.Font.FrontColor);
  FDialogs.ColorValue := $FF0000;
  FPresenter.ChooseBackColor;
  Assert.AreEqual($FF0000, FPresenter.Font.BackColor);
  Assert.AreEqual($FF0000, FView.Display.BackColor);
end;

procedure TTestFontEditorPresenter.DovrebbeNonCambiareIColoriSeIlDialogoEAnnullato;
begin
  StartFresh;
  FDialogs.ColorResult := False;
  FDialogs.ColorValue := $123456;
  FPresenter.ChooseFrontColor;
  FPresenter.ChooseBackColor;
  Assert.AreEqual($FFFFFF, FPresenter.Font.FrontColor);
  Assert.AreEqual(0, FPresenter.Font.BackColor);
  Assert.IsFalse(FPresenter.Modified);
end;

procedure TTestFontEditorPresenter.DovrebbeLimitareLaCellaDa5A32;
begin
  StartFresh;
  FPresenter.SetDrawWidth(2);
  Assert.AreEqual(5, FPresenter.Font.DrawWidth);
  FPresenter.SetDrawWidth(100);
  Assert.AreEqual(32, FPresenter.Font.DrawWidth);
  FPresenter.SetDrawHeight(0);
  Assert.AreEqual(5, FPresenter.Font.DrawHeight);
  FPresenter.SetDrawHeight(24);
  Assert.AreEqual(24, FPresenter.Font.DrawHeight);
  Assert.AreEqual(32 * 16, FView.Grid.Width);
  Assert.AreEqual(24 * 16, FView.Grid.Height);
end;

procedure TTestFontEditorPresenter.DovrebbeNonSegnareModificatoSeNienteCambia;
var
  LGrids: Integer;
begin
  StartFresh;
  LGrids := FView.GridCount;
  FPresenter.SetBold(False);
  FPresenter.SetDrawWidth(16);
  FPresenter.SelectFontName('Doom');
  Assert.IsFalse(FPresenter.Modified);
  Assert.AreEqual(LGrids, FView.GridCount, 'nessun disegno in piu');
  Assert.IsFalse(FView.State.CanUndo);
end;

procedure TTestFontEditorPresenter.DovrebbeDisegnareLaGrigliaDiNuovoQuandoCambiaIlFont;
var
  LGrids: Integer;
begin
  StartFresh;
  LGrids := FView.GridCount;
  FPresenter.SetItalic(True);
  Assert.AreEqual(LGrids + 1, FView.GridCount);
  Assert.IsTrue(FPresenter.Modified);
end;

procedure TTestFontEditorPresenter.DovrebbeFarePassareLoZoomEIlReticolo;
var
  LIndex: Integer;
begin
  StartFresh;
  Assert.IsFalse(FView.State.CanZoomOut);
  FPresenter.ZoomIn;
  Assert.AreEqual(1, FView.GridZoom);
  Assert.IsTrue(FView.State.CanZoomOut);
  for LIndex := 1 to 20 do
    FPresenter.ZoomIn;
  Assert.AreEqual(FONT_EDITOR_MAX_ZOOM, FPresenter.Zoom);
  Assert.IsFalse(FView.State.CanZoomIn);
  for LIndex := 1 to 20 do
    FPresenter.ZoomOut;
  Assert.AreEqual(FONT_EDITOR_MIN_ZOOM, FPresenter.Zoom);
  FPresenter.ToggleGrid;
  Assert.IsTrue(FView.GridLines);
  Assert.IsTrue(FView.Display.ShowGrid);
  FPresenter.ToggleGrid;
  Assert.IsFalse(FView.GridLines);
  Assert.IsFalse(FPresenter.Modified, 'la vista non e il progetto');
end;

procedure TTestFontEditorPresenter.DovrebbeDareLAnteprimaDellaPaginaScelta;
var
  LCalls: Integer;
begin
  StartFresh;
  FPresenter.SetText('abc');
  LCalls := FRasterizer.Calls;
  FPresenter.SetText('abcd');
  Assert.AreEqual(LCalls + 4, FRasterizer.Calls, 'un carattere per ogni lettera del testo');
  FPresenter.SetKind(fskDigits);
  LCalls := FRasterizer.Calls;
  FPresenter.SetFixedPitch(True);
  Assert.AreEqual(LCalls + Length(FONT_DIGIT_PREVIEW), FRasterizer.Calls);
  FPresenter.SetKind(fskCharacters);
  Assert.AreEqual(Ord(fskCharacters), Ord(FView.Display.Kind));
  Assert.AreEqual(FONT_MAX_PATCH_WIDTH, FView.Preview.Width, 'passo fisso: 59 celle di 16 pixel, tagliate a 320');
end;

procedure TTestFontEditorPresenter.DovrebbeNonPermetterediFareIlWadDiUnTestoDiSoliSpazi;
begin
  StartFresh;
  FPresenter.SetText('   ');
  Assert.IsFalse(FView.State.CanGenerate);
  FDialogs.WadResult := True;
  FDialogs.WadName := 'C:\out.wad';
  FPresenter.GenerateWad;
  Assert.IsFalse(FFileSystem.FileExists('C:\out.wad'));
  FPresenter.SetKind(fskDigits);
  Assert.IsTrue(FView.State.CanGenerate, 'le cifre non hanno bisogno del testo');
end;

procedure TTestFontEditorPresenter.DovrebbeFareIlWadDelTestoEScriverloConLaCopiaDiSicurezza;
var
  LSource: IWadSource;
begin
  StartFresh;
  FFileSystem.PutText('C:\out.wad', 'vecchio');
  FDialogs.WadResult := True;
  FDialogs.WadName := 'C:\out.wad';
  FPresenter.SetText('Doom Font');
  FPresenter.GenerateWad;
  LSource := TWadFactory.OpenBytes('out.wad', Wad('C:\out.wad'));
  Assert.AreEqual(2, LSource.Count);
  Assert.AreEqual('DDFONT', LSource.Entries[0].Name);
  Assert.AreEqual('DOOMFONT', LSource.Entries[1].Name);
  Assert.IsTrue(FFileSystem.FileExists('C:\out.wad_bak'), 'la copia del file che c era');
  Assert.AreEqual(0, FDialogs.Messages.Count);
end;

procedure TTestFontEditorPresenter.DovrebbeFareIlWadDeiCaratteriEDelleCifre;
var
  LSource: IWadSource;
begin
  StartFresh;
  FDialogs.WadResult := True;
  FDialogs.WadName := 'C:\chars.wad';
  FPresenter.SetKind(fskCharacters);
  FPresenter.SetCharacterPrefix('STCFN');
  FPresenter.GenerateWad;
  LSource := TWadFactory.OpenBytes('chars.wad', Wad('C:\chars.wad'));
  Assert.AreEqual(96, LSource.Count);
  Assert.AreEqual('STCFN033', LSource.Entries[1].Name);
  FDialogs.WadName := 'C:\digits.wad';
  FPresenter.SetKind(fskDigits);
  FPresenter.SetDigitPrefix('STTNUM');
  FPresenter.GenerateWad;
  LSource := TWadFactory.OpenBytes('digits.wad', Wad('C:\digits.wad'));
  Assert.AreEqual(11, LSource.Count);
  Assert.AreEqual('STTNUM9', LSource.Entries[10].Name);
end;

procedure TTestFontEditorPresenter.DovrebbeUsareLaPaletteDiUnFileOLaScalaDiGrigi;
var
  LReversed: TBytes;
  LIndex: Integer;
  LGray: TBytes;
  LWithFile: TBytes;
  LWithoutFile: TBytes;
begin
  StartFresh;
  FDialogs.WadResult := True;
  FDialogs.WadName := 'C:\a.wad';
  FPresenter.SetText('Wad');
  FPresenter.SelectPalette(epOther);
  // no file: the gray ramp
  FPresenter.SetExternalPalette('C:\missing.pal');
  FPresenter.GenerateWad;
  LWithoutFile := Wad('C:\a.wad');
  // a file with the gray ramp: the same WAD
  LGray := TGamePalettes.GrayscaleColors;
  FFileSystem.TryWriteAllBytes('C:\gray.pal', LGray);
  FPresenter.SetExternalPalette('C:\gray.pal');
  FDialogs.WadName := 'C:\b.wad';
  FPresenter.GenerateWad;
  Assert.AreEqual(TFontDigests.OfBytes(LWithoutFile), TFontDigests.OfBytes(Wad('C:\b.wad')));
  // a file with the ramp turned upside down: another WAD
  SetLength(LReversed, 768);
  for LIndex := 0 to 255 do
  begin
    LReversed[3 * LIndex] := Byte(255 - LIndex);
    LReversed[3 * LIndex + 1] := Byte(255 - LIndex);
    LReversed[3 * LIndex + 2] := Byte(255 - LIndex);
  end;
  FFileSystem.TryWriteAllBytes('C:\reversed.pal', LReversed);
  FPresenter.SetExternalPalette('C:\reversed.pal');
  FDialogs.WadName := 'C:\c.wad';
  FPresenter.GenerateWad;
  LWithFile := Wad('C:\c.wad');
  Assert.AreNotEqual(TFontDigests.OfBytes(LWithoutFile), TFontDigests.OfBytes(LWithFile));
  // a palette of a game is another one still
  FPresenter.SelectPalette(epRadix);
  FDialogs.WadName := 'C:\d.wad';
  FPresenter.GenerateWad;
  Assert.AreNotEqual(TFontDigests.OfBytes(LWithoutFile), TFontDigests.OfBytes(Wad('C:\d.wad')));
end;

procedure TTestFontEditorPresenter.DovrebbeNonFareIlWadSeLUtenteAnnulla;
var
  LBefore: Integer;
begin
  StartFresh;
  LBefore := FRasterizer.Calls;
  FDialogs.WadResult := False;
  FDialogs.WadName := 'C:\no.wad';
  FPresenter.GenerateWad;
  Assert.IsFalse(FFileSystem.FileExists('C:\no.wad'));
  Assert.AreEqual(LBefore, FRasterizer.Calls, 'nessun calcolo senza file');
end;

procedure TTestFontEditorPresenter.DovrebbeAvvisareSeIlWadNonSiScrive;
begin
  StartFresh;
  FDialogs.WadResult := True;
  FDialogs.WadName := 'C:\x.wad';
  FFileSystem.FailWrite := True;
  FPresenter.GenerateWad;
  Assert.AreEqual(1, FDialogs.Messages.Count);
  Assert.IsTrue(FDialogs.Messages[0].Contains('x.wad'));
end;

procedure TTestFontEditorPresenter.DovrebbeEsportareLaGrigliaInUnaImmagine;
begin
  StartFresh;
  FDialogs.ImageResult := True;
  FDialogs.ImageName := 'C:\grid.png';
  FPresenter.ExportImage;
  Assert.AreEqual(1, FExporter.Exported.Count);
  Assert.AreEqual('C:\grid.png', FExporter.Exported[0]);
  Assert.AreEqual(256, FExporter.LastImage.Width);
  Assert.AreEqual(256, FExporter.LastImage.Height);
  FDialogs.ImageResult := False;
  FPresenter.ExportImage;
  Assert.AreEqual(1, FExporter.Exported.Count);
end;

procedure TTestFontEditorPresenter.DovrebbeAvvisareSeLEsportazioneFallisce;
begin
  StartFresh;
  FDialogs.ImageResult := True;
  FDialogs.ImageName := 'C:\grid.png';
  FExporter.Fail := True;
  FPresenter.ExportImage;
  Assert.AreEqual(1, FDialogs.Messages.Count);
  Assert.IsTrue(FDialogs.Messages[0].Contains('grid.png'));
end;

procedure TTestFontEditorPresenter.DovrebbeUsareUnFontDaFile;
begin
  StartFresh;
  FInstaller.BroughtName := 'Doom Display';
  FDialogs.FontFileResult := True;
  FDialogs.FontFileName := 'C:\fonts\doom.ttf';
  FPresenter.InstallFont;
  Assert.AreEqual(1, FInstaller.Installed.Count);
  Assert.AreEqual(4, Length(FView.FontNames), 'la lista ha il nome nuovo');
  FPresenter.SelectFontName('Doom Display');
  Assert.AreEqual('Doom Display', FPresenter.Font.FontName);
end;

procedure TTestFontEditorPresenter.DovrebbeAvvisareUnFontGiaCaricatoOCheNonSiCarica;
begin
  StartFresh;
  FDialogs.FontFileResult := True;
  FDialogs.FontFileName := 'C:\fonts\a.ttf';
  FPresenter.InstallFont;
  FPresenter.InstallFont;
  Assert.AreEqual(1, FInstaller.Installed.Count);
  Assert.AreEqual(1, FDialogs.Messages.Count);
  Assert.IsTrue(FDialogs.Messages[0].Contains('already loaded'));
  FInstaller.FailInstall := True;
  FDialogs.FontFileName := 'C:\fonts\b.ttf';
  FPresenter.InstallFont;
  Assert.AreEqual(2, FDialogs.Messages.Count);
  Assert.AreEqual(1, FInstaller.Installed.Count);
  FDialogs.FontFileResult := False;
  FPresenter.InstallFont;
  Assert.AreEqual(2, FDialogs.Messages.Count, 'annullato');
end;

procedure TTestFontEditorPresenter.DovrebbeRestituireIFontCaricatiAllaChiusura;
begin
  StartFresh;
  FDialogs.FontFileResult := True;
  FDialogs.FontFileName := 'C:\fonts\a.ttf';
  FPresenter.InstallFont;
  FPresenter.Shutdown;
  Assert.AreEqual(1, FInstaller.UninstallCount);
  Assert.AreEqual(0, FInstaller.Installed.Count);
end;

procedure TTestFontEditorPresenter.DovrebbeSalvareEAprireUnProgetto;
var
  LText: string;
begin
  StartFresh;
  FPresenter.SelectFontName('Arial');
  FPresenter.SetBold(True);
  FDialogs.SaveResult := True;
  FDialogs.SaveName := PROJECT_FILE;
  FPresenter.Save;
  Assert.IsFalse(FPresenter.Modified);
  Assert.AreEqual(PROJECT_FILE, FPresenter.FileName);
  Assert.IsTrue(FView.Title.StartsWith(FONT_EDITOR_TITLE + ' - '));
  Assert.IsTrue(FView.Title.EndsWith('mine.ddp'));
  LText := FFileSystem.TextOf(PROJECT_FILE);
  Assert.IsTrue(LText.Contains('FontName=Arial'));
  // another presenter opens it
  FPresenter.NewDocument;
  Assert.AreEqual('Doom', FPresenter.Font.FontName);
  FDialogs.OpenResult := True;
  FDialogs.OpenName := PROJECT_FILE;
  FPresenter.OpenFile;
  Assert.AreEqual('Arial', FPresenter.Font.FontName);
  Assert.IsTrue(FPresenter.Font.IsBold);
  Assert.IsFalse(FPresenter.Modified);
  Assert.IsFalse(FView.State.CanUndo, 'aprire un progetto svuota l annullamento');
end;

procedure TTestFontEditorPresenter.DovrebbeChiedereIlNomeSeIlProgettoNonLoHa;
begin
  StartFresh;
  FDialogs.SaveResult := False;
  FPresenter.SetBold(True);
  FPresenter.Save;
  Assert.IsTrue(FPresenter.Modified, 'l utente ha annullato: non e salvato');
  Assert.AreEqual('', FPresenter.FileName);
  FDialogs.SaveResult := True;
  FDialogs.SaveName := PROJECT_FILE;
  FPresenter.Save;
  Assert.IsTrue(FFileSystem.FileExists(PROJECT_FILE));
  // the second time: no question, and the file that was there is kept
  FDialogs.SaveResult := False;
  FPresenter.SetItalic(True);
  FPresenter.Save;
  Assert.IsTrue(FFileSystem.FileExists('C:\work\mine.ddp_bak'));
  Assert.IsFalse(FPresenter.Modified);
end;

procedure TTestFontEditorPresenter.DovrebbeAvvisareSeIlProgettoNonSiLegge;
begin
  StartFresh;
  FDialogs.OpenResult := True;
  FDialogs.OpenName := 'C:\nothing.ddp';
  FPresenter.OpenFile;
  Assert.AreEqual(1, FDialogs.Messages.Count);
  Assert.IsTrue(FDialogs.Messages[0].Contains('nothing.ddp'));
  FFileSystem.PutText('C:\locked.ddp', 'Height=-5');
  FFileSystem.FailRead := True;
  FDialogs.OpenName := 'C:\locked.ddp';
  FPresenter.OpenFile;
  Assert.AreEqual(2, FDialogs.Messages.Count);
  FFileSystem.FailRead := False;
  FFileSystem.FailWrite := True;
  FPresenter.SetBold(True);
  FDialogs.SaveResult := True;
  FDialogs.SaveName := 'C:\w.ddp';
  FPresenter.Save;
  Assert.AreEqual(3, FDialogs.Messages.Count);
  Assert.IsTrue(FPresenter.Modified);
end;

procedure TTestFontEditorPresenter.DovrebbeTenereIlProgettoDellaRigaDiComando;
begin
  FFileSystem.PutText(PROJECT_FILE, 'FontName=Verdana'#13#10'FontSize=14'#13#10);
  FPresenter.Start(PROJECT_FILE);
  // the original loaded the project of the command line and then reset it: here it stays
  Assert.AreEqual('Verdana', FPresenter.Font.FontName);
  Assert.AreEqual(14, FPresenter.Font.FontSize);
  Assert.AreEqual(PROJECT_FILE, FPresenter.FileName);
  Assert.AreEqual(1, Length(FView.RecentCaptions));
end;

procedure TTestFontEditorPresenter.DovrebbeRicordareIFileRecenti;
var
  LNext: TFontEditorPresenter;
begin
  FFileSystem.PutText(PROJECT_FILE, 'FontName=Arial'#13#10);
  FPresenter.Start(PROJECT_FILE);
  FPresenter.Shutdown;
  Assert.IsTrue(FFileSystem.TextOf(INI_FILE).Contains(PROJECT_FILE));
  LNext := NewPresenter;
  try
    LNext.Start('');
    Assert.AreEqual(1, Length(FView.RecentCaptions));
    FPresenter.NewDocument;
    LNext.OpenRecent(0);
    Assert.AreEqual('Arial', LNext.Font.FontName);
    LNext.OpenRecent(7);
    Assert.AreEqual('Arial', LNext.Font.FontName, 'una voce che non c e non fa nulla');
  finally
    LNext.Free;
  end;
end;

procedure TTestFontEditorPresenter.DovrebbeChiedereSeSalvareLeModificheAllaChiusura;
begin
  StartFresh;
  Assert.IsTrue(FPresenter.TryClose, 'senza modifiche non chiede');
  Assert.AreEqual(0, FDialogs.ConfirmCount);
  FPresenter.SetBold(True);
  FDialogs.Confirmation := fcCancel;
  Assert.IsFalse(FPresenter.TryClose);
  FPresenter.RequestClose;
  Assert.AreEqual(0, FView.CloseCount);
  FDialogs.Confirmation := fcNo;
  Assert.IsTrue(FPresenter.TryClose);
  FDialogs.Confirmation := fcYes;
  FDialogs.SaveResult := True;
  FDialogs.SaveName := PROJECT_FILE;
  Assert.IsTrue(FPresenter.TryClose);
  Assert.IsTrue(FFileSystem.FileExists(PROJECT_FILE));
  FDialogs.Confirmation := fcNo;
  FPresenter.NewDocument;
  FPresenter.SetBold(True);
  FDialogs.Confirmation := fcYes;
  FDialogs.SaveResult := False;
  Assert.IsFalse(FPresenter.TryClose, 'si, ma l utente non sceglie il file');
  FDialogs.Confirmation := fcNo;
  FPresenter.RequestClose;
  Assert.AreEqual(1, FView.CloseCount);
  FPresenter.About;
  Assert.AreEqual(1, FDialogs.AboutCount);
end;

procedure TTestFontEditorPresenter.DovrebbeRipartireDaUnProgettoNuovo;
begin
  StartFresh;
  FPresenter.SetBold(True);
  FDialogs.Confirmation := fcCancel;
  FPresenter.NewDocument;
  Assert.IsTrue(FPresenter.Font.IsBold, 'annullato: non cambia nulla');
  FDialogs.Confirmation := fcNo;
  FPresenter.NewDocument;
  Assert.IsFalse(FPresenter.Font.IsBold);
  Assert.IsFalse(FPresenter.Modified);
  Assert.AreEqual('', FPresenter.FileName);
  Assert.AreEqual(FONT_EDITOR_TITLE, FView.Title);
  Assert.IsFalse(FView.State.CanUndo);
end;

end.

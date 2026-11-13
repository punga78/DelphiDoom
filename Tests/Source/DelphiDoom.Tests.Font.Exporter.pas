{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TFontExporter (issue #167)                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Font.Exporter;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.Font.Types,
  DelphiDoom.Font.Settings,
  DelphiDoom.Font.Intf,
  DelphiDoom.Tests.Font.Fakes;

type
  /// <summary>
  ///   The patch of a text is the one that FF_ExportFont of the old DD_FONT wrote (golden file made by running
  ///   the old code on the characters of the tests, in 360 combinations of font, colors, palette, pitch, noise,
  ///   solid patch and offsets)
  /// </summary>
  [TestFixture]
  [Category('font')]
  TTestFontExporter = class(TObject)
  strict private
    FRasterizer: TSyntheticRasterizer;
    FRasterizerIntf: IFontRasterizer;
    FExporter: IFontExporter;
    function GrayPalette: TFontPaletteSelection;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeScrivereLeStessePatchDelVecchio;
    [Test]
    procedure DovrebbeDisegnareSempreBiancoSuNeroQualunqueSianoIColori;
    [Test]
    procedure DovrebbeRendereTrasparenteLoSfondo;
    [Test]
    procedure DovrebbeUsareGliOffsetPredefinitiSeCosiSiChiede;
    [Test]
    procedure DovrebbeUsareGliOffsetChePassiamo;
    [Test]
    procedure DovrebbeTenereLoZeroPerLaTrasparenza;
    [Test]
    procedure DovrebbeDareUnaPatchSenzaColonnePerUnTestoVuoto;
    [Test]
    procedure DovrebbeTagliareLaPatchAllaLarghezzaDelloSchermoDiDoom;
    [Test]
    procedure DovrebbeRifiutareUnaPaletteNonValida;
    [Test]
    procedure DovrebbeRifiutareLeDipendenzeNil;
  end;

implementation

uses
  DelphiDoom.Imaging.Types,
  DelphiDoom.Imaging.Intf,
  DelphiDoom.Imaging.PatchWriter,
  DelphiDoom.Imaging.Factory,
  DelphiDoom.Palette.GamePalettes,
  DelphiDoom.Palette.ColorMatcher,
  DelphiDoom.Font.Exporter,
  DelphiDoom.Font.Factory,
  DelphiDoom.Tests.Font.Golden,
  DelphiDoom.Tests.Font.Scenarios;

const
  GOLDEN_FILE = 'Font\font.golden.txt';

{ TTestFontExporter }

procedure TTestFontExporter.Setup;
begin
  FRasterizer := TSyntheticRasterizer.Create;
  FRasterizerIntf := FRasterizer;
  FExporter := TFontFactory.CreateExporter(FRasterizerIntf);
end;

procedure TTestFontExporter.TearDown;
begin
  FExporter := nil;
  FRasterizerIntf := nil;
  FRasterizer := nil;
end;

function TTestFontExporter.GrayPalette: TFontPaletteSelection;
begin
  Result := TFontPaletteSelection.Create(TGamePalettes.ToColors(TGamePalettes.GrayscaleColors), 1, 255);
end;

procedure TTestFontExporter.DovrebbeScrivereLeStessePatchDelVecchio;
var
  LLine: string;
  LWords: TArray<string>;
  LScenario: TFontScenario;
  LPatch: TBytes;
  LCount: Integer;
begin
  LCount := 0;
  for LLine in TFontGolden.Lines(GOLDEN_FILE, 'EXPORT') do
  begin
    LWords := TFontGolden.Words(LLine);
    LScenario := TFontScenarios.Item(StrToInt(LWords[0]));
    LPatch := FExporter.ExportText(TFontScenarioBridge.Settings(LScenario), TFontScenarioBridge.Palette(LScenario),
      LScenario.Text, TFontScenarioBridge.Options(LScenario));
    Assert.AreEqual(LWords[1], TFontDigests.OfBytes(LPatch),
      Format('patch %s (palette %d, testo "%s")', [LWords[0], LScenario.Palette, LScenario.Text]));
    Inc(LCount);
  end;
  Assert.AreEqual(TFontScenarios.Count, LCount);
end;

procedure TTestFontExporter.DovrebbeDisegnareSempreBiancoSuNeroQualunqueSianoIColori;
var
  LSettings: TFontSettings;
begin
  LSettings := TFontSettings.Initial;
  LSettings.FrontColor := $0000FF;
  LSettings.BackColor := $FF0000;
  FExporter.ExportText(LSettings, GrayPalette, 'Wad', TFontExportOptions.Create(False, False, False, 0, 0));
  Assert.AreEqual(3, FRasterizer.Calls);
  Assert.AreEqual($FFFFFF, FRasterizer.LastSettings.FrontColor, 'bianco');
  Assert.AreEqual(0, FRasterizer.LastSettings.BackColor, 'su nero');
end;

procedure TTestFontExporter.DovrebbeRendereTrasparenteLoSfondo;
var
  LPatch: TBytes;
  LHeader: TImagingPatchHeader;
  LReader: IImagingPatchReader;
  LImage: TImagingPatchImage;
  LIndex: Integer;
  LTransparent: Integer;
begin
  LReader := TImagingFactory.CreatePatchReader;
  LPatch := FExporter.ExportText(TFontSettings.Initial, GrayPalette, 'Wad',
    TFontExportOptions.Create(False, False, False, 0, 3));
  Move(LPatch[0], LHeader, SizeOf(LHeader));
  Assert.AreEqual(16, Integer(LHeader.Height));
  LImage := LReader.Read(LPatch);
  LTransparent := 0;
  for LIndex := 0 to Length(LImage.Opaque) - 1 do
    if LImage.Opaque[LIndex] = 0 then
      Inc(LTransparent);
  Assert.IsTrue(LTransparent > 0, 'lo sfondo nero e trasparente');
end;

procedure TTestFontExporter.DovrebbeUsareGliOffsetPredefinitiSeCosiSiChiede;
var
  LPatch: TBytes;
  LHeader: TImagingPatchHeader;
begin
  LPatch := FExporter.ExportText(TFontSettings.Initial, GrayPalette, 'Wad',
    TFontExportOptions.CreateWithDefaultOffsets(True, False, False));
  Move(LPatch[0], LHeader, SizeOf(LHeader));
  Assert.AreEqual(Integer(LHeader.Width) div 2, Integer(LHeader.LeftOffset));
  Assert.AreEqual(Integer(LHeader.Height), Integer(LHeader.TopOffset));
end;

procedure TTestFontExporter.DovrebbeUsareGliOffsetChePassiamo;
var
  LPatch: TBytes;
  LHeader: TImagingPatchHeader;
begin
  LPatch := FExporter.ExportText(TFontSettings.Initial, GrayPalette, 'Wad',
    TFontExportOptions.Create(False, False, False, -4, 9));
  Move(LPatch[0], LHeader, SizeOf(LHeader));
  Assert.AreEqual(-4, Integer(LHeader.LeftOffset));
  Assert.AreEqual(9, Integer(LHeader.TopOffset));
end;

procedure TTestFontExporter.DovrebbeTenereLoZeroPerLaTrasparenza;
var
  LPalette: TFontPaletteSelection;
  LWithZero: TBytes;
  LWithOne: TBytes;
begin
  LPalette := GrayPalette;
  LWithOne := FExporter.ExportText(TFontSettings.Initial, LPalette, 'Wad',
    TFontExportOptions.Create(False, False, False, 0, 0));
  LPalette.FirstIndex := 0;
  LWithZero := FExporter.ExportText(TFontSettings.Initial, LPalette, 'Wad',
    TFontExportOptions.Create(False, False, False, 0, 0));
  Assert.AreEqual(TFontDigests.OfBytes(LWithOne), TFontDigests.OfBytes(LWithZero), 'il primo colore usato e almeno 1');
end;

procedure TTestFontExporter.DovrebbeDareUnaPatchSenzaColonnePerUnTestoVuoto;
var
  LPatch: TBytes;
begin
  LPatch := FExporter.ExportText(TFontSettings.Initial, GrayPalette, '',
    TFontExportOptions.Create(False, False, False, 0, 0));
  Assert.AreEqual<Integer>(8, Length(LPatch), 'solo l intestazione');
end;

procedure TTestFontExporter.DovrebbeTagliareLaPatchAllaLarghezzaDelloSchermoDiDoom;
var
  LSettings: TFontSettings;
  LPatch: TBytes;
  LHeader: TImagingPatchHeader;
begin
  LSettings := TFontSettings.Initial;
  LSettings.DrawWidth := 32;
  LPatch := FExporter.ExportText(LSettings, GrayPalette, 'WWWWWWWWWWWWWWWWWWWWWWWW',
    TFontExportOptions.Create(True, False, False, 0, 0));
  Move(LPatch[0], LHeader, SizeOf(LHeader));
  Assert.AreEqual(FONT_MAX_PATCH_WIDTH, Integer(LHeader.Width));
end;

procedure TTestFontExporter.DovrebbeRifiutareUnaPaletteNonValida;
var
  LShort: TFontPaletteSelection;
  LBackwards: TFontPaletteSelection;
begin
  LShort := TFontPaletteSelection.Create(nil, 1, 255);
  Assert.WillRaise(
    procedure
    begin
      FExporter.ExportText(TFontSettings.Initial, LShort, 'a', TFontExportOptions.Create(False, False, False, 0, 0));
    end, EFontException, 'senza colori');
  LBackwards := GrayPalette;
  LBackwards.FirstIndex := 200;
  LBackwards.LastIndex := 100;
  Assert.WillRaise(
    procedure
    begin
      FExporter.ExportText(TFontSettings.Initial, LBackwards, 'a', TFontExportOptions.Create(False, False, False, 0, 0));
    end, EFontException, 'intervallo al contrario');
  LBackwards.FirstIndex := 0;
  LBackwards.LastIndex := 0;
  Assert.WillRaise(
    procedure
    begin
      FExporter.ExportText(TFontSettings.Initial, LBackwards, 'a', TFontExportOptions.Create(False, False, False, 0, 0));
    end, EFontException, 'l indice 0 e della trasparenza: l intervallo restante e vuoto');
end;

procedure TTestFontExporter.DovrebbeRifiutareLeDipendenzeNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TFontExporter.Create(nil, TColorMatcher.Create, TImagingPatchWriter.Create);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TFontExporter.Create(TFontFactory.CreateTextComposer(FRasterizerIntf), nil, TImagingPatchWriter.Create);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TFontExporter.Create(TFontFactory.CreateTextComposer(FRasterizerIntf), TColorMatcher.Create, nil);
    end, EArgumentNilException);
end;

end.

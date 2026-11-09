{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TFontTextComposer and TFontGridComposer (issue #167)    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Font.TextComposer;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.Font.Types,
  DelphiDoom.Font.Settings,
  DelphiDoom.Font.Intf,
  DelphiDoom.Tests.Font.Fakes;

type
  /// <summary>
  ///   The texts and the grids are those of DrawStringToBitmap and DrawToBitmap of the old TFontEngine, with the
  ///   characters of the tests drawn by the same function in the old code (harness) and here: golden file with
  ///   the width and the fingerprint of the pixels of 360 texts and of 40 grids
  /// </summary>
  [TestFixture]
  [Category('font')]
  TTestFontTextComposer = class(TObject)
  strict private
    FRasterizer: TSyntheticRasterizer;
    FRasterizerIntf: IFontRasterizer;
    FText: IFontTextComposer;
    FGrid: IFontGridComposer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeComporreITestiDelVecchioPixelPerPixel;
    [Test]
    procedure DovrebbeComporreLeGrigliaDelVecchioPixelPerPixel;
    [Test]
    procedure DovrebbeChiedereAlRasterizzatoreUnCarattereAlGiro;
    [Test]
    procedure DovrebbeDareUnaImmagineSenzaLarghezzaPerUnTestoVuoto;
    [Test]
    procedure DovrebbeSommareLaLarghezzaDellaCellaConIlPassoFisso;
    [Test]
    procedure DovrebbeTagliareLaImmagineAllaLarghezzaMassima;
    [Test]
    procedure DovrebbeDareAllImmagineLAltezzaDellaCella;
    [Test]
    procedure DovrebbeStringereIlTestoSenzaPassoFisso;
    [Test]
    procedure DovrebbeRifiutareUnRasterizzatoreCheDaLAltezzaSbagliata;
    [Test]
    procedure DovrebbeRifiutareUnaLarghezzaMassimaNegativa;
    [Test]
    procedure DovrebbeRifiutareIlRasterizzatoreNil;
    [Test]
    procedure DovrebbeDareLeDimensioniDellaGriglia;
    [Test]
    procedure DovrebbeMettereIlCarattereNNellaCellaN;
    [Test]
    procedure DovrebbeDareUnaGrigliaSenzaCelleSeLaGrigliaEVuota;
    [Test]
    procedure DovrebbeDareUnaGrigliaVuotaSeLaCellaEVuota;
    [Test]
    procedure DovrebbeRifiutareUnaGrigliaConUnRasterizzatoreNil;
  end;

implementation

uses
  DelphiDoom.Font.Factory,
  DelphiDoom.Tests.Font.Golden,
  DelphiDoom.Tests.Font.Scenarios;

const
  GOLDEN_FILE = 'Font\font.golden.txt';

{ TTestFontTextComposer }

procedure TTestFontTextComposer.Setup;
begin
  FRasterizer := TSyntheticRasterizer.Create;
  FRasterizerIntf := FRasterizer;
  FText := TFontFactory.CreateTextComposer(FRasterizerIntf);
  FGrid := TFontFactory.CreateGridComposer(FRasterizerIntf);
end;

procedure TTestFontTextComposer.TearDown;
begin
  FText := nil;
  FGrid := nil;
  FRasterizerIntf := nil;
  FRasterizer := nil;
end;

procedure TTestFontTextComposer.DovrebbeComporreITestiDelVecchioPixelPerPixel;
var
  LLine: string;
  LWords: TArray<string>;
  LScenario: TFontScenario;
  LImage: TFontImage;
  LCount: Integer;
begin
  LCount := 0;
  for LLine in TFontGolden.Lines(GOLDEN_FILE, 'COMPOSE') do
  begin
    LWords := TFontGolden.Words(LLine);
    LScenario := TFontScenarios.Item(StrToInt(LWords[0]));
    LImage := FText.Compose(TFontScenarioBridge.Settings(LScenario), LScenario.Text, LScenario.FixedPitch,
      FONT_MAX_PATCH_WIDTH);
    Assert.AreEqual(StrToInt(LWords[1]), LImage.Width, 'larghezza del testo ' + LWords[0]);
    Assert.AreEqual(LWords[2], TFontDigests.OfPixels(LImage.Pixels, LImage.Width * LImage.Height),
      'pixel del testo ' + LWords[0]);
    Inc(LCount);
  end;
  Assert.AreEqual(TFontScenarios.Count, LCount);
end;

procedure TTestFontTextComposer.DovrebbeComporreLeGrigliaDelVecchioPixelPerPixel;
var
  LLine: string;
  LWords: TArray<string>;
  LIndex: Integer;
  LSettings: TFontSettings;
  LImage: TFontImage;
  LCount: Integer;
begin
  LCount := 0;
  for LLine in TFontGolden.Lines(GOLDEN_FILE, 'GRID') do
  begin
    LWords := TFontGolden.Words(LLine);
    LIndex := StrToInt(LWords[0]);
    LSettings := TFontScenarioBridge.Settings(TFontScenarios.Item(LIndex));
    LSettings.GridWidth := 8 + LIndex mod 9;
    LSettings.GridHeight := 4 + LIndex mod 13;
    LImage := FGrid.Compose(LSettings);
    Assert.AreEqual(StrToInt(LWords[1]), LImage.Width, 'larghezza della griglia ' + LWords[0]);
    Assert.AreEqual(StrToInt(LWords[2]), LImage.Height, 'altezza della griglia ' + LWords[0]);
    Assert.AreEqual(LWords[3], TFontDigests.OfPixels(LImage.Pixels, LImage.Width * LImage.Height),
      'pixel della griglia ' + LWords[0]);
    Inc(LCount);
  end;
  Assert.AreEqual(40, LCount);
end;

procedure TTestFontTextComposer.DovrebbeChiedereAlRasterizzatoreUnCarattereAlGiro;
begin
  FText.Compose(TFontSettings.Initial, 'Wad 1', False, FONT_MAX_PATCH_WIDTH);
  Assert.AreEqual(5, FRasterizer.Calls);
  Assert.AreEqual('W', string(FRasterizer.Characters[0]));
  Assert.AreEqual(' ', string(FRasterizer.Characters[3]));
  Assert.AreEqual('1', string(FRasterizer.Characters[4]));
end;

procedure TTestFontTextComposer.DovrebbeDareUnaImmagineSenzaLarghezzaPerUnTestoVuoto;
var
  LImage: TFontImage;
begin
  LImage := FText.Compose(TFontSettings.Initial, '', False, FONT_MAX_PATCH_WIDTH);
  Assert.AreEqual(0, LImage.Width);
  Assert.AreEqual(16, LImage.Height);
  Assert.AreEqual(0, FRasterizer.Calls);
end;

procedure TTestFontTextComposer.DovrebbeSommareLaLarghezzaDellaCellaConIlPassoFisso;
var
  LSettings: TFontSettings;
begin
  LSettings := TFontSettings.Initial;
  LSettings.DrawWidth := 12;
  Assert.AreEqual(36, FText.Compose(LSettings, 'abc', True, FONT_MAX_PATCH_WIDTH).Width);
end;

procedure TTestFontTextComposer.DovrebbeTagliareLaImmagineAllaLarghezzaMassima;
var
  LSettings: TFontSettings;
  LImage: TFontImage;
begin
  LSettings := TFontSettings.Initial;
  LSettings.DrawWidth := 32;
  LImage := FText.Compose(LSettings, 'WWWWWWWWWWWWWWWWWWWW', True, FONT_MAX_PATCH_WIDTH);
  Assert.AreEqual(FONT_MAX_PATCH_WIDTH, LImage.Width, '20 caratteri di 32 pixel sono 640');
  Assert.AreEqual(FONT_MAX_PATCH_WIDTH * 16, Length(LImage.Pixels));
  LImage := FText.Compose(LSettings, 'WWWWWWWWWW', True, 100);
  Assert.AreEqual(100, LImage.Width);
end;

procedure TTestFontTextComposer.DovrebbeDareAllImmagineLAltezzaDellaCella;
var
  LSettings: TFontSettings;
begin
  LSettings := TFontSettings.Initial;
  LSettings.DrawHeight := 23;
  Assert.AreEqual(23, FText.Compose(LSettings, 'a', False, FONT_MAX_PATCH_WIDTH).Height);
end;

procedure TTestFontTextComposer.DovrebbeStringereIlTestoSenzaPassoFisso;
var
  LSettings: TFontSettings;
begin
  LSettings := TFontSettings.Initial;
  LSettings.DrawWidth := 20;
  // the characters of the tests are narrower than the cell: the text without a fixed pitch is narrower
  Assert.IsTrue(FText.Compose(LSettings, 'Doom Font', False, FONT_MAX_PATCH_WIDTH).Width <
    FText.Compose(LSettings, 'Doom Font', True, FONT_MAX_PATCH_WIDTH).Width);
end;

procedure TTestFontTextComposer.DovrebbeRifiutareUnRasterizzatoreCheDaLAltezzaSbagliata;
var
  LFlat: TFlatRasterizer;
  LText: IFontTextComposer;
begin
  LFlat := TFlatRasterizer.Create;
  LFlat.Width := 16;
  LFlat.Height := 9;
  LText := TFontFactory.CreateTextComposer(LFlat);
  Assert.WillRaise(
    procedure
    begin
      LText.Compose(TFontSettings.Initial, 'a', False, FONT_MAX_PATCH_WIDTH);
    end, EFontException);
end;

procedure TTestFontTextComposer.DovrebbeRifiutareUnaLarghezzaMassimaNegativa;
begin
  Assert.WillRaise(
    procedure
    begin
      FText.Compose(TFontSettings.Initial, 'a', False, -1);
    end, EArgumentOutOfRangeException);
end;

procedure TTestFontTextComposer.DovrebbeRifiutareIlRasterizzatoreNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TFontFactory.CreateTextComposer(nil);
    end, EArgumentNilException);
end;

procedure TTestFontTextComposer.DovrebbeDareLeDimensioniDellaGriglia;
var
  LSettings: TFontSettings;
  LImage: TFontImage;
begin
  LSettings := TFontSettings.Initial;
  LSettings.DrawWidth := 10;
  LSettings.DrawHeight := 12;
  LSettings.GridWidth := 4;
  LSettings.GridHeight := 3;
  LImage := FGrid.Compose(LSettings);
  Assert.AreEqual(40, LImage.Width);
  Assert.AreEqual(36, LImage.Height);
  Assert.AreEqual(12, FRasterizer.Calls, 'una chiamata per cella');
end;

procedure TTestFontTextComposer.DovrebbeMettereIlCarattereNNellaCellaN;
var
  LSettings: TFontSettings;
  LIndex: Integer;
begin
  LSettings := TFontSettings.Initial;
  LSettings.GridWidth := 16;
  LSettings.GridHeight := 16;
  FGrid.Compose(LSettings);
  Assert.AreEqual(256, FRasterizer.Characters.Count);
  for LIndex := 0 to 255 do
    Assert.AreEqual(LIndex, Integer(Ord(FRasterizer.Characters[LIndex])), 'cella ' + IntToStr(LIndex));
end;

procedure TTestFontTextComposer.DovrebbeDareUnaGrigliaSenzaCelleSeLaGrigliaEVuota;
var
  LSettings: TFontSettings;
  LImage: TFontImage;
begin
  LSettings := TFontSettings.Initial;
  LSettings.GridWidth := 0;
  LSettings.GridHeight := 0;
  LImage := FGrid.Compose(LSettings);
  Assert.AreEqual(0, LImage.Width * LImage.Height);
  Assert.AreEqual(0, FRasterizer.Calls);
end;

procedure TTestFontTextComposer.DovrebbeDareUnaGrigliaVuotaSeLaCellaEVuota;
var
  LSettings: TFontSettings;
  LImage: TFontImage;
begin
  LSettings := TFontSettings.Initial;
  LSettings.DrawWidth := 0;
  LImage := FGrid.Compose(LSettings);
  Assert.AreEqual(0, LImage.Width);
  Assert.AreEqual(0, Length(LImage.Pixels));
end;

procedure TTestFontTextComposer.DovrebbeRifiutareUnaGrigliaConUnRasterizzatoreNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TFontFactory.CreateGridComposer(nil);
    end, EArgumentNilException);
end;

end.

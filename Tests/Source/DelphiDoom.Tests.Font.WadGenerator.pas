{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TFontWadGenerator (issue #167)                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Font.WadGenerator;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.Wad.Types,
  DelphiDoom.Wad.Intf,
  DelphiDoom.Font.Types,
  DelphiDoom.Font.Settings,
  DelphiDoom.Font.Intf,
  DelphiDoom.Tests.Font.Fakes;

type
  /// <summary>
  ///   The WAD is the one of DoGenerateWAD of the old DD_FONT: the same lumps with the same bytes, compared one by
  ///   one (the old tool put the directory after the header and did not align the data: the layout of the WAD
  ///   library is different, the lumps are not)
  /// </summary>
  [TestFixture]
  [Category('font')]
  TTestFontWadGenerator = class(TObject)
  strict private
    FRasterizer: TSyntheticRasterizer;
    FRasterizerIntf: IFontRasterizer;
    FGenerator: IFontWadGenerator;
    function GrayPalette: TFontPaletteSelection;
    function Open(const ABytes: TBytes): IWadSource;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeFareIWadDelVecchioLumpPerLump;
    [Test]
    procedure DovrebbeFareUnPwadConLeImpostazioniNelPrimoLump;
    [Test]
    procedure DovrebbeNominareEPartirePerLaPatchDelTesto;
    [Test]
    procedure DovrebbeFareUnaPatchPerOgniCarattereDa33A127;
    [Test]
    procedure DovrebbeFareUnaPatchPerOgniCifra;
    [Test]
    procedure DovrebbeUsareGliOffsetDelWadDelVecchio;
    [Test]
    procedure DovrebbeSvuotareIlWadDelGiroPrima;
    [Test]
    procedure DovrebbeRifiutareUnTestoDiSoliSpazi;
    [Test]
    procedure DovrebbeRifiutareUnaPaletteNonValida;
    [Test]
    procedure DovrebbeRifiutareLeDipendenzeNil;
  end;

implementation

uses
  DelphiDoom.Wad.Builder,
  DelphiDoom.Wad.Factory,
  DelphiDoom.Palette.GamePalettes,
  DelphiDoom.Imaging.Types,
  DelphiDoom.Font.SettingsFormat,
  DelphiDoom.Font.WadGenerator,
  DelphiDoom.Font.Factory,
  DelphiDoom.Tests.Font.Golden,
  DelphiDoom.Tests.Font.Scenarios;

const
  GOLDEN_FILE = 'Font\font.golden.txt';

{ TTestFontWadGenerator }

procedure TTestFontWadGenerator.Setup;
begin
  FRasterizer := TSyntheticRasterizer.Create;
  FRasterizerIntf := FRasterizer;
  FGenerator := TFontFactory.CreateWadGenerator(FRasterizerIntf, TWadFactory.CreateBuilder);
end;

procedure TTestFontWadGenerator.TearDown;
begin
  FGenerator := nil;
  FRasterizerIntf := nil;
  FRasterizer := nil;
end;

function TTestFontWadGenerator.GrayPalette: TFontPaletteSelection;
begin
  Result := TFontPaletteSelection.Create(TGamePalettes.ToColors(TGamePalettes.GrayscaleColors), 1, 255);
end;

function TTestFontWadGenerator.Open(const ABytes: TBytes): IWadSource;
begin
  Result := TWadFactory.OpenBytes('font.wad', ABytes);
end;

procedure TTestFontWadGenerator.DovrebbeFareIWadDelVecchioLumpPerLump;
var
  LCase: TWadCase;
  LScenario: TFontScenario;
  LRequest: TFontGenerationRequest;
  LSource: IWadSource;
  LLumps: TArray<string>;
  LLine: string;
  LWords: TArray<string>;
  LIndex: Integer;
  LWadIndex: Integer;
  LChecked: Integer;
begin
  LChecked := 0;
  for LWadIndex := 0 to TFontScenarios.WadCaseCount - 1 do
  begin
    LCase := TFontScenarios.WadCase(LWadIndex);
    LScenario := TFontScenarios.Item(LCase.Scenario);
    case LCase.Mode of
      0:
        LRequest := TFontGenerationRequest.ForText(LCase.Text, LScenario.FixedPitch, LScenario.PerlinNoise);
      1:
        LRequest := TFontGenerationRequest.ForCharacters(LCase.Prefix, LScenario.FixedPitch, LScenario.PerlinNoise);
    else
      LRequest := TFontGenerationRequest.ForDigits(LCase.Prefix, LScenario.FixedPitch, LScenario.PerlinNoise);
    end;
    LSource := Open(FGenerator.Generate(TFontScenarioBridge.Settings(LScenario),
      TFontScenarioBridge.Palette(LScenario), LRequest));
    LLumps := TFontGolden.Lines(GOLDEN_FILE, 'WAD');
    Assert.AreEqual(IntToStr(LSource.Count), TFontGolden.Words(LLumps[LWadIndex])[1], 'lump del WAD ' + IntToStr(LWadIndex));
    for LLine in TFontGolden.Lines(GOLDEN_FILE, 'LUMP') do
    begin
      LWords := TFontGolden.Words(LLine);
      if StrToInt(LWords[0]) <> LWadIndex then
        Continue;
      LIndex := StrToInt(LWords[1]);
      Assert.AreEqual(LWords[2], LSource.Entries[LIndex].Name, Format('nome del lump %d del WAD %d', [LIndex, LWadIndex]));
      Assert.AreEqual(LWords[3], TFontDigests.OfBytes(LSource.ReadEntry(LIndex)),
        Format('byte del lump %d del WAD %d', [LIndex, LWadIndex]));
      Inc(LChecked);
    end;
  end;
  Assert.AreEqual(2 * (2 + 96 + 11), LChecked, 'tutti i lump dei sei WAD');
end;

procedure TTestFontWadGenerator.DovrebbeFareUnPwadConLeImpostazioniNelPrimoLump;
var
  LSettings: TFontSettings;
  LSource: IWadSource;
begin
  LSettings := TFontSettings.Initial;
  LSettings.FontName := 'Arial';
  LSource := Open(FGenerator.Generate(LSettings, GrayPalette, TFontGenerationRequest.ForText('Doom', False, False)));
  Assert.AreEqual(Ord(TWadSourceKind.Wad), Ord(LSource.Kind));
  Assert.AreEqual('DDFONT', LSource.Entries[0].Name);
  Assert.AreEqual(TFontDigests.OfBytes(TFontSettingsFormat.Save(LSettings)), TFontDigests.OfBytes(LSource.ReadEntry(0)));
end;

procedure TTestFontWadGenerator.DovrebbeNominareEPartirePerLaPatchDelTesto;
var
  LSource: IWadSource;
begin
  LSource := Open(FGenerator.Generate(TFontSettings.Initial, GrayPalette,
    TFontGenerationRequest.ForText('Doom Font Creator', False, False)));
  Assert.AreEqual(2, LSource.Count);
  Assert.AreEqual('DOOMFONT', LSource.Entries[1].Name, 'senza spazi, in maiuscolo e a 8 caratteri');
end;

procedure TTestFontWadGenerator.DovrebbeFareUnaPatchPerOgniCarattereDa33A127;
var
  LSource: IWadSource;
  LIndex: Integer;
begin
  LSource := Open(FGenerator.Generate(TFontSettings.Initial, GrayPalette,
    TFontGenerationRequest.ForCharacters('STCFN', False, False)));
  Assert.AreEqual(1 + 95, LSource.Count);
  Assert.AreEqual('STCFN033', LSource.Entries[1].Name);
  Assert.AreEqual('STCFN127', LSource.Entries[95].Name);
  Assert.AreEqual(95, FRasterizer.Characters.Count);
  for LIndex := 0 to 94 do
    Assert.AreEqual(33 + LIndex, Integer(Ord(FRasterizer.Characters[LIndex])), 'carattere ' + IntToStr(LIndex));
end;

procedure TTestFontWadGenerator.DovrebbeFareUnaPatchPerOgniCifra;
var
  LSource: IWadSource;
begin
  LSource := Open(FGenerator.Generate(TFontSettings.Initial, GrayPalette,
    TFontGenerationRequest.ForDigits('STTNUM', False, False)));
  Assert.AreEqual(1 + 10, LSource.Count);
  Assert.AreEqual('STTNUM0', LSource.Entries[1].Name);
  Assert.AreEqual('STTNUM9', LSource.Entries[10].Name);
end;

procedure TTestFontWadGenerator.DovrebbeUsareGliOffsetDelWadDelVecchio;
var
  LSource: IWadSource;
  LHeader: TImagingPatchHeader;
  LBytes: TBytes;
begin
  LSource := Open(FGenerator.Generate(TFontSettings.Initial, GrayPalette,
    TFontGenerationRequest.ForText('Wad', False, False)));
  LBytes := LSource.ReadEntry(1);
  Move(LBytes[0], LHeader, SizeOf(LHeader));
  Assert.AreEqual(0, Integer(LHeader.LeftOffset));
  Assert.AreEqual(3, Integer(LHeader.TopOffset));
end;

procedure TTestFontWadGenerator.DovrebbeSvuotareIlWadDelGiroPrima;
var
  LFirst: TBytes;
  LSecond: TBytes;
begin
  LFirst := FGenerator.Generate(TFontSettings.Initial, GrayPalette, TFontGenerationRequest.ForDigits('A', False, False));
  LSecond := FGenerator.Generate(TFontSettings.Initial, GrayPalette, TFontGenerationRequest.ForDigits('A', False, False));
  Assert.AreEqual(TFontDigests.OfBytes(LFirst), TFontDigests.OfBytes(LSecond), 'lo stesso WAD, non il doppio dei lump');
end;

procedure TTestFontWadGenerator.DovrebbeRifiutareUnTestoDiSoliSpazi;
begin
  Assert.WillRaise(
    procedure
    begin
      FGenerator.Generate(TFontSettings.Initial, GrayPalette, TFontGenerationRequest.ForText('   ', False, False));
    end, EFontException);
  Assert.AreEqual(0, FRasterizer.Calls, 'nessun carattere disegnato');
end;

procedure TTestFontWadGenerator.DovrebbeRifiutareUnaPaletteNonValida;
begin
  Assert.WillRaise(
    procedure
    begin
      FGenerator.Generate(TFontSettings.Initial, TFontPaletteSelection.Create(nil, 1, 255),
        TFontGenerationRequest.ForText('a', False, False));
    end, EFontException);
end;

procedure TTestFontWadGenerator.DovrebbeRifiutareLeDipendenzeNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TFontWadGenerator.Create(nil, TWadFactory.CreateBuilder);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TFontWadGenerator.Create(TFontFactory.CreateExporter(FRasterizerIntf), nil);
    end, EArgumentNilException);
end;

end.

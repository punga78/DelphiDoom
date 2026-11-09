{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TGamePatchBuilder                                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.GameData.PatchBuilder;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Generics.Collections, DUnitX.TestFramework,
  DelphiDoom.GameData.Types, DelphiDoom.GameData.Intf;

type
  /// <summary>
  ///   Tests\Data\GameData\patch.golden.txt was written by the patch builders of the forks (MARS_,
  ///   RX_ and SH_CreateDoomPatch and the variants from lump data), compiled in a throwaway
  ///   harness outside the repository, on the images of TGameDataScenarios
  /// </summary>
  [TestFixture]
  [Category('gamedata')]
  TTestGameDataPatchBuilder = class(TObject)
  strict private
    FGolden: TDictionary<string, string>;
    function Builder(AGame: Integer): IGamePatchBuilder;
    procedure Check(const AScenario, AGame, AKind: string; const AActual: TBytes);
    function Header(const APatch: TBytes): TGamePatchHeader;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeDareGliStessiByteDelVecchioCodiceSulleColonne;
    [Test]
    procedure DovrebbeDareGliStessiByteDelVecchioCodiceSulleRighe;
    [Test]
    procedure DovrebbeDareGliStessiByteDelVecchioCodiceConLaPalette;
    [Test]
    procedure DovrebbeDareGliStessiByteDelVecchioCodiceConLoSfondoDiRadix;
    [Test]
    procedure DovrebbeDareGliStessiByteDelVecchioCodiceConGliOffsetEPerIlCielo;
    [Test]
    procedure DovrebbeScrivereUnaColonnaSolidaConUnSoloPost;
    [Test]
    procedure DovrebbeSpezzareLaColonnaNeiBuchi;
    [Test]
    procedure DovrebbeUsareGliOffsetDiDefault;
    [Test]
    procedure DovrebbeUsareSoloIColoriDelRangeDelleOpzioni;
    [Test]
    procedure DovrebbeAvereUnaIntestazioneDiOttoByte;
    [Test]
    procedure DovrebbeFareUnPatchVuotoSeLaLarghezzaEZero;
    [Test]
    procedure DovrebbeRifiutareUnaImmagineTroppoCorta;
    [Test]
    procedure DovrebbeRifiutareUnaImmagineTroppoAlta;
    [Test]
    procedure DovrebbeRifiutareUnaLarghezzaNegativa;
    [Test]
    procedure DovrebbeRifiutareUnaPalettaCorta;
    [Test]
    procedure DovrebbeRifiutareUnMatcherNil;
    [Test]
    procedure DovrebbeDareLeOpzioniDeiTreGiochi;
  end;

implementation

uses
  DelphiDoom.GameData.Factory, DelphiDoom.GameData.PatchBuilder, DelphiDoom.Tests.GameData.Scenarios;

const
  GAME_NAMES: array[0..2] of string = ('mars', 'radix', 'speed');

{ TTestGameDataPatchBuilder }

procedure TTestGameDataPatchBuilder.Setup;
var
  LLines: TStringList;
  LIndex: Integer;
  LParts: TArray<string>;
begin
  FGolden := TDictionary<string, string>.Create;
  LLines := TStringList.Create;
  try
    LLines.LoadFromFile(TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
      '..\..\Tests\Data\GameData\patch.golden.txt')));
    for LIndex := 0 to LLines.Count - 1 do
    begin
      LParts := LLines[LIndex].Split([' ']);
      if Length(LParts) = 5 then
        FGolden.Add(LParts[0] + ' ' + LParts[1] + ' ' + LParts[2], LParts[3] + ' ' + LParts[4]);
    end;
  finally
    LLines.Free;
  end;
end;

procedure TTestGameDataPatchBuilder.TearDown;
begin
  FGolden.Free;
end;

function TTestGameDataPatchBuilder.Builder(AGame: Integer): IGamePatchBuilder;
begin
  case AGame of
    0: Result := TGameDataFactory.CreatePatchBuilder(TGamePatchOptions.Mars);
    1: Result := TGameDataFactory.CreatePatchBuilder(TGamePatchOptions.Radix);
  else
    Result := TGameDataFactory.CreatePatchBuilder(TGamePatchOptions.Speed);
  end;
end;

procedure TTestGameDataPatchBuilder.Check(const AScenario, AGame, AKind: string; const AActual: TBytes);
var
  LKey: string;
  LExpected: string;
begin
  LKey := AScenario + ' ' + AGame + ' ' + AKind;
  Assert.IsTrue(FGolden.TryGetValue(LKey, LExpected), 'missing golden key ' + LKey);
  Assert.AreEqual(LExpected, IntToStr(Length(AActual)) + ' ' + TGameDataScenarios.Digest(AActual), LKey);
end;

function TTestGameDataPatchBuilder.Header(const APatch: TBytes): TGamePatchHeader;
begin
  Move(APatch[0], Result, SizeOf(TGamePatchHeader));
end;

procedure TTestGameDataPatchBuilder.DovrebbeDareGliStessiByteDelVecchioCodiceSulleColonne;
var
  LScenario: TGameDataScenario;
  LGame: Integer;
  LSolid: Integer;
begin
  for LScenario in TGameDataScenarios.All do
    for LGame := 0 to 2 do
      for LSolid := 0 to 1 do
        Check(LScenario.Name, GAME_NAMES[LGame], 'cols_solid' + IntToStr(LSolid),
          Builder(LGame).FromColumns(LScenario.Image, LScenario.Width, LScenario.Height, LSolid = 1));
end;

procedure TTestGameDataPatchBuilder.DovrebbeDareGliStessiByteDelVecchioCodiceSulleRighe;
var
  LScenario: TGameDataScenario;
  LGame: Integer;
  LSolid: Integer;
begin
  for LScenario in TGameDataScenarios.All do
    for LGame := 0 to 2 do
      for LSolid := 0 to 1 do
        Check(LScenario.Name, GAME_NAMES[LGame], 'rows_solid' + IntToStr(LSolid),
          Builder(LGame).FromRows(LScenario.Image, LScenario.Width, LScenario.Height, LSolid = 1));
end;

procedure TTestGameDataPatchBuilder.DovrebbeDareGliStessiByteDelVecchioCodiceConLaPalette;
var
  LScenario: TGameDataScenario;
  LGame: Integer;
  LSolid: Integer;
begin
  for LScenario in TGameDataScenarios.All do
    for LGame := 0 to 2 do
      for LSolid := 0 to 1 do
        Check(LScenario.Name, GAME_NAMES[LGame], 'pal_solid' + IntToStr(LSolid),
          Builder(LGame).FromPalettedRows(LScenario.Image, LScenario.Width, LScenario.Height,
            LScenario.Palette, LSolid = 1, LScenario.DefaultPalette));
end;

procedure TTestGameDataPatchBuilder.DovrebbeDareGliStessiByteDelVecchioCodiceConLoSfondoDiRadix;
var
  LScenario: TGameDataScenario;
  LBackground: Integer;
begin
  for LScenario in TGameDataScenarios.All do
    for LBackground := 0 to 1 do
      Check(LScenario.Name, 'radix', 'opaque_bg' + IntToStr(LBackground * 7),
        Builder(1).FromPalettedRowsWithBackground(LScenario.Image, LScenario.Width, LScenario.Height,
          LScenario.Palette, LBackground * 7, LScenario.DefaultPalette));
end;

procedure TTestGameDataPatchBuilder.DovrebbeDareGliStessiByteDelVecchioCodiceConGliOffsetEPerIlCielo;
var
  LScenario: TGameDataScenario;
  LGame: Integer;
begin
  for LScenario in TGameDataScenarios.All do
    for LGame := 0 to 2 do
    begin
      Check(LScenario.Name, GAME_NAMES[LGame], 'cols_offsets',
        Builder(LGame).FromColumns(LScenario.Image, LScenario.Width, LScenario.Height, False, 3, -2));
      Check(LScenario.Name, GAME_NAMES[LGame], 'sky',
        Builder(LGame).SkyFromColumns(LScenario.Image, LScenario.Width, LScenario.Height));
    end;
end;

procedure TTestGameDataPatchBuilder.DovrebbeScrivereUnaColonnaSolidaConUnSoloPost;
var
  LPatch: TBytes;
begin
  // 1 column of 3 pixels: header (8), one offset (4), post: top 0, length 3, pad, 3 pixels, pad, end 255 0
  LPatch := Builder(2).FromColumns(TBytes.Create(10, 20, 30), 1, 3, True);
  Assert.AreEqual(8 + 4 + 2 + 1 + 3 + 1 + 2, Length(LPatch));
  Assert.AreEqual(12, Integer(PInteger(@LPatch[8])^), 'offset of the first column');
  Assert.AreEqual<Byte>(0, LPatch[12], 'top delta');
  Assert.AreEqual<Byte>(3, LPatch[13], 'length');
  Assert.AreEqual<Byte>(10, LPatch[15]);
  Assert.AreEqual<Byte>(30, LPatch[17]);
  Assert.AreEqual<Byte>(255, LPatch[19], 'end of the column');
  Assert.AreEqual<Byte>(0, LPatch[20]);
end;

procedure TTestGameDataPatchBuilder.DovrebbeSpezzareLaColonnaNeiBuchi;
var
  LPatch: TBytes;
begin
  // Speed: 255 is the hole. Column: 1, hole, hole, 4, 5 -> post at 0 (1 pixel), post at 3 (2 pixels)
  LPatch := Builder(2).FromColumns(TBytes.Create(1, 255, 255, 4, 5), 1, 5, False);
  Assert.AreEqual<Byte>(0, LPatch[12]);
  Assert.AreEqual<Byte>(1, LPatch[13]);
  Assert.AreEqual<Byte>(1, LPatch[15]);
  Assert.AreEqual<Byte>(3, LPatch[17], 'top delta of the second post');
  Assert.AreEqual<Byte>(2, LPatch[18]);
  Assert.AreEqual<Byte>(4, LPatch[20]);
  Assert.AreEqual<Byte>(5, LPatch[21]);
end;

procedure TTestGameDataPatchBuilder.DovrebbeUsareGliOffsetDiDefault;
var
  LHeader: TGamePatchHeader;
begin
  LHeader := Header(Builder(2).FromColumns(TBytes.Create(1, 2, 3, 4, 5, 6, 7, 8, 9, 10), 5, 2, True));
  Assert.AreEqual<SmallInt>(5, LHeader.Width);
  Assert.AreEqual<SmallInt>(2, LHeader.Height);
  Assert.AreEqual<SmallInt>(2, LHeader.LeftOffset, 'half the width');
  Assert.AreEqual<SmallInt>(2, LHeader.TopOffset, 'the height');
  LHeader := Header(Builder(2).FromRows(TBytes.Create(1, 2, 3, 4), 2, 2, True));
  Assert.AreEqual<SmallInt>(0, LHeader.LeftOffset, 'rows: no offsets');
  Assert.AreEqual<SmallInt>(0, LHeader.TopOffset);
end;

procedure TTestGameDataPatchBuilder.DovrebbeUsareSoloIColoriDelRangeDelleOpzioni;
var
  LPalette: TBytes;
  LColors: TArray<Cardinal>;
  LImage: TBytes;
  LPatch: TBytes;
  LIndex: Integer;
begin
  // the first and the last 16 colors are out of the range of Speed: a color near them goes inside
  SetLength(LColors, 256);
  for LIndex := 0 to 255 do
    LColors[LIndex] := Cardinal(LIndex) * $010101;
  SetLength(LPalette, 768);
  for LIndex := 0 to 767 do
    LPalette[LIndex] := 0;
  LImage := TBytes.Create(0);
  LPatch := Builder(2).FromPalettedRows(LImage, 1, 1, LPalette, True, LColors);
  Assert.AreEqual<Byte>(16, LPatch[15], 'black is matched to the first color of the range');
  LPatch := Builder(1).FromPalettedRows(LImage, 1, 1, LPalette, True, LColors);
  Assert.AreEqual<Byte>(0, LPatch[15], 'Rad-X matches the whole palette');
end;

procedure TTestGameDataPatchBuilder.DovrebbeAvereUnaIntestazioneDiOttoByte;
begin
  Assert.AreEqual(8, SizeOf(TGamePatchHeader));
end;

procedure TTestGameDataPatchBuilder.DovrebbeFareUnPatchVuotoSeLaLarghezzaEZero;
var
  LPatch: TBytes;
begin
  LPatch := Builder(2).FromColumns(nil, 0, 0, True);
  Assert.AreEqual(8, Length(LPatch));
end;

procedure TTestGameDataPatchBuilder.DovrebbeRifiutareUnaImmagineTroppoCorta;
begin
  Assert.WillRaise(
    procedure
    begin
      Builder(2).FromColumns(TBytes.Create(1, 2, 3), 2, 2, True);
    end, EGameDataException);
end;

procedure TTestGameDataPatchBuilder.DovrebbeRifiutareUnaImmagineTroppoAlta;
var
  LImage: TBytes;
begin
  SetLength(LImage, 256);
  Assert.WillRaise(
    procedure
    begin
      Builder(2).FromColumns(LImage, 1, 256, True);
    end, EGameDataException);
end;

procedure TTestGameDataPatchBuilder.DovrebbeRifiutareUnaLarghezzaNegativa;
begin
  Assert.WillRaise(
    procedure
    begin
      Builder(2).FromRows(nil, -1, 4, True);
    end, EGameDataException);
end;

procedure TTestGameDataPatchBuilder.DovrebbeRifiutareUnaPalettaCorta;
begin
  Assert.WillRaise(
    procedure
    begin
      Builder(2).FromPalettedRows(TBytes.Create(0), 1, 1, TBytes.Create(1, 2, 3), True, nil);
    end, EGameDataException);
end;

procedure TTestGameDataPatchBuilder.DovrebbeRifiutareUnMatcherNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TGameDataFactory.CreatePatchBuilder(TGamePatchOptions.Speed, nil);
    end, EArgumentNilException);
end;

procedure TTestGameDataPatchBuilder.DovrebbeDareLeOpzioniDeiTreGiochi;
begin
  Assert.AreEqual<Byte>(0, TGamePatchOptions.Mars.TransparentIndex);
  Assert.AreEqual<Byte>(254, TGamePatchOptions.Radix.TransparentIndex);
  Assert.AreEqual<Byte>(255, TGamePatchOptions.Speed.TransparentIndex);
  Assert.AreEqual(16, TGamePatchOptions.Mars.PaletteLow);
  Assert.AreEqual(239, TGamePatchOptions.Speed.PaletteHigh);
  Assert.AreEqual(0, TGamePatchOptions.Radix.PaletteLow);
  Assert.AreEqual(255, TGamePatchOptions.Radix.PaletteHigh);
end;

end.

{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TRadixFlatPart                                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Radix.FlatPart;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.GameData.Intf, DelphiDoom.Radix.Context, DelphiDoom.Radix.FlatPart,
  DelphiDoom.Tests.Radix.DatBuilder;

type
  [TestFixture]
  [Category('radix')]
  TTestRadixFlatPart = class(TObject)
  strict private
    FWad: IGameWadComposer;
    FSource: TArray<TBytes>;
    function Palette: TBytes;
    procedure Run(const ASizes: array of Integer; ATile: Integer = 0);
  public
    [Test]
    procedure DovrebbeRipetereUnMuroDi32x32SuUn64x64;
    [Test]
    procedure DovrebbeGirareIlMuroDaColonneARighe;
    [Test]
    procedure DovrebbeRipetereUnMuroDi32x64InLarghezza;
    [Test]
    procedure DovrebbeRipetereUnMuroDi128x64InAltezza;
    [Test]
    procedure DovrebbeScrivereUnaMisuraStranaCosiCom;
    [Test]
    procedure DovrebbeMettereLeFlatTraIMarcatori;
    [Test]
    procedure DovrebbeFareUnaFlatDelCieloDiUnSoloColore;
    [Test]
    procedure DovrebbeLeggereLaPiastrellaQuandoPesa4100Byte;
    [Test]
    procedure DovrebbeIgnorareLaPiastrellaDiUnaAltraLunghezza;
    [Test]
    procedure DovrebbeNonFareFlatSeNessunMuroEMarcatoENonSiVuoleTutto;
  end;

implementation

uses
  DelphiDoom.Palette.Factory, DelphiDoom.GameData.Types;

{ TTestRadixFlatPart }

function TTestRadixFlatPart.Palette: TBytes;
var
  LColor: Integer;
begin
  SetLength(Result, 768);
  for LColor := 0 to 255 do
  begin
    Result[LColor * 3] := Byte(LColor);
    Result[LColor * 3 + 1] := Byte(LColor);
    Result[LColor * 3 + 2] := Byte(LColor);
  end;
end;

procedure TTestRadixFlatPart.Run(const ASizes: array of Integer; ATile: Integer);
var
  LBuilder: TRadixDatBuilder;
  LAliases: TArray<string>;
  LIndex: Integer;
begin
  LBuilder := TRadixDatBuilder.Create;
  try
    LBuilder.AddWallBitmaps(ASizes);
    SetLength(FSource, Length(ASizes) div 2);
    for LIndex := 0 to High(FSource) do
      FSource[LIndex] := TRadixDatBuilder.Pattern(ASizes[LIndex * 2] * ASizes[LIndex * 2 + 1], LIndex + 1);
    if ATile > 0 then
      LBuilder.Add('TileBitmap', TRadixDatBuilder.Pattern(ATile, 9));
    FWad := TRadixPartRunner.Run(TRadixFlatPart.Create(TPaletteFactory.CreateColorMatcher, True),
      LBuilder.ToBytes, Palette, LAliases);
  finally
    LBuilder.Free;
  end;
end;

procedure TTestRadixFlatPart.DovrebbeRipetereUnMuroDi32x32SuUn64x64;
var
  LFlat: TBytes;
  LRow: Integer;
  LColumn: Integer;
begin
  Run([32, 32]);
  LFlat := FWad.LumpData[FWad.IndexOf('RDXF0001')];
  Assert.AreEqual<Integer>(4096, Length(LFlat));
  for LRow := 0 to 63 do
    for LColumn := 0 to 63 do
      Assert.AreEqual(Integer(FSource[0][(LColumn mod 32) * 32 + (LRow mod 32)]),
        Integer(LFlat[LRow * 64 + LColumn]));
end;

procedure TTestRadixFlatPart.DovrebbeGirareIlMuroDaColonneARighe;
var
  LFlat: TBytes;
begin
  Run([64, 64]);
  LFlat := FWad.LumpData[FWad.IndexOf('RDXF0001')];
  // the pixel (x, y) of a wall by columns is at x * 64 + y; in the flat it is at y * 64 + x
  Assert.AreEqual(Integer(FSource[0][5 * 64 + 9]), Integer(LFlat[9 * 64 + 5]));
end;

procedure TTestRadixFlatPart.DovrebbeRipetereUnMuroDi32x64InLarghezza;
var
  LFlat: TBytes;
begin
  Run([32, 64]);
  LFlat := FWad.LumpData[FWad.IndexOf('RDXF0001')];
  Assert.AreEqual<Integer>(4096, Length(LFlat));
  Assert.AreEqual(Integer(FSource[0][3 * 64 + 20]), Integer(LFlat[20 * 64 + 3]));
  Assert.AreEqual(Integer(FSource[0][3 * 64 + 20]), Integer(LFlat[20 * 64 + 3 + 32]));
end;

procedure TTestRadixFlatPart.DovrebbeRipetereUnMuroDi128x64InAltezza;
var
  LFlat: TBytes;
begin
  Run([128, 64]);
  LFlat := FWad.LumpData[FWad.IndexOf('RDXF0001')];
  Assert.AreEqual<Integer>(128 * 128, Length(LFlat));
  Assert.AreEqual(Integer(FSource[0][100 * 64 + 7]), Integer(LFlat[7 * 128 + 100]));
  Assert.AreEqual(Integer(FSource[0][100 * 64 + 7]), Integer(LFlat[(7 + 64) * 128 + 100]));
end;

procedure TTestRadixFlatPart.DovrebbeScrivereUnaMisuraStranaCosiCom;
begin
  Run([16, 16]);
  Assert.AreEqual<TBytes>(FSource[0], FWad.LumpData[FWad.IndexOf('RDXF0001')]);
end;

procedure TTestRadixFlatPart.DovrebbeMettereLeFlatTraIMarcatori;
begin
  Run([32, 32]);
  Assert.AreEqual('F_START', FWad.LumpNames[0]);
  Assert.AreEqual('F_END', FWad.LumpNames[FWad.Count - 1]);
  Assert.AreEqual('F_SKY1', FWad.LumpNames[FWad.Count - 2]);
end;

procedure TTestRadixFlatPart.DovrebbeFareUnaFlatDelCieloDiUnSoloColore;
var
  LSky: TBytes;
  LIndex: Integer;
begin
  Run([32, 32]);
  LSky := FWad.LumpData[FWad.IndexOf('F_SKY1')];
  Assert.AreEqual<Integer>(4096, Length(LSky));
  for LIndex := 1 to High(LSky) do
    Assert.AreEqual(Integer(LSky[0]), Integer(LSky[LIndex]));
  // a gray palette: the nearest to (77, 179, 255) is the gray that is closest in distance
  Assert.IsTrue(LSky[0] > 150);
end;

procedure TTestRadixFlatPart.DovrebbeLeggereLaPiastrellaQuandoPesa4100Byte;
var
  LTile: TBytes;
  LIndex: Integer;
begin
  Run([32, 32], 4100);
  LTile := FWad.LumpData[FWad.IndexOf('RDXF0000')];
  Assert.AreEqual<Integer>(4096, Length(LTile));
  // the 4 bytes of the header are skipped and a zero becomes 63
  for LIndex := 0 to 4095 do
    Assert.IsTrue(LTile[LIndex] <> 0);
end;

procedure TTestRadixFlatPart.DovrebbeIgnorareLaPiastrellaDiUnaAltraLunghezza;
begin
  Run([32, 32], 4000);
  Assert.AreEqual(-1, FWad.IndexOf('RDXF0000'));
end;

procedure TTestRadixFlatPart.DovrebbeNonFareFlatSeNessunMuroEMarcatoENonSiVuoleTutto;
var
  LBuilder: TRadixDatBuilder;
  LAliases: TArray<string>;
begin
  LBuilder := TRadixDatBuilder.Create;
  try
    LBuilder.AddWallBitmaps([32, 32, 32, 64]);
    // no texture step ran, so no wall is marked as a flat: with makeallflats false there is none
    FWad := TRadixPartRunner.Run(TRadixFlatPart.Create(TPaletteFactory.CreateColorMatcher, False),
      LBuilder.ToBytes, Palette, LAliases);
  finally
    LBuilder.Free;
  end;
  Assert.AreEqual(-1, FWad.IndexOf('RDXF0001'));
  Assert.AreEqual(-1, FWad.IndexOf('RDXF0002'));
end;

end.

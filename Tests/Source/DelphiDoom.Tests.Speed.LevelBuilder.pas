{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TSpeedLevelBuilder                                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Speed.LevelBuilder;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.GameData.Intf, DelphiDoom.Wad.Level.Types, DelphiDoom.Speed.Intf, DelphiDoom.Tests.Speed.Fakes;

type
  [TestFixture]
  [Category('speed')]
  TTestSpeedLevelBuilder = class(TObject)
  strict private
    FLog: TFakeLog;
    FLogReference: IInterface;
    FWad: IGameWadComposer;
    FBuilder: ISpeedLevelBuilder;
    /// <summary>A circuit with two things (a star position and a decoration)</summary>
    function SmallMap: TBytes;
    function SmallSectors: TBytes;
    function SmallPath(ACount: Integer): TBytes;
    function Build(const AMap, ASectors, APath: TBytes): Boolean;
    function LumpNamed(const AName: string): TBytes;
    function NameOf(const AName: TWadName8): string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeScrivereILumpDelLivelloNellOrdineDiUnaMappa;
    [Test]
    procedure DovrebbeRaddoppiareLeCoordinateDelleCose;
    [Test]
    procedure DovrebbeFareDellaPrimaStellaLaPartenzaDelGiocatore;
    [Test]
    procedure DovrebbeCalcolareLAngoloDellaCosa;
    [Test]
    procedure DovrebbeAggiungereLaPartenzaDellaGaraInFondoAlleCose;
    [Test]
    procedure DovrebbeFareUnaCosaPerOgniPuntoDelPercorso;
    [Test]
    procedure DovrebbeCopiareIPuntiDelPercorsoNelLumpPath;
    [Test]
    procedure DovrebbeFareDueSettoriConLePiastrelleEIlCielo;
    [Test]
    procedure DovrebbeFareUnLatoPerOgniMuroDelFileDeiSettori;
    [Test]
    procedure DovrebbeNonFareMuriPerLeTessereSenzaTexture;
    [Test]
    procedure DovrebbeNonRipetereUnaLineaGiaFatta;
    [Test]
    procedure DovrebbeRifiutareUnFileDelCircuitoCorto;
    [Test]
    procedure DovrebbeAvvisareSeIlPercorsoNonHaLaFirma;
    [Test]
    procedure DovrebbeAvvisareSeIlPercorsoHaMenoPuntiDiQuantiNeDice;
    [Test]
    procedure DovrebbeRifiutareUnMuroConUnVerticeCheNonCe;
    [Test]
    procedure DovrebbeRifiutareUnaTextureDiPiuDiOttoCaratteri;
    [Test]
    procedure DovrebbeRifiutareUnFileDeiSettoriCheFinisceTroppoPresto;
    [Test]
    procedure DovrebbeRifiutareUnSettoreConPiuLineeDelNumeroDichiarato;
    [Test]
    procedure DovrebbeRifiutareUnLogNil;
    [Test]
    procedure DovrebbeFareLivelliConLaScalaDiUno;
  end;

implementation

uses
  DelphiDoom.Speed.Types, DelphiDoom.Speed.Factory, DelphiDoom.Speed.LevelBuilder,
  DelphiDoom.GameData.Factory, DelphiDoom.Tests.Speed.JclBuilder;

{ TTestSpeedLevelBuilder }

procedure TTestSpeedLevelBuilder.Setup;
begin
  FLog := TFakeLog.Create;
  FLogReference := FLog;
  FWad := TGameDataFactory.CreateWadComposer;
  FBuilder := TSpeedFactory.CreateLevelBuilder(FLog);
end;

procedure TTestSpeedLevelBuilder.TearDown;
begin
  FBuilder := nil;
  FWad := nil;
  FLogReference := nil;
end;

function TTestSpeedLevelBuilder.SmallMap: TBytes;
var
  LThing: TSpeedDiskThing;
begin
  SetLength(Result, SizeOf(TSpeedDiskMap) + 2 * SizeOf(TSpeedDiskThing));
  FillChar(Result[0], Length(Result), 0);
  // a star position: type 241 in the high byte
  LThing.X := 100;
  LThing.Y := 200;
  LThing.Angle := 0;
  LThing.ThingType := 241 shl 8;
  Move(LThing, Result[SizeOf(TSpeedDiskMap)], SizeOf(LThing));
  // a quarter of a turn, the group 6 and the number 2: the type 0x60 + 2
  LThing.X := 1000;
  LThing.Y := 2000;
  LThing.Angle := 16384;
  LThing.ThingType := $0602;
  Move(LThing, Result[SizeOf(TSpeedDiskMap) + SizeOf(LThing)], SizeOf(LThing));
end;

function TTestSpeedLevelBuilder.SmallSectors: TBytes;
begin
  // 3 vertices, 1 sector and 3 lines: a wall with the texture 7, a line without texture, a wall 12
  Result := TJclBuilder.TextBytes(
    '3 1 3'#13#10'Vertices'#13#10 +
    '  0x00010000 0x00020000'#13#10 +
    '  0x00030000 0x00040000'#13#10 +
    '  0x00050000 0x00060000'#13#10 +
    'Sectors'#13#10 +
    '  3 0x1'#13#10 +
    '    0 1 "7" -1'#13#10 +
    '    1 2 "" 1'#13#10 +
    '    2 0 "12" 4'#13#10 +
    'End'#13#10);
end;

function TTestSpeedLevelBuilder.SmallPath(ACount: Integer): TBytes;
var
  LPoint: TSpeedPathPoint;
  LIndex: Integer;
begin
  SetLength(Result, $100 + ACount * SizeOf(TSpeedPathPoint));
  FillChar(Result[0], Length(Result), 0);
  PCardinal(@Result[0])^ := SPEED_PATH_SIGNATURE;
  PWord(@Result[196])^ := ACount;
  for LIndex := 0 to ACount - 1 do
  begin
    // the direction is a quarter of a turn
    LPoint.X := Cardinal(100 + LIndex) shl 20;
    LPoint.Y := Cardinal(200 + LIndex) shl 20;
    LPoint.Direction := 16384;
    LPoint.Speed := LIndex;
    Move(LPoint, Result[$100 + LIndex * SizeOf(LPoint)], SizeOf(LPoint));
  end;
end;

function TTestSpeedLevelBuilder.Build(const AMap, ASectors, APath: TBytes): Boolean;
begin
  Result := FBuilder.Build('E1M5', '04', AMap, ASectors, APath, 2, 'FLAT0009', FWad);
end;

function TTestSpeedLevelBuilder.NameOf(const AName: TWadName8): string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 0 to 7 do
  begin
    if AName[LIndex] = #0 then
      Break;
    Result := Result + Char(AName[LIndex]);
  end;
end;

function TTestSpeedLevelBuilder.LumpNamed(const AName: string): TBytes;
var
  LIndex: Integer;
begin
  LIndex := FWad.IndexOf(AName);
  Assert.IsTrue(LIndex >= 0, 'lump ' + AName);
  Result := FWad.LumpData[LIndex];
end;

procedure TTestSpeedLevelBuilder.DovrebbeScrivereILumpDelLivelloNellOrdineDiUnaMappa;
const
  EXPECTED: array[0..11] of string = ('E1M5', 'THINGS', 'LINEDEFS', 'SIDEDEFS', 'VERTEXES', 'SEGS',
    'SSECTORS', 'NODES', 'SECTORS', 'REJECT', 'BLOCKMAP', 'PATH');
var
  LIndex: Integer;
begin
  Assert.IsTrue(Build(SmallMap, SmallSectors, SmallPath(2)));
  Assert.AreEqual(12, FWad.Count);
  for LIndex := 0 to 11 do
    Assert.AreEqual(EXPECTED[LIndex], FWad.LumpNames[LIndex]);
  // the markers are empty
  for LIndex in [0, 5, 6, 7, 9, 10] do
    Assert.AreEqual(0, Length(FWad.LumpData[LIndex]), FWad.LumpNames[LIndex]);
end;

procedure TTestSpeedLevelBuilder.DovrebbeRaddoppiareLeCoordinateDelleCose;
var
  LThings: TBytes;
  LThing: TWadThing;
begin
  Assert.IsTrue(Build(SmallMap, SmallSectors, SmallPath(0)));
  LThings := LumpNamed('THINGS');
  // x = 4096 - y, y = 4096 - x, times 2
  Move(LThings[SizeOf(TWadThing)], LThing, SizeOf(LThing));
  Assert.AreEqual<SmallInt>(2 * (4096 - 2000), LThing.X);
  Assert.AreEqual<SmallInt>(2 * (4096 - 1000), LThing.Y);
  Assert.AreEqual<SmallInt>(7, LThing.Options);
end;

procedure TTestSpeedLevelBuilder.DovrebbeFareDellaPrimaStellaLaPartenzaDelGiocatore;
var
  LThings: TBytes;
  LThing: TWadThing;
begin
  Assert.IsTrue(Build(SmallMap, SmallSectors, SmallPath(0)));
  LThings := LumpNamed('THINGS');
  Move(LThings[0], LThing, SizeOf(LThing));
  Assert.AreEqual<SmallInt>(1, LThing.ThingType, 'the star position is the start of the player');
  Move(LThings[SizeOf(TWadThing)], LThing, SizeOf(LThing));
  Assert.AreEqual<SmallInt>($60 + 2, LThing.ThingType, 'a type of the groups 0..240');
end;

procedure TTestSpeedLevelBuilder.DovrebbeCalcolareLAngoloDellaCosa;
var
  LThings: TBytes;
  LThing: TWadThing;
begin
  Assert.IsTrue(Build(SmallMap, SmallSectors, SmallPath(0)));
  LThings := LumpNamed('THINGS');
  Move(LThings[0], LThing, SizeOf(LThing));
  Assert.AreEqual<SmallInt>(360, LThing.Angle, '360 - 0');
  Move(LThings[SizeOf(TWadThing)], LThing, SizeOf(LThing));
  Assert.AreEqual<SmallInt>(270, LThing.Angle, '360 - 90');
end;

procedure TTestSpeedLevelBuilder.DovrebbeAggiungereLaPartenzaDellaGaraInFondoAlleCose;
var
  LThings: TBytes;
  LThing: TWadThing;
begin
  Assert.IsTrue(Build(SmallMap, SmallSectors, SmallPath(2)));
  LThings := LumpNamed('THINGS');
  // 2 things of the map, 2 of the path, the start of the race
  Assert.AreEqual(5 * SizeOf(TWadThing), Length(LThings));
  Move(LThings[4 * SizeOf(TWadThing)], LThing, SizeOf(LThing));
  Assert.AreEqual<SmallInt>(500, LThing.ThingType);
  Assert.AreEqual<SmallInt>(0, LThing.X);
end;

procedure TTestSpeedLevelBuilder.DovrebbeFareUnaCosaPerOgniPuntoDelPercorso;
var
  LThings: TBytes;
  LThing: TWadThing;
begin
  Assert.IsTrue(Build(SmallMap, SmallSectors, SmallPath(2)));
  LThings := LumpNamed('THINGS');
  Move(LThings[2 * SizeOf(TWadThing)], LThing, SizeOf(LThing));
  Assert.AreEqual<SmallInt>(512, LThing.ThingType, 'a point of the path');
  // x = 4096 - (y div 1048576) = 4096 - 200, doubled
  Assert.AreEqual<SmallInt>(2 * (4096 - 200), LThing.X);
  Assert.AreEqual<SmallInt>(2 * (4096 - 100), LThing.Y);
  // a quarter of a turn is 90, minus 90
  Assert.AreEqual<SmallInt>(0, LThing.Angle);
end;

procedure TTestSpeedLevelBuilder.DovrebbeCopiareIPuntiDelPercorsoNelLumpPath;
var
  LPath: TBytes;
  LPoints: TBytes;
begin
  LPath := SmallPath(3);
  Assert.IsTrue(Build(SmallMap, SmallSectors, LPath));
  LPoints := LumpNamed('PATH');
  Assert.AreEqual(3 * 16, Length(LPoints));
  Assert.AreEqual<TBytes>(Copy(LPath, $100, 48), LPoints);
end;

procedure TTestSpeedLevelBuilder.DovrebbeFareDueSettoriConLePiastrelleEIlCielo;
var
  LSectors: TBytes;
  LSector: TWadSector;
begin
  Assert.IsTrue(Build(SmallMap, SmallSectors, SmallPath(0)));
  LSectors := LumpNamed('SECTORS');
  Assert.AreEqual(2 * SizeOf(TWadSector), Length(LSectors));
  Move(LSectors[0], LSector, SizeOf(LSector));
  Assert.AreEqual('FMAP04', NameOf(LSector.FloorTexture));
  Assert.AreEqual('F_SKY1', NameOf(LSector.CeilingTexture));
  Assert.AreEqual<SmallInt>(256, LSector.CeilingHeight);
  Assert.AreEqual<SmallInt>(255, LSector.LightLevel);
  Move(LSectors[SizeOf(TWadSector)], LSector, SizeOf(LSector));
  Assert.AreEqual('FLAT0009', NameOf(LSector.FloorTexture), 'the flat outside');
  Assert.AreEqual<SmallInt>(0, LSector.CeilingHeight);
end;

procedure TTestSpeedLevelBuilder.DovrebbeFareUnLatoPerOgniMuroDelFileDeiSettori;
var
  LSides: TBytes;
  LSide: TWadSidedef;
  LFound: Integer;
  LIndex: Integer;
begin
  Assert.IsTrue(Build(SmallMap, SmallSectors, SmallPath(0)));
  LSides := LumpNamed('SIDEDEFS');
  LFound := 0;
  for LIndex := 0 to Length(LSides) div SizeOf(TWadSidedef) - 1 do
  begin
    Move(LSides[LIndex * SizeOf(TWadSidedef)], LSide, SizeOf(LSide));
    if (NameOf(LSide.MiddleTexture) = 'WALL7') or
      (NameOf(LSide.MiddleTexture) = 'WALL12') then
      Inc(LFound);
  end;
  // two sides for each of the two walls
  Assert.AreEqual(4, LFound);
end;

procedure TTestSpeedLevelBuilder.DovrebbeNonFareMuriPerLeTessereSenzaTexture;
var
  LLines: TBytes;
begin
  Assert.IsTrue(Build(SmallMap, SmallSectors, SmallPath(0)));
  LLines := LumpNamed('LINEDEFS');
  // 4 of the main sector (the same of the extra one) + 4 outside + 2 walls
  Assert.AreEqual(10 * SizeOf(TWadLinedef), Length(LLines));
end;

procedure TTestSpeedLevelBuilder.DovrebbeNonRipetereUnaLineaGiaFatta;
var
  LSectors: TBytes;
  LLines: TBytes;
begin
  // the same wall twice, once reversed
  LSectors := TJclBuilder.TextBytes(
    '2 1 2'#13#10'Vertices'#13#10'  0x00010000 0x00020000'#13#10'  0x00030000 0x00040000'#13#10 +
    'Sectors'#13#10'  2 0x1'#13#10'    0 1 "7" -1'#13#10'    1 0 "7" -1'#13#10'End'#13#10);
  Assert.IsTrue(Build(SmallMap, LSectors, SmallPath(0)));
  LLines := LumpNamed('LINEDEFS');
  Assert.AreEqual(9 * SizeOf(TWadLinedef), Length(LLines));
end;

procedure TTestSpeedLevelBuilder.DovrebbeRifiutareUnFileDelCircuitoCorto;
begin
  Assert.IsFalse(Build(TBytes.Create(1, 2, 3), SmallSectors, SmallPath(0)));
  Assert.AreEqual(0, FWad.Count);
  Assert.AreEqual(1, FLog.Warnings.Count);
end;

procedure TTestSpeedLevelBuilder.DovrebbeAvvisareSeIlPercorsoNonHaLaFirma;
begin
  Assert.IsTrue(Build(SmallMap, SmallSectors, TBytes.Create(1, 2, 3)));
  Assert.AreEqual(1, FLog.Warnings.Count);
  Assert.AreEqual(0, Length(LumpNamed('PATH')));
end;

procedure TTestSpeedLevelBuilder.DovrebbeAvvisareSeIlPercorsoHaMenoPuntiDiQuantiNeDice;
var
  LPath: TBytes;
begin
  LPath := SmallPath(2);
  PWord(@LPath[196])^ := 50;
  Assert.IsTrue(Build(SmallMap, SmallSectors, LPath));
  Assert.AreEqual(1, FLog.Warnings.Count);
  Assert.AreEqual(2 * 16, Length(LumpNamed('PATH')));
end;

procedure TTestSpeedLevelBuilder.DovrebbeRifiutareUnMuroConUnVerticeCheNonCe;
var
  LSectors: TBytes;
begin
  LSectors := TJclBuilder.TextBytes(
    '1 1 1'#13#10'Vertices'#13#10'  0x00010000 0x00020000'#13#10'Sectors'#13#10'  1 0x1'#13#10 +
    '    0 5 "7" -1'#13#10'End'#13#10);
  Assert.IsFalse(Build(SmallMap, LSectors, SmallPath(0)));
  Assert.AreEqual(0, FWad.Count, 'nothing is appended');
  Assert.AreEqual(1, FLog.Warnings.Count);
end;

procedure TTestSpeedLevelBuilder.DovrebbeRifiutareUnaTextureDiPiuDiOttoCaratteri;
var
  LSectors: TBytes;
begin
  LSectors := TJclBuilder.TextBytes(
    '2 1 1'#13#10'Vertices'#13#10'  0x00010000 0x00020000'#13#10'  0x00030000 0x00040000'#13#10 +
    'Sectors'#13#10'  1 0x1'#13#10'    0 1 "12345" -1'#13#10'End'#13#10);
  Assert.IsFalse(Build(SmallMap, LSectors, SmallPath(0)));
  Assert.AreEqual(0, FWad.Count);
end;

procedure TTestSpeedLevelBuilder.DovrebbeRifiutareUnFileDeiSettoriCheFinisceTroppoPresto;
begin
  Assert.IsFalse(Build(SmallMap, TJclBuilder.TextBytes('3 1 3'#13#10'Vertices'#13#10'1 2'), SmallPath(0)));
  Assert.IsFalse(Build(SmallMap, nil, SmallPath(0)));
  Assert.AreEqual(0, FWad.Count);
end;

procedure TTestSpeedLevelBuilder.DovrebbeRifiutareUnSettoreConPiuLineeDelNumeroDichiarato;
var
  LSectors: TBytes;
begin
  // the header says 1 line and the sector has 2: it is not good
  LSectors := TJclBuilder.TextBytes(
    '2 1 1'#13#10'Vertices'#13#10'  0x00010000 0x00020000'#13#10'  0x00030000 0x00040000'#13#10 +
    'Sectors'#13#10'  2 0x1'#13#10'    0 1 "7" -1'#13#10'    1 0 "8" -1'#13#10'End'#13#10);
  Assert.IsFalse(Build(SmallMap, LSectors, SmallPath(0)));
end;

procedure TTestSpeedLevelBuilder.DovrebbeRifiutareUnLogNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TSpeedLevelBuilder.Create(nil);
    end, EArgumentNilException);
end;

procedure TTestSpeedLevelBuilder.DovrebbeFareLivelliConLaScalaDiUno;
var
  LThings: TBytes;
  LThing: TWadThing;
begin
  Assert.IsTrue(FBuilder.Build('E1M1', '00', SmallMap, SmallSectors, SmallPath(0), 1, 'FLAT0001', FWad));
  LThings := LumpNamed('THINGS');
  Move(LThings[SizeOf(TWadThing)], LThing, SizeOf(LThing));
  Assert.AreEqual<SmallInt>(4096 - 2000, LThing.X);
end;

end.

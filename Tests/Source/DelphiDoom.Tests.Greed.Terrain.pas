{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TGreedTerrain, TGreedSlopes and TGreedWorld             }
{                                                                              }
{  The oracles are RF_GetFloorZ, RF_GetCeilingZ and ActivateSlopes of xGreed    }
{  as they were (arrays instead of the globals, padded with zeros after the     }
{  last tile: the original read what came after them)                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.Terrain;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Greed.Types, DelphiDoom.Greed.Intf,
  DelphiDoom.Greed.World.Intf;

type
  [TestFixture]
  [Category('greed')]
  TTestGreedTerrain = class(TObject)
  private
    FWorld: IGreedWorld;
    function RandomMap(var ASeed: Cardinal): IGreedMap;
  public
    [Test]
    procedure DovrebbeDareLAltezzaDiUnPavimentoPiano;
    [Test]
    procedure DovrebbeAbbassareIlPavimentoNellAcqua;
    [Test]
    procedure DovrebbeDareLAltezzaDiUnPavimentoInPendenza;
    [Test]
    procedure DovrebbeDareLAltezzaDelSoffittoPiano;
    [Test]
    procedure DovrebbeDareGliStessiValoriDelCodiceOriginale;
  end;

  [TestFixture]
  [Category('greed')]
  TTestGreedSlopes = class(TObject)
  public
    [Test]
    procedure DovrebbeDareLeForme;
    [Test]
    procedure DovrebbeDareZeroFuoriDa49A63;
    [Test]
    procedure DovrebbeDareGliStessiFlagDelCodiceOriginale;
  end;

  [TestFixture]
  [Category('greed')]
  TTestGreedWorld = class(TObject)
  private
    FWorld: IGreedWorld;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeCopiareIPiani;
    [Test]
    procedure DovrebbeDareZeroFuoriDallaMappa;
    [Test]
    procedure DovrebbeSostituireLeDefinizioniVuoteCon56;
    [Test]
    procedure DovrebbeAttivarePendenzeEMappaFlags;
    [Test]
    procedure DovrebbeAggiungereUnaPortaEMarcareLaCasella;
    [Test]
    procedure DovrebbeSollevareConPiuDi32Porte;
    [Test]
    procedure DovrebbeSollevareConUnaPortaFuoriDallaMappa;
    [Test]
    procedure DovrebbeSollevareConPiuDi96AreeDiSpawn;
    [Test]
    procedure DovrebbeSvuotareLeListeCaricandoUnaMappa;
    [Test]
    procedure DovrebbeModificareUnaPortaUnaAreaEUnaCasella;
    [Test]
    procedure DovrebbeSollevareConUnIndiceSbagliato;
    [Test]
    procedure DovrebbeSollevareSenzaMappa;
  end;

implementation

uses
  DelphiDoom.Greed.Factory, DelphiDoom.Greed.World, DelphiDoom.Greed.Slopes, DelphiDoom.Greed.Terrain,
  DelphiDoom.Tests.Greed.Builders;

const
  FRACUNIT = 65536;
  TILEUNIT = 64 * FRACUNIT;
  MAPSIZE = 64;
  FL_FLOOR = 7;
  FL_CEILING = 56;
  FLS_FLOOR = 0;
  FLS_CEILING = 3;
  POLY_FLAT = 0;
  POLY_SLOPE = 1;
  POLY_ULTOLR = 2;
  POLY_URTOLL = 3;
  PAD = 80;

type
  TOldPlane = array[0..4095 + PAD] of Byte;

var
  OFloorPic, OFloorHeight, OCeilingHeight, OMapSlopes, OMapFlags: TOldPlane;

function OldFixedMul(const a, b: Integer): Integer;
begin
  Result := Integer((Int64(a) * b) shr 16);
end;

function OldShr(const x, n: Integer): Integer;
begin
  Result := x shr n;
  if (x < 0) and (n > 0) then
    Result := Result or (-1 shl (32 - n));
end;

// ActivateSlopes of utils.pas
procedure OldActivateSlopes;
var
  i, j, mapspot: integer;
begin
  for i := 0 to 63 do
    for j := 0 to 63 do
    begin
      mapspot := i * 64 + j;
      case OMapSlopes[mapspot] of
      49:
        OMapFlags[mapspot] := OMapFlags[mapspot] or (POLY_SLOPE shl FLS_CEILING);
      50:
        OMapFlags[mapspot] := OMapFlags[mapspot] or (POLY_URTOLL shl FLS_CEILING);
      51:
        OMapFlags[mapspot] := OMapFlags[mapspot] or (POLY_ULTOLR shl FLS_CEILING);
      52:
        OMapFlags[mapspot] := OMapFlags[mapspot] or POLY_SLOPE;
      53:
        begin
          OMapFlags[mapspot] := OMapFlags[mapspot] or POLY_SLOPE;
          OMapFlags[mapspot] := OMapFlags[mapspot] or (POLY_URTOLL shl FLS_CEILING);
        end;
      54:
        begin
          OMapFlags[mapspot] := OMapFlags[mapspot] or POLY_SLOPE;
          OMapFlags[mapspot] := OMapFlags[mapspot] or (POLY_ULTOLR shl FLS_CEILING);
        end;
      55:
        begin
          OMapFlags[mapspot] := OMapFlags[mapspot] or POLY_URTOLL;
          OMapFlags[mapspot] := OMapFlags[mapspot] or (POLY_SLOPE shl FLS_CEILING);
        end;
      56:
         OMapFlags[mapspot] := OMapFlags[mapspot] or POLY_URTOLL;
      57:
        begin
          OMapFlags[mapspot] := OMapFlags[mapspot] or POLY_URTOLL;
          OMapFlags[mapspot] := OMapFlags[mapspot] or (POLY_ULTOLR shl FLS_CEILING);
        end;
      58:
        begin
          OMapFlags[mapspot] := OMapFlags[mapspot] or POLY_ULTOLR;
          OMapFlags[mapspot] := OMapFlags[mapspot] or (POLY_SLOPE shl FLS_CEILING);
        end;
      59:
        begin
          OMapFlags[mapspot] := OMapFlags[mapspot] or POLY_ULTOLR;
          OMapFlags[mapspot] := OMapFlags[mapspot] or (POLY_URTOLL shl FLS_CEILING);
        end;
      60:
        OMapFlags[mapspot] := OMapFlags[mapspot] or POLY_ULTOLR;
      61:
        begin
          OMapFlags[mapspot] := OMapFlags[mapspot] or POLY_SLOPE;
          OMapFlags[mapspot] := OMapFlags[mapspot] or (POLY_SLOPE shl FLS_CEILING);
        end;
      62:
        begin
          OMapFlags[mapspot] := OMapFlags[mapspot] or POLY_URTOLL;
          OMapFlags[mapspot] := OMapFlags[mapspot] or (POLY_URTOLL shl FLS_CEILING);
        end;
      63:
        begin
          OMapFlags[mapspot] := OMapFlags[mapspot] or POLY_ULTOLR;
          OMapFlags[mapspot] := OMapFlags[mapspot] or (POLY_ULTOLR shl FLS_CEILING);
        end;
      end;
    end;
end;

function OldGetFloorZ(const x, y: Integer): Integer;
var
  h1, h2, h3, h4: Integer;
  tilex, tiley, mapspot: integer;
  polytype: integer;
  fx, fy: Integer;
  top, bottom, water: Integer;
begin
  tilex := OldShr(x, (16 + 6));
  tiley := OldShr(y, (16 + 6));
  mapspot := tiley * MAPSIZE + tilex;
  polytype := (OMapFlags[mapspot] and FL_FLOOR) shr FLS_FLOOR;
  if (OFloorPic[mapspot] >= 57) and (OFloorPic[mapspot] <= 59) then
    water := -(20 * FRACUNIT)
  else
    water := 0;
  if polytype = POLY_FLAT then
  begin
    result := (OFloorHeight[mapspot] * FRACUNIT) + water;
    exit;
  end;
  h1 := OFloorHeight[mapspot] * FRACUNIT;
  h2 := OFloorHeight[mapspot + 1] * FRACUNIT;
  h3 := OFloorHeight[mapspot + MAPSIZE] * FRACUNIT;
  h4 := OFloorHeight[mapspot + MAPSIZE + 1] * FRACUNIT;
  fx := (x and (TILEUNIT - 1)) div 64;
  fy := (y and (TILEUNIT - 1)) div 64;
  if polytype = POLY_SLOPE then
  begin
    if h1 = h2 then
      result := h1 + OldFixedMul(h3 - h1, fy) + water
    else
      result := h1 + OldFixedMul(h2 - h1, fx) + water;
    exit;
  end;
  if polytype = POLY_ULTOLR then
  begin
    if fx > fy then
      h3 := h1 - (h2 - h1)
    else
      h2 := h1 + (h1 - h3);
  end
  else
  begin
    if fx < FRACUNIT - fy then
      h4 := h2 + (h2 - h1)
    else
      h1 := h2 - (h4 - h2);
  end;
  top := h1 + OldFixedMul(h2 - h1, fx);
  bottom := h3 + OldFixedMul(h4 - h3, fx);
  result := top + OldFixedMul(bottom - top, fy) + water;
end;

function OldGetCeilingZ(const x, y: Integer): Integer;
var
  h1, h2, h3, h4: Integer;
  tilex, tiley, mapspot: integer;
  polytype: integer;
  fx, fy: Integer;
  top, bottom: Integer;
begin
  tilex := OldShr(x, (16 + 6));
  tiley := OldShr(y, (16 + 6));
  mapspot := tiley * MAPSIZE + tilex;
  polytype := (OMapFlags[mapspot] and FL_CEILING) shr FLS_CEILING;
  if polytype = POLY_FLAT then
  begin
    result := OCeilingHeight[mapspot] * FRACUNIT;
    exit;
  end;
  if polytype = POLY_SLOPE then
  begin
    h1 := OCeilingHeight[mapspot] * FRACUNIT;
    h2 := OCeilingHeight[mapspot + 1] * FRACUNIT;
    if h1 = h2 then
    begin
      h3 := OCeilingHeight[mapspot + MAPSIZE] * FRACUNIT;
      fy := (y and (TILEUNIT - 1)) div 64;
      result := h1 + OldFixedMul(h3 - h1, fy);
      exit;
    end
    else
    begin
      fx := (x and (TILEUNIT - 1)) div 64;
      result := h1 + OldFixedMul(h2 - h1, fx);
      exit;
    end;
  end;
  h1 := OCeilingHeight[mapspot] * FRACUNIT;
  h2 := OCeilingHeight[mapspot + 1] * FRACUNIT;
  h3 := OCeilingHeight[mapspot + MAPSIZE] * FRACUNIT;
  h4 := OCeilingHeight[mapspot + MAPSIZE + 1] * FRACUNIT;
  fx := (x and (TILEUNIT - 1)) div 64;
  fy := (y and (TILEUNIT - 1)) div 64;
  if polytype = POLY_ULTOLR then
  begin
    if fx > fy then
      h3 := h1 - (h2 - h1)
    else
      h2 := h1 + (h1 - h3);
  end
  else
  begin
    if fx < FRACUNIT - fy then
      h4 := h2 + (h2 - h1)
    else
      h1 := h2 - (h4 - h2);
  end;
  top := h1 + OldFixedMul(h2 - h1, fx);
  bottom := h3 + OldFixedMul(h4 - h3, fx);
  result := top + OldFixedMul(bottom - top, fy);
end;

function Next(var ASeed: Cardinal): Cardinal;
begin
  ASeed := ASeed * 1664525 + 1013904223;
  Result := ASeed shr 8;
end;

function MapWith(const AValues: array of Byte; APlane: TGreedPlane; AFill: Byte): IGreedMap;
var
  LBytes: TBytes;
  LIndex: Integer;
begin
  LBytes := TGreedLumps.MapBytes(nil);
  FillChar(LBytes[Ord(APlane) * 4096], 4096, AFill);
  for LIndex := 0 to High(AValues) do
    LBytes[Ord(APlane) * 4096 + LIndex] := AValues[LIndex];
  Result := TGreedFactory.CreateMapReader.Read(LBytes);
end;

{ TTestGreedTerrain }

function TTestGreedTerrain.RandomMap(var ASeed: Cardinal): IGreedMap;
var
  LBytes: TBytes;
  LIndex: Integer;
begin
  LBytes := TGreedLumps.MapBytes(nil);
  for LIndex := 0 to High(LBytes) do
    LBytes[LIndex] := Byte(Next(ASeed));
  // the shapes and the water are common enough to be tried
  for LIndex := 0 to 4095 do
  begin
    case Next(ASeed) mod 4 of
      0: LBytes[Ord(gpMapSlopes) * 4096 + LIndex] := Byte(48 + Next(ASeed) mod 17);
      1: LBytes[Ord(gpMapSlopes) * 4096 + LIndex] := 0;
    end;
    if Next(ASeed) mod 3 = 0 then
      LBytes[Ord(gpFloorPic) * 4096 + LIndex] := Byte(55 + Next(ASeed) mod 6);
    // heights are small: a wall of 255 would overflow the products in a way that does not matter here
    LBytes[Ord(gpFloorHeight) * 4096 + LIndex] := LBytes[Ord(gpFloorHeight) * 4096 + LIndex] mod 100;
    LBytes[Ord(gpCeilingHeight) * 4096 + LIndex] := LBytes[Ord(gpCeilingHeight) * 4096 + LIndex] mod 100;
  end;
  Result := TGreedFactory.CreateMapReader.Read(LBytes);
end;

procedure TTestGreedTerrain.DovrebbeDareLAltezzaDiUnPavimentoPiano;
begin
  FWorld := TGreedWorld.Create;
  FWorld.Load(MapWith([], gpFloorHeight, 5));
  Assert.AreEqual(5 * FRACUNIT, TGreedTerrain.FloorZ(FWorld, 10 * 65536, 20 * 65536));
  Assert.AreEqual(5 * FRACUNIT, TGreedTerrain.FloorZ(FWorld, 63 * TILEUNIT + 1000, 63 * TILEUNIT + 1000));
end;

procedure TTestGreedTerrain.DovrebbeAbbassareIlPavimentoNellAcqua;
begin
  FWorld := TGreedWorld.Create;
  FWorld.Load(MapWith([], gpFloorHeight, 30));
  FWorld.SetValue(gpFloorPic, 0, 57);
  FWorld.SetValue(gpFloorPic, 1, 60);
  Assert.AreEqual(10 * FRACUNIT, TGreedTerrain.FloorZ(FWorld, 100, 100));
  Assert.AreEqual(30 * FRACUNIT, TGreedTerrain.FloorZ(FWorld, TILEUNIT + 100, 100));
end;

procedure TTestGreedTerrain.DovrebbeDareLAltezzaDiUnPavimentoInPendenza;
begin
  FWorld := TGreedWorld.Create;
  FWorld.Load(MapWith([0, 10], gpFloorHeight, 10));
  // the slope of the tile 0 goes from 0 on the west side to 10 on the east side: the middle is 5
  FWorld.SetMapFlags(0, GREED_POLY_SLOPE);
  Assert.AreEqual(5 * FRACUNIT, TGreedTerrain.FloorZ(FWorld, TILEUNIT div 2, 100));
  Assert.AreEqual(0, TGreedTerrain.FloorZ(FWorld, 0, 100));
end;

procedure TTestGreedTerrain.DovrebbeDareLAltezzaDelSoffittoPiano;
begin
  FWorld := TGreedWorld.Create;
  FWorld.Load(MapWith([], gpCeilingHeight, 64));
  Assert.AreEqual(64 * FRACUNIT, TGreedTerrain.CeilingZ(FWorld, 5000, 5000));
end;

procedure TTestGreedTerrain.DovrebbeDareGliStessiValoriDelCodiceOriginale;
var
  LSeed: Cardinal;
  LMap, LPoint, LSpot: Integer;
  LMapIntf: IGreedMap;
  LX, LY: Integer;
begin
  LSeed := 424242;
  for LMap := 1 to 12 do
  begin
    LMapIntf := RandomMap(LSeed);
    FWorld := TGreedWorld.Create;
    FWorld.Load(LMapIntf);
    FillChar(OFloorPic, SizeOf(OFloorPic), 0);
    FillChar(OFloorHeight, SizeOf(OFloorHeight), 0);
    FillChar(OCeilingHeight, SizeOf(OCeilingHeight), 0);
    FillChar(OMapSlopes, SizeOf(OMapSlopes), 0);
    FillChar(OMapFlags, SizeOf(OMapFlags), 0);
    Move(LMapIntf.Planes[gpFloorPic][0], OFloorPic, 4096);
    Move(LMapIntf.Planes[gpFloorHeight][0], OFloorHeight, 4096);
    Move(LMapIntf.Planes[gpCeilingHeight][0], OCeilingHeight, 4096);
    Move(LMapIntf.Planes[gpMapSlopes][0], OMapSlopes, 4096);
    OldActivateSlopes;
    for LSpot := 0 to 4095 do
      Assert.AreEqual<Integer>(OMapFlags[LSpot], FWorld.GetMapFlags(LSpot), 'flags ' + IntToStr(LSpot));
    for LPoint := 1 to 4000 do
    begin
      LX := Integer(Next(LSeed) mod (64 * Cardinal(TILEUNIT)));
      LY := Integer(Next(LSeed) mod (64 * Cardinal(TILEUNIT)));
      Assert.AreEqual(OldGetFloorZ(LX, LY), TGreedTerrain.FloorZ(FWorld, LX, LY),
        Format('floor %d, %d', [LX, LY]));
      Assert.AreEqual(OldGetCeilingZ(LX, LY), TGreedTerrain.CeilingZ(FWorld, LX, LY),
        Format('ceiling %d, %d', [LX, LY]));
    end;
  end;
end;

{ TTestGreedSlopes }

procedure TTestGreedSlopes.DovrebbeDareLeForme;
begin
  // 49: flat floor, sloped ceiling; 52: sloped floor, flat ceiling; 63: both from the upper left to the lower right
  Assert.AreEqual<Integer>(POLY_SLOPE shl FLS_CEILING, TGreedSlopes.FlagsOf(49));
  Assert.AreEqual<Integer>(POLY_SLOPE, TGreedSlopes.FlagsOf(52));
  Assert.AreEqual<Integer>(POLY_ULTOLR or (POLY_ULTOLR shl FLS_CEILING), TGreedSlopes.FlagsOf(63));
  Assert.AreEqual<Integer>(POLY_URTOLL, TGreedSlopes.FlagsOf(56));
end;

procedure TTestGreedSlopes.DovrebbeDareZeroFuoriDa49A63;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 255 do
    if (LIndex < 49) or (LIndex > 63) then
      Assert.AreEqual<Integer>(0, TGreedSlopes.FlagsOf(LIndex));
end;

procedure TTestGreedSlopes.DovrebbeDareGliStessiFlagDelCodiceOriginale;
var
  LValue, LSpot: Integer;
begin
  for LValue := 0 to 255 do
  begin
    FillChar(OMapSlopes, SizeOf(OMapSlopes), LValue);
    FillChar(OMapFlags, SizeOf(OMapFlags), 0);
    OldActivateSlopes;
    for LSpot := 0 to 4095 do
      Assert.AreEqual<Integer>(OMapFlags[LSpot], TGreedSlopes.FlagsOf(LValue), 'value ' + IntToStr(LValue));
  end;
end;

{ TTestGreedWorld }

procedure TTestGreedWorld.Setup;
begin
  FWorld := TGreedWorld.Create;
  FWorld.Load(MapWith([], gpFloorHeight, 0));
end;

procedure TTestGreedWorld.DovrebbeCopiareIPiani;
begin
  FWorld.Load(MapWith([1, 2, 3], gpNorthWall, 9));
  Assert.AreEqual<Integer>(2, FWorld.GetValue(gpNorthWall, 1));
  Assert.AreEqual<Integer>(9, FWorld.GetValue(gpNorthWall, 4095));
end;

procedure TTestGreedWorld.DovrebbeDareZeroFuoriDallaMappa;
begin
  Assert.AreEqual<Integer>(0, FWorld.GetValue(gpNorthWall, -1));
  Assert.AreEqual<Integer>(0, FWorld.GetValue(gpNorthWall, 4096));
  Assert.AreEqual<Integer>(0, FWorld.GetMapFlags(-5));
  Assert.AreEqual<Integer>(0, FWorld.GetMapFlags(5000));
end;

procedure TTestGreedWorld.DovrebbeSostituireLeDefinizioniVuoteCon56;
begin
  FWorld.Load(MapWith([0, 7], gpFloorDef, 0));
  Assert.AreEqual<Integer>(56, FWorld.GetValue(gpFloorDef, 0));
  Assert.AreEqual<Integer>(7, FWorld.GetValue(gpFloorDef, 1));
  FWorld.Load(MapWith([], gpCeilingDef, 0));
  Assert.AreEqual<Integer>(56, FWorld.GetValue(gpCeilingDef, 100));
  FWorld.Load(MapWith([], gpCeilingDef, 3));
  Assert.AreEqual<Integer>(3, FWorld.GetValue(gpCeilingDef, 100));
end;

procedure TTestGreedWorld.DovrebbeAttivarePendenzeEMappaFlags;
begin
  FWorld.Load(MapWith([49, 56, 99], gpMapSlopes, 0));
  Assert.AreEqual<Integer>(POLY_SLOPE shl FLS_CEILING, FWorld.GetMapFlags(0));
  Assert.AreEqual<Integer>(POLY_URTOLL, FWorld.GetMapFlags(1));
  Assert.AreEqual<Integer>(0, FWorld.GetMapFlags(2));
end;

procedure TTestGreedWorld.DovrebbeAggiungereUnaPortaEMarcareLaCasella;
var
  LIndex: Integer;
  LDoor: TGreedDoor;
begin
  LIndex := FWorld.AddDoor(5, 3);
  Assert.AreEqual(0, LIndex);
  Assert.AreEqual(1, FWorld.DoorCount);
  LDoor := FWorld.GetDoor(0);
  Assert.AreEqual(5, LDoor.TileX);
  Assert.AreEqual(3, LDoor.TileY);
  Assert.AreEqual<Integer>(GREED_FL_DOOR, FWorld.GetMapFlags(3 * 64 + 5) and GREED_FL_DOOR);
end;

procedure TTestGreedWorld.DovrebbeSollevareConPiuDi32Porte;
var
  LIndex: Integer;
begin
  for LIndex := 1 to GREED_MAX_DOORS do
    FWorld.AddDoor(LIndex, 0);
  Assert.WillRaise(
    procedure
    begin
      FWorld.AddDoor(40, 0);
    end, EGreedException);
end;

procedure TTestGreedWorld.DovrebbeSollevareConUnaPortaFuoriDallaMappa;
begin
  Assert.WillRaise(
    procedure
    begin
      FWorld.AddDoor(64, 0);
    end, EGreedDataException);
  Assert.WillRaise(
    procedure
    begin
      FWorld.AddDoor(0, -1);
    end, EGreedDataException);
  Assert.AreEqual(0, FWorld.DoorCount);
end;

procedure TTestGreedWorld.DovrebbeSollevareConPiuDi96AreeDiSpawn;
var
  LIndex: Integer;
begin
  for LIndex := 1 to GREED_MAX_SPAWN_AREAS do
    FWorld.AddSpawnArea;
  Assert.WillRaise(
    procedure
    begin
      FWorld.AddSpawnArea;
    end, EGreedException);
end;

procedure TTestGreedWorld.DovrebbeSvuotareLeListeCaricandoUnaMappa;
begin
  FWorld.AddDoor(1, 1);
  FWorld.AddSpawnArea;
  FWorld.Load(MapWith([], gpFloorHeight, 0));
  Assert.AreEqual(0, FWorld.DoorCount);
  Assert.AreEqual(0, FWorld.SpawnAreaCount);
  // and the door flag of the old map is gone
  Assert.AreEqual<Integer>(0, FWorld.GetMapFlags(65));
end;

procedure TTestGreedWorld.DovrebbeModificareUnaPortaUnaAreaEUnaCasella;
var
  LDoor: TGreedDoor;
  LArea: TGreedSpawnArea;
begin
  FWorld.AddDoor(2, 2);
  LDoor := FWorld.GetDoor(0);
  LDoor.Open := True;
  LDoor.Position := 64 * FRACUNIT;
  FWorld.SetDoor(0, LDoor);
  Assert.IsTrue(FWorld.GetDoor(0).Open);
  Assert.AreEqual(64 * FRACUNIT, FWorld.GetDoor(0).Position);
  FWorld.AddSpawnArea;
  LArea := FWorld.GetSpawnArea(0);
  LArea.Kind := 12;
  FWorld.SetSpawnArea(0, LArea);
  Assert.AreEqual(12, FWorld.GetSpawnArea(0).Kind);
  FWorld.SetValue(gpFloorPic, 7, 33);
  Assert.AreEqual<Integer>(33, FWorld.GetValue(gpFloorPic, 7));
  FWorld.SetMapFlags(7, 3);
  Assert.AreEqual<Integer>(3, FWorld.GetMapFlags(7));
end;

procedure TTestGreedWorld.DovrebbeSollevareConUnIndiceSbagliato;
begin
  Assert.WillRaise(
    procedure
    begin
      FWorld.GetDoor(0);
    end, EGreedException);
  Assert.WillRaise(
    procedure
    begin
      FWorld.GetSpawnArea(0);
    end, EGreedException);
  Assert.WillRaise(
    procedure
    begin
      FWorld.SetValue(gpFloorPic, 4096, 1);
    end, EGreedDataException);
  Assert.WillRaise(
    procedure
    begin
      FWorld.SetMapFlags(-1, 1);
    end, EGreedDataException);
end;

procedure TTestGreedWorld.DovrebbeSollevareSenzaMappa;
begin
  Assert.WillRaise(
    procedure
    begin
      FWorld.Load(nil);
    end, EArgumentNilException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGreedTerrain);
  TDUnitX.RegisterTestFixture(TTestGreedSlopes);
  TDUnitX.RegisterTestFixture(TTestGreedWorld);

end.

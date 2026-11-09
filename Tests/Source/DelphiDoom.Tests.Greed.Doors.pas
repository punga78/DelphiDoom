{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the doors of the greed library (DUnitX)                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.Doors;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Greed.Types, DelphiDoom.Greed.World.Intf,
  DelphiDoom.Greed.Door.Intf, DelphiDoom.Greed.DoorRules;

type
  TDoorTestHost = class(TInterfacedObject, IGreedDoorHost, IGreedDoorPictures)
  public
    Time: Integer;
    Sounds: Integer;
    function GetTimeCount: Integer;
    procedure PlayDoorSound(AX, AY: TGreedFixed);
    function PictureOf(ADoorKind: Integer): Integer;
  end;

  [TestFixture]
  [Category('greed')]
  TTestGreedDoors = class(TObject)
  private
    FWorld: IGreedWorld;
    FHost: TDoorTestHost;
    FHostIntf: IGreedDoorHost;
    FRules: TGreedDoorRules;
    procedure AddOpeningDoor;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeFareLeDueMetaDiUnaCoppiaDiPorte;
    [Test]
    procedure DovrebbeDareALaPortaLaSuaFigura;
    [Test]
    procedure DovrebbeSollevareConUnMondoNil;
    [Test]
    procedure DovrebbeAprireUnaPortaCheSiApre;
    [Test]
    procedure DovrebbeRichiudereLaPortaDopoTreSecondi;
    [Test]
    procedure DovrebbeTenereApertaLaPortaSeIlGiocatoreCEDentro;
    [Test]
    procedure DovrebbeNonMuovereUnaPortaChiusa;
    [Test]
    procedure DovrebbeSollevareConDipendenzeNil;
  end;

implementation

uses
  DelphiDoom.Greed.World, DelphiDoom.Greed.DoorSpawner;

{ TDoorTestHost }

function TDoorTestHost.GetTimeCount: Integer;
begin
  Result := Time;
end;

procedure TDoorTestHost.PlayDoorSound(AX, AY: TGreedFixed);
begin
  Inc(Sounds);
end;

function TDoorTestHost.PictureOf(ADoorKind: Integer): Integer;
begin
  Result := 100 + ADoorKind;
end;

{ TTestGreedDoors }

procedure TTestGreedDoors.Setup;
begin
  FWorld := TGreedWorld.Create;
  FHost := TDoorTestHost.Create;
  FHostIntf := FHost;
  FRules := TGreedDoorRules.Create(FWorld, FHostIntf);
end;

procedure TTestGreedDoors.TearDown;
begin
  FreeAndNil(FRules);
end;

procedure TTestGreedDoors.AddOpeningDoor;
var
  LDoor: TGreedDoor;
begin
  LDoor := Default(TGreedDoor);
  LDoor.TileX := 5;
  LDoor.TileY := 5;
  LDoor.Size := 64 * GREED_FRACUNIT;
  LDoor.Position := LDoor.Size;
  LDoor.Opening := True;
  FWorld.SetDoor(FWorld.AddDoor(5, 5), LDoor);
end;

procedure TTestGreedDoors.DovrebbeFareLeDueMetaDiUnaCoppiaDiPorte;
begin
  // a vertical door of the kind 1 (60) and a horizontal one of the kind 2 (63), and two vertical ones one over the other
  FWorld.SetValue(gpMapSprites, 5 * 64 + 5, 60);
  FWorld.SetValue(gpMapSprites, 5 * 64 + 9, 63);
  FWorld.SetValue(gpMapSprites, 8 * 64 + 12, 60);
  FWorld.SetValue(gpMapSprites, 9 * 64 + 12, 60);
  Assert.AreEqual(4, TGreedDoorSpawner.SpawnAll(FWorld, FHost, 0));
  Assert.AreEqual(4, FWorld.DoorCount);
  Assert.AreEqual(Ord(gdoVertical), Ord(FWorld.GetDoor(0).Orientation));
  Assert.AreEqual(Ord(gdoHorizontal), Ord(FWorld.GetDoor(1).Orientation));
  Assert.AreEqual(Ord(gdoVertical), Ord(FWorld.GetDoor(2).Orientation));
  // the second of two doors one over the other opens to the other side
  Assert.AreEqual(Ord(gdoVertical2), Ord(FWorld.GetDoor(3).Orientation));
  Assert.IsTrue(FWorld.GetDoor(0).Bumpable);
  Assert.AreEqual(64 * GREED_FRACUNIT, FWorld.GetDoor(0).Position);
  // the map does not say any more that there is a door there
  Assert.AreEqual(0, Integer(FWorld.GetValue(gpMapSprites, 5 * 64 + 5)));
end;

procedure TTestGreedDoors.DovrebbeDareALaPortaLaSuaFigura;
begin
  FWorld.SetValue(gpMapSprites, 5 * 64 + 5, 60); // kind 1
  FWorld.SetValue(gpMapSprites, 5 * 64 + 9, 73); // horizontal, kind 7
  TGreedDoorSpawner.SpawnAll(FWorld, FHost, 0);
  Assert.AreEqual(101, FWorld.GetDoor(0).Pic);
  Assert.AreEqual(107, FWorld.GetDoor(1).Pic);
end;

procedure TTestGreedDoors.DovrebbeSollevareConUnMondoNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TGreedDoorSpawner.SpawnAll(nil, FHost, 0);
    end, EArgumentNilException);
end;

procedure TTestGreedDoors.DovrebbeAprireUnaPortaCheSiApre;
var
  LDoor: TGreedDoor;
begin
  AddOpeningDoor;
  FHost.Time := 200;
  FRules.Check(0, 0);
  LDoor := FWorld.GetDoor(0);
  Assert.IsTrue(LDoor.Open);
  Assert.IsFalse(LDoor.Opening);
  Assert.AreEqual(GREED_MIN_DOOR_SIZE * GREED_FRACUNIT, LDoor.Position);
end;

procedure TTestGreedDoors.DovrebbeRichiudereLaPortaDopoTreSecondi;
var
  LDoor: TGreedDoor;
begin
  AddOpeningDoor;
  FHost.Time := 200;
  FRules.Check(0, 0);
  // the door was open since the tic 99 and waits 270 tics, then it closes in about 100 tics
  FHost.Time := 700;
  FRules.Check(0, 0);
  LDoor := FWorld.GetDoor(0);
  Assert.IsFalse(LDoor.Open);
  Assert.IsFalse(LDoor.Closing);
  Assert.AreEqual(64 * GREED_FRACUNIT, LDoor.Position);
  Assert.IsTrue(FHost.Sounds > 0);
end;

procedure TTestGreedDoors.DovrebbeTenereApertaLaPortaSeIlGiocatoreCEDentro;
var
  LDoor: TGreedDoor;
begin
  AddOpeningDoor;
  FHost.Time := 200;
  FRules.Check(0, 0);
  FHost.Time := 900;
  // the player stands in the tile (5, 5) of the door
  FRules.Check(5 * GREED_FRACTILEUNIT + 100, 5 * GREED_FRACTILEUNIT + 100);
  LDoor := FWorld.GetDoor(0);
  Assert.IsTrue(LDoor.Open);
  Assert.IsTrue(LDoor.Blocked);
  Assert.AreEqual(GREED_MIN_DOOR_SIZE * GREED_FRACUNIT, LDoor.Position);
end;

procedure TTestGreedDoors.DovrebbeNonMuovereUnaPortaChiusa;
var
  LDoor: TGreedDoor;
begin
  LDoor := Default(TGreedDoor);
  LDoor.Size := 64 * GREED_FRACUNIT;
  LDoor.Position := LDoor.Size;
  FWorld.SetDoor(FWorld.AddDoor(7, 7), LDoor);
  FHost.Time := 500;
  FRules.Check(0, 0);
  Assert.AreEqual(64 * GREED_FRACUNIT, FWorld.GetDoor(0).Position);
  Assert.IsFalse(FWorld.GetDoor(0).Open);
end;

procedure TTestGreedDoors.DovrebbeSollevareConDipendenzeNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TGreedDoorRules.Create(nil, FHostIntf);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedDoorRules.Create(FWorld, nil);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedDoorSpawner.SpawnAll(FWorld, nil, 0);
    end, EArgumentNilException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGreedDoors);

end.

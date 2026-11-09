{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the keen library - the actors of a level                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Keen.LevelScanner;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Keen.Types, DelphiDoom.Keen.GameTypes, DelphiDoom.Keen.Intf,
  DelphiDoom.Keen.LevelScanner, DelphiDoom.Tests.Keen.GameWorld, DelphiDoom.Tests.Keen.GameFakes;

type
  [TestFixture]
  [Category('keen')]
  TTestKeenLevelScanner = class(TObject)
  strict private
    FWorld: TKeenTestWorld;
    FSpawner: TFakeKeenSpawner;
    FSpawnerIntf: IKeenActorSpawner;
    FScanner: TKeenLevelScanner;
    procedure SetInfo(ATileX, ATileY, AValue: Integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeNonFareNullaSenzaInfo;
    [Test]
    procedure DovrebbeRicominciareLaListaDegliAttori;
    [Test]
    procedure DovrebbeFareKeenAGestaDestraESinistra;
    [TestCase('brocco', '41,brocco')]
    [TestCase('tomat', '42,tomat')]
    [TestCase('carrot', '43,carrot')]
    [TestCase('aspar', '45,aspar')]
    [TestCase('grape', '46,grape')]
    [TestCase('tater', '47,tater')]
    [TestCase('cart', '48,cart')]
    [TestCase('frenchy', '49,frenchy')]
    [TestCase('squasher', '57,squasher')]
    [TestCase('apel', '58,apel')]
    [TestCase('peapod', '59,peapod')]
    [TestCase('peabrain', '60,peabrain')]
    [TestCase('boobus', '61,boobus')]
    [TestCase('door', '33,door')]
    [TestCase('worldkeen', '19,worldkeen')]
    procedure DovrebbeFareLaCosaDelNumero(ATile: Integer; const AName: string);
    [Test]
    procedure DovrebbeFareIBonusConIlLoroTipo;
    [Test]
    procedure DovrebbeFareLeAnguriePiuAnguria;
    [Test]
    procedure DovrebbeAccorgersiDelleBombe;
    [Test]
    procedure DovrebbeLasciareDormireGliAttori;
    [Test]
    procedure DovrebbeLasciareSvegliCheNonDormonoMai;
    [Test]
    procedure DovrebbeFarDormireAncheKeenAncheSeEUnAttore;
    [Test]
    procedure DovrebbeDireDiQualiGrafichePrendere;
    [Test]
    procedure DovrebbeScorrereLaMappaRigaPerRiga;
    [Test]
    procedure DovrebbeTogliereIMuriDiUnaCittaFinita;
    [Test]
    procedure DovrebbePiantareLaBandieraDiUnaCittaFinita;
    [Test]
    procedure DovrebbeLasciareLeCittaNonFinite;
    [Test]
    procedure DovrebbeNonScrivereFuoriDallaMappaConLaBandiera;
    [Test]
    procedure DovrebbeRifiutareIParametriNulli;
  end;

implementation

{ TTestKeenLevelScanner }

procedure TTestKeenLevelScanner.Setup;
begin
  FWorld := TKeenTestWorld.Create(20, 20, []);
  FSpawner := TFakeKeenSpawner.Create(FWorld.Objects);
  FSpawnerIntf := FSpawner;
  FScanner := TKeenLevelScanner.Create(FWorld.Objects, FSpawnerIntf);
end;

procedure TTestKeenLevelScanner.TearDown;
begin
  FScanner.Free;
  FWorld.Free;
end;

procedure TTestKeenLevelScanner.SetInfo(ATileX, ATileY, AValue: Integer);
begin
  FWorld.Map.Planes[2][ATileY * FWorld.Map.Width + ATileX] := Word(AValue);
end;

procedure TTestKeenLevelScanner.DovrebbeNonFareNullaSenzaInfo;
begin
  FScanner.ScanInfoPlane(FWorld.Map);
  Assert.AreEqual(0, FSpawner.Calls.Count);
  Assert.AreEqual(2, FWorld.Objects.Count);
end;

procedure TTestKeenLevelScanner.DovrebbeRicominciareLaListaDegliAttori;
begin
  FWorld.Objects.GetNewObj(False);
  FWorld.Objects.GetNewObj(False);
  FScanner.ScanInfoPlane(FWorld.Map);
  Assert.AreEqual(2, FWorld.Objects.Count);
end;

procedure TTestKeenLevelScanner.DovrebbeFareKeenAGestaDestraESinistra;
begin
  SetInfo(3, 4, 1);
  SetInfo(9, 8, 2);
  FSpawner.ActiveOfSpawned := kaAllways;
  FScanner.ScanInfoPlane(FWorld.Map);
  Assert.AreEqual(2, FSpawner.Calls.Count);
  Assert.AreEqual('keen 3 4 1', FSpawner.Calls[0]);
  Assert.AreEqual('keen 9 8 -1', FSpawner.Calls[1]);
  // Keen is the first actor of the list: the scan does not know it, the spawner takes the next free place
  Assert.AreEqual(4, FWorld.Objects.Count);
end;

procedure TTestKeenLevelScanner.DovrebbeFareLaCosaDelNumero(ATile: Integer; const AName: string);
begin
  SetInfo(5, 6, ATile);
  FScanner.ScanInfoPlane(FWorld.Map);
  Assert.AreEqual(1, FSpawner.Calls.Count);
  Assert.AreEqual(Format('%s 5 6 0', [AName]), FSpawner.Calls[0]);
end;

procedure TTestKeenLevelScanner.DovrebbeFareIBonusConIlLoroTipo;
var
  LTile: Integer;
begin
  for LTile := 21 to 32 do
    SetInfo(LTile - 21, 2, LTile);
  FScanner.ScanInfoPlane(FWorld.Map);
  Assert.AreEqual(12, FSpawner.Calls.Count);
  Assert.AreEqual('bonus 0 2 0', FSpawner.Calls[0]);
  Assert.AreEqual('bonus 5 2 5', FSpawner.Calls[5]);
  Assert.AreEqual('bonus 11 2 11', FSpawner.Calls[11]);
end;

procedure TTestKeenLevelScanner.DovrebbeFareLeAnguriePiuAnguria;
begin
  SetInfo(1, 1, 50);
  SetInfo(2, 1, 51);
  SetInfo(3, 1, 52);
  FScanner.ScanInfoPlane(FWorld.Map);
  Assert.AreEqual('melon 1 1 0', FSpawner.Calls[0]);
  Assert.AreEqual('melon 2 1 1', FSpawner.Calls[1]);
  Assert.AreEqual('melon 3 1 2', FSpawner.Calls[2]);
  Assert.IsTrue(FScanner.LumpNeeded(KEEN_LUMP_MELON));
end;

procedure TTestKeenLevelScanner.DovrebbeAccorgersiDelleBombe;
begin
  SetInfo(4, 4, 30);
  FScanner.ScanInfoPlane(FWorld.Map);
  Assert.IsFalse(FScanner.BombsPresent);
  SetInfo(5, 4, 31);
  FScanner.ScanInfoPlane(FWorld.Map);
  Assert.IsTrue(FScanner.BombsPresent);
  // a new scan forgets
  SetInfo(5, 4, 0);
  FScanner.ScanInfoPlane(FWorld.Map);
  Assert.IsFalse(FScanner.BombsPresent);
end;

procedure TTestKeenLevelScanner.DovrebbeLasciareDormireGliAttori;
begin
  SetInfo(5, 6, 41);
  FSpawner.ActiveOfSpawned := kaYes;
  FScanner.ScanInfoPlane(FWorld.Map);
  Assert.AreEqual(Ord(kaNo), Ord(FWorld.Objects.New^.Active));
end;

procedure TTestKeenLevelScanner.DovrebbeLasciareSvegliCheNonDormonoMai;
begin
  SetInfo(5, 6, 61);
  FSpawner.ActiveOfSpawned := kaAllways;
  FScanner.ScanInfoPlane(FWorld.Map);
  Assert.AreEqual(Ord(kaAllways), Ord(FWorld.Objects.New^.Active));
end;

procedure TTestKeenLevelScanner.DovrebbeFarDormireAncheKeenAncheSeEUnAttore;
begin
  // a number that spawns nothing puts to sleep the last actor made, whoever it is: the score box after a clean start
  SetInfo(2, 2, 18);
  FScanner.ScanInfoPlane(FWorld.Map);
  Assert.AreEqual(Ord(kaNo), Ord(FWorld.Objects.ScoreObj^.Active));
end;

procedure TTestKeenLevelScanner.DovrebbeDireDiQualiGrafichePrendere;
begin
  SetInfo(1, 1, 42);
  SetInfo(2, 1, 59);
  SetInfo(3, 1, 60);
  FScanner.ScanInfoPlane(FWorld.Map);
  Assert.IsTrue(FScanner.LumpNeeded(KEEN_LUMP_TOMAT));
  Assert.IsTrue(FScanner.LumpNeeded(KEEN_LUMP_PEA));
  Assert.IsFalse(FScanner.LumpNeeded(KEEN_LUMP_BROCCO));
  Assert.IsFalse(FScanner.LumpNeeded(-1));
  Assert.IsFalse(FScanner.LumpNeeded(KEEN_NUMLUMPS));
  // a new scan starts again
  SetInfo(1, 1, 0);
  SetInfo(2, 1, 0);
  SetInfo(3, 1, 0);
  FScanner.ScanInfoPlane(FWorld.Map);
  Assert.IsFalse(FScanner.LumpNeeded(KEEN_LUMP_TOMAT));
end;

procedure TTestKeenLevelScanner.DovrebbeScorrereLaMappaRigaPerRiga;
begin
  SetInfo(15, 0, 41);
  SetInfo(2, 1, 42);
  SetInfo(0, 19, 43);
  FScanner.ScanInfoPlane(FWorld.Map);
  Assert.AreEqual('brocco 15 0 0', FSpawner.Calls[0]);
  Assert.AreEqual('tomat 2 1 0', FSpawner.Calls[1]);
  Assert.AreEqual('carrot 0 19 0', FSpawner.Calls[2]);
end;

procedure TTestKeenLevelScanner.DovrebbeTogliereIMuriDiUnaCittaFinita;
var
  LState: TKeenGameState;
begin
  FillChar(LState, SizeOf(LState), 0);
  LState.LevelDone[4] := True;
  // the city 6 (info 6, done[4]) has a blocking tile 130 in the foreground
  SetInfo(5, 5, 6);
  FWorld.SetTile(5, 5, 130);
  FScanner.PatchWorldMap(FWorld.Map, LState);
  Assert.AreEqual(0, Integer(FWorld.Map.Planes[1][5 * 20 + 5]));
  Assert.AreEqual(0, Integer(FWorld.Map.Planes[2][5 * 20 + 5]));
end;

procedure TTestKeenLevelScanner.DovrebbePiantareLaBandieraDiUnaCittaFinita;
var
  LState: TKeenGameState;
begin
  FillChar(LState, SizeOf(LState), 0);
  LState.LevelDone[1] := True;
  SetInfo(6, 7, 3);
  FWorld.SetTile(6, 7, 90);
  FScanner.PatchWorldMap(FWorld.Map, LState);
  Assert.AreEqual(133, Integer(FWorld.Map.Planes[1][7 * 20 + 6]));
  Assert.AreEqual(131, Integer(FWorld.Map.Planes[1][6 * 20 + 5]));
  Assert.AreEqual(132, Integer(FWorld.Map.Planes[1][6 * 20 + 6]));
end;

procedure TTestKeenLevelScanner.DovrebbeLasciareLeCittaNonFinite;
var
  LState: TKeenGameState;
begin
  FillChar(LState, SizeOf(LState), 0);
  SetInfo(5, 5, 6);
  FWorld.SetTile(5, 5, 130);
  FScanner.PatchWorldMap(FWorld.Map, LState);
  Assert.AreEqual(130, Integer(FWorld.Map.Planes[1][5 * 20 + 5]));
  Assert.AreEqual(6, Integer(FWorld.Map.Planes[2][5 * 20 + 5]));
end;

procedure TTestKeenLevelScanner.DovrebbeNonScrivereFuoriDallaMappaConLaBandiera;
var
  LState: TKeenGameState;
begin
  FillChar(LState, SizeOf(LState), 0);
  LState.LevelDone[1] := True;
  SetInfo(0, 0, 3);
  FWorld.SetTile(0, 0, 90);
  FScanner.PatchWorldMap(FWorld.Map, LState);
  Assert.AreEqual(133, Integer(FWorld.Map.Planes[1][0]));
end;

procedure TTestKeenLevelScanner.DovrebbeRifiutareIParametriNulli;
begin
  Assert.WillRaise(
    procedure
    begin
      TKeenLevelScanner.Create(nil, FSpawnerIntf);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TKeenLevelScanner.Create(FWorld.Objects, nil);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      FScanner.ScanInfoPlane(nil);
    end, EArgumentNilException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestKeenLevelScanner);

end.

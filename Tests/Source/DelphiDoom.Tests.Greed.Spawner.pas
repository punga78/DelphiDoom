{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TGreedSpawner                                           }
{                                                                              }
{  The oracle is SpawnSprite of spawn.pas of xGreed as it was: the harness      }
{  Tools\Verifica\175-spawn compiles the original file and writes               }
{  Tests\Data\Greed\spawn.golden.txt on the scenarios of                        }
{  DelphiDoom.Tests.Greed.SpawnScenarios; here the library runs the same cases  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.Spawner;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Greed.Types, DelphiDoom.Greed.Intf,
  DelphiDoom.Greed.Actor.Types, DelphiDoom.Greed.LinkedPool, DelphiDoom.Greed.World.Intf, DelphiDoom.Greed.World,
  DelphiDoom.Greed.Random, DelphiDoom.Greed.Game.Constants, DelphiDoom.Greed.Game.Tables,
  DelphiDoom.Greed.Game.Intf, DelphiDoom.Greed.Game.State, DelphiDoom.Greed.Spawner.Intf,
  DelphiDoom.Greed.Spawner, DelphiDoom.Tests.Greed.SpawnScenarios;

type
  /// <summary>CA_GetNamedNum of the scenarios: a number from the name, the other calls are not used</summary>
  TFakeLumpNumbers = class(TInterfacedObject, IGreedArchive)
  public
    function GetLumpCount: Integer;
    function GetLumpInfo(AIndex: Integer): TGreedLumpInfo;
    function GetLumpName(AIndex: Integer): string;
    function GetLumpSize(AIndex: Integer): Integer;
    function IndexOf(const AName: string): Integer;
    function RequireIndexOf(const AName: string): Integer;
    function ReadLump(AIndex: Integer): TBytes;
    function ReadLumpRaw(AIndex: Integer): TBytes;
  end;

  /// <summary>SoundEffect and DemandLoadMonster go to two lists</summary>
  TSpawnCallLog = class(TInterfacedObject, IGreedGameSound, IGreedSpritePictures)
  strict private
    FSounds: TArray<TSpawnRow>;
    FDemands: TArray<TSpawnRow>;
  public
    procedure SoundEffect(ASound, AVariation: Integer; AX, AY: TGreedFixed);
    procedure DemandLoadMonster(ALump, ACount: Integer);
    procedure Clear;
    /// <summary>The demands and then the sounds, as the harness of the original writes them</summary>
    function Calls: TArray<TSpawnRow>;
    property Sounds: TArray<TSpawnRow> read FSounds;
    property Demands: TArray<TSpawnRow> read FDemands;
  end;

  [TestFixture]
  [Category('greed')]
  TTestGreedSpawner = class(TObject)
  strict private
    FWorld: IGreedWorld;
    FSprites: TGreedLinkedPool<TGreedSprite>;
    FElevators: TGreedLinkedPool<TGreedElevator>;
    FState: TGreedGameState;
    FRandom: TGreedRandomTable;
    FRandomIntf: IGreedRandom;
    FLog: TSpawnCallLog;
    FLogIntf: IGreedGameSound;
    FSpawnerObject: TGreedSpawner;
    FSpawner: IGreedSpawner;
    procedure NewGame;
    function Spawn(AValue, ATileX, ATileY: Integer; AActive: Boolean = True; ASpawnId: Integer = 0): Integer;
    function RunCase(const ACase: TSpawnCase; const AMap: TSpawnMap): TSpawnSnapshot;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeSollevareSenzaUnaDipendenza;
    [Test]
    procedure DovrebbeDareNilPerUnValoreSconosciuto;
    [Test]
    procedure DovrebbeCreareUnMostroAttivo;
    [Test]
    procedure DovrebbeCreareUnMostroCheNonCade;
    [Test]
    procedure DovrebbeChiedereLeImmaginiDelMostro;
    [Test]
    procedure DovrebbeSuonareIlColpoDelMostro;
    [Test]
    procedure DovrebbeSegnareIlProiettileDelGiocatoreDiCasa;
    [Test]
    procedure DovrebbeMettereIlGiocatoreSulPuntoDiPartenza;
    [Test]
    procedure DovrebbeLasciareIlGiocatoreGiaPiazzato;
    [Test]
    procedure DovrebbeRifiutareUnaPartenzaDiReteSenzaPavimento;
    [Test]
    procedure DovrebbeCreareUnAscensoreAllAltezzaMassimaIntorno;
    [Test]
    procedure DovrebbeCreareUnaPortaEVedereLaDoppia;
    [Test]
    procedure DovrebbeCreareUnAreaDiSpawnSoloSeConsentito;
    [Test]
    procedure DovrebbeCreareIlGeneratoreERestituireNil;
    [Test]
    procedure DovrebbeTogliereIlSanguePiuVecchioOltreIlLimite;
    [Test]
    procedure DovrebbeNonFareSangueSenzaViolenza;
    [Test]
    procedure DovrebbeAumentareLaScalaInModalitaMidget;
    [Test]
    procedure DovrebbeRifiutareUnCloneDiUnPersonaggioCheNonEsiste;
    [Test]
    procedure DovrebbeSegnareLUscita;
    [Test]
    procedure DovrebbeAppendereUnOggettoAlSoffitto;
    [Test]
    procedure DovrebbeAzzerareIContatori;
    [Test]
    procedure DovrebbeDareGliStessiRisultatiDelCodiceOriginale;
  end;

implementation

uses
  DelphiDoom.Tests.Greed.RealData;

const
  GOLDEN_NAME = 'spawn.golden.txt';
  /// the full descriptions of the library go to the file named here, to look for a difference
  DUMP_VARIABLE = 'DELPHIDOOM_GREED_SPAWN_DUMP';

function TileCentre(ATile: Integer): TGreedFixed;
begin
  Result := (ATile shl GREED_FRACTILESHIFT) + (32 shl GREED_FRACBITS);
end;

{ TFakeLumpNumbers }

function TFakeLumpNumbers.GetLumpCount: Integer;
begin
  Result := 0;
end;

function TFakeLumpNumbers.GetLumpInfo(AIndex: Integer): TGreedLumpInfo;
begin
  Result := Default(TGreedLumpInfo);
end;

function TFakeLumpNumbers.GetLumpName(AIndex: Integer): string;
begin
  Result := '';
end;

function TFakeLumpNumbers.GetLumpSize(AIndex: Integer): Integer;
begin
  Result := 0;
end;

function TFakeLumpNumbers.IndexOf(const AName: string): Integer;
begin
  Result := TSpawnScenarios.LumpNumber(AName);
end;

function TFakeLumpNumbers.RequireIndexOf(const AName: string): Integer;
begin
  Result := TSpawnScenarios.LumpNumber(AName);
end;

function TFakeLumpNumbers.ReadLump(AIndex: Integer): TBytes;
begin
  Result := nil;
end;

function TFakeLumpNumbers.ReadLumpRaw(AIndex: Integer): TBytes;
begin
  Result := nil;
end;

{ TSpawnCallLog }

procedure TSpawnCallLog.SoundEffect(ASound, AVariation: Integer; AX, AY: TGreedFixed);
begin
  FSounds := FSounds + [TSpawnRow.Create(SPAWN_CALL_SOUND, ASound, AVariation, AX, AY)];
end;

procedure TSpawnCallLog.DemandLoadMonster(ALump, ACount: Integer);
begin
  FDemands := FDemands + [TSpawnRow.Create(SPAWN_CALL_DEMAND, ALump, ACount, 0, 0)];
end;

procedure TSpawnCallLog.Clear;
begin
  FSounds := nil;
  FDemands := nil;
end;

function TSpawnCallLog.Calls: TArray<TSpawnRow>;
begin
  Result := FDemands + FSounds;
end;

{ TTestGreedSpawner }

procedure TTestGreedSpawner.Setup;
begin
  FSprites := TGreedLinkedPool<TGreedSprite>.Create(GREED_MAX_SPRITES, 'sprites');
  FElevators := TGreedLinkedPool<TGreedElevator>.Create(GREED_MAX_ELEVATORS, 'elevators');
  FRandom := TGreedRandomTable.Create;
  FRandomIntf := FRandom;
  FLog := TSpawnCallLog.Create;
  FLogIntf := FLog;
  NewGame;
end;

procedure TTestGreedSpawner.TearDown;
begin
  FSpawner := nil;
  FSpawnerObject := nil;
  FreeAndNil(FState);
  FLogIntf := nil;
  FLog := nil;
  FRandomIntf := nil;
  FRandom := nil;
  FWorld := nil;
  FreeAndNil(FElevators);
  FreeAndNil(FSprites);
end;

procedure TTestGreedSpawner.NewGame;
var
  LNumber: Integer;
begin
  FSpawner := nil;
  FreeAndNil(FState);
  FSprites.Clear;
  FElevators.Clear;
  FWorld := TGreedWorld.Create;
  FState := TGreedGameState.Create(FWorld, FSprites, FElevators);
  // utils.pas: slumps[i] := CA_GetNamedNum(slumpnames[i])
  for LNumber := Low(FState.SpriteLumps) to High(FState.SpriteLumps) do
    FState.SpriteLumps[LNumber] := TSpawnScenarios.LumpNumber(TGreedGameTables.SpriteLumpNames[LNumber]);
  FState.PlayerNum := 0;
  FState.Player.X := -1;
  FRandom.Offset := 0;
  FLog.Clear;
  FSpawnerObject := TGreedSpawner.Create(FState, TFakeLumpNumbers.Create, FRandomIntf, FLogIntf, FLog);
  FSpawner := FSpawnerObject;
end;

function TTestGreedSpawner.Spawn(AValue, ATileX, ATileY: Integer; AActive: Boolean; ASpawnId: Integer): Integer;
begin
  Result := FSpawner.SpawnSprite(AValue, TileCentre(ATileX), TileCentre(ATileY), 0, 0, 0, 0, AActive, ASpawnId);
end;

procedure TTestGreedSpawner.DovrebbeSollevareSenzaUnaDipendenza;
var
  LLumps: IGreedArchive;
begin
  LLumps := TFakeLumpNumbers.Create;
  Assert.WillRaise(
    procedure
    begin
      TGreedSpawner.Create(nil, LLumps, FRandomIntf, FLogIntf, FLog);
    end, EArgumentNilException, 'state');
  Assert.WillRaise(
    procedure
    begin
      TGreedSpawner.Create(FState, nil, FRandomIntf, FLogIntf, FLog);
    end, EArgumentNilException, 'archive');
  Assert.WillRaise(
    procedure
    begin
      TGreedSpawner.Create(FState, LLumps, nil, FLogIntf, FLog);
    end, EArgumentNilException, 'random');
  Assert.WillRaise(
    procedure
    begin
      TGreedSpawner.Create(FState, LLumps, FRandomIntf, nil, FLog);
    end, EArgumentNilException, 'sound');
  Assert.WillRaise(
    procedure
    begin
      TGreedSpawner.Create(FState, LLumps, FRandomIntf, FLogIntf, nil);
    end, EArgumentNilException, 'pictures');
end;

procedure TTestGreedSpawner.DovrebbeDareNilPerUnValoreSconosciuto;
begin
  FWorld.SetValue(gpMapSprites, 5 * GREED_MAP_SIZE + 4, 77);
  Assert.AreEqual(GREED_POOL_NIL, Spawn(0, 4, 5));
  Assert.AreEqual(GREED_POOL_NIL, Spawn(GREED_S_SOLID, 4, 5));
  Assert.AreEqual(GREED_POOL_NIL, Spawn(699, 4, 5));
  Assert.AreEqual(0, FSprites.Count);
  Assert.AreEqual(77, Integer(FWorld.GetValue(gpMapSprites, 5 * GREED_MAP_SIZE + 4)));
  Assert.AreEqual(0, FRandom.Offset);
end;

procedure TTestGreedSpawner.DovrebbeCreareUnMostroAttivo;
var
  LIndex: Integer;
  LSprite: PGreedSprite;
begin
  FWorld.SetValue(gpFloorHeight, 5 * GREED_MAP_SIZE + 4, 10);
  LIndex := FSpawner.SpawnSprite(GREED_S_MONSTER1, TileCentre(4), TileCentre(5), 0, 0, 1024 + 300, 0, True, 0);
  Assert.AreNotEqual(GREED_POOL_NIL, LIndex);
  LSprite := PGreedSprite(FSprites.Item(LIndex));
  Assert.IsTrue(LSprite^.Active);
  Assert.IsFalse(LSprite^.NoFalling);
  Assert.AreEqual(GREED_S_MONSTER1, LSprite^.Kind);
  Assert.AreEqual(300, LSprite^.Angle, 'the angle is cut to 0..1023');
  Assert.AreEqual(10 * GREED_FRACUNIT, LSprite^.Z);
  Assert.AreEqual(80, LSprite^.HitPoints);
  Assert.AreEqual(GREED_S_MONSTERBULLET1, LSprite^.Bullet);
  Assert.AreEqual(TSpawnScenarios.LumpNumber('kman'), LSprite^.BasePic);
  Assert.AreEqual(LSprite^.BasePic, LSprite^.StartPic);
  Assert.AreEqual(LSprite^.X, LSprite^.OldX);
  Assert.AreEqual(LSprite^.Z, LSprite^.NewZ);
  Assert.AreEqual(10 * GREED_FRACUNIT, LSprite^.NewFloorZ);
  Assert.AreEqual(1, Integer(FWorld.GetValue(gpMapSprites, 5 * GREED_MAP_SIZE + 4)));
end;

procedure TTestGreedSpawner.DovrebbeCreareUnMostroCheNonCade;
var
  LSprite: PGreedSprite;
begin
  LSprite := PGreedSprite(FSprites.Item(Spawn(GREED_S_MONSTER3_NS, 4, 5, False)));
  Assert.IsTrue(LSprite^.NoFalling);
  Assert.IsFalse(LSprite^.Active);
  Assert.AreEqual(GREED_S_MONSTER3, LSprite^.Kind);
  Assert.AreEqual(25 * GREED_FRACUNIT, LSprite^.ZAdjust, 'the probe flies');
  Assert.AreEqual(25 * GREED_FRACUNIT, LSprite^.Z);
end;

procedure TTestGreedSpawner.DovrebbeChiedereLeImmaginiDelMostro;
begin
  Spawn(GREED_S_MONSTER4, 4, 5);
  Assert.AreEqual<Integer>(1, Length(FLog.Demands));
  Assert.AreEqual(TSpawnScenarios.LumpNumber('kbot'), FLog.Demands[0][1]);
  Assert.AreEqual(48, FLog.Demands[0][2]);
  Spawn(GREED_S_DEADMONSTER2, 6, 5);
  Assert.AreEqual(TSpawnScenarios.LumpNumber('kfem') + 55, FLog.Demands[1][1]);
  Assert.AreEqual(1, FLog.Demands[1][2]);
  FSpawner.DemandLoadMonster(1234, 48);
  Assert.AreEqual(1234, FLog.Demands[2][1]);
end;

procedure TTestGreedSpawner.DovrebbeSuonareIlColpoDelMostro;
var
  LSprite: PGreedSprite;
begin
  LSprite := PGreedSprite(FSprites.Item(FSpawner.SpawnSprite(GREED_S_MONSTERBULLET6, TileCentre(4), TileCentre(5),
    7 * GREED_FRACUNIT, 3 * GREED_FRACUNIT, 100, 20, True, 9)));
  Assert.AreEqual(150, LSprite^.Damage);
  Assert.AreEqual(2, LSprite^.Scale);
  Assert.AreEqual(10 * GREED_FRACUNIT, LSprite^.Z);
  Assert.AreEqual(9, LSprite^.SpawnId);
  Assert.AreEqual(5 * GREED_MAP_SIZE + 4, LSprite^.StartSpot);
  Assert.AreEqual<Integer>(1, Length(FLog.Sounds));
  Assert.AreEqual(GREED_SN_MON6_FIRE, FLog.Sounds[0][1]);
  Assert.AreEqual(7, FLog.Sounds[0][2]);
end;

procedure TTestGreedSpawner.DovrebbeSegnareIlProiettileDelGiocatoreDiCasa;
begin
  FState.PlayerNum := 3;
  Assert.AreEqual(203, FSprites.Item(Spawn(GREED_S_MINEBULLET, 4, 5, True, 3))^.SpawnId);
  Assert.AreEqual(2, FSprites.Item(Spawn(GREED_S_GRENADEBULLET, 4, 5, True, 2))^.SpawnId);
  Assert.AreEqual(-1, FSprites.Item(Spawn(GREED_S_SOULBULLET, 4, 5, True, 3))^.StartSpot);
end;

procedure TTestGreedSpawner.DovrebbeMettereIlGiocatoreSulPuntoDiPartenza;
begin
  FWorld.SetValue(gpFloorHeight, 9 * GREED_MAP_SIZE + 7, 20);
  FWorld.SetValue(gpMapSprites, 9 * GREED_MAP_SIZE + 7, GREED_S_PLAYER);
  FState.Player.Height := 40 * GREED_FRACUNIT;
  Assert.AreEqual(GREED_POOL_NIL, Spawn(GREED_S_PLAYER, 7, 9));
  Assert.AreEqual(TileCentre(7), FState.Player.X);
  Assert.AreEqual(TileCentre(9), FState.Player.Y);
  Assert.AreEqual(60 * GREED_FRACUNIT, FState.Player.Z);
  Assert.AreEqual(9 * GREED_MAP_SIZE + 7, FState.Player.MapSpot);
  Assert.AreEqual(256, FState.Player.Angle);
  Assert.AreEqual(256 * 64, FState.PlayerAngle64);
  Assert.AreEqual(7, FState.StartLocations[0][0]);
  Assert.AreEqual(9, FState.StartLocations[0][1]);
  Assert.AreEqual(0, Integer(FWorld.GetValue(gpMapSprites, 9 * GREED_MAP_SIZE + 7)));
end;

procedure TTestGreedSpawner.DovrebbeLasciareIlGiocatoreGiaPiazzato;
begin
  FState.Player.X := 5;
  Spawn(GREED_S_PLAYER, 7, 9);
  Assert.AreEqual(5, FState.Player.X);
  Assert.AreEqual(7, FState.StartLocations[0][0]);
end;

procedure TTestGreedSpawner.DovrebbeRifiutareUnaPartenzaDiReteSenzaPavimento;
begin
  Assert.WillRaise(
    procedure
    begin
      Spawn(GREED_S_NETPLAYER3, 7, 9);
    end, EGreedException, 'refused');
  FWorld.SetValue(gpFloorPic, 9 * GREED_MAP_SIZE + 7, 3);
  FWorld.SetValue(gpCeilingPic, 9 * GREED_MAP_SIZE + 7, 4);
  Spawn(GREED_S_NETPLAYER3, 7, 9);
  Assert.AreEqual(7, FState.StartLocations[2][0]);
  Assert.AreEqual(9, FState.StartLocations[2][1]);
  Assert.AreEqual(-1, FState.Player.X, 'the net game is not ported');
end;

procedure TTestGreedSpawner.DovrebbeCreareUnAscensoreAllAltezzaMassimaIntorno;
var
  LElevator: TGreedElevator;
  LSpot: Integer;
begin
  LSpot := 9 * GREED_MAP_SIZE + 7;
  FWorld.SetValue(gpFloorHeight, LSpot, 10);
  FWorld.SetValue(gpFloorHeight, LSpot + GREED_MAP_SIZE + 1, 50);
  FWorld.SetValue(gpFloorHeight, LSpot + 2, 90);
  FState.Player.TimeCount := 1234;
  Assert.AreEqual(GREED_POOL_NIL, Spawn(GREED_S_ELEVATOR, 7, 9));
  Assert.AreEqual(1, FElevators.Count);
  LElevator := FElevators.Item(FElevators.First)^;
  Assert.IsTrue(LElevator.Up);
  Assert.AreEqual(10, LElevator.Floor);
  Assert.AreEqual(50, LElevator.Ceiling);
  Assert.AreEqual(50, LElevator.Position);
  Assert.AreEqual(50 * GREED_FRACUNIT, LElevator.Position64);
  Assert.AreEqual(1234, LElevator.Timer);
  Assert.AreEqual(LSpot, LElevator.MapSpot);
  Assert.AreEqual(50, Integer(FWorld.GetValue(gpFloorHeight, LSpot)));
  NewGame;
  FWorld.SetValue(gpFloorHeight, LSpot, 10);
  FWorld.SetValue(gpCeilingHeight, LSpot, 70);
  Spawn(GREED_S_ELEVATORHIGH, 7, 9);
  LElevator := FElevators.Item(FElevators.First)^;
  Assert.AreEqual(Ord(getSwap), Ord(LElevator.Kind));
  Assert.AreEqual(70, LElevator.Position);
  Assert.AreEqual(0, LElevator.Position64, 'the original leaves it at zero');
  Assert.AreEqual(GREED_ELEVATOR_PAUSED, LElevator.Timer);
  Assert.AreEqual(70, Integer(FWorld.GetValue(gpFloorHeight, LSpot)));
end;

procedure TTestGreedSpawner.DovrebbeCreareUnaPortaEVedereLaDoppia;
var
  LDoor: TGreedDoor;
begin
  FState.Player.TimeCount := 55;
  Spawn(GREED_S_HDOOR3, 7, 9);
  Spawn(GREED_S_HDOOR3, 8, 9);
  Spawn(GREED_S_VDOOR1, 20, 9);
  Assert.AreEqual(3, FWorld.DoorCount);
  LDoor := FWorld.GetDoor(0);
  Assert.AreEqual(Ord(gdoHorizontal), Ord(LDoor.Orientation));
  Assert.IsTrue(LDoor.Bumpable);
  Assert.AreEqual(64 * GREED_FRACUNIT, LDoor.Position);
  Assert.AreEqual(55, LDoor.Timer);
  Assert.AreEqual(TSpawnScenarios.LumpNumber('door_3') - TSpawnScenarios.LumpNumber('startwalls'), LDoor.Pic);
  Assert.AreEqual(Ord(gdoHorizontal2), Ord(FWorld.GetDoor(1).Orientation));
  Assert.AreEqual(Ord(gdoVertical), Ord(FWorld.GetDoor(2).Orientation));
  Assert.IsTrue(FWorld.GetMapFlags(9 * GREED_MAP_SIZE + 7) and GREED_FL_DOOR <> 0);
end;

procedure TTestGreedSpawner.DovrebbeCreareUnAreaDiSpawnSoloSeConsentito;
var
  LArea: TGreedSpawnArea;
begin
  FWorld.SetValue(gpMapSprites, 9 * GREED_MAP_SIZE + 7, 200);
  FState.NoSpawn := True;
  Spawn(GREED_S_SPAWN3, 7, 9);
  Assert.AreEqual(0, FWorld.SpawnAreaCount);
  Assert.AreEqual(0, Integer(FWorld.GetValue(gpMapSprites, 9 * GREED_MAP_SIZE + 7)));
  FState.NoSpawn := False;
  FState.Player.TimeCount := 1000;
  FRandom.Offset := 2;
  Spawn(GREED_S_SPAWN3, 7, 9);
  Spawn(GREED_S_SPAWN9_NS, 8, 9);
  Assert.AreEqual(2, FWorld.SpawnAreaCount);
  LArea := FWorld.GetSpawnArea(0);
  Assert.AreEqual(12, LArea.Kind);
  Assert.AreEqual(TileCentre(7), LArea.MapX);
  Assert.AreEqual(9 * GREED_MAP_SIZE + 7, LArea.MapSpot);
  // the third number of the table is 109
  Assert.AreEqual(1000 + (109 and 15) * 64, LArea.Time);
  Assert.AreEqual(101, FWorld.GetSpawnArea(1).Kind);
end;

procedure TTestGreedSpawner.DovrebbeCreareIlGeneratoreERestituireNil;
var
  LSprite: PGreedSprite;
begin
  Assert.AreEqual(GREED_POOL_NIL, Spawn(GREED_S_GENERATOR2, 7, 9));
  Assert.AreEqual(1, FWorld.SpawnAreaCount);
  Assert.AreEqual(1, FWorld.GetSpawnArea(0).Kind);
  Assert.AreEqual(1, FSprites.Count);
  LSprite := PGreedSprite(FSprites.Item(FSprites.First));
  Assert.AreEqual(GREED_S_GENERATOR, LSprite^.Kind);
  Assert.AreEqual(TileCentre(7), LSprite^.X);
  Assert.AreEqual(2, FRandom.Offset);
end;

procedure TTestGreedSpawner.DovrebbeTogliereIlSanguePiuVecchioOltreIlLimite;
var
  LFirst, LSecond, LNew: Integer;
begin
  // the first numbers of the table are 0, 8, 109: under 221, so blood on the floor
  LFirst := Spawn(GREED_S_BLOODSPLAT, 7, 9);
  LSecond := Spawn(GREED_S_BLOODSPLAT, 7, 9);
  Assert.AreEqual(2, FSpawnerObject.BloodCount);
  FSpawnerObject.BloodCount := GREED_MAX_BLOOD_SPRITES + 1;
  LNew := Spawn(GREED_S_BLOODSPLAT, 7, 9);
  Assert.AreEqual(LFirst, LNew, 'the slot of the oldest splat is used again');
  Assert.AreEqual(2, FSprites.Count);
  Assert.AreEqual(LSecond, FSprites.First);
  Assert.AreEqual(GREED_MAX_BLOOD_SPRITES + 1, FSpawnerObject.BloodCount);
  // the metal parts: the count never goes down
  FSpawnerObject.MetalCount := GREED_MAX_METAL_PARTS + 1;
  Spawn(GREED_S_METALPARTS, 7, 9);
  Spawn(GREED_S_METALPARTS, 7, 9);
  Assert.AreEqual(GREED_MAX_METAL_PARTS + 3, FSpawnerObject.MetalCount);
  Assert.AreEqual(3, FSprites.Count);
end;

procedure TTestGreedSpawner.DovrebbeNonFareSangueSenzaViolenza;
begin
  Assert.IsTrue(FSpawnerObject.Violence);
  FSpawnerObject.Violence := False;
  Assert.AreEqual(GREED_POOL_NIL, Spawn(GREED_S_BLOODSPLAT, 7, 9));
  Assert.AreEqual(1, FRandom.Offset);
  // the fourth number of the table is 220, the fifth 222: a puff instead of blood, also without violence
  FRandom.Offset := 4;
  Assert.AreEqual(GREED_S_WALLPUFF, FSprites.Item(Spawn(GREED_S_BLOODSPLAT, 7, 9))^.Kind);
end;

procedure TTestGreedSpawner.DovrebbeAumentareLaScalaInModalitaMidget;
begin
  FState.MidgetMode := True;
  Assert.AreEqual(2, FSprites.Item(Spawn(GREED_S_MONSTER1, 4, 5))^.Scale);
  Assert.AreEqual(1, FSprites.Item(Spawn(GREED_S_MONSTER6, 6, 5))^.Scale);
end;

procedure TTestGreedSpawner.DovrebbeRifiutareUnCloneDiUnPersonaggioCheNonEsiste;
begin
  Assert.WillRaise(
    procedure
    begin
      Spawn(GREED_S_CLONE, 4, 5, True, GREED_MAXCHARTYPES);
    end, EGreedException, 'refused');
  Assert.AreEqual(TSpawnScenarios.LumpNumber('mooman'), FSprites.Item(Spawn(GREED_S_DECOY, 4, 5, True, 2))^.BasePic);
end;

procedure TTestGreedSpawner.DovrebbeSegnareLUscita;
begin
  Assert.AreNotEqual(GREED_POOL_NIL, Spawn(GREED_S_EXIT, 7, 9));
  Assert.IsTrue(FState.ExitExists);
  Assert.AreEqual(7, FState.ExitX);
  Assert.AreEqual(9, FState.ExitY);
  Assert.AreEqual(GREED_SM_EXIT, Integer(FWorld.GetValue(gpMapSprites, 9 * GREED_MAP_SIZE + 7)));
end;

procedure TTestGreedSpawner.DovrebbeAppendereUnOggettoAlSoffitto;
var
  LSprite: PGreedSprite;
begin
  FWorld.SetValue(gpFloorHeight, 9 * GREED_MAP_SIZE + 7, 10);
  FWorld.SetValue(gpCeilingHeight, 9 * GREED_MAP_SIZE + 7, 100);
  LSprite := PGreedSprite(FSprites.Item(Spawn(GREED_S_ITEM8, 7, 9)));
  Assert.AreEqual((100 - 39 - 10) * GREED_FRACUNIT, LSprite^.ZAdjust);
  Assert.AreEqual((100 - 39) * GREED_FRACUNIT, LSprite^.Z);
  Assert.AreEqual(TSpawnScenarios.LumpNumber('miscobj') + 7, LSprite^.BasePic);
  Assert.AreEqual(0, Integer(FWorld.GetValue(gpMapSprites, 9 * GREED_MAP_SIZE + 7)));
  LSprite := PGreedSprite(FSprites.Item(Spawn(GREED_S_ITEM9, 8, 9)));
  Assert.AreEqual(48 * GREED_FRACUNIT, LSprite^.Height);
  Assert.AreEqual(2, Integer(FWorld.GetValue(gpMapSprites, 9 * GREED_MAP_SIZE + 8)));
end;

procedure TTestGreedSpawner.DovrebbeAzzerareIContatori;
begin
  FSpawnerObject.BloodCount := 5;
  FSpawnerObject.MetalCount := 6;
  FSpawnerObject.ResetCounts;
  Assert.AreEqual(0, FSpawnerObject.BloodCount);
  Assert.AreEqual(0, FSpawnerObject.MetalCount);
end;

function SpriteRow(ASlot: Integer; const S: TGreedSprite): TSpawnRow;
begin
  Result := TSpawnRow.Create(ASlot,
    S.Animation, S.AnimationTime, S.MoveSpeed, S.ZAdjust, S.X, S.Y, S.Z, S.LastX, S.LastY, S.BasePic, Ord(S.Rotate),
    S.Angle, S.Angle2, S.MoveSize, Ord(S.Active), Ord(S.NoFalling), S.Intelligence, S.Bullet, S.Enraged,
    S.MoveTime, S.ModeTime, S.ActionTime, S.ScanTime, S.FireTime, S.Heat, S.StartPic, S.MoveMode, S.StartSpot,
    S.Damage, S.HitPoints, S.Kind, S.SpawnId, S.Score, S.MaxMove, S.Regen, S.DeathEvent, S.Height,
    Ord(S.SpecialType), S.Scale, S.OldX, S.OldY, S.OldZ, S.OldAngle, S.OldAngle2, S.OldFloorZ, S.NewX, S.NewY,
    S.NewZ, S.NewAngle, S.NewAngle2, S.NewFloorZ, Ord(S.Grounded));
end;

function TTestGreedSpawner.RunCase(const ACase: TSpawnCase; const AMap: TSpawnMap): TSpawnSnapshot;
var
  LSpot, LNumber, LIndex, LCount: Integer;
  LTiles: TSpawnTiles;
  LElevator: TGreedElevator;
  LDoor: TGreedDoor;
  LArea: TGreedSpawnArea;
begin
  NewGame;
  for LSpot := 0 to SPAWN_TILES - 1 do
  begin
    FWorld.SetValue(gpFloorHeight, LSpot, AMap.FloorHeight[LSpot]);
    FWorld.SetValue(gpCeilingHeight, LSpot, AMap.CeilingHeight[LSpot]);
    FWorld.SetValue(gpFloorPic, LSpot, AMap.FloorPic[LSpot]);
    FWorld.SetValue(gpCeilingPic, LSpot, AMap.CeilingPic[LSpot]);
    FWorld.SetMapFlags(LSpot, AMap.MapFlags[LSpot]);
    FWorld.SetValue(gpMapSprites, LSpot, AMap.MapSprites[LSpot]);
  end;
  FState.Player.X := ACase.PlayerX;
  FState.Player.Y := ACase.PlayerY;
  FState.Player.Z := ACase.PlayerZ;
  FState.Player.Height := ACase.PlayerHeight;
  FState.Player.TimeCount := ACase.PlayerTime;
  FState.TimeCount := ACase.TimeCount;
  FState.MidgetMode := ACase.Midget;
  FState.NoSpawn := ACase.NoSpawn;
  FState.PlayerNum := ACase.PlayerNum;
  FSpawnerObject.Violence := ACase.Violence;
  for LNumber := Low(ACase.Primaries) to High(ACase.Primaries) do
    FState.Primaries[LNumber] := ACase.Primaries[LNumber];
  for LNumber := Low(ACase.Secondaries) to High(ACase.Secondaries) do
    FState.Secondaries[LNumber] := ACase.Secondaries[LNumber];
  for LNumber := 0 to ACase.Prefill - 1 do
  begin
    LIndex := FSprites.Add;
    FSprites.Item(LIndex)^.Kind := TSpawnScenarios.PrefillKind(LNumber);
    FSprites.Item(LIndex)^.X := LNumber;
  end;
  if ACase.Prefill >= 3 then
    FSprites.Remove(ACase.Prefill div 2);
  FSpawnerObject.BloodCount := ACase.BloodCount;
  FSpawnerObject.MetalCount := ACase.MetalCount;
  FRandom.Offset := ACase.RandomOffset;

  Result := Default(TSpawnSnapshot);
  Result.Returned := GREED_POOL_NIL;
  try
    Result.Returned := FSpawner.SpawnSprite(ACase.Value, ACase.X, ACase.Y, ACase.Z, ACase.ZAdjust, ACase.Angle,
      ACase.Angle2, ACase.Active, ACase.SpawnId);
  except
    on EGreedException do
      Result.Failed := True;
  end;

  LIndex := FSprites.First;
  while LIndex <> GREED_POOL_NIL do
  begin
    Result.Sprites := Result.Sprites + [SpriteRow(LIndex, FSprites.Item(LIndex)^)];
    LIndex := FSprites.Next(LIndex);
  end;
  LIndex := FElevators.First;
  while LIndex <> GREED_POOL_NIL do
  begin
    LElevator := FElevators.Item(LIndex)^;
    Result.Elevators := Result.Elevators + [TSpawnRow.Create(LIndex, Ord(LElevator.Up), Ord(LElevator.Down),
      LElevator.Position, LElevator.Position64, LElevator.Timer, LElevator.Floor, LElevator.Ceiling,
      LElevator.MapSpot, LElevator.Speed, LElevator.Eval, LElevator.EndEval, LElevator.NoSave, Ord(LElevator.Kind))];
    LIndex := FElevators.Next(LIndex);
  end;
  LCount := FWorld.DoorCount;
  SetLength(Result.Doors, LCount);
  for LNumber := 0 to LCount - 1 do
  begin
    LDoor := FWorld.GetDoor(LNumber);
    Result.Doors[LNumber] := TSpawnRow.Create(LDoor.TileX, LDoor.TileY, Ord(LDoor.Open), Ord(LDoor.Opening),
      Ord(LDoor.Closing), Ord(LDoor.Blocked), Ord(LDoor.Bumpable), LDoor.Size, LDoor.Timer, LDoor.Locks,
      Ord(LDoor.Orientation), Ord(LDoor.Transparent), LDoor.Pic, LDoor.Height, LDoor.Position);
  end;
  LCount := FWorld.SpawnAreaCount;
  SetLength(Result.Areas, LCount);
  for LNumber := 0 to LCount - 1 do
  begin
    LArea := FWorld.GetSpawnArea(LNumber);
    Result.Areas[LNumber] := TSpawnRow.Create(LArea.MapSpot, LArea.MapX, LArea.MapY, LArea.Kind, LArea.Time);
  end;
  FWorld.CopyPlane(gpFloorHeight, @LTiles[0]);
  Result.FloorHeightHash := TSpawnScenarios.HashTiles(LTiles);
  FWorld.CopyPlane(gpMapSprites, @LTiles[0]);
  Result.MapSpritesHash := TSpawnScenarios.HashTiles(LTiles);
  FWorld.CopyMapFlags(@LTiles[0]);
  Result.MapFlagsHash := TSpawnScenarios.HashTiles(LTiles);
  Result.RandomUsed := FRandom.Offset - ACase.RandomOffset;
  Result.Calls := FLog.Calls;
  SetLength(Result.Globals, 27);
  Result.Globals[0] := FState.Player.X;
  Result.Globals[1] := FState.Player.Y;
  Result.Globals[2] := FState.Player.Z;
  Result.Globals[3] := FState.Player.MapSpot;
  Result.Globals[4] := FState.Player.Angle;
  Result.Globals[5] := FState.PlayerAngle64;
  for LNumber := 0 to GREED_MAXSTARTLOCATIONS - 1 do
  begin
    Result.Globals[6 + LNumber * 2] := FState.StartLocations[LNumber][0];
    Result.Globals[7 + LNumber * 2] := FState.StartLocations[LNumber][1];
  end;
  Result.Globals[22] := Ord(FState.ExitExists);
  Result.Globals[23] := FState.ExitX;
  Result.Globals[24] := FState.ExitY;
  Result.Globals[25] := FSpawnerObject.BloodCount;
  Result.Globals[26] := FSpawnerObject.MetalCount;
end;

procedure TTestGreedSpawner.DovrebbeDareGliStessiRisultatiDelCodiceOriginale;
var
  LGolden, LDump: TStringList;
  LMaps: array[1..6] of TSpawnMap;
  LCase: TSpawnCase;
  LSnapshot: TSpawnSnapshot;
  LIndex, LLine, LDifferences, LWithSprite: Integer;
  LFirst, LExpected, LActual, LDumpName: string;
begin
  for LIndex := Low(LMaps) to High(LMaps) do
    TSpawnScenarios.BuildMap(LIndex, LMaps[LIndex]);
  LDumpName := GetEnvironmentVariable(DUMP_VARIABLE);
  LDifferences := 0;
  LWithSprite := 0;
  LFirst := '';
  LGolden := TStringList.Create;
  LDump := TStringList.Create;
  try
    LGolden.LoadFromFile(TGreedRealData.GoldenPath(GOLDEN_NAME));
    Assert.AreEqual(TSpawnScenarios.CaseCount + 1, LGolden.Count, 'the golden file is of another list of cases');
    LLine := 1;
    for LIndex := 0 to TSpawnScenarios.CaseCount - 1 do
    begin
      LCase := TSpawnScenarios.CaseAt(LIndex);
      LSnapshot := RunCase(LCase, LMaps[LCase.MapSeed]);
      if LSnapshot.Returned <> GREED_POOL_NIL then
        Inc(LWithSprite);
      LExpected := LGolden[LLine];
      LActual := TSpawnScenarios.GoldenLine(LCase, LSnapshot);
      Inc(LLine);
      if LDumpName <> '' then
      begin
        LDump.Add('== ' + IntToStr(LIndex) + ' value ' + IntToStr(LCase.Value));
        LDump.Add(TSpawnScenarios.Describe(LSnapshot));
      end;
      if LExpected <> LActual then
      begin
        Inc(LDifferences);
        if LFirst = '' then
          LFirst := Format('case %d value %d: original "%s", library "%s"', [LIndex, LCase.Value, LExpected,
            LActual]);
      end;
    end;
    if LDumpName <> '' then
      LDump.SaveToFile(LDumpName);
  finally
    LDump.Free;
    LGolden.Free;
  end;
  Assert.AreEqual(0, LDifferences, Format('%d cases of %d differ; the first: %s', [LDifferences,
    TSpawnScenarios.CaseCount, LFirst]));
  Assert.IsTrue(LWithSprite > 1000, 'the cases must make sprites');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGreedSpawner);

end.

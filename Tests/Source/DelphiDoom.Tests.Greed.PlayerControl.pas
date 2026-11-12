{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TGreedPlayerControl and TGreedPlayerWeapons             }
{                                                                              }
{  The oracle is the code of raven.pas of xGreed as it was: the harness         }
{  Tools\Verifica\175-player compiles the original routines and writes          }
{  Tests\Data\Greed\player.golden.txt on the scenarios of                       }
{  DelphiDoom.Tests.Greed.PlayerScenarios; here the library runs the same tics  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.PlayerControl;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Greed.Types, DelphiDoom.Greed.Actor.Types,
  DelphiDoom.Greed.LinkedPool, DelphiDoom.Greed.World.Intf, DelphiDoom.Greed.World,
  DelphiDoom.Greed.Game.Constants, DelphiDoom.Greed.Game.Tables, DelphiDoom.Greed.Game.Intf,
  DelphiDoom.Greed.Game.State, DelphiDoom.Greed.PlayerMovement, DelphiDoom.Greed.PlayerControl.Intf,
  DelphiDoom.Greed.PlayerWeapons, DelphiDoom.Greed.PlayerControl, DelphiDoom.Tests.Greed.PlayerScenarios;

type
  /// <summary>
  ///   The keyboard and the mouse of the scenarios: the keys are the ones of the original, each gives its commands
  ///   (SPACE is the use and the restart, LEFT SHIFT the run and the shift, ALT the strafe and the alt)
  /// </summary>
  TFakeControls = class(TInterfacedObject, IGreedControls)
  strict private
    // keyboard[] of the original: 0 up, 1 down, 2 down and eaten
    FKeys: array[0..PLAYER_KEY_COUNT - 1] of Integer;
    FPrevious: TPlayerKeys;
    FNewCharacter: Boolean;
    FLastCharacter: Char;
    FMouseFlags, FMouseDeltaX, FMouseDeltaY: Integer;
    class function KeyOf(ACommand: TGreedCommand): Integer; static;
  public
    /// <summary>INT_ReadControls: the keys of the tic become the state of the commands</summary>
    procedure Read(const AInput: TPlayerTic);
    procedure Press(AKey: Integer);
    procedure Release(AKey: Integer);
    procedure MoveMouse(ADeltaX, ADeltaY, AFlags: Integer);
    function IsDown(ACommand: TGreedCommand): Boolean;
    function IsFresh(ACommand: TGreedCommand): Boolean;
    procedure Eat(ACommand: TGreedCommand);
    function TakeCharacter(out ACharacter: Char): Boolean;
    function IsMouseDown(AButton: TGreedMouseButton): Boolean;
    function GetMouseDeltaX: Integer;
    function GetMouseDeltaY: Integer;
  end;

  /// <summary>Everything that the control of the player calls outside: the calls go to a log</summary>
  TFakePlayerGame = class(TInterfacedObject, IGreedSpawner, IGreedGameSound, IGreedEventRunner,
    IGreedPlayerControlHost, IGreedWeaponView, IGreedMovementHost)
  strict private
    FLoaded: Integer;
  public
    Calls: TPlayerHash;
    /// <summary>How many calls of each PLAYER_CALL_ kind</summary>
    Kinds: array[1..7] of Integer;
    LastSpawn: Integer;
    Spawns: Integer;
    LastSound: Integer;
    LastLights: TGreedFixed;
    SwitchWalls: Integer;
    Events: Integer;
    function SpawnSprite(AValue: Integer; AX, AY, AZ, AZAdjust: TGreedFixed; AAngle, AAngle2: Integer;
      AActive: Boolean; ASpawnId: Integer): Integer;
    procedure DemandLoadMonster(ALump, ACount: Integer);
    procedure SoundEffect(ASound, AVariation: Integer; AX, AY: TGreedFixed);
    procedure RunEvent(AEvent: Integer; ANetSend: Boolean);
    function CheckForSwitch(ATileX, ATileY, AAngle: Integer; ADoubleSwitch: Boolean): Boolean;
    procedure SwitchWall(ATileX, ATileY, AAngle: Integer; ADoubleSwitch: Boolean);
    procedure SetLights(ABlackZ: TGreedFixed);
    procedure LoadWeapon(AWeapon: Integer);
    function PictureWidth(AMode: Integer): Integer;
    function PictureHeight(AMode: Integer): Integer;
    function GetNetMode: Boolean;
    procedure NetOpenDoor(AX, AY: TGreedFixed);
    property Loaded: Integer read FLoaded;
  end;

  [TestFixture]
  [Category('greed')]
  TTestGreedPlayerControl = class(TObject)
  strict private
    FWorld: IGreedWorld;
    FSprites: TGreedLinkedPool<TGreedSprite>;
    FElevators: TGreedLinkedPool<TGreedElevator>;
    FState: TGreedGameState;
    FGame: TFakePlayerGame;
    FGameRef: IInterface;
    FKeys: TFakeControls;
    FKeysRef: IGreedControls;
    FMovement: TGreedPlayerMovement;
    FWeaponsObject: TGreedPlayerWeapons;
    FWeapons: IGreedPlayerWeapons;
    FControl: TGreedPlayerControl;
    FLastWeaponX, FLastWeaponY: Integer;
    procedure FreeGame;
    procedure NewGame;
    procedure FlatRoom;
    procedure PlacePlayer(ATileX, ATileY: Integer);
    procedure Tic;
    procedure Tics(ACount: Integer);
    procedure PrepareScenario(const AScenario: TPlayerScenario; const AMap: TPlayerMap);
    procedure Frame;
    procedure Collect(out AValues: TPlayerValues);
    function RunScenario(const AScenario: TPlayerScenario; const AMap: TPlayerMap; ADump: TStrings): string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeSollevareSenzaUnaDipendenza;
    [Test]
    procedure DovrebbeAccelerareFinoAllaVelocitaDiCammino;
    [Test]
    procedure DovrebbeAndarePiuForteDiCorsa;
    [Test]
    procedure DovrebbeRallentareQuandoIlComandoSiRilascia;
    [Test]
    procedure DovrebbeLeggereIComandiSoloNeiTicDispari;
    [Test]
    procedure DovrebbeGirareConLeFrecce;
    [Test]
    procedure DovrebbeSaltareSoloDaTerra;
    [Test]
    procedure DovrebbeMuovereLaTestaCamminandoERiportarlaDaFermo;
    [Test]
    procedure DovrebbeSpostareLoSguardoEntroIlLimite;
    [Test]
    procedure DovrebbeChiedereIlCambioArmaSoloPerUnoSlotPieno;
    [Test]
    procedure DovrebbeAbbassareLArmaEAlzareLaNuova;
    [Test]
    procedure DovrebbeSparareNelFotogrammaDopoIlComando;
    [Test]
    procedure DovrebbeNonSparareSenzaMunizioni;
    [Test]
    procedure DovrebbeSparareLaSpreadgunAllaFineDellAnimazione;
    [Test]
    procedure DovrebbeCaricareLeArmiDiVentiInVenti;
    [Test]
    procedure DovrebbeFermareLaSondaSulMuroESegnareLoSpriteColpito;
    [Test]
    procedure DovrebbeMangiareIlTastoDelMenu;
    [Test]
    procedure DovrebbeFarAffondareIlMortoEChiedereDiRicominciare;
    [Test]
    procedure DovrebbeTenereLeLuciEntroILimiti;
    [Test]
    procedure DovrebbeAzionareGliAscensoriDiScambio;
    [Test]
    procedure DovrebbeEseguireLEventoDellInterruttoreSoloSeDiFronte;
    [Test]
    procedure DovrebbeRicordareICaratteriDeiCodiciSegreti;
    [Test]
    procedure DovrebbeUsareIlMouseSoloSeAbilitato;
    [Test]
    procedure DovrebbeDareGliStessiTicDelCodiceOriginale;
  end;

implementation

uses
  DelphiDoom.Tests.Greed.RealData, DelphiDoom.Greed.SaveTypes, DelphiDoom.Greed.Terrain;

const
  GOLDEN_NAME = 'player.golden.txt';
  /// the values of every tic of the scenario named in DELPHIDOOM_GREED_PLAYER_SCENARIO go to the file named here
  DUMP_VARIABLE = 'DELPHIDOOM_GREED_PLAYER_DUMP';
  DUMP_SCENARIO_VARIABLE = 'DELPHIDOOM_GREED_PLAYER_SCENARIO';

  KEY_OF_COMMAND: array[TGreedCommand] of Integer = (
    PK_UP, PK_RIGHT, PK_DOWN, PK_LEFT, PK_CONTROL, PK_ALT, PK_SPACE, PK_SHIFT, PK_Z, PK_X, PK_A, PK_PAGE_UP,
    PK_PAGE_DOWN, PK_HOME, PK_COMMA, PK_PERIOD, PK_INSERT, PK_DELETE, PK_S,
    PK_ESCAPE, PK_SHIFT, PK_F1, PK_F2, PK_F3, PK_F4, PK_F5, PK_F6, PK_F7, PK_F9, PK_F10, PK_ALT, PK_Q, PK_P,
    PK_MINUS, PK_PLUS, PK_M, PK_H, PK_TAB, PK_CAPS_LOCK, PK_NUM_LOCK, PK_SPACE,
    PK_1, PK_1 + 1, PK_1 + 2, PK_1 + 3, PK_1 + 4);

{ TFakeControls }

class function TFakeControls.KeyOf(ACommand: TGreedCommand): Integer;
begin
  Result := KEY_OF_COMMAND[ACommand];
end;

procedure TFakeControls.Read(const AInput: TPlayerTic);
var
  LKey: Integer;
  LCharacter: AnsiChar;
begin
  FLastCharacter := #0;
  for LKey := 0 to PLAYER_KEY_COUNT - 1 do
  begin
    if AInput.Keys[LKey] then
    begin
      if FKeys[LKey] = 0 then
        FKeys[LKey] := 1;
    end
    else
      FKeys[LKey] := 0;
  end;
  LCharacter := TPlayerScenarios.TypedCharacter(FPrevious, AInput.Keys);
  if LCharacter <> #0 then
  begin
    FLastCharacter := Char(LCharacter);
    FNewCharacter := True;
  end;
  FPrevious := AInput.Keys;
  FMouseFlags := AInput.MouseFlags;
  FMouseDeltaX := AInput.MouseDX;
  FMouseDeltaY := AInput.MouseDY;
end;

procedure TFakeControls.Press(AKey: Integer);
begin
  if FKeys[AKey] = 0 then
  begin
    FKeys[AKey] := 1;
    if PLAYER_KEY_CHARACTERS[AKey] <> #0 then
    begin
      FLastCharacter := Char(PLAYER_KEY_CHARACTERS[AKey]);
      FNewCharacter := True;
    end;
  end;
end;

procedure TFakeControls.Release(AKey: Integer);
begin
  FKeys[AKey] := 0;
end;

procedure TFakeControls.MoveMouse(ADeltaX, ADeltaY, AFlags: Integer);
begin
  FMouseDeltaX := ADeltaX;
  FMouseDeltaY := ADeltaY;
  FMouseFlags := AFlags;
end;

function TFakeControls.IsDown(ACommand: TGreedCommand): Boolean;
begin
  Result := FKeys[KeyOf(ACommand)] <> 0;
end;

function TFakeControls.IsFresh(ACommand: TGreedCommand): Boolean;
begin
  Result := FKeys[KeyOf(ACommand)] = 1;
end;

procedure TFakeControls.Eat(ACommand: TGreedCommand);
begin
  if FKeys[KeyOf(ACommand)] = 1 then
    FKeys[KeyOf(ACommand)] := 2;
end;

function TFakeControls.TakeCharacter(out ACharacter: Char): Boolean;
begin
  Result := FNewCharacter;
  ACharacter := FLastCharacter;
  FNewCharacter := False;
end;

function TFakeControls.IsMouseDown(AButton: TGreedMouseButton): Boolean;
begin
  Result := FMouseFlags and (1 shl Ord(AButton)) <> 0;
end;

function TFakeControls.GetMouseDeltaX: Integer;
begin
  Result := FMouseDeltaX;
end;

function TFakeControls.GetMouseDeltaY: Integer;
begin
  Result := FMouseDeltaY;
end;

{ TFakePlayerGame }

function TFakePlayerGame.SpawnSprite(AValue: Integer; AX, AY, AZ, AZAdjust: TGreedFixed; AAngle, AAngle2: Integer;
  AActive: Boolean; ASpawnId: Integer): Integer;
begin
  Calls.AddCall(PLAYER_CALL_SPAWN, [AValue, AX, AY, AZ, AZAdjust, AAngle, AAngle2, Ord(AActive), ASpawnId]);
  Inc(Kinds[PLAYER_CALL_SPAWN]);
  LastSpawn := AValue;
  Inc(Spawns);
  Result := GREED_POOL_NIL;
end;

procedure TFakePlayerGame.DemandLoadMonster(ALump, ACount: Integer);
begin
  raise ENotSupportedException.Create('DemandLoadMonster');
end;

procedure TFakePlayerGame.SoundEffect(ASound, AVariation: Integer; AX, AY: TGreedFixed);
begin
  Calls.AddCall(PLAYER_CALL_SOUND, [ASound, AVariation, AX, AY]);
  Inc(Kinds[PLAYER_CALL_SOUND]);
  LastSound := ASound;
end;

procedure TFakePlayerGame.RunEvent(AEvent: Integer; ANetSend: Boolean);
begin
  Calls.AddCall(PLAYER_CALL_RUN_EVENT, [AEvent, Ord(ANetSend)]);
  Inc(Kinds[PLAYER_CALL_RUN_EVENT]);
  Inc(Events);
end;

function TFakePlayerGame.CheckForSwitch(ATileX, ATileY, AAngle: Integer; ADoubleSwitch: Boolean): Boolean;
begin
  Calls.AddCall(PLAYER_CALL_CHECK_SWITCH, [ATileX, ATileY, AAngle, Ord(ADoubleSwitch)]);
  Inc(Kinds[PLAYER_CALL_CHECK_SWITCH]);
  Result := TPlayerScenarios.SwitchAnswer(ATileX, ATileY, AAngle);
end;

procedure TFakePlayerGame.SwitchWall(ATileX, ATileY, AAngle: Integer; ADoubleSwitch: Boolean);
begin
  Calls.AddCall(PLAYER_CALL_SWITCH_WALL, [ATileX, ATileY, AAngle, Ord(ADoubleSwitch)]);
  Inc(Kinds[PLAYER_CALL_SWITCH_WALL]);
  Inc(SwitchWalls);
end;

procedure TFakePlayerGame.SetLights(ABlackZ: TGreedFixed);
begin
  Calls.AddCall(PLAYER_CALL_SET_LIGHTS, [ABlackZ]);
  Inc(Kinds[PLAYER_CALL_SET_LIGHTS]);
  LastLights := ABlackZ;
end;

procedure TFakePlayerGame.LoadWeapon(AWeapon: Integer);
begin
  Calls.AddCall(PLAYER_CALL_LOAD_WEAPON, [AWeapon]);
  Inc(Kinds[PLAYER_CALL_LOAD_WEAPON]);
  FLoaded := AWeapon;
end;

function TFakePlayerGame.PictureWidth(AMode: Integer): Integer;
begin
  Result := TPlayerScenarios.PictureWidth(FLoaded, AMode);
end;

function TFakePlayerGame.PictureHeight(AMode: Integer): Integer;
begin
  Result := TPlayerScenarios.PictureHeight(FLoaded, AMode);
end;

function TFakePlayerGame.GetNetMode: Boolean;
begin
  Result := False;
end;

procedure TFakePlayerGame.NetOpenDoor(AX, AY: TGreedFixed);
begin
  raise ENotSupportedException.Create('NetOpenDoor');
end;

{ TTestGreedPlayerControl }

procedure TTestGreedPlayerControl.Setup;
begin
  FSprites := TGreedLinkedPool<TGreedSprite>.Create(GREED_MAX_SPRITES, 'sprites');
  FElevators := TGreedLinkedPool<TGreedElevator>.Create(GREED_MAX_ELEVATORS, 'elevators');
  NewGame;
  FlatRoom;
  PlacePlayer(10, 10);
end;

procedure TTestGreedPlayerControl.TearDown;
begin
  FreeGame;
  FreeAndNil(FElevators);
  FreeAndNil(FSprites);
end;

procedure TTestGreedPlayerControl.FreeGame;
begin
  FreeAndNil(FControl);
  FWeapons := nil;
  FWeaponsObject := nil;
  FreeAndNil(FMovement);
  FreeAndNil(FState);
  FKeysRef := nil;
  FKeys := nil;
  FGameRef := nil;
  FGame := nil;
  FWorld := nil;
end;

procedure TTestGreedPlayerControl.NewGame;
begin
  FreeGame;
  FSprites.Clear;
  FElevators.Clear;
  FWorld := TGreedWorld.Create;
  FState := TGreedGameState.Create(FWorld, FSprites, FElevators);
  FState.PlayerNum := 0;
  FState.MapZoom := 8;
  FState.Lighting := 1000;
  FGame := TFakePlayerGame.Create;
  FGameRef := FGame;
  FGame.Calls.Reset;
  FKeys := TFakeControls.Create;
  FKeysRef := FKeys;
  FMovement := TGreedPlayerMovement.Create(FWorld, FGame);
  FWeaponsObject := TGreedPlayerWeapons.Create(FState, FGame, FGame, FGame);
  FWeapons := FWeaponsObject;
  FWeaponsObject.InitProbe;
  FControl := TGreedPlayerControl.Create(FState, FMovement, FKeysRef, FGame, FGame, FWeapons);
  FControl.ScreenSize := 2;
  FControl.VrAngle := 3;
  FLastWeaponX := 0;
  FLastWeaponY := 0;
end;

// a square room of the tiles 4 .. 20 with the floor at 30 and the ceiling at 200, closed by walls
procedure TTestGreedPlayerControl.FlatRoom;
var
  LX, LY, LSpot: Integer;
begin
  for LY := 0 to GREED_MAP_SIZE - 1 do
    for LX := 0 to GREED_MAP_SIZE - 1 do
    begin
      LSpot := LY * GREED_MAP_SIZE + LX;
      FWorld.SetValue(gpFloorHeight, LSpot, 30);
      FWorld.SetValue(gpCeilingHeight, LSpot, 200);
      FWorld.SetValue(gpFloorPic, LSpot, 5);
      FWorld.SetValue(gpCeilingPic, LSpot, 5);
    end;
  for LX := 0 to GREED_MAP_SIZE - 1 do
  begin
    FWorld.SetValue(gpNorthWall, 4 * GREED_MAP_SIZE + LX, 7);
    FWorld.SetValue(gpNorthWall, 21 * GREED_MAP_SIZE + LX, 7);
    FWorld.SetValue(gpWestWall, LX * GREED_MAP_SIZE + 4, 7);
    FWorld.SetValue(gpWestWall, LX * GREED_MAP_SIZE + 21, 7);
  end;
end;

procedure TTestGreedPlayerControl.PlacePlayer(ATileX, ATileY: Integer);
begin
  FState.Player.X := (ATileX * 64 + 32) * GREED_FRACUNIT;
  FState.Player.Y := (ATileY * 64 + 32) * GREED_FRACUNIT;
  FState.Player.Height := 40 * GREED_FRACUNIT;
  FState.Player.Z := TGreedTerrain.FloorZ(FWorld, FState.Player.X, FState.Player.Y) + FState.Player.Height;
  FState.Player.MapSpot := ATileY * GREED_MAP_SIZE + ATileX;
  FState.Player.Angle := 0;
  FState.PlayerAngle64 := 0;
  FState.Player.Angst := 100;
  FState.Player.Weapons[0] := 1;
  FState.Player.Weapons[1] := 2;
  FState.Player.Weapons[2] := -1;
  FState.Player.Weapons[3] := 4;
  FState.Player.Weapons[4] := -1;
  FState.Player.Ammo[0] := 100;
  FState.Player.Ammo[1] := 100;
  FState.Player.Ammo[2] := 100;
  FGame.LoadWeapon(1);
  FGame.Calls.Reset;
end;

procedure TTestGreedPlayerControl.Tic;
begin
  Inc(FState.TimeCount);
  FControl.PlayerCommand;
end;

procedure TTestGreedPlayerControl.Tics(ACount: Integer);
var
  LIndex: Integer;
begin
  for LIndex := 1 to ACount do
    Tic;
end;

procedure TTestGreedPlayerControl.DovrebbeSollevareSenzaUnaDipendenza;
begin
  Assert.WillRaise(
    procedure
    begin
      TGreedPlayerControl.Create(nil, FMovement, FKeysRef, FGame, FGame, FWeapons).Free;
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedPlayerControl.Create(FState, nil, FKeysRef, FGame, FGame, FWeapons).Free;
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedPlayerControl.Create(FState, FMovement, nil, FGame, FGame, FWeapons).Free;
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedPlayerControl.Create(FState, FMovement, FKeysRef, nil, FGame, FWeapons).Free;
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedPlayerControl.Create(FState, FMovement, FKeysRef, FGame, nil, FWeapons).Free;
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedPlayerControl.Create(FState, FMovement, FKeysRef, FGame, FGame, nil).Free;
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedPlayerWeapons.Create(nil, FGame, FGame, FGame).Free;
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedPlayerWeapons.Create(FState, nil, FGame, FGame).Free;
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedPlayerWeapons.Create(FState, FGame, nil, FGame).Free;
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedPlayerWeapons.Create(FState, FGame, FGame, nil).Free;
    end, EArgumentNilException);
end;

procedure TTestGreedPlayerControl.DovrebbeAccelerareFinoAllaVelocitaDiCammino;
var
  LStartX: TGreedFixed;
begin
  LStartX := FState.Player.X;
  FKeys.Press(PK_UP);
  Tic;
  // one unit for each odd tic
  Assert.AreEqual(GREED_FRACUNIT, FState.MoveRate);
  Assert.AreEqual(1, FState.MoveForward);
  Tics(40);
  // (PLAYERMOVESPEED * 7) div 2 = 8.75 units: the rate stops at the last whole unit under it
  Assert.AreEqual(8 * GREED_FRACUNIT, FState.MoveRate);
  // the angle 0 is east
  Assert.IsTrue(FState.Player.X > LStartX + 100 * GREED_FRACUNIT, 'the player goes east');
  Assert.AreEqual(FState.Player.Y, (10 * 64 + 32) * GREED_FRACUNIT);
end;

procedure TTestGreedPlayerControl.DovrebbeAndarePiuForteDiCorsa;
begin
  FKeys.Press(PK_UP);
  FKeys.Press(PK_SHIFT);
  Tics(41);
  // PLAYERMOVESPEED * 6 = 15 units, two units for each odd tic
  Assert.AreEqual(14 * GREED_FRACUNIT, FState.MoveRate);
  // the automatic run turns the command over
  FState.AutoRun := True;
  Tics(40);
  Assert.AreEqual(8 * GREED_FRACUNIT, FState.MoveRate);
end;

procedure TTestGreedPlayerControl.DovrebbeRallentareQuandoIlComandoSiRilascia;
begin
  FKeys.Press(PK_DOWN);
  Tics(41);
  Assert.AreEqual(-8 * GREED_FRACUNIT, FState.MoveRate);
  Assert.AreEqual(-1, FState.MoveForward);
  FKeys.Release(PK_DOWN);
  Tics(4);
  Assert.AreEqual(-6 * GREED_FRACUNIT, FState.MoveRate);
  Tics(40);
  Assert.AreEqual(0, FState.MoveRate);
  Assert.AreEqual(0, FState.MoveForward);
end;

procedure TTestGreedPlayerControl.DovrebbeLeggereIComandiSoloNeiTicDispari;
begin
  FKeys.Press(PK_UP);
  FState.TimeCount := 1;
  // the tic 2
  Tic;
  Assert.AreEqual(0, FState.MoveRate);
  // the tic 3
  Tic;
  Assert.AreEqual(GREED_FRACUNIT, FState.MoveRate);
end;

procedure TTestGreedPlayerControl.DovrebbeGirareConLeFrecce;
begin
  FKeys.Press(PK_LEFT);
  Tic;
  // 512 of the 65536 parts of the turn for each odd tic: 8 angles
  Assert.AreEqual(512, FState.PlayerAngle64);
  Assert.AreEqual(8, FState.Player.Angle);
  FKeys.Release(PK_LEFT);
  FKeys.Press(PK_RIGHT);
  FKeys.Press(PK_SHIFT);
  Tics(2);
  // the run turns twice as fast, and the angle wraps
  Assert.AreEqual(65536 - 512, FState.PlayerAngle64);
  Assert.AreEqual(1016, FState.Player.Angle);
end;

procedure TTestGreedPlayerControl.DovrebbeSaltareSoloDaTerra;
var
  LGround: TGreedFixed;
begin
  LGround := FState.Player.Z;
  FKeys.Press(PK_Z);
  Tic;
  FKeys.Release(PK_Z);
  Assert.IsTrue(FState.Player.Z > LGround, 'the player goes up');
  Assert.AreEqual(GREED_KBDELAY + 1, FState.JumpDelay);
  // in the air the fall rate grows by one unit each odd tic and a second jump is not taken
  Tics(2);
  Assert.AreEqual(-7 * GREED_FRACUNIT, FState.FallRate);
  Tics(80);
  Assert.AreEqual(LGround, FState.Player.Z);
end;

procedure TTestGreedPlayerControl.DovrebbeMuovereLaTestaCamminandoERiportarlaDaFermo;
begin
  FKeys.Press(PK_UP);
  Tics(21);
  Assert.IsTrue(FState.HeadBob > 0, 'the head bobs');
  Assert.IsTrue(FState.WeapBob > 0, 'the weapon bobs');
  FKeys.Release(PK_UP);
  Tics(400);
  Assert.AreEqual(0, FState.MoveRate);
  Assert.AreEqual(0, FState.HeadBob);
  Assert.AreEqual(0, FState.WeapBob);
end;

procedure TTestGreedPlayerControl.DovrebbeSpostareLoSguardoEntroIlLimite;
var
  LIndex: Integer;
begin
  FKeys.Press(PK_PAGE_UP);
  Tic;
  Assert.AreEqual(-GREED_SCROLLRATE1, FState.ScrollView);
  FControl.ChangeScroll;
  Assert.AreEqual(-GREED_SCROLLRATE1, FState.Player.ScrollMin);
  Assert.AreEqual(-GREED_SCROLLRATE1, FState.Player.ScrollMax);
  Assert.AreEqual(0, FState.ScrollView);
  for LIndex := 1 to 100 do
  begin
    Tics(2);
    FControl.ChangeScroll;
  end;
  // the look stops one step before the limit
  Assert.AreEqual(-GREED_MAXSCROLL1 + GREED_SCROLLRATE1, FState.Player.ScrollMin);
  // the centre view command brings it back a step at a time
  FKeys.Release(PK_PAGE_UP);
  FKeys.Press(PK_HOME);
  Tics(2);
  Assert.AreEqual(255, FState.ScrollView);
  FControl.ChangeScroll;
  FKeys.Release(PK_HOME);
  Tics(200);
  Assert.AreEqual(0, FState.Player.ScrollMin);
  Assert.AreEqual(0, FState.ScrollView);
end;

procedure TTestGreedPlayerControl.DovrebbeChiedereIlCambioArmaSoloPerUnoSlotPieno;
begin
  // the slot 2 is empty
  FKeys.Press(PK_1 + 2);
  Tic;
  Assert.IsFalse(FState.ChangingWeapons);
  FKeys.Release(PK_1 + 2);
  // the weapon in the hands is not changed with itself
  FKeys.Press(PK_1);
  Tics(2);
  Assert.IsFalse(FState.ChangingWeapons);
  FKeys.Release(PK_1);
  FKeys.Press(PK_1 + 1);
  Tics(2);
  Assert.IsTrue(FState.ChangingWeapons);
  Assert.IsTrue(FState.WeaponLowering);
  Assert.AreEqual(1, FState.NewWeapon);
  Assert.AreEqual(0, FState.Player.CurrentWeapon);
end;

procedure TTestGreedPlayerControl.DovrebbeAbbassareLArmaEAlzareLaNuova;
var
  LX, LY, LSteps: Integer;
begin
  FWeapons.UpdateWeaponView(True, PLAYER_WINDOW_WIDTH, PLAYER_WINDOW_HEIGHT, LX, LY);
  Assert.AreEqual(PLAYER_WINDOW_HEIGHT - TPlayerScenarios.PictureHeight(1, 0), LY);
  Assert.AreEqual((PLAYER_WINDOW_WIDTH - TPlayerScenarios.PictureWidth(1, 0)) div 2, LX);
  FState.ChangingWeapons := True;
  FState.WeaponLowering := True;
  FState.NewWeapon := 3;
  LSteps := 0;
  while FState.WeaponLowering and (LSteps < 100) do
  begin
    FWeapons.UpdateWeaponView(True, PLAYER_WINDOW_WIDTH, PLAYER_WINDOW_HEIGHT, LX, LY);
    Inc(LSteps);
  end;
  Assert.IsTrue(LSteps < 100, 'the weapon goes out of the view');
  Assert.AreEqual(3, FState.Player.CurrentWeapon);
  Assert.AreEqual(4, FGame.Loaded);
  Assert.AreEqual(PLAYER_WINDOW_HEIGHT - 21, LY);
  Assert.AreEqual(TPlayerScenarios.PictureHeight(4, 0) - 20, FState.WeaponYChange);
  LSteps := 0;
  while FState.ChangingWeapons and (LSteps < 100) do
  begin
    FWeapons.UpdateWeaponView(True, PLAYER_WINDOW_WIDTH, PLAYER_WINDOW_HEIGHT, LX, LY);
    Inc(LSteps);
  end;
  Assert.IsTrue(LSteps < 100, 'the new weapon comes up');
  Assert.AreEqual(PLAYER_WINDOW_HEIGHT - TPlayerScenarios.PictureHeight(4, 0), LY);
  // the same image drawn again does not move the weapon
  FState.ChangingWeapons := True;
  FWeapons.UpdateWeaponView(False, PLAYER_WINDOW_WIDTH, PLAYER_WINDOW_HEIGHT, LX, LY);
  Assert.AreEqual(FWeaponsObject.WeaponY, LY);
end;

procedure TTestGreedPlayerControl.DovrebbeSparareNelFotogrammaDopoIlComando;
begin
  FState.TimeCount := 200;
  FState.Weapons[1].Charge := 100;
  FKeys.Press(PK_CONTROL);
  Tic;
  Assert.IsTrue(FControl.FirePending);
  Assert.AreEqual(0, FGame.Spawns);
  FControl.RunActionHook;
  Assert.IsFalse(FControl.FirePending);
  Assert.AreEqual(1, FGame.Spawns);
  Assert.AreEqual(GREED_S_BULLET1, FGame.LastSpawn);
  Assert.AreEqual(GREED_SN_BULLET1, FGame.LastSound);
  Assert.AreEqual(99, FState.Player.Ammo[1]);
  Assert.AreEqual(0, FState.Weapons[1].Charge);
  Assert.AreEqual(1, FState.WeapMode);
  Assert.AreEqual(2, FState.Player.Status);
  // nothing more without a new command
  FControl.RunActionHook;
  Assert.AreEqual(1, FGame.Spawns);
  // the frames of the weapon go on every 8 tics: 1 -> 2 -> 0 for the weapon 1
  FWeapons.AdvanceWeaponMode;
  Assert.AreEqual(2, FState.WeapMode);
  FWeapons.AdvanceWeaponMode;
  Assert.AreEqual(2, FState.WeapMode);
  FState.TimeCount := FState.TimeCount + 8;
  FWeapons.AdvanceWeaponMode;
  Assert.AreEqual(0, FState.WeapMode);
end;

procedure TTestGreedPlayerControl.DovrebbeNonSparareSenzaMunizioni;
begin
  FState.TimeCount := 200;
  FState.Weapons[1].Charge := 100;
  FState.Player.Ammo[1] := 0;
  FWeapons.FireWeapon;
  Assert.AreEqual(0, FGame.Spawns);
  Assert.AreEqual(100, FState.Weapons[1].Charge);
  Assert.AreEqual(2, FState.Player.Status);
  // an empty slot in the hands does nothing
  FState.Player.CurrentWeapon := 2;
  FWeapons.FireWeapon;
  FKeys.Press(PK_CONTROL);
  Tic;
  Assert.IsFalse(FControl.FirePending);
  Assert.AreEqual(0, FGame.Spawns);
end;

procedure TTestGreedPlayerControl.DovrebbeSparareLaSpreadgunAllaFineDellAnimazione;
begin
  FState.Player.CurrentWeapon := 3;
  FState.TimeCount := 400;
  FState.Weapons[4].Charge := 100;
  FKeys.Press(PK_CONTROL);
  Tic;
  Assert.IsFalse(FControl.FirePending, 'the spread gun does not use the action hook');
  Assert.AreEqual(1, FState.WeapMode);
  FKeys.Release(PK_CONTROL);
  FWeapons.AdvanceWeaponMode;
  Assert.AreEqual(GREED_SN_BULLET4, FGame.LastSound);
  Assert.AreEqual(2, FState.WeapMode);
  Assert.AreEqual(0, FGame.Spawns);
  FState.TimeCount := FState.TimeCount + 8;
  FWeapons.AdvanceWeaponMode;
  Assert.AreEqual(3, FState.WeapMode);
  FState.TimeCount := FState.TimeCount + 8;
  FWeapons.AdvanceWeaponMode;
  Assert.AreEqual(0, FState.WeapMode);
  Assert.AreEqual(5, FGame.Spawns);
  Assert.AreEqual(GREED_S_BULLET4, FGame.LastSpawn);
  Assert.AreEqual(95, FState.Player.Ammo[0]);
  // the green gun shoots 12 times
  FState.Player.Weapons[3] := 18;
  FState.Weapons[18].Charge := 100;
  FWeapons.FireWeapon;
  Assert.AreEqual(17, FGame.Spawns);
  Assert.AreEqual(25, FState.Player.Ammo[2]);
end;

procedure TTestGreedPlayerControl.DovrebbeCaricareLeArmiDiVentiInVenti;
begin
  // the weapon 1 has a charge rate of 4 tics, the weapon 2 of 3, the weapon 4 of 12
  FState.TimeCount := 9;
  FWeapons.ChargeWeapons;
  // the first charge sets the time to now: one step only
  Assert.AreEqual(20, FState.Weapons[1].Charge);
  Assert.AreEqual(13, FState.Weapons[1].ChargeTime);
  Assert.AreEqual(20, FState.Weapons[2].Charge);
  Assert.AreEqual(20, FState.Weapons[4].Charge);
  FState.TimeCount := 17;
  FWeapons.ChargeWeapons;
  Assert.AreEqual(60, FState.Weapons[1].Charge);
  Assert.AreEqual(60, FState.Weapons[2].Charge);
  Assert.AreEqual(20, FState.Weapons[4].Charge);
  FState.TimeCount := 1000;
  FWeapons.ChargeWeapons;
  Assert.AreEqual(100, FState.Weapons[1].Charge);
  Assert.AreEqual(100, FState.Weapons[4].Charge);
  // a weapon that the player does not have is not charged
  Assert.AreEqual(0, FState.Weapons[3].Charge);
end;

procedure TTestGreedPlayerControl.DovrebbeFermareLaSondaSulMuroESegnareLoSpriteColpito;
var
  LAngle: Integer;
begin
  FState.Player.ScrollMin := -12;
  // a solid sprite four tiles east of the player
  FWorld.SetValue(gpMapSprites, 10 * GREED_MAP_SIZE + 14, 30);
  LAngle := FWeapons.GetTargetAngle(0, 0);
  // the original never finds the target: the answer is the look of the player
  Assert.AreEqual(12, LAngle);
  Assert.AreEqual(GREED_SPRITE_PROBE, FState.MSprite);
  Assert.AreEqual(10 * GREED_MAP_SIZE + 10, FState.Probe.StartSpot);
  // the last probe goes 8 angles to the right and stops at the wall of the room (the west wall of the column 21)
  Assert.AreEqual(1016, FState.Probe.Angle);
  Assert.IsTrue(FState.Probe.X < 21 * 64 * GREED_FRACUNIT, 'the probe stays in the room');
  Assert.IsTrue(FState.Probe.X > 20 * 64 * GREED_FRACUNIT, 'the probe reaches the wall');
  Assert.AreEqual(10 * GREED_MAP_SIZE + 14, FState.SpriteLoc);
  Assert.IsFalse(FState.SpriteHit, 'the last step hit the wall');
  Assert.AreEqual(0, FState.Player.Angle);
  // without the automatic target the probe does not move
  FState.AutoTarget := False;
  FState.Probe.X := 5;
  Assert.AreEqual(12, FWeapons.GetTargetAngle(0, 0));
  Assert.AreEqual(5, FState.Probe.X);
end;

procedure TTestGreedPlayerControl.DovrebbeMangiareIlTastoDelMenu;
begin
  FKeys.Press(PK_ESCAPE);
  Tic;
  Assert.IsTrue(FState.ActivateMenu);
  Assert.AreEqual(1 + GREED_ACTIVATEMENUDELAY, FState.KeyboardDelay);
  FState.ActivateMenu := False;
  FState.KeyboardDelay := 0;
  // still down: it was eaten
  Tics(2);
  Assert.IsFalse(FState.ActivateMenu);
  FKeys.Release(PK_ESCAPE);
  FKeys.Press(PK_ESCAPE);
  Tics(2);
  Assert.IsTrue(FState.ActivateMenu);
  // the other keys only wait for the delay
  FState.KeyboardDelay := 0;
  FKeys.Press(PK_M);
  Tics(2);
  Assert.IsTrue(FState.ToggleMapMode);
  FKeys.Release(PK_M);
  FState.KeyboardDelay := 0;
  FKeys.Press(PK_F9);
  Tics(2);
  Assert.IsTrue(FControl.ResizeScreen);
  Assert.IsTrue(FControl.BiggerScreen);
  Assert.AreEqual(3, FControl.ScreenSize);
end;

procedure TTestGreedPlayerControl.DovrebbeFarAffondareIlMortoEChiedereDiRicominciare;
var
  LFloor: TGreedFixed;
begin
  LFloor := TGreedTerrain.FloorZ(FWorld, FState.Player.X, FState.Player.Y);
  FState.Player.Angst := 0;
  FKeys.Press(PK_UP);
  Tics(100);
  Assert.AreEqual(0, FState.MoveRate, 'a dead player does not walk');
  Assert.AreEqual(LFloor + 12 * GREED_FRACUNIT, FState.Player.Z);
  Assert.IsFalse(FState.DeadRestart);
  FKeys.Press(PK_SPACE);
  Tics(2);
  Assert.IsTrue(FState.DeadRestart);
  Assert.IsFalse(FState.CheckTrigger);
end;

procedure TTestGreedPlayerControl.DovrebbeTenereLeLuciEntroILimiti;
begin
  FState.ChangeLight := 500;
  FControl.NewLights;
  Assert.AreEqual(1500, FState.Lighting);
  Assert.AreEqual(0, FState.ChangeLight);
  Assert.AreEqual(1500 * GREED_FRACUNIT, FGame.LastLights);
  FState.ChangeLight := 5000;
  FControl.NewLights;
  Assert.AreEqual(4096, FState.Lighting);
  FState.ChangeLight := -9000;
  FControl.NewLights;
  Assert.AreEqual(1, FState.Lighting);
  Assert.AreEqual(GREED_FRACUNIT, FGame.LastLights);
end;

procedure TTestGreedPlayerControl.DovrebbeAzionareGliAscensoriDiScambio;
var
  LHigh, LLow, LMiddle: Integer;
begin
  LHigh := FElevators.Add;
  FElevators.Item(LHigh)^.Kind := getSwap;
  FElevators.Item(LHigh)^.Floor := 10;
  FElevators.Item(LHigh)^.Ceiling := 80;
  FElevators.Item(LHigh)^.Position := 80;
  LMiddle := FElevators.Add;
  FElevators.Item(LMiddle)^.Kind := getSwap;
  FElevators.Item(LMiddle)^.Floor := 10;
  FElevators.Item(LMiddle)^.Ceiling := 80;
  FElevators.Item(LMiddle)^.Position := 40;
  LLow := FElevators.Add;
  FElevators.Item(LLow)^.Kind := getSwap;
  FElevators.Item(LLow)^.Floor := 10;
  FElevators.Item(LLow)^.Ceiling := 80;
  FElevators.Item(LLow)^.Position := 10;
  FWorld.SetValue(gpMapSprites, FState.Player.MapSpot, GREED_SM_SWAPSWITCH);
  FState.TimeCount := 50;
  FControl.CheckHere(False, FState.Player.X, FState.Player.Y, 0);
  Assert.IsTrue(FElevators.Item(LHigh)^.Down);
  Assert.AreEqual(50, FElevators.Item(LHigh)^.Timer);
  Assert.IsFalse(FElevators.Item(LMiddle)^.Down or FElevators.Item(LMiddle)^.Up, 'an elevator on its way is left');
  Assert.IsTrue(FElevators.Item(LLow)^.Up);
  // the wall is switched once for each elevator from the first that swapped on
  Assert.AreEqual(3, FGame.SwitchWalls);
  Assert.AreEqual(50 + 3 * 70, FState.SwitchTime);
end;

procedure TTestGreedPlayerControl.DovrebbeEseguireLEventoDellInterruttoreSoloSeDiFronte;
begin
  // switches[x][y]
  FState.Switches[10 * GREED_MAP_SIZE + 10] := 33;
  // SwitchAnswer(10, 10, 2) is false: the player does not face the switch
  FControl.CheckHere(True, FState.Player.X, FState.Player.Y, 2);
  Assert.AreEqual(0, FGame.Events);
  Assert.AreEqual(0, FGame.SwitchWalls);
  FControl.CheckHere(True, FState.Player.X, FState.Player.Y, 0);
  Assert.AreEqual(1, FGame.Events);
  Assert.AreEqual(1, FGame.SwitchWalls);
  // when the game itself calls, the switch is not looked for
  FControl.CheckHere(False, FState.Player.X, FState.Player.Y, 2);
  Assert.AreEqual(2, FGame.Events);
  // the use command raises the flag that PlayLoop serves with CheckHere
  FKeys.Press(PK_SPACE);
  Tic;
  Assert.IsTrue(FState.CheckTrigger);
  Assert.AreEqual(1 + 2 * GREED_KBDELAY, FState.KeyboardDelay);
end;

procedure TTestGreedPlayerControl.DovrebbeRicordareICaratteriDeiCodiciSegreti;
var
  LIndex: Integer;
begin
  FKeys.Press(PK_Q);
  Tic;
  FKeys.Press(PK_1);
  Tics(2);
  // a key without a letter or a digit is not kept
  FKeys.Press(PK_COMMA);
  Tics(2);
  Assert.AreEqual('Q1', FState.SecretBuf);
  Assert.AreEqual(5 + 5 * GREED_KBDELAY, FState.SecretDelay);
  for LIndex := 1 to 30 do
  begin
    FKeys.Release(PK_M);
    Tics(2);
    FKeys.Press(PK_M);
    Tics(2);
  end;
  Assert.AreEqual(GREED_SECRET_BUFFER_SIZE - 1, Length(FState.SecretBuf));
  Assert.AreEqual(StringOfChar('M', GREED_SECRET_BUFFER_SIZE - 1), FState.SecretBuf);
end;

procedure TTestGreedPlayerControl.DovrebbeUsareIlMouseSoloSeAbilitato;
begin
  FKeys.MoveMouse(40, 0, 4);
  Tic;
  Assert.AreEqual(0, FControl.MouseDX);
  Assert.AreEqual(0, FState.MoveRate);
  FControl.MouseEnabled := True;
  Tics(2);
  // 40 * 65536 * 5 div 10 * 11 div 5, then halved for the next tic
  Assert.AreEqual((((40 * GREED_FRACUNIT * 5) div 10) * 11 div 5) div 2, FControl.MouseDX);
  Assert.IsTrue(FControl.MouseButton[gmbNorth]);
  // the middle button walks, the movement to the left turns left
  Assert.AreEqual(GREED_FRACUNIT, FState.MoveRate);
  Assert.AreEqual((((40 * GREED_FRACUNIT * 5) div 10) * 11 div 5) div 16384, FState.PlayerAngle64);
  FControl.InvertMouseTurn := True;
  FState.PlayerAngle64 := 0;
  FKeys.MoveMouse(0, 0, 0);
  Tics(2);
  Assert.IsTrue(FState.PlayerAngle64 > 32768, 'inverted, what is left of the movement turns right');
end;

procedure TTestGreedPlayerControl.PrepareScenario(const AScenario: TPlayerScenario; const AMap: TPlayerMap);
var
  LSpot, LIndex, LNumber: Integer;
  LDoor: TGreedDoor;
  LElevator: TGreedLinkedPool<TGreedElevator>.PItem;
begin
  NewGame;
  for LSpot := 0 to PLAYER_TILES - 1 do
  begin
    FWorld.SetValue(gpNorthWall, LSpot, AMap.NorthWall[LSpot]);
    FWorld.SetValue(gpNorthFlags, LSpot, AMap.NorthFlags[LSpot]);
    FWorld.SetValue(gpWestWall, LSpot, AMap.WestWall[LSpot]);
    FWorld.SetValue(gpWestFlags, LSpot, AMap.WestFlags[LSpot]);
    FWorld.SetValue(gpFloorPic, LSpot, AMap.FloorPic[LSpot]);
    FWorld.SetValue(gpFloorFlags, LSpot, AMap.FloorFlags[LSpot]);
    FWorld.SetValue(gpCeilingPic, LSpot, AMap.CeilingPic[LSpot]);
    FWorld.SetValue(gpFloorHeight, LSpot, AMap.FloorHeight[LSpot]);
    FWorld.SetValue(gpCeilingHeight, LSpot, AMap.CeilingHeight[LSpot]);
    FWorld.SetMapFlags(LSpot, AMap.MapFlags[LSpot]);
    FWorld.SetValue(gpMapSprites, LSpot, AMap.MapSprites[LSpot]);
    FState.Switches[LSpot] := AMap.Switches[LSpot];
  end;
  for LIndex := 0 to PLAYER_DOOR_COUNT - 1 do
  begin
    LNumber := FWorld.AddDoor(AMap.Doors[LIndex].TileX, AMap.Doors[LIndex].TileY);
    LDoor := FWorld.GetDoor(LNumber);
    LDoor.Orientation := TGreedDoorOrientation(AMap.Doors[LIndex].Orientation);
    LDoor.Open := AMap.Doors[LIndex].Open;
    LDoor.Bumpable := AMap.Doors[LIndex].Bumpable;
    FWorld.SetDoor(LNumber, LDoor);
  end;
  for LIndex := 0 to PLAYER_ELEVATOR_COUNT - 1 do
  begin
    LElevator := FElevators.Item(FElevators.Add);
    LElevator^.MapSpot := AMap.Elevators[LIndex].MapSpot;
    LElevator^.Kind := TGreedElevatorType(AMap.Elevators[LIndex].Kind);
    LElevator^.Floor := AMap.Elevators[LIndex].Floor;
    LElevator^.Ceiling := AMap.Elevators[LIndex].Ceiling;
    LElevator^.Position := AMap.Elevators[LIndex].Position;
  end;
  FControl.InvertMouseTurn := AScenario.InvertTurn;
  FControl.InvertMouseLook := AScenario.InvertLook;
  FControl.MouseEnabled := AScenario.MouseEnabled;
  FControl.MouseSensitivity := AScenario.MouseSensitivity;
  FState.Player := Default(TGreedPlayerRecord);
  FState.Player.X := (AMap.StartTileX * 64 + 32) * GREED_FRACUNIT;
  FState.Player.Y := (AMap.StartTileY * 64 + 32) * GREED_FRACUNIT;
  FState.Player.Height := AScenario.Height;
  FState.Player.Z := TGreedTerrain.FloorZ(FWorld, FState.Player.X, FState.Player.Y) + FState.Player.Height;
  FState.Player.MapSpot := AMap.StartTileY * GREED_MAP_SIZE + AMap.StartTileX;
  FState.Player.Angle := AScenario.Angle;
  FState.PlayerAngle64 := AScenario.Angle * 64;
  FState.Player.Angst := 100;
  FState.Player.CharType := AScenario.CharType;
  for LIndex := 0 to 4 do
    FState.Player.Weapons[LIndex] := AScenario.Weapons[LIndex];
  for LIndex := 0 to 2 do
    FState.Player.Ammo[LIndex] := AScenario.Ammo[LIndex];
  FState.Player.WalkMod := AScenario.WalkMod;
  FState.Player.RunMod := AScenario.RunMod;
  FState.Player.JumpMod := AScenario.JumpMod;
  FGame.LoadWeapon(FState.Player.Weapons[FState.Player.CurrentWeapon]);
  FGame.Calls.Reset;
end;

// the steps of PlayLoop, TimeUpdate and UpdateView that belong to the player, as the harness of the original
procedure TTestGreedPlayerControl.Frame;
begin
  if FState.ToggleAutoRun then
  begin
    FState.AutoRun := not FState.AutoRun;
    FState.ToggleAutoRun := False;
  end;
  if FState.ToggleAutoTarget then
  begin
    FState.AutoTarget := not FState.AutoTarget;
    FState.ToggleAutoTarget := False;
  end;
  FState.GoIRight := False;
  FState.GoILeft := False;
  FState.UseItem := False;
  if FState.CheckTrigger then
  begin
    FState.CheckTrigger := False;
    FControl.CheckHere(True, FState.Player.X, FState.Player.Y, FState.Player.Angle);
  end;
  FState.FallDamage := 0;
  FWeapons.ChargeWeapons;
  if FMovement.DoorSound then
  begin
    FMovement.DoorSound := False;
    FGame.SoundEffect(GREED_SN_DOOR, 15, FMovement.DoorX, FMovement.DoorY);
  end;
  FState.DeadRestart := False;
  FControl.ResizeScreen := False;
  if FState.ScrollView <> 0 then
    FControl.ChangeScroll;
  FState.ToggleHeatMode := False;
  FState.ToggleMotionMode := False;
  FState.ToggleMapMode := False;
  FState.ToggleGoalItem := False;
  FState.ToggleRearView := False;
  FControl.RunActionHook;
  FWeapons.UpdateWeaponView(True, PLAYER_WINDOW_WIDTH, PLAYER_WINDOW_HEIGHT, FLastWeaponX, FLastWeaponY);
  FState.NewSong := False;
  FState.ActivateMenu := False;
  FState.ActivateHelp := False;
  FState.ActivateBrief := False;
  FState.QuickExit := False;
  FState.Paused := False;
  if FState.ChangeLight <> 0 then
    FControl.NewLights;
  FWeapons.AdvanceWeaponMode;
end;

procedure TTestGreedPlayerControl.Collect(out AValues: TPlayerValues);
var
  LHash: TPlayerHash;
  LIndex: Integer;
  LDoor: TGreedDoor;
  LElevator: TGreedLinkedPool<TGreedElevator>.PItem;
begin
  LHash.Reset;
  LHash.AddBytes(FState.Player, SizeOf(FState.Player));
  AValues[0] := Integer(LHash.Value);
  AValues[1] := FState.PlayerAngle64;
  AValues[2] := FState.MoveRate;
  AValues[3] := FState.StrafRate;
  AValues[4] := FState.FallRate;
  AValues[5] := FState.TurnRate;
  AValues[6] := FState.ScrollView;
  AValues[7] := FState.HeadBob;
  AValues[8] := FState.WeapBob;
  AValues[9] := FState.WeapMode;
  AValues[10] := FState.WeaponYChange;
  AValues[11] := FState.NewWeapon;
  AValues[12] := Ord(FState.ChangingWeapons);
  AValues[13] := Ord(FState.WeaponLowering);
  AValues[14] := FState.WeapDelay;
  AValues[15] := FState.MoveForward;
  AValues[16] := FState.FallDamage;
  AValues[17] := FState.KeyboardDelay;
  AValues[18] := FState.SecretDelay;
  AValues[19] := FState.InventoryDelay;
  AValues[20] := FState.UseDelay;
  AValues[21] := FState.JumpDelay;
  AValues[22] := FState.InventoryTime;
  AValues[23] := Ord(FState.ActivateMenu);
  AValues[24] := Ord(FState.ActivateHelp);
  AValues[25] := Ord(FState.QuickExit);
  AValues[26] := Ord(FState.ActivateBrief);
  AValues[27] := Ord(FState.Paused);
  AValues[28] := Ord(FControl.ResizeScreen);
  AValues[29] := Ord(FControl.BiggerScreen);
  AValues[30] := Ord(FState.ToggleMapMode);
  AValues[31] := Ord(FState.ToggleHeatMode);
  AValues[32] := Ord(FState.ToggleMotionMode);
  AValues[33] := Ord(FState.ToggleRearView);
  AValues[34] := Ord(FState.ToggleGoalItem);
  AValues[35] := Ord(FState.ToggleAutoRun);
  AValues[36] := Ord(FState.ToggleAutoTarget);
  AValues[37] := Ord(FState.NewSong);
  AValues[38] := Ord(FState.GoIRight);
  AValues[39] := Ord(FState.GoILeft);
  AValues[40] := Ord(FState.DeadRestart);
  AValues[41] := Ord(FState.UseItem);
  AValues[42] := Ord(FState.CheckTrigger);
  AValues[43] := Ord(FState.AutoRun);
  AValues[44] := Ord(FState.AutoTarget);
  AValues[45] := FState.MapZoom;
  AValues[46] := FControl.ScreenSize;
  AValues[47] := FControl.AdjustVrAngle;
  AValues[48] := Trunc(FControl.AdjustVrDistance);
  AValues[49] := FControl.MouseDX;
  AValues[50] := FControl.MouseDY;
  AValues[51] := Ord(FControl.MouseButton[gmbFire]) + 2 * Ord(FControl.MouseButton[gmbUse]) +
    4 * Ord(FControl.MouseButton[gmbNorth]);
  LHash.Reset;
  LHash.Add(Length(FState.SecretBuf));
  for LIndex := 1 to Length(FState.SecretBuf) do
    LHash.Add(Ord(FState.SecretBuf[LIndex]));
  AValues[52] := Integer(LHash.Value);
  AValues[53] := FState.Lighting;
  AValues[54] := FState.ChangeLight;
  AValues[55] := FState.SwitchTime;
  LHash.Reset;
  for LIndex := 0 to 18 do
    LHash.Add(FState.Weapons[LIndex].Charge);
  AValues[56] := Integer(LHash.Value);
  LHash.Reset;
  for LIndex := 0 to 18 do
    LHash.Add(FState.Weapons[LIndex].ChargeTime);
  AValues[57] := Integer(LHash.Value);
  AValues[58] := FState.Probe.X;
  AValues[59] := FState.Probe.Y;
  AValues[60] := FState.Probe.Z;
  AValues[61] := FState.Probe.Angle;
  AValues[62] := FState.Probe.Angle2;
  AValues[63] := FState.Probe.ZAdjust;
  AValues[64] := FState.Probe.StartSpot;
  AValues[65] := Ord(FState.SpriteHit);
  AValues[66] := Ord(FState.PlayerHit);
  AValues[67] := FState.SpriteLoc;
  AValues[68] := FState.HitX;
  AValues[69] := FState.HitY;
  AValues[70] := Ord(FMovement.DoorSound);
  AValues[71] := FMovement.DoorX;
  AValues[72] := FMovement.DoorY;
  LHash.Reset;
  for LIndex := 0 to FWorld.DoorCount - 1 do
  begin
    LDoor := FWorld.GetDoor(LIndex);
    LHash.Add(Ord(LDoor.Open));
    LHash.Add(Ord(LDoor.Opening));
    LHash.Add(Ord(LDoor.Closing));
    LHash.Add(LDoor.Timer);
  end;
  AValues[73] := Integer(LHash.Value);
  LHash.Reset;
  LIndex := FElevators.First;
  while LIndex <> GREED_POOL_NIL do
  begin
    LElevator := FElevators.Item(LIndex);
    LHash.Add(Ord(LElevator^.Up));
    LHash.Add(Ord(LElevator^.Down));
    LHash.Add(LElevator^.Timer);
    LHash.Add(LElevator^.Position);
    LIndex := FElevators.Next(LIndex);
  end;
  AValues[74] := Integer(LHash.Value);
  AValues[75] := FWeaponsObject.WeaponBobView;
  AValues[76] := FWeaponsObject.WeaponX;
  AValues[77] := FWeaponsObject.WeaponY;
  AValues[78] := FLastWeaponX;
  AValues[79] := FLastWeaponY;
  AValues[80] := Ord(FControl.FirePending);
  AValues[81] := FGame.Calls.Count;
  AValues[82] := Integer(FGame.Calls.Value);
  AValues[83] := FControl.NetMsgStatus;
  AValues[84] := FState.TimeCount;
  AValues[85] := FState.Player.X;
  AValues[86] := FState.Player.Y;
  AValues[87] := FState.Player.Z;
  AValues[88] := FState.Player.Angle;
  AValues[89] := FState.Player.MapSpot;
  AValues[90] := FState.Player.CurrentWeapon;
  AValues[91] := FState.Player.Ammo[0];
  AValues[92] := FState.Player.Ammo[1];
  AValues[93] := FState.Player.Ammo[2];
  AValues[94] := FState.Player.ScrollMin;
  AValues[95] := FState.Player.ScrollMax;
  AValues[96] := FState.Player.Status;
  AValues[97] := FState.Player.Angst;
  AValues[98] := FState.Warping;
end;

function TTestGreedPlayerControl.RunScenario(const AScenario: TPlayerScenario; const AMap: TPlayerMap;
  ADump: TStrings): string;
var
  LInput: TPlayerInput;
  LTic: TPlayerTic;
  LValues: TPlayerValues;
  LRoll: TPlayerHash;
  LCheckpoints: TArray<Cardinal>;
  LTime, LIndex: Integer;
begin
  PrepareScenario(AScenario, AMap);
  LInput.Start(AScenario);
  LRoll.Reset;
  LCheckpoints := nil;
  for LTime := 1 to AScenario.Tics do
  begin
    Inc(FState.TimeCount);
    LInput.Next(LTime, LTic);
    if LTic.Angst >= 0 then
      FState.Player.Angst := LTic.Angst;
    if LTic.Warping >= 0 then
      FState.Warping := LTic.Warping;
    if LTic.ChangeLight <> 0 then
      FState.ChangeLight := LTic.ChangeLight;
    if FState.TimeCount and 1 <> 0 then
      FKeys.Read(LTic);
    FControl.PlayerCommand;
    Collect(LValues);
    for LIndex := 0 to High(LValues) do
      LRoll.Add(LValues[LIndex]);
    if Assigned(ADump) then
      ADump.Add(TPlayerScenarios.Describe(LTime, LValues));
    if LTime mod AScenario.FrameEvery = 0 then
      Frame;
    Collect(LValues);
    for LIndex := 0 to High(LValues) do
      LRoll.Add(LValues[LIndex]);
    if Assigned(ADump) then
      ADump.Add(TPlayerScenarios.Describe(-LTime, LValues));
    if (LTime mod PLAYER_CHECKPOINT = 0) or (LTime = AScenario.Tics) then
    begin
      SetLength(LCheckpoints, Length(LCheckpoints) + 1);
      LCheckpoints[High(LCheckpoints)] := LRoll.Value;
    end;
  end;
  Result := TPlayerScenarios.GoldenLine(AScenario, FGame.Calls.Count, LCheckpoints);
end;

procedure TTestGreedPlayerControl.DovrebbeDareGliStessiTicDelCodiceOriginale;
var
  LGolden, LDump: TStringList;
  LMaps: array[1..PLAYER_MAP_COUNT] of TPlayerMap;
  LScenario: TPlayerScenario;
  LIndex, LDifferences, LDumpScenario, LTics, LPart: Integer;
  LFirst, LExpected, LActual, LDumpName: string;
  LExpectedParts, LActualParts: TArray<string>;
  LKinds: array[1..7] of Integer;
begin
  for LIndex := Low(LMaps) to High(LMaps) do
    TPlayerScenarios.BuildMap(LIndex, LMaps[LIndex]);
  for LPart := Low(LKinds) to High(LKinds) do
    LKinds[LPart] := 0;
  LDumpName := GetEnvironmentVariable(DUMP_VARIABLE);
  LDumpScenario := StrToIntDef(GetEnvironmentVariable(DUMP_SCENARIO_VARIABLE), 0);
  LDifferences := 0;
  LTics := 0;
  LFirst := '';
  LGolden := TStringList.Create;
  LDump := TStringList.Create;
  try
    LGolden.LoadFromFile(TGreedRealData.GoldenPath(GOLDEN_NAME));
    Assert.AreEqual(PLAYER_SCENARIO_COUNT + 1, LGolden.Count, 'the golden file is of another list of scenarios');
    for LIndex := 0 to PLAYER_SCENARIO_COUNT - 1 do
    begin
      LScenario := TPlayerScenarios.Scenario(LIndex);
      Inc(LTics, LScenario.Tics);
      if (LDumpName <> '') and (LIndex = LDumpScenario) then
        LActual := RunScenario(LScenario, LMaps[LScenario.MapSeed], LDump)
      else
        LActual := RunScenario(LScenario, LMaps[LScenario.MapSeed], nil);
      for LPart := Low(LKinds) to High(LKinds) do
        Inc(LKinds[LPart], FGame.Kinds[LPart]);
      LExpected := LGolden[LIndex + 1];
      if LExpected <> LActual then
      begin
        Inc(LDifferences);
        if LFirst = '' then
        begin
          // the first checkpoint that differs says in which tics to look
          LExpectedParts := LExpected.Split([' ']);
          LActualParts := LActual.Split([' ']);
          LPart := 0;
          while (LPart < Length(LExpectedParts)) and (LPart < Length(LActualParts)) and
            (LExpectedParts[LPart] = LActualParts[LPart]) do
            Inc(LPart);
          LFirst := Format('scenario %d differs from the field %d of its line (the tics up to %d)', [LIndex, LPart,
            (LPart - 2) * PLAYER_CHECKPOINT]);
        end;
      end;
    end;
    if LDumpName <> '' then
    begin
      // the first line of the dump says how much the scenarios did
      LDump.Insert(0, Format('%d scenarios, %d tics; sounds %d, shots %d, switches looked for %d, walls switched %d, ' +
        'events %d, lights %d, weapons loaded %d', [PLAYER_SCENARIO_COUNT, LTics, LKinds[PLAYER_CALL_SOUND],
        LKinds[PLAYER_CALL_SPAWN], LKinds[PLAYER_CALL_CHECK_SWITCH], LKinds[PLAYER_CALL_SWITCH_WALL],
        LKinds[PLAYER_CALL_RUN_EVENT], LKinds[PLAYER_CALL_SET_LIGHTS], LKinds[PLAYER_CALL_LOAD_WEAPON]]));
      LDump.SaveToFile(LDumpName);
    end;
  finally
    LDump.Free;
    LGolden.Free;
  end;
  Assert.AreEqual(0, LDifferences, Format('%d scenarios of %d differ; the first: %s', [LDifferences,
    PLAYER_SCENARIO_COUNT, LFirst]));
  Assert.AreEqual(45000, LTics);
  // the scenarios must reach every part: shots, sounds, switches, events, lights, changes of weapon
  for LPart := Low(LKinds) to High(LKinds) do
    Assert.IsTrue(LKinds[LPart] >= 20, Format('the call %d is made %d times only', [LPart, LKinds[LPart]]));
end;

end.

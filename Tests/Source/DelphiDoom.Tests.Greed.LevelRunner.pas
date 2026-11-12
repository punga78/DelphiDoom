{******************************************************************************}
{                                                                              }
{  DelphiDoom: the scenarios of the level of Greed run on the library           }
{                                                                              }
{  The side of the library of the parity with raven.pas: the world, the pools,  }
{  TGreedItemRules, TGreedSwitchRules, TGreedLevelRules (with the elevators,    }
{  the doors and TryDoor that are already in the library) and the stand-ins     }
{  of the rest of the game, which write what they are asked in the trace        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.LevelRunner;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DelphiDoom.Greed.Types,
  DelphiDoom.Greed.SaveTypes, DelphiDoom.Greed.Actor.Types, DelphiDoom.Greed.World.Intf,
  DelphiDoom.Greed.LinkedPool, DelphiDoom.Greed.Random, DelphiDoom.Greed.Game.Intf, DelphiDoom.Greed.Game.State,
  DelphiDoom.Greed.Level.Intf, DelphiDoom.Greed.Elevator.Intf, DelphiDoom.Greed.Door.Intf,
  DelphiDoom.Greed.ElevatorRules, DelphiDoom.Greed.DoorRules, DelphiDoom.Greed.PlayerMovement,
  DelphiDoom.Greed.ItemRules, DelphiDoom.Greed.SwitchRules, DelphiDoom.Greed.LevelRules,
  DelphiDoom.Tests.Greed.LevelScenarios;

const
  /// <summary>How many calls and messages the stand-in of the game keeps as text</summary>
  CALL_LIMIT = 10000;

type
  /// <summary>
  ///   The rest of the game for the rules of the level: every call is written in the trace (and, if Calls is
  ///   asked, in a list of names for the tests); a spawned sprite is the one of TLevelStandIns.Spawned, the health
  ///   and the score change as TLevelStandIns says, the elevators, the doors and TryDoor are the ones of the
  ///   library
  /// </summary>
  TFakeLevelGame = class(TInterfacedObject, IGreedSpawner, IGreedGameSound, IGreedEventRunner, IGreedMessages,
    IGreedPlayerHealth, IGreedSystemClock, IGreedItemHost, IGreedSwitchHost, IGreedTicParts, IGreedLevelHost,
    IGreedElevatorHost, IGreedDoorHost, IGreedMovementHost)
  strict private
    FState: TGreedGameState;
    FTrace: TLevelTrace;
    FCalls: TStringList;
    FMessages: TStringList;
    FClock: Cardinal;
    FAmbientLight: Integer;
    FOldInventory, FOldShots, FOldGoalItem, FTotalEffectTime, FWeaponPictureHeight: Integer;
    FElevators: TGreedElevatorRules;
    FMovement: TGreedPlayerMovement;
    FLastSpawn: Integer;
    procedure Note(const AName: string; const AArguments: array of Integer);
  public
    constructor Create(AState: TGreedGameState; ATrace: TLevelTrace);
    destructor Destroy; override;
    // IGreedSpawner
    function SpawnSprite(AValue: Integer; AX, AY, AZ, AZAdjust: TGreedFixed; AAngle, AAngle2: Integer;
      AActive: Boolean; ASpawnId: Integer): Integer;
    procedure DemandLoadMonster(ALump, ACount: Integer);
    // IGreedGameSound
    procedure SoundEffect(ASound, AVariation: Integer; AX, AY: TGreedFixed);
    // IGreedEventRunner and IGreedElevatorHost
    procedure RunEvent(AEvent: Integer; ANetSend: Boolean); overload;
    procedure RunEvent(AEvent: Integer); overload;
    // IGreedMessages
    procedure WriteMessage(const AText: string);
    // IGreedPlayerHealth
    procedure Hurt(AAmount: Integer);
    procedure Heal(AAmount: Integer);
    procedure MedPaks(AAmount: Integer);
    procedure AddScore(AAmount: Integer);
    // IGreedSystemClock
    function Clock: Cardinal;
    // IGreedItemHost and IGreedLevelHost
    procedure RefreshInventory;
    procedure RefreshAmmo;
    procedure LoadWeapon(AWeapon: Integer);
    function GetWeaponPictureHeight: Integer;
    procedure ResetMouse;
    // IGreedSwitchHost
    function TryDoor(ACenterX, ACenterY: TGreedFixed): Boolean;
    // IGreedTicParts
    procedure UpdateInput;
    procedure UpdateSound;
    procedure RunProcesses;
    procedure ClearTileLights;
    procedure MoveSprites;
    procedure CheckElevators;
    // IGreedLevelHost
    procedure RefreshGoalItem;
    procedure SetTotalEffectTime(ATics: Integer);
    procedure LoadColorMaps(const ALumpName: string);
    function GetAmbientLight: Integer;
    procedure FadeOutLevel;
    procedure ResetDisplay;
    procedure NewMap(AMap, AActivate: Integer);
    // IGreedElevatorHost and IGreedDoorHost
    function GetTimeCount: Integer;
    procedure PlaySound(ASound, AVariation: Integer; AX, AY: TGreedFixed);
    procedure PlayDoorSound(AX, AY: TGreedFixed);
    // IGreedMovementHost
    function GetNetMode: Boolean;
    procedure NetOpenDoor(AX, AY: TGreedFixed);
    /// <summary>How many calls with that name are in Calls</summary>
    function CountOf(const AName: string): Integer;
    /// <summary>True if that call, written as its name and its arguments with spaces between, is in Calls</summary>
    function Has(const ACall: string): Boolean;
    /// <summary>The first calls that were made (at most CALL_LIMIT), in order: the name and the arguments</summary>
    property Calls: TStringList read FCalls;
    property Messages: TStringList read FMessages;
    property ClockValue: Cardinal read FClock write FClock;
    property AmbientLight: Integer read FAmbientLight write FAmbientLight;
    property OldInventory: Integer read FOldInventory write FOldInventory;
    property OldShots: Integer read FOldShots write FOldShots;
    property OldGoalItem: Integer read FOldGoalItem write FOldGoalItem;
    property TotalEffectTime: Integer read FTotalEffectTime write FTotalEffectTime;
    property WeaponPictureHeight: Integer read FWeaponPictureHeight write FWeaponPictureHeight;
    property LastSpawn: Integer read FLastSpawn;
    property Elevators: TGreedElevatorRules read FElevators write FElevators;
    property Movement: TGreedPlayerMovement read FMovement write FMovement;
  end;

  /// <summary>A level in memory with the rules and their stand-ins, for the tests and for the scenarios</summary>
  TLibraryLevelRunner = class(TLevelScenarioRunner)
  strict private
    FWorld: IGreedWorld;
    FSprites: TGreedLinkedPool<TGreedSprite>;
    FElevators: TGreedLinkedPool<TGreedElevator>;
    FState: TGreedGameState;
    FRandom: TGreedRandomTable;
    FRandomIntf: IGreedRandom;
    FGame: TFakeLevelGame;
    FGameIntf: IInterface;
    FElevatorRules: TGreedElevatorRules;
    FDoorRules: TGreedDoorRules;
    FMovement: TGreedPlayerMovement;
    FItems: TGreedItemRules;
    FSwitches: TGreedSwitchRules;
    FLevel: TGreedLevelRules;
    procedure Release;
  protected
    procedure LoadScenario(const AScenario: TLevelScenario); override;
    procedure GetGlobals(out AGlobals: TLevelGlobals); override;
    procedure SetGlobals(const AGlobals: TLevelGlobals); override;
    procedure GetPlayer(out APlayer: TGreedPlayerRecord); override;
    procedure SetPlayer(const APlayer: TGreedPlayerRecord); override;
    procedure SetClock(AValue: Cardinal); override;
    procedure GetBonus(out ABonus: TLevelBonus); override;
    procedure GetWeaponCharges(out ACharges: TLevelWeaponCharges); override;
    function GetWarpActive: Integer; override;
    function GetRandomOffset: Integer; override;
    procedure ListSprites(AList: TList<TGreedSprite>); override;
    procedure ListElevators(AList: TList<TGreedElevator>); override;
    function DoorCount: Integer; override;
    function DoorAt(AIndex: Integer): TGreedDoor; override;
    function AreaCount: Integer; override;
    function AreaAt(AIndex: Integer): TGreedSpawnArea; override;
    procedure CopyPlane(APlane: TGreedPlane; out ATiles: TLevelTiles); override;
    procedure CopyTriggers(out ATiles: TLevelTiles); override;
    procedure CopySwitches(out ATiles: TLevelTiles); override;
    procedure SetSpriteHitPoints(AOrdinal, AValue: Integer); override;
    procedure CheckWarps(AX, AY: Integer); override;
    procedure CheckItems(ATileX, ATileY: Integer; AUseIt: Boolean; ACharType: Integer); override;
    procedure CheckHere(AUseIt: Boolean; AX, AY, AAngle: Integer); override;
    procedure CheckDoors(AX, AY: Integer); override;
    procedure TimeUpdate; override;
    procedure WarpAnim; override;
    procedure JamWarps; override;
    procedure PrepareNexus; override;
    procedure EndLevel; override;
    procedure StartOver(ARestartValue: Integer); override;
    procedure NewGoalItem; override;
  public
    destructor Destroy; override;
    /// <summary>
    ///   An empty level: floor everywhere, no sprites, the player on the tile (10, 10) with full health, the
    ///   time at 1000 and the bonus item far in the future
    /// </summary>
    procedure LoadEmpty;
    /// <summary>A sprite of that kind at the centre of the tile, at the end of the list; the index in the pool</summary>
    function AddSprite(AKind, ATileX, ATileY: Integer): Integer;
    /// <summary>The value of the plane of the sprites on the tile and its sprite</summary>
    function PutItem(AMapValue, ASpriteKind, ATileX, ATileY: Integer): Integer;
    function AddElevator(AKind: TGreedElevatorType; ATileX, ATileY, AFloor, ACeiling, APosition: Integer): Integer;
    /// <summary>The player on the centre of the tile</summary>
    procedure PlacePlayer(ATileX, ATileY: Integer);
    function MapSprite(ATileX, ATileY: Integer): Integer;
    property World: IGreedWorld read FWorld;
    property Sprites: TGreedLinkedPool<TGreedSprite> read FSprites;
    property State: TGreedGameState read FState;
    property Random: TGreedRandomTable read FRandom;
    property Game: TFakeLevelGame read FGame;
    property Items: TGreedItemRules read FItems;
    property Switches: TGreedSwitchRules read FSwitches;
    property Level: TGreedLevelRules read FLevel;
  end;

implementation

uses
  DelphiDoom.Greed.World, DelphiDoom.Greed.Game.Constants;

{ TFakeLevelGame }

constructor TFakeLevelGame.Create(AState: TGreedGameState; ATrace: TLevelTrace);
begin
  inherited Create;
  FState := AState;
  FTrace := ATrace;
  FCalls := TStringList.Create;
  FMessages := TStringList.Create;
  FLastSpawn := GREED_POOL_NIL;
end;

destructor TFakeLevelGame.Destroy;
begin
  FMessages.Free;
  FCalls.Free;
  inherited Destroy;
end;

procedure TFakeLevelGame.Note(const AName: string; const AArguments: array of Integer);
var
  LText: string;
  LIndex: Integer;
begin
  FTrace.Call(AName, AArguments);
  // the list is only for the short tests: the scenarios make millions of calls
  if FCalls.Count < CALL_LIMIT then
  begin
    LText := AName;
    for LIndex := 0 to High(AArguments) do
      LText := LText + ' ' + IntToStr(AArguments[LIndex]);
    FCalls.Add(LText);
  end;
end;

function TFakeLevelGame.CountOf(const AName: string): Integer;
var
  LIndex: Integer;
begin
  Result := 0;
  for LIndex := 0 to FCalls.Count - 1 do
    if (FCalls[LIndex] = AName) or FCalls[LIndex].StartsWith(AName + ' ') then
      Inc(Result);
end;

function TFakeLevelGame.Has(const ACall: string): Boolean;
begin
  Result := FCalls.IndexOf(ACall) >= 0;
end;

function TFakeLevelGame.SpawnSprite(AValue: Integer; AX, AY, AZ, AZAdjust: TGreedFixed; AAngle, AAngle2: Integer;
  AActive: Boolean; ASpawnId: Integer): Integer;
var
  LMapSpot, LMapValue: Integer;
begin
  Note('SpawnSprite', [AValue, AX, AY, AZ, AZAdjust, AAngle, AAngle2, Ord(AActive), ASpawnId]);
  Result := FState.Sprites.Add;
  TLevelStandIns.Spawned(FState.Sprites.Item(Result)^, LMapSpot, LMapValue, AValue, AX, AY, AZ, AZAdjust, AAngle,
    AAngle2, AActive, ASpawnId);
  if LMapValue <> 0 then
    FState.World.SetValue(gpMapSprites, LMapSpot, Byte(LMapValue));
  FLastSpawn := Result;
end;

procedure TFakeLevelGame.DemandLoadMonster(ALump, ACount: Integer);
begin
  // the rules of the level do not ask for pictures
end;

procedure TFakeLevelGame.SoundEffect(ASound, AVariation: Integer; AX, AY: TGreedFixed);
begin
  Note('SoundEffect', [ASound, AVariation, AX, AY]);
end;

procedure TFakeLevelGame.RunEvent(AEvent: Integer; ANetSend: Boolean);
begin
  Note('RunEvent', [AEvent, Ord(ANetSend)]);
  TLevelStandIns.RunEvent(@FState.Triggers[0], @FState.Switches[0], AEvent);
end;

procedure TFakeLevelGame.RunEvent(AEvent: Integer);
begin
  RunEvent(AEvent, False);
end;

procedure TFakeLevelGame.WriteMessage(const AText: string);
begin
  Note('writemsg', []);
  FTrace.AddText(AText, 'text');
  if FMessages.Count < CALL_LIMIT then
    FMessages.Add(AText);
end;

procedure TFakeLevelGame.Hurt(AAmount: Integer);
begin
  Note('hurt', [AAmount]);
end;

procedure TFakeLevelGame.Heal(AAmount: Integer);
begin
  Note('heal', [AAmount]);
  TLevelStandIns.Heal(FState.Player, AAmount);
end;

procedure TFakeLevelGame.MedPaks(AAmount: Integer);
begin
  Note('medpaks', [AAmount]);
  TLevelStandIns.MedPaks(FState.Player, AAmount);
end;

procedure TFakeLevelGame.AddScore(AAmount: Integer);
begin
  Note('addscore', [AAmount]);
  TLevelStandIns.AddScore(FState.Player, AAmount);
end;

function TFakeLevelGame.Clock: Cardinal;
begin
  Result := FClock;
end;

procedure TFakeLevelGame.RefreshInventory;
begin
  FOldInventory := -2;
  Note('inventoryleft', []);
  Note('inventoryright', []);
end;

procedure TFakeLevelGame.RefreshAmmo;
begin
  FOldShots := -1;
end;

procedure TFakeLevelGame.LoadWeapon(AWeapon: Integer);
begin
  Note('loadweapon', [AWeapon]);
  FWeaponPictureHeight := TLevelStandIns.WeaponPictureHeight(AWeapon);
end;

function TFakeLevelGame.GetWeaponPictureHeight: Integer;
begin
  Result := FWeaponPictureHeight;
end;

procedure TFakeLevelGame.ResetMouse;
begin
  Note('ResetMouse', []);
end;

function TFakeLevelGame.TryDoor(ACenterX, ACenterY: TGreedFixed): Boolean;
begin
  Result := FMovement.TryDoor(ACenterX, ACenterY);
  // doorsound, doorx and doory are globals of the game in the original
  if FMovement.DoorSound then
  begin
    FState.DoorSound := True;
    FState.DoorX := FMovement.DoorX;
    FState.DoorY := FMovement.DoorY;
    FMovement.DoorSound := False;
  end;
end;

procedure TFakeLevelGame.UpdateInput;
begin
  Note('UpdateMouse', []);
end;

procedure TFakeLevelGame.UpdateSound;
begin
  Note('UpdateSound', []);
end;

procedure TFakeLevelGame.RunProcesses;
begin
  Note('Process', []);
end;

procedure TFakeLevelGame.ClearTileLights;
begin
  if FCalls.Count < CALL_LIMIT then
    FCalls.Add('ClearTileLights');
end;

procedure TFakeLevelGame.MoveSprites;
begin
  Note('MoveSprites', []);
end;

procedure TFakeLevelGame.CheckElevators;
begin
  if FCalls.Count < CALL_LIMIT then
    FCalls.Add('CheckElevators');
  if Assigned(FElevators) then
    FElevators.Check(FState.Player, FState.FallRate);
end;

procedure TFakeLevelGame.RefreshGoalItem;
begin
  FOldGoalItem := -1;
end;

procedure TFakeLevelGame.SetTotalEffectTime(ATics: Integer);
begin
  FTotalEffectTime := ATics;
end;

procedure TFakeLevelGame.LoadColorMaps(const ALumpName: string);
begin
  FTrace.AddText(ALumpName, 'CA_GetNamedNum');
  Note('CA_ReadLump', []);
end;

function TFakeLevelGame.GetAmbientLight: Integer;
begin
  Result := FAmbientLight;
end;

procedure TFakeLevelGame.FadeOutLevel;
begin
  Note('VI_FadeOut', [0, 256, 0, 0, 0, 64]);
  Note('R_ClearRenderBuffer', []);
  FTrace.AddText('palette', 'CA_GetNamedNum');
  Note('I_SetPalette', []);
end;

procedure TFakeLevelGame.ResetDisplay;
begin
  Note('resetdisplay', []);
end;

procedure TFakeLevelGame.NewMap(AMap, AActivate: Integer);
begin
  Note('newmap', [AMap, AActivate]);
  Note('INT_TimerHook', []);
end;

function TFakeLevelGame.GetTimeCount: Integer;
begin
  Result := FState.TimeCount;
end;

procedure TFakeLevelGame.PlaySound(ASound, AVariation: Integer; AX, AY: TGreedFixed);
begin
  SoundEffect(ASound, AVariation, AX, AY);
end;

procedure TFakeLevelGame.PlayDoorSound(AX, AY: TGreedFixed);
begin
  SoundEffect(GREED_SN_DOOR, 15, AX, AY);
end;

function TFakeLevelGame.GetNetMode: Boolean;
begin
  Result := False;
end;

procedure TFakeLevelGame.NetOpenDoor(AX, AY: TGreedFixed);
begin
  raise Exception.Create('NetOpenDoor');
end;

{ TLibraryLevelRunner }

destructor TLibraryLevelRunner.Destroy;
begin
  Release;
  inherited Destroy;
end;

procedure TLibraryLevelRunner.Release;
begin
  FreeAndNil(FLevel);
  FreeAndNil(FSwitches);
  FreeAndNil(FItems);
  FreeAndNil(FMovement);
  FreeAndNil(FDoorRules);
  FreeAndNil(FElevatorRules);
  FGame := nil;
  FGameIntf := nil;
  FRandom := nil;
  FRandomIntf := nil;
  FreeAndNil(FState);
  FreeAndNil(FSprites);
  FreeAndNil(FElevators);
  FWorld := nil;
end;

procedure TLibraryLevelRunner.LoadScenario(const AScenario: TLevelScenario);
var
  LPlane: TGreedPlane;
  LSpot, LIndex, LItem: Integer;
begin
  Release;
  FWorld := TGreedWorld.Create;
  for LPlane := Low(TGreedPlane) to High(TGreedPlane) do
    for LSpot := 0 to GREED_MAP_TILES - 1 do
      if AScenario.Planes[LPlane][LSpot] <> 0 then
        FWorld.SetValue(LPlane, LSpot, AScenario.Planes[LPlane][LSpot]);
  for LSpot := 0 to GREED_MAP_TILES - 1 do
    if AScenario.MapFlags[LSpot] <> 0 then
      FWorld.SetMapFlags(LSpot, AScenario.MapFlags[LSpot]);
  for LIndex := 0 to High(AScenario.Doors) do
    FWorld.SetDoor(FWorld.AddDoor(AScenario.Doors[LIndex].TileX, AScenario.Doors[LIndex].TileY),
      AScenario.Doors[LIndex]);
  // AddDoor marks the tile; the flags of the scenario are the ones that count
  for LSpot := 0 to GREED_MAP_TILES - 1 do
    FWorld.SetMapFlags(LSpot, AScenario.MapFlags[LSpot]);
  for LIndex := 0 to High(AScenario.Areas) do
    FWorld.SetSpawnArea(FWorld.AddSpawnArea, AScenario.Areas[LIndex]);
  FSprites := TGreedLinkedPool<TGreedSprite>.Create(GREED_MAX_SPRITES, 'sprites');
  FElevators := TGreedLinkedPool<TGreedElevator>.Create(GREED_MAX_ELEVATORS, 'elevators');
  FState := TGreedGameState.Create(FWorld, FSprites, FElevators);
  for LIndex := 0 to High(AScenario.Sprites) do
  begin
    LItem := FSprites.Add;
    FSprites.Item(LItem)^ := AScenario.Sprites[LIndex];
  end;
  for LIndex := 0 to High(AScenario.Elevators) do
  begin
    LItem := FElevators.Add;
    FElevators.Item(LItem)^ := AScenario.Elevators[LIndex];
  end;
  Move(AScenario.Triggers[0], FState.Triggers[0], GREED_MAP_TILES);
  Move(AScenario.Switches[0], FState.Switches[0], GREED_MAP_TILES);
  FState.Player := AScenario.Player;
  for LIndex := 0 to 3 do
    FState.Primaries[LIndex] := AScenario.Primaries[LIndex];
  for LIndex := 0 to 13 do
    FState.Secondaries[LIndex] := AScenario.Secondaries[LIndex];
  for LIndex := 0 to 1 do
    FState.PCount[LIndex] := AScenario.PCount[LIndex];
  for LIndex := 0 to 6 do
    FState.SCount[LIndex] := AScenario.SCount[LIndex];
  FState.BonusTime := AScenario.BonusTime;
  FState.LevelScore := AScenario.LevelScore;
  FState.BonusItem.Time := AScenario.BonusFirstTime;
  FState.Demo := AScenario.Demo;
  FState.TimeCount := AScenario.TimeCount;
  FState.SpriteMoveTime := AScenario.TimeCount;
  FState.NumProcesses := AScenario.NumProcesses;
  FState.Lighting := AScenario.AmbientLight;
  FRandom := TGreedRandomTable.Create;
  FRandomIntf := FRandom;
  FRandom.Offset := AScenario.RandomOffset;
  FGame := TFakeLevelGame.Create(FState, Trace);
  FGameIntf := FGame as IGreedSpawner;
  FGame.AmbientLight := AScenario.AmbientLight;
  FGame.ClockValue := AScenario.ClockBase;
  FElevatorRules := TGreedElevatorRules.Create(FWorld, FElevators, FGame);
  FDoorRules := TGreedDoorRules.Create(FWorld, FGame);
  FMovement := TGreedPlayerMovement.Create(FWorld, FGame);
  FGame.Elevators := FElevatorRules;
  FGame.Movement := FMovement;
  FItems := TGreedItemRules.Create(FState, FGame, FGame, FGame, FGame, FGame, FRandomIntf, FGame, FGame);
  FSwitches := TGreedSwitchRules.Create(FState, FGame, FGame, FGame);
  FLevel := TGreedLevelRules.Create(FState, FGame, FGame, FGame, FRandomIntf, FGame, FGame, FGame);
end;

procedure TLibraryLevelRunner.LoadEmpty;
var
  LScenario: TLevelScenario;
  LPlane: TGreedPlane;
  LSpot: Integer;
begin
  LScenario := Default(TLevelScenario);
  for LPlane := Low(TGreedPlane) to High(TGreedPlane) do
    SetLength(LScenario.Planes[LPlane], GREED_MAP_TILES);
  SetLength(LScenario.MapFlags, GREED_MAP_TILES);
  SetLength(LScenario.Triggers, GREED_MAP_TILES);
  SetLength(LScenario.Switches, GREED_MAP_TILES);
  for LSpot := 0 to GREED_MAP_TILES - 1 do
  begin
    LScenario.Planes[gpFloorPic][LSpot] := 1;
    LScenario.Planes[gpCeilingHeight][LSpot] := 200;
  end;
  LScenario.Player.X := 10 * GREED_FRACTILEUNIT + 32 * GREED_FRACUNIT;
  LScenario.Player.Y := 10 * GREED_FRACTILEUNIT + 32 * GREED_FRACUNIT;
  LScenario.Player.Height := 48 * GREED_FRACUNIT;
  LScenario.Player.Z := LScenario.Player.Height;
  LScenario.Player.MapSpot := 10 * GREED_MAP_SIZE + 10;
  LScenario.Player.MaxAngst := 500;
  LScenario.Player.MaxShield := 500;
  LScenario.Player.Angst := 500;
  LScenario.Player.Shield := 500;
  LScenario.Player.Weapons[2] := -1;
  LScenario.Player.Weapons[3] := -1;
  LScenario.Player.Weapons[4] := -1;
  LScenario.Player.Weapons[1] := 1;
  LScenario.TimeCount := 1000;
  LScenario.BonusFirstTime := MaxInt;
  LScenario.AmbientLight := 2048;
  LoadScenario(LScenario);
end;

function TLibraryLevelRunner.AddSprite(AKind, ATileX, ATileY: Integer): Integer;
var
  LSprite: PGreedSprite;
begin
  Result := FSprites.Add;
  LSprite := PGreedSprite(FSprites.Item(Result));
  LSprite^.Kind := AKind;
  LSprite^.X := ATileX * GREED_FRACTILEUNIT + 32 * GREED_FRACUNIT;
  LSprite^.Y := ATileY * GREED_FRACTILEUNIT + 32 * GREED_FRACUNIT;
end;

function TLibraryLevelRunner.PutItem(AMapValue, ASpriteKind, ATileX, ATileY: Integer): Integer;
begin
  FWorld.SetValue(gpMapSprites, ATileY * GREED_MAP_SIZE + ATileX, Byte(AMapValue));
  Result := AddSprite(ASpriteKind, ATileX, ATileY);
end;

function TLibraryLevelRunner.AddElevator(AKind: TGreedElevatorType; ATileX, ATileY, AFloor, ACeiling,
  APosition: Integer): Integer;
var
  LElevator: TGreedLinkedPool<TGreedElevator>.PItem;
begin
  Result := FElevators.Add;
  LElevator := FElevators.Item(Result);
  LElevator^.Kind := AKind;
  LElevator^.MapSpot := ATileY * GREED_MAP_SIZE + ATileX;
  LElevator^.Floor := AFloor;
  LElevator^.Ceiling := ACeiling;
  LElevator^.Position := APosition;
  LElevator^.Position64 := APosition * GREED_FRACUNIT;
  LElevator^.Speed := 4;
  LElevator^.Timer := $70000000;
end;

procedure TLibraryLevelRunner.PlacePlayer(ATileX, ATileY: Integer);
begin
  FState.Player.X := ATileX * GREED_FRACTILEUNIT + 32 * GREED_FRACUNIT;
  FState.Player.Y := ATileY * GREED_FRACTILEUNIT + 32 * GREED_FRACUNIT;
  FState.Player.MapSpot := ATileY * GREED_MAP_SIZE + ATileX;
end;

function TLibraryLevelRunner.MapSprite(ATileX, ATileY: Integer): Integer;
begin
  Result := FWorld.GetValue(gpMapSprites, ATileY * GREED_MAP_SIZE + ATileX);
end;

procedure TLibraryLevelRunner.GetGlobals(out AGlobals: TLevelGlobals);
begin
  AGlobals.TimeCount := FState.TimeCount;
  AGlobals.SpriteMoveTime := FState.SpriteMoveTime;
  AGlobals.SwitchTime := FState.SwitchTime;
  AGlobals.SpecialEffect := FState.SpecialEffect;
  AGlobals.SpecialEffectTime := FState.SpecialEffectTime;
  AGlobals.Warping := FState.Warping;
  AGlobals.WarpX := FState.WarpX;
  AGlobals.WarpY := FState.WarpY;
  AGlobals.WarpActive := FItems.WarpActive;
  AGlobals.WarpJammer := FState.WarpJammer;
  AGlobals.ExitLevel := FState.ExitLevel;
  AGlobals.ExitExists := FState.ExitExists;
  AGlobals.HurtBorder := FState.HurtBorder;
  AGlobals.ChangingWeapons := FState.ChangingWeapons;
  AGlobals.WeaponLowering := FState.WeaponLowering;
  AGlobals.NewWeapon := FState.NewWeapon;
  AGlobals.WeaponYChange := FState.WeaponYChange;
  AGlobals.TurnRate := FState.TurnRate;
  AGlobals.MoveRate := FState.MoveRate;
  AGlobals.StrafRate := FState.StrafRate;
  AGlobals.FallRate := FState.FallRate;
  AGlobals.DoorSound := FState.DoorSound;
  AGlobals.DoorX := FState.DoorX;
  AGlobals.DoorY := FState.DoorY;
  AGlobals.GoalItem := FState.GoalItem;
  AGlobals.ToggleGoalItem := FState.ToggleGoalItem;
  AGlobals.Lighting := FState.Lighting;
  AGlobals.ChangeLight := FState.ChangeLight;
  AGlobals.DeadRestart := FState.DeadRestart;
  AGlobals.NumProcesses := FState.NumProcesses;
  AGlobals.OldInventory := FGame.OldInventory;
  AGlobals.OldShots := FGame.OldShots;
  AGlobals.OldGoalItem := FGame.OldGoalItem;
  AGlobals.TotalEffectTime := FGame.TotalEffectTime;
end;

procedure TLibraryLevelRunner.SetGlobals(const AGlobals: TLevelGlobals);
begin
  FState.TimeCount := AGlobals.TimeCount;
  FState.SpriteMoveTime := AGlobals.SpriteMoveTime;
  FState.SwitchTime := AGlobals.SwitchTime;
  FState.SpecialEffect := AGlobals.SpecialEffect;
  FState.SpecialEffectTime := AGlobals.SpecialEffectTime;
  FState.Warping := AGlobals.Warping;
  FState.WarpX := AGlobals.WarpX;
  FState.WarpY := AGlobals.WarpY;
  FItems.WarpActive := Byte(AGlobals.WarpActive);
  FState.WarpJammer := AGlobals.WarpJammer;
  FState.ExitLevel := AGlobals.ExitLevel;
  FState.ExitExists := AGlobals.ExitExists;
  FState.HurtBorder := AGlobals.HurtBorder;
  FState.ChangingWeapons := AGlobals.ChangingWeapons;
  FState.WeaponLowering := AGlobals.WeaponLowering;
  FState.NewWeapon := AGlobals.NewWeapon;
  FState.WeaponYChange := AGlobals.WeaponYChange;
  FState.TurnRate := AGlobals.TurnRate;
  FState.MoveRate := AGlobals.MoveRate;
  FState.StrafRate := AGlobals.StrafRate;
  FState.FallRate := AGlobals.FallRate;
  FState.DoorSound := AGlobals.DoorSound;
  FState.DoorX := AGlobals.DoorX;
  FState.DoorY := AGlobals.DoorY;
  FState.GoalItem := AGlobals.GoalItem;
  FState.ToggleGoalItem := AGlobals.ToggleGoalItem;
  FState.Lighting := AGlobals.Lighting;
  FState.ChangeLight := AGlobals.ChangeLight;
  FState.DeadRestart := AGlobals.DeadRestart;
  FState.NumProcesses := AGlobals.NumProcesses;
  FGame.OldInventory := AGlobals.OldInventory;
  FGame.OldShots := AGlobals.OldShots;
  FGame.OldGoalItem := AGlobals.OldGoalItem;
  FGame.TotalEffectTime := AGlobals.TotalEffectTime;
end;

procedure TLibraryLevelRunner.GetPlayer(out APlayer: TGreedPlayerRecord);
begin
  APlayer := FState.Player;
end;

procedure TLibraryLevelRunner.SetPlayer(const APlayer: TGreedPlayerRecord);
begin
  FState.Player := APlayer;
end;

procedure TLibraryLevelRunner.SetClock(AValue: Cardinal);
begin
  FGame.ClockValue := AValue;
end;

procedure TLibraryLevelRunner.GetBonus(out ABonus: TLevelBonus);
var
  LIndex, LOrdinal: Integer;
begin
  ABonus.Time := FState.BonusItem.Time;
  ABonus.Score := FState.BonusItem.Score;
  ABonus.TileX := FState.BonusItem.TileX;
  ABonus.TileY := FState.BonusItem.TileY;
  ABonus.MapSpot := FState.BonusItem.MapSpot;
  ABonus.Num := FState.BonusItem.Num;
  ABonus.Name := FState.BonusItem.Name;
  ABonus.SpriteOrdinal := -1;
  LOrdinal := 0;
  LIndex := FSprites.First;
  while LIndex <> GREED_POOL_NIL do
  begin
    if LIndex = FState.BonusItem.Sprite then
    begin
      ABonus.SpriteOrdinal := LOrdinal;
      Break;
    end;
    Inc(LOrdinal);
    LIndex := FSprites.Next(LIndex);
  end;
end;

procedure TLibraryLevelRunner.GetWeaponCharges(out ACharges: TLevelWeaponCharges);
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(ACharges) do
  begin
    ACharges[LIndex].Charge := FState.Weapons[LIndex].Charge;
    ACharges[LIndex].ChargeTime := FState.Weapons[LIndex].ChargeTime;
  end;
end;

function TLibraryLevelRunner.GetWarpActive: Integer;
begin
  Result := FItems.WarpActive;
end;

function TLibraryLevelRunner.GetRandomOffset: Integer;
begin
  Result := FRandom.Offset;
end;

procedure TLibraryLevelRunner.ListSprites(AList: TList<TGreedSprite>);
var
  LIndex: Integer;
begin
  LIndex := FSprites.First;
  while LIndex <> GREED_POOL_NIL do
  begin
    AList.Add(FSprites.Item(LIndex)^);
    LIndex := FSprites.Next(LIndex);
  end;
end;

procedure TLibraryLevelRunner.ListElevators(AList: TList<TGreedElevator>);
var
  LIndex: Integer;
begin
  LIndex := FElevators.First;
  while LIndex <> GREED_POOL_NIL do
  begin
    AList.Add(FElevators.Item(LIndex)^);
    LIndex := FElevators.Next(LIndex);
  end;
end;

function TLibraryLevelRunner.DoorCount: Integer;
begin
  Result := FWorld.DoorCount;
end;

function TLibraryLevelRunner.DoorAt(AIndex: Integer): TGreedDoor;
begin
  Result := FWorld.GetDoor(AIndex);
end;

function TLibraryLevelRunner.AreaCount: Integer;
begin
  Result := FWorld.SpawnAreaCount;
end;

function TLibraryLevelRunner.AreaAt(AIndex: Integer): TGreedSpawnArea;
begin
  Result := FWorld.GetSpawnArea(AIndex);
end;

procedure TLibraryLevelRunner.CopyPlane(APlane: TGreedPlane; out ATiles: TLevelTiles);
begin
  FWorld.CopyPlane(APlane, @ATiles[0]);
end;

procedure TLibraryLevelRunner.CopyTriggers(out ATiles: TLevelTiles);
begin
  Move(FState.Triggers[0], ATiles[0], GREED_MAP_TILES);
end;

procedure TLibraryLevelRunner.CopySwitches(out ATiles: TLevelTiles);
begin
  Move(FState.Switches[0], ATiles[0], GREED_MAP_TILES);
end;

procedure TLibraryLevelRunner.SetSpriteHitPoints(AOrdinal, AValue: Integer);
var
  LIndex: Integer;
begin
  LIndex := FSprites.First;
  while (LIndex <> GREED_POOL_NIL) and (AOrdinal > 0) do
  begin
    Dec(AOrdinal);
    LIndex := FSprites.Next(LIndex);
  end;
  if LIndex <> GREED_POOL_NIL then
    PGreedSprite(FSprites.Item(LIndex))^.HitPoints := AValue;
end;

procedure TLibraryLevelRunner.CheckWarps(AX, AY: Integer);
begin
  FItems.CheckWarps(AX, AY);
end;

procedure TLibraryLevelRunner.CheckItems(ATileX, ATileY: Integer; AUseIt: Boolean; ACharType: Integer);
begin
  FItems.CheckItems(ATileX, ATileY, AUseIt, ACharType);
end;

procedure TLibraryLevelRunner.CheckHere(AUseIt: Boolean; AX, AY, AAngle: Integer);
begin
  FSwitches.CheckHere(AUseIt, AX, AY, AAngle);
end;

procedure TLibraryLevelRunner.CheckDoors(AX, AY: Integer);
begin
  FDoorRules.Check(AX, AY);
end;

procedure TLibraryLevelRunner.TimeUpdate;
begin
  FLevel.TimeUpdate;
end;

procedure TLibraryLevelRunner.WarpAnim;
begin
  FLevel.WarpAnim;
end;

procedure TLibraryLevelRunner.JamWarps;
begin
  FLevel.JamWarps;
end;

procedure TLibraryLevelRunner.PrepareNexus;
begin
  FLevel.PrepareNexus;
end;

procedure TLibraryLevelRunner.EndLevel;
begin
  FLevel.EndLevel;
end;

procedure TLibraryLevelRunner.StartOver(ARestartValue: Integer);
begin
  FLevel.StartOver(ARestartValue);
end;

procedure TLibraryLevelRunner.NewGoalItem;
begin
  FLevel.NewGoalItem;
end;

end.

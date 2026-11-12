{******************************************************************************}
{                                                                              }
{  DelphiDoom: scenarios of the parity of the rules of the level of Greed       }
{                                                                              }
{  The same synthetic levels (items of every kind, switches, triggers, warps,   }
{  spawn areas, goals, doors, elevators) and the same frames run on the         }
{  routines cut from the original raven.pas (harness Tools\Verifica\175-level)  }
{  and on TGreedItemRules, TGreedSwitchRules and TGreedLevelRules: this unit    }
{  is the part that the two sides share (generator, driver of the frames, the   }
{  behaviour of the stand-ins of the rest of the game, the trace)               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.LevelScenarios;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DelphiDoom.Greed.Types,
  DelphiDoom.Greed.SaveTypes, DelphiDoom.Greed.Actor.Types, DelphiDoom.Greed.World.Intf;

const
  /// <summary>How many scenarios the golden file has</summary>
  LEVEL_SCENARIO_COUNT = 32;
  /// <summary>The weapons of the table of the game</summary>
  LEVEL_WEAPON_COUNT = 19;

type
  /// <summary>A place where the driver puts the player, and where it looks</summary>
  TLevelWaypoint = record
    TileX, TileY, Angle: Integer;
  end;

  /// <summary>bonus_t without the pointer: the sprite is its place in the list (-1: not in the list)</summary>
  TLevelBonus = record
    Time, Score, TileX, TileY, MapSpot, Num: Integer;
    Name: string;
    SpriteOrdinal: Integer;
  end;

  /// <summary>The globals that the rules of the level read and write (and the ones of display.pas)</summary>
  TLevelGlobals = record
    TimeCount, SpriteMoveTime, SwitchTime, SpecialEffect, SpecialEffectTime: Integer;
    Warping, WarpX, WarpY, WarpActive: Integer;
    WarpJammer, ExitLevel, ExitExists, HurtBorder, ChangingWeapons, WeaponLowering: Boolean;
    NewWeapon, WeaponYChange, TurnRate, MoveRate, StrafRate, FallRate: Integer;
    DoorSound: Boolean;
    DoorX, DoorY: Integer;
    GoalItem: Integer;
    ToggleGoalItem: Boolean;
    Lighting, ChangeLight: Integer;
    DeadRestart: Boolean;
    NumProcesses: Integer;
    OldInventory, OldShots, OldGoalItem, TotalEffectTime: Integer;
    // ---- the ones of the secret codes ----
    GodMode, MidgetMode, Game1, Game2, Game3: Boolean;
    EnemyViewMode, WeapMode, GameEpisode: Integer;
    SecretBuf: string;
  end;

  TLevelWeaponCharge = record
    Charge, ChargeTime: Integer;
  end;

  TLevelWeaponCharges = array[0..LEVEL_WEAPON_COUNT - 1] of TLevelWeaponCharge;
  TLevelTiles = array[0..GREED_MAP_TILES - 1] of Byte;

  /// <summary>A level, what is in it, the player, the state of the game and how many frames to run</summary>
  TLevelScenario = record
    Index: Integer;
    Planes: array[TGreedPlane] of TBytes;
    MapFlags: TBytes;
    Doors: TArray<TGreedDoor>;
    Sprites: TArray<TGreedSprite>;
    Elevators: TArray<TGreedElevator>;
    Areas: TArray<TGreedSpawnArea>;
    /// <summary>triggers[x][y] and switches[x][y] as they lie in memory: the index is x * 64 + y</summary>
    Triggers: TBytes;
    Switches: TBytes;
    Player: TGreedPlayerRecord;
    Primaries: array[0..3] of Integer;
    Secondaries: array[0..13] of Integer;
    PCount: array[0..1] of Integer;
    SCount: array[0..6] of Integer;
    BonusTime, LevelScore: Integer;
    BonusFirstTime: Integer;
    Demo: Boolean;
    /// <summary>1 .. 3: which of GAME1, GAME2 and GAME3 is set</summary>
    Episode: Integer;
    AmbientLight: Integer;
    TimeCount, TimeStep: Integer;
    NumProcesses: Integer;
    RandomOffset: Integer;
    ClockBase, ClockStep: Cardinal;
    Waypoints: TArray<TLevelWaypoint>;
    Dwell: Integer;
    Tics: Integer;
    Seed: Cardinal;
  end;

  /// <summary>
  ///   Everything that a frame changes or asks, as a sequence of integers: its FNV-1a is the line of the golden
  ///   file; with Labels the values are also written as text, to find the first one that differs
  /// </summary>
  TLevelTrace = class
  strict private
    FHash: Cardinal;
    FLabels: TStrings;
    FCounts: TDictionary<string, Integer>;
    procedure Count(const AKey: string);
  public
    procedure Reset(ALabels: TStrings);
    procedure Add(AValue: Integer; const ALabel: string); overload;
    procedure Add(AValue: Boolean; const ALabel: string); overload;
    /// <summary>A call that goes out of the rules: its name and its arguments</summary>
    procedure Call(const AName: string; const AArguments: array of Integer);
    procedure AddText(const AText, ALabel: string);
    /// <summary>ACount bytes of an array (as text only the ones that are not zero)</summary>
    procedure AddBytes(AFirst: PByte; ACount: Integer; const ALabel: string);
    procedure AddSprite(const ASprite: TGreedSprite; AIndex: Integer);
    procedure AddElevator(const AElevator: TGreedElevator; AIndex: Integer);
    procedure AddDoor(const ADoor: TGreedDoor; AIndex: Integer);
    procedure AddArea(const AArea: TGreedSpawnArea; AIndex: Integer);
    property Hash: Cardinal read FHash;
    /// <summary>
    ///   If one is given (not owned), every call and every text is counted in it, to see what the scenarios
    ///   reach: the key is the name of the call with its first argument, or the text
    /// </summary>
    property Counts: TDictionary<string, Integer> read FCounts write FCounts;
  end;

  /// <summary>What the stand-ins of the rest of the game do, the same on the two sides</summary>
  TLevelStandIns = class
  public
    /// <summary>
    ///   SpawnSprite: the sprite that is made depends only on the arguments. AMapValue is what the tile AMapSpot
    ///   of the plane of the sprites becomes (0: the tile is not touched)
    /// </summary>
    class procedure Spawned(out ASprite: TGreedSprite; out AMapSpot, AMapValue: Integer; AValue, AX, AY, AZ,
      AZAdjust, AAngle, AAngle2: Integer; AActive: Boolean; ASpawnId: Integer); static;
    class procedure Heal(var APlayer: TGreedPlayerRecord; AAmount: Integer); static;
    class procedure MedPaks(var APlayer: TGreedPlayerRecord; AAmount: Integer); static;
    class procedure AddScore(var APlayer: TGreedPlayerRecord; AAmount: Integer); static;
    /// <summary>RunEvent: an odd event takes away the triggers and the switches that run it</summary>
    class procedure RunEvent(ATriggers, ASwitches: PByte; AEvent: Integer); static;
    /// <summary>weaponpic[0].height after loadweapon(n)</summary>
    class function WeaponPictureHeight(AWeapon: Integer): Integer; static;
    /// <summary>
    ///   KillSprite: the sprite has no hit points any more; True, it is taken out of the list (the odd kinds),
    ///   False, it stays as a corpse
    /// </summary>
    class function Kill(var ASprite: TGreedSprite; AWeapon: Integer): Boolean; static;
  end;

  /// <summary>
  ///   The frames of a scenario. A side (the original, the library) says how its world is loaded, read and
  ///   changed and runs its routines; the driver of the frames and the trace of the state are here
  /// </summary>
  TLevelScenarioRunner = class
  strict private
    FTrace: TLevelTrace;
    FSprites: TList<TGreedSprite>;
    FElevators: TList<TGreedElevator>;
    procedure TraceState;
    procedure Mutate(const AScenario: TLevelScenario; var ASeed: Cardinal);
    procedure Frame(const AScenario: TLevelScenario; var ASeed: Cardinal; var AWaypoint: Integer; ATic: Integer);
  protected
    procedure LoadScenario(const AScenario: TLevelScenario); virtual; abstract;
    procedure GetGlobals(out AGlobals: TLevelGlobals); virtual; abstract;
    procedure SetGlobals(const AGlobals: TLevelGlobals); virtual; abstract;
    procedure GetPlayer(out APlayer: TGreedPlayerRecord); virtual; abstract;
    procedure SetPlayer(const APlayer: TGreedPlayerRecord); virtual; abstract;
    procedure SetClock(AValue: Cardinal); virtual; abstract;
    procedure GetBonus(out ABonus: TLevelBonus); virtual; abstract;
    procedure GetWeaponCharges(out ACharges: TLevelWeaponCharges); virtual; abstract;
    function GetWarpActive: Integer; virtual; abstract;
    function GetRandomOffset: Integer; virtual; abstract;
    procedure ListSprites(AList: TList<TGreedSprite>); virtual; abstract;
    procedure ListElevators(AList: TList<TGreedElevator>); virtual; abstract;
    function DoorCount: Integer; virtual; abstract;
    function DoorAt(AIndex: Integer): TGreedDoor; virtual; abstract;
    function AreaCount: Integer; virtual; abstract;
    function AreaAt(AIndex: Integer): TGreedSpawnArea; virtual; abstract;
    procedure CopyPlane(APlane: TGreedPlane; out ATiles: TLevelTiles); virtual; abstract;
    procedure CopyTriggers(out ATiles: TLevelTiles); virtual; abstract;
    procedure CopySwitches(out ATiles: TLevelTiles); virtual; abstract;
    /// <summary>The sprite at that place of the list loses or gets its hit points</summary>
    procedure SetSpriteHitPoints(AOrdinal, AValue: Integer); virtual; abstract;
    // ---- the routines ----
    procedure CheckWarps(AX, AY: Integer); virtual; abstract;
    procedure CheckItems(ATileX, ATileY: Integer; AUseIt: Boolean; ACharType: Integer); virtual; abstract;
    procedure CheckHere(AUseIt: Boolean; AX, AY, AAngle: Integer); virtual; abstract;
    procedure CheckDoors(AX, AY: Integer); virtual; abstract;
    procedure TimeUpdate; virtual; abstract;
    procedure WarpAnim; virtual; abstract;
    procedure JamWarps; virtual; abstract;
    procedure PrepareNexus; virtual; abstract;
    procedure EndLevel; virtual; abstract;
    procedure StartOver(ARestartValue: Integer); virtual; abstract;
    procedure NewGoalItem; virtual; abstract;
    procedure SpecialCode; virtual; abstract;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>
    ///   Runs the frames and appends the hash of each to AHashes. ADumpTic >= 0: the values of that frame are
    ///   also written in ADump
    /// </summary>
    procedure Run(const AScenario: TLevelScenario; AHashes: TList<Cardinal>; ADumpTic: Integer = -1;
      ADump: TStrings = nil);
    property Trace: TLevelTrace read FTrace;
  end;

function BuildLevelScenario(AIndex: Integer): TLevelScenario;

implementation

uses
  DelphiDoom.Greed.Game.Constants, DelphiDoom.Greed.Game.Tables;

const
  FRACUNIT = GREED_FRACUNIT;
  TILE = GREED_FRACTILEUNIT;
  FIRST_TILE = 3;
  LAST_TILE = 60;
  ELEVATOR_PAUSED = $70000000;
  SWITCH_PICTURES: array[0..11] of Byte = (127, 128, 172, 173, 75, 76, 140, 141, 234, 235, 5, 0);
  AREA_KINDS: array[0..18] of Integer = (0, 1, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 100, 101);
  ANGLES_OF_COMPASS: array[0..7] of Integer = (0, 256, 512, 768, 100, 400, 700, 1000);
  /// what the player types: the codes of the original, in both cases, with other letters around, and pieces
  SECRETS: array[0..55] of string = (
    'belfast', 'allahmode', 'god', 'GOD', 'channel7', 'lizardman', 'dominatrix', 'cyborg', 'mooman', 'raven',
    'omni', 'kmfdm', 'beavis', 'gulliver', 'gulliver', 'gimme', 'taco', 'game1', 'game2', 'game3', 'score10000',
    'score20000', 'score50000', 'go01', 'go02', 'go03', 'go04', 'go07', 'go08', 'go11', 'go15', 'go16', 'go22',
    'go23', 'go28', 'go32', 'go33', 'blammo1', 'blammo2', 'blammo3', 'blammo4', 'blammo5', 'blammo6', 'blammo7',
    'xxBeLfAsTyy', 'qqgo05go23', 'bla', 'bl', 'ago', 'zzz', 'x', 'godgimme', 'blammo4go02', 'GAME2x', 'ravenous',
    '1234567890123456789');

function NextRandom(var ASeed: Cardinal): Integer;
begin
  ASeed := ASeed * 1664525 + 1013904223;
  Result := Integer(ASeed shr 8);
end;

function Pick(var ASeed: Cardinal; ACount: Integer): Integer;
begin
  Result := NextRandom(ASeed) mod ACount;
end;

// A weapon that has a slot: the grenade launcher (6) has the ammunition kind 3 and the original would use the
// memory after the slots and after the ammunition of the player
function PickWeapon(var ASeed: Cardinal): Integer;
begin
  repeat
    Result := Pick(ASeed, LEVEL_WEAPON_COUNT);
  until TGreedGameTables.Weapons[Result].AmmoType <= 2;
end;

function TileCenter(ATile: Integer): Integer;
begin
  Result := (ATile * GREED_MAP_SIZE + 32) * FRACUNIT;
end;

{ TLevelTrace }

procedure TLevelTrace.Reset(ALabels: TStrings);
begin
  FHash := 2166136261;
  FLabels := ALabels;
end;

procedure TLevelTrace.Add(AValue: Integer; const ALabel: string);
var
  LIndex: Integer;
  LBits: Cardinal;
begin
  LBits := Cardinal(AValue);
  for LIndex := 0 to 3 do
  begin
    FHash := (FHash xor (LBits and $FF)) * 16777619;
    LBits := LBits shr 8;
  end;
  if Assigned(FLabels) then
    FLabels.Add(ALabel + '=' + IntToStr(AValue));
end;

procedure TLevelTrace.Add(AValue: Boolean; const ALabel: string);
begin
  Add(Ord(AValue), ALabel);
end;

procedure TLevelTrace.AddText(const AText, ALabel: string);
var
  LIndex: Integer;
begin
  for LIndex := 1 to Length(AText) do
    FHash := (FHash xor (Ord(AText[LIndex]) and $FF)) * 16777619;
  FHash := (FHash xor $FF) * 16777619;
  if Assigned(FLabels) then
    FLabels.Add(ALabel + '="' + AText + '"');
  if Assigned(FCounts) then
    Count('"' + AText + '"');
end;

procedure TLevelTrace.Count(const AKey: string);
var
  LCount: Integer;
begin
  if not FCounts.TryGetValue(AKey, LCount) then
    LCount := 0;
  FCounts.AddOrSetValue(AKey, LCount + 1);
end;

procedure TLevelTrace.Call(const AName: string; const AArguments: array of Integer);
var
  LIndex: Integer;
  LText: string;
begin
  if Assigned(FCounts) then
  begin
    if Length(AArguments) > 0 then
      Count(AName + ' ' + IntToStr(AArguments[0]))
    else
      Count(AName);
  end;
  LText := '';
  if Assigned(FLabels) then
  begin
    for LIndex := 0 to High(AArguments) do
      LText := LText + ' ' + IntToStr(AArguments[LIndex]);
    FLabels.Add('call ' + AName + LText);
  end;
  for LIndex := 1 to Length(AName) do
    FHash := (FHash xor (Ord(AName[LIndex]) and $FF)) * 16777619;
  for LIndex := 0 to High(AArguments) do
  begin
    FHash := (FHash xor (Cardinal(AArguments[LIndex]) and $FF)) * 16777619;
    FHash := (FHash xor ((Cardinal(AArguments[LIndex]) shr 8) and $FF)) * 16777619;
    FHash := (FHash xor ((Cardinal(AArguments[LIndex]) shr 16) and $FF)) * 16777619;
    FHash := (FHash xor (Cardinal(AArguments[LIndex]) shr 24)) * 16777619;
  end;
end;

procedure TLevelTrace.AddBytes(AFirst: PByte; ACount: Integer; const ALabel: string);
var
  LIndex: Integer;
  LHash: Cardinal;
  LByte: PByte;
begin
  LHash := FHash;
  LByte := AFirst;
  for LIndex := 0 to ACount - 1 do
  begin
    LHash := (LHash xor LByte^) * 16777619;
    Inc(LByte);
  end;
  FHash := LHash;
  if Assigned(FLabels) then
  begin
    LByte := AFirst;
    for LIndex := 0 to ACount - 1 do
    begin
      if LByte^ <> 0 then
        FLabels.Add(ALabel + '[' + IntToStr(LIndex) + ']=' + IntToStr(LByte^));
      Inc(LByte);
    end;
  end;
end;

procedure TLevelTrace.AddSprite(const ASprite: TGreedSprite; AIndex: Integer);
var
  LName: string;
begin
  LName := '';
  if Assigned(FLabels) then
    LName := 's' + IntToStr(AIndex);
  Add(ASprite.Kind, LName + '.typ');
  Add(ASprite.X, LName + '.x');
  Add(ASprite.Y, LName + '.y');
  Add(ASprite.Z, LName + '.z');
  Add(ASprite.BasePic, LName + '.basepic');
  Add(ASprite.Angle, LName + '.angle');
  Add(ASprite.Angle2, LName + '.angle2');
  Add(ASprite.Active, LName + '.active');
  Add(ASprite.HitPoints, LName + '.hitpoints');
  Add(ASprite.SpawnId, LName + '.spawnid');
  Add(ASprite.DeathEvent, LName + '.deathevent');
  Add(ASprite.StartSpot, LName + '.startspot');
  Add(ASprite.ZAdjust, LName + '.zadj');
  Add(ASprite.Scale, LName + '.scale');
end;

procedure TLevelTrace.AddElevator(const AElevator: TGreedElevator; AIndex: Integer);
var
  LName: string;
begin
  LName := '';
  if Assigned(FLabels) then
    LName := 'e' + IntToStr(AIndex);
  Add(AElevator.Up, LName + '.up');
  Add(AElevator.Down, LName + '.down');
  Add(AElevator.Position, LName + '.position');
  Add(AElevator.Position64, LName + '.position64');
  Add(AElevator.Timer, LName + '.timer');
  Add(AElevator.Floor, LName + '.floor');
  Add(AElevator.Ceiling, LName + '.ceiling');
  Add(AElevator.MapSpot, LName + '.mapspot');
  Add(AElevator.Speed, LName + '.speed');
  Add(AElevator.Eval, LName + '.eval');
  Add(AElevator.EndEval, LName + '.endeval');
  Add(Ord(AElevator.Kind), LName + '.typ');
end;

procedure TLevelTrace.AddDoor(const ADoor: TGreedDoor; AIndex: Integer);
var
  LName: string;
begin
  LName := '';
  if Assigned(FLabels) then
    LName := 'door' + IntToStr(AIndex);
  Add(ADoor.TileX, LName + '.tilex');
  Add(ADoor.TileY, LName + '.tiley');
  Add(ADoor.Open, LName + '.open');
  Add(ADoor.Opening, LName + '.opening');
  Add(ADoor.Closing, LName + '.closing');
  Add(ADoor.Blocked, LName + '.blocked');
  Add(ADoor.Bumpable, LName + '.bumpable');
  Add(ADoor.Size, LName + '.size');
  Add(ADoor.Timer, LName + '.timer');
  Add(Ord(ADoor.Orientation), LName + '.orientation');
  Add(ADoor.Position, LName + '.position');
end;

procedure TLevelTrace.AddArea(const AArea: TGreedSpawnArea; AIndex: Integer);
var
  LName: string;
begin
  LName := '';
  if Assigned(FLabels) then
    LName := 'area' + IntToStr(AIndex);
  Add(AArea.MapSpot, LName + '.mapspot');
  Add(AArea.MapX, LName + '.mapx');
  Add(AArea.MapY, LName + '.mapy');
  Add(AArea.Kind, LName + '.typ');
  Add(AArea.Time, LName + '.time');
end;

{ TLevelStandIns }

class procedure TLevelStandIns.Spawned(out ASprite: TGreedSprite; out AMapSpot, AMapValue: Integer; AValue, AX,
  AY, AZ, AZAdjust, AAngle, AAngle2: Integer; AActive: Boolean; ASpawnId: Integer);
begin
  ASprite := Default(TGreedSprite);
  ASprite.Kind := AValue;
  ASprite.X := AX;
  ASprite.Y := AY;
  ASprite.Z := AZ;
  ASprite.ZAdjust := AZAdjust;
  ASprite.Angle := AAngle and GREED_ANGLES;
  ASprite.Angle2 := AAngle2 and GREED_ANGLES;
  ASprite.Active := AActive;
  ASprite.SpawnId := ASpawnId;
  ASprite.BasePic := AValue * 3;
  ASprite.Scale := 1;
  AMapSpot := (AY div TILE) * GREED_MAP_SIZE + (AX div TILE);
  ASprite.StartSpot := AMapSpot;
  if TGreedGameTables.IsMonster(AValue) then
    ASprite.HitPoints := 100;
  AMapValue := 0;
  case AValue of
    GREED_S_MEDPAK1..GREED_S_MEDPAK4:
      AMapValue := AValue - GREED_S_MEDPAK1 + GREED_SM_MEDPAK1;
    GREED_S_ENERGY, GREED_S_BALLISTIC, GREED_S_PLASMA:
      AMapValue := AValue - GREED_S_ENERGY + GREED_SM_ENERGY;
    GREED_S_SHIELD1..GREED_S_SHIELD4:
      AMapValue := AValue - GREED_S_SHIELD1 + GREED_SM_SHIELD1;
    GREED_S_IGRENADE..GREED_S_ISTEALER:
      AMapValue := AValue - GREED_S_IGRENADE + GREED_SM_IGRENADE;
    GREED_S_BONUSITEM:
      AMapValue := GREED_SM_BONUSITEM;
    GREED_S_EXIT:
      AMapValue := GREED_SM_EXIT;
    GREED_S_WEAPON0..GREED_S_WEAPON0 + LEVEL_WEAPON_COUNT - 1:
      AMapValue := AValue - GREED_S_WEAPON0 + GREED_SM_WEAPON0;
  end;
  if (AMapSpot < 0) or (AMapSpot >= GREED_MAP_TILES) then
    AMapValue := 0;
end;

class procedure TLevelStandIns.Heal(var APlayer: TGreedPlayerRecord; AAmount: Integer);
begin
  APlayer.Shield := APlayer.Shield + AAmount;
  if APlayer.Shield > APlayer.MaxShield then
    APlayer.Shield := APlayer.MaxShield;
end;

class procedure TLevelStandIns.MedPaks(var APlayer: TGreedPlayerRecord; AAmount: Integer);
begin
  APlayer.Angst := APlayer.Angst + AAmount;
  if APlayer.Angst > APlayer.MaxAngst then
    APlayer.Angst := APlayer.MaxAngst;
end;

class procedure TLevelStandIns.AddScore(var APlayer: TGreedPlayerRecord; AAmount: Integer);
begin
  APlayer.Score := APlayer.Score + AAmount;
  APlayer.LevelScore := APlayer.LevelScore - AAmount;
  if APlayer.LevelScore < 0 then
    APlayer.LevelScore := 0;
end;

class procedure TLevelStandIns.RunEvent(ATriggers, ASwitches: PByte; AEvent: Integer);
var
  LIndex: Integer;
begin
  if not Odd(AEvent) then
    Exit;
  for LIndex := 0 to GREED_MAP_TILES - 1 do
  begin
    if ATriggers^ = AEvent then
      ATriggers^ := 0;
    if ASwitches^ = AEvent then
      ASwitches^ := 0;
    Inc(ATriggers);
    Inc(ASwitches);
  end;
end;

class function TLevelStandIns.Kill(var ASprite: TGreedSprite; AWeapon: Integer): Boolean;
begin
  ASprite.HitPoints := 0;
  ASprite.Active := False;
  ASprite.BasePic := ASprite.BasePic + AWeapon;
  Result := Odd(ASprite.Kind);
end;

class function TLevelStandIns.WeaponPictureHeight(AWeapon: Integer): Integer;
begin
  Result := 40 + AWeapon;
end;

{ TLevelScenarioRunner }

constructor TLevelScenarioRunner.Create;
begin
  inherited Create;
  FTrace := TLevelTrace.Create;
  FTrace.Reset(nil);
  FSprites := TList<TGreedSprite>.Create;
  FElevators := TList<TGreedElevator>.Create;
end;

destructor TLevelScenarioRunner.Destroy;
begin
  FElevators.Free;
  FSprites.Free;
  FTrace.Free;
  inherited Destroy;
end;

procedure TLevelScenarioRunner.TraceState;
var
  LGlobals: TLevelGlobals;
  LPlayer: TGreedPlayerRecord;
  LBonus: TLevelBonus;
  LCharges: TLevelWeaponCharges;
  LTiles: TLevelTiles;
  LIndex: Integer;
begin
  GetGlobals(LGlobals);
  FTrace.Add(LGlobals.TimeCount, 'timecount');
  FTrace.Add(LGlobals.SpriteMoveTime, 'spritemovetime');
  FTrace.Add(LGlobals.SwitchTime, 'SwitchTime');
  FTrace.Add(LGlobals.SpecialEffect, 'specialeffect');
  FTrace.Add(LGlobals.SpecialEffectTime, 'specialeffecttime');
  FTrace.Add(LGlobals.Warping, 'Warping');
  FTrace.Add(LGlobals.WarpX, 'WarpX');
  FTrace.Add(LGlobals.WarpY, 'WarpY');
  FTrace.Add(LGlobals.WarpActive, 'warpActive');
  FTrace.Add(LGlobals.WarpJammer, 'warpjammer');
  FTrace.Add(LGlobals.ExitLevel, 'ExitLevel');
  FTrace.Add(LGlobals.ExitExists, 'exitexists');
  FTrace.Add(LGlobals.HurtBorder, 'hurtborder');
  FTrace.Add(LGlobals.ChangingWeapons, 'changingweapons');
  FTrace.Add(LGlobals.WeaponLowering, 'weaponlowering');
  FTrace.Add(LGlobals.NewWeapon, 'newweapon');
  FTrace.Add(LGlobals.WeaponYChange, 'weaponychange');
  FTrace.Add(LGlobals.TurnRate, 'turnrate');
  FTrace.Add(LGlobals.MoveRate, 'moverate');
  FTrace.Add(LGlobals.StrafRate, 'strafrate');
  FTrace.Add(LGlobals.FallRate, 'fallrate');
  FTrace.Add(LGlobals.DoorSound, 'doorsound');
  FTrace.Add(LGlobals.DoorX, 'doorx');
  FTrace.Add(LGlobals.DoorY, 'doory');
  FTrace.Add(LGlobals.GoalItem, 'goalitem');
  FTrace.Add(LGlobals.ToggleGoalItem, 'togglegoalitem');
  FTrace.Add(LGlobals.Lighting, 'lighting');
  FTrace.Add(LGlobals.ChangeLight, 'changelight');
  FTrace.Add(LGlobals.DeadRestart, 'deadrestart');
  FTrace.Add(LGlobals.NumProcesses, 'numprocesses');
  FTrace.Add(LGlobals.OldInventory, 'oldinventory');
  FTrace.Add(LGlobals.OldShots, 'oldshots');
  FTrace.Add(LGlobals.OldGoalItem, 'oldgoalitem');
  FTrace.Add(LGlobals.TotalEffectTime, 'totaleffecttime');
  FTrace.Add(LGlobals.GodMode, 'godmode');
  FTrace.Add(LGlobals.MidgetMode, 'midgetmode');
  FTrace.Add(LGlobals.Game1, 'GAME1');
  FTrace.Add(LGlobals.Game2, 'GAME2');
  FTrace.Add(LGlobals.Game3, 'GAME3');
  FTrace.Add(LGlobals.EnemyViewMode, 'enemyviewmode');
  FTrace.Add(LGlobals.WeapMode, 'weapmode');
  FTrace.Add(LGlobals.GameEpisode, 'gameepisode');
  FTrace.AddText(LGlobals.SecretBuf, 'secretbuf');
  GetBonus(LBonus);
  FTrace.Add(LBonus.Time, 'bonus.time');
  FTrace.Add(LBonus.Score, 'bonus.score');
  FTrace.Add(LBonus.TileX, 'bonus.tilex');
  FTrace.Add(LBonus.TileY, 'bonus.tiley');
  FTrace.Add(LBonus.MapSpot, 'bonus.mapspot');
  FTrace.Add(LBonus.Num, 'bonus.num');
  FTrace.AddText(LBonus.Name, 'bonus.name');
  FTrace.Add(LBonus.SpriteOrdinal, 'bonus.sprite');
  GetWeaponCharges(LCharges);
  for LIndex := 0 to High(LCharges) do
  begin
    FTrace.Add(LCharges[LIndex].Charge, 'weapon.charge');
    FTrace.Add(LCharges[LIndex].ChargeTime, 'weapon.chargetime');
  end;
  GetPlayer(LPlayer);
  FTrace.Add(LPlayer.X, 'player.x');
  FTrace.Add(LPlayer.Y, 'player.y');
  FTrace.Add(LPlayer.Z, 'player.z');
  FTrace.Add(LPlayer.MapSpot, 'player.mapspot');
  FTrace.Add(LPlayer.Shield, 'player.shield');
  FTrace.Add(LPlayer.Angst, 'player.angst');
  FTrace.Add(LPlayer.Map, 'player.map');
  FTrace.Add(LPlayer.LevelScore, 'player.levelscore');
  FTrace.Add(LPlayer.Score, 'player.score');
  FTrace.Add(LPlayer.CurrentWeapon, 'player.currentweapon');
  for LIndex := 0 to High(LPlayer.Weapons) do
    FTrace.Add(LPlayer.Weapons[LIndex], 'player.weapons');
  for LIndex := 0 to High(LPlayer.Ammo) do
    FTrace.Add(LPlayer.Ammo[LIndex], 'player.ammo');
  for LIndex := 0 to High(LPlayer.Inventory) do
    FTrace.Add(LPlayer.Inventory[LIndex], 'player.inventory');
  for LIndex := 0 to High(LPlayer.Primaries) do
    FTrace.Add(LPlayer.Primaries[LIndex], 'player.primaries');
  for LIndex := 0 to High(LPlayer.Secondaries) do
    FTrace.Add(LPlayer.Secondaries[LIndex], 'player.secondaries');
  // the whole record, as it would be saved
  FTrace.AddBytes(@LPlayer, SizeOf(LPlayer), 'player_t');
  FSprites.Clear;
  ListSprites(FSprites);
  FTrace.Add(FSprites.Count, 'sprites');
  for LIndex := 0 to FSprites.Count - 1 do
    FTrace.AddSprite(FSprites[LIndex], LIndex);
  FElevators.Clear;
  ListElevators(FElevators);
  FTrace.Add(FElevators.Count, 'elevators');
  for LIndex := 0 to FElevators.Count - 1 do
    FTrace.AddElevator(FElevators[LIndex], LIndex);
  FTrace.Add(DoorCount, 'doors');
  for LIndex := 0 to DoorCount - 1 do
    FTrace.AddDoor(DoorAt(LIndex), LIndex);
  FTrace.Add(AreaCount, 'areas');
  for LIndex := 0 to AreaCount - 1 do
    FTrace.AddArea(AreaAt(LIndex), LIndex);
  CopyPlane(gpMapSprites, LTiles);
  FTrace.AddBytes(@LTiles[0], GREED_MAP_TILES, 'mapsprites');
  CopyPlane(gpNorthWall, LTiles);
  FTrace.AddBytes(@LTiles[0], GREED_MAP_TILES, 'northwall');
  CopyPlane(gpWestWall, LTiles);
  FTrace.AddBytes(@LTiles[0], GREED_MAP_TILES, 'westwall');
  CopyPlane(gpFloorHeight, LTiles);
  FTrace.AddBytes(@LTiles[0], GREED_MAP_TILES, 'floorheight');
  CopyTriggers(LTiles);
  FTrace.AddBytes(@LTiles[0], GREED_MAP_TILES, 'triggers');
  CopySwitches(LTiles);
  FTrace.AddBytes(@LTiles[0], GREED_MAP_TILES, 'switches');
  FTrace.Add(GetWarpActive, 'warpActive');
  FTrace.Add(GetRandomOffset, 'rndofs');
end;

procedure TLevelScenarioRunner.Mutate(const AScenario: TLevelScenario; var ASeed: Cardinal);
var
  LGlobals: TLevelGlobals;
  LPlayer: TGreedPlayerRecord;
  LChoice, LSlot: Integer;
begin
  LChoice := Pick(ASeed, 100);
  if LChoice >= 30 then
    Exit;
  GetGlobals(LGlobals);
  GetPlayer(LPlayer);
  case LChoice of
    0..2:
      begin
        // hit
        LPlayer.Angst := LPlayer.Angst div 2 + 1;
        LPlayer.Shield := LPlayer.Shield div 2;
      end;
    3..5:
      LPlayer.Ammo[Pick(ASeed, 3)] := Pick(ASeed, 301);
    6, 7:
      begin
        FSprites.Clear;
        ListSprites(FSprites);
        if FSprites.Count > 0 then
          SetSpriteHitPoints(Pick(ASeed, FSprites.Count), 0);
      end;
    8, 9:
      begin
        LPlayer.Inventory[11] := LPlayer.Inventory[11] + 1;
        LGlobals.WarpJammer := True;
      end;
    10, 11:
      LGlobals.ToggleGoalItem := True;
    12, 13:
      LGlobals.NumProcesses := 1 - LGlobals.NumProcesses;
    14:
      LGlobals.DeadRestart := True;
    15..17:
      begin
        LSlot := Pick(ASeed, 5);
        if LPlayer.Weapons[LSlot] <> -1 then
          LPlayer.CurrentWeapon := LSlot;
      end;
    18, 19:
      LPlayer.LevelScore := 0;
    20:
      // the effect ends before its time
      LGlobals.SpecialEffect := 0;
    21:
      begin
        LPlayer.Inventory[Pick(ASeed, 13)] := Pick(ASeed, 21);
        LPlayer.Shield := LPlayer.MaxShield;
      end;
    22:
      LPlayer.Angst := LPlayer.MaxAngst;
    23:
      LGlobals.HurtBorder := False;
    24..28:
      // the player types something (the keyboard keeps the last 19 letters)
      begin
        LGlobals.SecretBuf := LGlobals.SecretBuf + SECRETS[Pick(ASeed, Length(SECRETS))];
        if Length(LGlobals.SecretBuf) > 19 then
          LGlobals.SecretBuf := Copy(LGlobals.SecretBuf, Length(LGlobals.SecretBuf) - 18, 19);
      end;
    29:
      LGlobals.WeapMode := 1 + Pick(ASeed, 2);
  end;
  SetGlobals(LGlobals);
  SetPlayer(LPlayer);
end;

procedure TLevelScenarioRunner.Frame(const AScenario: TLevelScenario; var ASeed: Cardinal; var AWaypoint: Integer;
  ATic: Integer);
var
  LGlobals: TLevelGlobals;
  LPlayer: TGreedPlayerRecord;
  LPoint: TLevelWaypoint;
  LBonus: TLevelBonus;
  LPrimary0, LPrimary1: Boolean;
begin
  // the clocks, and what newlights would do with changelight
  GetGlobals(LGlobals);
  LGlobals.TimeCount := LGlobals.TimeCount + AScenario.TimeStep;
  if LGlobals.ChangeLight <> 0 then
  begin
    LGlobals.Lighting := LGlobals.Lighting + LGlobals.ChangeLight;
    if LGlobals.Lighting < 0 then
      LGlobals.Lighting := 0;
    LGlobals.ChangeLight := 0;
  end;
  SetGlobals(LGlobals);
  SetClock(AScenario.ClockBase + Cardinal(ATic) * AScenario.ClockStep);

  // the player goes to the next place (not while it warps)
  if (LGlobals.Warping = 0) and (ATic mod AScenario.Dwell = 0) and (Length(AScenario.Waypoints) > 0) then
  begin
    LPoint := AScenario.Waypoints[AWaypoint mod Length(AScenario.Waypoints)];
    Inc(AWaypoint);
    GetPlayer(LPlayer);
    LPlayer.X := TileCenter(LPoint.TileX);
    LPlayer.Y := TileCenter(LPoint.TileY);
    LPlayer.MapSpot := LPoint.TileY * GREED_MAP_SIZE + LPoint.TileX;
    LPlayer.Angle := LPoint.Angle;
    // now and then it goes where the bonus item is
    GetBonus(LBonus);
    if (LBonus.Score > 0) and (Pick(ASeed, 10) = 0) then
    begin
      LPlayer.X := TileCenter(LBonus.TileX);
      LPlayer.Y := TileCenter(LBonus.TileY);
      LPlayer.MapSpot := LBonus.MapSpot;
    end;
    SetPlayer(LPlayer);
  end;
  Mutate(AScenario, ASeed);

  // one frame, in the order of PlayLoop
  GetPlayer(LPlayer);
  if Pick(ASeed, 3) = 0 then
    CheckHere(True, LPlayer.X, LPlayer.Y, LPlayer.Angle);
  GetGlobals(LGlobals);
  if LGlobals.WarpJammer then
    JamWarps;
  GetGlobals(LGlobals);
  GetPlayer(LPlayer);
  LPrimary0 := (AScenario.Primaries[0] = -1) or (LPlayer.Primaries[0] = AScenario.PCount[0]);
  LPrimary1 := (AScenario.Primaries[2] = -1) or (LPlayer.Primaries[1] = AScenario.PCount[1]);
  if (LPlayer.LevelScore = 0) and not LGlobals.ExitExists and LPrimary0 and LPrimary1 then
    PrepareNexus;
  GetGlobals(LGlobals);
  if LGlobals.ExitLevel then
    EndLevel;
  GetGlobals(LGlobals);
  if LGlobals.TimeCount > LGlobals.SpecialEffectTime then
  begin
    LGlobals.SpecialEffect := 0;
    LGlobals.SpecialEffectTime := MaxInt;
    SetGlobals(LGlobals);
  end;
  if LGlobals.Warping <> 0 then
  begin
    WarpAnim;
    // ControlMovement would do this
    GetPlayer(LPlayer);
    LPlayer.MapSpot := (LPlayer.Y div TILE) * GREED_MAP_SIZE + (LPlayer.X div TILE);
    SetPlayer(LPlayer);
  end;
  SpecialCode;
  TimeUpdate;
  GetPlayer(LPlayer);
  CheckWarps(LPlayer.X, LPlayer.Y);
  GetPlayer(LPlayer);
  CheckDoors(LPlayer.X, LPlayer.Y);
  GetGlobals(LGlobals);
  if LGlobals.DeadRestart then
    StartOver(2);
  TimeUpdate;
  GetGlobals(LGlobals);
  if LGlobals.ToggleGoalItem then
    NewGoalItem;
  // another player takes what is on a place of the path
  if (Pick(ASeed, 16) = 0) and (Length(AScenario.Waypoints) > 0) then
  begin
    LPoint := AScenario.Waypoints[Pick(ASeed, Length(AScenario.Waypoints))];
    CheckItems(LPoint.TileX, LPoint.TileY, False, Pick(ASeed, 5));
  end;
  TimeUpdate;
end;

procedure TLevelScenarioRunner.Run(const AScenario: TLevelScenario; AHashes: TList<Cardinal>; ADumpTic: Integer;
  ADump: TStrings);
var
  LTic, LWaypoint: Integer;
  LSeed: Cardinal;
begin
  FTrace.Reset(nil);
  LoadScenario(AScenario);
  LSeed := AScenario.Seed xor $5BD1E995;
  LWaypoint := 0;
  for LTic := 0 to AScenario.Tics - 1 do
  begin
    if LTic = ADumpTic then
      FTrace.Reset(ADump)
    else
      FTrace.Reset(nil);
    Frame(AScenario, LSeed, LWaypoint, LTic);
    TraceState;
    AHashes.Add(FTrace.Hash);
  end;
end;

{ the scenarios }

function BuildLevelScenario(AIndex: Integer): TLevelScenario;
var
  LSeed: Cardinal;
  LUsed: array[0..GREED_MAP_TILES - 1] of Boolean;
  LPoints: TList<TLevelWaypoint>;

  procedure SetTile(APlane: TGreedPlane; ASpot, AValue: Integer);
  begin
    Result.Planes[APlane][ASpot] := Byte(AValue);
  end;

  function FreeTile(out ATileX, ATileY: Integer): Integer;
  begin
    repeat
      ATileX := FIRST_TILE + Pick(LSeed, LAST_TILE - FIRST_TILE + 1);
      ATileY := FIRST_TILE + Pick(LSeed, LAST_TILE - FIRST_TILE + 1);
      Result := ATileY * GREED_MAP_SIZE + ATileX;
    until not LUsed[Result];
    LUsed[Result] := True;
  end;

  procedure AddPoint(ATileX, ATileY: Integer);
  var
    LPoint: TLevelWaypoint;
  begin
    LPoint.TileX := ATileX;
    LPoint.TileY := ATileY;
    LPoint.Angle := ANGLES_OF_COMPASS[Pick(LSeed, Length(ANGLES_OF_COMPASS))];
    LPoints.Add(LPoint);
  end;

  procedure AddSprite(AKind, ATileX, ATileY, AHitPoints, ADeathEvent: Integer);
  var
    LSprite: TGreedSprite;
  begin
    LSprite := Default(TGreedSprite);
    LSprite.Kind := AKind;
    LSprite.X := TileCenter(ATileX);
    LSprite.Y := TileCenter(ATileY);
    LSprite.HitPoints := AHitPoints;
    LSprite.DeathEvent := ADeathEvent;
    LSprite.BasePic := AKind * 3;
    LSprite.Scale := 1;
    LSprite.StartSpot := ATileY * GREED_MAP_SIZE + ATileX;
    Result.Sprites := Result.Sprites + [LSprite];
  end;

  procedure AddItem(AMapValue, ASpriteKind, ADeathEvent: Integer);
  var
    LTileX, LTileY, LSpot: Integer;
  begin
    LSpot := FreeTile(LTileX, LTileY);
    SetTile(gpMapSprites, LSpot, AMapValue);
    if ASpriteKind <> 0 then
      AddSprite(ASpriteKind, LTileX, LTileY, 0, ADeathEvent);
    AddPoint(LTileX, LTileY);
    // some places are visited again later
    if Pick(LSeed, 4) = 0 then
      AddPoint(LTileX, LTileY);
  end;

  procedure SwitchWalls(ASpot: Integer);
  begin
    SetTile(gpWestWall, ASpot + 1, SWITCH_PICTURES[Pick(LSeed, Length(SWITCH_PICTURES))]);
    SetTile(gpNorthWall, ASpot, SWITCH_PICTURES[Pick(LSeed, Length(SWITCH_PICTURES))]);
    SetTile(gpWestWall, ASpot, SWITCH_PICTURES[Pick(LSeed, Length(SWITCH_PICTURES))]);
    SetTile(gpNorthWall, ASpot + GREED_MAP_SIZE, SWITCH_PICTURES[Pick(LSeed, Length(SWITCH_PICTURES))]);
  end;

  procedure AddElevator(AKind: TGreedElevatorType; ASpot: Integer; AAtCeiling: Boolean);
  var
    LElevator: TGreedElevator;
  begin
    LElevator := Default(TGreedElevator);
    LElevator.Kind := AKind;
    LElevator.Floor := Pick(LSeed, 3) * 8;
    LElevator.Ceiling := LElevator.Floor + 16 + Pick(LSeed, 6) * 8;
    if AAtCeiling then
      LElevator.Position := LElevator.Ceiling
    else
      LElevator.Position := LElevator.Floor;
    LElevator.Position64 := LElevator.Position * FRACUNIT;
    LElevator.Speed := 2 + Pick(LSeed, 7);
    LElevator.Timer := ELEVATOR_PAUSED;
    LElevator.MapSpot := ASpot;
    if Pick(LSeed, 3) = 0 then
      LElevator.EndEval := 1 + Pick(LSeed, 30);
    SetTile(gpFloorHeight, ASpot, LElevator.Position);
    if AKind = getNormal then
    begin
      // it moves by itself
      LElevator.Timer := Result.TimeCount;
      LElevator.Up := True;
    end;
    Result.Elevators := Result.Elevators + [LElevator];
  end;

  procedure AddSwitchTile(AMapValue: Integer; AKind: TGreedElevatorType);
  var
    LTileX, LTileY, LSpot, LCount, LIndex, LElevatorX, LElevatorY: Integer;
  begin
    LSpot := FreeTile(LTileX, LTileY);
    SetTile(gpMapSprites, LSpot, AMapValue);
    AddPoint(LTileX, LTileY);
    AddPoint(LTileX, LTileY);
    LCount := 1 + Pick(LSeed, 3);
    for LIndex := 1 to LCount do
      AddElevator(AKind, FreeTile(LElevatorX, LElevatorY), AKind <> getSwitchUp);
  end;

  procedure AddSwapSwitch;
  var
    LTileX, LTileY, LSpot, LIndex, LElevatorX, LElevatorY, LElevator: Integer;
  begin
    LSpot := FreeTile(LTileX, LTileY);
    SetTile(gpMapSprites, LSpot, GREED_SM_SWAPSWITCH);
    SwitchWalls(LSpot);
    for LIndex := 1 to 4 do
      AddPoint(LTileX, LTileY);
    for LIndex := 1 to 1 + Pick(LSeed, 2) do
    begin
      AddElevator(getSwap, FreeTile(LElevatorX, LElevatorY), Pick(LSeed, 2) = 0);
      LElevator := High(Result.Elevators);
      // one that is half way and cannot be swapped
      if Pick(LSeed, 5) = 0 then
        Result.Elevators[LElevator].Position := Result.Elevators[LElevator].Floor + 3;
    end;
  end;

  procedure AddSecretTrigger;
  var
    LTileX, LTileY, LSpot, LElevatorSpot: Integer;
  begin
    LSpot := FreeTile(LTileX, LTileY);
    SetTile(gpMapSprites, LSpot, GREED_SM_STRIGGER);
    AddPoint(LTileX, LTileY);
    AddPoint(LTileX, LTileY);
    // the secret elevator is next to its trigger
    LElevatorSpot := LSpot + 1;
    if not LUsed[LElevatorSpot] then
    begin
      LUsed[LElevatorSpot] := True;
      AddElevator(getSecret, LElevatorSpot, True);
      if Pick(LSeed, 2) = 0 then
        Result.Switches[(LTileX + 1) * GREED_MAP_SIZE + LTileY] := Byte(1 + Pick(LSeed, 30));
    end;
    LElevatorSpot := LSpot + GREED_MAP_SIZE * 3;
    if not LUsed[LElevatorSpot] then
    begin
      // too far: it does not move
      LUsed[LElevatorSpot] := True;
      AddElevator(getSecret, LElevatorSpot, True);
    end;
  end;

  procedure AddWarps(AValue, ACount: Integer);
  var
    LIndex, LTileX, LTileY, LSpot: Integer;
  begin
    for LIndex := 1 to ACount do
    begin
      LSpot := FreeTile(LTileX, LTileY);
      SetTile(gpMapSprites, LSpot, AValue);
      AddPoint(LTileX, LTileY);
      AddPoint(LTileX, LTileY);
    end;
  end;

  procedure AddArea(AKind: Integer; AReady: Boolean);
  var
    LArea: TGreedSpawnArea;
    LTileX, LTileY: Integer;
  begin
    LArea.MapSpot := FreeTile(LTileX, LTileY);
    LArea.MapX := TileCenter(LTileX);
    LArea.MapY := TileCenter(LTileY);
    LArea.Kind := AKind;
    if AReady then
      LArea.Time := Pick(LSeed, Result.TimeCount + 1)
    else
      LArea.Time := Result.TimeCount + 1 + Pick(LSeed, 200);
    Result.Areas := Result.Areas + [LArea];
    case Pick(LSeed, 4) of
      0:
        AddSprite(GREED_S_GENERATOR, LTileX, LTileY, 0, 0);
      1:
        AddSprite(GREED_S_GENSTART + Pick(LSeed, GREED_S_GENEND - GREED_S_GENSTART + 1), LTileX, LTileY, 0, 0);
      2:
        // something is on the place: the area waits
        SetTile(gpMapSprites, LArea.MapSpot, 1);
    end;
    if Pick(LSeed, 3) = 0 then
      AddPoint(LTileX, LTileY);
  end;

  procedure AddDoor;
  var
    LDoor: TGreedDoor;
    LSpot: Integer;
  begin
    LDoor := Default(TGreedDoor);
    LSpot := FreeTile(LDoor.TileX, LDoor.TileY);
    LDoor.Bumpable := Pick(LSeed, 4) <> 0;
    LDoor.Orientation := TGreedDoorOrientation(Pick(LSeed, 4));
    LDoor.Size := 64 * FRACUNIT;
    LDoor.Position := LDoor.Size;
    LDoor.Timer := Result.TimeCount;
    Result.MapFlags[LSpot] := Result.MapFlags[LSpot] or GREED_FL_DOOR;
    Result.Doors := Result.Doors + [LDoor];
    AddPoint(LDoor.TileX, LDoor.TileY);
    AddPoint(LDoor.TileX, LDoor.TileY - 1 + Pick(LSeed, 3));
  end;

  procedure Shuffle;
  var
    LIndex, LOther: Integer;
    LPoint: TLevelWaypoint;
  begin
    for LIndex := LPoints.Count - 1 downto 1 do
    begin
      LOther := Pick(LSeed, LIndex + 1);
      LPoint := LPoints[LIndex];
      LPoints[LIndex] := LPoints[LOther];
      LPoints[LOther] := LPoint;
    end;
  end;

var
  LPlane: TGreedPlane;
  LSpot, LIndex, LCount, LTileX, LTileY, LKind, LEvent, LWeapon, LSlot: Integer;
begin
  Result := Default(TLevelScenario);
  Result.Index := AIndex;
  LSeed := Cardinal(AIndex) * 2654435761 + 97;
  Result.Seed := LSeed;
  for LPlane := Low(TGreedPlane) to High(TGreedPlane) do
    SetLength(Result.Planes[LPlane], GREED_MAP_TILES);
  SetLength(Result.MapFlags, GREED_MAP_TILES);
  SetLength(Result.Triggers, GREED_MAP_TILES);
  SetLength(Result.Switches, GREED_MAP_TILES);
  FillChar(LUsed, SizeOf(LUsed), 0);
  LPoints := TList<TLevelWaypoint>.Create;
  try
    Result.Tics := 300 + (AIndex * 157) mod 1201;
    Result.TimeStep := 1 + AIndex mod 3;
    Result.TimeCount := 100 + Pick(LSeed, 2000);
    Result.Dwell := 2 + Pick(LSeed, 4);
    Result.RandomOffset := Pick(LSeed, 512);
    Result.NumProcesses := AIndex mod 2;
    Result.Demo := AIndex mod 6 = 5;
    Result.Episode := 1 + (AIndex div 2) mod 3;
    Result.AmbientLight := 1024 + Pick(LSeed, 9) * 128;
    Result.BonusTime := 40 + Pick(LSeed, 400);
    Result.BonusFirstTime := Result.TimeCount + Pick(LSeed, 120);
    Result.ClockStep := 1 + Cardinal(Pick(LSeed, 37));
    if AIndex mod 8 = 7 then
      // the clock wraps during the scenario
      Result.ClockBase := $FFFFFF00 - Cardinal(Pick(LSeed, 2000))
    else
      Result.ClockBase := Cardinal(NextRandom(LSeed)) * 77;

    // the level: floor everywhere inside, with some holes and some places where nothing can be put
    for LTileY := 1 to GREED_MAP_SIZE - 2 do
      for LTileX := 1 to GREED_MAP_SIZE - 2 do
      begin
        LSpot := LTileY * GREED_MAP_SIZE + LTileX;
        SetTile(gpFloorPic, LSpot, 1 + Pick(LSeed, 40));
        SetTile(gpCeilingHeight, LSpot, 200);
        case Pick(LSeed, 40) of
          0:
            SetTile(gpFloorPic, LSpot, 0);
          1:
            SetTile(gpMapEffects, LSpot, 1 + Pick(LSeed, 7));
          2:
            SetTile(gpCeilingHeight, LSpot, 0);
          3:
            SetTile(gpMapEffects, LSpot, 8 + Pick(LSeed, 8) * 8);
        end;
      end;

    // the goals
    for LIndex := 0 to 1 do
    begin
      if Pick(LSeed, 4) = 0 then
        Result.Primaries[LIndex * 2] := -1
      else
      begin
        Result.Primaries[LIndex * 2] := LIndex;
        Result.PCount[LIndex] := 1 + Pick(LSeed, 3);
      end;
      Result.Primaries[LIndex * 2 + 1] := 500 + Pick(LSeed, 8) * 250;
    end;
    for LIndex := 0 to 6 do
    begin
      if Pick(LSeed, 2) = 0 then
        Result.Secondaries[LIndex * 2] := -1
      else
      begin
        Result.Secondaries[LIndex * 2] := LIndex;
        Result.SCount[LIndex] := 1 + Pick(LSeed, 2);
      end;
      Result.Secondaries[LIndex * 2 + 1] := 100 + Pick(LSeed, 8) * 50;
    end;
    Result.LevelScore := 1000 + Pick(LSeed, 6) * 500;
    for LIndex := 0 to 1 do
      for LCount := 1 to Result.PCount[LIndex] do
        AddItem(GREED_SM_PRIMARY1 + LIndex, GREED_S_PRIMARY1 + LIndex, 0);
    for LIndex := 0 to 6 do
      for LCount := 1 to Result.SCount[LIndex] do
        AddItem(GREED_SM_SECONDARY1 + LIndex, GREED_S_SECONDARY1 + LIndex, 0);

    // the items
    LCount := 50 + (AIndex * 7) mod 60;
    for LIndex := 1 to LCount do
    begin
      LEvent := 0;
      if Pick(LSeed, 3) = 0 then
        LEvent := 1 + Pick(LSeed, 30);
      case Pick(LSeed, 20) of
        0, 1:
          begin
            LKind := Pick(LSeed, 4);
            AddItem(GREED_SM_MEDPAK1 + LKind, GREED_S_MEDPAK1 + LKind, 0);
          end;
        2, 3:
          begin
            LKind := Pick(LSeed, 4);
            AddItem(GREED_SM_SHIELD1 + LKind, GREED_S_SHIELD1 + LKind, 0);
          end;
        4, 5:
          begin
            LKind := Pick(LSeed, 3);
            AddItem(GREED_SM_ENERGY + LKind, GREED_S_ENERGY + LKind, 0);
          end;
        6:
          AddItem(GREED_SM_AMMOBOX, GREED_S_AMMOBOX, LEvent);
        7:
          AddItem(GREED_SM_MEDBOX, GREED_S_MEDBOX, LEvent);
        8:
          AddItem(GREED_SM_GOODIEBOX, GREED_S_GOODIEBOX, LEvent);
        9..11:
          begin
            LKind := Pick(LSeed, 11);
            AddItem(GREED_SM_IGRENADE + LKind, GREED_S_IGRENADE + LKind, 0);
          end;
        12..15:
          begin
            LKind := PickWeapon(LSeed);
            AddItem(GREED_SM_WEAPON0 + LKind, GREED_S_WEAPON0 + LKind, 0);
          end;
        16:
          // the value without its sprite, or with the sprite of something else
          if Pick(LSeed, 2) = 0 then
          begin
            // not the bonus item: the original would use the nil pointer of its sprite
            LKind := GREED_SM_MEDPAK1 + Pick(LSeed, 42);
            if LKind = GREED_SM_BONUSITEM then
              LKind := GREED_SM_EXIT;
            AddItem(LKind, 0, 0);
          end
          else
            AddItem(GREED_SM_MEDPAK1 + Pick(LSeed, 22), GREED_S_GENERATOR, 0);
        17:
          // a value that is not an item
          AddItem(173 + Pick(LSeed, 27), GREED_S_AMMOBOX, 0);
        18:
          AddItem(GREED_SM_WEAPON0 + PickWeapon(LSeed), 0, 0);
        19:
          begin
            // an empty place of the path, sometimes with a trigger
            FreeTile(LTileX, LTileY);
            AddPoint(LTileX, LTileY);
          end;
      end;
    end;

    // the switches of the elevators
    for LIndex := 1 to 1 + AIndex mod 3 do
    begin
      AddSwitchTile(GREED_SM_SWITCHDOWN, getSwitchDown);
      AddSwitchTile(GREED_SM_SWITCHDOWN2, getSwitchDown2);
      AddSwitchTile(GREED_SM_SWITCHUP, getSwitchUp);
      AddSwapSwitch;
      AddSecretTrigger;
    end;
    // a switch without its elevators
    if AIndex mod 4 = 1 then
      AddItem(GREED_SM_SWITCHDOWN + Pick(LSeed, 3), 0, 0);
    if AIndex mod 5 = 0 then
      AddElevator(getNormal, FreeTile(LTileX, LTileY), False);

    // the warps
    AddWarps(GREED_SM_WARP1, 2);
    if AIndex mod 2 = 0 then
      AddWarps(GREED_SM_WARP2, 3);
    if AIndex mod 3 = 0 then
      AddWarps(GREED_SM_WARP3, 1);

    // the exit
    if AIndex mod 3 = 1 then
      AddItem(GREED_SM_EXIT, 0, 0);

    // the areas
    for LIndex := 0 to 5 + AIndex mod 8 do
      AddArea(AREA_KINDS[(AIndex + LIndex * 5) mod Length(AREA_KINDS)], Pick(LSeed, 3) <> 0);
    AddArea(0, True);
    AddArea(1, True);
    // corpses and living monsters of the kinds that the areas make
    for LIndex := 1 to 6 do
    begin
      FreeTile(LTileX, LTileY);
      AddSprite(GREED_S_MONSTER1 + 2 * Pick(LSeed, 4), LTileX, LTileY, Pick(LSeed, 2) * 80, 0);
    end;
    if AIndex mod 8 = 3 then
      // too many of them: the area does not make another
      for LIndex := 1 to GREED_MAXSPAWN do
        AddSprite(GREED_S_MONSTER1, FIRST_TILE + LIndex, FIRST_TILE, 50, 0);

    // doors
    for LIndex := 1 to 2 + AIndex mod 4 do
      AddDoor;

    // triggers and switches of the script, on places of the path
    for LIndex := 0 to LPoints.Count - 1 do
      case Pick(LSeed, 12) of
        0:
          Result.Triggers[LPoints[LIndex].TileX * GREED_MAP_SIZE + LPoints[LIndex].TileY] :=
            Byte(1 + Pick(LSeed, 40));
        1, 2:
          begin
            Result.Switches[LPoints[LIndex].TileX * GREED_MAP_SIZE + LPoints[LIndex].TileY] :=
              Byte(1 + Pick(LSeed, 40));
            SwitchWalls(LPoints[LIndex].TileY * GREED_MAP_SIZE + LPoints[LIndex].TileX);
          end;
      end;

    Shuffle;
    Result.Waypoints := LPoints.ToArray;
  finally
    LPoints.Free;
  end;

  // the player
  Result.Player := Default(TGreedPlayerRecord);
  Result.Player.CharType := AIndex mod 5;
  Result.Player.Difficulty := AIndex mod 5;
  Result.Player.Height := 48 * FRACUNIT;
  Result.Player.MaxAngst := 500;
  Result.Player.MaxShield := 500;
  Result.Player.Map := AIndex mod 20;
  Result.Player.LevelScore := Result.LevelScore;
  Result.Player.ScrollMax := 200;
  Result.Player.X := TileCenter(Result.Waypoints[0].TileX);
  Result.Player.Y := TileCenter(Result.Waypoints[0].TileY);
  Result.Player.Z := Result.Player.Height;
  Result.Player.MapSpot := Result.Waypoints[0].TileY * GREED_MAP_SIZE + Result.Waypoints[0].TileX;
  Result.Player.Weapons[0] := AIndex mod 2;
  Result.Player.Weapons[1] := 1 + AIndex mod 3;
  for LSlot := 2 to 4 do
  begin
    Result.Player.Weapons[LSlot] := -1;
    if Pick(LSeed, 2) = 0 then
      for LIndex := 0 to 40 do
      begin
        LWeapon := PickWeapon(LSeed);
        if TGreedGameTables.Weapons[LWeapon].AmmoType = LSlot - 2 then
        begin
          Result.Player.Weapons[LSlot] := LWeapon;
          Break;
        end;
      end;
  end;
  Result.Player.CurrentWeapon := AIndex mod 2;
  case AIndex mod 4 of
    0:
      begin
        // everything full
        Result.Player.Angst := Result.Player.MaxAngst;
        Result.Player.Shield := Result.Player.MaxShield;
        for LIndex := 0 to 2 do
          Result.Player.Ammo[LIndex] := 300;
        Result.Player.Inventory[0] := 20;
        Result.Player.Inventory[1] := 20;
        Result.Player.Inventory[2] := 15;
        for LIndex := 3 to 12 do
          Result.Player.Inventory[LIndex] := 10;
      end;
    1:
      begin
        // hurt and empty
        Result.Player.Angst := 20;
        Result.Player.Shield := 0;
      end;
    2:
      begin
        Result.Player.Angst := 250;
        Result.Player.Shield := Result.Player.MaxShield;
        for LIndex := 0 to 2 do
          Result.Player.Ammo[LIndex] := 290;
        Result.Player.Inventory[0] := 19;
        Result.Player.Inventory[1] := 18;
        Result.Player.Inventory[2] := 13;
        for LIndex := 3 to 12 do
          Result.Player.Inventory[LIndex] := 9;
      end;
  else
    Result.Player.Angst := Result.Player.MaxAngst;
    Result.Player.Shield := Pick(LSeed, 500);
    for LIndex := 0 to 2 do
      Result.Player.Ammo[LIndex] := Pick(LSeed, 301);
    for LIndex := 0 to 12 do
      Result.Player.Inventory[LIndex] := Pick(LSeed, 8);
  end;
end;

end.

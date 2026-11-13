{******************************************************************************}
{                                                                              }
{  DelphiDoom: scenarios of the parity of the logic of the sprites of Greed     }
{                                                                              }
{  The same synthetic levels, sprites and tics run on the original sprites.pas  }
{  (harness Tools\Verifica\175-sprites) and on TGreedSpriteLogic: this unit is  }
{  the part that the two sides share (generator, driver of the tics, the        }
{  behaviour of the stand-ins of SpawnSprite and KillSprite, the trace)         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.SpriteScenarios;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, System.Diagnostics, System.Generics.Collections, DelphiDoom.Greed.Types,
  DelphiDoom.Greed.Actor.Types, DelphiDoom.Greed.World.Intf;

const
  /// <summary>How many scenarios the golden file has</summary>
  SPRITE_SCENARIO_COUNT = 64;
  /// <summary>The driver stops a scenario that makes more sprites than this</summary>
  SPRITE_SCENARIO_MAX_SPRITES = 2500;

type
  TScenarioPlayer = record
    X, Y, Z: Integer;
    Height: Integer;
    Angle: Integer;
    Angst: Integer;
    Difficulty: Integer;
    MapSpot: Integer;
    BodyCount: Integer;
  end;

  /// <summary>A level, its sprites, the player and how many tics to run</summary>
  TSpriteScenario = record
    Index: Integer;
    Planes: array[TGreedPlane] of TBytes;
    MapFlags: TBytes;
    Doors: TArray<TGreedDoor>;
    Sprites: TArray<TGreedSprite>;
    Player: TScenarioPlayer;
    PlayerNum: Integer;
    SpecialEffect: Integer;
    TimeCount: Integer;
    TimeStep: Integer;
    RandomOffset: Integer;
    Tics: Integer;
    Seed: Cardinal;
  end;

  /// <summary>
  ///   Everything that a tic changes or asks, as a sequence of integers: its FNV-1a is the line of the golden
  ///   file; with Labels the values are also written as text, to find the first one that differs
  /// </summary>
  TSpriteTrace = class
  strict private
    FHash: Cardinal;
    FLabels: TStrings;
    FPrefix: string;
    procedure SetPrefix(const AName: string; AIndex: Integer);
  public
    procedure Reset(ALabels: TStrings);
    procedure Add(AValue: Integer; const ALabel: string); overload;
    procedure Add(AValue: Boolean; const ALabel: string); overload;
    /// <summary>ACount bytes, or integers, of an array</summary>
    procedure AddBytes(AFirst: PByte; ACount: Integer; const ALabel: string);
    procedure AddIntegers(AFirst: PInteger; ACount: Integer; const ALabel: string);
    procedure AddSprite(const ASprite: TGreedSprite; AIndex: Integer);
    procedure AddDoor(const ADoor: TGreedDoor; AIndex: Integer);
    procedure AddPlayer(const APlayer: TScenarioPlayer);
    property Hash: Cardinal read FHash;
  end;

  TSpriteFilter = function(const ASprite: TGreedSprite): Boolean;

  /// <summary>
  ///   The tics of a scenario. A side (the original, the library) says how its world is loaded, read and
  ///   changed; the driver between the tics and the behaviour of the stand-ins are here, the same for both
  /// </summary>
  TSpriteScenarioRunner = class
  strict private
    FTrace: TSpriteTrace;
    FThinkTime: TStopwatch;
    function GetThinkMicroseconds: Double;
  protected
    procedure LoadScenario(const AScenario: TSpriteScenario); virtual; abstract;
    /// <summary>A new sprite at the end of the list</summary>
    procedure AppendSprite(const ASprite: TGreedSprite); virtual; abstract;
    /// <summary>Removes, in the order of the list, the sprites that the filter chooses</summary>
    procedure RemoveSprites(AFilter: TSpriteFilter); virtual; abstract;
    function SpriteCount: Integer; virtual; abstract;
    procedure GetPlayer(out APlayer: TScenarioPlayer); virtual; abstract;
    procedure SetPlayer(const APlayer: TScenarioPlayer); virtual; abstract;
    procedure SetGame(ATimeCount, ASpecialEffect: Integer); virtual; abstract;
    /// <summary>
    ///   The copy of a sprite looks for what a shot would hit: SP_Thrust on the probe, at most ASteps times;
    ///   the result and the probe go in the trace
    /// </summary>
    procedure ProbeShot(const ASprite: TGreedSprite; ASteps: Integer); virtual; abstract;
    /// <summary>MoveSprites</summary>
    procedure Think; virtual; abstract;
    /// <summary>Sprites, player, doors, planes, lights, globals of sprites.pas and the random offset</summary>
    procedure TraceState; virtual; abstract;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>
    ///   Runs the tics and appends the hash of each to AHashes. ADumpTic >= 0: the values of that tic are also
    ///   written in ADump
    /// </summary>
    procedure Run(const AScenario: TSpriteScenario; AHashes: TList<Cardinal>; ADumpTic: Integer = -1;
      ADump: TStrings = nil);
    property Trace: TSpriteTrace read FTrace;
    /// <summary>The time spent in Think (MoveSprites alone) by all the runs, in microseconds</summary>
    property ThinkMicroseconds: Double read GetThinkMicroseconds;
    /// <summary>What the stand-in of SpawnSprite makes: a sprite that depends only on the arguments</summary>
    class procedure FillSpawned(out ASprite: TGreedSprite; AValue, AX, AY, AZ, AZAdjust, AAngle, AAngle2: Integer;
      AActive: Boolean; ASpawnId: Integer); static;
    /// <summary>
    ///   What the stand-in of KillSprite does: True, the sprite is removed from the list; False, it stays as
    ///   a corpse (changed in ASprite)
    /// </summary>
    class function ApplyKill(var ASprite: TGreedSprite; AWeapon: Integer): Boolean; static;
  end;

function BuildSpriteScenario(AIndex: Integer): TSpriteScenario;
function ScenarioIsPuff(const ASprite: TGreedSprite): Boolean;
function ScenarioIsFallen(const ASprite: TGreedSprite): Boolean;

implementation

uses
  DelphiDoom.Greed.Game.Constants;

const
  FRACUNIT = GREED_FRACUNIT;
  TILE = GREED_FRACTILEUNIT;
  FIRST_TILE = 3;
  LAST_TILE = 60;
  MONSTER_KINDS: array[0..14] of Integer = (
    GREED_S_MONSTER1, GREED_S_MONSTER2, GREED_S_MONSTER3, GREED_S_MONSTER4, GREED_S_MONSTER5, GREED_S_MONSTER6,
    GREED_S_MONSTER7, GREED_S_MONSTER8, GREED_S_MONSTER9, GREED_S_MONSTER10, GREED_S_MONSTER11, GREED_S_MONSTER12,
    GREED_S_MONSTER13, GREED_S_MONSTER14, GREED_S_MONSTER15);
  MONSTER_MINDS: array[0..5] of Integer = (5, 8, 9, 10, 10, 10);
  BULLET_KINDS: array[0..33] of Integer = (
    GREED_S_BULLET1, GREED_S_BULLET3, GREED_S_BULLET4, GREED_S_BULLET7, GREED_S_BULLET9, GREED_S_BULLET10,
    GREED_S_BULLET11, GREED_S_BULLET12, GREED_S_BULLET16, GREED_S_BULLET17, GREED_S_BULLET18, GREED_S_MINEBULLET,
    GREED_S_HANDBULLET, GREED_S_SOULBULLET, GREED_S_BLOODSPLAT, GREED_S_MONSTERBULLET1, GREED_S_MONSTERBULLET2,
    GREED_S_MONSTERBULLET3, GREED_S_MONSTERBULLET4, GREED_S_MONSTERBULLET5, GREED_S_MONSTERBULLET6,
    GREED_S_MONSTERBULLET7, GREED_S_MONSTERBULLET8, GREED_S_MONSTERBULLET9, GREED_S_MONSTERBULLET10,
    GREED_S_MONSTERBULLET11, GREED_S_MONSTERBULLET12, GREED_S_MONSTERBULLET13, GREED_S_MONSTERBULLET14,
    GREED_S_MONSTERBULLET15, GREED_S_GRENADE, GREED_S_GRENADEBULLET, GREED_S_METALPARTS, GREED_S_SOULBULLET);

function NextRandom(var ASeed: Cardinal): Integer;
begin
  ASeed := ASeed * 1664525 + 1013904223;
  Result := Integer(ASeed shr 8);
end;

function Pick(var ASeed: Cardinal; ACount: Integer): Integer;
begin
  Result := NextRandom(ASeed) mod ACount;
end;

function IsBulletKind(AKind: Integer): Boolean;
begin
  case AKind of
    GREED_S_EXPLODE, GREED_S_EXPLODE2, GREED_S_MINEPUFF, GREED_S_WALLPUFF, GREED_S_PLASMAWALLPUFF,
    GREED_S_GREENPUFF, GREED_S_ARROWPUFF:
      Result := False;
    GREED_S_GRENADE, GREED_S_GRENADEBULLET, GREED_S_METALPARTS:
      Result := True;
  else
    Result := (AKind >= GREED_S_START) and (AKind <= GREED_S_END);
  end;
end;

function ScenarioIsPuff(const ASprite: TGreedSprite): Boolean;
begin
  case ASprite.Kind of
    GREED_S_EXPLODE, GREED_S_EXPLODE2, GREED_S_MINEPUFF, GREED_S_WALLPUFF, GREED_S_PLASMAWALLPUFF,
    GREED_S_GREENPUFF, GREED_S_ARROWPUFF, GREED_S_SMALLEXPLODE:
      Result := True;
  else
    Result := False;
  end;
end;

function ScenarioIsFallen(const ASprite: TGreedSprite): Boolean;
begin
  Result := (ASprite.Kind = GREED_S_BLOODSPLAT) and (ASprite.Intelligence = 128);
end;

{ TSpriteTrace }

procedure TSpriteTrace.Reset(ALabels: TStrings);
begin
  FHash := 2166136261;
  FLabels := ALabels;
  FPrefix := '';
end;

procedure TSpriteTrace.SetPrefix(const AName: string; AIndex: Integer);
begin
  // the names are made only when the values are written as text
  if Assigned(FLabels) then
  begin
    if AName = '' then
      FPrefix := ''
    else
      FPrefix := AName + IntToStr(AIndex);
  end;
end;

procedure TSpriteTrace.AddBytes(AFirst: PByte; ACount: Integer; const ALabel: string);
var
  LIndex: Integer;
begin
  for LIndex := 0 to ACount - 1 do
  begin
    SetPrefix(ALabel, LIndex);
    Add(AFirst^, '');
    Inc(AFirst);
  end;
  SetPrefix('', 0);
end;

procedure TSpriteTrace.AddIntegers(AFirst: PInteger; ACount: Integer; const ALabel: string);
var
  LIndex: Integer;
begin
  for LIndex := 0 to ACount - 1 do
  begin
    SetPrefix(ALabel, LIndex);
    Add(AFirst^, '');
    Inc(AFirst);
  end;
  SetPrefix('', 0);
end;

procedure TSpriteTrace.Add(AValue: Integer; const ALabel: string);
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
    FLabels.Add(FPrefix + ALabel + '=' + IntToStr(AValue));
end;

procedure TSpriteTrace.Add(AValue: Boolean; const ALabel: string);
begin
  Add(Ord(AValue), ALabel);
end;

procedure TSpriteTrace.AddSprite(const ASprite: TGreedSprite; AIndex: Integer);
begin
  SetPrefix('s', AIndex);
  Add(ASprite.Kind, '.typ');
  Add(ASprite.X, '.x');
  Add(ASprite.Y, '.y');
  Add(ASprite.Z, '.z');
  Add(ASprite.Animation, '.animation');
  Add(ASprite.AnimationTime, '.animationTime');
  Add(ASprite.MoveSpeed, '.moveSpeed');
  Add(ASprite.ZAdjust, '.zadj');
  Add(ASprite.LastX, '.lastx');
  Add(ASprite.LastY, '.lasty');
  Add(ASprite.BasePic, '.basepic');
  Add(Ord(ASprite.Rotate), '.rotate');
  Add(ASprite.Angle, '.angle');
  Add(ASprite.Angle2, '.angle2');
  Add(ASprite.MoveSize, '.movesize');
  Add(ASprite.Active, '.active');
  Add(ASprite.NoFalling, '.nofalling');
  Add(ASprite.Intelligence, '.intelligence');
  Add(ASprite.Bullet, '.bullet');
  Add(ASprite.Enraged, '.enraged');
  Add(ASprite.MoveTime, '.movetime');
  Add(ASprite.ModeTime, '.modetime');
  Add(ASprite.ActionTime, '.actiontime');
  Add(ASprite.ScanTime, '.scantime');
  Add(ASprite.FireTime, '.firetime');
  Add(ASprite.Heat, '.heat');
  Add(ASprite.StartPic, '.startpic');
  Add(ASprite.MoveMode, '.movemode');
  Add(ASprite.StartSpot, '.startspot');
  Add(ASprite.Damage, '.damage');
  Add(ASprite.HitPoints, '.hitpoints');
  Add(ASprite.SpawnId, '.spawnid');
  Add(ASprite.Score, '.score');
  Add(ASprite.MaxMove, '.maxmove');
  Add(ASprite.Regen, '.regen');
  Add(ASprite.DeathEvent, '.deathevent');
  Add(ASprite.Height, '.height');
  Add(Ord(ASprite.SpecialType), '.specialtype');
  Add(ASprite.Scale, '.scale');
  Add(ASprite.OldX, '.oldx');
  Add(ASprite.OldY, '.oldy');
  Add(ASprite.OldZ, '.oldz');
  Add(ASprite.OldAngle, '.oldangle');
  Add(ASprite.OldAngle2, '.oldangle2');
  Add(ASprite.OldFloorZ, '.oldfloorz');
  Add(ASprite.NewX, '.newx');
  Add(ASprite.NewY, '.newy');
  Add(ASprite.NewZ, '.newz');
  Add(ASprite.NewAngle, '.newangle');
  Add(ASprite.NewAngle2, '.newangle2');
  Add(ASprite.NewFloorZ, '.newfloorz');
  Add(ASprite.Grounded, '.grounded');
  SetPrefix('', 0);
end;

procedure TSpriteTrace.AddDoor(const ADoor: TGreedDoor; AIndex: Integer);
begin
  SetPrefix('door', AIndex);
  Add(ADoor.TileX, '.tilex');
  Add(ADoor.TileY, '.tiley');
  Add(ADoor.Open, '.open');
  Add(ADoor.Opening, '.opening');
  Add(ADoor.Closing, '.closing');
  Add(ADoor.Blocked, '.blocked');
  Add(ADoor.Bumpable, '.bumpable');
  Add(ADoor.Timer, '.timer');
  Add(Ord(ADoor.Orientation), '.orientation');
  Add(ADoor.Position, '.position');
  SetPrefix('', 0);
end;

procedure TSpriteTrace.AddPlayer(const APlayer: TScenarioPlayer);
begin
  Add(APlayer.X, 'player.x');
  Add(APlayer.Y, 'player.y');
  Add(APlayer.Z, 'player.z');
  Add(APlayer.Height, 'player.height');
  Add(APlayer.Angle, 'player.angle');
  Add(APlayer.Angst, 'player.angst');
  Add(APlayer.Difficulty, 'player.difficulty');
  Add(APlayer.MapSpot, 'player.mapspot');
  Add(APlayer.BodyCount, 'player.bodycount');
end;

{ TSpriteScenarioRunner }

constructor TSpriteScenarioRunner.Create;
begin
  inherited Create;
  FTrace := TSpriteTrace.Create;
  FTrace.Reset(nil);
  FThinkTime := TStopwatch.Create;
end;

function TSpriteScenarioRunner.GetThinkMicroseconds: Double;
begin
  Result := FThinkTime.ElapsedTicks * 1000000.0 / TStopwatch.Frequency;
end;

destructor TSpriteScenarioRunner.Destroy;
begin
  FTrace.Free;
  inherited Destroy;
end;

class procedure TSpriteScenarioRunner.FillSpawned(out ASprite: TGreedSprite; AValue, AX, AY, AZ, AZAdjust, AAngle,
  AAngle2: Integer; AActive: Boolean; ASpawnId: Integer);
begin
  ASprite := Default(TGreedSprite);
  ASprite.Kind := AValue;
  ASprite.X := AX;
  ASprite.Y := AY;
  ASprite.Z := AZ + AZAdjust;
  ASprite.ZAdjust := AZAdjust;
  ASprite.Angle := AAngle and GREED_ANGLES;
  ASprite.Angle2 := AAngle2 and GREED_ANGLES;
  ASprite.Active := AActive;
  ASprite.SpawnId := ASpawnId;
  ASprite.StartSpot := (AY div TILE) * GREED_MAP_SIZE + (AX div TILE);
  ASprite.Scale := 1;
  if not IsBulletKind(AValue) then
    Exit;
  ASprite.Active := True;
  ASprite.MoveSize := (1 + AValue mod 5) * FRACUNIT;
  ASprite.Damage := (AValue * 7) mod 64;
  case AValue mod 4 of
    0: ASprite.Heat := 300;
    1: ASprite.Heat := 90;
  end;
  if AValue mod 3 = 0 then
    ASprite.MaxMove := 25;
  case AValue of
    GREED_S_BLOODSPLAT:
      begin
        ASprite.MoveSpeed := 3;
        ASprite.Angle := ((AX xor AY) shr 9 + AZ shr 12) and GREED_ANGLES;
        ASprite.Angle2 := 200;
        ASprite.MaxMove := 0;
        ASprite.Heat := 0;
      end;
    GREED_S_METALPARTS:
      ASprite.MoveSpeed := 4;
  else
    ASprite.MoveSpeed := 6 + AValue mod 23;
  end;
end;

class function TSpriteScenarioRunner.ApplyKill(var ASprite: TGreedSprite; AWeapon: Integer): Boolean;
begin
  if Odd(AWeapon) then
    Exit(True);
  ASprite.HitPoints := 0;
  ASprite.Intelligence := 255;
  ASprite.Active := False;
  ASprite.MoveSpeed := 0;
  ASprite.BasePic := ASprite.StartPic + 48;
  Result := False;
end;

procedure TSpriteScenarioRunner.Run(const AScenario: TSpriteScenario; AHashes: TList<Cardinal>; ADumpTic: Integer;
  ADump: TStrings);
var
  LTic, LTime, LEffect, LNewX, LNewY, LTileX, LTileY, LKind: Integer;
  LSeed: Cardinal;
  LPlayer: TScenarioPlayer;
  LShot: TGreedSprite;
begin
  LoadScenario(AScenario);
  LSeed := AScenario.Seed;
  LTime := AScenario.TimeCount;
  LEffect := AScenario.SpecialEffect;
  for LTic := 0 to AScenario.Tics - 1 do
  begin
    if LTic = ADumpTic then
      FTrace.Reset(ADump)
    else
      FTrace.Reset(nil);
    // what the renderer and the animations remove in the game
    RemoveSprites(ScenarioIsPuff);
    if LTic mod 16 = 15 then
      RemoveSprites(ScenarioIsFallen);
    if SpriteCount > SPRITE_SCENARIO_MAX_SPRITES then
      Break;
    // the player walks, without collisions, inside the level
    GetPlayer(LPlayer);
    LNewX := LPlayer.X + (Pick(LSeed, 13) - 6) * FRACUNIT;
    LNewY := LPlayer.Y + (Pick(LSeed, 13) - 6) * FRACUNIT;
    LTileX := LNewX div TILE;
    LTileY := LNewY div TILE;
    if (LTileX >= FIRST_TILE + 2) and (LTileX <= LAST_TILE - 2) and (LTileY >= FIRST_TILE + 2) and
      (LTileY <= LAST_TILE - 2) then
    begin
      LPlayer.X := LNewX;
      LPlayer.Y := LNewY;
      LPlayer.MapSpot := LTileY * GREED_MAP_SIZE + LTileX;
      LPlayer.Z := AScenario.Planes[gpFloorHeight][LPlayer.MapSpot] * FRACUNIT + LPlayer.Height;
    end;
    LPlayer.Angle := (LPlayer.Angle + Pick(LSeed, 9) - 4) and GREED_ANGLES;
    if Pick(LSeed, 97) = 0 then
      LPlayer.Angst := 100;
    SetPlayer(LPlayer);
    if Pick(LSeed, 61) = 0 then
      LEffect := LEffect xor GREED_SE_INVISIBILITY;
    // now and then the player shoots
    if Pick(LSeed, 7) = 0 then
    begin
      LKind := BULLET_KINDS[Pick(LSeed, 14)];
      FillSpawned(LShot, LKind, LPlayer.X, LPlayer.Y, LPlayer.Z - LPlayer.Height, 24 * FRACUNIT,
        LPlayer.Angle + Pick(LSeed, 65) - 32, Pick(LSeed, 33) - 16, True, AScenario.PlayerNum);
      if Pick(LSeed, 5) = 0 then
        LShot.SpawnId := 200 + AScenario.PlayerNum;
      AppendSprite(LShot);
    end;
    // ... or only looks at what a shot would hit
    if Pick(LSeed, 5) = 0 then
    begin
      FillSpawned(LShot, GREED_S_BULLET1, LPlayer.X, LPlayer.Y, LPlayer.Z - LPlayer.Height, 24 * FRACUNIT,
        LPlayer.Angle + Pick(LSeed, 129) - 64, Pick(LSeed, 17) - 8, True, AScenario.PlayerNum);
      ProbeShot(LShot, 100 + Pick(LSeed, 400));
    end;
    LTime := LTime + AScenario.TimeStep;
    SetGame(LTime, LEffect);
    FThinkTime.Start;
    Think;
    FThinkTime.Stop;
    TraceState;
    AHashes.Add(FTrace.Hash);
  end;
  FTrace.Reset(nil);
end;

{ the generator }

function TileCenter(ATile: Integer): Integer;
begin
  Result := ATile * TILE + 32 * FRACUNIT;
end;

procedure BuildMap(var AScenario: TSpriteScenario; var ASeed: Cardinal; AFlavor: Integer);
var
  LPlane: TGreedPlane;
  LX, LY, LSpot, LIndex, LCount: Integer;
  LDoor: TGreedDoor;
const
  WALL_FLAGS: array[0..5] of Byte = (0, 0, 0, 1 shl 5, 1 shl 6, 1 shl 4);
begin
  for LPlane := Low(TGreedPlane) to High(TGreedPlane) do
    SetLength(AScenario.Planes[LPlane], GREED_MAP_TILES);
  SetLength(AScenario.MapFlags, GREED_MAP_TILES);
  for LY := 0 to GREED_MAP_SIZE - 1 do
    for LX := 0 to GREED_MAP_SIZE - 1 do
    begin
      LSpot := LY * GREED_MAP_SIZE + LX;
      AScenario.Planes[gpCeilingHeight][LSpot] := 200 + Pick(ASeed, 50);
      AScenario.Planes[gpFloorDef][LSpot] := 56;
      AScenario.Planes[gpCeilingDef][LSpot] := 56;
      if (LX >= FIRST_TILE) and (LX <= LAST_TILE) and (LY >= FIRST_TILE) and (LY <= LAST_TILE) then
      begin
        AScenario.Planes[gpFloorPic][LSpot] := 1 + Pick(ASeed, 40);
        if Pick(ASeed, 40) = 0 then
          AScenario.Planes[gpFloorPic][LSpot] := 57 + Pick(ASeed, 3);
        if Pick(ASeed, 90) = 0 then
          AScenario.Planes[gpFloorPic][LSpot] := 0;
        case Pick(ASeed, 12 + AFlavor) of
          0: AScenario.Planes[gpFloorHeight][LSpot] := 8 + Pick(ASeed, 12);
          1: AScenario.Planes[gpFloorHeight][LSpot] := 20 + Pick(ASeed, 30);
          2: AScenario.Planes[gpFloorHeight][LSpot] := 4;
        end;
        // a few low ceilings
        if Pick(ASeed, 15) = 0 then
          AScenario.Planes[gpCeilingHeight][LSpot] := 50 + Pick(ASeed, 60);
        // sloped and triangulated floors and ceilings (the shapes of mapflags)
        if Pick(ASeed, 25) = 0 then
          AScenario.MapFlags[LSpot] := Pick(ASeed, 4);
        if Pick(ASeed, 50) = 0 then
          AScenario.MapFlags[LSpot] := AScenario.MapFlags[LSpot] or (Pick(ASeed, 4) shl 3);
        AScenario.Planes[gpMapLights][LSpot] := Pick(ASeed, 32);
      end;
    end;
  // the walls around the level: nothing leaves the tiles FIRST_TILE .. LAST_TILE
  for LIndex := 0 to GREED_MAP_SIZE - 1 do
  begin
    AScenario.Planes[gpNorthWall][FIRST_TILE * GREED_MAP_SIZE + LIndex] := 1;
    AScenario.Planes[gpNorthWall][(LAST_TILE + 1) * GREED_MAP_SIZE + LIndex] := 1;
    AScenario.Planes[gpWestWall][LIndex * GREED_MAP_SIZE + FIRST_TILE] := 1;
    AScenario.Planes[gpWestWall][LIndex * GREED_MAP_SIZE + LAST_TILE + 1] := 1;
  end;
  // walls inside, some of which let pass who walks or the bullets
  LCount := 80 + Pick(ASeed, 160);
  for LIndex := 1 to LCount do
  begin
    LSpot := (FIRST_TILE + 1 + Pick(ASeed, LAST_TILE - FIRST_TILE - 1)) * GREED_MAP_SIZE + FIRST_TILE + 1 +
      Pick(ASeed, LAST_TILE - FIRST_TILE - 1);
    if Pick(ASeed, 2) = 0 then
    begin
      AScenario.Planes[gpNorthWall][LSpot] := 1 + Pick(ASeed, 20);
      AScenario.Planes[gpNorthFlags][LSpot] := WALL_FLAGS[Pick(ASeed, 6)];
    end
    else
    begin
      AScenario.Planes[gpWestWall][LSpot] := 1 + Pick(ASeed, 20);
      AScenario.Planes[gpWestFlags][LSpot] := WALL_FLAGS[Pick(ASeed, 6)];
    end;
  end;
  // things on the tiles: solid ones, instawalls, items, a net player, a clone that is not there
  LCount := 10 + Pick(ASeed, 30);
  for LIndex := 1 to LCount do
  begin
    LSpot := (FIRST_TILE + 2 + Pick(ASeed, LAST_TILE - FIRST_TILE - 3)) * GREED_MAP_SIZE + FIRST_TILE + 2 +
      Pick(ASeed, LAST_TILE - FIRST_TILE - 3);
    case Pick(ASeed, 8) of
      0: AScenario.Planes[gpMapSprites][LSpot] := 64;
      1, 2: AScenario.Planes[gpMapSprites][LSpot] := 2 + Pick(ASeed, 60);
      3: AScenario.Planes[gpMapSprites][LSpot] := GREED_SM_CLONE;
      4: AScenario.Planes[gpMapSprites][LSpot] := 1;
    else
      AScenario.Planes[gpMapSprites][LSpot] := 128 + Pick(ASeed, 90);
    end;
  end;
  LCount := 2 + Pick(ASeed, 9);
  if AFlavor = 3 then
    LCount := 28;
  SetLength(AScenario.Doors, LCount);
  for LIndex := 0 to LCount - 1 do
  begin
    LDoor := Default(TGreedDoor);
    LDoor.TileX := FIRST_TILE + 2 + Pick(ASeed, LAST_TILE - FIRST_TILE - 3);
    LDoor.TileY := FIRST_TILE + 2 + Pick(ASeed, LAST_TILE - FIRST_TILE - 3);
    LDoor.Orientation := TGreedDoorOrientation(Pick(ASeed, 4));
    LDoor.Open := Pick(ASeed, 5) = 0;
    LDoor.Opening := Pick(ASeed, 3) = 0;
    LDoor.Closing := Pick(ASeed, 3) = 0;
    LDoor.Bumpable := Pick(ASeed, 4) <> 0;
    LDoor.Timer := Pick(ASeed, 300);
    LDoor.Position := Pick(ASeed, 65) * FRACUNIT;
    AScenario.Doors[LIndex] := LDoor;
    LSpot := LDoor.TileY * GREED_MAP_SIZE + LDoor.TileX;
    AScenario.MapFlags[LSpot] := AScenario.MapFlags[LSpot] or GREED_FL_DOOR;
  end;
end;

function FloorOf(const AScenario: TSpriteScenario; AX, AY: Integer): Integer;
begin
  Result := AScenario.Planes[gpFloorHeight][(AY div TILE) * GREED_MAP_SIZE + (AX div TILE)] * FRACUNIT;
end;

procedure PlaceSprite(var AScenario: TSpriteScenario; var ASeed: Cardinal; var ASprite: TGreedSprite;
  ANearX, ANearY, ASpread: Integer);
var
  LTileX, LTileY: Integer;
begin
  LTileX := ANearX + Pick(ASeed, 2 * ASpread + 1) - ASpread;
  LTileY := ANearY + Pick(ASeed, 2 * ASpread + 1) - ASpread;
  if LTileX < FIRST_TILE + 1 then
    LTileX := FIRST_TILE + 1;
  if LTileX > LAST_TILE - 1 then
    LTileX := LAST_TILE - 1;
  if LTileY < FIRST_TILE + 1 then
    LTileY := FIRST_TILE + 1;
  if LTileY > LAST_TILE - 1 then
    LTileY := LAST_TILE - 1;
  ASprite.X := TileCenter(LTileX) + (Pick(ASeed, 41) - 20) * FRACUNIT + Pick(ASeed, FRACUNIT);
  ASprite.Y := TileCenter(LTileY) + (Pick(ASeed, 41) - 20) * FRACUNIT + Pick(ASeed, FRACUNIT);
  ASprite.Z := FloorOf(AScenario, ASprite.X, ASprite.Y);
end;

function BuildMonster(var AScenario: TSpriteScenario; var ASeed: Cardinal; ANearX, ANearY, ASpread: Integer): TGreedSprite;
begin
  Result := Default(TGreedSprite);
  Result.Kind := MONSTER_KINDS[Pick(ASeed, 15)];
  Result.Intelligence := MONSTER_MINDS[Pick(ASeed, 6)];
  PlaceSprite(AScenario, ASeed, Result, ANearX, ANearY, ASpread);
  Result.MoveSpeed := (1 + Pick(ASeed, 6)) * FRACUNIT + Pick(ASeed, FRACUNIT);
  if Pick(ASeed, 12) = 0 then
    Result.MoveSpeed := 0;
  Result.MoveSize := (14 + Pick(ASeed, 14)) * FRACUNIT;
  Result.Height := (40 + Pick(ASeed, 50)) * FRACUNIT;
  if Pick(ASeed, 4) = 0 then
    Result.ZAdjust := Pick(ASeed, 30) * FRACUNIT;
  Result.Z := Result.Z + Result.ZAdjust + Pick(ASeed, 3) * 10 * FRACUNIT;
  Result.HitPoints := 20 + Pick(ASeed, 400);
  if Pick(ASeed, 6) = 0 then
    Result.HitPoints := 900 + Pick(ASeed, 5000);
  if Pick(ASeed, 15) = 0 then
    Result.HitPoints := 0;
  Result.Bullet := GREED_S_MONSTERBULLET1 + Pick(ASeed, 15);
  Result.Active := Pick(ASeed, 2) = 0;
  Result.NoFalling := Pick(ASeed, 3) = 0;
  Result.Angle := Pick(ASeed, 1024);
  Result.Enraged := Pick(ASeed, 8);
  if Pick(ASeed, 3) <> 0 then
    Result.Enraged := 0;
  Result.StartPic := 100 + Pick(ASeed, 400);
  Result.BasePic := Result.StartPic;
  Result.MoveMode := Pick(ASeed, 10);
  Result.Score := Pick(ASeed, 5000);
  Result.Rotate := grEight;
  Result.Scale := 1;
  if Pick(ASeed, 5) = 0 then
    Result.Heat := 50 + Pick(ASeed, 600);
  if Pick(ASeed, 12) = 0 then
    Result.DeathEvent := 1 + Pick(ASeed, 20);
  Result.MoveTime := Pick(ASeed, 200);
  Result.ScanTime := Pick(ASeed, 60);
  Result.FireTime := Pick(ASeed, 60);
  Result.ModeTime := Pick(ASeed, 60);
  Result.ActionTime := Pick(ASeed, 60);
  Result.LastX := Result.X;
  Result.LastY := Result.Y;
  Result.StartSpot := -1;
end;

function BuildBullet(var AScenario: TSpriteScenario; var ASeed: Cardinal; ANearX, ANearY, ASpread: Integer): TGreedSprite;
const
  SPAWN_IDS: array[0..4] of Integer = (0, 1, 255, 200, 201);
var
  LZAdjust, LAngle, LAngle2, LSpawnId, LKind: Integer;
begin
  Result := Default(TGreedSprite);
  PlaceSprite(AScenario, ASeed, Result, ANearX, ANearY, ASpread);
  // the draws in the order of the 32 bit compiler, which evaluates the parameters of the stack from the left and then
  // those of the registers from the right (the 64 bit one goes from the left): the kind, in a register, is last
  LZAdjust := (10 + Pick(ASeed, 60)) * FRACUNIT;
  LAngle := Pick(ASeed, 1024);
  LAngle2 := Pick(ASeed, 81) - 40;
  LSpawnId := SPAWN_IDS[Pick(ASeed, 5)];
  LKind := BULLET_KINDS[Pick(ASeed, 34)];
  TSpriteScenarioRunner.FillSpawned(Result, LKind, Result.X, Result.Y, Result.Z, LZAdjust, LAngle, LAngle2, True,
    LSpawnId);
  if Pick(ASeed, 3) = 0 then
    Result.StartSpot := -1;
  if Pick(ASeed, 4) = 0 then
    Result.Damage := 51 + Pick(ASeed, 60);
  if Pick(ASeed, 6) = 0 then
    Result.Damage := 0;
  if Pick(ASeed, 4) = 0 then
    Result.MaxMove := 1 + Pick(ASeed, 40);
  if Pick(ASeed, 10) = 0 then
    Result.Angle2 := Pick(ASeed, 1024);
  if Pick(ASeed, 9) = 0 then
    Result.Active := False;
  Result.NewFloorZ := FloorOf(AScenario, Result.X, Result.Y);
end;

function BuildOther(var AScenario: TSpriteScenario; var ASeed: Cardinal; ANearX, ANearY, ASpread: Integer): TGreedSprite;
begin
  Result := Default(TGreedSprite);
  PlaceSprite(AScenario, ASeed, Result, ANearX, ANearY, ASpread);
  Result.Active := Pick(ASeed, 4) <> 0;
  Result.MoveSpeed := FRACUNIT;
  Result.Scale := 1;
  Result.SpawnId := Pick(ASeed, 2);
  Result.ActionTime := Pick(ASeed, 150);
  Result.Angle := Pick(ASeed, 1024);
  case Pick(ASeed, 10) of
    0, 1:
      begin
        // a clone of the player
        Result.Kind := GREED_S_CLONE;
        Result.Active := Pick(ASeed, 2) = 0;
        Result.Intelligence := 7;
        Result.MoveSpeed := (2 + Pick(ASeed, 4)) * FRACUNIT;
        Result.MoveSize := 16 * FRACUNIT;
        Result.Height := 60 * FRACUNIT;
        Result.HitPoints := 50 + Pick(ASeed, 200);
        Result.Bullet := GREED_S_BULLET1 + Pick(ASeed, 12);
        Result.StartPic := 300;
        Result.BasePic := 300;
        Result.MoveTime := Pick(ASeed, 100);
        Result.StartSpot := -1;
      end;
    2, 3:
      begin
        Result.Kind := GREED_S_PROXMINE;
        Result.Intelligence := 6;
      end;
    4:
      begin
        Result.Kind := GREED_S_TIMEMINE;
        Result.Intelligence := 6;
      end;
    5:
      begin
        Result.Kind := GREED_S_INSTAWALL;
        Result.Intelligence := 6;
        AScenario.Planes[gpMapSprites][(Result.Y div TILE) * GREED_MAP_SIZE + (Result.X div TILE)] := 64;
      end;
    6:
      begin
        // something that fell and lies down
        Result.Kind := GREED_S_BLOODSPLAT;
        Result.Intelligence := 128;
        Result.Z := Result.Z + Pick(ASeed, 60) * FRACUNIT - 5 * FRACUNIT;
      end;
    7:
      begin
        // a net player that stands on its tile
        Result.Kind := GREED_S_NETPLAYER;
        Result.Intelligence := 255;
        Result.MoveSpeed := 0;
        Result.HitPoints := 100;
        Result.Height := 60 * FRACUNIT;
        AScenario.Planes[gpMapSprites][(Result.Y div TILE) * GREED_MAP_SIZE + (Result.X div TILE)] :=
          GREED_SM_NETPLAYER;
      end;
    8:
      begin
        // an item that glows and does nothing, or a mind that the game does not have
        Result.Kind := 150 + Pick(ASeed, 40);
        Result.Intelligence := 1 + Pick(ASeed, 3);
        Result.Heat := 100 + Pick(ASeed, 500);
      end;
  else
    begin
      Result.Kind := 150 + Pick(ASeed, 40);
      Result.Intelligence := 255;
      Result.Active := False;
      Result.Heat := Pick(ASeed, 400);
      Result.HitPoints := Pick(ASeed, 2) * 40;
      Result.Height := 40 * FRACUNIT;
    end;
  end;
end;

function BuildSpriteScenario(AIndex: Integer): TSpriteScenario;
var
  LSeed: Cardinal;
  LFlavor, LCount, LIndex, LPlayerX, LPlayerY, LNearX, LNearY, LSpread, LChoice: Integer;
  LSprite: TGreedSprite;
begin
  Result := Default(TSpriteScenario);
  Result.Index := AIndex;
  LSeed := Cardinal(20261112 + AIndex * 7919);
  LFlavor := AIndex mod 6;
  BuildMap(Result, LSeed, LFlavor);
  LPlayerX := FIRST_TILE + 8 + Pick(LSeed, LAST_TILE - FIRST_TILE - 16);
  LPlayerY := FIRST_TILE + 8 + Pick(LSeed, LAST_TILE - FIRST_TILE - 16);
  Result.Player.X := TileCenter(LPlayerX);
  Result.Player.Y := TileCenter(LPlayerY);
  Result.Player.MapSpot := LPlayerY * GREED_MAP_SIZE + LPlayerX;
  Result.Player.Height := (40 + Pick(LSeed, 30)) * FRACUNIT;
  Result.Player.Z := Result.Planes[gpFloorHeight][Result.Player.MapSpot] * FRACUNIT + Result.Player.Height;
  Result.Player.Angle := Pick(LSeed, 1024);
  Result.Player.Angst := 100;
  if Pick(LSeed, 8) = 0 then
    Result.Player.Angst := 0;
  Result.Player.Difficulty := Pick(LSeed, 5);
  Result.PlayerNum := Pick(LSeed, 2);
  if Pick(LSeed, 8) = 0 then
    Result.SpecialEffect := GREED_SE_INVISIBILITY;
  Result.TimeCount := Pick(LSeed, 400);
  Result.TimeStep := 1 + Pick(LSeed, 3);
  Result.RandomOffset := Pick(LSeed, 5000);
  Result.Tics := 150 + Pick(LSeed, 150);
  LCount := 20 + Pick(LSeed, 41);
  // most of the sprites are around the player, where things happen
  LSpread := 4 + Pick(LSeed, 12);
  SetLength(Result.Sprites, LCount);
  for LIndex := 0 to LCount - 1 do
  begin
    if Pick(LSeed, 5) = 0 then
    begin
      LNearX := FIRST_TILE + Pick(LSeed, LAST_TILE - FIRST_TILE);
      LNearY := FIRST_TILE + Pick(LSeed, LAST_TILE - FIRST_TILE);
    end
    else
    begin
      LNearX := LPlayerX;
      LNearY := LPlayerY;
    end;
    LChoice := Pick(LSeed, 10);
    case LFlavor of
      1: // mostly bullets
        if LChoice < 6 then
          LChoice := 9;
      2: // mostly monsters
        if LChoice > 6 then
          LChoice := 0;
      4: // mines, clones and the rest
        if LChoice < 5 then
          LChoice := 7;
    end;
    case LChoice of
      0..4:
        LSprite := BuildMonster(Result, LSeed, LNearX, LNearY, LSpread);
      5..6, 9:
        LSprite := BuildBullet(Result, LSeed, LNearX, LNearY, LSpread);
    else
      LSprite := BuildOther(Result, LSeed, LNearX, LNearY, LSpread);
    end;
    Result.Sprites[LIndex] := LSprite;
  end;
  Result.Seed := LSeed;
end;

end.

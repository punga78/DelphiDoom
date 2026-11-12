{******************************************************************************}
{                                                                              }
{  DelphiDoom: the scenarios of the sprites of Greed run on TGreedSpriteLogic   }
{                                                                              }
{  The side of the library of the parity with sprites.pas: the world, the pool  }
{  and the stand-ins of the rest of the game (SpawnSprite, KillSprite, sounds,  }
{  hurt ...), which write what they are asked in the trace of the scenario      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.SpriteRunner;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.Greed.Types, DelphiDoom.Greed.Actor.Types,
  DelphiDoom.Greed.World.Intf, DelphiDoom.Greed.LinkedPool, DelphiDoom.Greed.Random, DelphiDoom.Greed.Game.Intf,
  DelphiDoom.Greed.Game.State, DelphiDoom.Greed.SpriteLogic.Intf, DelphiDoom.Greed.SpriteLogic,
  DelphiDoom.Tests.Greed.SpriteScenarios;

type
  /// <summary>
  ///   The rest of the game for the logic of the sprites: every call is written in the trace, a spawned sprite
  ///   is the one of TSpriteScenarioRunner.FillSpawned, a killed one is removed or left as a corpse
  ///   (ApplyKill), a hurt player loses angst
  /// </summary>
  TFakeSpriteGame = class(TInterfacedObject, IGreedSpawner, IGreedGameSound, IGreedPlayerHealth,
    IGreedSpriteKiller, IGreedSpriteHost)
  strict private
    FState: TGreedGameState;
    FTrace: TSpriteTrace;
    FSpawnCount: Integer;
    FSoundCount: Integer;
    FKillCount: Integer;
    FHurtTotal: Integer;
    FLastSound: Integer;
    FLastSpawn: Integer;
    FRefuseSpawns: Boolean;
  public
    constructor Create(AState: TGreedGameState; ATrace: TSpriteTrace);
    function SpawnSprite(AValue: Integer; AX, AY, AZ, AZAdjust: TGreedFixed; AAngle, AAngle2: Integer;
      AActive: Boolean; ASpawnId: Integer): Integer;
    procedure DemandLoadMonster(ALump, ACount: Integer);
    procedure SoundEffect(ASound, AVariation: Integer; AX, AY: TGreedFixed);
    procedure Hurt(AAmount: Integer);
    procedure Heal(AAmount: Integer);
    procedure MedPaks(AAmount: Integer);
    procedure AddScore(AAmount: Integer);
    procedure KillSprite(ASprite, AWeapon: Integer);
    function ThrustPlayer(AAngle: Integer; ASpeed: TGreedFixed): Boolean;
    property SpawnCount: Integer read FSpawnCount;
    property SoundCount: Integer read FSoundCount;
    property KillCount: Integer read FKillCount;
    property HurtTotal: Integer read FHurtTotal;
    property LastSound: Integer read FLastSound;
    property LastSpawn: Integer read FLastSpawn;
    /// <summary>SpawnSprite answers GREED_POOL_NIL (what the original does when it makes no sprite)</summary>
    property RefuseSpawns: Boolean read FRefuseSpawns write FRefuseSpawns;
  end;

  /// <summary>A level in memory with everything the logic needs, for the tests and for the scenarios</summary>
  TLibrarySpriteRunner = class(TSpriteScenarioRunner)
  strict private
    FWorld: IGreedWorld;
    FSprites: TGreedLinkedPool<TGreedSprite>;
    FElevators: TGreedLinkedPool<TGreedElevator>;
    FState: TGreedGameState;
    FRandom: TGreedRandomTable;
    FRandomIntf: IGreedRandom;
    FGame: TFakeSpriteGame;
    FGameIntf: IInterface;
    FLogic: TGreedSpriteLogic;
    procedure Release;
  protected
    procedure LoadScenario(const AScenario: TSpriteScenario); override;
    procedure AppendSprite(const ASprite: TGreedSprite); override;
    procedure RemoveSprites(AFilter: TSpriteFilter); override;
    function SpriteCount: Integer; override;
    procedure GetPlayer(out APlayer: TScenarioPlayer); override;
    procedure SetPlayer(const APlayer: TScenarioPlayer); override;
    procedure SetGame(ATimeCount, ASpecialEffect: Integer); override;
    procedure Think; override;
    procedure TraceState; override;
  public
    destructor Destroy; override;
    /// <summary>An empty level: floor everywhere, no walls, no sprites, the player on the tile (10, 10)</summary>
    procedure LoadEmpty;
    /// <summary>A new sprite at the end of the list; the index in the pool</summary>
    function Add(const ASprite: TGreedSprite): Integer;
    property World: IGreedWorld read FWorld;
    property Sprites: TGreedLinkedPool<TGreedSprite> read FSprites;
    property State: TGreedGameState read FState;
    property Random: TGreedRandomTable read FRandom;
    property Game: TFakeSpriteGame read FGame;
    property Logic: TGreedSpriteLogic read FLogic;
  end;

implementation

uses
  DelphiDoom.Greed.World;

{ TFakeSpriteGame }

constructor TFakeSpriteGame.Create(AState: TGreedGameState; ATrace: TSpriteTrace);
begin
  inherited Create;
  FState := AState;
  FTrace := ATrace;
  FLastSound := -1;
  FLastSpawn := GREED_POOL_NIL;
end;

function TFakeSpriteGame.SpawnSprite(AValue: Integer; AX, AY, AZ, AZAdjust: TGreedFixed; AAngle, AAngle2: Integer;
  AActive: Boolean; ASpawnId: Integer): Integer;
begin
  FTrace.Add(AValue, 'spawn.value');
  FTrace.Add(AX, 'spawn.x');
  FTrace.Add(AY, 'spawn.y');
  FTrace.Add(AZ, 'spawn.z');
  FTrace.Add(AZAdjust, 'spawn.zadj');
  FTrace.Add(AAngle, 'spawn.angle');
  FTrace.Add(AAngle2, 'spawn.angle2');
  FTrace.Add(AActive, 'spawn.active');
  FTrace.Add(ASpawnId, 'spawn.spawnid');
  Inc(FSpawnCount);
  if FRefuseSpawns then
    Exit(GREED_POOL_NIL);
  Result := FState.Sprites.Add;
  TSpriteScenarioRunner.FillSpawned(FState.Sprites.Item(Result)^, AValue, AX, AY, AZ, AZAdjust, AAngle, AAngle2,
    AActive, ASpawnId);
  FLastSpawn := Result;
end;

procedure TFakeSpriteGame.DemandLoadMonster(ALump, ACount: Integer);
begin
  // the logic of the sprites does not ask for pictures
end;

procedure TFakeSpriteGame.SoundEffect(ASound, AVariation: Integer; AX, AY: TGreedFixed);
begin
  FTrace.Add(ASound, 'sound.n');
  FTrace.Add(AVariation, 'sound.variation');
  FTrace.Add(AX, 'sound.x');
  FTrace.Add(AY, 'sound.y');
  Inc(FSoundCount);
  FLastSound := ASound;
end;

procedure TFakeSpriteGame.Hurt(AAmount: Integer);
begin
  FTrace.Add(AAmount, 'hurt');
  FHurtTotal := FHurtTotal + AAmount;
  FState.Player.Angst := FState.Player.Angst - AAmount;
  if FState.Player.Angst < 0 then
    FState.Player.Angst := 0;
end;

procedure TFakeSpriteGame.Heal(AAmount: Integer);
begin
  FTrace.Add(AAmount, 'heal');
end;

procedure TFakeSpriteGame.MedPaks(AAmount: Integer);
begin
  FTrace.Add(AAmount, 'medpaks');
end;

procedure TFakeSpriteGame.AddScore(AAmount: Integer);
begin
  FTrace.Add(AAmount, 'addscore');
end;

procedure TFakeSpriteGame.KillSprite(ASprite, AWeapon: Integer);
var
  LSprite: PGreedSprite;
begin
  LSprite := PGreedSprite(FState.Sprites.Item(ASprite));
  FTrace.Add(LSprite^.Kind, 'kill.typ');
  FTrace.Add(LSprite^.X, 'kill.x');
  FTrace.Add(LSprite^.Y, 'kill.y');
  FTrace.Add(AWeapon, 'kill.weapon');
  Inc(FKillCount);
  if TSpriteScenarioRunner.ApplyKill(LSprite^, AWeapon) then
    FState.Sprites.Remove(ASprite);
end;

function TFakeSpriteGame.ThrustPlayer(AAngle: Integer; ASpeed: TGreedFixed): Boolean;
begin
  FTrace.Add(AAngle, 'thrust.angle');
  FTrace.Add(ASpeed, 'thrust.speed');
  Result := False;
end;

{ TLibrarySpriteRunner }

destructor TLibrarySpriteRunner.Destroy;
begin
  Release;
  inherited Destroy;
end;

procedure TLibrarySpriteRunner.Release;
begin
  FreeAndNil(FLogic);
  FGame := nil;
  FGameIntf := nil;
  FRandom := nil;
  FRandomIntf := nil;
  FreeAndNil(FState);
  FreeAndNil(FSprites);
  FreeAndNil(FElevators);
  FWorld := nil;
end;

procedure TLibrarySpriteRunner.LoadScenario(const AScenario: TSpriteScenario);
var
  LPlane: TGreedPlane;
  LSpot, LIndex: Integer;
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
  FSprites := TGreedLinkedPool<TGreedSprite>.Create(GREED_MAX_SPRITES, 'sprites');
  FElevators := TGreedLinkedPool<TGreedElevator>.Create(GREED_MAX_ELEVATORS, 'elevators');
  FState := TGreedGameState.Create(FWorld, FSprites, FElevators);
  FState.PlayerNum := AScenario.PlayerNum;
  FState.SpecialEffect := AScenario.SpecialEffect;
  FState.TimeCount := AScenario.TimeCount;
  SetPlayer(AScenario.Player);
  FRandom := TGreedRandomTable.Create;
  FRandomIntf := FRandom;
  FRandom.Offset := AScenario.RandomOffset;
  FGame := TFakeSpriteGame.Create(FState, Trace);
  FGameIntf := FGame;
  FLogic := TGreedSpriteLogic.Create(FState, FGame, FRandomIntf, FGame, FGame, FGame, FGame);
  for LIndex := 0 to High(AScenario.Sprites) do
    AppendSprite(AScenario.Sprites[LIndex]);
end;

procedure TLibrarySpriteRunner.LoadEmpty;
var
  LScenario: TSpriteScenario;
  LPlane: TGreedPlane;
  LSpot: Integer;
begin
  LScenario := Default(TSpriteScenario);
  for LPlane := Low(TGreedPlane) to High(TGreedPlane) do
    SetLength(LScenario.Planes[LPlane], GREED_MAP_TILES);
  SetLength(LScenario.MapFlags, GREED_MAP_TILES);
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
  LScenario.Player.Angst := 100;
  LoadScenario(LScenario);
end;

function TLibrarySpriteRunner.Add(const ASprite: TGreedSprite): Integer;
begin
  Result := FSprites.Add;
  FSprites.Item(Result)^ := ASprite;
end;

procedure TLibrarySpriteRunner.AppendSprite(const ASprite: TGreedSprite);
begin
  Add(ASprite);
end;

procedure TLibrarySpriteRunner.RemoveSprites(AFilter: TSpriteFilter);
var
  LIndex, LNext: Integer;
begin
  LIndex := FSprites.First;
  while LIndex <> GREED_POOL_NIL do
  begin
    LNext := FSprites.Next(LIndex);
    if AFilter(FSprites.Item(LIndex)^) then
      FSprites.Remove(LIndex);
    LIndex := LNext;
  end;
end;

function TLibrarySpriteRunner.SpriteCount: Integer;
begin
  Result := FSprites.Count;
end;

procedure TLibrarySpriteRunner.GetPlayer(out APlayer: TScenarioPlayer);
begin
  APlayer.X := FState.Player.X;
  APlayer.Y := FState.Player.Y;
  APlayer.Z := FState.Player.Z;
  APlayer.Height := FState.Player.Height;
  APlayer.Angle := FState.Player.Angle;
  APlayer.Angst := FState.Player.Angst;
  APlayer.Difficulty := FState.Player.Difficulty;
  APlayer.MapSpot := FState.Player.MapSpot;
  APlayer.BodyCount := FState.Player.BodyCount;
end;

procedure TLibrarySpriteRunner.SetPlayer(const APlayer: TScenarioPlayer);
begin
  FState.Player.X := APlayer.X;
  FState.Player.Y := APlayer.Y;
  FState.Player.Z := APlayer.Z;
  FState.Player.Height := APlayer.Height;
  FState.Player.Angle := APlayer.Angle;
  FState.Player.Angst := APlayer.Angst;
  FState.Player.Difficulty := APlayer.Difficulty;
  FState.Player.MapSpot := APlayer.MapSpot;
  FState.Player.BodyCount := APlayer.BodyCount;
end;

procedure TLibrarySpriteRunner.SetGame(ATimeCount, ASpecialEffect: Integer);
begin
  FState.TimeCount := ATimeCount;
  FState.SpecialEffect := ASpecialEffect;
end;

procedure TLibrarySpriteRunner.Think;
begin
  FLogic.MoveSprites;
end;

procedure TLibrarySpriteRunner.TraceState;
var
  LIndex, LNumber: Integer;
  LPlayer: TScenarioPlayer;
  LTiles: array[0..GREED_MAP_TILES - 1] of Byte;
begin
  Trace.Add(FSprites.Count, 'sprites');
  LNumber := 0;
  LIndex := FSprites.First;
  while LIndex <> GREED_POOL_NIL do
  begin
    Trace.AddSprite(FSprites.Item(LIndex)^, LNumber);
    Inc(LNumber);
    LIndex := FSprites.Next(LIndex);
  end;
  GetPlayer(LPlayer);
  Trace.AddPlayer(LPlayer);
  Trace.Add(FState.PlayerAngle64, 'player_angle64');
  Trace.Add(FState.SpriteHit, 'spritehit');
  Trace.Add(FState.PlayerHit, 'playerhit');
  Trace.Add(FState.HitX, 'hitx');
  Trace.Add(FState.HitY, 'hity');
  Trace.Add(FState.TargX, 'targx');
  Trace.Add(FState.TargY, 'targy');
  Trace.Add(FState.TargZ, 'targz');
  Trace.Add(FState.SpriteLoc, 'spriteloc');
  Trace.Add(FWorld.DoorCount, 'doors');
  for LIndex := 0 to FWorld.DoorCount - 1 do
    Trace.AddDoor(FWorld.GetDoor(LIndex), LIndex);
  FWorld.CopyPlane(gpMapSprites, @LTiles[0]);
  Trace.AddBytes(@LTiles[0], GREED_MAP_TILES, 'mapsprites');
  Trace.AddIntegers(@FLogic.RealLight^[0], GREED_MAP_TILES, 'reallight');
  Trace.Add(FRandom.Offset, 'rndofs');
end;

end.

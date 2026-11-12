{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the state of a game that is being played         }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): the globals of raven.pas,   }
{  utils.pas, sprites.pas, event.pas and r_public.pas that the logic shares     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Game.State;

interface

uses
  System.SysUtils, DelphiDoom.Greed.Types, DelphiDoom.Greed.SaveTypes, DelphiDoom.Greed.Actor.Types,
  DelphiDoom.Greed.LinkedPool, DelphiDoom.Greed.World.Intf, DelphiDoom.Greed.Game.Constants,
  DelphiDoom.Greed.Game.Tables;

const
  /// <summary>MAXZONES and MAXPROCESS of event.pas</summary>
  GREED_MAX_ZONES = 255;
  GREED_MAX_PROCESSES = 128;
  /// <summary>SECRETBUFSIZE</summary>
  GREED_SECRET_BUFFER_SIZE = 20;

type
  /// <summary>bonus_t: the bonus item that appears on the map for a while</summary>
  TGreedBonusItem = record
    Time: Integer;
    Score: Integer;
    Name: string;
    TileX: Integer;
    TileY: Integer;
    MapSpot: Integer;
    Num: Integer;
    /// <summary>The index of its sprite in the pool, GREED_POOL_NIL if there is none</summary>
    Sprite: Integer;
  end;

  /// <summary>zone_t of event.pas: a line of the script of the map</summary>
  TGreedZone = record
    X1, Y1, X2, Y2: Integer;
    Eval, EndEval: Integer;
    Rate, Layer, NewValue, SType, Removeable: Integer;
    Kind: Integer;
  end;

  TGreedTileBytes = array[0..GREED_MAP_TILES - 1] of Byte;

  /// <summary>
  ///   The variables that the original keeps in the globals of its game units, for one game: the player, the clocks,
  ///   the modes, the weapons, what the last shot hit, the script of the map. The classes of the logic (spawner,
  ///   sprites, player, events) share one object of this kind, the world and the two pools, and talk to each other
  ///   through the interfaces of DelphiDoom.Greed.Game.Intf. The fields are public and have the names of the
  ///   original, as in TGreedRenderState: the logic is a port line by line and reads them in the loops of the
  ///   sprites. A pointer to a sprite of the original is here the index in the pool (GREED_POOL_NIL = nil). The net
  ///   game is not ported: NetMode stays false
  /// </summary>
  TGreedGameState = class
  public
    // ---- what the game is made of (not owned) ----
    World: IGreedWorld;
    Sprites: TGreedLinkedPool<TGreedSprite>;
    Elevators: TGreedLinkedPool<TGreedElevator>;

    // ---- raven.pas ----
    Player: TGreedPlayerRecord;
    /// <summary>player_angle64</summary>
    PlayerAngle64: Integer;
    /// <summary>timecount: the tics of the game (70 a second)</summary>
    TimeCount: Integer;
    Frames: Integer;
    WeapDelay, SpriteMoveTime, SecretDelay, InventoryDelay, UseDelay, JumpDelay: Integer;
    KeyboardDelay: Integer;
    RearViewTime, RearViewDelay, InventoryTime: Integer;
    ChangingWeapons: Boolean;
    WeaponLowering: Boolean;
    QuitGame: Boolean;
    ToggleMapMode: Boolean;
    ToggleHeatMode: Boolean;
    HeatMode: Boolean;
    GodMode: Boolean;
    ToggleMotionMode: Boolean;
    MotionMode: Boolean;
    HurtBorder: Boolean;
    ActivateMenu: Boolean;
    DebugMode: Boolean;
    GameLoaded: Boolean;
    NoSpawn: Boolean;
    DoorSound: Boolean;
    DeadRestart: Boolean;
    Ticker: Boolean;
    ToggleGoalItem: Boolean;
    WaterDrop: Boolean;
    GamePause: Boolean;
    ExitLevel: Boolean;
    ExitExists: Boolean;
    WarpJammer: Boolean;
    Paused: Boolean;
    QuickExit: Boolean;
    AutoRun: Boolean;
    ToggleRearView: Boolean;
    RearViewOn: Boolean;
    CheckTrigger: Boolean;
    ActivateHelp: Boolean;
    UseItem: Boolean;
    ToggleAutoRun: Boolean;
    GoIRight: Boolean;
    GoILeft: Boolean;
    ActivateBrief: Boolean;
    MidgetMode: Boolean;
    AutoTarget: Boolean;
    ToggleAutoTarget: Boolean;
    WeapMode: Integer;
    NewWeapon: Integer;
    WeaponYChange: Integer;
    HeadBob: Integer;
    HeadBobOn: Boolean;
    WeapBob: Integer;
    WeapBobOn: Boolean;
    MoveForward: Integer;
    ChangeLight: Integer;
    Lighting: Integer;
    TurnRate: Integer;
    MapMode: Integer;
    ScrollView: Integer;
    DoorX: Integer;
    DoorY: Integer;
    MapZoom: Integer;
    Warping: Integer;
    GoalItem: Integer;
    SpecialEffect: Integer;
    FallDamage: Integer;
    WallAnimCount: Integer;
    PlayerTurnSpeed: Integer;
    TurnUnit: Integer;
    ExitX: Integer;
    ExitY: Integer;
    SongNum: Integer;
    EnemyViewMode: Integer;
    MoveRate, StrafRate, FallRate, WarpX, WarpY: TGreedFixed;
    NetMode: Boolean;
    WallAnimationTime: Integer;
    SpecialEffectTime: Integer;
    SwitchTime: Integer;
    SecretBuf: string;
    BonusItem: TGreedBonusItem;
    NewSong: Boolean;
    /// <summary>weapons of constant.pas: the copy of the game (the charge changes)</summary>
    Weapons: array[0..18] of TGreedWeaponInfo;
    /// <summary>slumps: the lump of each sprite that the game makes (GREED_S_START .. GREED_S_END)</summary>
    SpriteLumps: array[0..GREED_S_END - GREED_S_START] of Integer;
    /// <summary>playernum and greedcom.numplayers of the net game: 1 and 1 in a game of one player</summary>
    PlayerNum: Integer;
    NumPlayers: Integer;
    /// <summary>DEMO, GAME1 .. GAME3 and ASSASSINATOR of constant.pas</summary>
    Demo: Boolean;
    Game1, Game2, Game3: Boolean;
    Assassinator: Boolean;

    // ---- utils.pas ----
    Primaries: array[0..3] of Integer;
    Secondaries: array[0..13] of Integer;
    PCount: array[0..1] of Integer;
    SCount: array[0..6] of Integer;
    BonusTime: Integer;
    LevelScore: Integer;
    GameLoading, EventLoading: Boolean;
    StartLocations: array[0..GREED_MAXSTARTLOCATIONS - 1, 0..1] of Integer;

    // ---- sprites.pas ----
    /// <summary>msprite: the sprite that is thinking</summary>
    MSprite: Integer;
    /// <summary>probe: the copy of a sprite that looks for what a shot hits</summary>
    Probe: TGreedSprite;
    SpriteHit, PlayerHit: Boolean;
    HitX, HitY, TargX, TargY, TargZ: TGreedFixed;
    /// <summary>spriteloc: the tile where a sprite was hit</summary>
    SpriteLoc: Integer;

    // ---- event.pas ----
    Triggers: TGreedTileBytes;
    Switches: TGreedTileBytes;
    Processes: array[0..GREED_MAX_PROCESSES - 1] of Integer;
    NumProcesses, NumZones, FliPlayed: Integer;
    Zones: array[0..GREED_MAX_ZONES - 1] of TGreedZone;

    /// <summary>
    ///   The values that the original gives to its globals where they are declared (autotarget, headbobon,
    ///   weapbobon, playerturnspeed 8, turnunit 2, GAME1) and one player; the rest is zero. The world and the pools
    ///   are the ones of the level and are not owned
    /// </summary>
    constructor Create(const AWorld: IGreedWorld; const ASprites: TGreedLinkedPool<TGreedSprite>;
      const AElevators: TGreedLinkedPool<TGreedElevator>);
    /// <summary>The copy of the table of the weapons as it is when the program starts</summary>
    procedure ResetWeapons;
  end;

implementation

{ TGreedGameState }

constructor TGreedGameState.Create(const AWorld: IGreedWorld; const ASprites: TGreedLinkedPool<TGreedSprite>;
  const AElevators: TGreedLinkedPool<TGreedElevator>);
begin
  inherited Create;
  if not Assigned(AWorld) then
    raise EArgumentNilException.Create('AWorld');
  if not Assigned(ASprites) then
    raise EArgumentNilException.Create('ASprites');
  if not Assigned(AElevators) then
    raise EArgumentNilException.Create('AElevators');
  World := AWorld;
  Sprites := ASprites;
  Elevators := AElevators;
  AutoTarget := True;
  HeadBobOn := True;
  WeapBobOn := True;
  PlayerTurnSpeed := TGreedGameTables.DefaultPlayerTurnSpeed;
  TurnUnit := TGreedGameTables.DefaultTurnUnit;
  Game1 := True;
  NumPlayers := 1;
  MSprite := GREED_POOL_NIL;
  BonusItem.Sprite := GREED_POOL_NIL;
  ResetWeapons;
end;

procedure TGreedGameState.ResetWeapons;
var
  LIndex: Integer;
begin
  for LIndex := Low(Weapons) to High(Weapons) do
    Weapons[LIndex] := TGreedGameTables.Weapons[LIndex];
end;

end.

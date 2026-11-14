{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - what the model works on                           }
{                                                                              }
{  Port of war1 (acoto87/war1), the parts of WarContext and WarMap that the    }
{  entities and their states use, (c) 2019 Alejandro Coto Gutierrez, zlib      }
{  License (see Libs\War\LICENSE-war1.txt). This is an altered version.        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.Context;

interface

uses
  System.SysUtils, DelphiDoom.War.Level.Types, DelphiDoom.War.Map.Types, DelphiDoom.War.Sound.Intf,
  DelphiDoom.War.Model.Types, DelphiDoom.War.Model.Stats.Types, DelphiDoom.War.Model.Intf,
  DelphiDoom.War.Model.Combat.Intf, DelphiDoom.War.Model.EntityPool,
  DelphiDoom.War.Model.StateStorage, DelphiDoom.War.Model.GatherWorld, DelphiDoom.War.Model.Construction.Intf,
  DelphiDoom.War.Model.Walls, DelphiDoom.War.Autotile.Ruins, DelphiDoom.War.Autotile.Line,
  DelphiDoom.War.Model.Selection;

type
  PWarPlayerInfo = ^TWarPlayerInfo;
  PWarGameClock = ^TWarGameClock;

  /// <summary>
  ///   The data and the services that the classes of the model share: no global variable. The pool of the entities and
  ///   the storage of the states belong to the context; the services are interfaces given by whoever builds it
  ///   (TWarModelFactory). The clock is written by the game once per tic
  /// </summary>
  TWarModelContext = class
  strict private
    FPool: TWarEntityPool;
    FStorage: TWarStateStorage;
    FDatabase: IWarDatabase;
    FRandom: IWarRandom;
    FEvents: IWarModelEvents;
    FOccupancy: IWarOccupancy;
    FSteering: IWarMovementSteering;
    FQueries: IWarUnitQueries;
    FEntities: IWarEntityManager;
    FCombat: IWarCombatServices;
    FCombatEvents: IWarCombatEvents;
    FGather: TWarGatherWorld;
    FConstructionHost: IWarConstructionHost;
    FProbe: IWarOccupancyProbe;
    FWalls: TWarWalls;
    FRuins: TWarRuins;
    FRoads: TWarLine;
    FSelection: TWarSelection;
    FSpellEvents: IWarSpellEvents;
    FViewportTop: Single;
    FHurryUp: Boolean;
    FPlayers: array[0..WAR_MAX_PLAYERS_COUNT - 1] of TWarPlayerInfo;
    FPlayersCount: Integer;
    FUnsignedDirections: Boolean;
    FClock: TWarGameClock;
    FSpeeds: array[0..WAR_UNIT_COUNT - 1, 0..2] of Single;
    function GetPlayer(AIndex: Integer): PWarPlayerInfo;
    function GetClock: PWarGameClock;
    procedure SetConstructionHost(const AValue: IWarConstructionHost);
    procedure SetProbe(const AValue: IWarOccupancyProbe);
  public
    constructor Create(const ADatabase: IWarDatabase; const ARandom: IWarRandom; const AEvents: IWarModelEvents;
      const AOccupancy: IWarOccupancy);
    destructor Destroy; override;
    property Pool: TWarEntityPool read FPool;
    property Storage: TWarStateStorage read FStorage;
    property Database: IWarDatabase read FDatabase;
    property Random: IWarRandom read FRandom;
    property Events: IWarModelEvents read FEvents;
    property Occupancy: IWarOccupancy read FOccupancy;
    /// <summary>The avoidance of obstacles; nil (the default) means that the units go straight</summary>
    property Steering: IWarMovementSteering read FSteering write FSteering;
    /// <summary>Questions about the units and the creation of units: given by the factory once the model is built</summary>
    property Queries: IWarUnitQueries read FQueries write FQueries;
    property Entities: IWarEntityManager read FEntities write FEntities;
    /// <summary>The blows and the projectiles (given by the registration of the attack states); nil if none</summary>
    property Combat: IWarCombatServices read FCombat write FCombat;
    /// <summary>Sounds and explosions of the combat; nil if nobody listens</summary>
    property CombatEvents: IWarCombatEvents read FCombatEvents write FCombatEvents;
    /// <summary>
    ///   The grid, the forests and the sounds that the gatherers use; given by the game after the model is built, not owned.
    ///   nil (the default) and the states of the gatherers raise EWarException when they need it
    /// </summary>
    property Gather: TWarGatherWorld read FGather write FGather;
    /// <summary>The same, EWarException if the game did not give it</summary>
    function RequireGather: TWarGatherWorld;
    /// <summary>
    ///   Images, sounds and fog for building and training (a host that does nothing until the game gives its own). Nil
    ///   gives the default again
    /// </summary>
    property ConstructionHost: IWarConstructionHost read FConstructionHost write SetConstructionHost;
    /// <summary>
    ///   Which tile is free and where the nearest free one is (wpath_isEmpty, wpath_findEmptyTile). The factory takes it from
    ///   the occupancy when that can answer; otherwise every tile is free. Nil gives the default again
    /// </summary>
    property Probe: IWarOccupancyProbe read FProbe write SetProbe;
    /// <summary>The wall of the map (map->editing.wall); owned by the context</summary>
    property Walls: TWarWalls read FWalls;
    /// <summary>The ruins that the buildings that collapsed leave (map->editing.ruin); owned by the context</summary>
    property Ruins: TWarRuins read FRuins;
    /// <summary>The road of the map (map->editing.road: the pieces that the town hall builds); owned by the context</summary>
    property Roads: TWarLine read FRoads;
    /// <summary>The selected entities and the selection groups (map->selectedEntities, map->selectionGroups); owned by the context</summary>
    property Selection: TWarSelection read FSelection;
    /// <summary>The sounds of the spells; nil if nobody listens</summary>
    property SpellEvents: IWarSpellEvents read FSpellEvents write FSpellEvents;
    /// <summary>
    ///   map->camera.viewport.y: the top of what the player sees, in pixels of the map. Defect of the original kept: the
    ///   fire of a rain of fire starts from above the top of the view, so where the camera is changes how long it falls
    /// </summary>
    property ViewportTop: Single read FViewportTop write FViewportTop;
    /// <summary>map->hurryUp, the cheat that makes buildings, units and upgrades 100 times faster</summary>
    property HurryUp: Boolean read FHurryUp write FHurryUp;
    /// <summary>The player 0..4 (the original keeps them in the map); EWarException outside</summary>
    property Players[AIndex: Integer]: PWarPlayerInfo read GetPlayer;
    property PlayersCount: Integer read FPlayersCount write FPlayersCount;
    /// <summary>
    ///   The speed of a unit type at a level of speed (pixels per second); 0 for a type without statistics (the original stops on an assert).
    ///   A level above 2 (the original reads past the array) is the level 2. Read from the database once, at creation
    /// </summary>
    function UnitSpeed(AUnitType, ALevel: Integer): Single;
    /// <summary>
    ///   The directions of the original are an enum: the game written for MSVC (signed) turns from North to North West, the same C built with gcc (unsigned) turns
    ///   from North to North, because a negative step wraps around. False (the default) is the first; the golden of parity was made with gcc and sets True
    /// </summary>
    property UnsignedDirections: Boolean read FUnsignedDirections write FUnsignedDirections;
    /// <summary>The clock: the game writes the time and the length of each tic here</summary>
    property Clock: PWarGameClock read GetClock;
  end;

implementation

uses
  DelphiDoom.War.Types, DelphiDoom.War.Model.Construction.NullHost;

{ TWarModelContext }

constructor TWarModelContext.Create(const ADatabase: IWarDatabase; const ARandom: IWarRandom;
  const AEvents: IWarModelEvents; const AOccupancy: IWarOccupancy);
var
  LIndex: Integer;
  LLevel: Integer;
  LStats: TWarUnitStatsFull;
begin
  inherited Create;
  FPool := TWarEntityPool.Create;
  FStorage := TWarStateStorage.Create;
  FDatabase := ADatabase;
  FRandom := ARandom;
  FEvents := AEvents;
  FOccupancy := AOccupancy;
  FConstructionHost := TWarNullConstructionHost.Create;
  FProbe := TWarNullOccupancyProbe.Create;
  FWalls := TWarWalls.Create;
  FRuins := TWarRuins.Create;
  FRoads := TWarLine.CreateRoad;
  FSelection := TWarSelection.Create;
  FPlayersCount := WAR_MAX_PLAYERS_COUNT;
  for LIndex := 0 to High(FPlayers) do
    FPlayers[LIndex].Index := Byte(LIndex);
  for LIndex := 0 to WAR_UNIT_COUNT - 1 do
    if ADatabase.TryGetUnitStats(LIndex, LStats) then
      for LLevel := 0 to 2 do
        FSpeeds[LIndex, LLevel] := LStats.Speeds[LLevel];
  FClock.GlobalSpeed := 1.0;
  FClock.GameSpeed := 2;
end;

destructor TWarModelContext.Destroy;
begin
  FSelection.Free;
  FRoads.Free;
  FRuins.Free;
  FWalls.Free;
  FStorage.Free;
  FPool.Free;
  inherited;
end;

function TWarModelContext.UnitSpeed(AUnitType, ALevel: Integer): Single;
begin
  if (AUnitType < 0) or (AUnitType >= WAR_UNIT_COUNT) then
    Exit(0);
  if ALevel > 2 then
    ALevel := 2;
  if ALevel < 0 then
    ALevel := 0;
  Result := FSpeeds[AUnitType, ALevel];
end;

function TWarModelContext.RequireGather: TWarGatherWorld;
begin
  if not Assigned(FGather) then
    raise EWarException.CreateFmt(SWarModelNotRegistered, ['the map of the gatherers (Context.Gather)']);
  Result := FGather;
end;

function TWarModelContext.GetClock: PWarGameClock;
begin
  Result := @FClock;
end;

procedure TWarModelContext.SetConstructionHost(const AValue: IWarConstructionHost);
begin
  if Assigned(AValue) then
    FConstructionHost := AValue
  else
    FConstructionHost := TWarNullConstructionHost.Create;
end;

procedure TWarModelContext.SetProbe(const AValue: IWarOccupancyProbe);
begin
  if Assigned(AValue) then
    FProbe := AValue
  else
    FProbe := TWarNullOccupancyProbe.Create;
end;

function TWarModelContext.GetPlayer(AIndex: Integer): PWarPlayerInfo;
begin
  if (AIndex < 0) or (AIndex >= WAR_MAX_PLAYERS_COUNT) then
    raise EWarException.CreateFmt(SWarModelBadPlayer, [AIndex]);
  Result := @FPlayers[AIndex];
end;

end.

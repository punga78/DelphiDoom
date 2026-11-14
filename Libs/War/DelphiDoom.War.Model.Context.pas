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
  DelphiDoom.War.Model.Types, DelphiDoom.War.Model.Stats.Types, DelphiDoom.War.Model.Intf, DelphiDoom.War.Model.EntityPool,
  DelphiDoom.War.Model.StateStorage;

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
    FPlayers: array[0..WAR_MAX_PLAYERS_COUNT - 1] of TWarPlayerInfo;
    FPlayersCount: Integer;
    FUnsignedDirections: Boolean;
    FClock: TWarGameClock;
    FSpeeds: array[0..WAR_UNIT_COUNT - 1, 0..2] of Single;
    function GetPlayer(AIndex: Integer): PWarPlayerInfo;
    function GetClock: PWarGameClock;
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
  DelphiDoom.War.Types;

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

function TWarModelContext.GetClock: PWarGameClock;
begin
  Result := @FClock;
end;

function TWarModelContext.GetPlayer(AIndex: Integer): PWarPlayerInfo;
begin
  if (AIndex < 0) or (AIndex >= WAR_MAX_PLAYERS_COUNT) then
    raise EWarException.CreateFmt(SWarModelBadPlayer, [AIndex]);
  Result := @FPlayers[AIndex];
end;

end.

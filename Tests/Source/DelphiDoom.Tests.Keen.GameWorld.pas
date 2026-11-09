{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the keen library - a little world for the actors        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Keen.GameWorld;

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types, DelphiDoom.Keen.InputTypes, DelphiDoom.Keen.GameTypes,
  DelphiDoom.Keen.StateTypes, DelphiDoom.Keen.Intf, DelphiDoom.Keen.ActorMover, DelphiDoom.Keen.StateMachine,
  DelphiDoom.Keen.PlayLoop, DelphiDoom.Keen.LevelScanner, DelphiDoom.Tests.Keen.VideoFakes,
  DelphiDoom.Tests.Keen.GameFakes;

const
  /// <summary>The tile of the foreground plane that is a solid wall on its four sides</summary>
  WORLD_SOLID = 1;
  /// <summary>A floor that is only a floor (a wall of the north side)</summary>
  WORLD_FLOOR = 2;
  /// <summary>A ceiling (a wall of the south side)</summary>
  WORLD_CEILING = 3;
  /// <summary>A slope: its north wall is the type 4 (the height rises 16 at each pixel)</summary>
  WORLD_SLOPE = 4;

type
  /// <summary>
  ///   A map of AWidth x AHeight tiles with no walls, the fake graphics, the refresh manager and the parts of
  ///   the game that move the actors, built the way that the composition root builds them
  /// </summary>
  TKeenTestWorld = class
  public
    Memory: IKeenEgaMemory;
    Graphics: IKeenGraphics;
    Sprites: IKeenSpriteCache;
    Video: IKeenVideo;
    Clock: IKeenClock;
    TileInfo: IKeenTileInfo;
    Map: IKeenWorkingMap;
    Refresh: IKeenRefresh;
    States: IKeenStateTable;
    Objects: IKeenObjectList;
    ActionsFake: TFakeKeenActions;
    Actions: IKeenActions;
    EventsFake: TFakeKeenEvents;
    Events: IKeenGameEvents;
    Input: IKeenInput;
    Random: IKeenRandom;
    Mover: TKeenActorMover;
    Machine: TKeenStateMachine;
    PlayLoop: TKeenPlayLoop;
    constructor Create(AWidth, AHeight: Integer; const AStates: array of TKeenStateDef);
    destructor Destroy; override;
    /// <summary>A wall of the tile table on the foreground plane</summary>
    procedure SetTile(ATileX, ATileY, ATile: Integer);
    /// <summary>An actor with the shape (a sprite chunk), the state and the position in pixels (x, y of its top left corner)</summary>
    function AddActor(AShape: Integer; AState, APixelX, APixelY: Integer): PKeenObject;
    /// <summary>The map is shown at the tile (ATileX, ATileY) and the actors are asleep or not as the loop says</summary>
    procedure ShowAt(ATileX, ATileY: Integer);
  end;

implementation

uses
  DelphiDoom.Keen.EgaMemory, DelphiDoom.Keen.Video, DelphiDoom.Keen.SpriteCache, DelphiDoom.Keen.TileInfo,
  DelphiDoom.Keen.WorkingMap, DelphiDoom.Keen.Refresh, DelphiDoom.Keen.StateTableCopy, DelphiDoom.Keen.ObjectList,
  DelphiDoom.Keen.Input, DelphiDoom.Keen.ManualClock, DelphiDoom.Keen.Random;

{ TKeenTestWorld }

constructor TKeenTestWorld.Create(AWidth, AHeight: Integer; const AStates: array of TKeenStateDef);
var
  LTable: TBytes;
begin
  inherited Create;
  Memory := TKeenEgaMemory.Create;
  Graphics := TFakeKeenGraphics.Create(5);
  Sprites := TKeenSpriteCache.Create(Graphics);
  Video := TKeenVideo.Create(Memory, Graphics, Sprites);
  Clock := TKeenManualClock.Create(1);
  LTable := TFakeKeenTiles.EmptyTable;
  // the tile 1: a wall on the four sides
  LTable[KEEN_TINF_NORTHWALL + WORLD_SOLID] := 1;
  LTable[KEEN_TINF_EASTWALL + WORLD_SOLID] := 1;
  LTable[KEEN_TINF_SOUTHWALL + WORLD_SOLID] := 1;
  LTable[KEEN_TINF_WESTWALL + WORLD_SOLID] := 1;
  LTable[KEEN_TINF_NORTHWALL + WORLD_FLOOR] := 1;
  LTable[KEEN_TINF_SOUTHWALL + WORLD_CEILING] := 1;
  LTable[KEEN_TINF_NORTHWALL + WORLD_SLOPE] := 4;
  TileInfo := TKeenTileInfo.Create(LTable);
  Map := TKeenWorkingMap.Create(AWidth, AHeight);
  Refresh := TKeenRefresh.Create(Video, Graphics, TileInfo, Sprites, Clock);
  Refresh.NewMap(Map);
  States := TKeenStateTableCopy.Create(AStates);
  Objects := TKeenObjectList.Create(Refresh);
  ActionsFake := TFakeKeenActions.Create;
  Actions := ActionsFake;
  EventsFake := TFakeKeenEvents.Create;
  Events := EventsFake;
  Input := TKeenInput.Create(Clock, nil, nil, nil);
  Input.SetControlType(0, kctKeyboard1);
  Random := TKeenRandom.Create;
  Random.Initialize(False, 0);
  Mover := TKeenActorMover.Create(Map, TileInfo, Sprites, States, Objects, Events);
  Machine := TKeenStateMachine.Create(Objects, States, Actions, Mover, Refresh);
  PlayLoop := TKeenPlayLoop.Create(Objects, Machine, Mover, States, Actions, Refresh, Input, Random, Events);
end;

destructor TKeenTestWorld.Destroy;
begin
  PlayLoop.Free;
  Machine.Free;
  Mover.Free;
  inherited Destroy;
end;

procedure TKeenTestWorld.SetTile(ATileX, ATileY, ATile: Integer);
begin
  Map.Planes[1][ATileY * Map.Width + ATileX] := Word(ATile);
end;

function TKeenTestWorld.AddActor(AShape: Integer; AState, APixelX, APixelY: Integer): PKeenObject;
begin
  Result := Objects.GetNewObj(False);
  Result^.ShapeNum := Word(AShape);
  Result^.State := SmallInt(AState);
  Result^.X := Word(APixelX * 16);
  Result^.Y := Word(APixelY * 16);
  Result^.XDir := 1;
  if AShape <> 0 then
    // the hit rectangle for the first time, without moving
    Machine.NewState(Result, AState);
end;

procedure TKeenTestWorld.ShowAt(ATileX, ATileY: Integer);
begin
  Refresh.NewPosition(ATileX * 256, ATileY * 256);
  PlayLoop.CalcInactivate;
end;

end.

{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the click that gives the command a target         }
{                                                                              }
{  Port of war1 (acoto87/war1), wcmd_executeCommand of war_commands.c (the     }
{  mouse side: which click executes which command, what it consumes), the      }
{  click handlers of the buttons of the commands, and the right click that     }
{  cancels in updateCommandFromRightClick of war_map.c, (c) 2019 Alejandro     }
{  Coto Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt). This is an    }
{  altered version, not the original.                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.MapUi.CommandRunner;

{$R-}
{$Q-}

interface

uses
  System.SysUtils, DelphiDoom.War.Model.Types, DelphiDoom.War.Model.Context, DelphiDoom.War.Model.Commands.Dispatcher,
  DelphiDoom.War.Ui.Types, DelphiDoom.War.Ui.Intf,
  DelphiDoom.War.MapUi.Types, DelphiDoom.War.MapUi.Camera, DelphiDoom.War.MapUi.CommandState;

type
  /// <summary>
  ///   What turns the mouse into an order. The orders themselves (what a command does to the units) are the model's
  ///   (TWarCommands); this is the part of wcmd_executeCommand that reads the click: a command that waits is executed by a
  ///   left click on the map or the minimap (or at once, for the ones that need no target), only the clicks that really did
  ///   something consume it, and what the original answers "handled" keeps the click from selecting. Nothing is owned
  /// </summary>
  TWarMapCommandRunner = class
  strict private
    FContext: TWarModelContext;
    FCommands: TWarCommands;
    FCamera: TWarMapCamera;
    FState: TWarMapCommandState;
    function LeftClickOnMap(const AInput: IWarUiInput; out ATarget: TWarVec2): Boolean;
    function LeftClickOnMinimap(const AInput: IWarUiInput; out ATarget: TWarVec2): Boolean;
    function ExecuteWithTarget(ACommandType: Integer; const AInput: IWarUiInput; AMinimapToo: Boolean): Boolean;
    function ExecuteBuild(const AInput: IWarUiInput): Boolean;
    function ExecuteRoadOrWall(const AInput: IWarUiInput): Boolean;
    function ExecuteOnSingleBuilding(ACommandType: Integer): Boolean;
  public
    constructor Create(const AContext: TWarModelContext; const ACommands: TWarCommands; const ACamera: TWarMapCamera;
      const AState: TWarMapCommandState);
    /// <summary>
    ///   wcmd_executeCommand: True if the command was handled (the selection does not run this frame), which is not the
    ///   same as consumed: a building on a tile that is not free plays the sound of cancel and the command stays, a road or a
    ///   wall never ends, a harvest or a repair ends with any click on the map even when there is nothing to do
    /// </summary>
    function Execute(const AInput: IWarUiInput): Boolean;
    /// <summary>
    ///   The click handler of a button of the panel (commandPanel.slots[i].clickHandler): CANCEL does what it says at once
    ///   (the command and what the buildings do); the others only choose the command, which Execute runs
    /// </summary>
    procedure ClickCommand(ACommandType: Integer);
    /// <summary>
    ///   The right click while a command waits (updateCommandFromRightClick): wcmd_cancel
    /// </summary>
    procedure CancelWithRightClick;
  end;

implementation

uses
  DelphiDoom.War.Types, DelphiDoom.War.Level.Types, DelphiDoom.War.Model.Commands.Types,
  DelphiDoom.War.MapUi.CommandData.Data;

{ TWarMapCommandRunner }

constructor TWarMapCommandRunner.Create(const AContext: TWarModelContext; const ACommands: TWarCommands;
  const ACamera: TWarMapCamera; const AState: TWarMapCommandState);
begin
  inherited Create;
  FContext := AContext;
  FCommands := ACommands;
  FCamera := ACamera;
  FState := AState;
end;

function TWarMapCommandRunner.LeftClickOnMap(const AInput: IWarUiInput; out ATarget: TWarVec2): Boolean;
begin
  Result := AInput.IsButtonJustPressed(wmbLeft) and
    WarRectContains(FCamera.Panels.MapPanel, AInput.PositionX, AInput.PositionY);
  if Result then
    FCamera.ScreenToMap(AInput.PositionX, AInput.PositionY, ATarget.X, ATarget.Y);
end;

function TWarMapCommandRunner.LeftClickOnMinimap(const AInput: IWarUiInput; out ATarget: TWarVec2): Boolean;
var
  LTileX: Single;
  LTileY: Single;
begin
  Result := AInput.IsButtonJustPressed(wmbLeft) and
    WarRectContains(FCamera.Panels.MinimapPanel, AInput.PositionX, AInput.PositionY);
  if Result then
  begin
    // the tile under the mouse, in the middle of it; the camera does not follow this click
    LTileX := AInput.PositionX - FCamera.Panels.MinimapPanel.X;
    LTileY := AInput.PositionY - FCamera.Panels.MinimapPanel.Y;
    TWarMapCamera.TileToMap(LTileX, LTileY, True, ATarget.X, ATarget.Y);
    FState.SuppressMinimapViewportOnRelease := True;
  end;
end;

function TWarMapCommandRunner.ExecuteWithTarget(ACommandType: Integer; const AInput: IWarUiInput;
  AMinimapToo: Boolean): Boolean;
var
  LTarget: TWarVec2;
begin
  Result := False;
  if not AInput.IsButtonJustPressed(wmbLeft) then
    Exit;
  if LeftClickOnMap(AInput, LTarget) then
  begin
    FCommands.Execute(ACommandType, LTarget);
    FState.Consume;
    Exit(True);
  end;
  if AMinimapToo and LeftClickOnMinimap(AInput, LTarget) then
  begin
    // on the minimap the attack has no target but the point (what is on the tile is not looked for)
    if ACommandType = WAR_COMMAND_ATTACK then
      FCommands.Attack.Attack(0, LTarget)
    else
      FCommands.Execute(ACommandType, LTarget);
    FState.Consume;
    Result := True;
  end;
end;

function TWarMapCommandRunner.ExecuteBuild(const AInput: IWarUiInput): Boolean;
var
  LTarget: TWarVec2;
  LTileX: Single;
  LTileY: Single;
  LWorker: Integer;
begin
  Result := LeftClickOnMap(AInput, LTarget);
  if not Result then
    Exit;
  if FContext.Selection.Count = 0 then
    Exit;
  LWorker := FContext.Pool.FindSlot(FContext.Selection[0]);
  if LWorker = 0 then
    Exit;
  TWarMapCamera.MapToTile(LTarget.X, LTarget.Y, LTileX, LTileY);
  // PlaceBuilding is the check of the tile (the flash and the sound of cancel if it fails) and wcmd_tryPlaceBuilding: the
  // command is consumed only if the building was put there
  if FCommands.Construction.PlaceBuilding(LWorker, TWarCommands.BuildingOf(FState.CommandType), Trunc(LTileX),
    Trunc(LTileY)) then
    FState.Consume;
end;

function TWarMapCommandRunner.ExecuteRoadOrWall(const AInput: IWarUiInput): Boolean;
var
  LTarget: TWarVec2;
  LTileX: Single;
  LTileY: Single;
  LTownHall: Integer;
  LPlayer: Integer;
begin
  Result := LeftClickOnMap(AInput, LTarget);
  if not Result then
    Exit;
  if FContext.Selection.Count = 0 then
    Exit;
  LTownHall := FContext.Pool.FindSlot(FContext.Selection[0]);
  if LTownHall = 0 then
    Exit;
  LPlayer := FContext.Pool.Slots[LTownHall]^.UnitData.Player;
  TWarMapCamera.MapToTile(LTarget.X, LTarget.Y, LTileX, LTileY);
  // the command is not consumed: roads and walls are built one after the other until the player cancels
  if FState.CommandType = WAR_COMMAND_BUILD_WALL then
    FCommands.Construction.PlaceWall(LPlayer, Trunc(LTileX), Trunc(LTileY))
  else
    FCommands.Construction.PlaceRoad(LPlayer, Trunc(LTileX), Trunc(LTileY));
end;

function TWarMapCommandRunner.ExecuteOnSingleBuilding(ACommandType: Integer): Boolean;
begin
  // the original asserts that one building is selected; a building that died since the click leaves nothing to do
  if FContext.Selection.Count = 1 then
    FCommands.Execute(ACommandType);
  FState.Consume;
  Result := True;
end;

function TWarMapCommandRunner.Execute(const AInput: IWarUiInput): Boolean;
var
  LType: Integer;
begin
  LType := FState.CommandType;
  case LType of
    WAR_COMMAND_NONE:
      Result := False;
    WAR_COMMAND_MOVE, WAR_COMMAND_ATTACK, WAR_COMMAND_SPELL_RAIN_OF_FIRE, WAR_COMMAND_SPELL_POISON_CLOUD,
    WAR_COMMAND_SPELL_FAR_SIGHT, WAR_COMMAND_SPELL_DARK_VISION:
      Result := ExecuteWithTarget(LType, AInput, True);
    WAR_COMMAND_HARVEST, WAR_COMMAND_REPAIR, WAR_COMMAND_SPELL_HEALING, WAR_COMMAND_SPELL_INVISIBILITY,
    WAR_COMMAND_SPELL_UNHOLY_ARMOR, WAR_COMMAND_SPELL_RAISE_DEAD:
      Result := ExecuteWithTarget(LType, AInput, False);
    WAR_COMMAND_STOP, WAR_COMMAND_DELIVER, WAR_COMMAND_SUMMON_SPIDER .. WAR_COMMAND_SUMMON_WATER_ELEMENTAL:
      begin
        // no target: executed at once
        FCommands.Execute(LType);
        FState.Consume;
        Result := True;
      end;
    WAR_COMMAND_TRAIN_FIRST .. WAR_COMMAND_TRAIN_LAST, WAR_COMMAND_UPGRADE_FIRST .. WAR_COMMAND_UPGRADE_LAST:
      Result := ExecuteOnSingleBuilding(LType);
    WAR_COMMAND_BUILD_FIRST .. WAR_COMMAND_BUILD_LAST:
      Result := ExecuteBuild(AInput);
    WAR_COMMAND_BUILD_ROAD, WAR_COMMAND_BUILD_WALL:
      Result := ExecuteRoadOrWall(AInput);
  else
    // the two menus of the buildings (and a number that is not a command): the original does nothing here
    Result := False;
  end;
end;

procedure TWarMapCommandRunner.ClickCommand(ACommandType: Integer);
begin
  if ACommandType = WAR_COMMAND_CANCEL then
  begin
    FState.Clear;
    FCommands.Cancel;
  end
  else
    FState.CommandType := ACommandType;
end;

procedure TWarMapCommandRunner.CancelWithRightClick;
begin
  FState.Clear;
  FCommands.Cancel;
end;

end.

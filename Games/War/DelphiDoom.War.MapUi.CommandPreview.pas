{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the building that follows the mouse               }
{                                                                              }
{  Port of war1 (acoto87/war1), renderCommand of war_map_ui.c, (c) 2019        }
{  Alejandro Coto Gutierrez, zlib License (see Games\War\LICENSE-war1.txt).    }
{  This is an altered version, not the original.                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.MapUi.CommandPreview;

{$R-}
{$Q-}

interface

uses
  System.SysUtils, DelphiDoom.War.Render.Transform, DelphiDoom.War.Model.Context, DelphiDoom.War.Model.Commands.Dispatcher,
  DelphiDoom.War.Ui.Intf, DelphiDoom.War.MapUi.Camera, DelphiDoom.War.MapUi.CommandState;

type
  /// <summary>
  ///   renderCommand: while a building (or a road, or a wall) waits for its tile, a rectangle of the size of the building
  ///   follows the mouse, gray if the tiles are free and known and red if not. The check is we_checkRectToBuild (the one
  ///   that the preview uses; the click uses the one of the type of building). Nothing is owned
  /// </summary>
  TWarMapCommandPreview = class
  strict private
    FTransform: TWarRenderTransform;
    FCamera: TWarMapCamera;
    FContext: TWarModelContext;
    FCommands: TWarCommands;
    FState: TWarMapCommandState;
    procedure Draw(const AInput: IWarUiInput; ASizeX, ASizeY: Integer);
  public
    constructor Create(const ATransform: TWarRenderTransform; const ACamera: TWarMapCamera;
      const AContext: TWarModelContext; const ACommands: TWarCommands; const AState: TWarMapCommandState);
    /// <summary>renderCommand: draws nothing unless the command waiting is a building, a road or a wall</summary>
    procedure Render(const AInput: IWarUiInput);
  end;

implementation

uses
  DelphiDoom.War.Types, DelphiDoom.War.Level.Types, DelphiDoom.War.Render.Types, DelphiDoom.War.Model.Types,
  DelphiDoom.War.Model.Commands.Types, DelphiDoom.War.MapUi.Types;

{ TWarMapCommandPreview }

constructor TWarMapCommandPreview.Create(const ATransform: TWarRenderTransform; const ACamera: TWarMapCamera;
  const AContext: TWarModelContext; const ACommands: TWarCommands; const AState: TWarMapCommandState);
begin
  inherited Create;
  FTransform := ATransform;
  FCamera := ACamera;
  FContext := AContext;
  FCommands := ACommands;
  FState := AState;
end;

procedure TWarMapCommandPreview.Draw(const AInput: IWarUiInput; ASizeX, ASizeY: Integer);
var
  LMapX: Single;
  LMapY: Single;
  LTileX: Single;
  LTileY: Single;
  LScreenX: Single;
  LScreenY: Single;
  LRect: TWarRectF;
  LColor: TWarRgba;
begin
  FCamera.ScreenToMap(AInput.PositionX, AInput.PositionY, LMapX, LMapY);
  TWarMapCamera.MapToTile(LMapX, LMapY, LTileX, LTileY);
  if FCommands.Construction.CheckRectToBuild(Trunc(LTileX), Trunc(LTileY), ASizeX, ASizeY) then
    LColor := WAR_MAPUI_GRAY_TRANSPARENT
  else
    LColor := WAR_MAPUI_RED_TRANSPARENT;
  TWarMapCamera.TileToMap(LTileX, LTileY, False, LMapX, LMapY);
  FCamera.MapToScreen(LMapX, LMapY, LScreenX, LScreenY);
  LRect.X := LScreenX;
  LRect.Y := LScreenY;
  LRect.Width := ASizeX * WAR_MODEL_MEGA_TILE;
  LRect.Height := ASizeY * WAR_MODEL_MEGA_TILE;
  FTransform.FillRect(LRect, LColor);
end;

procedure TWarMapCommandPreview.Render(const AInput: IWarUiInput);
var
  LType: Integer;
  LSizeX: Integer;
  LSizeY: Integer;
begin
  FTransform.Save;
  LType := FState.CommandType;
  if (LType >= WAR_COMMAND_BUILD_FIRST) and (LType <= WAR_COMMAND_BUILD_LAST) then
  begin
    if FContext.Database.TryGetUnitSize(TWarCommands.BuildingOf(LType), LSizeX, LSizeY) then
      Draw(AInput, LSizeX, LSizeY);
  end
  else if (LType = WAR_COMMAND_BUILD_WALL) or (LType = WAR_COMMAND_BUILD_ROAD) then
    Draw(AInput, 1, 1);
  FTransform.Restore;
end;

end.

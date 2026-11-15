{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the debug drawing of the state machine             }
{                                                                              }
{  Port of war1 (acoto87/war1), war_map.c (renderStateMachineDebug and the      }
{  renderStateMachineDebug* it calls), (c) 2019 Alejandro Coto Gutierrez, zlib  }
{  License (see Libs\War\LICENSE-war1.txt). This is an altered version, not the }
{  original.                                                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.MapUi.DebugStateMachine;

{$R-}
{$Q-}

interface

uses
  System.SysUtils, DelphiDoom.War.Render.Types, DelphiDoom.War.Render.Transform, DelphiDoom.War.Model.Types,
  DelphiDoom.War.Model.State.Types, DelphiDoom.War.Model.Context, DelphiDoom.War.Model.StateMachine, DelphiDoom.War.Ui.Types,
  DelphiDoom.War.Ui.Intf, DelphiDoom.War.Ui.Canvas;

type
  /// <summary>
  ///   The flag "state-machine", drawn under the units for the only unit that is selected: what its active state is doing, as
  ///   lines and markers on the map (the path of a move or a patrol, the target of a follow or an attack and the range of
  ///   the unit, the mine, the forest or the town hall of the gathering with a label, the box of the search of an idle unit and the
  ///   enemy it found). The text of the stack is TWarDebugStateText, written in the cheat line by the scene
  /// </summary>
  TWarDebugStateMachine = class
  strict private
    FTransform: TWarRenderTransform;
    FCanvas: TWarUiCanvas;
    FContext: TWarModelContext;
    FMachine: TWarStateMachine;
    FFlags: IWarDebugRender;
    procedure DrawLine(const AStart, AEnd: TWarVec2; const AColor: TWarRgba);
    procedure DrawMarker(const APosition: TWarVec2; const AColor: TWarRgba);
    procedure DrawPath(const APoints: array of TWarVec2; ACount: Integer; const AColor: TWarRgba);
    procedure DrawLabel(const AText: AnsiString; const APosition: TWarVec2; const AColor: TWarRgba);
    procedure DrawLabelBetween(const AText: AnsiString; const AStart, AEnd: TWarVec2; const AColor: TWarRgba);
    function CenterOfEntity(AId: Word; out APosition: TWarVec2): Boolean;
    procedure DrawIdle(ASlot: Integer);
    procedure DrawFollow(ASlot: Integer; AState: PWarStateFollow);
    procedure DrawAttack(ASlot: Integer; AState: PWarStateAttack);
    procedure DrawResourceFlow(ASlot: Integer; AState: PWarStateBase);
  public
    /// <summary>Nothing is owned</summary>
    constructor Create(const ATransform: TWarRenderTransform; const ACanvas: TWarUiCanvas;
      const AContext: TWarModelContext; const AMachine: TWarStateMachine; const AFlags: IWarDebugRender);
    /// <summary>renderStateMachineDebug</summary>
    procedure Render;
  end;

implementation

uses
  DelphiDoom.War.Types, DelphiDoom.War.Level.Types, DelphiDoom.War.Map.Types, DelphiDoom.War.Text.Types,
  DelphiDoom.War.Model.EntityPool, DelphiDoom.War.Model.Math, DelphiDoom.War.Model.UnitGeometry;

const
  CYAN: TWarRgba = (R: 0; G: 255; B: 255; A: 255);
  YELLOW: TWarRgba = (R: 255; G: 255; B: 0; A: 255);
  ORANGE: TWarRgba = (R: 255; G: 128; B: 0; A: 255);
  MAGENTA: TWarRgba = (R: 255; G: 0; B: 255; A: 255);
  GREEN: TWarRgba = (R: 0; G: 255; B: 0; A: 255);
  WHITE: TWarRgba = (R: 255; G: 255; B: 255; A: 255);
  // WAR_COLOR_YELLOW is 0xFFC7C700: as bytes R=0, G=199, B=199 (a defect of the C kept, see Ui.Types)
  BOX: TWarRgba = (R: 0; G: $C7; B: $C7; A: $FF);
  MIN_LENGTH_SQR: Single = 0.001;
  HALF: Single = 0.5;
  NEAR_ENEMY_RADIUS = 5;

{ TWarDebugStateMachine }

constructor TWarDebugStateMachine.Create(const ATransform: TWarRenderTransform; const ACanvas: TWarUiCanvas;
  const AContext: TWarModelContext; const AMachine: TWarStateMachine; const AFlags: IWarDebugRender);
begin
  inherited Create;
  FTransform := ATransform;
  FCanvas := ACanvas;
  FContext := AContext;
  FMachine := AMachine;
  FFlags := AFlags;
end;

procedure TWarDebugStateMachine.DrawLine(const AStart, AEnd: TWarVec2; const AColor: TWarRgba);
var
  LDelta: TWarVec2;
begin
  LDelta := TWarModelMath.Sub(AEnd, AStart);
  if TWarModelMath.LengthSqr(LDelta) > MIN_LENGTH_SQR then
    FTransform.StrokeLine(AStart.X, AStart.Y, AEnd.X, AEnd.Y, AColor);
end;

procedure TWarDebugStateMachine.DrawMarker(const APosition: TWarVec2; const AColor: TWarRgba);
var
  LRect: TWarRectF;
  LFill: TWarRgba;
begin
  LRect.X := APosition.X - 2.0;
  LRect.Y := APosition.Y - 2.0;
  LRect.Width := 4;
  LRect.Height := 4;
  LFill := AColor;
  LFill.A := 96;
  FTransform.FillRect(LRect, LFill);
  FTransform.StrokeRect(LRect, AColor);
end;

procedure TWarDebugStateMachine.DrawPath(const APoints: array of TWarVec2; ACount: Integer; const AColor: TWarRgba);
var
  LIndex: Integer;
begin
  for LIndex := 1 to ACount - 1 do
    DrawLine(APoints[LIndex - 1], APoints[LIndex], AColor);
  for LIndex := 0 to ACount - 1 do
    DrawMarker(APoints[LIndex], AColor);
end;

procedure TWarDebugStateMachine.DrawLabel(const AText: AnsiString; const APosition: TWarVec2; const AColor: TWarRgba);
var
  LParams: TWarFontParams;
begin
  // WarFontParams params = {0}: font 0 of size 6, the highlight at 0 with no characters
  LParams := Default(TWarFontParams);
  LParams.FontData := FCanvas.FontData(0);
  LParams.FontSize := 6.0;
  LParams.FontColor := AColor;
  FCanvas.RenderText(AText, APosition.X, APosition.Y, 0, LParams, False);
end;

procedure TWarDebugStateMachine.DrawLabelBetween(const AText: AnsiString; const AStart, AEnd: TWarVec2;
  const AColor: TWarRgba);
var
  LMiddle: TWarVec2;
  LSum: Single;
begin
  LSum := AStart.X + AEnd.X;
  LMiddle.X := LSum * HALF;
  LSum := AStart.Y + AEnd.Y;
  LMiddle.Y := LSum * HALF;
  DrawLabel(AText, LMiddle, AColor);
end;

function TWarDebugStateMachine.CenterOfEntity(AId: Word; out APosition: TWarVec2): Boolean;
var
  LSlot: Integer;
begin
  APosition := Default(TWarVec2);
  Result := False;
  if AId = 0 then
    Exit;
  LSlot := FContext.Pool.FindSlot(AId);
  if (LSlot < 0) or (FContext.Pool.Slots[LSlot]^.EntityType <> WAR_ENTITY_UNIT) then
    Exit;
  APosition := TWarUnitGeometry.CenterPosition(FContext.Pool.Slots[LSlot]);
  Result := True;
end;

procedure TWarDebugStateMachine.DrawIdle(ASlot: Integer);
var
  LCenter: TWarVec2;
  LRadius: Single;
  LArea: TWarRectF;
  LEnemy: Integer;
  LEnemyPosition: TWarVec2;
begin
  LCenter := TWarUnitGeometry.CenterPosition(FContext.Pool.Slots[ASlot]);
  LRadius := NEAR_ENEMY_RADIUS;
  LRadius := LRadius * WAR_MEGA_TILE_SIZE;
  LArea.X := LCenter.X - LRadius;
  LArea.Y := LCenter.Y - LRadius;
  LArea.Width := LRadius * 2.0;
  LArea.Height := LRadius * 2.0;
  FTransform.StrokeRect(LArea, BOX);
  LEnemy := FContext.Queries.NearEnemy(ASlot);
  if LEnemy <> 0 then
  begin
    LEnemyPosition := TWarUnitGeometry.CenterPosition(FContext.Pool.Slots[LEnemy]);
    DrawLine(LCenter, LEnemyPosition, BOX);
    DrawMarker(LEnemyPosition, BOX);
  end;
end;

procedure TWarDebugStateMachine.DrawFollow(ASlot: Integer; AState: PWarStateFollow);
var
  LStart: TWarVec2;
  LEnd: TWarVec2;
  LTarget: TWarVec2;
  LDistance: Single;
  LArea: TWarRectF;
begin
  LStart := TWarUnitGeometry.CenterPosition(FContext.Pool.Slots[ASlot]);
  LEnd := AState^.TargetPosition;
  if CenterOfEntity(AState^.TargetEntityId, LTarget) then
    LEnd := LTarget;
  DrawLine(LStart, LEnd, ORANGE);
  DrawMarker(LEnd, ORANGE);
  if AState^.TargetDistance > 0 then
  begin
    LDistance := AState^.TargetDistance;
    LArea.X := LEnd.X - LDistance;
    LArea.Y := LEnd.Y - LDistance;
    LArea.Width := LDistance * 2.0;
    LArea.Height := LDistance * 2.0;
    FTransform.StrokeRect(LArea, ORANGE);
  end;
end;

procedure TWarDebugStateMachine.DrawAttack(ASlot: Integer; AState: PWarStateAttack);
var
  LEntity: PWarEntity;
  LStart: TWarVec2;
  LEnd: TWarVec2;
  LTarget: TWarVec2;
  LRange: Single;
  LArea: TWarRectF;
begin
  LEntity := FContext.Pool.Slots[ASlot];
  LStart := TWarUnitGeometry.CenterPosition(LEntity);
  LEnd := AState^.TargetPosition;
  LRange := LEntity^.UnitData.Range;
  LRange := LRange * WAR_MEGA_TILE_SIZE;
  LArea.X := LStart.X - LRange;
  LArea.Y := LStart.Y - LRange;
  LArea.Width := LRange * 2.0;
  LArea.Height := LRange * 2.0;
  FTransform.StrokeRect(LArea, MAGENTA);
  if CenterOfEntity(AState^.TargetEntityId, LTarget) then
    LEnd := LTarget;
  DrawLine(LStart, LEnd, MAGENTA);
  DrawMarker(LEnd, MAGENTA);
end;

procedure TWarDebugStateMachine.DrawResourceFlow(ASlot: Integer; AState: PWarStateBase);
var
  LStart: TWarVec2;
  LEnd: TWarVec2;
  LSource: TWarVec2;
  LHallPosition: TWarVec2;
  LDeliver: PWarStateDeliver;
  LHasHall: Boolean;
begin
  LStart := TWarUnitGeometry.CenterPosition(FContext.Pool.Slots[ASlot]);
  case AState^.StateType of
    WAR_STATE_GOLD, WAR_STATE_MINING:
      // the mine of a mining state is read as the one of a gold state (same place in the record)
      if CenterOfEntity(PWarStateGold(AState)^.GoldmineId, LEnd) then
      begin
        DrawLine(LStart, LEnd, GREEN);
        DrawMarker(LEnd, GREEN);
        DrawLabelBetween('GOLD', LStart, LEnd, GREEN);
      end;
    WAR_STATE_WOOD, WAR_STATE_CHOPPING:
      begin
        LEnd := PWarStateWood(AState)^.Position;
        DrawLine(LStart, LEnd, YELLOW);
        DrawMarker(LEnd, YELLOW);
        DrawLabelBetween('WOOD', LStart, LEnd, YELLOW);
      end;
    WAR_STATE_DELIVER:
      begin
        LDeliver := PWarStateDeliver(AState);
        LHasHall := CenterOfEntity(LDeliver^.TownHallId, LHallPosition);
        if LHasHall then
        begin
          DrawLine(LStart, LHallPosition, CYAN);
          DrawMarker(LHallPosition, CYAN);
          DrawLabelBetween('DELIVER', LStart, LHallPosition, CYAN);
        end;
        if LDeliver^.Cycle then
        begin
          LSource := LDeliver^.SourcePosition;
          if (LDeliver^.SourceKind = wrkGold) and CenterOfEntity(LDeliver^.SourceId, LEnd) then
            LSource := LEnd;
          if LDeliver^.SourceKind <> wrkNone then
          begin
            if LHasHall then
              LSource := LHallPosition;
            DrawLine(LStart, LSource, WHITE);
            DrawMarker(LSource, WHITE);
          end;
        end;
      end;
  end;
end;

procedure TWarDebugStateMachine.Render;
var
  LSlot: Integer;
  LEntity: PWarEntity;
  LState: PWarStateBase;
begin
  if not FFlags.Flag[wdrStateMachine] then
    Exit;
  if FContext.Selection.Count <> 1 then
    Exit;
  LSlot := FContext.Pool.FindSlot(FContext.Selection[0]);
  if LSlot < 0 then
    Exit;
  LEntity := FContext.Pool.Slots[LSlot];
  if (LEntity^.EntityType <> WAR_ENTITY_UNIT) or (not LEntity^.HasStateMachine) or (LEntity^.StateMachine.Depth = 0) then
    Exit;
  LState := FMachine.ActiveState(LSlot);
  if not Assigned(LState) then
    Exit;
  case LState^.StateType of
    WAR_STATE_IDLE: DrawIdle(LSlot);
    WAR_STATE_MOVE:
      if PWarStateMove(LState)^.WaypointsCount > 1 then
        DrawPath(PWarStateMove(LState)^.Waypoints, PWarStateMove(LState)^.WaypointsCount, CYAN);
    WAR_STATE_PATROL:
      if PWarStatePatrol(LState)^.WaypointsCount > 1 then
        DrawPath(PWarStatePatrol(LState)^.Waypoints, PWarStatePatrol(LState)^.WaypointsCount, YELLOW);
    WAR_STATE_FOLLOW: DrawFollow(LSlot, PWarStateFollow(LState));
    WAR_STATE_ATTACK: DrawAttack(LSlot, PWarStateAttack(LState));
    WAR_STATE_GOLD, WAR_STATE_MINING, WAR_STATE_WOOD, WAR_STATE_CHOPPING, WAR_STATE_DELIVER:
      DrawResourceFlow(LSlot, LState);
  end;
end;

end.

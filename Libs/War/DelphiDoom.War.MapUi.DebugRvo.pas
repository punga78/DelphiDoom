{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the debug drawing of the avoidance between units   }
{                                                                              }
{  Port of war1 (acoto87/war1), war_map.c (renderRvoDebug), (c) 2019 Alejandro  }
{  Coto Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt). This is an     }
{  altered version, not the original.                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.MapUi.DebugRvo;

{$R-}
{$Q-}

interface

uses
  DelphiDoom.War.Render.Types, DelphiDoom.War.Render.Transform, DelphiDoom.War.Model.Types,
  DelphiDoom.War.Model.Context, DelphiDoom.War.Model.StateMachine, DelphiDoom.War.Ui.Types, DelphiDoom.War.Ui.Intf;

type
  /// <summary>
  ///   The flag "rvo", drawn over the units: for every unit that has a move state in its stack and that the avoidance ran for
  ///   this tic (it has candidates) an arrow, in green, from where it was to where the velocity that the avoidance chose
  ///   would take it in one second, and another one, in yellow, for the velocity that it preferred; each has a head
  ///   </summary>
  TWarDebugRvo = class
  strict private
    FTransform: TWarRenderTransform;
    FContext: TWarModelContext;
    FMachine: TWarStateMachine;
    FFlags: IWarDebugRender;
    procedure DrawArrow(const APosition, AVelocity: TWarVec2; const AColor: TWarRgba);
  public
    /// <summary>Nothing is owned</summary>
    constructor Create(const ATransform: TWarRenderTransform; const AContext: TWarModelContext;
      const AMachine: TWarStateMachine; const AFlags: IWarDebugRender);
    /// <summary>renderRvoDebug</summary>
    procedure Render;
  end;

implementation

uses
  System.Generics.Collections, DelphiDoom.War.Model.State.Types, DelphiDoom.War.Model.EntityPool,
  DelphiDoom.War.Model.Math, DelphiDoom.War.MapUi.DebugArrow;

const
  GREEN: TWarRgba = (R: 0; G: 255; B: 0; A: 255);
  YELLOW: TWarRgba = (R: 255; G: 255; B: 0; A: 255);
  /// <summary>0.01f: a velocity shorter than this is not drawn</summary>
  MIN_LENGTH_SQR: Single = 0.01;
  /// <summary>CANDIDATE_DRAW_SCALE</summary>
  DRAW_SCALE: Single = 1.0;

{ TWarDebugRvo }

constructor TWarDebugRvo.Create(const ATransform: TWarRenderTransform; const AContext: TWarModelContext;
  const AMachine: TWarStateMachine; const AFlags: IWarDebugRender);
begin
  inherited Create;
  FTransform := ATransform;
  FContext := AContext;
  FMachine := AMachine;
  FFlags := AFlags;
end;

procedure TWarDebugRvo.DrawArrow(const APosition, AVelocity: TWarVec2; const AColor: TWarRgba);
var
  LEndX: Single;
  LEndY: Single;
  LStep: Single;
begin
  LStep := AVelocity.X * DRAW_SCALE;
  LEndX := APosition.X + LStep;
  LStep := AVelocity.Y * DRAW_SCALE;
  LEndY := APosition.Y + LStep;
  FTransform.StrokeLine(APosition.X, APosition.Y, LEndX, LEndY, AColor);
  TWarDebugArrow.DrawHead(FTransform, LEndX, LEndY, TWarDebugArrow.AngleOf(AVelocity.X, AVelocity.Y), AColor);
end;

procedure TWarDebugRvo.Render;
var
  LUnits: TList<Integer>;
  LIndex: Integer;
  LState: PWarStateMove;
begin
  if not FFlags.Flag[wdrRvo] then
    Exit;
  LUnits := FContext.Pool.OfType[WAR_ENTITY_UNIT];
  for LIndex := 0 to LUnits.Count - 1 do
  begin
    LState := PWarStateMove(FMachine.FindState(LUnits[LIndex], WAR_STATE_MOVE));
    if not Assigned(LState) then
      Continue;
    if LState^.RvoNumCandidates <= 0 then
      Continue;
    if TWarModelMath.LengthSqr(LState^.RvoVelocity) > MIN_LENGTH_SQR then
      DrawArrow(LState^.RvoPosition, LState^.RvoVelocity, GREEN);
    if TWarModelMath.LengthSqr(LState^.RvoPreferredVelocity) > MIN_LENGTH_SQR then
      DrawArrow(LState^.RvoPosition, LState^.RvoPreferredVelocity, YELLOW);
  end;
end;

end.

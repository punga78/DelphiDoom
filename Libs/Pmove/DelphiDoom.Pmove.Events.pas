{******************************************************************************}
{                                                                              }
{  DelphiDoom: pmove library - events, touched entities and animations         }
{                                                                              }
{  Port of PM_AddEvent, PM_AddTouchEnt, PM_StartTorsoAnim, PM_StartLegsAnim,   }
{  PM_ContinueLegsAnim, PM_ContinueTorsoAnim and PM_ForceLegsAnim of           }
{  bg_pmove.c and of BG_AddPredictableEventToPlayerstate of bg_misc.c, from    }
{  the Quake III Arena GPL Source Code (id Software). Copyright (C) 1999-2005  }
{  Id Software, Inc. This unit is derived from the Quake III Arena source      }
{  code and is therefore available under the GNU General Public License,       }
{  version 2 or (at your option) any later version.                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Pmove.Events;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Net.Q3.Types, DelphiDoom.Pmove.Types, DelphiDoom.Pmove.State;

type
  /// <summary>What the movement leaves in the player state besides the position: events, touched entities, animations</summary>
  TPmoveEvents = class
  strict private
    FState: TPmoveState;
  public
    constructor Create(const AState: TPmoveState);
    /// <summary>PM_AddEvent (BG_AddPredictableEventToPlayerstate with a zero parameter)</summary>
    procedure AddEvent(const ANewEvent: Integer);
    /// <summary>PM_AddTouchEnt: the world is not reported, nor an entity twice, nor more than Q3_MAXTOUCH</summary>
    procedure AddTouchEnt(const AEntityNumber: Integer);
    /// <summary>PM_StartTorsoAnim</summary>
    procedure StartTorsoAnim(const AAnimation: Integer);
    /// <summary>PM_StartLegsAnim</summary>
    procedure StartLegsAnim(const AAnimation: Integer);
    /// <summary>PM_ContinueLegsAnim</summary>
    procedure ContinueLegsAnim(const AAnimation: Integer);
    /// <summary>PM_ContinueTorsoAnim</summary>
    procedure ContinueTorsoAnim(const AAnimation: Integer);
    /// <summary>PM_ForceLegsAnim</summary>
    procedure ForceLegsAnim(const AAnimation: Integer);
  end;

implementation

constructor TPmoveEvents.Create(const AState: TPmoveState);
begin
  inherited Create;
  FState := AState;
end;

procedure TPmoveEvents.AddEvent(const ANewEvent: Integer);
var
  LSlot: Integer;
begin
  LSlot := FState.Pm.Ps.EventSequence and (Q3_MAX_PS_EVENTS - 1);
  FState.Pm.Ps.Events[LSlot] := ANewEvent;
  FState.Pm.Ps.EventParms[LSlot] := 0;
  Inc(FState.Pm.Ps.EventSequence);
end;

procedure TPmoveEvents.AddTouchEnt(const AEntityNumber: Integer);
var
  LIndex: Integer;
begin
  if AEntityNumber = Q3_ENTITYNUM_WORLD then
    Exit;
  if FState.Pm.NumTouch = Q3_MAXTOUCH then
    Exit;
  // see if it is already added
  for LIndex := 0 to FState.Pm.NumTouch - 1 do
    if FState.Pm.TouchEnts[LIndex] = AEntityNumber then
      Exit;
  FState.Pm.TouchEnts[FState.Pm.NumTouch] := AEntityNumber;
  Inc(FState.Pm.NumTouch);
end;

procedure TPmoveEvents.StartTorsoAnim(const AAnimation: Integer);
begin
  if FState.Pm.Ps.PmType >= Q3_PM_DEAD then
    Exit;
  FState.Pm.Ps.TorsoAnim := ((FState.Pm.Ps.TorsoAnim and Q3_ANIM_TOGGLEBIT) xor Q3_ANIM_TOGGLEBIT) or AAnimation;
end;

procedure TPmoveEvents.StartLegsAnim(const AAnimation: Integer);
begin
  if FState.Pm.Ps.PmType >= Q3_PM_DEAD then
    Exit;
  if FState.Pm.Ps.LegsTimer > 0 then
    Exit; // a high priority animation is running
  FState.Pm.Ps.LegsAnim := ((FState.Pm.Ps.LegsAnim and Q3_ANIM_TOGGLEBIT) xor Q3_ANIM_TOGGLEBIT) or AAnimation;
end;

procedure TPmoveEvents.ContinueLegsAnim(const AAnimation: Integer);
begin
  if (FState.Pm.Ps.LegsAnim and (not Q3_ANIM_TOGGLEBIT)) = AAnimation then
    Exit;
  if FState.Pm.Ps.LegsTimer > 0 then
    Exit; // a high priority animation is running
  StartLegsAnim(AAnimation);
end;

procedure TPmoveEvents.ContinueTorsoAnim(const AAnimation: Integer);
begin
  if (FState.Pm.Ps.TorsoAnim and (not Q3_ANIM_TOGGLEBIT)) = AAnimation then
    Exit;
  if FState.Pm.Ps.TorsoTimer > 0 then
    Exit; // a high priority animation is running
  StartTorsoAnim(AAnimation);
end;

procedure TPmoveEvents.ForceLegsAnim(const AAnimation: Integer);
begin
  FState.Pm.Ps.LegsTimer := 0;
  StartLegsAnim(AAnimation);
end;

end.

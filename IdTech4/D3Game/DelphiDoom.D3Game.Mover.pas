{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 game library - idMover (linear movement)                 }
{                                                                              }
{  Port of Doom 3 (id Software): game\Mover.h, Mover.cpp (idMover, the class   }
{  of func_mover), reduced to the linear movement scripts ask for: moveTo,     }
{  moveToPos, move, speed, time, accelTime, decelTime, stopMoving, isMoving    }
{  and the wait for the end of the move (waitFor). Rotation, bobbing, swaying, }
{  splines, sounds, portals, gui targets and pushing are not ported.           }
{  Based on the Doom 3 GPL Source Code (id Software).                          }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3 or (at your       }
{  option) any later version, with the additional terms of the Doom 3 Source   }
{  Code License (Reference\doom3\COPYING.txt: preservation of legal notices    }
{  and trademarks, no use of the licensors' names for publicity, warranty      }
{  disclaimer). The repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.D3Game.Mover;

interface

uses
  System.SysUtils, DelphiDoom.IdLib.Math.Vec3, DelphiDoom.MathCore.Float.Angles, DelphiDoom.DoomScript.Types, DelphiDoom.DoomScript.EventDef,
  DelphiDoom.D3Game.Intf, DelphiDoom.D3Game.ClassBase, DelphiDoom.D3Game.EntityEvents, DelphiDoom.D3Game.Entity,
  DelphiDoom.D3Game.PhysicsParametric;

type
  /// <summary>moveStage_t</summary>
  TD3MoveStage = (mvAcceleration, mvLinear, mvDeceleration, mvFinished);

  /// <summary>moverCommand_t (<c>mcSpline</c> is never used: no spline here)</summary>
  TD3MoverCommand = (mcNone, mcRotating, mcMoving, mcSpline);

  /// <summary>The rotation in progress (<c>idMover::rot</c>): the stage, the times of the next ones and the angular velocity</summary>
  TD3RotationState = record
    Stage: TD3MoveStage;
    Acceleration: Integer;
    MoveTime: Integer;
    Deceleration: Integer;
    Rot: TIdAngles;
  end;

  /// <summary>The movement in progress (<c>idMover::move</c>): the stage and the times of the next ones</summary>
  TD3MoveState = record
    Stage: TD3MoveStage;
    Acceleration: Integer;
    MoveTime: Integer;
    Deceleration: Integer;
    Dir: TIdVec3;
  end;

  /// <summary>
  ///   idMover: an entity a script moves to a position (<c>moveToPos</c>), to an entity (<c>moveTo</c>) or along a
  ///   direction (<c>move</c>), at a speed or in a time, with acceleration and deceleration. The move is made of up to
  ///   three stages; each stage ends with <c>&lt;reachedpos&gt;</c>, which starts the next, and the last one tells the
  ///   thread that waits for it (<c>sys.waitFor</c>).
  /// </summary>
  TD3Mover = class(TD3Entity)
  strict private
    FMove: TD3MoveState;
    FMoveThread: Integer;
    FDestPosition: TIdVec3;
    FMoveDelta: TIdVec3;
    FMoveSpeed: Single;
    FMoveTime: Integer;
    FDecelTime: Integer;
    FAccelTime: Integer;
    FLastCommand: TD3MoverCommand;
    FPhysicsObj: TD3PhysicsParametric;
    FRot: TD3RotationState;
    FRotateThread: Integer;
    FDestAngles: TIdAngles;
    FAngleDelta: TIdAngles;
    FStopRotation: Boolean;
    procedure EventUpdateRotation;
    procedure EventStopRotating;
    procedure EventRotateTo(const AAngles: TIdAngles);
    procedure EventRotate(const AAngles: TIdAngles);
    procedure EventRotateOnce(const AAngles: TIdAngles);
    procedure EventRotateAxisTo(const AAxis: Integer; const AAngle: Single; const AUp: Boolean);
    procedure EventIsRotating;
    procedure DoneRotating;
    procedure EventSetCallback;
    procedure EventUpdateMove;
    procedure EventStopMoving;
    procedure EventMoveTo(const AEntity: TD3Entity);
    procedure EventMoveDir(const AAngle, ADistance: Single);
    procedure EventSetMoveSpeed(const ASpeed: Single);
    procedure EventSetMoveTime(const ATime: Single);
    procedure EventSetAccelTime(const ATime: Single);
    procedure EventSetDecelTime(const ATime: Single);
    procedure EventIsMoving;
    procedure DoneMoving;
    function VectorForDir(const AAngle: Single): TIdVec3;
  public
    /// <summary>idMover::Spawn</summary>
    class procedure SpawnClass(const AInstance: TD3Class); static;
    class procedure DeclareEvents(const AType: TD3TypeInfo; const AEvents: TD3EntityEvents); static;
    /// <summary>idMover::BeginMove: plans the stages from the destination, the speed or time, and the accel/decel times</summary>
    procedure BeginMove;
    /// <summary>
    ///   idMover::BeginRotation: plans the stages from the destination angles (<c>dest_angles</c>); the rotation uses the
    ///   move time of the mover, so that it takes as long as a move started before it
    /// </summary>
    procedure BeginRotation(const AStopWhenDone: Boolean);
    /// <summary>idMover::MoveToPos: the position is in world coordinates (converted to the master's space)</summary>
    procedure MoveToPos(const APos: TIdVec3);
    property Rot: TD3RotationState read FRot;
    property DestAngles: TIdAngles read FDestAngles;
    property RotateThread: Integer read FRotateThread;
    property StopRotation: Boolean read FStopRotation;
    property Move: TD3MoveState read FMove;
    property DestPosition: TIdVec3 read FDestPosition;
    property MoveTime: Integer read FMoveTime;
    property MoveSpeed: Single read FMoveSpeed;
    property AccelTime: Integer read FAccelTime;
    property DecelTime: Integer read FDecelTime;
    property LastCommand: TD3MoverCommand read FLastCommand;
    property MoveThread: Integer read FMoveThread;
    property PhysicsObj: TD3PhysicsParametric read FPhysicsObj;
  end;

implementation

uses
  DelphiDoom.MathCore.Float.Conversions, DelphiDoom.MathCore.Float.Extrapolate, DelphiDoom.D3Game.Types,
  DelphiDoom.D3Game.Physics.Intf, DelphiDoom.D3Game.PhysicsTime;

const
  SSpeed = 'Cannot set speed less than or equal to 0.';
  STime = 'Cannot set time less than or equal to 0.';
  SAccelTime = 'Cannot set acceleration time less than 0.';
  SDecelTime = 'Cannot set deceleration time less than 0.';
  SEntityNotFound = 'Entity not found';

class procedure TD3Mover.SpawnClass(const AInstance: TD3Class);
var
  LSelf: TD3Mover;
  LHost: TD3PhysicsHost;
  LGame: ID3EntityGame;
  LOrigin: TIdVec3;
  LMins: TIdVec3;
  LMaxs: TIdVec3;
  LZero: TIdVec3;
  LZeroAngles: TIdAngles;
begin
  LSelf := TD3Mover(AInstance);
  LGame := LSelf.Game;
  LSelf.FMoveThread := 0;
  LSelf.FRotateThread := 0;
  LSelf.FStopRotation := False;
  LSelf.FLastCommand := mcNone;
  LSelf.FAccelTime := Trunc(Single(1000.0) * LSelf.SpawnArgs.GetFloat('accel_time', '0'));
  LSelf.FDecelTime := Trunc(Single(1000.0) * LSelf.SpawnArgs.GetFloat('decel_time', '0'));
  // safe default value
  LSelf.FMoveTime := Trunc(Single(1000.0) * LSelf.SpawnArgs.GetFloat('move_time', '1'));
  LSelf.FMoveSpeed := LSelf.SpawnArgs.GetFloat('move_speed', '0');
  LOrigin := LSelf.GetPhysics.GetOrigin;
  LSelf.FDestPosition := LOrigin;
  LMins := LSelf.GetPhysics.GetAbsBoundsMin - LOrigin;
  LMaxs := LSelf.GetPhysics.GetAbsBoundsMax - LOrigin;
  LSelf.FDestAngles := TIdRotationConversions.MatToAngles(LSelf.GetPhysics.GetAxis);
  LHost := LSelf.CreatePhysicsHost;
  LSelf.FPhysicsObj := TD3PhysicsParametric.CreateMoverPhysics(LHost, LSelf.GetPhysics, LMins, LMaxs,
    LGame.GetClip, LSelf);
  LSelf.FPhysicsObj.SetOrigin(LOrigin);
  LSelf.FPhysicsObj.SetAxis(LSelf.GetPhysics.GetAxis);
  if not LSelf.SpawnArgs.GetBool('solid', '1') then
    LSelf.FPhysicsObj.SetContents(0);
  // a mover with no render model is a pusher
  LSelf.FPhysicsObj.SetPusher;
  LZero.Zero;
  LZeroAngles.Zero;
  LSelf.FPhysicsObj.SetLinearExtrapolation(ID_EXTRAPOLATION_NONE, 0, 0, LSelf.FDestPosition, LZero, LZero);
  LSelf.FPhysicsObj.SetAngularExtrapolation(ID_EXTRAPOLATION_NONE, 0, 0, LSelf.FDestAngles, LZeroAngles, LZeroAngles);
  LSelf.SetPhysics(LSelf.FPhysicsObj);
end;

class procedure TD3Mover.DeclareEvents(const AType: TD3TypeInfo; const AEvents: TD3EntityEvents);
begin
  AType.AddEvent(AEvents.SetCallback,
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      TD3Mover(ATarget).EventSetCallback;
    end);
  AType.AddEvent(AEvents.ReachedPos,
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      TD3Mover(ATarget).EventUpdateMove;
    end);
  AType.AddEvent(AEvents.StopMoving,
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      TD3Mover(ATarget).EventStopMoving;
    end);
  AType.AddEvent(AEvents.Speed,
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      TD3Mover(ATarget).EventSetMoveSpeed(AArgs[0].FloatValue);
    end);
  AType.AddEvent(AEvents.Time,
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      TD3Mover(ATarget).EventSetMoveTime(AArgs[0].FloatValue);
    end);
  AType.AddEvent(AEvents.AccelTime,
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      TD3Mover(ATarget).EventSetAccelTime(AArgs[0].FloatValue);
    end);
  AType.AddEvent(AEvents.DecelTime,
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      TD3Mover(ATarget).EventSetDecelTime(AArgs[0].FloatValue);
    end);
  AType.AddEvent(AEvents.MoveTo,
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      TD3Mover(ATarget).EventMoveTo(TD3Mover(ATarget).EntityFromArg(AArgs[0]));
    end);
  AType.AddEvent(AEvents.MoveToPos,
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      TD3Mover(ATarget).MoveToPos(AArgs[0].VectorValue);
    end);
  AType.AddEvent(AEvents.Move,
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      TD3Mover(ATarget).EventMoveDir(AArgs[0].FloatValue, AArgs[1].FloatValue);
    end);
  AType.AddEvent(AEvents.IsMoving,
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      TD3Mover(ATarget).EventIsMoving;
    end);
  AType.AddEvent(AEvents.ReachedAng,
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      TD3Mover(ATarget).EventUpdateRotation;
    end);
  AType.AddEvent(AEvents.StopRotating,
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      TD3Mover(ATarget).EventStopRotating;
    end);
  AType.AddEvent(AEvents.RotateDownTo,
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      TD3Mover(ATarget).EventRotateAxisTo(AArgs[0].IntValue, AArgs[1].FloatValue, False);
    end);
  AType.AddEvent(AEvents.RotateUpTo,
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      TD3Mover(ATarget).EventRotateAxisTo(AArgs[0].IntValue, AArgs[1].FloatValue, True);
    end);
  AType.AddEvent(AEvents.RotateTo,
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      TD3Mover(ATarget).EventRotateTo(TIdAngles.FromVec3(AArgs[0].VectorValue));
    end);
  AType.AddEvent(AEvents.Rotate,
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      TD3Mover(ATarget).EventRotate(TIdAngles.FromVec3(AArgs[0].VectorValue));
    end);
  AType.AddEvent(AEvents.RotateOnce,
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      TD3Mover(ATarget).EventRotateOnce(TIdAngles.FromVec3(AArgs[0].VectorValue));
    end);
  AType.AddEvent(AEvents.IsRotating,
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      TD3Mover(ATarget).EventIsRotating;
    end);
  AType.AddEvent(AEvents.Activate,
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      // idMover::Event_Activate: Show(), and a spline that is not ported
      TD3Mover(ATarget).Show;
    end);
end;

procedure TD3Mover.EventSetCallback;
var
  LThreads: ID3ScriptThreads;
begin
  LThreads := Game.GetScriptThreads;
  if not Assigned(LThreads) then
    Exit;
  if (FLastCommand = mcRotating) and (FRotateThread = 0) then
  begin
    FLastCommand := mcNone;
    FRotateThread := LThreads.CurrentThreadNum;
    LThreads.ReturnInteger(1);
  end
  else if ((FLastCommand = mcMoving) or (FLastCommand = mcSpline)) and (FMoveThread = 0) then
  begin
    FLastCommand := mcNone;
    FMoveThread := LThreads.CurrentThreadNum;
    LThreads.ReturnInteger(1);
  end
  else
    LThreads.ReturnInteger(0);
end;

procedure TD3Mover.EventStopRotating;
var
  LZero: TIdAngles;
begin
  FDestAngles := FPhysicsObj.GetLocalAngles;
  LZero.Zero;
  FPhysicsObj.SetAngularExtrapolation(ID_EXTRAPOLATION_NONE, 0, 0, FDestAngles, LZero, LZero);
  DoneRotating;
end;

procedure TD3Mover.DoneRotating;
var
  LThreads: ID3ScriptThreads;
begin
  FLastCommand := mcNone;
  LThreads := Game.GetScriptThreads;
  if Assigned(LThreads) and (FRotateThread <> 0) then
    LThreads.ObjectMoveDone(FRotateThread, EntityNumber);
  FRotateThread := 0;
end;

procedure TD3Mover.EventUpdateRotation;
var
  LAngles: TIdAngles;
  LZero: TIdAngles;
begin
  LAngles := FPhysicsObj.GetLocalAngles;
  LZero.Zero;
  case FRot.Stage of
    mvAcceleration:
      begin
        FPhysicsObj.SetAngularExtrapolation(ID_EXTRAPOLATION_ACCELLINEAR, Game.GetTime, FRot.Acceleration, LAngles,
          FRot.Rot, LZero);
        if FRot.MoveTime > 0 then
          FRot.Stage := mvLinear
        else if FRot.Deceleration > 0 then
          FRot.Stage := mvDeceleration
        else
          FRot.Stage := mvFinished;
      end;
    mvLinear:
      begin
        if (not FStopRotation) and (FRot.Deceleration = 0) then
          FPhysicsObj.SetAngularExtrapolation(ID_EXTRAPOLATION_LINEAR or ID_EXTRAPOLATION_NOSTOP, Game.GetTime,
            FRot.MoveTime, LAngles, FRot.Rot, LZero)
        else
          FPhysicsObj.SetAngularExtrapolation(ID_EXTRAPOLATION_LINEAR, Game.GetTime, FRot.MoveTime, LAngles,
            FRot.Rot, LZero);
        if FRot.Deceleration <> 0 then
          FRot.Stage := mvDeceleration
        else
          FRot.Stage := mvFinished;
      end;
    mvDeceleration:
      begin
        FPhysicsObj.SetAngularExtrapolation(ID_EXTRAPOLATION_DECELLINEAR, Game.GetTime, FRot.Deceleration, LAngles,
          FRot.Rot, LZero);
        FRot.Stage := mvFinished;
      end;
    mvFinished:
      begin
        FLastCommand := mcNone;
        if FStopRotation then
        begin
          // set our final angles so that we get rid of any numerical inaccuracy
          FDestAngles.Normalize360;
          FPhysicsObj.SetAngularExtrapolation(ID_EXTRAPOLATION_NONE, 0, 0, FDestAngles, LZero, LZero);
          FStopRotation := False;
        end
        else if FPhysicsObj.GetAngularExtrapolationType = ID_EXTRAPOLATION_ACCELLINEAR then
          // keep our angular velocity constant
          FPhysicsObj.SetAngularExtrapolation(ID_EXTRAPOLATION_LINEAR or ID_EXTRAPOLATION_NOSTOP, Game.GetTime, 0,
            LAngles, FRot.Rot, LZero);
        DoneRotating;
      end;
  end;
end;

procedure TD3Mover.BeginRotation(const AStopWhenDone: Boolean);
var
  LStage: TD3MoveStage;
  LAngles: TIdAngles;
  LZero: TIdAngles;
  LAt: Integer;
  LDt: Integer;
begin
  FLastCommand := mcRotating;
  FRotateThread := 0;

  // rotation always uses move_time so that if a move was started before the rotation, the rotation will take the same
  // amount of time as the move. If no move has been started and no time is set, the rotation takes 1 second.
  if FMoveTime = 0 then
    FMoveTime := 1;

  LAngles := FPhysicsObj.GetLocalAngles;
  FAngleDelta := FDestAngles - LAngles;
  LZero.Zero;
  if FAngleDelta = LZero then
  begin
    // set our final angles so that we get rid of any numerical inaccuracy
    FDestAngles.Normalize360;
    FPhysicsObj.SetAngularExtrapolation(ID_EXTRAPOLATION_NONE, 0, 0, FDestAngles, LZero, LZero);
    FStopRotation := False;
    DoneRotating;
    Exit;
  end;

  // scale times up to whole physics frames
  LAt := TD3PhysicsTime.SnapToFrame(FAccelTime);
  Inc(FMoveTime, LAt - FAccelTime);
  FAccelTime := LAt;
  LDt := TD3PhysicsTime.SnapToFrame(FDecelTime);
  Inc(FMoveTime, LDt - FDecelTime);
  FDecelTime := LDt;
  FMoveTime := TD3PhysicsTime.SnapToFrame(FMoveTime);

  if FAccelTime <> 0 then
    LStage := mvAcceleration
  else if FMoveTime <= FDecelTime then
    LStage := mvDeceleration
  else
    LStage := mvLinear;

  LAt := FAccelTime;
  LDt := FDecelTime;
  if LAt + LDt > FMoveTime then
  begin
    // there's no real correct way to handle this, so we just scale the times to fit into the move time in the same
    // proportions
    LAt := TD3PhysicsTime.SnapToFrame(LAt * FMoveTime div (LAt + LDt));
    LDt := FMoveTime - LAt;
  end;

  FAngleDelta := FAngleDelta * (Single(1000.0) / (Single(FMoveTime) - (LAt + LDt) * Single(0.5)));

  FStopRotation := AStopWhenDone or (LDt <> 0);

  FRot.Stage := LStage;
  FRot.Acceleration := LAt;
  FRot.MoveTime := FMoveTime - LAt - LDt;
  FRot.Deceleration := LDt;
  FRot.Rot := FAngleDelta;

  ProcessEvent(Game.GetEvents.ReachedAng);
end;

procedure TD3Mover.EventRotateTo(const AAngles: TIdAngles);
begin
  FDestAngles := AAngles;
  BeginRotation(True);
end;

procedure TD3Mover.EventRotate(const AAngles: TIdAngles);
var
  LAngles: TIdAngles;
begin
  if FRotateThread <> 0 then
    DoneRotating;
  LAngles := FPhysicsObj.GetLocalAngles;
  FDestAngles := LAngles + AAngles * (FMoveTime - (FAccelTime + FDecelTime) div 2) * Single(0.001);
  BeginRotation(False);
end;

procedure TD3Mover.EventRotateOnce(const AAngles: TIdAngles);
begin
  if FRotateThread <> 0 then
    DoneRotating;
  FDestAngles := FPhysicsObj.GetLocalAngles + AAngles;
  BeginRotation(True);
end;

procedure TD3Mover.EventRotateAxisTo(const AAxis: Integer; const AAngle: Single; const AUp: Boolean);
var
  LAngles: TIdAngles;
begin
  if (AAxis < 0) or (AAxis > 2) then
    World.Error('Invalid axis');
  LAngles := FPhysicsObj.GetLocalAngles;
  FDestAngles[AAxis] := AAngle;
  if AUp then
  begin
    if FDestAngles[AAxis] < LAngles[AAxis] then
      FDestAngles[AAxis] := FDestAngles[AAxis] + 360;
  end
  else if FDestAngles[AAxis] > LAngles[AAxis] then
    FDestAngles[AAxis] := FDestAngles[AAxis] - 360;
  BeginRotation(True);
end;

procedure TD3Mover.EventIsRotating;
var
  LThreads: ID3ScriptThreads;
begin
  LThreads := Game.GetScriptThreads;
  if Assigned(LThreads) then
    LThreads.ReturnInteger(Ord(FPhysicsObj.GetAngularExtrapolationType <> ID_EXTRAPOLATION_NONE));
end;

procedure TD3Mover.EventStopMoving;
begin
  FDestPosition := FPhysicsObj.GetLocalOrigin;
  DoneMoving;
end;

procedure TD3Mover.DoneMoving;
var
  LZero: TIdVec3;
  LThreads: ID3ScriptThreads;
begin
  // set our final position so that we get rid of any numerical inaccuracy
  LZero.Zero;
  FPhysicsObj.SetLinearExtrapolation(ID_EXTRAPOLATION_NONE, 0, 0, FDestPosition, LZero, LZero);
  FLastCommand := mcNone;
  LThreads := Game.GetScriptThreads;
  if Assigned(LThreads) and (FMoveThread <> 0) then
    LThreads.ObjectMoveDone(FMoveThread, EntityNumber);
  FMoveThread := 0;
end;

procedure TD3Mover.EventUpdateMove;
var
  LOrg: TIdVec3;
  LZero: TIdVec3;
begin
  LOrg := FPhysicsObj.GetLocalOrigin;
  LZero.Zero;
  case FMove.Stage of
    mvAcceleration:
      begin
        FPhysicsObj.SetLinearExtrapolation(ID_EXTRAPOLATION_ACCELLINEAR, Game.GetTime, FMove.Acceleration, LOrg,
          FMove.Dir, LZero);
        if FMove.MoveTime > 0 then
          FMove.Stage := mvLinear
        else if FMove.Deceleration > 0 then
          FMove.Stage := mvDeceleration
        else
          FMove.Stage := mvFinished;
      end;
    mvLinear:
      begin
        FPhysicsObj.SetLinearExtrapolation(ID_EXTRAPOLATION_LINEAR, Game.GetTime, FMove.MoveTime, LOrg, FMove.Dir,
          LZero);
        if FMove.Deceleration <> 0 then
          FMove.Stage := mvDeceleration
        else
          FMove.Stage := mvFinished;
      end;
    mvDeceleration:
      begin
        FPhysicsObj.SetLinearExtrapolation(ID_EXTRAPOLATION_DECELLINEAR, Game.GetTime, FMove.Deceleration, LOrg,
          FMove.Dir, LZero);
        FMove.Stage := mvFinished;
      end;
    mvFinished:
      DoneMoving;
  end;
end;

procedure TD3Mover.BeginMove;
var
  LStage: TD3MoveStage;
  LOrg: TIdVec3;
  LDist: Single;
  LAccelDist: Single;
  LTotalAccelTime: Integer;
  LAt: Integer;
  LDt: Integer;
  LZero: TIdVec3;
begin
  FLastCommand := mcMoving;
  FMoveThread := 0;

  LOrg := FPhysicsObj.GetLocalOrigin;
  FMoveDelta := FDestPosition - LOrg;
  LZero.Zero;
  if FMoveDelta = LZero then
  begin
    DoneMoving;
    Exit;
  end;

  // scale times up to whole physics frames
  LAt := TD3PhysicsTime.SnapToFrame(FAccelTime);
  Inc(FMoveTime, LAt - FAccelTime);
  FAccelTime := LAt;
  LDt := TD3PhysicsTime.SnapToFrame(FDecelTime);
  Inc(FMoveTime, LDt - FDecelTime);
  FDecelTime := LDt;

  // if we're moving at a specific speed, we need to calculate the move time
  if FMoveSpeed <> 0 then
  begin
    LDist := FMoveDelta.Length;
    LTotalAccelTime := FAccelTime + FDecelTime;
    // calculate the distance we'll move during acceleration and deceleration
    LAccelDist := LTotalAccelTime * Single(0.5) * Single(0.001) * FMoveSpeed;
    if LAccelDist >= LDist then
      // going too slow for this distance to move at a constant speed
      FMoveTime := LTotalAccelTime
    else
      // calculate move time taking acceleration into account
      FMoveTime := Trunc(LTotalAccelTime + Single(1000.0) * (LDist - LAccelDist) / FMoveSpeed);
  end;

  // scale time up to a whole physics frames
  FMoveTime := TD3PhysicsTime.SnapToFrame(FMoveTime);

  if FAccelTime <> 0 then
    LStage := mvAcceleration
  else if FMoveTime <= FDecelTime then
    LStage := mvDeceleration
  else
    LStage := mvLinear;

  LAt := FAccelTime;
  LDt := FDecelTime;
  if LAt + LDt > FMoveTime then
  begin
    // there's no real correct way to handle this, so we just scale
    // the times to fit into the move time in the same proportions
    LAt := TD3PhysicsTime.SnapToFrame(LAt * FMoveTime div (LAt + LDt));
    LDt := FMoveTime - LAt;
  end;

  FMoveDelta := FMoveDelta * (Single(1000.0) / (Single(FMoveTime) - (LAt + LDt) * Single(0.5)));

  FMove.Stage := LStage;
  FMove.Acceleration := LAt;
  FMove.MoveTime := FMoveTime - LAt - LDt;
  FMove.Deceleration := LDt;
  FMove.Dir := FMoveDelta;

  ProcessEvent(Game.GetEvents.ReachedPos);
end;

procedure TD3Mover.MoveToPos(const APos: TIdVec3);
begin
  FDestPosition := GetLocalCoordinates(APos);
  BeginMove;
end;

procedure TD3Mover.EventMoveTo(const AEntity: TD3Entity);
begin
  if not Assigned(AEntity) then
  begin
    // the original goes on to dereference it
    Game.Warning(SEntityNotFound);
    Exit;
  end;
  FDestPosition := GetLocalCoordinates(AEntity.GetPhysics.GetOrigin);
  BeginMove;
end;

function TD3Mover.VectorForDir(const AAngle: Single): TIdVec3;
var
  LAngles: TIdAngles;
  LForward: TIdVec3;
  LRight: TIdVec3;
  LUp: TIdVec3;
begin
  case Trunc(AAngle) of
    -1, -7: Result.SetValues(0, 0, 1);
    -2, -8: Result.SetValues(0, 0, -1);
    -3, -4, -5, -6:
      begin
        // left, right, forward and back: the yaw of the local angles
        LAngles := FPhysicsObj.GetLocalAngles;
        LAngles.Pitch := 0;
        LAngles.Roll := 0;
        case Trunc(AAngle) of
          -3: LAngles.Yaw := LAngles.Yaw + 90;
          -4: LAngles.Yaw := LAngles.Yaw - 90;
          -6: LAngles.Yaw := LAngles.Yaw + 180;
        end;
        Result := LAngles.ToForward;
      end;
    -9, -10:
      begin
        LAngles := FPhysicsObj.GetLocalAngles;
        LAngles.ToVectors(LForward, LRight, LUp);
        if Trunc(AAngle) = -9 then
          Result := LRight * Single(-1)
        else
          Result := LRight;
      end;
    -11: Result := FPhysicsObj.GetLocalAngles.ToForward;
    -12: Result := FPhysicsObj.GetLocalAngles.ToForward * Single(-1);
  else
    Result := GetWorldVector(TIdAngles.Create(0, AAngle, 0).ToForward);
  end;
end;

procedure TD3Mover.EventMoveDir(const AAngle, ADistance: Single);
var
  LDir: TIdVec3;
  LOrg: TIdVec3;
begin
  LOrg := FPhysicsObj.GetLocalOrigin;
  LDir := VectorForDir(AAngle);
  FDestPosition := LOrg + LDir * ADistance;
  BeginMove;
end;

procedure TD3Mover.EventSetMoveSpeed(const ASpeed: Single);
begin
  if ASpeed <= 0 then
    World.Error(SSpeed);
  FMoveSpeed := ASpeed;
  // move_time is calculated for each move when move_speed is non-0
  FMoveTime := 0;
end;

procedure TD3Mover.EventSetMoveTime(const ATime: Single);
begin
  if ATime <= 0 then
    World.Error(STime);
  FMoveSpeed := 0;
  FMoveTime := TDoomScriptConvert.SecToMs(ATime);
end;

procedure TD3Mover.EventSetAccelTime(const ATime: Single);
begin
  if ATime < 0 then
    World.Error(SAccelTime);
  FAccelTime := TDoomScriptConvert.SecToMs(ATime);
end;

procedure TD3Mover.EventSetDecelTime(const ATime: Single);
begin
  if ATime < 0 then
    World.Error(SDecelTime);
  FDecelTime := TDoomScriptConvert.SecToMs(ATime);
end;

procedure TD3Mover.EventIsMoving;
var
  LThreads: ID3ScriptThreads;
begin
  LThreads := Game.GetScriptThreads;
  if Assigned(LThreads) then
    LThreads.ReturnInteger(Ord(FPhysicsObj.GetLinearExtrapolationType <> ID_EXTRAPOLATION_NONE));
end;

end.

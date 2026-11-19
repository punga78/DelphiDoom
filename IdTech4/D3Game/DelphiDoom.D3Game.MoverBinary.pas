{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 game library - idMover_Binary                            }
{                                                                              }
{  Port of Doom 3 (id Software): game\Mover.h, Mover.cpp (idMover_Binary: the  }
{  base of doors and plats, a mover that goes between two positions). Sounds,  }
{  area portals, gui targets, buddies, pushing, physics teams and binding are  }
{  not ported; the physics is TD3PhysicsParametric (linear motion).            }
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
unit DelphiDoom.D3Game.MoverBinary;

interface

uses
  System.SysUtils, DelphiDoom.IdLib.Math.Vec3, DelphiDoom.DoomScript.Types, DelphiDoom.DoomScript.EventDef,
  DelphiDoom.D3Game.Intf, DelphiDoom.D3Game.ClassBase, DelphiDoom.D3Game.EntityEvents, DelphiDoom.D3Game.Entity,
  DelphiDoom.D3Game.PhysicsParametric;

type
  /// <summary>moverState_t</summary>
  TD3MoverState = (msPos1, msPos2, ms1To2, ms2To1);

  /// <summary>
  ///   idMover_Binary: moves between two positions (<c>pos1</c> and <c>pos2</c>) in <c>duration</c> ms, with optional
  ///   acceleration and deceleration. Movers of the same <c>team</c> move together: the first one spawned is the move
  ///   master (it receives the activation) and the others are on its activate chain. When the motion ends the physics
  ///   posts <c>&lt;reachedpos&gt;</c> and the mover waits <c>wait</c> seconds before it returns (unless it toggles).
  /// </summary>
  TD3MoverBinary = class(TD3Entity)
  strict private
    FPos1: TIdVec3;
    FPos2: TIdVec3;
    FMoverState: TD3MoverState;
    FMoveMaster: TD3MoverBinary;
    FActivateChain: TD3MoverBinary;
    FWait: Single;
    FDuration: Integer;
    FAccelTime: Integer;
    FDecelTime: Integer;
    FActivatedBy: TD3EntityPtr;
    FStateStartTime: Integer;
    FTeam: AnsiString;
    FEnabled: Boolean;
    FMoveThread: Integer;
    FBlocked: Boolean;
    FPhysicsObj: TD3PhysicsParametric;
    procedure EventSetCallback;
  protected
    procedure EventReachedBinaryMover; virtual;
    procedure EventUse(const AActivator: TD3Entity); virtual;
  public
    destructor Destroy; override;
    /// <summary>idMover_Binary::Spawn: reads the team, makes the physics and joins the team</summary>
    class procedure SpawnClass(const AInstance: TD3Class); static;
    /// <summary>The <c>EVENT</c> lines of idMover_Binary</summary>
    class procedure DeclareEvents(const AType: TD3TypeInfo; const AEvents: TD3EntityEvents); static;
    /// <summary>idMover_Binary::GetMovedir: -1 is up, -2 is down, else the direction of the yaw</summary>
    class function GetMovedir(const AAngle: Single): TIdVec3; static;
    /// <summary>idMover_Binary::InitSpeed: pos1, pos2 and the speed give the duration (speed 0 is 100)</summary>
    procedure InitSpeed(const APos1, APos2: TIdVec3; const ASpeed, AAccelTime, ADecelTime: Single);
    /// <summary>idMover_Binary::InitTime</summary>
    procedure InitTime(const APos1, APos2: TIdVec3; const ATime, AAccelTime, ADecelTime: Single);
    /// <summary>idMover_Binary::SetMoverState</summary>
    procedure SetMoverState(const ANewState: TD3MoverState; const ATime: Integer);
    /// <summary>idMover_Binary::MatchActivateTeam: every mover of the team goes to the state at the same time</summary>
    procedure MatchActivateTeam(const ANewState: TD3MoverState; const ATime: Integer);
    procedure JoinActivateTeam(const AMaster: TD3MoverBinary);
    procedure Enable(const AValue: Boolean);
    procedure GotoPosition1;
    procedure GotoPosition2;
    /// <summary>idMover_Binary::Use_BinaryMover</summary>
    procedure UseBinaryMover(const AActivator: TD3Entity);
    procedure SetBlocked(const AValue: Boolean);
    function IsBlocked: Boolean;
    function GetActivator: TD3Entity;
    property Pos1: TIdVec3 read FPos1 write FPos1;
    property Pos2: TIdVec3 read FPos2 write FPos2;
    property MoverState: TD3MoverState read FMoverState;
    property MoveMaster: TD3MoverBinary read FMoveMaster;
    property ActivateChain: TD3MoverBinary read FActivateChain;
    property Wait: Single read FWait write FWait;
    property Duration: Integer read FDuration;
    property AccelTime: Integer read FAccelTime;
    property DecelTime: Integer read FDecelTime;
    property StateStartTime: Integer read FStateStartTime;
    property Team: AnsiString read FTeam;
    property Enabled: Boolean read FEnabled write FEnabled;
    property MoveThread: Integer read FMoveThread;
    property PhysicsObj: TD3PhysicsParametric read FPhysicsObj;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Strings, DelphiDoom.Scanner.IdDict, DelphiDoom.MathCore.Float.Angles, DelphiDoom.MathCore.Float.Extrapolate,
  DelphiDoom.D3Game.Types, DelphiDoom.D3Game.Physics.Intf, DelphiDoom.D3Game.PhysicsTime;

const
  SBadMoverState = 'Event_Reached_BinaryMover: bad moverState';

destructor TD3MoverBinary.Destroy;
var
  LMover: TD3MoverBinary;
begin
  // if this is the mover master
  if Self = FMoveMaster then
  begin
    // make the next mover in the chain the move master
    LMover := FMoveMaster;
    while Assigned(LMover) do
    begin
      LMover.FMoveMaster := FActivateChain;
      LMover := LMover.FActivateChain;
    end;
  end
  else
  begin
    // remove mover from the activate chain
    LMover := FMoveMaster;
    while Assigned(LMover) do
    begin
      if LMover.FActivateChain = Self then
      begin
        LMover.FActivateChain := FActivateChain;
        Break;
      end;
      LMover := LMover.FActivateChain;
    end;
  end;
  inherited Destroy;
end;

class procedure TD3MoverBinary.SpawnClass(const AInstance: TD3Class);
var
  LSelf: TD3MoverBinary;
  LEntity: TD3Entity;
  LHost: TD3PhysicsHost;
  LGame: ID3EntityGame;
  LOrigin: TIdVec3;
  LMins: TIdVec3;
  LMaxs: TIdVec3;
  LNeverMoves: TIdVec3;
begin
  LSelf := TD3MoverBinary(AInstance);
  LGame := LSelf.Game;
  LSelf.FMoveThread := 0;
  LSelf.FEnabled := True;
  LSelf.FActivateChain := nil;
  LSelf.FActivatedBy := TD3EntityPtr.Make(LGame, LSelf);
  LSelf.SpawnArgs.GetFloat('wait', '0', LSelf.FWait);
  LSelf.FTeam := LSelf.SpawnArgs.GetString('team', '');

  if Length(LSelf.FTeam) = 0 then
    LEntity := LSelf
  else
  begin
    // find the first entity spawned on this team (which could be us)
    LEntity := LGame.GetSpawnedEntities.Next;
    while Assigned(LEntity) do
    begin
      if (LEntity is TD3MoverBinary) and
        (TIdStrings.Icmp(TD3MoverBinary(LEntity).FTeam, LSelf.FTeam) = 0) then
        Break;
      LEntity := LEntity.SpawnNode.Next;
    end;
    if not Assigned(LEntity) then
      LEntity := LSelf;
  end;
  LSelf.FMoveMaster := TD3MoverBinary(LEntity);

  LOrigin := LSelf.GetPhysics.GetOrigin;
  LMins := LSelf.GetPhysics.GetAbsBoundsMin - LOrigin;
  LMaxs := LSelf.GetPhysics.GetAbsBoundsMax - LOrigin;
  LHost.GetTime :=
    function: Integer
    begin
      Result := LGame.GetTime;
    end;
  LHost.BecomeActive :=
    procedure(AFlags: Integer)
    begin
      LSelf.BecomeActive(AFlags);
    end;
  LHost.BecomeInactive :=
    procedure(AFlags: Integer)
    begin
      LSelf.BecomeInactive(AFlags);
    end;
  LSelf.FPhysicsObj := TD3PhysicsParametric.CreateMoverPhysics(LHost, LSelf.GetPhysics, LMins, LMaxs,
    LGame.GetClip, LSelf);
  LSelf.FPhysicsObj.SetOrigin(LOrigin);
  if not LSelf.SpawnArgs.GetBool('solid', '1') then
    LSelf.FPhysicsObj.SetContents(0);
  LNeverMoves.Zero;
  LSelf.FPhysicsObj.SetLinearExtrapolation(ID_EXTRAPOLATION_NONE, 0, 0, LOrigin, LNeverMoves, LNeverMoves);
  LSelf.SetPhysics(LSelf.FPhysicsObj);

  if LSelf.FMoveMaster <> LSelf then
    LSelf.JoinActivateTeam(LSelf.FMoveMaster);
end;

class procedure TD3MoverBinary.DeclareEvents(const AType: TD3TypeInfo; const AEvents: TD3EntityEvents);
begin
  AType.AddEvent(AEvents.SetCallback,
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      TD3MoverBinary(ATarget).EventSetCallback;
    end);
  AType.AddEvent(AEvents.ReturnToPos1,
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      TD3MoverBinary(ATarget).MatchActivateTeam(ms2To1, TD3MoverBinary(ATarget).Game.GetTime);
    end);
  AType.AddEvent(AEvents.Activate,
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      TD3MoverBinary(ATarget).EventUse(TD3MoverBinary(ATarget).EntityFromArg(AArgs[0]));
    end);
  AType.AddEvent(AEvents.ReachedPos,
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      TD3MoverBinary(ATarget).EventReachedBinaryMover;
    end);
  AType.AddEvent(AEvents.MatchTeam,
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      TD3MoverBinary(ATarget).MatchActivateTeam(TD3MoverState(AArgs[0].IntValue), AArgs[1].IntValue);
    end);
  AType.AddEvent(AEvents.Enable,
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    var
      LSlave: TD3MoverBinary;
    begin
      // the original calls Enable( false ) here too (conserved)
      LSlave := TD3MoverBinary(ATarget).FMoveMaster;
      while Assigned(LSlave) do
      begin
        LSlave.Enable(False);
        LSlave := LSlave.FActivateChain;
      end;
    end);
  AType.AddEvent(AEvents.Disable,
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    var
      LSlave: TD3MoverBinary;
    begin
      LSlave := TD3MoverBinary(ATarget).FMoveMaster;
      while Assigned(LSlave) do
      begin
        LSlave.Enable(False);
        LSlave := LSlave.FActivateChain;
      end;
    end);
end;

class function TD3MoverBinary.GetMovedir(const AAngle: Single): TIdVec3;
begin
  if AAngle = -1 then
    Result.SetValues(0, 0, 1)
  else if AAngle = -2 then
    Result.SetValues(0, 0, -1)
  else
    Result := TIdAngles.Create(0, AAngle, 0).ToForward;
end;

procedure TD3MoverBinary.EventSetCallback;
var
  LThreads: ID3ScriptThreads;
begin
  LThreads := Game.GetScriptThreads;
  if not Assigned(LThreads) then
    Exit;
  if (FMoverState = ms1To2) or (FMoverState = ms2To1) then
  begin
    FMoveThread := LThreads.CurrentThreadNum;
    LThreads.ReturnInteger(1);
  end
  else
    LThreads.ReturnInteger(0);
end;

procedure TD3MoverBinary.InitSpeed(const APos1, APos2: TIdVec3; const ASpeed, AAccelTime, ADecelTime: Single);
var
  LMove: TIdVec3;
  LDistance: Single;
  LSpeed: Single;
  LZero: TIdVec3;
begin
  FPos1 := APos1;
  FPos2 := APos2;
  FAccelTime := TD3PhysicsTime.SnapToFrame(TDoomScriptConvert.SecToMs(AAccelTime));
  FDecelTime := TD3PhysicsTime.SnapToFrame(TDoomScriptConvert.SecToMs(ADecelTime));

  if ASpeed <> 0 then
    LSpeed := ASpeed
  else
    LSpeed := 100;

  // calculate time to reach second position from speed
  LMove := FPos2 - FPos1;
  LDistance := LMove.Length;
  FDuration := TD3PhysicsTime.SnapToFrame(Trunc(LDistance * 1000 / LSpeed));
  if FDuration <= 0 then
    FDuration := 1;

  FMoverState := msPos1;
  LZero.Zero;
  FPhysicsObj.SetLinearExtrapolation(ID_EXTRAPOLATION_NONE, 0, 0, FPos1, LZero, LZero);
  FPhysicsObj.SetLinearInterpolation(0, 0, 0, 0, LZero, LZero);
  SetOrigin(FPos1);
end;

procedure TD3MoverBinary.InitTime(const APos1, APos2: TIdVec3; const ATime, AAccelTime, ADecelTime: Single);
var
  LZero: TIdVec3;
begin
  FPos1 := APos1;
  FPos2 := APos2;
  FAccelTime := TD3PhysicsTime.SnapToFrame(TDoomScriptConvert.SecToMs(AAccelTime));
  FDecelTime := TD3PhysicsTime.SnapToFrame(TDoomScriptConvert.SecToMs(ADecelTime));
  FDuration := TD3PhysicsTime.SnapToFrame(TDoomScriptConvert.SecToMs(ATime));
  if FDuration <= 0 then
    FDuration := 1;

  FMoverState := msPos1;
  LZero.Zero;
  FPhysicsObj.SetLinearExtrapolation(ID_EXTRAPOLATION_NONE, 0, 0, FPos1, LZero, LZero);
  FPhysicsObj.SetLinearInterpolation(0, 0, 0, 0, LZero, LZero);
  SetOrigin(FPos1);
end;

procedure TD3MoverBinary.SetMoverState(const ANewState: TD3MoverState; const ATime: Integer);
var
  LZero: TIdVec3;
  LSpeed: TIdVec3;
  LDuration: Single;
begin
  LZero.Zero;
  FMoverState := ANewState;
  FMoveThread := 0;
  FStateStartTime := ATime;
  LDuration := FDuration;

  case FMoverState of
    msPos1:
      FPhysicsObj.SetLinearExtrapolation(ID_EXTRAPOLATION_NONE, ATime, 0, FPos1, LZero, LZero);
    msPos2:
      FPhysicsObj.SetLinearExtrapolation(ID_EXTRAPOLATION_NONE, ATime, 0, FPos2, LZero, LZero);
    ms1To2:
      begin
        LSpeed := ((FPos2 - FPos1) * Single(1000.0)) / LDuration;
        FPhysicsObj.SetLinearExtrapolation(ID_EXTRAPOLATION_LINEAR, ATime, FDuration, FPos1, LSpeed, LZero);
        if (FAccelTime <> 0) or (FDecelTime <> 0) then
          FPhysicsObj.SetLinearInterpolation(ATime, FAccelTime, FDecelTime, FDuration, FPos1, FPos2)
        else
          FPhysicsObj.SetLinearInterpolation(0, 0, 0, 0, FPos1, FPos2);
      end;
    ms2To1:
      begin
        LSpeed := ((FPos1 - FPos2) * Single(1000.0)) / LDuration;
        FPhysicsObj.SetLinearExtrapolation(ID_EXTRAPOLATION_LINEAR, ATime, FDuration, FPos2, LSpeed, LZero);
        if (FAccelTime <> 0) or (FDecelTime <> 0) then
          FPhysicsObj.SetLinearInterpolation(ATime, FAccelTime, FDecelTime, FDuration, FPos2, FPos1)
        else
          FPhysicsObj.SetLinearInterpolation(0, 0, 0, 0, FPos1, FPos2);
      end;
  end;
end;

procedure TD3MoverBinary.MatchActivateTeam(const ANewState: TD3MoverState; const ATime: Integer);
var
  LSlave: TD3MoverBinary;
begin
  LSlave := Self;
  while Assigned(LSlave) do
  begin
    LSlave.SetMoverState(ANewState, ATime);
    LSlave := LSlave.FActivateChain;
  end;
end;

procedure TD3MoverBinary.JoinActivateTeam(const AMaster: TD3MoverBinary);
begin
  FActivateChain := AMaster.FActivateChain;
  AMaster.FActivateChain := Self;
end;

procedure TD3MoverBinary.Enable(const AValue: Boolean);
begin
  FEnabled := AValue;
end;

procedure TD3MoverBinary.EventReachedBinaryMover;
var
  LThreads: ID3ScriptThreads;
begin
  LThreads := Game.GetScriptThreads;
  if FMoverState = ms1To2 then
  begin
    // reached pos2
    if Assigned(LThreads) and (FMoveThread <> 0) then
      LThreads.ObjectMoveDone(FMoveThread, EntityNumber);
    FMoveThread := 0;
    SetMoverState(msPos2, Game.GetTime);
    if FEnabled and (FWait >= 0) and (not SpawnArgs.GetBool('toggle')) then
      // return to pos1 after a delay
      PostEventSec(Game.GetEvents.ReturnToPos1, FWait);
    // fire targets
    ActivateTargets(FMoveMaster.GetActivator);
    SetBlocked(False);
  end
  else if FMoverState = ms2To1 then
  begin
    // reached pos1
    if Assigned(LThreads) and (FMoveThread <> 0) then
      LThreads.ObjectMoveDone(FMoveThread, EntityNumber);
    FMoveThread := 0;
    SetMoverState(msPos1, Game.GetTime);
    if FEnabled and (FWait >= 0) and SpawnArgs.GetBool('continuous') then
      PostEventSec(Game.GetEvents.Activate, FWait, [EntityArg(Self)]);
    SetBlocked(False);
  end
  else
    World.Error(SBadMoverState);
end;

procedure TD3MoverBinary.GotoPosition1;
var
  LSlave: TD3MoverBinary;
  LPartial: Integer;
begin
  // only the master should control this
  if FMoveMaster <> Self then
  begin
    FMoveMaster.GotoPosition1;
    Exit;
  end;

  if (FMoverState = msPos1) or (FMoverState = ms2To1) then
    // already there, or on the way
    Exit;

  if FMoverState = msPos2 then
  begin
    LSlave := Self;
    while Assigned(LSlave) do
    begin
      LSlave.CancelEvent(Game.GetEvents.ReturnToPos1);
      LSlave := LSlave.FActivateChain;
    end;
    if not SpawnArgs.GetBool('toggle') then
      ProcessEvent(Game.GetEvents.ReturnToPos1);
    Exit;
  end;

  // only partway up before reversing
  if FMoverState = ms1To2 then
  begin
    // use the physics times because this might be executed during the physics simulation
    LPartial := FPhysicsObj.GetLinearEndTime - FPhysicsObj.GetTime;
    if LPartial < 0 then
      LPartial := 0;
    MatchActivateTeam(ms2To1, FPhysicsObj.GetTime - LPartial);
    // if already at at position 1 (partial == duration) execute the reached event
    if LPartial >= FDuration then
      EventReachedBinaryMover;
  end;
end;

procedure TD3MoverBinary.GotoPosition2;
var
  LPartial: Integer;
begin
  // only the master should control this
  if FMoveMaster <> Self then
  begin
    FMoveMaster.GotoPosition2;
    Exit;
  end;

  if (FMoverState = msPos2) or (FMoverState = ms1To2) then
    // already there, or on the way
    Exit;

  if FMoverState = msPos1 then
  begin
    MatchActivateTeam(ms1To2, Game.GetTime);
    // open areaportal: not ported
    Exit;
  end;

  // only partway up before reversing
  if FMoverState = ms2To1 then
  begin
    // use the physics times because this might be executed during the physics simulation
    LPartial := FPhysicsObj.GetLinearEndTime - FPhysicsObj.GetTime;
    if LPartial < 0 then
      LPartial := 0;
    MatchActivateTeam(ms1To2, FPhysicsObj.GetTime - LPartial);
    // if already at at position 2 (partial == duration) execute the reached event
    if LPartial >= FDuration then
      EventReachedBinaryMover;
  end;
end;

procedure TD3MoverBinary.UseBinaryMover(const AActivator: TD3Entity);
var
  LSlave: TD3MoverBinary;
begin
  // only the master should be used
  if FMoveMaster <> Self then
  begin
    FMoveMaster.UseBinaryMover(AActivator);
    Exit;
  end;

  if not FEnabled then
    Exit;

  FActivatedBy := TD3EntityPtr.Make(Game, AActivator);

  if FMoverState = msPos1 then
  begin
    // FIXME: start moving USERCMD_MSEC later, because if this was player
    // triggered, gameLocal.time hasn't been advanced yet
    MatchActivateTeam(ms1To2, Game.GetTime + D3_USERCMD_MSEC);
    // open areaportal: not ported
    Exit;
  end;

  // if all the way up, just delay before coming down
  if FMoverState = msPos2 then
  begin
    if FWait = -1 then
      Exit;
    LSlave := Self;
    while Assigned(LSlave) do
    begin
      LSlave.CancelEvent(Game.GetEvents.ReturnToPos1);
      if SpawnArgs.GetBool('toggle') then
        LSlave.PostEventSec(Game.GetEvents.ReturnToPos1, 0)
      else
        LSlave.PostEventSec(Game.GetEvents.ReturnToPos1, FWait);
      LSlave := LSlave.FActivateChain;
    end;
    Exit;
  end;

  // only partway down before reversing
  if FMoverState = ms2To1 then
  begin
    GotoPosition2;
    Exit;
  end;

  // only partway up before reversing
  if FMoverState = ms1To2 then
    GotoPosition1;
end;

procedure TD3MoverBinary.EventUse(const AActivator: TD3Entity);
begin
  UseBinaryMover(AActivator);
end;

procedure TD3MoverBinary.SetBlocked(const AValue: Boolean);
var
  LSlave: TD3MoverBinary;
  LIndex: Integer;
  LKeyValue: TIdKeyValue;
  LEntity: TD3Entity;
begin
  LSlave := FMoveMaster;
  while Assigned(LSlave) do
  begin
    LSlave.FBlocked := AValue;
    if AValue then
    begin
      LIndex := LSlave.SpawnArgs.MatchPrefix('triggerBlocked');
      while LIndex >= 0 do
      begin
        if LSlave.SpawnArgs.TryGetKeyVal(LIndex, LKeyValue) then
        begin
          LEntity := Game.FindEntity(LKeyValue.Value);
          if Assigned(LEntity) then
            LEntity.PostEventMS(Game.GetEvents.Activate, 0, [EntityArg(FMoveMaster.GetActivator)]);
        end;
        LIndex := LSlave.SpawnArgs.MatchPrefix('triggerBlocked', LIndex);
      end;
    end;
    LSlave := LSlave.FActivateChain;
  end;
end;

function TD3MoverBinary.IsBlocked: Boolean;
begin
  Result := FBlocked;
end;

function TD3MoverBinary.GetActivator: TD3Entity;
begin
  Result := FActivatedBy.GetEntity(Game);
end;

end.

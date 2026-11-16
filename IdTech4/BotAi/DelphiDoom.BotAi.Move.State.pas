{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotMoveState, the movement state of a bot             }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): bot_movestate_t of  }
{  code\botlib\be_ai_move.c. Based on the Quake III Arena GPL Source Code (id  }
{  Software). Copyright (C) 1999-2005 Id Software, Inc.                        }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Move.State;

interface

uses
  DelphiDoom.MathCore.Types, DelphiDoom.BotAi.Move.Types;

type
  /// <summary>
  ///   The movement state. The input variables are set outside the movement code (BotInitMoveState); the move flags
  ///   MFL_ONGROUND, MFL_TELEPORTED, MFL_WATERJUMP and MFL_GRAPPLEPULL are set from outside too. A cleared state
  ///   (GetClearedMemory, BotResetMoveState) is the one that is made.
  /// </summary>
  TBotMoveState = class
  public
    // input vars
    Origin: TVec3;
    Velocity: TVec3;
    ViewOffset: TVec3;
    EntityNum: Integer;
    Client: Integer;
    ThinkTime: Single;
    PresenceType: Integer;
    ViewAngles: TVec3;
    // state vars
    AreaNum: Integer;
    LastAreaNum: Integer;
    LastGoalAreaNum: Integer;
    LastReachNum: Integer;
    LastOrigin: TVec3;
    ReachAreaNum: Integer;
    MoveFlags: Integer;
    /// <summary>Set when jumped</summary>
    JumpReach: Integer;
    GrappleVisibleTime: Single;
    LastGrappleDist: Single;
    /// <summary>Time to use the current reachability</summary>
    ReachabilityTime: Single;
    AvoidReach: array[0..MAX_AVOIDREACH - 1] of Integer;
    AvoidReachTimes: array[0..MAX_AVOIDREACH - 1] of Single;
    AvoidReachTries: array[0..MAX_AVOIDREACH - 1] of Integer;
    AvoidSpots: array[0..MAX_AVOIDSPOTS - 1] of TBotAvoidSpot;
    NumAvoidSpots: Integer;
    /// <summary>BotResetMoveState: Com_Memset(ms, 0, sizeof(bot_movestate_t))</summary>
    procedure Reset;
    /// <summary>
    ///   BotAddToAvoidReach: the reachability is avoided for AAvoidTime seconds from ATime; the number of tries
    ///   grows each time it is added while it is still avoided
    /// </summary>
    procedure AddToAvoidReach(const ANumber: Integer; const AAvoidTime, ATime: Single);
  end;

implementation

{ TBotMoveState }

procedure TBotMoveState.Reset;
var
  LIndex: Integer;
begin
  Origin := Default(TVec3);
  Velocity := Default(TVec3);
  ViewOffset := Default(TVec3);
  EntityNum := 0;
  Client := 0;
  ThinkTime := 0;
  PresenceType := 0;
  ViewAngles := Default(TVec3);
  AreaNum := 0;
  LastAreaNum := 0;
  LastGoalAreaNum := 0;
  LastReachNum := 0;
  LastOrigin := Default(TVec3);
  ReachAreaNum := 0;
  MoveFlags := 0;
  JumpReach := 0;
  GrappleVisibleTime := 0;
  LastGrappleDist := 0;
  ReachabilityTime := 0;
  for LIndex := 0 to MAX_AVOIDREACH - 1 do
  begin
    AvoidReach[LIndex] := 0;
    AvoidReachTimes[LIndex] := 0;
    AvoidReachTries[LIndex] := 0;
  end;
  for LIndex := 0 to MAX_AVOIDSPOTS - 1 do
    AvoidSpots[LIndex] := Default(TBotAvoidSpot);
  NumAvoidSpots := 0;
end;

procedure TBotMoveState.AddToAvoidReach(const ANumber: Integer; const AAvoidTime, ATime: Single);
var
  LIndex: Integer;
begin
  for LIndex := 0 to MAX_AVOIDREACH - 1 do
  begin
    if AvoidReach[LIndex] = ANumber then
    begin
      if AvoidReachTimes[LIndex] > ATime then
        Inc(AvoidReachTries[LIndex])
      else
        AvoidReachTries[LIndex] := 1;
      AvoidReachTimes[LIndex] := ATime + AAvoidTime;
      Exit;
    end;
  end;
  // add the reachability to the reachabilities to avoid for a while
  for LIndex := 0 to MAX_AVOIDREACH - 1 do
  begin
    if AvoidReachTimes[LIndex] < ATime then
    begin
      AvoidReach[LIndex] := ANumber;
      AvoidReachTimes[LIndex] := ATime + AAvoidTime;
      AvoidReachTries[LIndex] := 1;
      Exit;
    end;
  end;
end;

end.

{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotMovers, elevators and func_bobbing                 }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): BotOnMover,         }
{  MoverDown, MoverBottomCenter, BotFuncBobStartEnd and BotOnTopOfEntity of    }
{  code\botlib\be_ai_move.c. Based on the Quake III Arena GPL Source Code (id  }
{  Software). Copyright (C) 1999-2005 Id Software, Inc.                        }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Move.Movers;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Types, DelphiDoom.Aas.Types, DelphiDoom.BotAi.Move.Context, DelphiDoom.BotAi.Move.State;

type
  /// <summary>
  ///   The geometry of the movers (a func_plat is an elevator, a func_bobbing goes between two points): where they
  ///   are, whether a bot is on one. The model number of the mover is in the low 16 bits of the face number of the
  ///   reachability.
  /// </summary>
  TBotMovers = class
  strict private
    FContext: TBotMoveContext;
  public
    constructor Create(const AContext: TBotMoveContext);
    /// <summary>BotOnMover: the bot is on the mover of the reachability</summary>
    function OnMover(const AOrigin: TVec3; const AEntityNum: Integer; const AReach: TAasReachability): Boolean;
    /// <summary>MoverDown: the top of the plat is below the start of the reachability</summary>
    function MoverDown(const AReach: TAasReachability): Boolean;
    /// <summary>
    ///   MoverBottomCenter: a point just above the plat in the bottom position (the reachability start height); the
    ///   origin of the mover stays the one of the model if there is no entity for it
    /// </summary>
    procedure MoverBottomCenter(const AReach: TAasReachability; out ABottomCenter: TVec3);
    /// <summary>
    ///   BotFuncBobStartEnd: the start and the end of the func_bobbing and its origin; the origin is not set if
    ///   there is no entity for the model (as in the original, where the caller's variable is not initialised)
    /// </summary>
    procedure FuncBobStartEnd(const AReach: TAasReachability; out AStart, AEnd: TVec3; var AOrigin: TVec3);
    /// <summary>BotOnTopOfEntity: the entity under the bot (not the world), -1 if there is none</summary>
    function OnTopOfEntity(const AState: TBotMoveState): Integer;
  end;

implementation

uses
  DelphiDoom.Aas.Move.Types, DelphiDoom.Aas.BoxMath, DelphiDoom.BotAi.Types, DelphiDoom.BotAi.Text.CFormat,
  DelphiDoom.BotAi.Move.Types,
  DelphiDoom.BotAi.Move.VectorMath;

const
  MASK_SOLID_PLAYERCLIP = $00010001;

{ TBotMovers }

constructor TBotMovers.Create(const AContext: TBotMoveContext);
begin
  inherited Create;
  FContext := AContext;
end;

function TBotMovers.OnMover(const AOrigin: TVec3; const AEntityNum: Integer; const AReach: TAasReachability): Boolean;
const
  ANGLES: TVec3 = (0, 0, 0);
  BOX_MINS: TVec3 = (-16, -16, -8);
  BOX_MAXS: TVec3 = (16, 16, 8);
var
  LModelNum: Integer;
  LMins: TVec3;
  LMaxs: TVec3;
  LUnused: TVec3;
  LModelOrigin: TVec3;
  LOrg: TVec3;
  LEnd: TVec3;
  LBoxMins: TVec3;
  LBoxMaxs: TVec3;
  LLimit: Single;
  LIndex: Integer;
  LTrace: TAasBspTrace;
begin
  LModelNum := AReach.FaceNum and $0000FFFF;
  // get some bsp model info
  FContext.World.BspModels.ModelMinsMaxsOrigin(LModelNum, ANGLES, LMins, LMaxs, LUnused);
  if not FContext.World.Entities.OriginOfMoverWithModelNum(LModelNum, LModelOrigin) then
  begin
    FContext.Import.Print(PRT_MESSAGE, 'no entity with model ' + TBotCFormat.Int(LModelNum) + #10);
    Exit(False);
  end;
  for LIndex := 0 to 1 do
  begin
    LLimit := LModelOrigin[LIndex] + LMaxs[LIndex];
    LLimit := LLimit + 16;
    if AOrigin[LIndex] > LLimit then
      Exit(False);
    LLimit := LModelOrigin[LIndex] + LMins[LIndex];
    LLimit := LLimit - 16;
    if AOrigin[LIndex] < LLimit then
      Exit(False);
  end;
  LOrg := AOrigin;
  LOrg[2] := LOrg[2] + 24;
  LEnd := AOrigin;
  LEnd[2] := LEnd[2] - 48;
  LBoxMins := BOX_MINS;
  LBoxMaxs := BOX_MAXS;
  LTrace := FContext.World.Bsp.Trace(LOrg, @LBoxMins, @LBoxMaxs, LEnd, AEntityNum, MASK_SOLID_PLAYERCLIP);
  if (not LTrace.StartSolid) and (not LTrace.AllSolid) then
  begin
    // NOTE: the reachability face number is the model number of the elevator
    if (LTrace.EntityNum <> ENTITYNUM_NONE) and (FContext.World.Entities.EntityModelNum(LTrace.EntityNum) = LModelNum) then
      Exit(True);
  end;
  Result := False;
end;

function TBotMovers.MoverDown(const AReach: TAasReachability): Boolean;
const
  ANGLES: TVec3 = (0, 0, 0);
var
  LModelNum: Integer;
  LMins: TVec3;
  LMaxs: TVec3;
  LOrigin: TVec3;
  LMoverOrigin: TVec3;
  LTop: Single;
begin
  LModelNum := AReach.FaceNum and $0000FFFF;
  // get some bsp model info
  FContext.World.BspModels.ModelMinsMaxsOrigin(LModelNum, ANGLES, LMins, LMaxs, LOrigin);
  LMoverOrigin := LOrigin;
  if not FContext.World.Entities.OriginOfMoverWithModelNum(LModelNum, LMoverOrigin) then
  begin
    FContext.Import.Print(PRT_MESSAGE, 'no entity with model ' + TBotCFormat.Int(LModelNum) + #10);
    Exit(False);
  end;
  // if the top of the plat is below the reachability start point
  LTop := LMoverOrigin[2] + LMaxs[2];
  Result := LTop < AReach.StartPoint[2];
end;

procedure TBotMovers.MoverBottomCenter(const AReach: TAasReachability; out ABottomCenter: TVec3);
const
  ANGLES: TVec3 = (0, 0, 0);
var
  LModelNum: Integer;
  LMins: TVec3;
  LMaxs: TVec3;
  LOrigin: TVec3;
  LMoverOrigin: TVec3;
  LMids: TVec3;
begin
  LModelNum := AReach.FaceNum and $0000FFFF;
  // get some bsp model info
  FContext.World.BspModels.ModelMinsMaxsOrigin(LModelNum, ANGLES, LMins, LMaxs, LOrigin);
  LMoverOrigin := LOrigin;
  if not FContext.World.Entities.OriginOfMoverWithModelNum(LModelNum, LMoverOrigin) then
    FContext.Import.Print(PRT_MESSAGE, 'no entity with model ' + TBotCFormat.Int(LModelNum) + #10)
  else
    LOrigin := LMoverOrigin;
  // get a point just above the plat in the bottom position
  LMids[0] := LMins[0] + LMaxs[0];
  LMids[1] := LMins[1] + LMaxs[1];
  LMids[2] := LMins[2] + LMaxs[2];
  TBotVectorMath.MultiplyAddDouble(LOrigin, 0.5, LMids, ABottomCenter);
  ABottomCenter[2] := AReach.StartPoint[2];
end;

procedure TBotMovers.FuncBobStartEnd(const AReach: TAasReachability; out AStart, AEnd: TVec3; var AOrigin: TVec3);
const
  ANGLES: TVec3 = (0, 0, 0);
var
  LModelNum: Integer;
  LMins: TVec3;
  LMaxs: TVec3;
  LUnused: TVec3;
  LMid: TVec3;
  LMoverOrigin: TVec3;
  LSpawnFlags: Integer;
  LNum0: Integer;
  LNum1: Integer;
  LIndex: Integer;
begin
  LModelNum := AReach.FaceNum and $0000FFFF;
  LMoverOrigin := AOrigin;
  if not FContext.World.Entities.OriginOfMoverWithModelNum(LModelNum, LMoverOrigin) then
  begin
    FContext.Import.Print(PRT_MESSAGE, 'BotFuncBobStartEnd: no entity with model ' + TBotCFormat.Int(LModelNum) + #10);
    AStart := Default(TVec3);
    AEnd := Default(TVec3);
    Exit;
  end;
  AOrigin := LMoverOrigin;
  FContext.World.BspModels.ModelMinsMaxsOrigin(LModelNum, ANGLES, LMins, LMaxs, LUnused);
  for LIndex := 0 to 2 do
  begin
    LMid[LIndex] := LMins[LIndex] + LMaxs[LIndex];
    LMid[LIndex] := LMid[LIndex] * 0.5;
  end;
  AStart := LMid;
  AEnd := LMid;
  LSpawnFlags := AReach.FaceNum shr 16;
  // an int shifted right: the sign is kept
  LNum0 := AReach.EdgeNum shr 16;
  if AReach.EdgeNum < 0 then
    LNum0 := LNum0 or Integer($FFFF0000);
  LNum1 := AReach.EdgeNum and $0000FFFF;
  if LNum1 > $00007FFF then
    LNum1 := LNum1 or Integer($FFFF0000);
  if (LSpawnFlags and 1) <> 0 then
  begin
    AStart[0] := LNum0;
    AEnd[0] := LNum1;
    AOrigin[0] := AOrigin[0] + LMid[0];
    AOrigin[1] := LMid[1];
    AOrigin[2] := LMid[2];
  end
  else if (LSpawnFlags and 2) <> 0 then
  begin
    AStart[1] := LNum0;
    AEnd[1] := LNum1;
    AOrigin[0] := LMid[0];
    AOrigin[1] := AOrigin[1] + LMid[1];
    AOrigin[2] := LMid[2];
  end
  else
  begin
    AStart[2] := LNum0;
    AEnd[2] := LNum1;
    AOrigin[0] := LMid[0];
    AOrigin[1] := LMid[1];
    AOrigin[2] := AOrigin[2] + LMid[2];
  end;
end;

function TBotMovers.OnTopOfEntity(const AState: TBotMoveState): Integer;
const
  UP: TVec3 = (0, 0, 1);
var
  LMins: TVec3;
  LMaxs: TVec3;
  LEnd: TVec3;
  LTrace: TAasBspTrace;
begin
  TAasBoxMath.PresenceTypeBoundingBox(FContext.Import, AState.PresenceType, LMins, LMaxs);
  TBotVectorMath.MultiplyAdd(AState.Origin, -3, UP, LEnd);
  LTrace := FContext.World.Bsp.Trace(AState.Origin, @LMins, @LMaxs, LEnd, AState.EntityNum, MASK_SOLID_PLAYERCLIP);
  if (not LTrace.StartSolid) and (LTrace.EntityNum <> ENTITYNUM_WORLD) and (LTrace.EntityNum <> ENTITYNUM_NONE) then
    Exit(LTrace.EntityNum);
  Result := -1;
end;

end.

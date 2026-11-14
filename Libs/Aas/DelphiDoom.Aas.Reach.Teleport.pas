{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - teleporter reachabilities                         }
{                                                                              }
{  Port of AAS_Reachability_Teleport of be_aas_reach.c. This is very game      }
{  dependent: trigger_multiple (with a target_teleporter) or trigger_teleport  }
{  with a target, and the entity that has that targetname as destination.      }
{  Based on the Quake III Arena GPL Source Code (id Software). Copyright (C)   }
{  1999-2005 Id Software, Inc. This unit is derived from the Quake III Arena   }
{  source code and is therefore available under the GNU General Public         }
{  License, version 2 or (at your option) any later version.                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Reach.Teleport;

{$Q-}
{$R+}

interface

uses
  DelphiDoom.MathCore.Types, DelphiDoom.Aas.Reach.Part;

type
  /// <summary>Reachabilities from the areas of the teleporter triggers to the destinations</summary>
  TAasReachTeleport = class(TAasReachPart)
  strict private
    function FindByTargetName(const AValue: AnsiString): Integer;
    procedure Say(const ALevel: Integer; const AText: string);
    function TriggerOrigin(const AOrigin: TVec3): string;
    procedure Process(const AEnt: Integer);
  public
    /// <summary>AAS_Reachability_Teleport: for every trigger_multiple and trigger_teleport of the map</summary>
    procedure Calculate;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Collision.Q3.Types, DelphiDoom.Collision.Q3.Math, DelphiDoom.BotAi.Types,
  DelphiDoom.Aas.Types, DelphiDoom.Aas.Move.Types, DelphiDoom.Aas.Bsp.CNumbers, DelphiDoom.Aas.Links,
  DelphiDoom.Aas.Printer, DelphiDoom.Aas.Reach.Types, DelphiDoom.Aas.Reach.Format, DelphiDoom.Aas.Reach.Vectors;

const
  CTenthFloat: Single = 0.100000001490116119384765625;

{ TAasReachTeleport }

procedure TAasReachTeleport.Say(const ALevel: Integer; const AText: string);
begin
  TAasPrinter.Print(Context.Import, ALevel, AText);
end;

function TAasReachTeleport.TriggerOrigin(const AOrigin: TVec3): string;
begin
  Result := TAasReachFormat.Fixed(AOrigin[0], 0) + ' ' + TAasReachFormat.Fixed(AOrigin[1], 0) + ' ' +
    TAasReachFormat.Fixed(AOrigin[2], 0);
end;

function TAasReachTeleport.FindByTargetName(const AValue: AnsiString): Integer;
var
  LName: AnsiString;
begin
  Result := Context.Entities.NextEntity(0);
  while Result <> 0 do
  begin
    if Context.Entities.ValueForKey(Result, 'targetname', LName) and (LName = AValue) then
      Exit;
    Result := Context.Entities.NextEntity(Result);
  end;
end;

procedure TAasReachTeleport.Process(const AEnt: Integer);
var
  LDest, LArea2Num, LLink, LAreaNum: Integer;
  LClassName, LTarget, LTargetName, LModel: AnsiString;
  LAngle: Single;
  LOrigin, LDestOrigin, LMins, LMaxs, LEnd, LAngles, LMid, LVelocity, LCmdMove: TVec3;
  LForward, LRight, LUp: TQ3Vec3;
  LTrace: TAasTrace;
  LMove: TAasClientMove;
  LReach: PAasLinkedReach;
  LTrigger: string;
begin
  if not Context.Entities.ValueForKey(AEnt, 'classname', LClassName) then
    Exit;
  if LClassName = 'trigger_multiple' then
    LTrigger := 'trigger_multiple'
  else if LClassName = 'trigger_teleport' then
    LTrigger := 'trigger_teleport'
  else
    Exit;
  Context.Entities.ValueForKey(AEnt, 'model', LModel);
  Say(PRT_MESSAGE, LTrigger + ' model = "' + string(LModel) + '"'#10);
  LAngles[0] := 0;
  LAngles[1] := 0;
  LAngles[2] := 0;
  Context.Models.ModelMinsMaxsOrigin(TAasCNumbers.AtoI(Copy(LModel, 2, MaxInt)), LAngles, LMins, LMaxs, LOrigin);
  if not Context.Entities.ValueForKey(AEnt, 'target', LTarget) then
  begin
    Say(PRT_ERROR, LTrigger + ' at ' + TriggerOrigin(LOrigin) + ' without target'#10);
    Exit;
  end;
  if LTrigger = 'trigger_multiple' then
  begin
    // the target_teleporter that has the target as targetname
    LDest := Context.Entities.NextEntity(0);
    while LDest <> 0 do
    begin
      if Context.Entities.ValueForKey(LDest, 'classname', LClassName) and (LClassName = 'target_teleporter') and
         Context.Entities.ValueForKey(LDest, 'targetname', LTargetName) and (LTargetName = LTarget) then
        Break;
      LDest := Context.Entities.NextEntity(LDest);
    end;
    if LDest = 0 then
      Exit;
    if not Context.Entities.ValueForKey(LDest, 'target', LTarget) then
    begin
      Say(PRT_ERROR, 'target_teleporter without target'#10);
      Exit;
    end;
  end;
  // the classname should be misc_teleporter_dest but any entity with the targetname can be used
  LDest := FindByTargetName(LTarget);
  if LDest = 0 then
  begin
    Say(PRT_ERROR, 'teleporter without misc_teleporter_dest (' + string(LTarget) + ')'#10);
    Exit;
  end;
  if not Context.Entities.VectorForKey(LDest, 'origin', LDestOrigin) then
  begin
    Say(PRT_ERROR, 'teleporter destination (' + string(LTarget) + ') without origin'#10);
    Exit;
  end;
  LArea2Num := Context.Sampler.PointAreaNum(LDestOrigin);
  // if not teleported into a teleporter or into a jumppad
  if not Context.AreaTeleporter(LArea2Num) and not Context.AreaJumpPad(LArea2Num) then
  begin
    LEnd := LDestOrigin;
    LEnd[2] := LEnd[2] - 64;
    LTrace := Context.Tracer.TraceClientBBox(LDestOrigin, LEnd, PRESENCE_CROUCH, -1);
    if LTrace.StartSolid then
    begin
      Say(PRT_ERROR, 'teleporter destination (' + string(LTarget) + ') in solid'#10);
      Exit;
    end;
    // predict where the client will end up
    Context.Entities.FloatForKey(LDest, 'angle', LAngle);
    if LAngle <> 0 then
    begin
      LAngles[0] := 0;
      LAngles[1] := LAngle;
      LAngles[2] := 0;
      TQ3Math.AngleVectors(TQ3Vec3(LAngles), LForward, LRight, LUp);
      LVelocity := TVec3(LForward);
      TAasReachVectors.Scale(LVelocity, 400, LVelocity);
    end
    else
    begin
      LVelocity[0] := 0;
      LVelocity[1] := 0;
      LVelocity[2] := 0;
    end;
    LCmdMove[0] := 0;
    LCmdMove[1] := 0;
    LCmdMove[2] := 0;
    Context.Movement.PredictClientMovement(LMove, -1, LDestOrigin, PRESENCE_NORMAL, False, LVelocity, LCmdMove, 0, 30,
      CTenthFloat, SE_HITGROUND or SE_ENTERWATER or SE_ENTERSLIME or SE_ENTERLAVA or SE_HITGROUNDDAMAGE or
      SE_TOUCHJUMPPAD or SE_TOUCHTELEPORTER, 0, False);
    LArea2Num := Context.Sampler.PointAreaNum(LMove.EndPos);
    if (LMove.StopEvent and (SE_ENTERSLIME or SE_ENTERLAVA)) <> 0 then
      Say(PRT_WARNING, 'teleported into slime or lava at dest ' + string(LTarget) + #10);
    LDestOrigin := LMove.EndPos;
  end;
  TAasReachVectors.Add(LOrigin, LMins, LMins);
  TAasReachVectors.Add(LOrigin, LMaxs, LMaxs);
  TAasReachVectors.Add(LMins, LMaxs, LMid);
  TAasReachVectors.Scale(LMid, 0.5, LMid);
  // link an invalid (-1) entity
  LLink := Context.Links.LinkEntityClientBBox(LMins, LMaxs, -1, PRESENCE_CROUCH);
  if LLink = AAS_NO_LINK then
    Say(PRT_MESSAGE, 'trigger_multiple not in any area'#10);
  LAreaNum := LLink;
  while LAreaNum <> AAS_NO_LINK do
  begin
    if Context.AreaTeleporter(Context.Links.AreaNum(LAreaNum)) then
    begin
      LReach := Context.Heap.Allocate;
      if LReach = nil then
        Break;
      LReach^.AreaNum := LArea2Num;
      LReach^.FaceNum := 0;
      LReach^.EdgeNum := 0;
      LReach^.Start := LMid;
      LReach^.EndPoint := LDestOrigin;
      LReach^.TravelType := TRAVEL_TELEPORT or Context.TravelFlagsForTeam(AEnt);
      LReach^.TravelTime := TAasReachVectors.ToTravelTime(Context.Settings.RsTeleport);
      Context.Heap.Push(Context.Links.AreaNum(LAreaNum), LReach);
      Inc(Context.Counters^.Teleport);
    end;
    LAreaNum := Context.Links.NextArea(LAreaNum);
  end;
  // unlink the invalid entity
  Context.Links.Unlink(LLink);
end;

procedure TAasReachTeleport.Calculate;
var
  LEnt: Integer;
begin
  LEnt := Context.Entities.NextEntity(0);
  while LEnt <> 0 do
  begin
    Process(LEnt);
    LEnt := Context.Entities.NextEntity(LEnt);
  end;
end;

end.

{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - the area to go to for an item or a goal           }
{                                                                              }
{  Port of AAS_BestReachableLinkArea, AAS_BestReachableArea and                }
{  AAS_BestReachableFromJumpPadArea of be_aas_reach.c. Based on the Quake III  }
{  Arena GPL Source Code (id Software). Copyright (C) 1999-2005 Id Software,   }
{  Inc. This unit is derived from the Quake III Arena source code and is       }
{  therefore available under the GNU General Public License, version 2 or (at  }
{  your option) any later version.                                             }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Reach.BestReachable;

{$Q-}
{$R+}

interface

uses
  DelphiDoom.MathCore.Types, DelphiDoom.Aas.Route.Types, DelphiDoom.Aas.Reach.Context, DelphiDoom.Aas.Reach.Part,
  DelphiDoom.Aas.Reach.JumpPadInfo;

type
  /// <summary>The best area for a point or a box: where a bot goes to to get an item</summary>
  TAasReachBest = class(TAasReachPart)
  strict private
    FJumpPadInfo: TAasReachJumpPadInfo;
    function Core(var AOrigin: TVec3; const AMins, AMaxs: TVec3; const AGoal: PVec3): Integer;
  public
    /// <summary>The jump pad info is not owned</summary>
    constructor Create(const AContext: TAasReachContext; const AJumpPadInfo: TAasReachJumpPadInfo); reintroduce;
    /// <summary>AAS_BestReachableLinkArea: the first grounded or swimmable area of the list of links, else the first area</summary>
    function BestReachableLinkArea(const ALinkHead: Integer): Integer;
    /// <summary>AAS_BestReachableArea with a goal origin that is not the origin</summary>
    function BestReachableArea(const AOrigin, AMins, AMaxs: TVec3; var AGoalOrigin: TVec3): Integer;
    /// <summary>
    ///   AAS_BestReachableArea(origin, mins, maxs, origin): the goal origin is the origin, which the function changes
    ///   while it looks for an area (as the call of the original that passes the same vector twice)
    /// </summary>
    function BestReachableAreaInPlace(var AOrigin: TVec3; const AMins, AMaxs: TVec3): Integer;
    /// <summary>AAS_BestReachableFromJumpPadArea</summary>
    function BestReachableFromJumpPadArea(const AOrigin, AMins, AMaxs: TVec3): Integer;
  end;

implementation

uses
  DelphiDoom.BotAi.Types, DelphiDoom.Aas.Types, DelphiDoom.Aas.Move.Types, DelphiDoom.Aas.Links,
  DelphiDoom.Aas.Printer, DelphiDoom.Aas.VectorMath, DelphiDoom.Aas.Reach.Types, DelphiDoom.Aas.Reach.Vectors;

const
  CTenthFloat: Single = 0.100000001490116119384765625;

{ TAasReachBest }

constructor TAasReachBest.Create(const AContext: TAasReachContext; const AJumpPadInfo: TAasReachJumpPadInfo);
begin
  inherited Create(AContext);
  FJumpPadInfo := AJumpPadInfo;
end;

function TAasReachBest.BestReachableLinkArea(const ALinkHead: Integer): Integer;
var
  LLink: Integer;
begin
  LLink := ALinkHead;
  while LLink <> AAS_NO_LINK do
  begin
    if Context.AreaGrounded(Context.Links.AreaNum(LLink)) or Context.AreaSwim(Context.Links.AreaNum(LLink)) then
      Exit(Context.Links.AreaNum(LLink));
    LLink := Context.Links.NextArea(LLink);
  end;
  LLink := ALinkHead;
  while LLink <> AAS_NO_LINK do
  begin
    // the original returns the first area that is not the dummy (the test of the reachabilities after it never runs)
    if Context.Links.AreaNum(LLink) <> 0 then
      Exit(Context.Links.AreaNum(LLink));
    LLink := Context.Links.NextArea(LLink);
  end;
  Result := 0;
end;

function TAasReachBest.Core(var AOrigin: TVec3; const AMins, AMaxs: TVec3; const AGoal: PVec3): Integer;
var
  LAreaNum, LI, LJ, LK, LL, LLink: Integer;
  LStart, LEnd, LAbsMins, LAbsMaxs: TVec3;
  LTrace: TAasTrace;
begin
  // find a point in an area
  LStart := AOrigin;
  LAreaNum := Context.Sampler.PointAreaNum(LStart);
  // while no area was found, fudge around a little
  LI := 0;
  while (LI < 5) and (LAreaNum = 0) do
  begin
    LJ := 0;
    while (LJ < 5) and (LAreaNum = 0) do
    begin
      LK := -1;
      while (LK <= 1) and (LAreaNum = 0) do
      begin
        LL := -1;
        while (LL <= 1) and (LAreaNum = 0) do
        begin
          LStart := AOrigin;
          LStart[0] := LStart[0] + Single(LJ * 4 * LK);
          LStart[1] := LStart[1] + Single(LJ * 4 * LL);
          LStart[2] := LStart[2] + Single(LI * 4);
          LAreaNum := Context.Sampler.PointAreaNum(LStart);
          Inc(LL);
        end;
        Inc(LK);
      end;
      Inc(LJ);
    end;
    Inc(LI);
  end;
  // if an area was found: drop the client box down and try again
  if LAreaNum <> 0 then
  begin
    LEnd := LStart;
    LStart[2] := LStart[2] + 0.25;
    LEnd[2] := LEnd[2] - 50;
    LTrace := Context.Tracer.TraceClientBBox(LStart, LEnd, PRESENCE_CROUCH, -1);
    if not LTrace.StartSolid then
    begin
      LAreaNum := Context.Sampler.PointAreaNum(LTrace.EndPos);
      AGoal^ := LTrace.EndPos;
      if LAreaNum <> 0 then
        Exit(LAreaNum);
    end
    else
    begin
      // the point can be in an area and a trace from it can start in solid all the same
      AGoal^ := LStart;
      Exit(LAreaNum);
    end;
  end;
  // the goal origin does not have to be in the goal area because the bot moves towards the item origin anyway
  AGoal^ := AOrigin;
  TAasReachVectors.Add(AOrigin, AMins, LAbsMins);
  TAasReachVectors.Add(AOrigin, AMaxs, LAbsMaxs);
  // link an invalid (-1) entity
  LLink := Context.Links.LinkEntityClientBBox(LAbsMins, LAbsMaxs, -1, PRESENCE_CROUCH);
  LAreaNum := BestReachableLinkArea(LLink);
  Context.Links.Unlink(LLink);
  Result := LAreaNum;
end;

function TAasReachBest.BestReachableArea(const AOrigin, AMins, AMaxs: TVec3; var AGoalOrigin: TVec3): Integer;
var
  LOrigin: TVec3;
begin
  LOrigin := AOrigin;
  Result := Core(LOrigin, AMins, AMaxs, @AGoalOrigin);
end;

function TAasReachBest.BestReachableAreaInPlace(var AOrigin: TVec3; const AMins, AMaxs: TVec3): Integer;
begin
  Result := Core(AOrigin, AMins, AMaxs, @AOrigin);
end;

function TAasReachBest.BestReachableFromJumpPadArea(const AOrigin, AMins, AMaxs: TVec3): Integer;
var
  LEnt, LArea2Num, LLink, LBestAreaNum: Integer;
  LClassName: AnsiString;
  LVolume, LBestAreaVolume: Single;
  LAreaStart, LCmdMove, LBBoxMins, LBBoxMaxs, LAbsMins, LAbsMaxs, LVelocity: TVec3;
  LMove: TAasClientMove;
  LHead: Integer;
begin
  TAasReachVectors.Add(AOrigin, AMins, LBBoxMins);
  TAasReachVectors.Add(AOrigin, AMaxs, LBBoxMaxs);
  LEnt := Context.Entities.NextEntity(0);
  while LEnt <> 0 do
  begin
    if Context.Entities.ValueForKey(LEnt, 'classname', LClassName) and (LClassName = 'trigger_push') then
      if FJumpPadInfo.GetInfo(LEnt, LAreaStart, LAbsMins, LAbsMaxs, LVelocity) then
      begin
        // the areas the jump pad brush is in
        LHead := Context.Links.LinkEntityClientBBox(LAbsMins, LAbsMaxs, -1, PRESENCE_CROUCH);
        LLink := LHead;
        while (LLink <> AAS_NO_LINK) and not Context.AreaJumpPad(Context.Links.AreaNum(LLink)) do
          LLink := Context.Links.NextArea(LLink);
        if LLink = AAS_NO_LINK then
          TAasPrinter.Print(Context.Import, PRT_MESSAGE, 'trigger_push not in any jump pad area'#10)
        else
        begin
          LCmdMove[0] := 0;
          LCmdMove[1] := 0;
          LCmdMove[2] := 0;
          FillChar(LMove, SizeOf(LMove), 0);
          LArea2Num := 0;
          Context.Movement.ClientMovementHitBBox(LMove, -1, LAreaStart, PRESENCE_NORMAL, False, LVelocity, LCmdMove, 0,
            30, CTenthFloat, LBBoxMins, LBBoxMaxs, False);
          if LMove.Frames < 30 then
          begin
            LBestAreaNum := 0;
            LBestAreaVolume := 0;
            LLink := LHead;
            while LLink <> AAS_NO_LINK do
            begin
              if Context.AreaJumpPad(Context.Links.AreaNum(LLink)) then
              begin
                LVolume := Context.Geometry.AreaVolume(Context.Links.AreaNum(LLink));
                if LVolume >= LBestAreaVolume then
                begin
                  LBestAreaNum := Context.Links.AreaNum(LLink);
                  LBestAreaVolume := LVolume;
                end;
              end;
              LLink := Context.Links.NextArea(LLink);
            end;
            Context.Links.Unlink(LHead);
            Exit(LBestAreaNum);
          end;
        end;
        Context.Links.Unlink(LHead);
      end;
    LEnt := Context.Entities.NextEntity(LEnt);
  end;
  Result := 0;
end;

end.

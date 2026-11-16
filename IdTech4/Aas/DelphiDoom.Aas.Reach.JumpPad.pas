{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - jump pad (trigger_push) reachabilities            }
{                                                                              }
{  Port of AAS_Reachability_JumpPad of be_aas_reach.c. Based on the Quake III  }
{  Arena GPL Source Code (id Software). Copyright (C) 1999-2005 Id Software,   }
{  Inc. This unit is derived from the quake III Arena source code and is       }
{  therefore available under the GNU General Public License, version 2 or (at  }
{  your option) any later version.                                             }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Reach.JumpPad;

{$Q-}
{$R+}

interface

uses
  DelphiDoom.Aas.Reach.Context, DelphiDoom.Aas.Reach.Part, DelphiDoom.Aas.Reach.JumpPadInfo;

type
  /// <summary>Reachabilities from the jump pad areas to where the push throws the bot</summary>
  TAasReachJumpPad = class(TAasReachPart)
  strict private
    FInfo: TAasReachJumpPadInfo;
  public
    /// <summary>The jump pad info is not owned</summary>
    constructor Create(const AContext: TAasReachContext; const AInfo: TAasReachJumpPadInfo); reintroduce;
    /// <summary>AAS_Reachability_JumpPad: for every trigger_push of the map</summary>
    procedure Calculate;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.MathCore.Types, DelphiDoom.BotAi.Types, DelphiDoom.Aas.Types, DelphiDoom.Aas.Move.Types,
  DelphiDoom.Aas.Links, DelphiDoom.Aas.Printer, DelphiDoom.Aas.VectorMath, DelphiDoom.Aas.Reach.Types,
  DelphiDoom.Aas.Reach.Format, DelphiDoom.Aas.Reach.Vectors;

const
  CTenthFloat: Single = 0.100000001490116119384765625;

{ TAasReachJumpPad }

constructor TAasReachJumpPad.Create(const AContext: TAasReachContext; const AInfo: TAasReachJumpPadInfo);
begin
  inherited Create(AContext);
  FInfo := AInfo;
end;

procedure TAasReachJumpPad.Calculate;
var
  LEnt, LI, LArea2Num, LLink, LHead, LFace2Num: Integer;
  LClassName: AnsiString;
  LAreaStart, LFaceCenter, LDir, LCmdMove, LVelocity, LAbsMins, LAbsMaxs: TVec3;
  LMove: TAasClientMove;
  LLinkReach: PAasLinkedReach;
  LArea2: TAasArea;
  LFace2: TAasFace;
  LSpeed, LZVel: Single;
  LRoot: Double;


  LSqrtX, LSqrtY, LSumFloat: Single;

begin
  LEnt := Context.Entities.NextEntity(0);
  while LEnt <> 0 do
  begin
    if not Context.Entities.ValueForKey(LEnt, 'classname', LClassName) or (LClassName <> 'trigger_push') or
       not FInfo.GetInfo(LEnt, LAreaStart, LAbsMins, LAbsMaxs, LVelocity) then
    begin
      LEnt := Context.Entities.NextEntity(LEnt);
      Continue;
    end;
    // the areas the jump pad brush is in
    LHead := Context.Links.LinkEntityClientBBox(LAbsMins, LAbsMaxs, -1, PRESENCE_CROUCH);
    LLink := LHead;
    while (LLink <> AAS_NO_LINK) and not Context.AreaJumpPad(Context.Links.AreaNum(LLink)) do
      LLink := Context.Links.NextArea(LLink);
    if LLink = AAS_NO_LINK then
    begin
      TAasPrinter.Print(Context.Import, PRT_MESSAGE, 'trigger_push not in any jump pad area'#10);
      Context.Links.Unlink(LHead);
      LEnt := Context.Entities.NextEntity(LEnt);
      Continue;
    end;
    TAasPrinter.Print(Context.Import, PRT_MESSAGE, 'found a trigger_push with velocity ' +
      TAasReachFormat.Fixed(LVelocity[0], 6) + ' ' + TAasReachFormat.Fixed(LVelocity[1], 6) + ' ' +
      TAasReachFormat.Fixed(LVelocity[2], 6) + #10);
    // if there is a horizontal velocity check for a reachability without air control
    if (LVelocity[0] <> 0) or (LVelocity[1] <> 0) then
    begin
      LCmdMove[0] := 0;
      LCmdMove[1] := 0;
      LCmdMove[2] := 0;
      FillChar(LMove, SizeOf(LMove), 0);
      LArea2Num := 0;
      LI := 0;
      while LI < 20 do
      begin
        Context.Movement.PredictClientMovement(LMove, -1, LAreaStart, PRESENCE_NORMAL, False, LVelocity, LCmdMove, 0, 30,
          CTenthFloat, SE_HITGROUND or SE_ENTERWATER or SE_ENTERSLIME or SE_ENTERLAVA or SE_HITGROUNDDAMAGE or
          SE_TOUCHJUMPPAD or SE_TOUCHTELEPORTER, 0, False);
        LArea2Num := LMove.EndArea;
        LLink := LHead;
        while LLink <> AAS_NO_LINK do
        begin
          if Context.AreaJumpPad(Context.Links.AreaNum(LLink)) and (Context.Links.AreaNum(LLink) = LArea2Num) then
            Break;
          LLink := Context.Links.NextArea(LLink);
        end;
        if LLink = AAS_NO_LINK then
          Break;
        LAreaStart := LMove.EndPos;
        LVelocity := LMove.Velocity;
        Inc(LI);
      end;
      if (LArea2Num <> 0) and (LI < 20) then
      begin
        LLink := LHead;
        while LLink <> AAS_NO_LINK do
        begin
          if (not Context.AreaJumpPad(Context.Links.AreaNum(LLink))) or
             Context.ReachabilityExists(Context.Links.AreaNum(LLink), LArea2Num) then
          begin
            LLink := Context.Links.NextArea(LLink);
            Continue;
          end;
          // a jump pad reachability from the jump pad area to the area where the push ends
          LLinkReach := Context.Heap.Allocate;
          if LLinkReach = nil then
          begin
            Context.Links.Unlink(LHead);
            Exit;
          end;
          LLinkReach^.AreaNum := LArea2Num;
          // the facenum is the Z velocity, the edgenum is the horizontal velocity
          LLinkReach^.FaceNum := Trunc(LVelocity[2]);
          LSqrtX := LVelocity[0] * LVelocity[0];
          LSqrtY := LVelocity[1] * LVelocity[1];
          LSumFloat := LSqrtX + LSqrtY;
          LRoot := Sqrt(Double(LSumFloat));
          LLinkReach^.EdgeNum := Trunc(LRoot);
          LLinkReach^.Start := LAreaStart;
          LLinkReach^.EndPoint := LMove.EndPos;
          LLinkReach^.TravelType := TRAVEL_JUMPPAD or Context.TravelFlagsForTeam(LEnt);
          LLinkReach^.TravelTime := TAasReachVectors.ToTravelTime(Context.Settings.RsJumpPad);
          Context.Heap.Push(Context.Links.AreaNum(LLink), LLinkReach);
          Inc(Context.Counters^.JumpPad);
          LLink := Context.Links.NextArea(LLink);
        end;
      end;
    end;
    // the original goes on with the next entity here without unlinking the entity
    if (Abs(Double(LVelocity[0])) > 100) or (Abs(Double(LVelocity[1])) > 100) then
    begin
      LEnt := Context.Entities.NextEntity(LEnt);
      Continue;
    end;
    // the areas that can be reached with air control
    LArea2Num := 1;
    while LArea2Num < Context.NumAreas do
    begin
      // never try to go back to one of the original jump pad areas and do not create reachabilities that exist already
      LLink := LHead;
      while LLink <> AAS_NO_LINK do
      begin
        if Context.ReachabilityExists(Context.Links.AreaNum(LLink), LArea2Num) then
          Break;
        if Context.AreaJumpPad(Context.Links.AreaNum(LLink)) then
          if Context.Links.AreaNum(LLink) = LArea2Num then
            Break;
        LLink := Context.Links.NextArea(LLink);
      end;
      if LLink <> AAS_NO_LINK then
      begin
        Inc(LArea2Num);
        Continue;
      end;
      LArea2 := Context.Areas[LArea2Num];
      for LI := 0 to LArea2.NumFaces - 1 do
      begin
        LFace2Num := Context.FaceIndex[LArea2.FirstFace + LI];
        LFace2 := Context.FaceTable[Abs(LFace2Num)];
        // if it is not a ground face
        if (LFace2.FaceFlags and FACE_GROUND) = 0 then
          Continue;
        // the original passes the face number with its sign to AAS_FaceCenter: a negative one is a zero face whose
        // center is not a number, so no test is true and no reachability is made
        if LFace2Num < 0 then
          Continue;
        Context.Geometry.FaceCenter(LFace2Num, LFaceCenter);
        // only go higher up
        if LFaceCenter[2] < LAreaStart[2] then
          Continue;
        // the jump pad jump z velocity
        LZVel := LVelocity[2];
        // the horizontal speed for the jump, if it can be calculated
        if Context.Movement.HorizontalVelocityForJump(LZVel, LAreaStart, LFaceCenter, LSpeed) and (LSpeed < 150) then
        begin
          // the direction towards the face center
          TAasVectorMath.Subtract(LFaceCenter, LAreaStart, LDir);
          LDir[2] := 0;
          TAasVectorMath.Normalize(LDir);
          TAasReachVectors.Scale(LDir, LSpeed, LCmdMove);
          Context.Movement.PredictClientMovement(LMove, -1, LAreaStart, PRESENCE_NORMAL, False, LVelocity, LCmdMove, 30,
            30, CTenthFloat, SE_ENTERWATER or SE_ENTERSLIME or SE_ENTERLAVA or SE_HITGROUNDDAMAGE or SE_TOUCHJUMPPAD or
            SE_TOUCHTELEPORTER or SE_HITGROUNDAREA, LArea2Num, False);
          // if the prediction time was enough: do not enter slime or lava and do not fall from too high
          if (LMove.Frames < 30) and ((LMove.StopEvent and (SE_ENTERSLIME or SE_ENTERLAVA or SE_HITGROUNDDAMAGE)) = 0)
             and ((LMove.StopEvent and (SE_HITGROUNDAREA or SE_TOUCHJUMPPAD or SE_TOUCHTELEPORTER)) <> 0) then
          begin
            // never go back to the same jump pad
            LLink := LHead;
            while (LLink <> AAS_NO_LINK) and (Context.Links.AreaNum(LLink) <> LMove.EndArea) do
              LLink := Context.Links.NextArea(LLink);
            if LLink = AAS_NO_LINK then
            begin
              LLink := LHead;
              while LLink <> AAS_NO_LINK do
              begin
                if (not Context.AreaJumpPad(Context.Links.AreaNum(LLink))) or
                   Context.ReachabilityExists(Context.Links.AreaNum(LLink), LArea2Num) then
                begin
                  LLink := Context.Links.NextArea(LLink);
                  Continue;
                end;
                LLinkReach := Context.Heap.Allocate;
                if LLinkReach = nil then
                begin
                  Context.Links.Unlink(LHead);
                  Exit;
                end;
                LLinkReach^.AreaNum := LMove.EndArea;
                LLinkReach^.FaceNum := Trunc(LVelocity[2]);
                LSqrtX := LCmdMove[0] * LCmdMove[0];
                LSqrtY := LCmdMove[1] * LCmdMove[1];
                LSumFloat := LSqrtX + LSqrtY;
                LRoot := Sqrt(Double(LSumFloat));
                LLinkReach^.EdgeNum := Trunc(LRoot);
                LLinkReach^.Start := LAreaStart;
                LLinkReach^.EndPoint := LFaceCenter;
                LLinkReach^.TravelType := TRAVEL_JUMPPAD or Context.TravelFlagsForTeam(LEnt);
                LLinkReach^.TravelTime := TAasReachVectors.ToTravelTime(Context.Settings.RsAirControlledJumpPad);
                Context.Heap.Push(Context.Links.AreaNum(LLink), LLinkReach);
                Inc(Context.Counters^.JumpPad);
                LLink := Context.Links.NextArea(LLink);
              end;
            end;
          end;
        end;
      end;
      Inc(LArea2Num);
    end;
    Context.Links.Unlink(LHead);
    LEnt := Context.Entities.NextEntity(LEnt);
  end;
end;

end.

{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - elevator (func_plat) reachabilities               }
{                                                                              }
{  Port of AAS_Reachability_Elevator of be_aas_reach.c. This is very game      }
{  dependent. Based on the Quake III Arena GPL Source Code (id Software).      }
{  Copyright (C) 1999-2005 Id Software, Inc. This unit is derived from the     }
{  Quake III Arena source code and is therefore available under the GNU        }
{  General Public License, version 2 or (at your option) any later version.    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Reach.Elevator;

{$Q-}
{$R+}

interface

uses
  DelphiDoom.Aas.Reach.Part;

type
  /// <summary>Reachabilities from the areas around a func_plat at the bottom to the areas around it at the top</summary>
  TAasReachElevator = class(TAasReachPart)
  strict private
    procedure Process(const AEnt: Integer);
  public
    /// <summary>AAS_Reachability_Elevator: for every func_plat of the map</summary>
    procedure Calculate;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.MathCore.Types, DelphiDoom.BotAi.Types, DelphiDoom.Aas.Types, DelphiDoom.Aas.Bsp.CNumbers,
  DelphiDoom.Aas.Printer, DelphiDoom.Aas.VectorMath, DelphiDoom.Aas.Reach.Types, DelphiDoom.Aas.Reach.Vectors;

{ TAasReachElevator }

procedure TAasReachElevator.Process(const AEnt: Integer);
var
  LClassName, LModel: AnsiString;
  LModelNum, LArea1Num, LArea2Num, LI, LJ, LK, LL, LN, LP: Integer;
  LLip, LHeight, LSpeed, LTime: Single;
  LMins, LMaxs, LOrigin, LAngles, LPos1, LPos2, LMids, LPlatBottom, LPlatTop, LBottomOrg, LTopOrg, LStart, LEnd,
  LDir: TVec3;
  LXValues, LYValues, LXValuesTop, LYValuesTop: array[0..7] of Single;
  LTrace: TAasTrace;
  LReach: PAasLinkedReach;
  LFound, LOutside: Boolean;
  LLimit: Single;
begin
  if not Context.Entities.ValueForKey(AEnt, 'classname', LClassName) then
    Exit;
  if LClassName <> 'func_plat' then
    Exit;
  if not Context.Entities.ValueForKey(AEnt, 'model', LModel) then
  begin
    TAasPrinter.Print(Context.Import, PRT_ERROR, 'func_plat without model'#10);
    Exit;
  end;
  // the model number, without the leading *
  LModelNum := TAasCNumbers.AtoI(Copy(LModel, 2, MaxInt));
  if LModelNum <= 0 then
  begin
    TAasPrinter.Print(Context.Import, PRT_ERROR, 'func_plat with invalid model number'#10);
    Exit;
  end;
  LAngles[0] := 0;
  LAngles[1] := 0;
  LAngles[2] := 0;
  // the origin is usually (0, 0, 0) and the mins and maxs are the absolute mins and maxs
  Context.Models.ModelMinsMaxsOrigin(LModelNum, LAngles, LMins, LMaxs, LOrigin);
  Context.Entities.VectorForKey(AEnt, 'origin', LOrigin);
  // pos1 is the top position, pos2 the bottom
  LPos1 := LOrigin;
  LPos2 := LOrigin;
  Context.Entities.FloatForKey(AEnt, 'lip', LLip);
  if LLip = 0 then
    LLip := 8;
  Context.Entities.FloatForKey(AEnt, 'height', LHeight);
  if LHeight = 0 then
  begin
    LHeight := LMaxs[2] - LMins[2];
    LHeight := LHeight - LLip;
  end;
  Context.Entities.FloatForKey(AEnt, 'speed', LSpeed);
  if LSpeed = 0 then
    LSpeed := 200;
  // the bottom position below pos1
  LPos2[2] := LPos2[2] - LHeight;
  // a point just above the plat in the bottom position
  TAasReachVectors.Add(LMins, LMaxs, LMids);
  TAasVectorMath.MultiplyAdd(LPos2, LMids, 0.5, LPlatBottom);
  LTime := LPos1[2] - LPos2[2];
  LTime := LMaxs[2] - LTime;
  LPlatBottom[2] := LTime + 2;
  // a point just above the plat in the top position
  TAasReachVectors.Add(LMins, LMaxs, LMids);
  TAasVectorMath.MultiplyAdd(LPos2, LMids, 0.5, LPlatTop);
  LPlatTop[2] := LMaxs[2] + 2;
  // the mins and maxs a little larger
  for LI := 0 to 2 do
  begin
    LMins[LI] := LMins[LI] - 1;
    LMaxs[LI] := LMaxs[LI] + 1;
  end;
  TAasReachVectors.Add(LMins, LMaxs, LMids);
  TAasReachVectors.Scale(LMids, 0.5, LMids);
  LXValues[0] := LMins[0]; LXValues[1] := LMids[0]; LXValues[2] := LMaxs[0]; LXValues[3] := LMids[0];
  LYValues[0] := LMids[1]; LYValues[1] := LMaxs[1]; LYValues[2] := LMids[1]; LYValues[3] := LMins[1];
  LXValues[4] := LMins[0]; LXValues[5] := LMaxs[0]; LXValues[6] := LMaxs[0]; LXValues[7] := LMins[0];
  LYValues[4] := LMaxs[1]; LYValues[5] := LMaxs[1]; LYValues[6] := LMins[1]; LYValues[7] := LMins[1];
  LArea1Num := 0;
  // the adjacent areas around the bottom of the plat
  for LI := 0 to 8 do
  begin
    if LI < 8 then
    begin
      // at the sides of the plat
      LBottomOrg[0] := LOrigin[0] + LXValues[LI];
      LBottomOrg[1] := LOrigin[1] + LYValues[LI];
      LBottomOrg[2] := LPlatBottom[2] + 16;
      // a grounded or swim area near the plat in the bottom position
      LArea1Num := Context.Sampler.PointAreaNum(LBottomOrg);
      LFound := False;
      LK := 0;
      while LK < 16 do
      begin
        if LArea1Num <> 0 then
          if Context.AreaGrounded(LArea1Num) or Context.AreaSwim(LArea1Num) then
          begin
            LFound := True;
            Break;
          end;
        LBottomOrg[2] := LBottomOrg[2] + 4;
        LArea1Num := Context.Sampler.PointAreaNum(LBottomOrg);
        Inc(LK);
      end;
      // if in solid
      if not LFound then
        Continue;
    end
    else
    begin
      // at the middle of the plat
      LBottomOrg := LPlatTop;
      LBottomOrg[2] := LBottomOrg[2] + 24;
      LArea1Num := Context.Sampler.PointAreaNum(LBottomOrg);
      if LArea1Num = 0 then
        Continue;
      LBottomOrg := LPlatBottom;
      LBottomOrg[2] := LBottomOrg[2] + 24;
    end;
    // the adjacent areas around the top of the plat, with larger steps to the outside every time
    LN := 0;
    while LN < 3 do
    begin
      for LK := 0 to 2 do
      begin
        LMins[LK] := LMins[LK] - 4;
        LMaxs[LK] := LMaxs[LK] + 4;
      end;
      LXValuesTop[0] := LMins[0]; LXValuesTop[1] := LMids[0]; LXValuesTop[2] := LMaxs[0]; LXValuesTop[3] := LMids[0];
      LYValuesTop[0] := LMids[1]; LYValuesTop[1] := LMaxs[1]; LYValuesTop[2] := LMids[1]; LYValuesTop[3] := LMins[1];
      LXValuesTop[4] := LMins[0]; LXValuesTop[5] := LMaxs[0]; LXValuesTop[6] := LMaxs[0]; LXValuesTop[7] := LMins[0];
      LYValuesTop[4] := LMaxs[1]; LYValuesTop[5] := LMaxs[1]; LYValuesTop[6] := LMins[1]; LYValuesTop[7] := LMins[1];
      for LJ := 0 to 7 do
      begin
        LTopOrg[0] := LOrigin[0] + LXValuesTop[LJ];
        LTopOrg[1] := LOrigin[1] + LYValuesTop[LJ];
        LTopOrg[2] := LPlatTop[2] + 16;
        // a grounded or swim area near the plat in the top position
        LArea2Num := Context.Sampler.PointAreaNum(LTopOrg);
        LFound := False;
        LL := 0;
        while LL < 16 do
        begin
          if LArea2Num <> 0 then
            if Context.AreaGrounded(LArea2Num) or Context.AreaSwim(LArea2Num) then
            begin
              LStart := LPlatTop;
              LStart[2] := LStart[2] + 32;
              LEnd := LTopOrg;
              LEnd[2] := LEnd[2] + 1;
              LTrace := Context.Tracer.TraceClientBBox(LStart, LEnd, PRESENCE_CROUCH, -1);
              if LTrace.Fraction >= 1 then
              begin
                LFound := True;
                Break;
              end;
            end;
          LTopOrg[2] := LTopOrg[2] + 4;
          LArea2Num := Context.Sampler.PointAreaNum(LTopOrg);
          Inc(LL);
        end;
        // if in solid
        if not LFound then
          Continue;
        // never create a reachability in the same area
        if LArea2Num = LArea1Num then
          Continue;
        // if the area is not grounded
        if not Context.AreaGrounded(LArea2Num) then
          Continue;
        // if there already is a reachability between the areas
        if Context.ReachabilityExists(LArea1Num, LArea2Num) then
          Continue;
        // if the reachability start is within the elevator bounding box
        TAasVectorMath.Subtract(LBottomOrg, LPlatBottom, LDir);
        TAasVectorMath.Normalize(LDir);
        LTime := 24 * LDir[0];
        LDir[0] := LBottomOrg[0] + LTime;
        LTime := 24 * LDir[1];
        LDir[1] := LBottomOrg[1] + LTime;
        LDir[2] := LBottomOrg[2];
        LOutside := False;
        LP := 0;
        while LP < 3 do
        begin
          LLimit := LOrigin[LP] + LMins[LP];
          if LDir[LP] < LLimit then
          begin
            LOutside := True;
            Break;
          end;
          LLimit := LOrigin[LP] + LMaxs[LP];
          if LDir[LP] > LLimit then
          begin
            LOutside := True;
            Break;
          end;
          Inc(LP);
        end;
        if not LOutside then
          Continue;
        LReach := Context.Heap.Allocate;
        if LReach = nil then
          Continue;
        LReach^.AreaNum := LArea2Num;
        // the facenum is the model number, the edgenum is the height
        LReach^.FaceNum := LModelNum;
        LReach^.EdgeNum := Trunc(LHeight);
        LReach^.Start := LDir;
        LReach^.EndPoint := LTopOrg;
        LReach^.TravelType := TRAVEL_ELEVATOR or Context.TravelFlagsForTeam(AEnt);
        LTime := LHeight * 100;
        LTime := LTime / LSpeed;
        LTime := Context.Settings.RsStartElevator + LTime;
        LReach^.TravelTime := TAasReachVectors.ToTravelTime(LTime);
        Context.Heap.Push(LArea1Num, LReach);
        // do not go any further to the outside
        LN := 9999;
        Inc(Context.Counters^.Elevator);
      end;
      Inc(LN);
    end;
  end;
end;

procedure TAasReachElevator.Calculate;
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

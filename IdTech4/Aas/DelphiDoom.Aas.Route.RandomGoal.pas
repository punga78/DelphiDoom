{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - a random goal area                                 }
{                                                                              }
{  Port of AAS_RandomGoalArea of be_aas_route.c. Based on the Quake III Arena   }
{  GPL Source Code (id Software). Copyright (C) 1999-2005 Id Software, Inc.     }
{  This unit is derived from the Quake III Arena source code and is therefore   }
{  available under the GNU General Public License, version 2 or (at your        }
{  option) any later version.                                                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Route.RandomGoal;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Types, DelphiDoom.BotAi.Import.Intf, DelphiDoom.Aas.Intf, DelphiDoom.Aas.Route.Intf,
  DelphiDoom.Aas.Reach.Intf;

type
  /// <summary>
  ///   Picks an area that the bot can reach, starting from a random number (the generator is injected so the tests
  ///   repeat): AAS_RandomGoalArea. Nothing is owned
  /// </summary>
  TAasRandomGoal = class
  strict private
    FFile: IAasFile;
    FSampler: IAasSampler;
    FTracer: IAasTracer;
    FRouter: IAasRouter;
    FAreas: IAasAreaQuery;
    FGeometry: IAasReachGeometry;
    FRandom: IBotRandom;
  public
    constructor Create(const AFile: IAasFile; const ASampler: IAasSampler; const ATracer: IAasTracer;
      const ARouter: IAasRouter; const AAreas: IAasAreaQuery; const AGeometry: IAasReachGeometry;
      const ARandom: IBotRandom);
    /// <summary>
    ///   False if the area has no reachabilities or no area was found after trying every one; otherwise the area
    ///   and the point to go to (the center for a swimmable area, the ground below it otherwise)
    /// </summary>
    function RandomGoalArea(const AAreaNum, ATravelFlags: Integer; out AGoalAreaNum: Integer;
      out AGoalOrigin: TVec3): Boolean;
  end;

implementation

uses
  DelphiDoom.Aas.Types;

constructor TAasRandomGoal.Create(const AFile: IAasFile; const ASampler: IAasSampler; const ATracer: IAasTracer;
  const ARouter: IAasRouter; const AAreas: IAasAreaQuery; const AGeometry: IAasReachGeometry;
  const ARandom: IBotRandom);
begin
  inherited Create;
  FFile := AFile;
  FSampler := ASampler;
  FTracer := ATracer;
  FRouter := ARouter;
  FAreas := AAreas;
  FGeometry := AGeometry;
  FRandom := ARandom;
end;

function TAasRandomGoal.RandomGoalArea(const AAreaNum, ATravelFlags: Integer; out AGoalAreaNum: Integer;
  out AGoalOrigin: TVec3): Boolean;
var
  LNumAreas, LIndex, LN, LTime: Integer;
  LCenter, LStart, LEnd: TVec3;
  LProduct: Single;
  LTrace: TAasTrace;
begin
  AGoalAreaNum := 0;
  FillChar(AGoalOrigin, SizeOf(AGoalOrigin), 0);
  Result := False;
  // if the area has no reachabilities
  if FAreas.AreaReachability(AAreaNum) = 0 then
    Exit;
  LNumAreas := Length(FFile.Areas);
  // int = int * float: the product is a float, cut
  LProduct := LNumAreas * FRandom.NextFloat;
  LN := Trunc(LProduct);
  for LIndex := 0 to LNumAreas - 1 do
  begin
    if LN <= 0 then
      LN := 1;
    if LN >= LNumAreas then
      LN := 1;
    if FAreas.AreaReachability(LN) <> 0 then
    begin
      LCenter := FFile.Areas[AAreaNum].Center;
      LTime := FRouter.AreaTravelTimeToGoalArea(AAreaNum, @LCenter, LN, ATravelFlags);
      // if the goal is reachable
      if LTime > 0 then
      begin
        if FAreas.AreaLiquid(LN) then
        begin
          AGoalAreaNum := LN;
          AGoalOrigin := FFile.Areas[LN].Center;
          Exit(True);
        end;
        LStart := FFile.Areas[LN].Center;
        LEnd := LStart;
        LEnd[2] := LEnd[2] - 300;
        LTrace := FTracer.TraceClientBBox(LStart, LEnd, PRESENCE_CROUCH, -1);
        if (not LTrace.StartSolid) and (LTrace.Fraction < 1) and (FSampler.PointAreaNum(LTrace.EndPos) = LN) then
          if FGeometry.AreaGroundFaceArea(LN) > 300 then
          begin
            AGoalAreaNum := LN;
            AGoalOrigin := LTrace.EndPos;
            Exit(True);
          end;
      end;
    end;
    Inc(LN);
  end;
end;

end.

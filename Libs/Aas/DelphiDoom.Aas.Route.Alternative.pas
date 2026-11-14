{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - alternative routes (be_aas_routealt.c)            }
{                                                                              }
{  Port of AAS_AlternativeRouteGoals and AAS_AltRoutingFloodCluster_r. Based   }
{  on the Quake III Arena GPL Source Code (id Software). Copyright (C)         }
{  1999-2005 Id Software, Inc. This unit is derived from the Quake III Arena   }
{  source code and is therefore available under the GNU General Public         }
{  License, version 2 or (at your option) any later version.                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Route.Alternative;

interface

uses
  System.SysUtils, DelphiDoom.MathCore.Types, DelphiDoom.Aas.Types, DelphiDoom.Aas.Intf,
  DelphiDoom.Aas.Route.Types, DelphiDoom.Aas.Route.Intf;

type
  /// <summary>
  ///   Finds the areas that an alternative route to a goal could go through: the areas that are reachable from the
  ///   start and from which the goal is reachable in a time that is a bit more and a bit less than the direct
  ///   one, grouped by the faces they share. The arrays of the file are shared, not owned
  /// </summary>
  TAasAlternativeRoutes = class
  strict private
    FAreas: TArray<TAasArea>;
    FFaces: TArray<TAasFace>;
    FFaceIndex: TArray<Integer>;
    FValid: TArray<Boolean>;
    FStartTime: TArray<Word>;
    FGoalTime: TArray<Word>;
    FClusterAreas: TArray<Integer>;
    FNumClusterAreas: Integer;
    procedure FloodCluster(const AAreaNum: Integer);
  public
    constructor Create(const AFile: IAasFile);
    /// <summary>
    ///   The goals go in <c>AGoals</c>, which is made as long as <c>AMaxGoals</c>; the result is how many there are
    /// </summary>
    function Find(const ARouter: IAasRouter; const ASettings: TArray<TAasAreaSettings>; const AStart: TVec3;
      const AStartAreaNum: Integer; const AGoal: TVec3; const AGoalAreaNum, ATravelFlags: Integer;
      var AGoals: TArray<TAasAltRouteGoal>; const AMaxGoals, AType: Integer): Integer;
  end;

implementation

uses
  DelphiDoom.Aas.VectorMath;

const
  // (float) 1.1 and (float) 0.8: the casts of the original give the float constants
  CLongest: Single = 1.10000002384185791015625;
  CShortest: Single = 0.800000011920928955078125;

{ TAasAlternativeRoutes }

constructor TAasAlternativeRoutes.Create(const AFile: IAasFile);
begin
  inherited Create;
  FAreas := AFile.Areas;
  FFaces := AFile.Faces;
  FFaceIndex := AFile.FaceIndex;
  SetLength(FValid, Length(FAreas));
  SetLength(FStartTime, Length(FAreas));
  SetLength(FGoalTime, Length(FAreas));
  SetLength(FClusterAreas, Length(FAreas));
end;

procedure TAasAlternativeRoutes.FloodCluster(const AAreaNum: Integer);
var
  LStackArea, LStackFace: TArray<Integer>;
  LTop, LArea, LOther, LFace: Integer;
begin
  // the recursion of the original, with a stack of (area, next face): the areas are taken in the same order
  SetLength(LStackArea, Length(FAreas) + 1);
  SetLength(LStackFace, Length(FAreas) + 1);
  LTop := 0;
  // add the current area to the areas of the current cluster
  FClusterAreas[FNumClusterAreas] := AAreaNum;
  Inc(FNumClusterAreas);
  // remove the area from the mid range areas
  FValid[AAreaNum] := False;
  LStackArea[0] := AAreaNum;
  LStackFace[0] := 0;
  while LTop >= 0 do
  begin
    LArea := LStackArea[LTop];
    if LStackFace[LTop] >= FAreas[LArea].NumFaces then
    begin
      Dec(LTop);
      Continue;
    end;
    // flood to other areas through the faces of this area
    LFace := Abs(FFaceIndex[FAreas[LArea].FirstFace + LStackFace[LTop]]);
    Inc(LStackFace[LTop]);
    // get the area at the other side of the face
    if FFaces[LFace].FrontArea = LArea then
      LOther := FFaces[LFace].BackArea
    else
      LOther := FFaces[LFace].FrontArea;
    // if there is an area at the other side of this face
    if LOther = 0 then
      Continue;
    // if the other area is not a midrange area
    if not FValid[LOther] then
      Continue;
    FClusterAreas[FNumClusterAreas] := LOther;
    Inc(FNumClusterAreas);
    FValid[LOther] := False;
    Inc(LTop);
    LStackArea[LTop] := LOther;
    LStackFace[LTop] := 0;
  end;
end;

function TAasAlternativeRoutes.Find(const ARouter: IAasRouter; const ASettings: TArray<TAasAreaSettings>;
  const AStart: TVec3; const AStartAreaNum: Integer; const AGoal: TVec3; const AGoalAreaNum, ATravelFlags: Integer;
  var AGoals: TArray<TAasAltRouteGoal>; const AMaxGoals, AType: Integer): Integer;
var
  LIndex, LJ, LBestArea, LStartTime, LGoalTime, LGoalTravelTime, LNumGoals: Integer;
  LStartPoint: TVec3;
  LMid, LDir: TVec3;
  LDist, LBestDist, LLimit: Single;
  LScale: Double;
begin
  Result := 0;
  // with room for no goal the original writes the first one past the end of the array: here there is none
  if (AStartAreaNum = 0) or (AGoalAreaNum = 0) or (AMaxGoals <= 0) then
    Exit;
  LStartPoint := AStart;
  // travel time towards the goal area
  LGoalTravelTime := ARouter.AreaTravelTimeToGoalArea(AStartAreaNum, @LStartPoint, AGoalAreaNum, ATravelFlags);
  // clear the midrange areas
  for LIndex := 0 to High(FValid) do
  begin
    FValid[LIndex] := False;
    FStartTime[LIndex] := 0;
    FGoalTime[LIndex] := 0;
  end;
  SetLength(AGoals, AMaxGoals);
  LNumGoals := 0;

  for LIndex := 1 to High(FAreas) do
  begin
    if (AType and ALTROUTEGOAL_ALL) = 0 then
      if not (((AType and ALTROUTEGOAL_CLUSTERPORTALS) <> 0) and
        ((ASettings[LIndex].Contents and AREACONTENTS_CLUSTERPORTAL) <> 0)) then
        if not (((AType and ALTROUTEGOAL_VIEWPORTALS) <> 0) and
          ((ASettings[LIndex].Contents and AREACONTENTS_VIEWPORTAL) <> 0)) then
          Continue;
    // if the area has no reachabilities
    if ASettings[LIndex].NumReachableAreas = 0 then
      Continue;
    // tavel time from the area to the start area
    LStartTime := ARouter.AreaTravelTimeToGoalArea(AStartAreaNum, @LStartPoint, LIndex, ATravelFlags);
    if LStartTime = 0 then
      Continue;
    // if the travel time from the start to the area is greater than the shortest goal travel time
    LLimit := CLongest * LGoalTravelTime;
    if LStartTime > LLimit then
      Continue;
    // travel time from the area to the goal area
    LGoalTime := ARouter.AreaTravelTimeToGoalArea(LIndex, nil, AGoalAreaNum, ATravelFlags);
    if LGoalTime = 0 then
      Continue;
    // if the travel time from the area to the goal is greater than the shortest goal travel time
    LLimit := CShortest * LGoalTravelTime;
    if LGoalTime > LLimit then
      Continue;
    // this is a mid range area
    FValid[LIndex] := True;
    FStartTime[LIndex] := Word(LStartTime);
    FGoalTime[LIndex] := Word(LGoalTime);
  end;

  for LIndex := 1 to High(FAreas) do
  begin
    if not FValid[LIndex] then
      Continue;
    // get the areas in one cluster
    FNumClusterAreas := 0;
    FloodCluster(LIndex);
    // now we've got a cluster with areas through which an alternative route could go
    // get the 'center' of the cluster
    LMid[0] := 0;
    LMid[1] := 0;
    LMid[2] := 0;
    for LJ := 0 to FNumClusterAreas - 1 do
    begin
      LMid[0] := LMid[0] + FAreas[FClusterAreas[LJ]].Center[0];
      LMid[1] := LMid[1] + FAreas[FClusterAreas[LJ]].Center[1];
      LMid[2] := LMid[2] + FAreas[FClusterAreas[LJ]].Center[2];
    end;
    // VectorScale( mid, 1.0 / numclusterareas, mid ): the scale is a double
    LScale := 1.0 / FNumClusterAreas;
    LMid[0] := LMid[0] * LScale;
    LMid[1] := LMid[1] * LScale;
    LMid[2] := LMid[2] * LScale;
    // get the area closest to the center of the cluster
    LBestDist := 999999;
    LBestArea := 0;
    for LJ := 0 to FNumClusterAreas - 1 do
    begin
      TAasVectorMath.Subtract(LMid, FAreas[FClusterAreas[LJ]].Center, LDir);
      LDist := TAasVectorMath.Length(LDir);
      if LDist < LBestDist then
      begin
        LBestDist := LDist;
        LBestArea := FClusterAreas[LJ];
      end;
    end;
    // now we've got an area for an alternative route
    AGoals[LNumGoals].Origin := FAreas[LBestArea].Center;
    AGoals[LNumGoals].AreaNum := LBestArea;
    AGoals[LNumGoals].StartTravelTime := FStartTime[LBestArea];
    AGoals[LNumGoals].GoalTravelTime := FGoalTime[LBestArea];
    AGoals[LNumGoals].ExtraTravelTime := Word((FStartTime[LBestArea] + FGoalTime[LBestArea]) - LGoalTravelTime);
    Inc(LNumGoals);
    // don't return more than the maximum alternative route goals
    if LNumGoals >= AMaxGoals then
      Break;
  end;
  Result := LNumGoals;
end;

end.

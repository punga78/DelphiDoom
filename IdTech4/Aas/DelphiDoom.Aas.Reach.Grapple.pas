{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - grapple hook reachabilities                       }
{                                                                              }
{  Port of AAS_Reachability_Grapple of be_aas_reach.c: never at ground faces,  }
{  always to a higher and pretty far area. Only calculated if the variable     }
{  grapplereach is set. Based on the Quake III Arena GPL Source Code (id       }
{  Software). Copyright (C) 1999-2005 Id Software, Inc. This unit is derived   }
{  from the Quake III Arena source code and is therefore available under the   }
{  GNU General Public License, version 2 or (at your option) any later         }
{  version.                                                                    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Reach.Grapple;

{$Q-}
{$R+}

interface

uses
  DelphiDoom.Aas.Reach.Part;

type
  /// <summary>Grapple hook reachabilities between two areas</summary>
  TAasReachGrapple = class(TAasReachPart)
  public
    /// <summary>AAS_Reachability_Grapple: the original makes the reachabilities and returns False all the same</summary>
    function Calculate(const AArea1, AArea2: Integer): Boolean;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.MathCore.Types, DelphiDoom.Aas.Types, DelphiDoom.Aas.Move.Types,
  DelphiDoom.Aas.VectorMath, DelphiDoom.Aas.Reach.Types, DelphiDoom.Aas.Reach.Vectors;

const
  // tan(2 * M_PI * 15 / 360): the minimal angle of the movement, 15 degrees
  CMinGrappleTangent: Double = 0.26794919243112270647;

{ TAasReachGrapple }

function TAasReachGrapple.Calculate(const AArea1, AArea2: Integer): Boolean;
var
  LI, LJ, LFace2Num, LAreaNum, LNumAreas: Integer;
  LArea1, LArea2: TAasArea;
  LFace2: TAasFace;
  LAreaStart, LFaceCenter, LStart, LEnd, LDir, LDown, LNormal, LVertex: TVec3;
  LTrace: TAasTrace;
  LBspTrace: TAasBspTrace;
  LHorizontalDistance, LZ, LDot, LQuotient, LLimit: Single;
  LAreas: TArray<Integer>;
  LPoints: TArray<TVec3>;
  LLink: PAasLinkedReach;
  LTime: Double;
  LClusterPortal: Boolean;
begin
  // only grapple when on the ground or swimming
  if not Context.AreaGrounded(AArea1) and not Context.AreaSwim(AArea1) then
    Exit(False);
  // do not grapple from a crouch area
  if (Context.AreaSettings[AArea1].PresenceType and PRESENCE_NORMAL) = 0 then
    Exit(False);
  // disabled for swim areas (it does not work right)
  if Context.AreaSwim(AArea1) then
    Exit(False);
  LArea1 := Context.Areas[AArea1];
  LArea2 := Context.Areas[AArea2];
  // do not grapple towards way lower areas
  if LArea2.Maxs[2] < LArea1.Mins[2] then
    Exit(False);
  LStart := LArea1.Center;
  LEnd := LStart;
  LEnd[2] := LEnd[2] - 1000;
  LTrace := Context.Tracer.TraceClientBBox(LStart, LEnd, PRESENCE_CROUCH, -1);
  if LTrace.StartSolid then
    Exit(False);
  LAreaStart := LTrace.EndPos;
  LDown[0] := 0;
  LDown[1] := 0;
  LDown[2] := -1;
  for LI := 0 to LArea2.NumFaces - 1 do
  begin
    LFace2Num := Context.FaceIndex[LArea2.FirstFace + LI];
    LFace2 := Context.FaceTable[Abs(LFace2Num)];
    // if it is not a solid face
    if (LFace2.FaceFlags and FACE_SOLID) = 0 then
      Continue;
    // the direction towards the first vertex of the face
    LVertex := Context.Vertexes[Context.Edges[Abs(Context.EdgeIndex[LFace2.FirstEdge])].Vertexes[0]];
    TAasVectorMath.Subtract(LVertex, LAreaStart, LDir);
    LNormal := Context.Planes[LFace2.PlaneNum].Normal;
    // if the face plane is facing away
    if TAasVectorMath.Dot(LNormal, LDir) > 0 then
      Continue;
    // the center of the face (the number keeps its sign, as in the original)
    Context.Geometry.FaceCenter(LFace2Num, LFaceCenter);
    // only go higher up with the grapple
    LLimit := LAreaStart[2] + 64;
    if LFaceCenter[2] < LLimit then
      Continue;
    // only use vertical faces or downward facing faces
    if TAasVectorMath.Dot(LNormal, LDown) < 0 then
      Continue;
    // the direction towards the face center
    TAasVectorMath.Subtract(LFaceCenter, LAreaStart, LDir);
    LZ := LDir[2];
    LDir[2] := 0;
    LHorizontalDistance := TAasVectorMath.Length(LDir);
    if LHorizontalDistance = 0 then
      Continue;
    // if too far
    if LHorizontalDistance > 2000 then
      Continue;
    // the minimal angle of the movement
    LQuotient := LZ / LHorizontalDistance;
    if LQuotient < CMinGrappleTangent then
      Continue;
    LStart := LFaceCenter;
    TAasReachVectors.MultiplyAdd(LFaceCenter, -500, LNormal, LEnd);
    LBspTrace := Context.World.Trace(LStart, nil, nil, LEnd, 0, BSP_CONTENTS_SOLID);
    // the grapple will not stick to the sky and the grapple point should be near the AAS wall
    LDot := LBspTrace.Fraction * 500;
    if ((LBspTrace.SurfaceFlags and SURF_SKY) <> 0) or (LDot > 32) then
      Continue;
    // trace a full bounding box from the area center on the ground to the center of the face
    TAasVectorMath.Subtract(LFaceCenter, LAreaStart, LDir);
    TAasVectorMath.Normalize(LDir);
    TAasReachVectors.MultiplyAdd(LAreaStart, 4, LDir, LStart);
    LEnd := LBspTrace.EndPos;
    LTrace := Context.Tracer.TraceClientBBox(LStart, LEnd, PRESENCE_NORMAL, -1);
    TAasVectorMath.Subtract(LTrace.EndPos, LFaceCenter, LDir);
    if TAasVectorMath.Length(LDir) > 24 then
      Continue;
    LStart := LTrace.EndPos;
    LEnd := LTrace.EndPos;
    LEnd[2] := LEnd[2] - Context.Physics.FallDamageDistance;
    LTrace := Context.Tracer.TraceClientBBox(LStart, LEnd, PRESENCE_NORMAL, -1);
    if LTrace.Fraction >= 1 then
      Continue;
    // the area to end in
    LAreaNum := Context.Sampler.PointAreaNum(LTrace.EndPos);
    // not in lava or slime
    if (Context.AreaSettings[LAreaNum].Contents and (AREACONTENTS_SLIME or AREACONTENTS_LAVA)) <> 0 then
      Continue;
    // do not go to the source area
    if LAreaNum = AArea1 then
      Continue;
    // do not create reachabilities if they already exist
    if Context.ReachabilityExists(AArea1, LAreaNum) then
      Continue;
    // only end in areas we can stand
    if not Context.AreaGrounded(LAreaNum) then
      Continue;
    // never go through cluster portals
    LNumAreas := Context.TraceAreas(LAreaStart, LBspTrace.EndPos, 20, LAreas, LPoints);
    if LNumAreas >= 20 then
      Continue;
    LClusterPortal := False;
    for LJ := 0 to LNumAreas - 1 do
      if (Context.AreaSettings[LAreas[LJ]].Contents and AREACONTENTS_CLUSTERPORTAL) <> 0 then
      begin
        LClusterPortal := True;
        Break;
      end;
    if LClusterPortal then
      Continue;
    LLink := Context.Heap.Allocate;
    if LLink = nil then
      Exit(False);
    LLink^.AreaNum := LAreaNum;
    LLink^.FaceNum := LFace2Num;
    LLink^.EdgeNum := 0;
    LLink^.Start := LAreaStart;
    LLink^.EndPoint := LBspTrace.EndPos;
    LLink^.TravelType := TRAVEL_GRAPPLEHOOK;
    TAasVectorMath.Subtract(LLink^.EndPoint, LLink^.Start, LDir);
    // rs + VectorLength(dir) * 0.25: a double
    LTime := TAasVectorMath.Length(LDir);
    LTime := LTime * 0.25;
    LTime := Context.Settings.RsStartGrapple + LTime;
    LLink^.TravelTime := TAasReachVectors.ToTravelTime(LTime);
    Context.Heap.Push(AArea1, LLink);
    Inc(Context.Counters^.Grapple);
  end;
  Result := False;
end;

end.

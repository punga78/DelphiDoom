{******************************************************************************}
{                                                                              }
{  DelphiDoom: collision library - sidedness caches                            }
{                                                                              }
{  Port of CM_SetVertexSidedness, CM_SetEdgeSidedness (translate.cpp) and      }
{  CM_SetTrmEdgeSidedness, CM_SetTrmPolygonSidedness (contents.cpp), Doom 3    }
{  GPL Source Code. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media   }
{  company. Doom 3 Source Code: GNU General Public License version 3 with      }
{  additional terms. This unit is a derived work (GPL v3).                     }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Collision.Sidedness;

interface

uses
  DelphiDoom.Geometry.Plane, DelphiDoom.Geometry.Pluecker, DelphiDoom.Collision.Model.Types;

type
  /// <summary>
  ///   The model vertices and edges cache, one bit per trace model edge or vertex, on which
  ///   side a line passes another (see the "side" and "sideSet" fields of the model)
  /// </summary>
  TCollisionSidedness = class sealed
  public
    /// <summary>
    ///   Stores for the model vertex at which side of one of the trm edges it passes
    ///   (CM_SetVertexSidedness). The bit is the sign bit of the permuted inner product
    /// </summary>
    class procedure SetVertex(AVertex: PCmVertex; const AVertexPluecker, AEdgePluecker: TGeoPluecker;
      ABitNum: Integer); static;
    /// <summary>
    ///   Stores for the model edge at which side one of the trm vertices (or edges) passes
    ///   (CM_SetEdgeSidedness and CM_SetTrmEdgeSidedness, which are the same operation)
    /// </summary>
    class procedure SetEdge(AEdge: PCmEdge; const ALinePluecker, AEdgePluecker: TGeoPluecker;
      ABitNum: Integer); static;
    /// <summary>
    ///   Stores on which side of a trm polygon plane the model vertex is (CM_SetTrmPolygonSidedness).
    ///   The bit is set for a strictly negative distance, not the float sign bit, which is
    ///   undetermined for 0.0
    /// </summary>
    class procedure SetVertexPolygon(AVertex: PCmVertex; const APlane: TGeoPlane; ABitNum: Integer); static;
  end;

implementation

uses
  DelphiDoom.Geometry.FloatMath;

{ TCollisionSidedness }

class procedure TCollisionSidedness.SetVertex(AVertex: PCmVertex; const AVertexPluecker,
  AEdgePluecker: TGeoPluecker; ABitNum: Integer);
var
  LMask: Cardinal;
  LValue: Single;
begin
  LMask := TGeoMath.BitMask(ABitNum);
  if (AVertex.SideSet and LMask) = 0 then
  begin
    LValue := AVertexPluecker.PermutedInnerProduct(AEdgePluecker);
    AVertex.Side := (AVertex.Side and not LMask) or (TGeoMath.FloatSignBitSet(LValue) shl (ABitNum and 31));
    AVertex.SideSet := AVertex.SideSet or LMask;
  end;
end;

class procedure TCollisionSidedness.SetEdge(AEdge: PCmEdge; const ALinePluecker,
  AEdgePluecker: TGeoPluecker; ABitNum: Integer);
var
  LMask: Cardinal;
  LValue: Single;
begin
  LMask := TGeoMath.BitMask(ABitNum);
  if (AEdge.SideSet and LMask) = 0 then
  begin
    LValue := ALinePluecker.PermutedInnerProduct(AEdgePluecker);
    AEdge.Side := (AEdge.Side and not LMask) or (TGeoMath.FloatSignBitSet(LValue) shl (ABitNum and 31));
    AEdge.SideSet := AEdge.SideSet or LMask;
  end;
end;

class procedure TCollisionSidedness.SetVertexPolygon(AVertex: PCmVertex; const APlane: TGeoPlane;
  ABitNum: Integer);
var
  LMask: Cardinal;
begin
  LMask := TGeoMath.BitMask(ABitNum);
  if (AVertex.SideSet and LMask) = 0 then
  begin
    if APlane.Distance(AVertex.P) < 0 then
      AVertex.Side := AVertex.Side or LMask
    else
      AVertex.Side := AVertex.Side and not LMask;
    AVertex.SideSet := AVertex.SideSet or LMask;
  end;
end;

end.

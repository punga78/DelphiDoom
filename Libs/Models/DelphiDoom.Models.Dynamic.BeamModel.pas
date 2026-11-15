{******************************************************************************}
{                                                                              }
{  DelphiDoom: models library - the beam model of Doom 3                       }
{                                                                              }
{  Port of idRenderModelBeam (renderer\Model_beam.cpp).                        }
{  Based on the Doom 3 GPL Source Code (id Software). This unit is derived     }
{  from it and is therefore available under the GNU General Public License,    }
{  version 3, with the additional terms of the Doom 3 Source Code License      }
{  (see Reference\doom3\README.txt and Libs\IdLib\README.md); the repository   }
{  as a whole is GPL v2 or later. Copyright (C) 1999-2011 id Software LLC.     }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Dynamic.BeamModel;

interface

uses
  System.SysUtils, DelphiDoom.IdLib.Math.Vec3, DelphiDoom.Geometry.Bounds, DelphiDoom.Models.Dynamic.Types;

type
  /// <summary>
  ///   A stretched quad between the origin of the entity and a target point (shader parameters 8 to 10, in world
  ///   coordinates) that faces the view, like a dynamic deform tube: the minor axis is the cross product of the beam and
  ///   the line from the view to the middle of the beam, normalized, and half the width of parameter 11 (a width
  ///   of 0 leaves it of length one). The snapshot depends on the view origin, so it is made for every view
  /// </summary>
  TBeamModel = class
  strict private
    class function ToLocal(const AEntity: TDynamicEntity; const APoint: TIdVec3): TIdVec3; static;
  public
    /// <summary>InstantiateDynamicModel for a view whose origin is AViewOrigin (world coordinates)</summary>
    function Instantiate(const AEntity: TDynamicEntity; const AViewOrigin: TIdVec3): TDynamicSnapshot;
    /// <summary>Bounds: the origin, the local target and, with a width, expanded by half of it (8 units without an entity)</summary>
    function Bounds(const AEntity: TDynamicEntity; AHasEntity: Boolean = True): TGeoBounds;
  end;

implementation

uses
  DelphiDoom.IdLib.Math.Math, DelphiDoom.Geometry.Vec3, DelphiDoom.Models.Static.Types;

{ TBeamModel }

class function TBeamModel.ToLocal(const AEntity: TDynamicEntity; const APoint: TIdVec3): TIdVec3;
var
  LTemp: TIdVec3;
begin
  // R_GlobalPointToLocal with the matrix of R_AxisToModelMatrix: the point from the origin on each axis
  LTemp := APoint - AEntity.Origin;
  Result.X := LTemp * AEntity.Axis.Rows[0];
  Result.Y := LTemp * AEntity.Axis.Rows[1];
  Result.Z := LTemp * AEntity.Axis.Rows[2];
end;

function TBeamModel.Instantiate(const AEntity: TDynamicEntity; const AViewOrigin: TIdVec3): TDynamicSnapshot;
var
  LTarget: TIdVec3;
  LLocalView, LLocalTarget: TIdVec3;
  LMajor, LMinor, LMid, LDirection: TIdVec3;
  LVertexes: TArray<TStaticDrawVert>;
  LColor: TStaticColor;
  LIndex: Integer;
  LTexture: array[0..3, 0..1] of Single;
begin
  LTarget := TIdVec3.Create(AEntity.ShaderParms[SHADERPARM_BEAM_END_X], AEntity.ShaderParms[SHADERPARM_BEAM_END_Y],
    AEntity.ShaderParms[SHADERPARM_BEAM_END_Z]);
  // the view direction projects the minor axis of the tube as the view changes
  LLocalView := ToLocal(AEntity, AViewOrigin);
  LLocalTarget := ToLocal(AEntity, LTarget);
  LMajor := LLocalTarget;
  LMid := LLocalTarget * 0.5;
  LDirection := LMid - LLocalView;
  LMinor.Cross(LMajor, LDirection);
  LMinor.Normalize;
  if AEntity.ShaderParms[SHADERPARM_BEAM_WIDTH] <> 0 then
    LMinor := LMinor * (AEntity.ShaderParms[SHADERPARM_BEAM_WIDTH] * 0.5);
  LColor := TStaticColor.Make(
    Byte(TIdMath.FtoiFast(AEntity.ShaderParms[SHADERPARM_RED] * 255.0)),
    Byte(TIdMath.FtoiFast(AEntity.ShaderParms[SHADERPARM_GREEN] * 255.0)),
    Byte(TIdMath.FtoiFast(AEntity.ShaderParms[SHADERPARM_BLUE] * 255.0)),
    Byte(TIdMath.FtoiFast(AEntity.ShaderParms[SHADERPARM_ALPHA] * 255.0)));

  SetLength(LVertexes, 4);
  LTexture[0, 0] := 0; LTexture[0, 1] := 0;
  LTexture[1, 0] := 0; LTexture[1, 1] := 1;
  LTexture[2, 0] := 1; LTexture[2, 1] := 0;
  LTexture[3, 0] := 1; LTexture[3, 1] := 1;
  for LIndex := 0 to 3 do
  begin
    LVertexes[LIndex].Clear;
    LVertexes[LIndex].St.X := LTexture[LIndex, 0];
    LVertexes[LIndex].St.Y := LTexture[LIndex, 1];
    LVertexes[LIndex].Color := LColor;
  end;
  LVertexes[0].Xyz := LMinor;
  LVertexes[1].Xyz := -LMinor;
  LVertexes[2].Xyz := LLocalTarget + LMinor;
  LVertexes[3].Xyz := LLocalTarget - LMinor;

  Result := Default(TDynamicSnapshot);
  Result.Name := BEAM_SNAPSHOT_NAME;
  Result.Surface.Id := 0;
  Result.Surface.MaterialName := STATIC_DEFAULT_MATERIAL;
  Result.Surface.HasGeometry := True;
  Result.Surface.Triangles.Verts := LVertexes;
  Result.Surface.Triangles.Indexes := [0, 2, 1, 2, 3, 1];
  Result.Bounds := Result.Surface.Triangles.CalcBounds;
end;

function TBeamModel.Bounds(const AEntity: TDynamicEntity; AHasEntity: Boolean): TGeoBounds;
var
  LTarget: TIdVec3;
  LLocal: TIdVec3;
begin
  Result.Zero;
  if not AHasEntity then
  begin
    Result.ExpandSelf(8.0);
    Exit;
  end;
  LTarget := TIdVec3.Create(AEntity.ShaderParms[SHADERPARM_BEAM_END_X], AEntity.ShaderParms[SHADERPARM_BEAM_END_Y],
    AEntity.ShaderParms[SHADERPARM_BEAM_END_Z]);
  LLocal := ToLocal(AEntity, LTarget);
  Result.AddPoint(TGeoVec3.Make(LLocal.X, LLocal.Y, LLocal.Z));
  if AEntity.ShaderParms[SHADERPARM_BEAM_WIDTH] <> 0 then
    Result.ExpandSelf(AEntity.ShaderParms[SHADERPARM_BEAM_WIDTH] * 0.5);
end;

end.

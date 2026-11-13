{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - the default model (a cube of 16 units)      }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): renderer\Model.cpp       }
{  (AddCubeFace, idRenderModelStatic::MakeDefaultModel). Copyright (C)         }
{  1999-2011 id Software LLC, a ZeniMax Media company. This unit is derived    }
{  from the Doom 3 GPL source code and is therefore available under the GNU    }
{  General Public License, version 3, with the additional terms of the Doom 3  }
{  Source Code License (see README.md of Libs\IdLib); the repository as a      }
{  whole is GPL v2 or later.                                                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Static.DefaultModel;

interface

uses
  System.SysUtils,
  DelphiDoom.Models.Static.Intf;

type
  /// <summary>
  ///   The model that stands for a model that cannot be loaded: a cube with a half side of 8
  ///   units and one surface of the default material, with generated normals (MakeDefaultModel
  ///   and FinishSurfaces).
  /// </summary>
  TStaticDefaultModel = class
  public
    /// <summary>The model with the name given (the original uses "_DEFAULT" and the name of the missing file)</summary>
    class function Build(const AName: string): IStaticModel; static;
    /// <summary>An empty model: no surfaces and the box at zero (InitEmpty)</summary>
    class function BuildEmpty(const AName: string): IStaticModel; static;
  end;

implementation

uses
  DelphiDoom.IdLib.Math.Vec2,
  DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.Models.Static.Types,
  DelphiDoom.Models.Static.Triangles,
  DelphiDoom.Models.Static.Model,
  DelphiDoom.Models.Static.SurfaceFinisher;

procedure AddCubeFace(var ATriangles: TStaticTriangles; const AV1, AV2, AV3, AV4: TIdVec3);
var
  LBase, LIndex: Integer;
  LCorners: array[0..3] of TIdVec3;
  LSt: array[0..3] of TIdVec2;
begin
  LCorners[0] := AV1;
  LCorners[1] := AV2;
  LCorners[2] := AV3;
  LCorners[3] := AV4;
  LSt[0] := TIdVec2.Create(0, 0);
  LSt[1] := TIdVec2.Create(1, 0);
  LSt[2] := TIdVec2.Create(1, 1);
  LSt[3] := TIdVec2.Create(0, 1);
  LBase := Length(ATriangles.Verts);
  SetLength(ATriangles.Verts, LBase + 4);
  for LIndex := 0 to 3 do
  begin
    ATriangles.Verts[LBase + LIndex].Clear;
    ATriangles.Verts[LBase + LIndex].Xyz := LCorners[LIndex] * 8;
    ATriangles.Verts[LBase + LIndex].St := LSt[LIndex];
  end;
  LIndex := Length(ATriangles.Indexes);
  SetLength(ATriangles.Indexes, LIndex + 6);
  ATriangles.Indexes[LIndex] := LBase;
  ATriangles.Indexes[LIndex + 1] := LBase + 1;
  ATriangles.Indexes[LIndex + 2] := LBase + 2;
  ATriangles.Indexes[LIndex + 3] := LBase;
  ATriangles.Indexes[LIndex + 4] := LBase + 2;
  ATriangles.Indexes[LIndex + 5] := LBase + 3;
end;

function V3(const AX, AY, AZ: Single): TIdVec3;
begin
  Result := TIdVec3.Create(AX, AY, AZ);
end;

{ TStaticDefaultModel }

class function TStaticDefaultModel.Build(const AName: string): IStaticModel;
var
  LModel: TStaticModel;
  LTriangles: TStaticTriangles;
begin
  LTriangles := Default(TStaticTriangles);
  AddCubeFace(LTriangles, V3(-1, 1, 1), V3(1, 1, 1), V3(1, -1, 1), V3(-1, -1, 1));
  AddCubeFace(LTriangles, V3(-1, 1, -1), V3(-1, -1, -1), V3(1, -1, -1), V3(1, 1, -1));
  AddCubeFace(LTriangles, V3(1, -1, 1), V3(1, 1, 1), V3(1, 1, -1), V3(1, -1, -1));
  AddCubeFace(LTriangles, V3(-1, -1, 1), V3(-1, -1, -1), V3(-1, 1, -1), V3(-1, 1, 1));
  AddCubeFace(LTriangles, V3(-1, -1, 1), V3(1, -1, 1), V3(1, -1, -1), V3(-1, -1, -1));
  AddCubeFace(LTriangles, V3(-1, 1, 1), V3(-1, 1, -1), V3(1, 1, -1), V3(1, 1, 1));
  LTriangles.GenerateNormals := True;
  LModel := TStaticModel.Create(AName);
  Result := LModel;
  LModel.AddSurface(STATIC_DEFAULT_MATERIAL);
  LModel.AddGeometry(0, TStaticSurfaceFinisher.Cleanup(LTriangles, True, False));
  LModel.Finish;
end;

class function TStaticDefaultModel.BuildEmpty(const AName: string): IStaticModel;
var
  LModel: TStaticModel;
begin
  LModel := TStaticModel.Create(AName);
  Result := LModel;
  LModel.Finish;
end;

end.

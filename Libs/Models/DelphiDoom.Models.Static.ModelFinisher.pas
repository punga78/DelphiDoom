{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - finishing a static model                    }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): renderer\Model.cpp       }
{  (idRenderModelStatic::FinishSurfaces). Copyright (C) 1999-2011 id Software  }
{  LLC, a ZeniMax Media company. This unit is derived from the Doom 3 GPL      }
{  source code and is therefore available under the GNU General Public         }
{  License, version 3, with the additional terms of the Doom 3 Source Code     }
{  License (see README.md of Libs\IdLib); the repository as a whole is GPL v2  }
{  or later.                                                                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Static.ModelFinisher;

interface

uses
  System.SysUtils,
  DelphiDoom.Models.Static.Intf,
  DelphiDoom.Models.Static.MaterialInfo.Intf;

type
  /// <summary>
  ///   What InitFromFile does after the loader has made the surfaces: the two sided surfaces
  ///   get their reversed copy, every surface is cleaned (degenerate triangles, mirrored
  ///   vertexes, normals and tangents) and the box of the model is the one of the surfaces.
  ///   The model given is not changed: a new one comes back. With <c>AFastLoad</c> (renderbump)
  ///   nothing is changed except the box. Not ported: the silhouette edges, the area of the
  ///   materials and the larger box of the materials with a deformation.
  /// </summary>
  TStaticModelFinisher = class
  public
    class function Finish(const AModel: IStaticModel; const AMaterials: IStaticMaterialInfo;
      const AFastLoad: Boolean): IStaticModel; static;
  end;

  /// <summary>The materials of a game that has none: nothing is two sided and the tangents are smooth</summary>
  TStaticMaterialInfoNone = class(TInterfacedObject, IStaticMaterialInfo)
  public
    function ShouldCreateBackSides(const AMaterialName: AnsiString): Boolean;
    function UseUnsmoothedTangents(const AMaterialName: AnsiString): Boolean;
  end;

implementation

uses
  DelphiDoom.Models.Static.Types,
  DelphiDoom.Models.Static.Triangles,
  DelphiDoom.Models.Static.Model,
  DelphiDoom.Models.Static.SurfaceFinisher;

resourcestring
  SStaticSurfaceNoGeometry = 'Model %s, surface %d had NULL geometry';

{ TStaticModelFinisher }

class function TStaticModelFinisher.Finish(const AModel: IStaticModel; const AMaterials: IStaticMaterialInfo;
  const AFastLoad: Boolean): IStaticModel;
var
  LResult: TStaticModel;
  LMaterials: IStaticMaterialInfo;
  LIndex, LOriginal, LSurface: Integer;
  LItem: TStaticSurface;
begin
  LMaterials := AMaterials;
  if LMaterials = nil then
    LMaterials := TStaticMaterialInfoNone.Create;
  LResult := TStaticModel.Create(AModel.Name);
  Result := LResult;
  LOriginal := AModel.NumSurfaces;
  for LIndex := 0 to LOriginal - 1 do
  begin
    LItem := AModel.Surfaces[LIndex];
    if not LItem.HasGeometry then
      raise EStaticModelException.CreateAtLine(Format(SStaticSurfaceNoGeometry, [AModel.Name, LIndex]), 0);
    LSurface := LResult.AddSurface(LItem.MaterialName);
    if AFastLoad then
      LResult.AddGeometry(LSurface, LItem.Triangles)
    else
      LResult.AddGeometry(LSurface, TStaticSurfaceFinisher.Cleanup(LItem.Triangles, LItem.Triangles.GenerateNormals,
        LMaterials.UseUnsmoothedTangents(LItem.MaterialName)));
  end;
  if not AFastLoad then
    // duplicate and reverse triangles for two sided bump mapped surfaces: separate surfaces,
    // because the tangent generation would not like the acute shared edges
    for LIndex := 0 to LOriginal - 1 do
    begin
      LItem := AModel.Surfaces[LIndex];
      if LMaterials.ShouldCreateBackSides(LItem.MaterialName) then
      begin
        LSurface := LResult.AddSurface(LItem.MaterialName);
        LResult.AddGeometry(LSurface, TStaticSurfaceFinisher.Cleanup(TStaticSurfaceFinisher.Reverse(LItem.Triangles),
          LItem.Triangles.GenerateNormals, LMaterials.UseUnsmoothedTangents(LItem.MaterialName)));
      end;
    end;
  LResult.Finish;
end;

{ TStaticMaterialInfoNone }

function TStaticMaterialInfoNone.ShouldCreateBackSides(const AMaterialName: AnsiString): Boolean;
begin
  Result := False;
end;

function TStaticMaterialInfoNone.UseUnsmoothedTangents(const AMaterialName: AnsiString): Boolean;
begin
  Result := False;
end;

end.

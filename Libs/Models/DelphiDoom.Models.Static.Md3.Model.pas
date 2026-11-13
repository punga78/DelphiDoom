{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - static models: the MD3 model                }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): renderer\Model_md3.cpp   }
{  (LerpMeshVertexes, InstantiateDynamicModel, Bounds). Copyright (C)          }
{  1999-2011 id Software LLC, a ZeniMax Media company. This unit is derived    }
{  from the Doom 3 GPL source code and is therefore available under the GNU    }
{  General Public License, version 3, with the additional terms of the Doom 3  }
{  Source Code License (see README.md of Libs\IdLib); the repository as a      }
{  whole is GPL v2 or later.                                                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Static.Md3.Model;

{$Q-}
{$R-}

interface

uses
  System.SysUtils,
  DelphiDoom.Geometry.Bounds,
  DelphiDoom.Models.Static.Intf,
  DelphiDoom.Models.Static.Md3.Types,
  DelphiDoom.Models.Static.Md3.Intf;

type
  /// <summary>The data of an MD3 file and its instances</summary>
  TMd3ModelData = class(TInterfacedObject, IMd3Model)
  strict private
    FData: TMd3Model;
    function GetName: string;
    function GetNumFrames: Integer;
    function GetNumTags: Integer;
    function GetNumSurfaces: Integer;
    function GetFrame(const AIndex: Integer): TMd3Frame;
    function GetTag(const AFrame, ATag: Integer): TMd3Tag;
    function GetSurface(const AIndex: Integer): TMd3Surface;
  public
    constructor Create(const AData: TMd3Model);
    function Bounds: TGeoBounds;
    function Instantiate(const AFrame, AOldFrame: Integer; const ABackLerp: Single): IStaticModel;
  end;

implementation

uses
  DelphiDoom.Geometry.Vec3,
  DelphiDoom.Models.Static.Types,
  DelphiDoom.Models.Static.Triangles,
  DelphiDoom.Models.Static.Model;

{ TMd3ModelData }

constructor TMd3ModelData.Create(const AData: TMd3Model);
begin
  inherited Create;
  FData := AData;
end;

function TMd3ModelData.GetName: string;
begin
  Result := string(FData.Name);
end;

function TMd3ModelData.GetNumFrames: Integer;
begin
  Result := Length(FData.Frames);
end;

function TMd3ModelData.GetNumTags: Integer;
begin
  Result := FData.NumTags;
end;

function TMd3ModelData.GetNumSurfaces: Integer;
begin
  Result := Length(FData.Surfaces);
end;

function TMd3ModelData.GetFrame(const AIndex: Integer): TMd3Frame;
begin
  if (AIndex < 0) or (AIndex > High(FData.Frames)) then
    raise EStaticModelException.CreateAtOffset(Format(SStaticMd3BadFrame, [AIndex, Length(FData.Frames)]), -1);
  Result := FData.Frames[AIndex];
end;

function TMd3ModelData.GetTag(const AFrame, ATag: Integer): TMd3Tag;
begin
  GetFrame(AFrame);
  if (ATag < 0) or (ATag >= FData.NumTags) then
    raise EArgumentOutOfRangeException.CreateFmt('Tag %d does not exist (%d tags)', [ATag, FData.NumTags]);
  Result := FData.Tags[AFrame * FData.NumTags + ATag];
end;

function TMd3ModelData.GetSurface(const AIndex: Integer): TMd3Surface;
begin
  if (AIndex < 0) or (AIndex > High(FData.Surfaces)) then
    raise EArgumentOutOfRangeException.CreateFmt('Surface %d does not exist (%d surfaces)',
      [AIndex, Length(FData.Surfaces)]);
  Result := FData.Surfaces[AIndex];
end;

function TMd3ModelData.Bounds: TGeoBounds;
begin
  Result := TGeoBounds.Cleared;
  Result.AddPoint(TGeoVec3.Make(FData.Frames[0].BoundsMin.X, FData.Frames[0].BoundsMin.Y, FData.Frames[0].BoundsMin.Z));
  Result.AddPoint(TGeoVec3.Make(FData.Frames[0].BoundsMax.X, FData.Frames[0].BoundsMax.Y, FData.Frames[0].BoundsMax.Z));
end;

function TMd3ModelData.Instantiate(const AFrame, AOldFrame: Integer; const ABackLerp: Single): IStaticModel;
var
  LModel: TStaticModel;
  LSurfaceIndex, LVertex, LBase, LOldBase: Integer;
  LSurface: TMd3Surface;
  LTriangles: TStaticTriangles;
  LNewScale, LOldScale: Single;
  LName: AnsiString;
begin
  GetFrame(AFrame);
  if ABackLerp <> 0 then
    GetFrame(AOldFrame);
  LModel := TStaticModel.Create(string(FData.Name));
  Result := LModel;
  for LSurfaceIndex := 0 to High(FData.Surfaces) do
  begin
    LSurface := FData.Surfaces[LSurfaceIndex];
    if AFrame >= LSurface.NumFrames then
      raise EStaticModelException.CreateAtOffset(Format(SStaticMd3BadFrame, [AFrame, LSurface.NumFrames]), -1);
    if (ABackLerp <> 0) and (AOldFrame >= LSurface.NumFrames) then
      raise EStaticModelException.CreateAtOffset(Format(SStaticMd3BadFrame, [AOldFrame, LSurface.NumFrames]), -1);
    if Length(LSurface.Shaders) > 0 then
      LName := LSurface.Shaders[0]
    else
      LName := STATIC_DEFAULT_MATERIAL;
    LTriangles.Verts := nil;
    SetLength(LTriangles.Verts, LSurface.NumVerts);
    LTriangles.Indexes := Copy(LSurface.Triangles);
    LTriangles.GenerateNormals := False;
    // the scale is a double in the original (1.0 / 64 * (1.0 - backlerp)) stored in a float
    LNewScale := (MD3_XYZ_SCALE * (1.0 - ABackLerp));
    LBase := AFrame * LSurface.NumVerts * 4;
    LOldBase := AOldFrame * LSurface.NumVerts * 4;
    LOldScale := (MD3_XYZ_SCALE * ABackLerp);
    for LVertex := 0 to LSurface.NumVerts - 1 do
    begin
      LTriangles.Verts[LVertex].Clear;
      if ABackLerp = 0 then
      begin
        LTriangles.Verts[LVertex].Xyz.X := LSurface.XyzNormals[LBase + LVertex * 4] * LNewScale;
        LTriangles.Verts[LVertex].Xyz.Y := LSurface.XyzNormals[LBase + LVertex * 4 + 1] * LNewScale;
        LTriangles.Verts[LVertex].Xyz.Z := LSurface.XyzNormals[LBase + LVertex * 4 + 2] * LNewScale;
      end
      else
      begin
        // interpolate the xyz
        LTriangles.Verts[LVertex].Xyz.X := LSurface.XyzNormals[LOldBase + LVertex * 4] * LOldScale +
          LSurface.XyzNormals[LBase + LVertex * 4] * LNewScale;
        LTriangles.Verts[LVertex].Xyz.Y := LSurface.XyzNormals[LOldBase + LVertex * 4 + 1] * LOldScale +
          LSurface.XyzNormals[LBase + LVertex * 4 + 1] * LNewScale;
        LTriangles.Verts[LVertex].Xyz.Z := LSurface.XyzNormals[LOldBase + LVertex * 4 + 2] * LOldScale +
          LSurface.XyzNormals[LBase + LVertex * 4 + 2] * LNewScale;
      end;
      LTriangles.Verts[LVertex].St := LSurface.St[LVertex];
    end;
    for LVertex := 0 to High(LTriangles.Indexes) do
      if (LTriangles.Indexes[LVertex] < 0) or (LTriangles.Indexes[LVertex] >= LSurface.NumVerts) then
        raise EStaticModelException.CreateAtOffset(Format(SStaticMd3Offset, ['triangle index', LTriangles.Indexes[LVertex],
          LSurface.NumVerts]), -1);
    LModel.AddGeometry(LModel.AddSurface(LName), LTriangles);
  end;
  LModel.Finish;
end;

end.

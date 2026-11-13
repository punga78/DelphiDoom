{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - one side of a brush                          }
{                                                                              }
{  Port of idMapBrushSide (MapFile.h, MapFile.cpp, idlib), Doom 3 GPL Source   }
{  Code. Based on the Doom 3 GPL Source Code (id Software). Copyright (C)      }
{  1999-2011 id Software LLC, a ZeniMax Media company. This unit is derived    }
{  from the Doom 3 GPL source code and is therefore available under the GNU    }
{  General Public License, version 3, with the additional terms of the Doom 3  }
{  Source Code License (see README.md of Libs\IdLib); the repository as a      }
{  whole is GPL v2 or later.                                                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.BrushSide;

interface

uses
  DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Plane, DelphiDoom.IdLib.Math.Vec4;

type
  /// <summary>
  ///   A plane with its material and texture matrix. The plane and the matrix are relative to
  ///   the origin of the entity, which the side remembers (it needs it for the texture vectors)
  /// </summary>
  TMapBrushSide = class
  strict private
    FMaterial: AnsiString;
    FPlane: TGeoPlane;
    FTextureMatrix: array[0..1] of TGeoVec3;
    FOrigin: TGeoVec3;
    function GetTextureMatrix(const AIndex: Integer): TGeoVec3;
    procedure SetTextureMatrix(const AIndex: Integer; const AValue: TGeoVec3);
  public
    /// <summary>The plane, the matrices and the origin start at zero (idMapBrushSide constructor)</summary>
    constructor Create;
    /// <summary>
    ///   The vectors that turn a point of the world into texture coordinates
    ///   (idMapBrushSide::GetTextureVectors): x, y and z, then the offset in w
    /// </summary>
    procedure GetTextureVectors(out AVectorS, AVectorT: TIdVec4);
    property Material: AnsiString read FMaterial write FMaterial;
    property Plane: TGeoPlane read FPlane write FPlane;
    /// <summary>Row 0 or 1 of the 2 x 3 texture matrix</summary>
    property TextureMatrix[const AIndex: Integer]: TGeoVec3 read GetTextureMatrix write SetTextureMatrix;
    property Origin: TGeoVec3 read FOrigin write FOrigin;
  end;

implementation

uses
  DelphiDoom.MapFile.TextureAxis;

{ TMapBrushSide }

constructor TMapBrushSide.Create;
begin
  inherited Create;
  FPlane := TGeoPlane.Make(0, 0, 0, 0);
  FTextureMatrix[0].Zero;
  FTextureMatrix[1].Zero;
  FOrigin.Zero;
end;

function TMapBrushSide.GetTextureMatrix(const AIndex: Integer): TGeoVec3;
begin
  Result := FTextureMatrix[AIndex];
end;

procedure TMapBrushSide.SetTextureMatrix(const AIndex: Integer; const AValue: TGeoVec3);
begin
  FTextureMatrix[AIndex] := AValue;
end;

procedure TMapBrushSide.GetTextureVectors(out AVectorS, AVectorT: TIdVec4);
var
  LTexX, LTexY: TGeoVec3;
  LNormal: TGeoVec3;
  LIndex: Integer;
  LResult: TIdVec4;
begin
  LNormal.SetValues(FPlane.A, FPlane.B, FPlane.C);
  TMapTextureAxis.ComputeAxisBase(LNormal, LTexX, LTexY);
  for LIndex := 0 to 1 do
  begin
    LResult.X := LTexX.X * FTextureMatrix[LIndex].X + LTexY.X * FTextureMatrix[LIndex].Y;
    LResult.Y := LTexX.Y * FTextureMatrix[LIndex].X + LTexY.Y * FTextureMatrix[LIndex].Y;
    LResult.Z := LTexX.Z * FTextureMatrix[LIndex].X + LTexY.Z * FTextureMatrix[LIndex].Y;
    LResult.W := FTextureMatrix[LIndex].Z +
      (FOrigin.X * LResult.X + FOrigin.Y * LResult.Y + FOrigin.Z * LResult.Z);
    if LIndex = 0 then
      AVectorS := LResult
    else
      AVectorT := LResult;
  end;
end;

end.

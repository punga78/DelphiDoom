{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - a "shadowModel" of a .proc file              }
{                                                                              }
{  Model of the shadow volume that idRenderWorldLocal::ParseShadowModel        }
{  builds (RenderWorld_load.cpp), Doom 3 GPL Source Code.                      }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Proc.ShadowModel;

interface

uses
  DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Bounds;

type
  /// <summary>
  ///   The shadow volume of a light ("_prelight_NAME"): the vertices (the fourth coordinate,
  ///   always 1 in the original, is not stored), the indexes, the two counts that separate the
  ///   caps from the sides and the bits of the cap planes
  /// </summary>
  TProcShadowModel = class
  strict private
    FName: AnsiString;
    FNumShadowIndexesNoCaps: Integer;
    FNumShadowIndexesNoFrontCaps: Integer;
    FShadowCapPlaneBits: Integer;
    FVertices: TArray<TGeoVec3>;
    FIndexes: TArray<Integer>;
  public
    constructor Create(const AName: AnsiString);
    property Name: AnsiString read FName write FName;
    property NumShadowIndexesNoCaps: Integer read FNumShadowIndexesNoCaps write FNumShadowIndexesNoCaps;
    property NumShadowIndexesNoFrontCaps: Integer read FNumShadowIndexesNoFrontCaps
      write FNumShadowIndexesNoFrontCaps;
    property ShadowCapPlaneBits: Integer read FShadowCapPlaneBits write FShadowCapPlaneBits;
    property Vertices: TArray<TGeoVec3> read FVertices write FVertices;
    property Indexes: TArray<Integer> read FIndexes write FIndexes;
    /// <summary>The bounds of the vertices (cleared, as idBounds::Clear, when there are none)</summary>
    function Bounds: TGeoBounds;
  end;

implementation

{ TProcShadowModel }

constructor TProcShadowModel.Create(const AName: AnsiString);
begin
  inherited Create;
  FName := AName;
end;

function TProcShadowModel.Bounds: TGeoBounds;
var
  LIndex: Integer;
begin
  Result := TGeoBounds.Cleared;
  for LIndex := 0 to High(FVertices) do
    Result.AddPoint(FVertices[LIndex]);
end;

end.

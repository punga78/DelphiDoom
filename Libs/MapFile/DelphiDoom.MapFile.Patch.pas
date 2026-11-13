{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - a patch (curved surface)                     }
{                                                                              }
{  Port of idMapPatch (MapFile.h, MapFile.cpp, idlib), Doom 3 GPL Source Code. }
{  Only the data of the control grid is ported; the tessellation of          }
{  idSurface_Patch (subdivision, normals, tangents) is not.                    }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Patch;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MapFile.Types, DelphiDoom.MapFile.Primitive;

type
  /// <summary>
  ///   A grid of control points, Width points per row and Height rows, stored by rows
  ///   (index = row * Width + column) like idSurface_Patch
  /// </summary>
  TMapPatch = class(TMapPrimitive)
  strict private
    FMaterial: AnsiString;
    FWidth: Integer;
    FHeight: Integer;
    FVertices: TArray<TMapPatchVertex>;
    FHorzSubdivisions: Integer;
    FVertSubdivisions: Integer;
    FExplicitlySubdivided: Boolean;
    function GetVertex(const AIndex: Integer): TMapPatchVertex;
    procedure SetVertex(const AIndex: Integer; const AValue: TMapPatchVertex);
  protected
    function GetPrimitiveType: TMapPrimitiveType; override;
  public
    /// <summary>An empty patch (the default constructor of idMapPatch)</summary>
    constructor Create; overload;
    /// <summary>A patch of the given size with all points at zero; raises EMapFileException if the size is not valid</summary>
    constructor Create(const AWidth, AHeight: Integer); overload;
    /// <summary>The number of control points, Width * Height</summary>
    function GetNumVertices: Integer;
    function GetGeometryCrc: Cardinal; override;
    property Material: AnsiString read FMaterial write FMaterial;
    property Width: Integer read FWidth;
    property Height: Integer read FHeight;
    /// <summary>Control point by index (row * Width + column)</summary>
    property Vertices[const AIndex: Integer]: TMapPatchVertex read GetVertex write SetVertex;
    property HorzSubdivisions: Integer read FHorzSubdivisions write FHorzSubdivisions;
    property VertSubdivisions: Integer read FVertSubdivisions write FVertSubdivisions;
    /// <summary>True for patchDef3 (the subdivisions are in the file), false for patchDef2</summary>
    property ExplicitlySubdivided: Boolean read FExplicitlySubdivided write FExplicitlySubdivided;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.MapFile.GeometryCrc;

resourcestring
  SMapPatchBadSize = 'idMapPatch: bad size %d x %d';

{ TMapPatch }

constructor TMapPatch.Create;
begin
  inherited Create;
end;

constructor TMapPatch.Create(const AWidth, AHeight: Integer);
begin
  inherited Create;
  if (AWidth < 0) or (AHeight < 0) or (Int64(AWidth) * AHeight > MAX_PATCH_VERTICES) then
    raise EMapFileException.CreateFmt(SMapPatchBadSize, [AWidth, AHeight]);
  FWidth := AWidth;
  FHeight := AHeight;
  SetLength(FVertices, AWidth * AHeight);
end;

function TMapPatch.GetPrimitiveType: TMapPrimitiveType;
begin
  Result := mptPatch;
end;

function TMapPatch.GetNumVertices: Integer;
begin
  Result := FWidth * FHeight;
end;

function TMapPatch.GetVertex(const AIndex: Integer): TMapPatchVertex;
begin
  Result := FVertices[AIndex];
end;

procedure TMapPatch.SetVertex(const AIndex: Integer; const AValue: TMapPatchVertex);
begin
  FVertices[AIndex] := AValue;
end;

function TMapPatch.GetGeometryCrc: Cardinal;
var
  LRow, LColumn: Integer;
  LPosition: Integer;
begin
  Result := Cardinal(FHorzSubdivisions) xor Cardinal(FVertSubdivisions);
  // the original walks the columns first; the exclusive or does not depend on the order
  for LColumn := 0 to FWidth - 1 do
  begin
    for LRow := 0 to FHeight - 1 do
    begin
      LPosition := LRow * FWidth + LColumn;
      Result := Result xor TMapGeometryCrc.FloatCrc(FVertices[LPosition].Position.X);
      Result := Result xor TMapGeometryCrc.FloatCrc(FVertices[LPosition].Position.Y);
      Result := Result xor TMapGeometryCrc.FloatCrc(FVertices[LPosition].Position.Z);
    end;
  end;
  Result := Result xor TMapGeometryCrc.StringCrc(FMaterial);
end;

end.

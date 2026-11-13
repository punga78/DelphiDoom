{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - a surface of a .proc model                   }
{                                                                              }
{  Model of a modelSurface_t with its srfTriangles_t (RenderWorld_load.cpp),   }
{  Doom 3 GPL Source Code.                                                     }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Proc.Surface;

interface

uses
  DelphiDoom.MapFile.Proc.Types;

type
  /// <summary>
  ///   A triangle list with a material: the name of the material (the catalogue of materials is
  ///   not the business of this library) and the vertices and indexes as the file has them
  /// </summary>
  TProcSurface = class
  strict private
    FMaterial: AnsiString;
    FVertices: TArray<TProcVertex>;
    FIndexes: TArray<Integer>;
  public
    property Material: AnsiString read FMaterial write FMaterial;
    property Vertices: TArray<TProcVertex> read FVertices write FVertices;
    /// <summary>Three indexes into <c>Vertices</c> for every triangle</summary>
    property Indexes: TArray<Integer> read FIndexes write FIndexes;
    function NumVertices: Integer;
    function NumIndexes: Integer;
  end;

implementation

{ TProcSurface }

function TProcSurface.NumVertices: Integer;
begin
  Result := Length(FVertices);
end;

function TProcSurface.NumIndexes: Integer;
begin
  Result := Length(FIndexes);
end;

end.

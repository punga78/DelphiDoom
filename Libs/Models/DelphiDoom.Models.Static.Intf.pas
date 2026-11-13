{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - static models (idTech 4): contracts         }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): renderer\Model_local.h   }
{  (idRenderModelStatic). Copyright (C) 1999-2011 id Software LLC, a ZeniMax   }
{  Media company. This unit is derived from the Doom 3 GPL source code and is  }
{  therefore available under the GNU General Public License, version 3, with   }
{  the additional terms of the Doom 3 Source Code License (see README.md of    }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Static.Intf;

interface

uses
  System.SysUtils,
  DelphiDoom.Geometry.Bounds,
  DelphiDoom.Models.Static.Types,
  DelphiDoom.Models.Static.Triangles;

type
  /// <summary>
  ///   A static model (idRenderModelStatic without the renderer): a list of surfaces with their
  ///   triangles and the box of all of them. Read only once built.
  /// </summary>
  IStaticModel = interface
    ['{3B8E6D52-4C1A-4E7F-9A03-7D2F51C8B6E4}']
    function GetName: string;
    function GetNumSurfaces: Integer;
    function GetSurface(const AIndex: Integer): TStaticSurface;
    function GetBounds: TGeoBounds;
    function GetWarnings: TArray<string>;
    /// <summary>The name given to the loader (the file name)</summary>
    property Name: string read GetName;
    property NumSurfaces: Integer read GetNumSurfaces;
    /// <summary>A surface; an index out of range is an EArgumentOutOfRangeException</summary>
    property Surfaces[const AIndex: Integer]: TStaticSurface read GetSurface;
    /// <summary>The union of the boxes of the surfaces (idRenderModelStatic::bounds)</summary>
    property Bounds: TGeoBounds read GetBounds;
    /// <summary>What the original prints with common->Warning while it loads</summary>
    property Warnings: TArray<string> read GetWarnings;
    function TotalVerts: Integer;
    function TotalIndexes: Integer;
  end;

  /// <summary>Reads the bytes of a file of one format and builds the model</summary>
  IStaticModelLoader = interface
    ['{9E4A1C77-0D5B-4B38-8F62-A13C7E905D20}']
    /// <summary>Raises EStaticModelException when the file cannot be read</summary>
    function Load(const AData: TBytes; const AName: string): IStaticModel;
  end;

implementation

end.

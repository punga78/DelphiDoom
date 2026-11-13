{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - constants, types and the error of the model  }
{                                                                              }
{  Port of the constants of MapFile.h (idlib), Doom 3 GPL Source Code.         }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Types;

interface

uses
  System.SysUtils, DelphiDoom.Geometry.Vec3, DelphiDoom.IdLib.Core.Exceptions;

const
  /// <summary>The version of the files without a "Version" line (OLD_MAP_VERSION)</summary>
  OLD_MAP_VERSION = 1;
  /// <summary>The version the writer produces (CURRENT_MAP_VERSION)</summary>
  CURRENT_MAP_VERSION = 2;
  DEFAULT_CURVE_SUBDIVISION = 4;
  /// <summary>Typed constants: a literal real of Delphi is an Extended</summary>
  DEFAULT_CURVE_MAX_ERROR: Single = 4.0;
  DEFAULT_CURVE_MAX_ERROR_CD: Single = 24.0;
  DEFAULT_CURVE_MAX_LENGTH: Single = -1.0;
  DEFAULT_CURVE_MAX_LENGTH_CD: Single = -1.0;
  /// <summary>
  ///   Upper bound of Width * Height of a patch. The original has no limit and allocates the
  ///   product of the two numbers of the file; a hostile file would exhaust the memory
  /// </summary>
  MAX_PATCH_VERTICES = 1 shl 20;
  /// <summary>Extensions tried by the reader (".reg" first, unless the region is ignored)</summary>
  MAP_EXTENSION = 'map';
  REGION_EXTENSION = 'reg';

type
  /// <summary>idMapPrimitive::TYPE_BRUSH and TYPE_PATCH (TYPE_INVALID is the base class)</summary>
  TMapPrimitiveType = (mptBrush, mptPatch);

  /// <summary>
  ///   A control point of a patch: the part of idDrawVert that a .map file holds (position and
  ///   texture coordinates; normal, tangents and colour are computed later by the engine)
  /// </summary>
  TMapPatchVertex = record
    Position: TGeoVec3;
    S: Single;
    T: Single;
  end;

  /// <summary>
  ///   A map file that cannot be read or written. For a text that is not valid the message is
  ///   the one of the lexer ("file F, line N: text") and <c>Line</c> is the line (0 when the
  ///   error does not come from the text)
  /// </summary>
  EMapFileException = class(EIdLibException)
  strict private
    FLine: Integer;
  public
    constructor Create(const AMessage: string; const ALine: Integer = 0);
    property Line: Integer read FLine;
  end;

implementation

{ EMapFileException }

constructor EMapFileException.Create(const AMessage: string; const ALine: Integer);
begin
  inherited Create(AMessage);
  FLine := ALine;
end;

end.

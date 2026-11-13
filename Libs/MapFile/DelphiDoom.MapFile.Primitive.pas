{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - the base of brushes and patches              }
{                                                                              }
{  Port of idMapPrimitive (MapFile.h, idlib), Doom 3 GPL Source Code.          }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Primitive;

interface

uses
  DelphiDoom.Scanner.IdDict, DelphiDoom.MapFile.Types;

type
  /// <summary>
  ///   A brush or a patch of an entity. It owns its key/value pairs (the editor puts them on
  ///   brushes and patches; the engine ignores them)
  /// </summary>
  TMapPrimitive = class abstract
  strict private
    FEpairs: TIdDict;
  protected
    function GetPrimitiveType: TMapPrimitiveType; virtual; abstract;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>The checksum of the geometry of the primitive (GetGeometryCRC)</summary>
    function GetGeometryCrc: Cardinal; virtual; abstract;
    property PrimitiveType: TMapPrimitiveType read GetPrimitiveType;
    property Epairs: TIdDict read FEpairs;
  end;

implementation

{ TMapPrimitive }

constructor TMapPrimitive.Create;
begin
  inherited Create;
  FEpairs := TIdDict.Create;
end;

destructor TMapPrimitive.Destroy;
begin
  FEpairs.Free;
  inherited Destroy;
end;

end.

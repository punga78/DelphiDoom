{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - writing an entity                            }
{                                                                              }
{  Port of idMapEntity::Write (MapFile.cpp, idlib), Doom 3 GPL Source Code.    }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.EntityWriter;

interface

uses
  DelphiDoom.MapFile.Entity, DelphiDoom.MapFile.TextWriter;

type
  /// <summary>Writes an entity with its key/value pairs and primitives</summary>
  TMapEntityWriter = class
  public
    /// <summary>
    ///   The "// entity N" comment and the entity (idMapEntity::Write). The primitives are
    ///   numbered from 0 in each entity; keys and values are written between quotes without any
    ///   escape, as the original does (a quote inside a value makes a file that cannot be read)
    /// </summary>
    class procedure Write(const AOutput: TMapTextWriter; const AEntity: TMapEntity;
      const AEntityNumber: Integer); static;
  end;

implementation

uses
  DelphiDoom.Geometry.Vec3, DelphiDoom.Scanner.IdDict, DelphiDoom.MapFile.Types, DelphiDoom.MapFile.Primitive,
  DelphiDoom.MapFile.Brush, DelphiDoom.MapFile.Patch, DelphiDoom.MapFile.BrushWriter,
  DelphiDoom.MapFile.PatchWriter;

{ TMapEntityWriter }

class procedure TMapEntityWriter.Write(const AOutput: TMapTextWriter; const AEntity: TMapEntity;
  const AEntityNumber: Integer);
var
  LIndex: Integer;
  LKeyValue: TIdKeyValue;
  LOrigin: TGeoVec3;
  LPrimitive: TMapPrimitive;
begin
  AOutput.Add('// entity ');
  AOutput.AddInteger(AEntityNumber);
  AOutput.Add(#10'{'#10);

  // write entity epairs
  for LIndex := 0 to AEntity.Epairs.GetNumKeyVals - 1 do
  begin
    AEntity.Epairs.TryGetKeyVal(LIndex, LKeyValue);
    AOutput.Add('"' + LKeyValue.Key + '" "' + LKeyValue.Value + '"'#10);
  end;

  with AEntity.Epairs.GetVector('origin', '0 0 0') do
    LOrigin.SetValues(X, Y, Z);

  // write primitives
  for LIndex := 0 to AEntity.GetNumPrimitives - 1 do
  begin
    LPrimitive := AEntity.GetPrimitive(LIndex);
    case LPrimitive.PrimitiveType of
      mptBrush:
        TMapBrushWriter.Write(AOutput, TMapBrush(LPrimitive), LIndex);
      mptPatch:
        TMapPatchWriter.Write(AOutput, TMapPatch(LPrimitive), LIndex, LOrigin);
    end;
  end;

  AOutput.Add('}'#10);
end;

end.

{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - writing an entity in the format of Quake III }
{                                                                              }
{  Written for this library after idMapEntity::Write (MapFile.cpp) of the      }
{  Doom 3 GPL Source Code.                                                     }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Q3EntityWriter;

interface

uses
  DelphiDoom.MapFile.Entity, DelphiDoom.MapFile.TextWriter;

type
  /// <summary>
  ///   Writes an entity with its pairs and its brushes and patches as GtkRadiant writes them for
  ///   Quake III: the primitives are numbered "// brush N" from 0 in the entity
  /// </summary>
  TMapQ3EntityWriter = class
  public
    class procedure Write(const AOutput: TMapTextWriter; const AEntity: TMapEntity;
      const AEntityNumber: Integer); static;
  end;

implementation

uses
  DelphiDoom.Geometry.Vec3, DelphiDoom.Scanner.IdDict, DelphiDoom.MapFile.Types, DelphiDoom.MapFile.Primitive,
  DelphiDoom.MapFile.Brush, DelphiDoom.MapFile.Patch, DelphiDoom.MapFile.Q3BrushWriter,
  DelphiDoom.MapFile.Q3PatchWriter;

{ TMapQ3EntityWriter }

class procedure TMapQ3EntityWriter.Write(const AOutput: TMapTextWriter; const AEntity: TMapEntity;
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
  for LIndex := 0 to AEntity.Epairs.GetNumKeyVals - 1 do
    if AEntity.Epairs.TryGetKeyVal(LIndex, LKeyValue) then
      AOutput.Add('"' + LKeyValue.Key + '" "' + LKeyValue.Value + '"'#10);

  with AEntity.Epairs.GetVector('origin', '0 0 0') do
    LOrigin.SetValues(X, Y, Z);

  for LIndex := 0 to AEntity.GetNumPrimitives - 1 do
  begin
    LPrimitive := AEntity.GetPrimitive(LIndex);
    case LPrimitive.PrimitiveType of
      mptBrush:
        TMapQ3BrushWriter.Write(AOutput, TMapBrush(LPrimitive), LIndex);
      mptPatch:
        TMapQ3PatchWriter.Write(AOutput, TMapPatch(LPrimitive), LIndex, LOrigin);
    end;
  end;
  AOutput.Add('}'#10);
end;

end.

{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - writing a patch                              }
{                                                                              }
{  Port of idMapPatch::Write (MapFile.cpp, idlib), Doom 3 GPL Source Code.     }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.PatchWriter;

interface

uses
  DelphiDoom.Geometry.Vec3, DelphiDoom.MapFile.Patch, DelphiDoom.MapFile.TextWriter;

type
  /// <summary>Writes a patch as patchDef3 (explicit subdivisions) or patchDef2</summary>
  TMapPatchWriter = class
  public
    /// <summary>
    ///   The "// primitive N" comment and the patch (idMapPatch::Write); the origin of the
    ///   entity is added back to the points, the reader takes it off. The key/value pairs of
    ///   the patch are not written (the original does not write them)
    /// </summary>
    class procedure Write(const AOutput: TMapTextWriter; const APatch: TMapPatch;
      const APrimitiveNumber: Integer; const AOrigin: TGeoVec3); static;
  end;

implementation

uses
  DelphiDoom.MapFile.Types;

{ TMapPatchWriter }

class procedure TMapPatchWriter.Write(const AOutput: TMapTextWriter; const APatch: TMapPatch;
  const APrimitiveNumber: Integer; const AOrigin: TGeoVec3);
var
  LColumn, LRow: Integer;
  LVertex: TMapPatchVertex;
begin
  AOutput.Add('// primitive ');
  AOutput.AddInteger(APrimitiveNumber);
  if APatch.ExplicitlySubdivided then
  begin
    AOutput.Add(#10'{'#10' patchDef3'#10' {'#10);
    AOutput.Add('  "' + APatch.Material + '"'#10'  ( ');
    AOutput.AddInteger(APatch.Width);
    AOutput.Add(' ');
    AOutput.AddInteger(APatch.Height);
    AOutput.Add(' ');
    AOutput.AddInteger(APatch.HorzSubdivisions);
    AOutput.Add(' ');
    AOutput.AddInteger(APatch.VertSubdivisions);
    AOutput.Add(' 0 0 0 )'#10);
  end
  else
  begin
    AOutput.Add(#10'{'#10' patchDef2'#10' {'#10);
    AOutput.Add('  "' + APatch.Material + '"'#10'  ( ');
    AOutput.AddInteger(APatch.Width);
    AOutput.Add(' ');
    AOutput.AddInteger(APatch.Height);
    AOutput.Add(' 0 0 0 )'#10);
  end;

  AOutput.Add('  ('#10);
  for LColumn := 0 to APatch.Width - 1 do
  begin
    AOutput.Add('   ( ');
    for LRow := 0 to APatch.Height - 1 do
    begin
      LVertex := APatch.Vertices[LRow * APatch.Width + LColumn];
      AOutput.Add(' ( ');
      AOutput.AddFloat(LVertex.Position.X + AOrigin.X);
      AOutput.Add(' ');
      AOutput.AddFloat(LVertex.Position.Y + AOrigin.Y);
      AOutput.Add(' ');
      AOutput.AddFloat(LVertex.Position.Z + AOrigin.Z);
      AOutput.Add(' ');
      AOutput.AddFloat(LVertex.S);
      AOutput.Add(' ');
      AOutput.AddFloat(LVertex.T);
      AOutput.Add(' )');
    end;
    AOutput.Add(' )'#10);
  end;
  AOutput.Add('  )'#10' }'#10'}'#10);
end;

end.

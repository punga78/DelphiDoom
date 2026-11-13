{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - writing a patch in the format of Quake III   }
{                                                                              }
{  Written for this library after idMapPatch::Write (MapFile.cpp) of the       }
{  Doom 3 GPL Source Code and the patchDef2 of GtkRadiant for Quake III Arena. }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Q3PatchWriter;

interface

uses
  DelphiDoom.Geometry.Vec3, DelphiDoom.MapFile.Patch, DelphiDoom.MapFile.TextWriter;

type
  /// <summary>
  ///   Writes a patch as patchDef2 with the material unquoted and without "textures/" (the
  ///   reader adds it to every material of a file without a version). Quake III has no patchDef3:
  ///   the explicit subdivisions of Doom 3 are not written
  /// </summary>
  TMapQ3PatchWriter = class
  strict private
    class function Material(const AName: AnsiString): AnsiString; static;
  public
    /// <summary>The "// brush N" comment and the patch; the origin of the entity is added to the points</summary>
    class procedure Write(const AOutput: TMapTextWriter; const APatch: TMapPatch; const ABrushNumber: Integer;
      const AOrigin: TGeoVec3); static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.MapFile.Types;

const
  TEXTURES_PREFIX: AnsiString = 'textures/';

{ TMapQ3PatchWriter }

class function TMapQ3PatchWriter.Material(const AName: AnsiString): AnsiString;
begin
  if SameText(string(Copy(AName, 1, Length(TEXTURES_PREFIX))), string(TEXTURES_PREFIX)) then
    Result := Copy(AName, Length(TEXTURES_PREFIX) + 1, MaxInt)
  else
    Result := AName;
end;

class procedure TMapQ3PatchWriter.Write(const AOutput: TMapTextWriter; const APatch: TMapPatch;
  const ABrushNumber: Integer; const AOrigin: TGeoVec3);
var
  LColumn, LRow: Integer;
  LVertex: TMapPatchVertex;
begin
  AOutput.Add('// brush ');
  AOutput.AddInteger(ABrushNumber);
  AOutput.Add(#10'{'#10'patchDef2'#10'{'#10);
  AOutput.Add(Material(APatch.Material) + #10'( ');
  AOutput.AddInteger(APatch.Width);
  AOutput.Add(' ');
  AOutput.AddInteger(APatch.Height);
  AOutput.Add(' 0 0 0 )'#10'('#10);
  for LColumn := 0 to APatch.Width - 1 do
  begin
    AOutput.Add('( ');
    for LRow := 0 to APatch.Height - 1 do
    begin
      LVertex := APatch.Vertices[LRow * APatch.Width + LColumn];
      AOutput.Add('( ');
      AOutput.AddFloat(LVertex.Position.X + AOrigin.X);
      AOutput.Add(' ');
      AOutput.AddFloat(LVertex.Position.Y + AOrigin.Y);
      AOutput.Add(' ');
      AOutput.AddFloat(LVertex.Position.Z + AOrigin.Z);
      AOutput.Add(' ');
      AOutput.AddFloat(LVertex.S);
      AOutput.Add(' ');
      AOutput.AddFloat(LVertex.T);
      AOutput.Add(' ) ');
    end;
    AOutput.Add(')'#10);
  end;
  AOutput.Add(')'#10'}'#10'}'#10);
end;

end.

{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - writing a brush                              }
{                                                                              }
{  Port of idMapBrush::Write (MapFile.cpp, idlib), Doom 3 GPL Source Code.     }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.BrushWriter;

interface

uses
  DelphiDoom.MapFile.Brush, DelphiDoom.MapFile.TextWriter;

type
  /// <summary>Writes a brush in the format brushDef3</summary>
  TMapBrushWriter = class
  public
    /// <summary>
    ///   The "// primitive N" comment and the brush (idMapBrush::Write). The planes are written as
    ///   they are: the origin of the entity is not added, as the reader does not take it off
    /// </summary>
    class procedure Write(const AOutput: TMapTextWriter; const ABrush: TMapBrush;
      const APrimitiveNumber: Integer); static;
  end;

implementation

uses
  DelphiDoom.Geometry.Vec3, DelphiDoom.MapFile.BrushSide, DelphiDoom.IdLib.Text.Strings,
  DelphiDoom.Scanner.IdDict;

{ TMapBrushWriter }

class procedure TMapBrushWriter.Write(const AOutput: TMapTextWriter; const ABrush: TMapBrush;
  const APrimitiveNumber: Integer);
var
  LIndex: Integer;
  LSide: TMapBrushSide;
  LKeyValue: TIdKeyValue;
  LRow: Integer;
  LMatrix: TGeoVec3;
begin
  AOutput.Add('// primitive ');
  AOutput.AddInteger(APrimitiveNumber);
  AOutput.Add(#10'{'#10' brushDef3'#10' {'#10);

  // write brush epairs
  for LIndex := 0 to ABrush.Epairs.GetNumKeyVals - 1 do
  begin
    ABrush.Epairs.TryGetKeyVal(LIndex, LKeyValue);
    AOutput.Add('  "' + LKeyValue.Key + '" "' + LKeyValue.Value + '"'#10);
  end;

  // write brush sides
  for LIndex := 0 to ABrush.GetNumSides - 1 do
  begin
    LSide := ABrush.GetSide(LIndex);
    AOutput.Add('  ( ');
    AOutput.AddFloat(LSide.Plane.A);
    AOutput.Add(' ');
    AOutput.AddFloat(LSide.Plane.B);
    AOutput.Add(' ');
    AOutput.AddFloat(LSide.Plane.C);
    AOutput.Add(' ');
    AOutput.AddFloat(LSide.Plane.D);
    AOutput.Add(' ) ( ');
    for LRow := 0 to 1 do
    begin
      LMatrix := LSide.TextureMatrix[LRow];
      AOutput.Add('( ');
      AOutput.AddFloat(LMatrix.X);
      AOutput.Add(' ');
      AOutput.AddFloat(LMatrix.Y);
      AOutput.Add(' ');
      AOutput.AddFloat(LMatrix.Z);
      AOutput.Add(' ) ');
    end;
    AOutput.Add(') "' + LSide.Material + '" 0 0 0'#10);
  end;

  AOutput.Add(' }'#10'}'#10);
end;

end.

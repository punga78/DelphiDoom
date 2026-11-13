{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - writing a "shadowModel" section of .proc     }
{                                                                              }
{  Port of WriteShadowTriangles and the "shadowModel" lines of WriteOutputFile }
{  (output.cpp of dmap), Doom 3 GPL Source Code.                               }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Proc.ShadowModelWriter;

interface

uses
  DelphiDoom.MapFile.TextWriter, DelphiDoom.MapFile.Proc.ShadowModel;

type
  /// <summary>Writes a shadow model as dmap does (five vertices and eighteen indexes on a line)</summary>
  TProcShadowModelWriter = class
  public
    class procedure Write(const AOutput: TMapTextWriter; const AModel: TProcShadowModel); static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Geometry.Vec3, DelphiDoom.MapFile.Proc.Types,
  DelphiDoom.MapFile.Proc.MatrixWriter;

{ TProcShadowModelWriter }

class procedure TProcShadowModelWriter.Write(const AOutput: TMapTextWriter;
  const AModel: TProcShadowModel);
var
  LIndex, LColumn: Integer;
  LVertex: TGeoVec3;
begin
  AOutput.Add(AnsiString(Format('shadowModel { /* name = */ "%s"'#10#10, [string(AModel.Name)])));
  AOutput.Add(AnsiString(Format('/* numVerts = */ %d /* noCaps = */ %d /* noFrontCaps = */ %d ' +
    '/* numIndexes = */ %d /* planeBits = */ %d'#10, [Length(AModel.Vertices),
    AModel.NumShadowIndexesNoCaps, AModel.NumShadowIndexesNoFrontCaps, Length(AModel.Indexes),
    AModel.ShadowCapPlaneBits])));
  LColumn := 0;
  for LIndex := 0 to High(AModel.Vertices) do
  begin
    LVertex := AModel.Vertices[LIndex];
    TProcMatrixWriter.Write1DMatrix(AOutput, [LVertex.X, LVertex.Y, LVertex.Z]);
    Inc(LColumn);
    if LColumn = PROC_SHADOW_VERTICES_PER_LINE then
    begin
      LColumn := 0;
      AOutput.Add(#10);
    end;
  end;
  if LColumn <> 0 then
    AOutput.Add(#10);
  TProcMatrixWriter.WriteIndexes(AOutput, AModel.Indexes);
  AOutput.Add('}'#10#10);
end;

end.

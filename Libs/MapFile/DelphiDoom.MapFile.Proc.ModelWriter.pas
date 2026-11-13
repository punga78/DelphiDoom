{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - writing a "model" section of .proc           }
{                                                                              }
{  Port of WriteOutputSurfaces and WriteUTriangles (output.cpp of dmap), Doom  }
{  3 GPL Source Code.                                                          }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Proc.ModelWriter;

interface

uses
  DelphiDoom.MapFile.TextWriter, DelphiDoom.MapFile.Proc.Model;

type
  /// <summary>
  ///   Writes a model as dmap does, with the same comments and line breaks (three vertices and
  ///   eighteen indexes on a line)
  /// </summary>
  TProcModelWriter = class
  public
    class procedure Write(const AOutput: TMapTextWriter; const AModel: TProcModel); static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.MapFile.Proc.Types, DelphiDoom.MapFile.Proc.Surface,
  DelphiDoom.MapFile.Proc.MatrixWriter;

{ TProcModelWriter }

class procedure TProcModelWriter.Write(const AOutput: TMapTextWriter; const AModel: TProcModel);
var
  LSurfaceIndex, LVertexIndex, LColumn: Integer;
  LSurface: TProcSurface;
  LVertex: TProcVertex;
begin
  AOutput.Add(AnsiString(Format('model { /* name = */ "%s" /* numSurfaces = */ %d'#10#10,
    [string(AModel.Name), AModel.NumSurfaces])));
  for LSurfaceIndex := 0 to AModel.NumSurfaces - 1 do
  begin
    LSurface := AModel.Surfaces[LSurfaceIndex];
    AOutput.Add(AnsiString(Format('/* surface %d */ { "%s" ', [LSurfaceIndex, string(LSurface.Material)])));
    AOutput.Add(AnsiString(Format('/* numVerts = */ %d /* numIndexes = */ %d'#10,
      [LSurface.NumVertices, LSurface.NumIndexes])));
    LColumn := 0;
    for LVertexIndex := 0 to LSurface.NumVertices - 1 do
    begin
      LVertex := LSurface.Vertices[LVertexIndex];
      TProcMatrixWriter.Write1DMatrix(AOutput, [LVertex.Position.X, LVertex.Position.Y, LVertex.Position.Z,
        LVertex.S, LVertex.T, LVertex.Normal.X, LVertex.Normal.Y, LVertex.Normal.Z]);
      Inc(LColumn);
      if LColumn = PROC_VERTICES_PER_LINE then
      begin
        LColumn := 0;
        AOutput.Add(#10);
      end;
    end;
    if LColumn <> 0 then
      AOutput.Add(#10);
    TProcMatrixWriter.WriteIndexes(AOutput, LSurface.Indexes);
    AOutput.Add('}'#10#10);
  end;
  AOutput.Add('}'#10#10);
end;

end.

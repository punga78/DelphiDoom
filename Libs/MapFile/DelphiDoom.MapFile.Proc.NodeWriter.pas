{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - writing "nodes" of .proc                     }
{                                                                              }
{  Port of WriteOutputNodes and WriteNode_r (output.cpp of dmap), Doom 3 GPL   }
{  Source Code.                                                                }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Proc.NodeWriter;

interface

uses
  DelphiDoom.MapFile.TextWriter, DelphiDoom.MapFile.Proc.ProcFile;

type
  /// <summary>
  ///   Writes the nodes in the order of the list (dmap writes them depth first, which is the
  ///   order the reader gives back); the number in the comment is the index
  /// </summary>
  TProcNodeWriter = class
  public
    class procedure Write(const AOutput: TMapTextWriter; const AFile: TProcFile); static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.MapFile.Proc.Types, DelphiDoom.MapFile.Proc.MatrixWriter;

{ TProcNodeWriter }

class procedure TProcNodeWriter.Write(const AOutput: TMapTextWriter; const AFile: TProcFile);
var
  LIndex: Integer;
  LNode: TProcNode;
begin
  AOutput.Add(AnsiString(Format('nodes { /* numNodes = */ %d'#10#10, [AFile.Nodes.Count])));
  AOutput.Add('/* node format is: ( planeVector ) positiveChild negativeChild */'#10);
  AOutput.Add('/* a child number of 0 is an opaque, solid area */'#10);
  AOutput.Add('/* negative child numbers are areas: (-1-child) */'#10);
  for LIndex := 0 to AFile.Nodes.Count - 1 do
  begin
    LNode := AFile.Nodes[LIndex];
    AOutput.Add(AnsiString(Format('/* node %d */ ', [LIndex])));
    TProcMatrixWriter.Write1DMatrix(AOutput, [LNode.Plane.A, LNode.Plane.B, LNode.Plane.C, LNode.Plane.D]);
    AOutput.Add(AnsiString(Format('%d %d'#10, [LNode.PositiveChild, LNode.NegativeChild])));
  end;
  AOutput.Add('}'#10#10);
end;

end.

{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - reading "nodes" of .proc                     }
{                                                                              }
{  Port of idRenderWorldLocal::ParseNodes (RenderWorld_load.cpp), Doom 3 GPL   }
{  Source Code.                                                                }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Proc.NodeReader;

interface

uses
  DelphiDoom.IdLib.Text.Lexer, DelphiDoom.MapFile.Proc.ProcFile;

type
  /// <summary>
  ///   Reads what follows the keyword "nodes": the number of nodes and, for each, the plane as
  ///   (a b c d) and the two children
  /// </summary>
  TProcNodeReader = class
  public
    /// <summary>Sets <c>HasNodeSection</c> and adds the nodes to the file</summary>
    class procedure Parse(const ALexer: TIdLexer; const AFile: TProcFile); static;
  end;

implementation

uses
  DelphiDoom.MapFile.Proc.Types, DelphiDoom.MapFile.Proc.Parse;

resourcestring
  SBadNumNodes = 'R_ParseNodes: bad numAreaNodes';

{ TProcNodeReader }

class procedure TProcNodeReader.Parse(const ALexer: TIdLexer; const AFile: TProcFile);
var
  LCount, LIndex: Integer;
  LValues: array[0..3] of Single;
  LNode: TProcNode;
begin
  ALexer.ExpectTokenString('{');
  LCount := TProcParse.ReadCount(ALexer, SBadNumNodes);
  AFile.HasNodeSection := True;
  for LIndex := 0 to LCount - 1 do
  begin
    ALexer.Parse1DMatrix(4, LValues);
    LNode.Plane.A := LValues[0];
    LNode.Plane.B := LValues[1];
    LNode.Plane.C := LValues[2];
    LNode.Plane.D := LValues[3];
    LNode.PositiveChild := ALexer.ParseInt;
    LNode.NegativeChild := ALexer.ParseInt;
    AFile.Nodes.Add(LNode);
  end;
  ALexer.ExpectTokenString('}');
end;

end.

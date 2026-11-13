{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - reading a "shadowModel" section of .proc     }
{                                                                              }
{  Port of idRenderWorldLocal::ParseShadowModel (RenderWorld_load.cpp),        }
{  Doom 3 GPL Source Code.                                                     }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Proc.ShadowModelReader;

interface

uses
  DelphiDoom.IdLib.Text.Lexer, DelphiDoom.MapFile.Proc.ShadowModel;

type
  /// <summary>
  ///   Reads what follows the keyword "shadowModel": the braces, the name, the five numbers
  ///   (vertices, indexes without caps, indexes without front caps, indexes, cap plane bits),
  ///   the vertices as (x y z) and the indexes
  /// </summary>
  TProcShadowModelReader = class
  public
    /// <summary>The caller owns the model</summary>
    class function Parse(const ALexer: TIdLexer): TProcShadowModel; static;
  end;

implementation

uses
  DelphiDoom.Geometry.Vec3, DelphiDoom.IdLib.Text.Token, DelphiDoom.MapFile.Proc.Parse;

resourcestring
  SBadNumVertices = 'R_ParseShadowModel: bad numVerts';
  SBadNumIndexes = 'R_ParseShadowModel: bad numIndexes';

{ TProcShadowModelReader }

class function TProcShadowModelReader.Parse(const ALexer: TIdLexer): TProcShadowModel;
var
  LToken: TIdToken;
  LVertexCount, LIndexCount, LIndex: Integer;
  LValues: array[0..2] of Single;
  LVertices: TArray<TGeoVec3>;
begin
  ALexer.ExpectTokenString('{');
  LToken := TIdToken.Create;
  ALexer.ExpectAnyToken(LToken);
  Result := TProcShadowModel.Create(LToken.Text);
  try
    LVertexCount := TProcParse.ReadCount(ALexer, SBadNumVertices);
    Result.NumShadowIndexesNoCaps := ALexer.ParseInt;
    Result.NumShadowIndexesNoFrontCaps := ALexer.ParseInt;
    LIndexCount := TProcParse.ReadCount(ALexer, SBadNumIndexes);
    Result.ShadowCapPlaneBits := ALexer.ParseInt;
    SetLength(LVertices, LVertexCount);
    for LIndex := 0 to LVertexCount - 1 do
    begin
      ALexer.Parse1DMatrix(3, LValues);
      LVertices[LIndex].X := LValues[0];
      LVertices[LIndex].Y := LValues[1];
      LVertices[LIndex].Z := LValues[2];
    end;
    Result.Vertices := LVertices;
    Result.Indexes := TProcParse.ReadIndexes(ALexer, LIndexCount);
    ALexer.ExpectTokenString('}');
  except
    Result.Free;
    raise;
  end;
end;

end.

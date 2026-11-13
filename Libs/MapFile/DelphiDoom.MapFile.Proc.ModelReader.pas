{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - reading a "model" section of .proc           }
{                                                                              }
{  Port of idRenderWorldLocal::ParseModel (RenderWorld_load.cpp), Doom 3 GPL   }
{  Source Code.                                                                }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Proc.ModelReader;

interface

uses
  DelphiDoom.IdLib.Text.Lexer, DelphiDoom.MapFile.Proc.Model, DelphiDoom.MapFile.Proc.Surface;

type
  /// <summary>
  ///   Reads what follows the keyword "model": the braces, the name, the number of surfaces and
  ///   the surfaces. The original asks the declaration manager for the material of every
  ///   surface and the model manager for an empty model; here the name of the material is kept
  ///   and the model is plain data
  /// </summary>
  TProcModelReader = class
  strict private
    class function ReadSurface(const ALexer: TIdLexer): TProcSurface; static;
  public
    /// <summary>The caller owns the model; an error of the lexer is raised as it is</summary>
    class function Parse(const ALexer: TIdLexer): TProcModel; static;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Token, DelphiDoom.MapFile.Proc.Types, DelphiDoom.MapFile.Proc.Parse;

resourcestring
  SBadNumSurfaces = 'R_ParseModel: bad numSurfaces';
  SBadNumVertices = 'R_ParseModel: bad numVerts';
  SBadNumIndexes = 'R_ParseModel: bad numIndexes';

{ TProcModelReader }

class function TProcModelReader.ReadSurface(const ALexer: TIdLexer): TProcSurface;
var
  LToken: TIdToken;
  LCount, LIndex: Integer;
  LValues: array[0..7] of Single;
  LVertices: TArray<TProcVertex>;
  LIndexCount: Integer;
begin
  ALexer.ExpectTokenString('{');
  LToken := TIdToken.Create;
  ALexer.ExpectAnyToken(LToken);
  Result := TProcSurface.Create;
  try
    Result.Material := LToken.Text;
    LCount := TProcParse.ReadCount(ALexer, SBadNumVertices);
    LIndexCount := TProcParse.ReadCount(ALexer, SBadNumIndexes);
    SetLength(LVertices, LCount);
    for LIndex := 0 to LCount - 1 do
    begin
      ALexer.Parse1DMatrix(8, LValues);
      LVertices[LIndex].Position.X := LValues[0];
      LVertices[LIndex].Position.Y := LValues[1];
      LVertices[LIndex].Position.Z := LValues[2];
      LVertices[LIndex].S := LValues[3];
      LVertices[LIndex].T := LValues[4];
      LVertices[LIndex].Normal.X := LValues[5];
      LVertices[LIndex].Normal.Y := LValues[6];
      LVertices[LIndex].Normal.Z := LValues[7];
    end;
    Result.Vertices := LVertices;
    Result.Indexes := TProcParse.ReadIndexes(ALexer, LIndexCount);
    ALexer.ExpectTokenString('}');
  except
    Result.Free;
    raise;
  end;
end;

class function TProcModelReader.Parse(const ALexer: TIdLexer): TProcModel;
var
  LToken: TIdToken;
  LCount, LIndex: Integer;
begin
  ALexer.ExpectTokenString('{');
  LToken := TIdToken.Create;
  ALexer.ExpectAnyToken(LToken);
  Result := TProcModel.Create(LToken.Text);
  try
    LCount := TProcParse.ReadCount(ALexer, SBadNumSurfaces);
    for LIndex := 0 to LCount - 1 do
      Result.AddSurface(ReadSurface(ALexer));
    ALexer.ExpectTokenString('}');
  except
    Result.Free;
    raise;
  end;
end;

end.

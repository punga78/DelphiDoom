{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - vectors of the "articulatedFigure"        }
{  declaration (reading)                                                       }
{                                                                              }
{  Port of the articulated figures of Doom 3 (id Software, GPL v3):            }
{  framework\DeclAF.cpp (idAFVector::Parse). Copyright (C) 1999-2011 id        }
{  Software LLC, a ZeniMax Media company. Based on the Doom 3 GPL Source Code  }
{  (id Software).                                                              }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.ArticulatedFigure.VectorParser;

interface

uses
  DelphiDoom.IdLib.Text.Lexer, DelphiDoom.Decl.ArticulatedFigure.Types;

type
  /// <summary>Reads an <c>idAFVector</c>: <c>( x, y, z )</c>, <c>joint( "a" )</c>, <c>bonecenter( "a", "b" )</c> or <c>bonedir( "a", "b" )</c>, with an optional <c>-</c> before</summary>
  TAfVectorParser = class sealed
  public
    /// <summary>
    ///   idAFVector::Parse. False when the text ends or the first word is not a known form (an error of the lexer);
    ///   the commas and brackets that are missing are errors of the lexer too, but the reading goes on as in the original.
    /// </summary>
    class function Parse(const ASource: TIdLexer; var AVector: TAfVector): Boolean; static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.IdLib.Text.Token;

{ TAfVectorParser }

class function TAfVectorParser.Parse(const ASource: TIdLexer; var AVector: TAfVector): Boolean;
var
  LToken: TIdToken;
  LX, LY, LZ: Single;

  function ReadName: AnsiString;
  begin
    ASource.ReadToken(LToken);
    Result := LToken.Text;
  end;

begin
  LToken := TIdToken.Create;
  if not ASource.ReadToken(LToken) then
    Exit(False);

  if LToken.IsText('-') then
  begin
    AVector.Negate := True;
    if not ASource.ReadToken(LToken) then
      Exit(False);
  end
  else
    AVector.Negate := False;

  if LToken.IsText('(') then
  begin
    AVector.Kind := avkCoords;
    // each ParseFloat is a separate statement: the order of the reads matters
    LX := ASource.ParseFloat;
    AVector.Vec.X := LX;
    ASource.ExpectTokenString(',');
    LY := ASource.ParseFloat;
    AVector.Vec.Y := LY;
    ASource.ExpectTokenString(',');
    LZ := ASource.ParseFloat;
    AVector.Vec.Z := LZ;
    ASource.ExpectTokenString(')');
  end
  else if LToken.IsText('joint') then
  begin
    AVector.Kind := avkJoint;
    ASource.ExpectTokenString('(');
    AVector.Joint1 := ReadName;
    ASource.ExpectTokenString(')');
  end
  else if LToken.IsText('bonecenter') then
  begin
    AVector.Kind := avkBoneCenter;
    ASource.ExpectTokenString('(');
    AVector.Joint1 := ReadName;
    ASource.ExpectTokenString(',');
    AVector.Joint2 := ReadName;
    ASource.ExpectTokenString(')');
  end
  else if LToken.IsText('bonedir') then
  begin
    AVector.Kind := avkBoneDir;
    ASource.ExpectTokenString('(');
    AVector.Joint1 := ReadName;
    ASource.ExpectTokenString(',');
    AVector.Joint2 := ReadName;
    ASource.ExpectTokenString(')');
  end
  else
  begin
    ASource.Error('unknown token %s in vector', [string(LToken.Text)]);
    Exit(False);
  end;
  Result := True;
end;

end.

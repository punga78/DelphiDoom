{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - constraints of the "articulatedFigure"    }
{  declaration (reading)                                                       }
{                                                                              }
{  Port of the articulated figures of Doom 3 (id Software, GPL v3):            }
{  framework\DeclAF.cpp (idDeclAF::ParseFixed, ParseBallAndSocketJoint,        }
{  ParseUniversalJoint, ParseHinge, ParseSlider, ParseSpring). Copyright (C)   }
{  1999-2011 id Software LLC, a ZeniMax Media company. Based on the Doom 3 GPL }
{  Source Code (id Software).                                                  }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.ArticulatedFigure.ConstraintParser;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.IdLib.Text.Lexer, DelphiDoom.IdLib.Text.Token, DelphiDoom.Decl.ArticulatedFigure.Types;

type
  /// <summary>
  ///   Reads the six kinds of constraint: <c>fixed</c>, <c>ballAndSocketJoint</c>, <c>universalJoint</c>, <c>hinge</c>,
  ///   <c>slider</c> and <c>spring</c> followed by <c>"name" { ... }</c>
  /// </summary>
  TAfConstraintParser = class sealed
  strict private
    class function Begin_(const ASource: TIdLexer; var AConstraint: TAfConstraint; const AType: TAfConstraintType;
      var AToken: TIdToken): Boolean; static;
    class function ReadBody(const ASource: TIdLexer; var AToken: TIdToken; var AConstraint: TAfConstraint): Boolean; static;
    class function Keyword(const AToken: TIdToken; const AName: AnsiString): Boolean; static;
    class function ParseFixed(const ASource: TIdLexer; var AConstraint: TAfConstraint): Boolean; static;
    class function ParseBallAndSocket(const ASource: TIdLexer; var AConstraint: TAfConstraint): Boolean; static;
    class function ParseUniversal(const ASource: TIdLexer; var AConstraint: TAfConstraint): Boolean; static;
    class function ParseHinge(const ASource: TIdLexer; var AConstraint: TAfConstraint): Boolean; static;
    class function ParseSlider(const ASource: TIdLexer; var AConstraint: TAfConstraint): Boolean; static;
    class function ParseSpring(const ASource: TIdLexer; var AConstraint: TAfConstraint): Boolean; static;
  public
    /// <summary>
    ///   idDeclAF::ParseFixed ... ParseSpring, by <c>AType</c>: <c>AConstraint</c> must have its defaults
    ///   (<c>SetDefault</c>) and the text is just after the word that names the kind. False after an error of the
    ///   lexer; what was read until then stays in <c>AConstraint</c>.
    /// </summary>
    class function Parse(const ASource: TIdLexer; var AConstraint: TAfConstraint;
      const AType: TAfConstraintType): Boolean; static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.IdLib.Text.Types, DelphiDoom.IdLib.Text.Strings,
  DelphiDoom.Decl.ArticulatedFigure.VectorParser;

{ TAfConstraintParser }

class function TAfConstraintParser.Keyword(const AToken: TIdToken; const AName: AnsiString): Boolean;
begin
  Result := TIdStrings.Icmp(AToken.Text, AName) = 0;
end;

// the name and the opening brace; then the kind and the name are set
class function TAfConstraintParser.Begin_(const ASource: TIdLexer; var AConstraint: TAfConstraint;
  const AType: TAfConstraintType; var AToken: TIdToken): Boolean;
begin
  AToken := TIdToken.Create;
  if not (ASource.ExpectTokenType(TT_STRING, 0, AToken) and ASource.ExpectTokenString('{')) then
    Exit(False);
  AConstraint.ConstraintType := AType;
  AConstraint.Name := AToken.Text;
  Result := True;
end;

// body1 and body2: the result of the read is not checked in the original
class function TAfConstraintParser.ReadBody(const ASource: TIdLexer; var AToken: TIdToken;
  var AConstraint: TAfConstraint): Boolean;
begin
  Result := True;
  if Keyword(AToken, 'body1') then
  begin
    ASource.ExpectTokenType(TT_STRING, 0, AToken);
    AConstraint.Body1 := AToken.Text;
  end
  else if Keyword(AToken, 'body2') then
  begin
    ASource.ExpectTokenType(TT_STRING, 0, AToken);
    AConstraint.Body2 := AToken.Text;
  end
  else
    Result := False;
end;

class function TAfConstraintParser.ParseFixed(const ASource: TIdLexer; var AConstraint: TAfConstraint): Boolean;
var
  LToken: TIdToken;
begin
  if not Begin_(ASource, AConstraint, actFixed, LToken) then
    Exit(False);
  while ASource.ReadToken(LToken) do
  begin
    if ReadBody(ASource, LToken, AConstraint) then
      Continue;
    if LToken.IsText('}') then
      Break;
    // the message of the original names the ball and socket joint
    ASource.Error('unknown token %s in ball and socket joint', [string(LToken.Text)]);
    Exit(False);
  end;
  Result := True;
end;

class function TAfConstraintParser.ParseBallAndSocket(const ASource: TIdLexer;
  var AConstraint: TAfConstraint): Boolean;
var
  LToken: TIdToken;
begin
  if not Begin_(ASource, AConstraint, actBallAndSocketJoint, LToken) then
    Exit(False);
  AConstraint.Limit := AF_LIMIT_NONE;
  AConstraint.Friction := 0.5;
  AConstraint.Anchor.Vec.Zero;
  AConstraint.Shaft[0].Vec.Zero;
  while ASource.ReadToken(LToken) do
  begin
    if ReadBody(ASource, LToken, AConstraint) then
      Continue;
    if Keyword(LToken, 'anchor') then
    begin
      if not TAfVectorParser.Parse(ASource, AConstraint.Anchor) then
        Exit(False);
    end
    else if Keyword(LToken, 'conelimit') then
    begin
      if not (TAfVectorParser.Parse(ASource, AConstraint.LimitAxis) and ASource.ExpectTokenString(',')) then
        Exit(False);
      AConstraint.LimitAngles[0] := ASource.ParseFloat;
      if not (ASource.ExpectTokenString(',') and TAfVectorParser.Parse(ASource, AConstraint.Shaft[0])) then
        Exit(False);
      AConstraint.Limit := AF_LIMIT_CONE;
    end
    else if Keyword(LToken, 'pyramidlimit') then
    begin
      if not (TAfVectorParser.Parse(ASource, AConstraint.LimitAxis) and ASource.ExpectTokenString(',')) then
        Exit(False);
      AConstraint.LimitAngles[0] := ASource.ParseFloat;
      if not ASource.ExpectTokenString(',') then
        Exit(False);
      AConstraint.LimitAngles[1] := ASource.ParseFloat;
      if not ASource.ExpectTokenString(',') then
        Exit(False);
      AConstraint.LimitAngles[2] := ASource.ParseFloat;
      if not (ASource.ExpectTokenString(',') and TAfVectorParser.Parse(ASource, AConstraint.Shaft[0])) then
        Exit(False);
      AConstraint.Limit := AF_LIMIT_PYRAMID;
    end
    else if Keyword(LToken, 'friction') then
      AConstraint.Friction := ASource.ParseFloat
    else if LToken.IsText('}') then
      Break
    else
    begin
      ASource.Error('unknown token %s in ball and socket joint', [string(LToken.Text)]);
      Exit(False);
    end;
  end;
  Result := True;
end;

class function TAfConstraintParser.ParseUniversal(const ASource: TIdLexer; var AConstraint: TAfConstraint): Boolean;
var
  LToken: TIdToken;
begin
  if not Begin_(ASource, AConstraint, actUniversalJoint, LToken) then
    Exit(False);
  AConstraint.Limit := AF_LIMIT_NONE;
  AConstraint.Friction := 0.5;
  AConstraint.Anchor.Vec.Zero;
  AConstraint.Shaft[0].Vec.Zero;
  AConstraint.Shaft[1].Vec.Zero;
  while ASource.ReadToken(LToken) do
  begin
    if ReadBody(ASource, LToken, AConstraint) then
      Continue;
    if Keyword(LToken, 'anchor') then
    begin
      if not TAfVectorParser.Parse(ASource, AConstraint.Anchor) then
        Exit(False);
    end
    else if Keyword(LToken, 'shafts') then
    begin
      if not (TAfVectorParser.Parse(ASource, AConstraint.Shaft[0]) and ASource.ExpectTokenString(',') and
        TAfVectorParser.Parse(ASource, AConstraint.Shaft[1])) then
        Exit(False);
    end
    else if Keyword(LToken, 'conelimit') then
    begin
      if not (TAfVectorParser.Parse(ASource, AConstraint.LimitAxis) and ASource.ExpectTokenString(',')) then
        Exit(False);
      AConstraint.LimitAngles[0] := ASource.ParseFloat;
      AConstraint.Limit := AF_LIMIT_CONE;
    end
    else if Keyword(LToken, 'pyramidlimit') then
    begin
      if not (TAfVectorParser.Parse(ASource, AConstraint.LimitAxis) and ASource.ExpectTokenString(',')) then
        Exit(False);
      AConstraint.LimitAngles[0] := ASource.ParseFloat;
      if not ASource.ExpectTokenString(',') then
        Exit(False);
      AConstraint.LimitAngles[1] := ASource.ParseFloat;
      if not ASource.ExpectTokenString(',') then
        Exit(False);
      AConstraint.LimitAngles[2] := ASource.ParseFloat;
      AConstraint.Limit := AF_LIMIT_PYRAMID;
    end
    else if Keyword(LToken, 'friction') then
      AConstraint.Friction := ASource.ParseFloat
    else if LToken.IsText('}') then
      Break
    else
    begin
      ASource.Error('unknown token %s in universal joint', [string(LToken.Text)]);
      Exit(False);
    end;
  end;
  Result := True;
end;

class function TAfConstraintParser.ParseHinge(const ASource: TIdLexer; var AConstraint: TAfConstraint): Boolean;
var
  LToken: TIdToken;
begin
  if not Begin_(ASource, AConstraint, actHinge, LToken) then
    Exit(False);
  AConstraint.Limit := AF_LIMIT_NONE;
  AConstraint.Friction := 0.5;
  AConstraint.Anchor.Vec.Zero;
  AConstraint.Axis.Vec.Zero;
  while ASource.ReadToken(LToken) do
  begin
    if ReadBody(ASource, LToken, AConstraint) then
      Continue;
    if Keyword(LToken, 'anchor') then
    begin
      if not TAfVectorParser.Parse(ASource, AConstraint.Anchor) then
        Exit(False);
    end
    else if Keyword(LToken, 'axis') then
    begin
      if not TAfVectorParser.Parse(ASource, AConstraint.Axis) then
        Exit(False);
    end
    else if Keyword(LToken, 'limit') then
    begin
      AConstraint.LimitAngles[0] := ASource.ParseFloat;
      if not ASource.ExpectTokenString(',') then
        Exit(False);
      AConstraint.LimitAngles[1] := ASource.ParseFloat;
      if not ASource.ExpectTokenString(',') then
        Exit(False);
      AConstraint.LimitAngles[2] := ASource.ParseFloat;
      AConstraint.Limit := AF_LIMIT_CONE;
    end
    else if Keyword(LToken, 'friction') then
      AConstraint.Friction := ASource.ParseFloat
    else if LToken.IsText('}') then
      Break
    else
    begin
      ASource.Error('unknown token %s in hinge', [string(LToken.Text)]);
      Exit(False);
    end;
  end;
  Result := True;
end;

class function TAfConstraintParser.ParseSlider(const ASource: TIdLexer; var AConstraint: TAfConstraint): Boolean;
var
  LToken: TIdToken;
begin
  if not Begin_(ASource, AConstraint, actSlider, LToken) then
    Exit(False);
  AConstraint.Limit := AF_LIMIT_NONE;
  AConstraint.Friction := 0.5;
  while ASource.ReadToken(LToken) do
  begin
    if ReadBody(ASource, LToken, AConstraint) then
      Continue;
    if Keyword(LToken, 'axis') then
    begin
      if not TAfVectorParser.Parse(ASource, AConstraint.Axis) then
        Exit(False);
    end
    else if Keyword(LToken, 'friction') then
      AConstraint.Friction := ASource.ParseFloat
    else if LToken.IsText('}') then
      Break
    else
    begin
      ASource.Error('unknown token %s in slider', [string(LToken.Text)]);
      Exit(False);
    end;
  end;
  Result := True;
end;

class function TAfConstraintParser.ParseSpring(const ASource: TIdLexer; var AConstraint: TAfConstraint): Boolean;
var
  LToken: TIdToken;
begin
  if not Begin_(ASource, AConstraint, actSpring, LToken) then
    Exit(False);
  AConstraint.Limit := AF_LIMIT_NONE;
  AConstraint.Friction := 0.5;
  while ASource.ReadToken(LToken) do
  begin
    if ReadBody(ASource, LToken, AConstraint) then
      Continue;
    if Keyword(LToken, 'anchor1') then
    begin
      if not TAfVectorParser.Parse(ASource, AConstraint.Anchor) then
        Exit(False);
    end
    else if Keyword(LToken, 'anchor2') then
    begin
      if not TAfVectorParser.Parse(ASource, AConstraint.Anchor2) then
        Exit(False);
    end
    else if Keyword(LToken, 'friction') then
      AConstraint.Friction := ASource.ParseFloat
    else if Keyword(LToken, 'stretch') then
      AConstraint.Stretch := ASource.ParseFloat
    else if Keyword(LToken, 'compress') then
      AConstraint.Compress := ASource.ParseFloat
    else if Keyword(LToken, 'damping') then
      AConstraint.Damping := ASource.ParseFloat
    else if Keyword(LToken, 'restLength') then
      AConstraint.RestLength := ASource.ParseFloat
    else if Keyword(LToken, 'minLength') then
      AConstraint.MinLength := ASource.ParseFloat
    else if Keyword(LToken, 'maxLength') then
      AConstraint.MaxLength := ASource.ParseFloat
    else if LToken.IsText('}') then
      Break
    else
    begin
      ASource.Error('unknown token %s in spring', [string(LToken.Text)]);
      Exit(False);
    end;
  end;
  Result := True;
end;

class function TAfConstraintParser.Parse(const ASource: TIdLexer; var AConstraint: TAfConstraint;
  const AType: TAfConstraintType): Boolean;
begin
  case AType of
    actFixed: Result := ParseFixed(ASource, AConstraint);
    actBallAndSocketJoint: Result := ParseBallAndSocket(ASource, AConstraint);
    actUniversalJoint: Result := ParseUniversal(ASource, AConstraint);
    actHinge: Result := ParseHinge(ASource, AConstraint);
    actSlider: Result := ParseSlider(ASource, AConstraint);
    actSpring: Result := ParseSpring(ASource, AConstraint);
  else
    raise EDeclArticulatedFigureException.Create('a constraint needs a kind to be read');
  end;
end;

end.

{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - bodies of the "articulatedFigure"         }
{  declaration (reading)                                                       }
{                                                                              }
{  Port of the articulated figures of Doom 3 (id Software, GPL v3):            }
{  framework\DeclAF.cpp (idDeclAF::ParseBody). Copyright (C) 1999-2011 id      }
{  Software LLC, a ZeniMax Media company. Based on the Doom 3 GPL Source Code  }
{  (id Software).                                                              }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.ArticulatedFigure.BodyParser;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.IdLib.Text.Lexer, DelphiDoom.Decl.ArticulatedFigure.Types;

type
  /// <summary>Reads <c>body "name" { ... }</c>: the model, the joint, the masses, the frictions and the masks</summary>
  TAfBodyParser = class sealed
  strict private
    class function ParseModel(const ASource: TIdLexer; var ABody: TAfBody): Boolean; static;
  public
    /// <summary>
    ///   idDeclAF::ParseBody. <c>ABody</c> must have its defaults (<c>SetDefault</c>); the text is just after the word
    ///   <c>body</c>. False after an error of the lexer: a word it does not know, a body named <c>origin</c> or
    ///   <c>world</c>, a model <c>custom</c> (not implemented in the original) or a body without a joint. The values read
    ///   until then stay in <c>ABody</c>.
    /// </summary>
    class function Parse(const ASource: TIdLexer; var ABody: TAfBody): Boolean; static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.IdLib.Text.Token, DelphiDoom.IdLib.Text.Types, DelphiDoom.IdLib.Text.Strings,
  DelphiDoom.IdLib.Math.Vec3, DelphiDoom.MathCore.Float.Angles, DelphiDoom.Decl.Material.Types,
  DelphiDoom.Decl.ArticulatedFigure.VectorParser, DelphiDoom.Decl.ArticulatedFigure.Contents;

{ TAfBodyParser }

// "( v1, v2 )" after the name of a box, an octahedron or a dodecahedron
class function TAfBodyParser.ParseModel(const ASource: TIdLexer; var ABody: TAfBody): Boolean;
var
  LToken: TIdToken;

  function Keyword(const AName: AnsiString): Boolean;
  begin
    Result := TIdStrings.Icmp(LToken.Text, AName) = 0;
  end;

  // "( v1, v2" : the same prefix for every shape
  function TwoVectors: Boolean;
  begin
    Result := ASource.ExpectTokenString('(') and TAfVectorParser.Parse(ASource, ABody.V1) and
      ASource.ExpectTokenString(',') and TAfVectorParser.Parse(ASource, ABody.V2);
  end;

  function Close: Boolean;
  begin
    Result := ASource.ExpectTokenString(')');
  end;

begin
  LToken := TIdToken.Create;
  if not ASource.ExpectTokenType(TT_NAME, 0, LToken) then
    Exit(False);
  if Keyword('box') then
  begin
    ABody.ModelType := abmBox;
    Result := TwoVectors and Close;
  end
  else if Keyword('octahedron') then
  begin
    ABody.ModelType := abmOctahedron;
    Result := TwoVectors and Close;
  end
  else if Keyword('dodecahedron') then
  begin
    ABody.ModelType := abmDodecahedron;
    Result := TwoVectors and Close;
  end
  else if Keyword('cylinder') then
  begin
    ABody.ModelType := abmCylinder;
    if not (TwoVectors and ASource.ExpectTokenString(',')) then
      Exit(False);
    ABody.NumSides := ASource.ParseInt;
    Result := Close;
  end
  else if Keyword('cone') then
  begin
    ABody.ModelType := abmCone;
    if not (TwoVectors and ASource.ExpectTokenString(',')) then
      Exit(False);
    ABody.NumSides := ASource.ParseInt;
    Result := Close;
  end
  else if Keyword('bone') then
  begin
    ABody.ModelType := abmBone;
    if not (TwoVectors and ASource.ExpectTokenString(',')) then
      Exit(False);
    ABody.Width := ASource.ParseFloat;
    Result := Close;
  end
  else if Keyword('custom') then
  begin
    ASource.Error('custom models not yet implemented', []);
    Result := False;
  end
  else
  begin
    // the typo of the original message is kept
    ASource.Error('unkown model type %s', [string(LToken.Text)]);
    Result := False;
  end;
end;

class function TAfBodyParser.Parse(const ASource: TIdLexer; var ABody: TAfBody): Boolean;
var
  LToken: TIdToken;
  LHasJoint: Boolean;
  LAngles: TAfVector;
  LMatrix: array[0..8] of Single;
  LIndex: Integer;
  LValue: Single;

  function Keyword(const AName: AnsiString): Boolean;
  begin
    Result := TIdStrings.Icmp(LToken.Text, AName) = 0;
  end;

begin
  LHasJoint := False;
  LToken := TIdToken.Create;
  LAngles := TAfVector.Create;

  if not (ASource.ExpectTokenType(TT_STRING, 0, LToken) and ASource.ExpectTokenString('{')) then
    Exit(False);

  ABody.Name := LToken.Text;
  if (TIdStrings.Icmp(ABody.Name, 'origin') = 0) or (TIdStrings.Icmp(ABody.Name, 'world') = 0) then
  begin
    ASource.Error('a body may not be named "origin" or "world"', []);
    Exit(False);
  end;

  while ASource.ReadToken(LToken) do
  begin
    if Keyword('model') then
    begin
      if not ParseModel(ASource, ABody) then
        Exit(False);
    end
    else if Keyword('origin') then
    begin
      if not TAfVectorParser.Parse(ASource, ABody.Origin) then
        Exit(False);
    end
    else if Keyword('angles') then
    begin
      if not TAfVectorParser.Parse(ASource, LAngles) then
        Exit(False);
      ABody.Angles := TIdAngles.Create(LAngles.Vec.X, LAngles.Vec.Y, LAngles.Vec.Z);
    end
    else if Keyword('joint') then
    begin
      if not ASource.ExpectTokenType(TT_STRING, 0, LToken) then
        Exit(False);
      ABody.JointName := LToken.Text;
      LHasJoint := True;
    end
    else if Keyword('mod') then
    begin
      if not ASource.ExpectAnyToken(LToken) then
        Exit(False);
      ABody.JointMod := TAfContents.JointModFromString(LToken.Text);
    end
    else if Keyword('density') then
      ABody.Density := ASource.ParseFloat
    else if Keyword('inertiaScale') then
    begin
      for LIndex := 0 to 8 do
        LMatrix[LIndex] := ABody.InertiaScale.Rows[LIndex div 3].Items[LIndex mod 3];
      ASource.Parse1DMatrix(9, LMatrix);
      for LIndex := 0 to 8 do
        ABody.InertiaScale.Rows[LIndex div 3].Items[LIndex mod 3] := LMatrix[LIndex];
    end
    else if Keyword('friction') then
    begin
      LValue := ASource.ParseFloat;
      ABody.LinearFriction := LValue;
      ASource.ExpectTokenString(',');
      LValue := ASource.ParseFloat;
      ABody.AngularFriction := LValue;
      ASource.ExpectTokenString(',');
      LValue := ASource.ParseFloat;
      ABody.ContactFriction := LValue;
    end
    else if Keyword('contents') then
      ABody.Contents := TAfContents.ParseContents(ASource)
    else if Keyword('clipMask') then
      ABody.ClipMask := TAfContents.ParseContents(ASource)
    else if Keyword('selfCollision') then
      ABody.SelfCollision := ASource.ParseBool
    else if Keyword('containedjoints') then
    begin
      if not ASource.ExpectTokenType(TT_STRING, 0, LToken) then
        Exit(False);
      ABody.ContainedJoints := LToken.Text;
    end
    else if Keyword('frictionDirection') then
    begin
      if not TAfVectorParser.Parse(ASource, ABody.FrictionDirection) then
        Exit(False);
    end
    else if Keyword('contactMotorDirection') then
    begin
      if not TAfVectorParser.Parse(ASource, ABody.ContactMotorDirection) then
        Exit(False);
    end
    else if LToken.IsText('}') then
      Break
    else
    begin
      ASource.Error('unknown token %s in body', [string(LToken.Text)]);
      Exit(False);
    end;
  end;

  // the default is a box: the check of the original never fires
  if ABody.ModelType = abmInvalid then
  begin
    ASource.Error('no model set for body', []);
    Exit(False);
  end;

  if not LHasJoint then
  begin
    ASource.Error('no joint set for body', []);
    Exit(False);
  end;

  ABody.ClipMask := ABody.ClipMask or CONTENTS_MOVEABLECLIP;
  Result := True;
end;

end.

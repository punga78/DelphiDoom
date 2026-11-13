{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - settings of the "articulatedFigure"       }
{  declaration (reading)                                                       }
{                                                                              }
{  Port of the articulated figures of Doom 3 (id Software, GPL v3):            }
{  framework\DeclAF.cpp (idDeclAF::ParseSettings). Copyright (C) 1999-2011 id  }
{  Software LLC, a ZeniMax Media company. Based on the Doom 3 GPL Source Code  }
{  (id Software).                                                              }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.ArticulatedFigure.SettingsParser;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.IdLib.Text.Lexer, DelphiDoom.Decl.ArticulatedFigure.Types;

type
  /// <summary>Reads <c>settings { ... }</c>: model, skin, frictions, suspend speed, movement limits, mass and masks</summary>
  TAfSettingsParser = class sealed
  public
    /// <summary>
    ///   idDeclAF::ParseSettings: the text is just after the word <c>settings</c>. <c>mesh</c> and <c>anim</c> are read
    ///   and ignored. False after an error of the lexer (a word it does not know, a string missing, a comma missing in
    ///   the numbers that need one); the values read until then stay in <c>ASettings</c>.
    /// </summary>
    class function Parse(const ASource: TIdLexer; var ASettings: TAfSettings): Boolean; static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.IdLib.Text.Token, DelphiDoom.IdLib.Text.Types, DelphiDoom.IdLib.Text.Strings,
  DelphiDoom.Decl.ArticulatedFigure.Contents;

{ TAfSettingsParser }

class function TAfSettingsParser.Parse(const ASource: TIdLexer; var ASettings: TAfSettings): Boolean;
var
  LToken: TIdToken;
  LValue: Single;

  function Keyword(const AName: AnsiString): Boolean;
  begin
    Result := TIdStrings.Icmp(LToken.Text, AName) = 0;
  end;

begin
  LToken := TIdToken.Create;
  if not ASource.ExpectTokenString('{') then
    Exit(False);

  while ASource.ReadToken(LToken) do
  begin
    if Keyword('mesh') or Keyword('anim') then
    begin
      if not ASource.ExpectTokenType(TT_STRING, 0, LToken) then
        Exit(False);
    end
    else if Keyword('model') then
    begin
      if not ASource.ExpectTokenType(TT_STRING, 0, LToken) then
        Exit(False);
      ASettings.Model := LToken.Text;
    end
    else if Keyword('skin') then
    begin
      if not ASource.ExpectTokenType(TT_STRING, 0, LToken) then
        Exit(False);
      ASettings.Skin := LToken.Text;
    end
    else if Keyword('friction') then
    begin
      ASettings.DefaultLinearFriction := ASource.ParseFloat;
      if not ASource.ExpectTokenString(',') then
        Exit(False);
      ASettings.DefaultAngularFriction := ASource.ParseFloat;
      if not ASource.ExpectTokenString(',') then
        Exit(False);
      ASettings.DefaultContactFriction := ASource.ParseFloat;
      if ASource.CheckTokenString(',') then
        ASettings.DefaultConstraintFriction := ASource.ParseFloat;
    end
    else if Keyword('totalMass') then
      ASettings.TotalMass := ASource.ParseFloat
    else if Keyword('suspendSpeed') then
    begin
      LValue := ASource.ParseFloat;
      ASettings.SuspendVelocity.X := LValue;
      if not ASource.ExpectTokenString(',') then
        Exit(False);
      LValue := ASource.ParseFloat;
      ASettings.SuspendVelocity.Y := LValue;
      if not ASource.ExpectTokenString(',') then
        Exit(False);
      LValue := ASource.ParseFloat;
      ASettings.SuspendAcceleration.X := LValue;
      if not ASource.ExpectTokenString(',') then
        Exit(False);
      LValue := ASource.ParseFloat;
      ASettings.SuspendAcceleration.Y := LValue;
    end
    else if Keyword('noMoveTime') then
      ASettings.NoMoveTime := ASource.ParseFloat
    else if Keyword('noMoveTranslation') then
      ASettings.NoMoveTranslation := ASource.ParseFloat
    else if Keyword('noMoveRotation') then
      ASettings.NoMoveRotation := ASource.ParseFloat
    else if Keyword('minMoveTime') then
      ASettings.MinMoveTime := ASource.ParseFloat
    else if Keyword('maxMoveTime') then
      ASettings.MaxMoveTime := ASource.ParseFloat
    else if Keyword('contents') then
      ASettings.Contents := TAfContents.ParseContents(ASource)
    else if Keyword('clipMask') then
      ASettings.ClipMask := TAfContents.ParseContents(ASource)
    else if Keyword('selfCollision') then
      ASettings.SelfCollision := ASource.ParseBool
    else if LToken.IsText('}') then
      Break
    else
    begin
      ASource.Error('unknown token %s in settings', [string(LToken.Text)]);
      Exit(False);
    end;
  end;
  Result := True;
end;

end.

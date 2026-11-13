{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - contents and joint mods of the            }
{  "articulatedFigure" declaration                                             }
{                                                                              }
{  Port of the articulated figures of Doom 3 (id Software, GPL v3):            }
{  framework\DeclAF.cpp (ContentsFromString, ContentsToString,                 }
{  JointModFromString, JointModToString). Copyright (C) 1999-2011 id Software  }
{  LLC, a ZeniMax Media company. Based on the Doom 3 GPL Source Code (id       }
{  Software).                                                                  }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.ArticulatedFigure.Contents;

interface

uses
  DelphiDoom.IdLib.Text.Lexer, DelphiDoom.Decl.ArticulatedFigure.Types;

type
  /// <summary>The words of the text for the contents masks and for the joint mods</summary>
  TAfContents = class sealed
  public
    /// <summary>
    ///   idDeclAF::ContentsFromString: <c>none</c> clears, <c>solid body corpse playerclip monsterclip</c> add; commas
    ///   are skipped and any other word ends the reading (the mask so far is the result)
    /// </summary>
    class function ContentsFromString(const AText: AnsiString): Integer; static;
    /// <summary>
    ///   idDeclAF::ParseContents: reads words separated by commas up to the first one without a comma after it and
    ///   gives them to <c>ContentsFromString</c>. At the end of the text the mask is zero.
    /// </summary>
    class function ParseContents(const ASource: TIdLexer): Integer; static;
    /// <summary>idDeclAF::ContentsToString: the names separated by ", " or <c>none</c></summary>
    class function ContentsToString(const AContents: Integer): AnsiString; static;
    /// <summary>idDeclAF::JointModFromString: <c>orientation</c>, <c>position</c>, <c>both</c>; anything else is the axis</summary>
    class function JointModFromString(const AText: AnsiString): TAfJointMod; static;
    /// <summary>idDeclAF::JointModToString</summary>
    class function JointModToString(const AJointMod: TAfJointMod): AnsiString; static;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Token, DelphiDoom.IdLib.Text.Strings,
  DelphiDoom.Decl.Material.Types;

{ TAfContents }

class function TAfContents.ContentsFromString(const AText: AnsiString): Integer;
var
  LSource: TIdLexer;
  LToken: TIdToken;
begin
  Result := 0;
  LToken := TIdToken.Create;
  LSource := TIdLexer.Create;
  try
    LSource.LoadMemory(AText, Length(AText), 'idDeclAF::ContentsFromString');
    while LSource.ReadToken(LToken) do
    begin
      if TIdStrings.Icmp(LToken.Text, 'none') = 0 then
        Result := 0
      else if TIdStrings.Icmp(LToken.Text, 'solid') = 0 then
        Result := Result or CONTENTS_SOLID
      else if TIdStrings.Icmp(LToken.Text, 'body') = 0 then
        Result := Result or CONTENTS_BODY
      else if TIdStrings.Icmp(LToken.Text, 'corpse') = 0 then
        Result := Result or CONTENTS_CORPSE
      else if TIdStrings.Icmp(LToken.Text, 'playerclip') = 0 then
        Result := Result or CONTENTS_PLAYERCLIP
      else if TIdStrings.Icmp(LToken.Text, 'monsterclip') = 0 then
        Result := Result or CONTENTS_MONSTERCLIP
      else if LToken.Text = ',' then
        Continue
      else
        Exit;
    end;
  finally
    LSource.Free;
  end;
end;

class function TAfContents.ParseContents(const ASource: TIdLexer): Integer;
var
  LToken: TIdToken;
  LText: AnsiString;
begin
  LToken := TIdToken.Create;
  LText := '';
  while ASource.ReadToken(LToken) do
  begin
    LText := LText + LToken.Text;
    if not ASource.CheckTokenString(',') then
      Break;
    LText := LText + ',';
  end;
  Result := ContentsFromString(LText);
end;

class function TAfContents.ContentsToString(const AContents: Integer): AnsiString;

  procedure Add(const AMask: Integer; const AName: AnsiString);
  begin
    if (AContents and AMask) <> 0 then
    begin
      if Result <> '' then
        Result := Result + ', ';
      Result := Result + AName;
    end;
  end;

begin
  Result := '';
  Add(CONTENTS_SOLID, 'solid');
  Add(CONTENTS_BODY, 'body');
  Add(CONTENTS_CORPSE, 'corpse');
  Add(CONTENTS_PLAYERCLIP, 'playerclip');
  Add(CONTENTS_MONSTERCLIP, 'monsterclip');
  if Result = '' then
    Result := 'none';
end;

class function TAfContents.JointModFromString(const AText: AnsiString): TAfJointMod;
begin
  if TIdStrings.Icmp(AText, 'orientation') = 0 then
    Exit(ajmAxis);
  if TIdStrings.Icmp(AText, 'position') = 0 then
    Exit(ajmOrigin);
  if TIdStrings.Icmp(AText, 'both') = 0 then
    Exit(ajmBoth);
  Result := ajmAxis;
end;

class function TAfContents.JointModToString(const AJointMod: TAfJointMod): AnsiString;
begin
  case AJointMod of
    ajmOrigin: Result := 'position';
    ajmBoth: Result := 'both';
  else
    Result := 'orientation';
  end;
end;

end.

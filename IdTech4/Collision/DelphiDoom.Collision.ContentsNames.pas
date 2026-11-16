{******************************************************************************}
{                                                                              }
{  DelphiDoom: collision library - names of the content flags                  }
{                                                                              }
{  Port of ContentsFromString, StringFromContents and the tables               }
{  cm_contentsNameByIndex and cm_contentsFlagByIndex of CollisionModel_debug.  }
{  cpp, Doom 3 GPL Source Code. Copyright (C) 1999-2011 id Software LLC, a     }
{  ZeniMax Media company. Doom 3 Source Code: GNU General Public License       }
{  version 3 with additional terms. This unit is a derived work (GPL v3).      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Collision.ContentsNames;

interface

type
  /// <summary>Converts content flags to the text of the brush lines of a collision model file and back</summary>
  TCollisionContentsNames = class sealed
  public
    /// <summary>
    ///   Flags from a text like "solid,playerclip" (separators and unknown names are ignored,
    ///   names compare without case)
    /// </summary>
    class function ContentsFromString(const AText: string): Integer; static;
    /// <summary>The names of the set flags, in table order, separated by commas</summary>
    class function StringFromContents(AContents: Integer): string; static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Collision.Types;

const
  // index 0 is "none" with flag -1 and is not looked up
  CONTENT_COUNT = 14;
  ContentNames: array[1..CONTENT_COUNT] of string = (
    'solid', 'opaque', 'water', 'playerclip', 'monsterclip', 'moveableclip', 'ikclip', 'blood',
    'body', 'corpse', 'trigger', 'aas_solid', 'aas_obstacle', 'flashlight_trigger');
  ContentFlags: array[1..CONTENT_COUNT] of Integer = (
    CONTENTS_SOLID, CONTENTS_OPAQUE, CONTENTS_WATER, CONTENTS_PLAYERCLIP, CONTENTS_MONSTERCLIP,
    CONTENTS_MOVEABLECLIP, CONTENTS_IKCLIP, CONTENTS_BLOOD, CONTENTS_BODY, CONTENTS_CORPSE,
    CONTENTS_TRIGGER, CONTENTS_AAS_SOLID, CONTENTS_AAS_OBSTACLE, CONTENTS_FLASHLIGHT_TRIGGER);

{ TCollisionContentsNames }

class function TCollisionContentsNames.ContentsFromString(const AText: string): Integer;
var
  LPart: string;
  LIndex: Integer;
  LToken: string;
  LTokens: TArray<string>;
begin
  Result := 0;
  // the lexer splits at spaces and commas
  LTokens := AText.Split([',', ' ', #9, #10, #13]);
  for LToken in LTokens do
  begin
    LPart := Trim(LToken);
    if LPart = '' then
      Continue;
    for LIndex := 1 to CONTENT_COUNT do
      if SameText(LPart, ContentNames[LIndex]) then
      begin
        Result := Result or ContentFlags[LIndex];
        Break;
      end;
  end;
end;

class function TCollisionContentsNames.StringFromContents(AContents: Integer): string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 1 to CONTENT_COUNT do
    if (AContents and ContentFlags[LIndex]) <> 0 then
    begin
      if Result <> '' then
        Result := Result + ',';
      Result := Result + ContentNames[LIndex];
    end;
end;

end.

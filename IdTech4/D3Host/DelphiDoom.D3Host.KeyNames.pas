{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 host library - the names of the keys                     }
{                                                                              }
{  Port of Doom 3 (id Software): framework\KeyInput.cpp (StringToKeyNum,       }
{  KeyNumToString, ArgCompletion_KeyName).                                     }
{  Based on the Doom 3 GPL Source Code (id Software).                          }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3 or (at your       }
{  option) any later version, with the additional terms of the Doom 3 Source   }
{  Code License (Reference\doom3\COPYING.txt: preservation of legal notices    }
{  and trademarks, no use of the licensors' names for publicity, warranty      }
{  disclaimer). The repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.D3Host.KeyNames;

interface

uses
  DelphiDoom.Console.CmdSystem.Types, DelphiDoom.D3Host.Input.Intf;

type
  /// <summary>The conversion between key numbers and key names</summary>
  TD3KeyNames = class
  public
    /// <summary>
    ///   idKeyInput::StringToKeyNum: a single character is its own key, "0x11" is raw hex (a bad digit counts 0),
    ///   otherwise the name of the table without regard to case; -1 if it is none
    /// </summary>
    class function StringToKeyNum(const AText: AnsiString): Integer; static;
    /// <summary>
    ///   idKeyInput::KeyNumToString: a printable character (not quote, semicolon, apostrophe), a name of the table
    ///   (localized with the language dictionary), the european high ascii when localized, or "0xNN"
    /// </summary>
    class function KeyNumToString(const AKey: Integer; const ALocalized: Boolean;
      const AText: ID3KeyText): AnsiString; static;
    /// <summary>idKeyInput::ArgCompletion_KeyName: every single character key and every name after the command</summary>
    class procedure ArgCompletionKeyName(const ACommand: AnsiString; const ACallback: TCmdCompletionCallback); static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.D3Host.Input.Types;

const
  SKeyNotFound = '<KEY NOT FOUND>';
  SOutOfRange = '<OUT OF RANGE>';
  // keys that can be set without a special name
  SUnnamedKeys = '*,-=./[\]1234567890abcdefghijklmnopqrstuvwxyz';

function SameAscii(const ALeft, ARight: AnsiString): Boolean;
var
  LIndex: Integer;
  LLeft: Byte;
  LRight: Byte;
begin
  Result := Length(ALeft) = Length(ARight);
  if not Result then
    Exit;
  for LIndex := 1 to Length(ALeft) do
  begin
    LLeft := Byte(ALeft[LIndex]);
    LRight := Byte(ARight[LIndex]);
    if LLeft in [Ord('A')..Ord('Z')] then
      Inc(LLeft, 32);
    if LRight in [Ord('A')..Ord('Z')] then
      Inc(LRight, 32);
    if LLeft <> LRight then
      Exit(False);
  end;
end;

function HexDigit(const AChar: AnsiChar): Integer;
begin
  if AChar in ['0'..'9'] then
    Result := Ord(AChar) - Ord('0')
  else if AChar in ['a'..'f'] then
    Result := Ord(AChar) - Ord('a') + 10
  else
    Result := 0;
end;

class function TD3KeyNames.StringToKeyNum(const AText: AnsiString): Integer;
var
  LIndex: Integer;
begin
  if AText = '' then
    Exit(-1);
  if Length(AText) = 1 then
    Exit(Byte(AText[1]));
  if (AText[1] = '0') and (AText[2] = 'x') and (Length(AText) = 4) then
    Exit(HexDigit(AText[3]) * 16 + HexDigit(AText[4]));
  for LIndex := Low(D3_KEY_NAMES) to High(D3_KEY_NAMES) do
    if SameAscii(AText, D3_KEY_NAMES[LIndex].Name) then
      Exit(D3_KEY_NAMES[LIndex].Key);
  Result := -1;
end;

class function TD3KeyNames.KeyNumToString(const AKey: Integer; const ALocalized: Boolean;
  const AText: ID3KeyText): AnsiString;
const
  HexChars: AnsiString = '0123456789abcdef';
var
  LIndex: Integer;
begin
  if AKey = -1 then
    Exit(SKeyNotFound);
  if (AKey < 0) or (AKey > 255) then
    Exit(SOutOfRange);
  if (AKey > 32) and (AKey < 127) and (AKey <> Ord('"')) and (AKey <> Ord(';')) and (AKey <> Ord('''')) then
    Exit(AnsiString(AText.MapCharForKey(AKey)));
  for LIndex := Low(D3_KEY_NAMES) to High(D3_KEY_NAMES) do
    if D3_KEY_NAMES[LIndex].Key = AKey then
    begin
      if (not ALocalized) or (D3_KEY_NAMES[LIndex].StrId[1] <> '#') then
        Exit(D3_KEY_NAMES[LIndex].Name);
      Exit(AText.LanguageString(D3_KEY_NAMES[LIndex].StrId));
    end;
  // European high-ASCII characters
  if ALocalized and (AKey >= 161) and (AKey <= 255) then
    Exit(AnsiString(AnsiChar(AKey)));
  Result := '0x' + HexChars[(AKey shr 4) + 1] + HexChars[(AKey and 15) + 1];
end;

class procedure TD3KeyNames.ArgCompletionKeyName(const ACommand: AnsiString; const ACallback: TCmdCompletionCallback);
var
  LIndex: Integer;
begin
  for LIndex := 1 to Length(SUnnamedKeys) do
    ACallback(ACommand + ' ' + AnsiChar(SUnnamedKeys[LIndex]));
  for LIndex := Low(D3_KEY_NAMES) to High(D3_KEY_NAMES) do
    ACallback(ACommand + ' ' + D3_KEY_NAMES[LIndex].Name);
end;

end.

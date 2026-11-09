{******************************************************************************}
{                                                                              }
{  DelphiDoom: font library - the names of the lumps of a font                  }
{  Copyright (C) 2021-2022 by Jim Valavanis (original DD_FONT)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Font.LumpNames;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   The names that DoGenerateWAD gave to the lumps: the text without its spaces, or the prefix with the code
  ///   of the character on three digits (STCFN033) or with the digit (STTNUM0). A name is cut to 8 characters
  ///   as the old writer did, and made upper case
  /// </summary>
  TFontLumpNames = class sealed
  public
    class function RemoveSpaces(const AText: string): string; static;
    /// <summary>The number with leading zeros up to ADigits digits (a longer number is left as it is)</summary>
    class function ZeroFill(ADigits, AValue: Integer): string; static;
    /// <summary>The name of the lump of a text; empty if the text has nothing but spaces</summary>
    class function ForText(const AText: string): string; static;
    /// <summary>The name of the lump of the character with the code ACode: prefix + three digits</summary>
    class function ForCharacter(const APrefix: string; ACode: Integer): string; static;
    /// <summary>The name of the lump of a digit: prefix + the digit</summary>
    class function ForDigit(const APrefix: string; ADigit: Char): string; static;
  end;

implementation

uses
  DelphiDoom.Font.Types;

const
  CODE_DIGITS = 3;
  /// <summary>A name of a lump has bytes: a character above $FF can not be one</summary>
  UNSUPPORTED_CHARACTER = '?';

function Normalize(const AName: string): string;
var
  LIndex: Integer;
  LChar: Char;
begin
  Result := Copy(AName, 1, FONT_WAD_LUMP_NAME_LENGTH);
  for LIndex := 1 to Length(Result) do
  begin
    LChar := Result[LIndex];
    if Ord(LChar) > $FF then
      Result[LIndex] := UNSUPPORTED_CHARACTER
    else if (LChar >= 'a') and (LChar <= 'z') then
      Result[LIndex] := Char(Ord(LChar) - 32);
  end;
end;

{ TFontLumpNames }

class function TFontLumpNames.RemoveSpaces(const AText: string): string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 1 to Length(AText) do
    if AText[LIndex] <> ' ' then
      Result := Result + AText[LIndex];
end;

class function TFontLumpNames.ZeroFill(ADigits, AValue: Integer): string;
begin
  Result := IntToStr(AValue);
  while Length(Result) < ADigits do
    Result := '0' + Result;
end;

class function TFontLumpNames.ForText(const AText: string): string;
begin
  Result := Normalize(RemoveSpaces(AText));
end;

class function TFontLumpNames.ForCharacter(const APrefix: string; ACode: Integer): string;
begin
  Result := Normalize(APrefix + ZeroFill(CODE_DIGITS, ACode));
end;

class function TFontLumpNames.ForDigit(const APrefix: string; ADigit: Char): string;
begin
  Result := Normalize(APrefix + ADigit);
end;

end.

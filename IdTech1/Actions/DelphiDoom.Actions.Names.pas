{******************************************************************************}
{                                                                              }
{  DelphiDoom: actions library - the names of the actions                      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Actions.Names;

interface

type
  /// <summary>How the name of an action is written, searched and taken from a declaration</summary>
  TActionNames = class
  public
    /// <summary>
    ///   The name at the beginning of a declaration such as "A_Chase(x: integer);": the text up
    ///   to the first space, semicolon, parenthesis, bracket, colon or control character
    /// </summary>
    class function FromDeclaration(const ADeclaration: string): string; static;
    /// <summary>The name without the prefix "A_" (any case)</summary>
    class function StripPrefix(const AName: string): string; static;
    /// <summary>The key of a search: no prefix, upper case (only the letters a-z)</summary>
    class function Normalize(const AName: string): string; static;
    /// <summary>The upper case of the letters a-z, the other characters do not change</summary>
    class function UpperAscii(const AText: string): string; static;
  end;

implementation

const
  NAME_END_CHARACTERS: set of AnsiChar = [' ', ';', '(', '[', ':', #7, #9, #10, #13];
  ACTION_PREFIX_LENGTH = 2;

{ TActionNames }

class function TActionNames.FromDeclaration(const ADeclaration: string): string;
var
  LIndex: Integer;
  LEnd: Integer;
  LStart: Integer;
begin
  LEnd := 0;
  for LIndex := 1 to Length(ADeclaration) do
    if (Ord(ADeclaration[LIndex]) < 256) and (AnsiChar(ADeclaration[LIndex]) in NAME_END_CHARACTERS) then
    begin
      LEnd := LIndex;
      Break;
    end;
  if LEnd = 0 then
  begin
    Result := ADeclaration;
    Exit;
  end;
  // the name is trimmed when it is cut, as the old firstword did
  LStart := 1;
  Dec(LEnd);
  while (LStart <= LEnd) and (ADeclaration[LStart] <= ' ') do
    Inc(LStart);
  while (LEnd >= LStart) and (ADeclaration[LEnd] <= ' ') do
    Dec(LEnd);
  Result := Copy(ADeclaration, LStart, LEnd - LStart + 1);
end;

class function TActionNames.StripPrefix(const AName: string): string;
begin
  if (Length(AName) >= ACTION_PREFIX_LENGTH) and ((AName[1] = 'A') or (AName[1] = 'a')) and
    (AName[2] = '_') then
    Result := Copy(AName, ACTION_PREFIX_LENGTH + 1, Length(AName) - ACTION_PREFIX_LENGTH)
  else
    Result := AName;
end;

class function TActionNames.Normalize(const AName: string): string;
begin
  Result := UpperAscii(StripPrefix(AName));
end;

class function TActionNames.UpperAscii(const AText: string): string;
var
  LIndex: Integer;
begin
  Result := AText;
  UniqueString(Result);
  for LIndex := 1 to Length(Result) do
    if (Result[LIndex] >= 'a') and (Result[LIndex] <= 'z') then
      Result[LIndex] := Char(Ord(Result[LIndex]) - 32);
end;

end.

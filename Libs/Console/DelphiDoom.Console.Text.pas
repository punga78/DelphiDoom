{******************************************************************************}
{                                                                              }
{  DelphiDoom: console library - text helpers                                  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Console.Text;

interface

type
  /// <summary>
  ///   The text functions of the console, with the same rules of the old code: only the ASCII
  ///   letters change case, and a character is blank when it is not above the space
  /// </summary>
  TConsoleText = class
  public
    class function UpperCase(const AText: string): string; static;
    class function LowerCase(const AText: string): string; static;
    /// <summary>Removes the characters up to the space from both ends</summary>
    class function Trim(const AText: string): string; static;
    /// <summary>
    ///   Cuts AText at the first ASeparator and trims both parts. If there is no separator the
    ///   first part is AText as it is (not trimmed) and the second is empty
    /// </summary>
    class procedure Split(const AText: string; ASeparator: Char; out AFirst, ASecond: string); static;
    class function StartsWith(const APrefix, AText: string): Boolean; static;
  end;

implementation

{ TConsoleText }

class function TConsoleText.UpperCase(const AText: string): string;
var
  LIndex: Integer;
begin
  Result := AText;
  for LIndex := 1 to Length(Result) do
    if (Result[LIndex] >= 'a') and (Result[LIndex] <= 'z') then
      Result[LIndex] := Char(Ord(Result[LIndex]) - 32);
end;

class function TConsoleText.LowerCase(const AText: string): string;
var
  LIndex: Integer;
begin
  Result := AText;
  for LIndex := 1 to Length(Result) do
    if (Result[LIndex] >= 'A') and (Result[LIndex] <= 'Z') then
      Result[LIndex] := Char(Ord(Result[LIndex]) + 32);
end;

class function TConsoleText.Trim(const AText: string): string;
var
  LFirst: Integer;
  LLast: Integer;
begin
  LFirst := 1;
  LLast := Length(AText);
  while (LFirst <= LLast) and (AText[LFirst] <= ' ') do
    Inc(LFirst);
  while (LLast >= LFirst) and (AText[LLast] <= ' ') do
    Dec(LLast);
  Result := Copy(AText, LFirst, LLast - LFirst + 1);
end;

class procedure TConsoleText.Split(const AText: string; ASeparator: Char;
  out AFirst, ASecond: string);
var
  LPosition: Integer;
begin
  LPosition := 1;
  while (LPosition <= Length(AText)) and (AText[LPosition] <> ASeparator) do
    Inc(LPosition);
  if LPosition > Length(AText) then
  begin
    AFirst := AText;
    ASecond := '';
  end
  else
  begin
    AFirst := Trim(Copy(AText, 1, LPosition - 1));
    ASecond := Trim(Copy(AText, LPosition + 1, Length(AText) - LPosition));
  end;
end;

class function TConsoleText.StartsWith(const APrefix, AText: string): Boolean;
begin
  Result := (Length(AText) >= Length(APrefix)) and
    (Copy(AText, 1, Length(APrefix)) = APrefix);
end;

end.

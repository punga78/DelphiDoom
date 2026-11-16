{******************************************************************************}
{                                                                              }
{  DelphiDoom: Dehacked library - the texts of a patch                         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Dehacked.Text;

interface

type
  /// <summary>The conversions of the strings of the game to and from the text of a patch</summary>
  TDehackedText = class
  public
    /// <summary>
    ///   The lines of a text as TDStringList.Text made them: a line ends at a line feed, a
    ///   carriage return or both; a character #0 ends the text
    /// </summary>
    class function SplitLines(const AText: string): TArray<string>; static;
    /// <summary>The string of the game as it is written in a patch: line feed becomes \n, carriage return is dropped</summary>
    class function StringToCString(const AText: string): string; static;
    /// <summary>
    ///   The text of a patch as the string of the game (DEH_CStringToString). The text of a
    ///   patch is in upper case, so the escape is the letter N (R) after a backslash
    /// </summary>
    class function CStringToString(const AText: string): string; static;
    /// <summary>The characters A..Z and 0..9 of the text, in upper case: how a string of the game is recognised</summary>
    class function StringValue(const AText: string): string; static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Dehacked.Strings;

{ TDehackedText }

class function TDehackedText.SplitLines(const AText: string): TArray<string>;
var
  LPosition, LStart, LCount, LLength: Integer;
begin
  LCount := 0;
  SetLength(Result, 16);
  LLength := Length(AText);
  LPosition := 1;
  while (LPosition <= LLength) and (AText[LPosition] <> #0) do
  begin
    LStart := LPosition;
    while (LPosition <= LLength) and not CharInSet(AText[LPosition], [#0, #10, #13]) do
      Inc(LPosition);
    if LCount = Length(Result) then
      SetLength(Result, LCount * 2);
    Result[LCount] := Copy(AText, LStart, LPosition - LStart);
    Inc(LCount);
    if (LPosition <= LLength) and (AText[LPosition] = #13) then
      Inc(LPosition);
    if (LPosition <= LLength) and (AText[LPosition] = #10) then
      Inc(LPosition);
  end;
  SetLength(Result, LCount);
end;

class function TDehackedText.StringToCString(const AText: string): string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 1 to Length(AText) do
    if AText[LIndex] <> #13 then
    begin
      if AText[LIndex] = #10 then
        Result := Result + '\n'
      else
        Result := Result + AText[LIndex];
    end;
end;

class function TDehackedText.CStringToString(const AText: string): string;
var
  LIndex: Integer;
begin
  Result := '';
  if AText = '' then
    Exit;
  Result := AText[1];
  for LIndex := 2 to Length(AText) do
  begin
    if AText[LIndex] = 'N' then
    begin
      if (Length(Result) > 0) and (Result[Length(Result)] = '\') then
      begin
        Result[Length(Result)] := #13;
        Result := Result + #10;
      end
      else
        Result := Result + 'N';
    end
    else if AText[LIndex] = 'R' then
    begin
      if (Length(Result) > 0) and (Result[Length(Result)] = '\') then
        SetLength(Result, Length(Result) - 1)
      else
        Result := Result + 'R';
    end
    else if AText[LIndex] = #10 then
    begin
      if (Length(Result) > 0) and (Result[Length(Result)] <> #13) then
        Result := Result + #13#10
      else
        Result := Result + #10;
    end
    else
      Result := Result + AText[LIndex];
  end;
end;

class function TDehackedText.StringValue(const AText: string): string;
var
  LIndex: Integer;
  LUpper: string;
begin
  Result := '';
  LUpper := TDehackedStrings.Upper(AText);
  for LIndex := 1 to Length(LUpper) do
    if CharInSet(LUpper[LIndex], ['A'..'Z', '1'..'9', '0']) then
      Result := Result + LUpper[LIndex];
end;

end.

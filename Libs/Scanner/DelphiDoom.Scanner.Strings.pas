{******************************************************************************}
{                                                                              }
{  DelphiDoom: scanner library - the string functions of the script code        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Scanner.Strings;

interface

type
  /// <summary>
  ///   The small string functions that the old script code took from d_delphi, with the
  ///   same results: the case changes only touch A-Z and a-z, a trim removes the characters
  ///   up to #32
  /// </summary>
  TScannerStrings = class
  public
    /// <summary>Upper case of the letters a-z only (the old strupper)</summary>
    class function UpperAscii(const AText: string): string; static;
    /// <summary>Removes the characters up to #32 at both ends</summary>
    class function Trim(const AText: string): string; static;
    /// <summary>
    ///   The lines of a text, like TDStrings.Text: CR LF, LF or CR end a line, a last line
    ///   break does not add an empty one, a #0 ends the text
    /// </summary>
    class function SplitLines(const AText: string): TArray<string>; static;
    /// <summary>
    ///   Splits at the first ASplitter (the old splitstring_ch): both parts are trimmed; when
    ///   there is no ASplitter the first part is the text as it is and the second is empty
    /// </summary>
    class procedure SplitAtFirst(const AText: string; out AFirst, ASecond: string; ASplitter: Char = ' '); static;
    /// <summary>
    ///   The old atoi: a decimal number, or 0x..., -0x..., #... ; 0 when it is not a number
    /// </summary>
    class function ToInteger(const AText: string): Integer; static;
  end;

implementation

uses
  System.SysUtils;

{ TScannerStrings }

class function TScannerStrings.UpperAscii(const AText: string): string;
var
  LIndex: Integer;
begin
  Result := AText;
  for LIndex := 1 to Length(Result) do
    if (Result[LIndex] >= 'a') and (Result[LIndex] <= 'z') then
      Result[LIndex] := Char(Ord(Result[LIndex]) - 32);
end;

class function TScannerStrings.Trim(const AText: string): string;
var
  LFirst: Integer;
  LLast: Integer;
begin
  LFirst := 1;
  LLast := Length(AText);
  while (LFirst <= LLast) and (AText[LFirst] <= ' ') do
    Inc(LFirst);
  if LFirst > LLast then
    Exit('');
  while AText[LLast] <= ' ' do
    Dec(LLast);
  Result := Copy(AText, LFirst, LLast - LFirst + 1);
end;

class function TScannerStrings.SplitLines(const AText: string): TArray<string>;
var
  LIndex: Integer;
  LStart: Integer;
  LCount: Integer;
begin
  Result := nil;
  LCount := Pos(#0, AText) - 1;
  if LCount < 0 then
    LCount := Length(AText);
  LStart := 1;
  LIndex := 1;
  while LIndex <= LCount do
  begin
    if (AText[LIndex] = #13) or (AText[LIndex] = #10) then
    begin
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := Copy(AText, LStart, LIndex - LStart);
      if (AText[LIndex] = #13) and (LIndex < LCount) and (AText[LIndex + 1] = #10) then
        Inc(LIndex);
      LStart := LIndex + 1;
    end;
    Inc(LIndex);
  end;
  if LStart <= LCount then
  begin
    SetLength(Result, Length(Result) + 1);
    Result[High(Result)] := Copy(AText, LStart, LCount - LStart + 1);
  end;
end;

class procedure TScannerStrings.SplitAtFirst(const AText: string; out AFirst, ASecond: string;
  ASplitter: Char);
var
  LPosition: Integer;
begin
  LPosition := Pos(ASplitter, AText);
  if LPosition = 0 then
  begin
    AFirst := AText;
    ASecond := '';
  end
  else
  begin
    AFirst := Trim(Copy(AText, 1, LPosition - 1));
    ASecond := Trim(Copy(AText, LPosition + 1, MaxInt));
  end;
end;

class function TScannerStrings.ToInteger(const AText: string): Integer;
var
  LCode: Integer;
  LOther: Integer;
begin
  Val(AText, Result, LCode);
  if LCode = 0 then
    Exit;
  LOther := 0;
  if AText.StartsWith('0x') then
    Val('$' + Copy(AText, 3, MaxInt), LOther, LCode)
  else if AText.StartsWith('-0x') then
  begin
    Val('$' + Copy(AText, 4, MaxInt), LOther, LCode);
    LOther := -LOther;
  end
  else if (AText <> '') and (AText[1] = '#') then
    Val(Copy(AText, 2, MaxInt), LOther, LCode);
  if LCode = 0 then
    Result := LOther
  else
    Result := 0;
end;

end.

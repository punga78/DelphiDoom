{******************************************************************************}
{                                                                              }
{  DelphiDoom: Dehacked library - the string functions of the old parser       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Dehacked.Strings;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   The functions of d_delphi that the parser of the patches used (strtrim, splitstring,
  ///   firstword, atoi ...), with the same results: where they do not trim a result or give
  ///   back the whole input, so do these
  /// </summary>
  TDehackedStrings = class
  public
    /// <summary>Removes the characters up to the space from both ends</summary>
    class function Trim(const AText: string): string; static;
    /// <summary>Only the letters a..z change</summary>
    class function Upper(const AText: string): string; static;
    /// <summary>The position of the first AChar, from 1; 0 if it is not there</summary>
    class function IndexOfChar(AChar: Char; const AText: string): Integer; static;
    /// <summary>The text starts with the prefix (all of its characters)</summary>
    class function StartsWith(const APrefix, AText: string): Boolean; static;
    /// <summary>
    ///   Splits at the first ASplitter and trims both parts; if it is not there AFirst is the
    ///   input as it is
    /// </summary>
    class procedure SplitChar(const AInput: string; out AFirst, ASecond: string;
      ASplitter: Char = ' '); static;
    /// <summary>What comes before the first ASplitter, not trimmed</summary>
    class function FirstWordChar(const AInput: string; ASplitter: Char = ' '): string; static;
    /// <summary>Splits at the first AText and trims both parts; if it is not there AFirst is the input</summary>
    class procedure SplitText(const AInput: string; out AFirst, ASecond: string;
      const ASplitter: string = ' '); static;
    /// <summary>The part after the first AText, trimmed; empty if it is not there</summary>
    class function SecondWord(const AInput: string; const ASplitter: string = ' '): string; static;
    /// <summary>Splits at the first character of the set; AFirst is the input if there is none</summary>
    class procedure SplitSet(const AInput: string; out AFirst, ASecond: string;
      const ASplitters: TSysCharSet); static;
    /// <summary>The first word, or the text between the first quotes if it starts with one</summary>
    class function ParseFirstWord(const AInput: string): string; static;
    /// <summary>Removes a quote at the start and one at the end</summary>
    class function RemoveQuotes(const AText: string): string; static;
    /// <summary>
    ///   A whole number: decimal, 0x or $ (hexadecimal), # (decimal again), with a minus; ADefault if
    ///   the text is not one
    /// </summary>
    class function ToInteger(const AText: string; ADefault: Integer): Integer; static;
    /// <summary>A number with a point or a comma as the separator; ADefault if the text is not one</summary>
    class function ToSingle(const AText: string; ADefault: Single): Single; static;
    /// <summary>The value of a field in fixed point (see DEH_FixedOrFloat)</summary>
    class function FixedOrFloat(const AToken: string; ATolerance: Integer): Integer; static;
  end;

implementation

uses
  DelphiDoom.Dehacked.Types;

{ TDehackedStrings }

class function TDehackedStrings.Trim(const AText: string): string;
var
  LFirst, LLast, LLength: Integer;
begin
  LLength := Length(AText);
  LLast := LLength;
  LFirst := 1;
  while (LFirst <= LLast) and (AText[LFirst] <= ' ') do
    Inc(LFirst);
  if LFirst > LLast then
    Result := ''
  else
  begin
    while AText[LLast] <= ' ' do
      Dec(LLast);
    if (LFirst = 1) and (LLast = LLength) then
      Result := AText
    else
      Result := Copy(AText, LFirst, LLast - LFirst + 1);
  end;
end;

class function TDehackedStrings.Upper(const AText: string): string;
var
  LIndex: Integer;
  LChar: Char;
begin
  Result := AText;
  for LIndex := 1 to Length(Result) do
  begin
    LChar := Result[LIndex];
    if (LChar >= 'a') and (LChar <= 'z') then
      Result[LIndex] := Char(Ord(LChar) - 32);
  end;
end;

class function TDehackedStrings.IndexOfChar(AChar: Char; const AText: string): Integer;
var
  LIndex: Integer;
begin
  for LIndex := 1 to Length(AText) do
    if AText[LIndex] = AChar then
      Exit(LIndex);
  Result := 0;
end;

class function TDehackedStrings.StartsWith(const APrefix, AText: string): Boolean;
begin
  if Length(AText) < Length(APrefix) then
    Exit(False);
  Result := CompareMem(PChar(APrefix), PChar(AText), Length(APrefix) * SizeOf(Char));
end;

class procedure TDehackedStrings.SplitChar(const AInput: string; out AFirst, ASecond: string;
  ASplitter: Char);
var
  LPosition: Integer;
  LInput: string;
begin
  LInput := AInput;
  LPosition := IndexOfChar(ASplitter, LInput);
  if LPosition = 0 then
  begin
    AFirst := LInput;
    ASecond := '';
  end
  else
  begin
    AFirst := Trim(Copy(LInput, 1, LPosition - 1));
    ASecond := Trim(Copy(LInput, LPosition + 1, Length(LInput) - LPosition));
  end;
end;

class function TDehackedStrings.FirstWordChar(const AInput: string; ASplitter: Char): string;
var
  LPosition: Integer;
begin
  LPosition := IndexOfChar(ASplitter, AInput);
  if LPosition = 0 then
    Result := AInput
  else
    Result := Copy(AInput, 1, LPosition - 1);
end;

class procedure TDehackedStrings.SplitText(const AInput: string; out AFirst, ASecond: string;
  const ASplitter: string);
var
  LPosition: Integer;
  LInput: string;
begin
  LInput := AInput;
  LPosition := Pos(ASplitter, LInput);
  if LPosition = 0 then
  begin
    AFirst := LInput;
    ASecond := '';
  end
  else
  begin
    AFirst := Trim(Copy(LInput, 1, LPosition - 1));
    ASecond := Trim(Copy(LInput, LPosition + 1, Length(LInput) - LPosition));
  end;
end;

class function TDehackedStrings.SecondWord(const AInput: string; const ASplitter: string): string;
var
  LFirst: string;
begin
  SplitText(AInput, LFirst, Result, ASplitter);
end;

class procedure TDehackedStrings.SplitSet(const AInput: string; out AFirst, ASecond: string;
  const ASplitters: TSysCharSet);
var
  LIndex, LPosition: Integer;
  LInput: string;
begin
  LInput := AInput;
  LPosition := 0;
  for LIndex := 1 to Length(LInput) do
    if CharInSet(LInput[LIndex], ASplitters) then
    begin
      LPosition := LIndex;
      Break;
    end;
  if LPosition = 0 then
  begin
    AFirst := LInput;
    ASecond := '';
  end
  else
  begin
    AFirst := Trim(Copy(LInput, 1, LPosition - 1));
    ASecond := Trim(Copy(LInput, LPosition + 1, Length(LInput) - LPosition));
  end;
end;

class function TDehackedStrings.ParseFirstWord(const AInput: string): string;
var
  LText, LRest: string;
  LIndex: Integer;
begin
  LText := Trim(AInput);
  if LText = '' then
    Exit('');
  if LText[1] = '"' then
  begin
    Result := '';
    for LIndex := 2 to Length(LText) do
    begin
      if LText[LIndex] = '"' then
        Break;
      Result := Result + LText[LIndex];
    end;
    Exit;
  end;
  SplitChar(LText, Result, LRest, ' ');
end;

class function TDehackedStrings.RemoveQuotes(const AText: string): string;
begin
  Result := AText;
  if Result = '' then
    Exit;
  if Result[1] = '"' then
    Delete(Result, 1, 1);
  if (Result <> '') and (Result[Length(Result)] = '"') then
    Delete(Result, Length(Result), 1);
end;

class function TDehackedStrings.ToInteger(const AText: string; ADefault: Integer): Integer;
var
  LCode, LOther: Integer;
begin
  Val(AText, Result, LCode);
  if LCode <> 0 then
  begin
    LOther := ADefault;
    if StartsWith('0x', AText) then
      Val('$' + Copy(AText, 3, Length(AText) - 2), LOther, LCode)
    else if StartsWith('-0x', AText) then
    begin
      Val('$' + Copy(AText, 4, Length(AText) - 3), LOther, LCode);
      LOther := -LOther;
    end
    else if IndexOfChar('#', AText) = 1 then
      Val(Copy(AText, 2, Length(AText) - 1), LOther, LCode);
    if LCode = 0 then
      Result := LOther
    else
      Result := ADefault;
  end;
end;

class function TDehackedStrings.ToSingle(const AText: string; ADefault: Single): Single;
var
  LCode, LIndex: Integer;
  LText: string;
begin
  Val(AText, Result, LCode);
  if LCode <> 0 then
  begin
    // the old code made the decimal separator a point first, so a comma is read as a point
    LText := AText;
    for LIndex := 1 to Length(LText) do
      if LText[LIndex] = ',' then
        LText[LIndex] := '.';
    Val(LText, Result, LCode);
    if LCode <> 0 then
      Result := ADefault;
  end;
end;

class function TDehackedStrings.FixedOrFloat(const AToken: string; ATolerance: Integer): Integer;
var
  LValue: Single;
begin
  if (Pos('.', AToken) > 0) or (Pos(',', AToken) > 0) then
  begin
    LValue := ToSingle(AToken, 0);
    if Abs(LValue) > ATolerance then
      Result := Round(LValue)
    else
      Result := Round(LValue * DEHACKED_FRACUNIT);
  end
  else
    Result := ToInteger(AToken, 0);
end;

end.

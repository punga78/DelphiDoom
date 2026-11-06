{******************************************************************************}
{                                                                              }
{  DelphiDoom: scanner library - helpers on the text of a script line           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Scanner.Text;

interface

uses
  System.SysUtils, DelphiDoom.Logging.Intf;

type
  /// <summary>The small functions on the text of a line that the script code of the engine used</summary>
  TScannerText = class
  public
    /// <summary>Drops the // comments and what follows a ; of each line, and the empty lines; the lines end in CR LF</summary>
    class function RemoveLineQuotes(const AText: string): string; static;
    /// <summary>The line up to the first // that is not in quotes</summary>
    class function RemoveLineComments(const AText: string): string; static;
    /// <summary>Adds the missing ( or ) so that they are balanced</summary>
    class function FixParenthesisLevel(const AText: string): string; static;
    /// <summary>
    ///   The arguments of a call, split at the commas that are not in quotes or in
    ///   parentheses; the parentheses around everything are dropped; empty ones are skipped
    /// </summary>
    class function ParamsToList(const AText: string): TArray<string>; static;
    /// <summary>True for a text in a pair of ' or " that does not have the quote inside</summary>
    class function IsStringInQuotes(const AText: string): Boolean; static;
    /// <summary>The words of the text, as the scanner reads them</summary>
    class function TokensToList(const AText: string; const ALog: ILog): TArray<string>; static;
    /// <summary>Removes the characters up to #32 at both ends</summary>
    class function Trim(const AText: string): string; static;
    /// <summary>The lines of a text, like TStringList.Text: CR LF, LF or CR end a line; a last line break does not add an empty one</summary>
    class function SplitLines(const AText: string): TArray<string>; static;
  end;

implementation

uses
  DelphiDoom.Scanner.Scanner;

{ TScannerText }

class function TScannerText.Trim(const AText: string): string;
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

class function TScannerText.SplitLines(const AText: string): TArray<string>;
var
  LIndex: Integer;
  LStart: Integer;
  LCount: Integer;
begin
  Result := nil;
  LStart := 1;
  LIndex := 1;
  LCount := Length(AText);
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

class function TScannerText.RemoveLineQuotes(const AText: string): string;
var
  LLine: string;
  LText: string;
  LPosition: Integer;
begin
  Result := '';
  for LLine in SplitLines(AText) do
  begin
    LText := Trim(LLine);
    LPosition := Pos('//', LText);
    if LPosition > 0 then
      LText := Copy(LText, 1, LPosition - 1);
    LPosition := Pos(';', LText);
    if LPosition > 0 then
      LText := Copy(LText, 1, LPosition - 1);
    if LText <> '' then
      Result := Result + LText + #13#10;
  end;
end;

class function TScannerText.RemoveLineComments(const AText: string): string;
var
  LIndex: Integer;
  LInQuotes: Boolean;
begin
  Result := '';
  LInQuotes := False;
  for LIndex := 1 to Length(AText) do
  begin
    if AText[LIndex] = '"' then
      LInQuotes := not LInQuotes;
    if not LInQuotes then
      if LIndex < Length(AText) then
        if (AText[LIndex] = '/') and (AText[LIndex + 1] = '/') then
          Break;
    Result := Result + AText[LIndex];
  end;
end;

class function TScannerText.FixParenthesisLevel(const AText: string): string;
var
  LIndex: Integer;
  LLeft: Integer;
  LRight: Integer;
begin
  Result := AText;
  LLeft := 0;
  LRight := 0;
  for LIndex := 1 to Length(Result) do
    if Result[LIndex] = '(' then
      Inc(LLeft)
    else if Result[LIndex] = ')' then
      Inc(LRight);
  while LRight < LLeft do
  begin
    Result := Result + ')';
    Inc(LRight);
  end;
  while LRight > LLeft do
  begin
    Result := '(' + Result;
    Inc(LLeft);
  end;
end;

class function TScannerText.ParamsToList(const AText: string): TArray<string>;
var
  LInput: string;
  LCurrent: string;
  LIndex: Integer;
  LLevel: Integer;
  LInQuotes: Boolean;
  LAllInParenthesis: Boolean;
begin
  Result := nil;
  LInput := Trim(AText);
  if LInput = '' then
    Exit;

  if (LInput[1] = '(') and (LInput[Length(LInput)] = ')') then
  begin
    LAllInParenthesis := True;
    LLevel := 0;
    for LIndex := 2 to Length(LInput) - 1 do
    begin
      if LInput[LIndex] = '(' then
        Inc(LLevel)
      else if LInput[LIndex] = ')' then
        Dec(LLevel);
      if LLevel < 0 then
      begin
        LAllInParenthesis := False;
        Break;
      end;
    end;
    if LAllInParenthesis then
    begin
      LInput[1] := ' ';
      LInput[Length(LInput)] := ' ';
      LInput := Trim(LInput);
      if LInput = '' then
        Exit;
    end;
  end;

  LLevel := 0;
  LInQuotes := False;
  LCurrent := '';
  for LIndex := 1 to Length(LInput) do
  begin
    if LInput[LIndex] = ',' then
      if not LInQuotes and (LLevel = 0) then
      begin
        LCurrent := Trim(LCurrent);
        if LCurrent <> '' then
        begin
          SetLength(Result, Length(Result) + 1);
          Result[High(Result)] := LCurrent;
          LCurrent := '';
        end;
        Continue;
      end;
    LCurrent := LCurrent + LInput[LIndex];
    if LInput[LIndex] = '(' then
      Inc(LLevel)
    else if LInput[LIndex] = ')' then
    begin
      Dec(LLevel);
      if LLevel < 0 then
        LLevel := 0;
    end
    else if LInput[LIndex] = '"' then
      LInQuotes := not LInQuotes;
  end;
  LCurrent := Trim(LCurrent);
  if LCurrent <> '' then
  begin
    SetLength(Result, Length(Result) + 1);
    Result[High(Result)] := LCurrent;
  end;
end;

class function TScannerText.IsStringInQuotes(const AText: string): Boolean;
var
  LIndex: Integer;
begin
  if Length(AText) < 2 then
    Exit(False);
  if not ((AText[1] = '''') or (AText[1] = '"')) then
    Exit(False);
  if AText[1] <> AText[Length(AText)] then
    Exit(False);
  for LIndex := 2 to Length(AText) - 1 do
    if AText[LIndex] = AText[1] then
      Exit(False);
  Result := True;
end;

class function TScannerText.TokensToList(const AText: string; const ALog: ILog): TArray<string>;
var
  LScanner: TScriptScanner;
begin
  Result := nil;
  LScanner := TScriptScanner.Create(AText, ALog);
  try
    while LScanner.GetString do
    begin
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := LScanner.AsString;
    end;
  finally
    LScanner.Free;
  end;
end;

end.

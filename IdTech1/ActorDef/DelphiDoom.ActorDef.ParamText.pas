{******************************************************************************}
{                                                                              }
{  DelphiDoom: actor definition library - the texts of the action parameters   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ActorDef.ParamText;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   The conversions of d_delphi that the parameters of the actions use (atoi, atof,
  ///   StrIsInteger, wordstolist, RemoveQuotesFromString), with the same results but without
  ///   the global format settings
  /// </summary>
  TActorDefParamText = class sealed
  public
    /// <summary>Digits only (at least one)</summary>
    class function IsLongWord(const AText: string): Boolean; static;
    /// <summary>Digits only, with an optional - in front</summary>
    class function IsInteger(const AText: string): Boolean; static;
    /// <summary>Digits with at most one . or , and an optional - in front</summary>
    class function IsFloat(const AText: string): Boolean; static;
    /// <summary>
    ///   The integer of a text: decimal, 0x hexadecimal, -0x or #decimal; ADefault if the
    ///   text is none of them
    /// </summary>
    class function ToInteger(const AText: string; const ADefault: Integer): Integer; static;
    /// <summary>The number of a text, with . or ,; ADefault if the text is not one</summary>
    class function ToFloat(const AText: string; const ADefault: Single): Single; static;
    /// <summary>
    ///   The words of a text cut at the characters of ASplitters; a word is trimmed (blanks
    ///   and control characters) when a splitter ends it, the last one is not (the old
    ///   wordstolist), and empty words are left out
    /// </summary>
    class function WordsToList(const AText: string; const ASplitters: TSysCharSet): TArray<string>; static;
    /// <summary>The text without a quote at the start and one at the end</summary>
    class function RemoveQuotes(const AText: string): string; static;
    /// <summary>
    ///   The text as a ShortString keeps it: at most 255 characters of the ANSI code page
    ///   (what the old customparam_t did to every text it stored)
    /// </summary>
    class function ToShortText(const AText: string): string; static;
  end;

implementation

uses
  DelphiDoom.Scanner.Numbers,
  DelphiDoom.Scanner.Strings;

{ TActorDefParamText }

class function TActorDefParamText.IsLongWord(const AText: string): Boolean;
begin
  Result := TScannerStrings.IsDigits(AText);
end;

class function TActorDefParamText.IsInteger(const AText: string): Boolean;
begin
  if (AText <> '') and (AText[1] = '-') then
    Result := IsLongWord(Copy(AText, 2, MaxInt))
  else
    Result := IsLongWord(AText);
end;

class function TActorDefParamText.IsFloat(const AText: string): Boolean;
begin
  Result := TScannerNumbers.IsFloat(AText);
end;

class function TActorDefParamText.ToInteger(const AText: string; const ADefault: Integer): Integer;
begin
  Result := TScannerStrings.ToInteger(AText, ADefault);
end;

class function TActorDefParamText.ToFloat(const AText: string; const ADefault: Single): Single;
var
  LCode: Integer;
  LText: string;
begin
  Val(AText, Result, LCode);
  if LCode = 0 then
    Exit;
  LText := AText.Replace(',', '.');
  Val(LText, Result, LCode);
  if LCode = 0 then
    Exit;
  Result := ADefault;
end;

class function TActorDefParamText.WordsToList(const AText: string;
  const ASplitters: TSysCharSet): TArray<string>;
var
  LIndex: Integer;
  LWord: string;
  LCount: Integer;
begin
  Result := nil;
  LCount := 0;
  LWord := '';
  for LIndex := 1 to Length(AText) do
  begin
    if CharInSet(AText[LIndex], ASplitters) then
    begin
      LWord := TScannerStrings.Trim(LWord);
      if LWord <> '' then
      begin
        SetLength(Result, LCount + 1);
        Result[LCount] := LWord;
        Inc(LCount);
        LWord := '';
      end;
    end
    else
      LWord := LWord + AText[LIndex];
  end;
  if LWord <> '' then
  begin
    SetLength(Result, LCount + 1);
    Result[LCount] := LWord;
  end;
end;

class function TActorDefParamText.RemoveQuotes(const AText: string): string;
begin
  Result := AText;
  if Result = '' then
    Exit;
  if Result[1] = '"' then
    Delete(Result, 1, 1);
  if (Result <> '') and (Result[Length(Result)] = '"') then
    Delete(Result, Length(Result), 1);
end;

class function TActorDefParamText.ToShortText(const AText: string): string;
var
  LShort: ShortString;
begin
  LShort := ShortString(AText);
  Result := string(LShort);
end;

end.

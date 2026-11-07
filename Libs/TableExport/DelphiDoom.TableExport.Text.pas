{******************************************************************************}
{                                                                              }
{  DelphiDoom: TableExport library - the small text functions of the writers   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.TableExport.Text;

interface

type
  /// <summary>Text helpers that the writers share</summary>
  TExportText = class
  public
    /// <summary>The label of a field: lower case with the first letter of every word in upper case</summary>
    class function Capitalize(const AText: string): string; static;
    /// <summary>A fixed point number as "%2.4f" does, with a dot as separator</summary>
    class function FixedText(AValue: Integer): string; static;
    /// <summary>
    ///   The names of the bits that are set, in the order of the bits, joined by ASeparator;
    ///   empty if no bit is set (or there is no name for it)
    /// </summary>
    class function FlagList(AValue: Integer; const ANames: TArray<string>;
      const ASeparator: string): string; static;
    /// <summary>The text of a string of the game as a patch has it: no CR, a line feed is "\n"</summary>
    class function ToCString(const AText: string): string; static;
    /// <summary>The text in a Pascal string: every quote is doubled</summary>
    class function PascalEscape(const AText: string): string; static;
    /// <summary>A text trimmed of every character at or below the space</summary>
    class function Trim(const AText: string): string; static;
    /// <summary>
    ///   Splits "key = value" at the first AChar. Both parts are trimmed; without the
    ///   character the key is the whole text and the value is empty
    /// </summary>
    class procedure Split(const AText: string; AChar: Char; out AKey, AValue: string); static;
    /// <summary>The text starts with the prefix (case sensitive)</summary>
    class function StartsWith(const APrefix, AText: string): Boolean; static;
  end;

implementation

uses
  System.SysUtils;

{ TExportText }

class function TExportText.Capitalize(const AText: string): string;
var
  LIndex: Integer;
begin
  if AText = '' then
    Exit('');
  Result := LowerCase(AText);
  Result[1] := UpCase(Result[1]);
  for LIndex := 2 to Length(Result) do
    if Result[LIndex - 1] = ' ' then
      Result[LIndex] := UpCase(Result[LIndex]);
end;

class function TExportText.FixedText(AValue: Integer): string;
begin
  Result := Format('%2.4f', [Single(AValue / 65536)], TFormatSettings.Invariant);
end;

class function TExportText.FlagList(AValue: Integer; const ANames: TArray<string>;
  const ASeparator: string): string;
var
  LIndex: Integer;
  LBits: Cardinal;
begin
  Result := '';
  LBits := Cardinal(AValue);
  for LIndex := 0 to High(ANames) do
    if (LIndex < 32) and ((LBits and (Cardinal(1) shl LIndex)) <> 0) then
    begin
      if Result <> '' then
        Result := Result + ASeparator;
      Result := Result + ANames[LIndex];
    end;
end;

class function TExportText.ToCString(const AText: string): string;
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

class function TExportText.PascalEscape(const AText: string): string;
begin
  Result := StringReplace(AText, '''', '''''', [rfReplaceAll]);
end;

class function TExportText.Trim(const AText: string): string;
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

class procedure TExportText.Split(const AText: string; AChar: Char; out AKey, AValue: string);
var
  LPosition: Integer;
begin
  LPosition := Pos(AChar, AText);
  if LPosition = 0 then
  begin
    AKey := AText;
    AValue := '';
  end
  else
  begin
    AKey := Trim(Copy(AText, 1, LPosition - 1));
    AValue := Trim(Copy(AText, LPosition + 1, Length(AText)));
  end;
end;

class function TExportText.StartsWith(const APrefix, AText: string): Boolean;
begin
  Result := (Length(AText) >= Length(APrefix)) and (Copy(AText, 1, Length(APrefix)) = APrefix);
end;

end.

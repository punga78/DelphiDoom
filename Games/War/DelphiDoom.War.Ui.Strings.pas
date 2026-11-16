{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the string helpers of the cheats                  }
{                                                                              }
{  Port of shl/wstr.h (wsv_trimLeft, wsv_equalsIgnoreCase,                     }
{  wsv_startsWithIgnoreCase, wsv_tryParseS32) used by war_cheats.c, (c) 2019   }
{  Alejandro Coto Gutierrez, zlib License (see Games\War\LICENSE-war1.txt).    }
{  This is an altered version, not the original.                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Ui.Strings;

interface

uses
  System.SysUtils;

type
  /// <summary>The functions of the strings of the original, on bytes and with ASCII rules (never the locale)</summary>
  TWarStrings = class
  strict private
    class function LowerAscii(AChar: AnsiChar): AnsiChar; static;
    class function IsSpace(AChar: AnsiChar): Boolean; static;
  public
    /// <summary>wsv_trimLeft: C isspace (space, tab, LF, VT, FF, CR)</summary>
    class function TrimLeft(const AText: AnsiString): AnsiString; static;
    /// <summary>wsv_trim</summary>
    class function Trim(const AText: AnsiString): AnsiString; static;
    /// <summary>wsv_equalsIgnoreCase: same length and same letters, only A-Z are folded</summary>
    class function EqualsIgnoreCase(const ALeft, ARight: AnsiString): Boolean; static;
    /// <summary>wsv_startsWithIgnoreCase</summary>
    class function StartsWithIgnoreCase(const AText, APrefix: AnsiString): Boolean; static;
    /// <summary>
    ///   wsv_tryParseS32: the text without the spaces around it, an optional sign, then decimal digits, 0x and
    ///   hexadecimal digits, or a leading 0 and octal digits; false for anything else or a value out of 32 bits
    /// </summary>
    class function TryParseS32(const AText: AnsiString; out AValue: Integer): Boolean; static;
  end;

implementation

{ TWarStrings }

class function TWarStrings.LowerAscii(AChar: AnsiChar): AnsiChar;
begin
  if (AChar >= 'A') and (AChar <= 'Z') then
    Result := AnsiChar(Ord(AChar) + 32)
  else
    Result := AChar;
end;

class function TWarStrings.IsSpace(AChar: AnsiChar): Boolean;
begin
  Result := AChar in [#9, #10, #11, #12, #13, ' '];
end;

class function TWarStrings.TrimLeft(const AText: AnsiString): AnsiString;
var
  LIndex: Integer;
begin
  LIndex := 1;
  while (LIndex <= Length(AText)) and IsSpace(AText[LIndex]) do
    Inc(LIndex);
  Result := Copy(AText, LIndex, MaxInt);
end;

class function TWarStrings.Trim(const AText: AnsiString): AnsiString;
var
  LLength: Integer;
begin
  Result := TrimLeft(AText);
  LLength := Length(Result);
  while (LLength > 0) and IsSpace(Result[LLength]) do
    Dec(LLength);
  SetLength(Result, LLength);
end;

class function TWarStrings.EqualsIgnoreCase(const ALeft, ARight: AnsiString): Boolean;
var
  LIndex: Integer;
begin
  if Length(ALeft) <> Length(ARight) then
    Exit(False);
  for LIndex := 1 to Length(ALeft) do
    if LowerAscii(ALeft[LIndex]) <> LowerAscii(ARight[LIndex]) then
      Exit(False);
  Result := True;
end;

class function TWarStrings.StartsWithIgnoreCase(const AText, APrefix: AnsiString): Boolean;
begin
  Result := (Length(APrefix) <= Length(AText)) and EqualsIgnoreCase(Copy(AText, 1, Length(APrefix)), APrefix);
end;

class function TWarStrings.TryParseS32(const AText: AnsiString; out AValue: Integer): Boolean;
var
  LView: AnsiString;
  LIndex: Integer;
  LNegative: Boolean;
  LBase: Integer;
  LChar: AnsiChar;
  LDigit: Integer;
  LLimit: UInt64;
  LResult: UInt64;
  LHasDigits: Boolean;
  LSigned: Int64;
begin
  AValue := 0;
  LView := Trim(AText);
  if LView = '' then
    Exit(False);
  LIndex := 1;
  LNegative := False;
  if (LView[LIndex] = '+') or (LView[LIndex] = '-') then
  begin
    LNegative := LView[LIndex] = '-';
    Inc(LIndex);
  end;
  if LIndex > Length(LView) then
    Exit(False);
  LBase := 10;
  if (LView[LIndex] = '0') and (LIndex + 1 <= Length(LView)) then
  begin
    if (LView[LIndex + 1] = 'x') or (LView[LIndex + 1] = 'X') then
    begin
      LBase := 16;
      Inc(LIndex, 2);
    end
    else
      LBase := 8;
  end;
  if LIndex > Length(LView) then
    Exit(False);
  if LNegative then
    LLimit := UInt64(High(Int64)) + 1
  else
    LLimit := UInt64(High(Int64));
  LResult := 0;
  LHasDigits := False;
  while LIndex <= Length(LView) do
  begin
    LChar := LView[LIndex];
    if (LChar >= '0') and (LChar <= '9') then
      LDigit := Ord(LChar) - Ord('0')
    else if (LChar >= 'a') and (LChar <= 'f') then
      LDigit := 10 + Ord(LChar) - Ord('a')
    else if (LChar >= 'A') and (LChar <= 'F') then
      LDigit := 10 + Ord(LChar) - Ord('A')
    else
      Exit(False);
    if LDigit >= LBase then
      Exit(False);
    if LResult > (LLimit - UInt64(LDigit)) div UInt64(LBase) then
      Exit(False);
    LResult := LResult * UInt64(LBase) + UInt64(LDigit);
    LHasDigits := True;
    Inc(LIndex);
  end;
  if not LHasDigits then
    Exit(False);
  if LNegative then
  begin
    if LResult = UInt64(High(Int64)) + 1 then
      LSigned := Low(Int64)
    else
      LSigned := -Int64(LResult);
  end
  else
    LSigned := Int64(LResult);
  if (LSigned < Low(Integer)) or (LSigned > High(Integer)) then
    Exit(False);
  AValue := Integer(LSigned);
  Result := True;
end;

end.

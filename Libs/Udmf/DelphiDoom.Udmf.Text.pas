{******************************************************************************}
{                                                                              }
{  DelphiDoom: UDMF library - numbers and names from the text                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Udmf.Text;

interface

uses
  System.SysUtils, DelphiDoom.Udmf.Types;

type
  TUdmfText = class
  public
    /// <summary>The same letters, with the capital ones for a to z only (nothing is done to the others)</summary>
    class function ToUpper(const AText: string): string; static;
    /// <summary>
    ///   An integer like the old code read it: decimal with a sign, or hexadecimal after $ or 0x;
    ///   false if there are other characters or the number does not fit in 32 bits
    /// </summary>
    class function TryParseInteger(const AText: string; out AValue: Integer): Boolean; static;
    /// <summary>A number with a point and, if it has to be, an exponent; false for anything else</summary>
    class function TryParseFloat(const AText: string; out AValue: Single): Boolean; static;
    /// <summary>The first 8 characters of the name, with zeros after them</summary>
    class function ToName8(const AText: string): TUdmfName8; static;
  end;

implementation

{ TUdmfText }

class function TUdmfText.ToUpper(const AText: string): string;
var
  LIndex: Integer;
begin
  Result := AText;
  for LIndex := 1 to Length(Result) do
    if (Result[LIndex] >= 'a') and (Result[LIndex] <= 'z') then
      Result[LIndex] := Char(Ord(Result[LIndex]) - 32);
end;

class function TUdmfText.TryParseInteger(const AText: string; out AValue: Integer): Boolean;
var
  LIndex: Integer;
  LNegative: Boolean;
  LHex: Boolean;
  LValue: Int64;
  LDigit: Integer;
  LChar: Char;
  LDigits: Integer;
begin
  Result := False;
  AValue := 0;
  LIndex := 1;
  LNegative := False;
  if (LIndex <= Length(AText)) and ((AText[LIndex] = '-') or (AText[LIndex] = '+')) then
  begin
    LNegative := AText[LIndex] = '-';
    Inc(LIndex);
  end;

  LHex := False;
  if (LIndex <= Length(AText)) and (AText[LIndex] = '$') then
  begin
    LHex := True;
    Inc(LIndex);
  end
  else if (LIndex + 1 <= Length(AText)) and (AText[LIndex] = '0') and
    ((AText[LIndex + 1] = 'x') or (AText[LIndex + 1] = 'X')) then
  begin
    LHex := True;
    Inc(LIndex, 2);
  end;

  LValue := 0;
  LDigits := 0;
  while LIndex <= Length(AText) do
  begin
    LChar := AText[LIndex];
    if (LChar >= '0') and (LChar <= '9') then
      LDigit := Ord(LChar) - Ord('0')
    else if LHex and (LChar >= 'a') and (LChar <= 'f') then
      LDigit := 10 + Ord(LChar) - Ord('a')
    else if LHex and (LChar >= 'A') and (LChar <= 'F') then
      LDigit := 10 + Ord(LChar) - Ord('A')
    else
      Exit;
    if LHex then
      LValue := LValue * 16 + LDigit
    else
      LValue := LValue * 10 + LDigit;
    if LValue > $FFFFFFFF then
      Exit;
    Inc(LDigits);
    Inc(LIndex);
  end;
  if LDigits = 0 then
    Exit;

  if LNegative then
    LValue := -LValue;
  if LHex then
  begin
    // hexadecimal numbers fill the 32 bits
    if (LValue < Low(Integer)) or (LValue > $FFFFFFFF) then
      Exit;
    AValue := Integer(Cardinal(LValue and $FFFFFFFF));
  end
  else
  begin
    if (LValue < Low(Integer)) or (LValue > High(Integer)) then
      Exit;
    AValue := Integer(LValue);
  end;
  Result := True;
end;

class function TUdmfText.TryParseFloat(const AText: string; out AValue: Single): Boolean;
var
  LIndex: Integer;
  LExtended: Extended;
  LSettings: TFormatSettings;
begin
  AValue := 0;
  Result := False;
  if AText = '' then
    Exit;
  for LIndex := 1 to Length(AText) do
    if not CharInSet(AText[LIndex], ['+', '-', '.', 'e', 'E', '0'..'9']) then
      Exit;

  LSettings := TFormatSettings.Create('en-US');
  LSettings.DecimalSeparator := '.';
  LSettings.ThousandSeparator := #0;
  if not TryStrToFloat(AText, LExtended, LSettings) then
    Exit;
  AValue := LExtended;
  Result := True;
end;

class function TUdmfText.ToName8(const AText: string): TUdmfName8;
var
  LIndex: Integer;
begin
  FillChar(Result, SizeOf(Result), 0);
  for LIndex := 1 to Length(AText) do
    if LIndex <= 8 then
      Result[LIndex - 1] := AnsiChar(AText[LIndex]);
end;

end.
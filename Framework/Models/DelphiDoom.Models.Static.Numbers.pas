{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - static models: atoi and atof of the C       }
{  library for the text formats                                                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Static.Numbers;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   The leniency of atoi and atof: leading spaces, an optional sign, the longest prefix that
  ///   is a number, 0 if there is none. Used by the readers of the text formats (ASE, MA), which
  ///   are written with these two functions.
  /// </summary>
  TStaticNumbers = class
  public
    /// <summary>atoi (values out of the range of an Integer saturate: C leaves them undefined)</summary>
    class function Atoi(const AText: AnsiString): Integer; static;
    /// <summary>atof: a double, as C returns it (the callers store it in a Single)</summary>
    class function Atof(const AText: AnsiString): Double; static;
  end;

implementation

{ TStaticNumbers }

class function TStaticNumbers.Atoi(const AText: AnsiString): Integer;
var
  LPos, LLength: Integer;
  LNegative: Boolean;
  LValue: Int64;
begin
  LLength := Length(AText);
  LPos := 1;
  while (LPos <= LLength) and (AText[LPos] in [#9, #10, #11, #12, #13, ' ']) do
    Inc(LPos);
  LNegative := False;
  if (LPos <= LLength) and (AText[LPos] in ['+', '-']) then
  begin
    LNegative := AText[LPos] = '-';
    Inc(LPos);
  end;
  LValue := 0;
  while (LPos <= LLength) and (AText[LPos] in ['0'..'9']) do
  begin
    if LValue < 100000000000 then
      LValue := LValue * 10 + (Ord(AText[LPos]) - Ord('0'));
    Inc(LPos);
  end;
  if LNegative then
    LValue := -LValue;
  if LValue > High(Integer) then
    LValue := High(Integer);
  if LValue < Low(Integer) then
    LValue := Low(Integer);
  Result := Integer(LValue);
end;

class function TStaticNumbers.Atof(const AText: AnsiString): Double;
var
  LPos, LLength, LStart, LDigits, LExponentStart: Integer;
  LNumber: string;
  LSettings: TFormatSettings;
begin
  Result := 0;
  LLength := Length(AText);
  LPos := 1;
  while (LPos <= LLength) and (AText[LPos] in [#9, #10, #11, #12, #13, ' ']) do
    Inc(LPos);
  LStart := LPos;
  if (LPos <= LLength) and (AText[LPos] in ['+', '-']) then
    Inc(LPos);
  LDigits := 0;
  while (LPos <= LLength) and (AText[LPos] in ['0'..'9']) do
  begin
    Inc(LPos);
    Inc(LDigits);
  end;
  if (LPos <= LLength) and (AText[LPos] = '.') then
  begin
    Inc(LPos);
    while (LPos <= LLength) and (AText[LPos] in ['0'..'9']) do
    begin
      Inc(LPos);
      Inc(LDigits);
    end;
  end;
  if LDigits = 0 then
    Exit;
  if (LPos <= LLength) and (AText[LPos] in ['e', 'E']) then
  begin
    LExponentStart := LPos;
    Inc(LPos);
    if (LPos <= LLength) and (AText[LPos] in ['+', '-']) then
      Inc(LPos);
    if (LPos <= LLength) and (AText[LPos] in ['0'..'9']) then
    begin
      while (LPos <= LLength) and (AText[LPos] in ['0'..'9']) do
        Inc(LPos);
    end
    else
      LPos := LExponentStart;
  end;
  LNumber := string(Copy(AText, LStart, LPos - LStart));
  LSettings := TFormatSettings.Invariant;
  if not TryStrToFloat(LNumber, Result, LSettings) then
    Result := 0;
end;

end.

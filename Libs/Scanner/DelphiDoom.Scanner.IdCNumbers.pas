{******************************************************************************}
{                                                                              }
{  DelphiDoom: scanner library - TIdCNumbers, the number reading of the C      }
{  library (atoi, atof, sscanf "%f") used by the idTech 4 dictionaries         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Scanner.IdCNumbers;

{$Q-}
{$R-}

interface

type
  /// <summary>
  ///   Numbers read from 8-bit text as <c>atoi</c>, <c>atof</c> and <c>sscanf("%f ...")</c> do: leading white
  ///   space, then the longest prefix that is a number; no number gives 0. <c>atoi</c> saturates like strtol
  ///   (Win32 long = 32 bit). Locale independent (the point is the decimal separator).
  /// </summary>
  TIdCNumbers = class
  public
    class function Atoi(const AText: AnsiString): Integer; static;
    class function Atof(const AText: AnsiString): Double; static;
    /// <summary>
    ///   sscanf of up to <c>Length(AValues)</c> floats separated by white space: how many were read; the
    ///   others keep their value
    /// </summary>
    class function ScanFloats(const AText: AnsiString; var AValues: array of Single): Integer; static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.IdLib.Text.Strings;

class function TIdCNumbers.Atoi(const AText: AnsiString): Integer;
var
  LIndex, LLength: Integer;
  LNegative: Boolean;
  LValue: Int64;
begin
  LLength := TIdStrings.Length(AText);
  LIndex := 1;
  while (LIndex <= LLength) and (AText[LIndex] in [#9, #10, #11, #12, #13, ' ']) do
    Inc(LIndex);
  LNegative := False;
  if (LIndex <= LLength) and (AText[LIndex] in ['+', '-']) then
  begin
    LNegative := AText[LIndex] = '-';
    Inc(LIndex);
  end;
  LValue := 0;
  while (LIndex <= LLength) and (AText[LIndex] in ['0'..'9']) do
  begin
    // strtol saturates
    if LValue < 4294967296 then
      LValue := LValue * 10 + (Ord(AText[LIndex]) - Ord('0'));
    Inc(LIndex);
  end;
  if LNegative then
    LValue := -LValue;
  if LValue > High(Integer) then
    Exit(High(Integer));
  if LValue < Low(Integer) then
    Exit(Low(Integer));
  Result := Integer(LValue);
end;

class function TIdCNumbers.Atof(const AText: AnsiString): Double;
var
  LIndex, LLength, LStart, LDigits: Integer;
begin
  LLength := TIdStrings.Length(AText);
  LIndex := 1;
  while (LIndex <= LLength) and (AText[LIndex] in [#9, #10, #11, #12, #13, ' ']) do
    Inc(LIndex);
  LStart := LIndex;
  if (LIndex <= LLength) and (AText[LIndex] in ['+', '-']) then
    Inc(LIndex);
  LDigits := 0;
  while (LIndex <= LLength) and (AText[LIndex] in ['0'..'9']) do
  begin
    Inc(LIndex);
    Inc(LDigits);
  end;
  if (LIndex <= LLength) and (AText[LIndex] = '.') then
  begin
    Inc(LIndex);
    while (LIndex <= LLength) and (AText[LIndex] in ['0'..'9']) do
    begin
      Inc(LIndex);
      Inc(LDigits);
    end;
  end;
  if LDigits = 0 then
    Exit(0);
  // an exponent counts only when it has digits
  if (LIndex <= LLength) and (AText[LIndex] in ['e', 'E']) then
  begin
    LDigits := LIndex + 1;
    if (LDigits <= LLength) and (AText[LDigits] in ['+', '-']) then
      Inc(LDigits);
    if (LDigits <= LLength) and (AText[LDigits] in ['0'..'9']) then
    begin
      while (LDigits <= LLength) and (AText[LDigits] in ['0'..'9']) do
        Inc(LDigits);
      LIndex := LDigits;
    end;
  end;
  if not TryStrToFloat(string(Copy(AText, LStart, LIndex - LStart)), Result, TFormatSettings.Invariant) then
    Result := 0;
end;

class function TIdCNumbers.ScanFloats(const AText: AnsiString; var AValues: array of Single): Integer;
var
  LPosition, LLength, LStart: Integer;
  LValue: Double;
begin
  Result := 0;
  LLength := TIdStrings.Length(AText);
  LPosition := 1;
  while Result < System.Length(AValues) do
  begin
    while (LPosition <= LLength) and (AText[LPosition] in [#9, #10, #11, #12, #13, ' ']) do
      Inc(LPosition);
    if LPosition > LLength then
      Exit;
    LStart := LPosition;
    if AText[LPosition] in ['+', '-'] then
      Inc(LPosition);
    if (LPosition > LLength) or not (AText[LPosition] in ['0'..'9', '.']) then
      Exit;
    while (LPosition <= LLength) and (AText[LPosition] in ['0'..'9', '.', 'e', 'E', '+', '-']) do
    begin
      // a sign belongs to the number only after an exponent
      if (AText[LPosition] in ['+', '-']) and not (AText[LPosition - 1] in ['e', 'E']) then
        Break;
      Inc(LPosition);
    end;
    LValue := Atof(Copy(AText, LStart, LPosition - LStart));
    // atof reads the longest valid prefix, which is what sscanf takes too
    AValues[Result] := LValue;
    Inc(Result);
  end;
end;


end.

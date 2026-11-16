{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - C numbers from text (atof, atoi, sscanf)          }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software). Copyright (C)   }
{  1999-2005 Id Software, Inc. This unit is derived from the Quake III Arena   }
{  source code and is therefore available under the GNU General Public         }
{  License, version 2 or (at your option) any later version.                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Bsp.CNumbers;

interface

uses
  DelphiDoom.MathCore.Types;

type
  /// <summary>atof, atoi and sscanf("%lf %lf %lf") of the C library: the longest prefix that is a number</summary>
  TAasCNumbers = class sealed
  public
    /// <summary>atof; 0 if the text does not begin with a number</summary>
    class function AtoF(const AText: AnsiString): Double; static;
    /// <summary>atoi; 0 if the text does not begin with a number</summary>
    class function AtoI(const AText: AnsiString): Integer; static;
    /// <summary>
    ///   sscanf(text, "%lf %lf %lf") into the three components, each from zero; the components that are not
    ///   there stay zero
    /// </summary>
    class function ScanVector(const AText: AnsiString): TVec3; static;
  end;

implementation

uses
  System.SysUtils;

function SkipSpaces(const AText: AnsiString; const AFrom: Integer): Integer;
begin
  Result := AFrom;
  while (Result <= Length(AText)) and (AText[Result] in [#9 .. #13, ' ']) do
    Inc(Result);
end;

// Scans the longest prefix of a decimal floating point number; the position after it (the start if none)
function ScanFloat(const AText: AnsiString; const AFrom: Integer; out AValue: Double): Integer;
var
  LPos, LMantissaEnd: Integer;
  LNumber: string;
  LHasDigits: Boolean;
begin
  LPos := AFrom;
  AValue := 0;
  Result := AFrom;
  if (LPos <= Length(AText)) and (AText[LPos] in ['+', '-']) then
    Inc(LPos);
  LHasDigits := False;
  while (LPos <= Length(AText)) and (AText[LPos] in ['0' .. '9']) do
  begin
    Inc(LPos);
    LHasDigits := True;
  end;
  if (LPos <= Length(AText)) and (AText[LPos] = '.') then
  begin
    Inc(LPos);
    while (LPos <= Length(AText)) and (AText[LPos] in ['0' .. '9']) do
    begin
      Inc(LPos);
      LHasDigits := True;
    end;
  end;
  if not LHasDigits then
    Exit;
  LMantissaEnd := LPos;
  if (LPos <= Length(AText)) and (AText[LPos] in ['e', 'E']) then
  begin
    Inc(LPos);
    if (LPos <= Length(AText)) and (AText[LPos] in ['+', '-']) then
      Inc(LPos);
    if (LPos <= Length(AText)) and (AText[LPos] in ['0' .. '9']) then
    begin
      while (LPos <= Length(AText)) and (AText[LPos] in ['0' .. '9']) do
        Inc(LPos);
      LMantissaEnd := LPos;
    end;
  end;
  LNumber := string(Copy(AText, AFrom, LMantissaEnd - AFrom));
  if TryStrToFloat(LNumber, AValue, TFormatSettings.Invariant) then
    Result := LMantissaEnd
  else
    AValue := 0;
end;

{ TAasCNumbers }

class function TAasCNumbers.AtoF(const AText: AnsiString): Double;
begin
  ScanFloat(AText, SkipSpaces(AText, 1), Result);
end;

class function TAasCNumbers.AtoI(const AText: AnsiString): Integer;
var
  LPos: Integer;
  LNegative: Boolean;
  LValue: Int64;
begin
  LPos := SkipSpaces(AText, 1);
  LNegative := False;
  if (LPos <= Length(AText)) and (AText[LPos] in ['+', '-']) then
  begin
    LNegative := AText[LPos] = '-';
    Inc(LPos);
  end;
  LValue := 0;
  while (LPos <= Length(AText)) and (AText[LPos] in ['0' .. '9']) do
  begin
    // the original overflows int: the value is cut to 32 bits
    LValue := (LValue * 10 + Ord(AText[LPos]) - Ord('0')) and $FFFFFFFF;
    Inc(LPos);
  end;
  if LNegative then
    LValue := -LValue;
  Result := Integer(Cardinal(LValue and $FFFFFFFF));
end;

class function TAasCNumbers.ScanVector(const AText: AnsiString): TVec3;
var
  LPos, LNext, LIndex: Integer;
  LValue: Double;
begin
  Result[0] := 0;
  Result[1] := 0;
  Result[2] := 0;
  LPos := 1;
  for LIndex := 0 to 2 do
  begin
    LPos := SkipSpaces(AText, LPos);
    LNext := ScanFloat(AText, LPos, LValue);
    if LNext = LPos then
      Break;
    Result[LIndex] := LValue;
    LPos := LNext;
  end;
end;

end.

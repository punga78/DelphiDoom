{******************************************************************************}
{                                                                              }
{  DelphiDoom: speed library - the names of the files of the container         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Speed.Names;

interface

uses
  System.SysUtils;

type
  /// <summary>What the translator of the fork did with the names of the files</summary>
  TSpeedNames = class
  public
    /// <summary>
    ///   atoi of d_delphi: a decimal number, 0x or $ and hexadecimal digits, a minus and 0x, or #
    ///   and decimal digits; 0 when it is none of them (or it does not fit an Integer)
    /// </summary>
    class function ToInteger(const AText: string): Integer; static;
    /// <summary>The text before the first point (all of it when there is none), trimmed</summary>
    class function Stem(const AName: string): string; static;
    /// <summary>The text after the first point, trimmed; empty when there is none</summary>
    class function Extension(const AName: string): string; static;
    /// <summary>The number that a name starts with, as ToInteger of its stem</summary>
    class function NumericPrefix(const AName: string): Integer; static;
    /// <summary>True when the stem is a number written the canonical way: 5, 22 or -3, not 05 or 0x5</summary>
    class function HasCanonicalNumberStem(const AName: string): Boolean; static;
    /// <summary>The order of the directory: the number first, then the name (exact comparison)</summary>
    class function Compare(const ALeft, ARight: string): Integer; static;
    /// <summary>True when the name ends with the extension (a point and 3 letters), the case ignored</summary>
    class function EndsWith(const AName, AExtension: string): Boolean; static;
    /// <summary>The name without its last four characters (the point and the extension)</summary>
    class function WithoutExtension(const AName: string): string; static;
    /// <summary>The number in a text of at least ADigits digits: zeros on the left (IntToStrZFill)</summary>
    class function ZeroFill(ADigits, AValue: Integer): string; static;
  end;

implementation

{ TSpeedNames }

class function TSpeedNames.ToInteger(const AText: string): Integer;
var
  LIndex: Integer;
  LValue: Int64;
  LNegative: Boolean;
  LDigit: Integer;
  LText: string;

  function ParseDecimal(const ADigits: string; out AResult: Int64): Boolean;
  var
    LPosition: Integer;
  begin
    Result := ADigits <> '';
    AResult := 0;
    for LPosition := 1 to Length(ADigits) do
    begin
      if not CharInSet(ADigits[LPosition], ['0'..'9']) then
        Exit(False);
      AResult := AResult * 10 + Ord(ADigits[LPosition]) - Ord('0');
      if AResult > Int64(High(Integer)) + 1 then
        Exit(False);
    end;
  end;

  function ParseHex(const ADigits: string; out AResult: Int64): Boolean;
  var
    LPosition: Integer;
  begin
    Result := (ADigits <> '') and (Length(ADigits) <= 8);
    AResult := 0;
    if not Result then
      Exit;
    for LPosition := 1 to Length(ADigits) do
    begin
      LDigit := Pos(UpCase(ADigits[LPosition]), '0123456789ABCDEF') - 1;
      if LDigit < 0 then
        Exit(False);
      AResult := AResult * 16 + LDigit;
    end;
  end;

begin
  LText := AText;
  LIndex := 1;
  LNegative := False;
  if (LText <> '') and ((LText[1] = '-') or (LText[1] = '+')) then
  begin
    LNegative := LText[1] = '-';
    LIndex := 2;
  end;
  if ParseDecimal(Copy(LText, LIndex, MaxInt), LValue) then
  begin
    if LNegative then
      LValue := -LValue;
    if (LValue >= Low(Integer)) and (LValue <= High(Integer)) then
      Exit(Integer(LValue));
    Exit(0);
  end;
  if (Copy(LText, LIndex, 2) = '0x') or (Copy(LText, LIndex, 2) = '0X') then
  begin
    if ParseHex(Copy(LText, LIndex + 2, MaxInt), LValue) then
    begin
      Result := Integer(Cardinal(LValue));
      if LNegative then
        Result := -Result;
      Exit;
    end;
    Exit(0);
  end;
  if (LIndex = 1) and (LText <> '') and (LText[1] = '$') then
  begin
    if ParseHex(Copy(LText, 2, MaxInt), LValue) then
      Exit(Integer(Cardinal(LValue)));
    Exit(0);
  end;
  if (LIndex = 1) and (LText <> '') and (LText[1] = '#') then
  begin
    if ParseDecimal(Copy(LText, 2, MaxInt), LValue) and (LValue <= High(Integer)) then
      Exit(Integer(LValue));
    Exit(0);
  end;
  Result := 0;
end;

class function TSpeedNames.Stem(const AName: string): string;
var
  LPoint: Integer;
begin
  LPoint := Pos('.', AName);
  if LPoint = 0 then
    Result := AName
  else
    Result := Trim(Copy(AName, 1, LPoint - 1));
end;

class function TSpeedNames.Extension(const AName: string): string;
var
  LPoint: Integer;
begin
  LPoint := Pos('.', AName);
  if LPoint = 0 then
    Result := ''
  else
    Result := Trim(Copy(AName, LPoint + 1, MaxInt));
end;

class function TSpeedNames.NumericPrefix(const AName: string): Integer;
begin
  Result := ToInteger(Stem(AName));
end;

class function TSpeedNames.HasCanonicalNumberStem(const AName: string): Boolean;
var
  LStem: string;
begin
  LStem := Stem(AName);
  Result := IntToStr(ToInteger(LStem)) = LStem;
end;

class function TSpeedNames.Compare(const ALeft, ARight: string): Integer;
var
  LLeft: Integer;
  LRight: Integer;
begin
  LLeft := NumericPrefix(ALeft);
  LRight := NumericPrefix(ARight);
  if LLeft > LRight then
    Result := 1
  else if LLeft < LRight then
    Result := -1
  else
    Result := CompareStr(ALeft, ARight);
end;

class function TSpeedNames.EndsWith(const AName, AExtension: string): Boolean;
begin
  Result := SameText(Copy(AName, Length(AName) - Length(AExtension) + 1, Length(AExtension)), AExtension);
end;

class function TSpeedNames.WithoutExtension(const AName: string): string;
begin
  Result := Copy(AName, 1, Length(AName) - 4);
end;

class function TSpeedNames.ZeroFill(ADigits, AValue: Integer): string;
begin
  Result := IntToStr(AValue);
  while Length(Result) < ADigits do
    Result := '0' + Result;
end;

end.

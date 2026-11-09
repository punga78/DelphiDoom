{******************************************************************************}
{                                                                              }
{  DelphiDoom: yaml library - converting scalars to numbers and back           }
{  Port of yaml-cpp 0.7.0 (MIT, Jesse Beder): see Libs\Yaml\README.md          }
{  (convert.h and convert.cpp: the std::stringstream rules of libstdc++)       }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Yaml.Convert;

interface

uses
  System.SysUtils,
  System.Math,
  DelphiDoom.Yaml.Types;

type
  /// <summary>
  ///   The conversions of YAML::convert&lt;T&gt;. A number is read like std::stringstream does it with the
  ///   settings of yaml-cpp: no leading spaces, optional sign, base autodetected (0x hexadecimal, a leading 0
  ///   octal), anything but spaces after the number is an error, a number out of range is an error; the
  ///   texts .inf .Inf .INF (with + or -) and .nan .NaN .NAN are the special floating point values
  /// </summary>
  TYamlConvert = class
  strict private
    class function ExtractInteger(const AText: TYamlText; ASigned: Boolean; AMaxMagnitude, AMaxNegMagnitude: UInt64;
      out ANegative: Boolean; out AMagnitude: UInt64): Boolean; static;
    class function ExtractFloat(const AText: TYamlText; out AValue: Double): Boolean; static;
    class function IsSpace(AChar: AnsiChar): Boolean; static;
    class function IsFlexibleCase(const AText: TYamlText): Boolean; static;
  public
    class function TryInt32(const AText: TYamlText; out AValue: Integer): Boolean; static;
    class function TryUInt32(const AText: TYamlText; out AValue: Cardinal): Boolean; static;
    class function TryInt64(const AText: TYamlText; out AValue: Int64): Boolean; static;
    class function TryUInt64(const AText: TYamlText; out AValue: UInt64): Boolean; static;
    class function TryInt16(const AText: TYamlText; out AValue: SmallInt): Boolean; static;
    class function TryUInt16(const AText: TYamlText; out AValue: Word): Boolean; static;
    class function TryInt8(const AText: TYamlText; out AValue: ShortInt): Boolean; static;
    class function TryUInt8(const AText: TYamlText; out AValue: Byte): Boolean; static;
    /// <summary>convert&lt;char&gt;: the text is one char (and spaces after it)</summary>
    class function TryChar(const AText: TYamlText; out AValue: AnsiChar): Boolean; static;
    class function TryDouble(const AText: TYamlText; out AValue: Double): Boolean; static;
    class function TrySingle(const AText: TYamlText; out AValue: Single): Boolean; static;
    /// <summary>convert&lt;bool&gt;: y/n, yes/no, true/false, on/off in lower case, Capitalized or UPPER case</summary>
    class function TryBool(const AText: TYamlText; out AValue: Boolean): Boolean; static;
    /// <summary>IsNullString: '', ~, null, Null and NULL</summary>
    class function IsNullString(const AText: TYamlText): Boolean; static;
    /// <summary>printf("%.*g") of the C library (the exponent has at least two digits); inf, -inf and nan too</summary>
    class function FormatGeneral(AValue: Double; APrecision: Integer): TYamlText; static;
    /// <summary>An integer as std::stringstream writes it with std::dec, std::hex (0x prefix) or std::oct (0 prefix)</summary>
    class function FormatInteger(AValue: UInt64; ANegative: Boolean; ABits: Integer; ABase: Integer): TYamlText; static;
    class function EncodeBase64(const AData: TBytes): TYamlText; static;
    /// <summary>An empty array for an invalid text (like yaml-cpp); bytes above 127 are invalid</summary>
    class function DecodeBase64(const AText: TYamlText): TBytes; static;
  end;

implementation

{ big numbers for the exact digits of a double }

type
  TBigNumber = TArray<Cardinal>; // base 1e9, little endian

const
  BigBase = 1000000000;

procedure BigFromUInt64(AValue: UInt64; var ANumber: TBigNumber);
begin
  SetLength(ANumber, 0);
  while AValue > 0 do
  begin
    SetLength(ANumber, Length(ANumber) + 1);
    ANumber[High(ANumber)] := Cardinal(AValue mod BigBase);
    AValue := AValue div BigBase;
  end;
end;

procedure BigMulSmall(var ANumber: TBigNumber; AFactor: Cardinal);
var
  I: Integer;
  LCarry, LValue: UInt64;
begin
  LCarry := 0;
  for I := 0 to High(ANumber) do
  begin
    LValue := UInt64(ANumber[I]) * AFactor + LCarry;
    ANumber[I] := Cardinal(LValue mod BigBase);
    LCarry := LValue div BigBase;
  end;
  while LCarry > 0 do
  begin
    SetLength(ANumber, Length(ANumber) + 1);
    ANumber[High(ANumber)] := Cardinal(LCarry mod BigBase);
    LCarry := LCarry div BigBase;
  end;
end;

function BigToDecimal(const ANumber: TBigNumber): string;
var
  I: Integer;
begin
  if Length(ANumber) = 0 then
    Exit('0');
  Result := IntToStr(ANumber[High(ANumber)]);
  for I := High(ANumber) - 1 downto 0 do
    Result := Result + Format('%.9d', [ANumber[I]]);
end;

// The exact decimal digits of a finite positive double: value = D[1].D[2]D[3]... * 10^X
procedure ExactDigits(AValue: Double; out ADigits: string; out AExponent10: Integer);
var
  LBits: UInt64;
  LFraction: UInt64;
  LBiased, LExp2, K: Integer;
  LNumber: TBigNumber;
begin
  LBits := PUInt64(@AValue)^;
  LBiased := Integer((LBits shr 52) and $7FF);
  LFraction := LBits and $000FFFFFFFFFFFFF;
  if LBiased = 0 then
    LExp2 := -1074
  else
  begin
    LFraction := LFraction or (UInt64(1) shl 52);
    LExp2 := LBiased - 1075;
  end;
  BigFromUInt64(LFraction, LNumber);
  if LExp2 >= 0 then
  begin
    K := LExp2;
    while K > 0 do
    begin
      if K >= 29 then
      begin
        BigMulSmall(LNumber, Cardinal(1) shl 29);
        Dec(K, 29);
      end
      else
      begin
        BigMulSmall(LNumber, Cardinal(1) shl K);
        K := 0;
      end;
    end;
    ADigits := BigToDecimal(LNumber);
    AExponent10 := Length(ADigits) - 1;
  end
  else
  begin
    K := -LExp2;
    // value = m * 5^k / 10^k
    while K > 0 do
    begin
      if K >= 13 then
      begin
        BigMulSmall(LNumber, 1220703125); // 5^13
        Dec(K, 13);
      end
      else
      begin
        case K of
          1: BigMulSmall(LNumber, 5);
          2: BigMulSmall(LNumber, 25);
          3: BigMulSmall(LNumber, 125);
          4: BigMulSmall(LNumber, 625);
          5: BigMulSmall(LNumber, 3125);
          6: BigMulSmall(LNumber, 15625);
          7: BigMulSmall(LNumber, 78125);
          8: BigMulSmall(LNumber, 390625);
          9: BigMulSmall(LNumber, 1953125);
          10: BigMulSmall(LNumber, 9765625);
          11: BigMulSmall(LNumber, 48828125);
          12: BigMulSmall(LNumber, 244140625);
        end;
        K := 0;
      end;
    end;
    ADigits := BigToDecimal(LNumber);
    AExponent10 := Length(ADigits) - 1 + LExp2;
  end;
end;

{ TYamlConvert }

class function TYamlConvert.IsSpace(AChar: AnsiChar): Boolean;
begin
  Result := (AChar = ' ') or ((AChar >= #9) and (AChar <= #13));
end;

class function TYamlConvert.ExtractInteger(const AText: TYamlText; ASigned: Boolean; AMaxMagnitude,
  AMaxNegMagnitude: UInt64; out ANegative: Boolean; out AMagnitude: UInt64): Boolean;
var
  LPos, LBase, LDigit, LDigits: Integer;
  LFoundZero, LOverflow: Boolean;
  LLimit: UInt64;
  C: AnsiChar;
begin
  Result := False;
  ANegative := False;
  AMagnitude := 0;
  LPos := 1;
  if Length(AText) = 0 then
    Exit;
  if (AText[1] = '-') or (AText[1] = '+') then
  begin
    ANegative := AText[1] = '-';
    Inc(LPos);
  end;
  if ANegative and ASigned then
    LLimit := AMaxNegMagnitude
  else
    LLimit := AMaxMagnitude;
  LBase := 10;
  LFoundZero := False;
  if (LPos <= Length(AText)) and (AText[LPos] = '0') then
  begin
    LFoundZero := True;
    Inc(LPos);
    if (LPos <= Length(AText)) and ((AText[LPos] = 'x') or (AText[LPos] = 'X')) then
    begin
      LBase := 16;
      LFoundZero := False;
      Inc(LPos);
    end
    else
      LBase := 8;
  end;
  LDigits := 0;
  LOverflow := False;
  while LPos <= Length(AText) do
  begin
    C := AText[LPos];
    if (C >= '0') and (C <= '9') then
      LDigit := Ord(C) - Ord('0')
    else if (LBase = 16) and (C >= 'a') and (C <= 'f') then
      LDigit := Ord(C) - Ord('a') + 10
    else if (LBase = 16) and (C >= 'A') and (C <= 'F') then
      LDigit := Ord(C) - Ord('A') + 10
    else
      Break;
    if LDigit >= LBase then
      Break;
    Inc(LDigits);
    if not LOverflow then
    begin
      if AMagnitude > (LLimit - UInt64(LDigit)) div UInt64(LBase) then
        LOverflow := True
      else
        AMagnitude := AMagnitude * UInt64(LBase) + UInt64(LDigit);
    end;
    Inc(LPos);
  end;
  if (not LFoundZero) and (LDigits = 0) then
    Exit;
  if LOverflow then
    Exit;
  // (stream >> std::ws).eof()
  while LPos <= Length(AText) do
  begin
    if not IsSpace(AText[LPos]) then
      Exit;
    Inc(LPos);
  end;
  Result := True;
end;

class function TYamlConvert.TryInt64(const AText: TYamlText; out AValue: Int64): Boolean;
var
  LNegative: Boolean;
  LMagnitude: UInt64;
begin
  AValue := 0;
  Result := ExtractInteger(AText, True, UInt64(High(Int64)), UInt64(High(Int64)) + 1, LNegative, LMagnitude);
  if Result then
  begin
    if LNegative then
      AValue := Int64(0 - LMagnitude)
    else
      AValue := Int64(LMagnitude);
  end;
end;

class function TYamlConvert.TryUInt64(const AText: TYamlText; out AValue: UInt64): Boolean;
var
  LNegative: Boolean;
  LMagnitude: UInt64;
begin
  AValue := 0;
  if (Length(AText) > 0) and (AText[1] = '-') then
    Exit(False);
  Result := ExtractInteger(AText, False, High(UInt64), High(UInt64), LNegative, LMagnitude);
  if Result then
    AValue := LMagnitude;
end;

class function TYamlConvert.TryInt32(const AText: TYamlText; out AValue: Integer): Boolean;
var
  LValue: Int64;
  LNegative: Boolean;
  LMagnitude: UInt64;
begin
  AValue := 0;
  Result := ExtractInteger(AText, True, High(Integer), UInt64(High(Integer)) + 1, LNegative, LMagnitude);
  if Result then
  begin
    LValue := Int64(LMagnitude);
    if LNegative then
      LValue := -LValue;
    AValue := Integer(LValue);
  end;
end;

class function TYamlConvert.TryUInt32(const AText: TYamlText; out AValue: Cardinal): Boolean;
var
  LNegative: Boolean;
  LMagnitude: UInt64;
begin
  AValue := 0;
  if (Length(AText) > 0) and (AText[1] = '-') then
    Exit(False);
  Result := ExtractInteger(AText, False, High(Cardinal), High(Cardinal), LNegative, LMagnitude);
  if Result then
    AValue := Cardinal(LMagnitude);
end;

class function TYamlConvert.TryInt16(const AText: TYamlText; out AValue: SmallInt): Boolean;
var
  LValue: Int64;
  LNegative: Boolean;
  LMagnitude: UInt64;
begin
  AValue := 0;
  Result := ExtractInteger(AText, True, High(SmallInt), UInt64(High(SmallInt)) + 1, LNegative, LMagnitude);
  if Result then
  begin
    LValue := Int64(LMagnitude);
    if LNegative then
      LValue := -LValue;
    AValue := SmallInt(LValue);
  end;
end;

class function TYamlConvert.TryUInt16(const AText: TYamlText; out AValue: Word): Boolean;
var
  LNegative: Boolean;
  LMagnitude: UInt64;
begin
  AValue := 0;
  if (Length(AText) > 0) and (AText[1] = '-') then
    Exit(False);
  Result := ExtractInteger(AText, False, High(Word), High(Word), LNegative, LMagnitude);
  if Result then
    AValue := Word(LMagnitude);
end;

class function TYamlConvert.TryInt8(const AText: TYamlText; out AValue: ShortInt): Boolean;
var
  LValue: Int64;
  LNegative: Boolean;
  LMagnitude: UInt64;
begin
  AValue := 0;
  Result := ExtractInteger(AText, True, High(ShortInt), UInt64(High(ShortInt)) + 1, LNegative, LMagnitude);
  if Result then
  begin
    LValue := Int64(LMagnitude);
    if LNegative then
      LValue := -LValue;
    AValue := ShortInt(LValue);
  end;
end;

class function TYamlConvert.TryUInt8(const AText: TYamlText; out AValue: Byte): Boolean;
var
  LNegative: Boolean;
  LMagnitude: UInt64;
begin
  AValue := 0;
  if (Length(AText) > 0) and (AText[1] = '-') then
    Exit(False);
  Result := ExtractInteger(AText, False, High(Byte), High(Byte), LNegative, LMagnitude);
  if Result then
    AValue := Byte(LMagnitude);
end;

class function TYamlConvert.TryChar(const AText: TYamlText; out AValue: AnsiChar): Boolean;
var
  I: Integer;
begin
  AValue := #0;
  if Length(AText) = 0 then
    Exit(False);
  for I := 2 to Length(AText) do
    if not IsSpace(AText[I]) then
      Exit(False);
  AValue := AText[1];
  Result := True;
end;

class function TYamlConvert.ExtractFloat(const AText: TYamlText; out AValue: Double): Boolean;
var
  LPos, LStart, LEnd: Integer;
  LHasDigits, LHasDot, LHasExp, LExpDigits: Boolean;
  LToken, LSign, LExpPart, LIntPart, LFracPart: string;
  I: Integer;
  C: AnsiChar;
  LFormat: TFormatSettings;
begin
  AValue := 0;
  Result := False;
  LPos := 1;
  LStart := 1;
  if (LPos <= Length(AText)) and ((AText[LPos] = '+') or (AText[LPos] = '-')) then
    Inc(LPos);
  LHasDigits := False;
  LHasDot := False;
  LHasExp := False;
  LExpDigits := False;
  while LPos <= Length(AText) do
  begin
    C := AText[LPos];
    if (C >= '0') and (C <= '9') then
    begin
      if LHasExp then
        LExpDigits := True
      else
        LHasDigits := True;
      Inc(LPos);
    end
    else if (C = '.') and (not LHasDot) and (not LHasExp) then
    begin
      LHasDot := True;
      Inc(LPos);
    end
    else if ((C = 'e') or (C = 'E')) and LHasDigits and (not LHasExp) then
    begin
      LHasExp := True;
      Inc(LPos);
      if (LPos <= Length(AText)) and ((AText[LPos] = '+') or (AText[LPos] = '-')) then
        Inc(LPos);
    end
    else
      Break;
  end;
  LEnd := LPos;
  // strtod must consume the whole token
  if not LHasDigits then
  begin
    // ".5" has digits after the dot; the flag above counts only digits before the exponent
    Exit;
  end;
  if LHasExp and (not LExpDigits) then
    Exit;
  // trailing spaces only
  while LPos <= Length(AText) do
  begin
    if not IsSpace(AText[LPos]) then
      Exit;
    Inc(LPos);
  end;
  LFormat := TFormatSettings.Invariant;
  LToken := string(Copy(AText, LStart, LEnd - LStart));
  // normalise to sign, digits, dot, digits, exponent (Delphi does not take "5." or ".5" everywhere)
  begin
    LSign := '';
    if (LToken <> '') and ((LToken[1] = '+') or (LToken[1] = '-')) then
    begin
      if LToken[1] = '-' then
        LSign := '-';
      Delete(LToken, 1, 1);
    end;
    LExpPart := '';
    I := Pos('e', LowerCase(LToken));
    if I > 0 then
    begin
      LExpPart := Copy(LToken, I, MaxInt);
      LToken := Copy(LToken, 1, I - 1);
    end;
    I := Pos('.', LToken);
    if I > 0 then
    begin
      LIntPart := Copy(LToken, 1, I - 1);
      LFracPart := Copy(LToken, I + 1, MaxInt);
    end
    else
    begin
      LIntPart := LToken;
      LFracPart := '';
    end;
    if LIntPart = '' then
      LIntPart := '0';
    if LFracPart = '' then
      LFracPart := '0';
    LToken := LSign + LIntPart + '.' + LFracPart + LExpPart;
  end;
  if not TryStrToFloat(LToken, AValue, LFormat) then
  begin
    // too big
    AValue := 0;
    Exit;
  end;
  if IsInfinite(AValue) then
    Exit(False);
  Result := True;
end;

class function TYamlConvert.TryDouble(const AText: TYamlText; out AValue: Double): Boolean;
begin
  if ExtractFloat(AText, AValue) then
    Exit(True);
  AValue := 0;
  if (AText = '.inf') or (AText = '.Inf') or (AText = '.INF') or (AText = '+.inf') or (AText = '+.Inf') or
    (AText = '+.INF') then
  begin
    AValue := Infinity;
    Exit(True);
  end;
  if (AText = '-.inf') or (AText = '-.Inf') or (AText = '-.INF') then
  begin
    AValue := NegInfinity;
    Exit(True);
  end;
  if (AText = '.nan') or (AText = '.NaN') or (AText = '.NAN') then
  begin
    AValue := NaN;
    Exit(True);
  end;
  Result := False;
end;

class function TYamlConvert.TrySingle(const AText: TYamlText; out AValue: Single): Boolean;
var
  LValue: Double;
begin
  AValue := 0;
  Result := TryDouble(AText, LValue);
  if not Result then
    Exit;
  if IsNan(LValue) or IsInfinite(LValue) then
    AValue := LValue
  else if Abs(LValue) > 3.4028234663852886E+38 then
  begin
    // strtof overflows: failbit
    AValue := 0;
    Result := False;
  end
  else
    AValue := LValue;
end;

class function TYamlConvert.IsFlexibleCase(const AText: TYamlText): Boolean;
var
  I: Integer;
  LAllLower, LRestLower, LRestUpper: Boolean;
begin
  if AText = '' then
    Exit(True);
  LAllLower := True;
  for I := 1 to Length(AText) do
    if not ((AText[I] >= 'a') and (AText[I] <= 'z')) then
      LAllLower := False;
  if LAllLower then
    Exit(True);
  if not ((AText[1] >= 'A') and (AText[1] <= 'Z')) then
    Exit(False);
  LRestLower := True;
  LRestUpper := True;
  for I := 2 to Length(AText) do
  begin
    if not ((AText[I] >= 'a') and (AText[I] <= 'z')) then
      LRestLower := False;
    if not ((AText[I] >= 'A') and (AText[I] <= 'Z')) then
      LRestUpper := False;
  end;
  Result := LRestLower or LRestUpper;
end;

class function TYamlConvert.TryBool(const AText: TYamlText; out AValue: Boolean): Boolean;
const
  TrueNames: array[0..3] of TYamlText = ('y', 'yes', 'true', 'on');
  FalseNames: array[0..3] of TYamlText = ('n', 'no', 'false', 'off');
var
  LLower: TYamlText;
  I: Integer;
begin
  AValue := False;
  if not IsFlexibleCase(AText) then
    Exit(False);
  LLower := AText;
  for I := 1 to Length(LLower) do
    if (LLower[I] >= 'A') and (LLower[I] <= 'Z') then
      LLower[I] := AnsiChar(Ord(LLower[I]) + 32);
  for I := 0 to 3 do
  begin
    if TrueNames[I] = LLower then
    begin
      AValue := True;
      Exit(True);
    end;
    if FalseNames[I] = LLower then
    begin
      AValue := False;
      Exit(True);
    end;
  end;
  Result := False;
end;

class function TYamlConvert.IsNullString(const AText: TYamlText): Boolean;
begin
  Result := (AText = '') or (AText = '~') or (AText = 'null') or (AText = 'Null') or (AText = 'NULL');
end;

class function TYamlConvert.FormatGeneral(AValue: Double; APrecision: Integer): TYamlText;
var
  LDigits, LHead, LTail, LSign, LExpText: string;
  LExp, I, LLength: Integer;
  LAbs: Double;
  LRoundUp, LAllZero: Boolean;
  LBits: UInt64;
  LRest: string;
begin
  if IsNan(AValue) then
    Exit('nan');
  LBits := PUInt64(@AValue)^;
  if (LBits shr 63) <> 0 then
    LSign := '-'
  else
    LSign := '';
  if IsInfinite(AValue) then
    Exit(TYamlText(LSign + 'inf'));
  if APrecision < 1 then
    APrecision := 1;
  LAbs := Abs(AValue);
  if LAbs = 0 then
    Exit(TYamlText(LSign + '0'));
  ExactDigits(LAbs, LDigits, LExp);
  LLength := Length(LDigits);
  if LLength > APrecision then
  begin
    LHead := Copy(LDigits, 1, APrecision);
    LTail := Copy(LDigits, APrecision + 1, MaxInt);
    LAllZero := True;
    for I := 2 to Length(LTail) do
      if LTail[I] <> '0' then
        LAllZero := False;
    if LTail[1] > '5' then
      LRoundUp := True
    else if LTail[1] < '5' then
      LRoundUp := False
    else if not LAllZero then
      LRoundUp := True
    else
      LRoundUp := (Ord(LHead[Length(LHead)]) - Ord('0')) mod 2 = 1;
    if LRoundUp then
    begin
      I := Length(LHead);
      while (I >= 1) and (LHead[I] = '9') do
      begin
        LHead[I] := '0';
        Dec(I);
      end;
      if I >= 1 then
        LHead[I] := Chr(Ord(LHead[I]) + 1)
      else
      begin
        LHead := '1' + Copy(LHead, 1, Length(LHead) - 1);
        Inc(LExp);
      end;
    end;
  end
  else
    LHead := LDigits;
  // remove the trailing zeros
  I := Length(LHead);
  while (I > 1) and (LHead[I] = '0') do
    Dec(I);
  LHead := Copy(LHead, 1, I);
  if (LExp < -4) or (LExp >= APrecision) then
  begin
    LRest := Copy(LHead, 2, MaxInt);
    if LRest <> '' then
      LRest := '.' + LRest;
    if LExp < 0 then
      LExpText := '-'
    else
      LExpText := '+';
    LExpText := LExpText + Format('%.2d', [Abs(LExp)]);
    Result := TYamlText(LSign + LHead[1] + LRest + 'e' + LExpText);
  end
  else if LExp >= 0 then
  begin
    if Length(LHead) <= LExp + 1 then
      Result := TYamlText(LSign + LHead + StringOfChar('0', LExp + 1 - Length(LHead)))
    else
      Result := TYamlText(LSign + Copy(LHead, 1, LExp + 1) + '.' + Copy(LHead, LExp + 2, MaxInt));
  end
  else
    Result := TYamlText(LSign + '0.' + StringOfChar('0', -LExp - 1) + LHead);
end;

class function TYamlConvert.FormatInteger(AValue: UInt64; ANegative: Boolean; ABits: Integer;
  ABase: Integer): TYamlText;
var
  LMasked: UInt64;
  LText: string;
begin
  if ABase = 10 then
  begin
    if ANegative then
      Exit(TYamlText('-' + UIntToStr(0 - AValue)));
    Exit(TYamlText(UIntToStr(AValue)));
  end;
  // the bit pattern of the type
  if ABits < 64 then
    LMasked := AValue and ((UInt64(1) shl ABits) - 1)
  else
    LMasked := AValue;
  if ABase = 16 then
  begin
    LText := LowerCase(IntToHex(LMasked, 1));
    Result := TYamlText('0x' + LText);
  end
  else
  begin
    LText := '';
    if LMasked = 0 then
      LText := '0';
    while LMasked > 0 do
    begin
      LText := Chr(Ord('0') + Integer(LMasked and 7)) + LText;
      LMasked := LMasked shr 3;
    end;
    Result := TYamlText('0' + LText);
  end;
end;

const
  Base64Encoding: AnsiString = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

class function TYamlConvert.EncodeBase64(const AData: TBytes): TYamlText;
var
  I, LChunks, LRemainder: Integer;
  B0, B1, B2: Byte;
  LOut: TYamlText;
begin
  LOut := '';
  LChunks := Length(AData) div 3;
  LRemainder := Length(AData) mod 3;
  for I := 0 to LChunks - 1 do
  begin
    B0 := AData[I * 3];
    B1 := AData[I * 3 + 1];
    B2 := AData[I * 3 + 2];
    LOut := LOut + Base64Encoding[(B0 shr 2) + 1] + Base64Encoding[(((B0 and 3) shl 4) or (B1 shr 4)) + 1] +
      Base64Encoding[(((B1 and $F) shl 2) or (B2 shr 6)) + 1] + Base64Encoding[(B2 and $3F) + 1];
  end;
  if LRemainder = 1 then
  begin
    B0 := AData[LChunks * 3];
    LOut := LOut + Base64Encoding[(B0 shr 2) + 1] + Base64Encoding[((B0 and 3) shl 4) + 1] + '==';
  end
  else if LRemainder = 2 then
  begin
    B0 := AData[LChunks * 3];
    B1 := AData[LChunks * 3 + 1];
    LOut := LOut + Base64Encoding[(B0 shr 2) + 1] + Base64Encoding[(((B0 and 3) shl 4) or (B1 shr 4)) + 1] +
      Base64Encoding[((B1 and $F) shl 2) + 1] + '=';
  end;
  Result := LOut;
end;

class function TYamlConvert.DecodeBase64(const AText: TYamlText): TBytes;
var
  I, LCount, LOut: Integer;
  LValue: Cardinal;
  C: Byte;
  D: Integer;
  LRet: TBytes;
begin
  SetLength(Result, 0);
  if AText = '' then
    Exit;
  SetLength(LRet, 3 * Length(AText) div 4 + 1);
  LOut := 0;
  LValue := 0;
  LCount := 0;
  for I := 1 to Length(AText) do
  begin
    C := Byte(AText[I]);
    if (C = 32) or ((C >= 9) and (C <= 13)) then
      Continue;
    if (C >= Ord('A')) and (C <= Ord('Z')) then
      D := C - Ord('A')
    else if (C >= Ord('a')) and (C <= Ord('z')) then
      D := C - Ord('a') + 26
    else if (C >= Ord('0')) and (C <= Ord('9')) then
      D := C - Ord('0') + 52
    else if C = Ord('+') then
      D := 62
    else if C = Ord('/') then
      D := 63
    else if C = Ord('=') then
      D := 0
    else
      Exit; // 255: invalid
    LValue := (LValue shl 6) or Cardinal(D);
    if LCount mod 4 = 3 then
    begin
      LRet[LOut] := Byte(LValue shr 16);
      Inc(LOut);
      if (I > 1) and (AText[I - 1] <> '=') then
      begin
        LRet[LOut] := Byte(LValue shr 8);
        Inc(LOut);
      end;
      if AText[I] <> '=' then
      begin
        LRet[LOut] := Byte(LValue);
        Inc(LOut);
      end;
    end;
    Inc(LCount);
  end;
  SetLength(LRet, LOut);
  Result := LRet;
end;

end.

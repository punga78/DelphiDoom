{******************************************************************************}
{                                                                              }
{  DelphiDoom: idLib text - TIdToken, a token read by the lexer                }
{                                                                              }
{  Port of idLib (id Software, Doom 3, GPL v3): idlib\Token.h, Token.cpp.      }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.IdLib.Text.Token;

{$Q-}
{$R-}

interface

type
  /// <summary>
  ///   A token read from a script with TIdLexer (idToken). The text of idToken is the idStr base
  ///   class; here it is the field <c>Text</c>. <c>IntValue</c> is the 32-bit "unsigned long" of
  ///   Win32 (it wraps at 2^32 on every platform, so 32 and 64 bit builds agree).
  ///   Not ported: the <c>next</c> chain used only by idParser.
  /// </summary>
  TIdToken = record
  private
    FIntValue: Cardinal;
    FFloatValue: Double;
  public
    /// <summary>The characters of the token</summary>
    Text: AnsiString;
    /// <summary>TT_STRING, TT_LITERAL, TT_NUMBER, TT_NAME or TT_PUNCTUATION</summary>
    TokenType: Integer;
    /// <summary>Sub type: string/name length, literal code, number flags, punctuation id</summary>
    SubType: Integer;
    /// <summary>The line of the script the token was on</summary>
    Line: Integer;
    /// <summary>The number of lines crossed in the white space before the token</summary>
    LinesCrossed: Integer;
    /// <summary>Token flags (used by the parser for recursive defines)</summary>
    Flags: Integer;
    /// <summary>Offset in the script buffer of the start of the white space before the token, -1 if unset</summary>
    WhiteSpaceStart: Integer;
    /// <summary>Offset in the script buffer of the end of the white space before the token, -1 if unset</summary>
    WhiteSpaceEnd: Integer;
    /// <summary>A cleared token (idToken constructor: the original leaves the numeric fields undefined)</summary>
    class function Create: TIdToken; static;
    /// <summary>idToken == "text" (idStr::Cmp)</summary>
    function IsText(const AText: AnsiString): Boolean;
    /// <summary>Double value of a TT_NUMBER token, 0 for the other types</summary>
    function GetDoubleValue: Double;
    function GetFloatValue: Single;
    function GetUnsignedLongValue: Cardinal;
    function GetIntValue: Integer;
    /// <summary>The length of the white space before the token is greater than zero</summary>
    function WhiteSpaceBeforeToken: Boolean;
    procedure ClearTokenWhiteSpace;
    /// <summary>Calculates IntValue and FloatValue of a TT_NUMBER token</summary>
    procedure NumberValue;
    /// <summary>Sets the integer and float values (the lexer clears them when it starts a number)</summary>
    procedure ClearValues;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Strings, DelphiDoom.IdLib.Text.Types;

const
  // a typed constant: a literal 0.1 of Delphi is an Extended, the original multiplies by the double 0.1
  DECIMAL_STEP: Double = 0.1;

// idMath::Ftol: (unsigned long) of the float the double is converted to. The conversion of a value that does
// not fit is undefined in C++; this is what the 32-bit clang (the compiler of the goldens) does: below 2^31 the
// truncated value (a negative one as two's complement), from 2^31 to 2^32 the value, from 2^32 on zero
// (an out of range double is an infinite float: positive infinity gives zero, negative gives $80000000)
function FloatToUnsignedLong(const AValue: Double): Cardinal;
var
  LFloat: Single;
  LRest: Single;
begin
  if AValue <> AValue then
    Exit($80000000);
  if AValue >= 3.4E38 then
    Exit(0);
  if AValue <= -3.4E38 then
    Exit($80000000);
  LFloat := AValue;
  if LFloat < 2147483648.0 then
  begin
    if LFloat < -2147483648.0 then
      Exit($80000000);
    Exit(Cardinal(Trunc(LFloat)));
  end;
  LRest := LFloat - 2147483648.0;
  if LRest >= 2147483648.0 then
    Exit(0);
  Result := Cardinal(Trunc(LRest)) xor $80000000;
end;

{ TIdToken }

class function TIdToken.Create: TIdToken;
begin
  Result.Text := '';
  Result.TokenType := 0;
  Result.SubType := 0;
  Result.Line := 0;
  Result.LinesCrossed := 0;
  Result.Flags := 0;
  Result.WhiteSpaceStart := -1;
  Result.WhiteSpaceEnd := -1;
  Result.FIntValue := 0;
  Result.FFloatValue := 0;
end;

function TIdToken.IsText(const AText: AnsiString): Boolean;
begin
  Result := TIdStrings.Cmp(Text, AText) = 0;
end;

procedure TIdToken.ClearValues;
begin
  FIntValue := 0;
  FFloatValue := 0;
end;

function TIdToken.GetDoubleValue: Double;
begin
  if TokenType <> TT_NUMBER then
    Exit(0.0);
  if (SubType and TT_VALUESVALID) = 0 then
    NumberValue;
  Result := FFloatValue;
end;

function TIdToken.GetFloatValue: Single;
begin
  Result := GetDoubleValue;
end;

function TIdToken.GetUnsignedLongValue: Cardinal;
begin
  if TokenType <> TT_NUMBER then
    Exit(0);
  if (SubType and TT_VALUESVALID) = 0 then
    NumberValue;
  Result := FIntValue;
end;

function TIdToken.GetIntValue: Integer;
begin
  Result := Integer(GetUnsignedLongValue);
end;

function TIdToken.WhiteSpaceBeforeToken: Boolean;
begin
  Result := WhiteSpaceEnd > WhiteSpaceStart;
end;

procedure TIdToken.ClearTokenWhiteSpace;
begin
  WhiteSpaceStart := -1;
  WhiteSpaceEnd := -1;
  LinesCrossed := 0;
end;

procedure TIdToken.NumberValue;
var
  LPosition, LPower, LIndex, LChar: Integer;
  LMultiplier: Double;
  LDivide: Boolean;
  LBits: Cardinal;

  function Ch(const AOffset: Integer): Integer;
  begin
    // a char of the original is signed; past the end it is the terminator
    Result := TIdStrings.CharAt(Text, AOffset);
  end;

begin
  LPosition := 0;
  FFloatValue := 0;
  FIntValue := 0;
  if (SubType and TT_FLOAT) <> 0 then
  begin
    if (SubType and (TT_INFINITE or TT_INDEFINITE or TT_NAN)) <> 0 then
    begin
      if (SubType and TT_INFINITE) <> 0 then
        LBits := $7F800000
      else if (SubType and TT_INDEFINITE) <> 0 then
        LBits := $FFC00000
      else
        LBits := $7FC00000;
      FFloatValue := PSingle(@LBits)^;
    end
    else
    begin
      while (Ch(LPosition) <> 0) and (Ch(LPosition) <> Ord('.')) and (Ch(LPosition) <> Ord('e')) do
      begin
        FFloatValue := FFloatValue * 10.0 + (Ch(LPosition) - Ord('0'));
        Inc(LPosition);
      end;
      if Ch(LPosition) = Ord('.') then
      begin
        Inc(LPosition);
        LMultiplier := DECIMAL_STEP;
        while (Ch(LPosition) <> 0) and (Ch(LPosition) <> Ord('e')) do
        begin
          FFloatValue := FFloatValue + (Ch(LPosition) - Ord('0')) * LMultiplier;
          LMultiplier := LMultiplier * DECIMAL_STEP;
          Inc(LPosition);
        end;
      end;
      if Ch(LPosition) = Ord('e') then
      begin
        Inc(LPosition);
        if Ch(LPosition) = Ord('-') then
        begin
          LDivide := True;
          Inc(LPosition);
        end
        else if Ch(LPosition) = Ord('+') then
        begin
          LDivide := False;
          Inc(LPosition);
        end
        else
          LDivide := False;
        LPower := 0;
        while Ch(LPosition) <> 0 do
        begin
          LPower := LPower * 10 + (Ch(LPosition) - Ord('0'));
          Inc(LPosition);
        end;
        LMultiplier := 1.0;
        for LIndex := 0 to LPower - 1 do
          LMultiplier := LMultiplier * 10.0;
        if LDivide then
          FFloatValue := FFloatValue / LMultiplier
        else
          FFloatValue := FFloatValue * LMultiplier;
      end;
    end;
    FIntValue := FloatToUnsignedLong(FFloatValue);
  end
  else if (SubType and TT_DECIMAL) <> 0 then
  begin
    while Ch(LPosition) <> 0 do
    begin
      FIntValue := FIntValue * 10 + Cardinal(Ch(LPosition) - Ord('0'));
      Inc(LPosition);
    end;
    FFloatValue := FIntValue;
  end
  else if (SubType and TT_IPADDRESS) <> 0 then
  begin
    LChar := 0;
    while (Ch(LPosition) <> 0) and (Ch(LPosition) <> Ord(':')) do
    begin
      if Ch(LPosition) = Ord('.') then
      begin
        while LChar <> 3 do
        begin
          FIntValue := FIntValue * 10;
          Inc(LChar);
        end;
        LChar := 0;
      end
      else
      begin
        FIntValue := FIntValue * 10 + Cardinal(Ch(LPosition) - Ord('0'));
        Inc(LChar);
      end;
      Inc(LPosition);
    end;
    while LChar <> 3 do
    begin
      FIntValue := FIntValue * 10;
      Inc(LChar);
    end;
    FFloatValue := FIntValue;
  end
  else if (SubType and TT_OCTAL) <> 0 then
  begin
    // step over the first zero
    Inc(LPosition);
    while Ch(LPosition) <> 0 do
    begin
      FIntValue := (FIntValue shl 3) + Cardinal(Ch(LPosition) - Ord('0'));
      Inc(LPosition);
    end;
    FFloatValue := FIntValue;
  end
  else if (SubType and TT_HEX) <> 0 then
  begin
    // step over the leading 0x or 0X
    Inc(LPosition, 2);
    while Ch(LPosition) <> 0 do
    begin
      FIntValue := FIntValue shl 4;
      if (Ch(LPosition) >= Ord('a')) and (Ch(LPosition) <= Ord('f')) then
        FIntValue := FIntValue + Cardinal(Ch(LPosition) - Ord('a') + 10)
      else if (Ch(LPosition) >= Ord('A')) and (Ch(LPosition) <= Ord('F')) then
        FIntValue := FIntValue + Cardinal(Ch(LPosition) - Ord('A') + 10)
      else
        FIntValue := FIntValue + Cardinal(Ch(LPosition) - Ord('0'));
      Inc(LPosition);
    end;
    FFloatValue := FIntValue;
  end
  else if (SubType and TT_BINARY) <> 0 then
  begin
    // step over the leading 0b or 0B
    Inc(LPosition, 2);
    while Ch(LPosition) <> 0 do
    begin
      FIntValue := (FIntValue shl 1) + Cardinal(Ch(LPosition) - Ord('0'));
      Inc(LPosition);
    end;
    FFloatValue := FIntValue;
  end;
  SubType := SubType or TT_VALUESVALID;
end;

end.

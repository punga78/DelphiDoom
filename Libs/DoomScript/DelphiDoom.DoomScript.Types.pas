{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom script (id Tech 4) - shared types, limits and exceptions   }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): game\script\             }
{  Script_Program.h, Script_Compiler.h, Script_Interpreter.h and               }
{  game\gamesys\Event.h. Copyright (C) 1999-2011 id Software LLC, a ZeniMax    }
{  Media company.                                                              }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3 or later, with    }
{  the additional terms of the Doom 3 Source Code License (see README.md of    }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.DoomScript.Types;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.IdLib.Core.Exceptions, DelphiDoom.IdLib.Math.Vec3;

const
  /// <summary>MAX_STRING_LEN: the bytes of a script string, terminator included</summary>
  DS_MAX_STRING_LEN = 128;
  /// <summary>MAX_GLOBALS: the bytes of the global variables</summary>
  DS_MAX_GLOBALS = 196608;
  DS_MAX_FUNCS = 3072;
  DS_MAX_STATEMENTS = 81920;
  /// <summary>MAX_STACK_DEPTH of the interpreter</summary>
  DS_MAX_STACK_DEPTH = 64;
  /// <summary>LOCALSTACK_SIZE of the interpreter, in bytes</summary>
  DS_LOCALSTACK_SIZE = 6144;
  /// <summary>The statements one <c>Execute</c> may run before "runaway loop error"</summary>
  DS_RUNAWAY_LIMIT = 5000000;
  DS_EVENT_MAXARGS = 8;
  DS_MAX_EVENTS = 4096;
  DS_MAX_EVENTSPERFRAME = 4096;
  DS_MAX_GENTITIES = 4096;
  DS_ENTITYNUM_NONE = DS_MAX_GENTITIES - 1;
  /// <summary>NUM_SIGNALS of Entity.h</summary>
  DS_NUM_SIGNALS = 10;
  DS_MAX_GLOBAL_SHADER_PARMS = 12;
  DS_USERCMD_HZ = 60;
  /// <summary>The largest script object: the offset of a field must fit in a pointer handle</summary>
  DS_MAX_OBJECT_SIZE = 1 shl 18;

  DS_RESULT_STRING: AnsiString = '<RESULT>';
  DS_DEFAULT_DEFS: AnsiString = 'script/doom_defs.script';

  // the characters of the argument format of an event (D_EVENT_*)
  DS_EVENT_VOID = #0;
  DS_EVENT_INTEGER = 'd';
  DS_EVENT_FLOAT = 'f';
  DS_EVENT_VECTOR = 'v';
  DS_EVENT_STRING = 's';
  DS_EVENT_ENTITY = 'e';
  DS_EVENT_ENTITY_NULL = 'E';
  DS_EVENT_TRACE = 't';

type
  /// <summary>etype_t: the basic kind of a script type</summary>
  TDoomScriptEType = (evError = -1, evVoid, evScriptEvent, evNamespace, evString, evFloat, evVector, evEntity,
    evField, evFunction, evVirtualFunction, evPointer, evObject, evJumpOffset, evArgSize, evBoolean);

  /// <summary>idVarDef::initialized_t</summary>
  TDoomScriptInitialized = (diUninitialized, diInitializedVariable, diInitializedConstant, diStackVariable);

  /// <summary>eval_t: an immediate value of the compiler (the text of a string travels beside it)</summary>
  TDoomScriptEval = record
    case Integer of
      0: (IntValue: Integer);
      1: (FloatValue: Single);
      2: (Vector: array[0..2] of Single);
      3: (Entity: Integer);
  end;

  /// <summary>One argument of an event; an entity is its number, -1 for none</summary>
  TDoomScriptEventArg = record
    Kind: AnsiChar;
    IntValue: Integer;
    FloatValue: Single;
    VectorValue: TIdVec3;
    StringValue: AnsiString;
  end;

  TDoomScriptEventArgs = array[0..DS_EVENT_MAXARGS - 1] of TDoomScriptEventArg;

  /// <summary>Base of the errors of the Doom script library</summary>
  EDoomScriptException = class(EIdLibException);

  /// <summary>idCompileError: the text is the message the original printed, with file and line</summary>
  EDoomScriptCompileError = class(EDoomScriptException);

  /// <summary><c>gameLocal.Error</c> / <c>common->Error</c> of the script system (run time)</summary>
  EDoomScriptError = class(EDoomScriptException);

  /// <summary>
  ///   An access outside the memory of the virtual machine (globals, local stack, object data, tables):
  ///   what was undefined behaviour in the original
  /// </summary>
  EDoomScriptMemoryError = class(EDoomScriptError);

  /// <summary>Conversions with the rules of the C++ of the original</summary>
  TDoomScriptConvert = record
  public
    /// <summary><c>(int)value</c> of the x86: truncation, 0x80000000 when it does not fit or is not a number</summary>
    class function FloatToInt(const AValue: Single): Integer; static;
    /// <summary>idInterpreter::FloatToString: "%d" for a whole value, "%f" otherwise</summary>
    class function FloatToString(const AValue: Single): AnsiString; static;
    /// <summary>
    ///   "%f" of C. A value too large for the exact scaling of TIdStrings.FormatFixed (9e12 and more: a whole
    ///   number) is written with its exact digits rounded to FIXED_SIGNIFICANT_DIGITS significant digits and
    ///   zeros after them, as the C runtime of the parity harness does (the runtime of the game stopped at 17).
    /// </summary>
    class function FloatToFixed(const AValue: Single): AnsiString; static;
    /// <summary>
    ///   idVec3::ToString: the three components with "%.2f", without the zeros at the end, separated by a blank;
    ///   a huge component as <c>FloatToFixed</c> writes it
    /// </summary>
    class function VectorToString(const AValue: TIdVec3): AnsiString; static;
    /// <summary>SEC2MS: idMath::FtoiFast( t * 1000 ), the x87 rounding to nearest even</summary>
    class function SecToMs(const ASeconds: Single): Integer; static;
    /// <summary><c>a == b</c> of C: false when either is not a number (Delphi would say true)</summary>
    class function FloatEq(const AFirst, ASecond: Single): Boolean; static; inline;
    /// <summary><c>a &lt; b</c> of C: false when either is not a number</summary>
    class function FloatLt(const AFirst, ASecond: Single): Boolean; static; inline;
    /// <summary><c>a &lt;= b</c> of C: false when either is not a number</summary>
    class function FloatLe(const AFirst, ASecond: Single): Boolean; static; inline;
    /// <summary><c>a != 0</c> of C: true for a NaN</summary>
    class function FloatNonZero(const AValue: Single): Boolean; static; inline;
    class function EntityArg(const ANumber: Integer): TDoomScriptEventArg; static;
    class function IntArg(const AValue: Integer): TDoomScriptEventArg; static;
    class function FloatArg(const AValue: Single): TDoomScriptEventArg; static;
    class function StringArg(const AValue: AnsiString): TDoomScriptEventArg; static;
    class function VectorArg(const AValue: TIdVec3): TDoomScriptEventArg; static;
  end;

  /// <summary>The strings of the virtual machine: 128 bytes, zero terminated, in the memory of the machine</summary>
  TDoomScriptMemory = record
  public
    /// <summary>idStr::Copynz into a 128 byte cell: at most 127 characters, the rest filled with zeros</summary>
    class procedure CopyString(const ADest: PByte; const AText: AnsiString;
      const ASize: Integer = DS_MAX_STRING_LEN); static;
    /// <summary>The text of a cell up to its terminator (at most <c>ASize</c> - 1 characters)</summary>
    class function ReadString(const ASource: PByte; const ASize: Integer = DS_MAX_STRING_LEN): AnsiString; static;
    /// <summary>idStr::Append into a 128 byte cell</summary>
    class procedure AppendString(const ADest: PByte; const AText: AnsiString); static;
  end;

implementation

uses
  System.Math, DelphiDoom.IdLib.Text.Strings;

class function TDoomScriptConvert.FloatToInt(const AValue: Single): Integer;
begin
  if IsNan(AValue) or (AValue >= 2147483648.0) or (AValue <= -2147483904.0) then
    Result := Low(Integer)
  else
    Result := Trunc(AValue);
end;

function IsNanBits(const AValue: Single): Boolean; inline;
begin
  Result := (PCardinal(@AValue)^ and $7FFFFFFF) > $7F800000;
end;

class function TDoomScriptConvert.FloatEq(const AFirst, ASecond: Single): Boolean;
begin
  Result := (not IsNanBits(AFirst)) and (not IsNanBits(ASecond)) and (AFirst = ASecond);
end;

class function TDoomScriptConvert.FloatLt(const AFirst, ASecond: Single): Boolean;
begin
  Result := (not IsNanBits(AFirst)) and (not IsNanBits(ASecond)) and (AFirst < ASecond);
end;

class function TDoomScriptConvert.FloatLe(const AFirst, ASecond: Single): Boolean;
begin
  Result := (not IsNanBits(AFirst)) and (not IsNanBits(ASecond)) and (AFirst <= ASecond);
end;

class function TDoomScriptConvert.FloatNonZero(const AValue: Single): Boolean;
begin
  Result := (PCardinal(@AValue)^ and $7FFFFFFF) <> 0;
end;

class function TDoomScriptConvert.FloatToString(const AValue: Single): AnsiString;
var
  LInt: Integer;
  LBack: Single;
begin
  LInt := FloatToInt(AValue);
  LBack := LInt;
  if AValue = LBack then
    Result := AnsiString(IntToStr(LInt))
  else
    Result := FloatToFixed(AValue);
end;

const
  FIXED_SIGNIFICANT_DIGITS = 20;
  EXACT_LIMIT = 9.0E12;

class function TDoomScriptConvert.VectorToString(const AValue: TIdVec3): AnsiString;
var
  LIndex: Integer;
  LPart: AnsiString;
  LValue: Single;
begin
  Result := '';
  for LIndex := 0 to 2 do
  begin
    LValue := AValue[LIndex];
    if (((PCardinal(@LValue)^ shr 23) and $FF) = $FF) or (Abs(LValue) < EXACT_LIMIT) then
      LPart := TIdStrings.FloatArrayToString([LValue], 2)
    else
    begin
      // a whole number: "%.2f" and the zeros taken away leave the digits
      LPart := FloatToFixed(LValue);
      SetLength(LPart, Pos(AnsiChar('.'), LPart) - 1);
    end;
    if LIndex > 0 then
      Result := Result + ' ';
    Result := Result + LPart;
  end;
end;

class function TDoomScriptConvert.FloatToFixed(const AValue: Single): AnsiString;
var
  LBits: Cardinal;
  LExponent: Integer;
  LDigits: AnsiString;
  LIndex: Integer;
  LCarry: Integer;
  LDigit: Integer;
  LShift: Integer;
begin
  LBits := PCardinal(@AValue)^;
  LExponent := Integer((LBits shr 23) and $FF);
  if (LExponent = $FF) or (Abs(AValue) < EXACT_LIMIT) then
    Exit(TIdStrings.FloatToPlainText(AValue));
  // a whole number: the 24 bits of the mantissa times a power of two, in decimal digits
  LDigits := AnsiString(IntToStr((LBits and $7FFFFF) or $800000));
  for LShift := 1 to LExponent - 150 do
  begin
    LCarry := 0;
    for LIndex := Length(LDigits) downto 1 do
    begin
      LDigit := (Ord(LDigits[LIndex]) - Ord('0')) * 2 + LCarry;
      LDigits[LIndex] := AnsiChar(Ord('0') + LDigit mod 10);
      LCarry := LDigit div 10;
    end;
    if LCarry > 0 then
      LDigits := AnsiChar(Ord('0') + LCarry) + LDigits;
  end;
  if Length(LDigits) > FIXED_SIGNIFICANT_DIGITS then
  begin
    LCarry := Ord(LDigits[FIXED_SIGNIFICANT_DIGITS + 1] >= '5');
    for LIndex := FIXED_SIGNIFICANT_DIGITS + 1 to Length(LDigits) do
      LDigits[LIndex] := '0';
    LIndex := FIXED_SIGNIFICANT_DIGITS;
    while (LCarry > 0) and (LIndex >= 1) do
    begin
      if LDigits[LIndex] = '9' then
        LDigits[LIndex] := '0'
      else
      begin
        Inc(LDigits[LIndex]);
        LCarry := 0;
      end;
      Dec(LIndex);
    end;
    if LCarry > 0 then
      LDigits := '1' + LDigits;
  end;
  Result := LDigits + '.000000';
  if (LBits and $80000000) <> 0 then
    Result := '-' + Result;
end;

class function TDoomScriptConvert.SecToMs(const ASeconds: Single): Integer;
var
  LScaled: Double;
  LSaved: TRoundingMode;
begin
  LScaled := ASeconds * 1000.0;
  if IsNan(LScaled) or (LScaled >= 2147483648.0) or (LScaled < -2147483648.0) then
    Exit(Low(Integer));
  LSaved := GetRoundMode;
  SetRoundMode(rmNearest);
  try
    Result := Round(LScaled);
  finally
    SetRoundMode(LSaved);
  end;
end;

class function TDoomScriptConvert.EntityArg(const ANumber: Integer): TDoomScriptEventArg;
begin
  Result := Default(TDoomScriptEventArg);
  Result.Kind := DS_EVENT_ENTITY;
  Result.IntValue := ANumber;
end;

class function TDoomScriptConvert.IntArg(const AValue: Integer): TDoomScriptEventArg;
begin
  Result := Default(TDoomScriptEventArg);
  Result.Kind := DS_EVENT_INTEGER;
  Result.IntValue := AValue;
end;

class function TDoomScriptConvert.FloatArg(const AValue: Single): TDoomScriptEventArg;
begin
  Result := Default(TDoomScriptEventArg);
  Result.Kind := DS_EVENT_FLOAT;
  Result.FloatValue := AValue;
end;

class function TDoomScriptConvert.StringArg(const AValue: AnsiString): TDoomScriptEventArg;
begin
  Result := Default(TDoomScriptEventArg);
  Result.Kind := DS_EVENT_STRING;
  Result.StringValue := AValue;
end;

class function TDoomScriptConvert.VectorArg(const AValue: TIdVec3): TDoomScriptEventArg;
begin
  Result := Default(TDoomScriptEventArg);
  Result.Kind := DS_EVENT_VECTOR;
  Result.VectorValue := AValue;
end;

class procedure TDoomScriptMemory.CopyString(const ADest: PByte; const AText: AnsiString; const ASize: Integer);
var
  LLength: Integer;
  LZero: Integer;
begin
  if ASize <= 0 then
    Exit;
  LLength := Length(AText);
  // the text ends at its first zero, as a C string does
  LZero := Pos(AnsiChar(#0), AText);
  if LZero > 0 then
    LLength := LZero - 1;
  if LLength > ASize - 1 then
    LLength := ASize - 1;
  if LLength > 0 then
    Move(AText[1], ADest^, LLength);
  FillChar(PByte(ADest + LLength)^, ASize - LLength, 0);
end;

class function TDoomScriptMemory.ReadString(const ASource: PByte; const ASize: Integer): AnsiString;
var
  LLength: Integer;
begin
  LLength := 0;
  while (LLength < ASize - 1) and (PByte(ASource + LLength)^ <> 0) do
    Inc(LLength);
  SetLength(Result, LLength);
  if LLength > 0 then
    Move(ASource^, Result[1], LLength);
end;

class procedure TDoomScriptMemory.AppendString(const ADest: PByte; const AText: AnsiString);
var
  LLength: Integer;
begin
  LLength := 0;
  while (LLength < DS_MAX_STRING_LEN) and (PByte(ADest + LLength)^ <> 0) do
    Inc(LLength);
  if LLength >= DS_MAX_STRING_LEN then
    raise EDoomScriptError.Create('idStr::Append: already overflowed');
  CopyString(ADest + LLength, AText, DS_MAX_STRING_LEN - LLength);
end;

end.

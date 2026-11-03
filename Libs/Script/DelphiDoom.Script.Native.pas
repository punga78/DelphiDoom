{******************************************************************************}
{                                                                              }
{  DelphiDoom: Script - helpers between the contract and Pascal Script         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Script.Native;

interface

uses
  System.SysUtils, ps_defs, ps_utils, DelphiDoom.Script.Intf;

type
  /// <summary>
  ///   Conversions between the contract of the DLL (raw integers and ANSI
  ///   buffers) and the types of the Pascal Script core (TbtString,
  ///   TPSCallingConvention)
  /// </summary>
  TScriptNative = class sealed
  private
    class function IsIdentifierChar(AChar: AnsiChar): Boolean; static;
  public
    /// <summary>
    ///   Name declared by 'function Name(...)...' or 'procedure Name...';
    ///   empty if the text is not such a declaration
    /// </summary>
    class function ExtractFunctionName(const ADeclaration: TbtString): TbtString; static;

    /// <summary>
    ///   Converts SCRIPT_CALL_* into the convention of Pascal Script
    /// </summary>
    class function TryGetConvention(AValue: Integer;
      out AConvention: TPSCallingConvention): Boolean; static;

    /// <summary>
    ///   Copies AText and its zero terminator in ABuffer. ABufferSize is the
    ///   size of ABuffer on input and the size needed (zero included) on
    ///   output
    /// </summary>
    /// <returns>
    ///   SCRIPT_OK, or SCRIPT_ERROR_BUFFER (nothing written) if ABuffer is
    ///   nil or too small
    /// </returns>
    class function CopyText(const AText: TbtString; ABuffer: PAnsiChar;
      var ABufferSize: Cardinal): Integer; static;
  end;

implementation

{ TScriptNative }

class function TScriptNative.IsIdentifierChar(AChar: AnsiChar): Boolean;
begin
  Result := AChar in ['A'..'Z', 'a'..'z', '0'..'9', '_'];
end;

class function TScriptNative.ExtractFunctionName(
  const ADeclaration: TbtString): TbtString;
var
  LIndex: Integer;
  LStart: Integer;
  LKeyword: string;

  procedure SkipBlanks;
  begin
    while (LIndex <= Length(ADeclaration)) and (ADeclaration[LIndex] <= ' ') do
      Inc(LIndex);
  end;

  procedure SkipIdentifier;
  begin
    while (LIndex <= Length(ADeclaration)) and
          IsIdentifierChar(ADeclaration[LIndex]) do
      Inc(LIndex);
  end;

begin
  Result := '';
  LIndex := 1;

  SkipBlanks;
  LStart := LIndex;
  SkipIdentifier;
  LKeyword := string(Copy(ADeclaration, LStart, LIndex - LStart));
  if not (SameText(LKeyword, 'function') or SameText(LKeyword, 'procedure')) then
    Exit;

  SkipBlanks;
  LStart := LIndex;
  SkipIdentifier;
  if LIndex = LStart then
    Exit;
  // An identifier does not start with a digit
  if ADeclaration[LStart] in ['0'..'9'] then
    Exit;

  Result := Copy(ADeclaration, LStart, LIndex - LStart);
end;

class function TScriptNative.TryGetConvention(AValue: Integer;
  out AConvention: TPSCallingConvention): Boolean;
begin
  Result := True;
  case AValue of
    SCRIPT_CALL_REGISTER: AConvention := cdRegister;
    SCRIPT_CALL_PASCAL:   AConvention := cdPascal;
    SCRIPT_CALL_CDECL:    AConvention := cdCdecl;
    SCRIPT_CALL_STDCALL:  AConvention := cdStdCall;
    SCRIPT_CALL_SAFECALL: AConvention := cdSafeCall;
  else
    AConvention := cdRegister;
    Result := False;
  end;
end;

class function TScriptNative.CopyText(const AText: TbtString;
  ABuffer: PAnsiChar; var ABufferSize: Cardinal): Integer;
var
  LNeeded: Cardinal;
begin
  LNeeded := Cardinal(Length(AText)) + 1;
  if not Assigned(ABuffer) or (ABufferSize < LNeeded) then
  begin
    ABufferSize := LNeeded;
    Exit(SCRIPT_ERROR_BUFFER);
  end;

  if Length(AText) > 0 then
    Move(Pointer(AText)^, ABuffer^, Length(AText));
  ABuffer[Length(AText)] := #0;
  ABufferSize := LNeeded;
  Result := SCRIPT_OK;
end;

end.

{******************************************************************************}
{                                                                              }
{  DelphiDoom: Script - implementation of IScriptExecutor                      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Script.Engine.Executor;

interface

uses
  System.SysUtils, DelphiDoom.Script.Intf, DelphiDoom.Script.Native.Executor;

type
  /// <summary>
  ///   Implementation of IScriptExecutor. Never lets an exception cross the
  ///   interface: every failure becomes an error code
  /// </summary>
  TScriptExecutorEngine = class(TInterfacedObject, IScriptExecutor)
  private
    FNative: TScriptNativeExecutor;
    function ReadArguments(AArguments: PScriptValue; AArgumentCount: Cardinal;
      out AValues: TArray<TScriptNativeValue>): Integer;
    function CallLocked(AName: PAnsiChar; AArguments: PScriptValue;
      AArgumentCount: Cardinal; var AResult: TScriptValue): Integer;
  public
    constructor Create;
    destructor Destroy; override;

    function AddHostFunction(ADeclaration: PAnsiChar; AAddress: Pointer;
      AConvention: Integer): Integer; stdcall;
    function LoadBytecode(ABytecode: Pointer; ABytecodeSize: Cardinal): Integer; stdcall;
    function RunMain: Integer; stdcall;
    function CallProcedure(AName: PAnsiChar; AArguments: PScriptValue;
      AArgumentCount: Cardinal; var AResult: TScriptValue): Integer; stdcall;
    function GetResultText(ABuffer: PAnsiChar; var ABufferSize: Cardinal): Integer; stdcall;
    function GetGlobalInteger(AName: PAnsiChar; out AValue: Int64): Integer; stdcall;
    function SetGlobalInteger(AName: PAnsiChar; AValue: Int64): Integer; stdcall;
    function GetLastErrorText(ABuffer: PAnsiChar; var ABufferSize: Cardinal): Integer; stdcall;
  end;

implementation

uses
  DelphiDoom.Script.Native;

const
  MAX_BYTECODE_SIZE = Cardinal(High(Integer));
  MAX_ARGUMENTS = 256;

{ TScriptExecutorEngine }

constructor TScriptExecutorEngine.Create;
begin
  inherited Create;
  FNative := TScriptNativeExecutor.Create;
end;

destructor TScriptExecutorEngine.Destroy;
begin
  FreeAndNil(FNative);
  inherited;
end;

function TScriptExecutorEngine.AddHostFunction(ADeclaration: PAnsiChar;
  AAddress: Pointer; AConvention: Integer): Integer;
begin
  if not Assigned(ADeclaration) or not Assigned(AAddress) then
    Exit(SCRIPT_ERROR_ARGUMENT);

  try
    Result := FNative.AddHostFunction(AnsiString(ADeclaration), AAddress,
      AConvention);
  except
    on EOutOfMemory do
      Result := SCRIPT_ERROR_MEMORY;
    on Exception do
      Result := SCRIPT_ERROR_INTERNAL;
  end;
end;

function TScriptExecutorEngine.LoadBytecode(ABytecode: Pointer;
  ABytecodeSize: Cardinal): Integer;
var
  LBytecode: AnsiString;
begin
  if not Assigned(ABytecode) or (ABytecodeSize = 0) or
     (ABytecodeSize > MAX_BYTECODE_SIZE) then
    Exit(SCRIPT_ERROR_ARGUMENT);

  try
    // Raw copy of the bytes: the bytecode is binary, not text
    SetString(LBytecode, PAnsiChar(ABytecode), Integer(ABytecodeSize));
    Result := FNative.Load(LBytecode);
  except
    on EOutOfMemory do
      Result := SCRIPT_ERROR_MEMORY;
    on Exception do
      Result := SCRIPT_ERROR_INTERNAL;
  end;
end;

function TScriptExecutorEngine.RunMain: Integer;
begin
  try
    Result := FNative.RunMain;
  except
    on EOutOfMemory do
      Result := SCRIPT_ERROR_MEMORY;
    on Exception do
      Result := SCRIPT_ERROR_INTERNAL;
  end;
end;

function TScriptExecutorEngine.ReadArguments(AArguments: PScriptValue;
  AArgumentCount: Cardinal; out AValues: TArray<TScriptNativeValue>): Integer;
var
  LIndex: Integer;
  LItem: PScriptValue;
begin
  SetLength(AValues, AArgumentCount);
  for LIndex := 0 to Integer(AArgumentCount) - 1 do
  begin
    LItem := PScriptValue(PByte(AArguments) + LIndex * SizeOf(TScriptValue));
    AValues[LIndex].Kind := LItem^.Kind;
    case LItem^.Kind of
      SCRIPT_VALUE_INTEGER:
        AValues[LIndex].IntegerValue := LItem^.IntegerValue;
      SCRIPT_VALUE_DOUBLE:
        AValues[LIndex].DoubleValue := LItem^.DoubleValue;
      SCRIPT_VALUE_TEXT:
        begin
          if not Assigned(LItem^.Text) then
            Exit(SCRIPT_ERROR_ARGUMENT);
          AValues[LIndex].Text := AnsiString(LItem^.Text);
        end;
    else
      Exit(SCRIPT_ERROR_ARGUMENT);
    end;
  end;
  Result := SCRIPT_OK;
end;

function TScriptExecutorEngine.CallLocked(AName: PAnsiChar;
  AArguments: PScriptValue; AArgumentCount: Cardinal;
  var AResult: TScriptValue): Integer;
var
  LValues: TArray<TScriptNativeValue>;
  LResult: TScriptNativeValue;
  LTextBuffer: PAnsiChar;
  LTextCapacity: Cardinal;
begin
  // The buffer for a text result belongs to the caller: keep it, the other
  // fields are overwritten
  LTextBuffer := AResult.Text;
  LTextCapacity := AResult.TextSize;
  AResult.Kind := SCRIPT_VALUE_NONE;
  AResult.IntegerValue := 0;
  AResult.DoubleValue := 0;

  Result := ReadArguments(AArguments, AArgumentCount, LValues);
  if Result <> SCRIPT_OK then
    Exit;

  Result := FNative.Call(AnsiString(AName), LValues, LResult);
  if Result <> SCRIPT_OK then
    Exit;

  AResult.Kind := LResult.Kind;
  AResult.IntegerValue := LResult.IntegerValue;
  AResult.DoubleValue := LResult.DoubleValue;
  if LResult.Kind = SCRIPT_VALUE_TEXT then
  begin
    AResult.TextSize := LTextCapacity;
    // BUFFER here means: the call ran, take the text with GetResultText
    Result := TScriptNative.CopyText(LResult.Text, LTextBuffer, AResult.TextSize);
  end;
end;

function TScriptExecutorEngine.CallProcedure(AName: PAnsiChar;
  AArguments: PScriptValue; AArgumentCount: Cardinal;
  var AResult: TScriptValue): Integer;
begin
  if not Assigned(AName) or (AName^ = #0) or
     (AArgumentCount > MAX_ARGUMENTS) or
     ((AArgumentCount > 0) and not Assigned(AArguments)) then
    Exit(SCRIPT_ERROR_ARGUMENT);

  try
    Result := CallLocked(AName, AArguments, AArgumentCount, AResult);
  except
    on EOutOfMemory do
      Result := SCRIPT_ERROR_MEMORY;
    on Exception do
      Result := SCRIPT_ERROR_INTERNAL;
  end;
end;

function TScriptExecutorEngine.GetResultText(ABuffer: PAnsiChar;
  var ABufferSize: Cardinal): Integer;
begin
  try
    Result := TScriptNative.CopyText(FNative.ResultText, ABuffer, ABufferSize);
  except
    on Exception do
      Result := SCRIPT_ERROR_INTERNAL;
  end;
end;

function TScriptExecutorEngine.GetGlobalInteger(AName: PAnsiChar;
  out AValue: Int64): Integer;
begin
  AValue := 0;
  if not Assigned(AName) or (AName^ = #0) then
    Exit(SCRIPT_ERROR_ARGUMENT);

  try
    Result := FNative.GetGlobalInteger(AnsiString(AName), AValue);
  except
    on EOutOfMemory do
      Result := SCRIPT_ERROR_MEMORY;
    on Exception do
      Result := SCRIPT_ERROR_INTERNAL;
  end;
end;

function TScriptExecutorEngine.SetGlobalInteger(AName: PAnsiChar;
  AValue: Int64): Integer;
begin
  if not Assigned(AName) or (AName^ = #0) then
    Exit(SCRIPT_ERROR_ARGUMENT);

  try
    Result := FNative.SetGlobalInteger(AnsiString(AName), AValue);
  except
    on EOutOfMemory do
      Result := SCRIPT_ERROR_MEMORY;
    on Exception do
      Result := SCRIPT_ERROR_INTERNAL;
  end;
end;

function TScriptExecutorEngine.GetLastErrorText(ABuffer: PAnsiChar;
  var ABufferSize: Cardinal): Integer;
begin
  try
    Result := TScriptNative.CopyText(FNative.LastError, ABuffer, ABufferSize);
  except
    on Exception do
      Result := SCRIPT_ERROR_INTERNAL;
  end;
end;

end.

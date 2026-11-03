{******************************************************************************}
{                                                                              }
{  DelphiDoom: Script - implementation of IScriptCompiler                      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Script.Engine.Compiler;

interface

uses
  System.SysUtils, DelphiDoom.Script.Intf, DelphiDoom.Script.Native.Compiler;

type
  /// <summary>
  ///   Implementation of IScriptCompiler. Never lets an exception cross the
  ///   interface: every failure becomes an error code
  /// </summary>
  /// <remarks>
  ///   The bytecode is kept between the call that reports the size needed
  ///   (SCRIPT_ERROR_BUFFER) and the call that receives it, so that the
  ///   two-phase protocol compiles the source only once
  /// </remarks>
  TScriptCompilerEngine = class(TInterfacedObject, IScriptCompiler)
  private
    FNative: TScriptNativeCompiler;
    FPendingSource: TBytes;
    FPendingBytecode: TBytes;
    function IsPending(ASource: Pointer; ASourceSize: Cardinal): Boolean;
    procedure KeepPending(ASource: Pointer; ASourceSize: Cardinal;
      const ABytecode: AnsiString);
    procedure ClearPending;
    function CompileSource(ASource: Pointer; ASourceSize: Cardinal;
      ADest: Pointer; var ADestSize: Cardinal): Integer;
  public
    constructor Create;
    destructor Destroy; override;

    function AddHostFunction(ADeclaration: PAnsiChar): Integer; stdcall;
    function ClearHostFunctions: Integer; stdcall;
    function SelectUnit(AUnitName: PAnsiChar): Integer; stdcall;
    function AddType(AName, ADefinition: PAnsiChar): Integer; stdcall;
    function AddConstantInteger(AName: PAnsiChar; AValue: Int64;
      ATypeName: PAnsiChar): Integer; stdcall;
    function AddConstantDouble(AName: PAnsiChar; AValue: Double): Integer; stdcall;
    function AddConstantString(AName, AValue: PAnsiChar): Integer; stdcall;
    function Compile(ASource: Pointer; ASourceSize: Cardinal; ADest: Pointer;
      var ADestSize: Cardinal): Integer; stdcall;
    function GetMessageCount(out ACount: Cardinal): Integer; stdcall;
    function GetMessageInfo(AIndex: Cardinal; out AInfo: TScriptMessageInfo;
      AText: PAnsiChar; var ATextSize: Cardinal): Integer; stdcall;
  end;

implementation

uses
  DelphiDoom.Script.Native;

const
  MAX_SOURCE_SIZE = Cardinal(High(Integer));

{ TScriptCompilerEngine }

constructor TScriptCompilerEngine.Create;
begin
  inherited Create;
  FNative := TScriptNativeCompiler.Create;
end;

destructor TScriptCompilerEngine.Destroy;
begin
  FreeAndNil(FNative);
  inherited;
end;

function TScriptCompilerEngine.IsPending(ASource: Pointer;
  ASourceSize: Cardinal): Boolean;
begin
  Result := (Length(FPendingBytecode) > 0) and
    (Cardinal(Length(FPendingSource)) = ASourceSize) and
    CompareMem(Pointer(FPendingSource), ASource, ASourceSize);
end;

procedure TScriptCompilerEngine.KeepPending(ASource: Pointer;
  ASourceSize: Cardinal; const ABytecode: AnsiString);
begin
  SetLength(FPendingSource, ASourceSize);
  Move(ASource^, Pointer(FPendingSource)^, ASourceSize);
  SetLength(FPendingBytecode, Length(ABytecode));
  Move(Pointer(ABytecode)^, Pointer(FPendingBytecode)^, Length(ABytecode));
end;

procedure TScriptCompilerEngine.ClearPending;
begin
  FPendingSource := nil;
  FPendingBytecode := nil;
end;

function TScriptCompilerEngine.AddHostFunction(ADeclaration: PAnsiChar): Integer;
begin
  if not Assigned(ADeclaration) then
    Exit(SCRIPT_ERROR_ARGUMENT);

  try
    // The declared functions change what a source means
    ClearPending;
    Result := FNative.AddHostFunction(AnsiString(ADeclaration));
  except
    on EOutOfMemory do
      Result := SCRIPT_ERROR_MEMORY;
    on Exception do
      Result := SCRIPT_ERROR_INTERNAL;
  end;
end;

function TScriptCompilerEngine.ClearHostFunctions: Integer;
begin
  try
    ClearPending;
    FNative.ClearHostFunctions;
    Result := SCRIPT_OK;
  except
    on Exception do
      Result := SCRIPT_ERROR_INTERNAL;
  end;
end;

function TScriptCompilerEngine.SelectUnit(AUnitName: PAnsiChar): Integer;
begin
  if not Assigned(AUnitName) then
    Exit(SCRIPT_ERROR_ARGUMENT);

  try
    ClearPending;
    Result := FNative.SelectUnit(AnsiString(AUnitName));
  except
    on EOutOfMemory do
      Result := SCRIPT_ERROR_MEMORY;
    on Exception do
      Result := SCRIPT_ERROR_INTERNAL;
  end;
end;

function TScriptCompilerEngine.AddType(AName, ADefinition: PAnsiChar): Integer;
begin
  if not Assigned(AName) or not Assigned(ADefinition) then
    Exit(SCRIPT_ERROR_ARGUMENT);

  try
    ClearPending;
    Result := FNative.AddType(AnsiString(AName), AnsiString(ADefinition));
  except
    on EOutOfMemory do
      Result := SCRIPT_ERROR_MEMORY;
    on Exception do
      Result := SCRIPT_ERROR_INTERNAL;
  end;
end;

function TScriptCompilerEngine.AddConstantInteger(AName: PAnsiChar;
  AValue: Int64; ATypeName: PAnsiChar): Integer;
var
  LTypeName: AnsiString;
begin
  if not Assigned(AName) then
    Exit(SCRIPT_ERROR_ARGUMENT);

  try
    ClearPending;
    if Assigned(ATypeName) then
      LTypeName := AnsiString(ATypeName)
    else
      LTypeName := '';
    Result := FNative.AddConstantInteger(AnsiString(AName), AValue, LTypeName);
  except
    on EOutOfMemory do
      Result := SCRIPT_ERROR_MEMORY;
    on Exception do
      Result := SCRIPT_ERROR_INTERNAL;
  end;
end;

function TScriptCompilerEngine.AddConstantDouble(AName: PAnsiChar;
  AValue: Double): Integer;
begin
  if not Assigned(AName) then
    Exit(SCRIPT_ERROR_ARGUMENT);

  try
    ClearPending;
    Result := FNative.AddConstantDouble(AnsiString(AName), AValue);
  except
    on EOutOfMemory do
      Result := SCRIPT_ERROR_MEMORY;
    on Exception do
      Result := SCRIPT_ERROR_INTERNAL;
  end;
end;

function TScriptCompilerEngine.AddConstantString(AName,
  AValue: PAnsiChar): Integer;
begin
  if not Assigned(AName) or not Assigned(AValue) then
    Exit(SCRIPT_ERROR_ARGUMENT);

  try
    ClearPending;
    Result := FNative.AddConstantString(AnsiString(AName), AnsiString(AValue));
  except
    on EOutOfMemory do
      Result := SCRIPT_ERROR_MEMORY;
    on Exception do
      Result := SCRIPT_ERROR_INTERNAL;
  end;
end;

function TScriptCompilerEngine.CompileSource(ASource: Pointer;
  ASourceSize: Cardinal; ADest: Pointer; var ADestSize: Cardinal): Integer;
var
  LSource: AnsiString;
begin
  if not IsPending(ASource, ASourceSize) then
  begin
    ClearPending;
    SetString(LSource, PAnsiChar(ASource), Integer(ASourceSize));
    if not FNative.Compile(LSource) then
      Exit(SCRIPT_ERROR_COMPILE);
    KeepPending(ASource, ASourceSize, FNative.Bytecode);
  end;

  if not Assigned(ADest) or (ADestSize < Cardinal(Length(FPendingBytecode))) then
  begin
    ADestSize := Length(FPendingBytecode);
    Exit(SCRIPT_ERROR_BUFFER);
  end;

  Move(Pointer(FPendingBytecode)^, ADest^, Length(FPendingBytecode));
  ADestSize := Length(FPendingBytecode);
  ClearPending;
  Result := SCRIPT_OK;
end;

function TScriptCompilerEngine.Compile(ASource: Pointer; ASourceSize: Cardinal;
  ADest: Pointer; var ADestSize: Cardinal): Integer;
begin
  if not Assigned(ASource) or (ASourceSize = 0) or
     (ASourceSize > MAX_SOURCE_SIZE) then
    Exit(SCRIPT_ERROR_ARGUMENT);

  try
    Result := CompileSource(ASource, ASourceSize, ADest, ADestSize);
  except
    on EOutOfMemory do
      Result := SCRIPT_ERROR_MEMORY;
    on Exception do
      Result := SCRIPT_ERROR_INTERNAL;
  end;
end;

function TScriptCompilerEngine.GetMessageCount(out ACount: Cardinal): Integer;
begin
  ACount := Cardinal(FNative.MessageCount);
  Result := SCRIPT_OK;
end;

function TScriptCompilerEngine.GetMessageInfo(AIndex: Cardinal;
  out AInfo: TScriptMessageInfo; AText: PAnsiChar;
  var ATextSize: Cardinal): Integer;
var
  LMessage: TScriptNativeMessage;
begin
  AInfo.Kind := SCRIPT_MESSAGE_ERROR;
  AInfo.Position := 0;
  AInfo.Row := 0;
  AInfo.Col := 0;
  if AIndex >= Cardinal(FNative.MessageCount) then
    Exit(SCRIPT_ERROR_ARGUMENT);

  try
    LMessage := FNative.Messages[Integer(AIndex)];
    AInfo.Kind := LMessage.Kind;
    AInfo.Position := LMessage.Position;
    AInfo.Row := LMessage.Row;
    AInfo.Col := LMessage.Col;
    Result := TScriptNative.CopyText(LMessage.Text, AText, ATextSize);
  except
    on Exception do
      Result := SCRIPT_ERROR_INTERNAL;
  end;
end;

end.

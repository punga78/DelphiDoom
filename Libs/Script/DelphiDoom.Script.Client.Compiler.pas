{******************************************************************************}
{                                                                              }
{  DelphiDoom: Script - the compiler class the engine uses                     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Script.Client.Compiler;

interface

uses
  System.SysUtils, DelphiDoom.Script.Intf;

{$SCOPEDENUMS ON}

type
  /// <summary>
  ///   Severity of a message of the compiler
  /// </summary>
  TScriptMessageKind = (Error, Warning, Hint);

  /// <summary>
  ///   A message of the compiler with its position in the source
  /// </summary>
  TScriptMessage = record
    Kind: TScriptMessageKind;
    /// <summary>Offset (1 based) of the token in the source, in bytes</summary>
    Position: Cardinal;
    /// <summary>Line (1 based)</summary>
    Row: Cardinal;
    /// <summary>Column (1 based)</summary>
    Col: Cardinal;
    Text: AnsiString;
  end;

  /// <summary>
  ///   Stands for the compiler in the rest of the engine: works with
  ///   AnsiString and TBytes and raises EScriptException instead of returning
  ///   error codes
  /// </summary>
  /// <remarks>
  ///   Depends only on IScriptCompiler, so it works the same with the DLL (see
  ///   TScriptLoader), with an engine linked in the executable, or with a fake
  ///   in the tests
  /// </remarks>
  TScriptCompilerClient = class
  private
    FCompiler: IScriptCompiler;
    FMessages: TArray<TScriptMessage>;
    procedure ReadMessages;
  public
    constructor Create(const ACompiler: IScriptCompiler);

    /// <summary>
    ///   Declares a function of the application the sources can call
    /// </summary>
    procedure AddHostFunction(const ADeclaration: AnsiString);
    procedure ClearHostFunctions;

    /// <summary>
    ///   Chooses the unit the following declarations belong to: a source sees
    ///   them when it names the unit in its uses clause. SYSTEM, the default,
    ///   is always visible
    /// </summary>
    procedure SelectUnit(const AUnitName: AnsiString);

    /// <summary>
    ///   Declares a type, for example AddType('TIntegerArray', 'array of integer')
    /// </summary>
    procedure AddType(const AName, ADefinition: AnsiString);

    /// <summary>
    ///   Declares a constant of the current unit; ATypeName is the type of an
    ///   integer constant (integer, longword, int64...)
    /// </summary>
    procedure AddConstant(const AName: AnsiString; AValue: Int64;
      const ATypeName: AnsiString = 'integer'); overload;
    procedure AddConstant(const AName: AnsiString; AValue: Double); overload;
    procedure AddConstant(const AName, AValue: AnsiString); overload;

    /// <summary>
    ///   Turns the preprocessor of the sources on or off ({$DEFINE},
    ///   {$IFDEF}, {$INCLUDE}...)
    /// </summary>
    procedure SetPreprocessor(AEnabled: Boolean);

    /// <summary>
    ///   Defines a symbol for the preprocessor
    /// </summary>
    procedure AddDefine(const AName: AnsiString);

    /// <summary>
    ///   Gives the preprocessor the text of an included file
    /// </summary>
    procedure AddInclude(const AName, AText: AnsiString);

    /// <summary>
    ///   Compiles ASource and returns the bytecode. When the source has
    ///   errors raises EScriptException with SCRIPT_ERROR_COMPILE; in any
    ///   case Messages holds the messages of this compilation
    /// </summary>
    function Compile(const ASource: AnsiString): TBytes;

    /// <summary>
    ///   True if the last compilation reported at least one error
    /// </summary>
    function HasErrors: Boolean;

    property Messages: TArray<TScriptMessage> read FMessages;
  end;

implementation

const
  // First guess of the size of the bytecode and of a message; if it is not
  // enough the DLL tells the exact size and the call is repeated once
  MIN_BYTECODE_CAPACITY = 4096;
  MIN_TEXT_CAPACITY = 256;

{ TScriptCompilerClient }

constructor TScriptCompilerClient.Create(const ACompiler: IScriptCompiler);
begin
  inherited Create;
  if not Assigned(ACompiler) then
    raise EArgumentNilException.Create('ACompiler');
  FCompiler := ACompiler;
end;

procedure TScriptCompilerClient.AddHostFunction(const ADeclaration: AnsiString);
var
  LCode: Integer;
begin
  LCode := FCompiler.AddHostFunction(PAnsiChar(ADeclaration));
  if LCode <> SCRIPT_OK then
    raise EScriptException.CreateCode(LCode, string(ADeclaration));
end;

procedure TScriptCompilerClient.ClearHostFunctions;
var
  LCode: Integer;
begin
  LCode := FCompiler.ClearHostFunctions;
  if LCode <> SCRIPT_OK then
    raise EScriptException.CreateCode(LCode);
end;

procedure TScriptCompilerClient.SelectUnit(const AUnitName: AnsiString);
var
  LCode: Integer;
begin
  LCode := FCompiler.SelectUnit(PAnsiChar(AUnitName));
  if LCode <> SCRIPT_OK then
    raise EScriptException.CreateCode(LCode, string(AUnitName));
end;

procedure TScriptCompilerClient.AddType(const AName, ADefinition: AnsiString);
var
  LCode: Integer;
begin
  LCode := FCompiler.AddType(PAnsiChar(AName), PAnsiChar(ADefinition));
  if LCode <> SCRIPT_OK then
    raise EScriptException.CreateCode(LCode, string(AName));
end;

procedure TScriptCompilerClient.AddConstant(const AName: AnsiString;
  AValue: Int64; const ATypeName: AnsiString);
var
  LCode: Integer;
begin
  LCode := FCompiler.AddConstantInteger(PAnsiChar(AName), AValue,
    PAnsiChar(ATypeName));
  if LCode <> SCRIPT_OK then
    raise EScriptException.CreateCode(LCode, string(AName));
end;

procedure TScriptCompilerClient.AddConstant(const AName: AnsiString;
  AValue: Double);
var
  LCode: Integer;
begin
  LCode := FCompiler.AddConstantDouble(PAnsiChar(AName), AValue);
  if LCode <> SCRIPT_OK then
    raise EScriptException.CreateCode(LCode, string(AName));
end;

procedure TScriptCompilerClient.AddConstant(const AName, AValue: AnsiString);
var
  LCode: Integer;
begin
  LCode := FCompiler.AddConstantString(PAnsiChar(AName), PAnsiChar(AValue));
  if LCode <> SCRIPT_OK then
    raise EScriptException.CreateCode(LCode, string(AName));
end;

procedure TScriptCompilerClient.SetPreprocessor(AEnabled: Boolean);
var
  LCode: Integer;
begin
  LCode := FCompiler.SetPreprocessor(AEnabled);
  if LCode <> SCRIPT_OK then
    raise EScriptException.CreateCode(LCode);
end;

procedure TScriptCompilerClient.AddDefine(const AName: AnsiString);
var
  LCode: Integer;
begin
  LCode := FCompiler.AddDefine(PAnsiChar(AName));
  if LCode <> SCRIPT_OK then
    raise EScriptException.CreateCode(LCode, string(AName));
end;

procedure TScriptCompilerClient.AddInclude(const AName, AText: AnsiString);
var
  LCode: Integer;
begin
  LCode := FCompiler.AddInclude(PAnsiChar(AName), PAnsiChar(AText));
  if LCode <> SCRIPT_OK then
    raise EScriptException.CreateCode(LCode, string(AName));
end;

procedure TScriptCompilerClient.ReadMessages;
var
  LCount: Cardinal;
  LIndex: Integer;
  LInfo: TScriptMessageInfo;
  LText: AnsiString;
  LSize: Cardinal;
  LCode: Integer;
begin
  FMessages := nil;
  if FCompiler.GetMessageCount(LCount) <> SCRIPT_OK then
    Exit;

  SetLength(FMessages, LCount);
  for LIndex := 0 to Integer(LCount) - 1 do
  begin
    SetLength(LText, MIN_TEXT_CAPACITY);
    LSize := Length(LText);
    LCode := FCompiler.GetMessageInfo(Cardinal(LIndex), LInfo, PAnsiChar(LText), LSize);
    if LCode = SCRIPT_ERROR_BUFFER then
    begin
      SetLength(LText, LSize);
      LCode := FCompiler.GetMessageInfo(Cardinal(LIndex), LInfo, PAnsiChar(LText), LSize);
    end;
    if LCode <> SCRIPT_OK then
      raise EScriptException.CreateCode(LCode);

    case LInfo.Kind of
      SCRIPT_MESSAGE_ERROR:   FMessages[LIndex].Kind := TScriptMessageKind.Error;
      SCRIPT_MESSAGE_WARNING: FMessages[LIndex].Kind := TScriptMessageKind.Warning;
    else
      FMessages[LIndex].Kind := TScriptMessageKind.Hint;
    end;
    FMessages[LIndex].Position := LInfo.Position;
    FMessages[LIndex].Row := LInfo.Row;
    FMessages[LIndex].Col := LInfo.Col;
    // LSize counts the zero terminator
    FMessages[LIndex].Text := Copy(LText, 1, LSize - 1);
  end;
end;

function TScriptCompilerClient.Compile(const ASource: AnsiString): TBytes;
var
  LCapacity: Cardinal;
  LSize: Cardinal;
  LCode: Integer;
begin
  if ASource = '' then
    raise EScriptException.CreateCode(SCRIPT_ERROR_ARGUMENT);

  Result := nil;
  LCapacity := Cardinal(Length(ASource)) * 2 + MIN_BYTECODE_CAPACITY;
  repeat
    SetLength(Result, LCapacity);
    LSize := LCapacity;
    LCode := FCompiler.Compile(Pointer(ASource), Length(ASource),
      Pointer(Result), LSize);
    if LCode = SCRIPT_OK then
    begin
      SetLength(Result, LSize);
      ReadMessages;
      Exit;
    end;
    // Only a buffer that is too small is worth another attempt, with the
    // exact size the DLL reported; the source is not compiled again
    if (LCode <> SCRIPT_ERROR_BUFFER) or (LSize <= LCapacity) then
    begin
      ReadMessages;
      raise EScriptException.CreateCode(LCode);
    end;
    LCapacity := LSize;
  until False;
end;

function TScriptCompilerClient.HasErrors: Boolean;
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(FMessages) do
    if FMessages[LIndex].Kind = TScriptMessageKind.Error then
      Exit(True);

  Result := False;
end;

end.

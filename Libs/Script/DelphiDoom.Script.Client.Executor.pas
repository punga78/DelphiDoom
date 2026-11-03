{******************************************************************************}
{                                                                              }
{  DelphiDoom: Script - the executor class the engine uses                     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Script.Client.Executor;

interface

uses
  System.SysUtils, DelphiDoom.Script.Intf;

type
  /// <summary>
  ///   Argument or result of a call, with its own storage for the text
  /// </summary>
  TScriptData = record
    /// <summary>SCRIPT_VALUE_*</summary>
    Kind: Integer;
    IntegerValue: Int64;
    DoubleValue: Double;
    Text: AnsiString;
    class function FromInteger(AValue: Int64): TScriptData; static;
    class function FromDouble(AValue: Double): TScriptData; static;
    class function FromText(const AValue: AnsiString): TScriptData; static;
  end;

  /// <summary>
  ///   Stands for the interpreter in the rest of the engine: works with
  ///   AnsiString and TBytes and raises EScriptException instead of returning
  ///   error codes
  /// </summary>
  /// <remarks>
  ///   Depends only on IScriptExecutor, so it works the same with the DLL
  ///   (see TScriptLoader), with an engine linked in the executable, or with a
  ///   fake in the tests
  /// </remarks>
  TScriptExecutorClient = class
  private
    FExecutor: IScriptExecutor;
    procedure Check(ACode: Integer);
    function LastErrorText: string;
  public
    constructor Create(const AExecutor: IScriptExecutor);

    /// <summary>
    ///   Registers a function of the application: the declaration, its
    ///   address and its calling convention (SCRIPT_CALL_*). Before Load
    /// </summary>
    procedure AddHostFunction(const ADeclaration: AnsiString; AAddress: Pointer;
      AConvention: Integer = SCRIPT_CALL_REGISTER);

    procedure Load(const ABytecode: TBytes);

    /// <summary>
    ///   Runs the main block of the script
    /// </summary>
    procedure RunMain;

    /// <summary>
    ///   Calls a procedure or function of the script. A procedure returns a
    ///   value of kind SCRIPT_VALUE_NONE
    /// </summary>
    function Call(const AName: AnsiString;
      const AArguments: array of TScriptData): TScriptData;

    function GetGlobalInteger(const AName: AnsiString): Int64;
    procedure SetGlobalInteger(const AName: AnsiString; AValue: Int64);
  end;

implementation

const
  // First guess of the size of a text; if it is not enough the DLL tells the
  // exact size and the text is taken with the call made for the purpose
  MIN_TEXT_CAPACITY = 256;

{ TScriptData }

class function TScriptData.FromInteger(AValue: Int64): TScriptData;
begin
  Result.Kind := SCRIPT_VALUE_INTEGER;
  Result.IntegerValue := AValue;
  Result.DoubleValue := 0;
  Result.Text := '';
end;

class function TScriptData.FromDouble(AValue: Double): TScriptData;
begin
  Result.Kind := SCRIPT_VALUE_DOUBLE;
  Result.IntegerValue := 0;
  Result.DoubleValue := AValue;
  Result.Text := '';
end;

class function TScriptData.FromText(const AValue: AnsiString): TScriptData;
begin
  Result.Kind := SCRIPT_VALUE_TEXT;
  Result.IntegerValue := 0;
  Result.DoubleValue := 0;
  Result.Text := AValue;
end;

{ TScriptExecutorClient }

constructor TScriptExecutorClient.Create(const AExecutor: IScriptExecutor);
begin
  inherited Create;
  if not Assigned(AExecutor) then
    raise EArgumentNilException.Create('AExecutor');
  FExecutor := AExecutor;
end;

function TScriptExecutorClient.LastErrorText: string;
var
  LText: AnsiString;
  LSize: Cardinal;
  LCode: Integer;
begin
  SetLength(LText, MIN_TEXT_CAPACITY);
  LSize := Length(LText);
  LCode := FExecutor.GetLastErrorText(PAnsiChar(LText), LSize);
  if LCode = SCRIPT_ERROR_BUFFER then
  begin
    SetLength(LText, LSize);
    LCode := FExecutor.GetLastErrorText(PAnsiChar(LText), LSize);
  end;
  if LCode <> SCRIPT_OK then
    Exit('');

  // LSize counts the zero terminator
  Result := string(Copy(LText, 1, LSize - 1));
end;

procedure TScriptExecutorClient.Check(ACode: Integer);
begin
  if ACode = SCRIPT_OK then
    Exit;

  if (ACode = SCRIPT_ERROR_LOAD) or (ACode = SCRIPT_ERROR_RUNTIME) then
    raise EScriptException.CreateCode(ACode, LastErrorText);
  raise EScriptException.CreateCode(ACode);
end;

procedure TScriptExecutorClient.AddHostFunction(const ADeclaration: AnsiString;
  AAddress: Pointer; AConvention: Integer);
var
  LCode: Integer;
begin
  LCode := FExecutor.AddHostFunction(PAnsiChar(ADeclaration), AAddress,
    AConvention);
  if LCode <> SCRIPT_OK then
    raise EScriptException.CreateCode(LCode, string(ADeclaration));
end;

procedure TScriptExecutorClient.Load(const ABytecode: TBytes);
begin
  Check(FExecutor.LoadBytecode(Pointer(ABytecode), Length(ABytecode)));
end;

procedure TScriptExecutorClient.RunMain;
begin
  Check(FExecutor.RunMain);
end;

function TScriptExecutorClient.Call(const AName: AnsiString;
  const AArguments: array of TScriptData): TScriptData;
var
  LValues: TArray<TScriptValue>;
  LResult: TScriptValue;
  LBuffer: AnsiString;
  LIndex: Integer;
  LSize: Cardinal;
  LCode: Integer;
begin
  SetLength(LValues, Length(AArguments));
  for LIndex := 0 to High(AArguments) do
  begin
    LValues[LIndex].Kind := AArguments[LIndex].Kind;
    LValues[LIndex].TextSize := 0;
    LValues[LIndex].IntegerValue := AArguments[LIndex].IntegerValue;
    LValues[LIndex].DoubleValue := AArguments[LIndex].DoubleValue;
    // The strings live in AArguments until the call returns
    LValues[LIndex].Text := PAnsiChar(AArguments[LIndex].Text);
  end;

  SetLength(LBuffer, MIN_TEXT_CAPACITY);
  LResult.Kind := SCRIPT_VALUE_NONE;
  LResult.IntegerValue := 0;
  LResult.DoubleValue := 0;
  LResult.Text := PAnsiChar(LBuffer);
  LResult.TextSize := Length(LBuffer);

  LCode := FExecutor.CallProcedure(PAnsiChar(AName), PScriptValue(LValues),
    Length(LValues), LResult);
  if LCode = SCRIPT_ERROR_BUFFER then
  begin
    // The procedure has run; only the text did not fit: take it, the call
    // must not be repeated
    SetLength(LBuffer, LResult.TextSize);
    LSize := LResult.TextSize;
    LCode := FExecutor.GetResultText(PAnsiChar(LBuffer), LSize);
    LResult.TextSize := LSize;
  end;
  Check(LCode);

  Result.Kind := LResult.Kind;
  Result.IntegerValue := LResult.IntegerValue;
  Result.DoubleValue := LResult.DoubleValue;
  Result.Text := '';
  if LResult.Kind = SCRIPT_VALUE_TEXT then
    // TextSize counts the zero terminator
    Result.Text := Copy(LBuffer, 1, LResult.TextSize - 1);
end;

function TScriptExecutorClient.GetGlobalInteger(const AName: AnsiString): Int64;
begin
  Check(FExecutor.GetGlobalInteger(PAnsiChar(AName), Result));
end;

procedure TScriptExecutorClient.SetGlobalInteger(const AName: AnsiString;
  AValue: Int64);
begin
  Check(FExecutor.SetGlobalInteger(PAnsiChar(AName), AValue));
end;

end.

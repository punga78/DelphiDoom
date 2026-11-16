{******************************************************************************}
{                                                                              }
{  DelphiDoom: Script - the Pascal Script interpreter, wrapped for the DLL     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Script.Native.Executor;

interface

uses
  System.SysUtils, System.Generics.Collections, ps_defs, ps_utils, ps_runtime,
  DelphiDoom.Script.Intf;

type
  /// <summary>
  ///   Argument or result of a call, in the types of the core
  /// </summary>
  TScriptNativeValue = record
    /// <summary>SCRIPT_VALUE_*</summary>
    Kind: Integer;
    IntegerValue: Int64;
    DoubleValue: Double;
    Text: TbtString;
  end;

  /// <summary>
  ///   A function of the application, registered before the bytecode is loaded
  /// </summary>
  TScriptNativeHostFunction = record
    Name: TbtString;
    Address: Pointer;
    Convention: TPSCallingConvention;
  end;

  /// <summary>
  ///   Pascal Script interpreter without engine functions: runs bytecode that
  ///   uses only the language and the host functions registered with
  ///   AddHostFunction
  /// </summary>
  /// <remarks>
  ///   Every method returns a SCRIPT_* code and never raises. Procedures are
  ///   called without going through Variant (RunProcPN): arguments and
  ///   results are written and read directly in the variables of the
  ///   interpreter, so the bytes of an AnsiString are never converted
  /// </remarks>
  TScriptNativeExecutor = class
  private
    FExec: TPSExec;
    FHostFunctions: TList<TScriptNativeHostFunction>;
    FHostNames: TList<TbtString>;
    FLastError: TbtString;
    FResultText: TbtString;
    FRunLine: TScriptRunLineHandler;
    FExceptionHandler: TScriptExceptionHandler;
    FEventData: Pointer;
    procedure AttachEvents;
    function FindGlobal(const AName: TbtString;
      out AVariable: PPSVariant): Integer;
    function AssignArgument(AVariable: PPSVariant;
      const AArgument: TScriptNativeValue): Boolean;
    function ReadResult(AVariable: PPSVariant;
      out AResult: TScriptNativeValue): Integer;
    function RuntimeErrorText: TbtString;
    procedure Unload;
  public
    constructor Create;
    destructor Destroy; override;

    /// <summary>
    ///   Registers a host function; only before Load
    /// </summary>
    function AddHostFunction(const ADeclaration: TbtString; AAddress: Pointer;
      AConvention: Integer): Integer;

    /// <summary>
    ///   Loads ABytecode (replacing the one loaded before)
    /// </summary>
    function Load(const ABytecode: TbtString): Integer;
    function RunMain: Integer;
    function Call(const AName: TbtString;
      const AArguments: TArray<TScriptNativeValue>;
      out AResult: TScriptNativeValue): Integer;
    function GetGlobalInteger(const AName: TbtString; out AValue: Int64): Integer;
    function SetGlobalInteger(const AName: TbtString; AValue: Int64): Integer;
    function GetGlobalDouble(const AName: TbtString; out AValue: Double): Integer;
    function SetGlobalDouble(const AName: TbtString; AValue: Double): Integer;
    function GetGlobalText(const AName: TbtString; out AValue: TbtString): Integer;
    function SetGlobalText(const AName, AValue: TbtString): Integer;

    /// <summary>
    ///   The globals reachable by name, in the order of declaration
    /// </summary>
    function GetGlobalCount(out ACount: Cardinal): Integer;
    function GetGlobalInfo(AIndex: Cardinal; out AKind: Integer;
      out AName: TbtString): Integer;

    procedure SetEventHandlers(ARunLine: TScriptRunLineHandler;
      AException: TScriptExceptionHandler; AUserData: Pointer);

    /// <summary>Text of the last error of Load, RunMain or Call</summary>
    property LastError: TbtString read FLastError;
    /// <summary>Text result of the last Call</summary>
    property ResultText: TbtString read FResultText;
  end;

implementation

uses
  DelphiDoom.Script.Native;

const
  INVALID_INDEX = Cardinal(-1);

// The events of the interpreter are plain procedures: it reaches this object
// through its Id property

procedure ScriptRunLine(Sender: TPSExec);
var
  LExecutor: TScriptNativeExecutor;
begin
  LExecutor := TScriptNativeExecutor(Sender.Id);
  if Assigned(LExecutor) and Assigned(LExecutor.FRunLine) then
    LExecutor.FRunLine(LExecutor.FEventData);
end;

procedure ScriptException(Sender: TPSExec; ExError: TPSError;
  const ExParam: TbtString; ExObject: TObject; ProcNo, Position: Cardinal);
var
  LExecutor: TScriptNativeExecutor;
begin
  LExecutor := TScriptNativeExecutor(Sender.Id);
  if Assigned(LExecutor) and Assigned(LExecutor.FExceptionHandler) then
    LExecutor.FExceptionHandler(LExecutor.FEventData, Ord(ExError), ProcNo,
      Position);
end;

function KindOfType(AType: PIFTypeRec): Integer;
begin
  case AType.BaseType of
    btU8, btS8, btU16, btS16, btU32, btS32, btS64:
      Result := SCRIPT_GLOBAL_INTEGER;
    btSingle, btDouble, btExtended, btCurrency:
      Result := SCRIPT_GLOBAL_DOUBLE;
    btString, btChar, btUnicodeString, btWideString, btWideChar:
      Result := SCRIPT_GLOBAL_TEXT;
  else
    Result := SCRIPT_GLOBAL_OTHER;
  end;
end;

{ TScriptNativeExecutor }

constructor TScriptNativeExecutor.Create;
begin
  inherited Create;
  FHostFunctions := TList<TScriptNativeHostFunction>.Create;
  FHostNames := TList<TbtString>.Create;
end;

destructor TScriptNativeExecutor.Destroy;
begin
  Unload;
  FreeAndNil(FHostNames);
  FreeAndNil(FHostFunctions);
  inherited;
end;

procedure TScriptNativeExecutor.Unload;
begin
  FreeAndNil(FExec);
end;

function TScriptNativeExecutor.RuntimeErrorText: TbtString;
begin
  Result := TIFErrorToString(FExec.ExceptionCode, FExec.ExceptionString) +
    ' (procedure ' + TbtString(IntToStr(FExec.ExceptionProcNo)) +
    ', position ' + TbtString(IntToStr(FExec.ExceptionPos)) + ')';
end;

function TScriptNativeExecutor.AddHostFunction(const ADeclaration: TbtString;
  AAddress: Pointer; AConvention: Integer): Integer;
var
  LName: TbtString;
  LHostFunction: TScriptNativeHostFunction;
begin
  if Assigned(FExec) then
    Exit(SCRIPT_ERROR_STATE);
  if not Assigned(AAddress) then
    Exit(SCRIPT_ERROR_ARGUMENT);
  if not TScriptNative.TryGetConvention(AConvention, LHostFunction.Convention) then
    Exit(SCRIPT_ERROR_ARGUMENT);

  LName := TScriptNative.ExtractFunctionName(ADeclaration);
  if LName = '' then
    Exit(SCRIPT_ERROR_ARGUMENT);
  LName := FastUpperCase(LName);
  if FHostNames.Contains(LName) then
    Exit(SCRIPT_ERROR_ARGUMENT);

  LHostFunction.Name := LName;
  LHostFunction.Address := AAddress;
  FHostNames.Add(LName);
  FHostFunctions.Add(LHostFunction);
  Result := SCRIPT_OK;
end;

function TScriptNativeExecutor.Load(const ABytecode: TbtString): Integer;
var
  LIndex: Integer;
begin
  Unload;
  FLastError := '';
  FResultText := '';

  FExec := TPSExec.Create;
  FExec.Id := Self;
  AttachEvents;
  for LIndex := 0 to FHostFunctions.Count - 1 do
    FExec.RegisterDelphiFunction(FHostFunctions[LIndex].Address,
      FHostFunctions[LIndex].Name, FHostFunctions[LIndex].Convention);

  if not FExec.LoadData(ABytecode) then
  begin
    FLastError := RuntimeErrorText;
    Unload;
    Exit(SCRIPT_ERROR_LOAD);
  end;

  Result := SCRIPT_OK;
end;

function TScriptNativeExecutor.RunMain: Integer;
begin
  if not Assigned(FExec) then
    Exit(SCRIPT_ERROR_STATE);

  FLastError := '';
  if FExec.RunScript and (FExec.ExceptionCode = erNoError) then
    Exit(SCRIPT_OK);

  if FExec.ExceptionCode = erNoError then
    FLastError := 'The script has no main block'
  else
    FLastError := RuntimeErrorText;
  Result := SCRIPT_ERROR_RUNTIME;
end;

function TScriptNativeExecutor.AssignArgument(AVariable: PPSVariant;
  const AArgument: TScriptNativeValue): Boolean;
var
  LData: Pointer;
begin
  Result := True;
  LData := @PPSVariantData(AVariable).Data;
  case AArgument.Kind of
    SCRIPT_VALUE_INTEGER:
      PSSetInt64(LData, AVariable.FType, Result, AArgument.IntegerValue);
    SCRIPT_VALUE_DOUBLE:
      PSSetReal(LData, AVariable.FType, Result, AArgument.DoubleValue);
    SCRIPT_VALUE_TEXT:
      PSSetAnsiString(LData, AVariable.FType, Result, AArgument.Text);
  else
    Result := False;
  end;
end;

function TScriptNativeExecutor.ReadResult(AVariable: PPSVariant;
  out AResult: TScriptNativeValue): Integer;
var
  LData: Pointer;
begin
  AResult.Kind := SCRIPT_VALUE_NONE;
  AResult.IntegerValue := 0;
  AResult.DoubleValue := 0;
  AResult.Text := '';
  Result := SCRIPT_OK;

  LData := @PPSVariantData(AVariable).Data;
  try
    case AVariable.FType.BaseType of
      btU8, btS8, btU16, btS16, btU32, btS32, btS64:
        begin
          AResult.IntegerValue := PSGetInt64(LData, AVariable.FType);
          AResult.Kind := SCRIPT_VALUE_INTEGER;
        end;
      btSingle, btDouble, btExtended, btCurrency:
        begin
          AResult.DoubleValue := PSGetReal(LData, AVariable.FType);
          AResult.Kind := SCRIPT_VALUE_DOUBLE;
        end;
      btString, btChar, btUnicodeString, btWideString, btWideChar:
        begin
          AResult.Text := PSGetAnsiString(LData, AVariable.FType);
          AResult.Kind := SCRIPT_VALUE_TEXT;
        end;
    else
      Result := SCRIPT_ERROR_TYPE;
    end;
  except
    Result := SCRIPT_ERROR_TYPE;
  end;
end;

function TScriptNativeExecutor.Call(const AName: TbtString;
  const AArguments: TArray<TScriptNativeValue>;
  out AResult: TScriptNativeValue): Integer;
var
  LProcNo: Cardinal;
  LProc: TPSProcRec;
  LDeclaration: TbtString;
  LResultType: TbtString;
  LWord: TbtString;
  LParameters: TPSList;
  LType: PIFTypeRec;
  LVariable: PPSVariant;
  LResultVariable: PPSVariant;
  LIndex: Integer;
  LRan: Boolean;
begin
  AResult.Kind := SCRIPT_VALUE_NONE;
  AResult.IntegerValue := 0;
  AResult.DoubleValue := 0;
  AResult.Text := '';
  FResultText := '';

  if not Assigned(FExec) then
    Exit(SCRIPT_ERROR_STATE);

  LProcNo := FExec.GetProc(AName);
  if LProcNo = INVALID_INDEX then
    Exit(SCRIPT_ERROR_NOTFOUND);
  LProc := FExec.GetProcNo(LProcNo);
  if not (LProc is TPSInternalProcRec) then
    Exit(SCRIPT_ERROR_NOTFOUND);

  // The export declaration is "result param1 ... paramN": the result type
  // first (-1 for a procedure), then the parameters; each one is a mode
  // character followed by the number of its type. The parameters are taken
  // from the last one, as RunProcP does, and the variable of the result goes
  // after them.
  LDeclaration := TPSInternalProcRec(LProc).ExportDecl;
  LResultType := GRFW(LDeclaration);
  LResultVariable := nil;
  LParameters := TPSList.Create;
  try
    LIndex := High(AArguments);
    while LDeclaration <> '' do
    begin
      if LIndex < 0 then
        Exit(SCRIPT_ERROR_TYPE);
      LWord := GRLW(LDeclaration);
      LType := FExec.GetTypeNo(StrToInt(Copy(LWord, 2, MaxInt)));
      if LType = nil then
        Exit(SCRIPT_ERROR_TYPE);
      LVariable := CreateHeapVariant(LType);
      LParameters.Add(LVariable);
      if not AssignArgument(LVariable, AArguments[LIndex]) then
        Exit(SCRIPT_ERROR_TYPE);
      Dec(LIndex);
    end;
    if LIndex >= 0 then
      Exit(SCRIPT_ERROR_TYPE);

    if LResultType <> '-1' then
    begin
      LType := FExec.GetTypeNo(StrToInt(LResultType));
      if LType = nil then
        Exit(SCRIPT_ERROR_TYPE);
      LResultVariable := CreateHeapVariant(LType);
      LParameters.Add(LResultVariable);
    end;

    FLastError := '';
    LRan := FExec.RunProc(LParameters, LProcNo);
    if not LRan or (FExec.ExceptionCode <> erNoError) then
    begin
      if FExec.ExceptionCode = erNoError then
        FLastError := 'The procedure could not be called'
      else
        FLastError := RuntimeErrorText;
      Exit(SCRIPT_ERROR_RUNTIME);
    end;

    if Assigned(LResultVariable) then
    begin
      Result := ReadResult(LResultVariable, AResult);
      if Result = SCRIPT_OK then
        FResultText := AResult.Text;
    end
    else
      Result := SCRIPT_OK;
  finally
    FreePIFVariantList(LParameters);
  end;
end;

procedure TScriptNativeExecutor.AttachEvents;
begin
  if not Assigned(FExec) then
    Exit;

  // Calling the line event costs, so the interpreter gets it only if wanted
  if Assigned(FRunLine) then
    FExec.OnRunLine := ScriptRunLine
  else
    FExec.OnRunLine := nil;
  FExec.OnException := ScriptException;
end;

procedure TScriptNativeExecutor.SetEventHandlers(ARunLine: TScriptRunLineHandler;
  AException: TScriptExceptionHandler; AUserData: Pointer);
begin
  FRunLine := ARunLine;
  FExceptionHandler := AException;
  FEventData := AUserData;
  AttachEvents;
end;

function TScriptNativeExecutor.FindGlobal(const AName: TbtString;
  out AVariable: PPSVariant): Integer;
var
  LIndex: Cardinal;
begin
  AVariable := nil;
  if not Assigned(FExec) then
    Exit(SCRIPT_ERROR_STATE);

  LIndex := FExec.GetVar(AName);
  if LIndex = INVALID_INDEX then
    Exit(SCRIPT_ERROR_NOTFOUND);

  AVariable := FExec.GetVarNo(LIndex);
  Result := SCRIPT_OK;
end;

function TScriptNativeExecutor.GetGlobalCount(out ACount: Cardinal): Integer;
begin
  ACount := 0;
  if not Assigned(FExec) then
    Exit(SCRIPT_ERROR_STATE);

  ACount := Cardinal(FExec.GetExportedVarCount);
  Result := SCRIPT_OK;
end;

function TScriptNativeExecutor.GetGlobalInfo(AIndex: Cardinal;
  out AKind: Integer; out AName: TbtString): Integer;
var
  LVariable: PPSVariant;
begin
  AKind := SCRIPT_GLOBAL_OTHER;
  AName := '';
  if not Assigned(FExec) then
    Exit(SCRIPT_ERROR_STATE);
  if AIndex >= Cardinal(FExec.GetExportedVarCount) then
    Exit(SCRIPT_ERROR_NOTFOUND);

  AName := FExec.GetExportedVarName(AIndex);
  LVariable := FExec.GetVarNo(AIndex);
  AKind := KindOfType(LVariable.FType);
  Result := SCRIPT_OK;
end;

function TScriptNativeExecutor.GetGlobalDouble(const AName: TbtString;
  out AValue: Double): Integer;
var
  LVariable: PPSVariant;
begin
  AValue := 0;
  Result := FindGlobal(AName, LVariable);
  if Result <> SCRIPT_OK then
    Exit;

  try
    if KindOfType(LVariable.FType) <> SCRIPT_GLOBAL_DOUBLE then
      Exit(SCRIPT_ERROR_TYPE);
    AValue := PSGetReal(@PPSVariantData(LVariable).Data, LVariable.FType);
  except
    Result := SCRIPT_ERROR_TYPE;
  end;
end;

function TScriptNativeExecutor.SetGlobalDouble(const AName: TbtString;
  AValue: Double): Integer;
var
  LVariable: PPSVariant;
  LValid: Boolean;
begin
  Result := FindGlobal(AName, LVariable);
  if Result <> SCRIPT_OK then
    Exit;

  try
    if KindOfType(LVariable.FType) <> SCRIPT_GLOBAL_DOUBLE then
      Exit(SCRIPT_ERROR_TYPE);
    LValid := True;
    PSSetReal(@PPSVariantData(LVariable).Data, LVariable.FType, LValid, AValue);
    if not LValid then
      Result := SCRIPT_ERROR_TYPE;
  except
    Result := SCRIPT_ERROR_TYPE;
  end;
end;

function TScriptNativeExecutor.GetGlobalText(const AName: TbtString;
  out AValue: TbtString): Integer;
var
  LVariable: PPSVariant;
begin
  AValue := '';
  Result := FindGlobal(AName, LVariable);
  if Result <> SCRIPT_OK then
    Exit;

  try
    if KindOfType(LVariable.FType) <> SCRIPT_GLOBAL_TEXT then
      Exit(SCRIPT_ERROR_TYPE);
    AValue := PSGetAnsiString(@PPSVariantData(LVariable).Data, LVariable.FType);
  except
    Result := SCRIPT_ERROR_TYPE;
  end;
end;

function TScriptNativeExecutor.SetGlobalText(const AName,
  AValue: TbtString): Integer;
var
  LVariable: PPSVariant;
  LValid: Boolean;
begin
  Result := FindGlobal(AName, LVariable);
  if Result <> SCRIPT_OK then
    Exit;

  try
    if KindOfType(LVariable.FType) <> SCRIPT_GLOBAL_TEXT then
      Exit(SCRIPT_ERROR_TYPE);
    LValid := True;
    PSSetAnsiString(@PPSVariantData(LVariable).Data, LVariable.FType, LValid,
      AValue);
    if not LValid then
      Result := SCRIPT_ERROR_TYPE;
  except
    Result := SCRIPT_ERROR_TYPE;
  end;
end;

function TScriptNativeExecutor.GetGlobalInteger(const AName: TbtString;
  out AValue: Int64): Integer;
var
  LIndex: Cardinal;
  LVariable: PPSVariant;
begin
  AValue := 0;
  if not Assigned(FExec) then
    Exit(SCRIPT_ERROR_STATE);

  LIndex := FExec.GetVar(AName);
  if LIndex = INVALID_INDEX then
    Exit(SCRIPT_ERROR_NOTFOUND);

  LVariable := FExec.GetVarNo(LIndex);
  try
    AValue := PSGetInt64(@PPSVariantData(LVariable).Data, LVariable.FType);
    Result := SCRIPT_OK;
  except
    Result := SCRIPT_ERROR_TYPE;
  end;
end;

function TScriptNativeExecutor.SetGlobalInteger(const AName: TbtString;
  AValue: Int64): Integer;
var
  LIndex: Cardinal;
  LVariable: PPSVariant;
  LOk: Boolean;
begin
  if not Assigned(FExec) then
    Exit(SCRIPT_ERROR_STATE);

  LIndex := FExec.GetVar(AName);
  if LIndex = INVALID_INDEX then
    Exit(SCRIPT_ERROR_NOTFOUND);

  LVariable := FExec.GetVarNo(LIndex);
  LOk := True;
  PSSetInt64(@PPSVariantData(LVariable).Data, LVariable.FType, LOk, AValue);
  if LOk then
    Result := SCRIPT_OK
  else
    Result := SCRIPT_ERROR_TYPE;
end;

end.

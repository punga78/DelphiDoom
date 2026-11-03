{******************************************************************************}
{                                                                              }
{  DelphiDoom: Script - the Pascal Script compiler, configured for the DLL     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Script.Native.Compiler;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, ps_defs,
  ps_utils, ps_keywords, ps_compiler, uPSPreProcessor, DelphiDoom.Script.Intf;

const
  /// <summary>Name of the unit that every source sees</summary>
  SCRIPT_SYSTEM_UNIT: TbtString = 'SYSTEM';

type
  /// <summary>
  ///   A message of the compiler, copied out of the compiler (which frees its
  ///   own messages at the next compilation)
  /// </summary>
  TScriptNativeMessage = record
    /// <summary>SCRIPT_MESSAGE_*</summary>
    Kind: Integer;
    Position: Cardinal;
    Row: Cardinal;
    Col: Cardinal;
    Text: TbtString;
  end;

  /// <summary>
  ///   What a declaration of the application declares
  /// </summary>
  TScriptNativeDeclarationKind = (sndFunction, sndType, sndConstantInteger,
    sndConstantDouble, sndConstantString);

  /// <summary>
  ///   A declaration of the application, kept until the compiler asks for it
  ///   (Pascal Script accepts them only while a compilation is running)
  /// </summary>
  TScriptNativeDeclaration = record
    Kind: TScriptNativeDeclarationKind;
    /// <summary>Name of the type or constant; unused for a function</summary>
    Name: TbtString;
    /// <summary>
    ///   Declaration of a function, definition of a type, name of the type of
    ///   an integer constant, value of a string constant
    /// </summary>
    Text: TbtString;
    IntegerValue: Int64;
    DoubleValue: Double;
  end;

  /// <summary>
  ///   Pascal Script compiler with the standard keywords and no engine
  ///   functions: the only functions a source can call, besides the ones of
  ///   the language, are the host functions declared with AddHostFunction
  /// </summary>
  /// <remarks>
  ///   Pascal Script allows to register functions only while a compilation is
  ///   running (in the OnUses event for the unit SYSTEM), so the declarations
  ///   are kept here and given to the compiler at the beginning of every
  ///   compilation. Every global variable of the source is exported, so that
  ///   the executor can read and write it by name
  /// </remarks>
  TScriptNativeCompiler = class
  private
    FCompiler: TPSPascalCompiler;
    // Declarations by unit (upper case name); SYSTEM always exists
    FUnits: TObjectDictionary<TbtString, TList<TScriptNativeDeclaration>>;
    FCurrentUnit: TbtString;
    // Upper case names of everything declared, units apart
    FHostNames: TList<TbtString>;
    FMessages: TList<TScriptNativeMessage>;
    FBytecode: TbtString;
    FPreprocess: Boolean;
    FDefines: TStringList;
    // Text of the files the sources include, by upper case name
    FIncludes: TDictionary<TbtString, TbtString>;
    function GetMessageCount: Integer;
    function GetMessage(AIndex: Integer): TScriptNativeMessage;
    procedure CollectMessages;
    procedure AddMessage(AKind: Integer; const AText: TbtString);
    function HasErrorMessage: Boolean;
    function DeclarationsOf(const AUnitName: TbtString;
      ACreate: Boolean): TList<TScriptNativeDeclaration>;
    function Reserve(const AName: TbtString): Boolean;
    procedure AddDeclaration(const ADeclaration: TScriptNativeDeclaration);
    procedure RegisterDeclaration(ACompiler: TPSPascalCompiler;
      const ADeclaration: TScriptNativeDeclaration);
  public
    /// <param name="AKeywords">SCRIPT_KEYWORDS_*</param>
    constructor Create(AKeywords: Integer = SCRIPT_KEYWORDS_STANDARD);
    destructor Destroy; override;

    /// <summary>
    ///   Called by the preprocessor for an included file. Not meant to be
    ///   called by anyone else
    /// </summary>
    function FindInclude(const AName: TbtString; out AText: TbtString): Boolean;

    function SetPreprocessor(AEnabled: Boolean): Integer;
    function AddDefine(const AName: TbtString): Integer;
    function AddInclude(const AName, AText: TbtString): Integer;

    /// <summary>
    ///   Called by the compiler for a unit: gives it what the application
    ///   declared for it. Not meant to be called by anyone else
    /// </summary>
    /// <returns>False if no declaration belongs to the unit</returns>
    function RegisterUnit(ACompiler: TPSPascalCompiler;
      const AUnitName: TbtString): Boolean;

    /// <summary>
    ///   Adds a host function declaration
    /// </summary>
    /// <returns>SCRIPT_OK, or SCRIPT_ERROR_ARGUMENT if invalid or duplicate</returns>
    function AddHostFunction(const ADeclaration: TbtString): Integer;
    procedure ClearHostFunctions;

    /// <summary>
    ///   Chooses the unit of the following declarations
    /// </summary>
    function SelectUnit(const AUnitName: TbtString): Integer;
    function AddType(const AName, ADefinition: TbtString): Integer;
    function AddConstantInteger(const AName: TbtString; AValue: Int64;
      const ATypeName: TbtString): Integer;
    function AddConstantDouble(const AName: TbtString; AValue: Double): Integer;
    function AddConstantString(const AName, AValue: TbtString): Integer;

    /// <summary>
    ///   Compiles ASource. True if the bytecode is available in Bytecode;
    ///   the messages are available in any case
    /// </summary>
    function Compile(const ASource: TbtString): Boolean;

    property Bytecode: TbtString read FBytecode;
    property MessageCount: Integer read GetMessageCount;
    property Messages[AIndex: Integer]: TScriptNativeMessage read GetMessage;
  end;

implementation

uses
  DelphiDoom.Script.Native;

// The events of the compiler are plain functions, not methods: the compiler
// reaches this object through its ID property

function ScriptOnUses(Sender: TPSPascalCompiler; const Name: TbtString): Boolean;
begin
  // SYSTEM is always there, the others exist when the application declared
  // something for them
  Result := TScriptNativeCompiler(Sender.ID).RegisterUnit(Sender, Name);
end;

function ScriptNeedFile(Sender: TPSPreProcessor; const CallingFileName: TbtString;
  var FileName, Output: TbtString): Boolean;
begin
  Result := TScriptNativeCompiler(Sender.ID).FindInclude(FileName, Output);
end;

function ScriptExportGlobals(Sender: TPSPascalCompiler): Boolean;
var
  LIndex: Integer;
  LVariable: TPSVar;
begin
  // The executor finds a variable by the index of its entry in the table of
  // the exported variables, which is the index of the variable only if all
  // of them are exported, in the order of declaration
  for LIndex := 0 to Sender.GetVarCount - 1 do
  begin
    LVariable := Sender.GetVar(LIndex);
    if LVariable.ExportName = '' then
      LVariable.ExportName := LVariable.Name;
  end;
  Result := True;
end;

{ TScriptNativeCompiler }

constructor TScriptNativeCompiler.Create(AKeywords: Integer);
begin
  inherited Create;
  FDefines := TStringList.Create;
  FIncludes := TDictionary<TbtString, TbtString>.Create;
  FUnits := TObjectDictionary<TbtString, TList<TScriptNativeDeclaration>>.Create(
    [doOwnsValues]);
  FCurrentUnit := SCRIPT_SYSTEM_UNIT;
  DeclarationsOf(SCRIPT_SYSTEM_UNIT, True);
  FHostNames := TList<TbtString>.Create;
  FMessages := TList<TScriptNativeMessage>.Create;

  if AKeywords = SCRIPT_KEYWORDS_MODEL then
    FCompiler := TPSPascalCompiler.Create(PRTabArray(@DDModelScriptLookupTable),
      DDMODELSCRIPT_KEYWORD_COUNT)
  else
    FCompiler := TPSPascalCompiler.Create(PRTabArray(@DefaultLookupTable),
      DEFAULT_KEYWORD_COUNT);
  FCompiler.ID := Self;
  FCompiler.OnUses := ScriptOnUses;
  FCompiler.OnBeforeOutput := ScriptExportGlobals;
end;

destructor TScriptNativeCompiler.Destroy;
begin
  FreeAndNil(FCompiler);
  FreeAndNil(FMessages);
  FreeAndNil(FHostNames);
  FreeAndNil(FUnits);
  FreeAndNil(FIncludes);
  FreeAndNil(FDefines);
  inherited;
end;

function TScriptNativeCompiler.FindInclude(const AName: TbtString;
  out AText: TbtString): Boolean;
begin
  Result := FIncludes.TryGetValue(FastUpperCase(AName), AText);
end;

function TScriptNativeCompiler.SetPreprocessor(AEnabled: Boolean): Integer;
begin
  FPreprocess := AEnabled;
  Result := SCRIPT_OK;
end;

function TScriptNativeCompiler.AddDefine(const AName: TbtString): Integer;
begin
  if not TScriptNative.IsIdentifier(AName) then
    Exit(SCRIPT_ERROR_ARGUMENT);

  if FDefines.IndexOf(string(FastUpperCase(AName))) < 0 then
    FDefines.Add(string(FastUpperCase(AName)));
  Result := SCRIPT_OK;
end;

function TScriptNativeCompiler.AddInclude(const AName, AText: TbtString): Integer;
begin
  if AName = '' then
    Exit(SCRIPT_ERROR_ARGUMENT);

  FIncludes.AddOrSetValue(FastUpperCase(AName), AText);
  Result := SCRIPT_OK;
end;

function TScriptNativeCompiler.GetMessageCount: Integer;
begin
  Result := FMessages.Count;
end;

function TScriptNativeCompiler.GetMessage(AIndex: Integer): TScriptNativeMessage;
begin
  Result := FMessages[AIndex];
end;

function TScriptNativeCompiler.DeclarationsOf(const AUnitName: TbtString;
  ACreate: Boolean): TList<TScriptNativeDeclaration>;
begin
  if not FUnits.TryGetValue(AUnitName, Result) then
  begin
    if not ACreate then
      Exit(nil);
    Result := TList<TScriptNativeDeclaration>.Create;
    FUnits.Add(AUnitName, Result);
  end;
end;

function TScriptNativeCompiler.Reserve(const AName: TbtString): Boolean;
var
  LName: TbtString;
begin
  Result := False;
  if not TScriptNative.IsIdentifier(AName) then
    Exit;

  LName := FastUpperCase(AName);
  if FHostNames.Contains(LName) then
    Exit;

  FHostNames.Add(LName);
  Result := True;
end;

procedure TScriptNativeCompiler.AddDeclaration(
  const ADeclaration: TScriptNativeDeclaration);
begin
  DeclarationsOf(FCurrentUnit, True).Add(ADeclaration);
end;

procedure TScriptNativeCompiler.RegisterDeclaration(ACompiler: TPSPascalCompiler;
  const ADeclaration: TScriptNativeDeclaration);
var
  LType: TPSType;
  LConstant: TPSConstant;
begin
  case ADeclaration.Kind of
    sndFunction:
      ACompiler.AddDelphiFunction(ADeclaration.Text);
    sndType:
      ACompiler.AddTypeS(ADeclaration.Name, ADeclaration.Text);
    sndConstantInteger:
      begin
        LType := ACompiler.FindType(ADeclaration.Text);
        if LType = nil then
          raise EPSCompilerException.Create('Unknown type ' + string(ADeclaration.Text) +
            ' for the constant ' + string(ADeclaration.Name));
        LConstant := ACompiler.AddConstant(ADeclaration.Name, LType);
        case LType.BaseType of
          btU8: LConstant.Value.tu8 := Byte(ADeclaration.IntegerValue);
          btS8: LConstant.Value.ts8 := ShortInt(ADeclaration.IntegerValue);
          btU16: LConstant.Value.tu16 := Word(ADeclaration.IntegerValue);
          btS16: LConstant.Value.ts16 := SmallInt(ADeclaration.IntegerValue);
          btU32: LConstant.Value.tu32 := Cardinal(ADeclaration.IntegerValue);
          btS32: LConstant.Value.ts32 := Integer(ADeclaration.IntegerValue);
          btS64: LConstant.Value.ts64 := ADeclaration.IntegerValue;
        else
          raise EPSCompilerException.Create('The type ' + string(ADeclaration.Text) +
            ' cannot hold an integer constant');
        end;
      end;
    sndConstantDouble:
      ACompiler.AddConstantN(ADeclaration.Name, 'extended').SetExtended(
        ADeclaration.DoubleValue);
    sndConstantString:
      ACompiler.AddConstantN(ADeclaration.Name, 'string').SetString(
        ADeclaration.Text);
  end;
end;

function TScriptNativeCompiler.RegisterUnit(ACompiler: TPSPascalCompiler;
  const AUnitName: TbtString): Boolean;
var
  LDeclarations: TList<TScriptNativeDeclaration>;
  LIndex: Integer;
begin
  LDeclarations := DeclarationsOf(FastUpperCase(AUnitName), False);
  Result := Assigned(LDeclarations);
  if not Result then
    Exit;

  for LIndex := 0 to LDeclarations.Count - 1 do
    RegisterDeclaration(ACompiler, LDeclarations[LIndex]);
end;

function TScriptNativeCompiler.SelectUnit(const AUnitName: TbtString): Integer;
begin
  if not TScriptNative.IsIdentifier(AUnitName) then
    Exit(SCRIPT_ERROR_ARGUMENT);

  FCurrentUnit := FastUpperCase(AUnitName);
  DeclarationsOf(FCurrentUnit, True);
  Result := SCRIPT_OK;
end;

function TScriptNativeCompiler.AddType(const AName, ADefinition: TbtString): Integer;
var
  LDeclaration: TScriptNativeDeclaration;
begin
  if Trim(string(ADefinition)) = '' then
    Exit(SCRIPT_ERROR_ARGUMENT);
  if not Reserve(AName) then
    Exit(SCRIPT_ERROR_ARGUMENT);

  LDeclaration := Default(TScriptNativeDeclaration);
  LDeclaration.Kind := sndType;
  LDeclaration.Name := AName;
  LDeclaration.Text := ADefinition;
  AddDeclaration(LDeclaration);
  Result := SCRIPT_OK;
end;

function TScriptNativeCompiler.AddConstantInteger(const AName: TbtString;
  AValue: Int64; const ATypeName: TbtString): Integer;
var
  LDeclaration: TScriptNativeDeclaration;
begin
  if (ATypeName <> '') and not TScriptNative.IsIdentifier(ATypeName) then
    Exit(SCRIPT_ERROR_ARGUMENT);
  if not Reserve(AName) then
    Exit(SCRIPT_ERROR_ARGUMENT);

  LDeclaration := Default(TScriptNativeDeclaration);
  LDeclaration.Kind := sndConstantInteger;
  LDeclaration.Name := AName;
  if ATypeName = '' then
    LDeclaration.Text := 'integer'
  else
    LDeclaration.Text := ATypeName;
  LDeclaration.IntegerValue := AValue;
  AddDeclaration(LDeclaration);
  Result := SCRIPT_OK;
end;

function TScriptNativeCompiler.AddConstantDouble(const AName: TbtString;
  AValue: Double): Integer;
var
  LDeclaration: TScriptNativeDeclaration;
begin
  if not Reserve(AName) then
    Exit(SCRIPT_ERROR_ARGUMENT);

  LDeclaration := Default(TScriptNativeDeclaration);
  LDeclaration.Kind := sndConstantDouble;
  LDeclaration.Name := AName;
  LDeclaration.DoubleValue := AValue;
  AddDeclaration(LDeclaration);
  Result := SCRIPT_OK;
end;

function TScriptNativeCompiler.AddConstantString(const AName,
  AValue: TbtString): Integer;
var
  LDeclaration: TScriptNativeDeclaration;
begin
  if not Reserve(AName) then
    Exit(SCRIPT_ERROR_ARGUMENT);

  LDeclaration := Default(TScriptNativeDeclaration);
  LDeclaration.Kind := sndConstantString;
  LDeclaration.Name := AName;
  LDeclaration.Text := AValue;
  AddDeclaration(LDeclaration);
  Result := SCRIPT_OK;
end;

function TScriptNativeCompiler.AddHostFunction(const ADeclaration: TbtString): Integer;
var
  LName: TbtString;
  LDeclaration: TbtString;
  LEntry: TScriptNativeDeclaration;
begin
  LName := TScriptNative.ExtractFunctionName(ADeclaration);
  if LName = '' then
    Exit(SCRIPT_ERROR_ARGUMENT);

  LName := FastUpperCase(LName);
  if FHostNames.Contains(LName) then
    Exit(SCRIPT_ERROR_ARGUMENT);

  // The parser of the declarations wants the final semicolon
  LDeclaration := ADeclaration;
  while LDeclaration[Length(LDeclaration)] <= ' ' do
    SetLength(LDeclaration, Length(LDeclaration) - 1);
  if LDeclaration[Length(LDeclaration)] <> ';' then
    LDeclaration := LDeclaration + ';';

  FHostNames.Add(LName);
  LEntry := Default(TScriptNativeDeclaration);
  LEntry.Kind := sndFunction;
  LEntry.Text := LDeclaration;
  AddDeclaration(LEntry);
  Result := SCRIPT_OK;
end;

procedure TScriptNativeCompiler.ClearHostFunctions;
begin
  // Everything the application declared goes: the names are free again
  FHostNames.Clear;
  FUnits.Clear;
  DeclarationsOf(SCRIPT_SYSTEM_UNIT, True);
  FCurrentUnit := SCRIPT_SYSTEM_UNIT;
end;

procedure TScriptNativeCompiler.AddMessage(AKind: Integer; const AText: TbtString);
var
  LMessage: TScriptNativeMessage;
begin
  LMessage.Kind := AKind;
  LMessage.Position := 0;
  LMessage.Row := 0;
  LMessage.Col := 0;
  LMessage.Text := AText;
  FMessages.Add(LMessage);
end;

procedure TScriptNativeCompiler.CollectMessages;
var
  LIndex: Integer;
  LSource: TPSPascalCompilerMessage;
  LMessage: TScriptNativeMessage;
begin
  FMessages.Clear;
  for LIndex := 0 to FCompiler.MsgCount - 1 do
  begin
    LSource := FCompiler.Msg[LIndex];
    if LSource is TPSPascalCompilerError then
      LMessage.Kind := SCRIPT_MESSAGE_ERROR
    else if LSource is TPSPascalCompilerWarning then
      LMessage.Kind := SCRIPT_MESSAGE_WARNING
    else
      LMessage.Kind := SCRIPT_MESSAGE_HINT;
    LMessage.Position := LSource.Pos;
    LMessage.Row := LSource.Row;
    LMessage.Col := LSource.Col;
    LMessage.Text := LSource.ShortMessageToString;
    FMessages.Add(LMessage);
  end;
end;

function TScriptNativeCompiler.HasErrorMessage: Boolean;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FMessages.Count - 1 do
    if FMessages[LIndex].Kind = SCRIPT_MESSAGE_ERROR then
      Exit(True);

  Result := False;
end;

function TScriptNativeCompiler.Compile(const ASource: TbtString): Boolean;
var
  LFailure: string;
  LPreProcessor: TPSPreProcessor;
  LText: TbtString;
begin
  FBytecode := '';
  LFailure := '';
  LPreProcessor := nil;
  try
    try
      LText := ASource;
      if FPreprocess then
      begin
        LPreProcessor := TPSPreProcessor.Create;
        LPreProcessor.ID := Self;
        LPreProcessor.OnNeedFile := ScriptNeedFile;
        LPreProcessor.Defines.AddStrings(FDefines);
        LPreProcessor.MainFileName := 'main';
        LPreProcessor.MainFile := ASource;
        LPreProcessor.PreProcess('main', LText);
      end;

      Result := FCompiler.Compile(LText);
      if Result then
        Result := FCompiler.GetOutput(FBytecode);
      // The messages refer to the preprocessed text: bring them back
      if Assigned(LPreProcessor) then
        LPreProcessor.AdjustMessages(FCompiler);
    except
      on E: Exception do
      begin
        Result := False;
        LFailure := E.Message;
      end;
    end;
  finally
    LPreProcessor.Free;
  end;

  CollectMessages;
  if LFailure <> '' then
    AddMessage(SCRIPT_MESSAGE_ERROR, TbtString(LFailure));
  // A failure the compiler did not explain still needs an error to show
  if not Result then
  begin
    FBytecode := '';
    if not HasErrorMessage then
      AddMessage(SCRIPT_MESSAGE_ERROR, 'Compilation failed');
  end;
end;

end.

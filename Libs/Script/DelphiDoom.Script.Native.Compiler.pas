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
  System.SysUtils, System.Generics.Collections, ps_defs, ps_utils, ps_keywords,
  ps_compiler, DelphiDoom.Script.Intf;

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
    FHostDeclarations: TList<TbtString>;
    FHostNames: TList<TbtString>;
    FMessages: TList<TScriptNativeMessage>;
    FBytecode: TbtString;
    function GetMessageCount: Integer;
    function GetMessage(AIndex: Integer): TScriptNativeMessage;
    procedure CollectMessages;
    procedure AddMessage(AKind: Integer; const AText: TbtString);
    function HasErrorMessage: Boolean;
  public
    constructor Create;
    destructor Destroy; override;

    /// <summary>
    ///   Called by the compiler for the unit SYSTEM: declares the host
    ///   functions. Not meant to be called by anyone else
    /// </summary>
    procedure RegisterHostFunctions(ACompiler: TPSPascalCompiler);

    /// <summary>
    ///   Adds a host function declaration
    /// </summary>
    /// <returns>SCRIPT_OK, or SCRIPT_ERROR_ARGUMENT if invalid or duplicate</returns>
    function AddHostFunction(const ADeclaration: TbtString): Integer;
    procedure ClearHostFunctions;

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
  // No units: the sources use the language and the host functions only
  Result := Name = 'SYSTEM';
  if Result then
    TScriptNativeCompiler(Sender.ID).RegisterHostFunctions(Sender);
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

constructor TScriptNativeCompiler.Create;
begin
  inherited Create;
  FHostDeclarations := TList<TbtString>.Create;
  FHostNames := TList<TbtString>.Create;
  FMessages := TList<TScriptNativeMessage>.Create;

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
  FreeAndNil(FHostDeclarations);
  inherited;
end;

function TScriptNativeCompiler.GetMessageCount: Integer;
begin
  Result := FMessages.Count;
end;

function TScriptNativeCompiler.GetMessage(AIndex: Integer): TScriptNativeMessage;
begin
  Result := FMessages[AIndex];
end;

procedure TScriptNativeCompiler.RegisterHostFunctions(ACompiler: TPSPascalCompiler);
var
  LIndex: Integer;
begin
  for LIndex := 0 to FHostDeclarations.Count - 1 do
    ACompiler.AddDelphiFunction(FHostDeclarations[LIndex]);
end;

function TScriptNativeCompiler.AddHostFunction(const ADeclaration: TbtString): Integer;
var
  LName: TbtString;
  LDeclaration: TbtString;
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
  FHostDeclarations.Add(LDeclaration);
  Result := SCRIPT_OK;
end;

procedure TScriptNativeCompiler.ClearHostFunctions;
begin
  FHostNames.Clear;
  FHostDeclarations.Clear;
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
begin
  FBytecode := '';
  LFailure := '';
  try
    Result := FCompiler.Compile(ASource);
    if Result then
      Result := FCompiler.GetOutput(FBytecode);
  except
    on E: Exception do
    begin
      Result := False;
      LFailure := E.Message;
    end;
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

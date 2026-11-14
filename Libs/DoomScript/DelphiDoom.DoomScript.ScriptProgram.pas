{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom script (id Tech 4) - TDoomScriptProgram (idProgram)        }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): game\script\             }
{  Script_Program.h, Script_Program.cpp. Copyright (C) 1999-2011 id Software   }
{  LLC, a ZeniMax Media company.                                               }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3 or later, with    }
{  the additional terms of the Doom 3 Source Code License (see README.md of    }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.DoomScript.ScriptProgram;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DelphiDoom.IdLib.Core.Intf,
  DelphiDoom.IdLib.Math.Vec3, DelphiDoom.DoomScript.Types, DelphiDoom.DoomScript.Intf,
  DelphiDoom.DoomScript.EventDef, DelphiDoom.DoomScript.Defs;

type
  /// <summary>
  ///   The compiler as the program sees it: compiles a text into the program, raising
  ///   EDoomScriptCompileError with the message of the original
  /// </summary>
  TDoomScriptCompileProc = reference to procedure(const AText, AFileName: AnsiString; const AConsole: Boolean);

  /// <summary>
  ///   idProgram: the tables of a compiled script (types, definitions, functions, statements, file names)
  ///   and the memory of its global variables. The types and defs of the simple types, which the original
  ///   kept as globals (type_float, def_float...), belong to the program. The compiler and the action
  ///   that ends the threads on a restart are given from outside (<c>SetCompiler</c>,
  ///   <c>SetRestartThreads</c>) so that the program does not know them.
  ///   <para>The memory never holds a native pointer: every size is the one of the 32 bit original.</para>
  /// </summary>
  TDoomScriptProgram = class
  strict private
    FLog: IIdLibLog;
    FFileSystem: IIdLibFileSystem;
    FHost: IDoomScriptHost;
    FCompile: TDoomScriptCompileProc;
    FRestartThreads: TProc;
    FReleaseObjects: TProc<Integer>;
    FFileList: TList<AnsiString>;
    FFileName: AnsiString;
    FFileNum: Integer;
    FNumVariables: Integer;
    FVariables: TBytes;
    FVariableDefaults: TBytes;
    FFunctions: TObjectList<TDoomScriptFunction>;
    // the functions a restart removed: cleared, kept alive because an older object type may still list them
    FRemovedFunctions: TObjectList<TDoomScriptFunction>;
    FStatements: TArray<TDoomScriptStatement>;
    FNumStatements: Integer;
    FTypes: TObjectList<TDoomScriptTypeDef>;
    FVarDefNames: TObjectDictionary<AnsiString, TDoomScriptVarDefName>;
    FVarDefs: TList<TDoomScriptVarDef>;
    FSysDef: TDoomScriptVarDef;
    FReturnDef: TDoomScriptVarDef;
    FReturnStringDef: TDoomScriptVarDef;
    FTopFunctions: Integer;
    FTopStatements: Integer;
    FTopTypes: Integer;
    FTopDefs: Integer;
    FTopFiles: Integer;
    FBuiltinTypes: array[TDoomScriptEType] of TDoomScriptTypeDef;
    FBuiltinDefs: array[TDoomScriptEType] of TDoomScriptVarDef;
    procedure CreateBuiltins;
    procedure FreeBuiltins;
    procedure CompileStats;
    procedure PrintLine(const AText: string);
    function DefInfo(const ADef: TDoomScriptVarDef; const AInstructionPointer: Integer): AnsiString;
    function ReturnPtr(const ASize: Integer): PByte;
  public
    constructor Create(const AHost: IDoomScriptHost; const ALog: IIdLibLog; const AFileSystem: IIdLibFileSystem);
    destructor Destroy; override;
    procedure SetCompiler(const ACompile: TDoomScriptCompileProc);
    procedure SetRestartThreads(const ARestartThreads: TProc);
    /// <summary>Called with the number of types that survive, before the program frees the others</summary>
    procedure SetReleaseObjects(const AReleaseObjects: TProc<Integer>);

    /// <summary>The built-in type of a kind (type_void ... type_boolean)</summary>
    function BuiltinType(const AKind: TDoomScriptEType): TDoomScriptTypeDef;
    /// <summary>The built-in def of a kind (def_void ... def_boolean)</summary>
    function BuiltinDef(const AKind: TDoomScriptEType): TDoomScriptVarDef;
    function DefNamespace: TDoomScriptVarDef;
    function DefObject: TDoomScriptVarDef;
    function TypeObject: TDoomScriptTypeDef;

    /// <summary>idProgram::Save: the files compiled after the start, the changed globals, the checksum</summary>
    procedure Save(const AStream: TStream);
    /// <summary>idProgram::Restore: false if the checksum of the statements differs from the saved one</summary>
    function Restore(const AStream: TStream): Boolean;
    /// <summary>MD4 of the statements, as the original computed it on its 20 byte records</summary>
    function CalculateChecksum: Integer;
    procedure Startup(const ADefaultScript: AnsiString);
    /// <summary>Ends the threads, drops what was compiled after <c>FinishCompilation</c>, resets the globals</summary>
    procedure Restart;
    function CompileText(const ASource, AText: AnsiString; const AConsole: Boolean): Boolean;
    function CompileFunction(const AFunctionName, AText: AnsiString): TDoomScriptFunction;
    procedure CompileFile(const AFileName: AnsiString);
    procedure BeginCompilation;
    procedure FinishCompilation;
    /// <summary>idProgram::DisassembleStatement: one line, ending with a line feed</summary>
    function DisassembleStatement(const AInstructionPointer: Integer): AnsiString;
    /// <summary>The text idProgram::Disassemble writes</summary>
    function DisassembleText: AnsiString;
    /// <summary>idProgram::Disassemble: writes script/disasm.txt through the file system</summary>
    procedure Disassemble;
    procedure FreeData;
    function GetFilename(const ANum: Integer): AnsiString;
    function GetFilenum(const AName: AnsiString): Integer;
    function GetLineNumberForStatement(const AIndex: Integer): Integer;
    function GetFilenameForStatement(const AIndex: Integer): AnsiString;
    function NumFilenames: Integer;

    function AllocType(const AType: TDoomScriptTypeDef): TDoomScriptTypeDef; overload;
    function AllocType(const AKind: TDoomScriptEType; const ADef: TDoomScriptVarDef; const AName: AnsiString;
      const ASize: Integer; const AAux: TDoomScriptTypeDef): TDoomScriptTypeDef; overload;
    function GetType(const AType: TDoomScriptTypeDef; const AAllocate: Boolean): TDoomScriptTypeDef;
    function FindType(const AName: AnsiString): TDoomScriptTypeDef;
    function NumTypes: Integer;
    function GetTypeByIndex(const AIndex: Integer): TDoomScriptTypeDef;

    function AllocDef(const AType: TDoomScriptTypeDef; const AName: AnsiString; const AScope: TDoomScriptVarDef;
      const AConstant: Boolean): TDoomScriptVarDef;
    /// <summary>The def with this name nearest to the scope; a nil type matches any type</summary>
    function GetDef(const AType: TDoomScriptTypeDef; const AName: AnsiString;
      const AScope: TDoomScriptVarDef): TDoomScriptVarDef;
    procedure FreeDef(const ADef: TDoomScriptVarDef; const AScope: TDoomScriptVarDef);
    function FindFreeResultDef(const AType: TDoomScriptTypeDef; const AName: AnsiString;
      const AScope, AVarA, AVarB: TDoomScriptVarDef): TDoomScriptVarDef;
    function GetDefList(const AName: AnsiString): TDoomScriptVarDef;
    function NumDefs: Integer;
    function GetDefByIndex(const AIndex: Integer): TDoomScriptVarDef;
    /// <summary>idVarDef::SetValue: writes an immediate where the def keeps its value</summary>
    procedure SetDefValue(const ADef: TDoomScriptVarDef; const AValue: TDoomScriptEval; const AConstant: Boolean);
    /// <summary>idVarDef::SetString</summary>
    procedure SetDefString(const ADef: TDoomScriptVarDef; const AText: AnsiString; const AConstant: Boolean);
    /// <summary>idVarDef::SetObject( NULL ): clears the entity number of a global object variable</summary>
    procedure ClearDefObject(const ADef: TDoomScriptVarDef);

    /// <summary>Finds a script function by its full name ("namespace::name"); nil for an event or none</summary>
    function FindFunction(const AName: AnsiString): TDoomScriptFunction; overload;
    /// <summary>Finds a method of an object type, looking up the super types</summary>
    function FindFunction(const AName: AnsiString; const AType: TDoomScriptTypeDef): TDoomScriptFunction; overload;
    function AllocFunction(const ADef: TDoomScriptVarDef): TDoomScriptFunction;
    function GetFunction(const AIndex: Integer): TDoomScriptFunction;
    function GetFunctionIndex(const AFunction: TDoomScriptFunction): Integer;
    function NumFunctions: Integer;
    /// <summary>Points the global <c>$name</c> to an entity (number, or -1 for none)</summary>
    procedure SetEntity(const AName: AnsiString; const AEntityNumber: Integer);

    /// <summary>The index of the new statement; raises a compile error at the limit</summary>
    function AllocStatement: Integer;
    function GetStatement(const AIndex: Integer): PDoomScriptStatement;
    function NumStatements: Integer;
    /// <summary>The first statement, for the loop of the interpreter (the array never moves)</summary>
    function StatementsBase: PDoomScriptStatement;

    /// <summary>A checked pointer to <c>ASize</c> bytes of the global memory</summary>
    function GlobalPtr(const AOffset, ASize: Integer): PByte;
    /// <summary>The start of the global memory (DS_MAX_GLOBALS bytes), for the loop of the interpreter</summary>
    function GlobalsBase: PByte;
    function GetReturnedInteger: Integer;
    procedure ReturnFloat(const AValue: Single);
    procedure ReturnInteger(const AValue: Integer);
    procedure ReturnVector(const AValue: TIdVec3);
    procedure ReturnString(const AText: AnsiString);
    /// <summary>Returns an entity to the script: its number, or -1 for none</summary>
    procedure ReturnEntity(const AEntityNumber: Integer);

    property ReturnDef: TDoomScriptVarDef read FReturnDef;
    property ReturnStringDef: TDoomScriptVarDef read FReturnStringDef;
    property SysDef: TDoomScriptVarDef read FSysDef;
    property NumVariables: Integer read FNumVariables;
    property Host: IDoomScriptHost read FHost;
    property Log: IIdLibLog read FLog;
    property FileSystem: IIdLibFileSystem read FFileSystem;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Strings, DelphiDoom.IdLib.Hashing.Md4, DelphiDoom.DoomScript.Opcodes,
  DelphiDoom.DoomScript.SaveStream;

const
  SWeirdType = 'weird type on ''%s''';
  SGlobalsExceeded = 'Exceeded global memory size (%d bytes)';
  STypeMismatchRedeclaration = 'Type mismatch on redeclaration of %s';
  SMaxFunctions = 'Exceeded maximum allowed number of functions (%d)';
  SMaxStatements = 'Exceeded maximum allowed number of statements (%d)';
  SNotDefined = 'function %s was not defined'#10;
  SCompileFailed = 'Compile failed.';
  SCouldNotLoad = 'Couldn''t load %s'#10;
  SNoCompiler = 'idProgram: no compiler was given';
  SGlobalOutOfRange = 'idProgram: access to %d bytes at %d is outside the global memory';
  SStatementOutOfRange = 'idProgram: statement %d out of range';
  SFunctionOutOfRange = 'idProgram: function %d out of range';
  SFileOutOfRange = 'idProgram: file %d out of range';
  SIndexOutOfRange = 'idProgram: index %d out of range';
  SResultOutsideFunction = 'idProgram::AllocDef: a result or local variable needs a function scope';
  SRestoreIndex = 'idProgram::Restore: variable index %d out of range';
  SNotStarted = 'idProgram: the program was not started (BeginCompilation)';
  DISASM_FILE: AnsiString = 'script/disasm.txt';

  BuiltinNames: array[TDoomScriptEType] of AnsiString = ('', 'void', 'scriptevent', 'namespace', 'string', 'float',
    'vector', 'entity', 'field', 'function', 'virtual function', 'pointer', 'object', '<jump>', '<argsize>',
    'boolean');
  // the sizes of the 32 bit original
  BuiltinSizes: array[TDoomScriptEType] of Integer = (0, 0, 4, 4, DS_MAX_STRING_LEN, 4, 12, 4, 4, 4, 4, 4, 4, 4,
    4, 4);

{ TDoomScriptProgram }

constructor TDoomScriptProgram.Create(const AHost: IDoomScriptHost; const ALog: IIdLibLog;
  const AFileSystem: IIdLibFileSystem);
begin
  inherited Create;
  FHost := AHost;
  FLog := ALog;
  FFileSystem := AFileSystem;
  FFileList := TList<AnsiString>.Create;
  FFunctions := TObjectList<TDoomScriptFunction>.Create(True);
  FRemovedFunctions := TObjectList<TDoomScriptFunction>.Create(True);
  FTypes := TObjectList<TDoomScriptTypeDef>.Create(True);
  FVarDefNames := TObjectDictionary<AnsiString, TDoomScriptVarDefName>.Create([doOwnsValues]);
  FVarDefs := TList<TDoomScriptVarDef>.Create;
  SetLength(FVariables, DS_MAX_GLOBALS);
  SetLength(FStatements, DS_MAX_STATEMENTS);
  CreateBuiltins;
  FreeData;
end;

destructor TDoomScriptProgram.Destroy;
begin
  FreeData;
  FreeBuiltins;
  FVarDefs.Free;
  FVarDefNames.Free;
  FTypes.Free;
  FRemovedFunctions.Free;
  FFunctions.Free;
  FFileList.Free;
  inherited;
end;

procedure TDoomScriptProgram.CreateBuiltins;
var
  LKind: TDoomScriptEType;
begin
  for LKind := evVoid to High(TDoomScriptEType) do
  begin
    FBuiltinTypes[LKind] := TDoomScriptTypeDef.Create(LKind, nil, BuiltinNames[LKind], BuiltinSizes[LKind], nil);
    FBuiltinDefs[LKind] := TDoomScriptVarDef.Create(FBuiltinTypes[LKind], True);
    FBuiltinTypes[LKind].Def := FBuiltinDefs[LKind];
  end;
  // type_function( ev_function, &def_function, "function", sizeof( void * ), &type_void )
  FBuiltinTypes[evFunction].SetReturnType(FBuiltinTypes[evVoid]);
end;

procedure TDoomScriptProgram.FreeBuiltins;
var
  LKind: TDoomScriptEType;
begin
  for LKind := evVoid to High(TDoomScriptEType) do
  begin
    FBuiltinDefs[LKind].Free;
    FBuiltinTypes[LKind].Free;
  end;
end;

procedure TDoomScriptProgram.SetCompiler(const ACompile: TDoomScriptCompileProc);
begin
  FCompile := ACompile;
end;

procedure TDoomScriptProgram.SetRestartThreads(const ARestartThreads: TProc);
begin
  FRestartThreads := ARestartThreads;
end;

procedure TDoomScriptProgram.SetReleaseObjects(const AReleaseObjects: TProc<Integer>);
begin
  FReleaseObjects := AReleaseObjects;
end;

procedure TDoomScriptProgram.PrintLine(const AText: string);
begin
  if Assigned(FLog) then
    FLog.Printf(AText);
end;

function TDoomScriptProgram.BuiltinType(const AKind: TDoomScriptEType): TDoomScriptTypeDef;
begin
  Result := FBuiltinTypes[AKind];
end;

function TDoomScriptProgram.BuiltinDef(const AKind: TDoomScriptEType): TDoomScriptVarDef;
begin
  Result := FBuiltinDefs[AKind];
end;

function TDoomScriptProgram.DefNamespace: TDoomScriptVarDef;
begin
  Result := FBuiltinDefs[evNamespace];
end;

function TDoomScriptProgram.DefObject: TDoomScriptVarDef;
begin
  Result := FBuiltinDefs[evObject];
end;

function TDoomScriptProgram.TypeObject: TDoomScriptTypeDef;
begin
  Result := FBuiltinTypes[evObject];
end;

function TDoomScriptProgram.GlobalsBase: PByte;
begin
  Result := @FVariables[0];
end;

function TDoomScriptProgram.GlobalPtr(const AOffset, ASize: Integer): PByte;
begin
  if (AOffset < 0) or (ASize < 0) or (AOffset > DS_MAX_GLOBALS - ASize) then
    raise EDoomScriptMemoryError.CreateFmt(SGlobalOutOfRange, [ASize, AOffset]);
  Result := @FVariables[AOffset];
end;

function TDoomScriptProgram.StatementsBase: PDoomScriptStatement;
begin
  Result := @FStatements[0];
end;

function TDoomScriptProgram.NumStatements: Integer;
begin
  Result := FNumStatements;
end;

function TDoomScriptProgram.GetStatement(const AIndex: Integer): PDoomScriptStatement;
begin
  if (AIndex < 0) or (AIndex >= FNumStatements) then
    raise EDoomScriptMemoryError.CreateFmt(SStatementOutOfRange, [AIndex]);
  Result := @FStatements[AIndex];
end;

function TDoomScriptProgram.AllocStatement: Integer;
begin
  if FNumStatements >= DS_MAX_STATEMENTS then
    raise EDoomScriptCompileError.CreateFmt(SMaxStatements, [DS_MAX_STATEMENTS]);
  Result := FNumStatements;
  FStatements[Result] := Default(TDoomScriptStatement);
  Inc(FNumStatements);
end;

function TDoomScriptProgram.NumFunctions: Integer;
begin
  Result := FFunctions.Count;
end;

function TDoomScriptProgram.GetFunction(const AIndex: Integer): TDoomScriptFunction;
begin
  if (AIndex < 0) or (AIndex >= FFunctions.Count) then
    raise EDoomScriptMemoryError.CreateFmt(SFunctionOutOfRange, [AIndex]);
  Result := FFunctions[AIndex];
end;

function TDoomScriptProgram.GetFunctionIndex(const AFunction: TDoomScriptFunction): Integer;
begin
  if Assigned(AFunction) and (AFunction.Index < FFunctions.Count) and (FFunctions[AFunction.Index] = AFunction) then
    Result := AFunction.Index
  else
    Result := -1;
end;

function TDoomScriptProgram.NumFilenames: Integer;
begin
  Result := FFileList.Count;
end;

function TDoomScriptProgram.GetFilename(const ANum: Integer): AnsiString;
begin
  if (ANum < 0) or (ANum >= FFileList.Count) then
    raise EDoomScriptMemoryError.CreateFmt(SFileOutOfRange, [ANum]);
  Result := FFileList[ANum];
end;

function TDoomScriptProgram.GetLineNumberForStatement(const AIndex: Integer): Integer;
begin
  Result := GetStatement(AIndex).LineNumber;
end;

function TDoomScriptProgram.GetFilenameForStatement(const AIndex: Integer): AnsiString;
begin
  Result := GetFilename(GetStatement(AIndex).FileNum);
end;

function TDoomScriptProgram.GetFilenum(const AName: AnsiString): Integer;
var
  LStripped: AnsiString;
  LName: AnsiString;
begin
  if FFileName = AName then
    Exit(FFileNum);
  LStripped := FHost.OSPathToRelativePath(AName);
  if LStripped = '' then
    // not off the base path so just use the full path
    LName := AName
  else
    LName := LStripped;
  FFileNum := FFileList.IndexOf(LName);
  if FFileNum < 0 then
    FFileNum := FFileList.Add(LName);
  // save the unstripped name so that the incoming name is not stripped at every call
  FFileName := AName;
  Result := FFileNum;
end;

function TDoomScriptProgram.NumTypes: Integer;
begin
  Result := FTypes.Count;
end;

function TDoomScriptProgram.GetTypeByIndex(const AIndex: Integer): TDoomScriptTypeDef;
begin
  if (AIndex < 0) or (AIndex >= FTypes.Count) then
    raise EDoomScriptMemoryError.CreateFmt(SIndexOutOfRange, [AIndex]);
  Result := FTypes[AIndex];
end;

function TDoomScriptProgram.NumDefs: Integer;
begin
  Result := FVarDefs.Count;
end;

function TDoomScriptProgram.GetDefByIndex(const AIndex: Integer): TDoomScriptVarDef;
begin
  if (AIndex < 0) or (AIndex >= FVarDefs.Count) then
    raise EDoomScriptMemoryError.CreateFmt(SIndexOutOfRange, [AIndex]);
  Result := FVarDefs[AIndex];
end;

function TDoomScriptProgram.AllocType(const AType: TDoomScriptTypeDef): TDoomScriptTypeDef;
begin
  Result := TDoomScriptTypeDef.CreateCopy(AType);
  FTypes.Add(Result);
end;

function TDoomScriptProgram.AllocType(const AKind: TDoomScriptEType; const ADef: TDoomScriptVarDef;
  const AName: AnsiString; const ASize: Integer; const AAux: TDoomScriptTypeDef): TDoomScriptTypeDef;
begin
  Result := TDoomScriptTypeDef.Create(AKind, ADef, AName, ASize, AAux);
  FTypes.Add(Result);
end;

function TDoomScriptProgram.GetType(const AType: TDoomScriptTypeDef; const AAllocate: Boolean): TDoomScriptTypeDef;
var
  LIndex: Integer;
begin
  for LIndex := FTypes.Count - 1 downto 0 do
    if FTypes[LIndex].MatchesType(AType) and (FTypes[LIndex].Name = AType.Name) then
      Exit(FTypes[LIndex]);
  if not AAllocate then
    Exit(nil);
  Result := AllocType(AType);
end;

function TDoomScriptProgram.FindType(const AName: AnsiString): TDoomScriptTypeDef;
var
  LIndex: Integer;
begin
  for LIndex := FTypes.Count - 1 downto 0 do
    if FTypes[LIndex].Name = AName then
      Exit(FTypes[LIndex]);
  Result := nil;
end;

function TDoomScriptProgram.GetDefList(const AName: AnsiString): TDoomScriptVarDef;
var
  LName: TDoomScriptVarDefName;
begin
  if FVarDefNames.TryGetValue(AName, LName) then
    Result := LName.Defs
  else
    Result := nil;
end;

function TDoomScriptProgram.AllocDef(const AType: TDoomScriptTypeDef; const AName: AnsiString;
  const AScope: TDoomScriptVarDef; const AConstant: Boolean): TDoomScriptVarDef;
var
  LDef: TDoomScriptVarDef;
  LName: TDoomScriptVarDefName;
  LDefX: TDoomScriptVarDef;
  LDefY: TDoomScriptVarDef;
  LDefZ: TDoomScriptVarDef;
  LFieldTemplate: TDoomScriptTypeDef;
  LFieldType: TDoomScriptTypeDef;
  LSize: Integer;
begin
  LDef := TDoomScriptVarDef.Create(AType);
  LDef.Scope := AScope;
  LDef.NumUsers := 1;
  LDef.Num := FVarDefs.Add(LDef);
  // add the def to the list of defs with this name
  if not FVarDefNames.TryGetValue(AName, LName) then
  begin
    LName := TDoomScriptVarDefName.Create(AName);
    FVarDefNames.Add(AName, LName);
  end;
  LName.AddDef(LDef);
  Result := LDef;

  if (AType.Kind = evVector) or ((AType.Kind = evField) and (AType.FieldType.Kind = evVector)) then
  begin
    if AName = DS_RESULT_STRING then
    begin
      // <RESULT> vector defs don't need the _x, _y and _z components
      if not Assigned(AScope.FunctionPtr) then
        raise EDoomScriptError.Create(SResultOutsideFunction);
      LDef.Value := AScope.FunctionPtr.Locals;
      LDef.Initialized := diStackVariable;
      Inc(AScope.FunctionPtr.Locals, AType.Size);
    end
    else if AScope.TypeDef.IsObject then
    begin
      LFieldTemplate := TDoomScriptTypeDef.Create(evField, nil, 'float field', 0, FBuiltinTypes[evFloat]);
      try
        LFieldType := GetType(LFieldTemplate, True);
      finally
        LFieldTemplate.Free;
      end;
      // set the value to the variable's position in the object
      LDef.Value := AScope.TypeDef.Size;
      // origin can be accessed as origin_x, origin_y, and origin_z
      LDefX := AllocDef(LFieldType, AName + '_x', AScope, AConstant);
      LDefY := AllocDef(LFieldType, AName + '_y', AScope, AConstant);
      LDefY.Value := LDefX.Value + 4;
      LDefZ := AllocDef(LFieldType, AName + '_z', AScope, AConstant);
      LDefZ.Value := LDefY.Value + 4;
    end
    else
    begin
      LDefX := AllocDef(FBuiltinTypes[evFloat], AName + '_x', AScope, AConstant);
      AllocDef(FBuiltinTypes[evFloat], AName + '_y', AScope, AConstant);
      AllocDef(FBuiltinTypes[evFloat], AName + '_z', AScope, AConstant);
      // point the vector def to the x coordinate
      LDef.Value := LDefX.Value;
      LDef.Initialized := LDefX.Initialized;
    end;
  end
  else if AScope.TypeDef.IsObject then
    // object variable: its position in the object
    LDef.Value := AScope.TypeDef.Size
  else if AScope.Kind = evFunction then
  begin
    // stack variable
    if not Assigned(AScope.FunctionPtr) then
      raise EDoomScriptError.Create(SResultOutsideFunction);
    LDef.Value := AScope.FunctionPtr.Locals;
    LDef.Initialized := diStackVariable;
    if AType.IsObject then
      // objects only have their entity number on the stack, not the entire object
      Inc(AScope.FunctionPtr.Locals, 4)
    else
      Inc(AScope.FunctionPtr.Locals, AType.Size);
  end
  else
  begin
    // global variable
    LSize := AType.Size;
    LDef.Value := FNumVariables;
    Inc(FNumVariables, LSize);
    if FNumVariables > DS_MAX_GLOBALS then
      raise EDoomScriptCompileError.CreateFmt(SGlobalsExceeded, [DS_MAX_GLOBALS]);
    if LSize > 0 then
      FillChar(FVariables[LDef.Value], LSize, 0);
  end;
end;

function TDoomScriptProgram.GetDef(const AType: TDoomScriptTypeDef; const AName: AnsiString;
  const AScope: TDoomScriptVarDef): TDoomScriptVarDef;
var
  LDef: TDoomScriptVarDef;
  LBestDepth: Integer;
  LDepth: Integer;
begin
  LBestDepth := 0;
  Result := nil;
  LDef := GetDefList(AName);
  while Assigned(LDef) do
  begin
    if LDef.Scope.Kind = evNamespace then
    begin
      LDepth := LDef.DepthOfScope(AScope);
      if LDepth = 0 then
      begin
        // not in the same namespace
        LDef := LDef.Next;
        Continue;
      end;
    end
    else if LDef.Scope <> AScope then
    begin
      // in a different function
      LDef := LDef.Next;
      Continue;
    end
    else
      LDepth := 1;
    if (not Assigned(Result)) or (LDepth < LBestDepth) then
    begin
      LBestDepth := LDepth;
      Result := LDef;
    end;
    LDef := LDef.Next;
  end;
  // see if the name is already in use for another type
  if Assigned(Result) and Assigned(AType) and (Result.TypeDef <> AType) then
    raise EDoomScriptCompileError.CreateFmt(STypeMismatchRedeclaration, [string(AName)]);
end;

procedure TDoomScriptProgram.FreeDef(const ADef: TDoomScriptVarDef; const AScope: TDoomScriptVarDef);
var
  LElement: TDoomScriptVarDef;
  LIndex: Integer;
  LName: AnsiString;
begin
  if ADef.Kind = evVector then
  begin
    LName := ADef.Name;
    LElement := GetDef(nil, LName + '_x', AScope);
    if Assigned(LElement) then
      FreeDef(LElement, AScope);
    LElement := GetDef(nil, LName + '_y', AScope);
    if Assigned(LElement) then
      FreeDef(LElement, AScope);
    LElement := GetDef(nil, LName + '_z', AScope);
    if Assigned(LElement) then
      FreeDef(LElement, AScope);
  end;
  FVarDefs.Delete(ADef.Num);
  for LIndex := ADef.Num to FVarDefs.Count - 1 do
    FVarDefs[LIndex].Num := LIndex;
  ADef.Free;
end;

function TDoomScriptProgram.FindFreeResultDef(const AType: TDoomScriptTypeDef; const AName: AnsiString;
  const AScope, AVarA, AVarB: TDoomScriptVarDef): TDoomScriptVarDef;
var
  LDef: TDoomScriptVarDef;
begin
  LDef := GetDefList(AName);
  while Assigned(LDef) do
  begin
    if (LDef <> AVarA) and (LDef <> AVarB) and (LDef.TypeDef = AType) and (LDef.Scope = AScope) and
      (LDef.NumUsers > 1) then
      Exit(LDef);
    LDef := LDef.Next;
  end;
  Result := AllocDef(AType, AName, AScope, False);
end;

procedure TDoomScriptProgram.SetDefValue(const ADef: TDoomScriptVarDef; const AValue: TDoomScriptEval;
  const AConstant: Boolean);
begin
  if AConstant then
    ADef.Initialized := diInitializedConstant
  else
    ADef.Initialized := diInitializedVariable;
  case ADef.Kind of
    evPointer, evBoolean, evField, evEntity, evObject, evFloat:
      PInteger(GlobalPtr(ADef.Value, 4))^ := AValue.IntValue;
    evJumpOffset, evArgSize, evVirtualFunction:
      ADef.Value := AValue.IntValue;
    evVector:
      Move(AValue.Vector[0], GlobalPtr(ADef.Value, 12)^, 12);
    evFunction:
      // the original stored the pointer of the union: a function immediate does not exist
      ADef.FunctionPtr := nil;
  else
    raise EDoomScriptCompileError.CreateFmt(SWeirdType, [string(ADef.Name)]);
  end;
end;

procedure TDoomScriptProgram.SetDefString(const ADef: TDoomScriptVarDef; const AText: AnsiString;
  const AConstant: Boolean);
begin
  if AConstant then
    ADef.Initialized := diInitializedConstant
  else
    ADef.Initialized := diInitializedVariable;
  TDoomScriptMemory.CopyString(GlobalPtr(ADef.Value, DS_MAX_STRING_LEN), AText);
end;

procedure TDoomScriptProgram.ClearDefObject(const ADef: TDoomScriptVarDef);
begin
  // idVarDef::SetObject has "initialized = initialized": the state of the def does not change
  PInteger(GlobalPtr(ADef.Value, 4))^ := 0;
end;

function TDoomScriptProgram.FindFunction(const AName: AnsiString): TDoomScriptFunction;
var
  LStart: Integer;
  LPos: Integer;
  LNamespaceDef: TDoomScriptVarDef;
  LDef: TDoomScriptVarDef;
begin
  LStart := 0;
  LNamespaceDef := DefNamespace;
  repeat
    LPos := TIdStrings.FindText(AName, '::', True, LStart);
    if LPos < 0 then
      Break;
    LDef := GetDef(nil, Copy(AName, LStart + 1, LPos - LStart), LNamespaceDef);
    if not Assigned(LDef) then
      // couldn't find namespace
      Exit(nil);
    LNamespaceDef := LDef;
    // skip past the ::
    LStart := LPos + 2;
  until LDef.Kind <> evNamespace;
  LDef := GetDef(nil, Copy(AName, LStart + 1, MaxInt), LNamespaceDef);
  if Assigned(LDef) and (LDef.Kind = evFunction) and Assigned(LDef.FunctionPtr) and
    not Assigned(LDef.FunctionPtr.EventDef) then
    Result := LDef.FunctionPtr
  else
    // is not a function, or is an eventdef
    Result := nil;
end;

function TDoomScriptProgram.FindFunction(const AName: AnsiString; const AType: TDoomScriptTypeDef): TDoomScriptFunction;
var
  LTypeDef: TDoomScriptVarDef;
  LDef: TDoomScriptVarDef;
begin
  LTypeDef := AType.Def;
  while Assigned(LTypeDef) and (LTypeDef <> DefObject) do
  begin
    LDef := GetDef(nil, AName, LTypeDef);
    if Assigned(LDef) then
      // the original returned the union as a function even for a field with this name
      Exit(LDef.FunctionPtr);
    LTypeDef := LTypeDef.TypeDef.SuperClass.Def;
  end;
  Result := nil;
end;

function TDoomScriptProgram.AllocFunction(const ADef: TDoomScriptVarDef): TDoomScriptFunction;
begin
  if FFunctions.Count >= DS_MAX_FUNCS then
    raise EDoomScriptCompileError.CreateFmt(SMaxFunctions, [DS_MAX_FUNCS]);
  Result := TDoomScriptFunction.Create;
  Result.Index := FFunctions.Add(Result);
  Result.Def := ADef;
  Result.TypeDef := ADef.TypeDef;
  Result.FileNum := FFileNum;
  Result.Name := ADef.GlobalName;
  ADef.SetFunction(Result);
end;

procedure TDoomScriptProgram.SetEntity(const AName: AnsiString; const AEntityNumber: Integer);
var
  LDef: TDoomScriptVarDef;
begin
  LDef := GetDef(FBuiltinTypes[evEntity], '$' + AName, DefNamespace);
  if Assigned(LDef) and (LDef.Initialized <> diStackVariable) then
    // 0 is reserved for NULL entity
    if AEntityNumber < 0 then
      PInteger(GlobalPtr(LDef.Value, 4))^ := 0
    else
      PInteger(GlobalPtr(LDef.Value, 4))^ := AEntityNumber + 1;
end;

procedure TDoomScriptProgram.BeginCompilation;
var
  LIndex: Integer;
begin
  FreeData;
  try
    // make the first statement a return for a "NULL" function
    LIndex := AllocStatement;
    FStatements[LIndex].Op := OP_RETURN;
    // define the return def
    FReturnDef := AllocDef(FBuiltinTypes[evVector], '<RETURN>', DefNamespace, False);
    // define the return def for strings
    FReturnStringDef := AllocDef(FBuiltinTypes[evString], '<RETURN>', DefNamespace, False);
    // define the sys object
    FSysDef := AllocDef(FBuiltinTypes[evVoid], 'sys', DefNamespace, True);
  except
    on E: EDoomScriptCompileError do
      raise EDoomScriptError.Create(E.Message);
  end;
end;

procedure TDoomScriptProgram.FinishCompilation;
begin
  FTopFunctions := FFunctions.Count;
  FTopStatements := FNumStatements;
  FTopTypes := FTypes.Count;
  FTopDefs := FVarDefs.Count;
  FTopFiles := FFileList.Count;
  if FNumVariables > DS_MAX_GLOBALS then
    raise EDoomScriptMemoryError.CreateFmt(SGlobalOutOfRange, [FNumVariables, 0]);
  FVariableDefaults := Copy(FVariables, 0, FNumVariables);
end;

function TDoomScriptProgram.DefInfo(const ADef: TDoomScriptVarDef; const AInstructionPointer: Integer): AnsiString;
var
  LJumpTo: Integer;
  LJump: PDoomScriptStatement;
  LText: AnsiString;
  LIndex: Integer;
  LChar: Integer;
  LVector: TIdVec3;
begin
  Result := '';
  if ADef.Initialized = diInitializedConstant then
    Result := 'const ';
  case ADef.Kind of
    evJumpOffset:
      begin
        LJumpTo := AInstructionPointer + ADef.Value;
        LJump := GetStatement(LJumpTo);
        Result := Result + AnsiString(Format('address %d [%s(%d)]', [LJumpTo, string(GetFilename(LJump.FileNum)),
          LJump.LineNumber]));
      end;
    evFunction:
      if Assigned(ADef.FunctionPtr) and Assigned(ADef.FunctionPtr.EventDef) then
        Result := Result + 'event ' + ADef.GlobalName
      else
        Result := Result + 'function ' + ADef.GlobalName;
    evField:
      Result := Result + AnsiString(Format('field %d', [ADef.Value]));
    evArgSize:
      Result := Result + AnsiString(Format('args %d', [ADef.Value]));
  else
    Result := Result + ADef.TypeDef.Name + ' ';
    if ADef.Initialized = diInitializedConstant then
      case ADef.Kind of
        evString:
          begin
            Result := Result + '"';
            LText := TDoomScriptMemory.ReadString(GlobalPtr(ADef.Value, DS_MAX_STRING_LEN));
            for LIndex := 1 to Length(LText) do
            begin
              // the character is a signed char in the original
              LChar := ShortInt(Ord(LText[LIndex]));
              if TIdStrings.CharIsPrintable(LChar) then
                Result := Result + LText[LIndex]
              else if LText[LIndex] = #10 then
                Result := Result + '\n'
              else
                Result := Result + '\x' + AnsiString(LowerCase(IntToHex(Cardinal(LChar), 2)));
            end;
            Result := Result + '"';
          end;
        evVector:
          begin
            Move(GlobalPtr(ADef.Value, 12)^, LVector, 12);
            Result := Result + '''' + LVector.ToString + '''';
          end;
        evFloat:
          Result := Result + TIdStrings.FloatToPlainText(PSingle(GlobalPtr(ADef.Value, 4))^);
        evVirtualFunction:
          Result := Result + AnsiString(Format('vtable[ %d ]', [ADef.Value]));
      else
        Result := Result + AnsiString(IntToStr(PInteger(GlobalPtr(ADef.Value, 4))^));
      end
    else if ADef.Initialized = diStackVariable then
      Result := Result + AnsiString(Format('stack[%d]', [ADef.Value]))
    else
      Result := Result + AnsiString(Format('global[%d]', [ADef.Num]));
  end;
end;

function TDoomScriptProgram.DisassembleStatement(const AInstructionPointer: Integer): AnsiString;
var
  LStatement: PDoomScriptStatement;
  LOpName: AnsiString;
begin
  LStatement := GetStatement(AInstructionPointer);
  if LStatement.Op < NUM_OPCODES then
    LOpName := DoomScriptOpcodes[LStatement.Op].OpName
  else
    LOpName := '';
  Result := AnsiString(Format('%20s(%d):'#9'%6d: %15s'#9, [string(GetFilename(LStatement.FileNum)),
    LStatement.LineNumber, AInstructionPointer, string(LOpName)]));
  if Assigned(LStatement.A) then
    Result := Result + #9'a: ' + DefInfo(LStatement.A, AInstructionPointer);
  if Assigned(LStatement.B) then
    Result := Result + #9'b: ' + DefInfo(LStatement.B, AInstructionPointer);
  if Assigned(LStatement.C) then
    Result := Result + #9'c: ' + DefInfo(LStatement.C, AInstructionPointer);
  Result := Result + #10;
end;

function TDoomScriptProgram.DisassembleText: AnsiString;
var
  LIndex: Integer;
  LPointer: Integer;
  LFunction: TDoomScriptFunction;
begin
  Result := '';
  for LIndex := 0 to FFunctions.Count - 1 do
  begin
    LFunction := FFunctions[LIndex];
    if Assigned(LFunction.EventDef) then
      // skip eventdefs
      Continue;
    Result := Result + AnsiString(Format(#10'function %s() %d stack used, %d parms, %d locals {'#10,
      [string(LFunction.Name), LFunction.Locals, LFunction.ParmTotal, LFunction.Locals - LFunction.ParmTotal]));
    for LPointer := 0 to LFunction.NumStatements - 1 do
      Result := Result + DisassembleStatement(LFunction.FirstStatement + LPointer);
    Result := Result + '}'#10;
  end;
end;

procedure TDoomScriptProgram.Disassemble;
var
  LText: AnsiString;
  LData: TBytes;
begin
  LText := DisassembleText;
  SetLength(LData, Length(LText));
  if LText <> '' then
    Move(LText[1], LData[0], Length(LText));
  if Assigned(FFileSystem) then
    FFileSystem.WriteFile(DISASM_FILE, LData);
end;

procedure TDoomScriptProgram.CompileStats;
var
  LIndex: Integer;
begin
  PrintLine('---------- Compile stats ----------'#10);
  if FHost.Developer then
  begin
    PrintLine('Files loaded:'#10);
    for LIndex := 0 to FFileList.Count - 1 do
      PrintLine(Format('   %s'#10, [string(FFileList[LIndex])]));
  end;
  // the byte counts of the original are sizes of its C++ structures: only the counts are reported
  PrintLine(#10'Memory usage:'#10);
  PrintLine(Format('     Strings: %d'#10, [FFileList.Count]));
  PrintLine(Format('  Statements: %d'#10, [FNumStatements]));
  PrintLine(Format('   Functions: %d'#10, [FFunctions.Count]));
  PrintLine(Format('   Variables: %d bytes'#10, [FNumVariables]));
end;

function TDoomScriptProgram.CompileText(const ASource, AText: AnsiString; const AConsole: Boolean): Boolean;
var
  LIndex: Integer;
  LDef: TDoomScriptVarDef;
begin
  if not Assigned(FCompile) then
    raise EDoomScriptError.Create(SNoCompiler);
  // a full os path for GetFilenum, which converts the names that come from the parser
  FFileNum := GetFilenum(FHost.RelativePathToOSPath(ASource));
  try
    FCompile(AText, FFileName, AConsole);
    // check to make sure all functions prototyped have code
    for LIndex := 0 to FVarDefs.Count - 1 do
    begin
      LDef := FVarDefs[LIndex];
      if (LDef.Kind = evFunction) and ((LDef.Scope.Kind = evNamespace) or LDef.Scope.TypeDef.IsObject) then
        if Assigned(LDef.FunctionPtr) and (not Assigned(LDef.FunctionPtr.EventDef)) and
          (LDef.FunctionPtr.FirstStatement = 0) then
          raise EDoomScriptCompileError.CreateFmt(SNotDefined, [string(LDef.GlobalName)]);
    end;
  except
    on E: EDoomScriptCompileError do
    begin
      if AConsole then
      begin
        PrintLine(E.Message + #10);
        Exit(False);
      end;
      raise EDoomScriptError.Create(E.Message + #10);
    end;
  end;
  if not AConsole then
    CompileStats;
  Result := True;
end;

function TDoomScriptProgram.CompileFunction(const AFunctionName, AText: AnsiString): TDoomScriptFunction;
var
  LResult: Boolean;
begin
  LResult := CompileText(AFunctionName, AText, False);
  if FHost.Disassemble then
    Disassemble;
  if not LResult then
    raise EDoomScriptError.Create(SCompileFailed);
  Result := FindFunction(AFunctionName);
end;

procedure TDoomScriptProgram.CompileFile(const AFileName: AnsiString);
var
  LFile: TIdLibFileData;
  LText: AnsiString;
begin
  if (not Assigned(FFileSystem)) or not FFileSystem.TryReadFile(AFileName, False, LFile) then
    raise EDoomScriptError.CreateFmt(SCouldNotLoad, [string(AFileName)]);
  SetLength(LText, Length(LFile.Data));
  if LText <> '' then
    Move(LFile.Data[0], LText[1], Length(LText));
  CompileText(AFileName, LText, False);
  if FHost.Disassemble then
    Disassemble;
end;

procedure TDoomScriptProgram.FreeData;
var
  LIndex: Integer;
begin
  // free the defs
  for LIndex := FVarDefs.Count - 1 downto 0 do
    FVarDefs[LIndex].Free;
  FVarDefs.Clear;
  FVarDefNames.Clear;
  FReturnDef := nil;
  FReturnStringDef := nil;
  FSysDef := nil;
  // free any special types we have created
  if Assigned(FReleaseObjects) then
    FReleaseObjects(0);
  FTypes.Clear;
  FFileNum := 0;
  FNumVariables := 0;
  FillChar(FVariables[0], DS_MAX_GLOBALS, 0);
  FFileName := '';
  FFileList.Clear;
  FNumStatements := 0;
  FFunctions.Clear;
  FRemovedFunctions.Clear;
  FVariableDefaults := nil;
  FTopFunctions := 0;
  FTopStatements := 0;
  FTopTypes := 0;
  FTopDefs := 0;
  FTopFiles := 0;
  // the built-in types the compiler changes while it works
  FBuiltinTypes[evPointer].SetPointerType(nil);
end;

procedure TDoomScriptProgram.Startup(const ADefaultScript: AnsiString);
begin
  PrintLine('Initializing scripts'#10);
  // make sure all data is freed up
  if Assigned(FRestartThreads) then
    FRestartThreads();
  // get ready for loading scripts
  BeginCompilation;
  // load the default script
  if ADefaultScript <> '' then
    CompileFile(ADefaultScript);
  FinishCompilation;
end;

procedure TDoomScriptProgram.Save(const AStream: TStream);
var
  LIndex: Integer;
begin
  TDoomScriptSaveStream.WriteInt(AStream, FFileList.Count - FTopFiles);
  for LIndex := FTopFiles to FFileList.Count - 1 do
    TDoomScriptSaveStream.WriteString(AStream, FFileList[LIndex]);
  for LIndex := 0 to Length(FVariableDefaults) - 1 do
    if FVariables[LIndex] <> FVariableDefaults[LIndex] then
    begin
      TDoomScriptSaveStream.WriteInt(AStream, LIndex);
      TDoomScriptSaveStream.WriteByte(AStream, FVariables[LIndex]);
    end;
  // mark the end of the diff with default variables with -1
  TDoomScriptSaveStream.WriteInt(AStream, -1);
  TDoomScriptSaveStream.WriteInt(AStream, FNumVariables);
  for LIndex := Length(FVariableDefaults) to FNumVariables - 1 do
    TDoomScriptSaveStream.WriteByte(AStream, GlobalPtr(LIndex, 1)^);
  TDoomScriptSaveStream.WriteInt(AStream, CalculateChecksum);
end;

function TDoomScriptProgram.Restore(const AStream: TStream): Boolean;
var
  LIndex: Integer;
  LCount: Integer;
  LVariable: Integer;
  LSavedChecksum: Integer;
begin
  LCount := TDoomScriptSaveStream.ReadInt(AStream);
  for LIndex := 0 to LCount - 1 do
    CompileFile(TDoomScriptSaveStream.ReadString(AStream));
  LVariable := TDoomScriptSaveStream.ReadInt(AStream);
  while LVariable >= 0 do
  begin
    if LVariable >= DS_MAX_GLOBALS then
      raise EDoomScriptMemoryError.CreateFmt(SRestoreIndex, [LVariable]);
    FVariables[LVariable] := TDoomScriptSaveStream.ReadByte(AStream);
    LVariable := TDoomScriptSaveStream.ReadInt(AStream);
  end;
  LCount := TDoomScriptSaveStream.ReadInt(AStream);
  if LCount > DS_MAX_GLOBALS then
    raise EDoomScriptMemoryError.CreateFmt(SRestoreIndex, [LCount]);
  // as in the original, the number of variables of the program is not changed
  for LIndex := Length(FVariableDefaults) to LCount - 1 do
    FVariables[LIndex] := TDoomScriptSaveStream.ReadByte(AStream);
  LSavedChecksum := TDoomScriptSaveStream.ReadInt(AStream);
  Result := LSavedChecksum = CalculateChecksum;
end;

function TDoomScriptProgram.CalculateChecksum: Integer;
type
  // statementBlock_t of the original, with its padding after op
  TStatementBlock = packed record
    Op: Word;
    Padding: Word;
    A: Integer;
    B: Integer;
    C: Integer;
    LineNumber: Word;
    FileNum: Word;
  end;
var
  LList: TArray<TStatementBlock>;
  LIndex: Integer;

  function DefNum(const ADef: TDoomScriptVarDef): Integer;
  begin
    if Assigned(ADef) then
      Result := ADef.Num
    else
      Result := -1;
  end;

begin
  SetLength(LList, FNumStatements);
  for LIndex := 0 to FNumStatements - 1 do
  begin
    LList[LIndex].Op := FStatements[LIndex].Op;
    LList[LIndex].Padding := 0;
    LList[LIndex].A := DefNum(FStatements[LIndex].A);
    LList[LIndex].B := DefNum(FStatements[LIndex].B);
    LList[LIndex].C := DefNum(FStatements[LIndex].C);
    LList[LIndex].LineNumber := FStatements[LIndex].LineNumber;
    LList[LIndex].FileNum := FStatements[LIndex].FileNum;
  end;
  if FNumStatements = 0 then
    Result := Integer(TIdMd4.BlockChecksum(LIndex, 0))
  else
    Result := Integer(TIdMd4.BlockChecksum(LList[0], FNumStatements * SizeOf(TStatementBlock)));
end;

procedure TDoomScriptProgram.Restart;
var
  LIndex: Integer;
  LFunction: TDoomScriptFunction;
begin
  if Assigned(FRestartThreads) then
    FRestartThreads();
  // since there may have been a script loaded by the map or the user may have typed "script" from the
  // console, free up any types and vardefs that have been allocated after the initial startup
  if Assigned(FReleaseObjects) then
    FReleaseObjects(FTopTypes);
  while FTypes.Count > FTopTypes do
    FTypes.Delete(FTypes.Count - 1);
  for LIndex := FVarDefs.Count - 1 downto FTopDefs do
  begin
    FVarDefs[LIndex].Free;
    FVarDefs.Delete(LIndex);
  end;
  while FFunctions.Count > FTopFunctions do
  begin
    LFunction := FFunctions.Extract(FFunctions[FFunctions.Count - 1]);
    LFunction.Clear;
    FRemovedFunctions.Add(LFunction);
  end;
  if FNumStatements > FTopStatements then
    FNumStatements := FTopStatements;
  while FFileList.Count > FTopFiles do
    FFileList.Delete(FFileList.Count - 1);
  FFileName := '';
  // reset the variables to their default values
  FNumVariables := Length(FVariableDefaults);
  if FNumVariables > 0 then
    Move(FVariableDefaults[0], FVariables[0], FNumVariables);
end;

function TDoomScriptProgram.ReturnPtr(const ASize: Integer): PByte;
begin
  if not Assigned(FReturnDef) then
    raise EDoomScriptError.Create(SNotStarted);
  Result := GlobalPtr(FReturnDef.Value, ASize);
end;

function TDoomScriptProgram.GetReturnedInteger: Integer;
begin
  Result := PInteger(ReturnPtr(4))^;
end;

procedure TDoomScriptProgram.ReturnFloat(const AValue: Single);
begin
  PSingle(ReturnPtr(4))^ := AValue;
end;

procedure TDoomScriptProgram.ReturnInteger(const AValue: Integer);
begin
  PInteger(ReturnPtr(4))^ := AValue;
end;

procedure TDoomScriptProgram.ReturnVector(const AValue: TIdVec3);
begin
  Move(AValue, ReturnPtr(12)^, 12);
end;

procedure TDoomScriptProgram.ReturnString(const AText: AnsiString);
begin
  if not Assigned(FReturnStringDef) then
    raise EDoomScriptError.Create(SNotStarted);
  TDoomScriptMemory.CopyString(GlobalPtr(FReturnStringDef.Value, DS_MAX_STRING_LEN), AText);
end;

procedure TDoomScriptProgram.ReturnEntity(const AEntityNumber: Integer);
begin
  if AEntityNumber >= 0 then
    ReturnInteger(AEntityNumber + 1)
  else
    ReturnInteger(0);
end;

end.

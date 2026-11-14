{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom script (id Tech 4) - types, definitions and functions of   }
{  a program (idTypeDef, idVarDef, idVarDefName, function_t, statement_t)      }
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
unit DelphiDoom.DoomScript.Defs;

{$Q-}
{$R-}

interface

// The four classes of this unit refer to each other (a type has a def and functions, a def has a type, a
// scope and a function, a function has a def and a type): Delphi needs mutually recursive classes in one
// unit, so this is the one place of the library with more than one class.

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.DoomScript.Types, DelphiDoom.DoomScript.EventDef;

type
  TDoomScriptVarDef = class;
  TDoomScriptTypeDef = class;

  /// <summary>function_t: a script function, or the script side of an event of the host</summary>
  TDoomScriptFunction = class
  public
    Name: AnsiString;
    /// <summary>The event this function stands for; nil for a function written in script</summary>
    EventDef: TDoomScriptEventDef;
    Def: TDoomScriptVarDef;
    TypeDef: TDoomScriptTypeDef;
    FirstStatement: Integer;
    NumStatements: Integer;
    ParmTotal: Integer;
    /// <summary>Total bytes of parameters and locals</summary>
    Locals: Integer;
    FileNum: Integer;
    ParmSize: TArray<Integer>;
    /// <summary>The position in the function table of the program (idProgram::GetFunctionIndex)</summary>
    Index: Integer;
    procedure Clear;
  end;

  /// <summary>
  ///   idTypeDef: a script type. Simple types are owned by the program as built-ins; function, field and
  ///   object types are allocated while compiling.
  /// </summary>
  TDoomScriptTypeDef = class
  strict private
    FKind: TDoomScriptEType;
    FName: AnsiString;
    FSize: Integer;
    FAuxType: TDoomScriptTypeDef;
    FParmTypes: TList<TDoomScriptTypeDef>;
    FParmNames: TList<AnsiString>;
    FFunctions: TList<TDoomScriptFunction>;
    procedure CheckParm(const AIndex: Integer);
  public
    /// <summary>A def that points to this type</summary>
    Def: TDoomScriptVarDef;
    constructor Create(const AKind: TDoomScriptEType; const ADef: TDoomScriptVarDef; const AName: AnsiString;
      const ASize: Integer; const AAux: TDoomScriptTypeDef);
    constructor CreateCopy(const AOther: TDoomScriptTypeDef);
    destructor Destroy; override;
    procedure Assign(const AOther: TDoomScriptTypeDef);
    /// <summary>True if <c>ABaseType</c> is this type or an ancestor of this object type</summary>
    function Inherits(const ABaseType: TDoomScriptTypeDef): Boolean;
    /// <summary>True for an object type (<c>Inherits( &amp;type_object )</c> of the original)</summary>
    function IsObject: Boolean; inline;
    function MatchesType(const AOther: TDoomScriptTypeDef): Boolean;
    function MatchesVirtualFunction(const AOther: TDoomScriptTypeDef): Boolean;
    procedure AddFunctionParm(const AParmType: TDoomScriptTypeDef; const AName: AnsiString);
    /// <summary>Adds a field to an object type and grows the object; an object field takes 4 bytes</summary>
    procedure AddField(const AFieldType: TDoomScriptTypeDef; const AName: AnsiString);
    function SuperClass: TDoomScriptTypeDef;
    function ReturnType: TDoomScriptTypeDef;
    procedure SetReturnType(const AType: TDoomScriptTypeDef);
    function FieldType: TDoomScriptTypeDef;
    procedure SetFieldType(const AType: TDoomScriptTypeDef);
    function PointerType: TDoomScriptTypeDef;
    procedure SetPointerType(const AType: TDoomScriptTypeDef);
    function NumParameters: Integer;
    function GetParmType(const AIndex: Integer): TDoomScriptTypeDef;
    function GetParmName(const AIndex: Integer): AnsiString;
    function NumFunctions: Integer;
    /// <summary>-1 if the function is not in the virtual table of this object type</summary>
    function GetFunctionNumber(const AFunction: TDoomScriptFunction): Integer;
    function GetFunction(const AIndex: Integer): TDoomScriptFunction;
    /// <summary>Adds a method, replacing the inherited one with the same name and matching signature</summary>
    procedure AddFunction(const AFunction: TDoomScriptFunction);
    property Kind: TDoomScriptEType read FKind;
    property Name: AnsiString read FName write FName;
    property Size: Integer read FSize;
    /// <summary>The raw auxiliary type (return, field, pointer or super type), without the kind check</summary>
    property AuxType: TDoomScriptTypeDef read FAuxType;
  end;

  /// <summary>idVarDefName: the defs that share a name, most recent first</summary>
  TDoomScriptVarDefName = class
  strict private
    FName: AnsiString;
    FDefs: TDoomScriptVarDef;
  public
    constructor Create(const AName: AnsiString);
    procedure AddDef(const ADef: TDoomScriptVarDef);
    procedure RemoveDef(const ADef: TDoomScriptVarDef);
    property Name: AnsiString read FName;
    property Defs: TDoomScriptVarDef read FDefs;
  end;

  /// <summary>
  ///   idVarDef: the name, type and location of a variable, constant, function, object type or namespace.
  ///   <c>Value</c> is what the union <c>varEval_t</c> held, never a pointer: the offset in the global
  ///   memory for a global, the offset from the stack base for a local (<c>diStackVariable</c>), the
  ///   offset in the object for a field, or the number itself for a jump offset, an argument size and a
  ///   virtual function index. A function def has its function in <c>FunctionPtr</c>.
  /// </summary>
  TDoomScriptVarDef = class
  private
    FName: TDoomScriptVarDefName;
    FNext: TDoomScriptVarDef;
  strict private
    FTypeDef: TDoomScriptTypeDef;
    FBuiltin: Boolean;
  public
    Num: Integer;
    Value: Integer;
    FunctionPtr: TDoomScriptFunction;
    /// <summary>The function, namespace or object the def was defined in</summary>
    Scope: TDoomScriptVarDef;
    NumUsers: Integer;
    Initialized: TDoomScriptInitialized;
    constructor Create(const ATypeDef: TDoomScriptTypeDef; const ABuiltin: Boolean = False);
    destructor Destroy; override;
    /// <summary>Raises EDoomScriptError for a built-in def, which has no name (a crash in the original)</summary>
    function Name: AnsiString;
    function GlobalName: AnsiString;
    function Kind: TDoomScriptEType; inline;
    function DepthOfScope(const AOtherScope: TDoomScriptVarDef): Integer;
    procedure SetFunction(const AFunction: TDoomScriptFunction);
    property TypeDef: TDoomScriptTypeDef read FTypeDef write FTypeDef;
    /// <summary>The next def with the same name</summary>
    property Next: TDoomScriptVarDef read FNext;
    /// <summary>True for the defs of the simple types (def_void, def_namespace...)</summary>
    property Builtin: Boolean read FBuiltin;
  end;

  /// <summary>statement_t</summary>
  TDoomScriptStatement = record
    Op: Word;
    A: TDoomScriptVarDef;
    B: TDoomScriptVarDef;
    C: TDoomScriptVarDef;
    LineNumber: Word;
    FileNum: Word;
  end;
  PDoomScriptStatement = ^TDoomScriptStatement;

implementation

const
  SAddParmNonFunction = 'idTypeDef::AddFunctionParm : tried to add parameter on non-function type';
  SAddFieldNonObject = 'idTypeDef::AddField : tried to add field to non-object type';
  SSuperClassNonObject = 'idTypeDef::SuperClass : tried to get superclass of a non-object type';
  SReturnTypeNonFunction = 'idTypeDef::ReturnType: tried to get return type on non-function type';
  SSetReturnTypeNonFunction = 'idTypeDef::SetReturnType: tried to set return type on non-function type';
  SFieldTypeNonField = 'idTypeDef::FieldType: tried to get field type on non-field type';
  SSetFieldTypeNonField = 'idTypeDef::SetFieldType: tried to set return type on non-function type';
  SPointerTypeNonPointer = 'idTypeDef::PointerType: tried to get pointer type on non-pointer';
  SSetPointerTypeNonPointer = 'idTypeDef::SetPointerType: tried to set type on non-pointer';
  SParmOutOfRange = 'idTypeDef: parameter %d out of range in type ''%s''';
  SFunctionOutOfRange = 'idTypeDef: function %d out of range in type ''%s''';
  SUnnamedDef = 'idVarDef: a built-in definition has no name';
  SObjectTooLarge = 'object type ''%s'' is larger than %d bytes';

{ TDoomScriptFunction }

procedure TDoomScriptFunction.Clear;
begin
  EventDef := nil;
  Def := nil;
  TypeDef := nil;
  FirstStatement := 0;
  NumStatements := 0;
  ParmTotal := 0;
  Locals := 0;
  FileNum := 0;
  Name := '';
  ParmSize := nil;
end;

{ TDoomScriptTypeDef }

constructor TDoomScriptTypeDef.Create(const AKind: TDoomScriptEType; const ADef: TDoomScriptVarDef;
  const AName: AnsiString; const ASize: Integer; const AAux: TDoomScriptTypeDef);
begin
  inherited Create;
  FParmTypes := TList<TDoomScriptTypeDef>.Create;
  FParmNames := TList<AnsiString>.Create;
  FFunctions := TList<TDoomScriptFunction>.Create;
  FKind := AKind;
  Def := ADef;
  FName := AName;
  FSize := ASize;
  FAuxType := AAux;
end;

constructor TDoomScriptTypeDef.CreateCopy(const AOther: TDoomScriptTypeDef);
begin
  Create(AOther.FKind, AOther.Def, AOther.FName, AOther.FSize, AOther.FAuxType);
  Assign(AOther);
end;

destructor TDoomScriptTypeDef.Destroy;
begin
  FParmTypes.Free;
  FParmNames.Free;
  FFunctions.Free;
  inherited;
end;

procedure TDoomScriptTypeDef.Assign(const AOther: TDoomScriptTypeDef);
begin
  FKind := AOther.FKind;
  Def := AOther.Def;
  FName := AOther.FName;
  FSize := AOther.FSize;
  FAuxType := AOther.FAuxType;
  FParmTypes.Clear;
  FParmTypes.AddRange(AOther.FParmTypes);
  FParmNames.Clear;
  FParmNames.AddRange(AOther.FParmNames);
  FFunctions.Clear;
  FFunctions.AddRange(AOther.FFunctions);
end;

function TDoomScriptTypeDef.IsObject: Boolean;
begin
  Result := FKind = evObject;
end;

function TDoomScriptTypeDef.Inherits(const ABaseType: TDoomScriptTypeDef): Boolean;
var
  LSuper: TDoomScriptTypeDef;
begin
  if FKind <> evObject then
    Exit(False);
  if Self = ABaseType then
    Exit(True);
  LSuper := FAuxType;
  while Assigned(LSuper) do
  begin
    if LSuper = ABaseType then
      Exit(True);
    LSuper := LSuper.FAuxType;
  end;
  Result := False;
end;

function TDoomScriptTypeDef.MatchesType(const AOther: TDoomScriptTypeDef): Boolean;
var
  LIndex: Integer;
begin
  if Self = AOther then
    Exit(True);
  if (FKind <> AOther.FKind) or (FAuxType <> AOther.FAuxType) then
    Exit(False);
  if FParmTypes.Count <> AOther.FParmTypes.Count then
    Exit(False);
  for LIndex := 0 to AOther.FParmTypes.Count - 1 do
    if FParmTypes[LIndex] <> AOther.FParmTypes[LIndex] then
      Exit(False);
  Result := True;
end;

function TDoomScriptTypeDef.MatchesVirtualFunction(const AOther: TDoomScriptTypeDef): Boolean;
var
  LIndex: Integer;
begin
  if Self = AOther then
    Exit(True);
  if (FKind <> AOther.FKind) or (FAuxType <> AOther.FAuxType) then
    Exit(False);
  if FParmTypes.Count <> AOther.FParmTypes.Count then
    Exit(False);
  if FParmTypes.Count > 0 then
    if not FParmTypes[0].Inherits(AOther.FParmTypes[0]) then
      Exit(False);
  for LIndex := 1 to AOther.FParmTypes.Count - 1 do
    if FParmTypes[LIndex] <> AOther.FParmTypes[LIndex] then
      Exit(False);
  Result := True;
end;

procedure TDoomScriptTypeDef.AddFunctionParm(const AParmType: TDoomScriptTypeDef; const AName: AnsiString);
begin
  if FKind <> evFunction then
    raise EDoomScriptCompileError.Create(SAddParmNonFunction);
  FParmTypes.Add(AParmType);
  FParmNames.Add(AName);
end;

procedure TDoomScriptTypeDef.AddField(const AFieldType: TDoomScriptTypeDef; const AName: AnsiString);
begin
  if FKind <> evObject then
    raise EDoomScriptCompileError.Create(SAddFieldNonObject);
  FParmTypes.Add(AFieldType);
  FParmNames.Add(AName);
  if AFieldType.FieldType.IsObject then
    Inc(FSize, 4)
  else
    Inc(FSize, AFieldType.FieldType.Size);
  // not in the original: the offset of a field must fit in the handle of a pointer
  if FSize > DS_MAX_OBJECT_SIZE then
    raise EDoomScriptCompileError.CreateFmt(SObjectTooLarge, [string(FName), DS_MAX_OBJECT_SIZE]);
end;

function TDoomScriptTypeDef.SuperClass: TDoomScriptTypeDef;
begin
  if FKind <> evObject then
    raise EDoomScriptCompileError.Create(SSuperClassNonObject);
  Result := FAuxType;
end;

function TDoomScriptTypeDef.ReturnType: TDoomScriptTypeDef;
begin
  if FKind <> evFunction then
    raise EDoomScriptCompileError.Create(SReturnTypeNonFunction);
  Result := FAuxType;
end;

procedure TDoomScriptTypeDef.SetReturnType(const AType: TDoomScriptTypeDef);
begin
  if FKind <> evFunction then
    raise EDoomScriptCompileError.Create(SSetReturnTypeNonFunction);
  FAuxType := AType;
end;

function TDoomScriptTypeDef.FieldType: TDoomScriptTypeDef;
begin
  if FKind <> evField then
    raise EDoomScriptCompileError.Create(SFieldTypeNonField);
  Result := FAuxType;
end;

procedure TDoomScriptTypeDef.SetFieldType(const AType: TDoomScriptTypeDef);
begin
  if FKind <> evField then
    raise EDoomScriptCompileError.Create(SSetFieldTypeNonField);
  FAuxType := AType;
end;

function TDoomScriptTypeDef.PointerType: TDoomScriptTypeDef;
begin
  if FKind <> evPointer then
    raise EDoomScriptCompileError.Create(SPointerTypeNonPointer);
  Result := FAuxType;
end;

procedure TDoomScriptTypeDef.SetPointerType(const AType: TDoomScriptTypeDef);
begin
  if FKind <> evPointer then
    raise EDoomScriptCompileError.Create(SSetPointerTypeNonPointer);
  FAuxType := AType;
end;

function TDoomScriptTypeDef.NumParameters: Integer;
begin
  Result := FParmTypes.Count;
end;

procedure TDoomScriptTypeDef.CheckParm(const AIndex: Integer);
begin
  if (AIndex < 0) or (AIndex >= FParmTypes.Count) then
    raise EDoomScriptMemoryError.CreateFmt(SParmOutOfRange, [AIndex, string(FName)]);
end;

function TDoomScriptTypeDef.GetParmType(const AIndex: Integer): TDoomScriptTypeDef;
begin
  CheckParm(AIndex);
  Result := FParmTypes[AIndex];
end;

function TDoomScriptTypeDef.GetParmName(const AIndex: Integer): AnsiString;
begin
  CheckParm(AIndex);
  Result := FParmNames[AIndex];
end;

function TDoomScriptTypeDef.NumFunctions: Integer;
begin
  Result := FFunctions.Count;
end;

function TDoomScriptTypeDef.GetFunctionNumber(const AFunction: TDoomScriptFunction): Integer;
begin
  Result := FFunctions.IndexOf(AFunction);
end;

function TDoomScriptTypeDef.GetFunction(const AIndex: Integer): TDoomScriptFunction;
begin
  if (AIndex < 0) or (AIndex >= FFunctions.Count) then
    raise EDoomScriptMemoryError.CreateFmt(SFunctionOutOfRange, [AIndex, string(FName)]);
  Result := FFunctions[AIndex];
end;

procedure TDoomScriptTypeDef.AddFunction(const AFunction: TDoomScriptFunction);
var
  LIndex: Integer;
begin
  for LIndex := 0 to FFunctions.Count - 1 do
    if Assigned(FFunctions[LIndex].Def) and (FFunctions[LIndex].Def.Name = AFunction.Def.Name) then
      if AFunction.Def.TypeDef.MatchesVirtualFunction(FFunctions[LIndex].Def.TypeDef) then
      begin
        FFunctions[LIndex] := AFunction;
        Exit;
      end;
  FFunctions.Add(AFunction);
end;

{ TDoomScriptVarDefName }

constructor TDoomScriptVarDefName.Create(const AName: AnsiString);
begin
  inherited Create;
  FName := AName;
end;

procedure TDoomScriptVarDefName.AddDef(const ADef: TDoomScriptVarDef);
begin
  ADef.FName := Self;
  ADef.FNext := FDefs;
  FDefs := ADef;
end;

procedure TDoomScriptVarDefName.RemoveDef(const ADef: TDoomScriptVarDef);
var
  LDef: TDoomScriptVarDef;
begin
  if FDefs = ADef then
    FDefs := ADef.FNext
  else
  begin
    LDef := FDefs;
    while Assigned(LDef) and Assigned(LDef.FNext) do
    begin
      if LDef.FNext = ADef then
      begin
        LDef.FNext := ADef.FNext;
        Break;
      end;
      LDef := LDef.FNext;
    end;
  end;
  ADef.FNext := nil;
  ADef.FName := nil;
end;

{ TDoomScriptVarDef }

constructor TDoomScriptVarDef.Create(const ATypeDef: TDoomScriptTypeDef; const ABuiltin: Boolean);
begin
  inherited Create;
  FTypeDef := ATypeDef;
  FBuiltin := ABuiltin;
  Initialized := diUninitialized;
end;

destructor TDoomScriptVarDef.Destroy;
begin
  if Assigned(FName) then
    FName.RemoveDef(Self);
  inherited;
end;

function TDoomScriptVarDef.Name: AnsiString;
begin
  if not Assigned(FName) then
    raise EDoomScriptError.Create(SUnnamedDef);
  Result := FName.Name;
end;

function TDoomScriptVarDef.GlobalName: AnsiString;
begin
  // scope != &def_namespace
  if Assigned(Scope) and not (Scope.Builtin and (Scope.Kind = evNamespace)) then
    Result := Scope.GlobalName + '::' + Name
  else
    Result := Name;
end;

function TDoomScriptVarDef.Kind: TDoomScriptEType;
begin
  if Assigned(FTypeDef) then
    Result := FTypeDef.Kind
  else
    Result := evVoid;
end;

function TDoomScriptVarDef.DepthOfScope(const AOtherScope: TDoomScriptVarDef): Integer;
var
  LDef: TDoomScriptVarDef;
begin
  Result := 1;
  LDef := AOtherScope;
  while Assigned(LDef) do
  begin
    if LDef = Scope then
      Exit;
    Inc(Result);
    LDef := LDef.Scope;
  end;
  Result := 0;
end;

procedure TDoomScriptVarDef.SetFunction(const AFunction: TDoomScriptFunction);
begin
  Initialized := diInitializedConstant;
  FunctionPtr := AFunction;
end;

end.

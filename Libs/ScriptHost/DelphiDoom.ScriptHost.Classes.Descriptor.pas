{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - the table of the members of a class of scripts    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.Classes.Descriptor;

interface

uses
  System.Generics.Collections,
  ps_defs,
  ps_compiler,
  ps_runtime,
  DelphiDoom.ScriptHost.Classes.Intf,
  DelphiDoom.ScriptHost.Types;

type
  /// <summary>
  ///   The members of one class that scripts see, as data: the same list registers the class in
  ///   the compiler and in the interpreter
  /// </summary>
  TScriptClassDescriptor = class(TInterfacedObject, IScriptClassDescriptor)
  strict private
    type
      TMemberKind = (mkProperty, mkDefaultProperty, mkMethod, mkConstructor);

      TMember = record
        Kind: TMemberKind;
        Name: string;
        Declaration: string;
        PropertyType: string;
        Access: TPSPropType;
        Reader: Pointer;
        Writer: Pointer;
        Code: Pointer;
        CompilerGames: TScriptGameSet;
        RuntimeGames: TScriptGameSet;
      end;

      TVariable = record
        Name: string;
        Instance: TScriptInstanceProvider;
      end;
  strict private
    FScriptName: string;
    FMembers: TList<TMember>;
    FVariables: TList<TVariable>;
    procedure AddMember(const AMember: TMember);
  public
    constructor Create(const AScriptName: string);
    destructor Destroy; override;
    function ScriptName: string;
    procedure AddProperty(const AName, AType: string; const AAccess: TPSPropType;
      const AReader, AWriter: Pointer;
      const AGames: TScriptGameSet = [sgDoom, sgHeretic, sgHexen, sgStrife]); overload;
    procedure AddProperty(const AName, AType: string; const AAccess: TPSPropType;
      const AReader, AWriter: Pointer; const ACompilerGames, ARuntimeGames: TScriptGameSet); overload;
    procedure AddRuntimeProperty(const AName: string; const AReader, AWriter: Pointer);
    procedure AddDefaultProperty(const AName: string);
    procedure AddMethod(const ADeclaration, AName: string; const ACode: Pointer);
    procedure AddConstructor(const ACode: Pointer);
    procedure AddVariable(const AName: string; const AInstance: TScriptInstanceProvider);
    function CompilerProperties(const AGame: TScriptGame): TArray<string>;
    function RuntimeProperties(const AGame: TScriptGame): TArray<string>;
    procedure RegisterCompiler(const ACompiler: TPSPascalCompiler; const AClass: TPSCompileTimeClass;
      const AGame: TScriptGame);
    procedure RegisterRuntime(const AClass: TPSRuntimeClass; const AGame: TScriptGame);
    procedure BindVariables(const AExec: TPSExec);
  end;

implementation

uses
  System.SysUtils;

{ TScriptClassDescriptor }

constructor TScriptClassDescriptor.Create(const AScriptName: string);
begin
  inherited Create;
  if AScriptName = '' then
    raise EScriptHostException.Create(SScriptClassWithoutName);
  FScriptName := AScriptName;
  FMembers := TList<TMember>.Create;
  FVariables := TList<TVariable>.Create;
end;

destructor TScriptClassDescriptor.Destroy;
begin
  FVariables.Free;
  FMembers.Free;
  inherited Destroy;
end;

function TScriptClassDescriptor.ScriptName: string;
begin
  Result := FScriptName;
end;

procedure TScriptClassDescriptor.AddMember(const AMember: TMember);
begin
  FMembers.Add(AMember);
end;

procedure TScriptClassDescriptor.AddProperty(const AName, AType: string;
  const AAccess: TPSPropType; const AReader, AWriter: Pointer; const AGames: TScriptGameSet);
begin
  AddProperty(AName, AType, AAccess, AReader, AWriter, AGames, AGames);
end;

procedure TScriptClassDescriptor.AddProperty(const AName, AType: string;
  const AAccess: TPSPropType; const AReader, AWriter: Pointer; const ACompilerGames,
  ARuntimeGames: TScriptGameSet);
var
  LMember: TMember;
begin
  LMember := Default(TMember);
  LMember.Kind := mkProperty;
  LMember.Name := AName;
  LMember.PropertyType := AType;
  LMember.Access := AAccess;
  LMember.Reader := AReader;
  LMember.Writer := AWriter;
  LMember.CompilerGames := ACompilerGames;
  LMember.RuntimeGames := ARuntimeGames;
  AddMember(LMember);
end;

procedure TScriptClassDescriptor.AddRuntimeProperty(const AName: string; const AReader,
  AWriter: Pointer);
begin
  AddProperty(AName, '', iptRW, AReader, AWriter, [], SCRIPT_ALL_GAMES);
end;

procedure TScriptClassDescriptor.AddDefaultProperty(const AName: string);
var
  LMember: TMember;
begin
  LMember := Default(TMember);
  LMember.Kind := mkDefaultProperty;
  LMember.Name := AName;
  LMember.CompilerGames := SCRIPT_ALL_GAMES;
  AddMember(LMember);
end;

procedure TScriptClassDescriptor.AddMethod(const ADeclaration, AName: string; const ACode: Pointer);
var
  LMember: TMember;
begin
  LMember := Default(TMember);
  LMember.Kind := mkMethod;
  LMember.Name := AName;
  LMember.Declaration := ADeclaration;
  LMember.Code := ACode;
  LMember.CompilerGames := SCRIPT_ALL_GAMES;
  LMember.RuntimeGames := SCRIPT_ALL_GAMES;
  AddMember(LMember);
end;

procedure TScriptClassDescriptor.AddConstructor(const ACode: Pointer);
var
  LMember: TMember;
begin
  LMember := Default(TMember);
  LMember.Kind := mkConstructor;
  LMember.Name := 'Create';
  LMember.Declaration := 'Constructor Create';
  LMember.Code := ACode;
  LMember.CompilerGames := SCRIPT_ALL_GAMES;
  LMember.RuntimeGames := SCRIPT_ALL_GAMES;
  AddMember(LMember);
end;

procedure TScriptClassDescriptor.AddVariable(const AName: string;
  const AInstance: TScriptInstanceProvider);
var
  LVariable: TVariable;
begin
  if not Assigned(AInstance) then
    raise EArgumentNilException.Create('AInstance');
  LVariable.Name := AName;
  LVariable.Instance := AInstance;
  FVariables.Add(LVariable);
end;

function TScriptClassDescriptor.CompilerProperties(const AGame: TScriptGame): TArray<string>;
var
  LMember: TMember;
  LNames: TList<string>;
begin
  LNames := TList<string>.Create;
  try
    for LMember in FMembers do
      if (LMember.Kind = mkProperty) and (AGame in LMember.CompilerGames) then
        LNames.Add(LMember.Name);
    Result := LNames.ToArray;
  finally
    LNames.Free;
  end;
end;

function TScriptClassDescriptor.RuntimeProperties(const AGame: TScriptGame): TArray<string>;
var
  LMember: TMember;
  LNames: TList<string>;
begin
  LNames := TList<string>.Create;
  try
    for LMember in FMembers do
      if (LMember.Kind = mkProperty) and (AGame in LMember.RuntimeGames) then
        LNames.Add(LMember.Name);
    Result := LNames.ToArray;
  finally
    LNames.Free;
  end;
end;

procedure TScriptClassDescriptor.RegisterCompiler(const ACompiler: TPSPascalCompiler;
  const AClass: TPSCompileTimeClass; const AGame: TScriptGame);
var
  LMember: TMember;
  LVariable: TVariable;
begin
  for LMember in FMembers do
  begin
    if not (AGame in LMember.CompilerGames) then
      Continue;
    case LMember.Kind of
      mkProperty:
        AClass.RegisterProperty(TbtString(LMember.Name), TbtString(LMember.PropertyType), LMember.Access);
      mkDefaultProperty:
        AClass.SetDefaultPropery(TbtString(LMember.Name));
      mkMethod, mkConstructor:
        AClass.RegisterMethod(TbtString(LMember.Declaration));
    end;
  end;
  for LVariable in FVariables do
    AddImportedClassVariable(ACompiler, TbtString(LVariable.Name), TbtString(FScriptName));
end;

procedure TScriptClassDescriptor.RegisterRuntime(const AClass: TPSRuntimeClass;
  const AGame: TScriptGame);
var
  LMember: TMember;
begin
  for LMember in FMembers do
  begin
    if not (AGame in LMember.RuntimeGames) then
      Continue;
    case LMember.Kind of
      mkProperty:
        AClass.RegisterPropertyHelper(LMember.Reader, LMember.Writer, TbtString(LMember.Name));
      mkMethod:
        AClass.RegisterMethod(LMember.Code, TbtString(LMember.Name));
      mkConstructor:
        AClass.RegisterConstructor(LMember.Code, TbtString(LMember.Name));
    end;
  end;
end;

procedure TScriptClassDescriptor.BindVariables(const AExec: TPSExec);
var
  LVariable: TVariable;
begin
  for LVariable in FVariables do
    SetVariantToClass(AExec.GetVarNo(AExec.GetVar(TbtString(LVariable.Name))), LVariable.Instance());
end;

end.

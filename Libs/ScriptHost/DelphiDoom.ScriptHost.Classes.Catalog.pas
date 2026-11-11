{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - the catalog of the classes that scripts see       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.Classes.Catalog;

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
  ///   The classes that scripts see (the ones of SIRegister_* and RIRegister_*), for one game: it
  ///   registers all of them in a compiler or in a class importer, in the order they were added
  /// </summary>
  TScriptClassCatalog = class(TInterfacedObject, IScriptClassCatalog)
  strict private
    FGame: TScriptGame;
    FClasses: TList<IScriptClassDescriptor>;
    FRuntimeClasses: TList<TClass>;
  public
    constructor Create(const AGame: TScriptGame);
    destructor Destroy; override;
    function Game: TScriptGame;
    function AddClass(const AScriptName: string; const ARuntimeClass: TClass): IScriptClassDescriptor;
    function Count: Integer;
    function ClassAt(const AIndex: Integer): IScriptClassDescriptor;
    function FindClass(const AScriptName: string): IScriptClassDescriptor;
    procedure RegisterCompiler(const ACompiler: TPSPascalCompiler);
    procedure RegisterRuntime(const AImporter: TPSRuntimeClassImporter);
    procedure BindVariables(const AExec: TPSExec);
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.ScriptHost.Classes.Descriptor;

{ TScriptClassCatalog }

constructor TScriptClassCatalog.Create(const AGame: TScriptGame);
begin
  inherited Create;
  FGame := AGame;
  FClasses := TList<IScriptClassDescriptor>.Create;
  FRuntimeClasses := TList<TClass>.Create;
end;

destructor TScriptClassCatalog.Destroy;
begin
  FRuntimeClasses.Free;
  FClasses.Free;
  inherited Destroy;
end;

function TScriptClassCatalog.Game: TScriptGame;
begin
  Result := FGame;
end;

function TScriptClassCatalog.AddClass(const AScriptName: string;
  const ARuntimeClass: TClass): IScriptClassDescriptor;
begin
  if not Assigned(ARuntimeClass) then
    raise EArgumentNilException.Create('ARuntimeClass');
  if Assigned(FindClass(AScriptName)) then
    raise EScriptHostException.CreateFmt(SScriptClassAlreadyAdded, [AScriptName]);
  Result := TScriptClassDescriptor.Create(AScriptName);
  FClasses.Add(Result);
  FRuntimeClasses.Add(ARuntimeClass);
end;

function TScriptClassCatalog.Count: Integer;
begin
  Result := FClasses.Count;
end;

function TScriptClassCatalog.ClassAt(const AIndex: Integer): IScriptClassDescriptor;
begin
  Result := FClasses[AIndex];
end;

function TScriptClassCatalog.FindClass(const AScriptName: string): IScriptClassDescriptor;
var
  LClass: IScriptClassDescriptor;
begin
  for LClass in FClasses do
    if SameText(LClass.ScriptName, AScriptName) then
      Exit(LClass);
  Result := nil;
end;

procedure TScriptClassCatalog.RegisterCompiler(const ACompiler: TPSPascalCompiler);
var
  LIndex: Integer;
  LCompileClasses: TArray<TPSCompileTimeClass>;
begin
  // the classes first: the properties of one name a class that is added later (Actor.Sector)
  SetLength(LCompileClasses, FClasses.Count);
  for LIndex := 0 to FClasses.Count - 1 do
    LCompileClasses[LIndex] := ACompiler.AddClassN(ACompiler.FindClass('!TOBJECT'),
      TbtString(FClasses[LIndex].ScriptName));
  for LIndex := 0 to FClasses.Count - 1 do
    FClasses[LIndex].RegisterCompiler(ACompiler, LCompileClasses[LIndex], FGame);
end;

procedure TScriptClassCatalog.RegisterRuntime(const AImporter: TPSRuntimeClassImporter);
var
  LIndex: Integer;
begin
  for LIndex := 0 to FClasses.Count - 1 do
    FClasses[LIndex].RegisterRuntime(
      AImporter.Add2(FRuntimeClasses[LIndex], TbtString(UpperCase(FClasses[LIndex].ScriptName))), FGame);
end;

procedure TScriptClassCatalog.BindVariables(const AExec: TPSExec);
var
  LClass: IScriptClassDescriptor;
begin
  for LClass in FClasses do
    LClass.BindVariables(AExec);
end;

end.

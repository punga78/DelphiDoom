{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - the registry of the host functions                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  It is the "units" list of ps_import.pas (a sorted list of names with the    }
{  list of functions of each) as a class.                                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.Registry;

interface

uses
  System.Classes,
  ps_compiler,
  ps_runtime,
  DelphiDoom.ScriptHost.Intf;

type
  /// <summary>The functions that scripts can call, by unit of script, in alphabetical order</summary>
  TScriptFunctionRegistry = class(TInterfacedObject, IScriptFunctionRegistry)
  strict private
    FUnits: TStringList;
    function ListOf(const AUnitName: string): TObject;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddGroup(const AGroup: IScriptFunctionGroup);
    procedure RemoveGroup(const AUnitName: string);
    function Contains(const AUnitName: string): Boolean;
    function UnitNames: TArray<string>;
    function CompilerUnitNames: TArray<string>;
    function Declarations(const AUnitName: string): string;
    procedure Reset;
    function RegisterCompiler(const AUnitName: string; const ACompiler: TPSPascalCompiler): Boolean;
    function RegisterExecutor(const AUnitName: string; const AExecutor: TPSExec): Boolean;
    procedure RegisterExecutorForAll(const AExecutor: TPSExec);
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.ScriptHost.FunctionList,
  DelphiDoom.ScriptHost.Types;

{ TScriptFunctionRegistry }

constructor TScriptFunctionRegistry.Create;
begin
  inherited Create;
  FUnits := TStringList.Create;
  // the case of a name does not matter and the names are always in order
  FUnits.Sorted := True;
  FUnits.Duplicates := dupError;
end;

destructor TScriptFunctionRegistry.Destroy;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FUnits.Count - 1 do
    FUnits.Objects[LIndex].Free;
  FUnits.Free;
  inherited Destroy;
end;

function TScriptFunctionRegistry.ListOf(const AUnitName: string): TObject;
var
  LIndex: Integer;
begin
  LIndex := FUnits.IndexOf(AUnitName);
  if LIndex < 0 then
    Result := nil
  else
    Result := FUnits.Objects[LIndex];
end;

procedure TScriptFunctionRegistry.AddGroup(const AGroup: IScriptFunctionGroup);
var
  LList: TScriptFunctionList;
  LName: string;
begin
  if not Assigned(AGroup) then
    raise EScriptHostException.Create(SScriptGroupIsNil);
  LName := UpperCase(AGroup.UnitName);
  if LName = '' then
    raise EScriptHostException.Create(SScriptUnitWithoutName);
  if Contains(LName) then
    raise EScriptHostException.CreateFmt(SScriptUnitAlreadyRegistered, [LName]);
  LList := TScriptFunctionList.Create(LName);
  try
    AGroup.Describe(LList);
  except
    LList.Free;
    raise;
  end;
  FUnits.AddObject(LName, LList);
end;

procedure TScriptFunctionRegistry.RemoveGroup(const AUnitName: string);
var
  LIndex: Integer;
begin
  LIndex := FUnits.IndexOf(AUnitName);
  if LIndex < 0 then
    Exit;
  FUnits.Objects[LIndex].Free;
  FUnits.Delete(LIndex);
end;

function TScriptFunctionRegistry.Contains(const AUnitName: string): Boolean;
begin
  Result := FUnits.IndexOf(AUnitName) >= 0;
end;

function TScriptFunctionRegistry.UnitNames: TArray<string>;
var
  LIndex: Integer;
begin
  SetLength(Result, FUnits.Count);
  for LIndex := 0 to FUnits.Count - 1 do
    Result[LIndex] := FUnits[LIndex];
end;

function TScriptFunctionRegistry.CompilerUnitNames: TArray<string>;
var
  LIndex: Integer;
  LCount: Integer;
begin
  SetLength(Result, FUnits.Count);
  LCount := 0;
  for LIndex := 0 to FUnits.Count - 1 do
    if UpperCase(FUnits[LIndex]) <> SCRIPT_UNIT_SYSTEM then
    begin
      Result[LCount] := UpperCase(FUnits[LIndex]);
      Inc(LCount);
    end;
  SetLength(Result, LCount);
end;

function TScriptFunctionRegistry.Declarations(const AUnitName: string): string;
var
  LList: TObject;
begin
  LList := ListOf(AUnitName);
  if LList = nil then
    Result := ''
  else
    Result := TScriptFunctionList(LList).Declarations;
end;

procedure TScriptFunctionRegistry.Reset;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FUnits.Count - 1 do
    TScriptFunctionList(FUnits.Objects[LIndex]).Reset;
end;

function TScriptFunctionRegistry.RegisterCompiler(const AUnitName: string;
  const ACompiler: TPSPascalCompiler): Boolean;
var
  LList: TObject;
begin
  LList := ListOf(AUnitName);
  Result := LList <> nil;
  if Result then
    TScriptFunctionList(LList).RegisterCompiler(ACompiler);
end;

function TScriptFunctionRegistry.RegisterExecutor(const AUnitName: string;
  const AExecutor: TPSExec): Boolean;
var
  LList: TObject;
begin
  LList := ListOf(AUnitName);
  Result := LList <> nil;
  if Result then
    TScriptFunctionList(LList).RegisterExecutor(AExecutor);
end;

procedure TScriptFunctionRegistry.RegisterExecutorForAll(const AExecutor: TPSExec);
var
  LIndex: Integer;
begin
  for LIndex := 0 to FUnits.Count - 1 do
    TScriptFunctionList(FUnits.Objects[LIndex]).RegisterExecutor(AExecutor);
end;

end.

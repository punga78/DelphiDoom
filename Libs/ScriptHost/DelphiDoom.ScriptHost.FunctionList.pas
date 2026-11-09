{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - the functions of one unit of script               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  It is the TProcedureList of ps_proclist.pas, without the manual memory:     }
{  the same rules for the declarations, the names and the "computed" flag.     }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.FunctionList;

interface

uses
  System.Generics.Collections,
  ps_defs,
  ps_compiler,
  ps_runtime,
  DelphiDoom.ScriptHost.Intf,
  DelphiDoom.ScriptHost.Types;

type
  /// <summary>
  ///   The functions of one unit of script, in the order in which they were added. A group writes
  ///   them through IScriptFunctionTable; the registry gives them to the compiler and to the
  ///   interpreter
  /// </summary>
  TScriptFunctionList = class(TObject, IScriptFunctionTable)
  strict private
    FUnitName: string;
    FEntries: TList<TScriptFunctionEntry>;
  public
    // the registry owns the list and hands it to the groups as an interface: no reference counting
    function QueryInterface(const AIID: TGUID; out AObject): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
    constructor Create(const AUnitName: string);
    destructor Destroy; override;
    procedure Add(const ADeclaration: string; const ACode: Pointer);
    procedure AddWithCustomResult(const ADeclaration, AResultType, AExportDeclaration: string;
      const ACode: Pointer);
    /// <summary>Registers every function in the compiler and keeps the names it gives</summary>
    procedure RegisterCompiler(const ACompiler: TPSPascalCompiler);
    /// <summary>Registers in the interpreter the functions that the compiler has registered</summary>
    procedure RegisterExecutor(const AExecutor: TPSExec);
    /// <summary>The functions have to be registered by the compiler again before the interpreter gets them</summary>
    procedure Reset;
    /// <summary>The export declarations, one for each line (CR LF)</summary>
    function Declarations: string;
    function Count: Integer;
    property ListName: string read FUnitName;
  end;

implementation

uses
  System.SysUtils;

{ TScriptFunctionList }

function TScriptFunctionList.QueryInterface(const AIID: TGUID; out AObject): HResult;
begin
  if GetInterface(AIID, AObject) then
    Result := 0
  else
    Result := -2147467262; // E_NOINTERFACE
end;

function TScriptFunctionList._AddRef: Integer;
begin
  Result := -1;
end;

function TScriptFunctionList._Release: Integer;
begin
  Result := -1;
end;

constructor TScriptFunctionList.Create(const AUnitName: string);
begin
  inherited Create;
  FUnitName := AUnitName;
  FEntries := TList<TScriptFunctionEntry>.Create;
end;

destructor TScriptFunctionList.Destroy;
begin
  FEntries.Free;
  inherited Destroy;
end;

procedure TScriptFunctionList.Add(const ADeclaration: string; const ACode: Pointer);
var
  LEntry: TScriptFunctionEntry;
  LDeclaration: string;
begin
  LDeclaration := Trim(ADeclaration);
  if LDeclaration = '' then
    Exit;
  if LDeclaration[Length(LDeclaration)] <> ';' then
    LDeclaration := LDeclaration + ';';
  LEntry.Code := ACode;
  LEntry.Declaration := LDeclaration;
  LEntry.ResultType := '';
  LEntry.ExportDeclaration := LDeclaration;
  LEntry.Name := '';
  LEntry.Computed := True;
  FEntries.Add(LEntry);
end;

procedure TScriptFunctionList.AddWithCustomResult(const ADeclaration, AResultType,
  AExportDeclaration: string; const ACode: Pointer);
var
  LEntry: TScriptFunctionEntry;
  LDeclaration: string;
begin
  LDeclaration := Trim(ADeclaration);
  if LDeclaration = '' then
    Exit;
  if LDeclaration[Length(LDeclaration)] <> ';' then
    LDeclaration := LDeclaration + ';';
  LEntry.Code := ACode;
  LEntry.Declaration := LDeclaration;
  LEntry.ResultType := AResultType;
  LEntry.ExportDeclaration := AExportDeclaration;
  LEntry.Name := '';
  LEntry.Computed := True;
  FEntries.Add(LEntry);
end;

procedure TScriptFunctionList.RegisterCompiler(const ACompiler: TPSPascalCompiler);
var
  LIndex: Integer;
  LEntry: TScriptFunctionEntry;
  LRegistered: TPSRegProc;
begin
  for LIndex := 0 to FEntries.Count - 1 do
  begin
    LEntry := FEntries[LIndex];
    if LEntry.ResultType <> '' then
      LRegistered := ACompiler.AddDelphiFunctionWithRTLObjectResult(TbtString(LEntry.Declaration),
        TbtString(LEntry.ResultType))
    else
      LRegistered := ACompiler.AddDelphiFunction(TbtString(LEntry.Declaration));
    if LRegistered <> nil then
    begin
      LEntry.Name := string(LRegistered.Name);
      LEntry.Computed := True;
      FEntries[LIndex] := LEntry;
    end;
  end;
end;

procedure TScriptFunctionList.RegisterExecutor(const AExecutor: TPSExec);
var
  LIndex: Integer;
begin
  for LIndex := 0 to FEntries.Count - 1 do
    if FEntries[LIndex].Computed then
      AExecutor.RegisterDelphiFunction(FEntries[LIndex].Code, TbtString(FEntries[LIndex].Name),
        cdRegister);
end;

procedure TScriptFunctionList.Reset;
var
  LIndex: Integer;
  LEntry: TScriptFunctionEntry;
begin
  for LIndex := 0 to FEntries.Count - 1 do
  begin
    LEntry := FEntries[LIndex];
    LEntry.Computed := False;
    FEntries[LIndex] := LEntry;
  end;
end;

function TScriptFunctionList.Declarations: string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 0 to FEntries.Count - 1 do
    Result := Result + FEntries[LIndex].ExportDeclaration + #13#10;
end;

function TScriptFunctionList.Count: Integer;
begin
  Result := FEntries.Count;
end;

end.

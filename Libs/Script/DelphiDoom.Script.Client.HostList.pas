{******************************************************************************}
{                                                                              }
{  DelphiDoom: Script - list of the functions the application gives to scripts }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Script.Client.HostList;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Script.Intf,
  DelphiDoom.Script.Client.Compiler, DelphiDoom.Script.Client.Executor;

type
  /// <summary>
  ///   One function of the application: its declaration as text, its address
  ///   and its calling convention
  /// </summary>
  TScriptHostFunction = record
    Declaration: AnsiString;
    Address: Pointer;
    Convention: Integer;
  end;

  /// <summary>
  ///   A list of functions of the application, given in one go to the
  ///   compiler (the declarations) and to the executor (declarations and
  ///   addresses), so the two never disagree
  /// </summary>
  /// <remarks>
  ///   Replaces SCRIPT\ps_proclist.pas for the code that talks to the library
  ///   through its clients: the declaration text is the same, and the default
  ///   convention is the register one of the engine functions
  /// </remarks>
  TScriptHostList = class
  private
    FFunctions: TList<TScriptHostFunction>;
    function GetCount: Integer;
    function GetFunction(AIndex: Integer): TScriptHostFunction;
  public
    constructor Create;
    destructor Destroy; override;

    /// <summary>
    ///   Adds a function; nothing is registered until Declare and Register
    /// </summary>
    procedure Add(const ADeclaration: AnsiString; AAddress: Pointer;
      AConvention: Integer = SCRIPT_CALL_REGISTER);

    /// <summary>
    ///   Gives the declarations to the compiler (in the unit it has selected)
    /// </summary>
    procedure Declare(const ACompiler: TScriptCompilerClient);

    /// <summary>
    ///   Gives declarations and addresses to the executor; before Load
    /// </summary>
    procedure Register(const AExecutor: TScriptExecutorClient);

    property Count: Integer read GetCount;
    property Functions[AIndex: Integer]: TScriptHostFunction read GetFunction; default;
  end;

implementation

{ TScriptHostList }

constructor TScriptHostList.Create;
begin
  inherited Create;
  FFunctions := TList<TScriptHostFunction>.Create;
end;

destructor TScriptHostList.Destroy;
begin
  FreeAndNil(FFunctions);
  inherited;
end;

function TScriptHostList.GetCount: Integer;
begin
  Result := FFunctions.Count;
end;

function TScriptHostList.GetFunction(AIndex: Integer): TScriptHostFunction;
begin
  Result := FFunctions[AIndex];
end;

procedure TScriptHostList.Add(const ADeclaration: AnsiString; AAddress: Pointer;
  AConvention: Integer);
var
  LFunction: TScriptHostFunction;
begin
  if ADeclaration = '' then
    raise EArgumentException.Create('ADeclaration');
  if not Assigned(AAddress) then
    raise EArgumentNilException.Create('AAddress');

  LFunction.Declaration := ADeclaration;
  LFunction.Address := AAddress;
  LFunction.Convention := AConvention;
  FFunctions.Add(LFunction);
end;

procedure TScriptHostList.Declare(const ACompiler: TScriptCompilerClient);
var
  LIndex: Integer;
begin
  for LIndex := 0 to FFunctions.Count - 1 do
    ACompiler.AddHostFunction(FFunctions[LIndex].Declaration);
end;

procedure TScriptHostList.Register(const AExecutor: TScriptExecutorClient);
var
  LIndex: Integer;
begin
  for LIndex := 0 to FFunctions.Count - 1 do
    AExecutor.AddHostFunction(FFunctions[LIndex].Declaration,
      FFunctions[LIndex].Address, FFunctions[LIndex].Convention);
end;

end.

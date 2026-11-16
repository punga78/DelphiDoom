{******************************************************************************}
{                                                                              }
{  DelphiDoom: Script - the class the engine uses in place of the library      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Script.Client;

interface

uses
  System.SysUtils, DelphiDoom.Script.Intf, DelphiDoom.Script.Client.Compiler,
  DelphiDoom.Script.Client.Executor;

type
  /// <summary>
  ///   Entry point of the script library for the rest of the engine: creates
  ///   the compiler and executor classes on top of an IScriptLibrary
  /// </summary>
  /// <remarks>
  ///   Depends only on IScriptLibrary, so it works the same with the DLL (see
  ///   TScriptLoader), with an engine linked in the executable, or with a
  ///   fake in the tests. The objects it creates must be freed before the
  ///   loader of the DLL
  /// </remarks>
  TScriptClient = class
  private
    FLibrary: IScriptLibrary;
  public
    constructor Create(const ALibrary: IScriptLibrary);

    /// <summary>
    ///   Creates a compiler; the caller owns it
    /// </summary>
    function CreateCompiler(AKeywords: Integer = SCRIPT_KEYWORDS_STANDARD): TScriptCompilerClient;

    /// <summary>
    ///   Creates an executor; the caller owns it
    /// </summary>
    function CreateExecutor: TScriptExecutorClient;
  end;

implementation

{ TScriptClient }

constructor TScriptClient.Create(const ALibrary: IScriptLibrary);
begin
  inherited Create;
  if not Assigned(ALibrary) then
    raise EArgumentNilException.Create('ALibrary');
  FLibrary := ALibrary;
end;

function TScriptClient.CreateCompiler(AKeywords: Integer): TScriptCompilerClient;
var
  LCompiler: IScriptCompiler;
  LCode: Integer;
begin
  LCode := FLibrary.CreateCompilerEx(AKeywords, LCompiler);
  if (LCode <> SCRIPT_OK) or not Assigned(LCompiler) then
    raise EScriptException.CreateCode(LCode);
  Result := TScriptCompilerClient.Create(LCompiler);
end;

function TScriptClient.CreateExecutor: TScriptExecutorClient;
var
  LExecutor: IScriptExecutor;
  LCode: Integer;
begin
  LCode := FLibrary.CreateExecutor(LExecutor);
  if (LCode <> SCRIPT_OK) or not Assigned(LExecutor) then
    raise EScriptException.CreateCode(LCode);
  Result := TScriptExecutorClient.Create(LExecutor);
end;

end.

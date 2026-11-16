{******************************************************************************}
{                                                                              }
{  DelphiDoom: Script - implementation of IScriptLibrary                       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Script.Engine;

interface

uses
  System.SysUtils, DelphiDoom.Script.Intf;

type
  /// <summary>
  ///   Root of the library: creates the compilers and the executors. Never
  ///   lets an exception cross the interface
  /// </summary>
  TScriptEngine = class(TInterfacedObject, IScriptLibrary)
  public
    function CreateCompiler(out ACompiler: IScriptCompiler): Integer; stdcall;
    function CreateCompilerEx(AKeywords: Integer;
      out ACompiler: IScriptCompiler): Integer; stdcall;
    function CreateExecutor(out AExecutor: IScriptExecutor): Integer; stdcall;
  end;

implementation

uses
  DelphiDoom.Script.Engine.Compiler, DelphiDoom.Script.Engine.Executor;

{ TScriptEngine }

function TScriptEngine.CreateCompiler(out ACompiler: IScriptCompiler): Integer;
begin
  ACompiler := nil;
  try
    ACompiler := TScriptCompilerEngine.Create;
    Result := SCRIPT_OK;
  except
    on EOutOfMemory do
      Result := SCRIPT_ERROR_MEMORY;
    on Exception do
      Result := SCRIPT_ERROR_INTERNAL;
  end;
end;

function TScriptEngine.CreateCompilerEx(AKeywords: Integer;
  out ACompiler: IScriptCompiler): Integer;
begin
  ACompiler := nil;
  if (AKeywords <> SCRIPT_KEYWORDS_STANDARD) and (AKeywords <> SCRIPT_KEYWORDS_MODEL) then
    Exit(SCRIPT_ERROR_ARGUMENT);

  try
    ACompiler := TScriptCompilerEngine.Create(AKeywords);
    Result := SCRIPT_OK;
  except
    on EOutOfMemory do
      Result := SCRIPT_ERROR_MEMORY;
    on Exception do
      Result := SCRIPT_ERROR_INTERNAL;
  end;
end;

function TScriptEngine.CreateExecutor(out AExecutor: IScriptExecutor): Integer;
begin
  AExecutor := nil;
  try
    AExecutor := TScriptExecutorEngine.Create;
    Result := SCRIPT_OK;
  except
    on EOutOfMemory do
      Result := SCRIPT_ERROR_MEMORY;
    on Exception do
      Result := SCRIPT_ERROR_INTERNAL;
  end;
end;

end.

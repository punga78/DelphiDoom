{******************************************************************************}
{                                                                              }
{  DDScript.dll: Pascal Script compiler and interpreter for DelphiDoom         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
library DDScript;

uses
  d_delphi in 'Libs\Script\Shim\d_delphi.pas',
  ps_defs in 'SCRIPT\ps_defs.pas',
  ps_keywords in 'SCRIPT\ps_keywords.pas',
  ps_utils in 'SCRIPT\ps_utils.pas',
  ps_compiler in 'SCRIPT\ps_compiler.pas',
  ps_runtime in 'SCRIPT\ps_runtime.pas',
  DelphiDoom.Script.Intf in 'Libs\Script\DelphiDoom.Script.Intf.pas',
  DelphiDoom.Script.Native in 'Libs\Script\DelphiDoom.Script.Native.pas',
  DelphiDoom.Script.Native.Compiler in 'Libs\Script\DelphiDoom.Script.Native.Compiler.pas',
  DelphiDoom.Script.Native.Executor in 'Libs\Script\DelphiDoom.Script.Native.Executor.pas',
  DelphiDoom.Script.Engine.Compiler in 'Libs\Script\DelphiDoom.Script.Engine.Compiler.pas',
  DelphiDoom.Script.Engine.Executor in 'Libs\Script\DelphiDoom.Script.Engine.Executor.pas',
  DelphiDoom.Script.Engine in 'Libs\Script\DelphiDoom.Script.Engine.pas';

function DDScriptCreate(out ALibrary: IScriptLibrary): Integer; stdcall;
begin
  ALibrary := nil;
  try
    ALibrary := TScriptEngine.Create;
    Result := SCRIPT_OK;
  except
    Result := SCRIPT_ERROR_MEMORY;
  end;
end;

exports
  DDScriptCreate;

begin
end.

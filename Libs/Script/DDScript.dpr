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
  d_delphi in 'Shim\d_delphi.pas',
  ps_defs in '..\..\Libs\PascalScript\ps_defs.pas',
  ps_keywords in '..\..\Libs\PascalScript\ps_keywords.pas',
  ps_utils in '..\..\Libs\PascalScript\ps_utils.pas',
  ps_compiler in '..\..\Libs\PascalScript\ps_compiler.pas',
  uPSPreProcessor in '..\..\Libs\PascalScript\uPSPreProcessor.pas',
  ps_runtime in '..\..\Libs\PascalScript\ps_runtime.pas',
  DelphiDoom.Script.Intf in 'DelphiDoom.Script.Intf.pas',
  DelphiDoom.Script.Native in 'DelphiDoom.Script.Native.pas',
  DelphiDoom.Script.Native.Compiler in 'DelphiDoom.Script.Native.Compiler.pas',
  DelphiDoom.Script.Native.Executor in 'DelphiDoom.Script.Native.Executor.pas',
  DelphiDoom.Script.Engine.Compiler in 'DelphiDoom.Script.Engine.Compiler.pas',
  DelphiDoom.Script.Engine.Executor in 'DelphiDoom.Script.Engine.Executor.pas',
  DelphiDoom.Script.Engine in 'DelphiDoom.Script.Engine.pas';

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

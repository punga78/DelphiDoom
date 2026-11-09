{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the failures of the variables of the scripts           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Script.VariablesFailure;

interface

uses
  DelphiDoom.ScriptHost.Variables.Intf;

type
  /// <summary>A failure of the variables of the scripts stops the game (I_Error), as it always did</summary>
  TEngineScriptVariablesFailure = class(TInterfacedObject, IScriptVariablesFailure)
  public
    procedure Report(const AMessage: string);
  end;

implementation

uses
  i_system;

{ TEngineScriptVariablesFailure }

procedure TEngineScriptVariablesFailure.Report(const AMessage: string);
begin
  I_Error('%s', [AMessage]);
end;

end.

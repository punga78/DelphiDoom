{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the text that scripts write                            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Script.Output;

interface

uses
  DelphiDoom.ScriptHost.System.Intf;

type
  /// <summary>
  ///   Where the Write, Writeln and OutputDebugString of the scripts go: the output of the game
  ///   (printf: the console, the window of the start and the stdout file) and the debug file.
  ///   It was in psi_system.pas
  /// </summary>
  TEngineScriptOutput = class(TInterfacedObject, IScriptSystemOutput)
  public
    procedure WriteText(const AText: string);
    procedure WriteDebug(const AText: string);
    function FormatText(const AFormat: string; const AArguments: array of const): string;
  end;

implementation

uses
  d_delphi,
  i_io,
  i_system;

{ TEngineScriptOutput }

procedure TEngineScriptOutput.WriteText(const AText: string);
begin
  printf(AText);
end;

procedure TEngineScriptOutput.WriteDebug(const AText: string);
begin
  if debugfile <> nil then
    fprintf(debugfile, AText);
end;

function TEngineScriptOutput.FormatText(const AFormat: string;
  const AArguments: array of const): string;
begin
  try
    sprintf(Result, AFormat, AArguments);
  except
    I_Warning('Script Runtime Error: Invalid Format Parameters (%s)'#13#10, [AFormat]);
    Result := AFormat;
  end;
end;

end.

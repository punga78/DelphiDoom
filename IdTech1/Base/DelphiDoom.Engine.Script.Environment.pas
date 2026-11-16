{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the world that the SYSTEM functions of scripts read    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Script.Environment;

interface

uses
  DelphiDoom.ScriptHost.System.Intf;

type
  /// <summary>
  ///   The time of the level and the trigonometric tables of the engine, for the scripts. The
  ///   only class of the SYSTEM group that reads these globals (they were in psi_system.pas)
  /// </summary>
  TEngineScriptEnvironment = class(TInterfacedObject, IScriptSystemEnvironment)
  public
    function LevelTime: Integer;
    function FineSine(const AAngle: LongWord): Integer;
    function FineCosine(const AAngle: LongWord): Integer;
    function FineTangent(const AAngle: LongWord): Integer;
  end;

implementation

uses
  p_tick,
  tables;

{ TEngineScriptEnvironment }

function TEngineScriptEnvironment.LevelTime: Integer;
begin
  // qualified: inside the class "leveltime" must not be read as this very method
  Result := p_tick.leveltime;
end;

function TEngineScriptEnvironment.FineSine(const AAngle: LongWord): Integer;
begin
  // qualified: inside the class the names of the tables are the ones of the methods
  Result := tables.finesine[AAngle and FINEMASK];
end;

function TEngineScriptEnvironment.FineCosine(const AAngle: LongWord): Integer;
begin
  Result := tables.finecosine[AAngle and FINEMASK];
end;

function TEngineScriptEnvironment.FineTangent(const AAngle: LongWord): Integer;
begin
  Result := tables.finetangent[AAngle and FINEMASK];
end;

end.

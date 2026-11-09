{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - the factory: the composition root                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.Factory;

interface

uses
  DelphiDoom.MathCore.Intf,
  DelphiDoom.ScriptHost.CallbackGroup,
  DelphiDoom.ScriptHost.Fixed.Functions,
  DelphiDoom.ScriptHost.Intf,
  DelphiDoom.ScriptHost.System.Functions,
  DelphiDoom.ScriptHost.System.Intf;

type
  /// <summary>The only place that knows the classes behind the contracts of the script host</summary>
  TScriptHostFactory = class
  public
    /// <summary>A registry with no units</summary>
    class function CreateRegistry: IScriptFunctionRegistry; static;
    /// <summary>The unit SYSTEM of the scripts: for the registry ask it for an IScriptFunctionGroup</summary>
    class function CreateSystemFunctions(const ARoutines: TScriptSystemRoutines;
      const AOutput: IScriptSystemOutput; const AEnvironment: IScriptSystemEnvironment;
      const AConsole: IScriptSystemConsole; const ARandom: IGameRandom): IScriptSystemFunctions; static;
    /// <summary>The unit PS_FIXED of the scripts</summary>
    class function CreateFixedGroup(const ARoutines: TScriptFixedRoutines): IScriptFunctionGroup; static;
    /// <summary>A unit of script whose functions a procedure writes</summary>
    class function CreateCallbackGroup(const AUnitName: string;
      const ADescribe: TScriptDescribeProcedure): IScriptFunctionGroup; static;
  end;

implementation

uses
  DelphiDoom.ScriptHost.Registry;

{ TScriptHostFactory }

class function TScriptHostFactory.CreateRegistry: IScriptFunctionRegistry;
begin
  Result := TScriptFunctionRegistry.Create;
end;

class function TScriptHostFactory.CreateSystemFunctions(const ARoutines: TScriptSystemRoutines;
  const AOutput: IScriptSystemOutput; const AEnvironment: IScriptSystemEnvironment;
  const AConsole: IScriptSystemConsole; const ARandom: IGameRandom): IScriptSystemFunctions;
begin
  Result := TScriptSystemFunctions.Create(ARoutines, AOutput, AEnvironment, AConsole, ARandom);
end;

class function TScriptHostFactory.CreateFixedGroup(
  const ARoutines: TScriptFixedRoutines): IScriptFunctionGroup;
begin
  Result := TScriptFixedFunctions.Create(ARoutines);
end;

class function TScriptHostFactory.CreateCallbackGroup(const AUnitName: string;
  const ADescribe: TScriptDescribeProcedure): IScriptFunctionGroup;
begin
  Result := TScriptCallbackGroup.Create(AUnitName, ADescribe);
end;

end.

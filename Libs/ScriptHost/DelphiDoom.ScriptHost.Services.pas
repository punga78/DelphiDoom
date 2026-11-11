{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - what a compiler and an interpreter of scripts use }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.Services;

interface

uses
  System.SysUtils,
  DelphiDoom.ScriptHost.Classes.Intf,
  DelphiDoom.ScriptHost.Constants.Intf,
  DelphiDoom.ScriptHost.Intf,
  DelphiDoom.ScriptHost.Services.Intf,
  DelphiDoom.ScriptHost.Source.Intf,
  DelphiDoom.ScriptHost.Types;

type
  /// <summary>The services of the scripts, as values given by the composition root</summary>
  TScriptHostServices = class(TInterfacedObject, IScriptHostServices)
  strict private
    FRegistry: IScriptFunctionRegistry;
    FClasses: IScriptClassCatalog;
    FConstants: IScriptConstantProvider;
    FSources: IScriptSourceProvider;
    FGameName: string;
    FGame: TScriptGame;
    FDefines: TFunc<TArray<string>>;
  public
    /// <summary>
    ///   ADefines is asked at every compilation (it may be nil: no defines): the engine learns
    ///   its parameters (-devparm) after it was composed
    /// </summary>
    /// <exception cref="EArgumentNilException">If a service is nil</exception>
    constructor Create(const ARegistry: IScriptFunctionRegistry; const AClasses: IScriptClassCatalog;
      const AConstants: IScriptConstantProvider; const ASources: IScriptSourceProvider;
      const AGameName: string; const AGame: TScriptGame; const ADefines: TFunc<TArray<string>>);
    function Registry: IScriptFunctionRegistry;
    function Classes: IScriptClassCatalog;
    function Constants: IScriptConstantProvider;
    function Sources: IScriptSourceProvider;
    function GameName: string;
    function Game: TScriptGame;
    function Defines: TArray<string>;
  end;

implementation

{ TScriptHostServices }

constructor TScriptHostServices.Create(const ARegistry: IScriptFunctionRegistry;
  const AClasses: IScriptClassCatalog; const AConstants: IScriptConstantProvider;
  const ASources: IScriptSourceProvider; const AGameName: string; const AGame: TScriptGame;
  const ADefines: TFunc<TArray<string>>);
begin
  inherited Create;
  if not Assigned(ARegistry) then
    raise EArgumentNilException.Create('ARegistry');
  if not Assigned(AClasses) then
    raise EArgumentNilException.Create('AClasses');
  if not Assigned(AConstants) then
    raise EArgumentNilException.Create('AConstants');
  if not Assigned(ASources) then
    raise EArgumentNilException.Create('ASources');
  FRegistry := ARegistry;
  FClasses := AClasses;
  FConstants := AConstants;
  FSources := ASources;
  FGameName := AGameName;
  FGame := AGame;
  FDefines := ADefines;
end;

function TScriptHostServices.Registry: IScriptFunctionRegistry;
begin
  Result := FRegistry;
end;

function TScriptHostServices.Classes: IScriptClassCatalog;
begin
  Result := FClasses;
end;

function TScriptHostServices.Constants: IScriptConstantProvider;
begin
  Result := FConstants;
end;

function TScriptHostServices.Sources: IScriptSourceProvider;
begin
  Result := FSources;
end;

function TScriptHostServices.GameName: string;
begin
  Result := FGameName;
end;

function TScriptHostServices.Game: TScriptGame;
begin
  Result := FGame;
end;

function TScriptHostServices.Defines: TArray<string>;
begin
  if Assigned(FDefines) then
    Result := FDefines()
  else
    Result := nil;
end;

end.

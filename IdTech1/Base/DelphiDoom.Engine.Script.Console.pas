{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the console and its variables, for the scripts         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Script.Console;

interface

uses
  DelphiDoom.Engine.Configuration.Intf,
  DelphiDoom.Engine.Console.Intf,
  DelphiDoom.ScriptHost.System.Intf;

type
  /// <summary>
  ///   The commands and the variables of the configuration that scripts can use
  ///   (ConsoleCommand, GetConsoleInt, SetConsoleStr...). The variables are read from the table
  ///   rows of IEngineDefaults.Table and written through IEngineDefaults. It was in psi_system.pas
  /// </summary>
  TEngineScriptConsole = class(TInterfacedObject, IScriptSystemConsole)
  strict private
    FConsole: IEngineConsole;
    FDefaults: IEngineDefaults;
  public
    /// <exception cref="EArgumentNilException">If a dependency is nil</exception>
    constructor Create(const AConsole: IEngineConsole; const ADefaults: IEngineDefaults);
    procedure AddCommand(const ACommand: string);
    function GetString(const AName: string): string;
    function GetInteger(const AName: string): Integer;
    function GetBoolean(const AName: string): Boolean;
    function SetString(const AName, AValue: string): Boolean;
    function SetInteger(const AName: string; const AValue: Integer): Boolean;
    function SetBoolean(const AName: string; const AValue: Boolean): Boolean;
  end;

implementation

uses
  System.SysUtils,
  d_delphi,
  DelphiDoom.Configuration.Types,
  DelphiDoom.Configuration.Intf;

{ TEngineScriptConsole }

constructor TEngineScriptConsole.Create(const AConsole: IEngineConsole;
  const ADefaults: IEngineDefaults);
begin
  inherited Create;
  if not Assigned(AConsole) then
    raise EArgumentNilException.Create('AConsole');
  if not Assigned(ADefaults) then
    raise EArgumentNilException.Create('ADefaults');
  FConsole := AConsole;
  FDefaults := ADefaults;
end;

procedure TEngineScriptConsole.AddCommand(const ACommand: string);
begin
  FConsole.AddCommand(ACommand);
end;

function TEngineScriptConsole.GetString(const AName: string): string;
var
  LItem: IConfigurationItem;
begin
  // the variable itself, also when it is forced (the old code read oldlocation)
  LItem := FDefaults.Table.FindValue(strlower(AName));
  if not Assigned(LItem) then
    Exit('');
  case LItem.Kind of
    cikString: Result := LItem.ActualString;
    cikInteger: Result := itoa(LItem.ActualInteger);
  else
    if LItem.ActualBoolean then
      Result := 'true'
    else
      Result := 'false';
  end;
end;

function TEngineScriptConsole.GetInteger(const AName: string): Integer;
var
  LItem: IConfigurationItem;
begin
  LItem := FDefaults.Table.FindValue(strlower(AName));
  if not Assigned(LItem) then
    Exit(0);
  case LItem.Kind of
    cikString: Result := atoi(LItem.ActualString, 0);
    cikInteger: Result := LItem.ActualInteger;
  else
    if LItem.ActualBoolean then
      Result := 1
    else
      Result := 0;
  end;
end;

function TEngineScriptConsole.GetBoolean(const AName: string): Boolean;
var
  LItem: IConfigurationItem;
begin
  LItem := FDefaults.Table.FindValue(strlower(AName));
  if not Assigned(LItem) then
    Exit(False);
  case LItem.Kind of
    cikString: Result := LItem.ActualString <> '';
    cikInteger: Result := LItem.ActualInteger <> 0;
  else
    Result := LItem.ActualBoolean;
  end;
end;

function TEngineScriptConsole.SetString(const AName, AValue: string): Boolean;
begin
  Result := FDefaults.ForceString(AName, AValue);
end;

function TEngineScriptConsole.SetInteger(const AName: string; const AValue: Integer): Boolean;
begin
  Result := FDefaults.ForceInteger(AName, AValue);
end;

function TEngineScriptConsole.SetBoolean(const AName: string; const AValue: Boolean): Boolean;
begin
  Result := FDefaults.ForceBoolean(AName, AValue);
end;

end.

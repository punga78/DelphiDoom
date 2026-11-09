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
  ///   "defaults" and written through IEngineDefaults. It was in psi_system.pas
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
  m_defs;

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
  i: integer;
  pd: Pdefault_t;
  cname: string;
  location: Pointer;
begin
  cname := strlower(AName);

  pd := @defaults[0];
  for i := 0 to NUMDEFAULTS - 1 do
  begin
    if pd.name = cname then
    begin
      if pd.oldlocation <> nil then
        location := pd.oldlocation
      else
        location := pd.location;
      case pd._type of
        tString:
          begin
            Result := PString(location)^;
            Exit;
          end;
        tInteger:
          begin
            Result := itoa(PInteger(location)^);
            Exit;
          end;
        tBoolean:
          begin
            if PBoolean(location)^ then
              Result := 'true'
            else
              Result := 'false';
            Exit;
          end;
      end;
    end;
    inc(pd);
  end;
  Result := '';
end;

function TEngineScriptConsole.GetInteger(const AName: string): Integer;
var
  i: integer;
  pd: Pdefault_t;
  cname: string;
  location: Pointer;
begin
  cname := strlower(AName);

  pd := @defaults[0];
  for i := 0 to NUMDEFAULTS - 1 do
  begin
    if pd.name = cname then
    begin
      if pd.oldlocation <> nil then
        location := pd.oldlocation
      else
        location := pd.location;
      case pd._type of
        tString:
          begin
            Result := atoi(PString(location)^, 0);
            Exit;
          end;
        tInteger:
          begin
            Result := PInteger(location)^;
            Exit;
          end;
        tBoolean:
          begin
            if PBoolean(location)^ then
              Result := 1
            else
              Result := 0;
            Exit;
          end;
      end;
    end;
    inc(pd);
  end;
  Result := 0;
end;

function TEngineScriptConsole.GetBoolean(const AName: string): Boolean;
var
  i: integer;
  pd: Pdefault_t;
  cname: string;
  location: Pointer;
begin
  cname := strlower(AName);

  pd := @defaults[0];
  for i := 0 to NUMDEFAULTS - 1 do
  begin
    if pd.name = cname then
    begin
      if pd.oldlocation <> nil then
        location := pd.oldlocation
      else
        location := pd.location;
      case pd._type of
        tString:
          begin
            Result := PString(location)^ <> '';
            Exit;
          end;
        tInteger:
          begin
            Result := PInteger(location)^ <> 0;
            Exit;
          end;
        tBoolean:
          begin
            Result := PBoolean(location)^;
            Exit;
          end;
      end;
    end;
    inc(pd);
  end;
  Result := False;
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

{******************************************************************************}
{                                                                              }
{  DelphiDoom: the console variables that #CVARFORCE sets                       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Scanner.CvarSetter;

interface

uses
  DelphiDoom.Scanner.Preprocessor.Intf,
  DelphiDoom.Engine.Configuration.Intf;

type
  /// <summary>The defaults of the engine (IEngineDefaults) and the evaluation of the console (c_cmds)</summary>
  TEngineCvarSetter = class(TInterfacedObject, ICvarSetter)
  strict private
    FDefaults: IEngineDefaults;
  public
    /// <remarks>Raises EArgumentNilException if ADefaults is nil</remarks>
    constructor Create(const ADefaults: IEngineDefaults);
    function EvaluateBoolean(const AText: string; ADefault: Boolean): Boolean;
    function TrySetBoolean(const AName: string; AValue: Boolean): Boolean;
    function TrySetInteger(const AName: string; AValue: Integer): Boolean;
    function TrySetString(const AName: string; const AValue: string): Boolean;
  end;

implementation

uses
  DelphiDoom.Console.Numbers,
  System.SysUtils;

const
  SDefaultsIsNil = 'TEngineCvarSetter: the defaults are nil';

{ TEngineCvarSetter }

constructor TEngineCvarSetter.Create(const ADefaults: IEngineDefaults);
begin
  inherited Create;
  if not Assigned(ADefaults) then
    raise EArgumentNilException.Create(SDefaultsIsNil);
  FDefaults := ADefaults;
end;

function TEngineCvarSetter.EvaluateBoolean(const AText: string; ADefault: Boolean): Boolean;
begin
  Result := TConsoleNumbers.EvaluateBoolean(AText, ADefault);
end;

function TEngineCvarSetter.TrySetBoolean(const AName: string; AValue: Boolean): Boolean;
begin
  Result := FDefaults.ForceBoolean(AName, AValue);
end;

function TEngineCvarSetter.TrySetInteger(const AName: string; AValue: Integer): Boolean;
begin
  Result := FDefaults.ForceInteger(AName, AValue);
end;

function TEngineCvarSetter.TrySetString(const AName: string; const AValue: string): Boolean;
begin
  Result := FDefaults.ForceString(AName, AValue);
end;

end.

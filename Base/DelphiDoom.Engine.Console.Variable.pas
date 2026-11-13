{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - a console variable made of a row of the options       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Console.Variable;

{$I Doom32.inc}

interface

uses
  DelphiDoom.Configuration.Intf,
  DelphiDoom.Console.Types,
  DelphiDoom.Console.Intf;

type
  /// <summary>
  ///   One row of the table of the options seen by the console: the name, the type, who can
  ///   change it and its value (after a force: the value of before, as the old row did)
  /// </summary>
  TEngineConsoleVariable = class(TInterfacedObject, IConsoleVariable)
  strict private
    FItem: IConfigurationItem;
  public
    /// <remarks>Raises EArgumentNilException if AItem is nil</remarks>
    constructor Create(const AItem: IConfigurationItem);
    function Name: string;
    function Kind: TConsoleVariableKind;
    function Access: TConsoleAccess;
    function GetInteger: Integer;
    procedure SetInteger(AValue: Integer);
    function GetBoolean: Boolean;
    procedure SetBoolean(AValue: Boolean);
    function GetString: string;
    procedure SetString(const AValue: string);
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.Configuration.Types;

const
  SItemIsNil = 'TEngineConsoleVariable: the row is nil';

{ TEngineConsoleVariable }

constructor TEngineConsoleVariable.Create(const AItem: IConfigurationItem);
begin
  inherited Create;
  if not Assigned(AItem) then
    raise EArgumentNilException.Create(SItemIsNil);
  FItem := AItem;
end;

function TEngineConsoleVariable.Name: string;
begin
  Result := FItem.Name;
end;

function TEngineConsoleVariable.Kind: TConsoleVariableKind;
begin
  case FItem.Kind of
    cikInteger: Result := cvkInteger;
    cikBoolean: Result := cvkBoolean;
  else
    Result := cvkString;
  end;
end;

function TEngineConsoleVariable.Access: TConsoleAccess;
begin
  Result := [];
  if FItem.Setable and CONFIGURATION_SET_SINGLEPLAYER <> 0 then
    Include(Result, camSinglePlayer);
  if FItem.Setable and CONFIGURATION_SET_NETWORK <> 0 then
    Include(Result, camNetwork);
end;

function TEngineConsoleVariable.GetInteger: Integer;
begin
  Result := FItem.GetInteger;
end;

procedure TEngineConsoleVariable.SetInteger(AValue: Integer);
begin
  FItem.SetInteger(AValue);
end;

function TEngineConsoleVariable.GetBoolean: Boolean;
begin
  Result := FItem.GetBoolean;
end;

procedure TEngineConsoleVariable.SetBoolean(AValue: Boolean);
begin
  FItem.SetBoolean(AValue);
end;

function TEngineConsoleVariable.GetString: string;
begin
  Result := FItem.GetString;
end;

procedure TEngineConsoleVariable.SetString(const AValue: string);
begin
  FItem.SetString(AValue);
end;

end.

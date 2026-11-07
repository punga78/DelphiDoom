{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - a console variable made of a row of the table defaults  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Console.Variable;

{$I Doom32.inc}

interface

uses
  DelphiDoom.Console.Types,
  DelphiDoom.Console.Intf,
  m_defs;

type
  /// <summary>
  ///   One row of the table defaults seen by the console: the name, the type, who can change it
  ///   and the global it points to
  /// </summary>
  TEngineConsoleVariable = class(TInterfacedObject, IConsoleVariable)
  private
    FDefault: Pdefault_t;
  public
    constructor Create(const ADefault: Pdefault_t);
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
  d_delphi;

{ TEngineConsoleVariable }

constructor TEngineConsoleVariable.Create(const ADefault: Pdefault_t);
begin
  inherited Create;
  FDefault := ADefault;
end;

function TEngineConsoleVariable.Name: string;
begin
  Result := FDefault.name;
end;

function TEngineConsoleVariable.Kind: TConsoleVariableKind;
begin
  case FDefault._type of
    m_defs.tInteger: Result := cvkInteger;
    m_defs.tBoolean: Result := cvkBoolean;
  else
    Result := cvkString;
  end;
end;

function TEngineConsoleVariable.Access: TConsoleAccess;
begin
  Result := [];
  if FDefault.setable and DFS_SINGLEPLAYER <> 0 then
    Include(Result, camSinglePlayer);
  if FDefault.setable and DFS_NETWORK <> 0 then
    Include(Result, camNetwork);
end;

function TEngineConsoleVariable.GetInteger: Integer;
begin
  Result := PInteger(FDefault.location)^;
end;

procedure TEngineConsoleVariable.SetInteger(AValue: Integer);
begin
  PInteger(FDefault.location)^ := AValue;
end;

function TEngineConsoleVariable.GetBoolean: Boolean;
begin
  Result := PBoolean(FDefault.location)^;
end;

procedure TEngineConsoleVariable.SetBoolean(AValue: Boolean);
begin
  PBoolean(FDefault.location)^ := AValue;
end;

function TEngineConsoleVariable.GetString: string;
begin
  Result := PString(FDefault.location)^;
end;

procedure TEngineConsoleVariable.SetString(const AValue: string);
begin
  PString(FDefault.location)^ := AValue;
end;

end.

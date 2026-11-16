{******************************************************************************}
{                                                                              }
{  DelphiDoom: configuration library - a row of the table of the options       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Configuration.Item;

interface

uses
  DelphiDoom.Configuration.Types,
  DelphiDoom.Configuration.Intf;

type
  /// <summary>
  ///   A row of the table of the options: the default_t of m_defs without the pointers. The
  ///   variable is reached through an IConfigurationValueAccess; a forced row keeps the value
  ///   seen by the file and the console in its defaults, as the old row did when its pointer was
  ///   moved to its own default
  /// </summary>
  TConfigurationItem = class sealed(TInterfacedObject, IConfigurationItem)
  strict private
    FName: string;
    FKind: TConfigurationItemKind;
    FSetable: Byte;
    FDefaults: TConfigurationDefaults;
    FAccess: IConfigurationValueAccess;
    FForced: Boolean;
    procedure CheckKind(AKind: TConfigurationItemKind);
  public
    /// <param name="AAccess">The variable of the row; nil only for a group</param>
    /// <remarks>Raises EArgumentNilException when a row that is not a group has no access</remarks>
    constructor Create(const AName: string; AKind: TConfigurationItemKind; ASetable: Byte;
      const ADefaults: TConfigurationDefaults; const AAccess: IConfigurationValueAccess);
    function Name: string;
    function Kind: TConfigurationItemKind;
    function Setable: Byte;
    function Defaults: TConfigurationDefaults;
    function IsForced: Boolean;
    function GetInteger: Integer;
    procedure SetInteger(AValue: Integer);
    function GetBoolean: Boolean;
    procedure SetBoolean(AValue: Boolean);
    function GetString: string;
    procedure SetString(const AValue: string);
    function ActualInteger: Integer;
    function ActualBoolean: Boolean;
    function ActualString: string;
    procedure ResetToDefault;
    procedure ForceInteger(AValue: Integer);
    procedure ForceBoolean(AValue: Boolean);
    procedure ForceString(const AValue: string);
  end;

implementation

uses
  System.SysUtils;

const
  SAccessIsNil = 'TConfigurationItem: the row "%s" has no access to its variable';
  SWrongKind = 'TConfigurationItem: the row "%s" is not of the kind asked for';
  SGroupHasNoValue = 'TConfigurationItem: the row "%s" is a group and has no value';

{ TConfigurationItem }

constructor TConfigurationItem.Create(const AName: string; AKind: TConfigurationItemKind;
  ASetable: Byte; const ADefaults: TConfigurationDefaults;
  const AAccess: IConfigurationValueAccess);
begin
  inherited Create;
  if (AKind <> cikGroup) and not Assigned(AAccess) then
    raise EArgumentNilException.CreateFmt(SAccessIsNil, [AName]);
  FName := AName;
  FKind := AKind;
  FSetable := ASetable;
  FDefaults := ADefaults;
  FAccess := AAccess;
  FForced := False;
end;

procedure TConfigurationItem.CheckKind(AKind: TConfigurationItemKind);
begin
  if FKind = cikGroup then
    raise EConfigurationException.CreateFmt(SGroupHasNoValue, [FName]);
  if FKind <> AKind then
    raise EConfigurationException.CreateFmt(SWrongKind, [FName]);
end;

function TConfigurationItem.Name: string;
begin
  Result := FName;
end;

function TConfigurationItem.Kind: TConfigurationItemKind;
begin
  Result := FKind;
end;

function TConfigurationItem.Setable: Byte;
begin
  Result := FSetable;
end;

function TConfigurationItem.Defaults: TConfigurationDefaults;
begin
  Result := FDefaults;
end;

function TConfigurationItem.IsForced: Boolean;
begin
  Result := FForced;
end;

function TConfigurationItem.GetInteger: Integer;
begin
  CheckKind(cikInteger);
  if FForced then
    Result := FDefaults.IntegerValue
  else
    Result := FAccess.GetInteger;
end;

procedure TConfigurationItem.SetInteger(AValue: Integer);
begin
  CheckKind(cikInteger);
  if FForced then
    FDefaults.IntegerValue := AValue
  else
    FAccess.SetInteger(AValue);
end;

function TConfigurationItem.GetBoolean: Boolean;
begin
  CheckKind(cikBoolean);
  if FForced then
    Result := FDefaults.BooleanValue
  else
    Result := FAccess.GetBoolean;
end;

procedure TConfigurationItem.SetBoolean(AValue: Boolean);
begin
  CheckKind(cikBoolean);
  if FForced then
    FDefaults.BooleanValue := AValue
  else
    FAccess.SetBoolean(AValue);
end;

function TConfigurationItem.GetString: string;
begin
  CheckKind(cikString);
  if FForced then
    Result := FDefaults.StringValue
  else
    Result := FAccess.GetString;
end;

procedure TConfigurationItem.SetString(const AValue: string);
begin
  CheckKind(cikString);
  if FForced then
    FDefaults.StringValue := AValue
  else
    FAccess.SetString(AValue);
end;

function TConfigurationItem.ActualInteger: Integer;
begin
  CheckKind(cikInteger);
  Result := FAccess.GetInteger;
end;

function TConfigurationItem.ActualBoolean: Boolean;
begin
  CheckKind(cikBoolean);
  Result := FAccess.GetBoolean;
end;

function TConfigurationItem.ActualString: string;
begin
  CheckKind(cikString);
  Result := FAccess.GetString;
end;

procedure TConfigurationItem.ResetToDefault;
begin
  case FKind of
    cikInteger: SetInteger(FDefaults.IntegerValue);
    cikBoolean: SetBoolean(FDefaults.BooleanValue);
    cikString: SetString(FDefaults.StringValue);
  end;
end;

procedure TConfigurationItem.ForceInteger(AValue: Integer);
begin
  CheckKind(cikInteger);
  if not FForced then
  begin
    FDefaults.IntegerValue := FAccess.GetInteger;
    FForced := True;
    FSetable := CONFIGURATION_SET_NEVER;
  end;
  FAccess.SetInteger(AValue);
end;

procedure TConfigurationItem.ForceBoolean(AValue: Boolean);
begin
  CheckKind(cikBoolean);
  if not FForced then
  begin
    FDefaults.BooleanValue := FAccess.GetBoolean;
    FForced := True;
    FSetable := CONFIGURATION_SET_NEVER;
  end;
  FAccess.SetBoolean(AValue);
end;

procedure TConfigurationItem.ForceString(const AValue: string);
begin
  CheckKind(cikString);
  if not FForced then
  begin
    FDefaults.StringValue := FAccess.GetString;
    FForced := True;
    FSetable := CONFIGURATION_SET_NEVER;
  end;
  FAccess.SetString(AValue);
end;

end.

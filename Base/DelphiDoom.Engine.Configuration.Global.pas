{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the variable of an option of the configuration         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Configuration.Global;

{$I Doom32.inc}

interface

uses
  DelphiDoom.Configuration.Intf;

type
  /// <summary>
  ///   The small object that gives a row of Libs\Configuration the global of the engine it
  ///   describes: the location of a row of the table defaults (m_defs). Only the methods of the
  ///   kind of the row are called, as the old code read the pointer as PInteger, PBoolean or
  ///   PString according to the type of the row
  /// </summary>
  TEngineConfigurationGlobal = class sealed(TInterfacedObject, IConfigurationValueAccess)
  strict private
    FLocation: Pointer;
  public
    /// <remarks>Raises EArgumentNilException if ALocation is nil</remarks>
    constructor Create(ALocation: Pointer);
    function GetInteger: Integer;
    procedure SetInteger(AValue: Integer);
    function GetBoolean: Boolean;
    procedure SetBoolean(AValue: Boolean);
    function GetString: string;
    procedure SetString(const AValue: string);
  end;

implementation

uses
  System.SysUtils;

const
  SLocationIsNil = 'TEngineConfigurationGlobal: the location is nil';

{ TEngineConfigurationGlobal }

constructor TEngineConfigurationGlobal.Create(ALocation: Pointer);
begin
  inherited Create;
  if not Assigned(ALocation) then
    raise EArgumentNilException.Create(SLocationIsNil);
  FLocation := ALocation;
end;

function TEngineConfigurationGlobal.GetInteger: Integer;
begin
  Result := PInteger(FLocation)^;
end;

procedure TEngineConfigurationGlobal.SetInteger(AValue: Integer);
begin
  PInteger(FLocation)^ := AValue;
end;

function TEngineConfigurationGlobal.GetBoolean: Boolean;
begin
  Result := PBoolean(FLocation)^;
end;

procedure TEngineConfigurationGlobal.SetBoolean(AValue: Boolean);
begin
  PBoolean(FLocation)^ := AValue;
end;

function TEngineConfigurationGlobal.GetString: string;
begin
  Result := PString(FLocation)^;
end;

procedure TEngineConfigurationGlobal.SetString(const AValue: string);
begin
  PString(FLocation)^ := AValue;
end;

end.

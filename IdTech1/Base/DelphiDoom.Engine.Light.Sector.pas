{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - a sector seen by the lights                            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Light.Sector;

interface

uses
  r_defs,
  DelphiDoom.Thinkers.Light.Intf;

type
  /// <summary>
  ///   A sector of the level as the lights need it when they are made. It writes in the sector
  ///   itself (no copy): the light level and the special are 16 bit there, so a value that does
  ///   not fit is cut as it always was
  /// </summary>
  TEngineLightSector = class(TInterfacedObject, ILightSector)
  strict private
    FSector: Psector_t;
  public
    constructor Create(ASector: Psector_t);
    /// <summary>The sector as an ILightSector; nil for a sector that does not exist</summary>
    class function Wrap(ASector: Psector_t): ILightSector; static;
    function GetLightLevel: Integer;
    procedure SetLightLevel(AValue: Integer);
    function GetSpecial: Integer;
    procedure SetSpecial(AValue: Integer);
    function GetNeighborCount: Integer;
    function GetNeighbor(AIndex: Integer): ILightSector;
    function GetHandle: Pointer;
  end;

implementation

uses
  p_spec;

{ TEngineLightSector }

constructor TEngineLightSector.Create(ASector: Psector_t);
begin
  inherited Create;
  FSector := ASector;
end;

class function TEngineLightSector.Wrap(ASector: Psector_t): ILightSector;
begin
  if ASector = nil then
    Result := nil
  else
    Result := TEngineLightSector.Create(ASector);
end;

function TEngineLightSector.GetLightLevel: Integer;
begin
  Result := FSector.lightlevel;
end;

procedure TEngineLightSector.SetLightLevel(AValue: Integer);
begin
  FSector.lightlevel := SmallInt(AValue);
end;

function TEngineLightSector.GetSpecial: Integer;
begin
  Result := FSector.special;
end;

procedure TEngineLightSector.SetSpecial(AValue: Integer);
begin
  FSector.special := SmallInt(AValue);
end;

function TEngineLightSector.GetNeighborCount: Integer;
begin
  Result := FSector.linecount;
end;

function TEngineLightSector.GetNeighbor(AIndex: Integer): ILightSector;
begin
  Result := Wrap(getNextSector(FSector.lines[AIndex], FSector));
end;

function TEngineLightSector.GetHandle: Pointer;
begin
  Result := FSector;
end;

end.

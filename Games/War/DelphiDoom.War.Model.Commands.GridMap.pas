{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the map of the commands over the grid and the fog }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.Commands.GridMap;

interface

uses
  DelphiDoom.War.Map.PathGrid, DelphiDoom.War.Map.Fog, DelphiDoom.War.Model.Commands.Intf;

type
  /// <summary>
  ///   IWarCommandMap over the TWarPathGrid of a game map and, if given, its TWarFogOfWar (neither is owned). Without a
  ///   fog everything is visible, as the original with the fog of war turned off
  /// </summary>
  TWarGridCommandMap = class(TInterfacedObject, IWarCommandMap)
  strict private
    FGrid: TWarPathGrid;
    FFog: TWarFogOfWar;
  public
    constructor Create(const AGrid: TWarPathGrid; const AFog: TWarFogOfWar = nil);
    function EntityIdAt(ATileX, ATileY: Integer): Word;
    function IsTileVisible(ATileX, ATileY: Integer): Boolean;
    function IsTileFog(ATileX, ATileY: Integer): Boolean;
    function IsTileUnknown(ATileX, ATileY: Integer): Boolean;
    function IsAreaUnknown(ATileX, ATileY, AWidth, AHeight: Integer): Boolean;
    function IsAreaPartiallyVisible(ATileX, ATileY, AWidth, AHeight: Integer): Boolean;
  end;

implementation

uses
  DelphiDoom.War.Map.Types;

{ TWarGridCommandMap }

constructor TWarGridCommandMap.Create(const AGrid: TWarPathGrid; const AFog: TWarFogOfWar);
begin
  inherited Create;
  FGrid := AGrid;
  FFog := AFog;
end;

function TWarGridCommandMap.EntityIdAt(ATileX, ATileY: Integer): Word;
begin
  if not TWarPathGrid.IsInside(ATileX, ATileY) then
    Exit(0);
  Result := FGrid.GetTileEntityId(ATileX, ATileY);
end;

function TWarGridCommandMap.IsTileVisible(ATileX, ATileY: Integer): Boolean;
begin
  Result := not Assigned(FFog) or FFog.IsTileVisible(ATileX, ATileY);
end;

function TWarGridCommandMap.IsTileFog(ATileX, ATileY: Integer): Boolean;
begin
  Result := Assigned(FFog) and FFog.IsTileFog(ATileX, ATileY);
end;

function TWarGridCommandMap.IsTileUnknown(ATileX, ATileY: Integer): Boolean;
begin
  Result := Assigned(FFog) and FFog.IsTileUnknown(ATileX, ATileY);
end;

function TWarGridCommandMap.IsAreaUnknown(ATileX, ATileY, AWidth, AHeight: Integer): Boolean;
begin
  Result := Assigned(FFog) and FFog.AreAllTilesInState(ATileX, ATileY, AWidth, AHeight, wtsUnknown);
end;

function TWarGridCommandMap.IsAreaPartiallyVisible(ATileX, ATileY, AWidth, AHeight: Integer): Boolean;
begin
  Result := not Assigned(FFog) or FFog.IsAnyTileInState(ATileX, ATileY, AWidth, AHeight, wtsVisible);
end;

end.

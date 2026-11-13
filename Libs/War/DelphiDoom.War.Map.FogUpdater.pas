{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the update of the fog by the units                }
{                                                                              }
{  Port of war1 (acoto87/war1), war_map.c (updateFoW), (c) 2019 Alejandro Coto }
{  Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt). This is an altered }
{  version, not the original.                                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Map.FogUpdater;

{$R-}
{$Q-}

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.War.Map.Types, DelphiDoom.War.Map.Intf,
  DelphiDoom.War.Map.Fog;

type
  /// <summary>
  ///   updateFoW: the tiles in sight go to fog, then every unit of the player lights the tiles around it (its size
  ///   plus its sight range, without the four corners) and the buildings of the player are seen for good; an
  ///   enemy or neutral building that is in sight is seen too. Not here: the sight spells (Holy Sight, Dark Vision),
  ///   the target and the attacker of a unit that attacks (they need the states of the units, #194), the removal
  ///   of the selection
  /// </summary>
  TWarFogUpdater = class
  strict private
    FCatalog: IWarUnitCatalog;
    FPlayer: Byte;
  public
    /// <summary>The catalog gives the sight and the kind of each unit; APlayer is the player whose units light the map (players[0])</summary>
    constructor Create(const ACatalog: IWarUnitCatalog; APlayer: Byte);
    /// <summary>Updates the fog of AFog from the units; the units that become seen are changed in the list</summary>
    procedure Update(const AFog: TWarFogOfWar; const AUnits: TList<TWarMapUnit>);
  end;

implementation

{ TWarFogUpdater }

constructor TWarFogUpdater.Create(const ACatalog: IWarUnitCatalog; APlayer: Byte);
begin
  inherited Create;
  FCatalog := ACatalog;
  FPlayer := APlayer;
end;

procedure TWarFogUpdater.Update(const AFog: TWarFogOfWar; const AUnits: TList<TWarMapUnit>);
var
  LIndex: Integer;
  LUnit: TWarMapUnit;
  LSight: Integer;
begin
  AFog.BeginUpdate;
  // the friendly units first
  for LIndex := 0 to AUnits.Count - 1 do
  begin
    LUnit := AUnits[LIndex];
    if LUnit.Player <> FPlayer then
      Continue;
    LSight := FCatalog.SightRange(LUnit.UnitType);
    if FCatalog.IsBuildingType(LUnit.UnitType) then
    begin
      // the friendly buildings are always seen by the player
      LUnit.HasBeenSeen := True;
      AUnits[LIndex] := LUnit;
    end;
    AFog.SetState(LUnit.TileX - LSight, LUnit.TileY - LSight, LUnit.SizeX + 2 * LSight, LUnit.SizeY + 2 * LSight,
      wtsVisible);
  end;
  // and then the enemies and the neutrals
  for LIndex := 0 to AUnits.Count - 1 do
  begin
    LUnit := AUnits[LIndex];
    if LUnit.Player = FPlayer then
      Continue;
    if AFog.IsUnitPartiallyIn(LUnit, wtsVisible) and FCatalog.IsBuildingType(LUnit.UnitType) then
    begin
      LUnit.HasBeenSeen := True;
      AUnits[LIndex] := LUnit;
    end;
  end;
end;

end.

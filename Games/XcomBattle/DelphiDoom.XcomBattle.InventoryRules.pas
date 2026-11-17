{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape library - overlap of items in an inventory     }
{  Derived from OpenXcom (the OpenXcom Developers), available under the GNU    }
{  General Public License, version 3 or (at your option) any later version;    }
{  see Games\XcomFormats\README.md for the license of this unit                }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattle.InventoryRules;

interface

uses
  System.SysUtils, DelphiDoom.XcomMod.RuleInventory, DelphiDoom.XcomBattle.Model;

type
  /// <summary>The part of Inventory (the screen) that does not draw: which items cover a slot</summary>
  TXcomInventoryRules = class
  public
    /// <summary>Inventory::overlapItems: whether AItem placed at (AX, AY) of ASlot would overlap an item of AUnit</summary>
    class function OverlapItems(const AUnit: TXcomBattleUnit; const AItem: TXcomBattleItem;
      const ASlot: TXcomRuleInventory; AX, AY: Integer): Boolean; static;
  end;

implementation

class function TXcomInventoryRules.OverlapItems(const AUnit: TXcomBattleUnit; const AItem: TXcomBattleItem;
  const ASlot: TXcomRuleInventory; AX, AY: Integer): Boolean;
var
  LItem: TXcomBattleItem;
begin
  if ASlot.InventoryType <> INV_GROUND then
  begin
    for LItem in AUnit.Inventory do
      if (LItem.Slot = ASlot) and LItem.OccupiesSlot(AX, AY, AItem) then
        Exit(True);
  end
  else if Assigned(AUnit.Tile) then
  begin
    for LItem in AUnit.Tile.Inventory do
      if LItem.OccupiesSlot(AX, AY, AItem) then
        Exit(True);
  end;
  Result := False;
end;

end.

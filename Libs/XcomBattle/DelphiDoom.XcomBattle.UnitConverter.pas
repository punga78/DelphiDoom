{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape library - a zombie that becomes another unit    }
{  (SavedBattleGame::convertUnit)                                               }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattle.UnitConverter;

interface

uses
  System.SysUtils, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomMod.MapBlock, DelphiDoom.XcomBattle.Model, DelphiDoom.XcomBattle.SavedBattleGame,
  DelphiDoom.XcomBattle.TileEngine;

type
  /// <summary>
  ///   Replaces a unit that carries a spawn unit (a victim of a zombie, a zombie) with a new hostile unit of the
  ///   spawn type at the same place; the old unit dies. It belongs to the saved battle and the tile engine it is given
  /// </summary>
  TXcomUnitConverter = class
  strict private
    FSave: TXcomSavedBattleGame;
    FEngine: TXcomTileEngine;
    FRuleset: TXcomRuleset;
    FDifficulty: Integer;
  public
    constructor Create(const ASave: TXcomSavedBattleGame; const AEngine: TXcomTileEngine;
      const ARuleset: TXcomRuleset; ADifficulty: Integer);
    /// <summary>convertUnit: gives the new unit</summary>
    function Convert(const AUnit: TXcomBattleUnit): TXcomBattleUnit;
  end;

implementation

uses
  DelphiDoom.XcomBattle.Types, DelphiDoom.XcomBattle.AIModule, DelphiDoom.XcomMod.RuleUnit,
  DelphiDoom.XcomMod.RuleItem;

constructor TXcomUnitConverter.Create(const ASave: TXcomSavedBattleGame; const AEngine: TXcomTileEngine;
  const ARuleset: TXcomRuleset; ADifficulty: Integer);
begin
  inherited Create;
  FSave := ASave;
  FEngine := AEngine;
  FRuleset := ARuleset;
  FDifficulty := ADifficulty;
end;

function TXcomUnitConverter.Convert(const AUnit: TXcomBattleUnit): TXcomBattleUnit;
var
  LNewType: string;
  LVisible: Boolean;
  LItem: TXcomBattleItem;
  LRules: TXcomRuleUnit;
  LTerroristWeapon: string;
  LWeaponRules: TXcomRuleItem;
  LPosition: TXcomPosition;
  LNew: TXcomBattleUnit;
begin
  LNewType := AUnit.SpawnUnit;
  LVisible := AUnit.Visible;
  LPosition := AUnit.Position;
  // in case the unit was unconscious
  FSave.RemoveUnconsciousBodyItem(AUnit);
  AUnit.InstaKill;
  for LItem in AUnit.Inventory.ToArray do
  begin
    FEngine.ItemDrop(FSave.TileAt(LPosition), LItem, FRuleset.Inventories.Find('STR_GROUND'));
    LItem.SetOwner(nil);
  end;
  AUnit.Inventory.Clear;
  // remove unit-tile link
  AUnit.SetTile(nil);
  FSave.TileAt(LPosition).SetUnit(nil);
  LRules := FRuleset.Units.Find(LNewType);
  if not Assigned(LRules) then
    raise EXcomBattleException.CreateFmt('The unit rules %s do not exist', [LNewType]);
  LTerroristWeapon := Copy(LRules.Race, 5, MaxInt) + '_WEAPON';
  LWeaponRules := FRuleset.Items.Find(LTerroristWeapon);
  LNew := TXcomBattleUnit.Create(FSave.Context, LRules, FACTION_HOSTILE, FSave.Units.Last.Id + 1,
    FRuleset.Armors.Find(LRules.Armor), FRuleset.Settings.StatAdjustment[FDifficulty], FSave.Depth);
  FSave.TileAt(LPosition).SetUnit(LNew, FSave.TileAt(LPosition + TXcomPosition.Make(0, 0, -1)));
  LNew.SetPosition(LPosition);
  LNew.SetDirection(AUnit.Direction);
  LNew.CacheInvalid := True;
  LNew.SetTimeUnits(0);
  LNew.SetSpecialWeapon(FRuleset,
    function(ARules: TXcomRuleItem): TXcomBattleItem
    begin
      Result := FSave.MakeSpecialItem(ARules, LNew);
    end);
  FSave.Units.Add(LNew);
  LNew.AI := TXcomAIModule.Create(LNew, nil);
  if Assigned(LWeaponRules) then
  begin
    LItem := FSave.NewItem(LWeaponRules);
    LItem.MoveToOwner(LNew);
    LItem.Slot := FRuleset.Inventories.Find('STR_RIGHT_HAND');
    FSave.Items.Add(LItem);
  end;
  LNew.Visible := LVisible;
  FEngine.CalculateFovAt(LNew.Position);
  FEngine.ApplyGravity(LNew.Tile);
  LNew.DontReselect := True;
  Result := LNew;
end;

end.

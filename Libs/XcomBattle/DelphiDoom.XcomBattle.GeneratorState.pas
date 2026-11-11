{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape library - state shared by the generator parts   }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattle.GeneratorState;

interface

uses
  System.SysUtils, DelphiDoom.XcomMod.Random, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomMod.RuleItem,
  DelphiDoom.XcomMod.RuleTerrain, DelphiDoom.XcomMod.MapScript, DelphiDoom.XcomMod.ModFiles.Intf,
  DelphiDoom.XcomMod.MapDataLoader, DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomSave.Craft,
  DelphiDoom.XcomSave.Ufo, DelphiDoom.XcomSave.Base, DelphiDoom.XcomBattle.Types, DelphiDoom.XcomBattle.Model,
  DelphiDoom.XcomBattle.SavedBattleGame, DelphiDoom.XcomBattle.Intf, DelphiDoom.XcomBattle.Services.Intf,
  DelphiDoom.XcomBattle.ItemEquipper, DelphiDoom.XcomBattle.LegacyRandom;

type
  /// <summary>
  ///   What the parts of BattlescapeGenerator (the map, the units, the facade) share: the members of the C++ class
  ///   that more than one of them reads or writes. Holds everything without owning it, except the equipper
  /// </summary>
  TXcomGeneratorState = class
  strict private
    FEquipper: TXcomItemEquipper;
    FItemOwnerSave: TXcomSavedBattleGame;
  public
    Ruleset: TXcomRuleset;
    Save: TXcomSavedBattleGame;
    Game: TXcomSavedGame;
    Random: IXcomRandom;
    /// <summary>The rand() of the C library (colors of the units)</summary>
    LegacyRandom: TXcomLegacyRandom;
    Files: IXcomModFiles;
    MapLoader: TXcomMapDataLoader;
    TileEngine: IXcomGeneratorTileEngine;
    Context: IXcomBattleContext;
    Craft: TXcomCraft;
    Ufo: TXcomUfo;
    Base: TXcomBase;
    Terrain: TXcomRuleTerrain;
    MapSizeX: Integer;
    MapSizeY: Integer;
    MapSizeZ: Integer;
    WorldShade: Integer;
    AlienRace: string;
    AlienItemLevel: Integer;
    UnitSequence: Integer;
    CraftInventoryTile: TXcomTile;
    BaseInventory: Boolean;
    GenerateFuel: Boolean;
    CraftDeployed: Boolean;
    CraftZ: Integer;
    CraftPos: TXcomScriptRect;
    AllowAutoLoadout: Boolean;
    constructor Create(const ARuleset: TXcomRuleset; const ASave: TXcomSavedBattleGame;
      const AGame: TXcomSavedGame; const AContext: IXcomBattleContext;
      const ATileEngine: IXcomGeneratorTileEngine; const ALegacyRandom: TXcomLegacyRandom;
      AAllowAutoLoadout: Boolean);
    destructor Destroy; override;
    /// <summary>new BattleItem(rules, save->getCurrentItemId()): the saved battle owns the item</summary>
    function NewItem(const ARules: TXcomRuleItem): TXcomBattleItem;
    /// <summary>The item rules AType; raises EXcomBattleException if the mod does not have them (getItem(x, true))</summary>
    function ItemRules(const AType: string): TXcomRuleItem;
    /// <summary>The month the alien equipment is taken from (the item levels are a table by month)</summary>
    function AlienMonth: Integer;
    property Equipper: TXcomItemEquipper read FEquipper;
  end;

implementation

const
  SItemNotFound = 'Item %s not found.';

constructor TXcomGeneratorState.Create(const ARuleset: TXcomRuleset; const ASave: TXcomSavedBattleGame;
  const AGame: TXcomSavedGame; const AContext: IXcomBattleContext; const ATileEngine: IXcomGeneratorTileEngine;
  const ALegacyRandom: TXcomLegacyRandom; AAllowAutoLoadout: Boolean);
begin
  inherited Create;
  Ruleset := ARuleset;
  Save := ASave;
  Game := AGame;
  Context := AContext;
  Random := AContext.Random;
  TileEngine := ATileEngine;
  LegacyRandom := ALegacyRandom;
  Files := ARuleset.Files;
  MapLoader := TXcomMapDataLoader.Create(Files);
  AllowAutoLoadout := AAllowAutoLoadout;
  GenerateFuel := True;
  FEquipper := TXcomItemEquipper.Create(ARuleset, ASave, AAllowAutoLoadout);
end;

destructor TXcomGeneratorState.Destroy;
begin
  FEquipper.Free;
  MapLoader.Free;
  inherited Destroy;
end;

function TXcomGeneratorState.NewItem(const ARules: TXcomRuleItem): TXcomBattleItem;
var
  LId: Integer;
begin
  LId := Save.CurrentItemId;
  Result := TXcomBattleItem.Create(ARules, LId);
  Save.CurrentItemId := LId;
  Save.OwnItem(Result);
end;

function TXcomGeneratorState.ItemRules(const AType: string): TXcomRuleItem;
begin
  Result := Ruleset.Items.Find(AType);
  if not Assigned(Result) then
    raise EXcomBattleException.CreateFmt(SItemNotFound, [AType]);
end;

function TXcomGeneratorState.AlienMonth: Integer;
var
  LLevels: Integer;
begin
  if Game.MonthsPassed <> -1 then
  begin
    LLevels := Length(Ruleset.Settings.AlienItemLevels);
    if Cardinal(Game.MonthsPassed) > Cardinal(LLevels - 1) then
      Result := LLevels - 1
    else
      Result := Game.MonthsPassed;
  end
  else
    Result := AlienItemLevel;
end;

end.

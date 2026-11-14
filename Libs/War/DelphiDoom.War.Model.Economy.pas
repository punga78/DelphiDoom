{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - gold, lumber, food and upgrades                   }
{                                                                              }
{  Port of war1 (acoto87/war1), we_enoughPlayerResources,                      }
{  we_decreasePlayerResources, we_increasePlayerResources, we_enoughFarmFood,  }
{  we_checkFarmFood and we_increaseUpgradeLevel of war_entities.c,             }
{  (c) 2019 Alejandro Coto Gutierrez, zlib License (see                        }
{  Libs\War\LICENSE-war1.txt). This is an altered version.                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.Economy;

interface

uses
  System.SysUtils, DelphiDoom.War.Types, DelphiDoom.War.Model.Types, DelphiDoom.War.Model.Context,
  DelphiDoom.War.Model.Intf;

type
  /// <summary>
  ///   What a player has and can spend: gold and lumber, the food that the farms give (4 for each farm, plus 1) and the
  ///   levels of the upgrades. The messages for the player go to the events of the model
  /// </summary>
  TWarEconomy = class
  strict private
    FContext: TWarModelContext;
    FQueries: IWarUnitQueries;
  public
    constructor Create(const AContext: TWarModelContext; const AQueries: IWarUnitQueries);
    /// <summary>we_enoughPlayerResources</summary>
    function EnoughResources(APlayer: PWarPlayerInfo; AGold, AWood: Integer): Boolean;
    /// <summary>
    ///   we_decreasePlayerResources: all or nothing; gold is checked first and the message is the one of the first that is
    ///   missing
    /// </summary>
    function DecreaseResources(APlayer: PWarPlayerInfo; AGold, AWood: Integer): Boolean;
    /// <summary>we_increasePlayerResources</summary>
    procedure IncreaseResources(APlayer: PWarPlayerInfo; AGold, AWood: Integer);
    /// <summary>we_enoughFarmFood: the units that move plus one fit in the food of the finished farms</summary>
    function EnoughFarmFood(APlayer: PWarPlayerInfo): Boolean;
    /// <summary>we_checkFarmFood: the same, with the message of the status bar when there is no room</summary>
    function CheckFarmFood(APlayer: PWarPlayerInfo): Boolean;
    /// <summary>
    ///   we_increaseUpgradeLevel: the level goes up and the units of the player change (arrows and spears +2 damage, swords
    ///   and axes +1 or +2, horses and wolves a faster speed, shields +1 or +2 armor). EWarException if the level
    ///   is at its maximum (the original stops on an assert). The upgrades go in pairs (humans and orcs) that share a level
    /// </summary>
    procedure IncreaseUpgradeLevel(APlayer: PWarPlayerInfo; AUpgrade: Integer);
  end;

implementation

uses
  System.Generics.Collections, DelphiDoom.War.Level.Types, DelphiDoom.War.Model.UnitClassifier,
  DelphiDoom.War.Model.Purse;

{ TWarEconomy }

constructor TWarEconomy.Create(const AContext: TWarModelContext; const AQueries: IWarUnitQueries);
begin
  inherited Create;
  FContext := AContext;
  FQueries := AQueries;
end;

function TWarEconomy.EnoughResources(APlayer: PWarPlayerInfo; AGold, AWood: Integer): Boolean;
begin
  Result := TWarPurse.Enough(APlayer, AGold, AWood);
end;

function TWarEconomy.DecreaseResources(APlayer: PWarPlayerInfo; AGold, AWood: Integer): Boolean;
begin
  Result := TWarPurse.Decrease(FContext, APlayer, AGold, AWood);
end;

procedure TWarEconomy.IncreaseResources(APlayer: PWarPlayerInfo; AGold, AWood: Integer);
begin
  TWarPurse.Increase(APlayer, AGold, AWood);
end;

function TWarEconomy.EnoughFarmFood(APlayer: PWarPlayerInfo): Boolean;
var
  LFarmType: Integer;
  LFoodCount: Integer;
begin
  LFarmType := TWarUnitClassifier.TypeForRace(WAR_UNIT_FARM_HUMANS, APlayer^.Race);
  LFoodCount := FQueries.CountBuildingsOfType(APlayer^.Index, LFarmType, True) * 4 + 1;
  Result := FQueries.CountDudes(APlayer^.Index) + 1 <= LFoodCount;
end;

function TWarEconomy.CheckFarmFood(APlayer: PWarPlayerInfo): Boolean;
begin
  Result := EnoughFarmFood(APlayer);
  if not Result then
    FContext.Events.FlashStatus(wsmNotEnoughFood);
end;

procedure TWarEconomy.IncreaseUpgradeLevel(APlayer: PWarPlayerInfo; AUpgrade: Integer);
var
  LUpgrade: PWarUpgradeState;
  LUnits: TList<Integer>;
  LIndex: Integer;
  LEntity: PWarEntity;
  LUnit: PWarUnitComponent;
  LLevel: Integer;
begin
  LUpgrade := @APlayer^.Upgrades[AUpgrade div 2];
  if LUpgrade^.Level >= LUpgrade^.Allowed then
    raise EWarException.CreateFmt(SWarModelNoUpgradeLeft, [AUpgrade]);
  Inc(LUpgrade^.Level);
  LLevel := LUpgrade^.Level;
  LUnits := FContext.Pool.OfType[WAR_ENTITY_UNIT];
  for LIndex := 0 to LUnits.Count - 1 do
  begin
    LEntity := FContext.Pool.Slots[LUnits[LIndex]];
    if not LEntity^.HasUnit then
      Continue;
    LUnit := @LEntity^.UnitData;
    if LUnit^.Player <> APlayer^.Index then
      Continue;
    case AUpgrade of
      WAR_UPGRADE_ARROWS, WAR_UPGRADE_SPEARS:
        if (LUnit^.UnitType = WAR_UNIT_ARCHER) or (LUnit^.UnitType = WAR_UNIT_SPEARMAN) then
          Inc(LUnit^.MinDamage, 2);
      WAR_UPGRADE_SWORDS, WAR_UPGRADE_AXES:
        if LUnit^.UnitType in [WAR_UNIT_FOOTMAN, WAR_UNIT_GRUNT, WAR_UNIT_KNIGHT, WAR_UNIT_RAIDER] then
        begin
          if LLevel = 1 then
          begin
            Inc(LUnit^.MinDamage, 1);
            Inc(LUnit^.RndDamage, 1);
          end
          else if LLevel = 2 then
          begin
            Inc(LUnit^.MinDamage, 2);
            Inc(LUnit^.RndDamage, 2);
          end;
        end;
      WAR_UPGRADE_HORSES, WAR_UPGRADE_WOLVES:
        if TWarUnitClassifier.IsDude(LUnit^.UnitType) then
          Inc(LUnit^.Speed);
      WAR_UPGRADE_SHIELD:
        if LLevel = 1 then
          Inc(LUnit^.Armor, 1)
        else if LLevel = 2 then
          Inc(LUnit^.Armor, 2);
    end;
  end;
end;

end.

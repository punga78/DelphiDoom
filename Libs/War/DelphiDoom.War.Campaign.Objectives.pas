{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - victory and defeat                                }
{                                                                              }
{  Port of war1 (acoto87/war1), wcamp_checkMap01Objectives,                    }
{  wcamp_checkMap02Objectives and wcamp_checkCustomMapObjectives of            }
{  war_campaigns.c, (c) 2019 Alejandro Coto Gutierrez, zlib License (see       }
{  Libs\War\LICENSE-war1.txt). This is an altered version, not the original.   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Campaign.Objectives;

interface

uses
  System.SysUtils, DelphiDoom.War.Campaign.Types, DelphiDoom.War.Campaign.Intf;

type
  /// <summary>
  ///   Map 1 (humans and orcs): win with 6 farms and a barracks built, lose with no unit left. Map 2: win when
  ///   the enemy has no fighters, lose with no unit left. Custom map: win when the enemy has no unit, lose with
  ///   no unit left. The original checks the win first. The other campaign maps have no condition in the
  ///   remake: wlrNone. The campaign data decide the rule of a map (TWarCampaigns)
  /// </summary>
  TWarObjectives = class(TInterfacedObject, IWarObjectives)
  strict private
    FCampaigns: IWarCampaigns;
    function CheckBuildFarmsAndBarracks(const ACensus: IWarCensus): TWarLevelResult;
    function CheckDefendAndDestroy(const ACensus: IWarCensus): TWarLevelResult;
    function CheckDestroyEnemy(const ACensus: IWarCensus): TWarLevelResult;
  public
    constructor Create; overload;
    /// <param name="ACampaigns">Where the rule of each map is</param>
    constructor Create(const ACampaigns: IWarCampaigns); overload;
    function Check(AMapType: Integer; const ACensus: IWarCensus): TWarLevelResult;
  end;

implementation

uses
  DelphiDoom.War.Level.Types, DelphiDoom.War.Campaign.Catalog;

{ TWarObjectives }

constructor TWarObjectives.Create;
begin
  Create(TWarCampaigns.Create);
end;

constructor TWarObjectives.Create(const ACampaigns: IWarCampaigns);
begin
  inherited Create;
  FCampaigns := ACampaigns;
end;

function TWarObjectives.Check(AMapType: Integer; const ACensus: IWarCensus): TWarLevelResult;
begin
  case FCampaigns.GetData(AMapType).Rule of
    worBuildFarmsAndBarracks: Result := CheckBuildFarmsAndBarracks(ACensus);
    worDefendAndDestroy: Result := CheckDefendAndDestroy(ACensus);
    worDestroyEnemy: Result := CheckDestroyEnemy(ACensus);
  else
    Result := wlrNone;
  end;
end;

function TWarObjectives.CheckBuildFarmsAndBarracks(const ACensus: IWarCensus): TWarLevelResult;
var
  LFarm: Byte;
  LBarracks: Byte;
begin
  // wcamp_checkMap01Objectives
  if ACensus.GetPlayerRace(0) = wraHumans then
  begin
    LFarm := WAR_UNIT_FARM_HUMANS;
    LBarracks := WAR_UNIT_BARRACKS_HUMANS;
  end
  else
  begin
    LFarm := WAR_UNIT_FARM_ORCS;
    LBarracks := WAR_UNIT_BARRACKS_ORCS;
  end;
  if (ACensus.GetBuildingsOfType(0, LFarm) >= 6) and (ACensus.GetBuildingsOfType(0, LBarracks) >= 1) then
    Exit(wlrWin);
  if ACensus.GetTotalUnits(0) = 0 then
    Exit(wlrLose);
  Result := wlrNone;
end;

function TWarObjectives.CheckDefendAndDestroy(const ACensus: IWarCensus): TWarLevelResult;
begin
  // wcamp_checkMap02Objectives
  if ACensus.GetTotalDudes(1) = 0 then
    Exit(wlrWin);
  if ACensus.GetTotalUnits(0) = 0 then
    Exit(wlrLose);
  Result := wlrNone;
end;

function TWarObjectives.CheckDestroyEnemy(const ACensus: IWarCensus): TWarLevelResult;
begin
  // wcamp_checkCustomMapObjectives
  if ACensus.GetTotalUnits(1) = 0 then
    Exit(wlrWin);
  if ACensus.GetTotalUnits(0) = 0 then
    Exit(wlrLose);
  Result := wlrNone;
end;

end.

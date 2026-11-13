{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - types of the campaigns                            }
{                                                                              }
{  Port of war1 (acoto87/war1), war_campaigns.h and the enums of               }
{  war_enums.h, (c) 2019 Alejandro Coto Gutierrez, zlib License (see           }
{  Libs\War\LICENSE-war1.txt). This is an altered version, not the original.   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Campaign.Types;

interface

const
  /// <summary>WAR_CAMPAIGN_HUMANS_01: the campaign maps are the level info records 117 to 140, humans and orcs alternating</summary>
  WAR_CAMPAIGN_HUMANS_01 = 117;
  WAR_CAMPAIGN_ORCS_01 = 118;
  WAR_CAMPAIGN_HUMANS_02 = 119;
  WAR_CAMPAIGN_ORCS_02 = 120;
  WAR_CAMPAIGN_ORCS_12 = 140;
  /// <summary>WAR_CAMPAIGN_CUSTOM: any other level (a map of the skirmish menu)</summary>
  WAR_CAMPAIGN_CUSTOM = 141;
  /// <summary>Entries of the table: 24 campaign maps and the custom one</summary>
  WAR_CAMPAIGN_COUNT = 25;
  /// <summary>Missions of each campaign</summary>
  WAR_CAMPAIGN_MISSIONS = 12;

type
  /// <summary>WarLevelResult of war_enums.h</summary>
  TWarLevelResult = (wlrNone, wlrWin, wlrLose);

  /// <summary>
  ///   Which of the three condition functions of the original a map has (the other 21 campaign maps have none: the
  ///   remake only plays the two missions of the demo)
  /// </summary>
  TWarObjectiveRule = (worNone, worBuildFarmsAndBarracks, worDefendAndDestroy, worDestroyEnemy);

  /// <summary>WarCampaignMapData: objectives, briefing and the rule of victory of a map</summary>
  TWarCampaignMapData = record
    MapType: Integer;
    Rule: TWarObjectiveRule;
    /// <summary>The short text of the objectives (lines separated by LF, a tab or spaces to indent)</summary>
    Objectives: AnsiString;
    /// <summary>WarAudioId of the spoken briefing (551 to 574; 0 for the custom map). The audio is #198</summary>
    BriefingAudioId: Integer;
    BriefingText: AnsiString;
    /// <summary>Seconds the briefing screen stays</summary>
    BriefingDuration: Single;
  end;

implementation

end.

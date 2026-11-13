{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the ids of the sounds the game picks               }
{                                                                              }
{  Port of war1 (acoto87/war1), WarAudioId of war_enums.h, (c) 2019 Alejandro   }
{  Coto Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt). This is an     }
{  altered version, not the original.                                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Sound.Ids;

interface

const
  /// <summary>No sound: what a choice that does not play gives</summary>
  WAR_SND_NONE = -1;

  WAR_SND_LOGO = 472;
  WAR_SND_INTRO_DOOR = 473;
  WAR_SND_BUILDING = 474;
  WAR_SND_EXPLOSION = 475;
  WAR_SND_CATAPULT_ROCK_FIRED = 476;
  WAR_SND_TREE_CHOPPING_FIRST = 477;
  WAR_SND_TREE_CHOPPING_LAST = 480;
  WAR_SND_BUILDING_COLLAPSE_FIRST = 481;
  WAR_SND_BUILDING_COLLAPSE_LAST = 483;
  WAR_SND_UI_CHIME = 484;
  WAR_SND_UI_CLICK = 485;
  WAR_SND_UI_CANCEL = 486;
  WAR_SND_SWORD_ATTACK_FIRST = 487;
  WAR_SND_SWORD_ATTACK_LAST = 489;
  WAR_SND_FIST_ATTACK = 490;
  WAR_SND_CATAPULT_FIRE_EXPLOSION = 491;
  WAR_SND_FIREBALL = 492;
  WAR_SND_ARROW_SPEAR = 493;
  WAR_SND_ARROW_SPEAR_HIT = 494;
  WAR_SND_ORC_DEAD = 499;
  WAR_SND_HUMAN_DEAD = 500;
  WAR_SND_ORC_WORK_COMPLETE = 501;
  WAR_SND_HUMAN_WORK_COMPLETE = 502;
  WAR_SND_ORC_READY = 507;
  WAR_SND_HUMAN_READY = 508;
  WAR_SND_ORC_ACKNOWLEDGEMENT_FIRST = 509;
  WAR_SND_ORC_ACKNOWLEDGEMENT_LAST = 512;
  WAR_SND_HUMAN_ACKNOWLEDGEMENT_FIRST = 513;
  WAR_SND_HUMAN_ACKNOWLEDGEMENT_LAST = 514;
  WAR_SND_ORC_SELECTED_FIRST = 515;
  WAR_SND_ORC_SELECTED_LAST = 519;
  WAR_SND_HUMAN_SELECTED_FIRST = 520;
  WAR_SND_HUMAN_SELECTED_LAST = 524;
  WAR_SND_ORC_ANNOYED_FIRST = 525;
  WAR_SND_ORC_ANNOYED_LAST = 527;
  WAR_SND_HUMAN_ANNOYED_FIRST = 528;
  WAR_SND_HUMAN_ANNOYED_LAST = 530;
  WAR_SND_DEAD_SPIDER_SCORPION = 531;
  WAR_SND_NORMAL_SPELL = 532;
  WAR_SND_BUILD_ROAD = 533;
  WAR_SND_ORC_TEMPLE = 534;
  WAR_SND_HUMAN_CHURCH = 535;
  WAR_SND_ORC_KENNEL = 536;
  WAR_SND_HUMAN_STABLE = 537;
  WAR_SND_BLACKSMITH = 538;
  WAR_SND_FIRE_CRACKLING = 539;
  WAR_SND_CAMPAIGNS_HUMAN_ENDING_FIRST = 542;
  WAR_SND_CAMPAIGNS_HUMAN_ENDING_LAST = 543;
  WAR_SND_CAMPAIGNS_ORC_ENDING_FIRST = 544;
  WAR_SND_CAMPAIGNS_ORC_ENDING_LAST = 545;
  WAR_SND_INTRO_FIRST = 546;
  WAR_SND_INTRO_LAST = 550;
  /// <summary>The briefing of the mission 1 of the humans (WAR_CAMPAIGNS_HUMAN_01_INTRO); the 12 are in a row</summary>
  WAR_SND_CAMPAIGNS_HUMAN_INTRO_FIRST = 551;
  /// <summary>The briefing of the mission 1 of the orcs (WAR_CAMPAIGNS_ORC_01_INTRO); the 12 are in a row</summary>
  WAR_SND_CAMPAIGNS_ORC_INTRO_FIRST = 563;
  WAR_SND_HUMAN_DEFEAT = 575;
  WAR_SND_ORC_DEFEAT = 576;
  WAR_SND_ORC_VICTORY_FIRST = 577;
  WAR_SND_ORC_VICTORY_LAST = 579;
  WAR_SND_HUMAN_VICTORY_FIRST = 580;
  WAR_SND_HUMAN_VICTORY_LAST = 582;

implementation

end.

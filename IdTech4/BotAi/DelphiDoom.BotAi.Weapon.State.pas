{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotWeaponState, the weapon state of a bot             }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): bot_weaponstate_t   }
{  of code\botlib\be_ai_weap.c. Based on the Quake III Arena GPL Source Code   }
{  (id Software). Copyright (C) 1999-2005 Id Software, Inc.                    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Weapon.State;

interface

uses
  DelphiDoom.BotAi.Weight.Config;

type
  /// <summary>
  ///   bot_weaponstate_t: the weights of the weapons of a bot and, for every weapon of the table, the
  ///   number of its weight in the file (-1 if the file has none). The configuration belongs to the weight
  ///   library; the state only refers to it.
  /// </summary>
  TBotWeaponState = class
  public
    WeaponWeights: TBotWeightConfig;
    WeaponWeightIndex: TArray<Integer>;
  end;

implementation

end.

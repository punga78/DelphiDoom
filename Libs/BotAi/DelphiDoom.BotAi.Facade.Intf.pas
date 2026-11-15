{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - IBotAi, the systems of the bot AI of Quake III Arena   }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software):                 }
{  code\botlib\be_interface.c (the AI half of the library export table).       }
{  Licensed under the GNU General Public License, version 2 or later.          }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Facade.Intf;

interface

uses
  DelphiDoom.BotAi.Character.Intf, DelphiDoom.BotAi.Chat.Intf, DelphiDoom.BotAi.Weapon.Intf,
  DelphiDoom.BotAi.Weight.Intf, DelphiDoom.BotAi.Goal.Intf, DelphiDoom.BotAi.Move.Intf, DelphiDoom.BotAi.Gen.Intf,
  DelphiDoom.BotAi.Ea.Intf;

type
  /// <summary>
  ///   What the game gets from the library for the AI of the bots (the <c>botlib_export_t</c> of the original, ai_export
  ///   and ea_export): every system is a state table with the handles of the C (characters, chats, weapon, goal and
  ///   move states 1..64) and none shares data with another one except through this object.
  /// </summary>
  IBotAi = interface
    ['{3A8D5C61-7B24-4E0F-9C13-5D6E21F0A7B4}']
    function Characters: IBotCharacterSystem;
    function Chat: IBotChatSystem;
    function Weights: IBotWeightCache;
    function Weapons: IBotWeaponSystem;
    function Goals: IBotGoalSystem;
    function Moves: IBotMoveSystem;
    function Genetics: IBotGenetics;
    function Actions: IBotElementaryActions;
  end;

implementation

end.

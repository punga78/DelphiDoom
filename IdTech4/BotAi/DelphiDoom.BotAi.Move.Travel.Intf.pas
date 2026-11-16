{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - contract of a travel type of the movement              }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): the             }
{  BotTravel_* and BotFinishTravel_* functions of code\botlib\be_ai_move.c.    }
{  Copyright (C) 1999-2005 Id Software, Inc. This unit is derived from the     }
{  Quake III Arena source code and is therefore available under the GNU        }
{  General Public License, version 2 or (at your option) any later version.    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Move.Travel.Intf;

interface

uses
  DelphiDoom.Aas.Types, DelphiDoom.BotAi.Move.Types, DelphiDoom.BotAi.Move.State;

type
  /// <summary>
  ///   How a bot moves along a reachability of one travel type: <c>Travel</c> while the bot is on the ground, in the
  ///   water or at a ladder; <c>FinishTravel</c> when it is in the air. Both send the elementary actions of the frame.
  /// </summary>
  IBotTravelType = interface
    ['{4F0C1A52-7B63-4C57-9E2D-3A6B8D1E0F97}']
    /// <summary>BotTravel_*</summary>
    function Travel(const AState: TBotMoveState; const AReach: TAasReachability): TBotMoveResult;
    /// <summary>BotFinishTravel_* (for the types where the original does nothing, an empty result)</summary>
    function FinishTravel(const AState: TBotMoveState; const AReach: TAasReachability): TBotMoveResult;
  end;

  /// <summary>The grapple hook is put away when the bot is not using its reachability any more (BotResetGrapple)</summary>
  IBotGrappleReset = interface
    ['{4F0C1A52-7B63-4C57-9E2D-3A6B8D1E0F98}']
    procedure ResetGrapple(const AState: TBotMoveState);
  end;

implementation

end.

{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - contract of the elementary actions (be_ea.c)           }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software). Copyright (C)   }
{  1999-2005 Id Software, Inc. This unit is derived from the Quake III Arena   }
{  source code and is therefore available under the GNU General Public         }
{  License, version 2 or (at your option) any later version.                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Ea.Intf;

interface

uses
  DelphiDoom.MathCore.Types, DelphiDoom.BotAi.Ea.Types;

type
  /// <summary>
  ///   The elementary actions of the bots (EA_*): the AI sets them and the game reads the bot input of a client
  ///   (EA_GetInput) when it makes the user command.
  /// </summary>
  IBotElementaryActions = interface
    ['{4F0C1A52-7B63-4C57-9E2D-3A6B8D1E0F91}']
    /// <summary>EA_Say: the command "say text" of the client</summary>
    procedure Say(const AClient: Integer; const AText: AnsiString);
    /// <summary>EA_SayTeam: "say_team text"</summary>
    procedure SayTeam(const AClient: Integer; const AText: AnsiString);
    /// <summary>EA_Tell: "tell client, text"</summary>
    procedure Tell(const AClient, AClientTo: Integer; const AText: AnsiString);
    /// <summary>EA_UseItem: "use item"</summary>
    procedure UseItem(const AClient: Integer; const AItem: AnsiString);
    /// <summary>EA_DropItem: "drop item"</summary>
    procedure DropItem(const AClient: Integer; const AItem: AnsiString);
    /// <summary>EA_UseInv: "invuse inv"</summary>
    procedure UseInv(const AClient: Integer; const AInventory: AnsiString);
    /// <summary>EA_DropInv: "invdrop inv"</summary>
    procedure DropInv(const AClient: Integer; const AInventory: AnsiString);
    /// <summary>EA_Command: any command line of the client</summary>
    procedure Command(const AClient: Integer; const ACommand: AnsiString);
    procedure Gesture(const AClient: Integer);
    procedure SelectWeapon(const AClient, AWeapon: Integer);
    procedure Attack(const AClient: Integer);
    procedure Talk(const AClient: Integer);
    procedure Use(const AClient: Integer);
    procedure Respawn(const AClient: Integer);
    /// <summary>EA_Jump: no jump flag if the bot jumped in the last frame (the jump must be released)</summary>
    procedure Jump(const AClient: Integer);
    procedure DelayedJump(const AClient: Integer);
    procedure Crouch(const AClient: Integer);
    procedure Walk(const AClient: Integer);
    /// <summary>EA_Action: adds action flags</summary>
    procedure Action(const AClient, AAction: Integer);
    procedure MoveUp(const AClient: Integer);
    procedure MoveDown(const AClient: Integer);
    procedure MoveForward(const AClient: Integer);
    procedure MoveBack(const AClient: Integer);
    procedure MoveLeft(const AClient: Integer);
    procedure MoveRight(const AClient: Integer);
    /// <summary>EA_Move: the direction and the speed (limited to plus or minus 400)</summary>
    procedure Move(const AClient: Integer; const ADir: TVec3; const ASpeed: Single);
    procedure View(const AClient: Integer; const AViewAngles: TVec3);
    /// <summary>EA_GetInput: the input of the client with the think time</summary>
    function GetInput(const AClient: Integer; const AThinkTime: Single): TBotInput;
    /// <summary>EA_ResetInput: starts the next frame (the jump flag becomes "jumped last frame")</summary>
    procedure ResetInput(const AClient: Integer);
  end;

implementation

end.

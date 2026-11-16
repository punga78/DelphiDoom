{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - what the player functions of the scripts ask of   }
{  the engine                                                                  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  IScriptPlayerSource is the only door to players[]: the library checks the   }
{  player and the index of what is asked (the engine says how many there are   }
{  of each) and builds what scripts see; the engine answers with the raw       }
{  data and knows how its game keeps keys, weapons and ammunition.             }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.Players.Intf;

interface

uses
  DelphiDoom.ScriptHost.Intf;

type
  /// <summary>
  ///   The players of the game for the scripts. The numbers of players and indexes arrive
  ///   already checked (the player is in the game, the index is lower than the count of what
  ///   is asked); a game that does not have a thing answers 0 for its count
  /// </summary>
  IScriptPlayerSource = interface
    ['{7A3C5E92-D014-4F68-B2A9-3E81C6D07F45}']
    /// <summary>MAXPLAYERS</summary>
    function MaxPlayers: Integer;
    function InGame(const APlayer: Integer): Boolean;
    /// <summary>The number of cards (Doom, Strife) or of keys (Heretic, Hexen)</summary>
    function KeyCount: Integer;
    function HasKey(const APlayer: Integer; const AKey: Integer): Boolean;
    procedure SetKey(const APlayer: Integer; const AKey: Integer; const AValue: Boolean);
    /// <summary>The artifacts (Heretic and Hexen; 0 for the other games)</summary>
    function ArtifactCount: Integer;
    procedure UseArtifact(const APlayer: Integer; const AArtifact: Integer);
    function GiveArtifact(const APlayer: Integer; const AArtifact: Integer): Boolean;
    /// <summary>How many of an artifact the player has in the slots of the inventory</summary>
    function ArtifactAmount(const APlayer: Integer; const AArtifact: Integer): Integer;
    function WeaponCount: Integer;
    function HasWeapon(const APlayer: Integer; const AWeapon: Integer): Boolean;
    /// <summary>Gives the weapon to the player (nothing takes it away: see SetPlayerHasWeapon)</summary>
    procedure GiveWeapon(const APlayer: Integer; const AWeapon: Integer);
    /// <summary>The kinds of ammunition (Doom, Heretic, Strife) or of mana (Hexen)</summary>
    function ReserveCount: Integer;
    function Reserve(const APlayer: Integer; const AKind: Integer): Integer;
    procedure SetReserve(const APlayer: Integer; const AKind: Integer; const AValue: Integer);
    /// <summary>The class of the player (Hexen)</summary>
    function PlayerClass(const APlayer: Integer): Integer;
    function Message(const APlayer: Integer): string;
    procedure SetMessage(const APlayer: Integer; const AText: string);
    function ExtraLight(const APlayer: Integer): Integer;
    procedure SetExtraLight(const APlayer: Integer; const AValue: Integer);
    function PowerCount: Integer;
    function PowerTicks(const APlayer: Integer; const APower: Integer): Integer;
    procedure SetPowerTicks(const APlayer: Integer; const APower: Integer; const ATicks: Integer);
    function ViewZ(const APlayer: Integer): Integer;
    function ViewHeight(const APlayer: Integer): Integer;
    /// <summary>The key of the actor of the player, SCRIPT_INVALID_ID if it has none</summary>
    function ActorKey(const APlayer: Integer): Cardinal;
    function ConsolePlayer: Integer;
    /// <summary>The quests of the player (Strife)</summary>
    function QuestFlags(const APlayer: Integer): Cardinal;
    procedure SetQuestFlags(const APlayer: Integer; const AFlags: Cardinal);
    /// <summary>Turns the player towards an actor for some tics (Doom and Strife); the actor can be nil</summary>
    procedure FaceActor(const APlayer: Integer; const AActorKey: Cardinal; const ATicks: Integer);
  end;

  /// <summary>The player functions of the scripts</summary>
  IScriptPlayers = interface(IScriptFunctionSection)
    ['{E15B8D37-4A92-4C06-8F73-B20A9C61D4E8}']
    function PlayerInGame(const APlayer: Integer): Boolean;
    procedure PlayerFaceMobj(const APlayer: Integer; const AActor: Cardinal; const ATicks: Integer);
    procedure SetPlayerHasKey(const APlayer: Integer; const AKey: Integer; const AValue: Boolean);
    function GetPlayerHasKey(const APlayer: Integer; const AKey: Integer): Boolean;
    procedure PlayerUseArtifact(const APlayer: Integer; const AArtifact: Integer);
    function GiveArtifactToPlayer(const APlayer: Integer; const AArtifact: Integer): Boolean;
    function CheckPlayerArtifact(const APlayer: Integer; const AArtifact: Integer): Integer;
    procedure SetPlayerHasWeapon(const APlayer: Integer; const AWeapon: Integer; const AValue: Boolean);
    function GetPlayerHasWeapon(const APlayer: Integer; const AWeapon: Integer): Boolean;
    procedure SetPlayerReserve(const APlayer: Integer; const AKind: Integer; const AValue: Integer);
    function GetPlayerReserve(const APlayer: Integer; const AKind: Integer): Integer;
    function GetPlayerClass(const APlayer: Integer): Integer;
    procedure SetPlayerMessage(const APlayer: Integer; const AText: string);
    function GetPlayerMessage(const APlayer: Integer): string;
    procedure SetPlayerExtraLight(const APlayer: Integer; const AValue: Integer);
    function GetPlayerExtraLight(const APlayer: Integer): Integer;
    procedure SetPlayerPowerTicks(const APlayer: Integer; const APower: Integer; const ATicks: Integer);
    function GetPlayerPowerTicks(const APlayer: Integer; const APower: Integer): Integer;
    function GetPlayerViewZ(const APlayer: Integer): Integer;
    function GetPlayerViewHeight(const APlayer: Integer): Integer;
    function GetPlayerActor(const APlayer: Integer): Cardinal;
    function ConsolePlayer: Integer;
    function CheckPlayerQuest(const APlayer: Integer; const AQuest: Cardinal): Boolean;
    procedure SetPlayerQuest(const APlayer: Integer; const AQuest: Cardinal);
    procedure UnSetPlayerQuest(const APlayer: Integer; const AQuest: Cardinal);
  end;

implementation

end.

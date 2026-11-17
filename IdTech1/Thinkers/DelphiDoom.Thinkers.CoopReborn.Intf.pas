{******************************************************************************}
{                                                                              }
{  DelphiDoom: thinkers library - what the reborn of a Hexen player asks      }
{  the game                                                                    }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Thinkers.CoopReborn.Intf;

interface

type
  /// <summary>
  ///   What G_DoReborn of Hexen needs from the game: the records of the players and of the
  ///   starting points of the current hub position stay on its side
  /// </summary>
  /// <remarks>
  ///   Every method is called in the order, and as many times, as the old code did: CheckSpot has
  ///   side effects (fog, sound, corpse), so the caller must stop at the first spot that is free
  /// </remarks>
  ICoopRebornHost = interface
    ['{2C6E9B14-58A3-4D07-B1E9-7A40C35D8F62}']
    /// <summary>SV_RebornSlotAvailable: the game saved the hub position, so the player can come back to it</summary>
    function RebornSlotAvailable: Boolean;
    /// <summary>The game action of the single player case: load the saved hub position or start a new game</summary>
    procedure RequestGameAction(const ALoadHubPosition: Boolean);
    /// <summary>The body of the dead player stops being the body of that player</summary>
    procedure DetachCorpse(const APlayer: Integer);
    /// <summary>G_DeathMatchSpawnPlayer</summary>
    procedure SpawnDeathMatch(const APlayer: Integer);
    /// <summary>G_CheckSpot on playerstarts[RebornPosition][AIndex]: false if something occupies the spot</summary>
    function CheckSpot(const APlayer, AIndex: Integer): Boolean;
    /// <summary>P_SpawnPlayer on playerstarts[RebornPosition][AIndex] and the extra data of the same index</summary>
    procedure Spawn(const AIndex: Integer);
    /// <summary>Writes the type of the start: it tells which player starts there (player + 1)</summary>
    procedure SetSpotType(const AIndex, AType: Integer);
    /// <summary>The keys of the player (a bit mask)</summary>
    function Keys(const APlayer: Integer): Integer;
    procedure SetKeys(const APlayer, AKeys: Integer);
    /// <summary>The pieces of the fourth weapon of the player (a bit mask)</summary>
    function Pieces(const APlayer: Integer): Integer;
    procedure SetPieces(const APlayer, APieces: Integer);
    /// <summary>NUMWEAPONS of the game</summary>
    function WeaponCount: Integer;
    function WeaponOwned(const APlayer, AWeapon: Integer): Boolean;
    procedure GiveWeapon(const APlayer, AWeapon: Integer);
    /// <summary>Both kinds of mana of the player are set (the amount is the same)</summary>
    procedure SetMana(const APlayer, AAmount: Integer);
    /// <summary>The weapon the player takes in hand next</summary>
    procedure SetPendingWeapon(const APlayer, AWeapon: Integer);
  end;

implementation

end.

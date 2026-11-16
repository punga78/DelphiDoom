{******************************************************************************}
{                                                                              }
{  DelphiDoom: thinkers library - what the respawn of a player asks the game   }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Thinkers.PlayerRespawn.Intf;

interface

type
  /// <summary>Which list of the starting points of a level a spot belongs to</summary>
  TPlayerSpotKind = (
    /// <summary>playerstarts: the place where a player begins the level</summary>
    pskPlayerStart,
    /// <summary>deathmatchstarts: the random places of a deathmatch</summary>
    pskDeathMatchStart
  );

  /// <summary>
  ///   What G_DoReborn and G_DeathMatchSpawnPlayer need from the game: the records of the players
  ///   and of the starting points are different in each game and stay on its side
  /// </summary>
  /// <remarks>
  ///   Every method is called in the order, and as many times, as the old code did: CheckSpot has
  ///   side effects (fog, sound, corpse), so the caller must stop at the first spot that is free
  /// </remarks>
  IPlayerRespawnHost = interface
    ['{5B0E8D3A-7C41-4E8B-9A52-3F6D1C27B904}']
    /// <summary>The player starts again from the beginning of the level (the single player case)</summary>
    procedure ReloadLevel;
    /// <summary>The body of the dead player stops being the body of that player (it may not exist)</summary>
    procedure DetachCorpse(const APlayer: Integer);
    /// <summary>G_CheckSpot: false if something occupies the spot</summary>
    function CheckSpot(const APlayer: Integer; const AKind: TPlayerSpotKind;
      const AIndex: Integer): Boolean;
    /// <summary>The player appears at the spot (P_SpawnPlayer, with the extra data of the same index)</summary>
    procedure Spawn(const AKind: TPlayerSpotKind; const AIndex: Integer);
    /// <summary>Writes the type of the spot: it tells which player starts there (player + 1)</summary>
    procedure SetSpotType(const AKind: TPlayerSpotKind; const AIndex, AType: Integer);
    /// <summary>The number of deathmatch spots of the level</summary>
    function DeathMatchSpotCount: Integer;
    /// <summary>The next number of the random generator of the game (P_Random)</summary>
    function NextRandom: Integer;
    /// <summary>
    ///   The level has too few deathmatch spots: Doom warns and goes on without spawning, the other
    ///   games stop with an error and never come back
    /// </summary>
    procedure TooFewDeathMatchSpots(const ACount: Integer);
  end;

implementation

end.

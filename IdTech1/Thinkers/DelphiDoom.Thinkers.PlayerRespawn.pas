{******************************************************************************}
{                                                                              }
{  DelphiDoom: thinkers library - where a player appears again                 }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Thinkers.PlayerRespawn;

interface

uses
  DelphiDoom.Thinkers.PlayerRespawn.Intf;

const
  /// <summary>How many times a deathmatch respawn draws a spot before it gives up</summary>
  PLAYER_RESPAWN_DEATHMATCH_TRIES = 20;
  /// <summary>The fewest deathmatch spots a level must have</summary>
  PLAYER_RESPAWN_MIN_DEATHMATCH_SPOTS = 4;

type
  /// <summary>
  ///   The choice of the spot where a player appears: G_DoReborn and G_DeathMatchSpawnPlayer of
  ///   Doom, Heretic and Strife (Hexen has its own G_DoReborn, which also carries the weapons over)
  /// </summary>
  /// <remarks>
  ///   Cold code (once per death in a network game): the game is behind IPlayerRespawnHost
  /// </remarks>
  TPlayerRespawn = class sealed
  strict private
    FHost: IPlayerRespawnHost;
  public
    /// <summary>The host must not be nil</summary>
    constructor Create(const AHost: IPlayerRespawnHost);

    /// <summary>
    ///   G_DoReborn: in a single player game the level is loaded again; in a network game the
    ///   player appears at a random spot (deathmatch), at the own start, or at the start of another player
    /// </summary>
    /// <param name="APlayer">The player that was killed</param>
    /// <param name="ANetGame">netgame</param>
    /// <param name="ADeathMatch">deathmatch: not 0 in a deathmatch</param>
    /// <param name="AMaxPlayers">MAXPLAYERS of the game</param>
    procedure Respawn(const APlayer: Integer; const ANetGame: Boolean;
      const ADeathMatch, AMaxPlayers: Integer);

    /// <summary>
    ///   G_DeathMatchSpawnPlayer: up to 20 random spots; if none is free the player appears at the own start
    /// </summary>
    procedure SpawnDeathMatch(const APlayer: Integer);
  end;

implementation

uses
  System.SysUtils;

{ TPlayerRespawn }

constructor TPlayerRespawn.Create(const AHost: IPlayerRespawnHost);
begin
  inherited Create;
  if not Assigned(AHost) then
    raise EArgumentNilException.Create('AHost');
  FHost := AHost;
end;

procedure TPlayerRespawn.SpawnDeathMatch(const APlayer: Integer);
var
  LSelections: Integer;
  LTry: Integer;
  LIndex: Integer;
  LPlaced: Boolean;
begin
  LSelections := FHost.DeathMatchSpotCount;
  if LSelections < PLAYER_RESPAWN_MIN_DEATHMATCH_SPOTS then
  begin
    FHost.TooFewDeathMatchSpots(LSelections);
    Exit;
  end;

  LPlaced := False;
  LTry := 0;
  while (LTry < PLAYER_RESPAWN_DEATHMATCH_TRIES) and not LPlaced do
  begin
    LIndex := FHost.NextRandom mod LSelections;
    if FHost.CheckSpot(APlayer, pskDeathMatchStart, LIndex) then
    begin
      FHost.SetSpotType(pskDeathMatchStart, LIndex, APlayer + 1);
      FHost.Spawn(pskDeathMatchStart, LIndex);
      LPlaced := True;
    end;
    Inc(LTry);
  end;

  // no good spot, so the player will probably get stuck
  if not LPlaced then
    FHost.Spawn(pskPlayerStart, APlayer);
end;

procedure TPlayerRespawn.Respawn(const APlayer: Integer; const ANetGame: Boolean;
  const ADeathMatch, AMaxPlayers: Integer);
var
  LIndex: Integer;
  LPlaced: Boolean;
begin
  if not ANetGame then
  begin
    // reload the level from scratch
    FHost.ReloadLevel;
    Exit;
  end;

  // first dissasociate the corpse
  FHost.DetachCorpse(APlayer);

  // spawn at random spot if in death match
  if ADeathMatch <> 0 then
  begin
    SpawnDeathMatch(APlayer);
    Exit;
  end;

  if FHost.CheckSpot(APlayer, pskPlayerStart, APlayer) then
  begin
    FHost.Spawn(pskPlayerStart, APlayer);
    Exit;
  end;

  // try to spawn at one of the other players spots
  LPlaced := False;
  LIndex := 0;
  while (LIndex < AMaxPlayers) and not LPlaced do
  begin
    if FHost.CheckSpot(APlayer, pskPlayerStart, LIndex) then
    begin
      FHost.SetSpotType(pskPlayerStart, LIndex, APlayer + 1); // fake as other player
      FHost.Spawn(pskPlayerStart, LIndex);
      FHost.SetSpotType(pskPlayerStart, LIndex, LIndex + 1); // restore
      LPlaced := True;
    end;
    Inc(LIndex);
  end;

  // he's going to be inside something. Too bad.
  if not LPlaced then
    FHost.Spawn(pskPlayerStart, APlayer);
end;

end.

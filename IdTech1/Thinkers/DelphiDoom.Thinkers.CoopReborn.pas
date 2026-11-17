{******************************************************************************}
{                                                                              }
{  DelphiDoom: thinkers library - the reborn of a player of Hexen             }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Thinkers.CoopReborn;

interface

uses
  DelphiDoom.Thinkers.CoopReborn.Intf;

const
  /// <summary>The mana a player has again after a cooperative reborn</summary>
  COOP_REBORN_MANA = 25;

type
  /// <summary>
  ///   G_DoReborn of Hexen: in a single player game the saved hub position is loaded; in a
  ///   network game the player appears at a random spot (deathmatch) or at a start of the hub
  ///   position, and in a cooperative game keeps the keys, the pieces and the weapons
  /// </summary>
  /// <remarks>
  ///   Cold code (once per death): the game is behind ICoopRebornHost. G_CheckDemoStatus stays
  ///   with the caller, because it can end the game
  /// </remarks>
  TCoopReborn = class sealed
  strict private
    FHost: ICoopRebornHost;
    function PlaceAtAStart(const APlayer, AMaxPlayers: Integer): Boolean;
    procedure CarryOver(const APlayer, AKeys, APieces: Integer; const AOwned: TArray<Boolean>);
  public
    /// <summary>The host must not be nil</summary>
    constructor Create(const AHost: ICoopRebornHost);

    /// <param name="APlayer">The player that was killed</param>
    /// <param name="ANetGame">netgame</param>
    /// <param name="ADeathMatch">deathmatch: not 0 in a deathmatch</param>
    /// <param name="AMaxPlayers">MAXPLAYERS of the game</param>
    procedure Respawn(const APlayer: Integer; const ANetGame: Boolean;
      const ADeathMatch, AMaxPlayers: Integer);
  end;

implementation

uses
  System.SysUtils;

{ TCoopReborn }

constructor TCoopReborn.Create(const AHost: ICoopRebornHost);
begin
  inherited Create;
  if not Assigned(AHost) then
    raise EArgumentNilException.Create('AHost');
  FHost := AHost;
end;

function TCoopReborn.PlaceAtAStart(const APlayer, AMaxPlayers: Integer): Boolean;
var
  LIndex: Integer;
begin
  if FHost.CheckSpot(APlayer, APlayer) then
  begin
    // appropriate player start spot is open
    FHost.Spawn(APlayer);
    Result := True;
    Exit;
  end;

  // try to spawn at one of the other player start spots
  for LIndex := 0 to AMaxPlayers - 1 do
  begin
    if FHost.CheckSpot(APlayer, LIndex) then
    begin
      // fake as other player, then restore the proper type
      FHost.SetSpotType(LIndex, APlayer + 1);
      FHost.Spawn(LIndex);
      FHost.SetSpotType(LIndex, LIndex + 1);
      Result := True;
      Exit;
    end;
  end;

  Result := False;
end;

procedure TCoopReborn.CarryOver(const APlayer, AKeys, APieces: Integer;
  const AOwned: TArray<Boolean>);
var
  LIndex: Integer;
  LBestWeapon: Integer;
begin
  FHost.SetKeys(APlayer, AKeys);
  FHost.SetPieces(APlayer, APieces);
  LBestWeapon := 0;
  for LIndex := 0 to Length(AOwned) - 1 do
  begin
    if AOwned[LIndex] then
    begin
      LBestWeapon := LIndex;
      FHost.GiveWeapon(APlayer, LIndex);
    end;
  end;
  FHost.SetMana(APlayer, COOP_REBORN_MANA);
  // bring up the best weapon
  if LBestWeapon <> 0 then
    FHost.SetPendingWeapon(APlayer, LBestWeapon);
end;

procedure TCoopReborn.Respawn(const APlayer: Integer; const ANetGame: Boolean;
  const ADeathMatch, AMaxPlayers: Integer);
var
  LKeys: Integer;
  LPieces: Integer;
  LOwned: TArray<Boolean>;
  LIndex: Integer;
begin
  if not ANetGame then
  begin
    // use the reborn code if the slot is available, else start a new game
    FHost.RequestGameAction(FHost.RebornSlotAvailable);
    Exit;
  end;

  // net game: dissassociate the corpse
  FHost.DetachCorpse(APlayer);

  if ADeathMatch <> 0 then
  begin
    // spawn at random spot if in death match
    FHost.SpawnDeathMatch(APlayer);
    Exit;
  end;

  // cooperative net-play, retain keys and weapons
  LKeys := FHost.Keys(APlayer);
  LPieces := FHost.Pieces(APlayer);
  SetLength(LOwned, FHost.WeaponCount);
  for LIndex := 0 to Length(LOwned) - 1 do
    LOwned[LIndex] := FHost.WeaponOwned(APlayer, LIndex);

  // if no spot is free the player is going to be inside something
  if not PlaceAtAStart(APlayer, AMaxPlayers) then
    FHost.Spawn(APlayer);

  CarryOver(APlayer, LKeys, LPieces, LOwned);
end;

end.

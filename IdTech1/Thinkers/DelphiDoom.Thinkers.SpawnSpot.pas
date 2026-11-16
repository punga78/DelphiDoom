{******************************************************************************}
{                                                                              }
{  DelphiDoom: thinkers library - is a spot free for a player (G_CheckSpot)    }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Thinkers.SpawnSpot;

// The angle of the fog is computed with the same wrap-around as the old code
{$Q-}
{$R-}

interface

type
  /// <summary>What G_CheckSpot asks the game: the objects, the map and the effects are on its side</summary>
  ISpawnSpotHost = interface
    ['{A1D3F6C2-52B8-4C7E-8E19-6B0F4A93D5E7}']
    /// <summary>The player already has a body in the level</summary>
    function PlayerHasBody(const APlayer: Integer): Boolean;
    /// <summary>The x of the body of a player (the old code read it without checking that it exists)</summary>
    function PlayerBodyX(const APlayer: Integer): Integer;
    /// <summary>The y of the body of a player</summary>
    function PlayerBodyY(const APlayer: Integer): Integer;
    /// <summary>Before the test of the position: the body of the player may pass through the other things</summary>
    procedure BeginPositionTest(const APlayer: Integer);
    /// <summary>After the test of the position (free or not): the body goes back as it was</summary>
    procedure EndPositionTest(const APlayer: Integer);
    /// <summary>The height where the fog appears (the floor, or the ceiling of a 3D floor)</summary>
    function SpotHeight(const APlayer, AX, AY: Integer): Integer;
    /// <summary>P_CheckPosition of the body of the player at the spot</summary>
    function PositionFree(const APlayer, AX, AY: Integer): Boolean;
    /// <summary>The old body of the player enters the queue of the corpses (the oldest is removed)</summary>
    procedure FlushCorpse(const APlayer: Integer);
    /// <summary>
    ///   The teleport fog, 20 units from the spot in the direction of the fine angle, and its sound
    ///   (not at the first frame)
    /// </summary>
    procedure SpawnFog(const AX, AY, AHeight, AFineAngle: Integer);
  end;

  /// <summary>
  ///   G_CheckSpot of the four games: false if a spot cannot take a player
  /// </summary>
  TSpawnSpot = class sealed
  public
    /// <summary>The index of the fine table for the angle of a thing (ANG45 * (angle div 45) shr ANGLETOFINESHIFT)</summary>
    class function FineAngleOf(const AMapThingAngle: Integer): Cardinal; static;

    /// <summary>G_CheckSpot</summary>
    /// <param name="AHost">The game</param>
    /// <param name="APlayer">The player that wants the spot</param>
    /// <param name="AX">x of the spot, in fixed point (mthing.x * FRACUNIT)</param>
    /// <param name="AY">y of the spot, in fixed point</param>
    /// <param name="AMapThingAngle">The angle of the mapthing, in degrees</param>
    class function Check(const AHost: ISpawnSpotHost; const APlayer, AX, AY,
      AMapThingAngle: Integer): Boolean; static;
  end;

implementation

const
  ANG45 = Cardinal($20000000);
  ANGLETOFINESHIFT = 19;

{ TSpawnSpot }

class function TSpawnSpot.FineAngleOf(const AMapThingAngle: Integer): Cardinal;
begin
  // the product is 64 bit, as the old code had it (a negative angle gives the same index as before)
  Result := Cardinal((Int64(ANG45) * (AMapThingAngle div 45)) shr ANGLETOFINESHIFT);
end;

class function TSpawnSpot.Check(const AHost: ISpawnSpotHost; const APlayer, AX, AY,
  AMapThingAngle: Integer): Boolean;
var
  LIndex: Integer;
  LHeight: Integer;
  LFree: Boolean;
begin
  if not AHost.PlayerHasBody(APlayer) then
  begin
    // first spawn of level, before corpses
    // stops at the first player on the spot: the others are not read (their body may not exist)
    Result := True;
    LIndex := 0;
    while Result and (LIndex < APlayer) do
    begin
      if (AHost.PlayerBodyX(LIndex) = AX) and (AHost.PlayerBodyY(LIndex) = AY) then
        Result := False;
      Inc(LIndex);
    end;
    Exit;
  end;

  AHost.BeginPositionTest(APlayer);
  LHeight := AHost.SpotHeight(APlayer, AX, AY);
  LFree := AHost.PositionFree(APlayer, AX, AY);
  AHost.EndPositionTest(APlayer);
  if not LFree then
  begin
    Result := False;
    Exit;
  end;

  // flush an old corpse if needed
  AHost.FlushCorpse(APlayer);

  AHost.SpawnFog(AX, AY, LHeight, Integer(FineAngleOf(AMapThingAngle)));
  Result := True;
end;

end.

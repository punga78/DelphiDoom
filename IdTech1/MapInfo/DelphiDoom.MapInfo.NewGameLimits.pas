{******************************************************************************}
{                                                                              }
{  DelphiDoom: map info library - the episode and the map of a new game        }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapInfo.NewGameLimits;

interface

type
  /// <summary>
  ///   Which edition of the game is loaded (the <c>gamemode</c> of the engine, with the
  ///   editions of every game: the rules of a game look at the ones it has)
  /// </summary>
  TNewGameEdition = (ngeShareware, ngeRegistered, ngeRetail, ngeCommercial, ngeExtended);

  /// <summary>
  ///   Which custom game (a total conversion that runs on Doom) is loaded
  /// </summary>
  TNewGameCustom = (ngcNone, ngcChex, ngcHacx);

  /// <summary>
  ///   Brings the episode and the map asked for a new game to the ones the game has
  ///   (the first part of G_InitNew of each game)
  /// </summary>
  TNewGameLimits = class sealed
  public
    /// <summary>
    ///   Doom: if the map is not in the WADs the episode and the map are brought to the edition
    /// </summary>
    /// <param name="AMapMissing">The map is not a lump of the WADs and the episodes are not custom</param>
    /// <param name="AEdition">Shareware, registered, retail or commercial</param>
    /// <param name="ACustom">Chex Quest and HacX have their own limits</param>
    /// <param name="AEpisode">The episode, from 1; changed</param>
    /// <param name="AMap">The map; changed</param>
    class procedure Doom(const AMapMissing: Boolean; const AEdition: TNewGameEdition;
      const ACustom: TNewGameCustom; var AEpisode, AMap: Integer); static;

    /// <summary>
    ///   Heretic: the map is from 1 to 9, and the episode is brought to the edition if the map is missing
    /// </summary>
    class procedure Heretic(const AMapMissing: Boolean; const AEdition: TNewGameEdition;
      var AEpisode, AMap: Integer); static;

    /// <summary>Strife: the shareware has three maps (32, 33, 34), the full game 34</summary>
    class procedure Strife(const AEdition: TNewGameEdition; var AMap: Integer); static;

    /// <summary>Hexen: the maps are from 1 to 99</summary>
    class procedure Hexen(var AMap: Integer); static;
  end;

implementation

{ TNewGameLimits }

class procedure TNewGameLimits.Doom(const AMapMissing: Boolean; const AEdition: TNewGameEdition;
  const ACustom: TNewGameCustom; var AEpisode, AMap: Integer);
begin
  if AEpisode < 1 then
    AEpisode := 1;

  if not AMapMissing then
    Exit;

  // The two maps of the secret levels of the old episodes have no lump on purpose
  if ((AEpisode = 9) and (AMap = 9)) or ((AMap = 99) and (AEpisode = 0)) then
    Exit;

  // This was quite messy with SPECIAL and commented parts.
  // Supposedly hacks to make the latest edition work.
  // It might not work properly.
  case AEdition of
    ngeRetail:
      if AEpisode > 4 then
        AEpisode := 4;
    ngeShareware:
      if AEpisode > 1 then
        AEpisode := 1; // only start episode 1 on shareware
  else
    if AEpisode > 3 then
      AEpisode := 3;
  end;

  if AMap < 1 then
    AMap := 1;

  if (AMap > 9) and (AEdition <> ngeCommercial) then
    AMap := 9;

  // Chex Support
  if ACustom = ngcChex then
  begin
    if AMap > 5 then
      AMap := 5;
    if AEpisode > 1 then
      AEpisode := 1;
  end;

  // Hacx Support
  if ACustom = ngcHacx then
  begin
    if AMap > 20 then
      AMap := 20;
    if AEpisode > 1 then
      AEpisode := 1;
  end;
end;

class procedure TNewGameLimits.Heretic(const AMapMissing: Boolean; const AEdition: TNewGameEdition;
  var AEpisode, AMap: Integer);
begin
  if AEpisode < 1 then
    AEpisode := 1;

  if AMap < 1 then
    AMap := 1
  else if AMap > 9 then
    AMap := 9;

  if not AMapMissing then
    Exit;

  case AEdition of
    ngeShareware:
      if AEpisode > 1 then
        AEpisode := 1; // only start episode 1 on shareware
    ngeExtended:
      if AEpisode > 5 then
        AEpisode := 5;
  else
    if AEpisode > 3 then
      AEpisode := 3;
  end;
end;

class procedure TNewGameLimits.Strife(const AEdition: TNewGameEdition; var AMap: Integer);
begin
  if AEdition = ngeShareware then
  begin
    if not (AMap in [32, 33, 34]) then
      AMap := 32;
  end
  else
  begin
    if AMap > 34 then
      AMap := 1;
  end;

  if AMap < 1 then
    AMap := 1;
end;

class procedure TNewGameLimits.Hexen(var AMap: Integer);
begin
  if AMap < 1 then
    AMap := 1
  else if AMap > 99 then
    AMap := 99;
end;

end.

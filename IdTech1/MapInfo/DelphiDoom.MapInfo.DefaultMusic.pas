{******************************************************************************}
{                                                                              }
{  DelphiDoom: mapinfo library - the default music of a map                    }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapInfo.DefaultMusic;

interface

type
  /// <summary>
  ///   The song a map plays when nothing else says which (S_DefaultMusicForMap of the games). The
  ///   numbers of the songs are the ones of the table of the game: they come from the caller, as
  ///   the first song of a group
  /// </summary>
  /// <remarks>
  ///   Cold code (once per level). A song number from UMAPINFO (greater than 0) wins where the
  ///   game reads it (Doom, Heretic, Strife)
  /// </remarks>
  TDefaultMusic = class sealed
  public
    /// <summary>
    ///   Doom: Doom 2 follows the order of the maps (the map 99 plays the first song), the episodes
    ///   have nine songs each, and a fourth episode that has no songs of its own borrows nine
    /// </summary>
    /// <param name="AMapInfoMusic">The song of the UMAPINFO entry; 0 if there is none</param>
    /// <param name="AFirstEpisodeSong">The song of E1M1; the songs of an episode are in a row</param>
    /// <param name="AFirstCommercialSong">The song of MAP01</param>
    /// <param name="AFourthEpisodeSongs">The nine songs of the maps 1..9 of the episodes after the fourth</param>
    class function Doom(const AMapInfoMusic: Integer; const AIsCommercial: Boolean; const AEpisode, AMap,
      AFirstEpisodeSong, AFirstCommercialSong: Integer; const AFourthEpisodeSongs: array of Integer): Integer; static;

    /// <summary>Heretic: nine songs for each of the five episodes; the next ones repeat the first episode</summary>
    class function Heretic(const AMapInfoMusic, AEpisode, AMap, AFirstEpisodeSong: Integer): Integer; static;

    /// <summary>Hexen: one song for each map, in a row</summary>
    class function Hexen(const AMap, AFirstSong: Integer): Integer; static;

    /// <summary>Strife: the song of the map comes from the table and goes back to the start after the map 31</summary>
    class function Strife(const AMapInfoMusic, AMap: Integer): Integer; static;
  end;

implementation

{ TDefaultMusic }

class function TDefaultMusic.Doom(const AMapInfoMusic: Integer; const AIsCommercial: Boolean;
  const AEpisode, AMap, AFirstEpisodeSong, AFirstCommercialSong: Integer;
  const AFourthEpisodeSongs: array of Integer): Integer;
begin
  if AMapInfoMusic > 0 then
    Result := AMapInfoMusic
  else if AIsCommercial then
  begin
    if AMap = 99 then
      Result := AFirstCommercialSong
    else
      Result := AFirstCommercialSong + AMap - 1;
  end
  else if AEpisode < 5 then
    Result := AFirstEpisodeSong + (AEpisode - 1) * 9 + AMap - 1
  else if (AMap >= 1) and (AMap <= 9) then
    Result := AFourthEpisodeSongs[AMap - 1]
  else
    Result := AFirstEpisodeSong;
end;

class function TDefaultMusic.Heretic(const AMapInfoMusic, AEpisode, AMap, AFirstEpisodeSong: Integer): Integer;
begin
  if AMapInfoMusic > 0 then
    Result := AMapInfoMusic
  else if AEpisode < 6 then
    Result := AFirstEpisodeSong + (AEpisode - 1) * 9 + AMap - 1
  else if (AMap >= 1) and (AMap <= 9) then
    Result := AFirstEpisodeSong + AMap - 1
  else
    Result := AFirstEpisodeSong;
end;

class function TDefaultMusic.Hexen(const AMap, AFirstSong: Integer): Integer;
begin
  Result := AFirstSong + AMap - 1;
end;

class function TDefaultMusic.Strife(const AMapInfoMusic, AMap: Integer): Integer;
begin
  if AMapInfoMusic > 0 then
    Result := AMapInfoMusic
  else if AMap <= 31 then
    Result := AMap + 1
  else
    Result := AMap - 30;
end;

end.

{******************************************************************************}
{                                                                              }
{  DelphiDoom: map info library - which map comes after the one that ended     }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapInfo.LevelProgression;

interface

type
  /// <summary>
  ///   The default order of the maps when a level ends and the map has no UMAPINFO entry
  ///   (the case of G_DoCompleted that fills wminfo.next, and the finale case of G_WorldDone)
  /// </summary>
  /// <remarks>
  ///   The numbers are 0 biased, as wminfo.next: the map 1 is 0. When the rules do not say where to
  ///   go, the number is left as it was (the old code did not write it); the games that keep the
  ///   level of the last intermission rely on it
  /// </remarks>
  TLevelProgression = class sealed
  public
    /// <summary>The rules of Doom, episodes and Doom 2 (and the custom games of the BFG edition)</summary>
    /// <param name="AIsCommercial">The game is Doom 2 (maps MAP01..MAP32)</param>
    /// <param name="ASecretExit">The level ended with the secret exit</param>
    /// <param name="AIsBfgSecondEdition">The custom game is the one of the BFG edition of Doom 2 (cg_bfg2)</param>
    /// <param name="AEpisode">The episode, from 1</param>
    /// <param name="AMap">The map that ended, from 1</param>
    /// <param name="ANext">The next map, 0 biased; untouched if the rules give none</param>
    class procedure DoomNextMap(const AIsCommercial, ASecretExit, AIsBfgSecondEdition: Boolean;
      const AEpisode, AMap: Integer; var ANext: Integer); static;

    /// <summary>The rules of Heretic: the secret map is the 9th, and each episode returns to its own map</summary>
    class procedure HereticNextMap(const ASecretExit: Boolean; const AEpisode, AMap: Integer;
      var ANext: Integer); static;

    /// <summary>
    ///   Doom 2 shows a text after the intermission of some maps (G_WorldDone)
    /// </summary>
    class function DoomCommercialFinale(const ASecretExit: Boolean; const AMap: Integer): Boolean; static;
  end;

implementation

{ TLevelProgression }

class procedure TLevelProgression.DoomNextMap(const AIsCommercial, ASecretExit,
  AIsBfgSecondEdition: Boolean; const AEpisode, AMap: Integer; var ANext: Integer);
begin
  if AIsCommercial then
  begin
    if ASecretExit then
    begin
      case AMap of
         2: if AIsBfgSecondEdition then ANext := 32 else ANext := AMap;
        15: ANext := 30;
        31: ANext := 31;
      end;
    end
    else
    begin
      case AMap of
        31,
        32: ANext := 15;
        33: if AIsBfgSecondEdition then ANext := 2 else ANext := AMap;
      else
        ANext := AMap;
      end;
    end;
  end
  else
  begin
    if ASecretExit then
      ANext := 8  // go to secret level
    else if AMap = 9 then
    begin
      // returning from secret level
      case AEpisode of
        1: ANext := 3;
        2: ANext := 5;
        3: ANext := 6;
        4: ANext := 2;
      end;
    end
    else
      ANext := AMap; // go to next level
  end;
end;

class procedure TLevelProgression.HereticNextMap(const ASecretExit: Boolean;
  const AEpisode, AMap: Integer; var ANext: Integer);
begin
  if ASecretExit then
    ANext := 8  // go to secret level
  else if AMap = 9 then
  begin
    // returning from secret level
    case AEpisode of
      1: ANext := 7;
      2: ANext := 5;
      3: ANext := 5;
      4: ANext := 5;
      5: ANext := 4;
    end;
  end
  else
    ANext := AMap; // go to next level
end;

class function TLevelProgression.DoomCommercialFinale(const ASecretExit: Boolean;
  const AMap: Integer): Boolean;
begin
  if ASecretExit then
    Result := AMap in [15, 31, 6, 11, 20, 30]
  else
    Result := AMap in [6, 11, 20, 30];
end;

end.

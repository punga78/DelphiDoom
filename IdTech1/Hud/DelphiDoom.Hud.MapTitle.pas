{******************************************************************************}
{                                                                              }
{  DelphiDoom: heads-up display library - the title of the map                 }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Hud.MapTitle;

interface

type
  /// <summary>
  ///   How the name of the map is chosen: the tables of names stay in the engine (the Dehacked
  ///   patches change them), the rules to read them are here
  /// </summary>
  THudMapTitle = class sealed
  public
    /// <summary>
    ///   The name of the map of an episode (nine maps each): from the table, or "Episode E - Map M"
    ///   if the map is not in it (HU_TITLE of Doom)
    /// </summary>
    class function ForEpisode(const ANames: array of string; const AEpisode, AMap: Integer): string; static;
    /// <summary>
    ///   The name of a map of a single list (maps from 1): from the table, or "Map N" if it is
    ///   not in it (HU_TITLE2, HU_TITLEP and HU_TITLET)
    /// </summary>
    class function ForMap(const ANames: array of string; const AMap: Integer): string; static;
    /// <summary>
    ///   The title the map information gives: "label: name", with the map name as label unless
    ///   the label is "-" (the label alone is not written then)
    /// </summary>
    class function FromMapInfo(const AMapName, ALabel, ALevelName: string): string; static;
  end;

implementation

uses
  System.SysUtils;

{ THudMapTitle }

class function THudMapTitle.ForEpisode(const ANames: array of string; const AEpisode,
  AMap: Integer): string;
var
  LIndex: Integer;
begin
  LIndex := (AEpisode - 1) * 9 + AMap - 1;
  if (LIndex >= 0) and (LIndex <= High(ANames)) then
    Result := ANames[LIndex]
  else
    Result := Format('Episode %d - Map %d', [AEpisode, AMap]);
end;

class function THudMapTitle.ForMap(const ANames: array of string; const AMap: Integer): string;
begin
  if (AMap >= 1) and (AMap <= Length(ANames)) then
    Result := ANames[AMap - 1]
  else
    Result := Format('Map %d', [AMap]);
end;

class function THudMapTitle.FromMapInfo(const AMapName, ALabel, ALevelName: string): string;
var
  LLabel: string;
begin
  if ALabel <> '' then
    LLabel := ALabel
  else
    LLabel := AMapName;
  if (LLabel = AMapName) or (LLabel <> '-') then
    Result := LLabel + ': ' + ALevelName
  else
    Result := ALevelName;
end;

end.

{******************************************************************************}
{                                                                              }
{  DelphiDoom: Speed library - the names and the skies of the circuits         }
{  Copyright (C) 1995 by Noriaworks                                            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom, GLSpeed)     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Speed.UmapInfoBuilder;

interface

uses
  System.SysUtils, DelphiDoom.GameData.Intf, DelphiDoom.Speed.SkyTextures;

const
  /// <summary>The lump that the engine reads for the names and the skies of the maps</summary>
  SPEED_UMAPINFO_LUMP = 'UMAPINFO';

type
  /// <summary>
  ///   The lump MAPDATA of every circuit says its name and its sky (speed_mapdata of the fork); the
  ///   engine of Doom takes them from UMAPINFO, so the WAD gets one (the sky was a plain color
  ///   because the engine looks for the sky of the episode)
  /// </summary>
  TSpeedUmapInfoBuilder = class
  public
    /// <summary>
    ///   Makes the text of UMAPINFO from the circuits (the markers E1M1..E4M9 followed by their MAPDATA)
    ///   that the WAD has
    /// </summary>
    /// <exception cref="EArgumentNilException">AWad is nil</exception>
    /// <param name="ASkies">The sky textures made for the circuits: a circuit that has one uses it, the others the sky of their MAPDATA</param>
    class function Build(const AWad: IGameWadComposer; const ASkies: TArray<TSpeedSkyEntry>): string; static;
  end;

implementation

uses
  System.Classes, DelphiDoom.Speed.MapInfoReader, DelphiDoom.Racing.Types;

const
  MAPDATA_LUMP = 'MAPDATA';
  // MAPDATA is after the lumps of the map (the old ML_MAPDATA is the 13th)
  MAP_LUMP_SPAN = 13;

{ TSpeedUmapInfoBuilder }

class function TSpeedUmapInfoBuilder.Build(const AWad: IGameWadComposer; const ASkies: TArray<TSpeedSkyEntry>): string;
var
  LBuilder: TStringBuilder;
  LEpisode, LMap, LMarker, LLump: Integer;
  LInfo: TSpeedMapInfo;
  LName, LSky: string;
  LSkyIndex: Integer;
begin
  if not Assigned(AWad) then
    raise EArgumentNilException.Create('AWad');
  LBuilder := TStringBuilder.Create;
  try
    for LEpisode := 1 to RACING_MAX_EPISODES do
      for LMap := 1 to RACING_MAX_MAPS do
      begin
        LName := Format('E%dM%d', [LEpisode, LMap]);
        LMarker := AWad.IndexOf(LName);
        if LMarker < 0 then
          Continue;
        for LLump := LMarker + 1 to LMarker + MAP_LUMP_SPAN - 1 do
          if (LLump < AWad.Count) and SameText(AWad.LumpNames[LLump], MAPDATA_LUMP) then
          begin
            LInfo := TSpeedMapInfoReader.Parse(TEncoding.ASCII.GetString(AWad.LumpData[LLump]));
            LBuilder.Append('MAP ').Append(LName).Append(#13#10).Append('{').Append(#13#10);
            if LInfo.Name <> '' then
              LBuilder.Append('  levelname = "').Append(LInfo.Name.Replace('"', '')).Append('"').Append(#13#10);
            LSky := LInfo.SkyTexture;
            for LSkyIndex := 0 to High(ASkies) do
              if SameText(ASkies[LSkyIndex].Level, LName) then
                LSky := ASkies[LSkyIndex].Texture;
            if LSky <> '' then
              LBuilder.Append('  skytexture = "').Append(LSky.Replace('"', '')).Append('"').Append(#13#10);
            LBuilder.Append('}').Append(#13#10);
            Break;
          end;
      end;
    Result := LBuilder.ToString;
  finally
    LBuilder.Free;
  end;
end;

end.

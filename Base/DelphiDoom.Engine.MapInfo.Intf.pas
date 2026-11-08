{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the UMAPINFO records of the game                       }
{  Copyright (C) 2004-2023 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.MapInfo.Intf;

interface

type
  /// <summary>
  ///   Keeps the records mapentry_t of p_umapinfo (u_mapinfo, default_mapinfo: they are read
  ///   by the HUD, the finale, the level and the sound code) up to date with the catalog of
  ///   Libs\MapInfo. The d_main of each game receives one from the composition root (it was
  ///   U_ParseMapInfo and U_FreeMapInfo of p_umapinfo.pas)
  /// </summary>
  IEngineMapInfoRecords = interface
    ['{3B8E52D1-9C47-4F0A-A6D3-71E4C25B8F90}']
    /// <summary>
    ///   The library reads the text of the lump and merges the maps, then the records are
    ///   made again from its catalog (the pointers to a record are taken when a level starts)
    /// </summary>
    procedure Load(AIsDefault: Boolean; const ALumpName: string);
    /// <summary>Frees the records of the maps and forgets the maps of the catalog</summary>
    procedure Release;
  end;

implementation

end.

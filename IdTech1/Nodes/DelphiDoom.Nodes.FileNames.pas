{******************************************************************************}
{                                                                              }
{  DelphiDoom: Nodes library - the names of the files of the built nodes       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Nodes.FileNames;

interface

type
  /// <summary>
  ///   The names of the files that the engine writes for the nodes of a map: the GWA that
  ///   glBSP builds (map and Adler-32 of the map, DATA\BSP), the WAD given to glBSP for it, and
  ///   the WAD rebuilt for a map without nodes (map and CRC-32 of four lumps, DATA\WADS). The
  ///   names are the ones of the old nd_main.pas, so the files already made are found again
  /// </summary>
  TNodesFileNames = class sealed
  public
    /// <summary>A checksum in 8 hexadecimal digits in lower case</summary>
    class function ChecksumText(AValue: Cardinal): string; static;
    /// <summary>MAP_xxxxxxxx.gwa in AFolder, where xxxxxxxx is the Adler-32 of the map</summary>
    class function GwaFileName(const AFolder, AMapName: string; AAdler32: Cardinal): string; static;
    /// <summary>MAP_xxxxxxxx.wad: the map alone, given to glBSP</summary>
    class function GlbspInputFileName(const AMapName: string; AAdler32: Cardinal): string; static;
    /// <summary>
    ///   MAP_a_b_c_d without the extension, with the CRC-32 (as text) of LINEDEFS, SIDEDEFS,
    ///   VERTEXES and SECTORS: the rebuilt WAD is this name with .wad, its input with .out
    /// </summary>
    class function RebuiltMapName(const AFolder, AMapName: string; const ACrcs: array of string): string; static;
  end;

implementation

uses
  System.SysUtils;

const
  GWA_EXTENSION = '.gwa';
  WAD_EXTENSION = '.wad';
  NAME_SEPARATOR = '_';

{ TNodesFileNames }

class function TNodesFileNames.ChecksumText(AValue: Cardinal): string;
begin
  Result := LowerCase(IntToHex(AValue, 8));
end;

class function TNodesFileNames.GwaFileName(const AFolder, AMapName: string; AAdler32: Cardinal): string;
begin
  Result := AFolder + AMapName + NAME_SEPARATOR + ChecksumText(AAdler32) + GWA_EXTENSION;
end;

class function TNodesFileNames.GlbspInputFileName(const AMapName: string; AAdler32: Cardinal): string;
begin
  Result := AMapName + NAME_SEPARATOR + ChecksumText(AAdler32) + WAD_EXTENSION;
end;

class function TNodesFileNames.RebuiltMapName(const AFolder, AMapName: string;
  const ACrcs: array of string): string;
var
  LIndex: Integer;
begin
  Result := AFolder + AMapName;
  for LIndex := 0 to High(ACrcs) do
    Result := Result + NAME_SEPARATOR + ACrcs[LIndex];
end;

end.

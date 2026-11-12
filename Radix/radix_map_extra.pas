{******************************************************************************}
{                                                                              }
{  DelphiDoom: Radix game - what a level of Radix has more than one of Doom    }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of RX_LoadRadixMapInfo of radix_map_extra.pas and of the Radix part    }
{  of P_SlopesSetup (p_slopes.pas) of Rad-X: the lump RMAP is read by          }
{  Libs\Radix, here its slopes and angles go to the sectors of the engine.     }
{  The rest of the old unit (wall damage, line traces, bounces) is not ported  }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}

unit radix_map_extra;

interface

uses
  DelphiDoom.Radix.Intf,
  DelphiDoom.Radix.MapInfo.Types;

var
  // What RMAP says of every sector and line of the level (numsectors and numlines entries,
  // the values of a sector or wall that RMAP does not name for the others)
  radixsectorinfo: array of TRadixSectorInfo;
  radixwallinfo: array of TRadixWallInfo;

//==============================================================================
//
// RX_ConfigureMapInfo
// Gives the unit the reader of RMAP. The composition root calls it; without it
// RX_LoadRadixMapInfo is an I_Error
//
//==============================================================================
procedure RX_ConfigureMapInfo(const AReader: IRadixMapInfoReader);

//==============================================================================
//
// RX_RadixLump
// The lump of a level of Radix (RMAP, RTHINGS, RGRID...) at its place after the
// lumps of Doom; -1 when the lump there has another name (P_RadixLump of Rad-X)
//
//==============================================================================
function RX_RadixLump(const lumpnum: integer; const lumpname: string): integer;

//==============================================================================
//
// RX_LoadRadixMapInfo
// Reads RMAP and makes the sloped floors and ceilings of the level. To call
// after the lines are grouped in the sectors and the nodes are loaded
//
//==============================================================================
procedure RX_LoadRadixMapInfo(const lumpnum: integer);

implementation

uses
  SysUtils,
  d_delphi,
  i_system,
  p_setup,
  p_slopes,
  r_defs,
  w_wad,
  DelphiDoom.Radix.Types,
  DelphiDoom.Radix.MapInfo.Reader,
  DelphiDoom.Radix.SlopePlanes;

var
  radix_mapinforeader: IRadixMapInfoReader = nil;

//==============================================================================
//
// RX_ConfigureMapInfo
//
//==============================================================================
procedure RX_ConfigureMapInfo(const AReader: IRadixMapInfoReader);
begin
  radix_mapinforeader := AReader;
end;

//==============================================================================
//
// RX_RadixLump
//
//==============================================================================
function RX_RadixLump(const lumpnum: integer; const lumpname: string): integer;
begin
  result := -1;
  if (lumpnum < 0) or (lumpnum >= W_NumLumps) then
    exit;
  if strupper(char8tostring(W_GetNameForNum(lumpnum))) = strupper(lumpname) then
    result := lumpnum;
end;

//==============================================================================
//
// RX_SlopeSector
// A sloped floor or ceiling from its plane (the Radix part of P_SlopesSetup)
//
//==============================================================================
procedure RX_SlopeSector(const sec: Psector_t; const plane: TRadixSlopePlane; const flag: LongWord);
begin
  if not plane.Valid then
  begin
    I_Warning('RX_LoadRadixMapInfo(): The three points of the slope of sector %d are on a line'#13#10,
      [sec.iSectorID]);
    exit;
  end;

  if flag = SRF_SLOPEFLOOR then
  begin
    sec.fa := plane.A;
    sec.fb := plane.B;
    sec.fic := plane.InverseC;
    sec.fd := plane.D;
  end
  else
  begin
    sec.ca := plane.A;
    sec.cb := plane.B;
    sec.cic := plane.InverseC;
    sec.cd := plane.D;
  end;
  sec.renderflags := sec.renderflags or flag;
  P_SlopesAlignPlane(sec, nil, flag, false);
  if sec.linecount > 0 then
  begin
    sec.slopeline := sec.lines[0];
    sec.slopeline.renderflags := sec.slopeline.renderflags or LRF_SLOPED;
  end;
end;

//==============================================================================
//
// RX_LoadRadixMapInfo
//
//==============================================================================
procedure RX_LoadRadixMapInfo(const lumpnum: integer);
var
  info: TRadixMapInfo;
  i: integer;
  id: integer;
  sec: Psector_t;
begin
  if radix_mapinforeader = nil then
    I_Error('RX_LoadRadixMapInfo(): RX_ConfigureMapInfo was not called');

  SetLength(radixsectorinfo, numsectors);
  for i := 0 to numsectors - 1 do
    radixsectorinfo[i] := TRadixMapInfoReader.DefaultSector(i);
  SetLength(radixwallinfo, 0); // clears the entries of the previous level
  SetLength(radixwallinfo, numlines);
  for i := 0 to numlines - 1 do
    radixwallinfo[i].WallId := i;

  if lumpnum < 0 then
    exit;

  try
    info := radix_mapinforeader.Read(W_TextLumpNum(lumpnum));
  except
    on e: ERadixException do
    begin
      I_Warning('RX_LoadRadixMapInfo(): %s'#13#10, [e.Message]);
      exit;
    end;
  end;

  for i := 0 to Length(info.Walls) - 1 do
  begin
    id := info.Walls[i].WallId;
    if (id >= 0) and (id < numlines) then
      radixwallinfo[id] := info.Walls[i]
    else
      I_Warning('RX_LoadRadixMapInfo(): Wall %d is not a line of the map'#13#10, [id]);
  end;

  for i := 0 to Length(info.Sectors) - 1 do
  begin
    id := info.Sectors[i].SectorId;
    if (id < 0) or (id >= numsectors) then
    begin
      I_Warning('RX_LoadRadixMapInfo(): Sector %d is not a sector of the map'#13#10, [id]);
      continue;
    end;
    radixsectorinfo[id] := info.Sectors[i];
    sec := @sectors[id];

    if rssFloorAngle in info.Sectors[i].Statements then
      sec.floorangle := TRadixSlopePlanes.ToEngineAngle(info.Sectors[i].FloorAngle);
    if rssCeilingAngle in info.Sectors[i].Statements then
      sec.ceilingangle := TRadixSlopePlanes.ToEngineAngle(info.Sectors[i].CeilingAngle);

    // the plane comes from the three points of the sector, not from the equation of RADIX.DAT
    if info.Sectors[i].Statements * [rssFloorSlope, rssHeightNodesX, rssHeightNodesY, rssFloorHeights] =
      [rssFloorSlope, rssHeightNodesX, rssHeightNodesY, rssFloorHeights] then
      RX_SlopeSector(sec, TRadixSlopePlanes.Floor(info.Sectors[i]), SRF_SLOPEFLOOR);
    if info.Sectors[i].Statements * [rssCeilingSlope, rssHeightNodesX, rssHeightNodesY, rssCeilingHeights] =
      [rssCeilingSlope, rssHeightNodesX, rssHeightNodesY, rssCeilingHeights] then
      RX_SlopeSector(sec, TRadixSlopePlanes.Ceiling(info.Sectors[i]), SRF_SLOPECEILING);
  end;
end;

end.

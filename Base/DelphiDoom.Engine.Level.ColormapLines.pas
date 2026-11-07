{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the colormaps named by the sides (special 242)         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Level.ColormapLines;

interface

uses
  doomdata,
  r_defs;

type
  /// <summary>
  ///   The colormaps of BOOM (Doom and Strife): a texture of a side that is not a texture may be
  ///   the name of a colormap, kept as a negative number until the lines are grouped; the
  ///   special 242 gives the colormaps of its front side to the sector, then every negative
  ///   texture becomes 0
  /// </summary>
  TLevelColormapLines = class
  public
    /// <summary>The textures of a side, or -1 minus the number of the colormap that it names</summary>
    class procedure ReadSideTextures(AMapSide: Pmapsidedef_t; ASide: Pside_t); static;
    /// <summary>The colormaps of the lines with the special 242 in their sectors</summary>
    class procedure ApplyToSectors; static;
  end;

implementation

uses
  r_data,
  r_colormaps,
  p_setup;

const
  COLORMAP_LINE_SPECIAL = 242;

{ TLevelColormapLines }

class procedure TLevelColormapLines.ReadSideTextures(AMapSide: Pmapsidedef_t; ASide: Pside_t);
begin
  ASide.toptexture := R_SafeTextureNumForName(AMapSide.toptexture);
  if ASide.toptexture = 0 then
    ASide.toptexture := -1 - R_CustomColorMapForName(AMapSide.toptexture);

  ASide.bottomtexture := R_SafeTextureNumForName(AMapSide.bottomtexture);
  if ASide.bottomtexture = 0 then
    ASide.bottomtexture := -1 - R_CustomColorMapForName(AMapSide.bottomtexture);

  ASide.midtexture := R_SafeTextureNumForName(AMapSide.midtexture);
  if ASide.midtexture = 0 then
    ASide.midtexture := -1 - R_CustomColorMapForName(AMapSide.midtexture);
end;

class procedure TLevelColormapLines.ApplyToSectors;
var
  LIndex: Integer;
  LSide: Pside_t;
begin
  for LIndex := 0 to numlines - 1 do
    if lines[LIndex].special = COLORMAP_LINE_SPECIAL then
    begin
      LSide := @sides[lines[LIndex].sidenum[0]];
      if LSide.toptexture < 0 then
        LSide.sector.topmap := -LSide.toptexture - 1;
      if LSide.bottomtexture < 0 then
        LSide.sector.bottommap := -LSide.bottomtexture - 1;
      if LSide.midtexture < 0 then
        LSide.sector.midmap := -LSide.midtexture - 1;
    end;

  for LIndex := 0 to numsides - 1 do
  begin
    if sides[LIndex].toptexture < 0 then
      sides[LIndex].toptexture := 0;
    if sides[LIndex].bottomtexture < 0 then
      sides[LIndex].bottomtexture := 0;
    if sides[LIndex].midtexture < 0 then
      sides[LIndex].midtexture := 0;
  end;
end;

end.

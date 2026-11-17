//------------------------------------------------------------------------------
//
//  DelphiDoom is a source port of the game Doom and it is
//  based on original Linux Doom as published by "id Software"
//  Copyright (C) 1993-1996 by id Software, Inc.
//  Copyright (C) 2004-2022 by Jim Valavanis
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
// DESCRIPTION:
//  Gamma correction LUT.
//  Functions to draw patches (by post) directly to screen.
//  Functions to blit a block to the screen.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit v_video;

interface

uses
  d_delphi,
  DelphiDoom.Video.PatchZoomer,
  doomdef,
  m_fixed,
// Needed because we are refering to patches.
  r_defs,
  v_data,
  DelphiDoom.Imaging.Intf,
  DelphiDoom.Palette.Intf,
  DelphiDoom.Engine.Texture.Intf;

//==============================================================================
//
// V_GetScreenWidth
//
//==============================================================================
function V_GetScreenWidth(scrn: integer): integer;

//==============================================================================
//
// V_GetScreenHeight
//
//==============================================================================
function V_GetScreenHeight(scrn: integer): integer;

//==============================================================================
//
// V_SetPalette
//
//==============================================================================
procedure V_SetPalette(const palette: PByteArray);

{$IFNDEF OPENGL}
{$IFDEF DOOM_OR_STRIFE}

//==============================================================================
//
// V_CalcColorMapPalette
//
//==============================================================================
procedure V_CalcColorMapPalette;
{$ENDIF}
{$ENDIF}

//==============================================================================
// V_Init
//
// Allocates buffer screens, call before R_Init.
//
//==============================================================================
procedure V_Init;

//==============================================================================
//
// V_ReInit
//
//==============================================================================
procedure V_ReInit;

//==============================================================================
//
// V_ShutDown
//
//==============================================================================
procedure V_ShutDown;

//==============================================================================
//
// V_ScreensSize
//
//==============================================================================
function V_ScreensSize(const scrn: integer = -1): integer;

//==============================================================================
//
// V_CopyCustomScreen
//
//==============================================================================
procedure V_CopyCustomScreen(
  src: PByteArray;
  width: integer;
  height: integer;
  destscrn: integer);

//==============================================================================
//
// V_CopyRect
//
//==============================================================================
procedure V_CopyRect(
  srcx: integer;
  srcy: integer;
  srcscrn: integer;
  width: integer;
  height: integer;
  destx: integer;
  desty: integer;
  destscrn: integer;
  preserve: boolean);

//==============================================================================
//
// V_CopyAddRect
//
//==============================================================================
procedure V_CopyAddRect(
  srcx: integer;
  srcy: integer;
  srcscrn: integer;
  width: integer;
  height: integer;
  destx: integer;
  desty: integer;
  destscrn: integer;
  preserve: boolean;
  addfactor: fixed_t);

//==============================================================================
//
// V_CopyRectTransparent
//
//==============================================================================
procedure V_CopyRectTransparent(
  srcx: integer;
  srcy: integer;
  srcscrn: integer;
  width: integer;
  height: integer;
  destx: integer;
  desty: integer;
  destscrn: integer;
  preserve: boolean);

//==============================================================================
//
// V_CopyRectTransparentEx
//
//==============================================================================
procedure V_CopyRectTransparentEx(
  srcx: integer;
  srcy: integer;
  srcscrn: integer;
  width: integer;
  height: integer;
  destx: integer;
  desty: integer;
  destscrn: integer;
  destw: integer;
  desth: integer);

//==============================================================================
//
// V_CopyScreenTransparent
//
//==============================================================================
procedure V_CopyScreenTransparent(
  srcscrn: integer;
  destscrn: integer; srcoffs: integer = 0; destoffs: integer = 0; size: integer = -1);

{$IFDEF OPENGL}

//==============================================================================
//
// V_ShadeBackground
//
//==============================================================================
procedure V_ShadeBackground(const ofs: integer = 0;
  const count: integer = -1);
{$ELSE}

//==============================================================================
//
// V_ShadeScreen
//
//==============================================================================
procedure V_ShadeScreen(const scn: integer; const ofs: integer = 0;
  const count: integer = -1);
{$ENDIF}

//==============================================================================
//
// V_CopyRawDataToScreen
//
//==============================================================================
procedure V_CopyRawDataToScreen(scrn: integer; const lumpname: string);

//==============================================================================
//
// V_RemoveTransparency
//
//==============================================================================
procedure V_RemoveTransparency(const scn: integer; const ofs: integer;
  const count: integer = -1);

//==============================================================================
//
// V_DrawPatch
//
//==============================================================================
procedure V_DrawPatch(x, y: integer; scrn: integer; patch: Ppatch_t; preserve: boolean); overload;

//==============================================================================
//
// V_DrawPatch
//
//==============================================================================
procedure V_DrawPatch(x, y: integer; scrn: integer; const patchname: string; preserve: boolean); overload;

//==============================================================================
//
// V_DrawPatch
//
//==============================================================================
procedure V_DrawPatch(x, y: integer; scrn: integer; const lump: integer; preserve: boolean); overload;

//==============================================================================
//
// V_DrawPatchTransparent
//
//==============================================================================
procedure V_DrawPatchTransparent(x, y: integer; scrn: integer; patch: Ppatch_t; preserve: boolean);

{$IFNDEF OPENGL}

//==============================================================================
//
// V_DrawPatchTransparentMT
//
//==============================================================================
procedure V_DrawPatchTransparentMT(x, y: integer; scrn: integer; patch: Ppatch_t; preserve: boolean);
{$ENDIF}

//==============================================================================
//
// V_DrawPatchZoomed
//
//==============================================================================
procedure V_DrawPatchZoomed(x, y: integer; scrn: integer; patch: Ppatch_t; preserve: boolean; fraczoom: fixed_t);

//==============================================================================
//
// V_DrawPatchFlipped
//
//==============================================================================
procedure V_DrawPatchFlipped(x, y: integer; scrn: integer; patch: Ppatch_t);

//==============================================================================
//
// V_DrawPatchFullScreenTMP320x200
//
//==============================================================================
procedure V_DrawPatchFullScreenTMP320x200(p: Ppatch_t); overload;

//==============================================================================
//
// V_DrawPatchFullScreenTMP320x200
//
//==============================================================================
procedure V_DrawPatchFullScreenTMP320x200(const pname: string); overload;

//==============================================================================
//
// V_DrawPatchFullScreenTMP320x200
//
//==============================================================================
procedure V_DrawPatchFullScreenTMP320x200(const lump: integer); overload;

//==============================================================================
//
// V_DrawPatchFullScreenTMP426x200
//
//==============================================================================
procedure V_DrawPatchFullScreenTMP426x200(p: Ppatch_t); overload;

//==============================================================================
//
// V_DrawPatchFullScreenTMP426x200
//
//==============================================================================
procedure V_DrawPatchFullScreenTMP426x200(const pname: string); overload;

//==============================================================================
//
// V_DrawPatchFullScreenTMP426x200
//
//==============================================================================
procedure V_DrawPatchFullScreenTMP426x200(const lump: integer); overload;

//==============================================================================
//
// V_PageDrawer
//
//==============================================================================
procedure V_PageDrawer(const pagename: string);

//==============================================================================
// V_DrawBlock
//
// Draw a linear block of pixels into the view buffer.
//
//==============================================================================

//==============================================================================
//
// V_DrawLongBlock
//
//==============================================================================

//==============================================================================
// V_GetBlock
//
// Reads a linear block of pixels into the view buffer.
//
//==============================================================================

//==============================================================================
//
// V_PreserveX
//
//==============================================================================
function V_PreserveX(const x: integer): integer; overload;

//==============================================================================
//
// V_PreserveX
//
//==============================================================================
function V_PreserveX(const SCN: integer; const x: integer): integer; overload;

//==============================================================================
//
// V_PreserveY
//
//==============================================================================
function V_PreserveY(const y: integer): integer;

{$IFDEF OPENGL}

//==============================================================================
//
// V_PreserveGLX
//
//==============================================================================
function V_PreserveGLX(const x: integer): integer;

//==============================================================================
//
// V_PreserveGLY
//
//==============================================================================
function V_PreserveGLY(const y: integer): integer;
{$ENDIF}

//==============================================================================
//
// V_PreserveW
//
//==============================================================================
function V_PreserveW(const x: integer; const w: integer): integer; overload;

//==============================================================================
//
// V_PreserveW
//
//==============================================================================
function V_PreserveW(const SCN: integer; const x: integer; const w: integer): integer; overload;

//==============================================================================
//
// V_PreserveH
//
//==============================================================================
function V_PreserveH(const y: integer; const h: integer): integer;

//==============================================================================
//
// V_NeedsPreserve
//
//==============================================================================
function V_NeedsPreserve(const destscrn, srcscrn: integer): boolean; overload;

//==============================================================================
//
// V_NeedsPreserve
//
//==============================================================================
function V_NeedsPreserve(const destscrn, srcscrn: integer; preserve: boolean): boolean; overload;

//==============================================================================
//
// V_CalcPreserveTables
//
//==============================================================================
procedure V_CalcPreserveTables;

//==============================================================================
//
// V_TileScreen8
//
//==============================================================================
function V_TileScreen8(const lumpname: string; const dstscn: integer): boolean;

const
  GAMMASIZE = 5;

var
  // The gamma tables, one row of 256 bytes for each level: they come from
  // Framework\Palette (V_ConfigureGamma), given by the composition root
  gammatable: array[0..GAMMASIZE - 1, 0..255] of byte;

//==============================================================================
//
// V_ConfigureGamma
// Fills gammatable with the tables of Framework\Palette
//
//==============================================================================
procedure V_ConfigureGamma(const ATables: IGammaTables);

//==============================================================================
//
// V_ConfigureFlatShrink
// The shrinker of the flats of Framework\Imaging (V_TileScreen8), given by the
// composition root
//
//==============================================================================
procedure V_ConfigureFlatShrink(const AShrinker: IImagingFlatShrinker);

//==============================================================================
//
// V_ConfigureDrawTextures
// The external textures of the full screen pages, given by the composition root
//
//==============================================================================
procedure V_ConfigureDrawTextures(const ADrawTextures: IEngineDrawTextures);

//==============================================================================
//
// V_InitDrawTextures
//
//==============================================================================
procedure V_InitDrawTextures;

//==============================================================================
//
// V_ShutDownDrawTextures
//
//==============================================================================
procedure V_ShutDownDrawTextures;

var
  usegamma: byte;

  curpal: array[0..255] of LongWord;
  videopal: array[0..255] of LongWord absolute DelphiDoom.Video.PatchZoomer.VideoZoomPalette;
  cvideopal: array[0..255] of LongWord;
{$IFNDEF OPENGL}
  {$IFDEF HEXEN}
  skvideopal: array[0..255] of LongWord;
  {$ENDIF}
{$ENDIF}

//==============================================================================
//
// V_FindAproxColorIndex
//
//==============================================================================
function V_FindAproxColorIndex(const pal: PLongWordArray; const c: LongWord;
  const start: integer = 0; const finish: integer = 255): integer;

//==============================================================================
//
// V_FindAproxColorIndexExcluding
//
//==============================================================================
function V_FindAproxColorIndexExcluding(const pal: PLongWordArray; const c: LongWord;
  const start: integer = 0; const finish: integer = 255; const exclude: integer = -1): integer;

//==============================================================================
//
// V_FullScreenStretch
//
//==============================================================================
procedure V_FullScreenStretch;

{$IFDEF DOOM}
//==============================================================================
//
// V_StatusBarStretch
//
//==============================================================================
procedure V_StatusBarStretch;
{$ENDIF}

var
  v_translation: PByteArray;

var
  default_palette: PLongWordArray = nil;
  intermissionstretch: boolean = true;
  statusbarstretch: boolean = true;

implementation

uses
  i_system,
  am_map,
  mt_utils,
  psi_overlay,
  DelphiDoom.ScriptHost.Overlay.Drawer,
  r_hires,
  r_precalc,
  r_data,
  r_draw,
  r_main,
  {$IFNDEF OPENGL}
  r_mmx,
  r_trans8,
  {$IFDEF DOOM_OR_STRIFE}
  r_colormaps,
  {$ENDIF}
  {$ENDIF}
  {$IFDEF DOOM_OR_STRIFE}
  st_lib,
  st_stuff,
  {$ENDIF}
  r_flatinfo,
  r_aspect,
  DelphiDoom.Texture.PatchInspector,
  DelphiDoom.Palette.NearestColor,
  DelphiDoom.Palette.ScreenPalette,
  DelphiDoom.Video.PreserveTables,
  DelphiDoom.Video.ScreenLayout,
  DelphiDoom.Video.TileGrid,
  DelphiDoom.Video.PageLayout,
  DelphiDoom.Video.Stretch,
  DelphiDoom.Video.ScreenOps,
  DelphiDoom.Video.PatchPainter,
  DelphiDoom.Video.PatchPainter32,
  DelphiDoom.Video.RectCopy,
  w_wad,
  z_zone;

//==============================================================================
//
// V_ConfigureGamma
//
//==============================================================================
procedure V_ConfigureGamma(const ATables: IGammaTables);
var
  level: integer;
  row: TArray<Byte>;
begin
  if ATables.LevelCount <> GAMMASIZE then
    I_Error('V_ConfigureGamma(): %d gamma levels instead of %d', [ATables.LevelCount, GAMMASIZE]);
  for level := 0 to GAMMASIZE - 1 do
  begin
    row := ATables.Table(level);
    memcpy(@gammatable[level, 0], @row[0], 256);
  end;
end;

var
  draw_textures: IEngineDrawTextures = nil;

//==============================================================================
//
// V_ConfigureDrawTextures
//
//==============================================================================
procedure V_ConfigureDrawTextures(const ADrawTextures: IEngineDrawTextures);
begin
  draw_textures := ADrawTextures;
end;

//==============================================================================
//
// V_InitDrawTextures
//
//==============================================================================
procedure V_InitDrawTextures;
begin
  if draw_textures = nil then
    I_Error('V_InitDrawTextures(): the draw textures are not configured');
  draw_textures.Initialize;
end;

//==============================================================================
//
// V_ShutDownDrawTextures
//
//==============================================================================
procedure V_ShutDownDrawTextures;
begin
  if draw_textures <> nil then
    draw_textures.ShutDown;
end;
var
  flat_shrinker: IImagingFlatShrinker = nil;

//==============================================================================
//
// V_ConfigureFlatShrink
//
//==============================================================================
procedure V_ConfigureFlatShrink(const AShrinker: IImagingFlatShrinker);
begin
  flat_shrinker := AShrinker;
end;

//==============================================================================
//
// V_ShrinkFlatTo64x64
// The 64x64 flat of a lump of any size of flat (it was R_ShrinkFlatTo64x64
// of r_flatinfo.pas)
//
//==============================================================================
function V_ShrinkFlatTo64x64(const fin: Pointer; const sz: Integer; const fout: Pointer): Boolean;
var
  flat: TArray<Byte>;
  shrunk: TArray<Byte>;
begin
  result := false;
  if flat_shrinker = nil then
    I_Error('V_ShrinkFlatTo64x64(): the images are not configured (ComposeEngine was not called)');

  if sz <= 0 then
    exit;

  SetLength(flat, sz);
  Move(fin^, flat[0], sz);
  if flat_shrinker.Shrink(flat, shrunk) then
  begin
    Move(shrunk[0], fout^, Length(shrunk));
    result := true;
  end;
end;

// x and y translation tables for stretcing
var
  preservetables: TVideoPreserveTables = nil;
  widthintmultiplier: Integer = 0;
  heightintmultiplier: Integer = 0;

//==============================================================================
//
// V_NeedsPreserve
//
//==============================================================================
function V_NeedsPreserve(const destscrn, srcscrn: integer): boolean; overload;
begin
  result := (V_GetScreenWidth(srcscrn) <> V_GetScreenWidth(destscrn)) or
            (V_GetScreenHeight(srcscrn) <> V_GetScreenHeight(destscrn));
end;

//==============================================================================
//
// V_NeedsPreserve
//
//==============================================================================
function V_NeedsPreserve(const destscrn, srcscrn: integer; preserve: boolean): boolean; overload;
begin
  result := preserve and V_NeedsPreserve(destscrn, srcscrn);
end;

//==============================================================================
// V_PreserveX
//
// preserve x coordinates
//
//==============================================================================
function V_PreserveX(const x: integer): integer;
begin
  result := preservetables.MapX(x);
end;

//==============================================================================
// V_PreserveX
//
// preserve x coordinates
//
//==============================================================================
function V_PreserveX(const SCN: integer; const x: integer): integer;
begin
  result := preservetables.MapX(V_GetScreenWidth(SCN), x);
end;

//==============================================================================
// V_PreserveY
//
// preserve y coordinates
//
//==============================================================================
function V_PreserveY(const y: integer): integer;
begin
  result := preservetables.MapY(y);
end;

{$IFDEF OPENGL}

//==============================================================================
//
// V_PreserveGLX
//
//==============================================================================
function V_PreserveGLX(const x: integer): integer;
begin
  result := Round(x * GLDRAWWIDTH / SCREENWIDTH);
end;

//==============================================================================
//
// V_PreserveGLY
//
//==============================================================================
function V_PreserveGLY(const y: integer): integer;
begin
  result := Round(y * GLDRAWHEIGHT / SCREENHEIGHT);
end;
{$ENDIF}

//==============================================================================
// V_PreserveW
//
// preserve width coordinates
//
//==============================================================================
function V_PreserveW(const x: integer; const w: integer): integer;
begin
  result := V_PreserveX(x + w) - V_PreserveX(x);
end;

//==============================================================================
// V_PreserveW
//
// preserve width coordinates
//
//==============================================================================
function V_PreserveW(const SCN: integer; const x: integer; const w: integer): integer;
begin
  result := V_PreserveX(SCN, x + w) - V_PreserveX(SCN, x);
end;

//==============================================================================
// V_PreserveH
//
// preserve height coordinates
//
//==============================================================================
function V_PreserveH(const y: integer; const h: integer): integer;
begin
  result := V_PreserveY(y + h) - V_PreserveY(y);
end;

//==============================================================================
//
// V_CopyCustomScreen8
//
//==============================================================================
procedure V_CopyCustomScreen8(
  scrA: PByteArray;
  width: integer;
  height: integer;
  destscrn: integer);
var
  src: PByteArray;
  dest: PByte;
  destw: integer;
  desth: integer;
  fracxstep: fixed_t;
  fracystep: fixed_t;
  fracx: fixed_t;
  fracy: fixed_t;
  col: integer;
  row: integer;
begin
  destw := V_GetScreenWidth(destscrn);
  desth := V_GetScreenHeight(destscrn);

  fracy := 0;
  fracxstep := FRACUNIT * width div destw;
  fracystep := FRACUNIT * height div desth;

  for row := 0 to desth - 1 do
  begin
    fracx := 0;
    dest := PByte(NativeInt(screens[destscrn]) + destw * row);
    src := @scrA[(fracy div FRACUNIT) * width];
    for col := 0 to destw - 1 do
    begin
      dest^ := src[LongWord(fracx) shr FRACBITS];
      inc(dest);
      fracx := fracx + fracxstep;
    end;
    fracy := fracy + fracystep;
  end
end;

//==============================================================================
//
// V_CopyCustomScreen32
//
//==============================================================================
procedure V_CopyCustomScreen32(
  scrA: PByteArray;
  width: integer;
  height: integer);
var
  src: PByteArray;
  dest: PLongWord;
  destw: integer;
  desth: integer;
  fracxstep: fixed_t;
  fracystep: fixed_t;
  fracx: fixed_t;
  fracy: fixed_t;
  col: integer;
  row: integer;
begin
  destw := V_GetScreenWidth(SCN_FG);
  desth := V_GetScreenHeight(SCN_FG);

  fracy := 0;
  fracxstep := FRACUNIT * width div destw;
  fracystep := FRACUNIT * height div desth;

  dest := @screen32[0];
  for row := 0 to desth - 1 do
  begin
    fracx := 0;
    src := @scrA[(fracy div FRACUNIT) * width];
    for col := 0 to destw - 1 do
    begin
      dest^ := videopal[src[LongWord(fracx) shr FRACBITS]];
      inc(dest);
      fracx := fracx + fracxstep;
    end;
    fracy := fracy + fracystep;
  end
end;

//==============================================================================
//
// V_CopyCustomScreen
//
//==============================================================================
procedure V_CopyCustomScreen(
  src: PByteArray;
  width: integer;
  height: integer;
  destscrn: integer);
begin
  if {$IFNDEF OPENGL}(videomode = vm32bit) and{$ENDIF} (destscrn = SCN_FG) then
    V_CopyCustomScreen32(src, width, height)
  else
    V_CopyCustomScreen8(src, width, height, destscrn)
end;

//==============================================================================
//
// V_CopyRect8
//
//==============================================================================
procedure V_CopyRect8(
  srcx: integer;
  srcy: integer;
  srcscrn: integer;
  width: integer;
  height: integer;
  destx: integer;
  desty: integer;
  destscrn: integer;
  preserve: boolean);
var
  src: PByteArray;
  destA: PByteArray;
  destw: integer;
  desth: integer;
  swidth: integer;
  dwidth: integer;
  params: TVideoRectCopyParams;
begin
  swidth := V_GetScreenWidth(srcscrn);
  dwidth := V_GetScreenWidth(destscrn);
  if V_NeedsPreserve(destscrn, srcscrn, preserve) then
  begin
    destw := V_PreserveW(srcscrn, destx, width);

    desth := V_PreserveH(desty, height);

    if (destw <> 0) and (desth <> 0) then
    begin
      destx := V_PreserveX(srcscrn, destx);

      desty := V_PreserveY(desty);

      // The loops over the rows are TVideoRectCopy (Framework\Video)
      params.Source := System.PByte(screens[srcscrn]);
      params.Destination := screens[destscrn];
      params.SourcePitch := swidth;
      params.DestinationPitch := dwidth;
      params.SourceX := srcx;
      params.DestinationX := destx;
      params.DestinationY := desty;
      params.DestinationWidth := destw;
      params.DestinationHeight := desth;
      params.FracY := srcy * FRACUNIT;
      params.FracYStep := FRACUNIT * height div desth;
      params.Index := 0;
      params.IndexCount := 1;

      if swidth = 320 then
        if TVideoRectCopy.ExpandRows8(widthintmultiplier, params, @precal8_toword[0], @precal8_tolong[0]) then
          Exit;

      params.FracXStep := FRACUNIT * width div destw;
      TVideoRectCopy.StretchRows8(params);
    end;
  end
  else
  begin

    src := PByteArray(NativeInt(screens[srcscrn]) + swidth * srcy + srcx);
    destA := PByteArray(NativeInt(screens[destscrn]) + dwidth * desty + destx);

    while height > 0 do
    begin
      memcpy(destA, src, width);
      src := PByteArray(NativeInt(src) + swidth);
      destA := PByteArray(NativeInt(destA) + dwidth);
      dec(height);
    end;
  end;
end;

//==============================================================================
//
// V_CopyRect8_MT
//
//==============================================================================
procedure V_CopyRect8_MT(
  idx, numidxs: integer;
  srcx: integer;
  srcy: integer;
  srcscrn: integer;
  width: integer;
  height: integer;
  destx: integer;
  desty: integer;
  destscrn: integer;
  preserve: boolean);
var
  src: PByteArray;
  destA: PByteArray;
  destw: integer;
  desth: integer;
  swidth: integer;
  dwidth: integer;
  params: TVideoRectCopyParams;
begin
  swidth := V_GetScreenWidth(srcscrn);
  dwidth := V_GetScreenWidth(destscrn);
  if V_NeedsPreserve(destscrn, srcscrn, preserve) then
  begin
    destw := V_PreserveW(srcscrn, destx, width);

    desth := V_PreserveH(desty, height);

    if (destw <> 0) and (desth <> 0) then
    begin
      destx := V_PreserveX(srcscrn, destx);

      desty := V_PreserveY(desty);

      // The loops over the rows are TVideoRectCopy (Framework\Video)
      params.Source := System.PByte(screens[srcscrn]);
      params.Destination := screens[destscrn];
      params.SourcePitch := swidth;
      params.DestinationPitch := dwidth;
      params.SourceX := srcx;
      params.DestinationX := destx;
      params.DestinationY := desty;
      params.DestinationWidth := destw;
      params.DestinationHeight := desth;
      params.FracY := srcy * FRACUNIT;
      params.FracYStep := FRACUNIT * height div desth;
      params.Index := idx;
      params.IndexCount := numidxs;

      if swidth = 320 then
        if TVideoRectCopy.ExpandRows8(widthintmultiplier, params, @precal8_toword[0], @precal8_tolong[0]) then
          Exit;

      params.FracXStep := FRACUNIT * width div destw;
      TVideoRectCopy.StretchRows8(params);
    end;
  end
  else
  begin

    src := PByteArray(NativeInt(screens[srcscrn]) + swidth * srcy + srcx);
    destA := PByteArray(NativeInt(screens[destscrn]) + dwidth * desty + destx);

    while height > 0 do
    begin
      if height mod numidxs = idx then
        memcpy(destA, src, width);
      src := PByteArray(NativeInt(src) + swidth);
      destA := PByteArray(NativeInt(destA) + dwidth);
      dec(height);
    end;
  end;
end;

//==============================================================================
//
// V_CopyRect32
//
//==============================================================================
procedure V_CopyRect32(
  srcx: integer;
  srcy: integer;
  srcscrn: integer;
  width: integer;
  height: integer;
  destx: integer;
  desty: integer;
  preserve: boolean);
var
  destw: integer;
  desth: integer;
  fracxstep: fixed_t;
  fracystep: fixed_t;
  swidth: integer;
  dwidth: integer;
  pv: boolean;
  params: TVideoRectCopyParams;
begin
  swidth := V_GetScreenWidth(srcscrn);
  dwidth := V_GetScreenWidth(SCN_FG);

  pv := V_NeedsPreserve(SCN_FG, srcscrn, preserve);
  if pv then
  begin
    destw := V_PreserveW(srcscrn, destx, width);
    desth := V_PreserveH(desty, height);
  end
  else
  begin
    destw := width;
    desth := height;
  end;

  if (destw <> 0) and (desth <> 0) then
  begin
    if pv then
    begin
      destx := V_PreserveX(srcscrn, destx);
      desty := V_PreserveY(desty);
      fracxstep := FRACUNIT * width div destw;
      fracystep := FRACUNIT * height div desth;
    end
    else
    begin
      fracxstep := FRACUNIT;
      fracystep := FRACUNIT;
    end;

    // The loops over the rows are TVideoRectCopy (Framework\Video)
    params.Source := System.PByte(screens[srcscrn]);
    params.Destination := @screen32[0];
    params.SourcePitch := swidth;
    params.DestinationPitch := dwidth;
    params.SourceX := srcx;
    params.DestinationX := destx;
    params.DestinationY := desty;
    params.DestinationWidth := destw;
    params.DestinationHeight := desth;
    params.FracY := srcy * FRACUNIT;
    params.FracYStep := fracystep;
    params.FracXStep := fracxstep;
    params.Index := 0;
    params.IndexCount := 1;

    if pv and (swidth = 320) then
      if TVideoRectCopy.ExpandRows32(widthintmultiplier, params, System.PLongWord(@videopal[0])) then
        Exit;

    TVideoRectCopy.StretchRows32(params, System.PLongWord(@videopal[0]));
  end;
end;

//==============================================================================
//
// V_CopyRect32_MT
//
//==============================================================================
procedure V_CopyRect32_MT(
  idx, numidxs: integer;
  srcx: integer;
  srcy: integer;
  srcscrn: integer;
  width: integer;
  height: integer;
  destx: integer;
  desty: integer;
  preserve: boolean);
var
  destw: integer;
  desth: integer;
  fracxstep: fixed_t;
  fracystep: fixed_t;
  swidth: integer;
  dwidth: integer;
  pv: boolean;
  params: TVideoRectCopyParams;
begin
  swidth := V_GetScreenWidth(srcscrn);
  dwidth := V_GetScreenWidth(SCN_FG);

  pv := V_NeedsPreserve(SCN_FG, srcscrn, preserve);
  if pv then
  begin
    destw := V_PreserveW(srcscrn, destx, width);
    desth := V_PreserveH(desty, height);
  end
  else
  begin
    destw := width;
    desth := height;
  end;

  if (destw <> 0) and (desth <> 0) then
  begin
    if pv then
    begin
      destx := V_PreserveX(srcscrn, destx);
      desty := V_PreserveY(desty);
      fracxstep := FRACUNIT * width div destw;
      fracystep := FRACUNIT * height div desth;
    end
    else
    begin
      fracxstep := FRACUNIT;
      fracystep := FRACUNIT;
    end;

    // The loops over the rows are TVideoRectCopy (Framework\Video)
    params.Source := System.PByte(screens[srcscrn]);
    params.Destination := @screen32[0];
    params.SourcePitch := swidth;
    params.DestinationPitch := dwidth;
    params.SourceX := srcx;
    params.DestinationX := destx;
    params.DestinationY := desty;
    params.DestinationWidth := destw;
    params.DestinationHeight := desth;
    params.FracY := srcy * FRACUNIT;
    params.FracYStep := fracystep;
    params.FracXStep := fracxstep;
    params.Index := idx;
    params.IndexCount := numidxs;

    if pv and (swidth = 320) then
      if TVideoRectCopy.ExpandRows32(widthintmultiplier, params, System.PLongWord(@videopal[0])) then
        Exit;

    TVideoRectCopy.StretchRows32(params, System.PLongWord(@videopal[0]));
  end;
end;

type
  th_copyrect_t = record
    srcx: integer;
    srcy: integer;
    srcscrn: integer;
    width: integer;
    height: integer;
    destx: integer;
    desty: integer;
    destscrn: integer;
    preserve: boolean;
  end;
  th_copyrect_p = ^th_copyrect_t;

//==============================================================================
//
// V_CopyRect8_thr
//
//==============================================================================
function V_CopyRect8_thr(p: iterator_p): integer; stdcall;
var
  crp: th_copyrect_p;
begin
  crp := p.data;
    V_CopyRect8_MT(
      p.idx, p.numidxs,
      crp.srcx,
      crp.srcy,
      crp.srcscrn,
      crp.width,
      crp.height,
      crp.destx,
      crp.desty,
      crp.destscrn,
      crp.preserve
    );
  result := 0;
end;

//==============================================================================
//
// V_CopyRect32_thr
//
//==============================================================================
function V_CopyRect32_thr(p: iterator_p): integer; stdcall;
var
  crp: th_copyrect_p;
begin
  crp := p.data;
    V_CopyRect32_MT(
      p.idx, p.numidxs,
      crp.srcx,
      crp.srcy,
      crp.srcscrn,
      crp.width,
      crp.height,
      crp.destx,
      crp.desty,
      crp.preserve
    );
  result := 0;
end;

//==============================================================================
//
// V_CopyRect
//
//==============================================================================
procedure V_CopyRect(
  srcx: integer;
  srcy: integer;
  srcscrn: integer;
  width: integer;
  height: integer;
  destx: integer;
  desty: integer;
  destscrn: integer;
  preserve: boolean);
var
  cr: th_copyrect_t;
begin
  if usemultithread then
  begin
    cr.srcx := srcx;
    cr.srcy := srcy;
    cr.srcscrn := srcscrn;
    cr.width := width;
    cr.height := height;
    cr.destx := destx;
    cr.desty := desty;
    cr.destscrn := destscrn;
    cr.preserve := preserve;
    if {$IFNDEF OPENGL}(videomode = vm32bit) and{$ENDIF} (destscrn = SCN_FG) then
      MT_Iterate(@V_CopyRect32_thr, @cr)
    else
      MT_Iterate(@V_CopyRect8_thr, @cr);
  end
  else
  begin
    if {$IFNDEF OPENGL}(videomode = vm32bit) and{$ENDIF} (destscrn = SCN_FG) then
      V_CopyRect32(
        srcx,
        srcy,
        srcscrn,
        width,
        height,
        destx,
        desty,
        preserve)
    else
      V_CopyRect8(
        srcx,
        srcy,
        srcscrn,
        width,
        height,
        destx,
        desty,
        destscrn,
        preserve);
  end;
end;

//==============================================================================
//
// V_CopyAddRect
//
//==============================================================================
procedure V_CopyAddRect(
  srcx: integer;
  srcy: integer;
  srcscrn: integer;
  width: integer;
  height: integer;
  destx: integer;
  desty: integer;
  destscrn: integer;
  preserve: boolean;
  addfactor: fixed_t);
var
  src: PByteArray;
  dest: PLongWord;
  destw: integer;
  desth: integer;
  fracxstep: fixed_t;
  fracystep: fixed_t;
  fracx: fixed_t;
  fracy: fixed_t;
  col: integer;
  row: integer;
  swidth: integer;
  dwidth: integer;
{$IFDEF OPENGL}
  pb: PByte;
  bfactor: byte;
{$ENDIF}
begin
  if addfactor <= 0 then
  begin
    V_CopyRect(srcx, srcy, srcscrn, width, height, destx, desty, destscrn, preserve);
    exit;
  end;

  if addfactor > FRACUNIT then
    exit;

{$IFDEF OPENGL}
  bfactor := 255 - (addfactor shr 16);
{$ENDIF}

  if {$IFNDEF OPENGL}(videomode = vm32bit) and{$ENDIF} (destscrn = SCN_FG) then
  begin
    swidth := V_GetScreenWidth(srcscrn);
    dwidth := V_GetScreenWidth(SCN_FG);

    if V_NeedsPreserve(SCN_FG, srcscrn, preserve) then
    begin
      destw := V_PreserveW(destx, width);
      desth := V_PreserveH(desty, height);
    end
    else
    begin
      destw := width;
      desth := height;
    end;

    if (destw <> 0) and (desth <> 0) then
    begin
      if V_NeedsPreserve(SCN_FG, srcscrn, preserve) then
      begin
        destx := V_PreserveX(destx);
        desty := V_PreserveY(desty);
        fracxstep := FRACUNIT * width div destw;
        fracystep := FRACUNIT * height div desth;
      end
      else
      begin
        fracxstep := FRACUNIT;
        fracystep := FRACUNIT;
      end;

      fracy := srcy * FRACUNIT;

      for row := desty to desty + desth - 1 do
      begin
        fracx := 0;
        dest := @screen32[dwidth * row + destx];
        src := PByteArray(NativeInt(screens[srcscrn]) + swidth * (fracy div FRACUNIT) + srcx);
        for col := 0 to destw - 1 do
        begin
          dest^ := R_ColorAverage(videopal[src[LongWord(fracx) shr FRACBITS]], dest^, addfactor);
          {$IFDEF OPENGL}
          pb := PByte(NativeInt(dest) + 3);
          pb^ := bfactor;
          {$ENDIF}
          inc(dest);
          fracx := fracx + fracxstep;
        end;
        fracy := fracy + fracystep;
      end;
    end;
  end
  else
    V_CopyRect8(srcx, srcy, srcscrn, width, height, destx, desty, destscrn, preserve);
end;

//==============================================================================
//
// V_CopyRectTransparent
//
//==============================================================================
procedure V_CopyRectTransparent8(
  srcx: integer;
  srcy: integer;
  srcscrn: integer;
  width: integer;
  height: integer;
  destx: integer;
  desty: integer;
  destscrn: integer;
  preserve: boolean);
var
  destw: integer;
  desth: integer;
  swidth: integer;
  dwidth: integer;
  params: TVideoRectCopyParams;
begin
  swidth := V_GetScreenWidth(srcscrn);
  dwidth := V_GetScreenWidth(destscrn);
  if V_NeedsPreserve(destscrn, srcscrn, preserve) then
  begin
    destw := V_PreserveW(destx, width);

    desth := V_PreserveH(desty, height);

    if (destw <> 0) and (desth <> 0) then
    begin
      destx := V_PreserveX(destx);

      desty := V_PreserveY(desty);

      // The loops over the rows are TVideoRectCopy (Framework\Video)
      params.Source := System.PByte(screens[srcscrn]);
      params.Destination := screens[destscrn];
      params.SourcePitch := swidth;
      params.DestinationPitch := dwidth;
      params.SourceX := srcx;
      params.DestinationX := destx;
      params.DestinationY := desty;
      params.DestinationWidth := destw;
      params.DestinationHeight := desth;
      params.FracY := srcy * FRACUNIT;
      params.FracYStep := FRACUNIT * height div desth;
      params.FracXStep := FRACUNIT * width div destw;
      params.Index := 0;
      params.IndexCount := 1;
      TVideoRectCopy.StretchRowsTransparent8(params);
    end;
  end
  else
    TVideoRectCopy.CopyRowsTransparent8(
      System.PByte(NativeInt(screens[srcscrn]) + swidth * srcy + srcx),
      System.PByte(NativeInt(screens[destscrn]) + dwidth * desty + destx),
      swidth, dwidth, width, height, 0, 1);
end;

//==============================================================================
//
// V_CopyRectTransparent8_MT
//
//==============================================================================
procedure V_CopyRectTransparent8_MT(
  idx, numidxs: integer;
  srcx: integer;
  srcy: integer;
  srcscrn: integer;
  width: integer;
  height: integer;
  destx: integer;
  desty: integer;
  destscrn: integer;
  preserve: boolean);
var
  destw: integer;
  desth: integer;
  swidth: integer;
  dwidth: integer;
  params: TVideoRectCopyParams;
begin
  swidth := V_GetScreenWidth(srcscrn);
  dwidth := V_GetScreenWidth(destscrn);
  if V_NeedsPreserve(destscrn, srcscrn, preserve) then
  begin
    destw := V_PreserveW(destx, width);

    desth := V_PreserveH(desty, height);

    if (destw <> 0) and (desth <> 0) then
    begin
      destx := V_PreserveX(destx);

      desty := V_PreserveY(desty);

      // The loops over the rows are TVideoRectCopy (Framework\Video)
      params.Source := System.PByte(screens[srcscrn]);
      params.Destination := screens[destscrn];
      params.SourcePitch := swidth;
      params.DestinationPitch := dwidth;
      params.SourceX := srcx;
      params.DestinationX := destx;
      params.DestinationY := desty;
      params.DestinationWidth := destw;
      params.DestinationHeight := desth;
      params.FracY := srcy * FRACUNIT;
      params.FracYStep := FRACUNIT * height div desth;
      params.FracXStep := FRACUNIT * width div destw;
      params.Index := idx;
      params.IndexCount := numidxs;
      TVideoRectCopy.StretchRowsTransparent8(params);
    end;
  end
  else
    TVideoRectCopy.CopyRowsTransparent8(
      System.PByte(NativeInt(screens[srcscrn]) + swidth * srcy + srcx),
      System.PByte(NativeInt(screens[destscrn]) + dwidth * desty + destx),
      swidth, dwidth, width, height, idx, numidxs);
end;

//==============================================================================
//
// V_CopyRectTransparent32
//
//==============================================================================
procedure V_CopyRectTransparent32(
  srcx: integer;
  srcy: integer;
  srcscrn: integer;
  width: integer;
  height: integer;
  destx: integer;
  desty: integer;
  preserve: boolean);
var
  destw: integer;
  desth: integer;
  fracxstep: fixed_t;
  fracystep: fixed_t;
  swidth: integer;
  dwidth: integer;
  pv: boolean;
  params: TVideoRectCopyParams;
begin
  swidth := V_GetScreenWidth(srcscrn);
  dwidth := V_GetScreenWidth(SCN_FG);

  pv := V_NeedsPreserve(SCN_FG, srcscrn, preserve);
  if pv then
  begin
    destw := V_PreserveW(destx, width);
    desth := V_PreserveH(desty, height);
  end
  else
  begin
    destw := width;
    desth := height;
  end;

  if (destw <> 0) and (desth <> 0) then
  begin
    if pv then
    begin
      destx := V_PreserveX(destx);
      desty := V_PreserveY(desty);
      fracxstep := FRACUNIT * width div destw;
      fracystep := FRACUNIT * height div desth;
    end
    else
    begin
      fracxstep := FRACUNIT;
      fracystep := FRACUNIT;
    end;

    // The loops over the rows are TVideoRectCopy (Framework\Video)
    params.Source := System.PByte(screens[srcscrn]);
    params.Destination := @screen32[0];
    params.SourcePitch := swidth;
    params.DestinationPitch := dwidth;
    params.SourceX := srcx;
    params.DestinationX := destx;
    params.DestinationY := desty;
    params.DestinationWidth := destw;
    params.DestinationHeight := desth;
    params.FracY := srcy * FRACUNIT;
    params.FracYStep := fracystep;
    params.FracXStep := fracxstep;
    params.Index := 0;
    params.IndexCount := 1;
    TVideoRectCopy.StretchRowsTransparent32(params, System.PLongWord(@videopal[0]));
  end;
end;

//==============================================================================
//
// V_CopyRectTransparent32_MT
//
//==============================================================================
procedure V_CopyRectTransparent32_MT(
  idx, numidxs: integer;
  srcx: integer;
  srcy: integer;
  srcscrn: integer;
  width: integer;
  height: integer;
  destx: integer;
  desty: integer;
  preserve: boolean);
var
  destw: integer;
  desth: integer;
  fracxstep: fixed_t;
  fracystep: fixed_t;
  swidth: integer;
  dwidth: integer;
  pv: boolean;
  params: TVideoRectCopyParams;
begin
  swidth := V_GetScreenWidth(srcscrn);
  dwidth := V_GetScreenWidth(SCN_FG);

  pv := V_NeedsPreserve(SCN_FG, srcscrn, preserve);
  if pv then
  begin
    destw := V_PreserveW(destx, width);
    desth := V_PreserveH(desty, height);
  end
  else
  begin
    destw := width;
    desth := height;
  end;

  if (destw <> 0) and (desth <> 0) then
  begin
    if pv then
    begin
      destx := V_PreserveX(destx);
      desty := V_PreserveY(desty);
      fracxstep := FRACUNIT * width div destw;
      fracystep := FRACUNIT * height div desth;
    end
    else
    begin
      fracxstep := FRACUNIT;
      fracystep := FRACUNIT;
    end;

    // The loops over the rows are TVideoRectCopy (Framework\Video)
    params.Source := System.PByte(screens[srcscrn]);
    params.Destination := @screen32[0];
    params.SourcePitch := swidth;
    params.DestinationPitch := dwidth;
    params.SourceX := srcx;
    params.DestinationX := destx;
    params.DestinationY := desty;
    params.DestinationWidth := destw;
    params.DestinationHeight := desth;
    params.FracY := srcy * FRACUNIT;
    params.FracYStep := fracystep;
    params.FracXStep := fracxstep;
    params.Index := idx;
    params.IndexCount := numidxs;
    TVideoRectCopy.StretchRowsTransparent32(params, System.PLongWord(@videopal[0]));
  end;
end;

type
  th_copyrecttransparent8_t = record
    srcx: integer;
    srcy: integer;
    srcscrn: integer;
    width: integer;
    height: integer;
    destx: integer;
    desty: integer;
    destscrn: integer;
    preserve: boolean;
  end;
  th_copyrecttransparent8_p = ^th_copyrecttransparent8_t;

  th_copyrecttransparent32_t = record
    srcx: integer;
    srcy: integer;
    srcscrn: integer;
    width: integer;
    height: integer;
    destx: integer;
    desty: integer;
    preserve: boolean;
  end;
  th_copyrecttransparent32_p = ^th_copyrecttransparent32_t;

//==============================================================================
//
// V_CopyRectTransparent8_thr
//
//==============================================================================
function V_CopyRectTransparent8_thr(it: iterator_p): integer; stdcall;
var
  p8: th_copyrecttransparent8_p;
begin
  p8 := it.data;
  V_CopyRectTransparent8_MT(
    it.idx, it.numidxs,
    p8.srcx, p8.srcy, p8.srcscrn, p8.width, p8.height, p8.destx, p8.desty, p8.destscrn, p8.preserve);
  result := 0;
end;

//==============================================================================
//
// V_CopyRectTransparent32_thr
//
//==============================================================================
function V_CopyRectTransparent32_thr(it: iterator_p): integer; stdcall;
var
  p32: th_copyrecttransparent32_p;
begin
  p32 := it.data;
  V_CopyRectTransparent32_MT(
    it.idx, it.numidxs,
    p32.srcx, p32.srcy, p32.srcscrn, p32.width, p32.height, p32.destx, p32.desty, p32.preserve);
  result := 0;
end;

//==============================================================================
//
// V_CopyRectTransparent
//
//==============================================================================
procedure V_CopyRectTransparent(
  srcx: integer;
  srcy: integer;
  srcscrn: integer;
  width: integer;
  height: integer;
  destx: integer;
  desty: integer;
  destscrn: integer;
  preserve: boolean);
var
  r8: th_copyrecttransparent8_t;
  r32: th_copyrecttransparent32_t;
begin
  if usemultithread then
  begin
    if {$IFNDEF OPENGL}(videomode = vm32bit) and{$ENDIF} (destscrn = SCN_FG) then
    begin
      r32.srcx := srcx;
      r32.srcy := srcy;
      r32.srcscrn := srcscrn;
      r32.width := width;
      r32.height := height;
      r32.destx := destx;
      r32.desty := desty;
      r32.preserve := preserve;
      MT_Iterate(@V_CopyRectTransparent32_thr, @r32);
    end
    else
    begin
      r8.srcx := srcx;
      r8.srcy := srcy;
      r8.srcscrn := srcscrn;
      r8.width := width;
      r8.height := height;
      r8.destx := destx;
      r8.desty := desty;
      r8.destscrn := destscrn;
      r8.preserve := preserve;
      MT_Iterate(@V_CopyRectTransparent8_thr, @r8);
    end;
  end
  else
  begin
    if {$IFNDEF OPENGL}(videomode = vm32bit) and{$ENDIF} (destscrn = SCN_FG) then
      V_CopyRectTransparent32(srcx, srcy, srcscrn, width, height, destx, desty, preserve)
    else
      V_CopyRectTransparent8(srcx, srcy, srcscrn, width, height, destx, desty, destscrn, preserve);
  end;
end;

//==============================================================================
//
// V_CopyRectTransparentEx8
//
//==============================================================================
procedure V_CopyRectTransparentEx8(
  srcx: integer;
  srcy: integer;
  srcscrn: integer;
  width: integer;
  height: integer;
  destx: integer;
  desty: integer;
  destscrn: integer;
  destw: integer;
  desth: integer);
var
  swidth: integer;
  dwidth: integer;
  params: TVideoRectCopyParams;
begin
  swidth := V_GetScreenWidth(srcscrn);
  dwidth := V_GetScreenWidth(destscrn);
  if (destw <> 0) and (desth <> 0) then
  begin
    // The loops over the rows are TVideoRectCopy (Framework\Video)
    params.Source := System.PByte(screens[srcscrn]);
    params.Destination := screens[destscrn];
    params.SourcePitch := swidth;
    params.DestinationPitch := dwidth;
    params.SourceX := srcx;
    params.DestinationX := destx;
    params.DestinationY := desty;
    params.DestinationWidth := destw;
    params.DestinationHeight := desth;
    params.FracY := srcy * FRACUNIT;
    params.FracYStep := FRACUNIT * height div desth;
    params.FracXStep := FRACUNIT * width div destw;
    params.Index := 0;
    params.IndexCount := 1;
    TVideoRectCopy.StretchRowsTransparent8(params);
  end;
end;

//==============================================================================
//
// V_CopyRectTransparentEx8_MT
//
//==============================================================================
procedure V_CopyRectTransparentEx8_MT(
  idx, numidxs: integer;
  srcx: integer;
  srcy: integer;
  srcscrn: integer;
  width: integer;
  height: integer;
  destx: integer;
  desty: integer;
  destscrn: integer;
  destw: integer;
  desth: integer);
var
  swidth: integer;
  dwidth: integer;
  params: TVideoRectCopyParams;
begin
  swidth := V_GetScreenWidth(srcscrn);
  dwidth := V_GetScreenWidth(destscrn);
  if (destw <> 0) and (desth <> 0) then
  begin
    // The loops over the rows are TVideoRectCopy (Framework\Video)
    params.Source := System.PByte(screens[srcscrn]);
    params.Destination := screens[destscrn];
    params.SourcePitch := swidth;
    params.DestinationPitch := dwidth;
    params.SourceX := srcx;
    params.DestinationX := destx;
    params.DestinationY := desty;
    params.DestinationWidth := destw;
    params.DestinationHeight := desth;
    params.FracY := srcy * FRACUNIT;
    params.FracYStep := FRACUNIT * height div desth;
    params.FracXStep := FRACUNIT * width div destw;
    params.Index := idx;
    params.IndexCount := numidxs;
    TVideoRectCopy.StretchRowsTransparent8(params);
  end;
end;

//==============================================================================
//
// V_CopyRectTransparentEx32
//
//==============================================================================
procedure V_CopyRectTransparentEx32(
  srcx: integer;
  srcy: integer;
  srcscrn: integer;
  width: integer;
  height: integer;
  destx: integer;
  desty: integer;
  destw: integer;
  desth: integer);
var
  swidth: integer;
  dwidth: integer;
  params: TVideoRectCopyParams;
begin
  swidth := V_GetScreenWidth(srcscrn);
  dwidth := V_GetScreenWidth(SCN_FG);
  if (destw <> 0) and (desth <> 0) then
  begin
    // The loops over the rows are TVideoRectCopy (Framework\Video)
    params.Source := System.PByte(screens[srcscrn]);
    params.Destination := @screen32[0];
    params.SourcePitch := swidth;
    params.DestinationPitch := dwidth;
    params.SourceX := srcx;
    params.DestinationX := destx;
    params.DestinationY := desty;
    params.DestinationWidth := destw;
    params.DestinationHeight := desth;
    params.FracY := srcy * FRACUNIT;
    params.FracYStep := FRACUNIT * height div desth;
    params.FracXStep := FRACUNIT * width div destw;
    params.Index := 0;
    params.IndexCount := 1;
    TVideoRectCopy.StretchRowsTransparent32(params, System.PLongWord(@videopal[0]));
  end;
end;

//==============================================================================
//
// V_CopyRectTransparentEx32_MT
//
//==============================================================================
procedure V_CopyRectTransparentEx32_MT(
  idx, numidxs: integer;
  srcx: integer;
  srcy: integer;
  srcscrn: integer;
  width: integer;
  height: integer;
  destx: integer;
  desty: integer;
  destw: integer;
  desth: integer);
var
  swidth: integer;
  dwidth: integer;
  params: TVideoRectCopyParams;
begin
  swidth := V_GetScreenWidth(srcscrn);
  dwidth := V_GetScreenWidth(SCN_FG);
  if (destw <> 0) and (desth <> 0) then
  begin
    // The loops over the rows are TVideoRectCopy (Framework\Video)
    params.Source := System.PByte(screens[srcscrn]);
    params.Destination := @screen32[0];
    params.SourcePitch := swidth;
    params.DestinationPitch := dwidth;
    params.SourceX := srcx;
    params.DestinationX := destx;
    params.DestinationY := desty;
    params.DestinationWidth := destw;
    params.DestinationHeight := desth;
    params.FracY := srcy * FRACUNIT;
    params.FracYStep := FRACUNIT * height div desth;
    params.FracXStep := FRACUNIT * width div destw;
    params.Index := idx;
    params.IndexCount := numidxs;
    TVideoRectCopy.StretchRowsTransparent32(params, System.PLongWord(@videopal[0]));
  end;
end;

type
  th_copyrecttransparentex8_t = record
    srcx: integer;
    srcy: integer;
    srcscrn: integer;
    width: integer;
    height: integer;
    destx: integer;
    desty: integer;
    destscrn: integer;
    destw: integer;
    desth: integer;
  end;
  th_copyrecttransparentex8_p = ^th_copyrecttransparentex8_t;

  th_copyrecttransparentex32_t = record
    srcx: integer;
    srcy: integer;
    srcscrn: integer;
    width: integer;
    height: integer;
    destx: integer;
    desty: integer;
    destw: integer;
    desth: integer;
  end;
  th_copyrecttransparentex32_p = ^th_copyrecttransparentex32_t;

//==============================================================================
//
// V_CopyRectTransparentEx8_thr
//
//==============================================================================
function V_CopyRectTransparentEx8_thr(it: iterator_p): integer; stdcall;
var
  p8: th_copyrecttransparentex8_p;
begin
  p8 := it.data;
  V_CopyRectTransparentEx8_MT(
    it.idx, it.numidxs,
    p8.srcx, p8.srcy, p8.srcscrn, p8.width, p8.height, p8.destx, p8.desty, p8.destscrn, p8.destw, p8.desth);
  result := 0;
end;

//==============================================================================
//
// V_CopyRectTransparentEx32_thr
//
//==============================================================================
function V_CopyRectTransparentEx32_thr(it: iterator_p): integer; stdcall;
var
  p32: th_copyrecttransparentex32_p;
begin
  p32 := it.data;
  V_CopyRectTransparentEx32_MT(
    it.idx, it.numidxs,
    p32.srcx, p32.srcy, p32.srcscrn, p32.width, p32.height, p32.destx, p32.desty, p32.destw, p32.desth);
  result := 0;
end;

//==============================================================================
//
// V_CopyRectTransparentEx
//
//==============================================================================
procedure V_CopyRectTransparentEx(
  srcx: integer;
  srcy: integer;
  srcscrn: integer;
  width: integer;
  height: integer;
  destx: integer;
  desty: integer;
  destscrn: integer;
  destw: integer;
  desth: integer);
var
  r8: th_copyrecttransparentex8_t;
  r32: th_copyrecttransparentex32_t;
begin
  if usemultithread then
  begin
    if {$IFNDEF OPENGL}(videomode = vm32bit) and{$ENDIF} (destscrn = SCN_FG) then
    begin
      r32.srcx := srcx;
      r32.srcy := srcy;
      r32.srcscrn := srcscrn;
      r32.width := width;
      r32.height := height;
      r32.destx := destx;
      r32.desty := desty;
      r32.destw := destw;
      r32.desth := desth;
      MT_Iterate(@V_CopyRectTransparentEx32_thr, @r32);
    end
    else
    begin
      r8.srcx := srcx;
      r8.srcy := srcy;
      r8.srcscrn := srcscrn;
      r8.width := width;
      r8.height := height;
      r8.destx := destx;
      r8.desty := desty;
      r8.destscrn := destscrn;
      r8.destw := destw;
      r8.desth := desth;
      MT_Iterate(@V_CopyRectTransparentEx8_thr, @r8);
    end;
  end
  else
  begin
    if {$IFNDEF OPENGL}(videomode = vm32bit) and{$ENDIF} (destscrn = SCN_FG) then
      V_CopyRectTransparentEx32(srcx, srcy, srcscrn, width, height, destx, desty, destw, desth)
    else
      V_CopyRectTransparentEx8(srcx, srcy, srcscrn, width, height, destx, desty, destscrn, destw, desth);
  end;
end;

{$IFDEF OPENGL}

//==============================================================================
//
// V_ShadeBackground
//
//==============================================================================
procedure V_ShadeBackground(const ofs: integer = 0;
  const count: integer = -1);
var
  src: PByte;
  cnt: integer;
begin
  if count = -1 then
    cnt := V_GetScreenWidth(SCN_FG) * V_GetScreenHeight(SCN_FG)
  else
    cnt := count;
  src := PByte(@screen32[ofs]);
  TVideoScreenOps.ShadeOpaque32(System.PByte(src), cnt);
end;
{$ELSE}

//==============================================================================
//
// V_ShadeScreen
//
//==============================================================================
procedure V_ShadeScreen(const scn: integer; const ofs: integer = 0;
  const count: integer = -1);
var
  src: PByte;
  cnt: integer;
  cmap: PByteArray;
begin
  if count = -1 then
    cnt := V_GetScreenWidth(scn) * V_GetScreenHeight(scn)
  else
    cnt := count;
  if {$IFNDEF OPENGL}(videomode = vm32bit) and{$ENDIF} (scn = SCN_FG) then
  begin
    cnt := cnt * 4;
    src := PByte(@screen32[0]);
    inc(src, ofs * 4);
  end
  else
  begin
    src := PByte(screens[scn]);
    inc(src, ofs);
  end;

  if {$IFNDEF OPENGL}(videomode = vm32bit) and{$ENDIF} (scn = SCN_FG) then
  begin
    if R_BatchColorShade_AMD(src, cnt) then
      exit;

    TVideoScreenOps.Shade32(System.PByte(src), cnt);
  end
  else
  begin
    cmap := @{$IFDEF DOOM_OR_STRIFE}def_colormaps{$ELSE}colormaps{$ENDIF}[(NUMCOLORMAPS div 2) * 256];
    TVideoScreenOps.ShadeIndexed(System.PByte(src), System.PByte(cmap), cnt);
  end;
end;
{$ENDIF}

//==============================================================================
//
// V_CopyScreenTransparent8
//
//==============================================================================
procedure V_CopyScreenTransparent8(
  srcscrn: integer;
  destscrn: integer; srcoffs: integer = 0; destoffs: integer = 0; size: integer = -1);
var
  src: PByte;
  dest: PByte;
  cnt: integer;
begin
  src := PByte(NativeInt(screens[srcscrn]) +  srcoffs);
  dest := PByte(NativeInt(screens[destscrn]) + destoffs);

  if size = -1 then
    cnt := V_GetScreenWidth(srcscrn) * V_GetScreenHeight(srcscrn)
  else
    cnt := size;
  TVideoScreenOps.CopyTransparent8(System.PByte(src), System.PByte(dest), cnt);
end;

//==============================================================================
//
// V_CopyScreenTransparent32
//
//==============================================================================
procedure V_CopyScreenTransparent32(
  srcscrn: integer;
  srcoffs: integer = 0; destoffs: integer = 0; size: integer = -1);
var
  src: PByte;
  dest: PLongWord;
  cnt: integer;
begin
  src := PByte(NativeInt(screens[srcscrn]) +  srcoffs);
  dest := @screen32[destoffs];

  if size = -1 then
    cnt := V_GetScreenWidth(srcscrn) * V_GetScreenHeight(srcscrn)
  else
    cnt := size;
  TVideoScreenOps.CopyTransparent32(System.PByte(src), System.PLongWord(dest), System.PLongWord(@videopal[0]), cnt);
end;

//==============================================================================
//
// V_CopyScreenTransparent
//
//==============================================================================
procedure V_CopyScreenTransparent(
  srcscrn: integer;
  destscrn: integer; srcoffs: integer = 0; destoffs: integer = 0; size: integer = -1);
begin
  if {$IFNDEF OPENGL}(videomode = vm32bit) and{$ENDIF} (destscrn = SCN_FG) then
    V_CopyScreenTransparent32(srcscrn, srcoffs, destoffs, size)
  else
    V_CopyScreenTransparent8(srcscrn, destscrn, srcoffs, destoffs, size);
end;

//==============================================================================
//
// V_CopyRawDataToScreen
//
//==============================================================================
procedure V_CopyRawDataToScreen(scrn: integer; const lumpname: string);
var
  len: integer;
  lump: integer;
  lmpdata: PByteArray;
begin
  lump := W_GetNumForName(lumpname);
  len := W_LumpLength(lump);
  if len <> 320 * 200 then
  begin
    {$IFDEF HEXEN}
    I_DevError('V_CopyRawDataToScreen(): Lump "%s" has invalid size: %d (does not have 320x200 size).'#13#10, [lumpname, len]);
    {$ELSE}
    V_DrawPatchFullScreenTMP320x200(lumpname);
    V_CopyRect(0, 0, SCN_TMP, 320, 200, 0, 0, scrn, true);
    exit;
    {$ENDIF}
  end;

  lmpdata := W_CacheLumpNum(lump, PU_STATIC);
  memcpy(@screens[scrn][0], lmpdata, len);
  Z_ChangeTag(lmpdata, PU_CACHE);

{$IFNDEF OPENGL}
  if (videomode = vm32bit) and (scrn = SCN_FG) then
    V_CopyRect32(0, 0, SCN_FG, 320, 200, 0, 0, true);
{$ENDIF}
end;

//==============================================================================
//
// V_RemoveTransparency
//
//==============================================================================
procedure V_RemoveTransparency(const scn: integer; const ofs: integer;
  const count: integer = -1);
var
  src: PByte;
  cnt: integer;
  approx: byte;
begin
  src := PByte(screens[scn]);
  inc(src, ofs);
  if count = -1 then
    cnt := V_GetScreenWidth(scn) * V_GetScreenHeight(scn)
  else
    cnt := count;

  approx := V_FindAproxColorIndex(@curpal, $0, 1);
  TVideoScreenOps.RemoveTransparency(System.PByte(src), approx, cnt);
end;

//==============================================================================
//
// V_GetScreenWidth
//
//==============================================================================
function V_GetScreenWidth(scrn: integer): integer;
begin
  result := screendimentions[scrn].width;
end;

//==============================================================================
//
// V_GetScreenHeight
//
//==============================================================================
function V_GetScreenHeight(scrn: integer): integer;
begin
  result := screendimentions[scrn].height;
end;

//==============================================================================
//
// V_DrawPatch8
//
//==============================================================================
procedure V_DrawPatch8(x, y: integer; scrn: integer; patch: Ppatch_t; preserve: boolean);
var
  desttop: PByte;
  pw: integer;
  ph: integer;
  swidth: integer;
begin
  swidth := V_GetScreenWidth(scrn);
  if not V_NeedsPreserve(scrn, SCN_320x200, preserve) then
  begin
    y := y - patch.topoffset;
    x := x - patch.leftoffset;

    desttop := PByte(NativeInt(screens[scrn]) + y * swidth + x);

    // the walk of the posts is TVideoPatchPainter (Framework\Video)
    TVideoPatchPainter.DrawColumns8(System.PByte(patch), PVideoIntegerRow(@patch.columnofs[0]), patch.width,
      System.PByte(desttop), swidth, PVideoByteRow(v_translation), false);

  end
////////////////////////////////////////////////////
// Streching Draw, preserving original dimentions
////////////////////////////////////////////////////
  else
  begin

    y := y - patch.topoffset;
    x := x - patch.leftoffset;

    pw := V_PreserveW(x, patch.width);
    ph := V_PreserveH(y, patch.height);

    if (pw > 0) and (ph > 0) then
    begin

      x := V_PreserveX(x);
      y := V_PreserveY(y);

      desttop := PByte(NativeInt(screens[scrn]) + y * swidth + x);

      TVideoPatchPainter.DrawColumnsStretched8(System.PByte(patch), PVideoIntegerRow(@patch.columnofs[0]), pw,
        FRACUNIT * patch.width div pw, FRACUNIT * patch.height div ph, System.PByte(desttop), swidth,
        V_GetScreenHeight(scrn), PVideoByteRow(v_translation));
    end;
  end;
end;

//==============================================================================
//
// V_DrawPatch32
//
//==============================================================================
procedure V_DrawPatch32(x, y: integer; patch: Ppatch_t; preserve: boolean);
var
  pw: integer;
  ph: integer;
  swidth: integer;
begin
  swidth := V_GetScreenWidth(SCN_FG);
  x := x - patch.leftoffset;
  y := y - patch.topoffset;

  if not V_NeedsPreserve(SCN_FG, SCN_320x200, preserve) then
  begin

    // the walk of the posts is TVideoPatchPainter32 (Framework\Video)
    TVideoPatchPainter32.DrawColumns32(System.PByte(patch), PVideoIntegerRow(@patch.columnofs[0]), patch.width,
      @screen32[y * swidth + x], swidth, PVideoLongWordRow(@videopal[0]), PVideoByteRow(v_translation));

  end
////////////////////////////////////////////////////
// Streching Draw, preserving original dimentions
////////////////////////////////////////////////////
  else
  begin

    pw := V_PreserveW(x, patch.width);
    ph := V_PreserveH(y, patch.height);

    if (pw > 0) and (ph > 0) then
    begin

      x := V_PreserveX(x);
      y := V_PreserveY(y);

      TVideoPatchPainter32.DrawColumnsStretched32(System.PByte(patch), PVideoIntegerRow(@patch.columnofs[0]), pw,
        FRACUNIT * patch.width div pw, FRACUNIT * patch.height div ph, @screen32[y * swidth + x], swidth,
        {$IFDEF OPENGL}V_GetScreenHeight(SCN_FG){$ELSE}SCREENHEIGHT{$ENDIF}, PVideoLongWordRow(@videopal[0]),
        PVideoByteRow(v_translation));
    end;
  end;
end;

//==============================================================================
//
// V_DrawPatch
//
//==============================================================================
procedure V_DrawPatch(x, y: integer; scrn: integer; patch: Ppatch_t; preserve: boolean);
begin
  if {$IFNDEF OPENGL}(videomode = vm32bit) and{$ENDIF} (scrn = SCN_FG) then
    V_DrawPatch32(x, y, patch, preserve)
  else
    V_DrawPatch8(x, y, scrn, patch, preserve);
end;

//==============================================================================
//
// V_DrawPatch
//
//==============================================================================
procedure V_DrawPatch(x, y: integer; scrn: integer; const patchname: string; preserve: boolean);
var
  patch: Ppatch_t;
begin
  patch := W_CacheLumpName(patchname, PU_STATIC);
  V_DrawPatch(x, y, scrn, patch, preserve);
  Z_ChangeTag(patch, PU_CACHE);
end;

//==============================================================================
//
// V_DrawPatch
//
//==============================================================================
procedure V_DrawPatch(x, y: integer; scrn: integer; const lump: integer; preserve: boolean); overload;
var
  patch: Ppatch_t;
begin
  patch := W_CacheLumpNum(lump, PU_STATIC);
  V_DrawPatch(x, y, scrn, patch, preserve);
  Z_ChangeTag(patch, PU_CACHE);
end;

//
// V_DrawPatchTransparent
//
{$IFNDEF OPENGL}

//==============================================================================
//
// V_DrawPatchTransparent8
//
//==============================================================================
// The drawing of V_DrawPatchTransparent8 and of the _MT one: idx of numidxs is the thread (numidxs 1 draws
// every column)
procedure V_DrawPatchTransparent8_Index(idx, numidxs: integer;
  x, y: integer; scrn: integer; patch: Ppatch_t; preserve: boolean);
var
  desttop: PByte;
  pw: integer;
  ph: integer;
  swidth: integer;
  trans: Ptrans8table_t;
begin
  trans := R_GetTransparency8table;
  swidth := V_GetScreenWidth(scrn);
  if not V_NeedsPreserve(scrn, SCN_320x200, preserve) then
  begin
    y := y - patch.topoffset;
    x := x - patch.leftoffset;

    desttop := PByte(NativeInt(screens[scrn]) + y * swidth + x);

    // the walk of the posts is TVideoPatchPainter (Framework\Video)
    TVideoPatchPainter.DrawColumnsTransparent8(System.PByte(patch), PVideoIntegerRow(@patch.columnofs[0]),
      patch.width, System.PByte(desttop), swidth, PVideoByteRow(v_translation), PVideoByteRow(trans),
      idx, numidxs);

  end
////////////////////////////////////////////////////
// Streching Draw, preserving original dimentions
////////////////////////////////////////////////////
  else
  begin

    y := y - patch.topoffset;
    x := x - patch.leftoffset;

    pw := V_PreserveW(x, patch.width);
    ph := V_PreserveH(y, patch.height);

    if (pw > 0) and (ph > 0) then
    begin

      x := V_PreserveX(x);
      y := V_PreserveY(y);

      desttop := PByte(NativeInt(screens[scrn]) + y * swidth + x);

      TVideoPatchPainter.DrawColumnsStretchedTransparent8(System.PByte(patch),
        PVideoIntegerRow(@patch.columnofs[0]), pw, FRACUNIT * patch.width div pw,
        FRACUNIT * patch.height div ph, System.PByte(desttop), swidth, V_GetScreenHeight(scrn),
        PVideoByteRow(v_translation), PVideoByteRow(trans), idx, numidxs);
    end;
  end;
end;

//==============================================================================
//
// V_DrawPatchTransparent8
//
//==============================================================================
procedure V_DrawPatchTransparent8(x, y: integer; scrn: integer; patch: Ppatch_t; preserve: boolean);
begin
  V_DrawPatchTransparent8_Index(0, 1, x, y, scrn, patch, preserve);
end;

//==============================================================================
//
// V_DrawPatchTransparent8_MT
//
//==============================================================================
procedure V_DrawPatchTransparent8_MT(
  idx, numidxs: integer;
  x, y: integer; scrn: integer; patch: Ppatch_t; preserve: boolean);
begin
  V_DrawPatchTransparent8_Index(idx, numidxs, x, y, scrn, patch, preserve);
end;
{$ENDIF}

//==============================================================================
//
// V_DrawPatchTransparent32
//
//==============================================================================
// The drawing of V_DrawPatchTransparent32 and of the _MT one (software only)
procedure V_DrawPatchTransparent32_Index(idx, numidxs: integer; x, y: integer; patch: Ppatch_t; preserve: boolean);
var
  pw: integer;
  ph: integer;
  swidth: integer;
begin
  swidth := V_GetScreenWidth(SCN_FG);
  x := x - patch.leftoffset;
  y := y - patch.topoffset;

  if not V_NeedsPreserve(SCN_FG, SCN_320x200, preserve) then
  begin

    // the walk of the posts is TVideoPatchPainter32 (Framework\Video)
{$IFDEF OPENGL}
    TVideoPatchPainter32.DrawColumnsTransparentAlpha32(System.PByte(patch), PVideoIntegerRow(@patch.columnofs[0]),
      patch.width, @screen32[y * swidth + x], swidth, PVideoLongWordRow(@videopal[0]));
{$ELSE}
    TVideoPatchPainter32.DrawColumnsTransparent32(System.PByte(patch), PVideoIntegerRow(@patch.columnofs[0]),
      patch.width, @screen32[y * swidth + x], swidth, PVideoLongWordRow(@videopal[0]), idx, numidxs);
{$ENDIF}

  end
////////////////////////////////////////////////////
// Streching Draw, preserving original dimentions
////////////////////////////////////////////////////
  else
  begin

    pw := V_PreserveW(x, patch.width);
    ph := V_PreserveH(y, patch.height);

    if (pw > 0) and (ph > 0) then
    begin

      x := V_PreserveX(x);
      y := V_PreserveY(y);

{$IFDEF OPENGL}
      TVideoPatchPainter32.DrawColumnsStretchedTransparentAlpha32(System.PByte(patch),
        PVideoIntegerRow(@patch.columnofs[0]), pw, FRACUNIT * patch.width div pw,
        FRACUNIT * patch.height div ph, @screen32[y * swidth + x], swidth, V_GetScreenHeight(SCN_FG),
        PVideoLongWordRow(@videopal[0]));
{$ELSE}
      TVideoPatchPainter32.DrawColumnsStretchedTransparent32(System.PByte(patch),
        PVideoIntegerRow(@patch.columnofs[0]), pw, FRACUNIT * patch.width div pw,
        FRACUNIT * patch.height div ph, @screen32[y * swidth + x], swidth, SCREENHEIGHT,
        PVideoLongWordRow(@videopal[0]), idx, numidxs);
{$ENDIF}
    end;
  end;
end;

//==============================================================================
//
// V_DrawPatchTransparent32
//
//==============================================================================
procedure V_DrawPatchTransparent32(x, y: integer; patch: Ppatch_t; preserve: boolean);
begin
  V_DrawPatchTransparent32_Index(0, 1, x, y, patch, preserve);
end;

{$IFNDEF OPENGL}
//==============================================================================
//
// V_DrawPatchTransparent32_MT
//
//==============================================================================
procedure V_DrawPatchTransparent32_MT(
  idx, numidxs: integer;
  x, y: integer; patch: Ppatch_t; preserve: boolean);
begin
  V_DrawPatchTransparent32_Index(idx, numidxs, x, y, patch, preserve);
end;
{$ENDIF}

//==============================================================================
//
// V_DrawPatchTransparent
//
//==============================================================================
procedure V_DrawPatchTransparent(x, y: integer; scrn: integer; patch: Ppatch_t; preserve: boolean);
begin
  {$IFDEF OPENGL}
  if scrn = SCN_FG then
    V_DrawPatchTransparent32(x, y, patch, preserve)
  else // JVAL unsupported :(
    V_DrawPatch(x, y, scrn, patch, preserve);
  {$ELSE}
  if (videomode = vm32bit) and (scrn = SCN_FG) then
    V_DrawPatchTransparent32(x, y, patch, preserve)
  else
    V_DrawPatchTransparent8(x, y, scrn, patch, preserve);
  {$ENDIF}
end;

{$IFNDEF OPENGL}
type
  th_drawpathctransparent_t = record
    x, y: integer;
    scrn: integer;
    patch: Ppatch_t;
    preserve: boolean;
  end;
  th_drawpathctransparent_p = ^th_drawpathctransparent_t;

//==============================================================================
//
// V_DrawPatchTransparent8_thr
//
//==============================================================================
function V_DrawPatchTransparent8_thr(p: iterator_p): integer; stdcall;
var
  param: th_drawpathctransparent_p;
begin
  param := p.data;
  V_DrawPatchTransparent8_MT(
    p.idx, p.numidxs, param.x, param.y, param.scrn, param.patch, param.preserve);
  result := 0;
end;

//==============================================================================
//
// V_DrawPatchTransparent32_thr
//
//==============================================================================
function V_DrawPatchTransparent32_thr(p: iterator_p): integer; stdcall;
var
  param: th_drawpathctransparent_p;
begin
  param := p.data;
  V_DrawPatchTransparent32_MT(
    p.idx, p.numidxs, param.x, param.y, param.patch, param.preserve);
  result := 0;
end;

//==============================================================================
//
// V_DrawPatchTransparentMT
//
//==============================================================================
procedure V_DrawPatchTransparentMT(x, y: integer; scrn: integer; patch: Ppatch_t; preserve: boolean);
var
  parm: th_drawpathctransparent_t;
begin
  parm.x := x;
  parm.y := y;
  parm.scrn := scrn;
  parm.patch := patch;
  parm.preserve := preserve;

  if (videomode = vm32bit) and (scrn = SCN_FG) then
    MT_Iterate(
      @V_DrawPatchTransparent32_thr, @parm)
  else
    MT_Iterate(
      @V_DrawPatchTransparent8_thr, @parm)
end;
{$ENDIF}

//==============================================================================
// V_DrawPatchZoomed8
//
// V_DrawPatchZoomed
//
//==============================================================================
procedure V_DrawPatchZoomed8(x, y: integer; scrn: integer; patch: Ppatch_t; preserve: boolean; fraczoom: fixed_t);
var
  desttop: PByte;
  pw: integer;
  ph: integer;
  swidth: integer;
  sheight: integer;
begin
  if fraczoom = FRACUNIT then
  begin
    V_DrawPatch(x, y, scrn, patch, preserve);
    exit;
  end;

  y := y - patch.topoffset;
  x := x - patch.leftoffset;

  if V_NeedsPreserve(scrn, SCN_320x200, preserve) then
  begin
    pw := V_PreserveW(x, patch.width) * fraczoom div FRACUNIT;
    ph := V_PreserveH(y, patch.height) * fraczoom div FRACUNIT;
    x := V_PreserveX(x);
    y := V_PreserveY(y);
  end
  else
  begin
    pw := patch.width * fraczoom div FRACUNIT;
    ph := patch.height * fraczoom div FRACUNIT;
  end;

  if (pw > 0) and (ph > 0) then
  begin

    swidth := V_GetScreenWidth(scrn);
    sheight := V_GetScreenHeight(scrn);

    desttop := PByte(NativeInt(screens[scrn]) + y * swidth + x);

    // the walk of the posts is TVideoPatchZoomer (Framework\Video)
    TVideoPatchZoomer.DrawColumns8(System.PByte(patch), PVideoIntegerRow(@patch.columnofs[0]), pw,
      FRACUNIT * patch.width div pw, FRACUNIT * patch.height div ph, System.PByte(desttop), swidth, sheight,
      fraczoom, preserve, PVideoByteRow(v_translation));
  end;

end;

//==============================================================================
//
// V_DrawPatchZoomed32
//
//==============================================================================
procedure V_DrawPatchZoomed32(x, y: integer; patch: Ppatch_t; preserve: boolean; fraczoom: fixed_t);
var
  desttop: PLongWordArray;
  pw: integer;
  ph: integer;
  swidth: integer;
  sheight: integer;
begin
  if fraczoom = FRACUNIT then
  begin
    V_DrawPatch32(x, y, patch, preserve);
    exit;
  end;

  y := y - patch.topoffset;
  x := x - patch.leftoffset;

  if V_NeedsPreserve(SCN_FG, SCN_320x200, preserve) then
  begin
    pw := V_PreserveW(x, patch.width) * fraczoom div FRACUNIT;
    ph := V_PreserveH(y, patch.height) * fraczoom div FRACUNIT;
    x := V_PreserveX(x);
    y := V_PreserveY(y);
  end
  else
  begin
    pw := patch.width * fraczoom div FRACUNIT;
    ph := patch.height * fraczoom div FRACUNIT;
  end;

  if (pw > 0) and (ph > 0) then
  begin
    swidth := V_GetScreenWidth(SCN_FG);
    sheight := V_GetScreenHeight(SCN_FG);

    desttop := @screen32[y * swidth + x];

    // the walk of the posts is TVideoPatchZoomer (Framework\Video); the palette is its VideoZoomPalette (videopal)
    TVideoPatchZoomer.DrawColumns32(System.PByte(patch), PVideoIntegerRow(@patch.columnofs[0]), pw,
      FRACUNIT * patch.width div pw, FRACUNIT * patch.height div ph, System.PLongWord(desttop), swidth, sheight,
      fraczoom, preserve);
  end;

end;

//==============================================================================
//
// V_DrawPatchZoomed
//
//==============================================================================
procedure V_DrawPatchZoomed(x, y: integer; scrn: integer; patch: Ppatch_t; preserve: boolean; fraczoom: fixed_t);
begin
  if {$IFNDEF OPENGL}(videomode = vm32bit) and{$ENDIF} (scrn = SCN_FG) then
    V_DrawPatchZoomed32(x, y, patch, preserve, fraczoom)
  else
    V_DrawPatchZoomed8(x, y, scrn, patch, preserve, fraczoom);
end;

//==============================================================================
//
// V_DrawPatchFlipped
// Masks a column based masked pic to the screen.
// Flips horizontally, e.g. to mirror face.
//
//==============================================================================
procedure V_DrawPatchFlipped(x, y: integer; scrn: integer; patch: Ppatch_t);
var
  desttop: PByte;
  w: integer;
begin
  y := y - patch.topoffset;
  x := x - patch.leftoffset;

  desttop := PByte(NativeInt(screens[scrn]) + y * 320 + x);

  w := patch.width;

  TVideoPatchPainter.DrawColumns8(System.PByte(patch), PVideoIntegerRow(@patch.columnofs[0]), w, System.PByte(desttop), 320,
    PVideoByteRow(v_translation), true);
end;

//==============================================================================
//
// V_ScaleBuffer8
//
//==============================================================================
procedure V_ScaleBuffer8(var FData: pointer; const FWidth, FHeight: integer; const AWidth, AHeight: integer);
var
  newimage: pointer;
begin
  if (AWidth = FWidth) and (AHeight = FHeight) then
    exit;

  newimage := malloc(AWidth * AHeight);
  // The scaling loop is TVideoStretch (Framework\Video)
  TVideoStretch.ScaleNearest8(PVideoByteRow(FData), PVideoByteRow(newimage), FWidth, FHeight, AWidth, AHeight);
  memfree(FData, FWidth * FHeight);
  FData := newimage;
end;

//==============================================================================
//
// V_DrawPatchFullScreenTMP320x200
//
//==============================================================================
procedure V_DrawPatchFullScreenTMP320x200(p: Ppatch_t);
var
  oldscreen, newscreen: PByteArray;
begin
  if (p.width = 320) and (p.height = 200) then
  begin
    V_DrawPatch8(0, 0, SCN_TMP, p, false);
    exit;
  end;

  oldscreen := screens[SCN_TMP];
  screendimentions[SCN_TMP].width := p.width;
  screendimentions[SCN_TMP].height := p.height;

  newscreen := mallocz(p.width * p.height);
  screens[SCN_TMP] := newscreen;

  V_DrawPatch(0, 0, SCN_TMP, p, false);

  V_ScaleBuffer8(pointer(screens[SCN_TMP]), p.width, p.height, 320, 200);
  memcpy(oldscreen, screens[SCN_TMP], 320 * 200);

  memfree(pointer(screens[SCN_TMP]), p.width * p.height);
  screens[SCN_TMP] := oldscreen;
  screendimentions[SCN_TMP].width := 320;
  screendimentions[SCN_TMP].height := 200;
end;

//==============================================================================
//
// V_DrawPatchFullScreenTMP320x200
//
//==============================================================================
procedure V_DrawPatchFullScreenTMP320x200(const pname: string); overload;
var
  p: Ppatch_t;
begin
  p := W_CacheLumpName(pname, PU_STATIC);
  V_DrawPatchFullScreenTMP320x200(p);
  Z_ChangeTag(p, PU_CACHE);
end;

//==============================================================================
//
// V_DrawPatchFullScreenTMP320x200
//
//==============================================================================
procedure V_DrawPatchFullScreenTMP320x200(const lump: integer); overload;
var
  p: Ppatch_t;
begin
  p := W_CacheLumpNum(lump, PU_STATIC);
  V_DrawPatchFullScreenTMP320x200(p);
  Z_ChangeTag(p, PU_CACHE);
end;

//==============================================================================
//
// V_DrawPatchFullScreenTMP426x200
//
//==============================================================================
procedure V_DrawPatchFullScreenTMP426x200(p: Ppatch_t);
var
  oldscreen, newscreen: PByteArray;
begin
  if (p.width = 426) and (p.height = 200) then
  begin
    V_DrawPatch8(0, 0, SCN_TMP426, p, false);
    exit;
  end;

  oldscreen := screens[SCN_TMP426];
  screendimentions[SCN_TMP426].width := p.width;
  screendimentions[SCN_TMP426].height := p.height;

  newscreen := mallocz(p.width * p.height);
  screens[SCN_TMP426] := newscreen;

  V_DrawPatch(0, 0, SCN_TMP426, p, false);

  V_ScaleBuffer8(pointer(screens[SCN_TMP426]), p.width, p.height, 426, 200);
  memcpy(oldscreen, screens[SCN_TMP426], 426 * 200);

  memfree(pointer(screens[SCN_TMP426]), p.width * p.height);
  screens[SCN_TMP426] := oldscreen;
  screendimentions[SCN_TMP426].width := 426;
  screendimentions[SCN_TMP426].height := 200;
end;

//==============================================================================
//
// V_DrawPatchFullScreenTMP426x200
//
//==============================================================================
procedure V_DrawPatchFullScreenTMP426x200(const pname: string); overload;
var
  p: Ppatch_t;
begin
  p := W_CacheLumpName(pname, PU_STATIC);
  V_DrawPatchFullScreenTMP426x200(p);
  Z_ChangeTag(p, PU_CACHE);
end;

//==============================================================================
//
// V_DrawPatchFullScreenTMP426x200
//
//==============================================================================
procedure V_DrawPatchFullScreenTMP426x200(const lump: integer); overload;
var
  p: Ppatch_t;
begin
  p := W_CacheLumpNum(lump, PU_STATIC);
  V_DrawPatchFullScreenTMP426x200(p);
  Z_ChangeTag(p, PU_CACHE);
end;

{$IFDEF DOOM_OR_STRIFE}

//==============================================================================
//
// V_PageDrawer
//
//==============================================================================
procedure V_PageDrawer(const pagename: string);
var
  p: Ppatch_t;
  bigpatch: boolean;
  oldscreen, newscreen: PByteArray;
  oldw, oldh: integer;
begin
  if {$IFNDEF OPENGL}(videomode = vm32bit) and{$ENDIF} useexternaltextures then
    if draw_textures.Draw(pagename, screen32) then
    begin
      V_FullScreenStretch;
      exit;
    end;
  p := W_CacheLumpName(pagename, PU_STATIC);
  bigpatch := TVideoPageLayout.IsOversized(p.width, p.height);
  if bigpatch then
  begin
    oldscreen := screens[SCN_TMP];
    oldw := screendimentions[SCN_TMP].width;
    oldh := screendimentions[SCN_TMP].height;
    screendimentions[SCN_TMP].width := p.width;
    screendimentions[SCN_TMP].height := p.height;

    newscreen := mallocz(p.width * p.height);
    screens[SCN_TMP] := newscreen;

    V_DrawPatch(0, 0, SCN_TMP, p, false);

    if TVideoPageLayout.NeedsDownscale(p.width, p.height, SCREENWIDTH, SCREENHEIGHT) then
    begin
      V_ScaleBuffer8(pointer(screens[SCN_TMP]), p.width, p.height, SCREENWIDTH, SCREENHEIGHT);
      screendimentions[SCN_TMP].width := SCREENWIDTH;
      screendimentions[SCN_TMP].height := SCREENHEIGHT;
    end;

    V_CopyRect(0, 0, SCN_TMP, screendimentions[SCN_TMP].width, screendimentions[SCN_TMP].height, 0, 0, SCN_FG, true);

    memfree(pointer(screens[SCN_TMP]), screendimentions[SCN_TMP].width * screendimentions[SCN_TMP].height);
    screens[SCN_TMP] := oldscreen;
    screendimentions[SCN_TMP].width := oldw;
    screendimentions[SCN_TMP].height := oldh;
  end
  else
  begin
    V_DrawPatch(0, 0, SCN_TMP, p, false);
    V_CopyRect(0, 0, SCN_TMP, 320, 200, 0, 0, SCN_FG, true);
  end;
  {$IFDEF DOOM}
  if TVideoPageLayout.NeedsStretch(p.width, p.height) then
  {$ENDIF}
  V_FullScreenStretch;
  Z_ChangeTag(p, PU_CACHE);
end;
{$ELSE}

//==============================================================================
//
// V_PageDrawer
//
//==============================================================================
procedure V_PageDrawer(const pagename: string);
{$IFDEF OPENGL}
var
  len: integer;
  lump: integer;
  lmpdata: pointer;
{$ENDIF}
begin
{$IFDEF OPENGL}
  if draw_textures.Draw(pagename, screen32) then
  begin
    V_FullScreenStretch;
    exit;
  end;
  lump := W_GetNumForName(pagename);
  len := W_LumpLength(lump);
  if len <> 320 * 200 then
    I_DevError('V_PageDrawer(): Lump "%s" has invalid size: %d (does not have 320x200 size).'#13#10, [pagename, len]);

  lmpdata := W_CacheLumpNum(lump, PU_STATIC);
  memcpy(screens[SCN_TMP], lmpdata, len);
  Z_ChangeTag(lmpdata, PU_CACHE);

  V_CopyRect32(0, 0, SCN_TMP, 320, 200, 0, 0, true);

{$ELSE}
  if (videomode = vm32bit) and useexternaltextures then
    if draw_textures.Draw(pagename, screen32) then
    begin
      V_FullScreenStretch;
      exit;
    end;
  V_CopyRawDataToScreen(SCN_TMP, pagename);
  V_CopyRect(0, 0, SCN_TMP, 320, 200, 0, 0, SCN_FG, true);
{$ENDIF}
  V_FullScreenStretch;
end;
{$ENDIF}

//==============================================================================
//
// V_CalcPreserveTables
//
//==============================================================================
procedure V_CalcPreserveTables;
begin
  // The tables and the multipliers are TVideoPreserveTables (Framework\Video)
  if preservetables = nil then
    preservetables := TVideoPreserveTables.Create;
  preservetables.Calculate(
    {$IFDEF OPENGL}V_GetScreenWidth(SCN_FG){$ELSE}SCREENWIDTH{$ENDIF},
    {$IFDEF OPENGL}V_GetScreenHeight(SCN_FG){$ELSE}SCREENHEIGHT{$ENDIF});
  widthintmultiplier := preservetables.WidthMultiplier;
  heightintmultiplier := preservetables.HeightMultiplier;
end;

//==============================================================================
//
// V_Init
//
// V_SetPalette
//
//==============================================================================
procedure V_SetPalette(const palette: PByteArray);
begin
  // The conversion of the 256 colors is TScreenPalette (Framework\Palette)
  TScreenPalette.Convert(System.PByte(palette), System.PByte(@gammatable[usegamma]), PCardinal(@videopal[0]),
    SCREEN_PALETTE_OPAQUE);
{$IFNDEF OPENGL}
{$IFDEF HEXEN}
  memcpy(@skvideopal[0], @videopal[0], SizeOf(skvideopal));
  skvideopal[0] := 0;
{$ENDIF}
{$ENDIF}
{$IFDEF DOOM_OR_STRIFE}
  videopal[0] := videopal[0] and $FFFFFF;
{$ENDIF}
  recalctables32needed := true;
  needsbackscreen := true; // force background redraw
{$IFNDEF OPENGL}
{$IFDEF DOOM_OR_STRIFE}
  V_CalcColorMapPalette;
{$ENDIF}
{$ENDIF}
end;

{$IFNDEF OPENGL}
{$IFDEF DOOM_OR_STRIFE}

//==============================================================================
//
// V_CalcColorMapPalette
//
//==============================================================================
procedure V_CalcColorMapPalette;
var
  p: pointer;
  palette: PByteArray;
begin
  if customcolormap = nil then
  begin
    memmove(@cvideopal, @curpal, SizeOf(cvideopal));
    exit;
  end;

  p := W_CacheLumpNum(lu_palette, PU_STATIC);
  palette := PByteArray(NativeInt(p) + st_palette * 768);

  TScreenPalette.ConvertThroughColormap(System.PByte(palette), System.PByte(customcolormap.colormap),
    System.PByte(@gammatable[usegamma]), PCardinal(@cvideopal[0]), SCREEN_PALETTE_OPAQUE);

  cvideopal[0] := cvideopal[0] and $FFFFFF;
  recalctables32needed := true;

  Z_ChangeTag(p, PU_CACHE);
end;
{$ENDIF}
{$ENDIF}

//==============================================================================
//
// V_InitDefaultPalette
//
//==============================================================================
procedure V_InitDefaultPalette;
var
  playpal: PByteArray;
begin
  if default_palette <> nil then
    exit;

  default_palette := Z_Malloc(256 * SizeOf(LongWord), PU_STATIC, nil);

  playpal := V_ReadPalette(PU_STATIC);
  TScreenPalette.Unpack(System.PByte(playpal), PCardinal(default_palette));
end;

var
  vsize: integer = 0;

//==============================================================================
//
// V_Init
//
//==============================================================================
procedure V_Init;
var
  i: integer;
  base: PByteArray;
  st: integer;
  pal: PByteArray;
{$IFDEF OPENGL}
  glsize: TVideoGlDrawSize;
{$ENDIF}
begin
  SCREENWIDTH32PITCH := SCREENWIDTH * SizeOf(LongWord);
  pal := V_ReadPalette(PU_STATIC);
  V_SetPalette(pal);
  Z_ChangeTag(pal, PU_CACHE);
  V_InitDefaultPalette;
{$IFDEF OPENGL}
  glsize := TVideoScreenLayout.GlDrawSize(SCREENWIDTH, SCREENHEIGHT);
  GLDRAWWIDTH := glsize.Width;
  GLDRAWHEIGHT := glsize.Height;
  GLDRAWTEXWIDTH := glsize.TextureWidth;
  GLDRAWTEXHEIGHT := glsize.TextureHeight;
{$ENDIF}
  {$IFDEF DOOM_OR_STRIFE}
  for i := SCN_FG to SCN_ST do
  {$ELSE}
  for i := SCN_FG to SCN_TMP do
  {$ENDIF}
  begin
    screendimentions[i].width := TVideoScreenLayout.Resolve(FIXED_DIMENTIONS[i].width,
      {$IFDEF OPENGL}GLDRAWWIDTH{$ELSE}SCREENWIDTH{$ENDIF});
    screendimentions[i].height := TVideoScreenLayout.Resolve(FIXED_DIMENTIONS[i].height,
      {$IFDEF OPENGL}GLDRAWHEIGHT{$ELSE}SCREENHEIGHT{$ENDIF});
  end;
  // stick these in low dos memory on PCs
  vsize := V_ScreensSize;
  base := malloc(vsize);

  st := 0;
  {$IFDEF DOOM_OR_STRIFE}
  for i := SCN_FG to SCN_ST do
  {$ELSE}
  for i := SCN_FG to SCN_TMP do
  {$ENDIF}
  begin
    screens[i] := @base[st];
    st := st + screendimentions[i].width * screendimentions[i].height;
  end;

  V_CalcPreserveTables;

end;

//==============================================================================
//
// V_ReInit
//
//==============================================================================
procedure V_ReInit;
begin
  V_ShutDown;
  V_Init;
end;

//==============================================================================
//
// V_ShutDown
//
//==============================================================================
procedure V_ShutDown;
var
  base: pointer;
begin
  base := screens[SCN_FG];
  memfree(base, vsize);
end;

//==============================================================================
//
// V_ScreensSize
//
//==============================================================================
function V_ScreensSize(const scrn: integer = -1): integer;
var
  i: integer;
  il, ih: integer;
begin
  if scrn = -1 then
  begin
    il := SCN_FG;
    ih := {$IFDEF DOOM_OR_STRIFE}SCN_ST{$ELSE}SCN_TMP{$ENDIF};
  end
  else
  begin
    il := scrn;
    ih := scrn;
  end;

  result := 0;
  for i := il to ih do
  begin
    result := result + TVideoScreenLayout.ByteSize(FIXED_DIMENTIONS[i].width, FIXED_DIMENTIONS[i].height,
      FIXED_DIMENTIONS[i].depth, SCREENWIDTH, SCREENHEIGHT);
  end;
end;

//==============================================================================
//
// V_TileScreen8
//  Global use screen filler with patch or flat
//
//==============================================================================
function V_TileScreen8(const lumpname: string; const dstscn: integer): boolean;
var
  lump: integer;
  sz: integer;
  flat: Pointer;
  isflat: boolean;
  src: packed array[0..4095] of byte;
  ovr: TOverlayDrawer;
  tile: TVideoTilePosition;
  p: Ppatch_t;
  patchbytes: TArray<Byte>;
begin
  result := false;
  lump := W_CheckNumForName(lumpname);
  if lump >= 0 then
  begin
    sz := W_LumpLength(lump);
    flat := W_CacheLumpNum(R_GetLumpForFlat(R_FlatNumForName(lumpname)), PU_STATIC);
    isflat := V_ShrinkFlatTo64x64(flat, sz, @src);
    Z_ChangeTag(flat, PU_CACHE);
    if isflat then
    begin
      // the rows of the flat repeated on the 320x200 screen are TVideoScreenOps (Framework\Video)
      TVideoScreenOps.TileFlat64(@src[0], System.PByte(@screens[dstscn, 0]), 320, 200);
      result := true;

    end
    else
    begin
      p := W_CacheLumpNum(lump, PU_STATIC);
      // the inspector of Framework\Texture reads a copy of the lump (the old T_IsValidPatchImage)
      SetLength(patchbytes, sz);
      if sz > 0 then
        Move(p^, patchbytes[0], sz);
      if (sz > 0) and TTexturePatchInspector.IsValid(patchbytes, sz) then
        if (p.width > 0) and (p.height > 0) then
        begin
          ovr := PS_CreateOverlayDrawer;

          // the positions of the copies of the patch on the 320x200 page are TVideoTileGrid (Framework\Video)
          for tile in TVideoTileGrid.Positions(p.width, p.height, p.leftoffset, p.topoffset, 320, 200) do
            ovr.AddPatch($FF, lumpname, tile.X, tile.Y);

          ovr.DrawDrawers;
          memcpy(@screens[dstscn, 0], ovr.overlayscreen, 320 * 200);
          ovr.Free;

          result := true;
        end;
    end;
  end;
end;

//==============================================================================
//
// V_FindAproxColorIndex
//
// JVAL: Calculates the euclidian square distance of a given color from all
//       pal items and return the nearest
//
//==============================================================================
function V_FindAproxColorIndex(const pal: PLongWordArray; const c: LongWord;
  const start: integer = 0; const finish: integer = 255): integer;
begin
  result := TNearestColor.Find(PCardinal(pal), c, start, finish);
end;

//==============================================================================
//
// V_FindAproxColorIndexExcluding
//
//==============================================================================
function V_FindAproxColorIndexExcluding(const pal: PLongWordArray; const c: LongWord;
  const start: integer = 0; const finish: integer = 255; const exclude: integer = -1): integer;
begin
  result := TNearestColor.Find(PCardinal(pal), c, start, finish, exclude);
end;

{$IFDEF OPENGL}

//==============================================================================
//
// V_FullScreenStretch
//
//==============================================================================
procedure V_FullScreenStretch;
var
  x, y: integer;
  bufl, pl: PLongWordArray;
  start, stop: integer;
  pct: integer;
  w, h: integer;
begin
  if not intermissionstretch then
    exit;

  w := V_GetScreenWidth(SCN_FG);
  h := V_GetScreenHeight(SCN_FG);

  pct := TVideoStretch.WidePercentage(w, h);
  if (pct <= 0) or (pct >= 100) then
    exit;

  start := (pct div 2) * w div 100;
  stop := w - start;

  bufl := malloc(w * SizeOf(LongWord));

  for x := 0 to h - 1 do
  begin
    pl := @screen32[x * w];
    for y := 0 to start - 1 do
      bufl[y] := $FF000000;
    TVideoStretch.StretchRow32(PVideoLongWordRow(pl), PVideoLongWordRow(bufl), w, start, stop);
    for y := stop + 1 to w - 1 do
      bufl[y] := $FF000000;
    memcpy(pl, bufl, w * SizeOf(LongWord));
  end;

  memfree(pointer(bufl), w * SizeOf(LongWord));
end;

{$ELSE}

//==============================================================================
//
// V_FullScreenStretch
//
//==============================================================================
procedure V_FullScreenStretch;
var
  x: integer;
  bufb, pb: PByteArray;
  bufl, pl: PLongWordArray;
  start, stop: integer;
  pct: integer;
begin
  if not intermissionstretch then
    exit;

  pct := TVideoStretch.WidePercentage(SCREENWIDTH, SCREENHEIGHT);
  if (pct <= 0) or (pct >= 100) then
    exit;

  start := (pct div 2) * SCREENWIDTH div 100;
  stop := SCREENWIDTH - start;

  if videomode = vm32bit then
  begin
    bufl := mallocz(SCREENWIDTH * SizeOf(LongWord));

    for x := 0 to SCREENHEIGHT - 1 do
    begin
      pl := @screen32[x * SCREENWIDTH];
      TVideoStretch.StretchRow32(PVideoLongWordRow(pl), PVideoLongWordRow(bufl), SCREENWIDTH, start, stop);
      memcpy(pl, bufl, SCREENWIDTH * SizeOf(LongWord));
    end;

    memfree(pointer(bufl), SCREENWIDTH * SizeOf(LongWord));
  end
  else
  begin
    bufb := malloc(SCREENWIDTH * SizeOf(byte));

    for x := 0 to start - 1 do
      bufb[x] := aprox_black;
    for x := stop + 1 to SCREENWIDTH - 1 do
      bufb[x] := aprox_black;

    for x := 0 to SCREENHEIGHT - 1 do
    begin
      pb := @screens[SCN_FG][x * SCREENWIDTH];
      TVideoStretch.StretchRow8(PVideoByteRow(pb), PVideoByteRow(bufb), SCREENWIDTH, start, stop);
      memcpy(pb, bufb, SCREENWIDTH * SizeOf(byte));
    end;

    memfree(pointer(bufb), SCREENWIDTH * SizeOf(byte));
  end;
end;
{$ENDIF}


{$IFDEF DOOM}
{$IFDEF OPENGL}

//==============================================================================
//
// V_StatusBarStretch
//
//==============================================================================
procedure V_StatusBarStretch;
var
  x, y: integer;
  pct: integer;
  bufl, pl: PLongWordArray;
  start, stop: integer;
  l: integer;
  w, h: integer;
begin
  if not statusbarstretch then
    exit;

  if wide_stbar <> 320 then
    exit;

  w := V_GetScreenWidth(SCN_FG);
  h := V_GetScreenHeight(SCN_FG);

  pct := TVideoStretch.WidePercentage(w, h);

  if (pct <= 0) or (pct >= 100) or (screenblocks > 10) then
  //   if not (amstate = am_only) then
       exit;

  l := ((pct div 2) * 320) div 100;
  start := l * w div 320;
  stop := w - start;

  bufl := mallocz(w * SizeOf(LongWord));

  for x := V_PreserveY(ST_Y) to SCREENHEIGHT - 1 do
  begin
    pl := @screen32[x * w];
    for y := 0 to start - 1 do
      bufl[y] := $FF000000;
    TVideoStretch.StretchRow32Opaque(PVideoLongWordRow(pl), PVideoLongWordRow(bufl), w, start, stop);
    for y := stop + 1 to w - 1 do
      bufl[y] := $FF000000;
    memcpy(pl, bufl, w * SizeOf(LongWord));
  end;

  memfree(Pointer(bufl), w * SizeOf(LongWord));

  if amstate <> am_only then
  begin
    V_CopyRect(0, 0, SCN_ST2, l, ST_HEIGHT, 0, ST_Y, SCN_FG, true);
    V_CopyRect(320 - l, 0, SCN_ST2, l, ST_HEIGHT, 320 - l, ST_Y, SCN_FG, true);
  end;
end;

{$ELSE}

//==============================================================================
//
// V_StatusBarStretch
//
//==============================================================================
procedure V_StatusBarStretch;
var
  x: integer;
  pct: integer;
  bufb, pb: PByteArray;
  bufl, pl: PLongWordArray;
  start, stop: integer;
  l: integer;
begin
  if not statusbarstretch then
    exit;

  if wide_stbar <> 320 then
    exit;

  pct := TVideoStretch.WidePercentage(SCREENWIDTH, SCREENHEIGHT);

  if (pct <= 0) or (pct >= 100) or (screenblocks > 10) then
  //   if not (amstate = am_only) then
       exit;

  R_FillBackStatusbar;

  l := ((pct div 2) * 320) div 100;
  start := l * SCREENWIDTH div 320;
  stop := SCREENWIDTH - start;

  if videomode = vm32bit then
  begin
    bufl := mallocz(SCREENWIDTH * SizeOf(LongWord));

    for x := V_PreserveY(ST_Y) to SCREENHEIGHT - 1 do
    begin
      pl := @screen32[x * SCREENWIDTH];
      TVideoStretch.StretchRow32(PVideoLongWordRow(pl), PVideoLongWordRow(bufl), SCREENWIDTH, start, stop);
      memcpy(pl, bufl, SCREENWIDTH * SizeOf(LongWord));
    end;

    memfree(Pointer(bufl), SCREENWIDTH * SizeOf(LongWord));
  end
  else
  begin
    bufb := mallocz(SCREENWIDTH * SizeOf(byte));

    for x := 0 to start - 1 do
      bufb[x] := aprox_black;
    for x := stop + 1 to SCREENWIDTH - 1 do
      bufb[x] := aprox_black;

    for x := V_PreserveY(ST_Y) to SCREENHEIGHT - 1 do
    begin
      pb := @screens[SCN_FG][x * SCREENWIDTH];
      TVideoStretch.StretchRow8(PVideoByteRow(pb), PVideoByteRow(bufb), SCREENWIDTH, start, stop);
      memcpy(pb, bufb, SCREENWIDTH * SizeOf(byte));
    end;

    memfree(Pointer(bufb), SCREENWIDTH * SizeOf(byte));
  end;

  if amstate <> am_only then
  begin
    V_CopyRect(0, 0, SCN_ST2, l, ST_HEIGHT, 0, ST_Y, SCN_FG, true);
    V_CopyRect(320 - l, 0, SCN_ST2, l, ST_HEIGHT, 320 - l, ST_Y, SCN_FG, true);
  end;
end;
{$ENDIF}
{$ENDIF}

end.


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
//  System specific interface stuff.
//  Rendering main loop and setup functions,
//  utility functions (BSP, geometry, trigonometry).
//  See tables.c, too.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit r_main;

interface

uses
  DelphiDoom.Engine.Net.Intf,
  d_delphi,
  doomdef,
  d_player,
  m_fixed,
  tables,
  r_data,
  {$IFNDEF OPENGL}
  r_sprite,
  {$ENDIF}
  r_defs,
  DelphiDoom.DynLights.Intf,
  DelphiDoom.Imaging.Intf,
  DelphiDoom.Palette.Intf,
  DelphiDoom.Palette.Types,
  DelphiDoom.Renderer.Intf;

const
//
// Lighting LUT.
// Used for z-depth cuing per column/row,
//  and other lighting effects (sector ambient, flash).
//

// Lighting constants.
// Now why not 32 levels here?
  LIGHTSEGSHIFT = 4;
  LIGHTLEVELS = (256 div (1 shl LIGHTSEGSHIFT));

  MAXLIGHTSCALE = 48;
  LIGHTSCALESHIFT = 12;
  LIGHTSCALEUNIT = 1 shl LIGHTSCALESHIFT;
  HLL_MAXLIGHTSCALE = MAXLIGHTSCALE * 64;

  MAXLIGHTZ = 128;
  LIGHTZSHIFT = 20;

  HLL_MAXLIGHTZ = MAXLIGHTZ * 64; // Hi resolution light level for z depth
  HLL_LIGHTZSHIFT = 12;
  HLL_LIGHTSCALESHIFT = 3;
  HLL_ZDISTANCESHIFT = 14;

  LIGHTDISTANCESHIFT = 12;

// Colormap constants
// Number of diminishing brightness levels.
// There a 0-31, i.e. 32 LUT in the COLORMAP lump.
// Index of the special effects (INVUL inverse) map.
  INVERSECOLORMAP = 32;

  DISTMAP = 2;

{$IFDEF HEXEN}
// Fog base ( < FRACUNIT ) for FOGMAP calculation
  FOGBASE = 55000;

{$ENDIF}
var
  forcecolormaps: boolean;
{$IF DEFINED(HEXEN)}
  useclassicfuzzeffect: boolean;
{$ELSEIF DEFINED(STRIFE)}
{$ELSE}
  use32bitfuzzeffect: boolean;
{$ENDIF}
  diher8bittransparency: boolean;

{$IFDEF DOOM}

{$ENDIF}

//==============================================================================
//
// R_AddPointToBox
//
//==============================================================================

{$IFNDEF OPENGL}
{$ENDIF}

{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}

{$ENDIF}
var
  {$IFNDEF OPENGL}
  basebatchcolfunc: PProcedure;
  batchcolfunc: PProcedure;
{$IF DEFINED(HEXEN)}
{$ELSEIF DEFINED(STRIFE)}
  batchfuzzcolfunc1: PProcedure;
  batchfuzzcolfunc2: PProcedure;
{$ELSE}
  batchfuzzcolfunc: PProcedure;
{$ENDIF}
  batchlightcolfunc: PProcedure;
  batchwhitelightcolfunc: PProcedure;
  batchredlightcolfunc: PProcedure;
  batchgreenlightcolfunc: PProcedure;
  batchbluelightcolfunc: PProcedure;
  batchyellowlightcolfunc: PProcedure;
  batchtranscolfunc: PProcedure;
{$IFDEF STRIFE}
  batchfuzztranscolfunc: PProcedure;
{$ENDIF}
  batchtaveragecolfunc: PProcedure;
  batchtalphacolfunc: PProcedure;
  batchaddcolfunc: PProcedure;
  batchsubtractcolfunc: PProcedure;

  // JVAL: Multithreading sprite funcs
  basebatchcolfunc_mt: spritefunc_t;
  batchcolfunc_mt: spritefunc_t;
  batchtaveragecolfunc_mt: spritefunc_t;
  batchtalphacolfunc_mt: spritefunc_t;
  batchaddcolfunc_mt: spritefunc_t;
  batchsubtractcolfunc_mt: spritefunc_t;
  maskedcolfunc_mt: spritefunc_t;
  colfunc_mt: spritefunc_t;
  averagecolfunc_mt: spritefunc_t;
  alphacolfunc_mt: spritefunc_t;
  addcolfunc_mt: spritefunc_t;
  addcolfunc_smallstep_mt: spritefunc_t;
  subtractcolfunc_mt: spritefunc_t;

  colfunc: PProcedure;
  wallcolfunc: PProcedure;
  basewallcolfunc: PProcedure;
  tallwallcolfunc: PProcedure;
  skycolfunc: PProcedure;
  transcolfunc: PProcedure;
{$IFDEF STRIFE}
  fuzztranscolfunc: PProcedure;
{$ENDIF}
  averagecolfunc: PProcedure;
  alphacolfunc: PProcedure;
  addcolfunc: PProcedure;
  addcolfunc_smallstep: PProcedure;
  subtractcolfunc: PProcedure;
  maskedcolfunc: PProcedure;
  maskedcolfunc2: PProcedure; // For hi res textures
{$IFDEF STRIFE}
  fuzzcolfunc1: PProcedure;
  fuzzcolfunc2: PProcedure;
{$ELSE}
  fuzzcolfunc: PProcedure;
{$ENDIF}
  lightcolfunc: PProcedure;
  whitelightcolfunc: PProcedure;
  redlightcolfunc: PProcedure;
  greenlightcolfunc: PProcedure;
  bluelightcolfunc: PProcedure;
  yellowlightcolfunc: PProcedure;
  spanfunc: PProcedure;
  basespanfunc: PProcedure;
  ripplespanfunc: PProcedure;

  // JVAL: Slopes
  slopefunc: PProcedure;
  baseslopefunc: PProcedure;
  rippleslopefunc: PProcedure;

  // JVAL: Multithreading flats
  spanfuncMT: PPointerParmProcedure;
  basespanfuncMT: PPointerParmProcedure;
  ripplespanfuncMT: PPointerParmProcedure;
  slopefuncMT: PPointerParmProcedure;
  baseslopefuncMT: PPointerParmProcedure;
  rippleslopefuncMT: PPointerParmProcedure;
  {$ENDIF}

  centerxfrac: fixed_t;
  centeryfrac: fixed_t;
  centerxshift: fixed_t;

  viewx: fixed_t;
  viewy: fixed_t;
  viewz: fixed_t;

  viewangle: angle_t;

  shiftangle: byte;

  viewcos: fixed_t;
  viewsin: fixed_t;
{$IFNDEF OPENGL}
  // for precise plane drawing in hi-res
  dviewsin, dviewcos: Double;
  planerelativeaspect: Double;
{$ENDIF}
  projection: fixed_t;
  projectiony: fixed_t; // JVAL For correct aspect

  centerx: integer;
  centery: integer;
{$IFDEF HEXEN}
  skytopy: integer;
{$ENDIF}

  fixedcolormap: PByteArray;
  fixedcolormapnum: integer = 0;

// increment every time a check is made
  validcount: integer = 1;

// bumped light from gun blasts
  extralight: integer;

type
  scalelight_t = array[0..LIGHTLEVELS - 1, 0..MAXLIGHTSCALE - 1] of PByteArray;
  Pscalelight_t = ^scalelight_t;

var
{$IF NOT (DEFINED(HERETIC) OR DEFINED(HEXEN))}
  def_scalelight: scalelight_t;
{$ENDIF}
  fog_scalelight: scalelight_t; // JVAL: Mars fog sectors
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  scalelight: scalelight_t;
{$ELSE}
  scalelight: Pscalelight_t;
{$ENDIF}

var
  scalelightlevels: array[0..LIGHTLEVELS - 1, 0..HLL_MAXLIGHTSCALE - 1] of fixed_t;
  scalelightfixed: array[0..MAXLIGHTSCALE - 1] of PByteArray;

type
  zlight_t = array[0..LIGHTLEVELS - 1, 0..MAXLIGHTZ - 1] of PByteArray;
  Pzlight_t = ^zlight_t;

var
{$IF NOT (DEFINED(HERETIC) OR DEFINED(HEXEN))}
  def_zlight: zlight_t;
{$ENDIF}
  fog_zlight: zlight_t;
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  zlight: zlight_t;
{$ELSE}
  zlight: Pzlight_t;
{$ENDIF}
  renderlightscale: integer;

var
  zlightlevels: array[0..LIGHTLEVELS - 1, 0..HLL_MAXLIGHTZ - 1] of fixed_t;

var
  viewplayer: Pplayer_t;

// The viewangletox[viewangle + FINEANGLES/4] lookup
// maps the visible view angles to screen X coordinates,
// flattening the arc to a flat projection plane.
// There will be many angles mapped to the same X.
  viewangletox: array[0..FINEANGLES div 2 - 1] of integer;

// The xtoviewangleangle[] table maps a screen pixel
// to the lowest viewangle that maps back to x ranges
// from clipangle to -clipangle.
  xtoviewangle: array[0..MAXWIDTH] of angle_t;

//
// precalculated math tables
//
  clipangle: angle_t;

// UNUSED.
// The finetangentgent[angle+FINEANGLES/4] table
// holds the fixed_t tangent values for view angles,
// ranging from MININT to 0 to MAXINT.
// fixed_t    finetangent[FINEANGLES/2];

// fixed_t    finesine[5*FINEANGLES/4];
// fixed_t*    finecosine = &finesine[FINEANGLES/4]; // JVAL -> moved to tables.pas

  linecount: integer;
  loopcount: integer;

  viewangleoffset: angle_t = 0; // Net drone angle

  setsizeneeded: boolean;

// Blocky mode, has default, 0 = high, 1 = normal
  screenblocks: integer;  // has default

{$IFDEF HEXEN}
{$IFNDEF OPENGL}

{$ENDIF}

{$ENDIF}

{$IFDEF OPENGL}
var
  viewpitch: integer;
  absviewpitch: integer;
{$ENDIF}

var
  monitor_relative_aspect: Double = 1.0;
  fov: fixed_t; // JVAL: 3d Floors (Made global - moved from R_InitTextureMapping)
{$IFNDEF OPENGL}
  xfocallen: float; // JVAL: Slopes
{$ENDIF}

{$IFNDEF OPENGL}

{$ENDIF}

var
  rendervalidcount: integer = 0; // Don't bother reseting this // version 205

type
  /// <summary>
  ///   The routines of this unit as static methods with the text and the names of the old free routines (issue #247,
  ///   wave 12): same unit, no virtual call and no interface, so the compiler produces the code it produced before
  /// </summary>
  TRendererMain = class sealed
  public
    //==============================================================================
    // R_ApplyColormap
    //
    // Utility functions.
    //
    //==============================================================================
    class procedure R_ApplyColormap(const ofs, count: integer; const scrn: integer; const cmap: integer); static;
    //==============================================================================
    //
    // R_PointOnSide
    //
    //==============================================================================
    class function R_PointOnSide(const x: fixed_t; const y: fixed_t; const node: Pnode_t): boolean; static;
{$IFDEF DOOM}
    //==============================================================================
    //
    // R_PointOnSideVanilla
    //
    //==============================================================================
    class function R_PointOnSideVanilla(const x: fixed_t; const y: fixed_t; const node: Pvanillanode_t): boolean; static;
{$ENDIF}
    //==============================================================================
    //
    // R_PointOnSegSide
    //
    //==============================================================================
    class function R_PointOnSegSide(x: fixed_t; y: fixed_t; line: Pseg_t): boolean; static;
    //==============================================================================
    //
    // R_PointOnLineSide
    //
    //==============================================================================
    class function R_PointOnLineSide(x: fixed_t; y: fixed_t; line: Pline_t): boolean; static;
    //==============================================================================
    //
    // R_PointToAngle
    //
    //==============================================================================
    class function R_PointToAngle(x: fixed_t; y: fixed_t): angle_t; static;
    //==============================================================================
    //
    // R_PointToAngleEx
    //
    //==============================================================================
    class function R_PointToAngleEx(x: fixed_t; y: fixed_t): angle_t; static;
    //==============================================================================
    //
    // R_PointToAngle2
    //
    //==============================================================================
    class function R_PointToAngle2(const x1: fixed_t; const y1: fixed_t; const x2: fixed_t; const y2: fixed_t): angle_t; static;
    //==============================================================================
    //
    // R_PointToDist
    //
    //==============================================================================
    class function R_PointToDist(const x: fixed_t; const y: fixed_t): fixed_t; static;
    //==============================================================================
    //
    // R_PointInSubsectorClassic
    //
    //==============================================================================
    class function R_PointInSubsectorClassic(const x: fixed_t; const y: fixed_t): Psubsector_t; static;
    //==============================================================================
    //
    // R_PointInSubsector
    //
    //==============================================================================
    class function R_PointInSubsector(const x: fixed_t; const y: fixed_t): Psubsector_t; static;
    //==============================================================================
    // R_RenderPlayerView
    //
    // REFRESH - the actual rendering functions.
    //
    // Called by G_Drawer.
    //
    //==============================================================================
    class procedure R_RenderPlayerView(player: Pplayer_t); static;
    //==============================================================================
    //
    // R_ConfigureLightTables
    //
    //==============================================================================
    class procedure R_ConfigureLightTables(const ACalculator: ILightTableCalculator); static;
    //==============================================================================
    //
    // R_ConfigureTextureMapping
    //
    //==============================================================================
    class procedure R_ConfigureTextureMapping(const ABuilder: IRendererTextureMappingBuilder); static;
    //==============================================================================
    //
    // R_ConfigureViewTables
    //
    //==============================================================================
    class procedure R_ConfigureViewTables(const ATables: IRendererViewTables); static;
    //==============================================================================
    //
    // R_ConfigureMenuThumbnail
    //
    //==============================================================================
    class procedure R_ConfigureMenuThumbnail(const ABuilder: IImagingThumbnailBuilder); static;
    //==============================================================================
    // R_Init
    //
    // Called by startup code.
    //
    //==============================================================================
    class procedure R_Init; static;
    //==============================================================================
    //
    // R_ShutDown
    //
    //==============================================================================
    class procedure R_ShutDown; static;
{$IFNDEF OPENGL}
    //==============================================================================
    //
    // R_ConfigureDynamicLights
    //
    // The lights of the level (IdTech1\DynLights): R_Init reads the lumps, R_ShutDown forgets them.
    // The composition root calls it; without it R_Init stops with I_Error
    //
    //==============================================================================
    class procedure R_ConfigureDynamicLights(const ACache: IDynLightRenderCache); static;
{$ENDIF}
    //==============================================================================
    // R_SetViewSize
    //
    // Called by M_Responder.
    //
    //==============================================================================
    class procedure R_SetViewSize; static;
    //==============================================================================
    //
    // R_ExecuteSetViewSize
    //
    //==============================================================================
    class procedure R_ExecuteSetViewSize; static;
    //==============================================================================
    //
    // R_SetViewAngleOffset
    //
    //==============================================================================
    class procedure R_SetViewAngleOffset(const angle: angle_t); static;
    //==============================================================================
    //
    // R_FullStOn
    //
    //==============================================================================
    class function R_FullStOn: boolean; static;
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
    //==============================================================================
    //
    // R_StOff
    //
    //==============================================================================
    class function R_StOff: boolean; static;
{$ENDIF}
    //==============================================================================
    //
    // R_GetColormapLightLevel
    //
    //==============================================================================
    class function R_GetColormapLightLevel(const cmap: PByteArray): fixed_t; static;
    //==============================================================================
    //
    // R_GetColormap32
    //
    //==============================================================================
    class function R_GetColormap32(const cmap: PByteArray): PLongWordArray; static;
{$IFDEF HEXEN}
{$IFNDEF OPENGL}
    //==============================================================================
    //
    // R_SetPalette64
    //
    //==============================================================================
    class procedure R_SetPalette64; static;
{$ENDIF}
{$ENDIF}
    //==============================================================================
    //
    // R_Ticker
    //
    //==============================================================================
    class procedure R_Ticker; static;
{$IFNDEF OPENGL}
    //==============================================================================
    //
    // R_SetRenderingFunctions
    //
    //==============================================================================
    class procedure R_SetRenderingFunctions; static;
{$ENDIF}
    //==============================================================================
    //
    // R_ConfigureNetGame
    // The network, given by the composition root
    //
    //==============================================================================
    class procedure R_ConfigureNetGame(const ANetGame: IEngineNetGame); static;
  end;


implementation

uses
  DelphiDoom.Console.Numbers,
  Math,
  doomdata,
  c_cmds,
  d_net,
  mt_utils,
  mn_screenshot,
  DelphiDoom.Imaging.Types,
  DelphiDoom.Imaging.SaveThumbnail,
{$IFDEF OPENGL}
  gl_main,
  v_video,
{$ENDIF}
{$IFDEF HEXEN}
  g_game,
{$ENDIF}
  DelphiDoom.MathCore.Types,
  DelphiDoom.Renderer.Types,
{$IFNDEF OPENGL}
  DelphiDoom.Engine.Renderer.FunctionTable,
{$ENDIF}
{$IFNDEF CPUX86}
  DelphiDoom.MathCore.X87Double,
  DelphiDoom.Renderer.X87,
{$ENDIF}
  m_misc,
{$IFDEF HEXEN}
  m_rnd,
  a_action,
{$ENDIF}
  p_setup,
{$IFDEF HEXEN}
  p_user,
  DelphiDoom.Engine.World.UserRules,
  DelphiDoom.Engine.World.PlayerArtifacts,
{$ENDIF}
   // JVAL: 3d floors
  {$IFNDEF OPENGL}
  i_threads,
  i_video,
  i_system,
  {$ELSE}
  i_system,
  {$ENDIF}
{$IF NOT (DEFINED(HERETIC) OR DEFINED(HEXEN))}
  r_colormaps,
{$ENDIF}
  r_aspect,
  r_draw,
  r_bsp,
  r_earthquake,
  r_things,
  {$IFNDEF OPENGL}
  r_things_sortvissprites,
  r_dynlights,
  r_softlights,
  {$ENDIF}
  r_plane,
  r_sky,
  {$IFNDEF OPENGL}
  r_segs,
  {$ENDIF}
  r_hires,
  r_camera,
  r_precalc,
  r_ripple,
  {$IFNDEF OPENGL}
  r_cache_main,
  r_fake3d,
  r_trans8,
  r_voxels,
  r_3dfloors, // JVAL: 3d Floors
  r_slopes, // JVAL: Slopes
  {$ENDIF}
  r_lights,
  r_intrpl,
  {$IFDEF OPENGL}
  gl_render, // JVAL OPENGL
  gl_clipper,
  gl_tex,
  {$ELSE}
  r_segs2,
  r_wall8,
  r_wall32,
  r_flat8,
  r_flat32,
  r_flat32_ripple,
  r_span,
  r_span32,
  r_span32_ripple,
{$IFDEF HEXEN}
  r_span32_fog,
  r_span32_fog_ripple,
{$ENDIF}
  r_column,
  r_tallcolumn,
  r_batchcolumn,
  r_col_l,
  r_col_ms,
  r_col_sk,
  r_col_fz,
  r_draw_average,
  r_draw_alpha,
  r_col_tr,
{$IFDEF HEXEN}
  r_col_fog,
  r_col_ms_fog,
{$ENDIF}
  r_draw_additive,
  r_draw_subtractive,
  r_depthbuffer,  // JVAL: 3d Floors
  r_zbuffer, // JVAL: version 205
  v_video,
  {$ENDIF}
  r_subsectors,
  r_translations,
  v_data,
{$IF DEFINED(HERETIC)}
  sb_bar,
{$ELSEIF DEFINED(HEXEN)}
  sb_bar,
  w_sprite,
{$ELSE}
  st_stuff,
{$ENDIF}
  z_zone;

var
  // given by the composition root
  r_netgame_ref: IEngineNetGame = nil;

type
  /// <summary>
  ///   The routines that only this unit calls, as static methods with the text and the names of the old free routines
  ///   (issue #247, wave 12): same unit, no virtual call and no interface, so the compiler produces the code it produced before
  /// </summary>
  TRendererMainLocal = class sealed
  public
    class function R_NetGame: IEngineNetGame; static;
    class function R_PointOnSide32(const x: fixed_t; const y: fixed_t; const node: Pnode_t): boolean; static;
    class function R_PointOnSide64(const x: fixed_t; const y: fixed_t; const node: Pnode_t): boolean; static;
    class function R_PointOnSegSide32(x: fixed_t; y: fixed_t; line: Pseg_t): boolean; static;
    class function R_PointOnSegSide64(x: fixed_t; y: fixed_t; line: Pseg_t): boolean; static;
    class function R_PointOnLineSide32(x: fixed_t; y: fixed_t; line: Pline_t): boolean; static;
    class function R_PointOnLineSide64(x: fixed_t; y: fixed_t; line: Pline_t): boolean; static;
    class function R_PointToAngleEx1(x: fixed_t; y: fixed_t): angle_t; static;
    class procedure R_InitPointToAngle; static;
    class procedure R_InitTables; static;
    class procedure R_InitTextureMapping; static;
    class procedure R_MakeMenuThumbnail; static;
    class procedure R_InitLightTables; static;
    class procedure R_CmdZAxisShift(const parm1: string = ''); static;
{$IFNDEF OPENGL}
    class procedure R_CmdUseFake3D(const parm1: string = ''); static;
{$ENDIF}
{$IF DEFINED(HEXEN)}
    class procedure R_CmdUseClassicFuzzEffect(const parm1: string = ''); static;
{$ELSEIF DEFINED(STRIFE)}
{$ELSE}
    class procedure R_CmdUse32bitfuzzeffect(const parm1: string = ''); static;
{$ENDIF}
    class procedure R_CmdDiher8bitTransparency(const parm1: string = ''); static;
    class procedure R_CmdScreenWidth; static;
    class procedure R_CmdScreenHeight; static;
    class procedure R_CmdClearCache; static;
    class procedure R_CmdResetCache; static;
    class procedure R_SetupFrame(player: Pplayer_t); static;
{$IFNDEF OPENGL}
    class procedure R_Fake3DPrepare(player: Pplayer_t); static;
    class procedure R_MaskedStuffMT; static;
    class procedure R_DoRenderPlayerView8_MultiThread(player: Pplayer_t); static;
    class procedure R_DoRenderPlayerView32_MultiThread(player: Pplayer_t); static;
{$ENDIF}
    class procedure R_DoRenderPlayerView_SingleThread(player: Pplayer_t); static;
  end;

//==============================================================================
//
// R_ConfigureNetGame
//
//==============================================================================
class procedure TRendererMain.R_ConfigureNetGame(const ANetGame: IEngineNetGame);
begin
  r_netgame_ref := ANetGame;
end;

//==============================================================================
//
// R_NetGame
//
//==============================================================================
class function TRendererMainLocal.R_NetGame: IEngineNetGame;
begin
  if r_netgame_ref = nil then
    I_Error('R_ConfigureNetGame() was not called: the network is missing');
  result := r_netgame_ref;
end;


var
// just for profiling purposes
  framecount: integer;

//==============================================================================
//
// R_ApplyColormap
//
//==============================================================================
class procedure TRendererMain.R_ApplyColormap(const ofs, count: integer; const scrn: integer; const cmap: integer);
var
  src: PByte;
  cnt: integer;
  colormap: PByteArray;
begin
  src := PByte(screens[scrn]);
  inc(src, ofs);
  cnt := count;
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  colormap := @colormaps[cmap * 256];
{$ELSE}
  colormap := @def_colormaps[cmap * 256];
{$ENDIF}

  while cnt > 0 do
  begin
    src^ := colormap[src^];
    inc(src);
    dec(cnt);
  end;
end;

//==============================================================================
// R_PointOnSide32
//
// R_PointOnSide
// Traverse BSP (sub) tree,
//  check point against partition plane.
// Returns side 0 (front) or 1 (back).
//
//==============================================================================
class function TRendererMainLocal.R_PointOnSide32(const x: fixed_t; const y: fixed_t; const node: Pnode_t): boolean;
var
  dx: fixed_t;
  dy: fixed_t;
  left: fixed_t;
  right: fixed_t;
begin
  if node.dx = 0 then
  begin
    if x <= node.x then
      result := node.dy > 0
    else
      result := node.dy < 0;
    exit;
  end;

  if node.dy = 0 then
  begin
    if y <= node.y then
      result := node.dx < 0
    else
      result := node.dx > 0;
    exit;
  end;

  dx := x - node.x;
  dy := y - node.y;

  // Try to quickly decide by looking at sign bits.
  if ((node.dy xor node.dx xor dx xor dy) and $80000000) <> 0 then
  begin
    result := ((node.dy xor dx) and $80000000) <> 0;
    exit;
  end;

  left := IntFixedMul(node.dy, dx);
  right := FixedIntMul(dy, node.dx);

  result := right >= left;
end;

//==============================================================================
//
// R_PointOnSide64
//
//==============================================================================
class function TRendererMainLocal.R_PointOnSide64(const x: fixed_t; const y: fixed_t; const node: Pnode_t): boolean;
var
  dx64: int64;
  dy64: int64;
  left64: int64;
  right64: int64;
begin
  if node.dx = 0 then
  begin
    if x <= node.x then
      result := node.dy > 0
    else
      result := node.dy < 0;
    exit;
  end;

  if node.dy = 0 then
  begin
    if y <= node.y then
      result := node.dx < 0
    else
      result := node.dx > 0;
    exit;
  end;

  dx64 := int64(x) - int64(node.x);
  dy64 := int64(y) - int64(node.y);

  left64 := int64(node.dy div 256) * (dx64 div 256);
  right64 := (dy64 div 256) * int64(node.dx div 256);

  result := right64 >= left64;
end;

//==============================================================================
//
// R_PointOnSide
//
//==============================================================================
class function TRendererMain.R_PointOnSide(const x: fixed_t; const y: fixed_t; const node: Pnode_t): boolean;
begin
  if largemap then
    result := TRendererMainLocal.R_PointOnSide64(x, y, node)
  else
    result := TRendererMainLocal.R_PointOnSide32(x, y, node);
{$IFDEF DOOM}
end;

//==============================================================================
//
// R_PointOnSideVanilla
//
//==============================================================================
class function TRendererMain.R_PointOnSideVanilla(const x: fixed_t; const y: fixed_t; const node: Pvanillanode_t): boolean;
var
  dx: fixed_t;
  dy: fixed_t;
  left: fixed_t;
  right: fixed_t;
begin
  if node.dx = 0 then
  begin
    if x <= node.x then
      result := node.dy > 0
    else
      result := node.dy < 0;
    exit;
  end;

  if node.dy = 0 then
  begin
    if y <= node.y then
      result := node.dx < 0
    else
      result := node.dx > 0;
    exit;
  end;

  dx := x - node.x;
  dy := y - node.y;

  // Try to quickly decide by looking at sign bits.
  if ((node.dy xor node.dx xor dx xor dy) and $80000000) <> 0 then
  begin
    result := ((node.dy xor dx) and $80000000) <> 0;
    exit;
  end;

  left := IntFixedMul(node.dy, dx);
  right := FixedIntMul(dy, node.dx);

  result := right >= left;
{$ENDIF}
end;

//==============================================================================
//
// R_PointOnSegSide32
//
//==============================================================================
class function TRendererMainLocal.R_PointOnSegSide32(x: fixed_t; y: fixed_t; line: Pseg_t): boolean;
var
  lx: fixed_t;
  ly: fixed_t;
  ldx: fixed_t;
  ldy: fixed_t;
  dx: fixed_t;
  dy: fixed_t;
  left: fixed_t;
  right: fixed_t;
begin
  lx := line.v1.x;
  ly := line.v1.y;

  ldx := line.v2.x - lx;
  ldy := line.v2.y - ly;

  if ldx = 0 then
  begin
    if x <= lx then
      result := ldy > 0
    else
      result := ldy < 0;
    exit;
  end;

  if ldy = 0 then
  begin
    if y <= ly then
      result := ldx < 0
    else
      result := ldx > 0;
    exit;
  end;

  dx := x - lx;
  dy := y - ly;

  // Try to quickly decide by looking at sign bits.
  if ((ldy xor ldx xor dx xor dy) and $80000000) <> 0 then
  begin
    result := ((ldy xor dx) and $80000000) <> 0;
    exit;
  end;

  left := IntFixedMul(ldy, dx);
  right := FixedIntMul(dy, ldx);

  result := left <= right;
end;

//==============================================================================
//
// R_PointOnSegSide64
//
//==============================================================================
class function TRendererMainLocal.R_PointOnSegSide64(x: fixed_t; y: fixed_t; line: Pseg_t): boolean;
var
  lx: fixed_t;
  ly: fixed_t;
  ldx: fixed_t;
  ldy: fixed_t;
  dx64: int64;
  dy64: int64;
  left64: int64;
  right64: int64;
begin
  lx := line.v1.x;
  ly := line.v1.y;

  ldx := line.v2.x - lx;
  ldy := line.v2.y - ly;

  if ldx = 0 then
  begin
    if x <= lx then
      result := ldy > 0
    else
      result := ldy < 0;
    exit;
  end;

  if ldy = 0 then
  begin
    if y <= ly then
      result := ldx < 0
    else
      result := ldx > 0;
    exit;
  end;

  dx64 := int64(x) - int64(lx);
  dy64 := int64(y) - int64(ly);

  left64 := int64(ldy div 256) * (dx64 div 256);
  right64 := (dy64 div 256) * int64(ldx div 256);

  result := left64 <= right64;
end;

//==============================================================================
//
// R_PointOnSegSide
//
//==============================================================================
class function TRendererMain.R_PointOnSegSide(x: fixed_t; y: fixed_t; line: Pseg_t): boolean;
begin
  if largemap then
    result := TRendererMainLocal.R_PointOnSegSide64(x, y, line)
  else
    result := TRendererMainLocal.R_PointOnSegSide32(x, y, line);
end;

//==============================================================================
//
// R_PointOnLineSide32
//
//==============================================================================
class function TRendererMainLocal.R_PointOnLineSide32(x: fixed_t; y: fixed_t; line: Pline_t): boolean;
var
  lx: fixed_t;
  ly: fixed_t;
  ldx: fixed_t;
  ldy: fixed_t;
  dx: fixed_t;
  dy: fixed_t;
  left: fixed_t;
  right: fixed_t;
begin
  lx := line.v1.x;
  ly := line.v1.y;

  ldx := line.v2.x - lx;
  ldy := line.v2.y - ly;

  if ldx = 0 then
  begin
    if x <= lx then
      result := ldy > 0
    else
      result := ldy < 0;
    exit;
  end;

  if ldy = 0 then
  begin
    if y <= ly then
      result := ldx < 0
    else
      result := ldx > 0;
    exit;
  end;

  dx := x - lx;
  dy := y - ly;

  left := IntFixedMul(ldy, dx);
  right := FixedIntMul(dy, ldx);

  result := left <= right;
end;

//==============================================================================
//
// R_PointOnLineSide64
//
//==============================================================================
class function TRendererMainLocal.R_PointOnLineSide64(x: fixed_t; y: fixed_t; line: Pline_t): boolean;
var
  lx: fixed_t;
  ly: fixed_t;
  ldx: fixed_t;
  ldy: fixed_t;
  dx64: int64;
  dy64: int64;
  left64: int64;
  right64: int64;
begin
  lx := line.v1.x;
  ly := line.v1.y;

  ldx := line.v2.x - lx;
  ldy := line.v2.y - ly;

  if ldx = 0 then
  begin
    if x <= lx then
      result := ldy > 0
    else
      result := ldy < 0;
    exit;
  end;

  if ldy = 0 then
  begin
    if y <= ly then
      result := ldx < 0
    else
      result := ldx > 0;
    exit;
  end;

  dx64 := int64(x) - int64(lx);
  dy64 := int64(y) - int64(ly);

  left64 := int64(ldy div 256) * (dx64 div 256);
  right64 := (dy64 div 256) * int64(ldx div 256);

  result := left64 <= right64;
end;

//==============================================================================
//
// R_PointOnLineSide
//
//==============================================================================
class function TRendererMain.R_PointOnLineSide(x: fixed_t; y: fixed_t; line: Pline_t): boolean;
begin
  if largemap then
    result := TRendererMainLocal.R_PointOnLineSide64(x, y, line)
  else
    result := TRendererMainLocal.R_PointOnLineSide32(x, y, line)
end;

//==============================================================================
//
// R_PointToAngle
// To get a global angle from cartesian coordinates,
//  the coordinates are flipped until they are in
//  the first octant of the coordinate system, then
//  the y (<=x) is scaled and divided by x to get a
//  tangent (slope) value which is looked up in the
//  tantoangle[] table.
//
// JVAL  -> Calculates: result := round(683565275 * (arctan2(y, x)));
//
//==============================================================================
class function TRendererMain.R_PointToAngle(x: fixed_t; y: fixed_t): angle_t;
begin
  x := x - viewx;
  y := y - viewy;

  if (x = 0) and (y = 0) then
  begin
    result := 0;
    exit;
  end;

  if x >= 0 then
  begin
    // x >=0
    if y >= 0 then
    begin
      // y>= 0
      if x > y then
      begin
        // octant 0
        result := tantoangle[SlopeDiv(y, x)];
        exit;
      end
      else
      begin
        // octant 1
        result := ANG90 - 1 - tantoangle[SlopeDiv(x, y)];
        exit;
      end;
    end
    else
    begin
      // y<0
      y := -y;
      if x > y then
      begin
        // octant 8
        result := -tantoangle[SlopeDiv(y, x)];
        exit;
      end
      else
      begin
        // octant 7
        result := ANG270 + tantoangle[SlopeDiv(x, y)];
        exit;
      end;
    end;
  end
  else
  begin
    // x<0
    x := -x;
    if y >= 0 then
    begin
      // y>= 0
      if x > y then
      begin
        // octant 3
        result := ANG180 - 1 - tantoangle[SlopeDiv(y, x)];
        exit;
      end
      else
      begin
        // octant 2
        result := ANG90 + tantoangle[SlopeDiv(x, y)];
        exit;
      end;
    end
    else
    begin
      // y<0
      y := -y;
      if x > y then
      begin
        // octant 4
        result := ANG180 + tantoangle[SlopeDiv(y, x)];
        exit;
      end
      else
      begin
        // octant 5
        result := ANG270 - 1 - tantoangle[SlopeDiv(x, y)];
        exit;
      end;
    end;
  end;

  result := 0;
end;

//==============================================================================
//
// R_PointToAngleEx1
//
//==============================================================================
class function TRendererMainLocal.R_PointToAngleEx1(x: fixed_t; y: fixed_t): angle_t;
begin
  if (x = 0) and (y = 0) then
  begin
    result := 0;
    exit;
  end;

  if x >= 0 then
  begin
    // x >=0
    if y >= 0 then
    begin
      // y>= 0
      if x > y then
      begin
        // octant 0
        result := tantoangle_ex[SlopeDivEx(y, x)];
        exit;
      end
      else
      begin
        // octant 1
        result := ANG90 - 1 - tantoangle_ex[SlopeDivEx(x, y)];
        exit;
      end;
    end
    else
    begin
      // y<0
      y := -y;
      if x > y then
      begin
        // octant 8
        result := -tantoangle_ex[SlopeDivEx(y, x)];
        exit;
      end
      else
      begin
        // octant 7
        result := ANG270 + tantoangle_ex[SlopeDivEx(x, y)];
        exit;
      end;
    end;
  end
  else
  begin
    // x<0
    x := -x;
    if y >= 0 then
    begin
      // y>= 0
      if x > y then
      begin
        // octant 3
        result := ANG180 - 1 - tantoangle_ex[SlopeDivEx(y, x)];
        exit;
      end
      else
      begin
        // octant 2
        result := ANG90 + tantoangle_ex[SlopeDivEx(x, y)];
        exit;
      end;
    end
    else
    begin
      // y<0
      y := -y;
      if x > y then
      begin
        // octant 4
        result := ANG180 + tantoangle_ex[SlopeDivEx(y, x)];
        exit;
      end
      else
      begin
        // octant 5
        result := ANG270 - 1 - tantoangle_ex[SlopeDivEx(x, y)];
        exit;
      end;
    end;
  end;

  result := 0;
end;

var
  pta_x, pta_y: fixed_t;
  pta_ret: angle_t;

//==============================================================================
//
// R_PointToAngleEx
//
//==============================================================================
class function TRendererMain.R_PointToAngleEx(x: fixed_t; y: fixed_t): angle_t;
begin
  x := x - viewx;
  y := y - viewy;

  if x = pta_x then
    if y = pta_y then
    begin
      Result := pta_ret;
      Exit;
    end;

  result := TRendererMainLocal.R_PointToAngleEx1(x, y);
  pta_x := x;
  pta_y := y;
  pta_ret := Result;
end;

//==============================================================================
//
// R_PointToAngle2
//
//==============================================================================
class function TRendererMain.R_PointToAngle2(const x1: fixed_t; const y1: fixed_t; const x2: fixed_t; const y2: fixed_t): angle_t;
begin
  result := R_PointToAngle(x2 - x1 + viewx, y2 - y1 + viewy);
end;

//==============================================================================
//
// R_PointToDist
//
//==============================================================================
class function TRendererMain.R_PointToDist(const x: fixed_t; const y: fixed_t): fixed_t;
var
  angle: integer;
  dx: fixed_t;
  dy: fixed_t;
  temp: fixed_t;
begin
  dx := abs(x - viewx);
  dy := abs(y - viewy);
  if dx = 0 then
  begin
    result := dy;
    exit;
  end;
  if dy = 0 then
  begin
    result := dx;
    exit;
  end;

  if dy > dx then
  begin
    temp := dx;
    dx := dy;
    dy := temp;
  end;

  {$IFDEF FPC}
  angle := _SHRW(tantoangle[FixedDiv(dy, dx) shr DBITS], ANGLETOFINESHIFT);
  {$ELSE}
  angle := tantoangle[FixedDiv(dy, dx) shr DBITS] shr ANGLETOFINESHIFT;
  {$ENDIF}

  result := FixedDiv(dx, finecosine[angle]);
end;

//==============================================================================
//
// R_InitPointToAngle
//
//==============================================================================
class procedure TRendererMainLocal.R_InitPointToAngle;
{var
  i: integer;
  t: angle_t;
  f: extended;}
begin
//
// slope (tangent) to angle lookup
//
{  for i := 0 to SLOPERANGE do
  begin
    f := arctan(i / SLOPERANGE) / (D_PI * 2);
    t := round(LongWord($ffffffff) * f);
    tantoangle[i] := t;
  end;}
end;

//==============================================================================
//
// R_InitTables
//
//==============================================================================
class procedure TRendererMainLocal.R_InitTables;
// JVAL: Caclulate tables constants
{var
  i: integer;
  a: extended;
  fv: extended;
  t: integer;}
begin              {
// viewangle tangent table
  for i := 0 to FINEANGLES div 2 - 1 do
  begin
    a := (i - FINEANGLES / 4 + 0.5) * D_PI * 2 / FINEANGLES;
    fv := FRACUNIT * tan(a);
    t := round(fv);
    finetangent[i] := t;
  end;

  // finesine table
  for i := 0 to 5 * FINEANGLES div 4 - 1 do
  begin
    // OPTIMIZE: mirror...
    a := (i + 0.5) * D_PI * 2 / FINEANGLES;
    t := round(FRACUNIT * sin(a));
    finesine[i] := t;
  end;              }

  finecosine := Pfixed_tArray(@finesine[FINEANGLES div 4]);
  fixedcosine := Pfixed_tArray(@fixedsine[FIXEDANGLES div 4]);
end;

var
  oldfocallength: fixed_t = -1;
  texture_mapping: IRendererTextureMappingBuilder = nil;
  view_tables: IRendererViewTables = nil;

//==============================================================================
//
// R_ConfigureViewTables
// The tables of the size of the view of IdTech1\Renderer, given by the composition root
//
//==============================================================================
class procedure TRendererMain.R_ConfigureViewTables(const ATables: IRendererViewTables);
begin
  view_tables := ATables;
end;

//==============================================================================
//
// R_ConfigureTextureMapping
// The builder of the tables of the view angles of IdTech1\Renderer, given by the composition root
//
//==============================================================================
class procedure TRendererMain.R_ConfigureTextureMapping(const ABuilder: IRendererTextureMappingBuilder);
begin
  texture_mapping := ABuilder;
end;

//==============================================================================
//
// R_InitTextureMapping
//
//==============================================================================
class procedure TRendererMainLocal.R_InitTextureMapping;
var
  i: integer;
  x: integer;
  focallength: fixed_t;
  tangents: TArray<Integer>;
  tables: TRendererTextureMapping;
begin
  // Use tangent table to generate viewangletox:
  //  viewangletox will give the next greatest x
  //  after the view angle.
  //
  // Calc focallength

// JVAL: Widescreen support
  if monitor_relative_aspect = 1.0 then
    fov := ANG90 shr ANGLETOFINESHIFT
  else
{$IFDEF CPUX86}
    fov := round(arctan(monitor_relative_aspect) * FINEANGLES / D_PI);
{$ELSE}
    // issue #40: the arc tangent, the product and the quotient have the 64 bits of mantissa of the 32 bit FPU
    fov := TRendererX87.FieldOfView(monitor_relative_aspect, FINEANGLES);
{$ENDIF}
  focallength := FixedDiv(centerxfrac, finetangent[FINEANGLES div 4 + fov div 2]);

  if focallength = oldfocallength then
    exit;
  oldfocallength := focallength;

  if texture_mapping = nil then
    I_Error('R_InitTextureMapping(): R_ConfigureTextureMapping() was not called');

  SetLength(tangents, FINEANGLES div 2);
  for i := 0 to FINEANGLES div 2 - 1 do
    tangents[i] := finetangent[i];

  // The tables are built by TRendererTextureMappingBuilder; here they are copied to the
  //  arrays that the renderer reads.
  try
    tables := texture_mapping.Build(focallength, centerxfrac, viewwidth, tangents);
  except
    on E: ERendererException do
      I_Error('%s', [E.Message]);
  end;

  for i := 0 to FINEANGLES div 2 - 1 do
    viewangletox[i] := tables.ViewAngleToX[i];
  for x := 0 to viewwidth do
    xtoviewangle[x] := tables.XToViewAngle[x];
  clipangle := tables.ClipAngle;
end;

var
  light_tables: ILightTableCalculator = nil;

//==============================================================================
//
// R_ConfigureLightTables
// The calculator of the light tables of Framework\Palette, given by the composition root
//
//==============================================================================
class procedure TRendererMain.R_ConfigureLightTables(const ACalculator: ILightTableCalculator);
begin
  light_tables := ACalculator;
end;

var
  menu_thumbnails: IImagingThumbnailBuilder = nil;

//==============================================================================
//
// R_ConfigureMenuThumbnail
// The builder of the thumbnails of the saved games of Framework\Imaging, given by
// the composition root
//
//==============================================================================
class procedure TRendererMain.R_ConfigureMenuThumbnail(const ABuilder: IImagingThumbnailBuilder);
begin
  menu_thumbnails := ABuilder;
end;

//==============================================================================
//
// R_MakeMenuThumbnail
// The thumbnail of the view that the menu shows and the savegame keeps
// (it was MN_ScreenShotFromBlitBuffer of mn_screenshot.pas)
//
//==============================================================================
class procedure TRendererMainLocal.R_MakeMenuThumbnail;
var
  settings: TImagingThumbnailSettings;
  buf: TArray<Byte>;
  palette: TImagingPixels;
begin
  if menu_thumbnails = nil then
    I_Error('R_MakeMenuThumbnail(): the thumbnails are not configured (ComposeEngine was not called)');

  {$IFNDEF OPENGL}
  I_BlitBuffer;
  {$ENDIF}
  SetLength(buf, SCREENWIDTH * SCREENHEIGHT * 4);
  I_ReadScreen32(Pointer(buf));

  settings.ScreenWidth := SCREENWIDTH;
  settings.ScreenHeight := SCREENHEIGHT;
  settings.ViewX := viewwindowx;
  settings.ViewY := viewwindowy;
  settings.ViewWidth := viewwidth;
  settings.ViewHeight := viewheight;
  settings.Width := MN_SCREENSHOTWIDTH;
  settings.Height := MN_SCREENSHOTHEIGHT;
  settings.BottomUp := {$IFDEF OPENGL}True{$ELSE}False{$ENDIF};

  SetLength(palette, IMAGING_PALETTE_SIZE);
  Move(videopal, palette[0], SizeOf(videopal));

  TImagingSaveThumbnailFormat.Fill(mn_screenshotbuffer,
    menu_thumbnails.Build(settings, Pointer(buf), palette));
  mn_makescreenshot := false;
end;

//==============================================================================
//
// R_InitLightTables
// Only inits the zlight table,
//  because the scalelight table changes with view size.
//
//==============================================================================

class procedure TRendererMainLocal.R_InitLightTables;
var
  i: integer;
  j: integer;
  level: integer;
  levelhi: integer;
  config: TLightTableConfig;
  zlightindex: TArray<Integer>;
  zlighthires: TArray<Integer>;
begin
  if light_tables = nil then
    I_Error('R_InitLightTables(): the light tables are not configured (ComposeEngine was not called)');

  // Calculate the light levels to use
  //  for each level / distance combination.
  config := TLightTableConfig.Default;
  zlightindex := light_tables.ZLight(config);
  zlighthires := light_tables.HiResZLight(config);
  for i := 0 to LIGHTLEVELS - 1 do
  begin
    for j := 0 to MAXLIGHTZ - 1 do
    begin
      level := zlightindex[i * MAXLIGHTZ + j];
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
      zlight[i][j] := @colormaps[level * 256];
{$ELSE}
      def_zlight[i][j] := @def_colormaps[level * 256];
{$ENDIF}
      fog_zlight[i][j] := @fog_colormaps[level * 256];
    end;

    for j := 0 to HLL_MAXLIGHTZ - 1 do
    begin
      levelhi := zlighthires[i * HLL_MAXLIGHTZ + j];
      zlightlevels[i][j] := levelhi;
    end;
  end;
end;

//
// R_SetViewSize
// Do not really change anything here,
//  because it might be in the middle of a refresh.
// The change will take effect next refresh.
//
var
  setblocks: integer = -1;
  olddetail: integer = -1;

//==============================================================================
//
// R_SetViewSize
//
//==============================================================================
class procedure TRendererMain.R_SetViewSize;
begin
  if not allowlowdetails then
    if detailLevel < DL_MEDIUM then
      detailLevel := DL_MEDIUM;
  if not allowhidetails then
    if detailLevel > DL_NORMAL then
    begin
      if allowlowdetails then
        detailLevel := DL_LOWEST
      else
        detailLevel := DL_MEDIUM;
    end;

  if (setblocks <> screenblocks) or (setdetail <> detailLevel) then
  begin
    if setdetail <> detailLevel then
    begin
      recalctables32needed := true;
    end;
    setsizeneeded := true;
    setblocks := screenblocks;
    setdetail := detailLevel;
  end;
end;

{$IFNDEF OPENGL}

//==============================================================================
//
// R_SetPalette64
//
//==============================================================================
class procedure TRendererMain.R_SetPalette64;
begin
  if setdetail in [DL_LOWEST, DL_LOW, DL_MEDIUM] then
    I_SetPalette64;
end;

//==============================================================================
//
// R_SetRenderingFunctions
//
//==============================================================================
class procedure TRendererMain.R_SetRenderingFunctions;
begin
  TEngineRendererFunctionTable.Apply(setdetail);
end;
{$ENDIF}

//==============================================================================
//
// R_ExecuteSetViewSize
//
//==============================================================================
class procedure TRendererMain.R_ExecuteSetViewSize;
var
  i: integer;
  j: integer;
  level: integer;
  scalelightindex: TArray<Integer>;
  dimensions: TRendererViewDimensions;
  fullviewheight: integer;
  blockbase: integer;
  blockdivisor: integer;
{$IFNDEF OPENGL}
  slopes: TRendererSlopeTables;
  columncosines: TArray<Integer>;
  distscales: TArray<Integer>;
{$ENDIF}
  highlightscale: TArray<Integer>;
begin
  setsizeneeded := false;

  if view_tables = nil then
    I_Error('R_ExecuteSetViewSize(): R_ConfigureViewTables() was not called');

  // The status bar of each game says how high the view is: the numbers are given to
  // TRendererViewTables, that does the arithmetic
{$IFDEF OPENGL}
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  fullviewheight := trunc(SB_Y * SCREENHEIGHT / 200);
  blockbase := trunc(SB_Y * SCREENHEIGHT / 2000);
{$ELSE}
  fullviewheight := trunc(ST_Y * SCREENHEIGHT / 200);
  blockbase := trunc(ST_Y * SCREENHEIGHT / 2000);
{$ENDIF}
  blockdivisor := 1;
{$ELSE}
{$IF DEFINED(DOOM)}
  fullviewheight := V_PreserveY(ST_Y);
{$ELSEIF DEFINED(STRIFE)}
  fullviewheight := SCREENHEIGHT - V_PreserveY(ST_HEIGHT);
{$ELSE}
  fullviewheight := V_PreserveY(SB_Y);
{$ENDIF}
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  blockbase := V_PreserveY(SB_Y);
{$ELSE}
  blockbase := V_PreserveY(ST_Y);
{$ENDIF}
  blockdivisor := 10;
{$ENDIF}
  dimensions := view_tables.Dimensions(setblocks, SCREENWIDTH, SCREENHEIGHT, fullviewheight,
    blockbase, blockdivisor);
  scaledviewwidth := dimensions.ScaledViewWidth;
  viewheight := dimensions.ViewHeight;

  viewwidth := scaledviewwidth;
  centery := viewheight div 2;
  centerx := viewwidth div 2;
  {$IFNDEF OPENGL}
  xfocallen := centerx / tan(fov * ANGLE_T_TO_RAD / 2); // JVAL: Slopes
  {$ENDIF}

  centerxfrac := centerx * FRACUNIT;
  centeryfrac := centery * FRACUNIT;

// JVAL: Widescreen support
{$IFDEF CPUX86}
  monitor_relative_aspect := R_GetRelativeAspect{$IFNDEF OPENGL} * R_Fake3DAspectCorrection(viewplayer){$ENDIF};
  projection := Round(centerx / monitor_relative_aspect * FRACUNIT);
{$ELSE}
  // the same numbers as the 32 bit FPU (issue #40)
  monitor_relative_aspect := {$IFDEF OPENGL}R_GetRelativeAspect{$ELSE}TX87Double.Multiply(R_GetRelativeAspect, R_Fake3DAspectCorrection(viewplayer)){$ENDIF};
  projection := TX87Double.RoundScaledQuotient(centerx, monitor_relative_aspect, FRACUNIT);
{$ENDIF}
  projectiony := (((SCREENHEIGHT * centerx * 320) div 200) div SCREENWIDTH * FRACUNIT); // JVAL for correct aspect

  if olddetail <> setdetail then
  begin
    olddetail := setdetail;
{$IFDEF OPENGL}
    videomode := vm32bit;
{$ELSE}
    R_SetRenderingFunctions;
    R_SetPalette64;
{$ENDIF}
  end;

  TRendererDraw.R_InitBuffer(scaledviewwidth, viewheight);

  TRendererMainLocal.R_InitTextureMapping;

// psprite scales
// JVAL: Widescreen support
{$IFDEF CPUX86}
  pspritescale := Round((centerx / monitor_relative_aspect * FRACUNIT) / 160);
{$ELSE}
  pspritescale := TX87Double.RoundScaledQuotient(centerx, monitor_relative_aspect, FRACUNIT, 160);
{$ENDIF}
  pspriteyscale := Round((((SCREENHEIGHT * viewwidth) / SCREENWIDTH) * FRACUNIT) / 200);
  pspriteiscale := FixedDiv(FRACUNIT, pspritescale);

  if excludewidescreenplayersprites then
    pspritescalep := Round((centerx * FRACUNIT) / 160)
  else
{$IFDEF CPUX86}
    pspritescalep := Round((centerx / R_GetRelativeAspect * FRACUNIT) / 160);
{$ELSE}
    pspritescalep := TX87Double.RoundScaledQuotient(centerx, R_GetRelativeAspect, FRACUNIT, 160);
{$ENDIF}
  pspriteiscalep := FixedDiv(FRACUNIT, pspritescalep);

  // thing clipping
  for i := 0 to viewwidth - 1 do
    screenheightarray[i] := viewheight;

{$IFNDEF OPENGL}
  // planes: the tables are made by TRendererViewTables
  slopes := view_tables.Slopes(projectiony, centeryfrac, viewheight);
  for i := 0 to viewheight - 1 do
  begin
    yslope[i] := slopes.YSlope[i]; // JVAL for correct aspect
    slyslope[i] := slopes.LightYSlope[i]; // JVAL: 20200430 - For slope lightmap
  end;

  SetLength(columncosines, viewwidth);
  for i := 0 to viewwidth - 1 do
    columncosines[i] := fixedcosine[xtoviewangle[i] div FRACUNIT];
  distscales := view_tables.DistanceScales(columncosines);
  for i := 0 to viewwidth - 1 do
    distscale[i] := distscales[i];
{$ENDIF}

  // Calculate the light levels to use
  //  for each level / scale combination.
  scalelightindex := light_tables.ScaleLight(TLightTableConfig.Default, viewwidth, SCREENWIDTH);
  for i := 0 to LIGHTLEVELS - 1 do
  begin
    for j := 0 to MAXLIGHTSCALE - 1 do
    begin
      level := scalelightindex[i * MAXLIGHTSCALE + j];
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
      scalelight[i][j] := @colormaps[level * 256];
{$ELSE}
      def_scalelight[i][j] := @def_colormaps[level * 256];
{$ENDIF}
      fog_scalelight[i][j] := @fog_colormaps[level * 256];
    end;
  end;


  if setdetail >= DL_NORMAL then
  begin
{$IFDEF DOOM}
    highlightscale := view_tables.LightLevels(LIGHTLEVELS, HLL_MAXLIGHTSCALE, viewwidth, SCREENWIDTH, True);
{$ELSE}
    highlightscale := view_tables.LightLevels(LIGHTLEVELS, HLL_MAXLIGHTSCALE, viewwidth, SCREENWIDTH, False);
{$ENDIF}
    for i := 0 to LIGHTLEVELS - 1 do
      for j := 0 to HLL_MAXLIGHTSCALE - 1 do
        scalelightlevels[i][j] := highlightscale[i * HLL_MAXLIGHTSCALE + j];
  end;

{$IF NOT (DEFINED(HERETIC) OR DEFINED(HEXEN))}
  R_RecalcColormaps;
{$ENDIF}
end;

//==============================================================================
//
// R_CmdZAxisShift
//
//==============================================================================
class procedure TRendererMainLocal.R_CmdZAxisShift(const parm1: string = '');
var
  newz: boolean;
begin
  if parm1 = '' then
  begin
    printf('Current setting: zaxisshift = %s.'#13#10, [truefalseStrings[zaxisshift]]);
    exit;
  end;

  newz := TConsoleNumbers.EvaluateBoolean(parm1, zaxisshift);
  if newz <> zaxisshift then
  begin
    zaxisshift := newz;
    setsizeneeded := true;
  end;
  R_CmdZAxisShift;
end;

{$IFNDEF OPENGL}

//==============================================================================
//
// R_CmdUseFake3D
//
//==============================================================================
class procedure TRendererMainLocal.R_CmdUseFake3D(const parm1: string = '');
var
  newf: boolean;
begin
  if parm1 = '' then
  begin
    printf('Current setting: usefake3d = %s.'#13#10, [truefalseStrings[usefake3d]]);
    exit;
  end;

  newf := TConsoleNumbers.EvaluateBoolean(parm1, usefake3d);
  if newf <> usefake3d then
  begin
    usefake3d := newf;
    R_InitTextureMapping;
    setsizeneeded := true;
  end;
  R_CmdUseFake3D;
end;
{$ENDIF}
{$IF DEFINED(HEXEN)}

//==============================================================================
//
// R_CmdUseClassicFuzzEffect
//
//==============================================================================
class procedure TRendererMainLocal.R_CmdUseClassicFuzzEffect(const parm1: string = '');
var
  newusefz: boolean;
begin
  if parm1 = '' then
  begin
    printf('Current setting: useclassicfuzzeffect = %s.'#13#10, [truefalseStrings[useclassicfuzzeffect]]);
    exit;
  end;

  newusefz := TConsoleNumbers.EvaluateBoolean(parm1, useclassicfuzzeffect);
  if newusefz <> useclassicfuzzeffect then
  begin
    useclassicfuzzeffect := newusefz;
{$IFNDEF OPENGL}
    TRendererMain.R_SetRenderingFunctions;
{$ENDIF}
  end;
  R_CmdUseClassicFuzzEffect;
end;
{$ELSEIF DEFINED(STRIFE)}
{$ELSE}

//==============================================================================
//
// R_CmdUse32bitfuzzeffect
//
//==============================================================================
class procedure TRendererMainLocal.R_CmdUse32bitfuzzeffect(const parm1: string = '');
var
  newusefz: boolean;
begin
  if parm1 = '' then
  begin
    printf('Current setting: use32bitfuzzeffect = %s.'#13#10, [truefalseStrings[use32bitfuzzeffect]]);
    exit;
  end;

  newusefz := TConsoleNumbers.EvaluateBoolean(parm1, use32bitfuzzeffect);
  if newusefz <> use32bitfuzzeffect then
  begin
    use32bitfuzzeffect := newusefz;
{$IFNDEF OPENGL}
    TRendererMain.R_SetRenderingFunctions;
{$ENDIF}
  end;
  R_CmdUse32bitfuzzeffect;
end;
{$ENDIF}

//==============================================================================
//
// R_CmdDiher8bitTransparency
//
//==============================================================================
class procedure TRendererMainLocal.R_CmdDiher8bitTransparency(const parm1: string = '');
var
  newdih: boolean;
begin
  if parm1 = '' then
  begin
    printf('Current setting: diher8bittransparency = %s.'#13#10, [truefalseStrings[diher8bittransparency]]);
    exit;
  end;

  newdih := TConsoleNumbers.EvaluateBoolean(parm1, diher8bittransparency);
  if newdih <> diher8bittransparency then
  begin
    diher8bittransparency := newdih;
{$IFNDEF OPENGL}
    TRendererMain.R_SetRenderingFunctions;
{$ENDIF}
  end;
  R_CmdDiher8bitTransparency;
end;

//==============================================================================
//
// R_CmdScreenWidth
//
//==============================================================================
class procedure TRendererMainLocal.R_CmdScreenWidth;
begin
  {$IFDEF OPENGL}
  printf('ScreenWidth = %d.'#13#10, [SCREENWIDTH]);
  {$ELSE}
  printf('ScreenWidth = %d.'#13#10, [WINDOWWIDTH]);
  {$ENDIF}
end;

//==============================================================================
//
// R_CmdScreenHeight
//
//==============================================================================
class procedure TRendererMainLocal.R_CmdScreenHeight;
begin
  {$IFDEF OPENGL}
  printf('ScreenHeight = %d.'#13#10, [SCREENHEIGHT]);
  {$ELSE}
  printf('ScreenHeight = %d.'#13#10, [WINDOWHEIGHT]);
  {$ENDIF}
end;

//==============================================================================
//
// R_CmdClearCache
//
//==============================================================================
class procedure TRendererMainLocal.R_CmdClearCache;
begin
  {$IFDEF OPENGL}
  gld_ClearTextureMemory;
  {$ELSE}
  R_Clear32Cache;
  {$ENDIF}
  Z_FreeTags(PU_CACHE, PU_CACHE);
  printf('Texture cache clear'#13#10);
end;

//==============================================================================
//
// R_CmdResetCache
//
//==============================================================================
class procedure TRendererMainLocal.R_CmdResetCache;
begin
  {$IFNDEF OPENGL}
  R_Reset32Cache;
  {$ENDIF}
  Z_FreeTags(PU_CACHE, PU_CACHE);
  printf('Texture cache reset'#13#10);
end;

{$IFNDEF OPENGL}
var
  // given by the composition root (R_ConfigureDynamicLights)
  main_dynlights: IDynLightRenderCache = nil;

//==============================================================================
//
// R_ConfigureDynamicLights
//
//==============================================================================
class procedure TRendererMain.R_ConfigureDynamicLights(const ACache: IDynLightRenderCache);
begin
  main_dynlights := ACache;
end;
{$ENDIF}

//==============================================================================
//
// R_Init
//
//==============================================================================
class procedure TRendererMain.R_Init;
begin
{$IFNDEF OPENGL}
  printf('R_Init32Cache'#13#10);
  R_Init32Cache;
  printf('R_InitFake3D'#13#10);
  R_InitFake3D;
{$ENDIF}
  printf('R_InitAspect'#13#10);
  R_InitAspect;
  printf('R_InitData'#13#10);
  R_InitData;
{$IF NOT (DEFINED(HERETIC) OR DEFINED(HEXEN))}
  printf('R_InitCustomColormaps'#13#10);
  R_InitCustomColormaps;
{$ENDIF}
  printf('R_InitRippleEffects'#13#10);
  TRendererRipple.R_InitRippleEffects;
  printf('R_InitInterpolations'#13#10);
  TRendererInterpolation.R_InitInterpolations;
  printf('R_InitPointToAngle'#13#10);
  TRendererMainLocal.R_InitPointToAngle;
  printf('R_InitTables'#13#10);
  TRendererMainLocal.R_InitTables;
  printf('R_SetViewSize'#13#10);
  // viewwidth / viewheight / detailLevel are set by the defaults
  R_SetViewSize;
  printf('R_InitPlanes'#13#10);
  TRendererPlane.R_InitPlanes;
  printf('R_InitLightTables'#13#10);
  TRendererMainLocal.R_InitLightTables;
  printf('R_InitSkyMap'#13#10);
  R_InitSkyMap;
  printf('R_InitTranslationsTables'#13#10);
  TRendererDraw.R_InitTranslationTables;
  printf('R_InitTranslations'#13#10);
  R_InitTranslations;
{$IFNDEF OPENGL}
  printf('R_InitTransparency8Tables'#13#10);
  R_InitTransparency8Tables;
{$ENDIF}
  printf('R_InitPrecalc'#13#10);
  R_InitPrecalc;
{$IFNDEF OPENGL}
  printf('R_InitVoxels'#13#10);
  TRendererVoxels.R_InitVoxels;
  printf('R_InitWallsCache8'#13#10);
  TRendererWall8.R_InitWallsCache8;
  printf('R_InitWallsCache32'#13#10);
  TRendererWall32.R_InitWallsCache32;
  printf('R_InitFlatsCache8'#13#10);
  R_InitFlatsCache8;
  printf('R_InitFlatsCache32'#13#10);
  R_InitFlatsCache32;
  printf('R_InitDepthBuffer'#13#10); // JVAL: 3d Floors
  TRendererDepthBuffer.R_InitDepthBuffer;
  printf('R_InitZBuffer'#13#10); // JVAL: version 205
  TRendererZBuffer.R_InitZBuffer;
  printf('R_InitDynamicLights'#13#10);
  if main_dynlights = nil then
    I_Error('R_InitDynamicLights(): the dynamic lights are not configured (ComposeEngine was not called)');
  if main_dynlights.Load(gldefs_as_lightdef) then
    lightdeflumppresent := true;
{$ENDIF}

  framecount := 0;

  C_AddCmd('zaxisshift', @TRendererMainLocal.R_CmdZAxisShift);
{$IFNDEF OPENGL}
  C_AddCmd('fake3d, usefake3d', @TRendererMainLocal.R_CmdUseFake3D);
{$ENDIF}
  C_AddCmd('lowestres, lowestresolution', @R_CmdLowestRes);
  C_AddCmd('lowres, lowresolution', @R_CmdLowRes);
  C_AddCmd('mediumres, mediumresolution', @R_CmdMediumRes);
  C_AddCmd('normalres, normalresolution', @R_CmdNormalRes);
  C_AddCmd('hires, hiresolution', @R_CmdHiRes);
  C_AddCmd('ultrares, ultraresolution', @R_CmdUltraRes);
  C_AddCmd('detaillevel, displayresolution', @R_CmdDetailLevel);
  C_AddCmd('fullscreen', @R_CmdFullScreen);
  C_AddCmd('extremeflatfiltering', @R_CmdExtremeflatfiltering);
  C_AddCmd('32bittexturepaletteeffects, use32bittexturepaletteeffects', @R_Cmd32bittexturepaletteeffects);
  C_AddCmd('useexternaltextures', @R_CmdUseExternalTextures);
{$IF DEFINED(HEXEN)}
  C_AddCmd('useclassicfuzzeffect', @TRendererMainLocal.R_CmdUseClassicFuzzEffect);
{$ELSEIF DEFINED(STRIFE)}
{$ELSE}
  C_AddCmd('use32bitfuzzeffect', @TRendererMainLocal.R_CmdUse32bitfuzzeffect);
{$ENDIF}
  C_AddCmd('diher8bittransparency', @TRendererMainLocal.R_CmdDiher8bitTransparency);
  C_AddCmd('lightboostfactor', @R_CmdLightBoostFactor);
  C_AddCmd('screenwidth', @TRendererMainLocal.R_CmdScreenWidth);
  C_AddCmd('screenheight', @TRendererMainLocal.R_CmdScreenHeight);
  C_AddCmd('clearcache, cleartexturecache', @TRendererMainLocal.R_CmdClearCache);
  C_AddCmd('resetcache, resettexturecache', @TRendererMainLocal.R_CmdResetCache);
end;

//==============================================================================
//
// R_ShutDown
//
//==============================================================================
class procedure TRendererMain.R_ShutDown;
begin
  printf(#13#10 + 'R_ShutDownLightBoost');
  R_ShutDownLightBoost;
{$IFNDEF OPENGL}
  printf(#13#10 + 'R_ShutDownLightTexture');
  TRendererSoftLights.R_ShutDownLightTexture;
  printf(#13#10 + 'R_ShutDownFake3D');
  R_ShutDownFake3D;
  printf(#13#10 + 'R_ShutDown32Cache');
  R_ShutDown32Cache;
{$ENDIF}
  printf(#13#10 + 'R_ShutDownInterpolation');
  TRendererInterpolation.R_ResetInterpolationBuffer;
{$IFNDEF OPENGL}
  printf(#13#10 + 'R_FreeTransparency8Tables');
  R_FreeTransparency8Tables;
{$ENDIF}
  printf('R_ShutDownTranslations'#13#10);
  R_ShutDownTranslations;
  printf(#13#10 + 'R_ShutDownPrecalc');
  R_ShutDownPrecalc;
{$IFNDEF OPENGL}
  printf(#13#10 + 'R_ShutDownWallsCache8');
  TRendererWall8.R_ShutDownWallsCache8;
  printf(#13#10 + 'R_ShutDownWallsCache32');
  TRendererWall32.R_ShutDownWallsCache32;
  printf(#13#10 + 'R_ShutDownFlatsCache8');
  R_ShutDownFlatsCache8;
  printf(#13#10 + 'R_ShutDownFlatsCache32');
  R_ShutDownFlatsCache32;
{$ENDIF}
{$IF NOT (DEFINED(HERETIC) OR DEFINED(HEXEN))}
  printf(#13#10 + 'R_ShutDownCustomColormaps');
  R_ShutDownCustomColormaps;
{$ENDIF}
  printf(#13#10 + 'R_ShutDownSprites');
  TRendererThings.R_ShutDownSprites;
  printf(#13#10 + 'R_FreeMemory');
  R_FreeMemory;
{$IFNDEF OPENGL}
  printf(#13#10 + 'R_VoxelsDone');
  TRendererVoxels.R_VoxelsDone;
  printf(#13#10 + 'R_ShutDownDepthBuffer'); // JVAL: 3d Floors
  TRendererDepthBuffer.R_ShutDownDepthBuffer;
  printf(#13#10 + 'R_ShutDownZBuffer'); // JVAL: version 205
  TRendererZBuffer.R_ShutDownZBuffer;
  printf(#13#10 + 'R_DynamicLightsDone');
  if main_dynlights <> nil then
    main_dynlights.Clear;
  TRendererDynLights.R_FreeDynamicLightItems;
{$ENDIF}
{$IFDEF OPENGL}
  printf(#13#10 + 'R_ShutDownOpenGL');
  R_ShutDownOpenGL;
{$ENDIF}
  printf(#13#10);
end;

//==============================================================================
// R_PointInSubsectorClassic
//
// R_PointInSubsector
//
//==============================================================================
class function TRendererMain.R_PointInSubsectorClassic(const x: fixed_t; const y: fixed_t): Psubsector_t;
var
  node: Pnode_t;
  nodenum: LongWord;
begin
  // single subsector is a special case
  if numnodes = 0 then
  begin
    result := @subsectors[0];
    exit;
  end;

  nodenum := numnodes - 1;

  while nodenum and NF_SUBSECTOR_V5 = 0 do
  begin
    node := @nodes[nodenum];
    if R_PointOnSide(x, y, node) then
      nodenum := node.children[1]
    else
      nodenum := node.children[0]
  end;

  result := @subsectors[nodenum and not NF_SUBSECTOR_V5]; // JVAL: glbsp
end;

//==============================================================================
//
// R_PointInSubsector
//
//==============================================================================
class function TRendererMain.R_PointInSubsector(const x: fixed_t; const y: fixed_t): Psubsector_t;
begin
  result := TRendererSubsectors.R_PointInSubsectorPrecalc(x, y);
  if result = nil then
    result := R_PointInSubSectorClassic(x, y);
end;

{$IF NOT (DEFINED(HERETIC) OR DEFINED(HEXEN))}
var
  lastcm: integer = -2;

{$ENDIF}
//==============================================================================
//
// R_SetupFrame
//
//==============================================================================
class procedure TRendererMainLocal.R_SetupFrame(player: Pplayer_t);
var
  i: integer;
{$IFDEF HEXEN}
  intensity: integer;
{$ENDIF}
  cy: fixed_t;
{$IFNDEF OPENGL}
  dy, dy1: fixed_t;
{$ENDIF}
  sblocks: integer;
{$IF NOT (DEFINED(HERETIC) OR DEFINED(HEXEN))}
  sec: Psector_t;
  cm: integer;
{$ENDIF}
  vangle: angle_t;
begin
  viewplayer := player;

  viewx := player.mo.x;
  viewy := player.mo.y;
{$IFDEF HEXEN}

  if (localQuakeHappening[P_GetPlayerNum(player)] <> 0) and not TGameSession.Paused then
  begin
    intensity := localQuakeHappening[displayplayer];
    viewx := viewx + ((P_RandomFromSeed(TGameSession.GameTic) mod (intensity * 4)) - intensity * 2) * FRACUNIT;
    viewy := viewy + ((P_RandomFromSeed(TGameSession.GameTic + 1) mod (intensity * 4)) - intensity * 2) * FRACUNIT;
  end;

{$ENDIF}
  shiftangle := player.lookdir2;
  viewangle := player.mo.angle + shiftangle * DIR256TOANGLEUNIT + viewangleoffset;
  extralight := player.extralight;
  renderlightscale := (SCREENWIDTH * LIGHTSCALEUNIT) div 320;

  viewz := player.viewz;

  // JVAL: 20220309 - Reset R_PointToAngleEx
  pta_x := 0;
  pta_y := 0;
  pta_ret := 0;

  R_AdjustTeleportZoom(player);
  R_AdjustChaseCamera;
  TRendererEarthquake.R_AdjustGlobalEarthQuake(player);

{$IFNDEF OPENGL}
  viewsubsector := TRendererMain.R_PointInSubSector(viewx, viewy); // JVAL: 3d Floors
  hasExtraFloors := viewsubsector.sector.midsec >= 0;  // JVAL: 3d Floors
{$ENDIF}

  {$IFDEF OPENGL}
  viewpitch := 0;
  absviewpitch := 0;
  {$ENDIF}
{$IFDEF HEXEN}

  skytopy := MAXLOOKDIR - player.lookdir;
{$ENDIF}
//******************************
// JVAL Enabled z axis shift
  if zaxisshift and ((player.lookdir16 <> 0) or p_justspawned) and (viewangleoffset = 0) then
  begin
    sblocks := screenblocks;
    if sblocks > 11 then
      sblocks := 11;
    cy := Round((viewheight + ((player.lookdir16 * sblocks) / 16) * SCREENHEIGHT / 1000) / 2);   // JVAL Smooth Look Up/Down
    if centery <> cy then
    begin
      centery := cy;
      centeryfrac := centery * FRACUNIT;
      {$IFNDEF OPENGL}
      // Per frame while the player looks up or down: not through TRendererViewTables (it makes
      //  arrays), the same rows as there
      dy := -centeryfrac - FRACUNIT div 2;
      for i := 0 to viewheight - 1 do
      begin
        dy := dy + FRACUNIT;
        dy1 := abs(dy);
        yslope[i] := FixedDiv(projectiony, dy1);

        // JVAL: 20200430 - For slope lightmap
        if dy1 < 4 * FRACUNIT then
          slyslope[i] := FixedDiv(projectiony, 4 * FRACUNIT)
        else
          slyslope[i] := yslope[i];
      end;
      {$ENDIF}

    end;

{$IFDEF OPENGL}
    viewpitch := player.lookdir;
    absviewpitch := abs(viewpitch);
{$ELSE}
    if usefake3d then
      R_Set3DLookup(player);
{$ENDIF}
  end
  else
    p_justspawned := false;
//******************************

  vangle := viewangle div FRACUNIT;
  viewsin := fixedsine[vangle];
  viewcos := fixedcosine[vangle];
{$IFNDEF OPENGL}
{$IFDEF CPUX86}
  dviewsin := Sin(viewangle / $FFFFFFFF * 2 * pi);
  dviewcos := Cos(viewangle / $FFFFFFFF * 2 * pi);
// JVAL: Widescreen support
  planerelativeaspect := 320 / 200 * SCREENHEIGHT / SCREENWIDTH * monitor_relative_aspect;
{$ELSE}
  // the same numbers as the 32 bit FPU (issue #40)
  dviewsin := TRendererX87.ViewSine(viewangle);
  dviewcos := TRendererX87.ViewCosine(viewangle);
  planerelativeaspect := TRendererX87.PlaneRelativeAspect(SCREENHEIGHT, SCREENWIDTH, monitor_relative_aspect);
{$ENDIF}
{$ENDIF}

{$IF NOT (DEFINED(HERETIC) OR DEFINED(HEXEN))}
  cm := -1;
  if Psubsector_t(player.mo.subsector).sector.heightsec > -1 then
  begin
    sec := @sectors[Psubsector_t(player.mo.subsector).sector.heightsec];
    if viewz < sec.floorheight then
      cm := sec.bottommap
    else if viewz > sec.ceilingheight then
      cm := sec.topmap
    else
      cm := sec.midmap;
  end;

  if cm >= 0 then
  begin
    customcolormap := @customcolormaps[cm];
    R_RecalcColormaps;
    if cm <> lastcm then
    begin
      zlight := @customcolormap.zlight;
      scalelight := @customcolormap.scalelight;
      colormaps := customcolormap.colormap;
     {$IFNDEF OPENGL}
      V_CalcColorMapPalette;
     {$ENDIF}
      lastcm := cm;
      recalctables32needed := true;
    end;
  end
  else
  begin
    if cm <> lastcm then
    begin
      customcolormap := nil;
      zlight := @def_zlight;
      scalelight := @def_scalelight;
      colormaps := def_colormaps;
     {$IFNDEF OPENGL}
      V_CalcColorMapPalette;
     {$ENDIF}
      lastcm := cm;
      recalctables32needed := true;
    end;
  end;

{$ENDIF}
  fixedcolormapnum := player.fixedcolormap;
  if fixedcolormapnum <> 0 then
  begin
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
    fixedcolormap := PByteArray(
      NativeInt(colormaps) + fixedcolormapnum * 256);
{$ELSE}
    if customcolormap <> nil then
      fixedcolormap := PByteArray(
        NativeInt(customcolormap.colormap) + fixedcolormapnum * 256)
    else
      fixedcolormap := PByteArray(
        NativeInt(colormaps) + fixedcolormapnum * 256);
{$ENDIF}

    {$IFNDEF OPENGL}
    walllights := @scalelightfixed;
    {$ENDIF}

    for i := 0 to MAXLIGHTSCALE - 1 do
      scalelightfixed[i] := fixedcolormap;
  end
  else
  begin
    fixedcolormap := nil;
  end;

  inc(framecount);
  inc(validcount);
end;

//==============================================================================
//
// R_SetViewAngleOffset
//
//==============================================================================
class procedure TRendererMain.R_SetViewAngleOffset(const angle: angle_t);
begin
  viewangleoffset := angle;
end;

//==============================================================================
//
// R_FullStOn
//
//==============================================================================
class function TRendererMain.R_FullStOn: boolean;
begin
  result := setblocks = 11;
end;

//==============================================================================
//
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
// R_StOff
//
//==============================================================================
class function TRendererMain.R_StOff: boolean;
begin
  result := setblocks = 12;
end;

//==============================================================================
//
{$ENDIF}
// R_GetColormapLightLevel
//
//==============================================================================
class function TRendererMain.R_GetColormapLightLevel(const cmap: PByteArray): fixed_t;
var
  m: integer;
begin
  if cmap = nil then
    result := -1
  else
  begin
    // JVAL: Mars fog sectors
    m := (NativeInt(cmap) - NativeInt(colormaps));
    if (m >= 0) and (m <= NUMCOLORMAPS * 256) then
      result := FRACUNIT - (NativeInt(cmap) - NativeInt(colormaps)) div 256 * FRACUNIT div NUMCOLORMAPS
    else
      result := FRACUNIT - (NativeInt(cmap) - NativeInt(fog_colormaps)) div 256 * FRACUNIT div NUMCOLORMAPS;
  end;
end;

//==============================================================================
//
// R_GetColormap32
//
//==============================================================================
class function TRendererMain.R_GetColormap32(const cmap: PByteArray): PLongWordArray;
var
  m: integer;
begin
{$IFDEF DOOM}
  if fixedcolormapnum = INVERSECOLORMAP then
    result := @inversecolormap32
  else if cmap = nil then
{$ELSE}
  if cmap = nil then
{$ENDIF}
    result := @colormaps32[6 * 256] // FuzzLight
  else
  begin
    // JVAL: Mars fog sectors
    m := (NativeInt(cmap) - NativeInt(colormaps));
    if (m >= 0) and (m <= NUMCOLORMAPS * 256) then
      result := @colormaps32[m]
    else
    begin
      m := (NativeInt(cmap) - NativeInt(fog_colormaps));
      result := @fog_colormaps32[m];
    end;
  end;
end;

//
// R_RenderView
//

{$IFNDEF OPENGL}
var
  oldlookdir16: integer = MAXINT;

//==============================================================================
//
// R_Fake3DPrepare
//
//==============================================================================
class procedure TRendererMainLocal.R_Fake3DPrepare(player: Pplayer_t);
begin
  if oldlookdir16 = player.lookdir16 then
    Exit;

  oldlookdir16 := player.lookdir16;

  viewplayer := player;
  TRendererMain.R_ExecuteSetViewSize;
end;

var
  task_clearplanes: integer = -1;
  task_8bitlights: integer = -1;
  task_maskedstuff: integer = -1;

class procedure TRendererMainLocal.R_MaskedStuffMT;
begin
  R_SortVisSprites;
  TRendererSegs2.R_SetUpDrawSegLists;
  TRendererThings.R_PrepareMasked;
end;

//==============================================================================
//
// R_DoRenderPlayerView8_MultiThread
//
//==============================================================================
class procedure TRendererMainLocal.R_DoRenderPlayerView8_MultiThread(player: Pplayer_t);
begin
  R_Fake3DPrepare(player);
  R_SetupFrame(player);
  task_8bitlights := MT_ScheduleTask(@R_Calc8bitTables);
  MT_ExecutePendingTask(task_8bitlights);

  // Clear buffers.
  TRendererBsp.R_ClearClipSegs;
  TRendererBsp.R_ClearDrawSegs;
  TRendererPlane.R_ClearPlanes;
  R_Wait3DLookup;
  R_Fake3DAdjustPlanes(player);
  TRendererThings.R_ClearSprites;

  // Check for completed thread tasks
  TestActiveThreads;

  // check for new console commands.
  R_NetGame.Update;

  TRendererWall8.R_ClearWallsCache8;

  // The head node is the last node output.
  TRendererBsp.R_RenderBSPNode(numnodes - 1);

  // Check for completed thread tasks
  TestActiveThreads;

  TRendererThings.R_ProjectAdditionalThings;

  R_SortVisSpritesMT;

  task_maskedstuff := MT_ScheduleTask(@R_MaskedStuffMT);
  MT_ExecutePendingTask(task_maskedstuff);

  TRendererWall8.R_RenderMultiThreadWalls8;

  TRendererPlane.R_DrawPlanes;

  // Check for completed thread tasks
  TestActiveThreads;

  R_RenderMultiThreadFlats8;

  TRendererWall8.R_WaitWallsCache8;

  TRenderer3dFloors.R_DrawFFloorsMultiThread;  // JVAL: 3d Floors

  // Check for completed thread tasks
  TestActiveThreads;

  R_RenderMultiThreadFFloors8;

  MT_WaitTask(task_8bitlights);
  TRendererThings.R_SignalPrepareMasked;
  MT_WaitTask(task_maskedstuff);
  TRendererThings.R_DrawMasked_MultiThread;

  // Check for completed thread tasks
  TestActiveThreads;

  // Check for new console commands.
  R_NetGame.Update;

  R_Execute3DTransform;

  TRendererThings.R_DrawPlayer;

  // Check for new console commands.
  R_NetGame.Update;

  task_clearplanes := MT_ScheduleTask(@TRendererPlane.R_InitializeVisplanes);
  MT_ExecutePendingTask(task_clearplanes);
end;

//==============================================================================
//
// R_DoRenderPlayerView32_MultiThread
//
//==============================================================================
class procedure TRendererMainLocal.R_DoRenderPlayerView32_MultiThread(player: Pplayer_t);
begin
  R_Fake3DPrepare(player);
  R_SetupFrame(player);
  R_CalcHiResTables_MultiThread;

  // Clear buffers.
  TRendererBsp.R_ClearClipSegs;
  TRendererBsp.R_ClearDrawSegs;
  TRendererPlane.R_ClearPlanes;
  R_Wait3DLookup;
  R_Fake3DAdjustPlanes(player);
  TRendererThings.R_ClearSprites;

  // Check for completed thread tasks
  TestActiveThreads;

  // check for new console commands.
  R_NetGame.Update;

  TRendererWall32.R_ClearWallsCache32;

  // The head node is the last node output.
  TRendererBsp.R_RenderBSPNode(numnodes - 1);

  // Check for completed thread tasks
  TestActiveThreads;

  TRendererThings.R_ProjectAdditionalThings;

  R_SortVisSpritesMT;

  task_maskedstuff := MT_ScheduleTask(@R_MaskedStuffMT);
  MT_ExecutePendingTask(task_maskedstuff);

  TRendererWall32.R_RenderMultiThreadWalls32;

  TRendererPlane.R_DrawPlanes;

  // Check for completed thread tasks
  TestActiveThreads;

  R_RenderMultiThreadFlats32;

  TRendererWall32.R_WaitWallsCache32;

  TRenderer3dFloors.R_DrawFFloorsMultiThread;  // JVAL: 3d Floors

  // Check for completed thread tasks
  TestActiveThreads;

  R_RenderMultiThreadFFloors32;

  TRendererThings.R_SignalPrepareMasked;
  MT_WaitTask(task_maskedstuff);
  TRendererThings.R_DrawMasked_MultiThread;

  // Check for completed thread tasks
  TestActiveThreads;

  // Check for new console commands.
  R_NetGame.Update;

  R_Execute3DTransform;

  TRendererThings.R_DrawPlayer;

  // Check for new console commands.
  R_NetGame.Update;

  task_clearplanes := MT_ScheduleTask(@TRendererPlane.R_InitializeVisplanes);
  MT_ExecutePendingTask(task_clearplanes);
end;
{$ENDIF}

//==============================================================================
//
// R_DoRenderPlayerView_SingleThread
//
//==============================================================================
class procedure TRendererMainLocal.R_DoRenderPlayerView_SingleThread(player: Pplayer_t);
begin
{$IFNDEF OPENGL}
  R_Fake3DPrepare(player);
{$ENDIF}
  R_SetupFrame(player);

{$IFNDEF OPENGL}
  R_Calc8bitTables;
  R_CalcHiResTables_SingleThread;
{$ENDIF}

  // Clear buffers.
{$IFNDEF OPENGL}
  TRendererBsp.R_ClearClipSegs;
  TRendererBsp.R_ClearDrawSegs;
{$ENDIF}
  TRendererPlane.R_ClearPlanes;
{$IFNDEF OPENGL}
  R_Fake3DAdjustPlanes(player);
{$ENDIF}
  TRendererThings.R_ClearSprites;

{$IFDEF OPENGL}
  gld_StartDrawScene; // JVAL OPENGL
{$ENDIF}

  // check for new console commands.
  R_NetGame.Update;

{$IFDEF OPENGL}
  gld_ClipperAddViewRange;
{$ENDIF}

  // The head node is the last node output.
  TRendererBsp.R_RenderBSPNode(numnodes - 1);

  TRendererThings.R_ProjectAdditionalThings;

  // Check for new console commands.
  R_NetGame.Update;

{$IFDEF OPENGL}
  gld_DrawScene(player);

  R_NetGame.Update;

  gld_EndDrawScene;

{$ELSE}
  TRendererSegs2.R_SetUpDrawSegLists;

  TRendererPlane.R_DrawPlanes;

  // Check for new console commands.
  R_NetGame.Update;

  TRenderer3dFloors.R_DrawFFloors;  // JVAL: 3d Floors

  TRendererThings.R_DrawMasked_SingleThread;

  R_Execute3DTransform;

  TRendererThings.R_DrawPlayer;
{$ENDIF}

  // Check for new console commands.
  R_NetGame.Update;

{$IFNDEF OPENGL}
  task_clearplanes := MT_ScheduleTask(@TRendererPlane.R_InitializeVisplanes);
  MT_ExecutePendingTask(task_clearplanes);
{$ENDIF}
end;

//==============================================================================
//
// R_RenderPlayerView
//
//==============================================================================
class procedure TRendererMain.R_RenderPlayerView(player: Pplayer_t);
begin
  // new render validcount
  Inc(rendervalidcount);

{$IFNDEF OPENGL}
  MT_WaitTask(task_clearplanes);
  zbufferactive := r_uselightmaps;
  TRendererSegs2.R_SetDrawSegFunctions;  // version 205
  if usemultithread then
  begin
    if videomode = vm8bit then
      TRendererMainLocal.R_DoRenderPlayerView8_MultiThread(player)
    else
      TRendererMainLocal.R_DoRenderPlayerView32_MultiThread(player);
  end
  else
{$ENDIF}
    TRendererMainLocal.R_DoRenderPlayerView_SingleThread(player);
{$IFNDEF OPENGL}
  if zbufferactive then
    TRendererZBuffer.R_StopZBuffer;
{$ENDIF}
  if mn_makescreenshot then
    TRendererMainLocal.R_MakeMenuThumbnail;
end;

//==============================================================================
//
// R_Ticker
//
//==============================================================================
class procedure TRendererMain.R_Ticker;
begin
  TRendererInterpolation.R_InterpolateTicker;
end;

end.


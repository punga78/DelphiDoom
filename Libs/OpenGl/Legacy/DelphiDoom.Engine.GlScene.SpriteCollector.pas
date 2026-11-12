//------------------------------------------------------------------------------
//
//  DelphiDoom: Engine - collects the sprites of a frame of the OpenGL scene
//  Copyright (C) 2004-2022 by Jim Valavanis
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit DelphiDoom.Engine.GlScene.SpriteCollector;

interface

uses
  d_delphi,
  r_defs,
  DelphiDoom.GlScene.Types,
  DelphiDoom.GlScene.DrawList,
  DelphiDoom.Engine.GlScene.Types,
  DelphiDoom.Engine.GlScene.LightMarker;

type
  /// <summary>
  ///   The vissprites of the renderer go to the draw list of the frame: light, colour translation, render
  ///   style, position and corners in OpenGL units, then the dynamic lights and the shadow of the sprite
  ///   (it was gld_AddSprite of gl_render.pas): the same records, in the same order
  /// </summary>
  /// <remarks>
  ///   A plain class called directly (once per sprite of every frame), never through an interface. It reads
  ///   the level and the view of the engine (sectors, viewx, viewy, extralight, usegamma, colorregions) and
  ///   registers the patches with gl_tex. The differences between the games are flags and fields their
  ///   records have (the two transparencies of Strife, the class of the player of Hexen, no floorclip in
  ///   Heretic): they stay conditional because the records are different by construction
  /// </remarks>
  TEngineGlSceneSpriteCollector = class(TObject)
  strict private
    FDrawList: TGlSceneDrawList;
    FLightTable: PGlSceneLightTable;
    FLights: TEngineGlSceneLightMarker;
    function LightLevel(const ALight: Integer): float;
  public
    /// <param name="ADrawList">The list of the frame; not owned</param>
    /// <param name="ALightTable">The light table of gl_render (gamma, light level)</param>
    /// <param name="ALights">Gets the lights and the shadow of every sprite; owned from now on</param>
    /// <exception cref="EArgumentNilException">A dependency is nil</exception>
    constructor Create(const ADrawList: TGlSceneDrawList; const ALightTable: PGlSceneLightTable;
      const ALights: TEngineGlSceneLightMarker);
    destructor Destroy; override;
    procedure Add(const AVisSprite: Pvissprite_t);
  end;

implementation

uses
  System.SysUtils,
  doomdef,
  m_fixed,
  info_h,
  v_data,
  v_video,
  p_mobj_h,
  p_local,
  p_maputl,
  p_3dfloors,
  p_setup,
  p_pspr,
  r_main,
  r_data,
  r_draw,
  r_dynlights,
  r_renderstyle,
  gl_defs,
  gl_tex,
  gl_shadows,
  DelphiDoom.GlScene.Light;

{ TEngineGlSceneSpriteCollector }

constructor TEngineGlSceneSpriteCollector.Create(const ADrawList: TGlSceneDrawList;
  const ALightTable: PGlSceneLightTable; const ALights: TEngineGlSceneLightMarker);
begin
  inherited Create;
  // owned at once: the destructor frees it if a check below fails
  FLights := ALights;
  if not Assigned(ADrawList) then
    raise EArgumentNilException.Create('ADrawList');
  if not Assigned(ALightTable) then
    raise EArgumentNilException.Create('ALightTable');
  if not Assigned(ALights) then
    raise EArgumentNilException.Create('ALights');
  FDrawList := ADrawList;
  FLightTable := ALightTable;
end;

destructor TEngineGlSceneSpriteCollector.Destroy;
begin
  FLights.Free;
  inherited Destroy;
end;

function TEngineGlSceneSpriteCollector.LightLevel(const ALight: Integer): float;
begin
  Result := TGlSceneLight.Level(FLightTable, usegamma, ALight);
end;

procedure TEngineGlSceneSpriteCollector.Add(const AVisSprite: Pvissprite_t);
var
  LMobj: Pmobj_t;
  LIndex: integer;
  LSprite: GLSprite;
  LTopOffset, LLeftOffset: float;
  LTexture: PGLTexture;
  LSector: Psector_t;
begin
  LMobj := AVisSprite.mo;
  LSprite.scale := AVisSprite.scale;
  if LMobj.frame and FF_FULLBRIGHT <> 0 then
    LSprite.light := 1.0
  else
  begin
    LSector := Psubsector_t(LMobj.subsector).sector;
    if LSector.midsec < 0 then
      LSprite.light := LightLevel(LSector.lightlevel + (extralight shl 5))
    else if P_3dFloorNumber(LMobj) = 0 then
      LSprite.light := LightLevel(sectors[LSector.midsec].lightlevel + (extralight shl 5))
    else
      LSprite.light := LightLevel(LSector.lightlevel + (extralight shl 5));
  end;
  LSprite.cm := -1;
  if LMobj.translationtable <> nil then
    for LIndex := 0 to Ord(CR_LIMIT) - 1 do
      if colorregions[LIndex] = LMobj.translationtable then
      begin
        LSprite.cm := LIndex;
        break;
      end;
  if LSprite.cm < 0 then
    LSprite.cm := Ord(CR_LIMIT) +
      {$IFDEF HEXEN}AVisSprite._class * ((MAXPLAYERS - 1)) + {$ENDIF}
      integer((LongWord(LMobj.flags) and LongWord(MF_TRANSLATION)) shr MF_TRANSSHIFT);
  if not IsIntegerInRange(LSprite.cm, 0, CR_INVUL) then
    LSprite.cm := Ord(CR_LIMIT);
  LSprite.gltexture := gld_RegisterPatch(AVisSprite.patch + firstspritelump, LSprite.cm);
  if LSprite.gltexture = nil then
    Exit;

  LTexture := LSprite.gltexture;

  LSprite.alpha := 0.0;
  LSprite.flags := 0;
  {$IFDEF STRIFE}
  if LMobj.flags and MF_SHADOW <> 0 then
  begin
    LSprite.flags := LSprite.flags or GLS_TRANSPARENT;
    LSprite.alpha := 33 / 100;
  end;
  if LMobj.flags and MF_MVIS <> 0 then
  begin
    LSprite.flags := LSprite.flags or GLS_TRANSPARENT;
    LSprite.alpha := 66 / 100;
  end;
  {$ELSE}
  if LMobj.flags and MF_SHADOW <> 0 then
    LSprite.flags := GLS_SHADOW;
  {$ENDIF}
  if LMobj.flags_ex and MF_EX_TRANSPARENT <> 0 then // JVAL -> alpha here!!!!
  begin
    LSprite.flags := LSprite.flags or GLS_TRANSPARENT;
    LSprite.alpha := tran_filter_pct / 100;
  end;
  if LMobj.renderstyle = mrs_translucent then
  begin
    LSprite.flags := LSprite.flags or GLS_TRANSPARENT;
    LSprite.alpha := LMobj.alpha / FRACUNIT;
  end
  else if LMobj.renderstyle = mrs_add then
  begin
    LSprite.flags := LSprite.flags or GLS_ADDITIVE;
    LSprite.alpha := LMobj.alpha / FRACUNIT;
  end
  else if LMobj.renderstyle = mrs_subtract then
  begin
    LSprite.flags := LSprite.flags or GLS_SUBTRACTIVE;
    LSprite.alpha := LMobj.alpha / FRACUNIT;
  end;

  if LMobj.flags_ex and MF_EX_LIGHT <> 0 then
  begin
    if LMobj.flags_ex and MF_EX_WHITELIGHT <> 0 then
      LSprite.flags := LSprite.flags or GLS_WHITELIGHT;
    if LMobj.flags_ex and MF_EX_REDLIGHT <> 0 then
      LSprite.flags := LSprite.flags or GLS_REDLIGHT;
    if LMobj.flags_ex and MF_EX_GREENLIGHT <> 0 then
      LSprite.flags := LSprite.flags or GLS_GREENLIGHT;
    if LMobj.flags_ex and MF_EX_BLUELIGHT <> 0 then
      LSprite.flags := LSprite.flags or GLS_BLUELIGHT;
    if LMobj.flags_ex and MF_EX_YELLOWLIGHT <> 0 then
      LSprite.flags := LSprite.flags or GLS_YELLOWLIGHT;
  end;

  LSprite.dlights := AVisSprite.mo.state.dlights;
  LSprite.models := AVisSprite.mo.state.models;
  LSprite.voxels := AVisSprite.mo.state.voxels;
  LSprite.mo := LMobj;
  LSprite.aproxdist := P_AproxDistance(LMobj.x - viewx, LMobj.y - viewy);

  LSprite.x := -LMobj.x / MAP_SCALE;
  LSprite.y :=  (LMobj.z{$IFNDEF HERETIC} - LMobj.floorclip{$ENDIF}) / MAP_SCALE;
  LSprite.z :=  LMobj.y / MAP_SCALE;

  LSprite.vt := 0.0;
  LSprite.vb := LTexture.height / LTexture.tex_height;
  if AVisSprite.flip then
  begin
    LSprite.ul := 0.0;
    LSprite.ur := LTexture.width / LTexture.tex_width;
  end
  else
  begin
    LSprite.ul := LTexture.width / LTexture.tex_width;
    LSprite.ur := 0.0;
  end;
  LLeftOffset := LTexture.leftoffset / MAP_COEFF;
  LTopOffset := LTexture.topoffset / MAP_COEFF;
  LSprite.x1 := LLeftOffset - (LTexture.realtexwidth / MAP_COEFF);
  LSprite.x2 := LLeftOffset;
  LSprite.y1 := LTopOffset;
  LSprite.y2 := LTopOffset - (LTexture.realtexheight / MAP_COEFF);

  if AVisSprite.infoscale <> FRACUNIT then
  begin
    LSprite.x1 := LSprite.x1 * AVisSprite.infoscale / FRACUNIT;
    LSprite.x2 := LSprite.x2 * AVisSprite.infoscale / FRACUNIT;
    LSprite.y1 := LSprite.y1 * AVisSprite.infoscale / FRACUNIT;
    LSprite.y2 := LSprite.y2 * AVisSprite.infoscale / FRACUNIT;
  end;

  if (LSprite.y2 < 0) and (AVisSprite.mobjflags and (MF_SPAWNCEILING or MF_FLOAT or MF_MISSILE or MF_NOGRAVITY) = 0) then
  begin
    LSprite.y1 := LSprite.y1 - LSprite.y2;
    LSprite.y2 := 0.0;
    LSprite.flags := LSprite.flags or GLS_CLIPPED;
  end;

  PGLSprite(FDrawList.AddSprite)^ := LSprite;

  // JVAL: Mark the dynamic lights of the LSprite
  if LSprite.aproxdist < DLIGHTSDRAWRANGE then
    FLights.MarkLights(@LSprite);

  if gl_drawshadows and (LSprite.dlights = nil) then
    if LSprite.aproxdist < SHADOWSDRAWRANGE then
      if LMobj.flags2_ex and MF2_EX_DONOTRENDERSHADOW = 0 then // JVAL: VERSION 204
        FLights.MarkShadow(@LSprite);
end;

end.

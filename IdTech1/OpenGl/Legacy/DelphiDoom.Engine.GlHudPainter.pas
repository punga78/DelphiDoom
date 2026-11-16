//------------------------------------------------------------------------------
//
//  DelphiDoom: Engine - the 2D pieces the OpenGL games draw with textures (patches, background, weapon)
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

unit DelphiDoom.Engine.GlHudPainter;

interface

uses
  d_delphi,
  r_defs;

type
  /// <summary>
  ///   The 2D pieces the OpenGL games draw as textured quads: a patch of the WAD at a screen position (the
  ///   automap marks), the flat behind the view window, the frame of the view window and the weapon of the
  ///   player (it was gld_DrawNumPatch, gld_DrawBackground, gld_DrawBackgroundFrame and gld_DrawWeapon of
  ///   gl_render.pas)
  /// </summary>
  /// <remarks>Static methods, no state: the texture bound and the blend are the ones of OpenGL and gl_tex</remarks>
  TEngineGlHudPainter = class sealed
  strict private
    class function ScaleX(const AX: Integer; const AFlags: Integer): float; static;
    class function ScaleY(const AY: Integer; const AFlags: Integer): float; static;
  public
    /// <summary>A patch of the WAD with its offsets, stretched to the screen, flipped or zoomed as the flags say</summary>
    class procedure DrawNumPatch(const AX, AY: Integer; const ALump: Integer; const AColorMap: Integer;
      const AFlags: Integer; const AZoomX: float = 1.0; const AZoomY: float = 1.0); static;
    /// <summary>The flat of the name over the whole screen (the part over the status bar in Doom)</summary>
    class procedure DrawBackground(const AName: string); static;
    /// <summary>The grey line around the view window, when it does not fill the screen</summary>
    class procedure DrawBackgroundFrame; static;
    /// <summary>The weapon sprite of the player lit, translucent or as a spectre as the player is</summary>
    class procedure DrawWeapon(const AWeaponLump: Integer; const AVisSprite: Pvissprite_t;
      const ALightLevel: Integer); static;
  end;

implementation

uses
  dglOpenGL,
  doomdef,
  d_player,
  doomstat,
  info_h,
  m_fixed,
  p_mobj_h,
  v_video,
  w_wad,
  r_main,
  r_draw,
  r_data,
  r_things,
  r_renderstyle,
  {$IFDEF DOOM}
  st_stuff,
  {$ENDIF}
  gl_types,
  gl_defs,
  gl_tex,
  gl_render;

{ TEngineGlHudPainter }

class function TEngineGlHudPainter.ScaleX(const AX: Integer; const AFlags: Integer): float;
begin
  if AFlags and VPT_STRETCH <> 0 then
    Result := AX * SCREENWIDTH / 320.0
  else
    Result := AX;
end;

class function TEngineGlHudPainter.ScaleY(const AY: Integer; const AFlags: Integer): float;
begin
  if AFlags and VPT_STRETCH <> 0 then
    Result := AY * SCREENHEIGHT / 200.0
  else
    Result := AY;
end;

class procedure TEngineGlHudPainter.DrawNumPatch(const AX, AY: Integer; const ALump: Integer;
  const AColorMap: Integer; const AFlags: Integer; const AZoomX: float; const AZoomY: float);
var
  gltexture: PGLTexture;
  fU1, fU2, fV1, fV2: float;
  width, height: float;
  xpos, ypos: float;
  dx, dy: float;
begin
  if AFlags and VPT_TRANS <> 0 then
  begin
    gltexture := gld_RegisterPatch(ALump, AColorMap, AFlags and VPT_NOUNLOAD = 0);
    gld_BindPatch(gltexture, AColorMap);
  end
  else
  begin
    gltexture := gld_RegisterPatch(ALump, Ord(CR_DEFAULT), AFlags and VPT_NOUNLOAD = 0);
    gld_BindPatch(gltexture, Ord(CR_DEFAULT));
  end;
  if gltexture = nil then
    exit;
  fV1 := 0.0;
  fV2 := gltexture.height / gltexture.tex_height;
  if AFlags and VPT_FLIP <> 0 then
  begin
    fU1 := gltexture.width / gltexture.tex_width;
    fU2 := 0.0;
  end
  else
  begin
    fU1 := 0.0;
    fU2 := gltexture.width / gltexture.tex_width;
  end;
  xpos := ScaleX(AX - gltexture.leftoffset, AFlags);
  ypos := ScaleY(AY - gltexture.topoffset, AFlags);
  width := ScaleX(gltexture.realtexwidth, AFlags);
  height := ScaleY(gltexture.realtexheight, AFlags);
  if (AZoomX <> 1.0) or (AZoomY <> 1.0) then
  begin
    dx := width * AZoomX - width;
    dy := height * AZoomY - height;
    xpos := xpos - dx / 2;
    ypos := ypos - dy / 2;
    width := width + dx;
    height := height + dy;
  end;

  glBegin(GL_TRIANGLE_STRIP);
    glTexCoord2f(fU1, fV1);
    glVertex2f(xpos, ypos);
    glTexCoord2f(fU1, fV2);
    glVertex2f(xpos, ypos + height);
    glTexCoord2f(fU2, fV1);
    glVertex2f(xpos + width, ypos);
    glTexCoord2f(fU2, fV2);
    glVertex2f(xpos + width, ypos + height);
  glEnd;
end;

class procedure TEngineGlHudPainter.DrawBackground(const AName: string);
var
  gltexture: PGLTexture;
  fU1, fU2, fV1, fV2: float;
  width, height: float;
{$IFDEF DOOM}
  sbar: Integer;
{$ENDIF}
begin
  gltexture := gld_RegisterFlat(W_GetNumForName(AName), false, -1);
  gld_BindFlat(gltexture, -1);
  if gltexture = nil then
    exit;
  fU1 := 0;
  fV1 := 0;
  fU2 := 320 / gltexture.realtexwidth;
  {$IFDEF DOOM}
  if statusbarstretch then
    sbar := 0
  else
    sbar := ST_HEIGHT;
  {$ENDIF}
  fV2 := (200{$IFDEF DOOM} - sbar{$ENDIF}) / gltexture.realtexheight;
  width := SCREENWIDTH;
  height := SCREENHEIGHT{$IFDEF DOOM} - sbar * SCREENHEIGHT / 200{$ENDIF};

  glBegin(GL_TRIANGLE_STRIP);
    glTexCoord2f(fU1, fV1);
    glVertex2f(0.0, 0.0);
    glTexCoord2f(fU1, fV2);
    glVertex2f(0.0, height);
    glTexCoord2f(fU2, fV1);
    glVertex2f(width, 0);
    glTexCoord2f(fU2, fV2);
    glVertex2f(width, height);
  glEnd;
end;

class procedure TEngineGlHudPainter.DrawBackgroundFrame;
var
  x1, x2, y1, y2: integer;
begin
  if (viewwindowx <= 0) and (viewwindowy <= 0) then
    Exit;

  x1 := viewwindowx - 1;
  x2 := x1 + viewwidth + 2;
  y1 := viewwindowy - 1;
  y2 := y1 + viewheight + 2;

  glDisable(GL_TEXTURE_2D);

  glColor4f(0.5, 0.5, 0.5, 1.0);
  glBegin(GL_LINE_STRIP);
    glVertex2i(x1, y1);
    glVertex2i(x2, y1);
    glVertex2i(x2, y2);
    glVertex2i(x1, y2);
    glVertex2i(x1, y1);
  glEnd;

  glEnable(GL_TEXTURE_2D);
end;

class procedure TEngineGlHudPainter.DrawWeapon(const AWeaponLump: Integer; const AVisSprite: Pvissprite_t;
  const ALightLevel: Integer);
var
  gltexture: PGLTexture;
  fU1, fU2, fV1, fV2: float;
  x1, y1, x2, y2: integer;
  scale: float;
  light: float;
  restoreblend: boolean;
begin
  gltexture := gld_RegisterPatch(firstspritelump + AWeaponLump, Ord(CR_DEFAULT));
  if gltexture = nil then
    exit;
  gld_BindPatch(gltexture, Ord(CR_DEFAULT));
  fU1 := 0.0;
  fV1 := 0.0;
  fU2 := gltexture.width / gltexture.tex_width;
  fV2 := gltexture.height / gltexture.tex_height;
  x1 := viewwindowx + AVisSprite.x1;
  x2 := viewwindowx + AVisSprite.x2;
  scale := AVisSprite.scale / FRACUNIT;
  y1 := viewwindowy + centery - round((AVisSprite.texturemid / FRACUNIT) * scale);
  y2 := y1 + round(gltexture.realtexheight * scale) + 1;
  light := gld_CalcLightLevel(ALightLevel);

// JVAL??  viewplayer.mo.renderstyle = mrs_translucent
  if viewplayer.mo.flags and MF_SHADOW <> 0 then
  begin
    glBlendFunc(GL_DST_COLOR, GL_ONE_MINUS_SRC_ALPHA);
    glAlphaFunc(GL_GEQUAL, 0.1);
    glColor4f(0.2, 0.2, 0.2, 0.33);
    restoreblend := true;
  end
  else
  begin
    if (viewplayer.mo.flags_ex and MF_EX_TRANSPARENT <> 0) or
       (viewplayer.mo.renderstyle = mrs_translucent) then
    begin
      gld_StaticLightAlpha(light, tran_filter_pct / 100.0);
      restoreblend := true;
    end
    else
    begin
      gld_StaticLight(light);
      restoreblend := false;
    end;
  end;
  glBegin(GL_TRIANGLE_STRIP);
    glTexCoord2f(fU1, fV1);
    glVertex2f(x1, y1);
    glTexCoord2f(fU1, fV2);
    glVertex2f(x1, y2);
    glTexCoord2f(fU2, fV1);
    glVertex2f(x2, y1);
    glTexCoord2f(fU2, fV2);
    glVertex2f(x2, y2);
  glEnd;
  if restoreblend then
  begin
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glAlphaFunc(GL_GEQUAL, 0.5);
  end;
  glColor3f(1.0, 1.0, 1.0);
end;

end.

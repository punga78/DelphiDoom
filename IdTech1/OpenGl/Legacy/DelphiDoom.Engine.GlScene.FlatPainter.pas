//------------------------------------------------------------------------------
//
//  DelphiDoom: Engine - draws the flats of a frame of the OpenGL scene
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

unit DelphiDoom.Engine.GlScene.FlatPainter;

interface

uses
  System.SysUtils,
  d_delphi,
  dglOpenGL,
  DelphiDoom.Engine.GlScene.Types;

type
  /// <summary>
  ///   Draws one flat (the floor or the ceiling of a sector) of the draw list with OpenGL: the display list
  ///   of the sector, the sloped floors and ceilings, the offset, the rotation and the ripple of the texture
  ///   (it was gld_DrawFlat and gld_MakeRippleMatrix of gl_render.pas): the same OpenGL calls, in the same
  ///   order, with the same numbers
  /// </summary>
  /// <remarks>
  ///   A plain class called directly (once per flat of every frame), never through an interface and with no
  ///   virtual method. The state OpenGL keeps (the bound texture, the fog, the light) stays where it was: in
  ///   gl_tex and gl_render. The only thing the class holds is the matrix of the old ripple effect, that is
  ///   made again when the fraction of the level time changes
  /// </remarks>
  TEngineGlSceneFlatPainter = class(TObject)
  strict private
    FRippleMatrix: array[0..15] of TGLfloat;
    FRippleLastFraction: Integer;
    procedure MakeRippleMatrix;
  public
    constructor Create;
    /// <summary>Draws the flat; a flat with a negative sector number is skipped</summary>
    procedure Draw(const AFlat: PGLFlat);
  end;

implementation

uses
  doomdef,
  r_defs,
  p_setup,
  p_tick,
  g_game,
  m_fixed,
  z_zone,
  gl_defs,
  gl_types,
  gl_lightmaps,
  DelphiDoom.Engine.GlLightmap.Types,
  gl_render,
  DelphiDoom.Engine.GlScene.Fog,
  gl_slopes,
  gl_tex;

{ TEngineGlSceneFlatPainter }

constructor TEngineGlSceneFlatPainter.Create;
begin
  inherited Create;
  FRippleLastFraction := -1;
end;

procedure TEngineGlSceneFlatPainter.MakeRippleMatrix;
var
  LSin, LCos: TGLfloat;
  LFraction: Integer;
begin
  LFraction := leveltime and 63;
  if FRippleLastFraction = LFraction then
    Exit;

  FRippleLastFraction := LFraction;

  LSin := 0.01 * Sin(LFraction / 64 * 2 * __glPi);
  LCos := 0.01 * Cos(LFraction / 64 * 2 * __glPi);

  FRippleMatrix[0 + 4 * 0] := 1;
  FRippleMatrix[0 + 4 * 1] := LSin;
  FRippleMatrix[0 + 4 * 2] := LSin;
  FRippleMatrix[0 + 4 * 3] := 0;

  FRippleMatrix[1 + 4 * 0] := LCos;
  FRippleMatrix[1 + 4 * 1] := 1;
  FRippleMatrix[1 + 4 * 2] := LCos;
  FRippleMatrix[1 + 4 * 3] := 0;

  FRippleMatrix[2 + 4 * 0] := 0;
  FRippleMatrix[2 + 4 * 1] := 0;
  FRippleMatrix[2 + 4 * 2] := 1;
  FRippleMatrix[2 + 4 * 3] := 0;

  FRippleMatrix[3 + 4 * 0] := 0;
  FRippleMatrix[3 + 4 * 1] := 0;
  FRippleMatrix[3 + 4 * 2] := 0;
  FRippleMatrix[3 + 4 * 3] := 1;
end;

procedure TEngineGlSceneFlatPainter.Draw(const AFlat: PGLFlat);
var
  LLoopNumber, LIndex: Integer; // current loop number
  LCurrentLoop: PGLLoopDef; // the current loop
  LTextureScale: float;
  LGlSector: PGLSector;
  LSector: Psector_t;
  LFloorZ: float;
begin
  if AFlat.sectornum < 0 then
    Exit;

  LTextureScale := AFlat.gltexture.texturescale;
  LGlSector := @sectorloops[AFlat.sectornum];
  LSector := @sectors[AFlat.sectornum];
  if LGlSector.list = 0 then
  begin
    if LGlSector.loopcount > 0 then
    begin
      LGlSector.list := glGenLists(1);

      if LGlSector.list > 0 then
      begin
        glNewList(LGlSector.list, GL_COMPILE);

        for LLoopNumber := 0 to LGlSector.loopcount - 1 do
        begin
          // set the current loop
          LCurrentLoop := @LGlSector.loops[LLoopNumber];
          glBegin(LCurrentLoop.mode);
          for LIndex := LCurrentLoop.vertexindex to LCurrentLoop.vertexindex + LCurrentLoop.vertexcount - 1 do
          begin
            glTexCoord2f(gld_texcoords[LIndex].u * LTextureScale, gld_texcoords[LIndex].v * LTextureScale);
            glVertex3fv(@gld_vertexes[LIndex]);
          end;
          glEnd;
        end;

        glEndList;

        LGlSector.listtexscale := LTextureScale;

        if G_PlayingEngineVersion < VERSIONSLOPES then
          Z_Free(LGlSector.loops);  // JVAL: Slopes
      end
      else
        LGlSector.list := GL_BAD_LIST;
    end
    else
      LGlSector.list := GL_BAD_LIST;
  end;

  if gl_uselightmaps then
  begin
    glActiveTextureARB(GL_TEXTURE1_ARB);
    glMatrixMode(GL_TEXTURE);
    glPushMatrix;
    glTranslatef(0, AFlat.z * MAP_COEFF / (LIGHTMAPSIZEY * LIGHTMAPUNIT), 0);
    glActiveTextureARB(GL_TEXTURE0_ARB);
  end;

  if AFlat.whitefog then TEngineGlSceneFog.StartWhite;  // JVAL: Mars fog sectors

  if AFlat.ripple and not gl_old_ripple_effect then
    gld_BindFlat(AFlat.gltexture, leveltime and 31)
  else
    gld_BindFlat(AFlat.gltexture, -1);
  gld_StaticLight(AFlat.light);
  glMatrixMode(GL_MODELVIEW);
  glPushMatrix;
  LFloorZ := AFlat.z;
  glTranslatef(0.0, LFloorZ, 0.0);
  {$IFNDEF HERETIC}
  if AFlat.hasoffset then
  begin
    glMatrixMode(GL_TEXTURE);
    glPushMatrix;
    glTranslatef(AFlat.uoffs * LTextureScale {$IFDEF HEXEN}* 64 / AFlat.gltexture.width{$ENDIF},
                 AFlat.voffs * LTextureScale {$IFDEF HEXEN}* 64 / AFlat.gltexture.height{$ENDIF},
                 0.0);
  end;
  {$ENDIF}

  glActiveTextureARB(GL_TEXTURE0_ARB);

  if AFlat.hasangle then
  begin
    glMatrixMode(GL_TEXTURE);
    glPushMatrix;
    glTranslatef(
      AFlat.anglex * LTextureScale {$IFDEF HEXEN}* 64 / AFlat.gltexture.width{$ENDIF},
      -AFlat.angley * LTextureScale {$IFDEF HEXEN}* 64 / AFlat.gltexture.height{$ENDIF},
      0.0);
    glRotatef(AFlat.angle, 0, 0, 1);
    glTranslatef(
      -AFlat.anglex * LTextureScale {$IFDEF HEXEN}* 64 / AFlat.gltexture.width{$ENDIF},
      AFlat.angley * LTextureScale {$IFDEF HEXEN}* 64 / AFlat.gltexture.height{$ENDIF},
      0.0);
  end;

  if AFlat.ripple and gl_old_ripple_effect then
  begin
    MakeRippleMatrix;
    glMatrixMode(GL_TEXTURE);
    glPushMatrix;
    glMultMatrixf(@FRippleMatrix);
  end;

  if not AFlat.ceiling and (LSector.renderflags and SRF_SLOPEFLOOR <> 0) then
  begin
    // go through all loops of this sector
    for LLoopNumber := 0 to LGlSector.loopcount - 1 do
    begin
      LCurrentLoop := @LGlSector.loops[LLoopNumber];
      glBegin(LCurrentLoop.mode);
      for LIndex := LCurrentLoop.vertexindex to LCurrentLoop.vertexindex + LCurrentLoop.vertexcount - 1 do
      begin
        glTexCoord2f(gld_texcoords[LIndex].u * LTextureScale, gld_texcoords[LIndex].v * LTextureScale);
        glVertex3f(gld_vertexes[LIndex].x,
          gld_FloorHeight(LSector, gld_vertexes[LIndex].x, gld_vertexes[LIndex].z) - LFloorZ,
          gld_vertexes[LIndex].z)
      end;
      glEnd;
    end;
  end
  else if AFlat.ceiling and (LSector.renderflags and SRF_SLOPECEILING <> 0) then
  begin
    // go through all loops of this sector
    for LLoopNumber := 0 to LGlSector.loopcount - 1 do
    begin
      LCurrentLoop := @LGlSector.loops[LLoopNumber];
      glBegin(LCurrentLoop.mode);
      for LIndex := LCurrentLoop.vertexindex to LCurrentLoop.vertexindex + LCurrentLoop.vertexcount - 1 do
      begin
        glTexCoord2f(gld_texcoords[LIndex].u * LTextureScale, gld_texcoords[LIndex].v * LTextureScale);
        glVertex3f(gld_vertexes[LIndex].x,
          gld_CeilingHeight(LSector, gld_vertexes[LIndex].x, gld_vertexes[LIndex].z) - LFloorZ,
          gld_vertexes[LIndex].z)
      end;
      glEnd;
    end;
  end
  else
  begin
    // JVAL: Call the precalced list if available
    if (LGlSector.list <> GL_BAD_LIST) and (LGlSector.listtexscale = AFlat.gltexture.texturescale) then
      glCallList(LGlSector.list)
    else if LTextureScale = 1.0 then
    begin
    // go through all loops of this sector
      for LLoopNumber := 0 to LGlSector.loopcount - 1 do
      begin
        // set the current loop
        LCurrentLoop := @LGlSector.loops[LLoopNumber];
        glDrawArrays(LCurrentLoop.mode, LCurrentLoop.vertexindex, LCurrentLoop.vertexcount);
      end;
    end
    else
    begin
      for LLoopNumber := 0 to LGlSector.loopcount - 1 do
      begin
        LCurrentLoop := @LGlSector.loops[LLoopNumber];
        glBegin(LCurrentLoop.mode);
        for LIndex := LCurrentLoop.vertexindex to LCurrentLoop.vertexindex + LCurrentLoop.vertexcount - 1 do
        begin
          glTexCoord2f(gld_texcoords[LIndex].u * LTextureScale, gld_texcoords[LIndex].v * LTextureScale);
          glVertex3fv(@gld_vertexes[LIndex]);
        end;
        glEnd;
      end;
    end;
  end;
  if AFlat.ripple and gl_old_ripple_effect then
  begin
    glPopMatrix;
    glMatrixMode(GL_MODELVIEW);
  end;

  glActiveTextureARB(GL_TEXTURE0_ARB);
  if AFlat.hasangle then
  begin
    glMatrixMode(GL_TEXTURE);
    glPopMatrix;
    glMatrixMode(GL_MODELVIEW);
    glActiveTextureARB(GL_TEXTURE0_ARB);
  end;

  {$IFNDEF HERETIC}
  if AFlat.hasoffset then
  begin
    glMatrixMode(GL_TEXTURE);
    glPopMatrix;
    glMatrixMode(GL_MODELVIEW);
  end;
  {$ENDIF}
  if gl_uselightmaps then
  begin
    glActiveTextureARB(GL_TEXTURE1_ARB);
    glMatrixMode(GL_TEXTURE);
    glPopMatrix;
    glMatrixMode(GL_MODELVIEW);
    glActiveTextureARB(GL_TEXTURE0_ARB);
  end;

  if AFlat.whitefog then TEngineGlSceneFog.Start;  // JVAL: Mars fog sectors

  glPopMatrix;
end;

end.

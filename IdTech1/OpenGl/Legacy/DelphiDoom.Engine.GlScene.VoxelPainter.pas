//------------------------------------------------------------------------------
//
//  DelphiDoom: Engine - draws the voxels of the things of the OpenGL scene
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

unit DelphiDoom.Engine.GlScene.VoxelPainter;

interface

uses
  d_delphi,
  DelphiDoom.Engine.GlScene.Types;

type
  /// <summary>
  ///   Draws the voxels of a sprite of the draw list with OpenGL: the position and rotation of the thing, the
  ///   light effects, the shadow, the blends, the spin of the voxel and its display list (it was
  ///   gld_DrawVoxels and gld_DrawVoxel of gl_render.pas): the same OpenGL calls, in the same order, with the
  ///   same numbers
  /// </summary>
  /// <remarks>
  ///   A plain class called directly (once per sprite with a voxel of every frame), never through an
  ///   interface and with no virtual method. It holds nothing: the voxel manager, the states and the display
  ///   lists are the ones of vx_base and gl_voxels, the state OpenGL keeps stays where it was
  /// </remarks>
  TEngineGlSceneVoxelPainter = class(TObject)
  strict private
    /// <summary>Draws one voxel of the sprite (an entry of voxelstates)</summary>
    class procedure DrawVoxel(const ASprite: PGLSprite; const AIndex: Integer); static;
  public
    /// <summary>Draws all the voxels of the sprite</summary>
    procedure Draw(const ASprite: PGLSprite);
  end;

implementation

uses
  dglOpenGL,
  doomstat,
  doomdef,
  m_fixed,
  tables,
  d_player,
  i_system,
  g_game,
  r_dynlights,
  r_intrpl,
  p_mobj_h,
  p_tick,
  r_defs,
  gl_defs,
  gl_types,
  gl_lights,
  gl_lightmaps,
  DelphiDoom.Engine.GlLightmap.Types,
  gl_render,
  gl_tex,
  gl_voxels,
  vx_base,
  r_lights;

{ TEngineGlSceneVoxelPainter }

class procedure TEngineGlSceneVoxelPainter.DrawVoxel(const ASprite: PGLSprite; const AIndex: Integer);
var
  LInfo: Pvoxelstate_t;
  LVoxelItem: Pvoxelmanageritem_t;
  LRestoreBlend: Boolean;
  LRestoreEquation: Boolean;
  LAngleDifference, LSpinAngle: angle_t;
begin
  LInfo := @voxelstates[AIndex];

  LRestoreBlend := False;
  LRestoreEquation := False;

  if ASprite.flags and GLS_SHADOW <> 0 then
  begin
    glBlendFunc(GL_DST_COLOR, GL_ONE_MINUS_SRC_ALPHA);
    glAlphaFunc(GL_GEQUAL, 0.1);
    glColor4f(0.2, 0.2, 0.2, 0.33);
    LRestoreBlend := True;
  end
  else
  begin
    if ASprite.flags and GLS_TRANSPARENT <> 0 then
    begin
      gld_StaticLightAlpha(ASprite.light, ASprite.alpha);
      glAlphaFunc(GL_GEQUAL, 0.01);
      LRestoreBlend := True;
    end
    else if ASprite.flags and GLS_ADDITIVE <> 0 then
    begin
      gld_StaticLightAlpha(ASprite.light, ASprite.alpha);
      glAlphaFunc(GL_GEQUAL, 0.01);
      glBlendFunc(GL_SRC_ALPHA, GL_ONE);
      LRestoreBlend := True;
    end
    else if ASprite.flags and GLS_SUBTRACTIVE <> 0 then
    begin
      gld_StaticLightAlpha(ASprite.light, ASprite.alpha);
      glAlphaFunc(GL_GEQUAL, 0.01);
      glBlendFunc(GL_SRC_ALPHA, GL_ONE);
      glBlendEquation(GL_FUNC_REVERSE_SUBTRACT);
      LRestoreBlend := True;
      LRestoreEquation := True;
    end
    else
      gld_StaticLight(ASprite.light);
  end;

  last_gltexture := nil;

  LVoxelItem := @voxelmanager.items[LInfo.voxelidx];
  // the model is made with the voxel (VX_AddVoxel): it is nil only after VX_VoxelsDone
  if LVoxelItem.voxel = nil then
  begin
    I_Warning('gld_DrawVoxel(): Can not load voxel %s'#13#10, [LVoxelItem.name]);
    if LRestoreBlend then
      glAlphaFunc(GL_GEQUAL, 0.01);
    if LRestoreEquation then
      glBlendEquation(GL_FUNC_ADD);
    Exit;
  end;

  LAngleDifference := LVoxelItem.angleoffset * ANG1;
  {$IFDEF HEXEN}
  if ASprite.mo.flags2 and MF2_DROPPED <> 0 then
  {$ELSE}
  if ASprite.mo.flags and MF_DROPPED <> 0 then
  {$ENDIF}
    LSpinAngle := LVoxelItem.droppedspin
  else
    LSpinAngle := LVoxelItem.placedspin;
  if LSpinAngle <> 0 then
  begin
    if not isgamesuspended then
      LSpinAngle := Round(((TTickState.LevelTime + ticfrac / FRACUNIT) / TICRATE * LSpinAngle) * (ANGLE_MAX / 360))
    else
      LSpinAngle := Round((TTickState.LevelTime / TICRATE * LSpinAngle) * (ANGLE_MAX / 360));
  end;
  LAngleDifference := LSpinAngle - LAngleDifference;

  LVoxelItem.voxel.Draw(LInfo.frame, LAngleDifference);

  if LRestoreBlend then
    glAlphaFunc(GL_GEQUAL, 0.01);
  if LRestoreEquation then
    glBlendEquation(GL_FUNC_ADD);
end;

procedure TEngineGlSceneVoxelPainter.Draw(const ASprite: PGLSprite);
var
  LIndex: Integer;
begin
  if gl_uselightmaps then
  begin
    glActiveTextureARB(GL_TEXTURE1_ARB);
    glMatrixMode(GL_TEXTURE);
    glPushMatrix;
    glTranslatef(ASprite.x * MAP_COEFF / (LIGHTMAPSIZEX * LIGHTMAPUNIT),
                 ASprite.y * MAP_COEFF / (LIGHTMAPSIZEY * LIGHTMAPUNIT),
                 ASprite.z * MAP_COEFF / (LIGHTMAPSIZEZ * LIGHTMAPUNIT));
    glActiveTextureARB(GL_TEXTURE0_ARB);
  end;

  glMatrixMode(GL_MODELVIEW);
  glPushMatrix;
  glTranslatef(ASprite.x, ASprite.y, ASprite.z);
  glRotatef(ASprite.mo.angle / (ANGLE_MAX / 360.0) - 90.0, 0.0, 1.0, 0.0);

  // JVAL
  // Draw light effects (only if not invulnerability)
  if uselightboost then
    if not lightdeflumppresent then
      if players[displayplayer].fixedcolormap <> 32 then
      // JVAL: Use old color effects only if LIGHTDEF lump not found
        if ASprite.flags and GLS_LIGHT <> 0 then
        begin
          if ASprite.flags and GLS_WHITELIGHT <> 0 then
            gld_SetUplight(1.0, 1.0, 1.0)
          else if ASprite.flags and GLS_REDLIGHT <> 0 then
            gld_SetUplight(1.0, 0.0, 0.0)
          else if ASprite.flags and GLS_GREENLIGHT <> 0 then
            gld_SetUplight(0.0, 1.0, 0.0)
          else if ASprite.flags and GLS_BLUELIGHT <> 0 then
            gld_SetUplight(0.0, 0.0, 1.0)
          else if ASprite.flags and GLS_YELLOWLIGHT <> 0 then
            gld_SetUplight(1.0, 1.0, 0.0);
          glBegin(GL_TRIANGLE_STRIP);
            glTexCoord2f(0.0, 0.0);
            glVertex3f(2.0 * ASprite.x1, 2.0 * ASprite.y1, 0.01);
            glTexCoord2f(1.0, 0.0);
            glVertex3f(2.0 * ASprite.x2, 2.0 * ASprite.y1, 0.01);
            glTexCoord2f(0.0, 1.0);
            glVertex3f(2.0 * ASprite.x1, 2.0 * ASprite.y2, 0.01);
            glTexCoord2f(1.0, 1.0);
            glVertex3f(2.0 * ASprite.x2, 2.0 * ASprite.y2, 0.01);
          glEnd;
          glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
          glAlphaFunc(GL_GEQUAL, 0.5);
        end;

  for LIndex := 0 to ASprite.voxels.Count - 1 do
    DrawVoxel(ASprite, ASprite.voxels.Numbers[LIndex]);

  glPopMatrix;

  if gl_uselightmaps then
  begin
    glActiveTextureARB(GL_TEXTURE1_ARB);
    glMatrixMode(GL_TEXTURE);
    glPopMatrix;
    glMatrixMode(GL_MODELVIEW);
    glActiveTextureARB(GL_TEXTURE0_ARB);
  end;

  if ASprite.flags and (GLS_SHADOW or GLS_TRANSPARENT or GLS_ADDITIVE or GLS_SUBTRACTIVE) <> 0 then
  begin
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glAlphaFunc(GL_GEQUAL, 0.5);
    if ASprite.flags and GLS_SUBTRACTIVE <> 0 then
      glBlendEquation(GL_FUNC_ADD);
  end;
  glColor3f(1.0, 1.0, 1.0);
end;

end.

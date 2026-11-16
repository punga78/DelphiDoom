//------------------------------------------------------------------------------
//
//  DelphiDoom: Engine - draws the sprites of a frame of the OpenGL scene
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

unit DelphiDoom.Engine.GlScene.SpritePainter;

interface

uses
  System.SysUtils,
  d_delphi,
  dglOpenGL,
  DelphiDoom.Engine.GlScene.Types,
  DelphiDoom.Engine.GlScene.ModelPainter,
  DelphiDoom.Engine.GlScene.VoxelPainter;

type
  /// <summary>
  ///   Draws one sprite of the draw list with OpenGL: the light effects, the shadow, the transparent,
  ///   additive and subtractive sprites and the flat quad of the thing (it was gld_DrawSprite of
  ///   gl_render.pas): the same OpenGL calls, in the same order, with the same numbers. A sprite that has a
  ///   model or a voxel is given to the routines that draw them
  /// </summary>
  /// <remarks>
  ///   A plain class called directly (once per sprite of every frame), never through an interface and with
  ///   no virtual method. The state OpenGL keeps stays where it was. The only thing the class holds is the
  ///   inverse yaw of the view of the frame, that gld_StartDrawScene gives it
  /// </remarks>
  TEngineGlSceneSpritePainter = class(TObject)
  strict private
    const
      DROPPED_ZOFFS = -0.04;
  strict private
    FInverseYaw: float;
    FModelPainter: TEngineGlSceneModelPainter;
    FVoxelPainter: TEngineGlSceneVoxelPainter;
  public
    /// <summary>A painter that gives the sprites with a model to AModelPainter and those with a voxel to AVoxelPainter, which it owns</summary>
    constructor Create(const AModelPainter: TEngineGlSceneModelPainter;
      const AVoxelPainter: TEngineGlSceneVoxelPainter);
    destructor Destroy; override;
    /// <summary>A new frame: the inverse yaw of the view in degrees</summary>
    procedure BeginFrame(const AInverseYaw: float);
    /// <summary>Draws the sprite</summary>
    procedure Draw(const ASprite: PGLSprite);
  end;

implementation

uses
  doomstat,
  doomdef,
  info_h,
  p_mobj_h,
  r_defs,
  r_dynlights,
  r_lights,
  d_player,
  g_game,
  gl_defs,
  gl_types,
  gl_lights,
  gl_lightmaps,
  DelphiDoom.Engine.GlLightmap.Types,
  gl_models,
  gl_voxels,
  gl_render,
  DelphiDoom.Engine.GlScene.Fog,
  gl_tex;

{ TEngineGlSceneSpritePainter }

constructor TEngineGlSceneSpritePainter.Create(const AModelPainter: TEngineGlSceneModelPainter;
  const AVoxelPainter: TEngineGlSceneVoxelPainter);
begin
  inherited Create;
  if not Assigned(AModelPainter) then
    raise EArgumentNilException.Create('AModelPainter');
  if not Assigned(AVoxelPainter) then
    raise EArgumentNilException.Create('AVoxelPainter');
  FModelPainter := AModelPainter;
  FVoxelPainter := AVoxelPainter;
end;

destructor TEngineGlSceneSpritePainter.Destroy;
begin
  FVoxelPainter.Free;
  FModelPainter.Free;
  inherited Destroy;
end;

procedure TEngineGlSceneSpritePainter.BeginFrame(const AInverseYaw: float);
begin
  FInverseYaw := AInverseYaw;
end;

procedure TEngineGlSceneSpritePainter.Draw(const ASprite: PGLSprite);
var
  LHasWhiteFog: Boolean; // JVAL: Mars fog sectors
begin
  LHasWhiteFog := Psubsector_t(ASprite.mo.subsector).sector.renderflags and SRF_FOG <> 0;

  if gl_drawmodels and (ASprite.models <> nil) then
  begin
    if LHasWhiteFog then TEngineGlSceneFog.StartWhite;  // JVAL: Mars fog sectors
    FModelPainter.Draw(ASprite);
    if LHasWhiteFog then TEngineGlSceneFog.Start; // JVAL: Mars fog sectors
    Exit;
  end;

  if gl_drawvoxels and (ASprite.voxels <> nil) then
  begin
    if LHasWhiteFog then TEngineGlSceneFog.StartWhite;  // JVAL: Mars fog sectors
    FVoxelPainter.Draw(ASprite);
    if LHasWhiteFog then TEngineGlSceneFog.Start; // JVAL: Mars fog sectors
    Exit;
  end;

  if LHasWhiteFog then TEngineGlSceneFog.StartWhite;  // JVAL: Mars fog sectors

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
  glRotatef(FInverseYaw, 0.0, 1.0, 0.0);

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

  gld_BindPatch(ASprite.gltexture, ASprite.cm);

  if ASprite.flags and GLS_SHADOW <> 0 then
  begin
    glBlendFunc(GL_DST_COLOR, GL_ONE_MINUS_SRC_ALPHA);
    glAlphaFunc(GL_GEQUAL, 0.1);
    glColor4f(0.2, 0.2, 0.2, 0.33);
  end
  else
  begin
    if ASprite.flags and GLS_TRANSPARENT <> 0 then
    begin
      gld_StaticLightAlpha(ASprite.light, ASprite.alpha);
      glAlphaFunc(GL_GEQUAL, 0.01);
    end
    else if ASprite.flags and GLS_ADDITIVE <> 0 then
    begin
      gld_StaticLightAlpha(ASprite.light, ASprite.alpha);
      glAlphaFunc(GL_GEQUAL, 0.01);
      glBlendFunc(GL_SRC_ALPHA, GL_ONE);
    end
    else if ASprite.flags and GLS_SUBTRACTIVE <> 0 then
    begin
      gld_StaticLightAlpha(ASprite.light, ASprite.alpha);
      glAlphaFunc(GL_GEQUAL, 0.01);
      glBlendFunc(GL_SRC_ALPHA, GL_ONE);
      glBlendEquation(GL_FUNC_REVERSE_SUBTRACT);
    end
    else
      gld_StaticLight(ASprite.light);
  end;
  glBegin(GL_TRIANGLE_STRIP);
  {$IFDEF HEXEN}
  if ASprite.mo.flags2 and MF2_DROPPED <> 0 then
  {$ELSE}
  if ASprite.mo.flags and MF_DROPPED <> 0 then
  {$ENDIF}
  begin
    glTexCoord2f(ASprite.ul, ASprite.vt);
    glVertex3f(ASprite.x1, ASprite.y1, DROPPED_ZOFFS);
    glTexCoord2f(ASprite.ur, ASprite.vt);
    glVertex3f(ASprite.x2, ASprite.y1, DROPPED_ZOFFS);
    glTexCoord2f(ASprite.ul, ASprite.vb);
    glVertex3f(ASprite.x1, ASprite.y2, DROPPED_ZOFFS);
    glTexCoord2f(ASprite.ur, ASprite.vb);
    glVertex3f(ASprite.x2, ASprite.y2, DROPPED_ZOFFS);
  end
  else
  begin
    glTexCoord2f(ASprite.ul, ASprite.vt);
    glVertex3f(ASprite.x1, ASprite.y1, 0.0);
    glTexCoord2f(ASprite.ur, ASprite.vt);
    glVertex3f(ASprite.x2, ASprite.y1, 0.0);
    glTexCoord2f(ASprite.ul, ASprite.vb);
    glVertex3f(ASprite.x1, ASprite.y2, 0.0);
    glTexCoord2f(ASprite.ur, ASprite.vb);
    glVertex3f(ASprite.x2, ASprite.y2, 0.0);
  end;
  glEnd;

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

  if LHasWhiteFog then TEngineGlSceneFog.Start; // JVAL: Mars fog sectors
end;

end.

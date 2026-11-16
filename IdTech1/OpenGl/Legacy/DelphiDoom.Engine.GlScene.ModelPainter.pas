//------------------------------------------------------------------------------
//
//  DelphiDoom: Engine - draws the 3D models of the things of the OpenGL scene
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

unit DelphiDoom.Engine.GlScene.ModelPainter;

interface

uses
  System.SysUtils,
  d_delphi,
  p_mobj_h,
  DelphiDoom.Engine.GlScene.Types;

type
  /// <summary>
  ///   Draws the models (MD2, DDMODEL, DMX, DLL) of a sprite of the draw list with OpenGL: the position and
  ///   rotation of the thing, the light effects, the shadow, the blends, the texture of the model and the
  ///   frame, interpolated with the next one where the game asks for it (it was gld_DrawModels,
  ///   gld_DrawModel and gld_FindNextModelFrame of gl_render.pas): the same OpenGL calls, in the same
  ///   order, with the same numbers
  /// </summary>
  /// <remarks>
  ///   A plain class called directly (once per sprite with a model of every frame), never through an
  ///   interface and with no virtual method. It holds nothing: the registry of the models, the textures
  ///   and the states are the ones of gl_models, the state OpenGL keeps stays where it was
  /// </remarks>
  TEngineGlSceneModelPainter = class(TObject)
  strict private
    /// <summary>The frame of the model the next state of the thing starts with, -1 if it has none</summary>
    class function FindNextFrame(const AMobj: Pmobj_t; const AModelIndex: Integer): Integer; static;
    /// <summary>Draws one model of the sprite (an entry of modelstates)</summary>
    class procedure DrawModel(const ASprite: PGLSprite; const AIndex: Integer); static;
  public
    /// <summary>Draws all the models of the sprite</summary>
    procedure Draw(const ASprite: PGLSprite);
  end;

implementation

uses
  dglOpenGL,
  doomstat,
  doomdef,
  info_h,
  info,
  m_fixed,
  tables,
  d_player,
  g_game,
  i_system,
  p_tick,
  r_dynlights,
  r_intrpl,
  r_defs,
  gl_defs,
  gl_types,
  gl_lights,
  gl_lightmaps,
  DelphiDoom.Engine.GlLightmap.Types,
  gl_models,
  gl_render,
  gl_tex,
  r_lights,
  sc_states;

{ TEngineGlSceneModelPainter }

class function TEngineGlSceneModelPainter.FindNextFrame(const AMobj: Pmobj_t;
  const AModelIndex: Integer): Integer;
var
  LIndex: Integer;
  LStateModel: Integer;
  LStateNumber: Integer;
  LState: Pstate_t;
begin
  LStateNumber := Ord(AMobj.state.nextstate);
  if LStateNumber < 1 then
  begin
    Result := -1;
    Exit;
  end;
  LState := @states[LStateNumber];
  if LState.models = nil then
  begin
    I_DevWarning('gld_FindNextModelFrame(): Missing model information on state %s'#13#10,
      [statenames.Strings[LStateNumber]]);
    Result := -1;
    Exit;
  end;
  if LState = AMobj.state then
  begin
    for LIndex := 0 to LState.models.Count - 1 do
    begin
      LStateModel := LState.models.Numbers[LIndex];
      if modelstates[LStateModel].modelidx = AModelIndex then
      begin
        Result := modelstates[LStateModel].endframe;
        Exit;
      end;
    end;
  end
  else
  begin
    for LIndex := 0 to LState.models.Count - 1 do
    begin
      LStateModel := LState.models.Numbers[LIndex];
      if modelstates[LStateModel].modelidx = AModelIndex then
      begin
        Result := modelstates[LStateModel].startframe;
        Exit;
      end;
    end;
  end;
  Result := -1;
end;

class procedure TEngineGlSceneModelPainter.DrawModel(const ASprite: PGLSprite; const AIndex: Integer);
var
  LInfo: Pmodelstate_t;
  LTexture: Ptexturemanagetitem_t;
  LModelItem: Pmodelmanageritem_t;
  LNextFrame: Integer;
  LRestoreBlend: Boolean;
  LRestoreEquation: Boolean;
begin
  LInfo := @modelstates[AIndex];

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
    else if LInfo.transparency < 0.9999 then
    begin
      gld_StaticLightAlpha(ASprite.light, LInfo.transparency);
      glAlphaFunc(GL_GEQUAL, 0.01);
      LRestoreBlend := True;
    end
    else
      gld_StaticLight(ASprite.light);
  end;

  last_gltexture := nil;
  if LInfo.texture >= 0 then
  begin
    LTexture := @modeltexturemanager.items[LInfo.texture];
    if LTexture.tex = 0 then
    begin
      LTexture.tex := gld_LoadExternalTexture(string(LTexture.name), True, GL_REPEAT);
      if LTexture.tex = 0 then
        I_DevError('gld_DrawModel(): Can not load texture %s'#13#10, [LTexture.name]);
    end;

    glBindTexture(GL_TEXTURE_2D, LTexture.tex);
  end
  else
    glBindTexture(GL_TEXTURE_2D, 0);

  LModelItem := @modelmanager.items[LInfo.modelidx];
  if LModelItem.model = nil then
  begin
    LModelItem.model :=
      TModel.Create(string(LModelItem.name), string(LModelItem.proc),
        LModelItem.xoffset, LModelItem.yoffset, LModelItem.zoffset,
        LModelItem.xscale, LModelItem.yscale, LModelItem.zscale,
        LModelItem.framemerge
      );
    if LModelItem.model = nil then
    begin
      I_Warning('gld_DrawModel(): Can not load model %s'#13#10, [LModelItem.name]);
      Exit;
    end;
    LModelItem.model.DrawSimple(LInfo.startframe);
    if LRestoreBlend then
      glAlphaFunc(GL_GEQUAL, 0.01);
    if LRestoreEquation then
      glBlendEquation(GL_FUNC_ADD);
    Exit;
  end;
{$IFDEF DEBUG}
  printf('**drawing model %d'#13#10, [AIndex]);
{$ENDIF}

  if LModelItem.model.modeltype in [mt_ddmodel, mt_dmx] then
  begin
    if isgamesuspended then
    begin
      LModelItem.model.DrawSimple(LModelItem.model.lastdrawframe);
    end
    else
    begin
      LNextFrame := FindNextFrame(ASprite.mo, LInfo.modelidx);
      LModelItem.model.Draw(LInfo.startframe, LNextFrame,
        1.0 - (ASprite.mo.tics - ticfrac / FRACUNIT) / ASprite.mo.state.tics);
    end;
  end
  else if gl_smoothmodelmovement and not isgamesuspended and
    ((ASprite.aproxdist < MODELINTERPOLATERANGE) or (LModelItem.model.modeltype = mt_dll)) then
  begin
    LNextFrame := FindNextFrame(ASprite.mo, LInfo.modelidx);
    LModelItem.model.Draw(LInfo.startframe, LNextFrame,
      1.0 - (ASprite.mo.tics - ticfrac / FRACUNIT) / ASprite.mo.state.tics);
  end
  else
    LModelItem.model.DrawSimple(LInfo.startframe);

  if LRestoreBlend then
    glAlphaFunc(GL_GEQUAL, 0.01);
  if LRestoreEquation then
    glBlendEquation(GL_FUNC_ADD);
end;

procedure TEngineGlSceneModelPainter.Draw(const ASprite: PGLSprite);
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

  for LIndex := 0 to ASprite.models.Count - 1 do
    DrawModel(ASprite, ASprite.models.Numbers[LIndex]);

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

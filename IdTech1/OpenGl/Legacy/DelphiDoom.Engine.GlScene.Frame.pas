//------------------------------------------------------------------------------
//
//  DelphiDoom: Engine - the start and the end of the 3D scene of a frame with OpenGL
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

unit DelphiDoom.Engine.GlScene.Frame;

interface

uses
  System.SysUtils,
  d_delphi,
  dglOpenGL,
  DelphiDoom.GlScene.DrawList,
  DelphiDoom.Engine.GlVSync,
  DelphiDoom.Engine.GlScene.FlatCollector,
  DelphiDoom.Engine.GlScene.WallCollector,
  DelphiDoom.Engine.GlScene.WallPainter,
  DelphiDoom.Engine.GlScene.SpritePainter,
  DelphiDoom.Engine.GlScene.LightPainter;

type
  /// <summary>
  ///   What the OpenGL renderer does at the two ends of the 3D scene of a frame: before it, the vertical sync,
  ///   the viewport and the scissor of the view window, the projection and the camera of the player, the
  ///   counters and the first frame of the collectors and painters; after it, the 2D mode, the weapon and the
  ///   status bar, the invulnerability and the damage tints (it was gld_StartDrawScene, gld_EndDrawScene and
  ///   infinitePerspective of gl_render.pas)
  /// </summary>
  /// <remarks>
  ///   A plain class, no interface and no virtual method: it is called twice per frame. It holds the camera of
  ///   the frame (angles, position, pitch), the frame counter and whether the scissor is on; the lists and
  ///   the painters are the ones of gl_render, given by the composition root and not owned
  /// </remarks>
  TEngineGlSceneFrame = class(TObject)
  strict private
    FDrawList: TGlSceneDrawList;
    FFlats: TEngineGlSceneFlatCollector;
    FWalls: TEngineGlSceneWallCollector;
    FWallPainter: TEngineGlSceneWallPainter;
    FSpritePainter: TEngineGlSceneSpritePainter;
    FLightPainter: TEngineGlSceneLightPainter;
    FVSync: TEngineGlVSync;
    FRoll: float;
    FYaw: float;
    FInvYaw: float;
    FPitch: float;
    FCameraX: float;
    FCameraY: float;
    FCameraZ: float;
    FRenderMarker: Byte;
    FScissorOn: Boolean;
    class procedure InfinitePerspective(AFovY: GLdouble; AAspect: GLdouble; ANearClip: GLdouble); static;
  public
    constructor Create(const ADrawList: TGlSceneDrawList; const AFlats: TEngineGlSceneFlatCollector;
      const AWalls: TEngineGlSceneWallCollector; const AWallPainter: TEngineGlSceneWallPainter;
      const ASpritePainter: TEngineGlSceneSpritePainter; const ALightPainter: TEngineGlSceneLightPainter;
      const AVSync: TEngineGlVSync);
    /// <summary>The state of OpenGL for the 3D scene of the frame of the player</summary>
    procedure Start;
    /// <summary>Back to the 2D screen: weapon, status bar and the tints over the scene</summary>
    procedure Finish;
    /// <summary>The pitch of the view of the frame in degrees, as the scene drawer needs it</summary>
    property Pitch: float read FPitch;
  end;

implementation

uses
  doomdef,
  doomstat,
  d_player,
  g_game,
  m_fixed,
  tables,
  r_main,
  r_draw,
  r_things,
  r_dynlights,
  {$IFDEF DOOM_OR_STRIFE}
  r_colormaps,
  {$ENDIF}
  v_video,
  gl_defs,
  gl_types,
  gl_tex,
  gl_render,
  DelphiDoom.Engine.Gl2dMode;

{ TEngineGlSceneFrame }

constructor TEngineGlSceneFrame.Create(const ADrawList: TGlSceneDrawList; const AFlats: TEngineGlSceneFlatCollector;
  const AWalls: TEngineGlSceneWallCollector; const AWallPainter: TEngineGlSceneWallPainter;
  const ASpritePainter: TEngineGlSceneSpritePainter; const ALightPainter: TEngineGlSceneLightPainter;
  const AVSync: TEngineGlVSync);
begin
  inherited Create;
  if not Assigned(ADrawList) then
    raise EArgumentNilException.Create('ADrawList');
  if not Assigned(AFlats) then
    raise EArgumentNilException.Create('AFlats');
  if not Assigned(AWalls) then
    raise EArgumentNilException.Create('AWalls');
  if not Assigned(AWallPainter) then
    raise EArgumentNilException.Create('AWallPainter');
  if not Assigned(ASpritePainter) then
    raise EArgumentNilException.Create('ASpritePainter');
  if not Assigned(ALightPainter) then
    raise EArgumentNilException.Create('ALightPainter');
  if not Assigned(AVSync) then
    raise EArgumentNilException.Create('AVSync');
  FDrawList := ADrawList;
  FFlats := AFlats;
  FWalls := AWalls;
  FWallPainter := AWallPainter;
  FSpritePainter := ASpritePainter;
  FLightPainter := ALightPainter;
  FVSync := AVSync;
end;

class procedure TEngineGlSceneFrame.InfinitePerspective(AFovY: GLdouble; AAspect: GLdouble; ANearClip: GLdouble);
var
  left, right, bottom, top: GLdouble;
  m: array[0..15] of GLdouble;
begin
  top := ANearClip * tan(AFovY * __glPi / 360.0);
  bottom := -top;
  left := bottom * AAspect;
  right := top * AAspect;

  m[ 0] := (2 * ANearClip) / (right - left);
  m[ 4] := 0;
  m[ 8] := (right + left) / (right - left);
  m[12] := 0;

  m[ 1] := 0;
  m[ 5] := (2 * ANearClip) / (top - bottom);
  m[ 9] := (top + bottom) / (top - bottom);
  m[13] := 0;

  m[ 2] := 0;
  m[ 6] := 0;
//  m[10] := - (zfar + znear) / (zfar - znear);
//  m[14] := - (2 * zfar * znear) / (zfar - znear);
  m[10] := -1;
  m[14] := -2 * ANearClip;

  m[ 3] := 0;
  m[ 7] := 0;
  m[11] := -1;
  m[15] := 0;

  glMultMatrixd(@m);
end;

procedure TEngineGlSceneFrame.Start;
var
  height: integer;
begin
  if gl_shared_texture_palette then
    glEnable(GL_SHARED_TEXTURE_PALETTE_EXT);
  gld_SetPalette(-1);

  FVSync.Update;

  if screenblocks > 10 then
    height := SCREENHEIGHT
  else if screenblocks = 10 then
    height := SCREENHEIGHT
  else
    height := (screenblocks * SCREENHEIGHT div 10) and not 7;

  glViewport(viewwindowx, SCREENHEIGHT - (height + viewwindowy - ((height - viewheight) div 2)), viewwidth, height);
  if screenblocks > 10 then
  begin
    glDisable(GL_SCISSOR_TEST);
    FScissorOn := false;
  end
  else
  begin
    glScissor(viewwindowx, SCREENHEIGHT - (viewheight + viewwindowy), viewwidth, viewheight);
    glEnable(GL_SCISSOR_TEST);
    FScissorOn := true;
  end;

  // Player coordinates
  FCameraX := -viewx / MAP_SCALE;
  FCameraY := viewy / MAP_SCALE;
  FCameraZ := viewz / MAP_SCALE;

  FYaw := 270.0 - (viewangle shr ANGLETOFINESHIFT) * 360.0 / FINEANGLES;
  FInvYaw := -90.0 + (viewangle shr ANGLETOFINESHIFT) * 360.0 / FINEANGLES;

  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT or GL_STENCIL_BUFFER_BIT);

  glShadeModel(GL_SMOOTH);

  glEnable(GL_DEPTH_TEST);

  glMatrixMode(GL_PROJECTION);
  glLoadIdentity;

  InfinitePerspective(64.0, 320.0 / 200.0 * monitor_relative_aspect, gl_nearclip / 100.0);

  if zaxisshift then
    FPitch := -TGameSession.Players[displayplayer].lookdir16 / 32 // JVAL Smooth Look Up/Down
  else
    FPitch := 0;
  // JVAL: Correct 2d bsp limitation
  if FPitch > 45 then
    FPitch := 45;

  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;

  glRotatef(FRoll,  0.0, 0.0, 1.0);
  glRotatef(FPitch, 1.0, 0.0, 0.0);
  glRotatef(FYaw,   0.0, 1.0, 0.0);
  glTranslatef(-FCameraX, -FCameraZ, -FCameraY);
  camera.rotation[0] := FPitch;
  camera.rotation[1] := FYaw;
  camera.rotation[2] := FRoll;
  camera.position[0] := FCameraX;
  camera.position[1] := FCameraZ;
  camera.position[2] := FCameraY;

  inc(FRenderMarker);
  FDrawList.BeginFrame(FRenderMarker);
  FFlats.BeginFrame(FRenderMarker);
  FWalls.BeginFrame(FRenderMarker, FYaw, FCameraZ);
  FWallPainter.BeginFrame(FCameraX, FCameraY, FCameraZ);
  FSpritePainter.BeginFrame(FInvYaw);
  FLightPainter.BeginFrame(FInvYaw);
  numdlitems := 0;

  if gl_renderwireframe then
  begin
    glClearColor(0.0, 0.0, 0.0, 0.0);
    glClear(GL_COLOR_BUFFER_BIT);
    glClearDepth(1.0);
    glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
  end
  else
    glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
end;

procedure TEngineGlSceneFrame.Finish;
var
  player: Pplayer_t;
begin
  player := @TGameSession.Players[displayplayer];

  glDisable(GL_POLYGON_SMOOTH);

  glViewport(0, 0, SCREENWIDTH, SCREENHEIGHT);
  TEngineGl2dMode.SetMode;

 // gld_AmbientExecute;

  R_DrawPlayer;

  if FScissorOn then
    glDisable(GL_SCISSOR_TEST);

  gld_DrawBackgroundFrame;

  if FScissorOn then
    glEnable(GL_SCISSOR_TEST);

  if player.fixedcolormap = 32 then
  begin
    glBlendFunc(GL_ONE_MINUS_DST_COLOR, GL_ZERO);
    glColor4f(1.0, 1.0, 1.0, 1.0);
    glBindTexture(GL_TEXTURE_2D, 0);
    last_gltexture := nil;
    last_cm := -1;
    glBegin(GL_TRIANGLE_STRIP);
      glVertex2f(0.0, 0.0);
      glVertex2f(0.0, SCREENHEIGHT);
      glVertex2f(SCREENWIDTH, 0.0);
      glVertex2f(SCREENWIDTH, SCREENHEIGHT);
    glEnd;
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    glDisable(GL_ALPHA_TEST);
    glColor4f(0.3, 0.3, 0.3, 0.3);
    glBindTexture(GL_TEXTURE_2D, 0);
    last_gltexture := nil;
    last_cm := -1;
    glBegin(GL_TRIANGLE_STRIP);
      glVertex2f(0.0, 0.0);
      glVertex2f(0.0, SCREENHEIGHT);
      glVertex2f(SCREENWIDTH, 0.0);
      glVertex2f(SCREENWIDTH, SCREENHEIGHT);
    glEnd;
    glEnable(GL_ALPHA_TEST);
  end;

  if gl_renderwireframe then
    glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);

  {$IFDEF DOOM_OR_STRIFE}
  if customcolormap <> nil then
  begin
    extra_red := extra_red + customcolormap.fog_r;
    if extra_red > 1.0 then
      extra_red := 1.0;
    extra_green := extra_green + customcolormap.fog_g;
    if extra_green > 1.0 then
      extra_green := 1.0;
    extra_blue := extra_blue + customcolormap.fog_b;
    if extra_blue > 1.0 then
      extra_blue := 1.0;
    extra_alpha := extra_alpha + 0.8;
    if extra_alpha > 1.0 then
      extra_alpha := 1.0;
  end;
  {$ENDIF}

  if extra_alpha > 0.0 then
  begin
    glDepthMask(False);
    glDisable(GL_TEXTURE_2D);
    glDisable(GL_ALPHA_TEST);
    glBlendFunc(GL_ONE, GL_ONE);

    glColor4f(extra_red * 0.25, extra_green * 0.25, extra_blue * 0.25, extra_alpha);
    glBindTexture(GL_TEXTURE_2D, 0);
    last_gltexture := nil;
    last_cm := -1;
    glBegin(GL_TRIANGLE_STRIP);
      glVertex2f(0.0, 0.0);
      glVertex2f(0.0, SCREENHEIGHT);
      glVertex2f(SCREENWIDTH, 0.0);
      glVertex2f(SCREENWIDTH, SCREENHEIGHT);
    glEnd;

    glDepthMask(True);
    glEnable(GL_TEXTURE_2D);
    glEnable(GL_ALPHA_TEST);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

  end;

  glColor3f(1.0, 1.0, 1.0);
  glDisable(GL_SCISSOR_TEST);
  FScissorOn := false;
  if gl_shared_texture_palette then
    glDisable(GL_SHARED_TEXTURE_PALETTE_EXT);
end;

end.

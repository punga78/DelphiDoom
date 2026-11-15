//------------------------------------------------------------------------------
//
//  DelphiDoom: Engine - draws the scene of a frame with OpenGL
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

unit DelphiDoom.Engine.GlScene.SceneDrawer;

interface

uses
  System.SysUtils,
  d_delphi,
  dglOpenGL,
  DelphiDoom.GlScene.DrawList,
  DelphiDoom.Engine.GlScene.WallCollector,
  DelphiDoom.Engine.GlScene.WallPainter,
  DelphiDoom.Engine.GlScene.FlatPainter,
  DelphiDoom.Engine.GlScene.SpritePainter;

type
  /// <summary>
  ///   Draws the draw list of a frame in the order of the old gld_DrawScene of gl_render.pas: the sky, the
  ///   flats, the walls, the sprites (the nearer last), the blended walls, the dynamic lights and the sky
  ///   through the stencil. It does not draw anything itself: it walks the runs of the list and gives every
  ///   wall, flat and sprite to its painter
  /// </summary>
  /// <remarks>
  ///   A plain class, no interface and no virtual method: the painters are called directly, once per wall,
  ///   flat and sprite. It does not own the list, the collector or the painters (gl_render does)
  /// </remarks>
  TEngineGlSceneDrawer = class(TObject)
  strict private
    FDrawList: TGlSceneDrawList;
    FWalls: TEngineGlSceneWallCollector;
    FWallPainter: TEngineGlSceneWallPainter;
    FFlatPainter: TEngineGlSceneFlatPainter;
    FSpritePainter: TEngineGlSceneSpritePainter;
    {$IFDEF DEBUG}
    FRenderedVisplanes: Integer;
    FRenderedSegs: Integer;
    FRenderedVissprites: Integer;
    {$ENDIF}
    procedure DrawWalls(const AWallRange: Integer; const ABlend: Boolean);
    procedure DrawSkyThroughStencil(const APitch: float);
  public
    /// <param name="ADrawList">The list of the frame; not owned</param>
    /// <param name="AWalls">Tells if a wall of sky was met in the frame; not owned</param>
    /// <exception cref="EArgumentNilException">A dependency is nil</exception>
    constructor Create(const ADrawList: TGlSceneDrawList; const AWalls: TEngineGlSceneWallCollector;
      const AWallPainter: TEngineGlSceneWallPainter; const AFlatPainter: TEngineGlSceneFlatPainter;
      const ASpritePainter: TEngineGlSceneSpritePainter);
    /// <summary>Draws the scene; APitch is the pitch of the view in degrees</summary>
    procedure Draw(const APitch: float);
  end;

implementation

uses
  doomdef,
  doomstat,
  m_fixed,
  gl_defs,
  gl_types,
  gl_lightmaps,
  gl_sky,
  gl_render,
  r_dynlights,
  DelphiDoom.GlScene.Types,
  DelphiDoom.Engine.GlScene.Types;

{ TEngineGlSceneDrawer }

constructor TEngineGlSceneDrawer.Create(const ADrawList: TGlSceneDrawList;
  const AWalls: TEngineGlSceneWallCollector; const AWallPainter: TEngineGlSceneWallPainter;
  const AFlatPainter: TEngineGlSceneFlatPainter; const ASpritePainter: TEngineGlSceneSpritePainter);
begin
  inherited Create;
  if not Assigned(ADrawList) then
    raise EArgumentNilException.Create('ADrawList');
  if not Assigned(AWalls) then
    raise EArgumentNilException.Create('AWalls');
  if not Assigned(AWallPainter) then
    raise EArgumentNilException.Create('AWallPainter');
  if not Assigned(AFlatPainter) then
    raise EArgumentNilException.Create('AFlatPainter');
  if not Assigned(ASpritePainter) then
    raise EArgumentNilException.Create('ASpritePainter');
  FDrawList := ADrawList;
  FWalls := AWalls;
  FWallPainter := AWallPainter;
  FFlatPainter := AFlatPainter;
  FSpritePainter := ASpritePainter;
end;

procedure TEngineGlSceneDrawer.DrawWalls(const AWallRange: Integer; const ABlend: Boolean);
var
  LRunIndex, LWallIndex, LKind, LCount: Integer;
  LRun: PGlSceneRun;
  LWallArray: PGLWallArray;
begin
  // the blocks do not move while the frame is drawn
  LWallArray := FDrawList.Walls;
  for LRunIndex := FDrawList.LastRun downto 0 do
  begin
    LRun := @FDrawList.Runs[LRunIndex];
    if LRun.Kind = gskWall then
    begin
      LCount := 0;
      for LKind := GLDWF_TOP to AWallRange do
      begin
        if LCount >= LRun.Count then
          Continue;
        if gl_drawsky and (LKind >= GLDWF_SKY) then
        begin
          gld_PauseLightmap;
          if gl_shared_texture_palette then
            glDisable(GL_SHARED_TEXTURE_PALETTE_EXT);
          glEnable(GL_TEXTURE_GEN_S);
          glEnable(GL_TEXTURE_GEN_T);
          glEnable(GL_TEXTURE_GEN_Q);
          glDisable(GL_FOG);
          glColor4fv(@gl_whitecolor);
        end;
        for LWallIndex := LRun.Count - 1 downto 0 do
          if LWallArray[LWallIndex + LRun.First].flag = LKind then
          begin
            {$IFDEF DEBUG}
            Inc(FRenderedSegs);
            {$ENDIF}
            Inc(LCount);
            FWallPainter.Draw(@LWallArray[LWallIndex + LRun.First], ABlend);
          end;
        if gl_drawsky and (LKind >= GLDWF_SKY) then
        begin
          gld_ResumeLightmap;
          gld_StartFog;
          glDisable(GL_TEXTURE_GEN_Q);
          glDisable(GL_TEXTURE_GEN_T);
          glDisable(GL_TEXTURE_GEN_S);
          if gl_shared_texture_palette then
            glEnable(GL_SHARED_TEXTURE_PALETTE_EXT);
        end;
      end;
    end;
  end;
end;

// The sky is drawn where the stencil buffer was set by the walls of sky
procedure TEngineGlSceneDrawer.DrawSkyThroughStencil(const APitch: float);
var
  LWallIndex: Integer;
  LWall: PGLWall;
  LSeg: PGLSeg;
  LWallArray: PGLWallArray;
begin
  LWallArray := FDrawList.Walls;
  glClear(GL_STENCIL_BUFFER_BIT); // Clear the stencil buffer the first time
  glEnable(GL_STENCIL_TEST);      // Turn on the stencil buffer test
  glDisable(GL_TEXTURE_2D);
  glColor4f(1.0, 1.0, 1.0, 1.0);
  glStencilFunc(GL_ALWAYS, 1, 1); // Setup the stencil buffer to write
  glStencilOp(GL_KEEP, GL_KEEP, GL_REPLACE);  // a 1 everywhere the plane is.

  for LWallIndex := 0 to FDrawList.WallCount - 1 do
    if LWallArray[LWallIndex].flag >= GLDWF_SKY then
    begin
      LWall := @LWallArray[LWallIndex];
      LSeg := LWall.glseg;
      glBegin(GL_TRIANGLE_STRIP);
        glVertex3f(LSeg.x1, LWall.ytop, LSeg.z1);
        glVertex3f(LSeg.x1, LWall.ybottom, LSeg.z1);
        glVertex3f(LSeg.x2, LWall.ytop, LSeg.z2);
        glVertex3f(LSeg.x2, LWall.ybottom, LSeg.z2);
      glEnd;
    end;

  glStencilFunc(GL_EQUAL, 1, 1);          // Set the stencil buffer to update
  glStencilOp(GL_KEEP, GL_KEEP, GL_INCR); // only where it finds a 1 from the plane and increment the buffer

  glEnable(GL_TEXTURE_2D);

  glDisable(GL_DEPTH_TEST);
  if APitch <= -35.0 then
    gld_DrawSky(True, False)
  else if APitch >= 35.0 then
    gld_DrawSky(False, True)
  else
    gld_DrawSky(True, True);

  glEnable(GL_DEPTH_TEST);
  glDisable(GL_STENCIL_TEST); // Turn off the stencil buffer test
end;

procedure TEngineGlSceneDrawer.Draw(const APitch: float);
var
  LRunIndex, LItemIndex, LBestIndex: Integer;
  LMaxScale: fixed_t;
  LWallRange: Integer;
  LRun: PGlSceneRun;
  LFlatArray: PGLFlatArray;
  LSpriteArray: PGLSpriteArray;
begin
  // the blocks do not move while the frame is drawn
  LFlatArray := FDrawList.Flats;
  LSpriteArray := FDrawList.Sprites;

  if zaxisshift then
  begin
    LWallRange := GLDWF_BOTFLUD;
    if not gl_stencilsky and FWalls.SkyMet then
    begin
      if APitch <= -35.0 then
        gld_DrawSky(True, False)
      else if APitch >= 35.0 then
        gld_DrawSky(False, True)
      else
        gld_DrawSky(True, True);
    end;
  end
  else
    LWallRange := GLDWF_SKYFLIP;

  // Sort the dynamic lights
  gld_SortDlights;

  gl_uselightmaps := gl_uselightmaps and canuselightmaps;

  if gl_uselightmaps then
    gld_ActivateLightmap;

  glEnableClientState(GL_VERTEX_ARRAY);
  glEnableClientState(GL_TEXTURE_COORD_ARRAY);

  gld_StartFog;

  {$IFDEF DEBUG}
  FRenderedVisplanes := 0;
  FRenderedSegs := 0;
  FRenderedVissprites := 0;
  {$ENDIF}

  glTexCoordPointer(2, GL_FLOAT, 0, gld_texcoords);
  glVertexPointer(3, GL_FLOAT, 0, gld_vertexes);

  // Floors and ceilings
  glDisable(GL_BLEND);
  for LRunIndex := FDrawList.LastRun downto 0 do
  begin
    LRun := @FDrawList.Runs[LRunIndex];
    if LRun.Kind = gskFlat then
    begin
      {$IFDEF DEBUG}
      FRenderedVisplanes := FRenderedVisplanes + LRun.Count;
      {$ENDIF}
      for LItemIndex := LRun.Count - 1 downto 0 do
        FFlatPainter.Draw(@LFlatArray[LItemIndex + LRun.First]);
    end;
  end;
  glEnable(GL_BLEND);

  DrawWalls(LWallRange, False);

  // Walls
  // Sprites
  if FDrawList.SpriteCount > 100 then
  begin
    for LRunIndex := 0 to FDrawList.SpriteCount - 1 do
    begin
      {$IFDEF DEBUG}
      Inc(FRenderedVissprites);
      {$ENDIF}
      FSpritePainter.Draw(@LSpriteArray[LRunIndex]);
    end;
  end
  else for LRunIndex := FDrawList.LastRun downto 0 do
  begin
    LRun := @FDrawList.Runs[LRunIndex];
    if LRun.Kind = gskSprite then
    begin
      repeat
        LMaxScale := MAXINT;
        LBestIndex := -1;
        for LItemIndex := LRun.Count - 1 downto 0 do
          if LSpriteArray[LItemIndex + LRun.First].scale < LMaxScale then
          begin
            LMaxScale := LSpriteArray[LItemIndex + LRun.First].scale;
            LBestIndex := LItemIndex + LRun.First;
          end;
        if LBestIndex >= 0 then
        begin
          {$IFDEF DEBUG}
          Inc(FRenderedVissprites);
          {$ENDIF}
          FSpritePainter.Draw(@LSpriteArray[LBestIndex]);
          LSpriteArray[LBestIndex].scale := MAXINT;
        end;
      until LMaxScale = MAXINT;
    end;
  end;

  DrawWalls(GLDWF_BOTFLUD, True);

  if gl_uselightmaps then
    gld_DeActivateLightmap;

  glDisable(GL_FOG);

  gld_DrawDLights;

  glDisableClientState(GL_TEXTURE_COORD_ARRAY);
  glDisableClientState(GL_VERTEX_ARRAY);

  if zaxisshift then
  begin
    if gl_drawsky and FWalls.SkyMet then
    begin
      if gl_stencilsky then
        DrawSkyThroughStencil(APitch);
    end;
  end;

  {$IFDEF DEBUG}
  printf('rendered_visplanes := %d'#13#10'rendered_segs := %d'#13#10'rendered_vissprites := %d'#13#10#13#10,
        [FRenderedVisplanes, FRenderedSegs, FRenderedVissprites]);
  {$ENDIF}
end;

end.

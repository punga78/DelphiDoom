//------------------------------------------------------------------------------
//
//  DelphiDoom: Engine - draws the walls of a frame of the OpenGL scene
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

unit DelphiDoom.Engine.GlScene.WallPainter;

interface

uses
  System.SysUtils,
  d_delphi,
  dglOpenGL,
  gl_defs,
  gl_types,
  DelphiDoom.Engine.GlScene.Types;

type
  /// <summary>
  ///   Draws one wall of the draw list with OpenGL: textured walls with their double light, the walls of
  ///   sloped sectors, sky and the gaps flooded through the stencil (it was gld_DrawWall and the flood
  ///   helpers of gl_render.pas): the same OpenGL calls, in the same order, with the same numbers
  /// </summary>
  /// <remarks>
  ///   A plain class called directly (once per wall of every frame), never through an interface and with no
  ///   virtual method. The state OpenGL keeps (the bound texture, the fog, the light) stays where it was: in
  ///   gl_tex and gl_render, which the painter calls like the old procedure did. The only thing the class
  ///   holds is the position of the camera of the frame, that gld_StartDrawScene gives it
  /// </remarks>
  TEngineGlSceneWallPainter = class(TObject)
  strict private
    type
      TStripCoords = record
        v: array[0..3] of array[0..2] of GLfloat;
        t: array[0..3] of array[0..1] of GLfloat;
      end;
      PStripCoords = ^TStripCoords;
  strict private
    FCameraX: float;
    FCameraY: float;
    FCameraZ: float;
    // the polygon of a sloped wall, filled by AddCoord and AddPosition
    FPoints: array[0..3] of GLVertexUV;
    FPointCount: Integer;
    FDidWhiteFog: Boolean;
    procedure AddCoord(const AU, AV: float);
    procedure AddPosition(const AX, AY, AZ: float);
    procedure RenderSimple;
    procedure Render(const AWall: PGLWall);
    procedure WhiteFogFirst(const AWall: PGLWall);
    procedure WhiteFogSecond(const AWall: PGLWall);
    procedure WhiteFogStop;
    class procedure SetupFloodStencil(const AWall: PGLWall); static;
    class procedure ClearFloodStencil(const AWall: PGLWall); static;
    procedure SetupFloodedPlaneCoords(const AWall: PGLWall; const ACoords: PStripCoords);
    class procedure SetupFloodedPlaneLight(const AWall: PGLWall); static;
    class procedure DrawTriangleStrip(const ACoords: PStripCoords); static;
  public
    /// <summary>A new frame: the position of the camera in OpenGL units</summary>
    procedure BeginFrame(const ACameraX, ACameraY, ACameraZ: float);
    /// <summary>Draws the wall if it belongs to the pass (blended or not)</summary>
    procedure Draw(const AWall: PGLWall; const ABlend: Boolean);
  end;

implementation

uses
  r_defs,
  r_main,
  gl_render,
  DelphiDoom.Engine.GlScene.Fog,
  gl_slopes,
  gl_tex;

{ TEngineGlSceneWallPainter }

procedure TEngineGlSceneWallPainter.BeginFrame(const ACameraX, ACameraY, ACameraZ: float);
begin
  FCameraX := ACameraX;
  FCameraY := ACameraY;
  FCameraZ := ACameraZ;
end;

procedure TEngineGlSceneWallPainter.AddCoord(const AU, AV: float);
begin
  FPoints[FPointCount].u := AU;
  FPoints[FPointCount].v := AV;
end;

procedure TEngineGlSceneWallPainter.AddPosition(const AX, AY, AZ: float);
begin
  FPoints[FPointCount].x := AX;
  FPoints[FPointCount].y := AY;
  FPoints[FPointCount].z := AZ;
end;

procedure TEngineGlSceneWallPainter.RenderSimple;
var
  LIndex: Integer;
begin
  if FPointCount < 3 then
    Exit;

  glBegin(GL_TRIANGLE_STRIP);
    for LIndex := 0 to FPointCount - 1 do
    begin
      glTexCoord2f(FPoints[LIndex].u, FPoints[LIndex].v);
      glVertex3f(FPoints[LIndex].x, FPoints[LIndex].y, FPoints[LIndex].z);
    end;
  glEnd;
end;

procedure TEngineGlSceneWallPainter.Render(const AWall: PGLWall);
var
  LIndex: Integer;
  LTextureHeight: float;
  LMiddleV: float;
  LSeg: PGLSeg;
begin
  if (FPointCount < 4) or not AWall.doublelight then
  begin
    RenderSimple;
    Exit;
  end;

  if (AWall.ymid <= FPoints[0].y) and
     (AWall.ymid >= FPoints[1].y) and
     (AWall.ymid <= FPoints[2].y) and
     (AWall.ymid >= FPoints[3].y) then
  begin
    LSeg := AWall.glseg;
    LTextureHeight := AWall.gltexture.buffer_height / MAP_COEFF;
    LMiddleV := AWall.vt + (AWall.ytop - AWall.ymid) / LTextureHeight;

    glBegin(GL_TRIANGLE_STRIP);
      glTexCoord2f(FPoints[0].u, FPoints[0].v);
      glVertex3f(FPoints[0].x, FPoints[0].y, FPoints[0].z);
      glTexCoord2f(FPoints[1].u, LMiddleV);
      glVertex3f(FPoints[1].x, AWall.ymid, FPoints[1].z);
      glTexCoord2f(FPoints[2].u, FPoints[2].v);
      glVertex3f(FPoints[2].x, FPoints[2].y, FPoints[2].z);
      glTexCoord2f(FPoints[3].u, LMiddleV);
      glVertex3f(FPoints[3].x, AWall.ymid, FPoints[3].z);
    glEnd;

    gld_StaticLightAlpha(AWall.light2, AWall.alpha);

    glBegin(GL_TRIANGLE_STRIP);
      glTexCoord2f(FPoints[0].u, LMiddleV);
      glVertex3f(FPoints[0].x, AWall.ymid, FPoints[0].z);
      glTexCoord2f(FPoints[1].u, FPoints[1].v);
      glVertex3f(FPoints[1].x, FPoints[1].y, FPoints[1].z);
      glTexCoord2f(FPoints[2].u, LMiddleV);
      glVertex3f(FPoints[2].x, AWall.ymid, FPoints[2].z);
      glTexCoord2f(FPoints[3].u, FPoints[3].v);
      glVertex3f(FPoints[3].x, FPoints[3].y, FPoints[3].z);

      glTexCoord2f(AWall.ul, LMiddleV);
      glVertex3f(LSeg.x1, AWall.ymid, LSeg.z1);
      glTexCoord2f(AWall.ul, AWall.vb);
      glVertex3f(LSeg.x1, AWall.ybottom, LSeg.z1);
      glTexCoord2f(AWall.ur, LMiddleV);
      glVertex3f(LSeg.x2, AWall.ymid, LSeg.z2);
      glTexCoord2f(AWall.ur, AWall.vb);
      glVertex3f(LSeg.x2, AWall.ybottom, LSeg.z2);
    glEnd;
  end
  else
  begin
    glBegin(GL_TRIANGLE_STRIP);
      for LIndex := 0 to FPointCount - 1 do
      begin
        glTexCoord2f(FPoints[LIndex].u, FPoints[LIndex].v);
        glVertex3f(FPoints[LIndex].x, FPoints[LIndex].y, FPoints[LIndex].z);
      end;
    glEnd;
  end;
end;

// JVAL: Mars fog sectors
procedure TEngineGlSceneWallPainter.WhiteFogFirst(const AWall: PGLWall);
begin
  if AWall.whitefog then
  begin
    TEngineGlSceneFog.StartWhite;
    FDidWhiteFog := True;
  end;
end;

procedure TEngineGlSceneWallPainter.WhiteFogSecond(const AWall: PGLWall);
begin
  if AWall.whitefog2 then
  begin
    TEngineGlSceneFog.StartWhite;
    FDidWhiteFog := True;
  end;
end;

procedure TEngineGlSceneWallPainter.WhiteFogStop;
begin
  if FDidWhiteFog then
  begin
    TEngineGlSceneFog.Start;
    FDidWhiteFog := False;
  end;
end;

// Flood gaps with the back side's ceiling/floor texture. This requires a stencil because the projected
// plane interferes with the depth buffer
class procedure TEngineGlSceneWallPainter.SetupFloodStencil(const AWall: PGLWall);
const
  RECURSION = 0;
begin
  // Create stencil
  glStencilFunc(GL_EQUAL, RECURSION, $FFFFFFFF);  // create stencil
  glStencilOp(GL_KEEP, GL_KEEP, GL_INCR); // increment stencil of valid pixels
  glColorMask(False, False, False, False); // don't write to the graphics buffer
  glDisable(GL_TEXTURE_2D);
  glColor3f(1, 1, 1);
  glEnable(GL_DEPTH_TEST);
  glDepthMask(True);

  glBegin(GL_TRIANGLE_FAN);
    glVertex3f(AWall.glseg.x1, AWall.ytop, AWall.glseg.z1);
    glVertex3f(AWall.glseg.x1, AWall.ybottom, AWall.glseg.z1);
    glVertex3f(AWall.glseg.x2, AWall.ybottom, AWall.glseg.z2);
    glVertex3f(AWall.glseg.x2, AWall.ytop, AWall.glseg.z2);
  glEnd();

  glStencilFunc(GL_EQUAL, RECURSION + 1, $FFFFFFFF); // draw sky into stencil
  glStencilOp(GL_KEEP, GL_KEEP, GL_KEEP);   // this stage doesn't modify the stencil

  glColorMask(True, True, True, True); // don't write to the graphics buffer
  glEnable(GL_TEXTURE_2D);
  glDepthMask(False);
end;

class procedure TEngineGlSceneWallPainter.ClearFloodStencil(const AWall: PGLWall);
const
  RECURSION = 0;
begin
  glStencilOp(GL_KEEP, GL_KEEP, GL_DECR);
  glDisable(GL_TEXTURE_2D);
  glColorMask(False, False, False, False); // don't write to the graphics buffer
  glColor3f(1, 1, 1);

  glBegin(GL_TRIANGLE_FAN);
    glVertex3f(AWall.glseg.x1, AWall.ytop, AWall.glseg.z1);
    glVertex3f(AWall.glseg.x1, AWall.ybottom, AWall.glseg.z1);
    glVertex3f(AWall.glseg.x2, AWall.ybottom, AWall.glseg.z2);
    glVertex3f(AWall.glseg.x2, AWall.ytop, AWall.glseg.z2);
  glEnd();

  // restore old stencil op.
  glStencilOp(GL_KEEP, GL_KEEP, GL_KEEP);
  glStencilFunc(GL_EQUAL, RECURSION, $FFFFFFFF);
  glEnable(GL_TEXTURE_2D);
  glColorMask(True, True, True, True);
  glEnable(GL_DEPTH_TEST);
  glDepthMask(True);
end;

// Calculation of the coordinates of the gap
procedure TEngineGlSceneWallPainter.SetupFloodedPlaneCoords(const AWall: PGLWall;
  const ACoords: PStripCoords);
var
  LProjection1, LProjection2: float;
  LK: float;
  LTop, LBottom, LPlaneZ: float;
begin
  if AWall.flag = GLDWF_TOPFLUD then
  begin
    LTop := AWall.ybottom;
    LBottom := AWall.ytop;
    LPlaneZ := AWall.ybottom;
  end
  else
  begin
    LTop := AWall.ytop;
    LBottom := AWall.ybottom;
    LPlaneZ := AWall.ytop;
  end;

  LProjection1 := (LTop - FCameraZ) / (LTop - FCameraZ);
  LProjection2 := (LTop - FCameraZ) / (LBottom - FCameraZ);

  ACoords.v[0][0] := FCameraX + LProjection1 * (AWall.glseg.x1 - FCameraX);
  ACoords.v[0][1] := LPlaneZ;
  ACoords.v[0][2] := FCameraY + LProjection1 * (AWall.glseg.z1 - FCameraY);

  ACoords.v[1][0] := FCameraX + LProjection2 * (AWall.glseg.x1 - FCameraX);
  ACoords.v[1][1] := LPlaneZ;
  ACoords.v[1][2] := FCameraY + LProjection2 * (AWall.glseg.z1 - FCameraY);

  ACoords.v[2][0] := FCameraX + LProjection1 * (AWall.glseg.x2 - FCameraX);
  ACoords.v[2][1] := LPlaneZ;
  ACoords.v[2][2] := FCameraY + LProjection1 * (AWall.glseg.z2 - FCameraY);

  ACoords.v[3][0] := FCameraX + LProjection2 * (AWall.glseg.x2 - FCameraX);
  ACoords.v[3][1] := LPlaneZ;
  ACoords.v[3][2] := FCameraY + LProjection2 * (AWall.glseg.z2 - FCameraY);

  LK := 0.5;

  ACoords.t[0][0] := -ACoords.v[0][0] / LK;
  ACoords.t[0][1] := -ACoords.v[0][2] / LK;

  ACoords.t[1][0] := -ACoords.v[1][0] / LK;
  ACoords.t[1][1] := -ACoords.v[1][2] / LK;

  ACoords.t[2][0] := -ACoords.v[2][0] / LK;
  ACoords.t[2][1] := -ACoords.v[2][2] / LK;

  ACoords.t[3][0] := -ACoords.v[3][0] / LK;
  ACoords.t[3][1] := -ACoords.v[3][2] / LK;
end;

class procedure TEngineGlSceneWallPainter.SetupFloodedPlaneLight(const AWall: PGLWall);
var
  LLight: float;
begin
  if AWall.glseg.backsector <> nil then
  begin
    LLight := gld_CalcLightLevel(AWall.glseg.backsector.lightlevel + (extralight shr 5));
    gld_StaticLightAlpha(LLight, AWall.alpha);
  end
  else
    gld_StaticLightAlpha(AWall.light, AWall.alpha);
end;

class procedure TEngineGlSceneWallPainter.DrawTriangleStrip(const ACoords: PStripCoords);
begin
  glBegin(GL_TRIANGLE_STRIP);
    glTexCoord2f(ACoords.t[0][0], ACoords.t[0][1]);
    glVertex3f(ACoords.v[0][0], ACoords.v[0][1], ACoords.v[0][2]);
    glTexCoord2f(ACoords.t[1][0], ACoords.t[1][1]);
    glVertex3f(ACoords.v[1][0], ACoords.v[1][1], ACoords.v[1][2]);
    glTexCoord2f(ACoords.t[2][0], ACoords.t[2][1]);
    glVertex3f(ACoords.v[2][0], ACoords.v[2][1], ACoords.v[2][2]);
    glTexCoord2f(ACoords.t[3][0], ACoords.t[3][1]);
    glVertex3f(ACoords.v[3][0], ACoords.v[3][1], ACoords.v[3][2]);
  glEnd();
end;

procedure TEngineGlSceneWallPainter.Draw(const AWall: PGLWall; const ABlend: Boolean);
var
  LSeg: PGLSeg;
  LFloorHeight: float;
  LCeilingHeight: float;
  LTextureHeight: float;
  LFrontSlope: Boolean;
  LBackSlope: Boolean;
  LMiddleV: float;
  LCoords: TStripCoords;
begin
  if not gl_drawsky and (AWall.flag >= GLDWF_SKY) then
    Exit;

  if AWall.gltexture.index = 0 then
    Exit;

  if AWall.blend <> ABlend then
    Exit;

  FDidWhiteFog := False;

  if (AWall.flag = GLDWF_TOPFLUD) or (AWall.flag = GLDWF_BOTFLUD) then
  begin
    gld_BindFlat(AWall.gltexture, -1);

    SetupFloodStencil(AWall);
    SetupFloodedPlaneCoords(AWall, @LCoords);
    SetupFloodedPlaneLight(AWall);
    WhiteFogFirst(AWall); // JVAL: Mars fog sectors
    DrawTriangleStrip(@LCoords);
    WhiteFogStop; // JVAL: Mars fog sectors
    ClearFloodStencil(AWall);

    Exit;
  end;

  gld_BindTexture(AWall.gltexture);
  if AWall.flag >= GLDWF_SKY then
  begin
    glMatrixMode(GL_TEXTURE);
    glPushMatrix;
    if AWall.flag = GLDWF_SKYFLIP then
      glScalef(-128.0 * AWall.gltexture.inv_buffer_width, 200.0 / 320.0 * 2.0, 1.0)
    else
      glScalef(128.0 * AWall.gltexture.inv_buffer_width, 200.0 / 320.0 * 2.0, 1.0);
    glTranslatef(AWall.skyyaw, AWall.skyymid, 0.0);

    LSeg := AWall.glseg;

    glBegin(GL_TRIANGLE_STRIP);
      glVertex3f(LSeg.x1, AWall.ytop, LSeg.z1);
      glVertex3f(LSeg.x1, AWall.ybottom, LSeg.z1);
      glVertex3f(LSeg.x2, AWall.ytop, LSeg.z2);
      glVertex3f(LSeg.x2, AWall.ybottom, LSeg.z2);
    glEnd;

    glPopMatrix;
    glMatrixMode(GL_MODELVIEW);
  end
  else
  begin
    gld_StaticLightAlpha(AWall.light, AWall.alpha);
    LSeg := AWall.glseg;

    if AWall.blend then
      glDepthMask(False)
    else
      glDisable(GL_BLEND);

    LFrontSlope := LSeg.frontsector.renderflags and SRF_SLOPED <> 0;
    if LSeg.backsector = nil then
      LBackSlope := False
    else
      LBackSlope := LSeg.backsector.renderflags and SRF_SLOPED <> 0;

    if LFrontSlope and (AWall.flag = GLDWF_M1S) then
    begin
      LTextureHeight := AWall.gltexture.buffer_height / MAP_COEFF;

      FPointCount := 0;

      LFloorHeight := gld_FloorHeight(LSeg.frontsector, LSeg.x1, LSeg.z1);
      LCeilingHeight := gld_CeilingHeight(LSeg.frontsector, LSeg.x1, LSeg.z1);

      if LCeilingHeight - LFloorHeight > GLEPSILON then
      begin
        AddCoord(AWall.ul, AWall.vt + (AWall.ytop - LCeilingHeight) / LTextureHeight);
        AddPosition(LSeg.x1, LCeilingHeight, LSeg.z1);
        Inc(FPointCount);
      end;

      AddCoord(AWall.ul, AWall.vt + (AWall.ytop - LFloorHeight) / LTextureHeight);
      AddPosition(LSeg.x1, LFloorHeight, LSeg.z1);
      Inc(FPointCount);

      LFloorHeight := gld_FloorHeight(LSeg.frontsector, LSeg.x2, LSeg.z2);
      LCeilingHeight := gld_CeilingHeight(LSeg.frontsector, LSeg.x2, LSeg.z2);

      if LCeilingHeight - LFloorHeight > GLEPSILON then
      begin
        AddCoord(AWall.ur, AWall.vt + (AWall.ytop - LCeilingHeight) / LTextureHeight);
        AddPosition(LSeg.x2, LCeilingHeight, LSeg.z2);
        Inc(FPointCount);
      end;

      AddCoord(AWall.ur, AWall.vt + (AWall.ytop - LFloorHeight) / LTextureHeight);
      AddPosition(LSeg.x2, LFloorHeight, LSeg.z2);
      Inc(FPointCount);

      WhiteFogFirst(AWall); // JVAL: Mars fog sectors
      Render(AWall);
      WhiteFogStop; // JVAL: Mars fog sectors
    end
    else if (LFrontSlope or LBackSlope) and (AWall.flag = GLDWF_BOT) then
    begin
      LTextureHeight := AWall.gltexture.buffer_height / MAP_COEFF;

      FPointCount := 0;

      LFloorHeight := gld_FloorHeight(LSeg.frontsector, LSeg.x1, LSeg.z1);
      LCeilingHeight := gld_FloorHeight(LSeg.backsector, LSeg.x1, LSeg.z1);

      if LCeilingHeight - LFloorHeight > GLEPSILON then
      begin
        AddCoord(AWall.ul, AWall.vt + (AWall.ytop - LCeilingHeight) / LTextureHeight);
        AddPosition(LSeg.x1, LCeilingHeight, LSeg.z1);
        Inc(FPointCount);
      end;

      AddCoord(AWall.ul, AWall.vt + (AWall.ytop - LFloorHeight) / LTextureHeight);
      AddPosition(LSeg.x1, LFloorHeight, LSeg.z1);
      Inc(FPointCount);

      LFloorHeight := gld_FloorHeight(LSeg.frontsector, LSeg.x2, LSeg.z2);
      LCeilingHeight := gld_FloorHeight(LSeg.backsector, LSeg.x2, LSeg.z2);

      if LCeilingHeight - LFloorHeight > GLEPSILON then
      begin
        AddCoord(AWall.ur, AWall.vt + (AWall.ytop - LCeilingHeight) / LTextureHeight);
        AddPosition(LSeg.x2, LCeilingHeight, LSeg.z2);
        Inc(FPointCount);
      end;

      AddCoord(AWall.ur, AWall.vt + (AWall.ytop - LFloorHeight) / LTextureHeight);
      AddPosition(LSeg.x2, LFloorHeight, LSeg.z2);
      Inc(FPointCount);

      WhiteFogFirst(AWall); // JVAL: Mars fog sectors
      Render(AWall);
      WhiteFogStop; // JVAL: Mars fog sectors
    end
    else if (LFrontSlope or LBackSlope) and (AWall.flag = GLDWF_TOP) then
    begin
      LTextureHeight := AWall.gltexture.buffer_height / MAP_COEFF;

      WhiteFogFirst(AWall); // JVAL: Mars fog sectors
      glBegin(GL_TRIANGLE_STRIP);
        LFloorHeight := gld_CeilingHeight(LSeg.frontsector, LSeg.x1, LSeg.z1);
        LCeilingHeight := gld_CeilingHeight(LSeg.backsector, LSeg.x1, LSeg.z1);

        glTexCoord2f(AWall.ul, AWall.vt + (AWall.ytop - LCeilingHeight) / LTextureHeight);
        glVertex3f(LSeg.x1, LCeilingHeight, LSeg.z1);
        glTexCoord2f(AWall.ul, AWall.vt + (AWall.ytop - LFloorHeight) / LTextureHeight);
        glVertex3f(LSeg.x1, LFloorHeight, LSeg.z1);

        LFloorHeight := gld_CeilingHeight(LSeg.frontsector, LSeg.x2, LSeg.z2);
        LCeilingHeight := gld_CeilingHeight(LSeg.backsector, LSeg.x2, LSeg.z2);

        glTexCoord2f(AWall.ur, AWall.vt + (AWall.ytop - LCeilingHeight) / LTextureHeight);
        glVertex3f(LSeg.x2, LCeilingHeight, LSeg.z2);
        glTexCoord2f(AWall.ur, AWall.vt + (AWall.ytop - LFloorHeight) / LTextureHeight);
        glVertex3f(LSeg.x2, LFloorHeight, LSeg.z2);
      glEnd;
      WhiteFogStop; // JVAL: Mars fog sectors
    end
    else
    begin
      if not AWall.doublelight or (AWall.ymid < AWall.ybottom) or (AWall.ymid > AWall.ytop) then
      begin
        WhiteFogFirst(AWall); // JVAL: Mars fog sectors
        glBegin(GL_TRIANGLE_STRIP);
          glTexCoord2f(AWall.ul, AWall.vt);
          glVertex3f(LSeg.x1, AWall.ytop, LSeg.z1);
          glTexCoord2f(AWall.ul, AWall.vb);
          glVertex3f(LSeg.x1, AWall.ybottom, LSeg.z1);
          glTexCoord2f(AWall.ur, AWall.vt);
          glVertex3f(LSeg.x2, AWall.ytop, LSeg.z2);
          glTexCoord2f(AWall.ur, AWall.vb);
          glVertex3f(LSeg.x2, AWall.ybottom, LSeg.z2);
        glEnd;
        WhiteFogStop; // JVAL: Mars fog sectors
      end
      else
      begin
        LTextureHeight := AWall.gltexture.buffer_height / MAP_COEFF;
        LMiddleV := AWall.vt + (AWall.ytop - AWall.ymid) / LTextureHeight;

        WhiteFogFirst(AWall); // JVAL: Mars fog sectors

        glBegin(GL_TRIANGLE_STRIP);
          glTexCoord2f(AWall.ul, AWall.vt);
          glVertex3f(LSeg.x1, AWall.ytop, LSeg.z1);
          glTexCoord2f(AWall.ul, LMiddleV);
          glVertex3f(LSeg.x1, AWall.ymid, LSeg.z1);
          glTexCoord2f(AWall.ur, AWall.vt);
          glVertex3f(LSeg.x2, AWall.ytop, LSeg.z2);
          glTexCoord2f(AWall.ur, LMiddleV);
          glVertex3f(LSeg.x2, AWall.ymid, LSeg.z2);
        glEnd;

        WhiteFogStop; // JVAL: Mars fog sectors

        WhiteFogSecond(AWall); // JVAL: Mars fog sectors

        gld_StaticLightAlpha(AWall.light2, AWall.alpha);

        glBegin(GL_TRIANGLE_STRIP);
          glTexCoord2f(AWall.ul, LMiddleV);
          glVertex3f(LSeg.x1, AWall.ymid, LSeg.z1);
          glTexCoord2f(AWall.ul, AWall.vb);
          glVertex3f(LSeg.x1, AWall.ybottom, LSeg.z1);
          glTexCoord2f(AWall.ur, LMiddleV);
          glVertex3f(LSeg.x2, AWall.ymid, LSeg.z2);
          glTexCoord2f(AWall.ur, AWall.vb);
          glVertex3f(LSeg.x2, AWall.ybottom, LSeg.z2);
        glEnd;

        WhiteFogStop; // JVAL: Mars fog sectors
      end;
    end;

    if AWall.blend then
      glDepthMask(True)
    else
      glEnable(GL_BLEND)
  end;
end;

end.

//------------------------------------------------------------------------------
//
//  DelphiDoom: Engine - draws the dynamic lights of a frame of the OpenGL scene
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

unit DelphiDoom.Engine.GlScene.LightPainter;

interface

uses
  d_delphi,
  r_dynlights;

type
  /// <summary>
  ///   Draws the dynamic lights of the buffer of the frame (dlbuffer, numdlitems of r_dynlights, already
  ///   sorted by TEngineGlSceneLightSorter) as flat discs facing the camera, the farthest first, one disc for
  ///   every different light (it was gld_DrawDLights and gld_DrawDLight of gl_render.pas): the same OpenGL
  ///   calls, in the same order, with the same numbers
  /// </summary>
  /// <remarks>
  ///   A plain class, no interface and no virtual method, called once per frame and once per light. The only
  ///   thing it holds is the inverse yaw of the view of the frame, that gld_StartDrawScene gives it
  /// </remarks>
  TEngineGlSceneLightPainter = class(TObject)
  strict private
    FInverseYaw: float;
    procedure DrawLight(const ALight: Pdlsortitem_t);
  public
    /// <summary>A new frame: the inverse yaw of the view in degrees</summary>
    procedure BeginFrame(const AInverseYaw: float);
    /// <summary>Draws the lights of the buffer; nothing without the light boost or with an empty buffer</summary>
    procedure Draw;
  end;

implementation

uses
  dglOpenGL,
  r_lights;

const
  COS16TABLE: array[0..16] of float = (
    1.0000000000,
    0.9238795042,
    0.7071067691,
    0.3826834261,
   -0.0000000000,
   -0.3826834261,
   -0.7071067691,
   -0.9238795042,
   -1.0000000000,
   -0.9238795042,
   -0.7071067691,
   -0.3826834261,
    0.0000000000,
    0.3826834261,
    0.7071067691,
    0.9238795042,
    1.0000000000
    );

  SIN16TABLE: array[0..16] of float = (
    0.0000000000,
    0.3826834261,
    0.7071067691,
    0.9238795042,
    1.0000000000,
    0.9238795042,
    0.7071067691,
    0.3826834261,
   -0.0000000000,
   -0.3826834261,
   -0.7071067691,
   -0.9238795042,
   -1.0000000000,
   -0.9238795042,
   -0.7071067691,
   -0.3826834261,
    0.0000000000
    );

{ TEngineGlSceneLightPainter }

procedure TEngineGlSceneLightPainter.BeginFrame(const AInverseYaw: float);
begin
  FInverseYaw := AInverseYaw;
end;

procedure TEngineGlSceneLightPainter.DrawLight(const ALight: Pdlsortitem_t);
var
  i: Integer;
  sz: float;
begin
  glPushMatrix;
  glTranslatef(ALight.x, ALight.y, ALight.z);
  glRotatef(FInverseYaw, 0.0, 1.0, 0.0);

  sz := ALight.l.radius;
  glBegin(GL_TRIANGLE_FAN);
    glColor4f(ALight.l.r * 0.2, ALight.l.g * 0.2, ALight.l.b * 0.2, 0.1);
    glVertex3f(0.0, 0.0, 0.05);
    glColor4f(0.0, 0.0, 0.0, 0.1);
    for i := 0 to 16 do
      glVertex3f(sz * COS16TABLE[i], sz * SIN16TABLE[i], 0.05);
  glEnd;

  glPopMatrix;
end;

procedure TEngineGlSceneLightPainter.Draw;
var
  LIndex: Integer;
  LItem: Pdlsortitem_t;
  LLast: dlsortitem_t;
begin
  if not uselightboost then
    Exit;

  if numdlitems = 0 then
    Exit;

  glMatrixMode(GL_MODELVIEW);
  glDepthMask(False);
  glDisable(GL_TEXTURE_2D);
  glDisable(GL_ALPHA_TEST);
  glBlendFunc(GL_ONE, GL_ONE);

  FillChar(LLast, SizeOf(dlsortitem_t), 0);
  // the farthest light first; a light equal to the one just drawn (same record, same place) is skipped
  for LIndex := numdlitems - 1 downto 0 do
  begin
    LItem := @dlbuffer[LIndex];
    if (LItem.l <> LLast.l) or
       (LItem.x <> LLast.x) or
       (LItem.y <> LLast.y) or
       (LItem.z <> LLast.z) then
    begin
      DrawLight(LItem);
      LLast := LItem^;
    end;
  end;

  glDepthMask(True);
  glEnable(GL_TEXTURE_2D);
  glEnable(GL_ALPHA_TEST);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
end;

end.

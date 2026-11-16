//------------------------------------------------------------------------------
//
//  DelphiDoom: Engine - the 2D drawing mode of the OpenGL games
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

unit DelphiDoom.Engine.Gl2dMode;

interface

type
  /// <summary>
  ///   The matrices and the depth test OpenGL has when the game draws the screen in two dimensions (overlay,
  ///   wipe, ENDOOM, patches), and the end of a frame that shows it (it was gld_Enable2D, gld_Disable2D,
  ///   gld_Set2DMode and gld_Finish of gl_render.pas)
  /// </summary>
  /// <remarks>Static methods: nothing is held here, the state is the one of OpenGL</remarks>
  TEngineGl2dMode = class sealed
  public
    /// <summary>Pushes the three matrices and sets an orthographic view of the size of the viewport</summary>
    class procedure Enable; static;
    /// <summary>Pops what Enable pushed</summary>
    class procedure Disable; static;
    /// <summary>Resets the matrices to an orthographic view of the whole screen, top left origin, and turns the depth test off</summary>
    class procedure SetMode; static;
    /// <summary>Ends a frame: 2D mode, the glFinish and glFlush the option asks for, and the swap of the buffers</summary>
    class procedure Finish; static;
  end;

implementation

uses
  dglOpenGL,
  doomdef,
  gl_defs,
  gl_main;

{ TEngineGl2dMode }

class procedure TEngineGl2dMode.Enable;
var
  vPort: array[0..3] of GLInt;
begin
  glGetIntegerv(GL_VIEWPORT, @vPort);

  glMatrixMode(GL_PROJECTION);
  glPushMatrix;
  glLoadIdentity;

  glOrtho(0, vPort[2], 0, vPort[3], -1, 1);
  glMatrixMode(GL_MODELVIEW);
  glPushMatrix;
  glLoadIdentity;

  glMatrixMode(GL_TEXTURE);
  glPushMatrix;
  glLoadIdentity;
end;

class procedure TEngineGl2dMode.Disable;
begin
  glMatrixMode(GL_PROJECTION);
  glPopMatrix;
  glMatrixMode(GL_MODELVIEW);
  glPopMatrix;
  glMatrixMode(GL_TEXTURE);
  glPopMatrix;
end;

class procedure TEngineGl2dMode.SetMode;
begin
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity;
  glOrtho(
    0,
    SCREENWIDTH,
    SCREENHEIGHT,
    0,
    -1.0,
    1.0
  );
  glDisable(GL_DEPTH_TEST);
end;

class procedure TEngineGl2dMode.Finish;
begin
  SetMode;
  // JVAL:
  //  Hack to avoid Intel HD4000 problem with Win10
  //  https://communities.intel.com/thread/117626
  if not gl_no_glfinish_hack then
    glFinish;
  glFlush;
  GL_SwapBuffers;
end;

end.

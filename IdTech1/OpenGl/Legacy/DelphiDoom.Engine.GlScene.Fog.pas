//------------------------------------------------------------------------------
//
//  DelphiDoom: Engine - the fog of the OpenGL scene (the normal one and the white one of the Mars sectors)
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

unit DelphiDoom.Engine.GlScene.Fog;

interface

type
  /// <summary>
  ///   Sets the OpenGL fog state of the scene: the normal fog (density, colour of the level or of the custom
  ///   colormap) and the white fog of the Mars fog sectors. They were gld_StartFog and gld_StartWhiteFog of
  ///   gl_render.pas: the same OpenGL calls, in the same order, with the same numbers
  /// </summary>
  /// <remarks>
  ///   Hot path (the painters call it for every wall, flat and sprite that changes fog): a sealed class of
  ///   static methods, no interface, no instance and no virtual call. The game differences are the same
  ///   conditional compilation the old procedures had
  /// </remarks>
  TEngineGlSceneFog = class sealed
  public
    /// <summary>Turns the normal fog on (or off when the player has a fixed colormap or the fog is disabled)</summary>
    class procedure Start; static;
    /// <summary>Turns the white fog of the Mars fog sectors on (or off when it is disabled)</summary>
    class procedure StartWhite; static;
  end;

implementation

uses
  d_delphi,
  dglOpenGL,
  d_player,
  doomstat,
  g_game,
  gl_defs,
  {$IFDEF DOOM_OR_STRIFE}
  r_colormaps,
  {$ENDIF}
  {$IFDEF HEXEN}
  r_data,
  {$ENDIF}
  m_fixed;

{ TEngineGlSceneFog }

class procedure TEngineGlSceneFog.Start;
var
  LFogColor: array[0..3] of TGLfloat;
begin
  if use_fog then
    if players[displayplayer].fixedcolormap = 0 then
    begin
{$IFDEF DOOM_OR_STRIFE}
      if customcolormap <> nil then
      begin
        glFogf(GL_FOG_DENSITY, customcolormap.fog_density * fog_density / 1000.0);

        LFogColor[0] := customcolormap.fog_r;
        LFogColor[1] := customcolormap.fog_g;
        LFogColor[2] := customcolormap.fog_b;
        LFogColor[3] := 0.0;
      end
      else
      begin
        glFogf(GL_FOG_DENSITY, fog_density / 1000.0);

        LFogColor[0] := 0.0;
        LFogColor[1] := 0.0;
        LFogColor[2] := 0.0;
        LFogColor[3] := 0.0;
      end;

      glFogfv(GL_FOG_COLOR, @LFogColor);
{$ENDIF}
{$IFDEF HERETIC}
      glFogf(GL_FOG_DENSITY, fog_density / 1000.0);

      LFogColor[0] := 0.0;
      LFogColor[1] := 0.0;
      LFogColor[2] := 0.0;
      LFogColor[3] := 0.0;

      glFogfv(GL_FOG_COLOR, @LFogColor);
{$ENDIF}
{$IFDEF HEXEN}
      glFogf(GL_FOG_DENSITY, fog_density / 1000.0);
      if LevelUseFog then
      begin
        LFogColor[0] := 1.0;
        LFogColor[1] := 1.0;
        LFogColor[2] := 1.0;
        LFogColor[3] := 0.0;
      end
      else
      begin
        LFogColor[0] := 0.0;
        LFogColor[1] := 0.0;
        LFogColor[2] := 0.0;
        LFogColor[3] := 0.0;
      end;

      glFogfv(GL_FOG_COLOR, @LFogColor);
{$ENDIF}

      glEnable(GL_FOG);
      Exit;
    end;

  glDisable(GL_FOG);
end;

class procedure TEngineGlSceneFog.StartWhite;
var
  LFogColor: array[0..3] of TGLfloat;
begin
  if use_white_fog then
    if players[displayplayer].fixedcolormap = 0 then
    begin
      glFogf(GL_FOG_DENSITY, white_fog_density / 1000.0);

{$IFDEF DOOM_OR_STRIFE}
      if customcolormap <> nil then
      begin
        LFogColor[0] := (customcolormap.fog_r + 1.0) / 2.0;
        LFogColor[1] := (customcolormap.fog_g + 1.0) / 2.0;
        LFogColor[2] := (customcolormap.fog_b + 1.0) / 2.0;
        LFogColor[3] := 0.0;
      end
      else
      begin
        LFogColor[0] := 1.0;
        LFogColor[1] := 1.0;
        LFogColor[2] := 1.0;
        LFogColor[3] := 0.0;
      end;
{$ENDIF}
{$IFDEF HERETIC_OR_HEXEN}
      LFogColor[0] := 1.0;
      LFogColor[1] := 1.0;
      LFogColor[2] := 1.0;
      LFogColor[3] := 0.0;
{$ENDIF}

      glFogfv(GL_FOG_COLOR, @LFogColor);
      glEnable(GL_FOG);
      Exit;
    end;

  glDisable(GL_FOG);
end;

end.

//------------------------------------------------------------------------------
//
//  DelphiDoom: Engine - the end of a frame of the OpenGL games (2D overlay, wipe, ENDOOM)
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

unit DelphiDoom.Engine.GlFrameEnder;

interface

uses
  dglOpenGL,
  DelphiDoom.Engine.Console.Intf{$IFNDEF HEXEN},
  DelphiDoom.Engine.Endoom.Intf{$ENDIF};

type
  /// <summary>
  ///   What the OpenGL games draw to end a frame: the software screen (HUD, status bar, menu, console) as a 2D
  ///   overlay texture on top of the 3D scene, the same overlay over a wipe, and the ENDOOM screen. It owns the
  ///   textures of the three (it was I_FinishUpdateOverlay, I_FinishUpdateWIPE, I_FinishUpdateENDOOM,
  ///   GL_CreateOverlayTexture and the texture part of I_ShutDownGraphics of gl_main.pas)
  /// </summary>
  /// <remarks>
  ///   A plain class, no interface and no virtual method, called once per frame by gl_main. The differences of
  ///   the games (the partial update of the overlay of Doom, no ENDOOM in Hexen) stay as conditional
  ///   compilation, as they were
  /// </remarks>
  TEngineGlFrameEnder = class(TObject)
  strict private
    FConsole: IEngineConsole;
    {$IFNDEF HEXEN}
    FEndoom: IEngineEndoomScreen;
    FEndoomTexture: GLuint;
    {$ENDIF}
    FOverlayTexture: GLuint;
    FWipeTexture: GLuint;
    FLinearHud: Boolean;
    {$IFDEF DOOM}
    FOverlayCreated: Boolean;
    FSubY2: Integer;
    FFullHudTics: Integer;
    FOverlayUpdateTic: Integer;
    FLastY1: Integer;
    {$ENDIF}
    procedure ApplyHudFilter;
  public
    /// <summary>The console is drawn by the caller; Doom asks it how high it is to update less of the overlay</summary>
    constructor Create(const AConsole: IEngineConsole{$IFNDEF HEXEN}; const AEndoom: IEngineEndoomScreen{$ENDIF});
    /// <summary>Creates the overlay texture (video start, and again after a change of size)</summary>
    procedure CreateOverlayTexture;
    /// <summary>Deletes the overlay texture, for a change of size: the next frame creates it whole again</summary>
    procedure DeleteOverlayTexture;
    /// <summary>Deletes all the textures (video stop)</summary>
    procedure ReleaseTextures;
    /// <summary>Remembers the filter the overlay texture has now (the one of the video start)</summary>
    procedure ResetHudFilter;
    /// <summary>The overlay over the 3D scene; flushes the frame (shows it) if asked</summary>
    procedure FinishOverlay(const ADoFlush: Boolean);
    /// <summary>A frame of a wipe, with the overlay over it</summary>
    procedure FinishWipe;
    {$IFNDEF HEXEN}
    /// <summary>The ENDOOM screen</summary>
    procedure FinishEndoom;
    {$ENDIF}
  end;

implementation

uses
  Windows,
  Messages,
  am_map,
  c_con,
  doomdef,
  d_main,
  d_net,
  d_notifications,
  g_game,
  hu_stuff,
  {$IFDEF DOOM}
  r_draw,
  st_stuff,
  {$ENDIF}
  {$IFDEF STRIFE}
  f_fade,
  {$ELSE}
  f_wipe,
  {$ENDIF}
  r_main,
  mt_utils,
  r_hires,
  i_mainwindow,
  i_system,
  m_argv,
  m_menu,
  psi_overlay,
  gl_render,
  gl_tex,
  gl_defs,
  v_data,
  v_video,
  d_delphi,
  doomstat;

{ TEngineGlFrameEnder }

constructor TEngineGlFrameEnder.Create(const AConsole: IEngineConsole{$IFNDEF HEXEN}; const AEndoom: IEngineEndoomScreen{$ENDIF});
begin
  inherited Create;
  FConsole := AConsole;
  {$IFNDEF HEXEN}
  FEndoom := AEndoom;
  {$ENDIF}
  {$IFDEF DOOM}
  FFullHudTics := 10;
  FOverlayUpdateTic := 30;
  FLastY1 := MAXINT;
  {$ENDIF}
end;

procedure TEngineGlFrameEnder.ApplyHudFilter;
begin
  if FLinearHud <> gl_linear_hud then
  begin
    if gl_linear_hud then
    begin
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    end
    else
    begin
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    end;
    FLinearHud := gl_linear_hud;
  end;
end;

procedure TEngineGlFrameEnder.CreateOverlayTexture;
begin
  glGenTextures(1, @FOverlayTexture);
  glBindTexture(GL_TEXTURE_2D, FOverlayTexture);
  glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);  {Texture blends with object background}
  if gl_linear_hud then
  begin
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  end
  else
  begin
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  end;
  glTexImage2D(GL_TEXTURE_2D, 0, 4, GLDRAWTEXWIDTH, GLDRAWTEXHEIGHT, 0, GL_BGRA, GL_UNSIGNED_BYTE, screen32);
end;

procedure TEngineGlFrameEnder.DeleteOverlayTexture;
begin
  glDeleteTextures(1, @FOverlayTexture);
end;

procedure TEngineGlFrameEnder.ResetHudFilter;
begin
  FLinearHud := gl_linear_hud;
end;

procedure TEngineGlFrameEnder.ReleaseTextures;
begin
  if FOverlayTexture <> 0 then
  begin
    glDeleteTextures(1, @FOverlayTexture);
    FOverlayTexture := 0;
  end;
  {$IFNDEF HEXEN}
  if FEndoomTexture <> 0 then
  begin
    glDeleteTextures(1, @FEndoomTexture);
    FEndoomTexture := 0;
  end;
  {$ENDIF}
  if FWipeTexture <> 0 then
  begin
    glDeleteTextures(1, @FWipeTexture);
    FWipeTexture := 0;
  end;
end;

procedure TEngineGlFrameEnder.FinishWipe;
begin
  glPushAttrib(GL_ALL_ATTRIB_BITS);
  gld_Enable2D;

  if FWipeTexture = 0 then
    glGenTextures(1, @FWipeTexture);

  glBindTexture(GL_TEXTURE_2D, FWipeTexture);

  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);

  glTexImage2D(GL_TEXTURE_2D, 0, 4, WIPESCREENWIDTH, WIPESCREENHEIGHT, 0, GL_BGRA, GL_UNSIGNED_BYTE, w_screen32);

  glColor4f(1.0, 1.0, 1.0, 1.0);
  glEnable(GL_ALPHA_TEST);
  glAlphaFunc(GL_NOTEQUAL, 0);

  glBegin(GL_QUADS);
    glTexCoord2f(0.0, SCREENHEIGHT / WIPESCREENHEIGHT);
    glVertex2f(0, 0);
    glTexCoord2f(SCREENWIDTH / WIPESCREENWIDTH, SCREENHEIGHT / WIPESCREENHEIGHT);
    glVertex2f(SCREENWIDTH, 0);
    glTexCoord2f(SCREENWIDTH / WIPESCREENWIDTH, 0.0);
    glVertex2f(SCREENWIDTH, SCREENHEIGHT);
    glTexCoord2f(0.0, 0.0);
    glVertex2f(0, SCREENHEIGHT);
  glEnd;

// Blend overlay (Menu & Console) over the wipe
  glBindTexture(GL_TEXTURE_2D, FOverlayTexture);
  ApplyHudFilter;

  glTexImage2D(GL_TEXTURE_2D, 0, 4, GLDRAWTEXWIDTH, GLDRAWTEXHEIGHT, 0, GL_BGRA, GL_UNSIGNED_BYTE, screen32);

  glColor4f(1.0, 1.0, 1.0, 1.0);
  glEnable(GL_ALPHA_TEST);
  glAlphaFunc(GL_NOTEQUAL, 0);

  glBegin(GL_QUADS);
    glTexCoord2f(0.0, GLDRAWHEIGHT / GLDRAWTEXHEIGHT);
    glVertex2f(0, 0);
    glTexCoord2f(GLDRAWWIDTH / GLDRAWTEXWIDTH, GLDRAWHEIGHT / GLDRAWTEXHEIGHT);
    glVertex2f(SCREENWIDTH, 0);
    glTexCoord2f(GLDRAWWIDTH / GLDRAWTEXWIDTH, 0.0);
    glVertex2f(SCREENWIDTH, SCREENHEIGHT);
    glTexCoord2f(0.0, 0.0);
    glVertex2f(0, SCREENHEIGHT);
  glEnd;

  glDisable(GL_BLEND);

  gld_Disable2D;
  glPopAttrib;

  gld_Finish;
end;

{$IFNDEF HEXEN}
procedure TEngineGlFrameEnder.FinishEndoom;
begin
  glPushAttrib(GL_ALL_ATTRIB_BITS);
  gld_Enable2D;

  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT or GL_STENCIL_BUFFER_BIT);

  if FEndoomTexture = 0 then
    glGenTextures(1, @FEndoomTexture);

  glBindTexture(GL_TEXTURE_2D, FEndoomTexture);

  if gl_linear_hud then
  begin
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  end
  else
  begin
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  end;

  glTexImage2D(GL_TEXTURE_2D, 0, 4, ENDOOM_TEXTURE_WIDTH, ENDOOM_TEXTURE_HEIGHT, 0, GL_BGRA, GL_UNSIGNED_BYTE, FEndoom.Pixels32);

  glColor4f(1.0, 1.0, 1.0, 1.0);
  glEnable(GL_ALPHA_TEST);
  glAlphaFunc(GL_NOTEQUAL, 0);

  glBegin(GL_QUADS);
    glTexCoord2f(0.0, 200 / ENDOOM_TEXTURE_HEIGHT);
    glVertex2f(0, 0);
    glTexCoord2f(640 / ENDOOM_TEXTURE_WIDTH, 200 / ENDOOM_TEXTURE_HEIGHT);
    glVertex2f(SCREENWIDTH, 0);
    glTexCoord2f(640 / ENDOOM_TEXTURE_WIDTH, 0.0);
    glVertex2f(SCREENWIDTH, SCREENHEIGHT);
    glTexCoord2f(0.0, 0.0);
    glVertex2f(0, SCREENHEIGHT);
  glEnd;

  glDisable(GL_BLEND);

  gld_Disable2D;
  glPopAttrib;

  gld_Finish;
end;
{$ENDIF}

procedure TEngineGlFrameEnder.FinishOverlay(const ADoFlush: Boolean);
{$IFDEF DOOM}
var
  sub_y1, y1, y2, yovr: Integer;
{$ENDIF}
begin
  glPushAttrib(GL_ALL_ATTRIB_BITS);
  gld_Enable2D;

  glBindTexture(GL_TEXTURE_2D, FOverlayTexture);
  ApplyHudFilter;

  if firstinterpolation then
  begin
{$IFDEF DOOM}
    Dec(FOverlayUpdateTic);
    if FOverlayCreated then
    begin
      if (gamestate = GS_LEVEL) and (amstate = am_inactive) and not menuactive then
      begin
        if FFullHudTics > 0 then
        begin
          Dec(FFullHudTics);
          glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, GLDRAWWIDTH, GLDRAWHEIGHT, GL_BGRA, GL_UNSIGNED_BYTE, screen32);
        end
        else
        begin
          y1 := FConsole.Position;
          yovr := OVR_OverlayHeight;
          if yovr > y1 then
            y1 := yovr;
          sub_y1 := V_PreserveY(HU_Height);
          if sub_y1 > y1 then
            y1 := sub_y1;
          sub_y1 := V_PreserveY(diskbusy_height);
          if sub_y1 > y1 then
            y1 := sub_y1;
          if FLastY1 = MAXINT then
            FLastY1 := GLDRAWTEXHEIGHT;
          if FLastY1 > y1 then
            glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, GLDRAWWIDTH, FLastY1, GL_BGRA, GL_UNSIGNED_BYTE, screen32)
          else
            glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, GLDRAWWIDTH, y1, GL_BGRA, GL_UNSIGNED_BYTE, screen32);
          FLastY1 := y1;
          if (screenblocks < 12) or (FOverlayUpdateTic = 0) then
            y2 := FSubY2
          else
            y2 := GLDRAWHEIGHT;
          if TGameSession.DemoPlayback then
            y2 := y2 - V_PreserveY(10);
          glTexSubImage2D(GL_TEXTURE_2D, 0, 0, y2, GLDRAWWIDTH, GLDRAWHEIGHT - y2, GL_BGRA, GL_UNSIGNED_BYTE, @screen32[y2 * GLDRAWWIDTH]);
        end;
      end
      else
      begin
        FFullHudTics := TICRATE;
        glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, GLDRAWWIDTH, GLDRAWHEIGHT, GL_BGRA, GL_UNSIGNED_BYTE, screen32);
      end;
      if FOverlayUpdateTic = 0 then
        FOverlayUpdateTic := 30;
    end
    else
    begin
      FOverlayCreated := True;
      FSubY2 := V_PreserveY(ST_Y);
      glTexImage2D(GL_TEXTURE_2D, 0, 4, GLDRAWTEXWIDTH, GLDRAWTEXHEIGHT, 0, GL_BGRA, GL_UNSIGNED_BYTE, screen32);
    end;
{$ELSE}
    glTexImage2D(GL_TEXTURE_2D, 0, 4, GLDRAWTEXWIDTH, GLDRAWTEXHEIGHT, 0, GL_BGRA, GL_UNSIGNED_BYTE, screen32);
{$ENDIF}
  end;

  glColor4f(1.0, 1.0, 1.0, 1.0);
  glEnable(GL_ALPHA_TEST);
  glAlphaFunc(GL_NOTEQUAL, 0);

  glBegin(GL_QUADS);
    glTexCoord2f(0.0, GLDRAWHEIGHT / GLDRAWTEXHEIGHT);
    glVertex2f(0, 0);
    glTexCoord2f(GLDRAWWIDTH / GLDRAWTEXWIDTH, GLDRAWHEIGHT / GLDRAWTEXHEIGHT);
    glVertex2f(SCREENWIDTH, 0);
    glTexCoord2f(GLDRAWWIDTH / GLDRAWTEXWIDTH, 0.0);
    glVertex2f(SCREENWIDTH, SCREENHEIGHT);
    glTexCoord2f(0.0, 0.0);
    glVertex2f(0, SCREENHEIGHT);
  glEnd;

  glDisable(GL_BLEND);

  gld_Disable2D;
  glPopAttrib;

  if ADoFlush then
    gld_Finish;
end;

end.

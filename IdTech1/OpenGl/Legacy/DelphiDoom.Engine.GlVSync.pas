//------------------------------------------------------------------------------
//
//  DelphiDoom: Engine - the vertical sync of the OpenGL games
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

unit DelphiDoom.Engine.GlVSync;

interface

type
  /// <summary>The two states of the vertical sync of the swap interval extension</summary>
  TGlVSyncMode = (vsmSync, vsmNoSync);

  /// <summary>
  ///   The vertical sync of the swap interval extension (WGL_EXT_swap_control): the change asked by the video
  ///   start and by the option of the menu (gl_screensync), and the first-frame dance that makes some drivers
  ///   take the setting (it was gld_VSync and the vsync part of gld_Init and gld_StartDrawScene of gl_render.pas)
  /// </summary>
  /// <remarks>A plain class, no interface and no virtual method: it is asked once per frame</remarks>
  TEngineGlVSync = class(TObject)
  strict private
    FWarned: Boolean;
    FLastSync: Boolean;
    FDidFirstSync: Boolean;
  public
    /// <summary>
    ///   Sets the swap interval to 1 (sync) or 0; False, with one warning for the whole run, if the driver has
    ///   no swap control
    /// </summary>
    function Apply(const AMode: TGlVSyncMode): Boolean;
    /// <summary>The setting of the option at the video start</summary>
    procedure Start;
    /// <summary>Called at the start of every frame: follows a change of the option, and repeats the setting at the first frame</summary>
    procedure Update;
  end;

implementation

uses
  dglOpenGL,
  i_system,
  gl_defs;

{ TEngineGlVSync }

function TEngineGlVSync.Apply(const AMode: TGlVSyncMode): Boolean;
var
  i: Integer;
begin
  if WGL_EXT_swap_control then
  begin
    Result := True;
    i := wglGetSwapIntervalEXT;
    case AMode of
      vsmSync: if i <> 1 then wglSwapIntervalEXT(1);
      vsmNoSync: if i <> 0 then wglSwapIntervalEXT(0);
    else
      Assert(False);
    end;
  end
  else
  begin
    Result := False;
    if not FWarned then
    begin
      I_Warning('gld_VSync(): wglSwapIntervalEXT() not assigned'#13#10);
      FWarned := True;
    end;
  end;
end;

procedure TEngineGlVSync.Start;
begin
  if gl_screensync then
    Apply(vsmSync)
  else
    Apply(vsmNoSync);
  FLastSync := gl_screensync;
end;

procedure TEngineGlVSync.Update;
var
  syncret: Boolean;
begin
  if (FLastSync <> gl_screensync) or not FDidFirstSync then
  begin
    if gl_screensync then
    begin
      syncret := Apply(vsmSync);
      if not FDidFirstSync then
      begin
        Apply(vsmNoSync);
        Apply(vsmSync);
      end;
    end
    else
    begin
      syncret := Apply(vsmNoSync);
      if not FDidFirstSync then
      begin
        Apply(vsmSync);
        Apply(vsmNoSync);
      end;
    end;
    FLastSync := gl_screensync;
    FDidFirstSync := syncret;
  end;
end;

end.

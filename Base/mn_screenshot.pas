//------------------------------------------------------------------------------
//
//  DelphiDoom is a source port of the game Doom and it is
//  based on original Linux Doom as published by "id Software"
//  Copyright (C) 1993-1996 by id Software, Inc.
//  Copyright (C) 2004-2022 by Jim Valavanis
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
// DESCRIPTION:
//   Save/Load screen preview
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit mn_screenshot;

interface

uses
  DelphiDoom.Imaging.Intf;

const
  MN_SCREENSHOTWIDTH = 80;
  MN_SCREENSHOTHEIGHT = 50;
  MN_SCREENSHOTSIZE = MN_SCREENSHOTWIDTH * MN_SCREENSHOTHEIGHT;

  MNSCREENSHOT_MAGIC_SIZE = 14;
  // MENUSCREENSHOT
  MNSCREENSHOT_MAGIC: packed array[0..MNSCREENSHOT_MAGIC_SIZE - 1] of byte = (
    $4D, $45, $4E, $55, $53, $43, $52, $45, $45, $4E, $53, $48, $4F, $54
  );

type
  menuscreenbuffer_t = record
    header: packed array[0..MNSCREENSHOT_MAGIC_SIZE - 1] of byte;
    data: packed array[0..MN_SCREENSHOTSIZE - 1] of byte;
  end;
  Pmenuscreenbuffer_t = ^menuscreenbuffer_t;

var
  mn_screenshotbuffer: menuscreenbuffer_t;
  mn_makescreenshot: boolean = false;

//==============================================================================
//
// MN_ConfigureScreenShot
//
//==============================================================================
procedure MN_ConfigureScreenShot(const ABuilder: IImagingThumbnailBuilder);

//==============================================================================
//
// MN_ScreenShotFromBlitBuffer
//
//==============================================================================
procedure MN_ScreenShotFromBlitBuffer;

//==============================================================================
//
// MN_ScreenShotFromSaveGame
//
//==============================================================================
procedure MN_ScreenShotFromSaveGame(const path: string; const outbuff: Pmenuscreenbuffer_t);

//==============================================================================
//
// MN_ValidScreenShot
//
//==============================================================================
function MN_ValidScreenShot(const mnbuf: Pmenuscreenbuffer_t): boolean;

implementation

uses
  System.SysUtils,
  d_delphi,
  doomdef,
  i_system,
  DelphiDoom.Imaging.Types,
  {$IFDEF OPENGL}
  gl_main,
  {$ELSE}
  i_video,
  {$ENDIF}
  r_draw,
  v_video;

var
  // given by the composition root (MN_ConfigureScreenShot)
  mn_thumbnails: IImagingThumbnailBuilder = nil;

//==============================================================================
//
// MN_ConfigureScreenShot
//
//==============================================================================
procedure MN_ConfigureScreenShot(const ABuilder: IImagingThumbnailBuilder);
begin
  mn_thumbnails := ABuilder;
end;

//==============================================================================
//
// MN_ScreenShotFromBlitBuffer
//
//==============================================================================
procedure MN_ScreenShotFromBlitBuffer;
var
  i: integer;
  settings: TImagingThumbnailSettings;
  buf: TBytes;
  palette: TImagingPixels;
  thumbnail: TBytes;
begin
  if mn_thumbnails = nil then
    I_Error('MN_ScreenShotFromBlitBuffer(): the thumbnails are not configured (MN_ConfigureScreenShot)');

  {$IFNDEF OPENGL}
  I_BlitBuffer;
  {$ENDIF}
  SetLength(buf, SCREENWIDTH * SCREENHEIGHT * 4);
  I_ReadScreen32(Pointer(buf));

  settings.ScreenWidth := SCREENWIDTH;
  settings.ScreenHeight := SCREENHEIGHT;
  settings.ViewX := viewwindowx;
  settings.ViewY := viewwindowy;
  settings.ViewWidth := viewwidth;
  settings.ViewHeight := viewheight;
  settings.Width := MN_SCREENSHOTWIDTH;
  settings.Height := MN_SCREENSHOTHEIGHT;
  settings.BottomUp := {$IFDEF OPENGL}True{$ELSE}False{$ENDIF};

  SetLength(palette, IMAGING_PALETTE_SIZE);
  Move(videopal, palette[0], SizeOf(videopal));

  thumbnail := mn_thumbnails.Build(settings, Pointer(buf), palette);

  for i := 0 to MNSCREENSHOT_MAGIC_SIZE - 1 do
    mn_screenshotbuffer.header[i] := MNSCREENSHOT_MAGIC[i];
  Move(thumbnail[0], mn_screenshotbuffer.data[0], MN_SCREENSHOTSIZE);
  mn_makescreenshot := false;
end;
//==============================================================================
//
// MN_ScreenShotFromSaveGame
//
//==============================================================================
procedure MN_ScreenShotFromSaveGame(const path: string; const outbuff: Pmenuscreenbuffer_t);
var
  f: TFile;
begin
  if not fexists(path) then
  begin
    ZeroMemory(outbuff, SizeOf(menuscreenbuffer_t));
    exit;
  end;

  f := TFile.Create(path, fOpenReadOnly);
  if f.Size < SizeOf(menuscreenbuffer_t) then
  begin
    ZeroMemory(outbuff, SizeOf(menuscreenbuffer_t));
    f.Free;
    exit;
  end;

  f.Read(outbuff^, SizeOf(menuscreenbuffer_t));
  f.Free;
end;

//==============================================================================
//
// MN_ValidScreenShot
//
//==============================================================================
function MN_ValidScreenShot(const mnbuf: Pmenuscreenbuffer_t): boolean;
var
  i: integer;
begin
  for i := 0 to MNSCREENSHOT_MAGIC_SIZE - 1 do
    if mnbuf.header[i] <> MNSCREENSHOT_MAGIC[i] then
    begin
      Result := False;
      Exit;
    end;
  Result := True;
end;

end.

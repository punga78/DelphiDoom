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
//  DESCRIPTION:
//   Notifications
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit d_notifications;


interface

uses
  DelphiDoom.Video.Intf;

//==============================================================================
//
// D_ConfigureNotifications
// The deferred notifications (composition root): D_NotifyVideoModeChange and
// D_RunNotifications need them
//
//==============================================================================
procedure D_ConfigureNotifications(const ANotifications: IDeferredNotifications);

//==============================================================================
//
// D_NotifyVideoModeChange
//
//==============================================================================
procedure D_NotifyVideoModeChange(const newwidth, newheight: integer);

{$IFDEF OPENGL}

//==============================================================================
//
// D_NotifyGLDisplayMode
//
//==============================================================================
procedure D_NotifyGLDisplayMode;
{$ENDIF}

//==============================================================================
//
// D_RunNotifications
//
//==============================================================================
procedure D_RunNotifications;

implementation

uses
  i_system;

var
  deferrednotifications: IDeferredNotifications = nil;

//==============================================================================
//
// D_ConfigureNotifications
//
//==============================================================================
procedure D_ConfigureNotifications(const ANotifications: IDeferredNotifications);
begin
  deferrednotifications := ANotifications;
end;

//==============================================================================
//
// D_CheckNotifications
//
//==============================================================================
procedure D_CheckNotifications;
begin
  if deferrednotifications = nil then
    I_Error('The notifications are not configured (ComposeEngine was not called)');
end;

//==============================================================================
//
// D_NotifyVideoModeChange
//
//==============================================================================
procedure D_NotifyVideoModeChange(const newwidth, newheight: integer);
begin
  D_CheckNotifications;
  deferrednotifications.NotifyVideoModeChange(newwidth, newheight);
end;

{$IFDEF OPENGL}

//==============================================================================
//
// D_NotifyGLDisplayMode
//
//==============================================================================
procedure D_NotifyGLDisplayMode;
begin
  D_CheckNotifications;
  deferrednotifications.NotifyGLDisplayMode;
end;
{$ENDIF}

//==============================================================================
//
// D_RunNotifications
//
//==============================================================================
procedure D_RunNotifications;
begin
  D_CheckNotifications;
  deferrednotifications.Run;
end;

end.
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
//  Pascal Script RTL - Overlay Drawing
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}


{$I Doom32.inc}

unit psi_overlay;

interface

uses
  p_mobj_h,
  DelphiDoom.ScriptHost.Classes.Intf,
  DelphiDoom.ScriptHost.Intf,
  DelphiDoom.ScriptHost.Overlay.Drawer,
  DelphiDoom.ScriptHost.Overlay.Intf;

var
  /// the overlay of the game (the class Overlay of the scripts is this same object)
  overlay: TOverlayDrawer;

//==============================================================================
//
// PS_ConfigureOverlay
// Gives the overlay the screen, the lumps and the font of the engine (ComposeScriptHost)
//
//==============================================================================
procedure PS_ConfigureOverlay(const ACanvas: IOverlayCanvas);

//==============================================================================
//
// PS_OverlayFunctions
// The functions of the unit PS_OVERLAY (OverlayClear, OverlayDrawPatch...)
//
//==============================================================================
function PS_OverlayFunctions: IScriptFunctionSection;

//==============================================================================
//
// PS_InitOverlay
// The overlay of the game; it needs PS_ConfigureOverlay
//
//==============================================================================
procedure PS_InitOverlay;

//==============================================================================
// PS_ShutDownOverlay
//
// --------------------- FINALIZATION -----------------------------------------
//
//==============================================================================
procedure PS_ShutDownOverlay;

//==============================================================================
//
// PS_CreateOverlayDrawer
// An overlay of the game that is not the one of the scripts (the background of the menus)
//
//==============================================================================
function PS_CreateOverlayDrawer: TOverlayDrawer;

//==============================================================================
//
// OVR_Drawer
//
//==============================================================================
procedure OVR_Drawer;

{$IFDEF OPENGL}

//==============================================================================
//
// OVR_OverlayHeight
//
//==============================================================================
function OVR_OverlayHeight: Integer;
{$ENDIF}

//==============================================================================
//
// PS_DescribeOverlayClasses
// The class Overlay of the scripts, for the compiler and the interpreter
//
//==============================================================================
procedure PS_DescribeOverlayClasses(const ACatalog: IScriptClassCatalog);

//==============================================================================
procedure A_OverlayClear;

//==============================================================================
//
// A_OverlayDrawPatch
//
//==============================================================================
procedure A_OverlayDrawPatch(actor: Pmobj_t);

//==============================================================================
//
// A_OverlayDrawPatchStretched
//
//==============================================================================
procedure A_OverlayDrawPatchStretched(actor: Pmobj_t);

//==============================================================================
//
// A_OverlayDrawPixel
//
//==============================================================================
procedure A_OverlayDrawPixel(actor: Pmobj_t);

//==============================================================================
//
// A_OverlayDrawRect
//
//==============================================================================
procedure A_OverlayDrawRect(actor: Pmobj_t);

//==============================================================================
//
// A_OverlayDrawLine
//
//==============================================================================
procedure A_OverlayDrawLine(actor: Pmobj_t);

//==============================================================================
//
// A_OverlayDrawText
//
//==============================================================================
procedure A_OverlayDrawText(actor: Pmobj_t);

//==============================================================================
//
// A_OverlayDrawLeftText
//
//==============================================================================
procedure A_OverlayDrawLeftText(actor: Pmobj_t);

//==============================================================================
//
// A_OverlayDrawRightText
//
//==============================================================================
procedure A_OverlayDrawRightText(actor: Pmobj_t);

//==============================================================================
//
// A_OverlayDrawCenterText
//
//==============================================================================
procedure A_OverlayDrawCenterText(actor: Pmobj_t);

//==============================================================================
implementation

uses
  d_delphi,
  doomdef,
  i_system,
  p_common,
  sc_params,
  DelphiDoom.ScriptHost.Factory;

var
  ps_overlay_canvas: IOverlayCanvas = nil;
  ps_overlay_functions: IScriptFunctionSection = nil;

//==============================================================================
//
// PS_ConfigureOverlay
//
//==============================================================================
procedure PS_ConfigureOverlay(const ACanvas: IOverlayCanvas);
begin
  ps_overlay_canvas := ACanvas;
  ps_overlay_functions := TScriptHostFactory.CreateOverlayFunctions(
    function: TOverlayDrawer
    begin
      Result := overlay;
    end);
end;

//==============================================================================
//
// PS_OverlayFunctions
//
//==============================================================================
function PS_OverlayFunctions: IScriptFunctionSection;
begin
  if not Assigned(ps_overlay_functions) then
    I_Error('PS_OverlayFunctions(): the overlay is not configured (PS_ConfigureOverlay)');
  Result := ps_overlay_functions;
end;

//==============================================================================
//
// PS_CreateOverlayDrawer
//
//==============================================================================
function PS_CreateOverlayDrawer: TOverlayDrawer;
begin
  if not Assigned(ps_overlay_canvas) then
    I_Error('PS_CreateOverlayDrawer(): the overlay is not configured (PS_ConfigureOverlay)');
  Result := TScriptHostFactory.CreateOverlayDrawer(ps_overlay_canvas);
end;

//==============================================================================
//
// PS_InitOverlay
//
//==============================================================================
procedure PS_InitOverlay;
begin
  overlay := PS_CreateOverlayDrawer;
end;

//==============================================================================
//
// PS_ShutDownOverlay
//
//==============================================================================
procedure PS_ShutDownOverlay;
begin
  FreeAndNil(overlay);
end;

//==============================================================================
//
// OVR_Drawer
//
//==============================================================================
procedure OVR_Drawer;
begin
  if gamestate = GS_LEVEL then
    overlay.FlashToScreen;
end;

{$IFDEF OPENGL}

//==============================================================================
//
// OVR_OverlayHeight
//
//==============================================================================
function OVR_OverlayHeight: Integer;
begin
  if gamestate = GS_LEVEL then
    Result := overlay.GetOverlayHeight
  else
    Result := 0;
end;
{$ENDIF}

//==============================================================================
//
// PS_DescribeOverlayClasses
// ---------------------- REGISTRATION ----------------------------------------
//
//==============================================================================
procedure PS_DescribeOverlayClasses(const ACatalog: IScriptClassCatalog);
var
  LClass: IScriptClassDescriptor;
begin
  LClass := ACatalog.AddClass('!TOverlay', TOverlayDrawer);
  LClass.AddVirtualConstructor(@TOverlayDrawer.Create);
  LClass.AddVirtualMethod('Procedure Clear', 'Clear', @TOverlayDrawer.Clear);
  LClass.AddMethod('Procedure DrawPatch( const ticks: Integer; const patchname: string; const x, y: Integer)', 'DrawPatch', @TOverlayDrawer.AddPatch);
  LClass.AddMethod('Procedure DrawPatchStretched( const ticks: Integer; const patchname: string; const x1, y1, x2, y2: Integer)', 'DrawPatchStretched', @TOverlayDrawer.AddPatchStretched);
  LClass.AddMethod('Procedure DrawPixel( const ticks: Integer; const red, green, blue: byte; const x, y: Integer)', 'DrawPixel', @TOverlayDrawer.AddPixel);
  LClass.AddMethod('Procedure DrawRect( const ticks: Integer; const red, green, blue: byte; const x1, y1, x2, y2: Integer)', 'DrawRect', @TOverlayDrawer.AddRect);
  LClass.AddMethod('Procedure DrawLine( const ticks: Integer; const red, green, blue: byte; const x1, y1, x2, y2: Integer)', 'DrawLine', @TOverlayDrawer.AddLine);
  LClass.AddMethod('Procedure DrawText( const ticks: Integer; const txt: string; const align: Integer; const x, y: Integer)', 'DrawText', @TOverlayDrawer.AddText);
  LClass.AddMethod('Procedure DrawLeftText( const ticks: Integer; const txt: string; const x, y: Integer)', 'DrawLeftText', @TOverlayDrawer.AddLeftText);
  LClass.AddMethod('Procedure DrawRightText( const ticks: Integer; const txt: string; const x, y: Integer)', 'DrawRightText', @TOverlayDrawer.AddRightText);
  LClass.AddMethod('Procedure DrawCenterText( const ticks: Integer; const txt: string; const x, y: Integer)', 'DrawCenterText', @TOverlayDrawer.AddCenterText);
  LClass.AddVariable('Overlay',
    function: TObject
    begin
      Result := overlay;
    end);
end;

//==============================================================================
// A_OverlayClear
//
//------------ Mobj Codepointers -----------------------------------------------
//
//==============================================================================
procedure A_OverlayClear;
begin
  if overlay <> nil then
    overlay.Clear;
end;

//==============================================================================
//
// A_OverlayDrawPatch
//
//==============================================================================
procedure A_OverlayDrawPatch(actor: Pmobj_t);
var
  ticks: Integer;
  patchname: string;
  x, y: Integer;
begin
  if not P_CheckStateParams(actor, 4) then
    Exit;

  ticks := actor.state.params.IntVal[0];
  patchname := actor.state.params.strval[1];
  x := actor.state.params.IntVal[2];
  y := actor.state.params.IntVal[3];

  if overlay <> nil then
    overlay.AddPatch(ticks, patchname, x, y);
end;

//==============================================================================
//
// A_OverlayDrawPatchStretched
//
//==============================================================================
procedure A_OverlayDrawPatchStretched(actor: Pmobj_t);
var
  ticks: Integer;
  patchname: string;
  x1, y1, x2, y2: Integer;
begin
  if not P_CheckStateParams(actor, 6) then
    Exit;

  ticks := actor.state.params.IntVal[0];
  patchname := actor.state.params.strval[1];
  x1 := actor.state.params.IntVal[2];
  y1 := actor.state.params.IntVal[3];
  x2 := actor.state.params.IntVal[4];
  y2 := actor.state.params.IntVal[5];

  if overlay <> nil then
    overlay.AddPatchStretched(ticks, patchname, x1, y1, x2, y2);
end;

//==============================================================================
//
// A_OverlayDrawPixel
//
//==============================================================================
procedure A_OverlayDrawPixel(actor: Pmobj_t);
var
  ticks: Integer;
  red, green, blue: byte;
  x, y: Integer;
begin
  if not P_CheckStateParams(actor, 6) then
    Exit;

  ticks := actor.state.params.IntVal[0];
  red := actor.state.params.IntVal[1];
  green := actor.state.params.IntVal[2];
  blue := actor.state.params.IntVal[3];
  x := actor.state.params.IntVal[4];
  y := actor.state.params.IntVal[5];

  if overlay <> nil then
    overlay.AddPixel(ticks, red, green, blue, x, y);
end;

//==============================================================================
//
// A_OverlayDrawRect
//
//==============================================================================
procedure A_OverlayDrawRect(actor: Pmobj_t);
var
  ticks: Integer;
  red, green, blue: byte;
  x1, y1, x2, y2: Integer;
begin
  if not P_CheckStateParams(actor, 8) then
    Exit;

  ticks := actor.state.params.IntVal[0];
  red := actor.state.params.IntVal[1];
  green := actor.state.params.IntVal[2];
  blue := actor.state.params.IntVal[3];
  x1 := actor.state.params.IntVal[4];
  y1 := actor.state.params.IntVal[5];
  x2 := actor.state.params.IntVal[6];
  y2 := actor.state.params.IntVal[7];

  if overlay <> nil then
    overlay.AddRect(ticks, red, green, blue, x1, y1, x2, y2);
end;

//==============================================================================
//
// A_OverlayDrawLine
//
//==============================================================================
procedure A_OverlayDrawLine(actor: Pmobj_t);
var
  ticks: Integer;
  red, green, blue: byte;
  x1, y1, x2, y2: Integer;
begin
  if not P_CheckStateParams(actor, 8) then
    Exit;

  ticks := actor.state.params.IntVal[0];
  red := actor.state.params.IntVal[1];
  green := actor.state.params.IntVal[2];
  blue := actor.state.params.IntVal[3];
  x1 := actor.state.params.IntVal[4];
  y1 := actor.state.params.IntVal[5];
  x2 := actor.state.params.IntVal[6];
  y2 := actor.state.params.IntVal[7];

  if overlay <> nil then
    overlay.AddLine(ticks, red, green, blue, x1, y1, x2, y2);
end;

//==============================================================================
//
// A_OverlayDrawText
//
//==============================================================================
procedure A_OverlayDrawText(actor: Pmobj_t);
var
  ticks: Integer;
  txt: string;
  align: Integer;
  x, y: Integer;
begin
  if not P_CheckStateParams(actor, 5) then
    Exit;

  ticks := actor.state.params.IntVal[0];
  txt := actor.state.params.StrVal[1];
  align := actor.state.params.IntVal[2];
  x := actor.state.params.IntVal[3];
  y := actor.state.params.IntVal[4];

  if overlay <> nil then
    overlay.AddText(ticks, txt, align, x, y);
end;

//==============================================================================
//
// A_OverlayDrawLeftText
//
//==============================================================================
procedure A_OverlayDrawLeftText(actor: Pmobj_t);
var
  ticks: Integer;
  txt: string;
  x, y: Integer;
begin
  if not P_CheckStateParams(actor, 4) then
    Exit;

  ticks := actor.state.params.IntVal[0];
  txt := actor.state.params.StrVal[1];
  x := actor.state.params.IntVal[2];
  y := actor.state.params.IntVal[3];

  if overlay <> nil then
    overlay.AddLeftText(ticks, txt, x, y);
end;

//==============================================================================
//
// A_OverlayDrawRightText
//
//==============================================================================
procedure A_OverlayDrawRightText(actor: Pmobj_t);
var
  ticks: Integer;
  txt: string;
  x, y: Integer;
begin
  if not P_CheckStateParams(actor, 4) then
    Exit;

  ticks := actor.state.params.IntVal[0];
  txt := actor.state.params.StrVal[1];
  x := actor.state.params.IntVal[2];
  y := actor.state.params.IntVal[3];

  if overlay <> nil then
    overlay.AddRightText(ticks, txt, x, y);
end;

//==============================================================================
//
// A_OverlayDrawCenterText
//
//==============================================================================
procedure A_OverlayDrawCenterText(actor: Pmobj_t);
var
  ticks: Integer;
  txt: string;
  x, y: Integer;
begin
  if not P_CheckStateParams(actor, 4) then
    Exit;

  ticks := actor.state.params.IntVal[0];
  txt := actor.state.params.StrVal[1];
  x := actor.state.params.IntVal[2];
  y := actor.state.params.IntVal[3];

  if overlay <> nil then
    overlay.AddCenterText(ticks, txt, x, y);
end;

end.

end.
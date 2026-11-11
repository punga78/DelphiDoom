{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the console commands of the overlay                    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  overlaydrawtextleft, overlaydrawpixel, overlaydrawrect... (the Cmd*         }
{  procedures of psi_overlay.pas): the player draws on the overlay from the    }
{  console, only while a level is played.                                      }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Script.Overlay.Commands;

interface

/// <summary>Adds the commands of the overlay to the console</summary>
procedure OVR_RegisterCommands;

implementation

uses
  d_delphi,
  c_cmds,
  doomdef,
  sc_params,
  DelphiDoom.Scanner.Scanner,
  DelphiDoom.Engine.Scanner.Log,
  DelphiDoom.ScriptHost.Overlay.Types,
  psi_overlay;

//==============================================================================
//
// CmdOverlayDrawText
//
//==============================================================================
procedure CmdOverlayDrawText(const s1, s2: string; const align: Integer);
var
  ticks: Integer;
  x, y: Integer;
  sx, sy: string;
  msg: string;
  tmp1: string;
begin
  if gamestate <> GS_LEVEL then
  begin
    printf('Overlay drawer is available only when playing the game'#13#10);
    Exit;
  end;

  if s1 = '' then
  begin
    case align of
      OVR_ALIGN_LEFT:
        printf('overlaydrawtextleft [ticks] [x] [y] [message]'#13#10);
      OVR_ALIGN_RIGHT:
        printf('overlaydrawtextright [ticks] [x] [y] [message]'#13#10);
      else
        printf('overlaydrawtextcenter [ticks] [x] [y] [message]'#13#10);
    end;
    Exit;
  end;

  ticks := atoi(s1, -1);
  if ticks < 0 then
  begin
    printf('Ticks must be a positive number'#13#10);
    Exit;
  end;

  splitstring_ch(s2, sx, tmp1, ' ');
  splitstring_ch(tmp1, sy, msg, ' ');
  x := atoi(sx, -1);
  y := atoi(sy, -1);

  overlay.AddText(ticks, msg, align, x, y);
end;

//==============================================================================
//
// CmdOverlayPutPixel
//
//==============================================================================
procedure CmdOverlayPutPixel(const s1, s2: string);
var
  ticks: Integer;
  x, y: Integer;
  sx, sy: string;
  red, green, blue: byte;
  sred, sgreen, sblue: string;
  tmp1: string;
  tmp2: string;
begin
  if gamestate <> GS_LEVEL then
  begin
    printf('Overlay drawer is available only when playing the game'#13#10);
    Exit;
  end;

  if s1 = '' then
  begin
    printf('overlayputpixel [ticks] [x] [y] [red] [green] [blue]'#13#10);
    Exit;
  end;

  ticks := atoi(s1, -1);
  if ticks < 0 then
  begin
    printf('Ticks must be a positive number'#13#10);
    Exit;
  end;

  splitstring_ch(s2, sx, tmp1, ' ');
  splitstring_ch(tmp1, sy, tmp2, ' ');
  x := atoi(sx, -1);
  y := atoi(sy, -1);
  splitstring_ch(tmp2, sred, tmp1, ' ');
  splitstring_ch(tmp1, sgreen, sblue, ' ');
  red := atoi(sred, 0);
  green := atoi(sgreen, 0);
  blue := atoi(sblue, 0);

  overlay.AddPixel(ticks, red, green, blue, x, y);
end;

//==============================================================================
//
// CmdOverlayDrawTextLeft
//
//==============================================================================
procedure CmdOverlayDrawTextLeft(const s1, s2: string);
begin
  CmdOverlayDrawText(s1, s2, OVR_ALIGN_LEFT);
end;

//==============================================================================
//
// CmdOverlayDrawTextRight
//
//==============================================================================
procedure CmdOverlayDrawTextRight(const s1, s2: string);
begin
  CmdOverlayDrawText(s1, s2, OVR_ALIGN_RIGHT);
end;

//==============================================================================
//
// CmdOverlayDrawTextCenter
//
//==============================================================================
procedure CmdOverlayDrawTextCenter(const s1, s2: string);
begin
  CmdOverlayDrawText(s1, s2, OVR_ALIGN_CENTER);
end;

//==============================================================================
//
// CmdOverlayDrawRect
//
//==============================================================================
procedure CmdOverlayDrawRect(const s1, s2: string);
var
  ticks: Integer;
  x1, y1, x2, y2: Integer;
  red, green, blue: byte;
  sc: TScriptScanner;
begin
  if gamestate <> GS_LEVEL then
  begin
    printf('Overlay drawer is available only when playing the game'#13#10);
    Exit;
  end;

  if (s1 = '') or (s2 = '') then
  begin
    printf('overlaydrawrect [ticks] [x1] [y1] [x2] [y2] [red] [green] [blue]'#13#10);
    Exit;
  end;

  ticks := atoi(s1, -1);
  if ticks < 0 then
  begin
    printf('Ticks must be a positive number'#13#10);
    Exit;
  end;

  sc := TScriptScanner.Create(s2, TEngineScannerLog.Create);

  sc.MustGetInteger;
  x1 := sc.AsInteger;
  sc.MustGetInteger;
  y1 := sc.AsInteger;
  sc.MustGetInteger;
  x2 := sc.AsInteger;
  sc.MustGetInteger;
  y2 := sc.AsInteger;
  sc.MustGetInteger;
  red := sc.AsInteger;
  sc.MustGetInteger;
  green := sc.AsInteger;
  sc.MustGetInteger;
  blue := sc.AsInteger;
  sc.Free;

  overlay.AddRect(ticks, red, green, blue, x1, y1, x2, y2);
end;

//==============================================================================
//
// CmdOverlayDrawLine
//
//==============================================================================
procedure CmdOverlayDrawLine(const s1, s2: string);
var
  ticks: Integer;
  x1, y1, x2, y2: Integer;
  red, green, blue: byte;
  sc: TScriptScanner;
begin
  if gamestate <> GS_LEVEL then
  begin
    printf('Overlay drawer is available only when playing the game'#13#10);
    Exit;
  end;

  if (s1 = '') or (s2 = '') then
  begin
    printf('overlaydrawline [ticks] [x1] [y1] [x2] [y2] [red] [green] [blue]'#13#10);
    Exit;
  end;

  ticks := atoi(s1, -1);
  if ticks < 0 then
  begin
    printf('Ticks must be a positive number'#13#10);
    Exit;
  end;

  sc := TScriptScanner.Create(s2, TEngineScannerLog.Create);

  sc.MustGetInteger;
  x1 := sc.AsInteger;
  sc.MustGetInteger;
  y1 := sc.AsInteger;
  sc.MustGetInteger;
  x2 := sc.AsInteger;
  sc.MustGetInteger;
  y2 := sc.AsInteger;
  sc.MustGetInteger;
  red := sc.AsInteger;
  sc.MustGetInteger;
  green := sc.AsInteger;
  sc.MustGetInteger;
  blue := sc.AsInteger;
  sc.Free;

  overlay.AddLine(ticks, red, green, blue, x1, y1, x2, y2);
end;

//==============================================================================
//
// CmdOverlayDrawPatch
//
//==============================================================================
procedure CmdOverlayDrawPatch(const s1, s2: string);
var
  ticks: Integer;
  x, y: Integer;
  patchname: string;
  sc: TScriptScanner;
begin
  if gamestate <> GS_LEVEL then
  begin
    printf('Overlay drawer is available only when playing the game'#13#10);
    Exit;
  end;

  if (s1 = '') or (s2 = '') then
  begin
    printf('overlaydrawpatch [ticks] [x] [y] [patch]'#13#10);
    Exit;
  end;

  ticks := atoi(s1, -1);
  if ticks < 0 then
  begin
    printf('Ticks must be a positive number'#13#10);
    Exit;
  end;

  sc := TScriptScanner.Create(s2, TEngineScannerLog.Create);

  sc.MustGetInteger;
  x := sc.AsInteger;
  sc.MustGetInteger;
  y := sc.AsInteger;
  sc.MustGetString;
  patchname := sc.AsString;
  sc.Free;

  overlay.AddPatch(ticks, patchname, x, y);
end;

//==============================================================================
//
// CmdOverlayDrawPatchStretched
//
//==============================================================================
procedure CmdOverlayDrawPatchStretched(const s1, s2: string);
var
  ticks: Integer;
  x1, y1, x2, y2: Integer;
  patchname: string;
  sc: TScriptScanner;
begin
  if gamestate <> GS_LEVEL then
  begin
    printf('Overlay drawer is available only when playing the game'#13#10);
    Exit;
  end;

  if (s1 = '') or (s2 = '') then
  begin
    printf('overlaydrawpatchstretched [ticks] [x1] [y1] [x2] [y2] [patch]'#13#10);
    Exit;
  end;

  ticks := atoi(s1, -1);
  if ticks < 0 then
  begin
    printf('Ticks must be a positive number'#13#10);
    Exit;
  end;

  sc := TScriptScanner.Create(s2, TEngineScannerLog.Create);

  sc.MustGetInteger;
  x1 := sc.AsInteger;
  sc.MustGetInteger;
  y1 := sc.AsInteger;
  sc.MustGetInteger;
  x2 := sc.AsInteger;
  sc.MustGetInteger;
  y2 := sc.AsInteger;
  sc.MustGetString;
  patchname := sc.AsString;
  sc.Free;

  overlay.AddPatchStretched(ticks, patchname, x1, y1, x2, y2);
end;

//==============================================================================
//
// OVR_RegisterCommands
//
//==============================================================================
procedure OVR_RegisterCommands;
begin
  C_AddCmd('overlaydrawtextleft', @CmdOverlayDrawTextLeft);
  C_AddCmd('overlaydrawtextright', @CmdOverlayDrawTextRight);
  C_AddCmd('overlaydrawtextcenter', @CmdOverlayDrawTextCenter);
  C_AddCmd('overlaydrawpixel, overlayputpixel', @CmdOverlayPutPixel);
  C_AddCmd('overlaydrawrect', @CmdOverlayDrawRect);
  C_AddCmd('overlaydrawline', @CmdOverlayDrawLine);
  C_AddCmd('overlaydrawpatch', @CmdOverlayDrawPatch);
  C_AddCmd('overlaydrawpatchstretched', @CmdOverlayDrawPatchStretched);
end;

end.
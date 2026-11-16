{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - overlay canvas of an overlay with no screen       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.Overlay.NullCanvas;

interface

uses
  DelphiDoom.ScriptHost.Overlay.Intf,
  DelphiDoom.ScriptHost.Overlay.Types;

type
  /// <summary>
  ///   The canvas of an overlay that a script makes with TOverlay.Create: 320x200, no patches, no
  ///   font, never flashed, so what it draws stays in its own buffer
  /// </summary>
  TOverlayNullCanvas = class(TInterfacedObject, IOverlayCanvas)
  public
    function ScreenWidth: Integer;
    function ScreenHeight: Integer;
    function LevelTime: Integer;
    function FindColorIndex(const ARed, AGreen, ABlue: Byte): Byte;
    function FindPatchLump(const AName: string): Integer;
    function CachePatch(const ALump: Integer): Pointer;
    function FontPatch(const AChar: Char): Pointer;
    function IsFirstInterpolation: Boolean;
    procedure Warning(const AText: string);
    procedure MarkScreenDirty;
    procedure Flash(const AData: TOverlayFlashData);
  end;

implementation

function TOverlayNullCanvas.ScreenWidth: Integer;
begin
  Result := OVERLAYWIDTH;
end;

function TOverlayNullCanvas.ScreenHeight: Integer;
begin
  Result := OVERLAYHEIGHT;
end;

function TOverlayNullCanvas.LevelTime: Integer;
begin
  Result := 0;
end;

function TOverlayNullCanvas.FindColorIndex(const ARed, AGreen, ABlue: Byte): Byte;
begin
  Result := 0;
end;

function TOverlayNullCanvas.FindPatchLump(const AName: string): Integer;
begin
  Result := -1;
end;

function TOverlayNullCanvas.CachePatch(const ALump: Integer): Pointer;
begin
  Result := nil;
end;

function TOverlayNullCanvas.FontPatch(const AChar: Char): Pointer;
begin
  Result := nil;
end;

function TOverlayNullCanvas.IsFirstInterpolation: Boolean;
begin
  Result := False;
end;

procedure TOverlayNullCanvas.Warning(const AText: string);
begin
end;

procedure TOverlayNullCanvas.MarkScreenDirty;
begin
end;

procedure TOverlayNullCanvas.Flash(const AData: TOverlayFlashData);
begin
end;

end.

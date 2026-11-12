{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the frame for the parity tools                         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Parity.FrameSource;

interface

uses
  DelphiDoom.Parity.Types;

type
  /// <summary>
  ///   Gives the frame that the engine has just drawn (before it is blitted): in the modes of 8 bits the
  ///   buffer of the indexes of the palette and the palette, in the modes of 32 bits the buffer of the pixels
  /// </summary>
  TEngineParityFrameSource = class
  strict private
    FRgb: TArray<Cardinal>;
  public
    /// <summary>
    ///   The pixels of the frame, how big they are (1 or 4 bytes), where the view is and the hash of the palette
    ///   (0 in the modes of 32 bits); False if the engine has no screen yet
    /// </summary>
    function Capture(out APixels: Pointer; out ABytesPerPixel: Integer; out ALayout: TParityFrameLayout;
      out APaletteHash: UInt64): Boolean;
    /// <summary>The frame as 32 bit pixels in any mode (the 8 bit ones go through the palette); the width and height</summary>
    function ReadRgb(out AWidth, AHeight: Integer): Pointer;
  end;

implementation

uses
  DelphiDoom.Parity.Hasher,
  doomdef,
  i_video,
  r_draw,
  r_hires,
  v_data,
  v_video;

{ TEngineParityFrameSource }

function TEngineParityFrameSource.Capture(out APixels: Pointer; out ABytesPerPixel: Integer;
  out ALayout: TParityFrameLayout; out APaletteHash: UInt64): Boolean;
var
  LHasher: TParityHasher;
  LIndex: Integer;
begin
  Result := False;
  APaletteHash := 0;
  ALayout := Default(TParityFrameLayout);
  if videomode = vm8bit then
  begin
    if screens[SCN_FG] = nil then
      Exit;
    APixels := screens[SCN_FG];
    ABytesPerPixel := 1;
    LHasher.Reset;
    for LIndex := 0 to High(curpal) do
      LHasher.AddInteger(Integer(curpal[LIndex]));
    APaletteHash := LHasher.Value;
  end
  else
  begin
    if screen32 = nil then
      Exit;
    APixels := screen32;
    ABytesPerPixel := 4;
  end;
  ALayout.Width := SCREENWIDTH;
  ALayout.Height := SCREENHEIGHT;
  // the view as it is on the screen, always inside it
  ALayout.ViewX := viewwindowx;
  ALayout.ViewY := viewwindowy;
  ALayout.ViewWidth := scaledviewwidth;
  ALayout.ViewHeight := viewheight;
  if (ALayout.ViewX < 0) or (ALayout.ViewY < 0) or (ALayout.ViewX + ALayout.ViewWidth > ALayout.Width) or
    (ALayout.ViewY + ALayout.ViewHeight > ALayout.Height) then
  begin
    ALayout.ViewX := 0;
    ALayout.ViewY := 0;
    ALayout.ViewWidth := 0;
    ALayout.ViewHeight := 0;
  end;
  Result := True;
end;

function TEngineParityFrameSource.ReadRgb(out AWidth, AHeight: Integer): Pointer;
begin
  AWidth := SCREENWIDTH;
  AHeight := SCREENHEIGHT;
  SetLength(FRgb, AWidth * AHeight);
  I_ReadScreen32(@FRgb[0]);
  Result := @FRgb[0];
end;

end.

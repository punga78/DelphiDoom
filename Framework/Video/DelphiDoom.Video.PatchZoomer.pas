{******************************************************************************}
{                                                                              }
{  DelphiDoom: video library - the columns of a zoomed patch                    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Video.PatchZoomer;

// The loops are the ones of V_DrawPatchZoomed8 and V_DrawPatchZoomed32 of v_video; the fixed point arithmetic wraps on
// purpose: {$Q-} {$R-}
{$Q-}
{$R-}

interface

uses
  DelphiDoom.Video.PatchPainter,
  DelphiDoom.Video.Stretch;

var
  /// <summary>
  ///   The 32 bit palette of the game: it is the storage of videopal of v_video (declared there with absolute). It is a
  ///   global array and not a parameter on purpose: DrawColumns32 reads it at a fixed address, one instruction per pixel
  ///   less than with a pointer that is reloaded from the stack at every pixel (plan, 12.10 and 12.11)
  /// </summary>
  VideoZoomPalette: array[0..255] of LongWord;

type
  /// <summary>
  ///   The column loops of a patch drawn bigger or smaller (a zoom factor, 16.16) on a screen of 8 or 32 bit
  ///   pixels. Static, plain pointers: the size of the picture on the screen and the
  ///   steps (16.16) are worked out by the caller, nothing is called for a pixel
  /// </summary>
  TVideoPatchZoomer = class sealed
  public
    /// <summary>
    ///   Draws ADestinationWidth columns on an 8 bit screen; the first row of a post is
    ///   (delta * AScreenHeight) * AZoom div 65536 div 200 with APreserve (the screen is stretched
    ///   too) and delta * AZoom div 65536 without
    /// </summary>
    class procedure DrawColumns8(const APatch: PByte; const AColumnOffsets: PVideoIntegerRow;
      const ADestinationWidth, AStepX, AStepY: Integer; const ADestinationTop: PByte;
      const AStride, AScreenHeight, AZoom: Integer; const APreserve: Boolean;
      const ATranslation: PVideoByteRow); static;
    /// <summary>
    ///   The same on a 32 bit screen (ADestinationTop is a pixel and AStride counts pixels); the colors come from
    ///   VideoZoomPalette
    /// </summary>
    class procedure DrawColumns32(const APatch: PByte; const AColumnOffsets: PVideoIntegerRow;
      const ADestinationWidth, AStepX, AStepY: Integer; const ADestinationTop: PLongWord;
      const AStride, AScreenHeight, AZoom: Integer; const APreserve: Boolean); static;
  end;

implementation

{ TVideoPatchZoomer }

class procedure TVideoPatchZoomer.DrawColumns8(const APatch: PByte; const AColumnOffsets: PVideoIntegerRow;
  const ADestinationWidth, AStepX, AStepY: Integer; const ADestinationTop: PByte;
  const AStride, AScreenHeight, AZoom: Integer; const APreserve: Boolean; const ATranslation: PVideoByteRow);
var
  LCount: Integer;
  LColumn: Integer;
  LPost: PByte;
  LDestinationTop: PByte;
  LDestination: PByte;
  LSource: PByte;
  LFractionX: Integer;
  LFractionY: Integer;
  LLastY: Integer;
  LCurrentY: Integer;
  LDelta: Integer;
  LPreviousDelta: Integer;
  LTallPatch: Boolean;
begin
  LFractionX := 0;
  LDestinationTop := ADestinationTop;
  LColumn := 0;
  while LColumn < ADestinationWidth do
  begin
    LPost := PByte(NativeInt(APatch) + AColumnOffsets[Cardinal(LFractionX) shr 16]);
    LDelta := 0;
    LTallPatch := False;
    // step through the posts in a column
    while LPost[0] <> $FF do
    begin
      LSource := PByte(NativeInt(LPost) + 3);
      LDelta := LDelta + LPost[0];
      if APreserve then
        LDestination := PByte(NativeInt(LDestinationTop) + ((LDelta * AScreenHeight) * AZoom div 65536 div 200) * AStride)
      else
        LDestination := PByte(NativeInt(LDestinationTop) + (LDelta * AZoom div 65536) * AStride);
      LCount := LPost[1];
      LFractionY := 0;
      LLastY := 0;

      while LCount > 0 do
      begin
        LDestination^ := ATranslation[LSource^];
        Inc(LDestination, AStride);
        LFractionY := LFractionY + AStepY;
        LCurrentY := Cardinal(LFractionY) shr 16;
        if LCurrentY > LLastY then
        begin
          LLastY := LCurrentY;
          Inc(LSource);
          Dec(LCount);
        end;
      end;
      if not LTallPatch then
      begin
        LPreviousDelta := LPost[0];
        LPost := PByte(NativeInt(LPost) + LPost[1] + 4);
        if LPost[0] > LPreviousDelta then
          LDelta := 0
        else
          LTallPatch := True;
      end
      else
        LPost := PByte(NativeInt(LPost) + LPost[1] + 4);
    end;
    Inc(LDestinationTop);
    Inc(LColumn);

    LFractionX := LFractionX + AStepX;
  end;
end;

class procedure TVideoPatchZoomer.DrawColumns32(const APatch: PByte; const AColumnOffsets: PVideoIntegerRow;
  const ADestinationWidth, AStepX, AStepY: Integer; const ADestinationTop: PLongWord;
  const AStride, AScreenHeight, AZoom: Integer; const APreserve: Boolean);
var
  LCount: Integer;
  LColumn: Integer;
  LPost: PByte;
  LDestinationTop: PLongWord;
  LDestination: PLongWord;
  LSource: PByte;
  LFractionX: Integer;
  LFractionY: Integer;
  LLastY: Integer;
  LCurrentY: Integer;
  LDelta: Integer;
  LPreviousDelta: Integer;
  LTallPatch: Boolean;
begin
  LFractionX := 0;
  LDestinationTop := ADestinationTop;
  LColumn := 0;
  while LColumn < ADestinationWidth do
  begin
    LPost := PByte(NativeInt(APatch) + AColumnOffsets[Cardinal(LFractionX) shr 16]);
    LDelta := 0;
    LTallPatch := False;
    // step through the posts in a column
    while LPost[0] <> $FF do
    begin
      LSource := PByte(NativeInt(LPost) + 3);
      LDelta := LDelta + LPost[0];
      if APreserve then
        LDestination := PLongWord(NativeInt(LDestinationTop) +
          ((LDelta * AScreenHeight) * AZoom div 65536 div 200) * AStride * SizeOf(LongWord))
      else
        LDestination := PLongWord(NativeInt(LDestinationTop) + (LDelta * AZoom div 65536) * AStride * SizeOf(LongWord));
      LCount := LPost[1];
      LFractionY := 0;
      LLastY := 0;

      while LCount > 0 do
      begin
        LDestination^ := VideoZoomPalette[LSource^];
        Inc(LDestination, AStride);
        LFractionY := LFractionY + AStepY;
        LCurrentY := Cardinal(LFractionY) shr 16;
        if LCurrentY > LLastY then
        begin
          LLastY := LCurrentY;
          Inc(LSource);
          Dec(LCount);
        end;
      end;
      if not LTallPatch then
      begin
        LPreviousDelta := LPost[0];
        LPost := PByte(NativeInt(LPost) + LPost[1] + 4);
        if LPost[0] > LPreviousDelta then
          LDelta := 0
        else
          LTallPatch := True;
      end
      else
        LPost := PByte(NativeInt(LPost) + LPost[1] + 4);
    end;
    Inc(LDestinationTop);
    Inc(LColumn);

    LFractionX := LFractionX + AStepX;
  end;
end;

end.

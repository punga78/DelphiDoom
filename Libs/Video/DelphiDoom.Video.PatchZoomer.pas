{******************************************************************************}
{                                                                              }
{  DelphiDoom: video library - the columns of a zoomed patch                    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Video.PatchZoomer;

// The loops are the ones of V_DrawPatchZoomed8 and V_DrawPatchZoomed32 of v_video; the fixed point
// arithmetic wraps on purpose: {$Q-} {$R-}
{$Q-}
{$R-}

interface

uses
  DelphiDoom.Video.PatchPainter,
  DelphiDoom.Video.Stretch;

type
  /// <summary>
  ///   The column loops of a patch drawn bigger or smaller (a zoom factor, 16.16) on a screen of 8
  ///   or 32 bit pixels. Static, plain pointers: the size of the picture on the screen and the
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
    /// <summary>As DrawColumns8 on a 32 bit screen through the palette (no translation)</summary>
    class procedure DrawColumns32(const APatch: PByte; const AColumnOffsets: PVideoIntegerRow;
      const ADestinationWidth, AStepX, AStepY: Integer; const ADestinationTop: PLongWord;
      const AStride, AScreenHeight, AZoom: Integer; const APreserve: Boolean;
      const APalette: PVideoLongWordRow); static;
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
  const AStride, AScreenHeight, AZoom: Integer; const APreserve: Boolean; const APalette: PVideoLongWordRow);
var
  LCount: Integer;
  LColumn: Integer;
  LPost: PByte;
  LDestinationTop: PVideoLongWordRow;
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
  LDestinationTop := PVideoLongWordRow(ADestinationTop);
  LColumn := 0;
  while LColumn < ADestinationWidth do
  begin
    LPost := PByte(NativeInt(APatch) + AColumnOffsets[LFractionX div 65536]);
    LDelta := 0;
    LTallPatch := False;
    // step through the posts in a column
    while LPost[0] <> $FF do
    begin
      LSource := PByte(NativeInt(LPost) + 3);
      LDelta := LDelta + LPost[0];
      if APreserve then
        LDestination := @LDestinationTop[((LDelta * AScreenHeight) * AZoom div 65536 div 200) * AStride]
      else
        LDestination := @LDestinationTop[(LDelta * AZoom div 65536) * AStride];
      LCount := LPost[1];
      LFractionY := 0;
      LLastY := 0;

      while LCount > 0 do
      begin
        LDestination^ := APalette[LSource^];
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
    LDestinationTop := @LDestinationTop[1];
    Inc(LColumn);

    LFractionX := LFractionX + AStepX;
  end;
end;

end.

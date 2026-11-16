{******************************************************************************}
{                                                                              }
{  DelphiDoom: video library - the columns of a patch on a 32 bit screen        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Video.PatchPainter32;

// The loops are the ones of V_DrawPatch32, V_DrawPatchTransparent32 and V_DrawPatchTransparent32_MT
// of v_video; the fixed point arithmetic wraps on purpose: {$Q-} {$R-}
{$Q-}
{$R-}

interface

uses
  DelphiDoom.Video.PatchPainter,
  DelphiDoom.Video.Stretch;

type
  /// <summary>
  ///   The column loops of the patches on a screen of 32 bit pixels: the colors come from a
  ///   palette of 256 entries (with an optional translation of the indexes). One static method
  ///   for every operation on the pixel, plain pointers, nothing is called for a pixel
  /// </summary>
  TVideoPatchPainter32 = class sealed
  public
    /// <summary>
    ///   Draws AWidth columns of the patch one to one starting at ADestinationTop (the pixel of the
    ///   first column of the top row of the patch); AStride is the width of the screen in pixels;
    ///   ATranslation may be nil
    /// </summary>
    class procedure DrawColumns32(const APatch: PByte; const AColumnOffsets: PVideoIntegerRow;
      const AWidth: Integer; const ADestinationTop: PLongWord; const AStride: Integer;
      const APalette: PVideoLongWordRow; const ATranslation: PVideoByteRow); static;
    /// <summary>
    ///   Draws the patch on ADestinationWidth columns of the screen, stretched (steps 16.16);
    ///   the first row of a post is Round(top delta * AScreenHeight / 200); ATranslation may be nil
    /// </summary>
    class procedure DrawColumnsStretched32(const APatch: PByte; const AColumnOffsets: PVideoIntegerRow;
      const ADestinationWidth, AStepX, AStepY: Integer; const ADestinationTop: PLongWord;
      const AStride, AScreenHeight: Integer; const APalette: PVideoLongWordRow;
      const ATranslation: PVideoByteRow); static;
    /// <summary>
    ///   One to one, the color of the screen is the mean of its channels with the ones of the patch
    ///   (what R_ColorMean of r_hires does: each channel halved sum, alpha 0); only the columns whose
    ///   number mod AIndexCount is AIndex are drawn (AIndexCount 1: all of them)
    /// </summary>
    class procedure DrawColumnsTransparent32(const APatch: PByte; const AColumnOffsets: PVideoIntegerRow;
      const AWidth: Integer; const ADestinationTop: PLongWord; const AStride: Integer;
      const APalette: PVideoLongWordRow; const AIndex, AIndexCount: Integer); static;
    /// <summary>As DrawColumnsTransparent32 with the alpha of the screen pixel set to $80 (OpenGL)</summary>
    class procedure DrawColumnsTransparentAlpha32(const APatch: PByte; const AColumnOffsets: PVideoIntegerRow;
      const AWidth: Integer; const ADestinationTop: PLongWord; const AStride: Integer;
      const APalette: PVideoLongWordRow); static;
    /// <summary>
    ///   Stretched, with the mean of DrawColumnsTransparent32; the first row of a post is
    ///   top delta * AScreenHeight div 200
    /// </summary>
    class procedure DrawColumnsStretchedTransparent32(const APatch: PByte; const AColumnOffsets: PVideoIntegerRow;
      const ADestinationWidth, AStepX, AStepY: Integer; const ADestinationTop: PLongWord;
      const AStride, AScreenHeight: Integer; const APalette: PVideoLongWordRow;
      const AIndex, AIndexCount: Integer); static;
    /// <summary>As DrawColumnsStretchedTransparent32 with the alpha of the screen pixel set to $80 (OpenGL)</summary>
    class procedure DrawColumnsStretchedTransparentAlpha32(const APatch: PByte;
      const AColumnOffsets: PVideoIntegerRow; const ADestinationWidth, AStepX, AStepY: Integer;
      const ADestinationTop: PLongWord; const AStride, AScreenHeight: Integer;
      const APalette: PVideoLongWordRow); static;
  end;

implementation

// The mean of two colors: the same arithmetic as R_ColorMean (r_hires), which a library cannot
// call. The red, green and blue of each are halved sums and the alpha of the result is 0
function ColorMean(const AColor1, AColor2: LongWord): LongWord; inline;
var
  LRed1, LGreen1, LBlue1: Byte;
  LRed2, LGreen2, LBlue2: Byte;
  LRed, LGreen, LBlue: LongWord;
begin
  LRed1 := AColor1;
  LGreen1 := AColor1 shr 8;
  LBlue1 := AColor1 shr 16;
  LRed2 := AColor2;
  LGreen2 := AColor2 shr 8;
  LBlue2 := AColor2 shr 16;

  LRed := (LRed1 + LRed2) shr 1;
  LGreen := (LGreen1 + LGreen2) shr 1;
  LBlue := (LBlue1 + LBlue2) shr 1;
  Result := LRed + LGreen shl 8 + LBlue shl 16;
end;

{ TVideoPatchPainter32 }

class procedure TVideoPatchPainter32.DrawColumns32(const APatch: PByte; const AColumnOffsets: PVideoIntegerRow;
  const AWidth: Integer; const ADestinationTop: PLongWord; const AStride: Integer;
  const APalette: PVideoLongWordRow; const ATranslation: PVideoByteRow);
var
  LCount: Integer;
  LColumn: Integer;
  LPost: PByte;
  LDestinationTop: PVideoLongWordRow;
  LDestination: PLongWord;
  LSource: PByte;
  LDelta: Integer;
  LPreviousDelta: Integer;
  LTallPatch: Boolean;
begin
  LColumn := 0;
  LDestinationTop := PVideoLongWordRow(ADestinationTop);
  while LColumn < AWidth do
  begin
    LPost := PByte(NativeInt(APatch) + AColumnOffsets[LColumn]);
    LDelta := 0;
    LTallPatch := False;
    // step through the posts in a column
    while LPost[0] <> $FF do
    begin
      LSource := PByte(NativeInt(LPost) + 3);
      LDelta := LDelta + LPost[0];
      LDestination := @LDestinationTop[LDelta * AStride];
      LCount := LPost[1];

      if ATranslation <> nil then
      begin
        while LCount > 0 do
        begin
          LDestination^ := APalette[ATranslation[LSource^]];
          Inc(LSource);
          Inc(LDestination, AStride);
          Dec(LCount);
        end;
      end
      else
      begin
        while LCount > 0 do
        begin
          LDestination^ := APalette[LSource^];
          Inc(LSource);
          Inc(LDestination, AStride);
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
    Inc(LColumn);
    LDestinationTop := @LDestinationTop[1];
  end;
end;

class procedure TVideoPatchPainter32.DrawColumnsStretched32(const APatch: PByte;
  const AColumnOffsets: PVideoIntegerRow; const ADestinationWidth, AStepX, AStepY: Integer;
  const ADestinationTop: PLongWord; const AStride, AScreenHeight: Integer;
  const APalette: PVideoLongWordRow; const ATranslation: PVideoByteRow);
var
  LCount: Integer;
  LColumn: Integer;
  LPost: PByte;
  LDestinationTop: PVideoLongWordRow;
  LDestination: PLongWord;
  LSource: PByte;
  LValue: LongWord;
  LFractionX: Integer;
  LFractionY: Integer;
  LLastY: Integer;
  LCurrentY: Integer;
  LDelta: Integer;
  LPreviousDelta: Integer;
  LTallPatch: Boolean;
begin
  LFractionX := 0;
  LColumn := 0;
  LDestinationTop := PVideoLongWordRow(ADestinationTop);
  if ATranslation <> nil then
  begin
    while LColumn < ADestinationWidth do
    begin
      LPost := PByte(NativeInt(APatch) + AColumnOffsets[LFractionX div 65536]);
      LDelta := 0;
      LTallPatch := False;
      // step through the posts in a column
      while LPost[0] <> $FF do
      begin
        LSource := PByte(NativeInt(LPost) + 3);
        LValue := APalette[ATranslation[LSource^]];
        LDelta := LDelta + LPost[0];
        LDestination := @LDestinationTop[(Round(LDelta * AScreenHeight / 200) * AStride)];
        LCount := LPost[1];
        LFractionY := 0;
        LLastY := 0;

        while LCount > 0 do
        begin
          LDestination^ := LValue;
          Inc(LDestination, AStride);
          LFractionY := LFractionY + AStepY;
          LCurrentY := Cardinal(LFractionY) shr 16;
          if LCurrentY > LLastY then
          begin
            LLastY := LCurrentY;
            Inc(LSource);
            LValue := APalette[ATranslation[LSource^]];
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
      Inc(LColumn);
      LDestinationTop := @LDestinationTop[1];

      LFractionX := LFractionX + AStepX;
    end;
  end
  else
  begin
    while LColumn < ADestinationWidth do
    begin
      LPost := PByte(NativeInt(APatch) + AColumnOffsets[LFractionX div 65536]);
      LDelta := 0;
      LTallPatch := False;
      // step through the posts in a column
      while LPost[0] <> $FF do
      begin
        LSource := PByte(NativeInt(LPost) + 3);
        LValue := APalette[LSource^];
        LDelta := LDelta + LPost[0];
        LDestination := @LDestinationTop[(Round(LDelta * AScreenHeight / 200) * AStride)];
        LCount := LPost[1];
        LFractionY := 0;
        LLastY := 0;

        while LCount > 0 do
        begin
          LDestination^ := LValue;
          Inc(LDestination, AStride);
          LFractionY := LFractionY + AStepY;
          LCurrentY := Cardinal(LFractionY) shr 16;
          if LCurrentY > LLastY then
          begin
            LLastY := LCurrentY;
            Inc(LSource);
            LValue := APalette[LSource^];
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
      Inc(LColumn);
      LDestinationTop := @LDestinationTop[1];

      LFractionX := LFractionX + AStepX;
    end;
  end;
end;

class procedure TVideoPatchPainter32.DrawColumnsTransparent32(const APatch: PByte;
  const AColumnOffsets: PVideoIntegerRow; const AWidth: Integer; const ADestinationTop: PLongWord;
  const AStride: Integer; const APalette: PVideoLongWordRow; const AIndex, AIndexCount: Integer);
var
  LCount: Integer;
  LColumn: Integer;
  LPost: PByte;
  LDestinationTop: PVideoLongWordRow;
  LDestination: PLongWord;
  LSource: PByte;
  LDelta: Integer;
  LPreviousDelta: Integer;
  LTallPatch: Boolean;
begin
  LColumn := 0;
  LDestinationTop := PVideoLongWordRow(ADestinationTop);
  while LColumn < AWidth do
  begin
    // AIndexCount 1 is the single thread: no remainder to compute
    if (AIndexCount = 1) or (LColumn mod AIndexCount = AIndex) then
    begin
      LPost := PByte(NativeInt(APatch) + AColumnOffsets[LColumn]);
      LDelta := 0;
      LTallPatch := False;
      // step through the posts in a column
      while LPost[0] <> $FF do
      begin
        LSource := PByte(NativeInt(LPost) + 3);
        LDelta := LDelta + LPost[0];
        LDestination := @LDestinationTop[LDelta * AStride];
        LCount := LPost[1];

        while LCount > 0 do
        begin
          LDestination^ := ColorMean(APalette[LSource^], LDestination^);
          Inc(LSource);
          Inc(LDestination, AStride);
          Dec(LCount);
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
    end;
    Inc(LColumn);
    LDestinationTop := @LDestinationTop[1];
  end;
end;

class procedure TVideoPatchPainter32.DrawColumnsTransparentAlpha32(const APatch: PByte;
  const AColumnOffsets: PVideoIntegerRow; const AWidth: Integer; const ADestinationTop: PLongWord;
  const AStride: Integer; const APalette: PVideoLongWordRow);
var
  LCount: Integer;
  LColumn: Integer;
  LPost: PByte;
  LDestinationTop: PVideoLongWordRow;
  LDestination: PLongWord;
  LAlpha: PByte;
  LSource: PByte;
  LDelta: Integer;
  LPreviousDelta: Integer;
  LTallPatch: Boolean;
begin
  LColumn := 0;
  LDestinationTop := PVideoLongWordRow(ADestinationTop);
  while LColumn < AWidth do
  begin
    LPost := PByte(NativeInt(APatch) + AColumnOffsets[LColumn]);
    LDelta := 0;
    LTallPatch := False;
    // step through the posts in a column
    while LPost[0] <> $FF do
    begin
      LSource := PByte(NativeInt(LPost) + 3);
      LDelta := LDelta + LPost[0];
      LDestination := @LDestinationTop[LDelta * AStride];
      LCount := LPost[1];

      while LCount > 0 do
      begin
        LDestination^ := ColorMean(APalette[LSource^], LDestination^);
        LAlpha := PByte(NativeInt(LDestination) + 3);
        LAlpha^ := $80;
        Inc(LSource);
        Inc(LDestination, AStride);
        Dec(LCount);
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
    Inc(LColumn);
    LDestinationTop := @LDestinationTop[1];
  end;
end;

class procedure TVideoPatchPainter32.DrawColumnsStretchedTransparent32(const APatch: PByte;
  const AColumnOffsets: PVideoIntegerRow; const ADestinationWidth, AStepX, AStepY: Integer;
  const ADestinationTop: PLongWord; const AStride, AScreenHeight: Integer; const APalette: PVideoLongWordRow;
  const AIndex, AIndexCount: Integer);
var
  LCount: Integer;
  LColumn: Integer;
  LPost: PByte;
  LDestinationTop: PVideoLongWordRow;
  LDestination: PLongWord;
  LSource: PByte;
  LValue: LongWord;
  LFractionX: Integer;
  LFractionY: Integer;
  LLastY: Integer;
  LCurrentY: Integer;
  LDelta: Integer;
  LPreviousDelta: Integer;
  LTallPatch: Boolean;
begin
  LFractionX := 0;
  LColumn := 0;
  LDestinationTop := PVideoLongWordRow(ADestinationTop);
  while LColumn < ADestinationWidth do
  begin
    if (AIndexCount = 1) or (LColumn mod AIndexCount = AIndex) then
    begin
      LPost := PByte(NativeInt(APatch) + AColumnOffsets[LFractionX div 65536]);
      LDelta := 0;
      LTallPatch := False;
      // step through the posts in a column
      while LPost[0] <> $FF do
      begin
        LSource := PByte(NativeInt(LPost) + 3);
        LValue := APalette[LSource^];
        LDelta := LDelta + LPost[0];
        LDestination := @LDestinationTop[((LDelta * AScreenHeight div 200) * AStride)];
        LCount := LPost[1];
        LFractionY := 0;
        LLastY := 0;

        while LCount > 0 do
        begin
          LDestination^ := ColorMean(LValue, LDestination^);
          Inc(LDestination, AStride);
          LFractionY := LFractionY + AStepY;
          LCurrentY := Cardinal(LFractionY) shr 16;
          if LCurrentY > LLastY then
          begin
            LLastY := LCurrentY;
            Inc(LSource);
            LValue := APalette[LSource^];
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
    end;
    Inc(LColumn);
    LDestinationTop := @LDestinationTop[1];

    LFractionX := LFractionX + AStepX;
  end;
end;

class procedure TVideoPatchPainter32.DrawColumnsStretchedTransparentAlpha32(const APatch: PByte;
  const AColumnOffsets: PVideoIntegerRow; const ADestinationWidth, AStepX, AStepY: Integer;
  const ADestinationTop: PLongWord; const AStride, AScreenHeight: Integer; const APalette: PVideoLongWordRow);
var
  LCount: Integer;
  LColumn: Integer;
  LPost: PByte;
  LDestinationTop: PVideoLongWordRow;
  LDestination: PLongWord;
  LAlpha: PByte;
  LSource: PByte;
  LValue: LongWord;
  LFractionX: Integer;
  LFractionY: Integer;
  LLastY: Integer;
  LCurrentY: Integer;
  LDelta: Integer;
  LPreviousDelta: Integer;
  LTallPatch: Boolean;
begin
  LFractionX := 0;
  LColumn := 0;
  LDestinationTop := PVideoLongWordRow(ADestinationTop);
  while LColumn < ADestinationWidth do
  begin
    LPost := PByte(NativeInt(APatch) + AColumnOffsets[LFractionX div 65536]);
    LDelta := 0;
    LTallPatch := False;
    // step through the posts in a column
    while LPost[0] <> $FF do
    begin
      LSource := PByte(NativeInt(LPost) + 3);
      LValue := APalette[LSource^];
      LDelta := LDelta + LPost[0];
      LDestination := @LDestinationTop[((LDelta * AScreenHeight div 200) * AStride)];
      LCount := LPost[1];
      LFractionY := 0;
      LLastY := 0;

      while LCount > 0 do
      begin
        LDestination^ := ColorMean(LValue, LDestination^);
        LAlpha := PByte(NativeInt(LDestination) + 3);
        LAlpha^ := $80;
        Inc(LDestination, AStride);
        LFractionY := LFractionY + AStepY;
        LCurrentY := Cardinal(LFractionY) shr 16;
        if LCurrentY > LLastY then
        begin
          LLastY := LCurrentY;
          Inc(LSource);
          LValue := APalette[LSource^];
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
    Inc(LColumn);
    LDestinationTop := @LDestinationTop[1];

    LFractionX := LFractionX + AStepX;
  end;
end;

end.

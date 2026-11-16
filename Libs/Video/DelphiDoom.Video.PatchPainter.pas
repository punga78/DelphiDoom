{******************************************************************************}
{                                                                              }
{  DelphiDoom: video library - the columns of a patch on an 8 bit screen        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Video.PatchPainter;

// The loops are the ones of V_DrawPatch8, V_DrawPatchFlipped, V_DrawPatchTransparent8 and
// V_DrawPatchTransparent8_MT of v_video; the fixed point arithmetic wraps on purpose: {$Q-} {$R-}
{$Q-}
{$R-}

interface

uses
  DelphiDoom.Video.Stretch;

type
  PVideoIntegerRow = ^TVideoIntegerRow;
  TVideoIntegerRow = packed array[0..MaxInt div 8 - 1] of Integer;

  /// <summary>
  ///   The column loops of the patches on a screen of 8 bit pixels: they walk the posts of every
  ///   column of a patch and write them one to one (no stretching) or stretched, opaque or
  ///   through a table of transparency. One static method for every operation on the pixel: the
  ///   operation is in the loop, so nothing is called for a pixel or for a column
  /// </summary>
  TVideoPatchPainter = class sealed
  public
    /// <summary>
    ///   Draws AWidth columns of the patch starting at ADestinationTop (the pixel of the first
    ///   column of the top row of the patch). AColumnOffsets are the offsets of the columns from
    ///   the start of the patch; AStride is the width of the screen; with AFlipped the columns
    ///   are drawn from the last to the first (a mirror image)
    /// </summary>
    class procedure DrawColumns8(const APatch: PByte; const AColumnOffsets: PVideoIntegerRow;
      const AWidth: Integer; const ADestinationTop: PByte; const AStride: Integer;
      const ATranslation: PVideoByteRow; const AFlipped: Boolean); static;
    /// <summary>
    ///   Draws the patch on ADestinationWidth columns of the screen, stretched: the steps of the
    ///   source column and of the source row are 16.16 fixed point (AStepX, AStepY); the first
    ///   row of a post is its top delta times AScreenHeight div 200
    /// </summary>
    class procedure DrawColumnsStretched8(const APatch: PByte; const AColumnOffsets: PVideoIntegerRow;
      const ADestinationWidth, AStepX, AStepY: Integer; const ADestinationTop: PByte;
      const AStride, AScreenHeight: Integer; const ATranslation: PVideoByteRow); static;
    /// <summary>
    ///   As DrawColumns8 (not flipped) with the color of the screen mixed with the one of the patch
    ///   through ATable (65536 entries: screen color * 256 + patch color); only the columns whose
    ///   number mod AIndexCount is AIndex are drawn (AIndexCount 1: all of them)
    /// </summary>
    class procedure DrawColumnsTransparent8(const APatch: PByte; const AColumnOffsets: PVideoIntegerRow;
      const AWidth: Integer; const ADestinationTop: PByte; const AStride: Integer;
      const ATranslation, ATable: PVideoByteRow; const AIndex, AIndexCount: Integer); static;
    /// <summary>As DrawColumnsStretched8 through the table of transparency, with the columns of one thread</summary>
    class procedure DrawColumnsStretchedTransparent8(const APatch: PByte; const AColumnOffsets: PVideoIntegerRow;
      const ADestinationWidth, AStepX, AStepY: Integer; const ADestinationTop: PByte;
      const AStride, AScreenHeight: Integer; const ATranslation, ATable: PVideoByteRow;
      const AIndex, AIndexCount: Integer); static;
  end;

implementation

{ TVideoPatchPainter }

class procedure TVideoPatchPainter.DrawColumns8(const APatch: PByte; const AColumnOffsets: PVideoIntegerRow;
  const AWidth: Integer; const ADestinationTop: PByte; const AStride: Integer;
  const ATranslation: PVideoByteRow; const AFlipped: Boolean);
var
  LCount: Integer;
  LColumn: Integer;
  LPost: PByte;
  LDestinationTop: PByte;
  LDestination: PByte;
  LSource: PByte;
  LDelta: Integer;
  LPreviousDelta: Integer;
  LTallPatch: Boolean;
begin
  LColumn := 0;
  LDestinationTop := ADestinationTop;
  while LColumn < AWidth do
  begin
    if AFlipped then
      LPost := PByte(NativeInt(APatch) + AColumnOffsets[AWidth - 1 - LColumn])
    else
      LPost := PByte(NativeInt(APatch) + AColumnOffsets[LColumn]);
    LDelta := 0;
    LTallPatch := False;
    // step through the posts in a column (post: top delta, length, a padding byte, the pixels)
    while LPost[0] <> $FF do
    begin
      LSource := PByte(NativeInt(LPost) + 3);
      LDelta := LDelta + LPost[0];
      LDestination := PByte(NativeInt(LDestinationTop) + LDelta * AStride);
      LCount := LPost[1];

      while LCount > 0 do
      begin
        LDestination^ := ATranslation[LSource^];
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
    Inc(LDestinationTop);
  end;
end;

class procedure TVideoPatchPainter.DrawColumnsStretched8(const APatch: PByte;
  const AColumnOffsets: PVideoIntegerRow; const ADestinationWidth, AStepX, AStepY: Integer;
  const ADestinationTop: PByte; const AStride, AScreenHeight: Integer; const ATranslation: PVideoByteRow);
var
  LCount: Integer;
  LColumn: Integer;
  LPost: PByte;
  LDestinationTop: PByte;
  LDestination: PByte;
  LSource: PByte;
  LValue: Byte;
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
  LDestinationTop := ADestinationTop;
  while LColumn < ADestinationWidth do
  begin
    LPost := PByte(NativeInt(APatch) + AColumnOffsets[Cardinal(LFractionX) shr 16]);
    LDelta := 0;
    LTallPatch := False;
    // step through the posts in a column
    while LPost[0] <> $FF do
    begin
      LSource := PByte(NativeInt(LPost) + 3);
      LValue := ATranslation[LSource^];
      LDelta := LDelta + LPost[0];
      LDestination := PByte(NativeInt(LDestinationTop) + ((LDelta * AScreenHeight) div 200) * AStride);
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
          LValue := ATranslation[LSource^];
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
    Inc(LDestinationTop);

    LFractionX := LFractionX + AStepX;
  end;
end;

class procedure TVideoPatchPainter.DrawColumnsTransparent8(const APatch: PByte;
  const AColumnOffsets: PVideoIntegerRow; const AWidth: Integer; const ADestinationTop: PByte;
  const AStride: Integer; const ATranslation, ATable: PVideoByteRow; const AIndex, AIndexCount: Integer);
var
  LCount: Integer;
  LColumn: Integer;
  LPost: PByte;
  LDestinationTop: PByte;
  LDestination: PByte;
  LSource: PByte;
  LDelta: Integer;
  LPreviousDelta: Integer;
  LTallPatch: Boolean;
begin
  LColumn := 0;
  LDestinationTop := ADestinationTop;
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
        LDestination := PByte(NativeInt(LDestinationTop) + LDelta * AStride);
        LCount := LPost[1];

        while LCount > 0 do
        begin
          LDestination^ := ATable[LDestination^ shl 8 + ATranslation[LSource^]];
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
    Inc(LDestinationTop);
  end;
end;

class procedure TVideoPatchPainter.DrawColumnsStretchedTransparent8(const APatch: PByte;
  const AColumnOffsets: PVideoIntegerRow; const ADestinationWidth, AStepX, AStepY: Integer;
  const ADestinationTop: PByte; const AStride, AScreenHeight: Integer; const ATranslation, ATable: PVideoByteRow;
  const AIndex, AIndexCount: Integer);
var
  LCount: Integer;
  LColumn: Integer;
  LPost: PByte;
  LDestinationTop: PByte;
  LDestination: PByte;
  LSource: PByte;
  LValue: Byte;
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
  LDestinationTop := ADestinationTop;
  while LColumn < ADestinationWidth do
  begin
    if (AIndexCount = 1) or (LColumn mod AIndexCount = AIndex) then
    begin
      LPost := PByte(NativeInt(APatch) + AColumnOffsets[Cardinal(LFractionX) shr 16]);
      LDelta := 0;
      LTallPatch := False;
      // step through the posts in a column
      while LPost[0] <> $FF do
      begin
        LSource := PByte(NativeInt(LPost) + 3);
        LValue := ATranslation[LSource^];
        LDelta := LDelta + LPost[0];
        LDestination := PByte(NativeInt(LDestinationTop) + ((LDelta * AScreenHeight) div 200) * AStride);
        LCount := LPost[1];
        LFractionY := 0;
        LLastY := 0;

        while LCount > 0 do
        begin
          LDestination^ := ATable[LDestination^ shl 8 + LValue];
          Inc(LDestination, AStride);
          LFractionY := LFractionY + AStepY;
          LCurrentY := Cardinal(LFractionY) shr 16;
          if LCurrentY > LLastY then
          begin
            LLastY := LCurrentY;
            Inc(LSource);
            LValue := ATranslation[LSource^];
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
    Inc(LDestinationTop);

    LFractionX := LFractionX + AStepX;
  end;
end;

end.

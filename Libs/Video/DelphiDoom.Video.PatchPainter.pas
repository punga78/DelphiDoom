{******************************************************************************}
{                                                                              }
{  DelphiDoom: video library - the columns of a patch on an 8 bit screen        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Video.PatchPainter;

interface

uses
  DelphiDoom.Video.Stretch;

type
  PVideoIntegerRow = ^TVideoIntegerRow;
  TVideoIntegerRow = packed array[0..MaxInt div 8 - 1] of Integer;

  /// <summary>
  ///   The column loop of V_DrawPatch8 and V_DrawPatchFlipped: it walks the posts of every
  ///   column of a patch and writes them translated on a screen of 8 bit pixels, one to one
  ///   (no stretching). Static, on plain pointers: nothing is called for a pixel or for a column
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

end.

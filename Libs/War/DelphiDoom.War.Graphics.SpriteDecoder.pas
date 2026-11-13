{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - decoding of a sprite record                       }
{                                                                              }
{  Port of war1 (acoto87/war1), wres_loadSpriteResource of war_resources.c,    }
{  (c) 2019 Alejandro Coto Gutierrez, zlib License (see Libs\War\LICENSE-      }
{  war1.txt). This is an altered version, not the original.                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Graphics.SpriteDecoder;

interface

uses
  System.SysUtils, DelphiDoom.War.Graphics.Types;

type
  /// <summary>
  ///   A sprite record is the number of frames (16 bit) and the size of the area of a frame (8 bit each), 8
  ///   bytes of header per frame (Dx, Dy, Width, Height, offset of the pixels) and the palette indices of each
  ///   frame, row by row. The pixels of a frame go at (Dx + x, Dy + y) of an area of FrameWidth x FrameHeight;
  ///   what is not drawn stays transparent. As in the original all the frames share one pool of pixels, so a
  ///   frame that goes past the end of its row writes in the next row (and past its area, in the next frame,
  ///   that is written after it: the order is that of the original); outside the whole pool, or reading past the
  ///   record, is EWarException (the original wrote and read past the memory)
  /// </summary>
  TWarSpriteDecoder = class
  public
    class function Decode(AIndex: Integer; const ARaw: TBytes; const ALookup: TWarColorLookup): TWarSprite; static;
  end;

implementation

uses
  DelphiDoom.War.Types, DelphiDoom.War.LittleEndian, DelphiDoom.War.Graphics.ColorLookup;

{ TWarSpriteDecoder }

class function TWarSpriteDecoder.Decode(AIndex: Integer; const ARaw: TBytes; const ALookup: TWarColorLookup): TWarSprite;
var
  LCount: Integer;
  LFrameSize: Integer;
  LEntryOffset: Integer;
  LPool: TBytes;
  LFrame: Integer;
  LSource: Int64;
  LX: Integer;
  LY: Integer;
  LTarget: Int64;
begin
  if Length(ARaw) < SizeOf(TWarSpriteHeader) then
    raise EWarException.CreateFmt(SWarGraphicsTooShort, ['sprite', AIndex, Length(ARaw), SizeOf(TWarSpriteHeader)]);
  LCount := TWarLittleEndian.ReadWord(ARaw, 0);
  Result.FrameWidth := ARaw[2];
  Result.FrameHeight := ARaw[3];
  LFrameSize := Result.FrameWidth * Result.FrameHeight * WAR_PIXEL_SIZE;

  SetLength(Result.Frames, LCount);
  SetLength(LPool, LCount * LFrameSize);
  for LFrame := 0 to LCount - 1 do
  begin
    LEntryOffset := SizeOf(TWarSpriteHeader) + LFrame * SizeOf(TWarSpriteFrameEntry);
    if LEntryOffset + SizeOf(TWarSpriteFrameEntry) > Length(ARaw) then
      raise EWarException.CreateFmt(SWarGraphicsTooShort, ['sprite', AIndex, Length(ARaw), LEntryOffset + SizeOf(TWarSpriteFrameEntry)]);
    Result.Frames[LFrame].Dx := ARaw[LEntryOffset];
    Result.Frames[LFrame].Dy := ARaw[LEntryOffset + 1];
    Result.Frames[LFrame].Width := ARaw[LEntryOffset + 2];
    Result.Frames[LFrame].Height := ARaw[LEntryOffset + 3];
    Result.Frames[LFrame].Offset := TWarLittleEndian.ReadCardinal(ARaw, LEntryOffset + 4);
  end;

  for LFrame := 0 to LCount - 1 do
  begin
    LSource := Result.Frames[LFrame].Offset;
    for LY := Result.Frames[LFrame].Dy to Result.Frames[LFrame].Dy + Result.Frames[LFrame].Height - 1 do
      for LX := Result.Frames[LFrame].Dx to Result.Frames[LFrame].Dx + Result.Frames[LFrame].Width - 1 do
      begin
        LTarget := Int64(LFrame) * LFrameSize + (Int64(LX) + Int64(LY) * Result.FrameWidth) * WAR_PIXEL_SIZE;
        if LTarget + WAR_PIXEL_SIZE > Length(LPool) then
          raise EWarException.CreateFmt(SWarGraphicsPixelOutside, [LFrame]);
        if LSource >= Length(ARaw) then
          raise EWarException.CreateFmt(SWarGraphicsTooShort, ['sprite', AIndex, Length(ARaw), LSource + 1]);
        TWarColorLookupBuilder.PutPixel(ALookup, ARaw[LSource], LPool, Integer(LTarget));
        Inc(LSource);
      end;
  end;

  for LFrame := 0 to LCount - 1 do
    Result.Frames[LFrame].Pixels := Copy(LPool, LFrame * LFrameSize, LFrameSize);
end;

end.

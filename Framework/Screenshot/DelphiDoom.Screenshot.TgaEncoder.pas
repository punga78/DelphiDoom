{******************************************************************************}
{                                                                              }
{  DelphiDoom: Screenshot library - TGA encoder                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Screenshot.TgaEncoder;

interface

uses
  System.SysUtils, DelphiDoom.Screenshot.Types, DelphiDoom.Screenshot.EncoderBase;

const
  /// <summary>Bytes of the header of a TGA file</summary>
  SCREENSHOT_TGA_HEADER_SIZE = 18;

type
  /// <summary>
  ///   M_DoScreenShotTGA: an uncompressed 32 bit file, with the alpha channel at 255. The
  ///   origin of the rows is written in the header (upper left for the software renderer,
  ///   lower left for OpenGL) and the rows are copied as they come
  /// </summary>
  TScreenshotTgaEncoder = class(TScreenshotEncoderBase)
  protected
    function GetFormat: TScreenshotFormat; override;
    function DoEncode(APixels: Pointer; AWidth, AHeight: Integer;
      ABottomUp: Boolean): TBytes; override;
  end;

implementation

{ TScreenshotTgaEncoder }

function TScreenshotTgaEncoder.GetFormat: TScreenshotFormat;
begin
  Result := TScreenshotFormat.Tga;
end;

function TScreenshotTgaEncoder.DoEncode(APixels: Pointer; AWidth, AHeight: Integer;
  ABottomUp: Boolean): TBytes;
var
  LCount: Integer;
  LIndex: Integer;
begin
  LCount := AWidth * AHeight;
  SetLength(Result, SCREENSHOT_TGA_HEADER_SIZE + LCount * 4);
  FillChar(Result[0], SCREENSHOT_TGA_HEADER_SIZE, 0);
  Result[2] := 2; // uncompressed true color
  Result[12] := AWidth and 255;
  Result[13] := (AWidth shr 8) and 255;
  Result[14] := AHeight and 255;
  Result[15] := (AHeight shr 8) and 255;
  Result[16] := 32; // bits per pixel
  if ABottomUp then
    Result[17] := 0 // origin in the lower left-hand corner
  else
    Result[17] := 32; // origin in the upper left-hand corner

  Move(APixels^, Result[SCREENSHOT_TGA_HEADER_SIZE], LCount * 4);
  for LIndex := 0 to LCount - 1 do
    Result[SCREENSHOT_TGA_HEADER_SIZE + LIndex * 4 + 3] := 255;
end;

end.

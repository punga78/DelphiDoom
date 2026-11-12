{******************************************************************************}
{                                                                              }
{  DelphiDoom: parity library - a frame as a BMP file                          }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Parity.BitmapWriter;

interface

uses
  System.Classes;

type
  /// <summary>Writes a frame of 32 bit pixels (blue, green, red, unused: as the memory of the engine) as a BMP file</summary>
  TParityBitmapWriter = class
  public
    /// <summary>A BMP of 32 bits per pixel, rows from the top (negative height); the pixels are Width x Height numbers</summary>
    class procedure Write(AStream: TStream; AWidth, AHeight: Integer; APixels: Pointer); static;
    /// <summary>The same in a file (overwritten)</summary>
    class procedure SaveToFile(const AFileName: string; AWidth, AHeight: Integer; APixels: Pointer); static;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.Parity.Types;

const
  SWrongSize = 'The size of the bitmap is wrong';
  FILE_HEADER_SIZE = 14;
  INFO_HEADER_SIZE = 40;

type
  TBitmapHeaders = packed record
    Signature: Word;
    FileSize: Cardinal;
    Reserved: Cardinal;
    PixelOffset: Cardinal;
    HeaderSize: Cardinal;
    Width: Integer;
    Height: Integer;
    Planes: Word;
    BitCount: Word;
    Compression: Cardinal;
    ImageSize: Cardinal;
    XPixelsPerMeter: Integer;
    YPixelsPerMeter: Integer;
    ColorsUsed: Cardinal;
    ColorsImportant: Cardinal;
  end;

{ TParityBitmapWriter }

class procedure TParityBitmapWriter.Write(AStream: TStream; AWidth, AHeight: Integer; APixels: Pointer);
var
  LHeaders: TBitmapHeaders;
begin
  if (AWidth <= 0) or (AHeight <= 0) or not Assigned(APixels) then
    raise EParityException.Create(SWrongSize);
  FillChar(LHeaders, SizeOf(LHeaders), 0);
  LHeaders.Signature := $4D42;
  LHeaders.PixelOffset := FILE_HEADER_SIZE + INFO_HEADER_SIZE;
  LHeaders.ImageSize := Cardinal(AWidth) * Cardinal(AHeight) * 4;
  LHeaders.FileSize := LHeaders.PixelOffset + LHeaders.ImageSize;
  LHeaders.HeaderSize := INFO_HEADER_SIZE;
  LHeaders.Width := AWidth;
  LHeaders.Height := -AHeight;
  LHeaders.Planes := 1;
  LHeaders.BitCount := 32;
  AStream.WriteBuffer(LHeaders, SizeOf(LHeaders));
  AStream.WriteBuffer(APixels^, Integer(LHeaders.ImageSize));
end;

class procedure TParityBitmapWriter.SaveToFile(const AFileName: string; AWidth, AHeight: Integer;
  APixels: Pointer);
var
  LStream: TFileStream;
begin
  LStream := TFileStream.Create(AFileName, fmCreate);
  try
    Write(LStream, AWidth, AHeight, APixels);
  finally
    LStream.Free;
  end;
end;

end.

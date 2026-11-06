{******************************************************************************}
{                                                                              }
{  DelphiDoom: Imaging library - reads the lump of a flat as 32 bit pixels     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Imaging.FlatReader;

interface

uses
  System.SysUtils, DelphiDoom.Imaging.Types, DelphiDoom.Imaging.Intf;

type
  /// <summary>
  ///   The conversion of R_ReadDS32Cache (r_cache_flats.pas) from the bytes of a flat to the
  ///   pixels of its palette. The size comes from FLATINFO when it gave one; otherwise from
  ///   the length of the lump: a length of 64x64, 128x128 ... 4096x4096 bytes gives that flat,
  ///   any other (64x128 for example) the 64x64 one that begins the lump
  /// </summary>
  /// <remarks>
  ///   A lump shorter than 4096 bytes gives whole rows of 64 pixels only (the tail of less than
  ///   64 bytes is dropped, as before). What the lump does not cover is 0: the old code left
  ///   there what the memory had, and read past the lump when FLATINFO asked for more than it has
  /// </remarks>
  TImagingFlatReader = class(TInterfacedObject, IImagingFlatReader)
  private
    class function IndexFromLength(ALength: Integer): Integer; static;
  public
    function Read(const ALump: TBytes; const APalette: TImagingPixels;
      AInfoSizeIndex: Integer): TImagingFlatImage;
  end;

implementation

{ TImagingFlatReader }

class function TImagingFlatReader.IndexFromLength(ALength: Integer): Integer;
var
  LSide: Int64;
begin
  for Result := 0 to IMAGING_FLAT_MAX_INDEX do
  begin
    LSide := Int64(IMAGING_FLAT_SIDE) shl Result;
    if ALength = LSide * LSide then
      Exit;
  end;
  Result := 0;
end;

function TImagingFlatReader.Read(const ALump: TBytes; const APalette: TImagingPixels;
  AInfoSizeIndex: Integer): TImagingFlatImage;
var
  LIndex: Integer;
  LLoops: Integer;
  LCount: Integer;
  LPixel: Integer;
begin
  if Length(APalette) < IMAGING_PALETTE_SIZE then
    raise EImagingException.Create(SImagingBadPalette);
  if (AInfoSizeIndex < 0) or (AInfoSizeIndex > IMAGING_FLAT_MAX_INDEX) then
    raise EImagingException.Create(SImagingBadFlatIndex);

  if AInfoSizeIndex > 0 then
    LIndex := AInfoSizeIndex
  else
    LIndex := IndexFromLength(Length(ALump));
  Result.Side := IMAGING_FLAT_SIDE shl LIndex;
  SetLength(Result.Pixels, Result.Side * Result.Side);
  // SetLength does not clear the new pixels
  FillChar(Result.Pixels[0], Length(Result.Pixels) * SizeOf(Cardinal), 0);

  if Length(ALump) < IMAGING_FLAT_PIXELS then
    LLoops := Length(ALump) div 64
  else
    LLoops := (Result.Side * Result.Side) div 64;
  LCount := LLoops * 64;
  if LCount > Length(ALump) then
    LCount := Length(ALump);
  for LPixel := 0 to LCount - 1 do
    Result.Pixels[LPixel] := APalette[ALump[LPixel]];
end;

end.

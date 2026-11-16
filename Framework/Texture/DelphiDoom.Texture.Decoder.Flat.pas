{******************************************************************************}
{                                                                              }
{  DelphiDoom: Texture library - decoder of flats                              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Port of t_flat.pas                                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Texture.Decoder.Flat;

interface

uses
  System.SysUtils, DelphiDoom.Texture.Types, DelphiDoom.Texture.Image,
  DelphiDoom.Texture.Intf;

type
  /// <summary>
  ///   Reads the lump of a flat (the extension is '.FLAT'): one byte for each pixel, the
  ///   color from the palette of the game. A lump of 64x64 or 64x128 bytes is the 64x64 flat,
  ///   one of 128x128, 256x256 ... 4096x4096 the square flat of that size; any other length is
  ///   not a flat. The colors have the alpha set and red and blue exchanged
  /// </summary>
  TTextureFlatDecoder = class(TInterfacedObject, ITextureDecoder)
  strict private
    FPalette: ITexturePaletteSource;
    function GetExtension: string;
  public
    constructor Create(const APalette: ITexturePaletteSource);
    function Decode(const ASource: TBytes; const AImage: TTextureImage): Boolean;
    /// <summary>True when a lump of that length is a flat (64x64, 64x128, 128x128 ... 4096x4096)</summary>
    class function IsFlatLength(ALength: Integer): Boolean; static;
  end;

implementation

{ TTextureFlatDecoder }

constructor TTextureFlatDecoder.Create(const APalette: ITexturePaletteSource);
begin
  inherited Create;
  if not Assigned(APalette) then
    raise EArgumentNilException.Create('APalette');
  FPalette := APalette;
end;

function TTextureFlatDecoder.GetExtension: string;
begin
  Result := '.FLAT';
end;

class function TTextureFlatDecoder.IsFlatLength(ALength: Integer): Boolean;
var
  LSide: Integer;
begin
  if ALength = 64 * 128 then
    Exit(True);
  LSide := 64;
  while LSide <= 4096 do
  begin
    if ALength = LSide * LSide then
      Exit(True);
    LSide := LSide * 2;
  end;
  Result := False;
end;

function TTextureFlatDecoder.Decode(const ASource: TBytes; const AImage: TTextureImage): Boolean;
var
  LSide: Integer;
  LCount: Integer;
  LColors: TTexturePixels;
  LIndex: Integer;
  LPixels: PTextureColorArray;
begin
  Result := False;
  if not IsFlatLength(Length(ASource)) then
    Exit;
  if Length(ASource) = 64 * 128 then
    LSide := 64
  else
  begin
    LSide := 64;
    while LSide * LSide < Length(ASource) do
      LSide := LSide * 2;
  end;
  LCount := LSide * LSide;
  LColors := FPalette.GetColors;
  if Length(LColors) < TEXTURE_PALETTE_SIZE then
    Exit;

  AImage.SetBytesPerPixel(4);
  AImage.SetWidth(LSide);
  AImage.SetHeight(LSide);
  if not AImage.HasPixels then
    Exit;
  LPixels := PTextureColorArray(AImage.PixelsPointer);
  for LIndex := 0 to LCount - 1 do
    LPixels^[LIndex] := LColors[ASource[LIndex]] or $FF000000;
  AImage.SwapRGB;
  Result := True;
end;

end.

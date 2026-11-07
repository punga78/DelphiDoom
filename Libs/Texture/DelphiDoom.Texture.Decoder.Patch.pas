{******************************************************************************}
{                                                                              }
{  DelphiDoom: Texture library - decoder of patches                            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Port of t_patch.pas                                                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Texture.Decoder.Patch;

interface

uses
  System.SysUtils, DelphiDoom.Texture.Types, DelphiDoom.Texture.Image, DelphiDoom.Texture.Intf;

type
  /// <summary>
  ///   Reads a patch of Doom (the extension is '.PATCH') as a 32 bit image: the pixels
  ///   of the posts get the color of the palette of the game and the full alpha, the
  ///   others are 0; red and blue are exchanged. The offsets of the patch are kept
  /// </summary>
  /// <remarks>
  ///   The posts are walked as the old reader did: the first post of a column has its
  ///   top delta from the top of the picture, and so do the next ones while their delta
  ///   grows; from the first one that does not, the deltas of a column are added up (the
  ///   "tall patch" rule). This is not the rule of the Imaging library, which paints a
  ///   column with absolute deltas, so the posts are walked here. The old code walked the lump
  ///   with pointers and no limits: now a column or a post that goes outside of the lump gives false,
  ///   and a pixel above or below the picture is dropped
  /// </remarks>
  TTexturePatchDecoder = class(TInterfacedObject, ITextureDecoder)
  strict private
    const
      MAX_WIDTH = 8192;
      MAX_HEIGHT = 1024;
      HEADER_SIZE = 8;
      POST_END = $FF;
    var
      FPalette: ITexturePaletteSource;
    function GetExtension: string;
    class function WalkColumn(const ASource: TBytes; AColumnOffset, AColumn, AWidth, AHeight: Integer;
      const AColors: TTexturePixels; APixels: PTextureColorArray): Boolean; static;
  public
    constructor Create(const APalette: ITexturePaletteSource);
    function Decode(const ASource: TBytes; const AImage: TTextureImage): Boolean;
  end;

implementation

{ TTexturePatchDecoder }

constructor TTexturePatchDecoder.Create(const APalette: ITexturePaletteSource);
begin
  inherited Create;
  if not Assigned(APalette) then
    raise EArgumentNilException.Create('APalette');
  FPalette := APalette;
end;

function TTexturePatchDecoder.GetExtension: string;
begin
  Result := '.PATCH';
end;

class function TTexturePatchDecoder.WalkColumn(const ASource: TBytes; AColumnOffset, AColumn, AWidth,
  AHeight: Integer; const AColors: TTexturePixels; APixels: PTextureColorArray): Boolean;
var
  LPosition: Integer;
  LDelta, LPreviousDelta: Integer;
  LTall: Boolean;
  LLength, LRow, LIndex: Integer;
begin
  Result := False;
  LPosition := AColumnOffset;
  LDelta := 0;
  LTall := False;
  while True do
  begin
    if (LPosition < 0) or (LPosition >= Length(ASource)) then
      Exit;
    if ASource[LPosition] = POST_END then
      Break;
    if LPosition + 2 >= Length(ASource) then
      Exit;
    LLength := ASource[LPosition + 1];
    if LPosition + 3 + LLength > Length(ASource) then
      Exit;
    LDelta := LDelta + ASource[LPosition];
    for LIndex := 0 to LLength - 1 do
    begin
      LRow := LDelta + LIndex;
      if (LRow >= 0) and (LRow < AHeight) then
        APixels^[LRow * AWidth + AColumn] := AColors[ASource[LPosition + 3 + LIndex]] or $FF000000;
    end;
    LPreviousDelta := ASource[LPosition];
    LPosition := LPosition + LLength + 4;
    if not LTall then
    begin
      if (LPosition >= 0) and (LPosition < Length(ASource)) and (ASource[LPosition] > LPreviousDelta) then
        LDelta := 0
      else
        LTall := True;
    end;
  end;
  Result := True;
end;

function TTexturePatchDecoder.Decode(const ASource: TBytes; const AImage: TTextureImage): Boolean;
var
  LColors: TTexturePixels;
  LWidth, LHeight: Integer;
  LColumn: Integer;
  LOffset: Integer;
  LPixels: PTextureColorArray;
begin
  Result := False;
  LColors := FPalette.GetColors;
  if (Length(LColors) < TEXTURE_PALETTE_SIZE) or (Length(ASource) < HEADER_SIZE) then
    Exit;
  LWidth := SmallInt(ASource[0] or (ASource[1] shl 8));
  LHeight := SmallInt(ASource[2] or (ASource[3] shl 8));
  if (LWidth <= 0) or (LHeight <= 0) or (LWidth > MAX_WIDTH) or (LHeight > MAX_HEIGHT) then
    Exit;
  if HEADER_SIZE + LWidth * 4 > Length(ASource) then
    Exit;

  AImage.SetBytesPerPixel(4);
  AImage.SetWidth(LWidth);
  AImage.SetHeight(LHeight);
  if not AImage.HasPixels then
    Exit;
  AImage.LeftOffset := SmallInt(ASource[4] or (ASource[5] shl 8));
  AImage.TopOffset := SmallInt(ASource[6] or (ASource[7] shl 8));
  LPixels := PTextureColorArray(AImage.PixelsPointer);
  for LColumn := 0 to LWidth - 1 do
  begin
    Move(ASource[HEADER_SIZE + LColumn * 4], LOffset, SizeOf(LOffset));
    if not WalkColumn(ASource, LOffset, LColumn, LWidth, LHeight, LColors, LPixels) then
      Exit;
  end;
  AImage.SwapRGB;
  Result := True;
end;

end.

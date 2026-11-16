{******************************************************************************}
{                                                                              }
{  DelphiDoom: Imaging library - a patch of Doom from a picture of 32 bit colors}
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Imaging.ColorPatchBuilder;

interface

uses
  System.SysUtils,
  DelphiDoom.Imaging.Types,
  DelphiDoom.Imaging.Intf;

type
  /// <summary>
  ///   W_TextureAsPatch of w_sprite.pas without the engine: the colors that are not black-transparent become
  ///   the nearest color of the palette, and TImagingPatchWriter writes the patch (tall posts included)
  /// </summary>
  TImagingColorPatchBuilder = class(TInterfacedObject, IImagingColorPatchBuilder)
  strict private
    FWriter: IImagingPatchWriter;
    FColors: IImagingColorIndex;
  public
    constructor Create(const AWriter: IImagingPatchWriter; const AColors: IImagingColorIndex);
    function Build(const AColors: TImagingPixels; AWidth, AHeight, ALeftOffset,
      ATopOffset: Integer; const APalette: TImagingPixels; AMaxPostLength: Integer): TBytes;
  end;

implementation

{ TImagingColorPatchBuilder }

constructor TImagingColorPatchBuilder.Create(const AWriter: IImagingPatchWriter;
  const AColors: IImagingColorIndex);
begin
  inherited Create;
  if not Assigned(AWriter) then
    raise EArgumentNilException.Create('AWriter');
  if not Assigned(AColors) then
    raise EArgumentNilException.Create('AColors');
  FWriter := AWriter;
  FColors := AColors;
end;

function TImagingColorPatchBuilder.Build(const AColors: TImagingPixels; AWidth, AHeight,
  ALeftOffset, ATopOffset: Integer; const APalette: TImagingPixels;
  AMaxPostLength: Integer): TBytes;
var
  LImage: TImagingPatchImage;
  LCount: Integer;
  LIndex: Integer;
  LColor: Cardinal;
begin
  if (AWidth < 0) or (AHeight < 0) or (Int64(Length(AColors)) < Int64(AWidth) * AHeight) then
    raise EImagingException.Create(SImagingPatchPictureTooSmall);
  if Length(APalette) < IMAGING_PALETTE_SIZE then
    raise EImagingException.Create(SImagingBadPalette);

  LCount := AWidth * AHeight;
  LImage.Width := AWidth;
  LImage.Height := AHeight;
  LImage.LeftOffset := ALeftOffset;
  LImage.TopOffset := ATopOffset;
  SetLength(LImage.Pixels, LCount);
  SetLength(LImage.Opaque, LCount);
  for LIndex := 0 to LCount - 1 do
  begin
    LColor := AColors[LIndex];
    // a color without red, green and blue is transparent, whatever its alpha
    if LColor and $FFFFFF = 0 then
      Continue;
    LImage.Pixels[LIndex] := Byte(FColors.Nearest(APalette, LColor, 0, IMAGING_PALETTE_SIZE - 1));
    LImage.Opaque[LIndex] := $FF;
  end;
  Result := FWriter.BuildTall(LImage, AMaxPostLength);
end;

end.

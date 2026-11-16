{******************************************************************************}
{                                                                              }
{  DelphiDoom: Imaging library - the thumbnail of a saved game                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Imaging.ThumbnailBuilder;

interface

uses
  System.SysUtils, DelphiDoom.Imaging.Types, DelphiDoom.Imaging.Intf;

const
  /// <summary>The first color that a thumbnail can use (the color 0 is the transparent one)</summary>
  IMAGING_THUMBNAIL_FIRST_COLOR = 1;

type
  /// <summary>
  ///   MN_ScreenShotFromBlitBuffer (mn_screenshot.pas) on a buffer that the caller gives: the
  ///   thumbnail takes one pixel of the view window for each of its own, with no filter
  /// </summary>
  TImagingThumbnailBuilder = class(TInterfacedObject, IImagingThumbnailBuilder)
  strict private
    FColors: IImagingColorIndex;
    class function Clamp(AValue, ALow, AHigh: Integer): Integer; static;
  public
    constructor Create(const AColors: IImagingColorIndex);
    function Build(const ASettings: TImagingThumbnailSettings; APixels: Pointer;
      const APalette: TImagingPixels): TBytes;
  end;

implementation

{ TImagingThumbnailBuilder }

constructor TImagingThumbnailBuilder.Create(const AColors: IImagingColorIndex);
begin
  inherited Create;
  if not Assigned(AColors) then
    raise EArgumentNilException.Create('AColors');
  FColors := AColors;
end;

class function TImagingThumbnailBuilder.Clamp(AValue, ALow, AHigh: Integer): Integer;
begin
  if AValue < ALow then
    Result := ALow
  else if AValue > AHigh then
    Result := AHigh
  else
    Result := AValue;
end;

function TImagingThumbnailBuilder.Build(const ASettings: TImagingThumbnailSettings;
  APixels: Pointer; const APalette: TImagingPixels): TBytes;
var
  LRow: PByte;
  LPixel: PByte;
  LX: Integer;
  LY: Integer;
  LSourceX: Integer;
  LSourceY: Integer;
  LColor: Cardinal;
begin
  if (not Assigned(APixels)) or (Length(APalette) < IMAGING_PALETTE_SIZE) or
    (ASettings.ScreenWidth < 1) or (ASettings.ScreenHeight < 1) or
    (ASettings.Width < 1) or (ASettings.Height < 1) then
    raise EImagingException.Create(SImagingBadThumbnail);

  SetLength(Result, ASettings.Width * ASettings.Height);
  for LY := 0 to ASettings.Height - 1 do
  begin
    LSourceY := ASettings.ViewY + ((LY * ASettings.ViewHeight) div ASettings.Height);
    if ASettings.BottomUp then
      LSourceY := ASettings.ScreenHeight - LSourceY - 1;
    LSourceY := Clamp(LSourceY, 0, ASettings.ScreenHeight - 1);
    LRow := PByte(APixels) + LSourceY * ASettings.ScreenWidth * 4;
    for LX := 0 to ASettings.Width - 1 do
    begin
      LSourceX := ASettings.ViewX + ((LX * ASettings.ViewWidth) div ASettings.Width);
      LSourceX := Clamp(LSourceX, 0, ASettings.ScreenWidth - 1);
      LPixel := LRow + LSourceX * 4;
      LColor := (Cardinal(LPixel[2]) shl 16) + (Cardinal(LPixel[1]) shl 8) + LPixel[0];
      Result[LY * ASettings.Width + LX] := Byte(FColors.Nearest(APalette, LColor,
        IMAGING_THUMBNAIL_FIRST_COLOR, IMAGING_PALETTE_SIZE - 1));
    end;
  end;
end;

end.

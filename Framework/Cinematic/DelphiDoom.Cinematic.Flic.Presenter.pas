{******************************************************************************}
{                                                                              }
{  DelphiDoom: cinematic library - putting a FLIC image on a screen (#199)     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Cinematic.Flic.Presenter;

interface

uses
  DelphiDoom.Imaging.Types,
  DelphiDoom.Cinematic.Flic.Intf;

type
  /// <summary>How the picture fills the screen</summary>
  TFlicPresentMode = (
    /// <summary>As large as fits, with the proportions of the display (bands around it)</summary>
    fpmFit,
    /// <summary>The largest whole multiple of the size of the picture that fits (at least 1; a screen smaller than the picture gets fpmFit)</summary>
    fpmIntegerFit,
    /// <summary>The whole screen, whatever the proportions</summary>
    fpmStretch
  );

  /// <summary>Where the picture goes on the screen, in pixels</summary>
  TFlicPresentRect = record
    Left: Integer;
    Top: Integer;
    Width: Integer;
    Height: Integer;
  end;

  /// <summary>
  ///   Puts the image of a FLIC on a screen of 32 bit pixels: it scales with the nearest pixel (the animations
  ///   are 8 bit art, a filter would blur them), centers and paints the bands. No window and no device: the
  ///   caller gets the pixels and shows them where it likes
  /// </summary>
  TFlicPresenter = class
  public
    /// <summary>
    ///   Where an animation of ASourceWidth x ASourceHeight goes on a screen of AScreenWidth x AScreenHeight.
    ///   The proportions of the display are ADisplayWidth : ADisplayHeight (the 320 x 200 of the DOS games was
    ///   shown at 4 : 3: 4, 3); 0 means the proportions of the picture. A size that is not positive gives an empty rect
    /// </summary>
    class function Layout(ASourceWidth, ASourceHeight, AScreenWidth, AScreenHeight: Integer;
      AMode: TFlicPresentMode; ADisplayWidth: Integer = 0; ADisplayHeight: Integer = 0): TFlicPresentRect; static;
    /// <summary>
    ///   Draws the image into AScreen (resized to AScreenWidth x AScreenHeight, the rows from the top); the bands
    ///   get ABackground. An image with no pixels only paints the background
    /// </summary>
    class procedure Present(const AImage: TFlicPlayerImage; AMode: TFlicPresentMode; AScreenWidth,
      AScreenHeight: Integer; var AScreen: TImagingPixels; ABackground: Cardinal = $FF000000;
      ADisplayWidth: Integer = 0; ADisplayHeight: Integer = 0); static;
  end;

implementation

{ TFlicPresenter }

class function TFlicPresenter.Layout(ASourceWidth, ASourceHeight, AScreenWidth, AScreenHeight: Integer;
  AMode: TFlicPresentMode; ADisplayWidth, ADisplayHeight: Integer): TFlicPresentRect;
var
  LFactor: Integer;
begin
  Result := Default(TFlicPresentRect);
  if (ASourceWidth <= 0) or (ASourceHeight <= 0) or (AScreenWidth <= 0) or (AScreenHeight <= 0) then
    Exit;
  if (ADisplayWidth <= 0) or (ADisplayHeight <= 0) then
  begin
    ADisplayWidth := ASourceWidth;
    ADisplayHeight := ASourceHeight;
  end;
  if (AMode = fpmIntegerFit) and (AScreenWidth >= ASourceWidth) and (AScreenHeight >= ASourceHeight) then
  begin
    LFactor := AScreenWidth div ASourceWidth;
    if AScreenHeight div ASourceHeight < LFactor then
      LFactor := AScreenHeight div ASourceHeight;
    Result.Width := ASourceWidth * LFactor;
    Result.Height := ASourceHeight * LFactor;
  end
  else if AMode = fpmStretch then
  begin
    Result.Width := AScreenWidth;
    Result.Height := AScreenHeight;
  end
  else if Int64(AScreenWidth) * ADisplayHeight <= Int64(AScreenHeight) * ADisplayWidth then
  begin
    Result.Width := AScreenWidth;
    Result.Height := Integer(Int64(AScreenWidth) * ADisplayHeight div ADisplayWidth);
  end
  else
  begin
    Result.Height := AScreenHeight;
    Result.Width := Integer(Int64(AScreenHeight) * ADisplayWidth div ADisplayHeight);
  end;
  if Result.Width < 1 then
    Result.Width := 1;
  if Result.Height < 1 then
    Result.Height := 1;
  Result.Left := (AScreenWidth - Result.Width) div 2;
  Result.Top := (AScreenHeight - Result.Height) div 2;
end;

class procedure TFlicPresenter.Present(const AImage: TFlicPlayerImage; AMode: TFlicPresentMode; AScreenWidth,
  AScreenHeight: Integer; var AScreen: TImagingPixels; ABackground: Cardinal; ADisplayWidth, ADisplayHeight: Integer);
var
  LPlace: TFlicPresentRect;
  LColumns: TArray<Integer>;
  LX, LY, LSourceRow: Integer;
  LTarget: Integer;
begin
  if (AScreenWidth <= 0) or (AScreenHeight <= 0) then
  begin
    AScreen := nil;
    Exit;
  end;
  SetLength(AScreen, AScreenWidth * AScreenHeight);
  for LX := 0 to High(AScreen) do
    AScreen[LX] := ABackground;
  if (AImage.Width <= 0) or (AImage.Height <= 0) or (Length(AImage.Pixels) < AImage.Width * AImage.Height) then
    Exit;
  LPlace := Layout(AImage.Width, AImage.Height, AScreenWidth, AScreenHeight, AMode, ADisplayWidth, ADisplayHeight);
  SetLength(LColumns, LPlace.Width);
  for LX := 0 to LPlace.Width - 1 do
    LColumns[LX] := LX * AImage.Width div LPlace.Width;
  for LY := 0 to LPlace.Height - 1 do
  begin
    LSourceRow := (LY * AImage.Height div LPlace.Height) * AImage.Width;
    LTarget := (LPlace.Top + LY) * AScreenWidth + LPlace.Left;
    for LX := 0 to LPlace.Width - 1 do
      AScreen[LTarget + LX] := AImage.Pixels[LSourceRow + LColumns[LX]];
  end;
end;

end.

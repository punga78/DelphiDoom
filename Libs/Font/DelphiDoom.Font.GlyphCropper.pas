{******************************************************************************}
{                                                                              }
{  DelphiDoom: font library - cuts the empty columns on the right of a character }
{  Copyright (C) 2021-2022 by Jim Valavanis (original DD_FONT)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Font.GlyphCropper;

interface

uses
  System.SysUtils,
  DelphiDoom.Font.Types;

type
  /// <summary>
  ///   RightCropLetterBitmap of TFontEngine: the picture of a character is as wide as the cell, and a character
  ///   that does not fill it must not leave the space that a text with the other characters would show. The
  ///   columns on the right that are empty (all pixels are the background) are taken away, but one is left
  ///   (the two last columns are not both empty) and the character is never made narrower than half of the
  ///   size of the font minus one, with 3 pixels as the least. A character narrower than that is not touched
  /// </summary>
  TFontGlyphCropper = class sealed
  strict private
    const
      MIN_WIDTH_FLOOR = 3;
    class function IsColumnEmpty(const AImage: TFontImage; AColumn: Integer; ABackground: Cardinal): Boolean; static;
  public
    /// <param name="ABackground">The background color of the picture, as $00RRGGBB</param>
    /// <param name="AFontSize">The size of the font of the settings (not in pixels: points)</param>
    /// <returns>The number of columns to keep</returns>
    class function CroppedWidth(const AImage: TFontImage; ABackground: Cardinal; AFontSize: Integer): Integer; static;
  end;

implementation

{ TFontGlyphCropper }

class function TFontGlyphCropper.IsColumnEmpty(const AImage: TFontImage; AColumn: Integer;
  ABackground: Cardinal): Boolean;
var
  LRow: Integer;
begin
  for LRow := 0 to AImage.Height - 1 do
    if (AImage.Pixels[AColumn + LRow * AImage.Width] and $FFFFFF) <> ABackground then
      Exit(False);
  Result := True;
end;

class function TFontGlyphCropper.CroppedWidth(const AImage: TFontImage; ABackground: Cardinal;
  AFontSize: Integer): Integer;
var
  LMinimumWidth: Integer;
  LColumn: Integer;
begin
  if not AImage.IsValid then
    raise EFontException.Create(SFontBadImage);
  Result := AImage.Width;
  LMinimumWidth := AFontSize div 2 - 1;
  if LMinimumWidth < MIN_WIDTH_FLOOR then
    LMinimumWidth := MIN_WIDTH_FLOOR;
  if Result < LMinimumWidth then
    Exit;
  LColumn := AImage.Width - 1;
  while LColumn >= LMinimumWidth do
  begin
    // one empty column is left on the right: it takes two to give one up
    if IsColumnEmpty(AImage, LColumn, ABackground) and IsColumnEmpty(AImage, LColumn - 1, ABackground) then
      Dec(Result)
    else
      Break;
    Dec(LColumn);
  end;
end;

end.

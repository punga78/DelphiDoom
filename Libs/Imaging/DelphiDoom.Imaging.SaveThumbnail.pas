{******************************************************************************}
{                                                                              }
{  DelphiDoom: Imaging library - the thumbnail of a saved game                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Imaging.SaveThumbnail;

interface

uses
  System.SysUtils, DelphiDoom.Imaging.Types;

type
  /// <summary>
  ///   The mark and the pixels of the thumbnail of a saved game (TImagingSaveThumbnail): the
  ///   part of MN_ScreenShotFromBlitBuffer and MN_ValidScreenShot of mn_screenshot.pas that does
  ///   not read the screen. The bytes are those of the savegames of the engine
  /// </summary>
  TImagingSaveThumbnailFormat = class
  public
    /// <summary>True when the thumbnail begins with the text MENUSCREENSHOT</summary>
    class function IsValid(const AThumbnail: TImagingSaveThumbnail): Boolean; static;
    /// <summary>
    ///   Writes the mark and the IMAGING_SAVE_THUMBNAIL_SIZE palette indices of APixels (the
    ///   result of IImagingThumbnailBuilder.Build with a size of 80x50)
    /// </summary>
    /// <exception cref="EImagingException">APixels has not IMAGING_SAVE_THUMBNAIL_SIZE bytes</exception>
    class procedure Fill(var AThumbnail: TImagingSaveThumbnail; const APixels: TBytes); static;
  end;

const
  /// <summary>The text MENUSCREENSHOT (MNSCREENSHOT_MAGIC)</summary>
  IMAGING_SAVE_THUMBNAIL_MAGIC: packed array[0..IMAGING_SAVE_THUMBNAIL_MAGIC_SIZE - 1] of Byte = (
    $4D, $45, $4E, $55, $53, $43, $52, $45, $45, $4E, $53, $48, $4F, $54
  );

implementation

{ TImagingSaveThumbnailFormat }

class function TImagingSaveThumbnailFormat.IsValid(const AThumbnail: TImagingSaveThumbnail): Boolean;
var
  LIndex: Integer;
begin
  for LIndex := 0 to IMAGING_SAVE_THUMBNAIL_MAGIC_SIZE - 1 do
    if AThumbnail.Header[LIndex] <> IMAGING_SAVE_THUMBNAIL_MAGIC[LIndex] then
      Exit(False);
  Result := True;
end;

class procedure TImagingSaveThumbnailFormat.Fill(var AThumbnail: TImagingSaveThumbnail;
  const APixels: TBytes);
begin
  if Length(APixels) <> IMAGING_SAVE_THUMBNAIL_SIZE then
    raise EImagingException.CreateFmt(SImagingBadSaveThumbnail,
      [IMAGING_SAVE_THUMBNAIL_SIZE, Length(APixels)]);
  Move(IMAGING_SAVE_THUMBNAIL_MAGIC[0], AThumbnail.Header[0], IMAGING_SAVE_THUMBNAIL_MAGIC_SIZE);
  Move(APixels[0], AThumbnail.Data[0], IMAGING_SAVE_THUMBNAIL_SIZE);
end;

end.

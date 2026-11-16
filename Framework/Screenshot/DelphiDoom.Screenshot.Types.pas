{******************************************************************************}
{                                                                              }
{  DelphiDoom: Screenshot library - shared types                               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Screenshot.Types;

interface

uses
  System.SysUtils;

const
  /// <summary>Quality of the JPEG files (the old code used the maximum one)</summary>
  SCREENSHOT_JPEG_QUALITY = 100;

type
  /// <summary>The file formats of a screenshot</summary>
  TScreenshotFormat = (Tga, Png, Jpg);

  /// <summary>
  ///   Where each format of one screenshot is written. Format is the one that was asked for:
  ///   the others are only used when the JPEG copy is on
  /// </summary>
  TScreenshotTarget = record
    Format: TScreenshotFormat;
    TgaPath: string;
    JpgPath: string;
    PngPath: string;
    /// <summary>The path of the file of AFormat</summary>
    function PathOf(AFormat: TScreenshotFormat): string;
  end;

  /// <summary>Raised when an image cannot be encoded</summary>
  EScreenshotException = class(Exception);

resourcestring
  SScreenshotInvalidImage = 'The screenshot has no pixels or a size that is not valid';
  SScreenshotNoEncoder = 'There is no encoder for the format %s';

implementation

{ TScreenshotTarget }

function TScreenshotTarget.PathOf(AFormat: TScreenshotFormat): string;
begin
  case AFormat of
    TScreenshotFormat.Tga:
      Result := TgaPath;
    TScreenshotFormat.Png:
      Result := PngPath;
  else
    Result := JpgPath;
  end;
end;

end.

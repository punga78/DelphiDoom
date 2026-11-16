{******************************************************************************}
{                                                                              }
{  DelphiDoom: texture library - R_LoadImage: contracts                        }
{                                                                              }
{  Port of renderer\Image_files.cpp of the Doom 3 GPL Source Code (id          }
{  Software). Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.}
{  Based on the Doom 3 GPL Source Code (id Software).                          }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Framework\IdLib); the repository as a whole is GPL v2 or later.             }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Texture.IdImage.Intf;

interface

uses
  System.SysUtils, DelphiDoom.Imaging.Rgba.Image;

const
  /// <summary>The timestamp of a file that does not exist (0xFFFFFFFF stored in a long, as the original does)</summary>
  ID_IMAGE_NO_TIMESTAMP = -1;

type
  /// <summary>
  ///   Where the images come from (idFileSystem::ReadFile): the bytes and the time of the file. The file system of
  ///   <c>Framework\Wad</c> or the one of a game gives an adapter; a fake gives the files of a test
  /// </summary>
  IIdImageSource = interface
    ['{7D41B0A2-3C58-4E9F-A6D1-5B2E90C7F314}']
    /// <summary>False when the file does not exist; <c>ATimestamp</c> is then <c>ID_IMAGE_NO_TIMESTAMP</c></summary>
    function ReadFile(const AName: string; out ABytes: TBytes; out ATimestamp: Int64): Boolean;
  end;

  /// <summary>LoadJPG: the bytes of a JPEG file as an RGBA image (alpha 255)</summary>
  IIdImageJpegDecoder = interface
    ['{7D41B0A2-3C58-4E9F-A6D1-5B2E90C7F315}']
    function Decode(const ABytes: TBytes; out AImage: TImagingRgbaImage): Boolean;
  end;

  /// <summary>
  ///   R_LoadImage: loads any of the images of Doom 3 (TGA, PCX, BMP, JPG) into the canonical 32 bit RGBA format.
  ///   This is the contract an engine asks for an image by name; the loader of the engine (<c>TTextureDecoder*</c>
  ///   of <c>Decoder.Tga</c> and the others) can be aligned to it behind this interface, which has not been done:
  ///   it would change the external textures of the games.
  /// </summary>
  IIdImageLoader = interface
    ['{7D41B0A2-3C58-4E9F-A6D1-5B2E90C7F316}']
    /// <summary>
    ///   The image called by the name (the extension defaults to .tga, a name under five characters loads nothing,
    ///   the name is lower cased, a .tga that fails to load is tried as .jpg). False when nothing was loaded; the
    ///   timestamp is then <c>ID_IMAGE_NO_TIMESTAMP</c> if the file does not exist. With <c>AMakePowerOf2</c> the
    ///   image is resampled to power of two sides
    /// </summary>
    function Load(const AName: string; AMakePowerOf2: Boolean; out AImage: TImagingRgbaImage;
      out ATimestamp: Int64): Boolean;
    /// <summary>R_LoadImage with no picture asked for: only the timestamp of the file (the .jpg of a missing .tga)</summary>
    function Timestamp(const AName: string): Int64;
  end;

implementation

end.
{******************************************************************************}
{                                                                              }
{  DelphiDoom: Texture library - DDS file header, flags and shared types       }
{                                                                              }
{  The records and the DDSF_* flags are those of renderer\Image.h (id          }
{  Software, Doom 3, GPL v3), which are the ones of the DirectDraw surface     }
{  header (public file format). Copyright (C) 1999-2011 id Software LLC.       }
{                                                                              }
{  The header records are derived from the Doom 3 GPL source code and are      }
{  therefore available under the GNU General Public License, version 3, with   }
{  the additional terms of the Doom 3 Source Code License (see README.md of    }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Texture.Dds.Types;

interface

uses
  System.SysUtils, DelphiDoom.Texture.Types, DelphiDoom.Imaging.Rgba.Image;

const
  /// <summary>The four bytes "DDS " at the start of a file</summary>
  DDS_MAGIC = $20534444;
  /// <summary>The size that the header and the pixel format say they have</summary>
  DDS_HEADER_SIZE = 124;
  DDS_PIXEL_FORMAT_SIZE = 32;
  /// <summary>Magic and header</summary>
  DDS_FILE_PREFIX_SIZE = 4 + DDS_HEADER_SIZE;
  /// <summary>MAX_TEXTURE_LEVELS of Image.h</summary>
  DDS_MAX_LEVELS = 14;

  // surface description flags
  DDSF_CAPS = $00000001;
  DDSF_HEIGHT = $00000002;
  DDSF_WIDTH = $00000004;
  DDSF_PITCH = $00000008;
  DDSF_PIXELFORMAT = $00001000;
  DDSF_MIPMAPCOUNT = $00020000;
  DDSF_LINEARSIZE = $00080000;
  DDSF_DEPTH = $00800000;
  // pixel format flags
  DDSF_ALPHAPIXELS = $00000001;
  DDSF_FOURCC = $00000004;
  DDSF_RGB = $00000040;
  DDSF_RGBA = $00000041;
  // the extended flags of idTech 4
  DDSF_ID_INDEXCOLOR = $10000000;
  DDSF_ID_MONOCHROME = $20000000;
  // dwCaps1 flags
  DDSF_COMPLEX = $00000008;
  DDSF_TEXTURE = $00001000;
  DDSF_MIPMAP = $00400000;

  /// <summary>DDS_MAKEFOURCC('D','X','T','1') and the others</summary>
  DDS_FOURCC_DXT1 = $31545844;
  DDS_FOURCC_DXT3 = $33545844;
  DDS_FOURCC_DXT5 = $35545844;

  SDdsTooShort = 'The DDS file is too short';
  SDdsBadMagic = 'The file is not a DDS file';
  SDdsBadHeader = 'The header of the DDS file is not valid';
  SDdsBadSize = 'The size of the DDS image is not valid: %d x %d';
  SDdsUnsupported = 'This kind of DDS file is not supported: %s';
  SDdsTruncated = 'The DDS file ends before the pixels of the level %d';
  SDdsBadLevels = 'The levels of the DDS image to write are not a chain of halved sizes';

type
  /// <summary>ddsFilePixelFormat_t (32 bytes)</summary>
  TDdsPixelFormat = packed record
    Size: Cardinal;
    Flags: Cardinal;
    FourCC: Cardinal;
    RGBBitCount: Cardinal;
    RBitMask: Cardinal;
    GBitMask: Cardinal;
    BBitMask: Cardinal;
    ABitMask: Cardinal;
  end;

  /// <summary>ddsFileHeader_t (124 bytes; the magic "DDS " comes before it in the file)</summary>
  TDdsHeader = packed record
    Size: Cardinal;
    Flags: Cardinal;
    Height: Cardinal;
    Width: Cardinal;
    PitchOrLinearSize: Cardinal;
    Depth: Cardinal;
    MipMapCount: Cardinal;
    Reserved1: array[0..10] of Cardinal;
    PixelFormat: TDdsPixelFormat;
    Caps1: Cardinal;
    Caps2: Cardinal;
    Reserved2: array[0..2] of Cardinal;
  end;

  /// <summary>How the pixels of a DDS file are stored</summary>
  TDdsFormat = (
    Dxt1,
    Dxt3,
    Dxt5,
    /// <summary>Uncompressed, with channel masks (8, 16, 24 or 32 bits per pixel)</summary>
    Uncompressed
  );

  /// <summary>The levels of a DDS file decoded to RGBA</summary>
  TDdsImage = record
    Format: TDdsFormat;
    /// <summary>The file has the id Tech 4 flag that says that the image is monochrome</summary>
    IsMonochrome: Boolean;
    /// <summary>The format has an alpha channel (DXT3, DXT5, a mask of alpha, or DXT1 flagged with alpha)</summary>
    HasAlpha: Boolean;
    /// <summary>Level 0 is the full image, then each one half the size (never below 1)</summary>
    Levels: TArray<TImagingRgbaImage>;
  end;

  /// <summary>Raised for a DDS file that is damaged or that this library does not read</summary>
  EDdsException = class(ETextureException);

implementation

end.

{******************************************************************************}
{                                                                              }
{  DelphiDoom: cinematic library - FLIC animations: constants, types and       }
{  exceptions (issue #199)                                                     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Written from the description of the FLIC format (Autodesk Animator); no     }
{  code of a third party in this unit                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Cinematic.Flic.Types;

interface

uses
  System.SysUtils,
  DelphiDoom.Cinematic.Types;

const
  /// <summary>Type of a FLI file (320x200, the speed is in 1/70 of a second)</summary>
  FLIC_TYPE_FLI = $AF11;
  /// <summary>Type of a FLC file (any size, the speed is in milliseconds)</summary>
  FLIC_TYPE_FLC = $AF12;
  /// <summary>Bytes of the header of the file</summary>
  FLIC_HEADER_SIZE = 128;
  /// <summary>Bytes of the header of a frame (and of a prefix chunk)</summary>
  FLIC_FRAME_HEADER_SIZE = 16;
  /// <summary>Colors of the palette</summary>
  FLIC_PALETTE_SIZE = 256;
  /// <summary>Alpha byte of the pixels that the decoder gives</summary>
  FLIC_ALPHA_OPAQUE = $FF;
  /// <summary>Milliseconds of a frame whose delay is 0 (one tick of a FLI, 1000 / 70 rounded down)</summary>
  FLIC_DEFAULT_DELAY = 14;
  /// <summary>The largest picture accepted, in pixels (the buffer is one byte per pixel)</summary>
  FLIC_MAX_PIXELS = 64 * 1024 * 1024;

type
  /// <summary>Base of the errors of the FLIC decoder</summary>
  EFlicException = class(ECinematicException);

  /// <summary>
  ///   The data are not a valid FLIC: not a FLI/FLC header, no frames, a frame that is not
  ///   inside the file, a chunk that reads past the end or writes outside the picture
  /// </summary>
  EFlicInvalidDataException = class(EFlicException);

  /// <summary>The 256 colors of the palette as pixels $AABBGGRR (the red one is the low byte, as in Libs\Imaging)</summary>
  TFlicPalette = array[0..FLIC_PALETTE_SIZE - 1] of Cardinal;

implementation

end.

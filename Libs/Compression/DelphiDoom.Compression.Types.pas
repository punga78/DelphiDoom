{******************************************************************************}
{                                                                              }
{  DelphiDoom: compression library - shared types and constants                }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): framework\Compressor.h,  }
{  Compressor.cpp. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media    }
{  company.                                                                    }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Compression.Types;

interface

uses
  System.SysUtils;

const
  /// <summary>The size of the internal buffer of the bit stream compressors (byte buffer[65536])</summary>
  COMPRESSOR_BUFFER_SIZE = 65536;

  SCompressorNoStream = 'Compressor: Init was not called with a stream';
  SCompressorBadWordLength = 'Compressor: the word length %d is not in 1..32';
  SCompressorCannotSeek = 'cannot seek on idCompressor';

type
  /// <summary>
  ///   The error of the compressors: <c>common->Error</c> of the original (seek on a compressor) and the
  ///   preconditions it only asserts (a stream that was not given, a word length out of range)
  /// </summary>
  ECompressionException = class(Exception);

implementation

end.

{******************************************************************************}
{                                                                              }
{  DelphiDoom: cinematic library - shared types, constants and exceptions      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  The constants come from the RoQ decoders of Quake III Arena (cl_cin.c, GPL  }
{  v2 or later, Id Software, Inc.) and Doom 3 (Cinematic.cpp, GPL v3 with the  }
{  additional terms of the Doom 3 Source Code License, id Software LLC).       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Cinematic.Types;

interface

uses
  System.SysUtils;

const
  /// <summary>Id of the file header chunk (ROQ_FILE); the bytes are $84 $10 in the file</summary>
  ROQ_FILE = $1084;
  ROQ_QUAD = $1000;
  /// <summary>Size, width, height and block sizes of the video (ROQ_QUAD_INFO)</summary>
  ROQ_QUAD_INFO = $1001;
  /// <summary>The 2x2 vectors and the pairs of them that make the 4x4 and 8x8 ones (ROQ_CODEBOOK)</summary>
  ROQ_CODEBOOK = $1002;
  /// <summary>A frame of 8x8 and 4x4 blocks (ROQ_QUAD_VQ)</summary>
  ROQ_QUAD_VQ = $1011;
  /// <summary>A frame in JPEG (ROQ_QUAD_JPEG): not decoded, see README.md</summary>
  ROQ_QUAD_JPEG = $1012;
  ROQ_QUAD_HANG = $1013;
  /// <summary>A container: its chunks follow the header (ROQ_PACKET)</summary>
  ROQ_PACKET = $1030;
  /// <summary>DPCM audio, one channel (ZA_SOUND_MONO, ROQ_SOUND_MONO)</summary>
  ROQ_SOUND_MONO = $1020;
  /// <summary>DPCM audio, two channels interleaved (ZA_SOUND_STEREO, ROQ_SOUND_STEREO)</summary>
  ROQ_SOUND_STEREO = $1021;

  /// <summary>Bytes of the file header and of the header of a chunk</summary>
  ROQ_HEADER_SIZE = 8;
  /// <summary>The largest chunk that the decoders accept (the buffer of the original)</summary>
  ROQ_MAX_CHUNK_SIZE = 65536;
  /// <summary>Frames per second when the header says 0</summary>
  ROQ_DEFAULT_FPS = 30;
  /// <summary>Sample rate of the audio of the RoQ files of Quake III</summary>
  ROQ_SOUND_RATE = 22050;
  /// <summary>Alpha byte of the pixels of Quake III (yuv_to_rgb24); Doom 3 writes 0</summary>
  ROQ_ALPHA_OPAQUE = $FF;

  /// <summary>Largest and smallest block of the video (MAXSIZE, MINSIZE)</summary>
  ROQ_MAX_BLOCK = 8;
  ROQ_MIN_BLOCK = 4;
  /// <summary>The side of the macroblocks, which the video size must be a multiple of</summary>
  ROQ_MACROBLOCK = 16;

type
  /// <summary>Base of the errors of the library</summary>
  ECinematicException = class(Exception);

  /// <summary>The bytes end inside a header or a chunk</summary>
  ERoqTruncatedException = class(ECinematicException);

  /// <summary>A frame uses a vector, but no codebook has been decoded before it</summary>
  ERoqMissingCodebookException = class(ECinematicException);

  /// <summary>A frame comes before the chunk that says the size of the video</summary>
  ERoqMissingInfoException = class(ECinematicException);

  /// <summary>
  ///   The data are not valid: not a RoQ file, a chunk that is too big, a size that is not a
  ///   multiple of 16, a motion vector that points outside the buffers
  /// </summary>
  ERoqInvalidDataException = class(ECinematicException);

  /// <summary>Header of a chunk: 8 bytes, little endian; the file header has the same layout (size $FFFFFFFF, frames per second in Flags)</summary>
  TRoqChunkHeader = packed record
    Id: Word;
    Size: Cardinal;
    Flags: Word;
  end;

  /// <summary>
  ///   The kind of a chunk that the decoder has just handled: what the caller may find new
  /// </summary>
  TRoqChunkKind = (rckOther, rckInfo, rckCodebook, rckFrame, rckSound);

implementation

end.

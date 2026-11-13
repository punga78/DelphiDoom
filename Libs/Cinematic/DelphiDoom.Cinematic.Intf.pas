{******************************************************************************}
{                                                                              }
{  DelphiDoom: cinematic library - the contracts                               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Cinematic.Intf;

interface

uses
  DelphiDoom.Imaging.Types,
  DelphiDoom.Cinematic.Types;

type
  /// <summary>Where the bytes of a RoQ file come from (a file, a lump, a buffer)</summary>
  IRoqSource = interface
    ['{4B7E2C18-95A3-4D60-8F1E-C3A2D70B5E94}']
    function GetSize: Int64;
    function GetPosition: Int64;
    /// <summary>Reads up to ACount bytes; the result is how many were read (less at the end)</summary>
    function Read(var ABuffer; ACount: Integer): Integer;
    /// <summary>Moves to a position from the start (used to rewind)</summary>
    procedure Seek(APosition: Int64);
    property Size: Int64 read GetSize;
    property Position: Int64 read GetPosition;
  end;

  /// <summary>Who receives the audio of the file as the decoder meets it</summary>
  IRoqAudioSink = interface
    ['{91D5A0E3-2C47-4B8F-A6D1-7E30F2B84C15}']
    /// <summary>
    ///   PCM of 16 bits, interleaved when there are two channels; a mono chunk arrives as
    ///   two identical channels, as in Quake III
    /// </summary>
    procedure AudioReceived(const ASamples: TArray<SmallInt>; AChannels, ASampleRate: Integer);
  end;

  /// <summary>Decodes the chunks of a RoQ file one after the other</summary>
  IRoqDecoder = interface
    ['{E3A81F26-7B05-4C9D-92E4-5D16B0C7A3F8}']
    function GetWidth: Integer;
    function GetHeight: Integer;
    function GetFramesPerSecond: Integer;
    function GetFrameIndex: Integer;
    function GetFrame: TImagingPixels;
    /// <summary>
    ///   Handles the next chunk; False when the file is over. AKind says what it was: after
    ///   rckFrame the property Frame is the new image
    /// </summary>
    function ReadChunk(out AKind: TRoqChunkKind): Boolean;
    /// <summary>Handles chunks until a frame is ready; False if the file ends first</summary>
    function NextFrame: Boolean;
    /// <summary>Starts again from the first chunk (the codebook and the buffers are forgotten)</summary>
    procedure Reset;
    /// <summary>Pixels of the video; 0 until the chunk of the information has been read</summary>
    property Width: Integer read GetWidth;
    property Height: Integer read GetHeight;
    property FramesPerSecond: Integer read GetFramesPerSecond;
    /// <summary>Number of the last frame decoded since the start, from 0; -1 before the first</summary>
    property FrameIndex: Integer read GetFrameIndex;
    /// <summary>The last frame, Width * Height pixels $AABBGGRR (the red one is the low byte); a copy that stays valid</summary>
    property Frame: TImagingPixels read GetFrame;
  end;

  TRoqPlayerStatus = (rpsPlaying, rpsEnded);

  /// <summary>What the player shows at a time</summary>
  TRoqPlayerImage = record
    Width: Integer;
    Height: Integer;
    /// <summary>Number of the frame shown; -1 if the file has none</summary>
    FrameIndex: Integer;
    Status: TRoqPlayerStatus;
    Pixels: TImagingPixels;
  end;

  /// <summary>
  ///   Gives the image of a cinematic for a time that the caller provides: the player
  ///   never reads a clock
  /// </summary>
  IRoqPlayer = interface
    ['{0A6C94D7-3E18-4F52-B7A9-D2E5C813F640}']
    /// <summary>The frame that is on screen at AMilliseconds, which is a time on the clock of the caller</summary>
    function ImageForTime(AMilliseconds: Integer): TRoqPlayerImage;
    /// <summary>The next call to ImageForTime is the start of the cinematic</summary>
    procedure ResetTime;
  end;

implementation

end.
